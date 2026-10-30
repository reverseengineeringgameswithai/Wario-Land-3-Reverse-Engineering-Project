"""The clear screen's data (wl3pc.extract.clear) on a synthetic ROM, and its addresses against the
reference build's symbols (WL3-043)."""

import re

import pytest

from test_rooms import at
from wl3pc.address import BankedAddress, RomView
from wl3pc.extract import clear
from wl3pc.extract.block_functions import MalformedDataError
from wl3pc.paths import BUILD_DIR, PROJECT_ROOT

SYM = BUILD_DIR / "refbuild" / "electrodeoxys-560fce6" / "warioland3.sym"


def synthetic() -> bytes:
    rom = bytearray([0xFF]) * (0x80 * 0x4000)
    for where in clear.OAM_TABLES:  # one frame each, one entry
        start = at(where.bank, where.address)
        rom[start:start + 7] = (where.address + 2).to_bytes(2, "little") + bytes([0xF8, 0xFC, 0x04, 0x01, 0x80])
    start = at(0x35, 0x5059)
    rom[start:start + 3] = bytes([7, 12, 0xFF])
    for where in clear.COMPRESSED:  # empty streams
        rom[at(where.bank, where.address)] = 0
    return bytes(rom)


def test_framesets_oam_tables_and_tables_decode_from_their_places():
    document = clear.decode(synthetic())
    assert document["framesets"]["35:5059"] == [[7, 12]]
    assert document["framesets"]["35:4d18"] == []
    assert document["oam_tables"]["7c:556c"] == [[[-8, -4, 4, 1]]]
    assert len(bytes.fromhex(document["tables"]["level_treasure_ids"]["bytes"])) == 100
    assert document["gfx"]["compressed"]["78:57fa"] == "" and len(document["gfx"]["palettes"]) == 6
    assert len(bytes.fromhex(document["gfx"]["raw"]["26:4000"])) == 101 * 64


def test_a_frame_in_home_bank_0_is_read_there():
    rom = bytearray(synthetic())
    start = at(0x7C, 0x556C)
    rom[start:start + 9] = (0x5570).to_bytes(2, "little") + (0x1826).to_bytes(2, "little") + bytes([0, 0, 1, 0, 0x80])
    rom[0x1826] = 0x80  # an empty frame
    assert clear.decode_oam_table(RomView(bytes(rom)), BankedAddress(0x7C, 0x556C)) == [[[0, 0, 1, 0]], []]
    rom[start + 2:start + 4] = (0x9000).to_bytes(2, "little")
    with pytest.raises(MalformedDataError):
        clear.decode_oam_table(RomView(bytes(rom)), BankedAddress(0x7C, 0x556C))


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
    labels = {where: name for name, where in names.items() if "." not in name}
    at: dict[tuple[int, int], set[str]] = {}
    for name, where in names.items():
        at.setdefault(where, set()).add(name)
    for where in clear.FRAMESETS:
        assert labels.get((where.bank, where.address), "").startswith("Frameset_"), str(where)
    for where in clear.OAM_TABLES:
        assert labels.get((where.bank, where.address), "").startswith("OAM_"), str(where)
    expected = {"pencil_x_offsets": "PencilScribbleXOffsets", "pencil_y_offsets": "PencilScribbleYOffsets",
                "musical_coin_level_bg_pals": "MusicalCoinLevelBGPals",
                "level_treasure_ids": "LevelTreasureIDs_WithoutTemple"}
    for name, (where, _) in clear.TABLES.items():
        assert names[expected[name]] == (where.bank, where.address), name
    graphics = ["ClearScreen1Gfx", "ClearScreen2Gfx", "ClearScreenTreasureTilemap", "ClearScreenTreasureAttrmap",
                "ClearScreenTimeAttackTilemap", "ClearScreenTimeAttackAttrmap", "GolfMenuGfx", "GolfMenuTilemap",
                "GolfMenuAttrmap"]
    raw = ["WarioClearGfx", "TreasureGfx", "TreasureOBPals", "TreasurePals", "LevelTreasureIDs"]
    palettes = ["Pals_1e0378", "Pals_1e03b8", "Pals_1e03f8", "Pals_1e0438", "Pals_d50a4", "Pals_d50e4"]
    for places, expected_names in ((clear.COMPRESSED, graphics), (tuple(map(BankedAddress.parse, clear.RAW)), raw),
                                   (clear.PALETTES, palettes)):
        for where, name in zip(places, expected_names, strict=True):
            assert name in at.get((where.bank, where.address), set()), (str(where), name)


def test_clear_sims_ram_constants_are_the_labels_they_name():
    names = {name.lower(): where for name, where in _symbols().items()}
    screens = PROJECT_ROOT / "game" / "scripts" / "sim" / "screens"
    source = (screens / "clear_sim.gd").read_text() + (screens / "menu_screen_sim.gd").read_text()
    checked = 0
    for constant, value in re.findall(r"^const (W[0-9A-Z_]+): int = 0x([0-9A-F]{4})$", source, re.MULTILINE):
        label = constant.replace("_", "").lower()
        assert label in names, constant
        assert names[label][1] == int(value, 16), constant
        checked += 1
    assert checked >= 20
