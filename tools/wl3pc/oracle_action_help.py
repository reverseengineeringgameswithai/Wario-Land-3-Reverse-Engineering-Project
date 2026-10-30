"""Oracle movies of Action Help's demos (WL3-051).

The owner's movies reach Action Help only after a power-up treasure, so they show two demos. A
branch of one at Action Help's start (the first tick that ends in ST_ACTION_HELP, before
InitActionHelp picks the power-up) with wPowerUpLevel and wTransformation poked shows any of the
thirteen: InitActionHelp takes the power-up from them. With ACTION_HELP_LEVEL_CLEAR the demo plays
once without input and leads to the map; without it, it loops, and a scripted input browses the
power-ups (left and right, held for the d-pad's repeat) and closes it.
"""

from __future__ import annotations

import io
from typing import Any

from . import oracle
from .oracle_levels import apply_end_pokes

W_STATE, ST_ACTION_HELP = 0xC09B, 0x07
W_POWER_UP_LEVEL, W_TRANSFORMATION = 0xCA3C, 0xCA8E
ACTION_HELP_LEVEL_CLEAR = 0x80
# The transformations InitActionHelp shows instead of the power-up.
TRANSFORMATIONS = {"owl": 0x0E, "rail": 0x0F, "vampire": 0x4B}


def truncate_trace(trace: dict[str, Any], ticks: int) -> dict[str, Any]:
    """`trace`'s first `ticks` ticks."""
    events = [event for event in trace["events"] if event["tick"] < ticks]
    return {"format": "wl3pc.input-trace", "format_version": 1,
            "description": f"{trace.get('description', 'input')}; its first {ticks} ticks",
            "ticks": ticks, "events": events}


def browse_trace(ticks: int) -> dict[str, Any]:
    """Without ACTION_HELP_LEVEL_CLEAR: idle for 400 ticks, right for 3, idle, right held 60 (the
    d-pad's repeat), idle, left held 40, idle; A at `ticks` - 200, which closes it."""
    held: list[frozenset[str]] = [frozenset()] * ticks
    for start, length, button in ((400, 3, "right"), (500, 60, "right"), (700, 40, "left"),
                                  (ticks - 200, 3, "a")):
        for tick in range(start, min(start + length, ticks)):
            held[tick] = frozenset({button})
    return oracle.make_trace(held, f"Action Help browsed for {ticks} ticks")


def action_help_start(rom: bytes, movie: dict[str, Any], power_up_level: int,
                      transformation: int | None = None) -> tuple[Any, dict[str, Any]]:
    """An emulator at `movie`'s Action Help start with the pokes made, and the origin that rebuilds
    it (the movie's start and input up to there, then the pokes)."""
    pyboy = oracle.start_from(rom, movie["start"])
    found: list[int] = []

    class Reached(Exception):
        pass

    def watch(tick: int) -> None:
        if pyboy.memory[W_STATE] == ST_ACTION_HELP:
            found.append(tick + 1)
            raise Reached

    try:
        oracle.play(pyboy, movie["input"], watch)
    except Reached:
        pass
    if not found:
        pyboy.stop(save=False)
        raise oracle.OracleError("the movie never reaches Action Help")
    pokes = [{"name": "wPowerUpLevel", "address": f"{W_POWER_UP_LEVEL:04x}", "value": power_up_level}]
    if transformation is not None:
        pokes.append({"name": "wTransformation", "address": f"{W_TRANSFORMATION:04x}", "value": transformation})
    origin = {"start": movie["start"], "input": truncate_trace(movie["input"], found[0]), "frame": found[0],
              "end_pokes": pokes}
    apply_end_pokes(pyboy, origin)
    origin["ram_sha256"] = oracle.ram_digest(pyboy)
    return pyboy, origin


def store_action_help_start(rom: bytes, movie: dict[str, Any], power_up_level: int,
                            transformation: int | None = None) -> dict[str, Any]:
    """Store the start as an oracle state; returns the start to use in recordings."""
    pyboy, origin = action_help_start(rom, movie, power_up_level, transformation)
    data = io.BytesIO()
    pyboy.save_state(data)
    pyboy.stop(save=False)
    sha = oracle.store_put("state", data.getvalue(), {"origin": origin})
    return oracle.state_start(sha, oracle.boot_rom_of(origin["start"]), origin)
