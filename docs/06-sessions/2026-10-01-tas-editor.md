---
type: session
status: done
updated: 2026-10-01
tags: [session]
---
# 2026-10-01: TAS editor for the oracle (WL3-029)

## Outcomes

- The owner asked for an easily recordable, TAStudio-like setup with the
  emulator screen visible. `make tas NAME=… [START=…]` opens a Tkinter
  window ([emulator oracle](../02-research/emulator-oracle.md), item 9) with:
  - the live screen at 3×;
  - a piano roll: click a frame number to seek, click or drag cells to set
    buttons, and rows marked for the greenzone, lag frames, and frames past
    the end;
  - a RAM watch of the sampled WRAM variables;
  - play and pause, frame advance and back, speeds from 6% to max, record
    mode (live keys overwrite and then extend the movie), go to frame,
    insert and delete frames, undo, and save.
- `tools/wl3pc/tas.py` holds the editing model, with compressed save states
  every 10 frames. An edit rewinds to the edited frame, and the window seeks
  back when the gesture ends. Movies save as oracle recordings, so
  `make oracle-replay` and captures accept them.
- Tkinter (Tk 9.0) was already installed for `/usr/bin/python3`; nothing was
  installed. Pillow's `ImageTk` does not load with this Tk, so frames go to
  Tk as PPM data.

## Tests

Observed passing on the host: `make test` (155 Python passed, 18 ROM tests
deselected; Godot import OK, 21 passed), `make test-rom` (18 passed,
including `tas-check` through PyBoy), `make tas-check`, `make docs-check`,
and `make repo-check` before the commit.

The scripted window test (`oracle tas-selftest`) ran twice on the desktop
display, after warning the owner that a window would appear. The first run's
window-only screenshot showed a blank screen after saving: the checkpoint
pass had not rendered. That was fixed; the second screenshot showed Wario in
Out of the Woods, the piano roll, and the RAM watch. A full redraw took
5.3 ms on average.

The model's unit tests caught a wrong expectation in my own undo test
(edits only rewind, never move forward), which was corrected. `Original_ROM/`
was unchanged throughout.

## Blockers and gaps

- Real keyboard input in the editor and the recorder has not been exercised:
  the self-test sets held buttons directly.
- No markers, branches, or multi-frame copy and paste yet.

## Next action

The owner records with `make tas NAME=… START=ootw-day1-start`. Then
WL3-012: make the native walk reproduce the oracle capture tick for tick.
