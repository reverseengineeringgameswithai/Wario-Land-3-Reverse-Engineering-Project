---
type: research
status: active
updated: 2026-10-28
tags: [research, rom, validation, tooling]
---
# Emulator oracle

**Question:** can the original be run deterministically as a local
development oracle (per-frame input in, per-frame state out), so that
native behaviour can be checked against it?

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
PyBoy 2.7.0 (`/usr/bin/python3`, user site packages); ElectroDeoxys @
`560fce6` symbols. Tasks: WL3-014, WL3-015, WL3-029, WL3-030, WL3-031. Decision context:
[ADR-0001](../03-architecture/adr-0001-native-port-strategy.md) (the
emulator is an oracle, never the runtime).

## Verified observations

1. **PyBoy's input and state model** (read from the installed package):
   - Buttons change between `tick()` calls (`button_press`,
     `button_release`, `send_input`) and hold for whole frames. There is no
     sub-frame input. `save_state`/`load_state` capture the whole machine.
   - `memory[bank, address]` reads banked RAM.
   - `symbols=` loads a `.sym` file, and `hook_register` runs a callback
     when an address executes. It does this by patching the emulated ROM
     with opcode `$db`, so captures here use plain memory reads instead.
2. **Writes next to the ROM.** Given a ROM *path*, PyBoy derives `.ram`
   and `.rtc` paths next to it, saves cartridge RAM on `stop()` by default,
   writes `<rom>.state` on its save hotkey, and its `--record-input` plugin
   writes `<rom>.replay` (with a screenshot per input event). The oracle
   therefore passes the ROM as bytes and stops with `save=False`; neither
   the `pyboy` command nor its recorder is used. After every run in this
   session, `Original_ROM/` still held only the ROM, with the same SHA-256.
3. **A PyBoy quirk.** In 2.7.0, a banked slice whose exclusive end equals
   the region end (e.g. `memory[1, 0x8000:0xA000]`) raises "out of bounds".
   The oracle reads up to the last byte and that byte on its own.
4. **Boot.** When no boot ROM is given, PyBoy still runs one: its own
   bundled `bootrom_cgb.bin`, a 256-byte stub (SHA-256 `6cc8fc26…`), not
   Nintendo's 2304-byte CGB boot ROM. *(Corrected: an earlier version of
   this note and format 1 of the oracle files said "no boot ROM".)* With
   `cgb=True` and that stub, `hCGB` is 1 (the game does not show its
   GB-incompatible screen). Headless and unthrottled, the game runs at about
   10,000 frames per second.
5. **Route to the first room.** The tracked route
   `tools/wl3pc/data/oracle/ootw-day1-start.route.json` (9453 ticks, 312
   input events) goes from power-on (PyBoy's boot ROM, empty cartridge RAM)
   through the
   title (`ST_TITLE`), language selection (`ST_LANGUAGE_SELECTION`), and the
   overworld intro. The temple dialogue (`UpdateTempleScene`) is left with
   B, since its talking scene waits for `PAD_B | PAD_LEFT`. On the map it
   presses Left then A. It ends 60 ticks after `wState` = `ST_LEVEL` and
   `wSubState` = 3 (`UpdateLevel`). End state: `wLevel` 0, `wRoom` 1,
   `wLevelRoomID` 0, `wWarioState` 0 (`WST_IDLING`), and
   `wWarioXPos`/`wWarioYPos` = 56/752. The route stores the SHA-256 of all
   RAM (WRAM banks 0–7, VRAM banks 0–1, cartridge RAM banks 0–3, OAM, HRAM)
   and the CPU registers. `make oracle-check` replays it in a fresh emulator
   and reproduced both.
6. **The first room, seen running.** The level starts in `ROOM_001`, and
   Wario stands exactly on the spawn point decoded statically from the
   object map in WL3-013, (56, 752) ([first room pack](first-room-pack.md)).
7. **Capture: hold Right for 300 ticks** from the route's end
   (`game/assets/traces/walk-right-300.json`; `make oracle-verify`).
   - Two captures in separate emulators gave identical per-tick samples and
     identical per-tick RAM digests (stream `65045a58…`). A re-run wrote a
     byte-identical capture file.
   - `wJoypadDown` is `$10` (`PAD_RIGHT`) from tick 0, so a press applied
     before a tick is seen in that tick.
   - Positions are whole pixels. On tick 0 Wario enters the walking
     state (`wWarioState` 1) without moving. From tick 1, the per-tick x
     steps are `WalkVelTable`'s entries in order (0, 1, 0, 1, 1, 1, 1, 1,
     1, 1, 2, 2, …), with `wWalkVelIndex` one ahead. The index counts up to
     15 and then cycles 12–15, at 2 px per tick. The table's own cap (`$1b` → `and $fc`) is not reached
     while walking; state code applies its own caps (e.g. ice skating caps at
     `$14` → `$10`). Which code gives the 12–15 cycle is for WL3-012.
   - Wario stops at x = 88 from tick 22 and stays there, pushing
     (`wWarioState` 1 throughout), against the non-cracked block at
     column 6 of the extracted `ROOM_001` (x = 96). This is a second
     confirmation of the extracted geometry.
   - `wGlobalCounter` advanced by exactly 1 on each of the 299 tick steps:
     one game loop per LCD frame during this play (WL3-015).
8. **Recorder.** `make oracle-record NAME=…` runs PyBoy headless and draws
   the screen in its own SDL window. It reads the keyboard every frame and
   applies it through the same calls a replay uses. Keys: arrows; X = A;
   Z = B; Enter = Start; Backspace = Select; P = pause; `.` = one frame
   while paused; Esc = save and quit. It writes held buttons per tick
   (`input-trace.v1`) and a RAM digest every 60 ticks and at the end.
   Under SDL's dummy video driver, 150 ticks were recorded in 2.7 s, which
   is real-time pacing. Replays from power-on and from the route matched
   every checkpoint, and a tampered recording was rejected at the next
   checkpoint.

9. **TAS editor** (`make tas NAME=…`; `tools/wl3pc/tas.py`, `tas_gui.py`).
   - It shows the live screen (3×), a piano roll of per-frame buttons, and a
     RAM watch of the sampled WRAM variables.
   - Compressed save states every 10 frames (about 6.5 KB each; a PyBoy
     state is about 200 KB raw and loads in about 4 ms) make seeking to any
     frame immediate.
   - An edit discards the states after the edited frame and rewinds there.
     When the mouse gesture ends, the editor seeks back to where it was, so
     a later frame is always re-emulated from the new inputs.
   - Rows show the greenzone (frames whose result is known), lag frames (no
     `wGlobalCounter` step while the frame ran), and frames past the movie's
     end.
   - Movies are saved as oracle recordings, with checkpoints taken by
     re-emulating from the start, so `make oracle-replay` and captures accept
     them.
   - `make tas-check` runs against PyBoy. Seeks to 10 frames, including
     frames on and next to snapshots where the buttons change, matched
     straight replays in the full-memory digest. An edit 110 frames back
     re-emulated to the same digest as a straight replay of the edited
     inputs, and a saved movie replayed with all checkpoints matching. So
     PyBoy's save states carry the held-button state the editor relies on.
   - The scripted window test (`oracle tas-selftest`) ran on the desktop
     display. It played 89 frames in 1.5 s (real time) while recording,
     recorded 12 frames by frame advance, painted B on frames 13–16 by
     mouse, saved, and replayed the result. A redraw took 5.3 ms on average
     (9.2 ms worst), within one 16.7 ms frame. It caught one bug, now fixed:
     after a save the screen was blank, because the checkpoint pass does not
     render.

10. **Starts** (format 2 of routes, captures, and recordings). A movie
    starts from one of these:
    - power-on, with PyBoy's boot ROM or the user's own dump, and empty
      cartridge RAM or the user's own raw 32 KiB battery save;
    - a tracked route;
    - a PyBoy save state, with its origin when known.

    The user's files are copied into `local/oracle/{bootroms,saves,states}/`
    under their SHA-256, read-only, and documents name them only by hash.
    The tool refuses boot ROMs that are not 2304 or 256 bytes, and saves
    that are not exactly 32768 bytes. It warns that a 256-byte DMG boot ROM
    would make the game refuse to run.
    - The first frame of every movie sets all eight buttons (released unless
      held). PyBoy raises the joypad interrupt only when a released button is
      pressed (`Interaction.key_event`), and its save states include the
      button lines. So a start's own button state cannot leak into a movie.
      Regenerated as format 2 with this rule, the route gave the identical
      memory digest (`e2e5a5a8…`), and the walk capture the identical stream
      (`65045a58…`).
    - `make starts-check` checks the start kinds against straight replays:
      - PyBoy's boot ROM given as a file reproduces the route;
      - a state saved at frame 120 of the walk continues to the same memory
        as the straight walk, and `state-check` rebuilds it from its
        origin;
      - a state saved by PyBoy outside the oracle (frame 150, no origin)
        imports and continues identically;
      - a battery save exported from the game loads into cartridge RAM at
        power-on, replays identically twice, and changes the run compared
        with an empty save.
    - By the end of the route, the game has written save data (7374 non-zero
      bytes of 32768).
    - The editor adds Save state (Ctrl+T), Branch (Ctrl+B: a new movie whose
      start is the current frame's state, with the parent's start and inputs
      as its origin), and Export save (Ctrl+E). Its scripted window test now
      branches, records 30 frames, saves, and replays the branch from its
      state.

11. **Deep dive into PyBoy 2.7.0** (source read from the installed package;
    license LGPL-3.0-only, used only as a local development tool, never
    distributed with the game).
    - **Execution hooks.** `hook_register` writes opcode `$db` at a ROM
      address. When execution reaches it, the callback runs, and the
      original opcode is restored, single-stepped, and re-inserted
      (`mb.breakpoint_add`, `breakpoint_reinject`).
    - `ProcessBlock` (`06:4000`) is hooked on entry, and the `ld b, a` after
      each of its 10 `call` sites in `collisions.asm` (`06:5b5c`–`06:5c16`,
      checked in the ROM bytes before hooking) is hooked to read the
      handler's result in register A. With these hooks, the 300-frame walk
      kept the identical memory digest on every frame (stream `65045a58…`),
      at no measurable cost. `oracle probes` checks this against a plain
      run every time.
    - **Probe trace of the walk.** There were 1476 `ProcessBlock` calls,
      about 5 per frame.
      - Wario's probes were the ground probe (`COLLISION_DOWN`), the wall
        probe (UNK4), and the presence probe (UNK7). The other calls came
        from the enemy on the blocks.
      - With Wario at (88, 752), the wall probe was at (96, 744), the
        presence probe at (88, 748), and the ground probe at (88, 752).
      - Every handler and probe pair matched the WL3-011 mapping:
        `BlockFunc_Free` always returned `$00`, and `BlockFunc_Solid`
        returned `$01` to all 300 ground probes. The non-cracked block at
        column 6 (`h06_4d60`) returned `$01` to all 277 wall probes; Wario
        was not attacking. The cracked and non-cracked blocks under the enemy
        returned `$01` to its probes.
    - **Live map check.** Each probe reads its block from the game's SRAM
      copy of the level map (row = (bank − 1) × 32 + page, column = the low
      byte of the pointer). All 20 distinct cells probed during the walk
      match the statically decoded `OutOfTheWoodsBlockMap` (WL3-025).
      `oracle review` repeats this for any movie; a broken block differs on
      purpose.
    - **Not used yet:**
      - `tilemap_background`/`tilemap_window` and `screen` (for WL3-018,
        comparing decoded tiles with VRAM);
      - `get_sprite` (OAM, for objects);
      - `sound.ndarray` (WL3-020);
      - `memory_scanner` (value searches; the `.sym` makes it unnecessary
        for now);
      - `gameshark` (cheats; a run with cheats is not original behaviour);
      - the rewind and debug plugins, which the editor's greenzone and
        RAM watch replace.
    - **Review tool.** `oracle review` writes, for any recording or trace:
      - a timeline of frames where the state, room, keys and treasures,
        transformation, or power-up change;
      - contact sheets of every Nth frame;
      - the probe trace;
      - the live map check.
12. **BizHawk movies (.bk2/.tasproj).** The game reads the DIV timer, which
    counts CPU cycles since power-on, as its randomness. Readers include
    `BreakBlock` (a coin on `rDIV & 3 == 0`, so 25% of broken blocks) and
    enemies including Para-Goom, Doll Boy, Brrr Bear, Anonster, and Octohon
    (`src/engine/level/objects/`). BizHawk's cores and Nintendo's boot ROM
    time the boot and each frame differently from PyBoy. A BizHawk input
    log therefore cannot be expected to stay in sync here once a random roll
    differs. An importer could still turn one into a draft movie to repair
    in the editor (WL3-032).
13. **TAStudio-style editing.**
    - BizHawk-style hotkeys: F frame advance, Shift+R frame back, Q
      toggles record/read-only, Pause plays and pauses, and holding Tab
      fast-forwards.
    - Markers: M adds or removes a labelled marker, and `[`/`]` jump
      between markers. Markers move with inserts and deletes, are undoable,
      and are saved as an optional `markers` list that replay ignores.
    - Range editing: Shift+click frame numbers to select, Ctrl+C copy,
      Ctrl+V paste over, Ctrl+Shift+V paste-insert.
14. **Keyboard and modes in the editor.** The owner's keys did nothing
    because a new movie opened paused and read-only.
    - A new movie now opens running and recording. A movie that already has
      input still opens paused and read-only, so it cannot be overwritten by
      accident.
    - The mode is shown by a banner above the screen and the screen's
      border: red for "RECORDING", blue for "READ-ONLY". Q, Ctrl+R, the
      Mode button, or a click on the banner switch modes. A branch opens
      recording.
    - The Game Boy key map is printed under the screen: arrows for the
      D-pad, X for A, Z for B, Enter for Start, Backspace for Select. In
      read-only mode, or while paused, pressing a Game Boy key shows a hint
      instead of doing nothing silently.
    - X11 key repeat sends a release and a press together. A release now
      takes effect only after 30 ms, so a held key stays held through the
      repeat.
    - A save state on the level-select map (`8b5fd0d5…`, 9215 frames into
      the `ootw-day1-start` route, before the Left press that selects
      Out of the Woods) was stored and rebuilt from power-on. In it,
      `wLevel`, `wKeyAndTreasureFlags`, and `wNumCollectedTreasures` are 0
      and the cursor is on "The Temple". A movie started there includes
      entering the level, so the level's own setup is in the recording.
15. **The owner's Out of the Woods recording (gray key and chest).**
    `local/recordings/ootw-gray-key.recording.json` (local, untracked) is
    8363 frames from the map state `8b5fd0d5…`, through the level clear and
    back to the map. It replays with all 140 checkpoints matching; its first
    6031 frames are the first version's, unchanged. `make review` gives
    (state names from `src/constants/state_constants.asm`):
    - Frame 99: `wState` 1 → 2 (`ST_OVERWORLD` → `ST_LEVEL`). Frame 148:
      Wario at the level spawn (56, 752), as at the route's level start.
    - **Gray key:** frame 2040, `wKeyAndTreasureFlags` 0 → 1 (bit 0), at
      (2440, 197) with `wLevelRoomID` 21, while `wState` is `ST_COLLECT_KEY`
      (8) for 100 frames.
    - **Gray chest:** frame 5745, flags 1 → 17 (bit 4), at (193, 336) with
      `wLevelRoomID` 5.
    - **Clear:** `ST_CLEAR` from frame 6557. At frame 6592 byte 3 of
      `wTreasuresCollected` (WRAM bank 2, `$d000`) goes from `$00` to
      `$08`, which by `IsTreasureCollected`'s layout is treasure `$1b`,
      `AXE` (`src/constants/treasure_constants.asm`), the item the clear
      screen shows. `UpdateNumCollectedTreasures` raises
      `wNumCollectedTreasures` from 0 to 1 at frame 6596. Bit 0 (index 0,
      `TREASURE_NONE`) was already set at the start; the counting loop
      stops before index 0, so it is never counted.
      `ST_OVERWORLD` from frame 6798; `ST_PAUSE_MENU` at frames 7892–8030,
      when the contact sheet shows "Now Saving" and "Save Complete". The
      key bit is cleared on the map at frame 8179 (flags 17 → 16), and the
      treasure bit stays.
    - Coins: 0 → 21, matching the clear screen's "TOTAL COIN 021".
      Transformations (names from `src/constants/wario_constants.asm`):
      `$85` ELECTRIC (frames 1201–1332), `$c3` BALL_O_STRING_WARIO
      (3589–4349), and `$c1` HOT_WARIO (4437–5182). `wLevelRoomID` took the
      values 0, 21, 19, 5, 10, 5.
    - 27,989 collision probes, with hooked and plain runs identical in
      memory.
    - The map check covered 682 cells. All 15 differences are bit 7 alone,
      which marks a block whose object is not spawned
      ([level block maps](level-block-maps.md), finding 7). The review now
      reports those separately from changed blocks. It also reads the level
      where the probes begin, instead of at the movie's start, because a
      movie that starts on the map may enter any level.
    - **Two watch bugs found and fixed.** `wNumCollectedTreasures` was
      sampled as one byte, but it is two (`ds $2`) with the high byte
      first, so the watch showed only the hundreds digit. Both it and
      `wNumCoins` are binary-coded decimal (`add`/`daa` in
      `ObjInteraction_RegularCoin` and `UpdateNumCollectedTreasures`), so
      the first review reported 33 coins for `$0021`. The review and the
      RAM watch now show BCD counters in decimal (the watch's hex column
      keeps the raw value), and the review names `wState` values.
16. **Wario traces** (`make wario-trace MOVIE=…`, `tools/wl3pc/oracle_wario.py`).
    65 named variables every frame, the live block map with its changes,
    and every Wario update exactly: the variables on entry to
    `UpdateWarioStates` and to `UpdateObjects`, recorded through hooks,
    because frame boundaries do not fall at a fixed point of the game loop.
    The native parity check (`make wario-parity`) uses them
    ([wario movement](wario-movement.md)).
    - **When a block changed** (WL3-047): a change is one sample per
      frame, so an object breaking a block at frame N looked as if it
      happened before frame N's `UpdateObjects`, and the rerun found the
      block already broken (a thrown object's break at night, level 04).
      The trace now diffs the map at each object checkpoint too, and each
      change carries `seen`, the checkpoint where it first showed (4: the
      frame's end). The object step applies this frame's changes seen at
      checkpoint 0 and then compares the map with those seen by 1; the
      interaction step applies up to 2 and compares with 3. Older traces
      without `seen` keep the frame-wide behaviour. Re-recording a trace
      from its movie takes about a second; all 302 were.
    - **The hidden figure's fight drawn** (WL3-052, 2026-10-28): in the
      Temple the tracer renders every tick and records, at every 32nd
      Wario update, both VRAM banks at the update (`temple_vram`) and the
      screen at the end of its tick (`temple_screens`), keyed by frame;
      in any level it records each palette `SetBGPals` and `SetWarioPal`
      write while the frame is drawn, with its line, the palettes left,
      and the source (`pal_writes`, hooked at each palette's first data
      write, `00:35fb` and `00:1b34`, after their H-Blank waits). The ten
      movies that reach the fight were re-traced
      ([the fight drawn](hidden-figure-drawing.md)).

17. **Starts at any level** (`make level-movie LEVEL=… SCRIPT=… TICKS=…`,
    `tools/wl3pc/oracle_levels.py`). The route's input from power-on, with
    `wLevel` (`$ca06`) set to the wanted level (level × 8 + variant: day
    1-4, night 1-4) the first time `InitLevel` (`02:4024`) runs, then idle
    until the level plays and 60 ticks more. The state is stored with that
    origin (`level_poke`), and `make state-check` rebuilds it: The Peaceful
    Village (`0x08`) matched its origin after 9513 frames. A test harness
    only; progress is a new game's. Scripted movies (idle, a direction, or
    a direction with A for 20 of every 60 ticks) are saved as recordings
    with the recorder's checkpoints, and the level's content is extracted
    alongside. The first, 900 ticks of Right in The Peaceful Village: all
    900 Wario updates and camera runs match the native port (a free camera,
    unlike level 0's), and its two objects are named as unported.
    - **Coverage sweep** (all 25 levels' day-1 starts, 1200 ticks of Right
      with jumps): every compared Wario update matched in every level, and
      three levels ($58, $80, $b8) ran all 1200 frames natively. What they
      met unported, by levels: the water states (9 levels, now ported),
      enemy bumping (`$19`, 6), Para-Goom and Brrr Bear (4 each), Spear
      Bot, Hebarii, and Haridama (2 each), and some 30 more objects in one
      level each; block handlers (water, now ported; light sources,
      slippery blocks, fences, cloud platforms).
    - **More scripts** for coverage the Right-and-jump movies do not
      reach: `right-attack` (B for 4 of every 40 ticks besides the jumps),
      `right-crouch` (Down for 30 of every 90), and `wander` (a 24-tick
      segment of one of 12 button sets, chosen by a 16-bit linear
      congruential generator seeded with 1, so the same every time).
    - **Power-ups** (`POWER_UP=0-9`, WL3-046): every start is a new
      game's, so `wPowerUpLevel` (`$ca3c`) is 0. With the option it is
      set once the level has settled (the game sets it only from
      collected treasures, and nothing at a level's start recomputes
      it); the origin records it (`end_pokes`) and `make state-check`
      replays it after the input, so the stored start still rebuilds
      (checked for level 08 with all power-ups). Movies are named
      `-puN`. Level 08's `wander` movie with every power-up compares 683
      of its 1200 Wario updates, all identical; the rest meet the smash
      attack in the air first.
    - **Night** (WL3-047): `SelectLevel` sets `wLevel`'s bit 2 (+4, nights
      1-4) from `wDayNight`'s bit 0, which the objects read too (the
      Spearhead sleeps at night). A night level's poke therefore sets that
      bit as well; poking `wLevel` alone gave the night map with day
      objects (a first night sweep, set aside). The origin records it, and
      `make state-check` replays it with the level.
    - **`make sweep`** (`tools/wl3pc/sweep.py`): a sweep as one command,
      `SCRIPT=…` with `POWER_UP=…`, `VARIANT=0-7` (days 1-4, nights 1-4),
      and `MODE=step|run`; `RECORD=1` records missing movies and traces
      through `make level-movie` and `make wario-trace`. The per-level
      results and a summary (totals, levels that differ, what is left
      unported, or how far whole frames run) go to
      `local/reviews/sweeps/`; it fails when anything compared differs.
      `VARIANT=1,2,3` takes several, and `DISTINCT=1` leaves out a
      variant whose room list and block map are an earlier variant's of
      the same time of day (`SelectLevel` picks variants 1-3 by the
      treasures collected): of the 150 later variants, 85 have their own
      (the rest repeat; treating them as the same is a hypothesis, since
      code may read `wLevel`'s low bits).
      `JOBS=n` records and checks n levels at once (each check is its own
      Godot process): the 408 day-1 room starts take under a minute with
      12.
    - **Room starts** (`make level-movie … ROOM=n`, `make sweep … ROOMS=1`):
      the level start also sets `wLevelRoomID` the first time
      `StartRoom_FromLevelStart` reaches `.load_blocks_and_objects`
      (`02:47eb`, after it clears the ID and before `LoadRoom` reads it),
      so the level starts in that room-list entry at its spawn; the movie
      is `level-LLrRR-…` and the origin records the poke. An entry is the
      room a transition from section `x + 10y` leads to, so a spawn can
      itself sit at a transition: level 00's entry 2 spawns at (1592,
      480) and the game moves on at once to entry 16 (`GetNextLevelRoomID`
      from that position), where the movie starts. Day 1 has 408 room
      starts with a spawn (entries repeating a header left out).
    - **Below the map** (WL3-047): SRAM holds 64 map rows (two banks of 32
      pages) and the decoded maps 48. A spawn on the last row stands
      Wario on row 48 (four day-1 room starts: 10r03, 78r0a, 78r18,
      90r17), so traces now record all 64 block rows (rows 48-63 were
      zero at every start checked) and the port's map is 64 rows, the
      rows below the decoded ones zero (provisional for native play;
      since 2026-10-28 native play from a load takes SRAM's there,
      [the resets](resets.md) item 7).
      With it those four compare all their 4,800 Wario updates, all
      identical. All traces were re-recorded (1,443 in eight minutes).
    - **The interaction step's flag** (WL3-047): `UpdateLevel` sets
      `wBlockFuncWarioFlag` around `ProcessInteractions` (the port's
      `update_level_objects` does too), but the parity tool's interaction
      step called it without, so a block probe from an interaction (the
      Vampire's `Func_19b25` under water) read as an object's. The step
      now sets the flag as `UpdateLevel` does.
    - **Whole frames from a room start** (WL3-047): 60 room-start movies
      stopped at a difference in run mode while every step matched, for
      three reasons. The run loaded the particle region from the first
      frame's checkpoint, which `UpdateParticles` had already run before,
      and then updated it again (seen only when a room starts with
      particles alive); it now loads them after the first frame's Wario
      update. `DeviceFunctions` declared a `_bubble_drift` for the bubble
      object, which silently replaced `WarioSim`'s for Wario in a bubble in
      every `LevelSim` (the Wario step runs `WarioSim` alone, so only whole
      frames showed it); it is `_bubble_object_drift` now, and
      `tests/test_sim_overrides.py` fails on any method a class redefines
      that is not one of the intended hooks. And the owl's particle was not
      ported, its note lost because Wario's update clears the list after
      `UpdateParticles`; the owl, snow, and magic particles are ported and
      such notes kept. With them all 24 sweeps (3,258 movies) run to the
      end in 3,082, every other stopping at something not ported.
    - **Writes past the slots** (WL3-047): the object step reruns a whole
      `UpdateObjects` pass and judges each slot, except those an unported
      update ran in or may have replaced. Unported code can also write
      past the slots: the Shoot ball's goal reached the goal counter
      (ported) in a later slot of the same pass as a count the port never
      saw. When the bytes from `wObjDataPointers` on end up different
      after a pass with an unported update, the slots after the first
      unported one are not judged either.
    - **Longer and more varied movies** (WL3-048): `TICKS=n` names a movie
      of other than 1200 ticks `-tN` (in `make level-movie` and `make
      sweep`), so longer movies sit beside the sweeps' own;
      `left-attack` mirrors `right-attack`, and `wander-sN` seeds
      wander's generator with N. In the boss rooms they reach more of the
      battles than the 1200-tick movies, but not the bosses' defeats
      ([objects](objects.md), item 79). A 3600-tick trace is about 60 MB.
    - **Coverage-guided search** (WL3-048, `tools/wl3pc/oracle_search.py`,
      `SCRIPT=search-sN`): from the start, 48-tick segments of runs of
      wander's button sets, 16 tried from each saved state. It keeps the
      one that reaches the most coverage keys not yet seen: an active
      slot's (ID, update function, `OBJ_STATE`), Wario's state, his 32-px
      cell, and the values of the battle variables (`$d140`-`$d149`: the
      bosses' hits, goals, and phases). It applies inputs as `oracle.play`
      does, and the movie is replayed from the start for its checkpoints
      (a test checks that a replay sees what the search saw). In the 11
      boss rooms, 22 movies of 7200 ticks (seeds 3 and 4) are identical in
      every update but reach no object function the scripted movies had
      not. Greedy novelty explores the room (20 to 158 keys per movie) but
      does not fight; 22 earlier movies without the battle variables did
      no better. The battles need goals per boss or movies the owner
      plays.
18. **The owner's game movies** (WL3-048; [owner's
    movies](../04-development/owner-movies.md)). A chain of movies, each
    branched from the end of the one before. `game-002` (The Peaceful
    Village at night, `$0c`, gray key and chest; 4705 frames) and
    `game-003` (The Vast Plain, `$10`, gray key and chest; 5070 frames)
    match in every Wario update (3,597 and 2,732), object update,
    interaction run, and room transition, and in run mode to the end
    (3,628 and 2,881 whole frames). They are the first movies that start a
    level after another. The native level start differed in `wFloor` (0,
    the original 5): `StartRoom_FromLevelStart` updates the floor only in
    a room with floor transitions, so otherwise it keeps the last level's.
    The check now starts the native level from the traced values of the
    last frame before it, as the original keeps them. That showed two
    variables the port's start did not clear (`wIsIntangible`,
    `wLevelEndScreen`, left at 1 by the last level's end). `start_level`
    now clears every variable the original's does (with
    `ClearTransformationValues`), and both starts, like
    `ootw-gray-key`'s, are identical.
    The next twelve (`game-004` to `game-014`, rename list in
    `local/recordings/game-movies.md`) brought the hand and Wario dragged
    down, a ladder slide's ground pound (wario movement item 44), and
    `Func_ba42`'s spawn (objects item 83). Each needed level's collision
    data is extracted on demand (later variants whose data repeats an
    earlier one's were never extracted). Remaining gaps:
    - **Golf** (now ported). Doors in some levels lead to the golf
      minigame (`wState` 5; `game-007`, `-008`, `-013`, `-014`). The
      level's side of it is ported (room transitions item 5), and the
      minigame too ([golf](golf.md)): the tracer records every golf loop
      (`golf_updates`, at `_GolfStateTable`), and a parity run plays it
      natively on each loop's traced joypad, with its rDIV read
      (`PickAndLoadGolfHole`) replayed. A trace from before that replays
      the minigame's game loops (`golf_loops`; the frames cannot place
      the short loop that enters golf, which came out one loop off in
      three movies of four) and the coins and clear it leaves. Game loops
      between two updates unwrap `wGlobalCounter` by the frames between,
      since a visit is thousands of loops. All four movies match and run
      to the end.
    - **Above the map** (now replayed). A probe above row 0 (row 255)
      reaches `GetBlockPtr`'s page `$9f` in SRAM bank 1's numbering,
      which is VRAM's second background tile map (`$9f00`-`$9fff`); rows
      past 63 reach SRAM bank 3, ROM, or VRAM. The tracer hooks the
      instruction after `ProcessBlock`'s read (`06:4014`) and records any
      read outside the traced rows in `div_reads` (bank `$ff`, the address,
      the byte), in the game's order with the rDIV reads; the port's
      `process_block` takes the next one when its own address
      (`_block_address`, as `GetBlockPtr` forms it) matches. The Sun in
      `game-013` (bytes 1 at `$9f77`-`$9f7b`) and Wario in the water in
      `game-016` (`$9f19`, 32 or 255) now match.
    - **Several levels in one movie.** `game-016` enters The Pool of Rain
      at night (`$45`), leaves, enters it by day (`$41`), resets at the
      title, and resumes the level. `make wario-parity` now checks a trace
      a visit at a time when it has more than one. A visit runs from
      entering a level from the map or the title until the game leaves it
      (for the map, the title, the clear screen): pause, golf, and a key's
      pause stay inside. Each visit uses its level's data; the parity
      script takes the window (`--from`, `--to`) and filters every
      per-frame list to it, while the maps follow the whole trace. A
      level resumed from a save (`wceef` bits 2-5, now traced) skips
      `StartRoom_FromLevelStart`'s setup. The port does not model that, so
      its start is reported as not checked. All three visits match.
    - **Action Help** (now ported; [Action Help](action-help.md)). A
      power-up's treasure leads from the clear screen to Action Help
      (`wState` 7), now inside a level visit. The owner's movies show two
      of its thirteen demos; `make action-help-movie MOVIE=…
      POWER_UP_LEVEL=…` branches a movie at the first tick ending in
      Action Help, pokes `wPowerUpLevel` (and with `TRANSFORMATION=` a
      transformation) as end pokes of a stored state's origin (so
      `make state-check` rebuilds it), and records an idle or browsing
      continuation under `local/recordings/action-help/`.

## Interpretation

- PyBoy is deterministic for a fixed version, start, and per-frame input,
  which is what TAS-style recordings need. Recordings are portable only
  between machines with the same PyBoy version; they will not sync in
  other emulators, whose frame boundaries differ.
- The oracle already turned two static conclusions into observed ones (the
  spawn point and the wall at column 6). It also gives WL3-012 its first
  ground truth: the native walk must reproduce the 22-tick x sequence
  above.

## Hypotheses

- PyBoy matches hardware closely enough for per-frame WRAM logic. It is not
  cycle-exact, so anything timing-sensitive (raster effects, sound,
  `rLY`-gated palette updates such as `UpdateRoomAnimatedPals`) needs a
  second emulator before it counts as evidence.

## Unknowns

- Real keyboard input in the recorder and the TAS editor. The self-tests
  call the key handlers directly (including a release and press in the
  same instant, as X11 key repeat sends them), not through the window
  system, so real key events are exercised first by the owner's own use.
- Probe positions are known for walking only; jumping, attacking, and
  object probes need their own captures before the collision box offsets
  are written down for WL3-012.
- Nintendo's own CGB boot ROM has not been run here (none is available, and
  none will be downloaded). Its boot timing will differ from PyBoy's stub,
  so movies made with one do not replay with the other; the start records
  which one was used.
- Whether the game drops frames in heavier scenes; the cadence result covers
  this capture only.

## Tests

- `tests/test_oracle.py`, without PyBoy: tick timing of held buttons (with a
  fake emulator), trace compression and validation, capture comparison, the
  tracked route against `oracle-route.v1` and the native trace rules, sample
  addresses against the `.sym`, and a clear error without PyBoy.
- `tests/test_rom_integration.py`, through the PyBoy interpreter
  (`ORACLE_PY`, labelled SKIPPED without it): route replay; the walk
  capture's reproducibility, schema, positions, wall stop, and cadence; and
  `tas-check`.
- `tests/test_oracle_levels.py`: the scripts' input and the level poke
  (once, at `InitLevel`) with a fake emulator.
- `tests/test_tas.py`, against a deterministic fake machine: seeking
  anywhere matches straight play, edits rewind and re-emulate, recording
  overwrites and then appends, insert, delete, truncate, undo, lag
  detection, and saved checkpoints.

## Next experiment

WL3-012: read the walking state that keeps `wWalkVelIndex` in 12–15, then
make the native movement reproduce this capture tick for tick.
