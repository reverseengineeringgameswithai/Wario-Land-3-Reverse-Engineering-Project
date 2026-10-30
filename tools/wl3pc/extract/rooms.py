"""Decode the per-room records (room -> block function table and graphics sources).

Question: which tables and graphics does each room load, and from which banks?
Evidence (ElectroDeoxys/warioland3 @560fce6, verified byte-identical to the
identified ROM): LoadRoomGfx (30:4000, engine/level/load_room_gfx.asm) indexes
RoomBlockAndGfxData by wRoom, resets via `debug_assert_not $ff` when the
pointer's high byte is $ff, then reads five bytes into wRoomBlockFunctionTable,
wRoomTileMap, wRoomMainTiles, wRoomSpecialTiles, and wRoomPalettes. The home
loaders it calls (home/load_room.asm) run with bank 30 still mapped, so they
read their pointer tables from bank 30 and switch only for the data.

Layout facts below are recorded per verified revision. Research note:
docs/02-research/room-records.md.
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

FORMAT = "wl3pc.room-records"
FORMAT_VERSION = 1
EXTRACTOR_VERSION = 1

# Record byte order, named after the WRAM variable LoadRoomGfx stores each byte in.
FIELDS = ("block_function_table", "tile_map", "main_tiles", "special_tiles", "palettes")


@dataclass(frozen=True)
class GfxSource:
    """One pointer-table lookup made by a home loader that LoadRoomGfx calls."""

    name: str
    # Record field that indexes the pointer table
    index_field: str
    # Record field whose value selects the data bank
    bank_field: str
    pointers: BankedAddress
    # Entries before the table's NULL padding
    count: int
    first_bank: int
    # bank = first_bank + value // per_bank; None means a fixed bank
    per_bank: int | None
    # "copy" reads `size` bytes; "rle" runs Decompress into a `size`-byte buffer
    kind: str
    size: int

    def bank_for(self, value: int) -> int:
        return self.first_bank if self.per_bank is None else self.first_bank + value // self.per_bank


@dataclass(frozen=True)
class RoomLayout:
    rom_id: str
    # RoomBlockAndGfxData (src/data/levels/rooms1.asm, section "Rooms 1")
    room_pointer_table: BankedAddress
    # NUM_ROOMS = $9b (src/constants/room_constants.asm); `assert_table_length NUM_ROOMS`
    room_count: int
    block_functions: bf.BlockFunctionLayout
    sources: tuple[GfxSource, ...]
    # `room` macro: five `db` fields; LoadRoomGfx reads them with `ld a, [hli]`
    record_size: int = 5
    # LoadRoomGfx: `ld a, h / debug_assert_not $ff` jumps to Init (NULL = $ffff)
    reset_high_byte: int = 0xFF


WL3_WORLD_ROOM_LAYOUT = RoomLayout(
    rom_id=WL3_WORLD_EN_JA.rom_id,
    room_pointer_table=BankedAddress(0x30, 0x44C5),
    room_count=0x9B,
    block_functions=bf.WL3_WORLD_LAYOUT,
    sources=(
        # Func_298d: RoomBlockTilesPointers[wRoomBlockFunctionTable] from bank wRoomBlockFunctionTableBank
        # (BANK("Level Data 1") = $38 plus index / 6); copies 4 * NUM_ROOM_BLOCK_TYPES bytes to wRoomBlockTiles.
        GfxSource("block_tiles", "block_function_table", "block_function_table",
                  BankedAddress(0x30, 0x490D), 0x59, 0x38, 6, "copy", 0x200),
        # LoadRoomTileMap: RoomBlockAttributePointers[wRoomTileMap]; Decompress runs with bank wc0d0, which
        # LoadRoomGfx sets to wRoomBlockFunctionTableBank. Output goes to wRoomBlockAttributes (ds $4 * $80).
        GfxSource("block_attributes", "tile_map", "block_function_table",
                  BankedAddress(0x30, 0x49D1), 0x59, 0x38, 6, "rle", 0x200),
        # LoadRoomMainTiles: LevelMainTilesPointers[wRoomMainTiles] from BANK("Room Main Tiles 1") = $51 plus
        # index / 8 (three `srl a`); copies $800 bytes. 40 entries precede the NULL padding.
        GfxSource("main_tiles", "main_tiles", "main_tiles",
                  BankedAddress(0x30, 0x4A95), 40, 0x51, 8, "copy", 0x800),
        # LoadRoomSpecialTiles: SpecialTilesPointers[wRoomSpecialTiles] from BANK("Room Special Tiles 1") = $4e
        # plus index / 8; copies $800 bytes to VRAM bank 1. 9 entries precede the NULL padding.
        GfxSource("special_tiles", "special_tiles", "special_tiles",
                  BankedAddress(0x30, 0x4AF7), 9, 0x4E, 8, "copy", 0x800),
        # LoadRoomPalettes: RoomPals[wRoomPalettes] from BANK("Level Palettes") = $33 via LoadPalsToTempPals1,
        # which copies 8 palettes (64 bytes). 146 entries precede the `ds $12, $ff` padding.
        GfxSource("palettes", "palettes", "palettes",
                  BankedAddress(0x30, 0x4B1B), 0x92, 0x33, None, "copy", 0x40),
    ),
)


def _resolve(base: BankedAddress, pointer: int, what: str) -> BankedAddress:
    try:
        return base.in_same_bank(pointer)
    except ValueError as error:
        raise MalformedDataError(f"{what}: pointer {pointer:#06x} is not a ROM address") from error


def _source(view: RomView, spec: GfxSource, fields: dict[str, int], room: int) -> dict[str, Any]:
    what = f"room {room:#04x} {spec.name}"
    index = fields[spec.index_field]
    if index >= spec.count:
        raise MalformedDataError(f"{what}: {spec.index_field} {index:#04x} is outside its {spec.count}-entry table")
    try:
        raw = view.read_banked(BankedAddress(spec.pointers.bank, spec.pointers.address + 2 * index), 2)
    except (ValueError, RomBoundsError) as error:
        raise MalformedDataError(f"{what}: pointer table: {error}") from error
    pointer = raw[0] | (raw[1] << 8)
    location = _resolve(BankedAddress(spec.bank_for(fields[spec.bank_field]), 0x4000), pointer, what)
    try:
        if spec.kind == "rle":
            output, compressed = decompress(view, location, spec.size)
            return {"location": str(location), "bytes": len(output), "compressed_bytes": compressed}
        view.read_banked(location, spec.size)
    except (DecompressError, RomBoundsError) as error:
        raise MalformedDataError(f"{what}: {error}") from error
    return {"location": str(location), "bytes": spec.size}


def decode(rom: bytes, layout: RoomLayout = WL3_WORLD_ROOM_LAYOUT) -> dict[str, Any]:
    """Decode every room record. Raises on any structural violation."""
    view = RomView(rom)
    tables = bf.decode(rom, layout.block_functions)["tables"]
    table_pointer_bank = layout.room_pointer_table.bank
    try:
        pointer_bytes = view.read_banked(layout.room_pointer_table, 2 * layout.room_count)
    except RomBoundsError as error:
        raise MalformedDataError(f"room pointer table: {error}") from error

    rooms: list[dict[str, Any]] = []
    for room in range(layout.room_count):
        pointer = pointer_bytes[2 * room] | (pointer_bytes[2 * room + 1] << 8)
        if pointer >> 8 == layout.reset_high_byte:
            rooms.append({"room": room, "status": "reset-sentinel", "pointer": f"{pointer:04x}"})
            continue
        record = _resolve(BankedAddress(table_pointer_bank, 0x4000), pointer, f"room {room:#04x}")
        try:
            raw = view.read_banked(record, layout.record_size)
        except RomBoundsError as error:
            raise MalformedDataError(f"room {room:#04x} record: {error}") from error
        fields = dict(zip(FIELDS, raw))

        table_index = fields["block_function_table"]
        if table_index >= len(tables):
            raise MalformedDataError(
                f"room {room:#04x}: block function table {table_index:#04x} is outside its {len(tables)}-entry table"
            )
        table = tables[table_index]
        if table["status"] != "decoded":
            raise MalformedDataError(
                f"room {room:#04x}: block function table {table_index:#04x} is a reset sentinel"
            )
        rooms.append({
            "room": room,
            "status": "decoded",
            "record": str(record),
            "fields": fields,
            "block_function_table": table["location"],
            "sources": {spec.name: _source(view, spec, fields, room) for spec in layout.sources},
        })

    decoded = [r for r in rooms if r["status"] == "decoded"]
    return {
        "pointer_table": str(layout.room_pointer_table),
        "room_count": layout.room_count,
        "record_size": layout.record_size,
        "rooms": rooms,
        "audit": {
            # The tile map's bank comes from the function-table byte (wc0d0); a mismatch would read across groups.
            "tile_map_differs_from_block_function_table": [
                r["room"] for r in decoded if r["fields"]["tile_map"] != r["fields"]["block_function_table"]
            ],
        },
    }


def annotate(document: dict[str, Any], symbols: dict[BankedAddress, str] | None) -> dict[str, Any]:
    """Attach optional local labels to resolved sources. Labels never change decoded values."""
    if symbols is None:
        return document
    missing = []
    for room in document["rooms"]:
        for name, source in room.get("sources", {}).items():
            source["symbol"] = symbols.get(BankedAddress.parse(source["location"]))
            if source["symbol"] is None:
                missing.append(f"{room['room']}:{name}")
    document["audit"]["sources_without_symbol"] = missing
    return document


def extract(
    rom_path: Path,
    out_dir: Path,
    sym_path: Path | None = None,
    exploratory: bool = False,
) -> dict[str, Any]:
    rom = read_rom(rom_path)
    report = inspect_bytes(rom, str(rom_path))
    require_known(report, WL3_WORLD_ROOM_LAYOUT.rom_id, exploratory=exploratory)
    is_exploratory = report.identity.status != "verified"

    document = annotate(decode(rom, WL3_WORLD_ROOM_LAYOUT), load_sym(sym_path) if sym_path else None)
    document.update({
        "format": FORMAT,
        "format_version": FORMAT_VERSION,
        "marker": ROM_DERIVED_MARKER,
        "exploratory": is_exploratory,
        "provenance": {
            "rom_sha256": report.hashes.sha256,
            "rom_id": report.identity.rom_id,
            "extractor": "wl3pc.extract.rooms",
            "extractor_version": EXTRACTOR_VERSION,
            "tools_version": TOOLS_VERSION,
            "layout_evidence": bf.DISASSEMBLY,
            "symbol_file_sha256": sha256_file(sym_path) if sym_path else None,
        },
    })
    payload = canonical_json(document)
    target_dir = out_dir / ("exploratory" if is_exploratory else "wl3-original")
    filename = "room_records.json"
    changed = write_immutable(target_dir / filename, payload)
    manifest = {
        "format": "wl3pc.extraction-manifest",
        "format_version": 1,
        "marker": ROM_DERIVED_MARKER,
        "rom_sha256": report.hashes.sha256,
        "files": {filename: {"sha256": sha256_bytes(payload), "format": FORMAT, "format_version": FORMAT_VERSION}},
    }
    write_immutable(target_dir / "manifest.room_records.json", canonical_json(manifest))
    return {"path": str(target_dir / filename), "sha256": sha256_bytes(payload), "changed": changed,
            "document": document}


def summarise(document: dict[str, Any]) -> str:
    decoded = [r for r in document["rooms"] if r["status"] == "decoded"]
    sentinels = [f"{r['room']:#04x}" for r in document["rooms"] if r["status"] == "reset-sentinel"]
    lines = [
        f"rooms decoded: {len(decoded)} of {document['room_count']}; reset sentinels: {len(sentinels)} "
        f"({', '.join(sentinels) or 'none'})",
    ]
    for field in FIELDS:
        values = sorted({r["fields"][field] for r in decoded})
        span = f"{values[0]:#04x}-{values[-1]:#04x}" if values else "none"
        lines.append(f"{field}: {len(values)} distinct ({span})")
    sizes = sorted({r["sources"]["block_attributes"]["bytes"] for r in decoded})
    lines.append(f"block_attributes decompressed sizes: {', '.join(f'{s:#x}' for s in sizes) or 'none'}")
    for key, values in document.get("audit", {}).items():
        lines.append(f"{key}: {len(values)}")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="extract-rooms", description=__doc__.splitlines()[0])
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
