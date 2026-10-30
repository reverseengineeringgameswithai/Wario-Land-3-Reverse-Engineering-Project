---
type: research
status: active
updated: 2026-10-28
tags: [research, validation]
---
# The game over screen

**Question:** what does the game over screen do, game loop by game loop,
from the map's save screen after the hidden figure's fight is lost to
Wario's waking and the reset, and can the port play it natively after a
whole game, equal to the original at every loop and on screen? Task:
WL3-052.

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys @ `560fce6` (`src/engine/game_over/state_table.asm`,
`core.asm`, `load_gfx.asm`, `common.asm`, `src/game_over.asm`,
`src/data/game_over/`, `src/data/overworld/oam_1.asm`,
`src/home/load_game_over_sprite.asm`, `vblank.asm`, `object_animation.asm`,
`sprite.asm`, `clear_memory.asm`, `src/engine/pause/save/save.asm`,
`src/ram/wram.asm`, `src/macros/wram.asm`); the oracle traces of
`map-temple-all-treasures-invented` (power-on with an invented save
through the hidden figure's fight, lost, the map's save screen, and the
game over screen to tick 10,000) and `map-temple-game-over-invented`
(the same way, then A on the game over screen, its reset, and the title
and the map after it, to tick 28,000).

## Verified observations

1. **States.** The map's save screen ends in `TransitionAfterSave`, whose
   `.game_over` (for `TRANSITION_GAME_OVER`, $f3) sets `ST_GAME_OVER`
   ($0c). `GameOverStateTable` (01:47fd) farcalls `_GameOverStateTable`
   (36:7277) with WRAMX bank 3 mapped; by `wSubState`: `FastFadeToWhite`,
   `InitGameOverScreen`, `SlowFadeFromWhite`, `UpdateGameOverScreen`,
   `Func_db3e4`, `FastFadeToWhite`, `GameOverReset` (0-6), then nine
   `DebugReset` entries. `GameOverReset` is `jp Init` (`core.asm` 176-177),
   as `DebugReset` is. The tracer records each loop at 36:7277.
2. **On the movies.** `route6`: 329 game over loops from tick 9,667: the
   fade to white 33, `InitGameOverScreen` 1 (ticks 9,700 to 9,705, the LCD
   off), the fade in 33, and `UpdateGameOverScreen` 262 to the trace's
   end. `ending`: 440 loops from tick 10,386: the same 67, then
   `UpdateGameOverScreen` 257, `Func_db3e4` 82, the fade to white 33, and
   `GameOverReset` 1 (tick 10,830); the title's next visit starts at tick
   10,849. `wTransitionParam` is $f3 on both.
3. **The screen.** `LoadGameOverPals` loads `Pals_db509` and `Pals_db549`
   into the temporary palettes and copies one palette of `Pals_86ad5`
   (21:6ad5, the map's) over `wTempPals2`'s first (`load_gfx.asm` 52-62).
   `LoadGameOverGfx` decompresses `GameOverGfx` ($1800 bytes) to VRAM 0's
   $8000, then copies `WarioSleepGfx`'s $80 tiles (76:6800, uncompressed)
   over its start; `Func_db4cf` decompresses `GameOverAttrmap` and
   `GameOverTilemap` ($400 bytes each) to BG map 0, after
   `FillBGMap0_With7f`. It sets `VBlank_GameOver` (the scroll and the OAM
   only), the scroll to x 0 and y $60, `LCDC_DEFAULT`, and `wTimer` 64.
4. **Its objects.** Wario (`wGameOverWario`, a `menu_obj_ext_struct`) at
   x $50, y $80 on `Frameset_aaccb`, animated by `UpdateObjAnim` farcalled in
   bank $2a and drawn by `LoadGameOverSprite` (`OAM_aab5c`, bank $2a)
   without the scroll; the text (`wMenuObj1`) at x $18, y $18 on
   `Frameset_dbbf5`, animated in bank $36 and drawn by `Func_db4e9`
   (`OAM_dbbd2`) less `wSCY`, so it moves with the screen
   (`load_gfx.asm` 89-105). The init clears `wGameOverWarioVar` and
   `wSFXTimer`.
5. **No clear after the init.** `InitGameOverScreen` draws both objects
   but does not call `ClearUnusedVirtualOAM` (`core.asm` 1-62):
   `wVirtualOAMByteSize` stays 56 through the fade in, and the first
   `UpdateGameOverScreen` draws after those 14 sprites (28 in the virtual
   OAM at the next loop's start on the movie, 14 after).
6. **The update.** By `wGameOverWarioVar` (`core.asm` 64-154): 0 (and
   any value past 3) counts `wTimer` down, at 0 the next (`SFX_134`);
   1 scrolls the screen up 3 lines a loop (`wSCY` from $60 to 0: the
   screen drops in from above), at 0 `wTimer` 6 and the next
   (`SFX_061`, `MUSIC_GOLF_GAME_OVER`); 2 moves on every 4th loop only
   (`ret nz` at line 98 returns before anything is animated or drawn on
   the others), 2 lines down on odd counts and 2 up on even ones, and
   after the sixth the next (`MUSIC_GAME_OVER`); 3 waits for A
   (`SFX_SELECTION`), which restarts Wario on `Frameset_aace2` and goes
   to `Func_db3e4`. Every loop that reaches `.asm_db3a9` animates and
   draws both, and each end of Wario's animation plays `SFX_SNORE`.
   On `route6`: the wait 64 loops, the drop 32, the bounce 24 (moves at
   counters 168 to 188), and the wait for A 142 to the end; its one A
   press, during the first wait, is ignored. On `ending` the bounce takes
   21 loops (the first move on its first loop) and A comes after 140.
7. **The way out.** `Func_db3e4` animates and draws both until Wario's
   animation ends (`wGameOverWarioAnimationEnded`): `Frameset_aace2`'s 10
   frames take 82 loops (each frame its duration and one more). Then the
   fade to white and `GameOverReset`'s `Init`, which loads the save as
   SRAM now holds it: the title's first loop after it has the save
   screen's progress (`wGameModeFlags` $04, `wDayNight` $80), not the
   power-on save's; banks 1 and 2 hold the level map as the Temple's
   play left it (InitLevel decompresses it there, [the resets](resets.md)).

## Results

| Check | Compared | Differences |
| --- | --- | --- |
| The game over screen, step (`map-temple-all-treasures-invented`) | 328 loops (of 329; the last has no next to compare) | 0 |
| Its drawing | 10 VRAM snapshots, 8 screens | 0 |
| From power-on, run | 142 title, 8,619 map, 106 save screen, and 329 game over loops, 442 whole level frames, to the trace's end | 0; nothing seeded for the game over screen |
| The game over screen, step (`map-temple-game-over-invented`) | 439 loops (of 440: `GameOverReset`'s `Init` left to runs) | 0 |
| Its drawing | 13 VRAM snapshots, 9 screens | 0 |
| From power-on, run | 142 title, 8,619 map, 101 save screen, and 440 game over loops, 1,165 whole level frames, `GameOverReset`'s `Init` (tick 10,830), then 3,378 title and 13,753 map loops (Continue), to the trace's end | 0; the SRAM `Init` loads equal to the original's, all 32,768 bytes |

## Interpretation

- A lost fight's end is ported: a run plays from power-on through the
  hidden figure's fight, the map's save screen, and the whole game over
  screen to its reset, natively and equal to the original at every loop.
- So is the reset after it (2026-10-28): `Init` loads SRAM banks 1 and 2
  as the Temple's play left them, which the port keeps in its level map
  ([the resets](resets.md) item 7), and a run goes on natively through the
  title and Continue to the map. The step check, which keeps no SRAM (the
  map's save screen saved since power-on), leaves it to runs, as the
  pause menu's reset after a level's save.

## Hypotheses

- None open for the screen itself.

## Unknowns

- `DebugReset` is not met. The sounds and the music are not simulated.

## Tests

- `tests/test_game_over.py`: the extractor on a synthetic ROM, its places
  and the port's constants against the reference build's symbols.
- `game/tests/unit/test_game_over.gd`: `InitGameOverScreen`, the first
  update after its sprites, the wait, the drop and the bounce (every 4th
  loop), A and `Func_db3e4`, the fade, `LevelSim`'s routing with
  `GameOverReset` and `DebugReset`, and `GameOverVram`.
- `make wario-parity MOVIE=local/recordings/map-temple-all-treasures-invented.recording.json`
  and `map-temple-game-over-invented`, step and `MODE=run`.

## Next experiment

None for the screen; its music and sounds are not simulated.
