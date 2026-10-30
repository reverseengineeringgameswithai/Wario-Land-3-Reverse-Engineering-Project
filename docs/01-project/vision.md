---
type: project
status: active
updated: 2026-10-01
tags: [project]
---
# Vision

## Goal

Build a faithful, source-understood PC port of Wario Land 3 for Linux that is
much easier to modify than the Game Boy Color original. Gameplay executes as
host-side game logic in Godot. Original content is extracted reproducibly
from the user's own ROM into documented, editable formats; nothing
copyrighted is tracked or distributed by this repository.

## Terms used precisely

| Term | Meaning here | Is it the goal? |
| --- | --- | --- |
| Reference build | Reassembling the disassembly into a `.gbc` that is byte-identical to the ROM | No. It shows the source tree reproduces the ROM, not that the code is understood. |
| Static recompilation | Mechanically translating SM83 instructions into host code | No. Not chosen ([ADR-0001](../03-architecture/adr-0001-native-port-strategy.md)). |
| Emulator wrapper | Running the original ROM inside an emulator | No. Fails the product goal; an emulator may only serve as a local development oracle. |
| Source-grounded native port | Reimplementing behaviour in Godot, each part traced to ROM or disassembly evidence and covered by a test | **Yes** |
| Remake | New implementation guided by appearance and memory | No. Approximations must be labelled and replaced. |

A Linux export containing GDScript is a native executable plus a script pack. It
is not proof of ahead-of-time compilation of the original game code, and we do
not describe it that way.

## Two tracks

1. **Original-game investigation and reference reproduction.** Identify the
   ROM, pin sources, reproduce the reference build, decode one structure at
   a time with provenance, and record verified facts in research notes.
2. **Native runtime development.** Typed GDScript simulation, content loading,
   and presentation, kept separate. Each migrated behaviour links back to its
   evidence and forward to a test.

## Principles

- Faithful baseline first, enhancements second. Enhancements (wider screens,
  high refresh rates, larger maps, new abilities, replacement assets,
  configurable limits) must not require editing ROM banks or respecting
  hardware budgets, and must not change the baseline unless chosen.
- Evidence over plausibility. A decoded structure needs a consumer in the
  original code and a validated result, not just output that looks right.
- Unknowns stay visible. Provisional constants are labelled, and unknown
  required data fails loudly instead of defaulting to zero.
- Modding is data-first: a base pack that is never modified, plus ordered, validated,
  data-only mods. No untrusted scripts run.

## Non-goals for now

Packaging (RPM/Flatpak), non-Linux exports, online features, and any
distribution of ROM-derived content.
