---
type: adr
status: accepted
updated: 2026-10-12
tags: [architecture, decision, validation]
---
# ADR-0004: One RAM for the level and the screens

- **Status:** accepted (2026-10-12; the owner delegated the direction of
  the work to the agent that session)
- **Supersedes:** none
- **Related:** [ADR-0003](adr-0003-wario-port-by-translation.md), WL3-052,
  [native play across screens](../02-research/native-play.md)

## Context

The level's port (`WarioRam`, `LevelSim`) keeps the game's variables as
named fields. The screens ported since (the clear screen, Action Help,
the map, and its save screen) keep their RAM byte for byte (`MenuScreenSim`),
because their traces and parity checks compare whole ranges. In the
original both are one RAM. The progress the map reads (`wLevel`,
`wNumCoins`, `wPowerUpLevel`, and the rest of WRAM0 `$ca00-$cac0`) is what
the level wrote, and the level the map enters is the `wLevel` the map
wrote. The step checks load both copies from the trace before every loop,
so the two never had to agree. Native play across a screen boundary did
not exist: no run had gone from a level into the map or back.

## Options

1. **Make the level byte-backed**: every `WarioRam` variable a property on
   a shared WRAM array. One copy, but it touches every one of the level's
   hot paths (the level runs about 12 million compared updates in a
   sweep), and it changes code the sweeps have validated.
2. **Keep both, and sync them at the boundary**: the level's variables
   that live in the shared RAM (`SharedWram`, generated from the oracle's
   layout) are written to the screens' RAM before a screen loop when they
   changed, and read back after it when the screen changed the byte. The
   screens' own WRAM0 variables become views of their bytes, and the
   virtual OAM is handed from screen to screen.
3. **Keep them separate**: native play stops at the first screen.

## Decision

Option 2, on in native play (`LevelRunner.start`) and in the parity
script's run mode, off in the step checks, which still load each loop from
the trace. Level bytes the port keeps only in that RAM (`wTempLevelRoomID`,
`wUnused_ca6c`) are written there directly. The level's RAM that the port
does not keep at all (its palettes in `wTempPals1`/`wTempPals2`, and
`wTempBank`) is named in the check (`LEVEL_RAM_NOT_KEPT`) and taken from
the trace at the first screen loop after a level.

## Tradeoffs

- A shared variable has two homes. The rule that reconciles them (only
  changes cross, in both directions) is exact only if a screen loop never
  changes both copies of one variable; a conflict would keep the
  LevelSim's. None has been seen in the 17 movies.
- The step checks no longer exercise the sync: the run mode does, from the
  map through the level and its screens, and stops at the first
  difference.
- A run that does not start at power-on must take what earlier screens
  left in RAM from the trace. The check seeds only bytes the run has
  never written, and records each seed (screen, frame, count), so a
  native write is always compared and never replaced.

## Revisit when

- A screen needs a level variable mid-loop that the sync has not carried
  (the loop's first read would differ in the run, not in the step check).
- Profiling shows the sync's 140 comparisons a screen loop matter.
- The level's palettes or banks are ported, and `LEVEL_RAM_NOT_KEPT`
  shrinks to nothing.
