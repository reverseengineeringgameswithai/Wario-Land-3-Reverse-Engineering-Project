---
type: guide
status: active
updated: 2026-10-18
tags: [development, tooling]
---
# Workflow

How work is done in this repository. The rules for agents are in
[AGENTS.md](../../AGENTS.md); this note adds the detail.

## Commands

| Target | What it does |
| --- | --- |
| `make doctor` | Host, tools, pinned toolchain, references, ROM identity |
| `make test` | ROM-free Python tests plus headless Godot import and tests |
| `make test-rom` | Optional tests against the local ROM (labelled skips without it) |
| `make smoke` | Headless main-scene selftest compared with the recorded snapshot |
| `make content-check` | Schema and semantic validation of the pack, traces, and example mods |
| `make docs-check` | Links, anchors, front matter, and tags in the vault and root docs |
| `make repo-check` | Index audit for protected paths, ROM payloads, and generated files |
| `make run [MODS=dir] [CONTENT=dir]` | Prototype window; `CONTENT` loads another pack, such as the extracted room |
| `make run LEVEL=0` | Play an extracted level with its room graphics, the ported Wario (a box for now), and the camera (arrows, X = A, Z = B, F2 collision view, Esc quits; unported routines are named on screen) |
| `make run SAVE=file.sav\|sha256\|none` | Start at power-on with a 32 KiB battery save (a file, or a stored save's SHA-256), or none for a new game: the save's load, the title, the language selection, the prologue, the map, and the levels it enters, natively |
| `make export-linux` | Export to `dist/linux`, check the pack, run it outside the checkout (also against the extracted room and level 0 when they exist) |
| `make extract` | Decode block tables and materials, rooms, level headers and maps, Wario's movement tables, and level 0's collision into `local/content` (needs the ROM) |
| `make room-pack` | Build the first room as an `original-extracted` pack in `local/content/packs` and validate it (needs the ROM) |
| `make smoke-extracted` | Headless selftest on that pack (labelled SKIPPED without it) |
| `make smoke-level` | Headless run of the ported Wario from level 0's start under the walk input, compared with the oracle (labelled SKIPPED without the level) |
| `make wario-trace MOVIE=…` | Record every Wario update of a movie through hooks (`local/captures/`) |
| `make screen-check MOVIE=… TICKS=…` | Compare the background on screen at those ticks with one composed from the decoded room graphics |
| `make sprite-check MOVIE=…` | Check Wario's OAM entries, tiles, and pixels on the original's screen against his decoded sprites, every frame |
| `make window-check [TRACE=… TICKS=…]` | Save the game window after those ticks of a trace from level 0's start (default: the walk) and compare it with the original's screen; opens the window briefly per tick |
| `make save-load-check` | Capture the save's load at power-on from each owner's movie's save, and with none (ROM + PyBoy), then check `SaveLoad` byte for byte |
| `make continue-movie SAVE=… NAME=… [PRESSES=… TICKS=… ROUTE=…]` | Record a movie that powers on with a stored save (`SAVE=none`: no save), takes Continue at the title, and waits on the map (ROM + PyBoy); `PRESSES=200:a,600-1600:right,…` scripts single ticks and held ranges instead (buttons joined by `+`); `ROUTE=ootw-day1-start` plays a power-on route's input first (a new game) |
| `make sweeps [JOBS=14] [SNAPSHOT=1]` | The 34 regression sweeps (11,082 movies) in one pool, after every change: each movie checked in step and run mode by one Godot process, several movies a process, the longest first; results and summaries as `make sweep` writes them, with totals. `SNAPSHOT=1` checks a copy of `game/` and the content (`build/snapshots/COMMIT`), so the next change can be made meanwhile; run one sweep at a time, since they share `local/reviews/sweeps` |
| `make sweep SCRIPT=… [MODE=run] …` | One sweep: a script's movies of the 25 levels (or their room starts) |
| `make wario-parity MOVIE=… [MODE=run]` | Rerun those Wario updates and camera runs natively and require identical results, plus the level start; `MODE=run` runs whole frames alone on the movie's input |
| `make oracle-check` | Replay the tracked emulator route from power-on and require its end state and memory digest (ROM + PyBoy) |
| `make oracle-verify [TRACE=file]` | Capture an input trace from the route twice in separate emulators and require identical results |
| `make tas NAME=… [START=…\|STATE=…\|SAVE=…\|BOOTROM=…]` | TAS editor on `local/recordings/NAME`: live screen, piano roll, RAM watch, record, seek, edit, save state, branch, export save (keys shown in the window). A new movie starts at power-on, a route, a stored or outside save state, with your battery save, or with your boot ROM |
| `make tas-check` | Check the editor's seeking, editing, and saving against straight replays |
| `make starts-check` | Check boot ROM files, battery saves, and save states as starts against straight replays |
| `make state-check SHA=…` | Load a stored state and rebuild it from its recorded origin |
| `make review MOVIE=… [EVERY=30]` | Timeline of game events, contact sheets, collision-probe trace, and live map check for a recording or trace (`local/reviews/`) |
| `make probes MOVIE=…` | Collision-probe trace only (`local/captures/`) |
| `make oracle-record NAME=… [START=…]` | Minimal recorder window without editing (keys in the [emulator oracle](../02-research/emulator-oracle.md) note) |
| `make oracle-replay FILE=…` | Replay a recording headlessly and check every checkpoint |
| `make refbuild` | Rebuild the pinned disassembly and compare it with the ROM |
| `make verify-clean` | Clone HEAD to a temp dir and run the ROM-free checks there |

The Godot steps fail on any `SCRIPT ERROR`, `Parse Error`, or `ERROR:`
output line, because Godot can exit 0 after script errors.

## Git

- One repository at the project root; `docs/` and `game/` are plain
  directories inside it.
- `main` plus short topic branches. Stage explicit paths
  (`git add -- path`), read `git diff --cached`, and run `make repo-check` before
  committing. The optional hook (`make install-hook`) runs the same check
  and never replaces an existing hook.
- Small commits with their tests and docs, e.g. `tools: add read-only ROM
  inspector`. No all-files commits, history rewrites, remotes, or pushes.
- Adding an ignore rule does not untrack a file. `repo-check` reads the index,
  so it catches files that were tracked before the rule existed.

## Evidence

Research notes separate **verified observations**, **interpretation**, and
**unknowns**, and attach evidence to each claim: ROM SHA-256 or reference
commit, file, symbol, and banked address (`BB:AAAA`), with file offsets
listed separately. Provisional constants say so in data and in code. Update
the [parity matrix](../05-validation/parity-matrix.md) whenever a
subsystem's state changes.

## Notes and properties

- Kebab-case filenames, relative Markdown links (no wikilinks), and no absolute
  paths. `make docs-check` enforces this.
- Front matter: `type`, `status`, `updated` (YYYY-MM-DD), `tags`.
- Ownership: [roadmap](../01-project/roadmap.md) owns milestones,
  [tasks](../01-project/tasks.md) owns the backlog with stable `WL3-###`
  IDs, and [current state](../01-project/current-state.md) owns the handoff. Link
  between them instead of copying.
- Decisions are immutable `ADR-####` notes in `03-architecture/`. To change
  a decision, write a new ADR, set the old one's status to `superseded`, and
  link both ways.
- Superseded research moves to `99-archive/` with a link to its
  replacement ([archive policy](../99-archive/README.md)).
- `assets/` holds only reviewed, shareable attachments: never screenshots of
  original game content.
- Session notes in `06-sessions/` record outcomes, tests, blockers, and the
  next action. They are not transcripts.

Templates: [research note](../90-templates/research-note.md),
[ADR](../90-templates/adr.md), [session handoff](../90-templates/session-handoff.md).

## Tag vocabulary

- `project`
- `research`
- `architecture`
- `decision`
- `development`
- `validation`
- `session`
- `template`
- `rom`
- `collision`
- `movement`
- `content`
- `tooling`
- `licensing`

## Session procedure

1. Read AGENTS.md, [home](../00-home.md), [current state](../01-project/current-state.md),
   the relevant ADRs, and `git status`/`git diff`.
2. Pick one task, implement it, and test it.
3. Update its research note, the parity matrix, and the task status.
4. Write a session note and refresh the current state.
