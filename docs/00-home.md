---
type: home
status: active
updated: 2026-10-28
tags: [project]
---
# WL3PC home

WL3PC is a source-grounded native Linux port of Wario Land 3. Behaviour is
recovered from the user's identified ROM and a byte-identical disassembly
build, then reimplemented as host-side game logic in Godot. It is not an
emulator wrapper or a loose remake ([vision](01-project/vision.md)).

- **Active milestone:** M3, expanding systems. M2 (first real room) met its
  exit criteria on 2026-10-01 ([roadmap](01-project/roadmap.md)).
- **Latest handoff:** [current state](01-project/current-state.md)
- **Runnable today:** `make run LEVEL=0` plays Out of the Woods, day 1, from
  your extracted level data with the original's room graphics, the ported
  Wario (drawn from his original sprites), the camera, room transitions and
  doors, and the level's objects (drawn from their original graphics).
  Golf (its building too), the level's clear screen, Action Help, the map
  (with its top bar, the treasure collection, the best times, and the
  Temple), the hidden figure's fight, and the map's save screen are ported, and the window draws them from the
  original's graphics, the pause menu among them. The same code takes a level's play on through them into the
  map and from the map into the next level (checked in parity runs, see
  below). `make run SAVE=…` starts at power-on with a battery save, and
  `make run SAVE=none` a new game: the save's load, the title, the
  language selection, the prologue, the map, and the levels, all ported
  and drawn from the original's graphics. Unported routines are
  named on screen. The
  *synthetic prototype* and the room pack on prototype physics
  (`make run CONTENT=…`) remain as the pipeline testbed
  ([ADR-0002](03-architecture/adr-0002-labelled-approximations.md)).
- **Development oracle:** the original runs locally in PyBoy for
  comparison only; `make tas NAME=…` opens a TAS editor on it
  ([emulator oracle](02-research/emulator-oracle.md)).
- **Ported by translation:** Wario's states, the objects (bosses
  included), and the screens around a level are translated from the
  disassembly (`game/scripts/sim/`,
  [ADR-0003](03-architecture/adr-0003-wario-port-by-translation.md)). They
  match every compared update of the owner's 17 movies and of 34 scripted
  sweeps (11,082 movies; `make wario-parity`, `make sweep`;
  [parity matrix](05-validation/parity-matrix.md)). Each owner's movie
  also runs natively from its first map loop to its end, equal at every
  traced loop ([native play](02-research/native-play.md)), and power-on
  movies from a save run natively from power-on through the title, the
  map, and a level, with nothing taken from the trace before the level
  ([the title](02-research/title.md)), and on through the game's resets
  ([the resets](02-research/resets.md)).

## Next tasks

1. WL3-048: the owner's game movies, as the owner records more; the
   title's paths (a new game, a save, the resets, Time Attack's
   description) and the golf building all play natively from power-on
   (WL3-050, WL3-055 to WL3-058).
2. WL3-048 in detail: one movie per level visit; trace, check, and port
   what they reach (17 so far, all matching).
3. WL3-052 and WL3-050: the map's paths no movie reaches, golf's fades;
   WL3-021: a desktop check by the owner.

The full backlog is in [tasks](01-project/tasks.md).

## Navigate

- Research: [sources](02-research/sources.md) · [ROM identity](02-research/rom-identity.md) ·
  [editor reference audit](02-research/editor-reference-audit.md) ·
  [first investigation](02-research/first-investigation.md) ·
  [room records](02-research/room-records.md) ·
  [level headers](02-research/level-headers.md) ·
  [block handlers](02-research/block-handlers.md) ·
  [level block maps](02-research/level-block-maps.md) ·
  [first room pack](02-research/first-room-pack.md) ·
  [emulator oracle](02-research/emulator-oracle.md) ·
  [wario movement](02-research/wario-movement.md) ·
  [level camera](02-research/level-camera.md) ·
  [room graphics](02-research/room-graphics.md) ·
  [room transitions](02-research/room-transitions.md) ·
  [Wario's sprites](02-research/wario-sprites.md) ·
  [objects](02-research/objects.md) ·
  [native play across screens](02-research/native-play.md) ·
  [the pause menu](02-research/pause-menu.md) ·
  [the save's load](02-research/save-load.md) ·
  [the title](02-research/title.md) ·
  [the prologue](02-research/prologue.md) ·
  [the resets](02-research/resets.md) ·
  [the credits](02-research/credits.md) ·
  [the game over screen](02-research/game-over.md) ·
  [the Perfect screen](02-research/perfect.md) ·
  [the hidden figure's fight drawn](02-research/hidden-figure-drawing.md)
- Architecture: [overview](03-architecture/overview.md) ·
  [ADR-0001 native port strategy](03-architecture/adr-0001-native-port-strategy.md) ·
  [ADR-0002 labelled approximations](03-architecture/adr-0002-labelled-approximations.md) ·
  [ADR-0003 Wario port by translation](03-architecture/adr-0003-wario-port-by-translation.md) ·
  [ADR-0004 one RAM across screens](03-architecture/adr-0004-one-ram-across-screens.md)
- Development: [Fedora setup](04-development/fedora-setup.md) · [workflow](04-development/workflow.md)
- Validation: [strategy](05-validation/strategy.md) · [parity matrix](05-validation/parity-matrix.md)
- Sessions: [2026-10-01 M0 bootstrap](06-sessions/2026-10-01-m0-bootstrap.md) ·
  [2026-10-01 room records](06-sessions/2026-10-01-room-records.md) ·
  [2026-10-01 level headers](06-sessions/2026-10-01-level-headers.md) ·
  [2026-10-01 block handlers](06-sessions/2026-10-01-block-handlers.md) ·
  [2026-10-01 level block maps](06-sessions/2026-10-01-level-block-maps.md) ·
  [2026-10-01 first room pack](06-sessions/2026-10-01-first-room-pack.md) ·
  [2026-10-01 emulator oracle](06-sessions/2026-10-01-emulator-oracle.md) ·
  [2026-10-01 TAS editor](06-sessions/2026-10-01-tas-editor.md) ·
  [2026-10-01 oracle starts](06-sessions/2026-10-01-oracle-starts.md) ·
  [2026-10-01 oracle review](06-sessions/2026-10-01-oracle-review.md) ·
  [2026-10-01 Wario movement](06-sessions/2026-10-01-wario-movement.md) ·
  [2026-10-01 playable level](06-sessions/2026-10-01-playable-level.md) ·
  [2026-10-01 level camera](06-sessions/2026-10-01-level-camera.md) ·
  [2026-10-01 room graphics](06-sessions/2026-10-01-room-graphics.md) ·
  [2026-10-02 Wario states](06-sessions/2026-10-02-wario-states.md) ·
  [2026-10-12 map drawing](06-sessions/2026-10-12-map-drawing.md) ·
  [2026-10-12 native chain](06-sessions/2026-10-12-native-chain.md) ·
  [2026-10-12 pause menu](06-sessions/2026-10-12-pause-menu.md) ·
  [2026-10-12 faster sweeps](06-sessions/2026-10-12-faster-sweeps.md) ·
  [2026-10-12 save's load](06-sessions/2026-10-12-save-load.md) ·
  [2026-10-18 the title](06-sessions/2026-10-18-title.md) ·
  [2026-10-23 the golf building and the map's menus and Temple](06-sessions/2026-10-23-golf-building.md) ·
  [2026-10-28 the reset after an unsaved level](06-sessions/2026-10-28-reset-after-unsaved-level.md)
