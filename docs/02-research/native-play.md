---
type: research
status: active
updated: 2026-10-18
tags: [research, validation]
---
# Native play across screens

**Question:** can the port play an owner's movie natively from its first
map loop to its end (the map, the way into the level, the level, its clear
screen and Action Help, the map, and the save) from the movie's input
alone, and what must change for it to equal the original at every traced
loop? Task: WL3-052.

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys @ `560fce6` (`src/engine/level/state_table.asm`,
`init.asm`, `start_room.asm`, `src/engine/golf/lobby.asm`,
`src/home/backup_vram.asm`, `src/ram/wram.asm`); oracle traces of the
owner's 17 movies; an oracle replay of `game-007` watching WRAMX bank 3
`$d500`. Design: [ADR-0004](../03-architecture/adr-0004-one-ram-across-screens.md).

## Verified observations

1. **Two copies of one RAM.** The level's port keeps the game's variables
   as fields (`WarioRam`); the screens keep their RAM byte for byte
   (`MenuScreenSim`). The step checks load both from the trace every loop,
   so nothing had kept them in step. 140 of the level's traced variables
   live in WRAM0 or WRAMX bank 2 (`SharedWram`, from the oracle's layout;
   `tests/test_shared_wram.py`), and the clear screen's six own WRAM0
   variables, `wTempBank`, and `wSRAMBank` were separate fields per screen.
2. **The way into a level.** `_LevelStateTable` starts with
   `FastFadeToWhite`, `InitLevel`, and `SlowFadeFromWhite` (sub-states
   0-2). `InitLevel` resets the scroll, runs
   `LoadLevelCommonGfxAndTreasures` (the common tiles, then
   `LoadLevelTreasureData`: the level's treasures, their palettes, and
   their tiles in the map's RAM), `StartRoom_FromLevelStart`, turns the
   room animation on, clears `wceef` and four bytes each at SRAM bank 0
   `$a000` and `$a800`, then advances. On every movie the way in takes 67
   loops: 33, 1, and 33.
3. **A level start bug.** `StartRoom_FromLevelStart` clears
   `wAnimatedTilesFrameDuration`, `wRoomPalCycleDuration`, and the
   animation flags, then `LoadRoom` sets them from the room. The port ran
   LoadRoom's part first, so native play started every level with the
   first room's tile animation and palette cycle off. The step check's
   level start never compared these variables, and run mode loaded them
   from the trace.
4. **Level bytes the port did not keep.** `StartRoom_FromLevelStart`
   clears `wUnused_ca6c`, `wTempLevelRoomID`, and `wLevelTime`. `StartRoom_FromTransition`
   sets `wTempLevelRoomID` to the new room and `wUnused_ca6c` to Wario's
   position's high bytes (Y's swapped, or X's). Only a level resumed from a
   save reads `wTempLevelRoomID`, and nothing reads `wUnused_ca6c`, but the
   save copies both.
5. **Golf's backup.** `InitGolfLobby` calls `SaveBackupVRAM` on golf's
   first entry from a level (`w1d800` 0): `wSCY` and `wSCX` to GFX RAM's
   `w3d500` and `w3d501`, and the temporary palettes to `w3d280`. The golf
   port skipped it. The oracle replay of `game-007` shows `w3d500` going
   from 4 to 0 at tick 3153, in golf's sub-state 1.
6. **What the level writes that the port does not keep.** The level's
   palettes in `wTempPals1`/`wTempPals2` (`$c000-$c07f`) and `wTempBank`
   differ at the map's first loop after a level, and nothing else does
   once items 3-5 are ported.

## Interpretation

- With the two copies kept in step (ADR-0004), the way into a level
  ported, and items 3-5 fixed, the port plays every owner's movie natively
  from its first map loop to its end, as far as the screens are ported.
  See [results](#results).
- The remaining difference to power-on native play is the movie's start:
  a run is seeded from its first map loop. Native play from `make run`
  still starts in a level with no save's progress.

## Results

`make wario-parity MODE=run` on the 17 movies (19 level visits). A visit's
window starts on the map, where its run is seeded, except `game-016`'s
third, which re-enters its level from the pause menu (not ported) and
starts at the level:

| Part | Natively, compared loop by loop | Differences |
| --- | --- | --- |
| Before the level | 3,767 map loops, 503 save screen loops (18 runs) | 0 |
| The way in | 18 of 18 levels entered (1,206 loops); each start equal to the original's | 0 |
| The level | 82,794 whole frames | 0 |
| After the level | 23,885 screen loops: 4,115 clear, 1,997 Action Help, 15,764 map, 2,009 save | 0 |

17 runs go on to the end of their window; two of `game-016`'s visits stop
where the owner opened the in-level pause menu (sub-state 0, not ported).

What a run takes from the trace, besides its start: the screens' bytes it
has never written when it first meets each screen after a level (what
earlier screens left: the menu objects in WRAMX bank 3, the BG tile
queue, SRAM before the first save), HRAM variables the first time it
meets a screen, the virtual OAM of the first screen after a level (the
level's sprites are not kept as one), and after each level the 129 bytes
of `LEVEL_RAM_NOT_KEPT`. Each seed is listed in the run's report. A run
stops as a difference when a compared loop, the way into a level (its
loop count or its end state), or a replayed rDIV read or room animation
call differs; a map that reaches what is not ported falls back to the
level's run from the trace.

## Unknowns

- Whether the sync's rule (only changes cross) ever meets a variable a
  screen loop changes in both copies. No such loop has been seen.
- The in-level pause menu (not ported) stops two of `game-016`'s visits.

## Tests

- `game/tests/unit/test_shared_ram.gd`: the sync in both directions, the
  screens' shared variables and OAM, the sync off, the level start's room
  animation, the way into a level, and a level not extracted or resumed.
- `tests/test_shared_wram.py`: `SharedWram` equals the oracle layout's
  WRAM entries, the screens' WRAM0 variables are at the screen layouts'
  addresses, and the two level bytes are their labels.
- `tests/test_sweep.py`: sweeps count the screens run on after a level.
- `make wario-parity MODE=run` on the 17 movies.

## Next experiment

Done for a map's save (WL3-055): a run can start at power-on with the
movie's battery save, through the save's load and the title's Continue,
with nothing seeded before the first level ([the title](title.md)). Next:
the title without a save and a level resumed from a save (WL3-056).

Done (WL3-056, WL3-057): a new game plays from power-on through the
prologue into the first level, and the game's resets (the title's demos,
Clear Data, the four buttons, the reset after the level's save) rebuild
the game in place from the SRAM as it is, so native play goes on through
them ([the resets](resets.md)). A run also goes through a screen opened in
the middle of a level and left for it again (the pause menu, Action Help
from it): the loops between two level updates that a screen recorded run
as the screens after a level do, each compared (`_run_level_gap`;
[the pause menu](pause-menu.md)).
