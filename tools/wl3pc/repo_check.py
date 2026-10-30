"""Refuse protected inputs, ROM payloads, and generated files in the Git index.

Checks every index entry (tracked plus staged) by path and by the content
stored in the index, not the working tree. Passing is necessary, not
sufficient: a transformed derivative (for example a decoded PNG) can still
carry original content without matching any rule here.

Exit codes: 0 clean, 1 findings, 2 cannot run (not a Git repository, etc.).
"""

from __future__ import annotations

import argparse
import hashlib
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path, PurePosixPath

from .known_roms import LOGO_SHA256
from .paths import DEFAULT_ROM, PROJECT_ROOT
from .provenance import ROM_DERIVED_MARKER

PROTECTED_PREFIXES = (
    "Original_ROM/", "WL3 Editor/", "external/", "local/", "build/", "dist/",
    ".venv/", "game/.godot/", "docs/.trash/", ".claude/settings.local.json",
)
FORBIDDEN_SUFFIXES = {
    # ROMs, saves, emulator state
    ".gb", ".gbc", ".sgb", ".sav", ".srm", ".rtc", ".state",
    # build and toolchain outputs
    ".o", ".sym", ".2bpp", ".1bpp", ".rle", ".pck", ".tpz", ".x86_64", ".exe", ".so", ".dll",
    ".pyc", ".jar", ".zip", ".7z",
}
FORBIDDEN_PARTS = {"__pycache__", ".pytest_cache", ".godot"}
OBSIDIAN_ALLOWED = {"app.json", "appearance.json", "core-plugins.json", "templates.json"}
BINARY_ALLOWED_SUFFIXES = {".png", ".ogg", ".wav", ".ttf", ".otf", ".woff2"}
MAX_BLOB_BYTES = 2 * 1024 * 1024
FRAGMENT = 32  # aligned window size; any copied run of >= 2*FRAGMENT-1 bytes contains one
MIN_DISTINCT = 8  # skip low-entropy windows (padding, fills) to avoid false positives


@dataclass(frozen=True)
class Finding:
    path: str
    reason: str


def _git(root: Path, *args: str, data: bytes | None = None) -> bytes:
    result = subprocess.run(["git", "-C", str(root), *args], input=data, capture_output=True, check=False)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.decode(errors="replace").strip() or f"git {' '.join(args)} failed")
    return result.stdout


def index_entries(root: Path) -> list[tuple[str, str, str]]:
    """Return (mode, blob sha, path) for each index entry. Paths may contain spaces."""
    entries = []
    for record in _git(root, "ls-files", "--stage", "-z").split(b"\0"):
        if not record:
            continue
        meta, path = record.split(b"\t", 1)
        mode, sha, _stage = meta.decode().split(" ")
        entries.append((mode, sha, path.decode("utf-8", errors="surrogateescape")))
    return entries


def read_blobs(root: Path, shas: list[str]) -> dict[str, bytes]:
    if not shas:
        return {}
    out = _git(root, "cat-file", "--batch", data=("\n".join(shas) + "\n").encode())
    blobs: dict[str, bytes] = {}
    pos = 0
    for sha in shas:
        header_end = out.index(b"\n", pos)
        header = out[pos:header_end].decode().split(" ")
        size = int(header[2])
        start = header_end + 1
        blobs[sha] = out[start : start + size]
        pos = start + size + 1
    return blobs


def check_path(path: str, mode: str = "100644") -> list[str]:
    reasons = []
    pure = PurePosixPath(path)
    if any(path.startswith(prefix) for prefix in PROTECTED_PREFIXES):
        reasons.append("protected or ignored location")
    if pure.suffix.lower() in FORBIDDEN_SUFFIXES:
        reasons.append(f"forbidden file type {pure.suffix}")
    if FORBIDDEN_PARTS.intersection(pure.parts[:-1]):
        reasons.append("generated cache directory")
    if path.startswith("docs/.obsidian/") and pure.name not in OBSIDIAN_ALLOWED:
        reasons.append("Obsidian file outside the shared-config allowlist")
    if mode == "160000":
        reasons.append("submodule entries are not allowed")
    return reasons


def looks_like_gb_rom(blob: bytes) -> bool:
    if len(blob) < 0x150:
        return False
    if hashlib.sha256(blob[0x104:0x134]).hexdigest() == LOGO_SHA256:
        return True
    checksum = 0
    for byte in blob[0x134:0x14D]:
        checksum = (checksum - byte - 1) & 0xFF
    size_ok = len(blob) >= 0x8000 and (len(blob) & (len(blob) - 1)) == 0
    return size_ok and checksum == blob[0x14D]


def rom_fragments(rom: bytes) -> set[bytes]:
    windows = set()
    for offset in range(0, len(rom) - FRAGMENT + 1, FRAGMENT):
        window = rom[offset : offset + FRAGMENT]
        if len(set(window)) >= MIN_DISTINCT:
            windows.add(window)
    return windows


def contains_fragment(blob: bytes, fragments: set[bytes]) -> int | None:
    for offset in range(0, len(blob) - FRAGMENT + 1):
        if blob[offset : offset + FRAGMENT] in fragments:
            return offset
    return None


def check_content(path: str, blob: bytes, fragments: set[bytes]) -> list[str]:
    reasons = []
    if len(blob) > MAX_BLOB_BYTES:
        reasons.append(f"blob is {len(blob)} bytes (limit {MAX_BLOB_BYTES})")
    if ROM_DERIVED_MARKER.encode() in blob:
        reasons.append("contains the ROM-derived content marker")
    if b"\0" in blob[:8192] and PurePosixPath(path).suffix.lower() not in BINARY_ALLOWED_SUFFIXES:
        reasons.append("unexpected binary content")
    if looks_like_gb_rom(blob):
        reasons.append("content looks like a Game Boy ROM image")
    if fragments and len(blob) <= MAX_BLOB_BYTES:
        hit = contains_fragment(blob, fragments)
        if hit is not None:
            reasons.append(f"contains bytes copied from a local ROM (at offset {hit:#x})")
    return reasons


def run(root: Path, rom_paths: list[Path]) -> list[Finding]:
    fragments: set[bytes] = set()
    for rom_path in rom_paths:
        with open(rom_path, "rb") as handle:
            fragments |= rom_fragments(handle.read())
    entries = index_entries(root)
    blobs = read_blobs(root, sorted({sha for mode, sha, _ in entries if mode != "160000"}))
    findings = []
    for mode, sha, path in entries:
        reasons = check_path(path, mode)
        if mode != "160000":
            reasons += check_content(path, blobs[sha], fragments)
        findings += [Finding(path, reason) for reason in reasons]
    return findings


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="repo-check", description=__doc__.splitlines()[0])
    parser.add_argument("--root", type=Path, default=PROJECT_ROOT)
    parser.add_argument("--rom", type=Path, action="append", default=None,
                        help="local ROM to scan for copied fragments (default: the original ROM if present)")
    parser.add_argument("--no-rom", action="store_true", help="skip the fragment scan")
    args = parser.parse_args(argv)
    roms: list[Path] = [] if args.no_rom else (args.rom or ([DEFAULT_ROM] if DEFAULT_ROM.exists() else []))
    try:
        findings = run(args.root, roms)
    except (RuntimeError, OSError) as error:
        print(f"repo-check: cannot run: {error}", file=sys.stderr)
        return 2
    entries = len(index_entries(args.root))
    scope = f"{entries} index entries; ROM fragment scan {'on' if roms else 'off'}"
    if findings:
        for finding in findings:
            print(f"repo-check: {finding.path!r}: {finding.reason}")
        print(f"repo-check: FAILED with {len(findings)} finding(s) ({scope})", file=sys.stderr)
        return 1
    print(f"repo-check: OK ({scope})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
