---
type: adr
status: accepted
updated: 2026-10-01
tags: [architecture, decision, movement, collision]
---
# ADR-0003: Port Wario's movement by translation, checked update by update

- **Status:** accepted (2026-10-01)
- **Supersedes:** none
- **Related:** [ADR-0001](adr-0001-native-port-strategy.md), [ADR-0002](adr-0002-labelled-approximations.md), WL3-012

## Context

The prototype `PlayerSim` uses acceleration, gravity, and tile materials
with provisional constants. Wario Land 3 moves by table steps chosen by
state and index, and its collision is per probe: each check reads one
point, and the block's handler decides what that point means for that
probe kind ([wario movement](../02-research/wario-movement.md)). A
material model cannot reproduce slopes, one-way floors, or breakables
exactly, and tuning constants until a capture looks right would not be
evidence. The oracle can record every Wario update exactly.

## Options

1. **Tune the prototype** (materials and physics constants) to captures.
   Approximate by construction; every new case needs new tuning.
2. **Translate the routines** (`UpdateWarioStates` and what it calls, the
   collision checks, the block handlers) into GDScript, keeping the
   original variable names and handler IDs, with game data loaded from
   extracted content; check each update against the oracle.
3. **Recompile the routines** mechanically. Rejected for the runtime by
   ADR-0001.

## Decision

Option 2. `WarioRam` holds the variables under their disassembly names;
`WarioBlocks` ports the probes and handlers (keyed by handler ID such as
`h06_4032`); `WarioSim` ports the states. Arithmetic is masked to the
CPU's byte and word widths. Any path into a routine that is not ported is
recorded by name, never guessed. Tables and framesets are extracted from
the user's ROM; the code holds logic and code constants, each next to the
routine it ports. `make wario-parity` compares one update at a time with
the oracle's hooked updates and must show no differences.

## Tradeoffs

- The code reads like the original, not like idiomatic GDScript (names
  such as `wJumpVelIndex`, byte masks). That is deliberate: it can be
  checked line by line and against traces. A cleaner API for mods can sit
  on top once behaviour is pinned.
- `PlayerSim` and material packs stay for the synthetic testbed and
  editing until the runtime runs `WarioSim` on extracted levels (WL3-033).

## Revisit when

- A routine depends on hardware timing (rDIV, LY) that the port cannot
  model deterministically; record the input it needs instead.
- Mods need movement that the original variables cannot express.
