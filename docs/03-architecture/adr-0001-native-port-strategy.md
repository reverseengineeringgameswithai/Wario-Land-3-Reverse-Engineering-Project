---
type: adr
status: accepted
updated: 2026-10-01
tags: [architecture, decision]
---
# ADR-0001: Native port strategy

- **Status:** accepted (2026-10-01)
- **Supersedes:** none

## Context

The goal is a faithful Wario Land 3 for Linux whose gameplay runs as
host-side logic and which is much easier to modify than the original
([vision](../01-project/vision.md)). Evidence is strong: the ElectroDeoxys
disassembly reassembles to a byte-identical ROM, and about 81% of its global
ROM labels have descriptive names. Godot 4.7.2 (standard build) is available
on the Fedora 44 host, and its official Linux export templates have been verified.

## Options

1. **Source-grounded Godot port.** Reimplement each subsystem in typed
   GDScript from disassembly and ROM evidence, with a test for each migrated
   behaviour; extract content into documented formats.
2. **Static recompilation.** Translate SM83 machine code into C/C++
   mechanically, with a hardware-model runtime (PPU, APU, MBC5, timers).
3. **Emulator wrapper.** Ship an emulator core that runs the user's ROM,
   with enhancements layered on top.

## Decision

Option 1, with a typed-GDScript core separated into simulation, content, and
presentation layers.

## Tradeoffs

| Criterion | 1. Godot port | 2. Static recompilation | 3. Emulator wrapper |
| --- | --- | --- | --- |
| Fidelity | Earned subsystem by subsystem; needs oracle traces and tests | High for CPU logic, but still needs a faithful PPU/APU model | Highest, for free |
| Editability (maps, limits, entities) | High: data formats and engine limits are ours | Low: logic stays shaped by banks and hardware budgets | Very low: ROM hacking |
| Evidence and understanding | Forces understanding; every behaviour is documented | Opaque generated code; understanding optional | None required |
| Maintenance | Normal game code; Godot editor tooling | Large generated corpus and a hardware layer | Small, but owns an emulator |
| Meets the product goal | Yes | Partially: native, but not "easier to modify" | **No**: the original ROM still executes |

Accepted costs of option 1: slower progress, risk of subtle divergence
(mitigated by integer state, tick-indexed traces, a parity matrix, and an
emulator used only as a local oracle), and GDScript performance limits.
Those limits are unlikely to matter at this game's scale but are watched.

## Revisit when

- A subsystem's timing or interactions resist reimplementation despite
  traces. Then consider recompiling *that routine* as a verification oracle,
  not as the runtime.
- Profiling shows GDScript cannot hold the tick rate on target hardware
  (move only the hot path to GDExtension C++).
- Godot introduces non-determinism in the integer simulation path (the
  regression tests compare per-tick state hashes, so this would be detected).
