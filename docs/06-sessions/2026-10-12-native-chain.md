---
type: session
status: done
updated: 2026-10-12
tags: [session, validation]
---
# 2026-10-12: Native play across screens (WL3-052)

After the [map drawing](2026-10-12-map-drawing.md), the owner asked for
work to continue while the sweeps ran, with the agent choosing direction,
toward reverse engineering the whole game and rebuilding it natively. The
work was done in an ignored copy of `game/` and `tools/`, since the sweeps
read both live, and merged after them.

## Outcomes

- The parity script's run mode goes on past a level's end into the screens
  after it (the clear screen, Action Help, the map, the save), and starts
  on the map when a visit's window does: the map, the way into the level,
  the level, and its screens run natively from the movie's input alone
  and are compared before every traced loop
  ([native play](../02-research/native-play.md)).
- The level and the screens keep one RAM
  ([ADR-0004](../03-architecture/adr-0004-one-ram-across-screens.md)):
  `SharedWram` (140 of the level's variables, from the oracle's layout),
  the sync around screen loops, the screens' own WRAM0 variables as
  bytes, and the virtual OAM handed from screen to screen. Native play
  (`LevelRunner.start`) turns it on and gives `InitLevel` the extracted
  levels.
- Ported: the way into a level (`InitLevel` and the two fades),
  `LoadLevelTreasureData`, `wTempLevelRoomID` and `wUnused_ca6c`, and
  `SaveBackupVRAM` at golf's lobby. Fixed: the level start set up the
  room's animation before `StartRoom_FromLevelStart`'s clears, so native
  play started each level with it off.
- The check found its own bug too: loops that share a frame were ordered
  by an unstable sort. They now keep the trace's order.
- Results: every movie runs to its end with no difference (3,767 map and
  503 save loops before the levels, 18 of 18 levels entered, 82,794 level
  frames, 23,885 screen loops after them); two of `game-016`'s visits stop
  at the in-level pause menu, which is not ported.
- An independent review of the change (a read-only subagent) found no
  serious problem and confirmed step mode unchanged. Its six findings were
  fixed before the commit: a failed way into a level now counts as a
  difference (and so does reaching the level early); a map that reaches
  something unported falls back to the level run from the trace; HRAM is
  seeded only the first time a run meets a screen; the replays of loops no
  screen recorded are checked; `wLevelTime` is cleared at the level start;
  and `InitLevel`'s treasure load passes on its notes. The screens' new
  RAM addresses are named constants.
- Next task added and scoped: WL3-055, native play from a save (the save
  loads at power-on in `Init`, not in the title; plan in
  [tasks](../01-project/tasks.md)).

## Tests

After the merge into `game/`:

- `make test`: 254 Python passed (34 ROM tests deselected); Godot 297
  passed, 0 failed, 0 skipped.
- `make smoke`, `make smoke-level` (all 300 Wario and camera positions
  equal the oracle), `make test-rom` (34 passed).
- `make window-check`: every pixel of the walk's five compared screens
  equal, as before the change (it does not show whether the first room's
  animation runs: the walk's screens passed with it off too).
- `make wario-parity` on the 17 movies, step and run, before and after the
  review's fixes: every step check passed (the map's drawing among them,
  unchanged), and every run gave the totals above.
- `make docs-check`, `make repo-check`, and `git diff --check` before the
  commit. The 34 regression sweeps for the commit are recorded in
  [sweeps after the commit](#sweeps-after-the-commit).

## Sweeps after the commit

The step sweeps ran on this commit as before (the 29 first in `game/`, the
last 5 on a snapshot of it): all unchanged, 12,965,952 Wario, 26,744,689
object, and 13,003,290 interaction updates identical, nothing unported.
Their run pass was stopped in favour of the faster sweeps of `49a61a9`,
which contains this commit: all 11,082 movies run whole frames to the end
there, and no screen loop after a level differs
([faster sweeps](2026-10-12-faster-sweeps.md)).

## Blockers and gaps

- A run is seeded at its first map loop. A start from a save (WL3-055)
  would remove that seed; native `make run` still starts in a level with
  no save's progress.
- The level's palettes in WRAM and `wTempBank` are not kept by the
  level's port (`LEVEL_RAM_NOT_KEPT`).

## Next action

WL3-055: translate the title screen's load of a save into the progress
WRAM, check it against the oracle's RAM after loading the same save, then
start native play and a parity run from it.
