"""The map's data (wl3pc.extract.overworld: ROM banks kept whole) on a synthetic ROM, and the map
port's RAM constants against the reference build's symbols (WL3-052)."""

import re

import pytest

from wl3pc.extract import overworld
from wl3pc.paths import BUILD_DIR, PROJECT_ROOT

SYM = BUILD_DIR / "refbuild" / "electrodeoxys-560fce6" / "warioland3.sym"
OVERWORLD = PROJECT_ROOT / "game" / "scripts" / "sim" / "screens" / "overworld"


def test_the_banks_are_kept_whole_the_home_bank_from_0000():
    rom = bytearray(0x80 * 0x4000)
    rom[0x0000] = 0x11
    rom[0x20 * 0x4000] = 0x22
    rom[0x20 * 0x4000 + 0x3FFF] = 0x23
    document = overworld.decode(bytes(rom))
    assert sorted(int(key, 16) for key in document["banks"]) == sorted(overworld.BANKS)
    home, bank20 = bytes.fromhex(document["banks"]["00"]), bytes.fromhex(document["banks"]["20"])
    assert (home[0], bank20[0], bank20[-1], len(bank20)) == (0x11, 0x22, 0x23, 0x4000)


def test_the_maps_ram_constants_are_the_labels_they_name():
    if not SYM.exists():
        pytest.skip(f"SKIPPED (no reference-build symbols at {SYM}; run `make refbuild`)")
    names: dict[str, tuple[int, int]] = {}
    for line in SYM.read_text().splitlines():
        match = re.match(r"([0-9a-f]{2}):([0-9a-f]{4}) (\S+)$", line)
        if match:
            names.setdefault(match.group(3).lower(), (int(match.group(1), 16), int(match.group(2), 16)))
    checked = 0
    for path in sorted(OVERWORLD.glob("*.gd")):
        pattern = r"^const (W_[0-9A-Z_]+|W[0-9]D[0-9A-F]+): int = 0x([0-9A-F]{4})\b"
        for constant, value in re.findall(pattern, path.read_text(), re.MULTILINE):
            label = constant.replace("_", "").lower()
            assert label in names, (path.name, constant)
            assert names[label][1] == int(value, 16), (path.name, constant)
            checked += 1
    assert checked >= 200
