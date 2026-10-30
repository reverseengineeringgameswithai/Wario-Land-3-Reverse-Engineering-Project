"""The hidden figure's fight's drawing data (wl3pc.extract.temple) on a synthetic ROM, its addresses and the
port's constants against the reference build's symbols (WL3-052)."""

import re

from test_rooms import at
from test_title import _symbols
from wl3pc.address import BankedAddress
from wl3pc.extract import temple
from wl3pc.paths import PROJECT_ROOT

TEMPLE_VRAM = PROJECT_ROOT / "game" / "scripts" / "present" / "temple_vram.gd"
HIDDEN_FIGURE = PROJECT_ROOT / "game" / "scripts" / "sim" / "objects" / "hidden_figure_functions.gd"


def synthetic() -> bytes:
    rom = bytearray([0xFF]) * (0x80 * 0x4000)
    for where in temple.COMPRESSED:  # empty streams, but the figure's tiles: two bytes of $22
        rom[at(where.bank, where.address)] = 0
    start = at(0x36, 0x7068)
    rom[start:start + 3] = bytes([0x02, 0x22, 0x00])
    start = at(0x13, 0x504B)
    rom[start:start + 2] = bytes([0x1F, 0x00])
    return bytes(rom)


def test_graphics_maps_and_palettes_decode_from_their_places():
    document = temple.decode(synthetic())
    assert document["gfx"]["compressed"]["36:7068"] == "2222"
    assert all(document["gfx"]["compressed"][key] == "" for key in ("36:7193", "36:723b", "36:7268"))
    assert document["gfx"]["raw"]["36:4000"] == document["gfx"]["raw"]["36:5800"] == "ff" * 0x1800
    palettes = document["gfx"]["palettes"]
    assert palettes["13:504b"] == "1f00" + "ff" * 0x2E
    assert len(palettes["36:7000"]) == 0x80 and len(palettes["36:7040"]) == 0x50
    assert all(len(palettes[key]) == 0x60 for key in ("13:501b", "13:504b", "13:507b"))


def test_the_extractor_reads_the_labelled_data():
    names = _symbols()
    places = [*temple.COMPRESSED, *map(BankedAddress.parse, temple.RAW), *map(BankedAddress.parse, temple.PALETTES)]
    expected = ["HiddenFigure1Map", "HiddenFigure2Map", "HiddenFigure3Map", "HiddenFigure4Map", "HiddenFigure1Gfx",
                "HiddenFigure2Gfx", "Pals_db000", "Pals_db040", "Pals_4d01b", "Pals_4d04b", "Pals_4d07b"]
    for where, name in zip(places, expected, strict=True):
        assert names[name] == (where.bank, where.address), name
    # The data LoadHiddenFigureGfx copies whole ends where the next label starts.
    assert names["HiddenFigure2Gfx"][1] - names["HiddenFigure1Gfx"][1] == temple.RAW["36:4000"]
    assert names["Pals_db000"][1] - names["HiddenFigure2Gfx"][1] == temple.RAW["36:5800"]
    assert names["Pals_4d04b"][1] - names["Pals_4d01b"][1] == temple.PALETTES["13:501b"]


def test_the_ports_rom_constants_are_the_labels_they_name():
    names = _symbols()
    source = TEMPLE_VRAM.read_text()
    places = dict(re.findall(r'^const ([A-Z0-9_]+): String = "([0-9a-f]{2}:[0-9a-f]{4})"$', source, re.MULTILINE))
    labels = {"HIDDEN_FIGURE_1_GFX": "HiddenFigure1Gfx", "HIDDEN_FIGURE_2_GFX": "HiddenFigure2Gfx",
              "HIDDEN_FIGURE_1_MAP": "HiddenFigure1Map", "HIDDEN_FIGURE_2_MAP": "HiddenFigure2Map",
              "HIDDEN_FIGURE_3_MAP": "HiddenFigure3Map", "HIDDEN_FIGURE_4_MAP": "HiddenFigure4Map",
              "PALS_DB000": "Pals_db000", "PALS_DB040": "Pals_db040"}
    assert set(places) == set(labels)
    for constant, where in places.items():
        assert names[labels[constant]] == (int(where[:2], 16), int(where[3:], 16)), constant
    pals = re.findall(r"^const PALS_(4D0[0-9A-F]{2}): int = 0x([0-9A-F]{4})", HIDDEN_FIGURE.read_text(), re.MULTILINE)
    assert len(pals) == 3
    for label, value in pals:
        assert names[f"Pals_{label.lower()}"] == (0x13, int(value, 16)), label
