"""Report the host, required tools, pinned toolchain, references, and inputs.

Exit 1 only when a tool required for the ROM-free workflow is missing
(Python >= 3.12, Git, Make). Everything else is reported with a fix.
"""

from __future__ import annotations

import argparse
import json
import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any

from .oracle import PYBOY_VERSION
from .paths import EDITOR_REF_DIR, PROJECT_ROOT, rom_path_from_env
from .references import load_lock as load_references, status_of
from .rom import inspect_file
from .toolchain import godot_binary, load_lock as load_toolchain


def _version(command: list[str], last_line: bool = False) -> str | None:
    if shutil.which(command[0]) is None and not Path(command[0]).exists():
        return None
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=30, check=False)
    except OSError:
        return None
    text = (result.stdout or result.stderr).strip().splitlines()
    if not text:
        return None
    return (text[-1] if last_line else text[0]).strip()


def os_release() -> str:
    try:
        for line in Path("/etc/os-release").read_text().splitlines():
            if line.startswith("PRETTY_NAME="):
                return line.split("=", 1)[1].strip('"')
    except OSError:
        pass
    return platform.platform()


def gather() -> list[dict[str, Any]]:
    lock = load_toolchain()
    checks: list[dict[str, Any]] = []

    def add(name: str, state: str, detail: str, fix: str = "", required: bool = False) -> None:
        checks.append({"name": name, "state": state, "detail": detail, "fix": fix, "required": required})

    add("host", "info", f"{os_release()}; {platform.machine()}; kernel {platform.release()}")
    py_ok = sys.version_info >= (3, 12)
    add("python", "ok" if py_ok else "missing", sys.version.split()[0], "install python3 >= 3.12", required=True)
    for tool in ("git", "make"):
        found = _version([tool, "--version"])
        add(tool, "ok" if found else "missing", found or "not found", f"sudo dnf install {tool}", required=True)
    uv = _version(["uv", "--version"])
    venv = (PROJECT_ROOT / ".venv" / "bin" / "python").exists()
    add("uv", "ok" if uv else "warn", uv or "not found", "install uv (needed for `make venv`)")
    add("venv", "ok" if venv else "warn", ".venv present" if venv else ".venv missing", "make venv")

    godot = godot_binary(lock)
    godot_version = _version([str(godot), "--version"], last_line=True) if godot.exists() else None
    expected = lock["godot"]["version_string"]
    if godot_version == expected:
        add("godot", "ok", f"{godot_version} at {godot}")
    elif godot_version:
        add("godot", "warn", f"{godot_version} at {godot}; lock expects {expected}",
            "unset GODOT or run `make godot`")
    else:
        add("godot", "warn", f"not installed at {godot}", "make godot")
    templates = (PROJECT_ROOT / lock["godot"]["install_dir"] / "editor_data" / "export_templates"
                 / lock["godot"]["export_templates"]["version_dir"] / "linux_release.x86_64")
    add("godot export templates", "ok" if templates.exists() else "warn",
        "Linux x86_64 templates present" if templates.exists() else "missing", "make godot")

    rgbasm = PROJECT_ROOT / lock["rgbds"]["install_dir"] / "bin" / "rgbasm"
    rgb_version = _version([str(rgbasm), "--version"]) if rgbasm.exists() else None
    add("rgbds (reference build only)", "ok" if rgb_version else "warn", rgb_version or "not built", "make rgbds")
    java = _version(["java", "-version"])
    add("java (WL3 Editor only)", "ok" if java else "warn", java or "not found", "optional")
    oracle_py = os.environ.get("ORACLE_PY", "/usr/bin/python3")
    pyboy = _version([oracle_py, "-W", "ignore", "-c",
                      "import importlib.metadata as m; print('PyBoy', m.version('pyboy'))"], last_line=True)
    pyboy_ok = pyboy == f"PyBoy {PYBOY_VERSION}"
    add("pyboy (emulator oracle only)", "ok" if pyboy_ok else "warn",
        f"{pyboy or 'not importable'} via {oracle_py}" + ("" if pyboy_ok else f"; pinned {PYBOY_VERSION}"),
        f"install PyBoy {PYBOY_VERSION} for {oracle_py}, or set ORACLE_PY")

    for ref in load_references():
        info = status_of(ref)
        if info["state"] == "missing":
            add(f"ref {ref['id']}", "warn", "missing", "make references")
        else:
            dirty = ", modified" if info["dirty"] else ""
            state = "ok" if info["state"] == "pinned" and not info["dirty"] else "warn"
            add(f"ref {ref['id']}", state, f"{info['state']}{dirty} @ {info['head'][:12]}", "see docs/02-research/sources.md")

    rom = rom_path_from_env()
    if rom.exists():
        try:
            report = inspect_file(rom)
            add("rom", "ok" if report.identity.status == "verified" else "warn",
                f"{report.identity.status} {report.identity.rom_id or ''} sha256 {report.hashes.sha256[:16]}...")
        except (OSError, ValueError) as error:
            add("rom", "warn", f"unreadable: {error}")
    else:
        add("rom", "info", f"not present at {rom} (ROM-free workflow still works)")
    editor_ref = EDITOR_REF_DIR.exists()
    add("editor ref", "ok" if editor_ref else "info", "WL3 Editor/ref present" if editor_ref else "absent")
    return checks


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="doctor", description=__doc__.splitlines()[0])
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)
    checks = gather()
    if args.json:
        print(json.dumps(checks, indent=2))
    else:
        for check in checks:
            fix = f"  -> {check['fix']}" if check["state"] in ("warn", "missing") and check["fix"] else ""
            print(f"[{check['state']:<7}] {check['name']:<30} {check['detail']}{fix}")
    return 1 if any(c["required"] and c["state"] == "missing" for c in checks) else 0


if __name__ == "__main__":
    sys.exit(main())
