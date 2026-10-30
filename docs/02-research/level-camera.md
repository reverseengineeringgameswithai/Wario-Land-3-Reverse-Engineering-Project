---
type: research
status: active
updated: 2026-10-28
tags: [research, movement, validation]
---
# Level camera

**Question:** how does the camera follow Wario in a level, and can the port
reproduce it frame for frame?

Evidence base: identified ROM `wl3-world-en-ja` (SHA-256 `b625ed03…7406`);
ElectroDeoxys @ `560fce6` (`src/engine/level/camera.asm`,
`update_level.asm`, `scroll.asm` `Func_8ed9`, `start_room.asm`
`SetInitialCameraScroll` and `ApplyInitialCameraScroll`, `src/home/load_room.asm`,
`level_vblank.asm`, `load_wario_gfx.asm`); oracle Wario traces of the owner's
movie and the walk capture ([emulator oracle](emulator-oracle.md), item 16).
Task: WL3-036.

## Verified observations

1. **Where it runs.** `UpdateLevel` moves the camera after Wario, objects,
   interactions, and drawing, by the room's `wCameraConfigFlags`:
   - transitions rooms (`CAM_TRANSITIONS` set): `LevelScroll_Horizontal`
     only, unless a floor transition is under way, which slides the camera
     4 px a frame (`wFloorTransitionTimer`) and runs `LevelScroll_Vertical`;
     the slide waits while a Wario graphics transfer is pending;
   - free rooms (`CAM_FREE`): both directions every frame;
   - Y-scroll rooms (`CAM_YSCROLL`): vertical only, without the floor
     transition check before Wario's update.
2. **What it follows.** Wario's moves add to `wCameraXDelta`/`wCameraYDelta`.
   The camera scrolls by the delta plus or minus one towards the spacing
   (`wCamRightSpacing`/`wCamLeftSpacing`, `$58` from `LoadRoom`) measured
   against Wario's screen position (`SetWarioScreenPos`, computed from the
   previous frame's scroll). When the delta is 0, it waits one frame and then
   drifts 1 px a frame towards the spacing. `ScrollCamera*` clamp it at the
   room's section limits, with `$20` more kept in view on a bordered side,
   and report the edge in `wScroll*Edge`.
3. **Room start.** `LoadRoom` sets the spacings, `wPrevWarioScreenYPos`
   (`$70`), and the limits; `SetInitialCameraScroll` places the camera by
   the spacing and caps it at the limits; `ApplyInitialCameraScroll`
   settles a capped camera on the edge. For level 0 this gives (0, 616).
4. **Edges.** Each scroll sets a `wLevelEdgeUpdateFlags` bit; after the
   camera, `Func_8ed9` draws one new column (right before left) and one new
   row (up before down) a frame, spawns their objects, and clears those
   bits.
5. **Parity** (`make wario-parity`, `game/scripts/sim/wario/level_sim.gd`):
   - every camera run of the owner's movie, 5802 of them in four modes
     (`$18`, `$21`, `$28`, `$38`), loaded from the oracle's variables
     before it and compared after it on 15 variables: all identical;
   - the native level start with its camera equals the oracle's before
     the first update on 54 variables (Wario's 39 and the camera's 15);
   - run alone over whole frames (Wario's update, the camera, the edge
     flags), the port matches the walk capture on all 300 frames, and the
     owner's movie until the first attack (frame 193, not ported);
   - from level 0's own start, `make smoke-level` matches the oracle's
     Wario and camera positions on all 300 walk frames.
6. **The Hidden Figure camera** (`HIDDEN_FIGURE_CAMCONFIG`, `$3c`, the
   Temple's fight, WL3-048). The camera does not follow Wario: the room
   start keeps the initial scroll in `wc08a` and `wHiddenFigureSCYShake`
   (y) and `wc08c` and `wc08b` (x); each frame `wSCY` is the shake plus
   `wSCYShake` and `wSCX` is `wc08b`, and each Temple object's update puts
   them back after it; Wario's screen position is taken from `wc08a` plus
   `wSCYShake` and `wc08c`; `LevelScroll_Horizontal` and `.asm_8229` (the
   edges, `Func_8ed9`) are skipped, its `.asm_8227` going straight to
   `.check_end_screen` (the tracer hooks it to end the frame's camera
   run). `map-temple-fight-invented`: all 442 camera runs and the level
   start identical, and 442 whole frames run natively.

## Interpretation

- The camera is a deterministic function of Wario's movement and the
  room's header, so it belongs with the simulation, not the presentation;
  the window only draws from `wCameraSCX`/`wCameraSCY`.

## Hypotheses

- The ground-shake scroll offset (`wSCYShake`) is kept in RAM by the
  ground shake's port (`WarioSim`) but not drawn by the level window,
  except in the hidden figure's fight, which is drawn from VRAM with
  `LevelVBlankFunc`'s `rSCY` (`wSCY` plus `wSCYShake`; [the fight
  drawn](hidden-figure-drawing.md)).

## Unknowns

- Floor transitions have been compared in single camera runs of the movie,
  but not yet in a whole-frame run, because the movie's first attack stops
  the run first.
- Room transitions reset the camera through `StartRoom_FromTransition`
  (WL3-027).

## Tests

- `game/tests/unit/test_level_camera.gd`: edge clamps (with and without a
  border), the delta correction, the idle drift, initial capping, floor
  transition sliding and its DMA wait, and edge streaming order.
- `make wario-parity` (step and run) and `make smoke-level`, against oracle
  traces of the local ROM.

## Next experiment

Draw the room's tiles (WL3-018) at this camera, so a screenshot of the port
can be compared with the oracle's screen.
