import json

import jsonschema
import pytest

from synthetic_rom import build_rom, fix
from wl3pc.address import BankedAddress
from wl3pc.extract import block_functions as bf
from wl3pc.extract import rooms
from wl3pc.paths import PROJECT_ROOT
from wl3pc.provenance import ROM_DERIVED_MARKER
from wl3pc.rom import UnknownRomError
from wl3pc.symbols import parse_sym

# A miniature layout over a 128 KiB synthetic ROM (banks 0-7). Pointer tables
# sit in bank 1; data banks follow the same index-to-bank rules as the original.
LAYOUT = rooms.RoomLayout(
    rom_id="synthetic",
    room_pointer_table=BankedAddress(1, 0x4000),
    room_count=4,
    block_functions=bf.BlockFunctionLayout(
        rom_id="synthetic", pointer_table=BankedAddress(2, 0x4000), pointer_count=3, group2_first_index=1,
        group1_bank=2, group2_bank=3, entries_per_table=2, handler_bank=7,
    ),
    sources=(
        rooms.GfxSource("block_tiles", "block_function_table", "block_function_table",
                        BankedAddress(1, 0x4200), 4, 4, 2, "copy", 4),
        rooms.GfxSource("block_attributes", "tile_map", "block_function_table",
                        BankedAddress(1, 0x4210), 4, 4, 2, "rle", 8),
        rooms.GfxSource("main_tiles", "main_tiles", "main_tiles", BankedAddress(1, 0x4220), 3, 6, 2, "copy", 0x10),
        rooms.GfxSource("special_tiles", "special_tiles", "special_tiles",
                        BankedAddress(1, 0x4230), 2, 7, 8, "copy", 0x10),
        rooms.GfxSource("palettes", "palettes", "palettes", BankedAddress(1, 0x4240), 2, 7, None, "copy", 8),
    ),
)


def le(*words: int) -> bytes:
    return b"".join(w.to_bytes(2, "little") for w in words)


def at(bank: int, address: int) -> int:
    return BankedAddress(bank, address).file_offset


def synthetic(room_pointers=(0xFFFF, 0x4100, 0xFF12, 0x4105), room3=(1, 2, 2, 1, 1), extra=None) -> bytes:
    patches = {
        at(1, 0x4000): le(*room_pointers),
        at(1, 0x4100): bytes([0, 0, 0, 0, 0]) + bytes(room3),
        at(1, 0x4200): le(0x4000, 0x4010, 0x4020, 0x4030),  # block tiles
        at(1, 0x4210): le(0x4100, 0x4110, 0x4120, 0x4130),  # block attributes
        at(1, 0x4220): le(0x4000, 0x4800, 0x5000),  # main tiles
        at(1, 0x4230): le(0x6000, 0x6100),  # special tiles
        at(1, 0x4240): le(0x7000, 0x7008),  # palettes
        at(2, 0x4000): le(0x4010, 0x4000, 0xFFFF),  # block function table pointers
        at(2, 0x4010): le(0x4000, 0x4001),
        at(3, 0x4000): le(0x4002, 0x4003),
        at(4, 0x4100): bytes([0x03, 0xAA, 0x82, 0x01, 0x02, 0x00]),  # 5 bytes
        at(4, 0x4120): bytes([0x08, 0x55, 0x00]),  # 8 bytes
        at(5, 0x4120): bytes([0x01, 0x66, 0x00]),  # 1 byte: only read if the bank came from the tile map
    }
    patches.update(extra or {})
    return bytes(build_rom(size=0x20000, patches=patches))


def test_decodes_records_sentinels_and_bank_rules():
    document = rooms.decode(synthetic(), LAYOUT)
    assert [r["status"] for r in document["rooms"]] == ["reset-sentinel", "decoded", "reset-sentinel", "decoded"]
    # LoadRoomGfx only tests the pointer's high byte, so $ff12 is a reset too.
    assert document["rooms"][2]["pointer"] == "ff12"
    first, third = document["rooms"][1], document["rooms"][3]
    assert first["record"] == "01:4100"
    assert third["fields"] == {"block_function_table": 1, "tile_map": 2, "main_tiles": 2,
                               "special_tiles": 1, "palettes": 1}
    # Function table 1 is in group 2, so it is read from the group-2 bank.
    assert (first["block_function_table"], third["block_function_table"]) == ("02:4010", "03:4000")
    assert first["sources"]["block_attributes"] == {"location": "04:4100", "bytes": 5, "compressed_bytes": 6}
    # The tile map is indexed by its own byte (2) but read from the function table's bank (4 + 1 // 2).
    assert third["sources"]["block_attributes"] == {"location": "04:4120", "bytes": 8, "compressed_bytes": 3}
    assert third["sources"]["block_tiles"] == {"location": "04:4010", "bytes": 4}
    assert third["sources"]["main_tiles"] == {"location": "07:5000", "bytes": 0x10}
    assert third["sources"]["special_tiles"]["location"] == "07:6100"
    assert third["sources"]["palettes"] == {"location": "07:7008", "bytes": 8}
    assert document["audit"]["tile_map_differs_from_block_function_table"] == [3]


@pytest.mark.parametrize("patch, message", [
    ({at(1, 0x4002): le(0xC000)}, "room 0x01: pointer 0xc000 is not a ROM address"),
    ({at(1, 0x4002): le(0x7FFD)}, "cross the end of bank 01"),
    ({at(1, 0x4105): bytes([2])}, "block function table 0x02 is a reset sentinel"),
    ({at(1, 0x4105): bytes([3])}, "block function table 0x03 is outside its 3-entry table"),
    ({at(1, 0x4107): bytes([3])}, "main_tiles 0x03 is outside its 3-entry table"),
    ({at(1, 0x4242): le(0xFFFF)}, "palettes: pointer 0xffff is not a ROM address"),
    ({at(1, 0x4232): le(0x7FF8)}, "special_tiles: 16 byte"),
    ({at(4, 0x4120): bytes([0x09, 0x55, 0x00])}, "block_attributes: stream from 04:4120 overflows"),
])
def test_rejects_structural_violations(patch, message):
    with pytest.raises(bf.MalformedDataError, match=message):
        rooms.decode(synthetic(extra=patch), LAYOUT)


def test_rejects_rom_missing_the_tables():
    with pytest.raises(bf.MalformedDataError, match="pointer table"):
        rooms.decode(bytes(build_rom(size=0x8000)), LAYOUT)


def test_labels_are_optional_and_do_not_change_values():
    plain = rooms.decode(synthetic(), LAYOUT)
    labelled = rooms.annotate(rooms.decode(synthetic(), LAYOUT),
                              parse_sym("04:4100 AttrsA\n04:4120 AttrsB\n04:4000 TilesA\n07:5000 Main\n"))
    strip = lambda d: json.dumps([{k: v for k, v in r.items() if k != "sources"} for r in d["rooms"]])
    assert strip(plain) == strip(labelled)
    assert labelled["rooms"][3]["sources"]["block_attributes"]["symbol"] == "AttrsB"
    assert labelled["rooms"][3]["sources"]["block_tiles"]["symbol"] is None
    assert "3:block_tiles" in labelled["audit"]["sources_without_symbol"]
    assert "sources_without_symbol" not in plain["audit"]


def wl3_shaped_rom(extra: dict[int, bytes] | None = None) -> bytes:
    """2 MiB synthetic ROM that satisfies the WL3 layouts with one room and one table."""
    layout = rooms.WL3_WORLD_ROOM_LAYOUT
    table_pointers = [0xFFFF] * layout.block_functions.pointer_count
    table_pointers[0] = 0x40C4
    room_pointers = [0xFFFF] * layout.room_count
    room_pointers[1] = 0x460B
    patches = {
        layout.block_functions.pointer_table.file_offset: le(*table_pointers),
        at(0x32, 0x40C4): le(*([0x4032] * layout.block_functions.entries_per_table)),
        layout.room_pointer_table.file_offset: le(*room_pointers),
        at(0x30, 0x460B): bytes(5),
        at(0x38, 0x6E0B): bytes([0x7F, 0x00] * 4 + [0x04, 0x00, 0x00]),  # 4 * 127 + 4 = 512 bytes
    }
    data = {"block_tiles": 0x6C0B, "block_attributes": 0x6E0B}
    for source in layout.sources:
        patches[source.pointers.file_offset] = le(data.get(source.name, 0x4000))
    patches.update(extra or {})
    return bytes(build_rom(size=0x200000, patches=patches))


def test_extract_refuses_unknown_rom(tmp_path):
    rom_path = tmp_path / "unknown cart.gbc"
    rom_path.write_bytes(wl3_shaped_rom())
    with pytest.raises(UnknownRomError):
        rooms.extract(rom_path, tmp_path / "out")
    assert not (tmp_path / "out").exists()


def test_exploratory_extraction_is_marked_deterministic_and_schema_valid(tmp_path):
    rom_path = tmp_path / "unknown cart.gbc"
    rom_path.write_bytes(wl3_shaped_rom())
    first = rooms.extract(rom_path, tmp_path / "out", exploratory=True)
    second = rooms.extract(rom_path, tmp_path / "out", exploratory=True)
    assert first["changed"] and not second["changed"]
    assert first["sha256"] == second["sha256"]
    output = tmp_path / "out" / "exploratory" / "room_records.json"
    document = json.loads(output.read_text())
    schema = json.loads((PROJECT_ROOT / "schemas" / "room-records.v1.schema.json").read_text())
    jsonschema.Draft202012Validator(schema).validate(document)
    assert document["exploratory"] is True
    assert document["marker"] == ROM_DERIVED_MARKER
    decoded = [r for r in document["rooms"] if r["status"] == "decoded"]
    assert [r["room"] for r in decoded] == [1]
    assert decoded[0]["sources"]["block_attributes"]["bytes"] == 0x200
    assert decoded[0]["sources"]["block_tiles"]["location"] == "38:6c0b"
    assert not (output.stat().st_mode & 0o222), "extracted base files are written read-only"
    manifest = json.loads((tmp_path / "out" / "exploratory" / "manifest.room_records.json").read_text())
    assert manifest["files"]["room_records.json"]["sha256"] == first["sha256"]


def test_malformed_wl3_layout_fails_clearly(tmp_path):
    rom_path = tmp_path / "zeros.gbc"
    rom_path.write_bytes(bytes(fix(build_rom(size=0x200000))))
    with pytest.raises(bf.MalformedDataError):
        rooms.extract(rom_path, tmp_path / "out", exploratory=True)
