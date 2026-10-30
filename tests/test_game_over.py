"""The game over screen's data (wl3pc.extract.game_over) on a synthetic ROM, its addresses and the port's
constants against the reference build's symbols (WL3-052)."""

import re

import pytest

from test_credits import _linear
from test_rooms import at
from test_title import _symbols
from wl3pc.address import BankedAddress
from wl3pc.extract import game_over
from wl3pc.extract.block_functions import MalformedDataError
from wl3pc.paths import PROJECT_ROOT

PORT = PROJECT_ROOT / "game" / "scripts" / "sim" / "screens" / "game_over_sim.gd"


def synthetic() -> bytes:
    rom = bytearray([0xFF]) * (0x80 * 0x4000)
    for where in game_over.OAM_TABLES:  # one frame, one entry
        start = at(where.bank, where.address)
        rom[start:start + 7] = (where.address + 2).to_bytes(2, "little") + bytes([0xF0, 0xF8, 0x02, 0x00, 0x80])
    start = at(0x2A, 0x6CCB)
    rom[start:start + 5] = bytes([3, 7, 4, 9, 0xFF])
    for where in game_over.COMPRESSED:  # empty streams, but the graphics': two bytes of $11
        rom[at(where.bank, where.address)] = 0
    start = at(0x36, 0x7589)
    rom[start:start + 3] = bytes([0x02, 0x11, 0x00])
    start = at(0x21, 0x6AD5)
    rom[start:start + 2] = bytes([0xFF, 0x7F])
    return bytes(rom)


def test_framesets_oam_tables_graphics_and_palettes_decode_from_their_places():
    document = game_over.decode(synthetic())
    assert document["framesets"]["2a:6ccb"] == [[3, 7], [4, 9]]
    assert document["framesets"]["36:7bf5"] == []
    assert len(document["framesets"]) == 3
    assert document["oam_tables"]["2a:6b5c"] == document["oam_tables"]["36:7bd2"] == [[[-16, -8, 2, 0]]]
    assert document["gfx"]["compressed"]["36:7589"] == "1111"
    assert document["gfx"]["compressed"]["36:7aee"] == document["gfx"]["compressed"]["36:7b8f"] == ""
    assert document["gfx"]["raw"]["76:6800"] == "ff" * 0x800
    assert document["gfx"]["palettes"]["21:6ad5"] == "ff7f" + "ff" * 6
    assert len(document["gfx"]["palettes"]["36:7509"]) == len(document["gfx"]["palettes"]["36:7549"]) == 0x80


def test_a_frameset_without_its_terminator_is_refused():
    rom = bytearray(synthetic())
    start = at(0x36, 0x7BF5)
    rom[start:at(0x37, 0x4000)] = bytes([1]) * (at(0x37, 0x4000) - start)
    with pytest.raises(MalformedDataError):
        game_over.decode(bytes(rom))


def test_the_extractor_reads_the_labelled_data():
    names = _symbols()
    labels = {where: name for name, where in names.items() if "." not in name}
    assert [labels.get((where.bank, where.address)) for where in game_over.FRAMESETS] == [
        "Frameset_aaccb", "Frameset_aace2", "Frameset_dbbf5"]
    assert [labels.get((where.bank, where.address)) for where in game_over.OAM_TABLES] == ["OAM_aab5c", "OAM_dbbd2"]
    places = [*game_over.COMPRESSED, *map(BankedAddress.parse, game_over.RAW),
              *map(BankedAddress.parse, game_over.PALETTES)]
    expected = ["GameOverGfx", "GameOverTilemap", "GameOverAttrmap", "WarioSleepGfx", "Pals_db509", "Pals_db549",
                "Pals_86ad5"]
    for where, name in zip(places, expected, strict=True):
        assert names[name] == (where.bank, where.address), name


def test_the_ports_rom_constants_are_the_labels_they_name():
    names = _symbols()
    source = PORT.read_text()
    framesets = re.findall(r"^const FRAMESET_([0-9A-F]{5}): int = 0x([0-9A-F]{4})$", source, re.MULTILINE)
    assert len(framesets) == len(game_over.FRAMESETS)
    for label, value in framesets:
        bank = int(label, 16) // 0x4000
        assert _linear(bank, int(value, 16)) == int(label, 16)
        assert names[f"Frameset_{label.lower()}"] == (bank, int(value, 16)), label
    for label in ("OAM_AAB5C", "OAM_DBBD2"):
        value = int(re.search(rf"^const {label}: int = 0x([0-9A-F]{{4}})$", source, re.MULTILINE).group(1), 16)
        assert names[f"OAM_{label[4:].lower()}"][1] == value, label
    pals = dict(re.findall(r'^const (PALS_[0-9A-F]{5}): String = "([0-9a-f]{2}:[0-9a-f]{4})"$', source, re.MULTILINE))
    assert len(pals) == 3
    for constant, where in pals.items():
        assert names["Pals_" + constant[5:].lower()] == (int(where[:2], 16), int(where[3:], 16)), constant


def test_the_game_over_ram_constants_are_the_labels_they_name():
    names: dict[str, tuple[int, int]] = {}
    for name, where in _symbols().items():  # without their underscores: W_GAME_OVER_WARIO_VAR, wGameOverWarioVar
        names.setdefault(name.replace("_", "").lower(), where)
    checked = 0
    for constant, value in re.findall(r"^const (W[0-9A-Z_]+): int = 0x([0-9A-F]{4})$", PORT.read_text(), re.MULTILINE):
        label = constant.replace("_", "").lower()
        assert label in names, constant
        assert names[label][1] == int(value, 16), constant
        checked += 1
    assert checked >= 8
