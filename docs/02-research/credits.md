---
type: research
status: active
updated: 2026-10-23
tags: [research, validation]
---
# The credits

**Question:** what do the credits do, game loop by game loop, from the
epilogue's save screen to the music box's close-up and its wait, and can
the port play them natively after a whole game, equal to the original at
every loop and on screen? Task: WL3-052.

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys @ `560fce6` (`src/engine/credits/state_table.asm`,
`credits.asm`, `common.asm`, `src/data/credits.asm`,
`src/data/credits/oam.asm`, `src/credits.asm`, `src/charmaps.asm`,
`src/home/load_credits_sprite.asm`, `update_level_music.asm`, `fade.asm`,
`object_animation.asm`, `sprite.asm`, `copy.asm`, `start.asm`,
`src/ram/wram.asm`); the oracle trace of `map-temple-credits-invented`
(power-on with an invented save through the hidden figure's fight, the
epilogue, its save screen, and the credits to tick 30,000).

## Verified observations

1. **States.** The epilogue's save screen ends in `TransitionAfterSave`,
   which sets `ST_CREDITS` ($09). `CreditsStateTable` (01:4776) farcalls
   `_CreditsStateTable` (58:4000) with WRAMX bank 3 mapped; by
   `wSubState`: `FastFadeToWhite`, `InitCredits`, `SlowFadeFromWhite`,
   `ShowCredits`, `Func_160190`, `Func_16026c`, `Func_1602ee`,
   `Func_160318`, `Func_160365` (0-8), then nine `DebugReset` entries
   (`jp Init`). The tracer records each loop at 58:4000.
2. **On the movie.** 12,767 credits loops: the fade to white 33 (from tick
   17,227), `InitCredits` 1 (ticks 17,260 to 17,267, the LCD off), the fade
   in 33, `ShowCredits` 4,729 (ticks 17,300 to 22,029), `Func_160190`
   1,391, `Func_16026c` 16, `Func_1602ee` 1, `Func_160318` 523 (ticks
   23,437 to 23,960), and `Func_160365` 6,040 to the trace's end.
   `wTransitionParam` is `$f1` (`TRANSITION_EPILOGUE_NOT_PERFECT`).
3. **The screen.** `InitCredits` loads `Pals_1604cc` and `Pals_16050c`
   into the temporary palettes; `PrologueGfx` ($800 bytes) to VRAM 1's
   $8000, `MusicBoxGfx`'s $30 tiles to VRAM 1's $8800, then
   `CreditsFontGfx` ($1800 bytes) and `CreditsMusicBoxGfx` ($1000 bytes)
   both to VRAM 0's $8000, and `CreditsAttrmap` and `CreditsTilemap`
   ($400 bytes each) to BG map 1. It sets `VBlank_160439`, the scroll to
   (0, 4), page 0, the BG map pointer to $9ae7, and the text and palette
   map pointers to `CreditsText` (58:5d0f) and `CreditsPalsMap` (58:60e5),
   with `LCDC_DEFAULT` and the window at (0, 0) (`rWX` 7).
4. **The text.** `CreditsText` is 288 lines (982 bytes), each ending in
   $7f (the credits charmap's `"\n"`); `CreditsPalsMap` is 13 attribute
   bytes a line (3,744). `ShowCredits` waits 120 loops (`wTimer`; the
   music starts at 0), then scrolls a line a loop on pages 0 and 9 and
   every other loop on pages 1-8: `wCreditsPage` is the high byte of a
   16-bit count with `wSCY` (`add 1`, `adc 0`). On pages 1-9 each 8
   lines it copies the next text line and its 13 palettes and moves the
   BG map pointer a row (`and $fb` on its high byte wraps $9c back to
   $98), then sets `wcee4` to $80. 120 + 2 × 256 + 8 × 512 + 1 = 4,729
   loops, the count observed.
5. **Two V-Blanks a line.** `VBlank_160439` with request $80 writes the
   palettes to VRAM 1 and 13 blank tiles ($7e) to VRAM 0 at the pointer,
   then sets $81; the next writes the text up to its $7f (the pointer's low
   byte wrapping, `inc e`) and clears bit 7. Request $82 applies the
   temporary palettes and turns the window on from BG map 1.
6. **The music box.** `Func_160190` moves it and its key right a pixel a
   loop to x $38, then on even loops to $50. Stopped, on even loops each
   end of its animation counts in `wCreditsMusicBoxVar`: at 3 it plays
   `Frameset_161cee` with the key turning every 4 loops, at 4 the
   close-up starts (16 loops of `Func_16026c`: `Frameset_161ceb` at 6,
   then `Frameset_15e7ed` with `OAM_15e44a` in bank $57, `Pals_16054c`
   and `Pals_16058c`, and request $82). `Func_1602ee` loads `Pals_1605cc`
   and `Pals_16060c`; `Func_160318` steps `SlowFadeInScreen` every 16
   loops (33 calls) while the key rises to y $80.
7. **The wait.** `Func_160365` animates on; only after a perfect game
   (`$f2`) a button or `wTimer`'s 180 loops go to `ST_PERFECT`
   (`SetPerfectState`). Otherwise it waits forever, as on the movie.
8. **Shared RAM.** `wCreditsBGMapPtr` is `wBGPtr`, and the text buffer,
   its palettes, and its pointers are a `UNION` with the level's BG tile
   and address queues ($ce01-$ce6d). On the movie the credits' first loop
   holds `wBGPtr` $9923, $7f tiles and $0b attributes in the queues, and
   the addresses $9923 and $9943; besides the level's code only the save
   and clear screens write there (the queue's first 6 bytes).

## Results

| Check | Compared | Differences |
| --- | --- | --- |
| The credits, step (`map-temple-credits-invented`) | 12,766 loops (of 12,767; the last has no next to compare) | 0 |
| Their drawing | 398 VRAM snapshots, 331 screens | 0 |
| From power-on, run | 142 title, 13,559 map, 605 save screen, and 12,767 credits loops, 2,545 whole level frames, to the trace's end | 0; 105 bytes of the level's not-kept RAM seeded at the credits' first loop |

## Interpretation

- The end of a game that is not perfect is ported: a run plays from
  power-on through the hidden figure's fight, the epilogue, its save
  screen, and the credits to the music box's wait, natively and equal to
  the original.
- The level's BG queues and `wBGPtr` are presentation the level's port
  keeps otherwise; a run seeds them from the trace at the first screen
  that traces them (the credits), as it does the level's palettes.

## Hypotheses

- None open for the paths the movies reach. After a perfect game the
  Perfect screen follows after 180 loops or a button:
  `map-temple-perfect-game-invented` takes the 180 loops into it (its
  6,900 credits loops match) ([the Perfect screen](perfect.md)).

## Unknowns

- A button during a perfect game's wait (only unit-tested). `DebugReset`
  (`Init`) from the credits is ported, but the credits' own code never
  takes `wSubState` past 8.
- The music is not ported.

## Tests

- `tests/test_credits.py`: the extractor on a synthetic ROM, its places
  and the port's constants against the reference build's symbols.
- `game/tests/unit/test_credits.gd`: `InitCredits`, `ShowCredits`' wait,
  scroll, and a line's two V-Blanks, the music box's moves and plays, the
  close-up and its window, the fade in, the wait and the Perfect screen,
  `LevelSim`'s routing and `DebugReset`, and `CreditsVram`.
- `make wario-parity MOVIE=local/recordings/map-temple-credits-invented.recording.json`,
  step and `MODE=run`.

## Next experiment

A window check of the credits from power-on (the window's per-loop input
across a level first).
