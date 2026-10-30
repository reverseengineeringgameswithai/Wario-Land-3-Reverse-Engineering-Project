---
type: session
status: done
updated: 2026-10-12
tags: [session, validation]
---
# 2026-10-12: The pause menu (WL3-052)

While the sweeps of the [native chain](2026-10-12-native-chain.md) ran,
the owner asked what else could be done; the agent chose the in-level
pause menu, the only thing that stopped a native run in the owner's
movies.

## Outcomes

- A subagent translated the pause menu and the level's save from it
  (`PauseMenuSim`: sub-states 0-$0f) in an ignored copy of `game/` and the
  tools, from a copy of the native chain's work, and extended the pause
  menu extractor (format 2: 21 framesets, the OAM table, two palette
  sets). The agent then reviewed its changes, applied them onto the
  committed `game/` (one hunk by hand), and added a labelled stand-in for
  the window, which does not draw the menu yet
  ([the pause menu](../02-research/pause-menu.md)).
- The subagent's attempts to overwrite its scratch copy of the extracted
  `pause_menu.json` were refused twice by the session's permission check.
  It wrote the new file to another scratch folder instead, and the agent
  did not repeat the refused overwrite: the content was regenerated the
  usual way, by `make extract`, which changed only `pause_menu.json`
  (equal to the subagent's file, SHA-256 `e0f3b89b…`). The owner was told.
- Results: 2,897 of 2,897 compared loops of the pause menu's table match
  (`game-016`'s 403 new ones among them), 20 of 20 ways out; the save
  screen's drawing and the map's results are unchanged.

## Tests

- `make test`: 255 Python passed (34 ROM tests deselected; the override
  test now lists `PauseMenuSim._init`, which adds SRAM banks 2 and 3);
  Godot 307 passed, 0 failed, 0 skipped.
- `make smoke`, `make smoke-level`, `make test-rom` (34 passed).
- `make wario-parity` on the 17 movies, step and run: every check passed;
  the totals are above.
- `make docs-check`, `make repo-check`, and `git diff --check` before the
  commit. The regression sweeps ran on the next commit (`49a61a9`, the
  faster sweeps), which contains this one: all unchanged
  ([faster sweeps](2026-10-12-faster-sweeps.md)).

## Blockers and gaps

- The pause menu is not drawn. The reset after the level's save runs
  `Init` (WL3-055). A native run stops at `SaveLevel`'s copy of the level
  map's SRAM, whose bytes between the map's rows it cannot know.

## Next action

WL3-055: the save's load at power-on.
