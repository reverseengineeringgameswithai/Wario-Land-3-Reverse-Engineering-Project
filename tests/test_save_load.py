"""The save's load (SaveLoad, game/scripts/sim/screens/save_load.gd): its RAM and SRAM constants against
the reference build's symbols, bank and address, and its sizes against the reference build's map
(WL3-055)."""

import re

import pytest

from wl3pc.paths import BUILD_DIR, PROJECT_ROOT

REFBUILD = BUILD_DIR / "refbuild" / "electrodeoxys-560fce6"
SYM = REFBUILD / "warioland3.sym"
MAP = REFBUILD / "warioland3.map"
SOURCE = PROJECT_ROOT / "game" / "scripts" / "sim" / "screens" / "save_load.gd"
# The constants outside WRAM0 and SRAM bank 0, by their bank (WRAMX or SRAM).
BANKED = {"W_OBJECTS": 1, "W_TREASURES_COLLECTED": 2, "S_LEVEL_BLOCK_OBJECT_MAP": 1, "S2A000": 2, "S2B000": 2,
          "S3A000": 3}


def _symbols() -> dict[str, tuple[int, int]]:
    if not SYM.exists():
        pytest.skip(f"SKIPPED (no reference-build symbols at {SYM}; run `make refbuild`)")
    names: dict[str, tuple[int, int]] = {}
    for line in SYM.read_text().splitlines():
        match = re.match(r"([0-9a-f]{2}):([0-9a-f]{4}) (\S+)$", line)
        if match:  # without underscores, lower case: W_CHECKSUM_MISMATCHES, wChecksumMismatches
            key = match.group(3).replace("_", "").lower()
            names.setdefault(key, (int(match.group(1), 16), int(match.group(2), 16)))
    return names


def _constants() -> dict[str, int]:
    source = SOURCE.read_text()
    return {name: int(value, 16) for name, value in
            re.findall(r"^const ([A-Z][0-9A-Z_]+): int = 0x([0-9A-F]+)\b", source, re.MULTILINE)}


def test_the_loads_ram_and_sram_constants_are_the_labels_they_name():
    names = _symbols()
    checked = 0
    for constant, value in _constants().items():
        if not re.match(r"[WS][0-9A-Z_]*$", constant) or constant.endswith("_SIZE"):
            continue
        label = constant.replace("_", "").lower()
        assert label in names, constant
        assert names[label] == (BANKED.get(constant, 0), value), constant
        checked += 1
    assert checked == 63


def test_the_loads_sizes_are_the_sections_and_labels_they_name():
    if not MAP.exists():
        pytest.skip(f"SKIPPED (no reference-build map at {MAP}; run `make refbuild`)")
    sections = {match.group(3): int(match.group(2), 16) - int(match.group(1), 16) + 1 for match in
                re.finditer(r"SECTION: \$([0-9a-f]{4})-\$([0-9a-f]{4}) \(\$[0-9a-f]+ bytes\) \[\"([^\"]+)\"\]",
                            MAP.read_text())}
    constants = _constants()
    assert constants["PROGRESS_WRAM_SIZE"] == sections["Progress WRAM"]
    assert constants["LEVEL_WRAM_SIZE"] == sections["Level WRAM"]
    assert constants["LEVEL_OBJECTS_WRAM_SIZE"] == sections["Level Objects WRAM"]
    names = _symbols()
    assert constants["TREASURES_SIZE"] == names["wowlevel"][1] - names["wtreasurescollected"][1] + 2
    assert constants["W_SAVE_COUNTER"] == int(re.search(r"SECTION: \$([0-9a-f]{4})-\$[0-9a-f]{4} \(\$[0-9a-f]+ "
                                                        r"bytes\) \[\"Progress WRAM\"\]", MAP.read_text())[1], 16)
    # The six slots' data after their four check values.
    assert [constants[name] - constants[slot] for slot, name in
            [("S0A000", "S_SAVE_COUNTER"), ("S_CHECK_VALS", "S_GAME_DATA"), ("S0A400", "S0A404"),
             ("S0A800", "S0A804"), ("S_BACKUP_CHECK_VALS", "S_BACKUP_GAME_DATA"), ("S0AC00", "S0AC04")]] == [4] * 6
