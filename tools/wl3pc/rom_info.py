"""Inspect a ROM image read-only and report header, hashes, and identity.

Exit codes: 0 inspected; 2 unreadable or not a cartridge image;
3 --require-known was given and the ROM is not a verified revision.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from .paths import rom_path_from_env
from .rom import RomFormatError, RomReport, inspect_file


def format_text(report: RomReport) -> str:
    h = report.header
    lines = [
        f"path:            {report.path}",
        f"size:            {report.size} bytes",
        f"sha256:          {report.hashes.sha256}",
        f"sha1 (legacy):   {report.hashes.sha1}",
        f"md5 (legacy):    {report.hashes.md5}",
        f"title:           {h.title!r}  manufacturer {h.manufacturer_code!r}",
        f"cgb:             {h.cgb_flag:#04x} {h.cgb_mode}",
        f"cartridge:       {h.cartridge_type:#04x} {h.cartridge_type_name}",
        f"rom size:        code {h.rom_size_code:#04x} -> {h.rom_size_declared}",
        f"ram size:        code {h.ram_size_code:#04x} -> {h.ram_size_declared}",
        f"destination:     {h.destination_code:#04x} {h.destination}",
        f"licensee:        new {h.new_licensee_code!r} old {h.old_licensee_code:#04x}  version {h.mask_rom_version}",
        f"boot logo:       {'matches' if h.logo_matches_boot_logo else 'MISMATCH'}",
        f"header checksum: stored {h.header_checksum_stored:#04x} computed {h.header_checksum_computed:#04x} "
        f"{'OK' if h.header_checksum_valid else 'BAD'}",
        f"global checksum: stored {h.global_checksum_stored:#06x} computed {h.global_checksum_computed:#06x} "
        f"{'OK' if h.global_checksum_valid else 'BAD'}",
        f"identity:        {report.identity.status}"
        + (f" ({report.identity.rom_id}: {report.identity.name})" if report.identity.rom_id else ""),
    ]
    lines += [f"  evidence: {item}" for item in report.identity.evidence]
    lines.append(
        "extraction:      "
        + ("allowed for this revision" if report.identity.status == "verified"
           else "refused (unknown revision; only --exploratory runs are possible)")
    )
    lines += [f"warning:         {item}" for item in report.warnings]
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="rom-info", description=__doc__.splitlines()[0])
    parser.add_argument("rom", nargs="?", type=Path, help="ROM path (default: $WL3PC_ROM or Original_ROM/...)")
    parser.add_argument("--json", action="store_true", help="emit structured JSON")
    parser.add_argument("--require-known", action="store_true", help="exit 3 unless the ROM is a verified revision")
    args = parser.parse_args(argv)
    path: Path = args.rom or rom_path_from_env()
    try:
        report = inspect_file(path)
    except FileNotFoundError:
        print(f"rom-info: no file at {path}. Pass a path or set WL3PC_ROM.", file=sys.stderr)
        return 2
    except (OSError, RomFormatError) as error:
        print(f"rom-info: {path}: {error}", file=sys.stderr)
        return 2
    print(json.dumps(report.to_dict(), indent=2, sort_keys=True) if args.json else format_text(report))
    if args.require_known and report.identity.status != "verified":
        print("rom-info: ROM is not a verified revision", file=sys.stderr)
        return 3
    return 0


if __name__ == "__main__":
    sys.exit(main())
