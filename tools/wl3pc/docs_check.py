"""Check Markdown links, anchors, and note properties in the vault and root docs.

Rules: relative Markdown links only (no wikilinks, no absolute or file:
paths); targets must exist; `#anchor` fragments must match a heading in the
target using GitHub slug rules; notes with front matter need `type`,
`status`, `updated`, and `tags` drawn from the vocabulary in
docs/04-development/workflow.md ("Tag vocabulary" section).
"""

from __future__ import annotations

import argparse
import re
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import unquote

from .paths import PROJECT_ROOT

ROOT_DOCS = ("README.md", "AGENTS.md", "CLAUDE.md", "LICENSES.md")
VOCAB_NOTE = Path("docs/04-development/workflow.md")
REQUIRED_PROPERTIES = ("type", "status", "updated", "tags")
TEMPLATE_DIR = Path("docs/90-templates")

_FENCE_RE = re.compile(r"^(```|~~~)")
_CODE_SPAN_RE = re.compile(r"`+[^`]*`+")
_LINK_RE = re.compile(r"!?\[(?:[^\]\\]|\\.)*\]\(\s*<?([^)\s>]+)>?(?:\s+\"[^\"]*\")?\s*\)")
_REFDEF_RE = re.compile(r"^\s{0,3}\[[^\]]+\]:\s*<?(\S+?)>?(?:\s|$)")
_WIKILINK_RE = re.compile(r"\[\[[^\]]+\]\]")
_HEADING_RE = re.compile(r"^(#{1,6})\s+(.*?)\s*#*\s*$")
_DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")


@dataclass(frozen=True)
class Problem:
    path: str
    line: int
    message: str
    warning: bool = False


def slugify(heading: str) -> str:
    """GitHub-style heading anchor."""
    text = re.sub(r"<[^>]+>", "", heading)
    text = re.sub(r"[`*~]|\[([^\]]*)\]\([^)]*\)", lambda m: m.group(1) or "", text)
    text = unicodedata.normalize("NFKC", text).strip().lower()
    text = re.sub(r"[^\w\- ]", "", text)
    return text.replace(" ", "-")


def strip_code(lines: list[str]) -> list[str]:
    """Blank out fenced blocks and inline code spans, preserving line numbers."""
    result, fenced = [], False
    for line in lines:
        if _FENCE_RE.match(line.lstrip()):
            fenced = not fenced
            result.append("")
            continue
        result.append("" if fenced else _CODE_SPAN_RE.sub("", line))
    return result


def front_matter(lines: list[str]) -> tuple[dict[str, str], int]:
    if not lines or lines[0].strip() != "---":
        return {}, 0
    props: dict[str, str] = {}
    for index in range(1, len(lines)):
        if lines[index].strip() == "---":
            return props, index + 1
        if ":" in lines[index] and not lines[index].startswith((" ", "-")):
            key, value = lines[index].split(":", 1)
            props[key.strip()] = value.strip()
    return props, 0


def anchors_of(path: Path) -> set[str]:
    anchors: set[str] = set()
    counts: dict[str, int] = {}
    for line in strip_code(path.read_text(encoding="utf-8").splitlines()):
        match = _HEADING_RE.match(line)
        if not match:
            continue
        slug = slugify(match.group(2))
        n = counts.get(slug, 0)
        anchors.add(slug if n == 0 else f"{slug}-{n}")
        counts[slug] = n + 1
    return anchors


def tag_vocabulary(root: Path) -> set[str] | None:
    note = root / VOCAB_NOTE
    if not note.exists():
        return None
    vocab: set[str] = set()
    in_section = False
    for line in note.read_text(encoding="utf-8").splitlines():
        if line.startswith("#"):
            in_section = line.lstrip("#").strip().lower() == "tag vocabulary"
            continue
        if in_section:
            vocab.update(re.findall(r"^\s*-\s+`([a-z0-9/-]+)`", line))
    return vocab


def parse_tags(lines: list[str], end: int) -> list[str]:
    tags, in_tags = [], False
    for line in lines[1 : end - 1]:
        if line.startswith("tags:"):
            inline = line.split(":", 1)[1].strip()
            if inline.startswith("["):
                return [t.strip().strip("'\"") for t in inline.strip("[]").split(",") if t.strip()]
            in_tags = True
            continue
        if in_tags:
            match = re.match(r"^\s+-\s+(.+)$", line)
            if match:
                tags.append(match.group(1).strip().strip("'\""))
            else:
                in_tags = False
    return tags


def check_file(path: Path, root: Path, vocab: set[str] | None) -> tuple[list[Problem], set[Path]]:
    rel = path.relative_to(root).as_posix()
    raw_lines = path.read_text(encoding="utf-8").splitlines()
    problems: list[Problem] = []
    linked: set[Path] = set()

    props, fm_end = front_matter(raw_lines)
    in_docs = rel.startswith("docs/")
    if in_docs and fm_end:
        for key in REQUIRED_PROPERTIES:
            if key not in props:
                problems.append(Problem(rel, 1, f"front matter is missing `{key}`"))
        is_template = path.parent.relative_to(root) == TEMPLATE_DIR
        if not is_template:
            if "updated" in props and not _DATE_RE.match(props["updated"]):
                problems.append(Problem(rel, 1, f"`updated` must be YYYY-MM-DD, got {props['updated']!r}"))
            if vocab is not None:
                for tag in parse_tags(raw_lines, fm_end):
                    if tag not in vocab:
                        problems.append(Problem(rel, 1, f"tag {tag!r} is not in the vocabulary ({VOCAB_NOTE})"))

    lines = strip_code(raw_lines)
    for number, line in enumerate(lines, start=1):
        if number <= fm_end:
            continue
        if _WIKILINK_RE.search(line):
            problems.append(Problem(rel, number, "wikilink found; use a relative Markdown link"))
        targets = [m.group(1) for m in _LINK_RE.finditer(line)]
        ref = _REFDEF_RE.match(line)
        if ref:
            targets.append(ref.group(1))
        for target in targets:
            problems += check_target(path, root, rel, number, target, linked)
    return problems, linked


def check_target(path: Path, root: Path, rel: str, number: int, target: str, linked: set[Path]) -> list[Problem]:
    if re.match(r"^(https?|mailto):", target):
        return []
    if target.startswith(("file:", "/", "~")) or re.match(r"^[A-Za-z]:\\", target):
        return [Problem(rel, number, f"absolute or file link {target!r}; use a relative path")]
    file_part, _, fragment = target.partition("#")
    resolved = (path.parent / unquote(file_part)).resolve() if file_part else path.resolve()
    try:
        resolved.relative_to(root.resolve())
    except ValueError:
        return [Problem(rel, number, f"link {target!r} leaves the project")]
    if not resolved.exists():
        return [Problem(rel, number, f"broken link {target!r}")]
    linked.add(resolved)
    if fragment and resolved.suffix == ".md":
        anchors = anchors_of(resolved)
        if unquote(fragment) not in anchors and slugify(unquote(fragment)) not in anchors:
            return [Problem(rel, number, f"missing anchor #{fragment} in {resolved.relative_to(root.resolve())}")]
    return []


def collect(root: Path) -> list[Path]:
    files = [root / name for name in ROOT_DOCS if (root / name).exists()]
    docs = root / "docs"
    if docs.exists():
        files += sorted(p for p in docs.rglob("*.md") if ".obsidian" not in p.parts and ".trash" not in p.parts)
    return files


def run(root: Path) -> list[Problem]:
    vocab = tag_vocabulary(root)
    problems: list[Problem] = []
    if (root / "docs").exists() and vocab is None:
        problems.append(Problem(VOCAB_NOTE.as_posix(), 0, "tag vocabulary note is missing"))
    files = collect(root)
    linked: set[Path] = set()
    for path in files:
        found, targets = check_file(path, root, vocab)
        problems += found
        linked |= targets
    home = (root / "docs" / "00-home.md").resolve()
    for path in files:
        resolved = path.resolve()
        if resolved.is_relative_to((root / "docs").resolve()) and resolved != home and resolved not in linked:
            rel = path.relative_to(root).as_posix()
            if not rel.startswith(("docs/90-templates/", "docs/99-archive/")):
                problems.append(Problem(rel, 0, "note is not linked from any other note", warning=True))
    return problems


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="docs-check", description=__doc__.splitlines()[0])
    parser.add_argument("--root", type=Path, default=PROJECT_ROOT)
    args = parser.parse_args(argv)
    problems = run(args.root)
    errors = [p for p in problems if not p.warning]
    for problem in problems:
        kind = "warning" if problem.warning else "error"
        print(f"{problem.path}:{problem.line}: {kind}: {problem.message}")
    print(f"docs-check: {len(collect(args.root))} files, {len(errors)} error(s), "
          f"{len(problems) - len(errors)} warning(s)", file=sys.stderr if errors else sys.stdout)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
