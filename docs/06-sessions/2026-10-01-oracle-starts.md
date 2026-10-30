---
type: session
status: done
updated: 2026-10-01
tags: [session]
---
# 2026-10-01: Oracle starts (WL3-030)

## Outcomes

- The owner asked for all four start options. WL3-030 delivers them
  ([emulator oracle](../02-research/emulator-oracle.md), item 10):
  1. **Boot ROM recorded.** Correction: "power-on" always ran PyBoy's
     bundled boot ROM, a 256-byte CGB stub (`6cc8fc26…`), not "no boot ROM"
     as format 1 files and the research note said. Every start now names its
     boot ROM by SHA-256.
  2. **Save-state starts.** `STATE=` takes a stored state's SHA-256 or an
     outside PyBoy state file. In the editor, Save state (Ctrl+T) and Branch
     (Ctrl+B) store the state with its origin (the parent's start, inputs,
     and memory digest), so `make state-check` can rebuild it.
  3. **Battery saves.** `SAVE=` loads your own raw 32 KiB save at power-on.
     Export save (Ctrl+E) turns a movie's cartridge RAM into a save for new
     movies.
  4. **Your own boot ROM.** `BOOTROM=` takes a 2304-byte CGB dump (or a
     256-byte one, with a warning).
- User files are copied into `local/oracle/` by SHA-256, read-only. The
  originals are only read.
- Routes, captures, and recordings moved to format 2: the boot ROM and
  cartridge RAM moved into the start, and save-state starts were added.
  Format 1 is refused with a "re-create it" message. No user recordings
  existed yet. The route was regenerated and kept its exact memory digest;
  the walk capture kept its exact stream.
- Every movie's first frame now sets all eight buttons explicitly, so a
  state's own held buttons cannot leak in. PyBoy's joypad code shows this
  cannot raise a spurious interrupt, and the unchanged digests confirm it.

## Tests

Observed passing on the host: `make test` (166 Python passed, 19 ROM tests
deselected; Godot import OK, 21 passed), `make test-rom` (19 passed,
including `starts-check` and `tas-check` through PyBoy), `make oracle-check`,
`make oracle-verify` with each of `STATE=`, `SAVE=`, and `BOOTROM=`,
`make state-check`, `make docs-check`, and `make repo-check` before the
commit. A route start combined with a battery save was refused as intended.
The scripted editor test ran on the desktop again (its window appears for a
few seconds). It now also branches, records 30 frames, saves, and replays
the branch from its state; a screenshot confirmed the branch's start line
and inputs. A reopened branch movie reached its saved final checkpoint.
`Original_ROM/` was unchanged.

## Blockers and gaps

- Nintendo's CGB boot ROM has not been run: there is none locally, and none
  will be downloaded. Movies record which boot ROM they used, and do not
  replay across different ones.
- Real keyboard input in the editor is still untested.

## Next action

WL3-012: make the native walk reproduce the oracle capture tick for tick.
