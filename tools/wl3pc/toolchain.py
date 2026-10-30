"""Install the pinned Godot build and RGBDS into ignored local/toolchain/.

Unprivileged and project-local. Godot archives are verified against the
SHA-512 values in toolchain.lock.json before extraction. The editor runs in
self-contained mode (an `_sc_` file beside the binary), so its settings and
export templates stay under local/ instead of ~/.local/share/godot.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import urllib.request
import zipfile
from pathlib import Path
from typing import Any

from .paths import PROJECT_ROOT, TOOLCHAIN_LOCK

DOWNLOADS = PROJECT_ROOT / "local" / "toolchain" / "downloads"


def load_lock() -> dict[str, Any]:
    return json.loads(TOOLCHAIN_LOCK.read_text(encoding="utf-8"))


def godot_binary(lock: dict[str, Any] | None = None) -> Path:
    lock = lock or load_lock()
    override = os.environ.get("GODOT")
    if override:
        return Path(override)
    return PROJECT_ROOT / lock["godot"]["install_dir"] / lock["godot"]["editor"]["binary"]


def sha512_file(path: Path) -> str:
    digest = hashlib.sha512()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def fetch_verified(url: str, name: str, sha512: str) -> Path:
    DOWNLOADS.mkdir(parents=True, exist_ok=True)
    target = DOWNLOADS / name
    if target.exists() and sha512_file(target) == sha512:
        print(f"verified cached {name}")
        return target
    partial = target.with_suffix(target.suffix + ".part")
    print(f"downloading {url}")
    with urllib.request.urlopen(url) as response, open(partial, "wb") as handle:
        shutil.copyfileobj(response, handle, 1 << 20)
    actual = sha512_file(partial)
    if actual != sha512:
        partial.unlink()
        raise RuntimeError(f"{name}: SHA-512 mismatch (expected {sha512[:16]}..., got {actual[:16]}...)")
    partial.replace(target)
    print(f"verified {name}")
    return target


def install_godot() -> int:
    lock = load_lock()["godot"]
    install = PROJECT_ROOT / lock["install_dir"]
    editor_zip = fetch_verified(lock["editor"]["url"], lock["editor"]["file"], lock["editor"]["sha512"])
    templates = lock["export_templates"]
    tpz = fetch_verified(templates["url"], templates["file"], templates["sha512"])
    install.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(editor_zip) as archive:
        archive.extract(lock["editor"]["binary"], install)
    binary = install / lock["editor"]["binary"]
    binary.chmod(0o755)
    (install / "_sc_").touch()
    template_dir = install / "editor_data" / "export_templates" / templates["version_dir"]
    template_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(tpz) as archive:
        for member in templates["extract"]:
            target = template_dir / Path(member).name
            with archive.open(member) as source, open(target, "wb") as handle:
                shutil.copyfileobj(source, handle)
            if target.name != "version.txt":
                target.chmod(0o755)
    version = subprocess.run([str(binary), "--version"], capture_output=True, text=True, check=False).stdout.strip()
    if version.splitlines()[-1:] != [lock["version_string"]]:
        print(f"installed binary reports {version!r}, expected {lock['version_string']!r}", file=sys.stderr)
        return 1
    print(f"godot {version} ready at {binary}")
    return 0


def install_rgbds() -> int:
    lock = load_lock()["rgbds"]
    source = PROJECT_ROOT / "external" / "gbdev_rgbds"
    head = subprocess.run(["git", "-C", str(source), "rev-parse", "HEAD"], capture_output=True, text=True,
                          check=False).stdout.strip()
    if head != lock["commit"]:
        print(f"external/gbdev_rgbds is at {head or 'nothing'}, expected {lock['commit']}; run `make references`",
              file=sys.stderr)
        return 1
    prefix = PROJECT_ROOT / lock["install_dir"]
    jobs = str(os.cpu_count() or 1)
    for command in (["make", "-C", str(source), f"-j{jobs}"],
                    ["make", "-C", str(source), "install", f"PREFIX={prefix}"]):
        if subprocess.run(command, check=False).returncode != 0:
            print(f"failed: {' '.join(command)}", file=sys.stderr)
            return 1
    version = subprocess.run([str(prefix / "bin" / "rgbasm"), "--version"], capture_output=True, text=True,
                             check=False).stdout.strip()
    print(f"{version} ready at {prefix / 'bin'}")
    return 0 if version.endswith(lock["version"].lstrip("v")) else 1


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="toolchain", description=__doc__.splitlines()[0])
    parser.add_argument("tool", choices=["godot", "rgbds", "godot-path"])
    args = parser.parse_args(argv)
    if args.tool == "godot-path":
        print(godot_binary())
        return 0
    try:
        return install_godot() if args.tool == "godot" else install_rgbds()
    except (OSError, RuntimeError, KeyError) as error:
        print(f"toolchain: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
