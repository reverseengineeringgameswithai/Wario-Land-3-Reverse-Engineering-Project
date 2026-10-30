"""Decode level headers: per-level room lists and the room headers they point to.

Question: which room does each level load first, and what does each room
header set before LoadRoomGfx runs?
Evidence (ElectroDeoxys/warioland3 @560fce6, verified byte-identical to the
identified ROM): LoadRoom (00:285c, home/load_room.asm) reads
LevelHeaders[wLevel] with BANK(LevelHeaders) = $30 mapped and resets on a $ff
high byte. It then maps bank $30 for levels below THE_GRASSLANDS_NIGHT_1 and
bank $31 otherwise, reads entry wLevelRoomID of the list, resets on a $ff high
byte again, and reads an 8-byte room header that ends with wRoom.
StartRoom_FromLevelStart (02:4747, engine/level/start_room.asm) clears
wLevelRoomID on a fresh level start, so entry 0 is the room a level starts in.

Layout facts below are recorded per verified revision. Research note:
docs/02-research/level-headers.md.
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
from . import rooms
from .block_functions import MalformedDataError

FORMAT = "wl3pc.level-headers"
FORMAT_VERSION = 1
EXTRACTOR_VERSION = 1

# Header fields in byte order, named after the WRAM variables LoadRoom stores them in.
# Bytes 0-2 hold two nibbles each (high nibble first), as the `room_header` macro packs them with `dn`.
NIBBLE_FIELDS = (("spawn_y", "spawn_x"), ("upper_y_limit", "lower_y_limit"), ("left_x_limit", "right_x_limit"))
BYTE_FIELDS = ("camera_config", "object_group", "animated_tiles_group", "pal_cycle", "room")


@dataclass(frozen=True)
class LevelHeaderLayout:
    rom_id: str
    # LevelHeaders (src/data/levels/rooms1.asm), read with BANK(LevelHeaders) mapped
    level_pointer_table: BankedAddress
    # OUT_OF_THE_WOODS_DAY_1 ($00) to THE_TEMPLE ($c8) (src/constants/level_constants.asm); 13 NULLs follow
    level_count: int
    # LoadRoom: `cp THE_GRASSLANDS_NIGHT_1 / jr nc, .group_2`
    group2_first_level: int
    group1_bank: int
    group2_bank: int
    # GetNextLevelRoomID gives XPosHi + 10 * YPosHi. Every list in the disassembly has 30 entries
    # (3 rows of 10); no constant states it, so the decoder also refuses a header inside its list.
    entries_per_list: int
    rooms: rooms.RoomLayout
    # NUM_OBJECT_GROUPS = $92 (src/constants/object_constants.asm), indexed by LoadObjectGroupData
    object_group_count: int
    # LoadObjectGroupData jumps to LoadHiddenFigureData for OBJECT_GROUP_HIDDEN_FIGURE ($f0)
    special_object_groups: tuple[int, ...]
    # AnimatedTilesGroups entries, indexed by InitRoomAnimatedTiles (2 bytes each)
    animated_tiles_group_count: int
    # RoomPalCycles entries, indexed by InitRoomAnimatedPals
    pal_cycle_count: int
    # `room_header` macro: 3 `dn` bytes and 5 `db` bytes; LoadRoom reads them with `ld a, [hli]`
    header_size: int = 8
    # LoadRoom: `ld a, h / debug_assert_not $ff` after each pointer load
    reset_high_byte: int = 0xFF

    def list_bank(self, level: int) -> int:
        return self.group1_bank if level < self.group2_first_level else self.group2_bank


WL3_WORLD_LEVEL_LAYOUT = LevelHeaderLayout(
    rom_id=WL3_WORLD_EN_JA.rom_id,
    level_pointer_table=BankedAddress(0x30, 0x4319),
    level_count=0xC9,
    group2_first_level=0x64,
    group1_bank=0x30,
    group2_bank=0x31,
    entries_per_list=30,
    rooms=rooms.WL3_WORLD_ROOM_LAYOUT,
    object_group_count=0x92,
    special_object_groups=(0xF0,),
    animated_tiles_group_count=29,
    pal_cycle_count=20,
)


def _resolve(bank: int, pointer: int, what: str) -> BankedAddress:
    try:
        return BankedAddress(bank, 0x4000).in_same_bank(pointer)
    except ValueError as error:
        raise MalformedDataError(f"{what}: pointer {pointer:#06x} is not a ROM address") from error


def _read(view: RomView, start: BankedAddress, length: int, what: str) -> bytes:
    try:
        return view.read_banked(start, length)
    except RomBoundsError as error:
        raise MalformedDataError(f"{what}: {error}") from error


def _words(raw: bytes) -> list[int]:
    return [raw[i] | (raw[i + 1] << 8) for i in range(0, len(raw), 2)]


def _header_fields(raw: bytes) -> dict[str, int]:
    fields: dict[str, int] = {}
    for (high, low), value in zip(NIBBLE_FIELDS, raw[:3]):
        fields[high], fields[low] = value >> 4, value & 0x0F
    fields.update(zip(BYTE_FIELDS, raw[3:]))
    return fields


def _check_header(fields: dict[str, int], layout: LevelHeaderLayout, decoded_rooms: set[int],
                  room_count: int, what: str) -> None:
    room = fields["room"]
    if room >= room_count:
        raise MalformedDataError(f"{what}: room {room:#04x} is outside its {room_count}-entry table")
    if room not in decoded_rooms:
        raise MalformedDataError(f"{what}: room {room:#04x} is a reset sentinel")
    group = fields["object_group"]
    if group >= layout.object_group_count and group not in layout.special_object_groups:
        raise MalformedDataError(f"{what}: object group {group:#04x} is outside its "
                                 f"{layout.object_group_count}-entry table")
    for name, count in (("animated_tiles_group", layout.animated_tiles_group_count),
                        ("pal_cycle", layout.pal_cycle_count)):
        if fields[name] >= count:
            raise MalformedDataError(f"{what}: {name} {fields[name]:#04x} is outside its {count}-entry table")


def decode(rom: bytes, layout: LevelHeaderLayout = WL3_WORLD_LEVEL_LAYOUT) -> dict[str, Any]:
    """Decode every level's room list and the headers they reach. Raises on any structural violation."""
    view = RomView(rom)
    room_document = rooms.decode(rom, layout.rooms)
    decoded_rooms = {r["room"] for r in room_document["rooms"] if r["status"] == "decoded"}
    level_pointers = _words(_read(view, layout.level_pointer_table, 2 * layout.level_count, "level pointer table"))
    list_bytes = 2 * layout.entries_per_list

    levels: list[dict[str, Any]] = []
    lists: dict[BankedAddress, dict[str, Any]] = {}
    headers: dict[BankedAddress, dict[str, int]] = {}
    for level, pointer in enumerate(level_pointers):
        if pointer >> 8 == layout.reset_high_byte:
            levels.append({"level": level, "status": "reset-sentinel", "pointer": f"{pointer:04x}"})
            continue
        bank = layout.list_bank(level)
        start = _resolve(bank, pointer, f"level {level:#04x}")
        if start not in lists:
            entries: list[str | None] = []
            for index, entry in enumerate(_words(_read(view, start, list_bytes, f"level {level:#04x} list"))):
                what = f"list {start} entry {index}"
                if entry >> 8 == layout.reset_high_byte:
                    entries.append(None)
                    continue
                header = _resolve(start.bank, entry, what)
                if header.bank == start.bank and start.address <= header.address < start.address + list_bytes:
                    raise MalformedDataError(f"{what}: header {header} is inside its "
                                             f"{layout.entries_per_list}-entry list")
                if header not in headers:
                    fields = _header_fields(_read(view, header, layout.header_size, what))
                    _check_header(fields, layout, decoded_rooms, layout.rooms.room_count, what)
                    headers[header] = fields
                entries.append(str(header))
            lists[start] = {"location": str(start), "used_by_levels": [], "entries": entries}
        lists[start]["used_by_levels"].append(level)
        start_header = lists[start]["entries"][0]
        levels.append({
            "level": level,
            "status": "decoded",
            "list": str(start),
            # StartRoom_FromLevelStart clears wLevelRoomID, so LoadRoom reads entry 0 first.
            "start_header": start_header,
            "start_room": headers[BankedAddress.parse(start_header)]["room"] if start_header else None,
        })

    referenced = {fields["room"] for fields in headers.values()}
    return {
        "level_pointer_table": str(layout.level_pointer_table),
        "level_count": layout.level_count,
        "entries_per_list": layout.entries_per_list,
        "header_size": layout.header_size,
        "levels": levels,
        "lists": [lists[key] for key in sorted(lists)],
        "headers": [{"location": str(key), "fields": headers[key]} for key in sorted(headers)],
        "audit": {
            "levels_starting_on_reset_entry": [lv["level"] for lv in levels
                                               if lv["status"] == "decoded" and lv["start_header"] is None],
            "decoded_rooms_not_referenced": sorted(decoded_rooms - referenced),
        },
    }


def annotate(document: dict[str, Any], symbols: dict[BankedAddress, str] | None) -> dict[str, Any]:
    """Attach optional local labels (global and local) to lists and headers. Labels never change values."""
    if symbols is None:
        return document
    for kind in ("lists", "headers"):
        for item in document[kind]:
            item["symbol"] = symbols.get(BankedAddress.parse(item["location"]))
        document["audit"][f"{kind}_without_symbol"] = [i["location"] for i in document[kind] if not i["symbol"]]
    return document


def extract(
    rom_path: Path,
    out_dir: Path,
    sym_path: Path | None = None,
    exploratory: bool = False,
) -> dict[str, Any]:
    rom = read_rom(rom_path)
    report = inspect_bytes(rom, str(rom_path))
    require_known(report, WL3_WORLD_LEVEL_LAYOUT.rom_id, exploratory=exploratory)
    is_exploratory = report.identity.status != "verified"

    symbols = load_sym(sym_path, include_local=True) if sym_path else None
    document = annotate(decode(rom, WL3_WORLD_LEVEL_LAYOUT), symbols)
    document.update({
        "format": FORMAT,
        "format_version": FORMAT_VERSION,
        "marker": ROM_DERIVED_MARKER,
        "exploratory": is_exploratory,
        "provenance": {
            "rom_sha256": report.hashes.sha256,
            "rom_id": report.identity.rom_id,
            "extractor": "wl3pc.extract.level_headers",
            "extractor_version": EXTRACTOR_VERSION,
            "tools_version": TOOLS_VERSION,
            "layout_evidence": bf.DISASSEMBLY,
            "symbol_file_sha256": sha256_file(sym_path) if sym_path else None,
        },
    })
    payload = canonical_json(document)
    target_dir = out_dir / ("exploratory" if is_exploratory else "wl3-original")
    filename = "level_headers.json"
    changed = write_immutable(target_dir / filename, payload)
    manifest = {
        "format": "wl3pc.extraction-manifest",
        "format_version": 1,
        "marker": ROM_DERIVED_MARKER,
        "rom_sha256": report.hashes.sha256,
        "files": {filename: {"sha256": sha256_bytes(payload), "format": FORMAT, "format_version": FORMAT_VERSION}},
    }
    write_immutable(target_dir / "manifest.level_headers.json", canonical_json(manifest))
    return {"path": str(target_dir / filename), "sha256": sha256_bytes(payload), "changed": changed,
            "document": document}


def summarise(document: dict[str, Any]) -> str:
    decoded = [lv for lv in document["levels"] if lv["status"] == "decoded"]
    sentinels = len(document["levels"]) - len(decoded)
    lines = [
        f"levels decoded: {len(decoded)} of {document['level_count']}; reset sentinels: {sentinels}",
        f"distinct lists: {len(document['lists'])}; distinct room headers: {len(document['headers'])}",
        f"distinct start rooms: {len({lv['start_room'] for lv in decoded})}",
    ]
    if decoded:
        lines.append(f"level 0x00 starts in room {decoded[0]['start_room']:#04x} (header {decoded[0]['start_header']})")
    for key, values in document.get("audit", {}).items():
        lines.append(f"{key}: {len(values)}")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="extract-level-headers", description=__doc__.splitlines()[0])
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
