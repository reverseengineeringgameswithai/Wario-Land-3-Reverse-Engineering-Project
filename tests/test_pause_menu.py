"""The pause menu's and the save screens' data (wl3pc.extract.pause_menu) on a synthetic ROM, and their
addresses and the port's RAM and SRAM constants against the reference build's symbols (WL3-052)."""

import re

import pytest

from test_rooms import at
from wl3pc.address import BankedAddress
from wl3pc.extract import pause_menu
from wl3pc.paths import BUILD_DIR, PROJECT_ROOT

SYM = BUILD_DIR / "refbuild" / "electrodeoxys-560fce6" / "warioland3.sym"


def synthetic() -> bytes:
    rom = bytearray([0xFF]) * (0x80 * 0x4000)
    for where in pause_menu.OAM_TABLES:  # one frame, one entry
        start = at(where.bank, where.address)
        rom[start:start + 7] = (where.address + 2).to_bytes(2, "little") + bytes([0xF8, 0xFC, 0x04, 0x01, 0x80])
    start = at(0x7C, 0x5CB8)
    rom[start:start + 3] = bytes([22, 50, 0xFF])
    for where in pause_menu.COMPRESSED:  # empty streams
        rom[at(where.bank, where.address)] = 0
    start = at(0x7D, 0x628C)
    rom[start:start + 2] = bytes([0xC0, 0x42])
    start = at(0x7D, 0x41C2)
    rom[start:start + 2] = bytes([0x16, 0x58])
    return bytes(rom)


def test_framesets_oam_table_graphics_maps_and_palettes_decode_from_their_places():
    document = pause_menu.decode(synthetic())
    assert document["framesets"]["7c:5cb8"] == [[22, 50]]
    assert document["framesets"]["7c:5c4a"] == []
    assert len(document["framesets"]) == 21
    assert document["oam_tables"]["7c:556c"] == [[[-8, -4, 4, 1]]]
    assert document["gfx"]["compressed"]["7d:6949"] == ""
    assert len(bytes.fromhex(document["gfx"]["raw"]["76:6800"])) == 0x800
    assert document["gfx"]["palettes"]["7d:628c"][:4] == "c042"
    assert document["gfx"]["palettes"]["7d:41c2"][:4] == "1658"
    assert len(bytes.fromhex(document["gfx"]["palettes"]["7d:4182"])) == 0x40


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
    for where in pause_menu.FRAMESETS:
        assert labels.get((where.bank, where.address), "").startswith("Frameset_1f1"), str(where)
    assert [labels.get((where.bank, where.address)) for where in pause_menu.OAM_TABLES] == ["OAM_1f156c"]
    places = [*pause_menu.COMPRESSED, *map(BankedAddress.parse, pause_menu.RAW),
              *map(BankedAddress.parse, pause_menu.PALETTES)]
    expected = ["SaveBoxGfx", "SaveInProgressBoxTilemap", "SaveInProgressBoxAttrmap", "SaveCompleteBoxTilemap",
                "SaveCompleteBoxAttrmap", "PauseMenuGfx", "PauseMenuTilemap", "PauseMenuAttrmap",
                "TimeAttackPauseMenuTilemap", "TimeAttackPauseMenuAttrmap", "WarioSleepGfx", "ActionHelpOwlGfx",
                "ActionHelpRailGfx", "ActionHelpVampireGfx", "Pals_1f628c", "Pals_1f4182", "Pals_1f41c2"]
    for where, name in zip(places, expected, strict=True):
        assert names[name] == (where.bank, where.address), name


def test_the_pause_menus_framesets_are_the_ones_the_port_names():
    source = (PROJECT_ROOT / "game" / "scripts" / "sim" / "screens" / "pause_menu_sim.gd").read_text()
    named = {int(value, 16) for value in re.findall(r"^const FRAMESET_1F1[0-9A-F]{3}: int = 0x([0-9A-F]{4})$",
                                                     source, re.MULTILINE)}
    assert named == {where.address for where in pause_menu.FRAMESETS}


def test_the_pause_menus_ram_and_sram_constants_are_the_labels_they_name():
    names: dict[str, tuple[int, int]] = {}
    for name, where in _symbols().items():  # without their underscores: W_UNUSED_IS_PAUSED, wUnused_IsPaused
        names.setdefault(name.replace("_", "").lower(), where)
    source = (PROJECT_ROOT / "game" / "scripts" / "sim" / "screens" / "pause_menu_sim.gd").read_text()
    checked = 0
    for constant, value in re.findall(r"^const ([WS][0-9A-Z_]+): int = 0x([0-9A-F]{4})$", source, re.MULTILINE):
        label = constant.replace("_", "").lower()
        assert label in names, constant
        assert names[label][1] == int(value, 16), constant
        checked += 1
    assert checked >= 70
