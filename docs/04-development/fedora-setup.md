---
type: guide
status: active
updated: 2026-10-01
tags: [development, tooling]
---
# Fedora setup

Verified on Fedora Linux 44 Workstation, x86_64, kernel 7.0.11. Versions
are authoritative in `toolchain.lock.json` and `uv.lock`; this note explains
how to reproduce them.

## System packages

Present on the verified host; install any that are missing (needs root):

```sh
sudo dnf install git-core make python3 gcc-c++ bison libpng-devel pkgconf-pkg-config
sudo dnf install uv            # or a user-local uv; 0.11.23 was used
sudo dnf install java-25-openjdk-headless   # only to run the WL3 Editor jar
```

`gcc-c++`, `bison`, `libpng-devel`, and `pkgconf-pkg-config` are needed only to
build RGBDS for the reference build. Fedora's own `rgbds` package (0.9.0) is
too old for the disassembly (≥ 1.0.0), and Fedora's `godot` package
(4.7.2-1.fc44) is not used because installing it needs root. The pinned
upstream build is project-local instead.

## Project-local toolchain (no root)

```sh
cd ~/WL3PC
make venv          # .venv from uv.lock with /usr/bin/python3.14 (pytest, jsonschema)
make godot         # Godot 4.7.2 standard + Linux templates, SHA-512 verified, into local/toolchain
make references    # pinned checkouts into external/ (reference work only)
make rgbds         # RGBDS v1.0.0 from external/gbdev_rgbds into local/toolchain
make doctor        # confirm everything
```

Godot runs in **self-contained mode** (an `_sc_` file beside the binary), so
its editor settings and export templates live in
`local/toolchain/godot-4.7.2/editor_data/`, not `~/.local/share/godot`. The
`godot` command on `PATH` (`~/.local/bin/godot`, the 4.7.2 **.NET** build) is
left alone and is not used. Set `GODOT=/path/to/binary` to override the
pinned build deliberately.

To edit the project in the Godot editor:

```sh
local/toolchain/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --path game -e
```

## Open the vault in Obsidian

1. Start Obsidian (installed here as `~/.local/bin/obsidian`, version 1.13.6).
2. Choose **Open folder as vault** and select `~/WL3PC/docs`, not
   `~/WL3PC`.
3. Start at `00-home.md`. Core plugins only; templates are in `90-templates`
   (Templates core plugin), and new links are relative Markdown links.

Only `app.json`, `appearance.json`, `core-plugins.json`, and `templates.json`
under `docs/.obsidian/` are tracked; workspace layouts and plugin data are
ignored. Obsidian Sync and Publish are disabled in the shared config, and no Git plugin
is installed. Use command-line Git at the repository root.

## Status of graphical checks

The configuration files were validated by `make docs-check`. Opening the
vault in Obsidian, running `make run` in a desktop session, keyboard and
controller input, and window resizing have **not** been checked yet (WL3-021).
