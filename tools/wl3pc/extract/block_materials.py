"""Map each block function table's handlers to runtime materials (WL3-011).

The tracked mapping (tools/wl3pc/data/block_handler_materials.v1.json) is a
project-original reading of the handlers in src/engine/level/block_functions.asm
(ElectroDeoxys/warioland3 @560fce6). This step applies it to the tables decoded
from the ROM. A block whose handler has no row becomes `unknown`, never `empty`;
the runtime refuses `unknown`. Research note: docs/02-research/block-handlers.md.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from .. import TOOLS_VERSION
from ..paths import CONTENT_OUT_DIR, rom_path_from_env
from ..provenance import ROM_DERIVED_MARKER, canonical_json, sha256_bytes, sha256_file, write_immutable
from ..rom import RomFormatError, UnknownRomError, inspect_bytes, read_rom, require_known
from . import block_functions as bf
from .block_functions import MalformedDataError

FORMAT = "wl3pc.block-materials"
FORMAT_VERSION = 1
EXTRACTOR_VERSION = 1
MAPPING_FORMAT = "wl3pc.block-handler-materials"
MAPPING_PATH = Path(__file__).resolve().parents[1] / "data" / "block_handler_materials.v1.json"
UNKNOWN = "unknown"

# Flags that need an extra value on the row, and the key that carries it.
_VALUE_FLAGS = {"room-transition": "room_transition", "door": "room_transition"}
_BREAKABLE_PREFIX = "breakable-"
_ID_RE = re.compile(r"^h[0-9a-f]{2}_[0-9a-f]{4}$")


class MappingError(ValueError):
    """The handler mapping breaks one of its own rules."""


def check_mapping(mapping: dict[str, Any]) -> None:
    """Semantic rules the JSON schema cannot express. Raises MappingError."""
    if mapping.get("format") != MAPPING_FORMAT or mapping.get("format_version") != 1:
        raise MappingError("not a wl3pc.block-handler-materials v1 mapping")
    materials, flags = mapping["materials"], mapping["flags"]
    if UNKNOWN in materials:
        raise MappingError("`unknown` is reserved for handlers without a row")
    seen: set[str] = set()
    for row in mapping["handlers"]:
        where = f"handler {row.get('id')!r}"
        if not _ID_RE.match(row["id"]):
            raise MappingError(f"{where}: malformed id")
        if row["id"] in seen:
            raise MappingError(f"{where}: duplicate row")
        seen.add(row["id"])
        if row["material"] not in materials:
            raise MappingError(f"{where}: material {row['material']!r} is not defined")
        if not row.get("evidence"):
            raise MappingError(f"{where}: no evidence")
        for flag in row["flags"]:
            if flag not in flags:
                raise MappingError(f"{where}: flag {flag!r} is not defined")
        needs_transition = any(flag in _VALUE_FLAGS for flag in row["flags"])
        if needs_transition != ("room_transition" in row):
            raise MappingError(f"{where}: room_transition must be present exactly when a door or "
                               "room-transition flag is")
        breakable = any(flag.startswith(_BREAKABLE_PREFIX) for flag in row["flags"])
        if breakable != ("replacement_block" in row):
            raise MappingError(f"{where}: replacement_block must be present exactly when a breakable flag is")


def load_mapping(path: Path = MAPPING_PATH) -> dict[str, Any]:
    mapping = json.loads(path.read_text(encoding="utf-8"))
    check_mapping(mapping)
    return mapping


def _block(row: dict[str, Any] | None) -> dict[str, Any]:
    if row is None:
        return {"material": UNKNOWN, "flags": []}
    block = {"material": row["material"], "flags": list(row["flags"])}
    for key in ("replacement_block", "room_transition"):
        if key in row:
            block[key] = row[key]
    return block


def apply(tables_document: dict[str, Any], mapping: dict[str, Any]) -> dict[str, Any]:
    """Turn decoded tables (block_functions.decode output) into per-block materials."""
    rows = {row["id"]: row for row in mapping["handlers"]}
    tables: list[dict[str, Any]] = []
    used: set[str] = set()
    for table in tables_document["tables"]:
        if table["status"] != "decoded":
            tables.append({"index": table["index"], "status": table["status"]})
            continue
        used.update(table["entries"])
        blocks = [_block(rows.get(handler)) for handler in table["entries"]]
        tables.append({
            "index": table["index"],
            "status": "decoded",
            "unknown_blocks": sum(block["material"] == UNKNOWN for block in blocks),
            "blocks": blocks,
        })
    return {
        "entries_per_table": tables_document["entries_per_table"],
        "tables": tables,
        "audit": {
            "unmapped_handlers_used": sorted(used - rows.keys()),
            "mapped_handlers_not_found": sorted(rows.keys() - used),
            "tables_fully_mapped": [t["index"] for t in tables if t["status"] == "decoded" and not t["unknown_blocks"]],
        },
    }


def extract(
    rom_path: Path,
    out_dir: Path,
    mapping_path: Path = MAPPING_PATH,
    exploratory: bool = False,
) -> dict[str, Any]:
    rom = read_rom(rom_path)
    report = inspect_bytes(rom, str(rom_path))
    require_known(report, bf.WL3_WORLD_LAYOUT.rom_id, exploratory=exploratory)
    is_exploratory = report.identity.status != "verified"

    document = apply(bf.decode(rom, bf.WL3_WORLD_LAYOUT), load_mapping(mapping_path))
    document.update({
        "format": FORMAT,
        "format_version": FORMAT_VERSION,
        "marker": ROM_DERIVED_MARKER,
        "exploratory": is_exploratory,
        "provenance": {
            "rom_sha256": report.hashes.sha256,
            "rom_id": report.identity.rom_id,
            "extractor": "wl3pc.extract.block_materials",
            "extractor_version": EXTRACTOR_VERSION,
            "tools_version": TOOLS_VERSION,
            "layout_evidence": bf.DISASSEMBLY,
            "mapping_sha256": sha256_file(mapping_path),
        },
    })
    payload = canonical_json(document)
    target_dir = out_dir / ("exploratory" if is_exploratory else "wl3-original")
    filename = "block_materials.json"
    changed = write_immutable(target_dir / filename, payload)
    manifest = {
        "format": "wl3pc.extraction-manifest",
        "format_version": 1,
        "marker": ROM_DERIVED_MARKER,
        "rom_sha256": report.hashes.sha256,
        "files": {filename: {"sha256": sha256_bytes(payload), "format": FORMAT, "format_version": FORMAT_VERSION}},
    }
    write_immutable(target_dir / "manifest.block_materials.json", canonical_json(manifest))
    return {"path": str(target_dir / filename), "sha256": sha256_bytes(payload), "changed": changed,
            "document": document}


def summarise(document: dict[str, Any]) -> str:
    decoded = [t for t in document["tables"] if t["status"] == "decoded"]
    audit = document["audit"]
    unknown = sum(t["unknown_blocks"] for t in decoded)
    return "\n".join([
        f"tables: {len(decoded)}; blocks mapped: {len(decoded) * document['entries_per_table'] - unknown}; "
        f"unknown: {unknown}",
        f"tables fully mapped: {len(audit['tables_fully_mapped'])} "
        f"({', '.join(f'{i:#04x}' for i in audit['tables_fully_mapped']) or 'none'})",
        f"handlers used but unmapped: {len(audit['unmapped_handlers_used'])}",
        f"mapped handlers not found in the ROM: {len(audit['mapped_handlers_not_found'])}",
    ])


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="extract-block-materials", description=__doc__.splitlines()[0])
    parser.add_argument("--rom", type=Path, default=None)
    parser.add_argument("--out", type=Path, default=CONTENT_OUT_DIR)
    parser.add_argument("--mapping", type=Path, default=MAPPING_PATH)
    parser.add_argument("--exploratory", action="store_true", help="allow an unidentified ROM; output is marked")
    args = parser.parse_args(argv)
    rom_path = args.rom or rom_path_from_env()
    try:
        result = extract(rom_path, args.out, args.mapping, args.exploratory)
    except FileNotFoundError as error:
        print(f"extract: missing input: {error.filename}", file=sys.stderr)
        return 2
    except (UnknownRomError, RomFormatError, MalformedDataError, MappingError) as error:
        print(f"extract: {error}", file=sys.stderr)
        return 3
    print(f"wrote {result['path']} ({'updated' if result['changed'] else 'unchanged'}) sha256 {result['sha256']}")
    print(summarise(result["document"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
