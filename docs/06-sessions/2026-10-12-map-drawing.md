---
type: session
status: done
updated: 2026-10-12
tags: [session, validation]
---
# 2026-10-12: The map drawn (WL3-052)

Resumed from the [2026-10-02 session's](2026-10-02-wario-states.md) pause
note. The owner asked for the work to continue and for Git and the vault to
be left clean. A second agent session ran alongside, with the same brief.

## Outcomes

- The map's drawing (WL3-052), left by a stopped subagent in the ignored
  copy `build/agent/mapdraw`, was checked there on all 17 owner movies
  first. Nothing differed, so the copy was kept and merged into `game/`:
  `OverworldVram`, the records in the map's sims, the parity script's
  per-visit models, the window's drawing of the map and its save screen,
  `main.gd` loading `overworld.json`, and 7 unit tests
  ([the map](../02-research/overworld.md), item 8). `make wario-parity`
  now prints the map's drawing.
- Result: 586 of 586 VRAM snapshots match on the bytes the model wrote, and
  460 of 460 compared screens are identical pixel for pixel. All 19,478 map
  loops and 36 ways out, and the save screen's 2,494 loops, 71 snapshots,
  and 44 screens, are unchanged.

## Tests

- `make test`: 250 Python passed (34 ROM tests deselected); Godot 291
  passed, 0 failed, 0 skipped.
- `make smoke`, `make smoke-level` (all 300 Wario and camera positions
  equal the oracle), `make test-rom` (34 passed).
- `make wario-parity` on the 17 movies, step and run: every step check
  passed, and every run reached the end of its trace.
- `make docs-check`, `make repo-check`, and `git diff --check` before each
  commit.
- The 34 regression sweeps were rerun after the commit; the outcome is in
  [sweeps after the commit](#sweeps-after-the-commit).
- Skipped: `make window-check` and any desktop check of the window. The
  level's drawing path is unchanged, and native play does not reach the
  map, so the window's map has been checked only through the parity
  script's renders of the same models.

## Sweeps after the commit

Step: all 34 sweeps (11,082 movies) unchanged: 12,965,952 Wario,
26,744,689 object, and 13,003,290 interaction updates, all identical.
Run: all 11,082 movies run whole frames to the end.

## Blockers and gaps

- Native play has not been seen reaching the map. It does not load the
  progress a save gives the map, and entering a level from the map is not
  ported.

## Next action

WL3-052: native play from a level into the map, then entering a level from
it (the level's sub-states 0-2, `InitLevel` loading the chosen level's data
by `wLevel`, from the 140 extracted level variants). After that, play goes
on from a level through the clear screen, Action Help, the map, and the
save, into the next level. WL3-048: movies that fight the bosses and play
the Shoot minigame.
