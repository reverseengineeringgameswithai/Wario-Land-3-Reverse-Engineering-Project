"""Oracle starts at any level, and scripted movies from them (parity coverage beyond the owner's movie).

A level start is the ootw-day1-start route's input from power-on, with one change to the game's
memory: when `InitLevel` (02:4024) first runs, `wLevel` ($ca06) is set to the wanted level
(LEVEL * 8 + variant: day 1-4, night 1-4), so the game loads that level instead of Out of the
Woods. The run then goes on until the level is playing (`wState` ST_LEVEL, `wSubState`
SST_UPDATE_LEVEL) and 60 idle ticks more. The state is stored with that origin, so
`oracle state-check` can rebuild it. This is a test harness only: the game itself never chooses a
level this way, and progress-dependent details (keys, treasures, music) stay those of a new game.

Scripted movies are plain input traces from such a state ("idle", "right", "right-jump",
"left", "left-jump"; "right-attack" and "left-attack" add a B press every 40 ticks,
"right-crouch" holds Down for 30 of every 90 ticks, and "wander" changes buttons every 24 ticks
by a fixed generator; "wander-sN" seeds it with N instead of 1), saved as recordings with
memory checkpoints like the recorder's.
"""

from __future__ import annotations

import io
from typing import Any

from . import oracle
from .provenance import ROM_DERIVED_MARKER, sha256_bytes

INIT_LEVEL = (0x02, 0x4024)
W_LEVEL = 0xCA06
W_DAY_NIGHT = 0xCA3B
NIGHT_LEVEL = 1 << 2  # SelectLevel sets wLevel's bit 2 from wDayNight's bit 0
W_STATE, W_SUB_STATE = 0xC09B, 0xC09C
ST_LEVEL, SST_UPDATE_LEVEL = 0x02, 0x03
SETTLE_TICKS = 60
# StartRoom_FromLevelStart.load_blocks_and_objects: after the level start clears wLevelRoomID ($c0a0)
# and before LoadRoom reads it.
LOAD_START_ROOM = (0x02, 0x47EB)
W_LEVEL_ROOM_ID = 0xC0A0
W_POWER_UP_LEVEL = 0xCA3C
NUM_MAIN_POWER_UPS = 10  # NO_POWER_UP (0) to SUPER_GRAB_GLOVES (9), cumulative
MAX_EXTRA_TICKS = 5000
SCRIPTS = ("idle", "right", "right-jump", "left", "left-jump", "right-attack", "left-attack", "right-crouch",
           "wander")
# "wander": a 24-tick segment of each, chosen by a 16-bit linear congruential generator (seed 1;
# "wander-sN": seed N, 2-65535).
WANDER_SEGMENT = 24
WANDER_CHOICES = (("right",), ("right", "a"), ("right", "b"), ("left",), ("left", "a"), ("left", "b"),
                  ("down",), ("down", "a"), ("right", "down"), ("a",), ("b",), ())


def install_level_poke(pyboy: Any, level: int, room: int | None = None) -> None:
    """Set wLevel to `level` the first time InitLevel runs, and for a night level (bit 2) night itself
    (wDayNight's bit 0, which SelectLevel takes that bit from and the objects read). With `room`,
    the level starts in that room-list entry instead of entry 0 (wLevelRoomID, set the first time
    the level start loads its room), at that room's spawn."""
    done = {"poked": False, "room": room is None}

    def poke(_context: Any) -> None:
        if not done["poked"]:
            pyboy.memory[W_LEVEL] = level
            if level & NIGHT_LEVEL:
                pyboy.memory[W_DAY_NIGHT] = pyboy.memory[W_DAY_NIGHT] | 1
            done["poked"] = True

    pyboy.hook_register(*INIT_LEVEL, poke, None)
    if room is None:
        return

    def poke_room(_context: Any) -> None:
        if not done["room"]:
            pyboy.memory[W_LEVEL_ROOM_ID] = room
            done["room"] = True

    pyboy.hook_register(*LOAD_START_ROOM, poke_room, None)


def apply_end_pokes(pyboy: Any, origin: dict[str, Any]) -> None:
    """The memory writes an origin makes once its input has played (a level start's power-up)."""
    for poke in origin.get("end_pokes", []):
        pyboy.memory[int(poke["address"], 16)] = int(poke["value"])


def level_start(rom: bytes, level: int, power_up: int | None = None,
                room: int | None = None) -> tuple[Any, dict[str, Any]]:
    """A running emulator at `level`'s start, and the origin that rebuilds it. With `power_up`,
    wPowerUpLevel is set once the level has settled (a test harness: the game sets it only from
    collected treasures); with `room`, the level starts in that room-list entry."""
    if power_up is not None and not 0 <= power_up < NUM_MAIN_POWER_UPS:
        raise oracle.OracleError(f"power-up level {power_up} is not one of 0-{NUM_MAIN_POWER_UPS - 1}")
    route, _ = oracle.load_route("ootw-day1-start")
    start = route["start"]
    pyboy = oracle.start_from(rom, start)
    install_level_poke(pyboy, level, room)
    final = oracle.play(pyboy, route["input"])
    if final:
        raise oracle.OracleError("the route must end with no buttons held")
    extra = 0
    while (pyboy.memory[W_STATE], pyboy.memory[W_SUB_STATE]) != (ST_LEVEL, SST_UPDATE_LEVEL):
        pyboy.tick(1, False)
        extra += 1
        if extra > MAX_EXTRA_TICKS:
            raise oracle.OracleError(f"level {level:#04x} did not start within {MAX_EXTRA_TICKS} ticks")
    for _ in range(SETTLE_TICKS):
        pyboy.tick(1, False)
    extra += SETTLE_TICKS
    events = list(route["input"]["events"])
    trace = {"format": "wl3pc.input-trace", "format_version": 1,
             "description": f"{route['input']['description']}; {extra} idle ticks more",
             "ticks": route["input"]["ticks"] + extra, "events": events}
    origin = {"start": start, "input": trace, "frame": trace["ticks"],
              "level_poke": {"level": level, "at": "02:4024", "address": "ca06",
                             **({"night": {"address": f"{W_DAY_NIGHT:04x}", "bit": 0}} if level & NIGHT_LEVEL else {}),
                             **({"room": {"value": room, "at": "02:47eb", "address": f"{W_LEVEL_ROOM_ID:04x}"}}
                                if room is not None else {})}}
    if power_up is not None:
        origin["end_pokes"] = [{"name": "wPowerUpLevel", "address": f"{W_POWER_UP_LEVEL:04x}", "value": power_up}]
        apply_end_pokes(pyboy, origin)
    origin["ram_sha256"] = oracle.ram_digest(pyboy)
    return pyboy, origin


def store_level_start(rom: bytes, level: int, power_up: int | None = None,
                      room: int | None = None) -> dict[str, Any]:
    """Store `level`'s start as an oracle state; returns the start to use in recordings."""
    pyboy, origin = level_start(rom, level, power_up, room)
    data = io.BytesIO()
    pyboy.save_state(data)
    pyboy.stop(save=False)
    sha = oracle.store_put("state", data.getvalue(), {"origin": origin})
    return oracle.state_start(sha, oracle.boot_rom_of(origin["start"]), origin)


def script_trace(script: str, ticks: int) -> dict[str, Any]:
    """An input trace for one of SCRIPTS: holding a direction, with A for 20 of every 60 ticks to
    jump (and for "right-attack", B for 4 of every 40 ticks; for "right-crouch", Down for 30 of
    every 90); or "wander"'s segments."""
    seed = wander_seed(script)
    if script not in SCRIPTS and seed is None:
        raise oracle.OracleError(f"unknown script {script!r} (one of {', '.join(SCRIPTS)}, or wander-sN)")
    if seed is not None:
        return oracle.make_trace(_wander(ticks, seed), f"Scripted: {script} for {ticks} ticks")
    held: list[frozenset[str]] = []
    for tick in range(ticks):
        buttons: set[str] = set()
        if script.startswith("right"):
            buttons.add("right")
        elif script.startswith("left"):
            buttons.add("left")
        if script in ("right-jump", "left-jump", "right-attack", "left-attack", "right-crouch") and tick % 60 < 20:
            buttons.add("a")
        if script in ("right-attack", "left-attack") and tick % 40 >= 36:
            buttons.add("b")
        if script == "right-crouch" and tick % 90 >= 60:
            buttons.add("down")
        held.append(frozenset(buttons))
    return oracle.make_trace(held, f"Scripted: {script} for {ticks} ticks")


def wander_seed(script: str) -> int | None:
    """The generator's seed of "wander" (1) or "wander-sN" (N, 2-65535); None for other scripts."""
    if script == "wander":
        return 1
    if script.startswith("wander-s") and script[8:].isdigit() and 2 <= int(script[8:]) <= 0xFFFF:
        return int(script[8:])
    return None


def _wander(ticks: int, seed: int = 1) -> list[frozenset[str]]:
    state = seed
    held: list[frozenset[str]] = []
    choice: frozenset[str] = frozenset()
    for tick in range(ticks):
        if tick % WANDER_SEGMENT == 0:
            state = (state * 25173 + 13849) & 0xFFFF
            choice = frozenset(WANDER_CHOICES[(state >> 8) % len(WANDER_CHOICES)])
        held.append(choice)
    return held


def scripted_recording(rom: bytes, start: dict[str, Any], trace: dict[str, Any]) -> dict[str, Any]:
    """Play `trace` from `start` headlessly, with checkpoints as the recorder takes them."""
    pyboy = oracle.start_from(rom, start)
    checkpoints: list[dict[str, Any]] = []

    def check(tick: int) -> None:
        if (tick + 1) % oracle.CHECKPOINT_EVERY == 0 or tick == trace["ticks"] - 1:
            checkpoints.append({"tick": tick, "ram_sha256": oracle.ram_digest(pyboy)})

    oracle.play(pyboy, trace, check)
    pyboy.stop(save=False)
    return {
        "format": "wl3pc.oracle-recording", "format_version": oracle.FORMAT_VERSION, "marker": ROM_DERIVED_MARKER,
        "rom_sha256": sha256_bytes(rom), "emulator": oracle.emulator_config(), "start": start,
        "input": trace, "checkpoints": checkpoints,
    }
