---
type: research
status: active
updated: 2026-10-18
tags: [research, validation]
---
# The prologue

**Question:** what does the map's prologue do, game loop by game loop, from
New Game's language selection to the map side, and can the port play a new
game from power-on into the first level equal to the original? Task:
WL3-056.

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys @ `560fce6` (`src/engine/overworld/cutscene/prologue/`,
`bank2b_1.asm`, `bank2b_2.asm`, `bank21.asm` `_PrologueFade`,
`src/home/overworld.asm`, `src/macros/gfx.asm`, `src/charmaps.asm`); the
oracle trace of `new-game-ootw`, a power-on movie with no save from the
tracked route `ootw-day1-start` (A every second; Left and A on the map)
and 1,600 ticks walking and jumping in Out of the Woods.

## Verified observations

1. **Where.** New Game's language selection goes to the map with
   `wTransitionParam` `$ff`. The map's `InitOverworld` starts the event
   cutscene `EVENT_PROLOGUE` (sub-states `$11` to `$15`): `InitCutscene`
   calls `InitPrologue` (`_InitPrologue`), and each `UpdateCutscene` loop
   runs `PrologueFunc` (`Prologue`). Then the map's scene, the save screen,
   and the map side follow, all ported before.
2. **The set-up.** `_InitPrologue` clears the scene RAM and objects, sets
   `VBlank_PrologueEpilogue`, loads the prologue's maps on BG map 1 and its
   tiles (`PrologueBackgroundGfx` to v0Tiles2; `FontGfx`, then
   `PrologueGfx` over its start, to v1Tiles0), the music box's maps on BG
   map 0 and tiles, decompresses the hidden figure's text by `wLanguage`
   into `wTextBuffer`, clears the temporary palettes, and places scene
   Wario at (96, 96).
3. **The steps.** `Prologue` plays 39 steps by `w2d013`, counted in
   `w2d014`; most have steps of their own by `w2d890`, counted in
   `w2d891`. Wario falls from his plane by the forest (the plane's four
   parts fall too, `Func_ae8bb`, each by `ApplyOWMovement` tables in bank
   `$2b`), walks to the cave, finds the music box, and is drawn into it;
   he wakes in the temple, and the hidden figure's text plays. On the
   movie the prologue takes 6,452 loops.
4. **Palettes.** `PrologueFade` sets a fade up by `w2d880` (black, the
   forest, the temple, the cave), keeps the colours shown in `wTempBGPals`
   and `wTempOBPals`, and steps both sets 32 times toward `wTempPals1` and
   2 through `wPalConfig1` and 2 (`Func_851bc`, `Func_851d1`, ported for
   the map), which `VBlank_PrologueEpilogue` applies.
5. **The text.** `InitTextPrinting`, `PrintTextWithHeader` and
   `PrintTextWithoutHeader` put one character at a time in
   `wPendingCharTile` (palette 1 from VRAM bank 1) with its BG map 0
   address, every 4 loops (2 with A or down held), skipping `'@'`; the
   V-Blank writes it and clears the address's low byte. A page is three
   lines of `wTextBuffer` (`$40` bytes; its address is the page's nibbles
   swapped, times 4), A turns it, and a page starting with `'▼'` ends the
   text. The temple charmap's `'@'` is `$7f`, space `$7e`, `'▼'` `$5d`.
6. **Data.** The prologue reads ROM banks `$01`, `$21`, `$2a`, `$2b`,
   `$2c`, `$35` (scene Wario's nod's OAM), `$57`, and `$7c`; `overworld.json`
   now keeps `$09`, `$35`, `$36`, and `$7c` too (scene Wario's other
   groups and `_PrologueFade`'s unused fades included).
7. **Ported and checked.** `OverworldPrologue`
   (`game/scripts/sim/screens/overworld/overworld_prologue.gd`) translates
   all of it; the plane's four parts are a table of six kinds of action.
   Its first run against the trace had no RAM difference once the missing
   banks were added. Results below.
8. **Two traced loops in one tick.** Now and then two game loops run in
   one emulator tick. The parity run ordered such loops by their index in
   each screen's own list, which put the map's first loop before the
   language selection's last; it now orders them by `wGlobalCounter`. The
   drawing check compared the later loop of such a pair with the tick's
   screen, which shows the earlier one; it now skips that loop.

## Results

| Check | Compared | Differences |
| --- | --- | --- |
| The map, step (`new-game-ootw`) | 6,970 of 6,972 loops (6,452 of the prologue), 2 ways out | 0 |
| Its drawing | 217 VRAM snapshots, 200 screens | 0 |
| From power-on with no save, run | 1,982 title, 82 language selection, 6,972 map, and 136 save screen loops, 67 loops into Out of the Woods, 1,660 whole level frames | 0, nothing seeded |
| The window (`--save=none`, the movie's joypad by loop) | after 2,300, 2,700, 3,200, 3,800, 4,400, 5,200, 6,200, and 7,500 loops: the plane's fall, the forest, the cave, the music box, the temple's text | 0 pixels each |

## Interpretation

- A new game is ported from power-on to the first level: the title, the
  language selection, the prologue, the map, and the level run natively,
  equal to the original at every compared loop.

## Unknowns

- The epilogue shares `VBlank_PrologueEpilogue`, `PrologueFade`, and the
  text printer, but is not ported.
- The music and sound effects are not ported.

## Tests

- `game/tests/unit/test_prologue.gd`: the cutscene's dispatch, the text
  printer and its pages, a plane part's fall, and `PrologueFade`, on
  invented banks.
- `make wario-parity MOVIE=local/recordings/new-game-ootw.recording.json`,
  step and `MODE=run`.
- `make run SAVE=none` plays a new game in the window.

## Next experiment

The epilogue, when a movie reaches it.
