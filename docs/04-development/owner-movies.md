---
type: guide
status: active
updated: 2026-10-23
tags: [development, validation, tooling]
---
# The owner's game movies

The owner records the game with the TAS editor so that the battles and other paths scripted
movies cannot reach meet the oracle (WL3-048 in [tasks](../01-project/tasks.md)). This note is the
agreement on how those movies are made, named, and checked. Agents: read it before touching
`local/recordings/`.

## How they are recorded (agreed 2026-10-03)

- **A chain, not one movie.** One movie per level visit (a visit usually ends with that level's
  treasure), each started with **Ctrl+B** (branch) from a frame of the previous movie, usually its
  end on the map. A branch starts from the exact saved state of that frame, so progress
  (treasures, power-ups, keys, which variant of a level loads) carries over. Idling on the map
  before branching does not matter. A movie started any other way (from power-on, or played back
  to the same place by hand) breaks the chain.
- **Why not one movie for the whole game:** traces are about 18 MB per minute of play, the parity
  tool loads a whole trace into memory, and it loads one level's data per trace (the first level
  the trace enters), so a movie spanning several levels is checked against the wrong map after the
  first.
- **Any order, no glitches.** The game has no single order; chests have prerequisites, and the
  owner's natural route satisfies them by definition. Mistakes, damage, and failed attempts are kept
  (they reach code a clean run skips); a movie is only redone for a technical problem. A long visit
  (over about 10 minutes) may be split with another branch mid-level.
- **Movie 1** is `ootw-gray-key` (Out of the Woods, gray key and chest; [emulator
  oracle](../02-research/emulator-oracle.md), item 15). It starts from a saved state on the map at
  frame 9215 of the tracked route `ootw-day1-start`, so the whole chain rebuilds from power-on
  (`make state-check`). Recording the title and menus by hand would add nothing until they are
  ported.
- **When to record (2026-10-23):** agents reach new code first with scripted movies, labelled
  invented saves, and emulator planners, and ask the owner for a movie only when a path cannot be
  reached that way (above all the boss battles' later phases, WL3-048). Collecting a level's 8
  musical coins and playing golf are checked now too (the clear screens, golf, and the golf
  building are ported), so they are welcome in any movie.

## Naming and renaming

- While recording, the owner names movies `game-002`, `game-003`, ... (Ctrl+B asks for the name;
  letters, digits, `-` and `_`).
- When the owner says some are finished, the agent renames each to `game-NNN-<level>-<colour>`
  (for example `game-002-ootw-red`), keeping the number for the order. The level is `wLevel` / 8
  (`src/constants/level_constants.asm`: `$00` Out of the Woods, `$08` The Peaceful Village, ...;
  `wLevel` bit 2 is night). The colour is the key or chest the visit collects: `wKeyAndTreasureFlags`
  bits 0-3 are the gray, red, green, and blue keys, bits 4-7 their chests (`GREY_KEY_F` ...
  `BLUE_TREASURE_F`). A visit without a chest is named for what it does.
- **Only finished movies are renamed**, never the one open in the editor: its next Ctrl+S would
  write it back under the old name. Renaming is safe for the chain: a branch's start stores the
  previous movie's start and full input (`TasSession.save_state_here`), not its file name; the old
  name stays only as a label in the next movie's origin.
- The agent keeps a list of old and new names in `local/recordings/game-movies.md` (local, not
  tracked, like the movies themselves).
- **Cutting a movie** (the owner may ask, e.g. to end it at a frame): the agent keeps the inputs
  before that frame, replays the result from its start to rebuild the checkpoints, checks that the
  replay matches and that every checkpoint it shares with the original is identical, and keeps the
  original in `local/recordings/originals/`. A branch already made from the movie is unaffected (its
  start stores its own input), as long as the cut is not before its branch frame.
- **The editor is started detached** (`setsid nohup make tas NAME=...`), never as a time-limited
  agent task: one launched that way was stopped after 30 minutes while the owner was recording.

## What the agent does with each movie

A movie may enter several levels (leaving one, pausing out, resetting at the title): `make
wario-parity` checks it a level visit at a time.

1. `make wario-trace MOVIE=local/recordings/<name>.recording.json`.
2. `make wario-parity MOVIE=...` in step and run mode; anything unported is ported by translation,
   anything that differs is fixed, as for the sweeps.
3. The results go into the research notes (objects, Wario movement, block handlers) and WL3-048's
   progress, with the movie's name and what it reached.
