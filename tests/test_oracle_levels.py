"""Level starts and scripted movies (oracle_levels) without an emulator or ROM."""

import pytest

from wl3pc import oracle, oracle_levels


def held_at(trace, tick):
    current = frozenset()
    for event in trace["events"]:
        if event["tick"] > tick:
            break
        current = frozenset(event["held"])
    return current


def test_scripts_hold_a_direction_and_jump_for_20_of_every_60_ticks():
    trace = oracle_levels.script_trace("right-jump", 130)
    assert trace["ticks"] == 130
    assert held_at(trace, 0) == {"right", "a"} and held_at(trace, 19) == {"right", "a"}
    assert held_at(trace, 20) == {"right"} and held_at(trace, 60) == {"right", "a"}
    assert held_at(oracle_levels.script_trace("idle", 10), 5) == frozenset()
    assert held_at(oracle_levels.script_trace("left", 10), 5) == {"left"}
    with pytest.raises(oracle.OracleError):
        oracle_levels.script_trace("dance", 10)


def test_attack_and_crouch_scripts_add_b_and_down_and_wander_changes_every_24_ticks():
    attack = oracle_levels.script_trace("right-attack", 80)
    assert held_at(attack, 35) == {"right"} and held_at(attack, 36) == {"right", "b"}
    assert held_at(attack, 0) == {"right", "a"} and held_at(attack, 76) == {"right", "a", "b"}
    crouch = oracle_levels.script_trace("right-crouch", 100)
    assert held_at(crouch, 59) == {"right"} and held_at(crouch, 60) == {"right", "down", "a"}
    wander = oracle_levels.script_trace("wander", 240)
    assert wander == oracle_levels.script_trace("wander", 240), "deterministic"
    segments = [held_at(wander, tick) for tick in range(0, 240, 24)]
    assert all(held_at(wander, tick + 23) == segments[tick // 24] for tick in range(0, 240, 24))
    assert len(set(segments)) > 3, "more than a few different segments"
    left_attack = oracle_levels.script_trace("left-attack", 80)
    assert held_at(left_attack, 36) == {"left", "b"} and held_at(left_attack, 0) == {"left", "a"}
    seeded = oracle_levels.script_trace("wander-s7", 240)
    assert seeded != wander and seeded == oracle_levels.script_trace("wander-s7", 240), "another, fixed generator"
    assert oracle_levels.wander_seed("wander") == 1 and oracle_levels.wander_seed("wander-s7") == 7
    for name in ("wander-s1", "wander-s0", "wander-s65536", "wander-sx"):
        assert oracle_levels.wander_seed(name) is None


class FakeEmulator:
    def __init__(self):
        self.memory = bytearray(0x10000)
        self.hooks = {}

    def hook_register(self, bank, address, callback, context):
        self.hooks[(bank, address)] = callback


def test_the_level_is_set_the_first_time_init_level_runs_only():
    pyboy = FakeEmulator()
    oracle_levels.install_level_poke(pyboy, 0x10)
    hook = pyboy.hooks[oracle_levels.INIT_LEVEL]
    hook(None)
    assert pyboy.memory[oracle_levels.W_LEVEL] == 0x10
    pyboy.memory[oracle_levels.W_LEVEL] = 0x00  # the game's own later choice stands
    hook(None)
    assert pyboy.memory[oracle_levels.W_LEVEL] == 0x00
    assert pyboy.memory[oracle_levels.W_DAY_NIGHT] == 0, "a day level leaves the time of day"


def test_a_night_level_is_night_too():
    pyboy = FakeEmulator()
    pyboy.memory[oracle_levels.W_DAY_NIGHT] = 0x10
    oracle_levels.install_level_poke(pyboy, 0x0C)
    pyboy.hooks[oracle_levels.INIT_LEVEL](None)
    assert (pyboy.memory[oracle_levels.W_LEVEL], pyboy.memory[oracle_levels.W_DAY_NIGHT]) == (0x0C, 0x11)


def test_a_room_start_sets_the_room_the_first_time_the_level_start_loads_it():
    pyboy = FakeEmulator()
    oracle_levels.install_level_poke(pyboy, 0x10)
    assert oracle_levels.LOAD_START_ROOM not in pyboy.hooks, "no room: entry 0, as the game starts"
    pyboy = FakeEmulator()
    oracle_levels.install_level_poke(pyboy, 0x10, room=5)
    hook = pyboy.hooks[oracle_levels.LOAD_START_ROOM]
    hook(None)
    assert pyboy.memory[oracle_levels.W_LEVEL_ROOM_ID] == 5
    pyboy.memory[oracle_levels.W_LEVEL_ROOM_ID] = 7  # a later start (a restart) is the game's own
    hook(None)
    assert pyboy.memory[oracle_levels.W_LEVEL_ROOM_ID] == 7


def test_a_level_start_origin_replays_its_power_up_after_the_input():
    pyboy = FakeEmulator()
    oracle_levels.apply_end_pokes(pyboy, {"end_pokes": [{"name": "wPowerUpLevel", "address": "ca3c", "value": 7}]})
    assert pyboy.memory[0xCA3C] == 7
    oracle_levels.apply_end_pokes(pyboy, {})  # an origin without pokes changes nothing
    assert pyboy.memory[0xCA3C] == 7
    with pytest.raises(oracle.OracleError):
        oracle_levels.level_start(b"", 0x08, power_up=10)
