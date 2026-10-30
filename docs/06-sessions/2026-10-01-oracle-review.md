---
type: session
status: done
updated: 2026-10-01
tags: [session]
---
# 2026-10-01: Recording session and PyBoy deep dive (WL3-031)

## Outcomes

- The owner asked to record Out of the Woods (gray key and chest) from a
  save state.
  - A state at the start of the level was stored (`6c16166f…`; it rebuilds
    from the route plus 0 frames).
  - `make tas NAME=ootw-gray-key STATE=6c16166f…` was launched detached on
    the desktop.
  - Before launch, the RAM watch gained the key and treasure flags, coins,
    treasures, power-up, and transformation progress. The editor gained
    hold-Tab fast-forward and `-`/`=` speed steps.
- **Deep dive into PyBoy** ([emulator oracle](../02-research/emulator-oracle.md), item 11):
  - Execution hooks on `ProcessBlock` and its 10 return sites trace every
    collision probe without changing the run (identical memory on all 300
    walk frames).
  - The walk's probes agree with the WL3-011 handler mapping. Every probed
    block matches the statically decoded level map (WL3-025).
  - `make review` and `make probes` package this with event timelines and
    contact sheets.
  - PyBoy is LGPL-3.0, so it stays a local development tool.
- **The owner asked about EmuHawk/TAStudio** (item 12). Replay already
  works in the editor. Converting a `.tasproj` is possible for inputs, but
  the game's randomness reads the DIV timer (`BreakBlock` coins, several
  enemies), so it will not stay in sync across emulators. This is WL3-032,
  blocked on a sample file.
- **TAStudio-style editing** (item 13): BizHawk-style hotkeys, markers
  (saved, undoable, shifted by inserts and deletes), and range selection
  with copy, paste, and paste-insert.

## Tests

Observed passing on the host: `make test` (171 Python passed, 20 ROM tests
deselected; Godot import OK, 21 passed) and `make test-rom` (20 passed,
including the probe trace with its mapping and map checks). Also: the hook
experiment (300/300 identical frames), `review` and `probes` on the walk
trace, and the contact sheet viewed as an image. `make docs-check` and
`make repo-check` passed before the commit.

The extended window self-test was held back while the owner's editor was
open, because it would have taken keyboard focus. The owner could not see
that window (most likely behind other windows; Wayland does not let other
programs raise it), and nothing had been recorded in it. So it was closed,
and the self-test ran: markers, Shift+click selection, copy, paste, and
marker jumps all worked in the real window, and the saved movie (with its
marker) replayed. The editor now raises itself when it opens, and was
relaunched on the same state.

### Keyboard, modes, and the map start

The owner reported that the keys did nothing in the relaunched editor. A
new movie opened paused and read-only, so key presses were ignored without
any sign. The owner asked for the key map, a way to leave read-only, and a
visible mode, and for the movie to start on the level-select map rather
than inside the level ([emulator oracle](../02-research/emulator-oracle.md),
item 14):

- New movies open running and recording. A red (recording) or blue
  (read-only) banner and screen border show the mode. Q, Ctrl+R, the Mode
  button, or a click on the banner switch it. The Game Boy key map is
  printed under the screen. Keys pressed while read-only or paused show a
  hint.
- Key releases wait 30 ms, so X11 key repeat does not drop a held button.
- A state on the level-select map (`8b5fd0d5…`, frame 9215 of the route,
  before the Left press for Out of the Woods) was stored and rebuilt from
  power-on. Its screen was viewed: the map, with "The Temple" selected.

The window self-test passed with these changes (fresh-movie defaults, a
release and press in the same instant, and the earlier steps), and its
screenshot showed the blue read-only banner, border, and key map. The
editor was then relaunched on the map state.

After the review change: `make test` (173 Python passed, 20 ROM tests
deselected; Godot import OK, 21 passed), `make test-rom` (20 passed), and
`make review` on the owner's movie and on the walk trace (0 and 0 changed
blocks; 15 and 0 cells differing only in bit 7).

After the BCD and state-name changes: `make test` (175 Python passed, 20
deselected; Godot import OK, 21 passed), `make test-rom` (20 passed), and
`make review` on the extended movie (coins 0 → 21, treasure count 0 → 1 at
frame 6596). The window self-test was **skipped** for the one-line RAM
watch change, because the owner's editor was open; the file compiles and
`sample_value` is unit-tested.

### The owner's recording

The owner recorded and saved `local/recordings/ootw-gray-key.recording.json`
(6031 frames from the map state). `make oracle-replay` matched all 101
checkpoints, and `make review` found the gray key at frame 2040 and the
gray chest at frame 5745 ([emulator oracle](../02-research/emulator-oracle.md),
item 15). The contact sheets were viewed and show the same run.

The map check reported 15 cells that differ from the decoded map. All 15
differ only in bit 7. A per-frame trace of the map in SRAM, a check of all
35 decoded maps, and `SpawnObject`/`DespawnObject` show that bit 7 means
"this block's object is not spawned"
([level block maps](../02-research/level-block-maps.md), finding 7). The
review now sorts these cells from changed blocks (tested ROM-free), and
reads the level where the probes begin, which matters for movies that
start on the map.

The owner then extended the movie through the level clear and back to the
map (8363 frames; the first 6031 unchanged), and it replayed with all 140
checkpoints. The timeline showed no change in the treasure count, although
the clear screen counted the treasure. A per-frame trace found the count
rising at frame 6596: the watch had sampled one byte of a two-byte BCD
counter. Coins are BCD too, so the first review's "33 coins" was `$0021`,
21 coins, as the clear screen shows. Both are fixed and tested, and the
review now names `wState` values (`wState` 8 is `ST_COLLECT_KEY`).

## Blockers and gaps

- WL3-032 needs a sample BizHawk file, and cannot promise sync.
- Real key events (rather than the self-test's direct handler calls) are
  confirmed only by the owner's use.

## Next action

Read the object group (`LoadObjectGroupData`) to learn which object each
nibble selects. Then return to WL3-012.
