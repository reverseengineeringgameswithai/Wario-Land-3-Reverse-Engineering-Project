import json

import jsonschema
import pytest

from synthetic_rom import build_rom, fix
from test_rooms import at, le
from wl3pc.address import BankedAddress
from wl3pc.extract import block_functions as bf
from wl3pc.extract import level_maps as lm
from wl3pc.paths import PROJECT_ROOT
from wl3pc.provenance import ROM_DERIVED_MARKER
from wl3pc.rom import UnknownRomError
from wl3pc.symbols import parse_sym

# A miniature layout over a 64 KiB synthetic ROM: rows of 4 blocks (2 object bytes), at most 3 rows.
LAYOUT = lm.LevelMapLayout(rom_id="synthetic", pointer_table=BankedAddress(1, 0x4000), level_count=4,
                           row_width=4, object_row_width=2, max_rows=3)


def record(block_map: int, bank: int, object_map: int) -> bytes:
    return le(block_map) + bytes([bank]) + le(object_map)


def synthetic(extra=None) -> bytes:
    patches = {
        at(1, 0x4000): le(0x4100, 0xFFFF, 0x4100, 0x4105),  # levels 0 and 2 share a record
        at(1, 0x4100): record(0x4000, 2, 0x4800),
        at(1, 0x4105): record(0x4010, 3, 0x4800),
        # 8 x $05, then literals $81 $02 $03, then 1 x $04: three full rows.
        at(2, 0x4000): bytes([0x08, 0x05, 0x83, 0x81, 0x02, 0x03, 0x01, 0x04, 0x00]),
        # Five bytes: one full row and one unfinished row.
        at(3, 0x4010): bytes([0x05, 0x07, 0x00]),
        # Object map: 4 x $00, then literals $0f $f0: three rows of two bytes.
        at(2, 0x4800): bytes([0x04, 0x00, 0x82, 0x0F, 0xF0, 0x00]),
    }
    patches.update(extra or {})
    return bytes(build_rom(size=0x10000, patches=patches))


def test_decodes_maps_rows_and_sentinels():
    document = lm.decode(synthetic(), LAYOUT)
    assert [lv["status"] for lv in document["levels"]] == ["decoded", "reset-sentinel", "decoded", "decoded"]
    assert document["levels"][0]["map"] == document["levels"][2]["map"] == "02:4000"
    first, second = document["maps"]
    assert first["used_by_levels"] == [0, 2] and first["object_map"] == "02:4800"
    assert first["block_rows"] == ["05050505", "05050505", "81020304"]
    assert (first["rows"], first["bytes"], first["compressed_bytes"]) == (3, 12, 9)
    assert first["incomplete_final_row"] is False and first["blocks_with_bit7"] == 1
    assert first["object_rows"] == ["0000", "0000", "0ff0"] and first["object_compressed_bytes"] == 6
    assert second["object_rows"] == [] and second["object_bytes"] == 0  # bank 3 holds only a terminator
    # The data bank comes from the record, so level 3's map is read from bank 3.
    assert second["location"] == "03:4010" and second["block_rows"] == ["07070707", "07"]
    assert second["incomplete_final_row"] is True
    assert document["audit"] == {"maps_with_incomplete_final_row": ["03:4010"],
                                 "object_maps_with_incomplete_final_row": [], "row_counts": [2, 3]}


def test_block_ids_drop_bit_seven():
    assert [lm.block_id(b) for b in (0x00, 0x05, 0x81, 0xFF)] == [0x00, 0x05, 0x01, 0x7F]


def test_spawn_search_follows_the_original_scan_order():
    # 32 blocks wide (16 object bytes), 34 rows: two sections across, two down (plus spare rows).
    rows = [bytearray(16) for _ in range(34)]
    rows[3][9] = 0x0F    # section (1, 0): low nibble of byte 9 -> block 19, row 3
    rows[2][10] = 0xF0   # high nibble of byte 10 -> block 20, row 2, which is scanned before row 3
    assert lm.find_spawn([bytes(r) for r in rows], 1, 0) == (20, 2)
    # Section (0, 0) never reaches columns 16+, so it scans down into section (0, 1).
    rows[20][1] = 0x0F
    assert lm.find_spawn([bytes(r) for r in rows], 0, 0) == (3, 20)
    # High nibble wins over low nibble within a byte; earlier bytes win within a row.
    rows[17][0] = 0xFF
    assert lm.find_spawn([bytes(r) for r in rows], 0, 1) == (0, 17)
    with pytest.raises(bf.MalformedDataError, match="no spawn nibble"):
        lm.find_spawn([bytes(16)] * 34, 1, 1)


def test_spawn_point_is_block_centre_and_bottom_edge():
    assert lm.spawn_point_px(3, 46) == (56, 752)
    assert lm.spawn_point_px(0, 0) == (8, 16)


@pytest.mark.parametrize("patch, message", [
    ({at(1, 0x4000): le(0xC000)}, "level 0x00: pointer 0xc000 is not a ROM address"),
    ({at(1, 0x4000): le(0x7FFE)}, "level 0x00 record: 5 byte"),
    ({at(1, 0x4100): record(0x9000, 2, 0x4800)}, "block map: pointer 0x9000 is not a ROM address"),
    ({at(2, 0x4000): bytes([0x0D, 0x01, 0x00])}, "overflows its 0xc-byte destination"),
    ({at(2, 0x4800): bytes([0x07, 0x01, 0x00])}, "object map: stream from 02:4800 overflows"),
    ({at(1, 0x4100): record(0x7FFE, 2, 0x4800), at(2, 0x7FFE): bytes([0x02, 0x01])}, "not terminated"),
    ({at(1, 0x4105): record(0x4000, 2, 0x4900)}, "paired with two object maps"),
    ({at(1, 0x4100): record(0x4000, 0, 0x4800)}, "data bank \\$00 is not modelled"),
])
def test_rejects_structural_violations(patch, message):
    with pytest.raises(bf.MalformedDataError, match=message):
        lm.decode(synthetic(extra=patch), LAYOUT)


def test_rejects_rom_missing_the_table():
    with pytest.raises(bf.MalformedDataError, match="level map pointer table"):
        lm.decode(bytes(build_rom(size=0x4000)), LAYOUT)


def test_labels_are_optional_and_do_not_change_values():
    plain = lm.decode(synthetic(), LAYOUT)
    labelled = lm.annotate(lm.decode(synthetic(), LAYOUT), parse_sym("02:4000 MapA\n02:4800 ObjA\n"))
    assert [m["block_rows"] for m in labelled["maps"]] == [m["block_rows"] for m in plain["maps"]]
    assert (labelled["maps"][0]["symbol"], labelled["maps"][0]["object_map_symbol"]) == ("MapA", "ObjA")
    assert labelled["audit"]["maps_without_symbol"] == ["03:4010"]


def wl3_shaped_rom() -> bytes:
    """2 MiB synthetic ROM with one level whose map is 48 full rows of one block."""
    layout = lm.WL3_WORLD_MAP_LAYOUT
    pointers = [0x4300] + [0xFFFF] * (layout.level_count - 1)  # past the 402-byte pointer table
    stream = bytes([0x7F, 0x01] * 60 + [0x3C, 0x01, 0x00])  # 127 * 60 + 60 = 48 * 160
    objects = bytes([0x7F, 0x00] * 30 + [0x1E, 0x00, 0x00])  # 127 * 30 + 30 = 48 * 80
    return bytes(build_rom(size=0x200000, patches={
        layout.pointer_table.file_offset: le(*pointers),
        at(0x30, 0x4300): record(0x4000, 0x38, 0x6000),
        at(0x38, 0x4000): stream,
        at(0x38, 0x6000): objects,
    }))


def test_extract_refuses_unknown_rom(tmp_path):
    rom_path = tmp_path / "unknown cart.gbc"
    rom_path.write_bytes(wl3_shaped_rom())
    with pytest.raises(UnknownRomError):
        lm.extract(rom_path, tmp_path / "out")
    assert not (tmp_path / "out").exists()


def test_exploratory_extraction_is_marked_deterministic_and_schema_valid(tmp_path):
    rom_path = tmp_path / "unknown cart.gbc"
    rom_path.write_bytes(wl3_shaped_rom())
    first = lm.extract(rom_path, tmp_path / "out", exploratory=True)
    second = lm.extract(rom_path, tmp_path / "out", exploratory=True)
    assert first["changed"] and not second["changed"]
    output = tmp_path / "out" / "exploratory" / "level_block_maps.json"
    document = json.loads(output.read_text())
    schema = json.loads((PROJECT_ROOT / "schemas" / "level-block-maps.v2.schema.json").read_text())
    jsonschema.Draft202012Validator(schema).validate(document)
    assert document["exploratory"] is True and document["marker"] == ROM_DERIVED_MARKER
    assert document["maps"][0]["rows"] == 48 and document["audit"]["maps_with_incomplete_final_row"] == []
    assert len(document["maps"][0]["object_rows"]) == 48 and document["format_version"] == 2
    assert not (output.stat().st_mode & 0o222), "extracted base files are written read-only"
    manifest = json.loads((tmp_path / "out" / "exploratory" / "manifest.level_block_maps.json").read_text())
    assert manifest["files"]["level_block_maps.json"]["sha256"] == first["sha256"]


def test_malformed_wl3_layout_fails_clearly(tmp_path):
    rom_path = tmp_path / "zeros.gbc"
    rom_path.write_bytes(bytes(fix(build_rom(size=0x200000))))
    with pytest.raises(bf.MalformedDataError):
        lm.extract(rom_path, tmp_path / "out", exploratory=True)
