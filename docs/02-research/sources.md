---
type: research
status: active
updated: 2026-10-01
tags: [research, licensing]
---
# Sources

Which external sources this project relies on, how they compare, and what
each may be used for. Pins are authoritative in `references.lock.json`;
checkouts live in ignored `external/` (`make references`, `python -m
wl3pc.references status`). Licensing consequences are in
[LICENSES.md](../../LICENSES.md).

## Comparison (inspected 2026-10-01)

| | ElectroDeoxys/warioland3 | froggestspirit/wland3 | Nearoo/Wario-Land-3 |
| --- | --- | --- | --- |
| Pinned commit | `560fce6faf50df4a48c0448f00105b6075f8f231` (2026-08-17) | `29f1df63322efc635074c532e335896edf630515` (2020-08-20) | `ecd96f38b4d7e28609588352ef53520ba3fcaede` (2018-10-15) |
| Kind | Full disassembly | Early disassembly | Pygame remake |
| Organisation | 430 `.asm` files under `src/` by subsystem (`engine/level`, `home`, `data/levels`, `gfx`, `audio`); tools for graphics, compression, and text | 3 `.asm` files; 4,999 of 5,311 `INCBIN`s slice `baserom.gbc` | 20 Python files, 2,118 PNGs (ripped sprites), one Tiled map |
| Useful symbols | 8,497 global ROM labels in the built `.sym`; 1,623 still placeholder-named (`Func_`, `Data_`, `Unk…`) | Few | None (not a disassembly) |
| Build | `make compare`; needs RGBDS ≥ 1.0.0 (`src/rgbdscheck.asm`; CI pins v1.0.0); no base ROM | Needs RGBDS v0.4.1 and `baserom.gbc` | Python 2-era Pygame |
| Reproduced here | **Yes**: byte-identical with RGBDS v1.0.0 ([ROM identity](rom-identity.md)) | Not attempted (WL3-017) | Not run |
| Expected hash in README | SHA-1 `bb787730…d7ba` (matches) | MD5 `16bb3fb8…f4ee` (matches); README calls it the "US rom" | n/a |
| GitHub status | Active, not archived | **Archived** | Not archived, inactive since 2018 |
| License | None declared | None declared | MIT for the author's own resources; README excludes all graphics |
| Role here | Primary evidence: symbols, formats, reference build | Secondary comparison | Implementation comparison only; not evidence of original behaviour |

## Use rules

- Cite evidence as *repository @ commit, file, symbol*, plus the banked address
  from the local reference-build `.sym`. Line numbers alone are not enough.
- Do not copy disassembly source, tools, or assets into the repository. Facts
  such as addresses, counts, and table shapes may be recorded with
  citations; see open question 2 in [LICENSES.md](../../LICENSES.md).
- Nearoo's graphics are ripped game art and its license excludes them. Do
  not use them.
- Never reset or clean a modified checkout. `references fetch` refuses to.

## Toolchain sources

- RGBDS v1.0.0 (`gbdev/rgbds` @ `fb9fa603`, MIT), built from source into
  `local/toolchain/rgbds-1.0.0`. Fedora 44 ships rgbds 0.9.0, which the
  disassembly rejects.
- Godot 4.7.2-stable standard build from the official GitHub release,
  checked against `SHA512-SUMS.txt`. See [Fedora setup](../04-development/fedora-setup.md).

## External references consulted

- Pan Docs, cartridge header and MBC5: <https://gbdev.io/pandocs/>
- Godot command line and runtime file loading:
  <https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html>
