---
type: session
status: done
updated: 2026-10-28
tags: [session, validation]
---
# 2026-10-28: The reset after a level played and not saved (WL3-057)

The owner asked the agent to continue where the last session stopped. The
handoff named the sweeps to run again first, then the next task; this
session took the first of its pointers: the reset after an unsaved level,
which stopped two runs (the game over's and the save after the Perfect
screen's).

## Done

- `make sweeps SNAPSHOT=1` on `9ed35c1` (the game over and Perfect screens,
  the save after the Perfect screen) and the 50-movie recheck, step and
  `MODE=run`, on the same code: results below.
- The original's loads during four invented movies captured with
  `python -m wl3pc.oracle_save` and their names: a load at power-on in
  each, and a second at the reset in `map-temple-game-over-invented`
  (tick 10,838) and `map-perfect-after-clear-invented` (tick 3,125).
  Between power-on and those resets SRAM changed in bank 0 (the map's
  save) and in the level map's 48 rows (blocks and object map) only; the
  bytes the decompressors never write, rows 48-63 (`game-017`'s save
  holds `SaveLevel`'s backup there), and bank 3 were as the load left them
  ([the resets](../02-research/resets.md) item 7).
- `LevelSim.current_sram` now gives SRAM after a level played and not saved
  from the level map the port keeps, and `InitLevel` gives an extracted
  level SRAM's rows 48-63 with each row's unwritten bytes
  (`_keep_sram_unwritten_bytes`), so the map reads below row 48 as the
  original's does. A run from power-on compares each load it makes with
  the original's captured one (`--loads`, `_check_loads`).
- `map-temple-game-over-invented`, `MODE=run`: from power-on through the
  fight, the map's save, the game over screen, `GameOverReset`'s `Init`,
  then 3,378 title and 13,753 map loops (Continue) to the trace's end;
  `map-perfect-after-clear-invented`: through the Perfect screen, its
  save, `ResetAfterSave`'s `Init`, then 2,184 title and 669 Action Help
  loops (a demo) to the end. Each run's two loads equal the original's,
  32,768 of 32,768 SRAM bytes. Step: unchanged (518 and 1,165 Wario
  updates, every compared screen loop; the resets left to runs).
- The four buttons held within a level, statically: `title-reset-level-game-017`
  (`make continue-movie` from `game-017`'s save: Continue, into Out of the
  Woods, A, B, Select and Start held at tick 1,700, Continue again). Step:
  every update, 1,011 map and 550 title loops, 46 VRAM snapshots, 40
  screens; `MODE=run`: 1,216 whole level frames, the reset, then 410 title
  and 856 map loops to the end, nothing seeded, both loads' SRAM equal.
- Godot 415 passed (three SRAM tests in place of one), Python 288,
  `make test-rom` 35.
- Then the next pointer, the save after the Perfect screen's screens
  (left uncompared as "a layer the model's fixed registers do not
  show"): with `$2b` and `$2f` compared, 17 of 28 differed and the port's
  frames were black. `SaveScreenVram.FADED_IN` listed the map's save
  screen's sub-states (`$1b`, `$1f`) but not their mirrors after the
  Perfect screen, so the drawing never took the palettes the fades in
  end on. With them, all 28 screens equal the original's, and
  `PAUSE_MENU_DRAWN` compares them. Godot 416.

## Checks

- `make sweeps` on `9ed35c1` (the game over and Perfect screens, the save
  after the Perfect screen): all 34 sweeps unchanged, every update
  identical (Wario 12,965,952, objects 26,744,689, interactions
  13,003,290), all 11,082 movies to the end.
- The 50 movies on `9ed35c1` (the owner's 17, 13 title movies,
  `new-game-ootw`, two golf building movies, 17 map movies), step and
  `MODE=run`: all pass; `map-temple-game-over-invented`'s and
  `map-perfect-after-clear-invented`'s runs stop at their resets' `Init`
  ("SRAM not known whole"), as the handoff said.
- The same 50 on the change (before its commit, in a worktree), step and
  `MODE=run`: all pass, each movie's results line for line as before but
  those two runs, which now go to their traces' ends; the runs with
  captured loads (`title-save-level-game-017`'s two among them, until now
  checked by hand) find each load's SRAM equal to the original's.
- `make sweeps` on `fe0b863` (the reset after an unsaved level): all 34
  sweeps unchanged, every update identical, all 11,082 movies to the end
  (their level movies start from save states, with no load's SRAM).
  `9ff2829` (the save screen's palettes) touches only the drawing of
  sub-states the sweeps never reach; no sweep was run on it.

## Next action

The fight's drawing, a window check of the late screens (the credits, the
game over and Perfect screens, the saves after them), or golf's fades.
