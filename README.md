# WL3PC

Workspace for a faithful, source-understood native Linux port of Wario Land 3,
built from a locally owned ROM. Gameplay runs as host-side game logic in
Godot; the game itself never runs the original ROM (a local emulator is used
only as a development oracle), and no Nintendo content is tracked here.

**Status:** M2 (first real room) is complete and M3 is active. Level data
and room graphics are decoded from your ROM into ignored `local/content/`;
Wario's idling, walking, turning, jumping, and landing and the level camera
are ported and match the original update for update, and the background
matches its screen pixel for pixel. `make run LEVEL=0` plays Out of the
Woods with them (Wario is still drawn as a box).

## Start here

- [Vault home](docs/00-home.md): purpose, active milestone, next tasks
- [Current state](docs/01-project/current-state.md): latest handoff
- [Fedora setup](docs/04-development/fedora-setup.md) and [workflow](docs/04-development/workflow.md)
- [Licensing and provenance](LICENSES.md)
- [Agent rules](AGENTS.md)

## Common commands

```sh
make doctor        # host, tools, pinned toolchain, references, ROM identity
make venv          # Python dev environment from uv.lock
make test          # ROM-free Python + headless Godot tests
make run           # open the synthetic prototype (MODS=mods/examples to apply the example mod)
make export-linux  # standalone build in dist/linux, checked outside the checkout
make rom-info      # read-only ROM inspection
make extract       # decode original block tables, rooms, level headers, and block maps into ignored local/content
make room-pack     # build the first real room as a local pack (collision only, labelled approximations)
make run CONTENT=local/content/packs/wl3-level-00-room-001   # open it on the prototype physics
make run LEVEL=0   # play extracted level 0 with the ported Wario and camera (arrows, X = A, Z = B)
make tas NAME=my-run START=ootw-day1-start   # TAS editor on the original in a local emulator: record, seek, edit inputs
make tas NAME=late SAVE=~/my-wl3.sav         # or start from your own battery save, a save state (STATE=), or boot ROM (BOOTROM=)
```

Open `docs/` (not the repository root) as an Obsidian vault.
