import json

import jsonschema
import pytest

import test_rooms
from synthetic_rom import fix, build_rom
from wl3pc.address import BankedAddress
from wl3pc.extract import block_functions as bf
from wl3pc.extract import level_headers as lh
from wl3pc.paths import PROJECT_ROOT
from wl3pc.provenance import ROM_DERIVED_MARKER
from wl3pc.rom import UnknownRomError
from wl3pc.symbols import parse_sym

le, at = test_rooms.le, test_rooms.at

# Builds on the synthetic room ROM from test_rooms, where rooms 1 and 3 are
# decoded and rooms 0 and 2 are reset sentinels. Levels below 2 read their
# lists from bank 1; level 2 and up read them from bank 6.
LAYOUT = lh.LevelHeaderLayout(
    rom_id="synthetic", level_pointer_table=BankedAddress(1, 0x4300), level_count=3, group2_first_level=2,
    group1_bank=1, group2_bank=6, entries_per_list=3, rooms=test_rooms.LAYOUT,
    object_group_count=4, special_object_groups=(0xF0,), animated_tiles_group_count=2, pal_cycle_count=2,
)

HEADER_A = bytes([0x21, 0x13, 0x02, 0x18, 0x03, 0x01, 0x01, 0x01])
HEADER_B = bytes([0x00, 0x01, 0x01, 0x00, 0xF0, 0x00, 0x00, 0x03])  # $f0 is the hidden-figure object group
HEADER_C = bytes([0x10, 0x02, 0x9A, 0x00, 0x00, 0x00, 0x00, 0x03])


def synthetic(levels=(0x4400, 0xFFFF, 0x6000), extra=None) -> bytes:
    patches = {
        at(1, 0x4300): le(*levels),
        at(1, 0x4400): le(0x4410, 0xFF00, 0x4418),
        at(1, 0x4410): HEADER_A,
        at(1, 0x4418): HEADER_B,
        at(6, 0x6000): le(0x6010, 0x6010, 0xFFFF),
        at(6, 0x6010): HEADER_C,
    }
    patches.update(extra or {})
    return test_rooms.synthetic(extra=patches)


def test_decodes_levels_lists_and_headers():
    document = lh.decode(synthetic(), LAYOUT)
    assert [lv["status"] for lv in document["levels"]] == ["decoded", "reset-sentinel", "decoded"]
    assert document["levels"][1]["pointer"] == "ffff"
    assert document["levels"][0] == {"level": 0, "status": "decoded", "list": "01:4400",
                                     "start_header": "01:4410", "start_room": 1}
    # Level 2 is in group 2: the same kind of 16-bit pointer is read from bank 6.
    assert document["levels"][2]["list"] == "06:6000" and document["levels"][2]["start_room"] == 3
    assert [(lst["location"], lst["entries"]) for lst in document["lists"]] == [
        ("01:4400", ["01:4410", None, "01:4418"]),  # $ff00 resets: only the high byte is tested
        ("06:6000", ["06:6010", "06:6010", None]),
    ]
    headers = {h["location"]: h["fields"] for h in document["headers"]}
    assert len(headers) == 3  # the shared header is decoded once
    assert headers["01:4410"] == {"spawn_y": 2, "spawn_x": 1, "upper_y_limit": 1, "lower_y_limit": 3,
                                  "left_x_limit": 0, "right_x_limit": 2, "camera_config": 0x18,
                                  "object_group": 3, "animated_tiles_group": 1, "pal_cycle": 1, "room": 1}
    assert headers["06:6010"]["left_x_limit"] == 9 and headers["06:6010"]["right_x_limit"] == 10
    assert document["audit"] == {"levels_starting_on_reset_entry": [], "decoded_rooms_not_referenced": []}


def test_shared_lists_and_reset_start_entries_are_reported():
    document = lh.decode(synthetic(levels=(0x4400, 0x4400, 0x6000), extra={at(6, 0x6000): le(0xFFFF, 0x6010, 0x6010)}),
                         LAYOUT)
    assert document["lists"][0]["used_by_levels"] == [0, 1]
    assert document["levels"][2]["start_header"] is None and document["levels"][2]["start_room"] is None
    assert document["audit"]["levels_starting_on_reset_entry"] == [2]


@pytest.mark.parametrize("patch, message", [
    ({at(1, 0x4300): le(0xC000)}, "level 0x00: pointer 0xc000 is not a ROM address"),
    ({at(1, 0x4300): le(0x7FFC)}, "level 0x00 list: 6 byte"),
    ({at(1, 0x4400): le(0x4402)}, "header 01:4402 is inside its 3-entry list"),
    ({at(1, 0x4400): le(0x7FFC)}, "list 01:4400 entry 0: 8 byte"),
    ({at(1, 0x4417): bytes([0])}, "room 0x00 is a reset sentinel"),
    ({at(1, 0x4417): bytes([2])}, "room 0x02 is a reset sentinel"),
    ({at(1, 0x4417): bytes([4])}, "room 0x04 is outside its 4-entry table"),
    ({at(1, 0x4414): bytes([4])}, "object group 0x04 is outside its 4-entry table"),
    ({at(1, 0x4415): bytes([2])}, "animated_tiles_group 0x02 is outside its 2-entry table"),
    ({at(1, 0x4416): bytes([2])}, "pal_cycle 0x02 is outside its 2-entry table"),
])
def test_rejects_structural_violations(patch, message):
    with pytest.raises(bf.MalformedDataError, match=message):
        lh.decode(synthetic(extra=patch), LAYOUT)


def test_labels_are_optional_and_do_not_change_values():
    plain = lh.decode(synthetic(), LAYOUT)
    symbols = parse_sym("01:4400 ListA\n01:4410 ListA.room_00\n06:6000 ListB\n", include_local=True)
    labelled = lh.annotate(lh.decode(synthetic(), LAYOUT), symbols)
    assert [h["fields"] for h in labelled["headers"]] == [h["fields"] for h in plain["headers"]]
    assert labelled["lists"][0]["symbol"] == "ListA" and labelled["headers"][0]["symbol"] == "ListA.room_00"
    assert labelled["audit"]["lists_without_symbol"] == []
    assert labelled["audit"]["headers_without_symbol"] == ["01:4418", "06:6010"]


def wl3_shaped_rom() -> bytes:
    """2 MiB synthetic ROM with one level whose list starts in the one decodable room."""
    layout = lh.WL3_WORLD_LEVEL_LAYOUT
    levels = [0x4D1F] + [0xFFFF] * (layout.level_count - 1)
    entries = [0x4D5B] + [0xFFFF] * (layout.entries_per_list - 1)
    return test_rooms.wl3_shaped_rom(extra={
        layout.level_pointer_table.file_offset: le(*levels),
        at(0x30, 0x4D1F): le(*entries),
        at(0x30, 0x4D5B): bytes([0x11, 0x12, 0x01, 0x00, 0x01, 0x00, 0x00, 0x01]),
    })


def test_extract_refuses_unknown_rom(tmp_path):
    rom_path = tmp_path / "unknown cart.gbc"
    rom_path.write_bytes(wl3_shaped_rom())
    with pytest.raises(UnknownRomError):
        lh.extract(rom_path, tmp_path / "out")
    assert not (tmp_path / "out").exists()


def test_exploratory_extraction_is_marked_deterministic_and_schema_valid(tmp_path):
    rom_path = tmp_path / "unknown cart.gbc"
    rom_path.write_bytes(wl3_shaped_rom())
    first = lh.extract(rom_path, tmp_path / "out", exploratory=True)
    second = lh.extract(rom_path, tmp_path / "out", exploratory=True)
    assert first["changed"] and not second["changed"]
    output = tmp_path / "out" / "exploratory" / "level_headers.json"
    document = json.loads(output.read_text())
    schema = json.loads((PROJECT_ROOT / "schemas" / "level-headers.v1.schema.json").read_text())
    jsonschema.Draft202012Validator(schema).validate(document)
    assert document["exploratory"] is True and document["marker"] == ROM_DERIVED_MARKER
    assert document["levels"][0]["start_room"] == 1
    # Group 1 ends at level $63; every later level, including THE_TEMPLE ($c8), is a reset sentinel here.
    assert sum(lv["status"] == "reset-sentinel" for lv in document["levels"]) == 0xC8
    assert not (output.stat().st_mode & 0o222), "extracted base files are written read-only"
    manifest = json.loads((tmp_path / "out" / "exploratory" / "manifest.level_headers.json").read_text())
    assert manifest["files"]["level_headers.json"]["sha256"] == first["sha256"]


def test_malformed_wl3_layout_fails_clearly(tmp_path):
    rom_path = tmp_path / "zeros.gbc"
    rom_path.write_bytes(bytes(fix(build_rom(size=0x200000))))
    with pytest.raises(bf.MalformedDataError):
        lh.extract(rom_path, tmp_path / "out", exploratory=True)
