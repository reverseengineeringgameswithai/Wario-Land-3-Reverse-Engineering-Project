---
type: session
status: done
updated: 2026-10-28
tags: [session, validation]
---
# 2026-10-28: The hidden figure's fight drawn (WL3-052)

The owner asked the agent to go on to the next task. Of the handoff's
pointers (the fight's drawing, a window check of the late screens, golf's
fades), the agent took the fight's drawing: the fight was ported and
matched at every update, but the window drew the Temple level's room
blocks, not the figure.

## Done

- What the original shows, read in the disassembly and measured on
  `map-temple-win-invented` with scratch PyBoy scripts: `LoadHiddenFigureGfx`
  replaces the level's graphics (the figure on BG map 0, the floor in the
  window from line 136); during the fight only Wario's tile set and the
  room's animated tiles change VRAM; the figure's palette flashes and
  Wario's flicker are written one palette an H-Blank while the frame is
  drawn; all four objects use one OAM table, `63:488a`
  ([the fight drawn](../02-research/hidden-figure-drawing.md)).
- `wl3pc.extract.temple` (`temple.json`, in `make extract`); the sim's
  records for the drawing (`hidden_figure_gfx_loads`, `rWY`,
  `hidden_figure_bg_pals`, `hidden_figure_bg_pal_writes`; `Func_4cfe0` and
  `Func_4d005` ported at their four call sites); `TempleVram`, drawn by
  `CgbScreen` (which can now write a palette from a line) and shown by
  `LevelView`.
- The tracer records the Temple's VRAM and screen at every 32nd fight
  update (`temple_vram`, `temple_screens`) and every palette write's line
  in a level (`pal_writes`); the schema has them, and the ten movies that
  reach the fight were re-traced. `make wario-parity MODE=run` compares
  them (`the fight's drawing: …`).
- The first run matched every VRAM snapshot and the lost fight's screens;
  6 of the won fight's 79 screens were 2 lines off, in frames where
  `wSCYShake` was 2: `LevelVBlankFunc` adds the shake to `rSCY` again,
  and the fight's `wSCY` holds it already. With it, all match.
- The window from power-on, with `map-temple-win-invented`'s inputs by
  loop (a scratch script), at two compared frames: equal to the original
  but for what a loop writes while its frame is drawn, which the window
  shows a frame late (the floor's 8 lines at a shake's end, Wario's
  colours at a flicker).

## Checks

- The ten fight movies, step and `MODE=run`: all pass; 446 of 446 VRAM
  snapshots and screens, 320 of 320 frames' `SetBGPals` calls.
- The 51 movies of the recheck (the owner's 17, 14 title movies,
  `new-game-ootw`, two golf building movies, 17 map movies), step and
  `MODE=run`, on the change before its commit: all pass (36 runs to their
  traces' ends, 15 with no level). The last session's outputs were not
  kept, so they were not compared line for line.
- Godot 423 passed (7 new), Python 291 (3 new), `make test-rom` 36 (1
  new).
- `make sweeps` on `cb46f93` (the fight drawn): all 34 sweeps unchanged,
  every update identical (Wario 12,965,952, objects 26,744,689,
  interactions 13,003,290), all 11,082 movies to the end (none reaches
  the Temple; their traces predate the new records).

## Next

- Pick up from the [current state](../01-project/current-state.md).
