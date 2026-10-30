---
type: research
status: active
updated: 2026-10-28
tags: [research, validation]
---
# The Perfect screen

**Question:** what does the Perfect screen do, game loop by game loop,
after a perfect game's credits, and can the port play it natively after
a whole game, equal to the original at every loop and on screen? Task:
WL3-052.

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys @ `560fce6` (`src/engine/perfect/state_table.asm`,
`core.asm`, `common.asm`, `src/perfect.asm`, `src/data/perfect/`,
`src/home/fade.asm`, `vblank.asm`, `object_animation.asm`, `sprite.asm`,
`clear_memory.asm`, `update_level_music.asm`,
`src/engine/credits/credits.asm`, `src/constants/menu_constants.asm`,
`state_constants.asm`, `src/ram/wram.asm`); the oracle trace of
`map-temple-perfect-game-invented` (power-on with an invented save holding
all 100 treasures, the hidden figure's fight won, the perfect epilogue,
its save screen, the credits, and the Perfect screen to tick 28,000).

## Verified observations

1. **States.** After a perfect game (`wTransitionParam` $f2) the credits'
   wait (`Func_160365`) goes to `ST_PERFECT` ($0d) by a button or after
   180 loops (`SetPerfectState`, [the credits](credits.md)). The map's
   way to its save screen (`SaveGameOrEnterPerfectScreen`,
   `src/home/update_level_music.asm`) goes there too, outside Time Attack,
   once a cleared game holds all 100 treasures.
   `PerfectStateTable` (01:4817) farcalls `_PerfectStateTable` (37:4000)
   with WRAMX bank 3 mapped; by `wSubState`: `SlowFadeBGToWhite`,
   `InitPerfectScreen`, `DarkenBGToPal_Fast`, `UpdatePerfectScreen`
   (0-3), then nine `DebugReset` entries (`jp Init`). The tracer records
   each loop at 37:4000.
2. **On the movie.** 2,704 loops from tick 25,292: the fade to white 10,
   `InitPerfectScreen` 1 (ticks 25,302 to 25,307, the LCD off), the fade
   in 10, and `UpdatePerfectScreen` 2,683 (from tick 25,318) to the
   trace's end. Both fades are `FADE_SPEED_FAST` (`SlowFadeBGToWhite`
   too, `fade.asm` 6-9): 10 loops each. `wGameModeFlags` is $07 (Time
   Attack opened by the perfect epilogue) and no button is pressed.
3. **The screen.** `LoadPerfectPals` loads `Pals_dc173` and `Pals_dc1fb`
   into the temporary palettes; `LoadPerfectGfx` decompresses `PerfectGfx`
   ($1800 bytes) to VRAM 0's $8000, and `Func_dc13e` `PerfectAttrmap` and
   `PerfectTilemap` ($400 bytes each) to BG map 0, after
   `FillBGMap0_With7f`. It sets `VBlank_Perfect` (the scroll and the OAM
   only), the scroll to 0 (the credits left `wSCX` 4), `LCDC_DEFAULT`,
   `MUSIC_PERFECT`, and clears `wTimer` and `wGameOverWarioVar`.
4. **Its object.** `wMenuObj1` at x $2b, y $23 on `Frameset_dd848` (8
   frames of 4 loops), animated by `UpdateObjAnim` in bank $37 and drawn
   by `Func_dc158` (`OAM_dd710`, 8 to 10 sprites a frame) without the
   scroll. As on the game over screen, `InitPerfectScreen` draws it but
   does not call `ClearUnusedVirtualOAM` (`core.asm` 1-45):
   `wVirtualOAMByteSize` stays 32 through the fade in, and the first
   update draws after those sprites.
5. **The update** (`core.asm` 47-114). Each loop animates and draws the
   object. While `wTimer` counts down nothing else runs; on the loop it
   reaches 0 (or with it 0) every 8th loop (`wGlobalCounter` & 7) is a
   step of `SlowFadeInScreen`. Its 33rd step moves the sub-state on; the
   update puts it back to 3 (lines 66-68) and counts `wGameOverWarioVar`
   (the game over screen's Wario state, reused): 1 sets `wTimer` 240 and
   takes `Pals_dc1b3` for `wTempPals1`'s palettes 5-7 (`Func_dc10d`), 2
   and 4 `Pals_dc1cb` (`Func_dc119`), 3 `Pals_dc1e3` (`Func_dc125`), 5
   `Pals_dc1b3`, and past 5 the count goes to 0 with `Pals_dc173`'s own
   palettes 5-7 (`Func_dc101`). The next fade goes to them, so the screen
   fades from set to set, 264 loops each (33 steps 8 loops apart), the
   first after a 240-loop wait. The first fade, before any count, steps
   to the palettes the fade in already reached. On the movie the count
   reaches 1 at loop 284, 2 at 780, then every 264 loops, 0 at 1,836,
   and 1 again at 2,100.
6. **The way out.** Outside Time Attack any button clears the fade
   (`wFadeSpeed`, `wPalFadeCounter`, `wUnused_c186`; the V-Blank function
   a fade set aside is not put back), opens Time Attack, and takes the
   pause menu's `SST_PAUSE_28` (`core.asm` 97-114). A perfect epilogue
   opens Time Attack itself (`src/engine/level/update_level.asm` 221-224),
   so after the credits the screen stays; only the map's way in, after a
   game cleared without all the treasures, leaves it closed.
7. **`wUnused_c186`.** Each fade sets it at its set-up and clears it at
   its end (`fade.asm` 22-23, 170, 306-307, 498, 513-514, 673); nothing
   reads it. The Perfect screen's trace records it: 1 through each fade.

## Results

| Check | Compared | Differences |
| --- | --- | --- |
| The Perfect screen, step (`map-temple-perfect-game-invented`) | 2,703 loops (of 2,704; the last has no next to compare) | 0 |
| Its drawing | 84 VRAM snapshots, 84 screens | 0 |
| The credits' way out to it | 1 | 0 |
| From power-on, run | 142 title, 14,814 map, 605 save screen, 6,901 credits, and 2,704 Perfect loops, 2,450 whole level frames, to the trace's end | 0; nothing seeded for the Perfect screen |
| The button's way out, run from power-on (`map-perfect-after-clear-invented`) | 518 level frames, then 34 map, 1,072 Perfect, and 985 save loops, `ResetAfterSave`'s `Init` (its SRAM byte for byte), 2,184 title and 669 Action Help loops, to the trace's end | 0 |

## Interpretation

- A perfect game's end is ported: a run plays from power-on through the
  hidden figure's fight, the perfect epilogue, its save screen, the
  credits, and the Perfect screen's palette cycle, natively and equal to
  the original at every loop and on screen.
- `PerfectVram` steps the palettes toward the sets each step saw: the
  loop that ends a fade changes the target after its step.
- `wUnused_c186` is kept by the Perfect screen's fades only; the port's
  other fades leave it, which every trace that records it allows (each
  fade ends by clearing it).

- The map's way in, then the button: `map-perfect-after-clear-invented`
  (a save invented from the perfect game's with the game cleared,
  `MODE_GAME_CLEARED` and `MODE_FOUGHT_A_HIDDEN_FIGURE`, labelled:
  `d87e3e67…`) enters the first level, takes To Map from the pause menu,
  and the map's save (`SaveGameOrEnterPerfectScreen`: the game cleared,
  Time Attack closed, 100 treasures) enters the Perfect screen; A takes
  the pause menu's `SST_PAUSE_28`. Its 1,071 Perfect loops, 33 VRAM
  snapshots and screens, and the way out match. `SST_PAUSE_28` to `$31`
  are the map's save screen's steps again (`$18` to `$20`), then
  `ResetAfterSave` (`Init`) instead of `TransitionAfterSave`: ported, all
  983 of the movie's save loops, 29 VRAM snapshots, and 28 screens match;
  then the title and Action Help's demo (2,324 and 668 loops) match too.

## Hypotheses

- None open for the paths the movies reach.

## Unknowns

- `DebugReset` is not met. The music is not simulated.

## Tests

- `tests/test_perfect.py`: the extractor on a synthetic ROM, its places
  and the port's constants against the reference build's symbols.
- `game/tests/unit/test_perfect.gd`: `InitPerfectScreen`, the fades with
  `wUnused_c186`, the first update after the init's sprites, the fade in
  every 8th loop and the palette cycle, the way to the pause menu,
  `LevelSim`'s routing with `DebugReset`, and `PerfectVram`.
- `make wario-parity MOVIE=local/recordings/map-temple-perfect-game-invented.recording.json`,
  step and `MODE=run`.

## Next experiment

None for the screen: its save's screens are compared too (2026-10-28: the
6,000 to 7,000 pixels that differed were the save screen's palettes, which
the port's drawing did not take at `$2b` and `$2f`, not a layer).
