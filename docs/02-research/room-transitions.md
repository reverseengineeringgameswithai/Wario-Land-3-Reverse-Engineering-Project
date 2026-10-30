---
type: research
status: active
updated: 2026-10-02
tags: [research, movement, validation]
---
# Room transitions

**Question:** how does Wario move from one room to the next, and how long
does it take?

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys @ `560fce6` (`src/home/room_transition.asm`,
`src/engine/level/state_table.asm`, `start_room.asm`,
`block_functions.asm` `EnterDoor` and the transition handlers,
`src/home/fade.asm`, `src/home/door_transition.asm`); oracle Wario traces of
the owner's movie. Task: WL3-027.

## Verified observations

1. **Start.** A presence probe (`UNK7`) on a transition block sets
   `wRoomTransitionParam` (kind 4 from `BlockFunc_187b0`, kind 5 with a
   ladder from `BlockFunc_182fe`). The state's update then calls
   `TriggerRoomTransition`: Wario becomes intangible and `wSubState` moves
   on by 2 (to `FastFadeToWhite`). A door (`BlockFunc_Door`, Up while idling)
   calls `EnterDoor` and sets the delay flag; `UpdateState_EnteringDoor`
   plays two animations, clears the flag, and moves `wSubState` on by 1 (to
   `DoorTransition`).
2. **Timing**, in game loops, from the code: the door effect 34 (17 steps of
   two frames), the fade to white 33 (`wPalFadeCounter` to 33 at
   `FADE_SPEED_SLOW`), the room start 1 (with the LCD off, so it spans more
   emulator frames), the fade from white 33. So 67 loops for a transition
   and 101 through a door, which is exactly the gap in `wGlobalCounter`
   between Wario updates in the oracle.
3. **The next room** (`StartRoom_FromTransition`): Wario moves up 16 px; the
   room-list entry is `XPosHi + 10 * YPosHi` (`GetNextLevelRoomID`); its
   header is loaded (`LoadRoom`), Wario is placed on its spawn
   (`SetWarioPositionToSpawn`, the first `$f` nibble below the spawn
   section), the camera is placed (`SetInitialCameraScroll`), and after a
   door Wario walks out (`Frameset_14d18`).
4. **Parity** (`make wario-parity`, `LevelSim.update_level`): each of the
   five transitions in the owner's movie (three of kind 4, two doors) was
   run natively from the oracle's variables after the update that started
   it. Each took the same number of game loops (67 or 101) and matched the
   oracle's state before the next update on 55 variables (Wario's, the
   camera's, and the room entry). The 36 door-entering updates match too.
5. **Golf** (kind 3, `BlockFunc_MinigameDoor`; WL3-048). The room start
   keeps the room's animated tiles (`wTempAnimatedTilesFrameDuration`,
   `wTempAnimatedTilesGroup` in WRAM bank 3), saves `wSubState` in
   `wPendingSubState`, and enters `ST_GOLF` (5). `_GolfStateTable` fades
   to white (33 loops, the room's tiles still animating), and
   `InitGolfLobby` stops them. Of the minigame, the level sees only
   `wNumCoins` (paid) and `wIsMinigameCleared` (set at the first clear,
   which the clear gates read); the oracle shows no other traced variable
   changed across a visit. `ReturnToLevelFromGolf` restores the tiles from
   their first frame, makes the transition a door's (`$63` becomes `$62`,
   its flags kept), draws the level, and returns to the pending sub-state:
   the door's room then starts as after any door. The port has this side
   (`LevelSim.enter_golf`, `golf_state`), and so is the minigame itself
   ([golf](golf.md), `GolfSim`), played on each loop's traced joypad in a
   parity run. Without golf's data the port replays each visit's game loops
   (counted by the tracer at `_GolfStateTable`, `golf_loops`) and outcome,
   or natively leaves the lobby at once (provisional, ADR-0002). The
   owner's four golf movies (`game-007`, `-008`, `-013`, `-014`: 1729 to
   3464 golf loops) match in every update and in game loops through each
   visit, and run whole frames to the end.

## Interpretation

- The transition's timing is game logic (counters), while its look (fades,
  the door effect) is presentation, so the port keeps the counters and
  draws approximate overlays.

## Hypotheses

- Kind 5 (a ladder transition) behaves as kind 4 here: the code only treats
  Golf (3) and teleports (7) differently. It is covered by a synthetic test,
  not yet by an oracle trace.

## Unknowns

- Teleport (kind 7) transitions, switch blocks (`UpdateSwitchableBlocks`),
  and objects reloaded on entry (`ReloadLevelObjects`) are not ported; the
  golf minigame is not drawn yet.

## Tests

- `game/tests/unit/test_room_transitions.gd`: the spawn search, kinds 4 and
  5 on a synthetic level (frame counts, room entry, spawn).
- `game/tests/unit/test_room_animation.gd`: golf's way out and back,
  native and replayed.
- `make wario-parity`: the transition check on the owner's movie.
