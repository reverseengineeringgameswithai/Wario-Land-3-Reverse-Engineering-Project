---
type: session
status: done
updated: 2026-10-01
tags: [session]
---
# 2026-10-01: M0 bootstrap and first extraction

## Outcomes

- Inputs inventoried and hashed; the ROM was identified as `wl3-world-en-ja`,
  and its hash was unchanged at the end of the session.
- Git repository initialised on `main`; ignore rules verified with
  `git check-ignore`; `repo-check` audits the index by content.
- References pinned: ElectroDeoxys `560fce6`, froggestspirit `29f1df6`,
  Nearoo `ecd96f3`, RGBDS `fb9fa60` (v1.0.0).
- Reference build: ElectroDeoxys + RGBDS v1.0.0 is byte-identical to the ROM.
- Toolchain: Godot 4.7.2 standard (official build, SHA-512 verified, self-contained
  in `local/`); the user's .NET build was left untouched.
- M1: block function tables decoded (89 tables, 138 handlers, all on labels).
- Native: synthetic testbed scene, integer prototype movement, data-only
  mods, headless tests, and a Linux export run outside the checkout.

## Tests

Observed passing on the host: `make test-python` (54 passed),
`make test-rom` (3 passed), `make test-godot` (19 passed, no script errors),
`make smoke`, `make content-check`, `make docs-check`, `make repo-check`,
`make refbuild` (byte-identical), `make extract` (unchanged on re-run), and
`make export-linux` (x86_64 ELF; pack check; run from a temporary directory
outside the checkout). The test runner was also shown to fail on a
deliberate assertion failure and on a parse error.

After the commits, `make verify-clean` passed on `84fa90e` in a temporary
clone with no ROM, `external/`, or `local/`, and left that clone's working
tree unchanged. Re-running the Godot import, tests, and smoke run in the main checkout
produced no tracked-file changes. The final ROM size, timestamp, MD5, SHA-1,
and SHA-256 equal the values taken before any work.

## Blockers and gaps

- The project license needs an owner decision (WL3-016).
- No desktop GUI or controller check was performed (WL3-021).
- No global Git identity exists. At the owner's request, the commits use a
  repo-local identity. The repository is local only: no remote, no push.

## Next action

WL3-010: decode the per-room records at `30:44c5`.
