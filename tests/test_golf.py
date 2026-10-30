"""The golf minigame's data (wl3pc.extract.golf) on a synthetic ROM, and its addresses against the
reference build's symbols (WL3-050)."""

import re

import pytest

from test_rooms import at
from wl3pc.address import BankedAddress
from wl3pc.extract import golf
from wl3pc.extract.block_functions import MalformedDataError
from wl3pc.paths import BUILD_DIR, PROJECT_ROOT

SYM = BUILD_DIR / "refbuild" / "electrodeoxys-560fce6" / "warioland3.sym"


def synthetic() -> bytes:
    rom = bytearray([0xFF]) * (0x80 * 0x4000)
    empty = 0x7F00  # an empty compressed stream for every map
    rom[at(golf.GOLF_HOLE_DATA_BANK, empty)] = 0
    for where in golf.COMPRESSED:
        rom[at(where.bank, where.address)] = 0
    for index in range(golf.NUM_GOLF_HOLES):
        entry = at(golf.GOLF_HOLES.bank, golf.GOLF_HOLES.address + index * golf.GOLF_HOLE_ENTRY_SIZE)
        data = 0x4000 + index * golf.GOLF_HOLE_DATA_SIZE
        rom[entry:entry + 10] = data.to_bytes(2, "little") + empty.to_bytes(2, "little") * 4
        start = at(golf.GOLF_HOLE_DATA_BANK, data)
        rom[start:start + golf.GOLF_HOLE_DATA_SIZE] = bytes([index]) * golf.GOLF_HOLE_DATA_SIZE
    start = at(0x72, 0x6F6F)
    rom[start:start + 5] = bytes([26, 8, 27, 8, 0xFF])
    for where in golf.OAM_TABLES:  # one frame of one entry each
        start = at(where.bank, where.address)
        rom[start:start + 7] = (where.address + 2).to_bytes(2, "little") + bytes([0xF8, 0xFC, 0x80, 0x05, 0x80])
    return bytes(rom)


def test_framesets_holes_and_digits_decode_from_their_places():
    document = golf.decode(synthetic())
    assert document["framesets"]["72:6f6f"] == [[26, 8], [27, 8]]
    assert document["framesets"]["00:2da4"] == []  # an $ff first: empty
    assert len(document["holes"]) == 20
    assert document["holes"][3]["data_location"] == f"70:{0x4000 + 3 * 70:04x}"
    assert document["holes"][3]["data"] == "03" * 70
    assert len(bytes.fromhex(document["stroke_numbers"]["bytes"])) == 320
    assert document["oam_tables"]["72:72d3"] == [[[-8, -4, 0x80, 0x05]]]
    assert document["holes"][0]["maps"] == ["7f00"] * 4 and document["gfx"]["compressed"]["70:7f00"] == ""
    assert len(bytes.fromhex(document["gfx"]["wario_tiles"]["71:4000"])) == 0x800
    assert len(document["gfx"]["palettes"]) == 12


def test_a_frameset_without_its_terminator_is_refused():
    rom = bytearray(synthetic())
    start = at(0x72, 0x6F6F)
    rom[start:start + 0x200] = bytes([1]) * 0x200
    with pytest.raises(MalformedDataError):
        golf.decode_frameset(golf.RomView(bytes(rom)), BankedAddress(0x72, 0x6F6F))


def _symbols() -> dict[str, tuple[int, int]]:
    if not SYM.exists():
        pytest.skip(f"SKIPPED (no reference-build symbols at {SYM}; run `make refbuild`)")
    names: dict[str, tuple[int, int]] = {}
    for line in SYM.read_text().splitlines():
        match = re.match(r"([0-9a-f]{2}):([0-9a-f]{4}) (\S+)$", line)
        if match:
            names.setdefault(match.group(3), (int(match.group(1), 16), int(match.group(2), 16)))
    return names


def test_the_extractor_reads_the_labelled_data():
    names = _symbols()
    labels = {where: name for name, where in names.items()}
    for where in golf.FRAMESETS:
        name = labels.get((where.bank, where.address))
        if where == BankedAddress(0x72, 0x4E23):  # read past UpdateGolfParaGoom's table
            assert names["Frameset_1c8e21"] == (0x72, 0x4E21)
            continue
        assert name is not None and name.startswith("Frameset_"), str(where)
    assert names["GolfHoles"] == (golf.GOLF_HOLES.bank, golf.GOLF_HOLES.address)
    assert names["GolfHole00"][0] == golf.GOLF_HOLE_DATA_BANK
    assert names["GolfStrokeNumbersGfx"] == (golf.STROKE_NUMBERS.bank, golf.STROKE_NUMBERS.address)
    assert names["wGolfHoleDataEnd"][1] - names["wGolfHoleData"][1] == golf.GOLF_HOLE_DATA_SIZE
    for where in golf.OAM_TABLES:
        name = labels.get((where.bank, where.address))
        assert name is not None and name.startswith("OAM_"), str(where)
    # The golf building's menu: its maps, its courses' attribute rows, and the scroll's.
    for name in ("GolfMenuGfx", "GolfBuildingCoursesLockedTilemap", "GolfBuildingCoursesUnlockedTilemap",
                 "GolfBuildingCoursesAttrmap"):
        assert BankedAddress(*names[name]) in golf.COMPRESSED, name
    raw = {where: size for where, size in golf.RAW}
    for name in ("GolfBuildingCourseScrollingAttrmap", "GolfBuildingCourse1Tilemap", "GolfBuildingCourse2Tilemap",
                 "GolfBuildingCourse3Tilemap", "GolfBuildingCourse4Tilemap"):
        assert raw.get(BankedAddress(*names[name])) == golf.COURSE_ROWS_SIZE, name
    assert names["GolfBuildingCoursesLockedTilemap"][1] - names["GolfBuildingCourse4Tilemap"][1] == golf.COURSE_ROWS_SIZE


def test_golf_sims_ram_constants_are_the_labels_they_name():
    names = {name.lower(): where for name, where in _symbols().items()}
    source = (PROJECT_ROOT / "game" / "scripts" / "sim" / "golf" / "golf_sim.gd").read_text()
    checked = 0
    for constant, value in re.findall(r"^const (W[0-9A-Z_]+): int = 0x([0-9A-F]{4})", source, re.MULTILINE):
        label = constant.replace("_", "").lower()
        address = int(value, 16)
        assert label in names, constant
        assert names[label] == (0 if address < 0xD000 else 1, address), constant  # WRAM0, or golf RAM's bank
        checked += 1
    assert checked > 80
