---
type: project
status: active
updated: 2026-10-03
tags: [project]
---
# Roadmap

This note owns the milestones. Individual tasks live in [tasks](tasks.md); the
latest handoff lives in [current state](current-state.md).

## M0: Safe foundation (complete, 2026-10-01)

Exit criteria, all met: inputs preserved and hashed; Git repository with
verified ignore rules and a safety checker; vault; pinned references and
toolchain; tested read-only ROM inspector; a clearly labelled synthetic native
scene with headless tests and a Linux export.

## M1: First verified extraction (criteria met, 2026-10-01)

Exit criteria: one identified original data structure, documented provenance,
a bounded decoder, synthetic tests, and a locally validated result; plus a
reference ROM build where feasible, with its status recorded separately.

Met for the **block function tables**
([first investigation](../02-research/first-investigation.md)). The ElectroDeoxys
disassembly reference build is byte-identical to the ROM
([ROM identity](../02-research/rom-identity.md)). This does not establish
what each of the 138 handlers does; that work is WL3-011.

## M2: First real room (exit criteria met, 2026-10-01)

Exit criteria:
- Original room graphics and collision for one room (Out of the Woods, day 1,
  first room), extracted into ignored local content.
- Source-grounded walking, jumping, and camera behaviour for the subset that
  room needs.
- Reproducible comparison traces against an emulator oracle, with metadata.
- A native Linux export that loads the local extracted pack.
- Every approximation labelled in the [parity matrix](../05-validation/parity-matrix.md).

Main tasks: WL3-010 to WL3-015, WL3-018, WL3-024 to WL3-027, WL3-033, WL3-036.

Progress (2026-10-01): the first room's collision layout and spawn are
extracted from the original data, and the runtime and the Linux export load
the local pack (WL3-010, WL3-011, WL3-013, WL3-024, WL3-025). The emulator
oracle produces reproducible captures from a defined start (WL3-014), and
cadence is confirmed (WL3-015). Wario's walking, turning, jumping, and
landing are ported and match every compared oracle update (WL3-012), the
window and the export play level 0 with them (WL3-033), the level camera is
ported and matches every oracle camera run (WL3-036), and the room graphics
are decoded and match the original's screen pixel for pixel (WL3-018).

Exit criteria met on 2026-10-01: original graphics and collision for the
room (and the whole of level 0's layout), source-grounded walking, jumping,
and camera, reproducible oracle traces with metadata, an export that loads
the local data, and every gap in the [parity matrix](../05-validation/parity-matrix.md).
Breakables and transitions (WL3-026, WL3-027) were not exit criteria and
continue in M3, with Wario's other states (WL3-034), animated tiles
(WL3-037), and sprites (WL3-038).

## M3: Expand systems (active)

Player abilities and transformations, objects and enemies, transitions, and
animation, one subsystem at a time, each with evidence and tests.

Main tasks: WL3-034 (Wario's states), WL3-026 (breakables), WL3-027 (room
transitions and doors), WL3-035 (objects), WL3-037 (animated tiles and
palettes), WL3-038 (sprites).

Progress (2026-10-02): the owner's whole Out of the Woods movie runs
natively from its input and equals the original at every checkpoint of
every level frame: all of Wario's states it meets (transformations and the
treasure scene included), its objects and interactions, room transitions,
particles, and the room animation (WL3-034, WL3-040, WL3-027, WL3-037),
with randomness (`rDIV`) and late-frame timing replayed from the oracle.
Wario, objects, particles, and backgrounds are drawn from the original
graphics, pixel for pixel where checked (WL3-038, WL3-039, WL3-042).
Starts at any level (`make level-movie`) now extend parity checks to the
other levels; what they meet unported is the next work: water, enemy
bumping, sand, Fat Wario, the ground shake, being picked up, Ice Skatin',
hanging from a rail, Para-Goom, Brrr Bear, and the zip lines are ported
from that list: every one of the sweep's 29,826 Wario updates is now
compared, and
every compared update of all 25 levels' scripted movies matches
(WL3-041, WL3-044, WL3-045). Three more scripts (attacks, crouching,
wandering) brought in Flat, Zombie, Blind, and Bouncy Wario, slipping,
and the multi-block breakables: all four sweeps match every update and
run whole frames to the end. Their movies start with no power-ups;
two more scripts with every power-up followed (WL3-046), then night 1 and
the 85 later variants with their own level data (WL3-047): 810 movies,
every Wario, object, and interaction update identical and every movie
running to the end. Starts in every day-1 room followed (3,258 movies in
24 sweeps), and with them the bosses, the Shoot minigame, and the
variable cart: every update identical, nothing unported, every movie to
the end (2026-10-03). The battles past their starts have not met the
oracle yet (WL3-048).

## M4: Complete-game integration

World and progression rules, day/night versions, keys and treasures,
bosses, menus, localisation, audio, and versioned saves, with regression
coverage. Track every remaining gap; room count alone does not imply
completion.

## M5: Parity and extension release

Systematic validation against the original, a documented editable content
pipeline, regression-protected enhancements, and a reproducible Linux release
process. "Complete" must be defined in writing before the word is used.
