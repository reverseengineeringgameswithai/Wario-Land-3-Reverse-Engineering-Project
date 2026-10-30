---
type: research
status: active
updated: 2026-10-02
tags: [research, rom, content, validation]
---
# Wario's sprites

**Question:** what does Wario look like in each frame, and does the port draw him as the original
does?

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys @ `560fce6` (`src/home/load_wario_gfx.asm`, `src/home/sprite.asm`,
`src/home/level_vblank.asm`, `src/home/bg_ob_pals.asm` `SetWarioPal`,
`src/engine/level/start_room.asm`, `src/engine/level/update_level.asm`,
`src/gfx/oam/wario1.asm`, `src/gfx/pals/wario.asm`, `src/macros/gfx.asm`) and
its byte-identical reference build; oracle runs of the owner's movie and the
walk capture. Task: WL3-038.

## Verified observations

1. **Tiles.** Each state names a tile set in `wDMASourceBank:wDMASourcePtr` and
   calls `LoadWarioGfx`, which queues 128 tiles (`$800` bytes) for VRAM bank 0
   at `$8000`; `LevelVBlankFunc` performs the transfer before it writes the
   scroll and transfers OAM. The sets the ported states use are
   `WarioIdleGfx` (`04:4000`), `WarioWalkGfx` (`04:4800`), `WarioAttackGfx`
   (`04:5800`), `WarioLadderGfx` (`04:6800`), `WarioAirborneGfx` (`04:7800`),
   and `WarioSlideGfx` (`09:5000`); each equals its `INCBIN` in the reference
   build (`gfx/wario/*.2bpp`, 2048 bytes). Later ports added the dizzy,
   electric, string, hot, burnt, clear, swim, fat, bubble, and hang sets
   (`WarioFatGfx`, `09:6000`, with `OAM_1742d`; `WarioBubbleGfx`, `0b:6800`,
   with `OAM_1fdb6d`), each checked against its `INCBIN` the same
   way (`make test-rom`). Flat Wario uses the slide set with its own
   table, `OAM_16e9d` (`05:6e9d`); `make sprite-check` on level a8's
   `right-attack` movie, where an Omodon flattens him, matches all
   350,369 of Wario's pixels over 1199 frames. Zombie Wario: `WarioZombieGfx`
   (`0b:4000`, its `INCBIN` checked as the others), `OAM_1fc48b`, and
   `WarioZombiePal` with the seven palettes after it that the recovery
   steps through; level a0's `wander` movie matches all 487,482 of
   Wario's pixels, the recovery's palettes included. Bouncy Wario:
   `WarioBouncyGfx` (`0b:4800`), `OAM_1fc95e`, `WarioBouncyPal` and
   `WarioBouncyRedPal`; level 20's `wander` movie matches all 590,472 of
   Wario's pixels.
2. **Layouts.** Each state also names an OAM table in
   `wWarioOAMBank:wWarioOAMPtr`. A table is a list of frame pointers followed
   by the frames; a frame is (y, x, tile, attributes) entries ending at `$80`.
   `DrawWario` passes `wWarioFrame` (set by `UpdateWarioAnimation` from the
   frameset) to `LoadSprite`, which adds Wario's screen position and XORs
   `wWarioAttributes` (always 0 in the movie). Sprites are 8x16
   (`LCDC_DEFAULT`), so a tile number names a pair. The seven tables the
   ported states use have 250 frames; ending each table at its lowest frame
   pointer gives exactly the reference build's `.frame_N` label counts.
   Their entries use OBJ palettes 0 and 1 and both flips, never VRAM bank 1
   or the OBJ priority bit.
3. **Palettes.** `StartRoom` and `SetWarioPal` load two palettes from
   `wWarioPalsPtr` into OBJ palettes 0–1: `WarioDefaultPal` (`03:4800`) and,
   while stung, `WarioInvisiblePal` (`03:4810`) every 4 frames
   (`Func_1f6c2`). `SetWarioPal` writes the hardware palettes at once, during
   the frame, not at V-Blank.
4. **Visibility.** `DrawWario` skips Wario while `wInvisibleFrame` is set;
   `HandleInvincibility` toggles it at each counter step (the flicker after
   being hurt) and clears it at the end.
5. **Timing.** In the oracle, `DrawWario` runs part-way down the screen
   (`LY` about 30) and `LevelVBlankFunc` at `LY` 144 of the same emulator
   tick, and only after a whole game loop (`wEnableVBlankFunc`). So the
   screen drawn during tick *t* shows the OAM, Wario tiles, and scroll of the
   loop that ended in tick *t − 1*.
6. **State parity.** The ported states set all of the above as the original
   does: with `wWarioFrame`, `wWarioAttributes`, `wWarioPalsPtr`,
   `wDMASourceBank`/`Ptr`, `wWarioOAMBank`/`Ptr`, and `wInvisibleFrame` added
   to the compared variables, all 3309 compared updates of the owner's movie
   match (`make wario-parity`), as do the level start and the five room
   transitions.
7. **On the original's screen** (`make sprite-check MOVIE=…`,
   `tools/wl3pc/oracle_screen.py`), over the owner's movie:
   - at all 3383 V-Blank transfers where Wario was drawn from a decoded
     table, his OAM entries equal the decoded frame (180 more had him hidden
     by the flicker);
   - after all 3580 transfers whose tile set is decoded, VRAM holds exactly
     that set;
   - 1,514,112 of 1,514,112 of Wario's pixels equal the decoded sprite,
     25,978 of them in the stung palette, and 12,861 correctly hidden
     behind BG tiles with the priority bit. With the transformations' and
     the treasure scene's graphics decoded (WL3-034), every frame he is
     drawn in the level is checked: 2,680,266 of 2,680,266 pixels over
     5613 frames; the 35 frames after the level ends (the clear screen's
     fade, not ported) are left out.

   The check composes the frame by the hardware rules: ten sprites per line,
   the lowest OAM index on top, other sprites' opacity read from VRAM, BG
   priority, and the palette per scanline. The walk capture gives
   129,488 of 129,488.
8. **In the window** (`make window-check`): screenshots after 10, 20, 100,
   200, and 299 ticks of the walk equal the original's screen after the same
   ticks on every compared pixel. That covers the background, Wario, and the
   blocks drawn over him. Left out are only the pixels where another sprite
   is opaque: 2 for a particle at Wario's feet, and 124 at tick 200 for an
   object entering from the right.

## Interpretation

- Wario's look is fully determined by his decoded tile sets, OAM tables,
  and palettes plus five variables the port now tracks exactly. The window
  draws him from what `DrawWario` saw (`LevelSim.drawn_wario`) and lays the
  room's priority pixels over him (`room-NNN-priority.png`).

## Hypotheses

- The other tables in the movie (`OAM_1673c`, `OAM_171c0`, `OAM_1790e`,
  `OAM_16b6c`, `OAM_17bbc`, `OAM_1fc000`, `OAM_1fc31b`) belong to
  transformations and the treasure scene. They will decode the same way when
  those states are ported.

## Unknowns

- Object, particle, and HUD sprites (objects are WL3-035).
- `wWarioAttributes` other than 0 and Wario's palettes during fades.

## Tests

- `tests/test_wario_sprites.py`: table length, terminators, 8x16 pairs, flips,
  the XORed attributes, `DrawWario`'s visibility, and the priority sheet
  (invented data).
- `game/tests/unit/test_wario_sprites.gd`: the window's pair sheets, flips,
  OAM placement, `draw_wario`, the states' graphics names, and the
  invincibility flicker.
- `tests/test_rom_integration.py`: the tile sets, labels, and palettes against
  the reference build; `sprite-check` on the walk capture.
