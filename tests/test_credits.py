"""The credits' data (wl3pc.extract.credits) on a synthetic ROM, its addresses and the port's constants
against the reference build's symbols (WL3-052)."""

import re

import pytest

from test_rooms import at
from test_title import _symbols
from wl3pc.address import BankedAddress
from wl3pc.extract import credits
from wl3pc.extract.block_functions import MalformedDataError
from wl3pc.paths import PROJECT_ROOT

PORT = PROJECT_ROOT / "game" / "scripts" / "sim" / "screens" / "credits_sim.gd"


def synthetic() -> bytes:
    rom = bytearray([0xFF]) * (0x80 * 0x4000)
    for where in credits.OAM_TABLES:  # one frame, one entry
        start = at(where.bank, where.address)
        rom[start:start + 7] = (where.address + 2).to_bytes(2, "little") + bytes([0xF0, 0xF8, 0x02, 0x00, 0x80])
    start = at(0x58, 0x5CAF)
    rom[start:start + 5] = bytes([16, 11, 17, 10, 0xFF])
    for where in credits.COMPRESSED:  # empty streams
        rom[at(where.bank, where.address)] = 0
    start = at(0x58, 0x44CC)
    rom[start:start + 2] = bytes([0xFF, 0x7F])
    # 288 lines: "A" and its end, empty ones, and a last one of blanks up to CreditsPalsMap.
    text = bytes([0x40, credits.TEXT_END]) + bytes([credits.TEXT_END]) * (credits.CREDITS_LINES - 2)
    size = credits.CREDITS_PALS_MAP.address - credits.CREDITS_TEXT.address
    text += bytes([0x7E]) * (size - len(text))
    start = at(0x58, credits.CREDITS_TEXT.address)
    rom[start:start + size] = text[:size - 1] + bytes([credits.TEXT_END])
    start = at(0x58, credits.CREDITS_PALS_MAP.address)
    rom[start:start + 3] = bytes([1, 2, 3])
    return bytes(rom)


def test_framesets_oam_tables_graphics_text_and_palettes_decode_from_their_places():
    document = credits.decode(synthetic())
    assert document["framesets"]["58:5caf"] == [[16, 11], [17, 10]]
    assert document["framesets"]["57:67ed"] == []
    assert len(document["framesets"]) == 7
    assert document["oam_tables"]["58:57e8"] == document["oam_tables"]["57:644a"] == [[[-16, -8, 2, 0]]]
    assert document["gfx"]["compressed"]["58:5744"] == ""
    assert document["gfx"]["raw"]["2c:4000"] == "ff" * 0x300
    assert document["gfx"]["palettes"]["58:44cc"][:4] == "ff7f"
    text = bytes.fromhex(document["tables"]["CreditsText"]["bytes"])
    assert text[:2] == bytes([0x40, 0x7F]) and len(text) == 0x3D6
    assert document["tables"]["CreditsText"]["location"] == "58:5d0f"
    pals = bytes.fromhex(document["tables"]["CreditsPalsMap"]["bytes"])
    assert pals[:3] == bytes([1, 2, 3]) and len(pals) == 288 * 13


def test_text_without_its_288_lines_is_refused():
    rom = bytearray(synthetic())
    rom[at(0x58, credits.CREDITS_TEXT.address) + 1] = 0x41  # the first line's end gone: 287 lines
    with pytest.raises(MalformedDataError):
        credits.decode(bytes(rom))


def test_the_extractor_reads_the_labelled_data():
    names = _symbols()
    labels = {where: name for name, where in names.items() if "." not in name}
    for where in credits.FRAMESETS:
        assert labels.get((where.bank, where.address), "").startswith("Frameset_"), str(where)
    assert [labels.get((where.bank, where.address)) for where in credits.OAM_TABLES] == ["OAM_1617e8", "OAM_15e44a"]
    places = [*credits.COMPRESSED, *map(BankedAddress.parse, credits.RAW), *map(BankedAddress.parse, credits.PALETTES),
              credits.CREDITS_TEXT, credits.CREDITS_PALS_MAP]
    expected = ["PrologueGfx", "CreditsFontGfx", "CreditsMusicBoxGfx", "CreditsTilemap", "CreditsAttrmap",
                "MusicBoxGfx", "Pals_1604cc", "Pals_16050c", "Pals_16054c", "Pals_16058c", "Pals_1605cc",
                "Pals_16060c", "CreditsText", "CreditsPalsMap"]
    for where, name in zip(places, expected, strict=True):
        assert names[name] == (where.bank, where.address), name


def _linear(bank: int, address: int) -> int:
    return bank * 0x4000 + address - 0x4000


def test_the_ports_rom_constants_are_the_labels_they_name():
    names = _symbols()
    source = PORT.read_text()
    framesets = re.findall(r"^const FRAMESET_([0-9A-F]{6}): int = 0x([0-9A-F]{4})$", source, re.MULTILINE)
    assert len(framesets) == len(credits.FRAMESETS)
    for label, value in framesets:
        bank = int(label, 16) // 0x4000
        assert _linear(bank, int(value, 16)) == int(label, 16)
        assert names[f"Frameset_{label.lower()}"] == (bank, int(value, 16)), label
    for label in ("OAM_1617E8", "OAM_15E44A", "CREDITS_TEXT", "CREDITS_PALS_MAP"):
        value = int(re.search(rf"^const {label}: int = 0x([0-9A-F]{{4}})$", source, re.MULTILINE).group(1), 16)
        name = {"CREDITS_TEXT": "CreditsText", "CREDITS_PALS_MAP": "CreditsPalsMap"}.get(label, f"OAM_{label[4:].lower()}")
        assert names[name][1] == value, label
    pals = dict(re.findall(r'^const (PALS_[0-9A-F]{6}): String = "([0-9a-f]{2}:[0-9a-f]{4})"$', source, re.MULTILINE))
    assert len(pals) == 6
    for constant, where in pals.items():
        assert names["Pals_" + constant[5:].lower()] == (int(where[:2], 16), int(where[3:], 16)), constant


def test_the_credits_ram_constants_are_the_labels_they_name():
    names: dict[str, tuple[int, int]] = {}
    for name, where in _symbols().items():  # without their underscores: W_CREDITS_BG_MAP_PTR, wCreditsBGMapPtr
        names.setdefault(name.replace("_", "").lower(), where)
    checked = 0
    for constant, value in re.findall(r"^const (W[0-9A-Z_]+): int = 0x([0-9A-F]{4})$", PORT.read_text(), re.MULTILINE):
        label = constant.replace("_", "").lower()
        assert label in names, constant
        assert names[label][1] == int(value, 16), constant
        checked += 1
    assert checked >= 16
