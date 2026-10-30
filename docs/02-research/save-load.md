---
type: research
status: active
updated: 2026-10-18
tags: [research, validation]
---
# The save's load

**Question:** how does the game load its battery save, and does a port of
the load leave the RAM and the cartridge RAM exactly as the original does?
Task: WL3-055, step 1 of 4.

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys @ `560fce6` (`src/home/start.asm` `Init`,
`src/engine/pause/save/validate_save.asm`, `checksum.asm`,
`src/ram/wram.asm`, `src/ram/sram.asm`); the oracle's captures of the load
(`wl3pc.oracle_save`).

## Verified observations

1. **When.** The save loads at power-on, not in the title: `Init`
   (00:015e) clears the RAM and calls `ValidateSaveData` (7c:4cad), then
   `InitGameState` (00:1690). Every reset (`jp Init`) loads it again, as
   after the level's save from the pause menu
   ([the pause menu](pause-menu.md)); the port's resets load the SRAM as
   it then is ([the resets](resets.md)).
2. **What.** `ValidateSaveData` checks six slots in SRAM bank 0: the map's
   save and its backup (`"war3"`), and four copies of a level's save
   (`"WAR3"`). A slot counts when its checksum and the checksum's two
   echoes agree, after a vote, with its sum. The level copies count only
   when the level map's SRAM matches its checksum: SRAM bank 1 and bank 2's
   first half for the first pair, bank 3 and bank 2's second half for the
   second. The highest save counter wins. Tied slots all stay set in
   `wceef`, and the first of them loads, so a map save and its backup give
   `wceef` = 3. With no valid slot, the Time Attack and golf best scores
   are set to `$aa`. The load also writes SRAM bank 0 (invalid slots'
   check values cleared, the counters' scratch copies).
3. **A kept bug.** `CalculateChecksumLong` jumps into `CalculateChecksum`
   instead of its own loop, so the objects' part of a level save's sum
   covers two of their `$14a` bytes. The save (`SaveLevel`) and the load
   share it, so the game agrees with itself.
4. **The oracle's captures.** `wl3pc.oracle_save` replays each owner's
   movie to its end (all 2,176 recorded memory checkpoints matched), keeps
   the 32 KiB save it leaves, and powers on with it, and with none,
   recording the RAM and SRAM at `ValidateSaveData`'s first instruction
   and at `InitGameState`'s. `game-016`'s reset after its level's save is
   captured as it happens (`wceef` `$14`, a level save). That makes 19
   loads; each changes 56 to 293 of the compared bytes.
5. **The port.** `SaveLoad` (`game/scripts/sim/screens/save_load.gd`)
   translates `ValidateSaveData` and its routines. From each capture's
   "before", it leaves every byte of the "after": all 19 equal
   (`make save-load-check`). Not compared: the stack page
   (`$cf00-$cfff`) and `wROMBank` (`$c5ff`, the bank the code switched to
   last; the port has no ROM banks). WRAMX banks 3-7 and HRAM, which the
   port does not keep, are unchanged by the original's load.

6. **From the title to the map.** With a save, the title goes from its
   fade in (sub-state 3) straight to the start menu (sub-state 7), 160
   ticks after power-on with PyBoy's boot ROM; the intro is skipped. There
   A takes Continue (`HandleStartMenuSelection`; Start does nothing, and
   left alone the menu starts a demo after about 2,100 ticks). The map
   then starts from transition 0: `InitOverworld`, then sub-states 9, `$a`,
   and `$b`. `make continue-movie` records such a movie (power-on with a
   stored save, A once at tick 200, 800 ticks); with `game-017`'s save
   (`title-continue-game-017`) all 555 compared map loops match, and its 17
   VRAM snapshots and 16 screens equal the original's. The title's loops
   are traced and ported since, and the load and the title together play
   from power-on natively ([the title](title.md)).

## Interpretation

- The load is a faithful port for the saves the owner's play produces: a
  map save with its backup, a level's save, and no save. Corrupted slots
  and the second level pair winning are covered by unit tests on invented
  data only.

## Unknowns

- No movie has a save whose second level pair wins (bits 4 and 5), whose
  slots disagree, or a Time Attack save.

## Tests

- `game/tests/unit/test_save_load.gd`: no save, a map save, a corrupted
  main save with its backup, a level save winning, tied counters, the
  checksum bug, and a round trip through `PauseMenuSim.save()`, on
  invented data.
- `tests/test_save_load.py`: the 63 RAM and SRAM constants against the
  reference build's symbols, and its sizes against its map.
- `make save-load-check`: the 19 captures (ROM and PyBoy).

## Next experiment

A level's save (`game-016`'s, captured at its reset) through Continue, to
port the level's resume (WL3-056).
