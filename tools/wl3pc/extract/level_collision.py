"""Build a level's collision data for the native Wario model (WL3-012): block map and per-room handlers.

Chain: level header list (LoadRoom reads entry wLevelRoomID) -> room header (byte 7 is wRoom) -> room
record -> block function table -> the handler ProcessBlock jumps to for each block ID (`byte & $7f`).
The native model implements handlers by their ID (`h06_4032` is BlockFunc_Solid), not by material,
so every probe can return what the original returns. The block map keeps bit 7, which marks a block
whose object is not spawned; ProcessBlock drops it.
Everything is decoded from the ROM by the other extractors. The output goes to the ignored
local/content/ and is marked as ROM-derived.
Research note: docs/02-research/wario-movement.md.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Any

from .. import TOOLS_VERSION
from ..paths import CONTENT_OUT_DIR, rom_path_from_env
from ..provenance import ROM_DERIVED_MARKER, canonical_json, sha256_bytes, write_immutable
from ..rom import RomFormatError, UnknownRomError, inspect_bytes, read_rom, require_known
from ..symbols import load_sym
from . import block_functions as bf
from . import level_headers as lh
from . import level_maps as lm
from . import rooms
from .block_functions import MalformedDataError

FORMAT = "wl3pc.level-collision"
FORMAT_VERSION = 1
EXTRACTOR_VERSION = 2
BLOCK_IDS = 0x80  # ProcessBlock: `add a` drops bit 7 of the map byte


def build(rom: bytes, level: int, symbols: dict[Any, str] | None = None) -> dict[str, Any]:
    """The level's block map and, for each room-list entry, the handler of every block ID.

    `symbols` (an optional reference .sym) only adds handler labels.
    """
    headers = lh.decode(rom)
    entry = headers["levels"][level]
    if entry["status"] != "decoded":
        raise MalformedDataError(f"level {level:#04x} has no room list")
    room_list = next(item for item in headers["lists"] if item["location"] == entry["list"])
    fields_at = {h["location"]: h["fields"] for h in headers["headers"]}
    records = rooms.decode(rom)["rooms"]
    tables = bf.decode(rom)
    if symbols is not None:
        tables = bf.annotate(tables, symbols, None, bf.WL3_WORLD_LAYOUT.handler_bank)
    level_map = next(m for m in lm.decode(rom)["maps"] if level in m["used_by_levels"])

    used_handlers: set[str] = set()
    room_entries = []
    for level_room_id, location in enumerate(room_list["entries"]):
        if location is None:
            continue
        fields = fields_at[location]
        table_index = records[fields["room"]]["fields"]["block_function_table"]
        handlers = tables["tables"][table_index]["entries"][:BLOCK_IDS]
        if len(handlers) != BLOCK_IDS:
            raise MalformedDataError(f"table {table_index} has {len(handlers)} entries, not {BLOCK_IDS}")
        used_handlers.update(handlers)
        room_entries.append({"level_room_id": level_room_id, "header": location, "fields": fields,
                             "block_function_table": table_index, "handlers": handlers})
    labels = {h["id"]: h.get("symbol") for h in tables["handlers"]}
    # StartRoom_FromLevelStart loads list entry 0; SetWarioPositionToSpawn searches its spawn section.
    start_fields = room_entries[0]["fields"] if room_entries and room_entries[0]["level_room_id"] == 0 else None
    if start_fields is None:
        raise MalformedDataError(f"level {level:#04x}: list entry 0 is empty")
    object_rows = [bytes.fromhex(row) for row in level_map["object_rows"]]
    spawn_x, spawn_y = lm.find_spawn(object_rows, start_fields["spawn_x"], start_fields["spawn_y"])
    point_x, point_y = lm.spawn_point_px(spawn_x, spawn_y)
    return {
        "level": level,
        "block_map": level_map["location"],
        "row_width": len(bytes.fromhex(level_map["block_rows"][0])),
        "block_rows": level_map["block_rows"],
        # SetWarioPositionToSpawn searches it when a room starts (one nibble per block, $f marks a spawn).
        "object_rows": level_map["object_rows"],
        "rooms": room_entries,
        "handlers": {handler: labels.get(handler) for handler in sorted(used_handlers)},
        "start": {"level_room_id": 0, "spawn_block": [spawn_x, spawn_y], "wario_x": point_x, "wario_y": point_y},
    }


def extract(rom_path: Path, out_dir: Path, level: int, sym_path: Path | None = None,
            exploratory: bool = False) -> dict[str, Any]:
    rom = read_rom(rom_path)
    report = inspect_bytes(rom, str(rom_path))
    require_known(report, lm.WL3_WORLD_MAP_LAYOUT.rom_id, exploratory=exploratory)
    is_exploratory = report.identity.status != "verified"
    document = build(rom, level, load_sym(sym_path) if sym_path else None)
    document.update({
        "format": FORMAT,
        "format_version": FORMAT_VERSION,
        "marker": ROM_DERIVED_MARKER,
        "exploratory": is_exploratory,
        "provenance": {
            "rom_sha256": report.hashes.sha256,
            "rom_id": report.identity.rom_id,
            "extractor": "wl3pc.extract.level_collision",
            "extractor_version": EXTRACTOR_VERSION,
            "tools_version": TOOLS_VERSION,
            "layout_evidence": bf.DISASSEMBLY,
        },
    })
    payload = canonical_json(document)
    target = out_dir / ("exploratory" if is_exploratory else "wl3-original") / "levels" / f"level-{level:02x}.json"
    changed = write_immutable(target, payload)
    return {"path": str(target), "sha256": sha256_bytes(payload), "changed": changed, "document": document}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="extract-level-collision", description=__doc__.splitlines()[0])
    parser.add_argument("--rom", type=Path, default=None)
    parser.add_argument("--out", type=Path, default=CONTENT_OUT_DIR)
    parser.add_argument("--level", type=lambda text: int(text, 0), default=0, help="level number (default 0)")
    parser.add_argument("--symbols", type=Path, help="RGBDS .sym from a verified reference build (labels only)")
    parser.add_argument("--exploratory", action="store_true", help="allow an unidentified ROM; output is marked")
    args = parser.parse_args(argv)
    rom_path = args.rom or rom_path_from_env()
    try:
        result = extract(rom_path, args.out, args.level, args.symbols, args.exploratory)
    except FileNotFoundError as error:
        print(f"extract: missing input: {error.filename}", file=sys.stderr)
        return 2
    except (UnknownRomError, RomFormatError, MalformedDataError) as error:
        print(f"extract: {error}", file=sys.stderr)
        return 3
    document = result["document"]
    print(f"wrote {result['path']} ({'updated' if result['changed'] else 'unchanged'}) sha256 {result['sha256']}")
    print(f"level {document['level']:#04x}: map {document['block_map']}, {len(document['rooms'])} rooms, "
          f"tables {sorted({r['block_function_table'] for r in document['rooms']})}, "
          f"{len(document['handlers'])} handlers")
    return 0


if __name__ == "__main__":
    sys.exit(main())
