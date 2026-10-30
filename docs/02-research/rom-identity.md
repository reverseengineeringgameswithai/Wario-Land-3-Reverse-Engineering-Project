---
type: research
status: active
updated: 2026-10-01
tags: [research, rom]
---
# ROM identity

**Question:** exactly which ROM is the input, and which sources describe
exactly these bytes?

## Verified observations

Input: `Original_ROM/Wario Land 3 (World) (En,Ja).gbc` (read-only; `make rom-info`).

| Property | Value |
| --- | --- |
| Size | 2,097,152 bytes (2 MiB, 128 banks of 16 KiB) |
| SHA-256 (provenance) | `b625ed03e7553cc29ebc4203d919838312fc9f9f85915f5d2eddfe14aec77406` |
| SHA-1 (legacy, comparison only) | `bb7877309834441fd03adb7fa65738e5d5b2d7ba` |
| MD5 (legacy, comparison only) | `16bb3fb83e8cbbf2c4c510b9f50cf4ee` |
| Title / manufacturer | `WARIOLAND3` / `AW8A` |
| CGB flag | `$C0` (CGB only) |
| Cartridge type | `$1B` MBC5+RAM+BATTERY |
| ROM / RAM size codes | `$06` (2 MiB, matches file) / `$03` (32 KiB) |
| Destination | `$01` (overseas) |
| Licensee | new `01`, old `$33`; mask ROM version 0 |
| Boot logo | matches (compared by SHA-256; logo bytes are not stored) |
| Header checksum | stored `$89`, computed `$89`: valid |
| Global checksum | stored `$7633`, computed `$7633`: valid |

Hashes were taken before any work and again at the end of the session; they
were identical both times.

## Upstream comparisons

| Source | Claim | Result |
| --- | --- | --- |
| froggestspirit/wland3 @ `29f1df6`, `README.md`, `rom.md5` | MD5 `16bb3fb8…f4ee` | Match |
| ElectroDeoxys/warioland3 @ `560fce6`, `README.md`, `rom.sha1` | SHA-1 `bb787730…d7ba` | Match |
| ElectroDeoxys reference build (RGBDS v1.0.0, `make compare`) | builds `warioland3.gbc` | **Byte-identical** (`cmp` and SHA-256), 2026-10-01 |

The froggestspirit README calls its base ROM the "US rom", while the
filename here says "(World) (En,Ja)". The bytes are the same, so that is a
naming difference, not a different revision. Neither label establishes region
compatibility; only the hash does.

## Interpretation

- **Header valid:** yes (both checksums and the logo).
- **Revision identified:** yes, `wl3-world-en-ja`, by exact SHA-256 in
  `tools/wl3pc/known_roms.py`.
- **Demonstrated compatibility with ElectroDeoxys @ `560fce6`:** yes, by a
  byte-identical build. Revision-dependent tools rely on this.
- **Address rule:** MBC5 banks map file offset `bank × $4000 + (addr −
  $4000)` for ROMX. This was confirmed on this ROM: the symbol `32:4000
  BlockFunctionTablePointers` sits at file offset `0xC8000`, and its first
  pointer `$40C4` equals the symbol `BlockFunctionTable00` (`32:40c4`).

## How much of the build is understood

A byte-identical build proves reproduction, not understanding. At this
commit the source pulls in 110 opaque `.bin` blobs and builds 554 `.rle` and
244 `.2bpp` assets from editable sources. Of 8,497 global ROM labels,
1,623 are still placeholder-named. A per-region map of understood,
annotated, and opaque code is future work.

## Unknowns

- Whether other dumps or revisions of this game exist and how they differ.
  Unknown ROMs are reported as `unknown` and refused by extractors unless
  `--exploratory` is passed.

## Re-verify

```sh
make rom-info      # hashes, header, identity
make refbuild      # rebuild and compare (needs make references rgbds)
make test-rom      # ROM integration tests; confirms the ROM hash is unchanged
```
