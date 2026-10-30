"""Decode the per-room block function tables (block ID -> collision handler).

Question: how does the original map a room's block IDs to collision behaviour?
Evidence (ElectroDeoxys/warioland3 @560fce6, verified byte-identical to the
identified ROM): LoadRoomGfx reads a room's table index; LoadBlockFunctionTable
(home/load_room.asm) looks up BlockFunctionTablePointers and copies 256 bytes
into wBlockFunctionTable; ProcessBlock (engine/level/block_functions.asm,
bank 06) indexes that table by block ID and jumps to the handler.

Layout facts below are recorded per verified revision. Research note:
docs/02-research/first-investigation.md.
"""

from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .. import TOOLS_VERSION
from ..address import BankedAddress, RomBoundsError, RomView
from ..known_roms import WL3_WORLD_EN_JA
from ..paths import CONTENT_OUT_DIR, EDITOR_REF_DIR, rom_path_from_env
from ..provenance import ROM_DERIVED_MARKER, canonical_json, sha256_bytes, sha256_file, write_immutable
from ..rom import RomFormatError, UnknownRomError, inspect_bytes, read_rom, require_known
from ..symbols import load_sym, parse_editor_ref

FORMAT = "wl3pc.block-function-tables"
FORMAT_VERSION = 1
EXTRACTOR_VERSION = 1
DISASSEMBLY = {"repository": "ElectroDeoxys/warioland3", "commit": "560fce6faf50df4a48c0448f00105b6075f8f231"}


class MalformedDataError(ValueError):
    """Decoded data violates a structural rule taken from the original code."""


@dataclass(frozen=True)
class BlockFunctionLayout:
    rom_id: str
    # BlockFunctionTablePointers (src/data/levels/function_table_pointers.asm)
    pointer_table: BankedAddress
    # NUM_BLOCK_FUNCTION_TABLES = $62 (src/constants/room_constants.asm)
    pointer_count: int
    # LoadBlockFunctionTable: `cp NUM_BLOCK_FUNCTION_TABLES_GROUP_1 - 1; jr nc, .group_2`
    group2_first_index: int
    # Group 1 is read from BANK(BlockFunctionTablePointers); group 2 from BANK("Block Function Tables 2")
    group1_bank: int
    group2_bank: int
    # wBlockFunctionTable is `ds 2 * $80`; CopyHLToDE with b = $00 copies 256 bytes
    entries_per_table: int
    # ProcessBlock runs in bank 06 and dispatches with `jp hl`
    handler_bank: int
    # LoadBlockFunctionTable jumps to Init when the pointer's high byte is $ff (NULL = $ffff)
    reset_high_byte: int = 0xFF


WL3_WORLD_LAYOUT = BlockFunctionLayout(
    rom_id=WL3_WORLD_EN_JA.rom_id,
    pointer_table=BankedAddress(0x32, 0x4000),
    pointer_count=0x62,
    group2_first_index=0x3F,
    group1_bank=0x32,
    group2_bank=0x50,
    entries_per_table=0x80,
    handler_bank=0x06,
)


def handler_id(address: BankedAddress) -> str:
    return f"h{address.bank:02x}_{address.address:04x}"


def decode(rom: bytes, layout: BlockFunctionLayout = WL3_WORLD_LAYOUT) -> dict[str, Any]:
    """Decode every table reachable from the pointer table. Raises on any structural violation."""
    view = RomView(rom)
    try:
        pointer_bytes = view.read_banked(layout.pointer_table, 2 * layout.pointer_count)
    except RomBoundsError as error:
        raise MalformedDataError(f"pointer table: {error}") from error

    tables: list[dict[str, Any]] = []
    handlers: dict[BankedAddress, set[int]] = {}
    for index in range(layout.pointer_count):
        pointer = pointer_bytes[2 * index] | (pointer_bytes[2 * index + 1] << 8)
        if pointer >> 8 == layout.reset_high_byte:
            tables.append({"index": index, "status": "reset-sentinel", "pointer": f"{pointer:04x}"})
            continue
        bank = layout.group1_bank if index < layout.group2_first_index else layout.group2_bank
        try:
            start = BankedAddress(bank, pointer)
            raw = view.read_banked(start, 2 * layout.entries_per_table)
        except (ValueError, RomBoundsError) as error:
            raise MalformedDataError(f"table {index:#04x} pointer {pointer:#06x}: {error}") from error
        entries: list[str] = []
        for block in range(layout.entries_per_table):
            target = raw[2 * block] | (raw[2 * block + 1] << 8)
            if target >= 0x8000:
                raise MalformedDataError(
                    f"table {index:#04x} block {block:#04x}: handler {target:#06x} is not a ROM address"
                )
            resolved = BankedAddress(layout.handler_bank, 0x4000).in_same_bank(target)
            handlers.setdefault(resolved, set()).add(index)
            entries.append(handler_id(resolved))
        tables.append({"index": index, "status": "decoded", "location": str(start), "entries": entries})

    return {
        "pointer_table": str(layout.pointer_table),
        "pointer_count": layout.pointer_count,
        "entries_per_table": layout.entries_per_table,
        "tables": tables,
        "handlers": [
            {"id": handler_id(address), "location": str(address), "used_by_tables": sorted(users)}
            for address, users in sorted(handlers.items())
        ],
    }


def annotate(
    document: dict[str, Any],
    symbols: dict[BankedAddress, str] | None,
    editor_names: list[tuple[str, int]] | None,
    handler_bank: int,
) -> dict[str, Any]:
    """Attach optional local labels. Labels never change decoded values."""
    by_address = {}
    if editor_names:
        for name, address in editor_names:
            by_address.setdefault(address, []).append(name)
    for handler in document["handlers"]:
        location = BankedAddress.parse(handler["location"])
        handler["symbol"] = symbols.get(location) if symbols is not None else None
        handler["editor_names"] = sorted(by_address.get(location.address, [])) if location.bank == handler_bank else []
    audit: dict[str, Any] = {}
    if symbols is not None:
        audit["handlers_without_symbol"] = [h["id"] for h in document["handlers"] if not h["symbol"]]
    if editor_names is not None:
        used = {BankedAddress.parse(h["location"]).address for h in document["handlers"]}
        audit["editor_entries_unused_by_any_table"] = sorted(
            f"{name} ({address:04x})" for name, address in editor_names if address not in used
        )
        audit["handlers_without_editor_name"] = [h["id"] for h in document["handlers"] if not h["editor_names"]]
    document["audit"] = audit
    return document


def extract(
    rom_path: Path,
    out_dir: Path,
    sym_path: Path | None = None,
    editor_ref: Path | None = None,
    exploratory: bool = False,
) -> dict[str, Any]:
    rom = read_rom(rom_path)
    report = inspect_bytes(rom, str(rom_path))
    require_known(report, WL3_WORLD_LAYOUT.rom_id, exploratory=exploratory)
    is_exploratory = report.identity.status != "verified"

    document = decode(rom, WL3_WORLD_LAYOUT)
    symbols = load_sym(sym_path) if sym_path else None
    editor = parse_editor_ref(editor_ref.read_text(encoding="utf-8", errors="replace")) if editor_ref else None
    annotate(document, symbols, editor, WL3_WORLD_LAYOUT.handler_bank)
    document.update({
        "format": FORMAT,
        "format_version": FORMAT_VERSION,
        "marker": ROM_DERIVED_MARKER,
        "exploratory": is_exploratory,
        "provenance": {
            "rom_sha256": report.hashes.sha256,
            "rom_id": report.identity.rom_id,
            "extractor": "wl3pc.extract.block_functions",
            "extractor_version": EXTRACTOR_VERSION,
            "tools_version": TOOLS_VERSION,
            "layout_evidence": DISASSEMBLY,
            "symbol_file_sha256": sha256_file(sym_path) if sym_path else None,
            "editor_ref_sha256": sha256_file(editor_ref) if editor_ref else None,
        },
    })
    payload = canonical_json(document)
    target_dir = out_dir / ("exploratory" if is_exploratory else "wl3-original")
    filename = "block_function_tables.json"
    changed = write_immutable(target_dir / filename, payload)
    manifest = {
        "format": "wl3pc.extraction-manifest",
        "format_version": 1,
        "marker": ROM_DERIVED_MARKER,
        "rom_sha256": report.hashes.sha256,
        "files": {filename: {"sha256": sha256_bytes(payload), "format": FORMAT, "format_version": FORMAT_VERSION}},
    }
    write_immutable(target_dir / "manifest.block_function_tables.json", canonical_json(manifest))
    return {"path": str(target_dir / filename), "sha256": sha256_bytes(payload), "changed": changed,
            "document": document}


def summarise(document: dict[str, Any]) -> str:
    decoded = [t for t in document["tables"] if t["status"] == "decoded"]
    sentinels = [t for t in document["tables"] if t["status"] == "reset-sentinel"]
    lines = [
        f"tables decoded: {len(decoded)}; reset sentinels: {len(sentinels)} "
        f"(indices {sentinels[0]['index']:#04x}-{sentinels[-1]['index']:#04x})" if sentinels
        else f"tables decoded: {len(decoded)}; reset sentinels: 0",
        f"distinct handlers: {len(document['handlers'])}",
    ]
    for key, values in document.get("audit", {}).items():
        lines.append(f"{key}: {len(values)}")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="extract-block-functions", description=__doc__.splitlines()[0])
    parser.add_argument("--rom", type=Path, default=None)
    parser.add_argument("--out", type=Path, default=CONTENT_OUT_DIR)
    parser.add_argument("--symbols", type=Path, help="RGBDS .sym from a verified reference build (labels only)")
    parser.add_argument("--editor-ref", type=Path, help="WL3 Editor ref/tileEffects.txt (labels only)")
    parser.add_argument("--exploratory", action="store_true", help="allow an unidentified ROM; output is marked")
    args = parser.parse_args(argv)
    rom_path = args.rom or rom_path_from_env()
    editor_ref = args.editor_ref
    if editor_ref is None and (EDITOR_REF_DIR / "tileEffects.txt").exists():
        editor_ref = EDITOR_REF_DIR / "tileEffects.txt"
    try:
        result = extract(rom_path, args.out, args.symbols, editor_ref, args.exploratory)
    except FileNotFoundError as error:
        print(f"extract: missing input: {error.filename}", file=sys.stderr)
        return 2
    except (UnknownRomError, RomFormatError, MalformedDataError) as error:
        print(f"extract: {error}", file=sys.stderr)
        return 3
    print(f"wrote {result['path']} ({'updated' if result['changed'] else 'unchanged'}) sha256 {result['sha256']}")
    print(summarise(result["document"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
