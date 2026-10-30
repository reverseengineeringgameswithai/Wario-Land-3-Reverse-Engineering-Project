"""The level and the screens as one RAM (WL3-052): the LevelSim's shared variables (SharedWram) and the
screens' WRAM0 variables kept as bytes are where the oracle's layouts place them (those layouts are
checked against the reference build's symbols by tests/test_oracle.py), and the level bytes the
LevelSim keeps only in that RAM are the labels they name."""

import re

import pytest

from wl3pc import oracle_wario
from wl3pc.paths import BUILD_DIR, PROJECT_ROOT

SIM = PROJECT_ROOT / "game" / "scripts" / "sim"
SYM = BUILD_DIR / "refbuild" / "electrodeoxys-560fce6" / "warioland3.sym"


def test_the_shared_variables_are_the_oracle_layout_s_wram_entries():
    source = (SIM / "wario" / "shared_wram.gd").read_text()
    table = [(name, int(bank), int(address, 16), int(size)) for name, bank, address, size in
             re.findall(r'\["(\w+)", (\d+), 0x([0-9A-F]{4}), (\d)\]', source)]
    expected = []
    for name, address, size in oracle_wario.WARIO_VARIABLES:
        bank, address = address >> 16, address & 0xFFFF
        if (bank == 0 and 0xC000 <= address < 0xD000) or (bank in (2, 3) and 0xD000 <= address < 0xE000):
            expected.append((name, bank, address, size))
    assert table == expected


def test_the_screens_wram0_variables_are_where_the_screen_layouts_put_them():
    layout = {name: address for screen in oracle_wario.SCREENS for name, address, _ in screen.variables}
    checked = 0
    for path in sorted((SIM / "screens").rglob("*.gd")):
        source = path.read_text()
        constants = dict(re.findall(r"^const (W_\w+): int = 0x([0-9A-F]{4})", source, re.MULTILINE))
        pattern = r"^var (w\w+): int:\n\tget:\n\t\treturn r0\((W_\w+)\)"
        for name, constant in re.findall(pattern, source, re.MULTILINE):
            assert layout.get(name) == int(constants[constant], 16), (path.name, name)
            checked += 1
    assert checked >= 9


def test_the_level_bytes_kept_in_the_shared_ram_are_their_labels():
    if not SYM.exists():
        pytest.skip(f"SKIPPED (no reference-build symbols at {SYM}; run `make refbuild`)")
    labels = {}
    for line in SYM.read_text().splitlines():
        match = re.match(r"([0-9a-f]{2}):([0-9a-f]{4}) (\S+)$", line)
        if match:
            labels.setdefault(match.group(3).replace("_", "").lower(), int(match.group(2), 16))
    source = (SIM / "wario" / "level_sim.gd").read_text()
    constants = re.findall(r"^const (W_TEMP_LEVEL_ROOM_ID|W_UNUSED_CA6C|W_LEVEL_TIME): int = 0x([0-9A-F]{4})", source,
                           re.MULTILINE)
    assert len(constants) == 3
    for constant, address in constants:
        assert labels[constant.replace("_", "").lower()] == int(address, 16), constant
