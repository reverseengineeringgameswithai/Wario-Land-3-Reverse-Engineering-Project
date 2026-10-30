---
type: architecture
status: active
updated: 2026-10-12
tags: [architecture, content]
---
# Architecture overview

The strategy is decided in
[ADR-0001](adr-0001-native-port-strategy.md), and labelled approximations in
[ADR-0002](adr-0002-labelled-approximations.md). This note describes what exists
now and the rules new code follows.

## Data flow

```text
Original_ROM (read-only) ──► tools/wl3pc (identify, bounded decoders) ──► local/content/<pack>/  (immutable base, ROM-derived, ignored)
                                                                              │
game/assets/content/synthetic (tracked, ROM-free) ───────────────────────────┤
                                                                              ▼
mods/<id>/mod.json (data-only overrides) ─────────────────────────► ContentLoader ─► ContentPack (effective copy)
                                                                                         │
                                                       input (keyboard/controller/trace) ▼
                                                                                   PlayerSim.step  (fixed ticks)
                                                                                         │ PlayerState snapshot
                                                                                         ▼
                                                                                   RoomView (draw only)
```

## Layers in `game/scripts/`

| Layer | Files | Rule |
| --- | --- | --- |
| Simulation | `sim/player_sim.gd`, `player_state.gd`, `collision_grid.gd`, `movement_params.gd`, `input_bits.gd`, `input_trace.gd`, `sim_clock.gd`, `sim_runner.gd` | Pure integer state transitions; no nodes, no rendering, no wall-clock time. `step(state, held, grid, params)` is the only mutation. |
| Content | `content/content_loader.gd`, `content_pack.gd`, `room_data.gd` | Loads JSON through `FileAccess` from `res://` or absolute filesystem paths; validates everything; applies mods to a copy. |
| Presentation | `present/room_view.gd`, `main.gd`, `input_setup.gd` | Reads state and draws; samples input once per tick. |

Native C++ extensions are deferred until a measured need or a correctness
boundary justifies them.

## The ported game

The table above is the synthetic prototype's. The ported game
([ADR-0003](adr-0003-wario-port-by-translation.md)) lives beside it:

| Part | Files | Rule |
| --- | --- | --- |
| Level | `sim/wario/` (`WarioRam`, `WarioSim`, `LevelSim`, `LevelRunner`), `sim/objects/` | The level's routines translated under their disassembly names; its variables as fields. |
| Screens | `sim/screens/` (clear screen, Action Help, the map, the pause menu's save), `sim/golf/` | Each screen's state table translated; its RAM byte for byte. |
| One RAM | `sim/wario/shared_wram.gd`, `LevelSim.screen_wram_in`/`_out` | The level's variables and the screens' bytes kept in step at each screen loop ([ADR-0004](adr-0004-one-ram-across-screens.md)). |
| Drawing | `present/` (`LevelView`, `CgbScreen`, each screen's VRAM model) | Reads the simulation's state and records; never changes it. |
| Checks | `tests/parity/wario_parity.gd`, `tools/wl3pc/godot.py`, `tools/wl3pc/sweep.py` | Step mode loads each traced loop and compares the next; run mode plays natively from the input and compares as it goes. |

## Units, coordinates, timing

- Engine coordinates: x right, y down, origin at the room's top-left; tiles are
  16×16 px. Room IDs and material names are stable strings, never ROM
  pointers.
- Positions and velocities are integers in subpixels
  (`subpixels_per_pixel` comes from content; the synthetic pack uses 16, a
  **provisional** value). Whether the original uses whole-pixel table
  steps or subpixel bytes is WL3-012.
- Simulation ticks run at the Game Boy LCD frame rate (70224 cycles at
  4.194304 MHz, ≈59.7275 Hz). `SimClock` accumulates real time and runs at
  most 4 ticks per rendered frame. The test
  `test_clock_runs_at_lcd_rate_not_60hz` pins this. An emulator oracle
  capture shows one gameplay update per frame during normal play
  ([emulator oracle](../02-research/emulator-oracle.md)); heavier scenes are
  not yet measured.
- The emulator oracle (`tools/wl3pc/oracle.py`, PyBoy) is development
  tooling only ([ADR-0001](adr-0001-native-port-strategy.md)). It receives
  the ROM as bytes, so it never writes next to the original, and its
  captures and recordings stay in `local/`.
- Out-of-room tiles are solid (provisional). A spawned body is airborne until
  its first tick resolves floor contact.

## Content formats

Schemas live in `schemas/`; Python (`tools/wl3pc/content.py`) and GDScript
(`ContentLoader`) enforce the same rules, kept aligned by the shared
fixtures in `tests/fixtures/content/`.

- `content-pack.v1`: manifest with `origin` of `synthetic` or
  `original-extracted`, a license string, a movement file, room files, and a start.
- `content-pack.v2`: version 1 plus a required `approximations` list
  ([ADR-0002](adr-0002-labelled-approximations.md)). Each entry names a
  subject (`start`, `movement`, or `room/<id>/legend/<char>`), what it
  `behaves_as`, the `original` behaviour, and optionally a task. The runtime
  prints them and lists them in the selftest output. The extracted first
  room (`make room-pack`) is a version 2 pack in `local/content/packs/`.
- `room.v1`: a `legend` mapping one character to a material (`empty`, `solid`,
  `platform`) plus text `rows`. This is easy to diff and to edit by hand.
- `movement.v1`: integer parameters with a mandatory `provisional` flag and
  `source` text.
- `input-trace.v1`: held buttons per tick.
- `block-function-tables.v1`, `room-records.v1`, `level-headers.v1`,
  `level-block-maps.v2` (block and object maps), and `block-materials.v1`:
  extracted original data (local only).
- `block-handler-materials.v1`: the tracked, project-original mapping from
  original handler IDs to runtime material names and flags
  (`tools/wl3pc/data/`). Handlers without a row become `unknown`, and the
  runtime refuses any material it does not implement.

Missing or unknown fields are errors; nothing silently becomes zero.

## Mods (data-only)

- A mod is `<mods_dir>/<name>/mod.json` (`mod.v1`). It may override the six
  overridable movement integers and patch room rows. No scripts, scenes,
  or resources are loaded from mods.
- **Order:** ascending mod `id`; later mods win. Duplicate IDs are an error.
- **Limits:** 64 mods, 256 KiB per mod file, 1 MiB per content file, rooms up to
  4096×4096 tiles, 1024 patches per mod. These are engine limits, not
  hardware budgets, and can be raised.
- **Containment:** pack paths must be relative, use `[A-Za-z0-9_./-]`, end in
  `.json`, contain no `..`, and resolve inside the pack; filesystem symlinks
  are refused.
- **Atomicity:** a mod is fully validated before any change, so a rejected mod
  leaves the pack untouched.
- **Locations:** `--mods-dir=/abs/path` on the command line, else
  `user://mods` (`~/.local/share/wl3pc/mods`) if it exists.

## Runtime options

`wl3pc.x86_64 [--headless] -- [--content-dir=/abs] [--mods-dir=/abs]
[--selftest] [--trace=/abs]`. `--selftest` prints `WL3PC_SELFTEST {json}` with
the content hash and the per-tick state-stream hash, then exits.

## Rendering

Compatibility renderer; 160×144 viewport, integer scaling (window starts at
640×576), nearest filtering, 2D transforms snapped to pixels. Wider views,
smooth cameras, and high refresh rates are separate future enhancements.
