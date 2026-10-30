"""Action Help's data (wl3pc.extract.action_help) on a synthetic ROM, its addresses against the
reference build's symbols, and the oracle's Action Help branches (WL3-051)."""

import re

import pytest

from test_rooms import at
from wl3pc import oracle_action_help
from wl3pc.extract import action_help
from wl3pc.paths import BUILD_DIR, PROJECT_ROOT

SYM = BUILD_DIR / "refbuild" / "electrodeoxys-560fce6" / "warioland3.sym"
SCREENS = PROJECT_ROOT / "game" / "scripts" / "sim" / "screens"


def synthetic() -> bytes:
    rom = bytearray([0xFF]) * (0x80 * 0x4000)
    for where in action_help.OAM_TABLES:  # one frame each, one entry
        start = at(where.bank, where.address)
        rom[start:start + 7] = (where.address + 2).to_bytes(2, "little") + bytes([0xF8, 0xFC, 0x04, 0x01, 0x80])
    start = at(0x79, 0x6B76)
    rom[start:start + 5] = bytes([3, 8, 4, 8, 0xFF])
    for where in action_help.COMPRESSED:  # empty streams
        rom[at(where.bank, where.address)] = 0
    return bytes(rom)


def test_framesets_oam_tables_tables_and_graphics_decode_from_their_places():
    document = action_help.decode(synthetic())
    assert document["framesets"]["79:6b76"] == [[3, 8], [4, 8]]
    assert document["framesets"]["05:425f"] == []
    assert document["oam_tables"]["03:520e"] == [[[-8, -4, 4, 1]]]
    assert len(bytes.fromhex(document["tables"]["jump_vel_table_normal"]["bytes"])) == 0x100
    assert len(bytes.fromhex(document["tables"]["power_up_ob_pals"]["bytes"])) == 10
    assert document["gfx"]["compressed"]["79:6796"] == ""
    assert all(len(bytes.fromhex(tiles)) == 0x800 for tiles in document["gfx"]["wario"].values())
    assert len(bytes.fromhex(document["gfx"]["palettes"]["79:4f6f"])) == 0x10


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
    for where in action_help.FRAMESETS:
        assert labels.get((where.bank, where.address), "").startswith("Frameset_"), str(where)
    for where in action_help.OAM_TABLES:
        assert labels.get((where.bank, where.address), "").startswith("OAM_"), str(where)
    expected = ["ActionHelpHUDGfx", "ActionHelpObjects1Gfx", "ActionHelpObjects2Gfx", "ActionHelpTilemap",
                "ActionHelpAttrmap"]
    assert [labels[(where.bank, where.address)] for where in action_help.COMPRESSED] == expected
    wario = ["WarioIdleGfx", "WarioWalkGfx", "WarioSwimGfx", "WarioAttackGfx", "WarioThrowGfx", "WarioAirborneGfx",
             "WarioSlideGfx", "WarioBatGfx", "WarioVampireGfx", "WarioHangGfx"]
    assert [names[name] for name in wario] == [(int(key[:2], 16), int(key[3:], 16)) for key in action_help.WARIO_GFX]
    pals = ["Pals_1e4e6f", "Pals_1e4eaf", "Pals_1e4eef", "Pals_1e4f2f", "Pals_1e4f6f", "Pals_1e4f7f", "Pals_1e4fbf"]
    assert [names[name] for name in pals] == [(int(key[:2], 16), int(key[3:], 16)) for key in action_help.PALETTES]
    tables = {"jump_vel_table_normal": "JumpVelTable_Normal", "jump_vel_table_high_jump": "JumpVelTable_HighJump",
              "power_up_ob_pals": "PowerUpOBPals"}
    for name, (where, _) in action_help.TABLES.items():
        assert names[tables[name]] == (where.bank, where.address), name


def test_the_ports_ram_constants_are_the_labels_they_name():
    names = {name.lower(): where for name, where in _symbols().items()}
    checked = 0
    for path in (SCREENS / "menu_screen_sim.gd", SCREENS / "action_help" / "action_help_common.gd"):
        source = path.read_text()
        for constant, value in re.findall(r"^const (W[0-9A-Z_]+): int = 0x([0-9A-F]{4})$", source, re.MULTILINE):
            label = constant.replace("_", "").lower()
            assert label in names, constant
            assert names[label][1] == int(value, 16), constant
            checked += 1
    assert checked >= 30


def test_a_branch_keeps_the_movies_input_up_to_action_help():
    trace = {"format": "wl3pc.input-trace", "format_version": 1, "description": "a movie", "ticks": 100,
             "events": [{"tick": 0, "held": []}, {"tick": 40, "held": ["a"]}, {"tick": 60, "held": []}]}
    cut = oracle_action_help.truncate_trace(trace, 50)
    assert cut["ticks"] == 50 and [event["tick"] for event in cut["events"]] == [0, 40]
    browse = oracle_action_help.browse_trace(3000)
    held = {event["tick"]: event["held"] for event in browse["events"]}
    assert held[400] == ["right"] and held[403] == [] and held[2800] == ["a"] and browse["ticks"] == 3000
