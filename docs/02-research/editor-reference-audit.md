---
type: research
status: active
updated: 2026-10-01
tags: [research, rom, collision]
---
# Editor reference audit

**Question:** which claims in the WL3 Editor's `ref/` tables (Drenn, v0.5,
user-provided in `WL3 Editor/`) hold for the identified ROM?

The tables are leads. An address landing on a disassembly label shows the
address is plausible for this revision; it does not confirm the editor's
*name* or *meaning*. Checks below use the ElectroDeoxys @ `560fce6`
reference-build symbols, which match this ROM byte for byte
([ROM identity](rom-identity.md)).

## Verified observations

| File | Editor's claim | Check (2026-10-01) | Result |
| --- | --- | --- | --- |
| `tileEffects.txt` | 226 handler pointers "in bank 6" for tile collisions | Each address looked up as `06:AAAA` in the `.sym` | 226/226 land on bank-06 global labels (e.g. `Solid` → `BlockFunc_Solid` `06:4032`) |
| `tileEffects.txt` | Covers the handlers the game uses | Compared with the 138 handlers referenced by the decoded block function tables ([first investigation](first-investigation.md)) | 137/138 named. Missing: `06:49d4` (`BlockFunc_CloudPlatform2`, used by 5 tables). 89 editor entries are referenced by no table (mostly breakable-block variants, plus `Unknown 1/2`, `Empty 2`). |
| `enemyAis.txt` | Object pointers (bank not stated) | Address looked up in every bank | 111/111 land on labels in bank `$19` (e.g. `Spearhead` `4413` → `19:4413 SpearheadData`) |
| `enemySet.txt` | Object-set pointers | Same | 118/118 on bank `$19` labels (`ObjectGroup…`) |
| `itemSet.txt` | Item-set pointers "in bank 0x19" | Same | 5/5 on bank `$19` labels (`CommonObjects_Red`, …) |
| `enemyGfx.txt` | Graphics addresses per stated bank (`[68]`–`[6F]`) | `BB:AAAA` lookup | 101/101 on labels in the stated bank |
| `level.txt` | Levels `$00`–`$C8`, 8 versions each (day 1–4, night 1–4), then the final boss | Compared with `LevelHeaders` in `src/data/levels/rooms1.asm` | 201 entries on both sides. Order of the first entries matches (`OUT_OF_THE_WOODS_DAY_1`…). Not yet checked against the ROM by a decoder. |
| `music.txt` | Song IDs (`0001` Out of the Woods D, `0015` Credits, `0033` Title) | Compared with `src/constants/sound_constants.asm` | These three agree; the rest are unchecked |

## Unverified leads

- `scrollModes.txt` (scroll values 0, 1, 8, C) and the readme's description of
  region crop bits: candidates for the camera work in M2.
- `textTable.txt`, `creditTextTable.txt`, and `textLocations.txt`: the text
  encoding and pointer locations (stated as file offsets). Check against
  `src/charmaps.asm` and the text loaders (WL3-019).
- `miscGfx.txt`: compressed-graphics pointers stated as file offsets.
- Readme claims: sectors are 16×16 tiles, sector 0's warp destination is
  the spawn point, and tiles `$78`–`$7F` are the only "broken" replacements.
  Each needs a consumer in the code before use.

## Interpretation

The editor's address tables are consistent with this revision, so they are
useful indexes into the disassembly. Its names are one modder's
interpretation from 2012–2014. The project uses disassembly symbols plus its
own verified descriptions, never editor names alone.

## Next experiment

Fold the editor's names into WL3-011 as secondary labels. Where an editor
name disagrees with the behaviour read in `block_functions.asm`, record the
disagreement.
