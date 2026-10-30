# Agent rules for WL3PC

Canonical instructions for any coding agent working in this repository.
Project knowledge lives in the vault; start at [docs/00-home.md](docs/00-home.md).

## Boundaries

- `Original_ROM/` and `WL3 Editor/` are the user's inputs: never modify, move,
  rename, or track them. Read the ROM read-only; never run checksum fixers on
  it. Editor experiments and reference builds use ignored copies only.
- Never download ROMs, upload the ROM or extracted content, add a Git remote,
  push, publish, or use Git LFS. ROMs, ripped assets, captures, saves, and
  third-party binaries stay out of tracked history.
- Never change global Git config, invent an author identity, rewrite history,
  reset or stash someone else's work, or reset a modified `external/` checkout.
- System installs, `sudo`, and changes outside the project need the user's
  approval. Inspect downloaded build scripts before running them.
- Do not call the project clean-room: contributors have read the disassembly.
- Never write the owner's name, surname, personal email, or personal GitHub
  login anywhere: files, code, tests, comments, commit messages, or anything
  sent to GitHub. Refer to them as "the owner", and write paths repo-relative.

## Layout

| Path | Purpose |
| --- | --- |
| `tools/wl3pc/` | Python inspection, extraction, and checking (stdlib except tests) |
| `game/` | Godot 4.7.2 project: `scripts/sim` (state), `scripts/content` (loading), `scripts/present` (drawing), `tests/` |
| `schemas/` | Versioned JSON schemas for content, mods, traces, extracted data |
| `tests/` | Python tests and synthetic fixtures (no ROM bytes) |
| `mods/examples/` | Original, redistributable example mods |
| `docs/` | Obsidian vault and canonical documentation |
| `external/`, `local/`, `build/`, `dist/` | Ignored: reference checkouts, toolchain and extracted content, intermediates, exports |

Versions are authoritative in `toolchain.lock.json` and `references.lock.json`.

## Commands

`make doctor`, `make test` (ROM-free Python and Godot), `make smoke`,
`make docs-check`, `make repo-check`, `make export-linux`. Run `make help`
for all targets. Run `make repo-check` and inspect `git diff --cached`
before every commit.

## Evidence standards

- Separate verified observations, hypotheses, and unknowns. Cite the ROM
  SHA-256 or reference commit plus file and symbol, and record banked
  addresses (`BB:AAAA`) separately from file offsets.
- Editor tables and the Pygame remake are leads, not authority.
- Mark constants without original-game evidence as provisional. A screenshot
  that looks right does not validate movement, collision, or progression.
- Never report a command result, checksum, offset, or GUI check you did not
  observe. Label skipped tests as skipped.

## Git

Work on `main` or short topic branches. Stage explicit paths, make small
commits that include their tests and docs, and never use all-files commits.

## Session handoff

At the start: read this file, [docs/00-home.md](docs/00-home.md),
[current state](docs/01-project/current-state.md), relevant ADRs, and
`git status`/`git diff`. Pick one task from
[tasks.md](docs/01-project/tasks.md), implement and test it, update the
research note and [parity matrix](docs/05-validation/parity-matrix.md), and
leave a session note in `docs/06-sessions/` and an updated current state.
