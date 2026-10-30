"""Report or fetch the pinned reference checkouts listed in references.lock.json.

`fetch` clones missing checkouts and detaches them at the pinned commit. It
never resets, cleans, or moves a checkout that has local modifications, and it
only moves a clean checkout at a different commit when --checkout is given.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

from .paths import PROJECT_ROOT, REFERENCES_LOCK


def load_lock(path: Path = REFERENCES_LOCK) -> list[dict[str, Any]]:
    return json.loads(path.read_text(encoding="utf-8"))["references"]


def _git(path: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["git", "-C", str(path), *args], capture_output=True, text=True, check=False)


def status_of(ref: dict[str, Any], root: Path = PROJECT_ROOT) -> dict[str, Any]:
    path = root / ref["path"]
    if not (path / ".git").exists():
        return {"id": ref["id"], "state": "missing", "path": ref["path"]}
    head = _git(path, "rev-parse", "HEAD").stdout.strip()
    dirty = bool(_git(path, "status", "--porcelain", "--untracked-files=normal").stdout.strip())
    state = "pinned" if head == ref["commit"] else "different-commit"
    return {"id": ref["id"], "state": state, "dirty": dirty, "head": head, "expected": ref["commit"],
            "path": ref["path"]}


def fetch(ref: dict[str, Any], root: Path, allow_checkout: bool) -> str:
    current = status_of(ref, root)
    path = root / ref["path"]
    if current["state"] == "missing":
        if path.exists() and any(path.iterdir()):
            return f"{ref['id']}: {ref['path']} exists but is not a Git checkout; left untouched"
        path.parent.mkdir(parents=True, exist_ok=True)
        clone = subprocess.run(["git", "clone", "--quiet", "--no-checkout", ref["url"], str(path)],
                               capture_output=True, text=True, check=False)
        if clone.returncode != 0:
            return f"{ref['id']}: clone failed: {clone.stderr.strip()}"
        checkout = _git(path, "checkout", "--quiet", "--detach", ref["commit"])
        if checkout.returncode != 0:
            return f"{ref['id']}: pinned commit not available: {checkout.stderr.strip()}"
        return f"{ref['id']}: cloned at {ref['commit']}"
    if current["state"] == "pinned":
        return f"{ref['id']}: already pinned" + (" (has local modifications; left as is)" if current["dirty"] else "")
    if current["dirty"]:
        return f"{ref['id']}: at {current['head']} with local modifications; refusing to move it"
    if not allow_checkout:
        return f"{ref['id']}: clean but at {current['head']}; rerun with --checkout to detach at the pinned commit"
    _git(path, "fetch", "--quiet", "origin")
    checkout = _git(path, "checkout", "--quiet", "--detach", ref["commit"])
    if checkout.returncode != 0:
        return f"{ref['id']}: checkout failed: {checkout.stderr.strip()}"
    return f"{ref['id']}: detached at {ref['commit']}"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="references", description=__doc__.splitlines()[0])
    parser.add_argument("command", choices=["status", "fetch"])
    parser.add_argument("--checkout", action="store_true", help="allow moving a clean checkout to the pinned commit")
    args = parser.parse_args(argv)
    refs = load_lock()
    if args.command == "fetch":
        for ref in refs:
            print(fetch(ref, PROJECT_ROOT, args.checkout))
    problems = 0
    for ref in refs:
        info = status_of(ref)
        if info["state"] == "missing":
            print(f"{info['id']:<26} missing ({info['path']}); run `make references`")
            problems += 1
            continue
        flag = " DIRTY" if info["dirty"] else ""
        if info["state"] != "pinned":
            problems += 1
        print(f"{info['id']:<26} {info['state']}{flag} {info['head'][:12]}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
