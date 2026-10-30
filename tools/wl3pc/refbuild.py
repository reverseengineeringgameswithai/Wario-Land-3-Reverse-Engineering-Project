"""Rebuild the pinned disassembly in build/refbuild and compare it with the identified ROM.

A matching build shows the source tree reproduces this revision byte for byte.
It does not show that the code is understood: INCBIN'd binaries are copied,
not explained. The original ROM is only read for comparison.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

from .known_roms import WL3_WORLD_EN_JA
from .paths import BUILD_DIR, PROJECT_ROOT, rom_path_from_env
from .provenance import canonical_json, sha256_file
from .references import load_lock as load_references
from .toolchain import load_lock as load_toolchain


def count_incbins(src: Path) -> dict[str, int]:
    counts: dict[str, int] = {}
    for asm in src.rglob("*.asm"):
        for match in re.finditer(r'INCBIN\s+"[^"]+\.([A-Za-z0-9]+)"', asm.read_text(errors="replace")):
            counts[match.group(1)] = counts.get(match.group(1), 0) + 1
    return dict(sorted(counts.items()))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="refbuild", description=__doc__.splitlines()[0])
    parser.parse_args(argv)
    ref = next(r for r in load_references() if r["id"] == "electrodeoxys-warioland3")
    rgbds_bin = PROJECT_ROOT / load_toolchain()["rgbds"]["install_dir"] / "bin"
    source = PROJECT_ROOT / ref["path"]
    if not (rgbds_bin / "rgbasm").exists():
        print("refbuild: RGBDS not installed; run `make rgbds`", file=sys.stderr)
        return 2
    if not (source / ".git").exists():
        print(f"refbuild: {ref['path']} missing; run `make references`", file=sys.stderr)
        return 2
    work = BUILD_DIR / "refbuild" / f"electrodeoxys-{ref['commit'][:7]}"
    if work.exists():
        shutil.rmtree(work)
    work.parent.mkdir(parents=True, exist_ok=True)
    for command in (["git", "clone", "--quiet", "--no-hardlinks", "--no-checkout", str(source), str(work)],
                    ["git", "-C", str(work), "checkout", "--quiet", "--detach", ref["commit"]]):
        if subprocess.run(command, check=False).returncode != 0:
            print(f"refbuild: failed: {' '.join(command)}", file=sys.stderr)
            return 2
    log_path = work.parent / f"electrodeoxys-{ref['commit'][:7]}.log"
    with open(log_path, "w") as log:
        built = subprocess.run(["make", "-C", str(work), f"RGBDS={rgbds_bin}/", "DEBUG=1", "warioland3.gbc"],
                               stdout=log, stderr=subprocess.STDOUT, check=False)
    output = work / "warioland3.gbc"
    if built.returncode != 0 or not output.exists():
        print(f"refbuild: build failed; see {log_path}", file=sys.stderr)
        return 1
    built_sha = sha256_file(output)
    rom_path = rom_path_from_env()
    report = {
        "reference": ref["id"],
        "commit": ref["commit"],
        "rgbds": load_toolchain()["rgbds"]["version"],
        "output_sha256": built_sha,
        "expected_sha256": WL3_WORLD_EN_JA.sha256,
        "matches_identified_revision": built_sha == WL3_WORLD_EN_JA.sha256,
        "local_rom_byte_identical": (output.read_bytes() == rom_path.read_bytes()) if rom_path.exists() else None,
        "incbin_counts_by_extension": count_incbins(work / "src"),
        "symbols": str((work / "warioland3.sym").relative_to(PROJECT_ROOT)),
    }
    (work.parent / "report.json").write_bytes(canonical_json(report))
    print(json.dumps(report, indent=2))
    return 0 if report["matches_identified_revision"] else 1


if __name__ == "__main__":
    sys.exit(main())
