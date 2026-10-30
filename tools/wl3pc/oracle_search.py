"""Coverage-guided input search from an oracle start (WL3-048).

Scripted movies reach the bosses' rooms but rarely fight them. The search plays a movie a segment
at a time: from the state the chosen segments led to, it tries several random input segments
(each a few runs of one of the wander script's button sets), keeps the one that reaches the most
coverage keys not yet seen, and goes on from where that one ended. A coverage key is an active
object slot's (ID, update function, OBJ_STATE), Wario's state (`wWarioState`), the 32-px cell
of the level he is in (exploring the room reaches what his position triggers), or a value of one
of the battle variables at $d140-$d149 (the bosses' hits, goals, and phases), sampled after every
tick. The result is a plain input trace: `make level-movie SCRIPT=search-sN` records it
from the start like any scripted movie (so its checkpoints are a straight replay's), and the
sweep tools trace and check it as usual. Seeded, so the same start and seed give the same movie.
"""

from __future__ import annotations

import io
import random
from typing import Any, Callable

from . import oracle
from .oracle_levels import WANDER_CHOICES

OBJECTS_BANK, OBJECTS_START, NUM_OBJECTS, OBJ_STRUCT_LENGTH = 1, 0xD000, 8, 0x20
OBJ_FLAGS, OBJ_ID, OBJ_STATE, OBJ_UPDATE_FUNCTION = 0x00, 0x07, 0x1B, 0x1E
W_WARIO_STATE = 0xCA83
W_WARIO_Y_POS, W_WARIO_X_POS = 0xCA61, 0xCA63  # big-endian words
BATTLE_VARIABLES = range(0xD140, 0xD14A)  # WRAMX bank 1: wShootGoals, wWolfenbossRemainingHits, ...
SEGMENT_TICKS = 48  # one choice per branch is made of runs of RUN_TICKS
RUN_TICKS = (8, 12, 16, 24)
BRANCHES = 16


def search_seed(script: str) -> int | None:
    """The seed of "search-sN" (N, 1-65535); None for other scripts."""
    if script.startswith("search-s") and script[8:].isdigit() and 1 <= int(script[8:]) <= 0xFFFF:
        return int(script[8:])
    return None


def coverage_keys(pyboy: Any) -> set[tuple[int, ...]]:
    """What the current tick shows: (ID, update function, state) of each active object slot,
    Wario's state as (-1, state), his 32-px cell as (-2, x // 32, y // 32), and each battle
    variable as (-3, address, value)."""
    y = pyboy.memory[W_WARIO_Y_POS] << 8 | pyboy.memory[W_WARIO_Y_POS + 1]
    x = pyboy.memory[W_WARIO_X_POS] << 8 | pyboy.memory[W_WARIO_X_POS + 1]
    keys = {(-1, pyboy.memory[W_WARIO_STATE]), (-2, x >> 5, y >> 5)}
    keys.update((-3, address, pyboy.memory[OBJECTS_BANK, address]) for address in BATTLE_VARIABLES)
    for slot in range(NUM_OBJECTS):
        base = OBJECTS_START + slot * OBJ_STRUCT_LENGTH
        if pyboy.memory[OBJECTS_BANK, base + OBJ_FLAGS] & 1:
            function = (pyboy.memory[OBJECTS_BANK, base + OBJ_UPDATE_FUNCTION]
                        | pyboy.memory[OBJECTS_BANK, base + OBJ_UPDATE_FUNCTION + 1] << 8)
            keys.add((pyboy.memory[OBJECTS_BANK, base + OBJ_ID], function,
                      pyboy.memory[OBJECTS_BANK, base + OBJ_STATE]))
    return keys


def _segment(rng: random.Random, ticks: int) -> list[frozenset[str]]:
    held: list[frozenset[str]] = []
    while len(held) < ticks:
        choice = frozenset(rng.choice(WANDER_CHOICES))
        held.extend([choice] * min(rng.choice(RUN_TICKS), ticks - len(held)))
    return held


def _save(pyboy: Any) -> bytes:
    data = io.BytesIO()
    pyboy.save_state(data)
    return data.getvalue()


def _load(pyboy: Any, state: bytes) -> None:
    pyboy.load_state(io.BytesIO(state))


def search(pyboy: Any, ticks: int, seed: int, branches: int = BRANCHES,
           segment_ticks: int = SEGMENT_TICKS) -> tuple[list[frozenset[str]], set[tuple[int, ...]]]:
    """Search `ticks` of input from `pyboy`'s current state; returns the held set of every tick
    and the coverage keys the chosen segments reached. Inputs change as `oracle.play` changes
    them (only on a change, every button at the first tick), so a straight replay matches."""
    rng = random.Random(seed)
    seen = coverage_keys(pyboy)
    held_all: list[frozenset[str]] = []
    previous: frozenset[str] | None = None
    state = _save(pyboy)
    while len(held_all) < ticks:
        count = min(segment_ticks, ticks - len(held_all))
        best: tuple[int, list[frozenset[str]], bytes, set[tuple[int, ...]]] | None = None
        for _ in range(branches):
            _load(pyboy, state)
            inputs = _segment(rng, count)
            new: set[tuple[int, ...]] = set()
            last = previous
            for held in inputs:
                if last is None or held != last:
                    oracle.apply_held(pyboy, last, held)
                last = held
                pyboy.tick(1, False)
                new |= coverage_keys(pyboy) - seen
            if best is None or len(new) > best[0]:
                best = (len(new), inputs, _save(pyboy), new)
        assert best is not None
        _, inputs, state, new = best
        held_all.extend(inputs)
        previous = inputs[-1]
        seen |= new
    return held_all, seen


def search_trace(rom: bytes, start: dict[str, Any], ticks: int, seed: int,
                 open_emulator: Callable[[bytes, dict[str, Any]], Any] = oracle.start_from) -> dict[str, Any]:
    """The input trace a search from `start` finds (see the module docstring)."""
    pyboy = open_emulator(rom, start)
    held, seen = search(pyboy, ticks, seed)
    pyboy.stop(save=False)
    return oracle.make_trace(held, f"Searched: seed {seed} for {ticks} ticks, {len(seen)} coverage keys")
