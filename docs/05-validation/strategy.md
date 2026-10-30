---
type: validation
status: active
updated: 2026-10-01
tags: [validation]
---
# Validation strategy

What counts as evidence, in layers from cheapest to strongest. Status per
subsystem is tracked in the [parity matrix](parity-matrix.md).

## Layers

| Layer | Runs where | Needs ROM? | Implemented |
| --- | --- | --- | --- |
| Python unit tests on synthetic fixtures (header parsing, address rules, decoders, repo and docs checks, content rules, oracle and TAS editor logic) | `make test-python` | No | Yes (200 tests) |
| Real-ROM integration tests (identity, decoded counts, symbol cross-checks; ROM hash re-checked afterwards) | `make test-rom` | Yes, local | Yes (28 tests, 8 of them through PyBoy; skips are labelled) |
| Reference build comparison | `make refbuild` | Yes, local | Yes: byte-identical |
| Godot headless unit tests (simulation rules, the ported Wario on invented tables, the level runner and camera, loader, mods, approximations, trace regression) | `make test-godot` | No | Yes (81 tests) |
| Headless smoke run of the main scene against the recorded snapshot | `make smoke` | No | Yes |
| Headless run of the extracted first room through `--content-dir`, checking its origin and labelled approximations (not a parity check) | `make smoke-extracted`, and inside `make export-linux` | Yes, via `make room-pack` (labelled SKIPPED without it) | Yes |
| Headless run of the ported Wario and camera from extracted level 0's start under the walk input, compared frame by frame with the oracle Wario trace when present | `make smoke-level`, and inside `make export-linux` | Yes, via `make extract` (labelled SKIPPED without it) | Yes |
| Background pixels on the original's screen against the decoded room graphics at chosen frames (sprites of the frame and the one before left out) | `make screen-check MOVIE=… TICKS=…` | Yes, plus PyBoy and `make extract` | Yes: 389,192 of 389,192 pixels over the owner's movie and the walk |
| Wario's and the objects' sprites on the original's screen: OAM entries at every V-Blank transfer, tiles in VRAM, and Wario's pixels every frame (hardware sprite rules, BG priority, palette per scanline) against the decoded sprites | `make sprite-check MOVIE=…` | Yes, plus PyBoy and `make extract` | Yes: the owner's movie (1,514,112 of 1,514,112 of Wario's pixels; 10,547 of 10,547 drawn objects) and the walk |
| The game window's own screenshots against the original's screen after the same ticks of the walk, objects included (only particles left out) | `make window-check` (opens the window briefly per tick) | Yes, plus PyBoy, Godot, and `make extract` | Yes: every compared pixel at 5 ticks |
| Export check: ELF architecture, pack contents, launch outside the checkout | `make export-linux` | No | Yes |
| Clean-checkout run proving no dependence on ignored files | `make verify-clean` | No | Yes |
| Emulator oracle traces (per-frame WRAM for an input trace, reproducible bit for bit) | `make oracle-check`, `make oracle-verify` | Yes, plus PyBoy 2.7.0 | Yes: route and walk capture |
| Native parity: every Wario update and every camera run of a movie, recorded through hooks, rerun natively and compared (49 and 15 variables), plus the level start, room transitions, every `UpdateObjects` (each fully ported slot byte for byte), every `ProcessInteractions`, and spawning (room starts and each frame's streamed edges); or whole frames run alone on a movie's input | `make wario-trace MOVIE=…`, then `make wario-parity MOVIE=… [MODE=run]` | Yes, plus PyBoy 2.7.0 and `make extract` | Yes: the owner's movie (3309 updates, 5802 camera runs, 5 room transitions, 6238 object slot updates, and 5786 interaction runs, none differ; 937 whole frames alone with objects and interactions, through the first room and room 21 to the electric transformation) and the walk capture alone (300 whole frames) |
| Desktop session checks (keyboard, controller, resize, audio) | Fedora GUI | No | **No** (WL3-021) |

The synthetic trace snapshot (`game/tests/golden/walk-jump.synthetic.json`)
detects unintended change. It is **not** parity evidence.

## States used in the parity matrix

- **unknown:** no evidence gathered.
- **investigated:** the original's code and data are located and partly
  read; the claims are in a research note.
- **implemented:** native code exists and has tests of its own rules, but is
  not yet compared with the original.
- **validated:** native behaviour matches original evidence under stated
  acceptance criteria, e.g. a decoder whose output lands on every
  disassembly label, or native state matching an oracle trace frame for
  frame for a stated input set.

A screenshot that looks right does not validate movement, collision, or
progression.

## Oracle traces

Implemented in WL3-014 ([emulator oracle](../02-research/emulator-oracle.md)).
Each capture records the emulator name, version, and settings, the ROM
SHA-256, the start (power-on, or a tracked route identified by its file
SHA-256), the `input-trace.v1` input, the WRAM variables sampled with their
addresses, the samples per tick, and a SHA-256 of all RAM and the CPU
registers after every tick. The game has no RNG seed outside RAM, so the RAM
digest covers it. Routes are tracked in `tools/wl3pc/data/oracle/` and hold
no ROM bytes; captures and recordings stay in `local/`. The emulator is a
development oracle only, never part of the shipped runtime.

## Skips and failures

Skipped tests print `SKIPPED (reason)` and are counted separately from
passes. Godot steps fail on script-error output even when the exit code is
0. A runtime error inside a Godot test does not fail the runner by itself;
the make targets catch it from the output.
