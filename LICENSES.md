# Licensing and provenance

This file records what each part of the repository is, where it came from,
and what may be done with it. The project's own work is under the
**[MIT License](LICENSE)**, chosen by the owner on 2026-10-29 (WL3-016):
anyone may use, copy, modify, fork, merge, publish, distribute, sublicense,
and sell it, keeping the copyright and permission notice.

The license covers this project's own work only. It grants no rights in
Wario Land 3 or any other Nintendo property (the game, its code, graphics,
music, names, and trademarks), nor in the third-party sources listed below,
whose own terms apply. No ROM or content extracted from one is included.

## Tracked in this repository

| Component | Origin | Status |
| --- | --- | --- |
| `tools/`, `tests/`, `game/scripts/`, `game/tests/`, `schemas/`, `Makefile` | Written for this project | Project-original; MIT |
| `docs/` | Written for this project | Project-original; MIT |
| `game/assets/content/synthetic/`, `game/assets/traces/`, `tests/fixtures/` | Written for this project; invented values | Project-original synthetic data, no ROM bytes; MIT |
| `mods/examples/` | Written for this project | Project-original example; MIT |
| Layout facts in `tools/wl3pc/extract/` and `tools/wl3pc/known_roms.py` | Addresses, counts, and hashes observed in the user's ROM and read from the ElectroDeoxys disassembly | The code is MIT; the facts are short, cited references, see open question 2 |
| `uv.lock`, lock JSON files | Generated or written for this project | Metadata only |

Not tracked, ever: the ROM, the WL3 Editor, reference checkouts, extracted
content, captures, saves, Godot export templates, and build outputs. See
`.gitignore` and `make repo-check`.

## External sources (local, ignored, pinned in `references.lock.json`)

| Source | Declared license | How it is used here |
| --- | --- | --- |
| ElectroDeoxys/warioland3 @ `560fce6` | None found (no LICENSE file; GitHub reports none) | Read and cited by commit, file, and symbol; built locally in `build/refbuild`. No source or assets copied. |
| froggestspirit/wland3 @ `29f1df6` (archived) | None found | Read for comparison only |
| Nearoo/Wario-Land-3 @ `ecd96f3` | MIT for the author's own resources; README excludes all graphics | Implementation comparison only. No code or graphics copied. Any future code reuse needs MIT attribution and a fresh review. |
| gbdev/rgbds v1.0.0 @ `fb9fa60` | MIT | Toolchain built locally into `local/toolchain` |
| Godot 4.7.2-stable | MIT (engine); export templates are Godot binaries | Downloaded locally, SHA-512 verified, never tracked |
| WL3 Editor (Drenn), user-provided | No license file in the user's copy | Its `ref/` tables are read locally as leads; not copied |
| Wario Land 3 ROM, user-provided | Nintendo copyright | Read-only local input; nothing derived from it is tracked |

## Open questions

1. **Project license.** Resolved 2026-10-29: MIT for project-original code,
   docs, schemas, synthetic data, and example mods ([LICENSE](LICENSE),
   WL3-016).
2. **Facts from an unlicensed disassembly.** The extractor records a few
   addresses, counts, and symbol names learned from reading ElectroDeoxys'
   disassembly, which declares no license. These are kept minimal and cited,
   and symbol names are only attached to local outputs at runtime from a
   locally built `.sym`. Whether this is acceptable for a public release is
   unresolved; the public repository (2026-10-29) includes them as they
   stand. Deferred under WL3-016.
3. **Distribution of ROM-derived content.** Extracted content stays in
   ignored `local/content/`. Future public builds must select synthetic or
   original-authored content explicitly. The export check (`make
   export-linux`) refuses packs containing the ROM-derived marker, ROM images,
   or byte fragments of the local ROM. That check is necessary but not
   sufficient: a re-encoded asset will not match it.
4. **Not clean-room.** Contributors have read the disassembly. Do not describe
   this project as a clean-room implementation.
5. **Translated routines.** `game/scripts/sim/` reimplements the original's
   routines by translating the disassembly
   ([ADR-0003](docs/03-architecture/adr-0003-wario-port-by-translation.md)),
   and the code and notes use the disassembly's symbol names. The MIT
   License covers this project's own expression; it cannot license
   Nintendo's original code, and whether a translation derives from it is
   a legal question this project has not answered.
