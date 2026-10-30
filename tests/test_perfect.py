"""The Perfect screen's data (wl3pc.extract.perfect) on a synthetic ROM, its addresses and the port's constants
against the reference build's symbols (WL3-052)."""

import re

import pytest

from test_credits import _linear
from test_rooms import at
from test_title import _symbols
from wl3pc.address import BankedAddress
from wl3pc.extract import perfect
from wl3pc.extract.block_functions import MalformedDataError
from wl3pc.paths import PROJECT_ROOT

PORT = PROJECT_ROOT / "game" / "scripts" / "sim" / "screens" / "perfect_sim.gd"


def synthetic() -> bytes:
    rom = bytearray([0xFF]) * (0x80 * 0x4000)
    start = at(0x37, 0x5710)  # one frame, one entry
    rom[start:start + 7] = (0x5712).to_bytes(2, "little") + bytes([0xF0, 0xF8, 0x02, 0x00, 0x80])
    start = at(0x37, 0x5848)
    rom[start:start + 5] = bytes([3, 7, 4, 9, 0xFF])
    for where in perfect.COMPRESSED:  # empty streams, but the graphics': two bytes of $11
        rom[at(where.bank, where.address)] = 0
    start = at(0x37, 0x423B)
    rom[start:start + 3] = bytes([0x02, 0x11, 0x00])
    start = at(0x37, 0x41B3)
    rom[start:start + 2] = bytes([0xFF, 0x7F])
    return bytes(rom)


def test_the_frameset_oam_table_graphics_and_palettes_decode_from_their_places():
    document = perfect.decode(synthetic())
    assert document["framesets"] == {"37:5848": [[3, 7], [4, 9]]}
    assert document["oam_tables"] == {"37:5710": [[[-16, -8, 2, 0]]]}
    assert document["gfx"]["compressed"]["37:423b"] == "1111"
    assert document["gfx"]["compressed"]["37:5417"] == document["gfx"]["compressed"]["37:55b5"] == ""
    assert document["gfx"]["palettes"]["37:41b3"] == "ff7f" + "ff" * 0x16
    assert [len(value) // 2 for value in document["gfx"]["palettes"].values()] == [0x40, 0x18, 0x18, 0x18, 0x40]


def test_a_frameset_without_its_terminator_is_refused():
    rom = bytearray(synthetic())
    start = at(0x37, 0x5848)
    rom[start:at(0x38, 0x4000)] = bytes([1]) * (at(0x38, 0x4000) - start)
    with pytest.raises(MalformedDataError):
        perfect.decode(bytes(rom))


def test_the_extractor_reads_the_labelled_data():
    names = _symbols()
    labels = {where: name for name, where in names.items() if "." not in name}
    assert [labels.get((where.bank, where.address)) for where in perfect.FRAMESETS] == ["Frameset_dd848"]
    assert [labels.get((where.bank, where.address)) for where in perfect.OAM_TABLES] == ["OAM_dd710"]
    places = [*perfect.COMPRESSED, *map(BankedAddress.parse, perfect.PALETTES)]
    expected = ["PerfectGfx", "PerfectTilemap", "PerfectAttrmap", "Pals_dc173", "Pals_dc1b3", "Pals_dc1cb", "Pals_dc1e3",
                "Pals_dc1fb"]
    for where, name in zip(places, expected, strict=True):
        assert names[name] == (where.bank, where.address), name


def test_the_ports_rom_constants_are_the_labels_they_name():
    names = _symbols()
    source = PORT.read_text()
    framesets = re.findall(r"^const FRAMESET_([0-9A-F]{5}): int = 0x([0-9A-F]{4})$", source, re.MULTILINE)
    assert len(framesets) == len(perfect.FRAMESETS)
    for label, value in framesets:
        bank = int(label, 16) // 0x4000
        assert _linear(bank, int(value, 16)) == int(label, 16)
        assert names[f"Frameset_{label.lower()}"] == (bank, int(value, 16)), label
    value = int(re.search(r"^const OAM_DD710: int = 0x([0-9A-F]{4})$", source, re.MULTILINE).group(1), 16)
    assert names["OAM_dd710"][1] == value
    pals = dict(re.findall(r'^const (PALS_[0-9A-F]{5}): String = "([0-9a-f]{2}:[0-9a-f]{4})"$', source, re.MULTILINE))
    assert len(pals) == 5
    for constant, where in pals.items():
        assert names["Pals_" + constant[5:].lower()] == (int(where[:2], 16), int(where[3:], 16)), constant


def test_the_perfect_ram_constants_are_the_labels_they_name():
    names: dict[str, tuple[int, int]] = {}
    for name, where in _symbols().items():  # without their underscores: W_UNUSED_C186, wUnused_c186
        names.setdefault(name.replace("_", "").lower(), where)
    checked = 0
    for constant, value in re.findall(r"^const (W[0-9A-Z_]+): int = 0x([0-9A-F]{4})$", PORT.read_text(), re.MULTILINE):
        label = constant.replace("_", "").lower()
        assert label in names, constant
        assert names[label][1] == int(value, 16), constant
        checked += 1
    assert checked >= 8
