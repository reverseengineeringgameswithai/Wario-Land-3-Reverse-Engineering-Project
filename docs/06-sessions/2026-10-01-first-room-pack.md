---
type: session
status: done
updated: 2026-10-01
tags: [session]
---
# 2026-10-01: First room as an extracted pack (WL3-013)

## Outcomes

- The owner delegated the format decision. It is
  [ADR-0002](../03-architecture/adr-0002-labelled-approximations.md):
  content-pack v2 with a required `approximations` list, enforced the same
  way by the Python validator and the Godot loader. v1 packs and their
  hashes are unchanged; the synthetic golden snapshot still matches.
- "Recompilation" in the request was read as getting the extracted room into
  the native build. ADR-0001 keeps a source-grounded port, not static
  recompilation, and that was not revisited.
- The object maps are now decoded (`level-block-maps` format 2), and the
  level-start spawn search is reimplemented from `SetWarioPositionToSpawn`,
  `Func_cc0`, and `Func_cf8`. It holds for 3617 of 3641 list entries; the
  exceptions are all in Beneath the Waves and The Colossal Hole.
- WL3-013 is done for collision. `make room-pack` writes
  `local/content/packs/wl3-level-00-room-001`: 32 × 16 blocks, 12 labelled
  approximations, and a spawn that lands exactly on the floor
  ([first room pack](../02-research/first-room-pack.md)). The runtime
  (`make smoke-extracted`) and the exported binary load it. The interactive
  path that `make run CONTENT=…` uses was run headlessly for 30 frames: it
  loaded the pack, drew the room, and printed all 12 approximations without
  script errors. No window was opened.
- New tasks WL3-026 (breakable blocks) and WL3-027 (room transitions and
  doors). They are the tasks the pack's labels point at.
- Mistakes corrected before committing: an unchecked guess that the spawn
  exceptions were in a "Grasslands-to-Swamp range" (they are Beneath the
  Waves and The Colossal Hole), a citation of the object-nibble parity to the
  wrong routine (`GetBlockPtr` instead of `Func_cc0`), and an over-clever
  legend line in the builder.

## Tests

Observed passing on the host: `make test` (136 Python passed, 15 ROM tests
deselected; Godot import OK, 21 passed), `make test-rom` (15 passed),
`make smoke` (golden unchanged), `make content-check`, `make extract` (all
outputs unchanged except the intended `level_block_maps.json` format 2),
`make room-pack`, `make smoke-extracted`, `make export-linux` (pack check
clean; the exported binary loaded the extracted pack outside the checkout),
`make docs-check`, and `make repo-check` before each commit. A headless
script confirmed that Godot rejects each new invalid fixture for the same
reason as Python. A mutation that treats flagged blocks as exact failed the
pack tests and was reverted. The ROM's SHA-256 was `b625ed03…7406` before
and after.

## Blockers and gaps

- No GUI check was made: the window was not opened, so nothing about how
  the room looks on screen is verified (WL3-021).
- The physics, the start box, breakables, transitions, and movement are
  provisional or approximated, each labelled in the pack.
- What `UpdateFloor` does after the spawn is unknown.

## Next action

WL3-012: decode `WalkVelTable` and `JumpVelTable_Normal`, find where the
returned `b` is applied, and replace the pack's labelled movement.
