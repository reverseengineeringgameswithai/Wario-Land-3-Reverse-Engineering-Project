"""Decode the per-level block maps and object maps (one cell per 16x16 block of a whole level).

Question: which block IDs make up each level, and how are they laid out?
Evidence (ElectroDeoxys/warioland3 @560fce6, verified byte-identical to the
identified ROM): LoadLevelBlockMapAndObjects (00:0e8a, home/load_level.asm)
reads LevelBlockAndObjectMaps[wLevel] with bank $30 mapped, resets when the
pointer's high byte is $ff, and reads a 5-byte record: the block map as `dab`
(pointer, then bank) and the object map pointer in the same bank.
DecompressLevelBlockMap (00:0ab5, home/decompress_level_data.asm) expands the
block map with the same run/literal scheme as Decompress, writing LEVEL_WIDTH
bytes per row. Each row starts on a new 256-byte SRAM page from
sLevelBlockObjectMap (01:a000). DecompressLevelObjectMap writes the object map
the same way, LEVEL_WIDTH / 2 bytes per row from offset $b0 of each page, one
nibble per block (high nibble first). SetWarioPositionToSpawn
(02:4a41, engine/level/start_room.asm) finds the spawn as the first $f nibble.

Layout facts below are recorded per verified revision. Research note:
docs/02-research/level-block-maps.md.
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
from ..paths import CONTENT_OUT_DIR, rom_path_from_env
from ..provenance import ROM_DERIVED_MARKER, canonical_json, sha256_bytes, sha256_file, write_immutable
from ..rom import RomFormatError, UnknownRomError, inspect_bytes, read_rom, require_known
from ..symbols import load_sym
from . import block_functions as bf
from .block_functions import MalformedDataError
from .rle import DecompressError, decompress

FORMAT = "wl3pc.level-block-maps"
FORMAT_VERSION = 2
EXTRACTOR_VERSION = 2
SECTION_BLOCKS = 16  # one high byte of a pixel position, at 16 px per block
SPAWN_NIBBLE = 0x0F  # SetWarioPositionToSpawn: `cp $0f / jr nc, .found_spawn_block`


@dataclass(frozen=True)
class LevelMapLayout:
    rom_id: str
    # LevelBlockAndObjectMaps (src/data/levels/level_maps.asm), read with BANK(LevelBlockAndObjectMaps) mapped
    pointer_table: BankedAddress
    # OUT_OF_THE_WOODS_DAY_1 ($00) to THE_TEMPLE ($c8); 13 NULLs follow
    level_count: int
    # LEVEL_WIDTH = 160 blocks (src/constants/level_constants.asm); .Decompress starts a row when e == LEVEL_WIDTH
    row_width: int
    # DecompressLevelObjectMap: (LEVEL_WIDTH / 2) bytes per row, written from page offset $b0
    object_row_width: int
    # Rows are 256 bytes apart from sLevelBlockObjectMap (01:a000), 32 per 8 KiB SRAM bank. The cart has 4 SRAM
    # banks (header RAM code $03) and the map starts in bank 1, so at most 3 * 32 rows fit.
    max_rows: int
    # `dab` block map (2-byte pointer + bank), then `dw` object map in the same bank
    record_size: int = 5
    # LoadLevelBlockMapAndObjects: `ld a, h / inc a / jr z, InvalidLevelData` (jp Init)
    reset_high_byte: int = 0xFF


WL3_WORLD_MAP_LAYOUT = LevelMapLayout(
    rom_id=WL3_WORLD_EN_JA.rom_id,
    pointer_table=BankedAddress(0x30, 0x40BE),
    level_count=0xC9,
    row_width=160,
    object_row_width=80,
    max_rows=96,
)


def _read(view: RomView, start: BankedAddress, length: int, what: str) -> bytes:
    try:
        return view.read_banked(start, length)
    except RomBoundsError as error:
        raise MalformedDataError(f"{what}: {error}") from error


def _resolve(bank: int, pointer: int, what: str) -> BankedAddress:
    try:
        return BankedAddress(bank, 0x4000).in_same_bank(pointer)
    except ValueError as error:
        raise MalformedDataError(f"{what}: pointer {pointer:#06x} is not a ROM address") from error


def _expand(view: RomView, start: BankedAddress, width: int, max_rows: int, what: str) -> dict[str, Any]:
    try:
        output, compressed = decompress(view, start, max_rows * width)
    except DecompressError as error:
        raise MalformedDataError(f"{what}: {error}") from error
    rows = [output[i:i + width] for i in range(0, len(output), width)]
    return {
        "output": output,
        "compressed_bytes": compressed,
        "bytes": len(output),
        "rows": len(rows),
        # The original leaves the rest of an unfinished row as it was in SRAM.
        "incomplete_final_row": len(output) % width != 0,
        "hex_rows": [row.hex() for row in rows],
    }


def decode(rom: bytes, layout: LevelMapLayout = WL3_WORLD_MAP_LAYOUT) -> dict[str, Any]:
    """Decode every level's block map. Raises on any structural violation."""
    view = RomView(rom)
    raw = _read(view, layout.pointer_table, 2 * layout.level_count, "level map pointer table")
    table_bank = layout.pointer_table.bank

    levels: list[dict[str, Any]] = []
    maps: dict[BankedAddress, dict[str, Any]] = {}
    for level in range(layout.level_count):
        pointer = raw[2 * level] | (raw[2 * level + 1] << 8)
        if pointer >> 8 == layout.reset_high_byte:
            levels.append({"level": level, "status": "reset-sentinel", "pointer": f"{pointer:04x}"})
            continue
        what = f"level {level:#04x}"
        record = _resolve(table_bank, pointer, what)
        fields = _read(view, record, layout.record_size, f"{what} record")
        data_bank = fields[2]
        if data_bank == 0:
            # MBC5 can map ROM bank 0 at $4000-$7fff; nothing in this ROM does, so it is refused, not guessed.
            raise MalformedDataError(f"{what} record: data bank $00 is not modelled")
        block_map = _resolve(data_bank, fields[0] | (fields[1] << 8), f"{what} block map")
        object_map = _resolve(data_bank, fields[3] | (fields[4] << 8), f"{what} object map")
        if block_map not in maps:
            blocks = _expand(view, block_map, layout.row_width, layout.max_rows, f"{what} block map")
            objects = _expand(view, object_map, layout.object_row_width, layout.max_rows, f"{what} object map")
            maps[block_map] = {
                "location": str(block_map),
                "record": str(record),
                "object_map": str(object_map),
                "used_by_levels": [],
                "compressed_bytes": blocks["compressed_bytes"],
                "bytes": blocks["bytes"],
                "rows": blocks["rows"],
                "incomplete_final_row": blocks["incomplete_final_row"],
                # ProcessBlock doubles the byte with `add a`, so bit 7 never reaches the table index.
                "blocks_with_bit7": sum(byte >= 0x80 for byte in blocks["output"]),
                "block_rows": blocks["hex_rows"],
                "object_compressed_bytes": objects["compressed_bytes"],
                "object_bytes": objects["bytes"],
                "object_incomplete_final_row": objects["incomplete_final_row"],
                "object_rows": objects["hex_rows"],
            }
        elif maps[block_map]["object_map"] != str(object_map):
            raise MalformedDataError(f"{what}: block map {block_map} is paired with two object maps")
        maps[block_map]["used_by_levels"].append(level)
        levels.append({"level": level, "status": "decoded", "map": str(block_map)})

    ordered = [maps[key] for key in sorted(maps)]
    return {
        "pointer_table": str(layout.pointer_table),
        "level_count": layout.level_count,
        "row_width": layout.row_width,
        "levels": levels,
        "maps": ordered,
        "audit": {
            "maps_with_incomplete_final_row": [m["location"] for m in ordered if m["incomplete_final_row"]],
            "object_maps_with_incomplete_final_row": [m["object_map"] for m in ordered
                                                      if m["object_incomplete_final_row"]],
            "row_counts": sorted({m["rows"] for m in ordered}),
        },
    }


def block_id(byte: int) -> int:
    """The block function table index ProcessBlock uses for a map byte."""
    return byte & 0x7F


def find_spawn(object_rows: list[bytes], section_x: int, section_y: int) -> tuple[int, int]:
    """Block (x, y) of the first spawn nibble, searched as SetWarioPositionToSpawn does.

    The search starts at the section's top-left block, reads 16 blocks (8 object bytes, high
    nibble first) per row, and moves down a row at a time with no lower bound; running off the
    decoded map is refused here instead of reading whatever SRAM holds.
    """
    first_byte = section_x * SECTION_BLOCKS // 2
    for y in range(section_y * SECTION_BLOCKS, len(object_rows)):
        row = object_rows[y]
        for offset in range(SECTION_BLOCKS // 2):
            if first_byte + offset >= len(row):
                break
            value = row[first_byte + offset]
            if value >> 4 >= SPAWN_NIBBLE:
                return 2 * (first_byte + offset), y
            if value & 0x0F >= SPAWN_NIBBLE:
                return 2 * (first_byte + offset) + 1, y
    raise MalformedDataError(f"no spawn nibble below section ({section_x}, {section_y}) of the object map")


def spawn_point_px(block_x: int, block_y: int) -> tuple[int, int]:
    """wWarioPos after SetWarioPositionToSpawn (Func_cf8): the block's centre column and bottom edge."""
    return block_x * 16 + 8, block_y * 16 + 16


def annotate(document: dict[str, Any], symbols: dict[BankedAddress, str] | None) -> dict[str, Any]:
    """Attach optional labels to block and object maps. Labels never change decoded values."""
    if symbols is None:
        return document
    for item in document["maps"]:
        item["symbol"] = symbols.get(BankedAddress.parse(item["location"]))
        item["object_map_symbol"] = symbols.get(BankedAddress.parse(item["object_map"]))
    document["audit"]["maps_without_symbol"] = [m["location"] for m in document["maps"] if not m["symbol"]]
    return document


def extract(
    rom_path: Path,
    out_dir: Path,
    sym_path: Path | None = None,
    exploratory: bool = False,
) -> dict[str, Any]:
    rom = read_rom(rom_path)
    report = inspect_bytes(rom, str(rom_path))
    require_known(report, WL3_WORLD_MAP_LAYOUT.rom_id, exploratory=exploratory)
    is_exploratory = report.identity.status != "verified"

    document = annotate(decode(rom, WL3_WORLD_MAP_LAYOUT), load_sym(sym_path) if sym_path else None)
    document.update({
        "format": FORMAT,
        "format_version": FORMAT_VERSION,
        "marker": ROM_DERIVED_MARKER,
        "exploratory": is_exploratory,
        "provenance": {
            "rom_sha256": report.hashes.sha256,
            "rom_id": report.identity.rom_id,
            "extractor": "wl3pc.extract.level_maps",
            "extractor_version": EXTRACTOR_VERSION,
            "tools_version": TOOLS_VERSION,
            "layout_evidence": bf.DISASSEMBLY,
            "symbol_file_sha256": sha256_file(sym_path) if sym_path else None,
        },
    })
    payload = canonical_json(document)
    target_dir = out_dir / ("exploratory" if is_exploratory else "wl3-original")
    filename = "level_block_maps.json"
    changed = write_immutable(target_dir / filename, payload)
    manifest = {
        "format": "wl3pc.extraction-manifest",
        "format_version": 1,
        "marker": ROM_DERIVED_MARKER,
        "rom_sha256": report.hashes.sha256,
        "files": {filename: {"sha256": sha256_bytes(payload), "format": FORMAT, "format_version": FORMAT_VERSION}},
    }
    write_immutable(target_dir / "manifest.level_block_maps.json", canonical_json(manifest))
    return {"path": str(target_dir / filename), "sha256": sha256_bytes(payload), "changed": changed,
            "document": document}


def summarise(document: dict[str, Any]) -> str:
    decoded = [lv for lv in document["levels"] if lv["status"] == "decoded"]
    lines = [
        f"levels decoded: {len(decoded)} of {document['level_count']}; distinct block maps: {len(document['maps'])}",
        f"row counts: {', '.join(str(r) for r in document['audit']['row_counts'])} "
        f"(rows of {document['row_width']} blocks)",
    ]
    for key, values in document["audit"].items():
        if key != "row_counts":
            lines.append(f"{key}: {len(values)}")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="extract-level-maps", description=__doc__.splitlines()[0])
    parser.add_argument("--rom", type=Path, default=None)
    parser.add_argument("--out", type=Path, default=CONTENT_OUT_DIR)
    parser.add_argument("--symbols", type=Path, help="RGBDS .sym from a verified reference build (labels only)")
    parser.add_argument("--exploratory", action="store_true", help="allow an unidentified ROM; output is marked")
    args = parser.parse_args(argv)
    rom_path = args.rom or rom_path_from_env()
    try:
        result = extract(rom_path, args.out, args.symbols, args.exploratory)
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
