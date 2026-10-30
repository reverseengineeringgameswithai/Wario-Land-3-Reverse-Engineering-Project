---
type: session
status: done
updated: 2026-10-01
tags: [session]
---
# 2026-10-01: Room graphics decoded and matched to the screen (WL3-018); M2 exit criteria met

## Outcomes

- `tools/wl3pc/extract/room_gfx.py` decodes a room's block tiles,
  attributes, main and special tiles, and palettes (`make extract` does level
  0's four rooms), with block and tile sheets in PNG
  ([room graphics](../02-research/room-graphics.md)).
- `ROOM_001`'s tiles equal the reference build's `.2bpp` intermediates and
  its palettes equal the palette source.
- `make screen-check` composes the background from the level map in SRAM and
  the decoded blocks at the scroll each scanline was drawn with, leaving out
  sprites of this frame and the one before: 300,216 of 300,216 pixels over
  14 frames of the owner's movie and 88,976 of 88,976 on the walk match.
  The first attempts differed only because the scroll registers and OAM read
  after a frame can already belong to the next one.
- The window draws the block sheets at the scroll the original shows; its own
  screenshots after 20, 24, and 100 walk ticks equal the oracle's screen on
  every compared pixel (label, Wario's box, and sprites left out).
- M2's exit criteria are met; the roadmap moves to M3, with breakables and
  transitions carried over.

## Tests

Observed passing on the host: `make test` (188 Python passed; Godot import
OK, 42 passed), `make test-rom` (25 passed), `make screen-check` on both
movies, `make wario-parity`, `make smoke-level`, and `make export-linux`.
`make docs-check` and `make repo-check` passed before the commit.

## Blockers and gaps

- Animated tiles (VRAM bank 1, 112–119) and palette cycles are not ported
  (WL3-037); no compared frame showed them.
- Wario is drawn as a box (WL3-038); objects are absent (WL3-035).

## Next action

WL3-034: port attacking, the most frequent unported state in the movie.
