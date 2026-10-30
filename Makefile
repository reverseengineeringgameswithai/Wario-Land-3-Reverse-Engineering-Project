# WL3PC command interface. Each target runs a readable script under tools/.
# Details: docs/04-development/workflow.md

SHELL := /bin/bash
.DEFAULT_GOAL := help

ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
PY ?= $(if $(wildcard $(ROOT)/.venv/bin/python),$(ROOT)/.venv/bin/python,python3)
RUN := PYTHONPATH=$(ROOT)/tools $(PY) -m
MODS ?=
SYMBOLS := $(ROOT)/build/refbuild/electrodeoxys-560fce6/warioland3.sym
# The emulator oracle (WL3-014) runs in an interpreter that has the pinned PyBoy.
ORACLE_PY ?= /usr/bin/python3
ORACLE := PYTHONPATH=$(ROOT)/tools $(ORACLE_PY) -W ignore::UserWarning -m wl3pc.oracle
TRACE ?= $(ROOT)/game/assets/traces/walk-right-300.json
START ?= power-on
# Optional starts: SAVE=your 32 KiB battery save, BOOTROM=your boot ROM dump, STATE=sha256 or a PyBoy state file.
START_ARGS = --start "$(if $(STATE),state:$(STATE),$(START))" $(if $(SAVE),--save "$(SAVE)") $(if $(BOOTROM),--bootrom "$(BOOTROM)")

.PHONY: help venv doctor rom-info test test-python test-godot test-rom smoke smoke-extracted smoke-level content-check \
	docs-check repo-check run export-linux extract room-pack oracle-check oracle-verify oracle-record \
	oracle-replay tas tas-check starts-check state-check review probes wario-trace wario-parity sweeps save-load-check continue-movie screen-check sprite-check window-check refbuild references godot rgbds \
	install-hook verify-clean clean

help: ## List targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-14s %s\n", $$1, $$2}'

venv: ## Create .venv from uv.lock (pytest, jsonschema)
	uv sync --locked --python /usr/bin/python3.14

doctor: ## Report host, tools, pinned toolchain, references, inputs
	@$(RUN) wl3pc.doctor

rom-info: ## Inspect the ROM read-only (ROM=path to override)
	@$(RUN) wl3pc.rom_info $(ROM)

test: test-python test-godot ## ROM-free Python and Godot test suites

test-python: _need-venv ## ROM-free Python tests
	$(PY) -m pytest -m "not rom"

test-rom: _need-venv ## Optional tests against the local identified ROM
	$(PY) -m pytest -m rom -rs

test-godot: ## Headless Godot import + test runner (fails on script errors)
	@$(RUN) wl3pc.godot test

smoke: ## Headless main-scene selftest against the recorded synthetic snapshot
	@$(RUN) wl3pc.godot smoke

smoke-extracted: ## Headless selftest on the extracted first-room pack (labelled SKIPPED without it)
	@$(RUN) wl3pc.godot smoke-extracted

smoke-level: ## Headless run of the ported Wario on extracted level 0 under the walk input (labelled SKIPPED without it)
	@$(RUN) wl3pc.godot smoke-level

content-check: _need-venv ## Validate synthetic pack, traces, and example mods against schemas
	@$(RUN) wl3pc.content

docs-check: ## Check vault and root Markdown links, anchors, and note properties
	@$(RUN) wl3pc.docs_check

repo-check: ## Refuse protected inputs, ROM payloads, and generated files in the Git index
	@$(RUN) wl3pc.repo_check

run: ## Run the window: LEVEL=0 plays an extracted level with the ported Wario, SAVE=file.sav|sha256|none starts at power-on with a battery save or none (the title, the map, the levels); else the prototype (MODS=, CONTENT=)
	@$(RUN) wl3pc.godot run $(if $(MODS),--mods "$(MODS)") $(if $(CONTENT),--content "$(CONTENT)") $(if $(LEVEL),--level "$(LEVEL)") $(if $(SAVE),--save "$(SAVE)")

export-linux: ## Export dist/linux/wl3pc.x86_64, check the pack, run it outside the checkout
	@$(RUN) wl3pc.godot export

extract: ## Decode block tables, rooms, level headers and maps, Wario's movement tables and sprites, object framesets, golf's and the clear screen's data, the credits', the game over screen's, the Perfect screen's, the hidden figure's fight's, and level 0's collision and room graphics into local/content
	@$(RUN) wl3pc.extract.block_functions $(if $(wildcard $(SYMBOLS)),--symbols "$(SYMBOLS)")
	@$(RUN) wl3pc.extract.block_materials
	@$(RUN) wl3pc.extract.rooms $(if $(wildcard $(SYMBOLS)),--symbols "$(SYMBOLS)")
	@$(RUN) wl3pc.extract.level_headers $(if $(wildcard $(SYMBOLS)),--symbols "$(SYMBOLS)")
	@$(RUN) wl3pc.extract.level_maps $(if $(wildcard $(SYMBOLS)),--symbols "$(SYMBOLS)")
	@$(RUN) wl3pc.extract.wario_movement $(if $(wildcard $(SYMBOLS)),--symbols "$(SYMBOLS)")
	@$(RUN) wl3pc.extract.level_collision --level 0 $(if $(wildcard $(SYMBOLS)),--symbols "$(SYMBOLS)")
	@$(RUN) wl3pc.extract.room_gfx --level 0
	@$(RUN) wl3pc.extract.wario_sprites
	@$(RUN) wl3pc.extract.objects
	@$(RUN) wl3pc.extract.golf
	@$(RUN) wl3pc.extract.clear
	@$(RUN) wl3pc.extract.action_help
	@$(RUN) wl3pc.extract.pause_menu
	@$(RUN) wl3pc.extract.overworld
	@$(RUN) wl3pc.extract.title
	@$(RUN) wl3pc.extract.credits
	@$(RUN) wl3pc.extract.game_over
	@$(RUN) wl3pc.extract.perfect
	@$(RUN) wl3pc.extract.temple

room-pack: _need-venv ## Build the first room as an original-extracted pack in local/content/packs and validate it
	@$(RUN) wl3pc.extract.room_pack
	@$(RUN) wl3pc.content --pack "$(ROOT)/local/content/packs/wl3-level-00-room-001" --pack-only

oracle-check: ## Replay the tracked oracle route from power-on; require its end state and memory digest (ROM + PyBoy)
	@$(ORACLE) route-check

oracle-verify: ## Capture TRACE from the ootw-day1-start route twice in separate emulators; require identical results
	@$(ORACLE) verify --trace "$(TRACE)" $(if $(filter-out power-on,$(START))$(STATE)$(SAVE)$(BOOTROM),$(START_ARGS))

oracle-record: ## Play in a window, recording per-frame input to local/recordings/NAME (START=power-on or a route id)
	@test -n "$(NAME)" || { echo "usage: make oracle-record NAME=my-run [START=ootw-day1-start]"; exit 2; }
	@$(ORACLE) record "$(NAME)" $(START_ARGS)

oracle-replay: ## Replay FILE (a recording) headlessly and check every checkpoint
	@test -n "$(FILE)" || { echo "usage: make oracle-replay FILE=local/recordings/my-run.recording.json"; exit 2; }
	@$(ORACLE) replay "$(FILE)"

level-movie: ## Store LEVEL's start (wLevel = LEVEL, e.g. 0x10; POWER_UP=0-9 sets wPowerUpLevel) and record SCRIPT (idle, right, right-jump, left, left-jump, right-attack, left-attack, right-crouch, wander, wander-sN) for TICKS
	@test -n "$(LEVEL)" || { echo "usage: make level-movie LEVEL=0x10 [SCRIPT=right] [TICKS=1200] [POWER_UP=0-9]"; exit 2; }
	@$(ORACLE) level-movie --level "$(LEVEL)" --script "$(or $(SCRIPT),right)" --ticks "$(or $(TICKS),1200)" $(if $(POWER_UP),--power-up "$(POWER_UP)") $(if $(ROOM),--room "$(ROOM)")
	@$(RUN) wl3pc.extract.level_collision --level "$(LEVEL)" $(if $(wildcard $(SYMBOLS)),--symbols "$(SYMBOLS)")
	@$(RUN) wl3pc.extract.room_gfx --level "$(LEVEL)"

action-help-movie: ## Branch MOVIE at Action Help's start with POWER_UP_LEVEL (e.g. 0x85: garlic after a level's clear; TRANSFORMATION=owl|rail|vampire) and record SCRIPT (idle or browse) for TICKS under local/recordings/action-help/
	@test -n "$(MOVIE)" -a -n "$(POWER_UP_LEVEL)" || { echo "usage: make action-help-movie MOVIE=local/recordings/NAME.recording.json POWER_UP_LEVEL=0x81 [TRANSFORMATION=owl] [SCRIPT=idle|browse] [TICKS=2400]"; exit 2; }
	@$(ORACLE) action-help-movie --movie "$(MOVIE)" --power-up-level "$(POWER_UP_LEVEL)" $(if $(TRANSFORMATION),--transformation "$(TRANSFORMATION)") --script "$(or $(SCRIPT),idle)" --ticks "$(or $(TICKS),2400)"

tas: ## TAS editor on local/recordings/NAME; a new movie starts at START, or STATE=, SAVE=, BOOTROM=
	@test -n "$(NAME)" || { echo "usage: make tas NAME=my-run [START=power-on|ootw-day1-start] [STATE=sha256-or-file] [SAVE=file.sav] [BOOTROM=file]"; exit 2; }
	@$(ORACLE) tas "$(NAME)" $(START_ARGS)

tas-check: ## Check the TAS editor's seeking, editing, and saving against straight replays (ROM + PyBoy)
	@$(ORACLE) tas-check

starts-check: ## Check boot ROM files, battery saves, and save states as starts against straight replays
	@$(ORACLE) starts-check

review: ## Review MOVIE (a recording or trace): event timeline, contact sheets, probes, live map check
	@test -n "$(MOVIE)" || { echo "usage: make review MOVIE=local/recordings/my-run.recording.json [EVERY=30]"; exit 2; }
	@$(ORACLE) review "$(MOVIE)" --every "$(or $(EVERY),30)"

probes: ## Trace every collision probe of MOVIE through PyBoy hooks into local/captures/
	@test -n "$(MOVIE)" || { echo "usage: make probes MOVIE=local/recordings/my-run.recording.json"; exit 2; }
	@$(ORACLE) probes "$(MOVIE)"

screen-check: ## Compare MOVIE's background on screen at TICKS (comma list) with decoded room graphics
	@test -n "$(MOVIE)" -a -n "$(TICKS)" || { echo "usage: make screen-check MOVIE=local/recordings/my-run.recording.json TICKS=300,700"; exit 2; }
	@$(ORACLE) screen-check "$(MOVIE)" --ticks "$(TICKS)"

WINDOW_TICKS := 10,20,100,200,299
window-check: ## Compare the game window with the original's screen after TICKS of TRACE (default: the walk); opens windows
	@$(ORACLE) window-check "$(or $(TRACE),$(ROOT)/game/assets/traces/walk-right-300.json)" --ticks "$(or $(TICKS),$(WINDOW_TICKS))"

sprite-check: ## Check Wario's sprite on screen in MOVIE against his decoded graphics (WL3-038)
	@test -n "$(MOVIE)" || { echo "usage: make sprite-check MOVIE=local/recordings/my-run.recording.json"; exit 2; }
	@$(ORACLE) sprite-check "$(MOVIE)"

wario-trace: ## Record Wario's variables every frame of MOVIE into local/captures/ (WL3-012)
	@test -n "$(MOVIE)" || { echo "usage: make wario-trace MOVIE=local/recordings/my-run.recording.json"; exit 2; }
	@$(ORACLE) wario-trace "$(MOVIE)"

save-load-check: ## The save's load at power-on: capture it from each owner's movie's save (ROM + PyBoy) and check the port byte for byte
	@PYTHONPATH=$(ROOT)/tools $(ORACLE_PY) -W ignore::UserWarning -m wl3pc.oracle_save
	@$(RUN) wl3pc.godot save-load-parity

continue-movie: ## Record NAME: power on with SAVE (a stored save's SHA-256, or none), Continue at the title, then the map; PRESSES=200:a,700:a,900-2000:right and TICKS=n script it, ROUTE=id plays a power-on route first (ROM + PyBoy)
	@test -n "$(NAME)" -a -n "$(SAVE)$(ROUTE)" || { echo "usage: make continue-movie SAVE=sha256|none NAME=new-name [PRESSES=tick:buttons,first-last:buttons] [TICKS=n] [ROUTE=power-on route]"; exit 2; }
	@PYTHONPATH=$(ROOT)/tools $(ORACLE_PY) -W ignore::UserWarning -m wl3pc.oracle_save --continue-movie "$(NAME)" $(if $(SAVE),--save "$(SAVE)") $(if $(PRESSES),--presses "$(PRESSES)") $(if $(TICKS),--ticks "$(TICKS)") $(if $(ROUTE),--route "$(ROUTE)")

sweeps: ## The regression sweeps (11,082 movies) in one pool, step and run, longest first (JOBS=14; SNAPSHOT=1 checks a copy of game/ so work can go on)
	@$(RUN) wl3pc.sweep --all --jobs "$(or $(JOBS),14)" $(if $(SNAPSHOT),--snapshot) $(if $(MODES),--modes "$(MODES)") $(if $(CHUNK),--chunk "$(CHUNK)")

sweep: ## Parity over the 25 levels' SCRIPT movies (POWER_UP=0-9, VARIANT=0-7 day/night or 1,2,3, DISTINCT=1 skips repeated level data, ROOMS=1 starts in every other room, MODE=step|run, RECORD=1 records missing ones, JOBS=n at once, TICKS=n longer movies named -tN)
	@test -n "$(SCRIPT)" || { echo "usage: make sweep SCRIPT=wander [POWER_UP=9] [VARIANT=4|1,2,3] [DISTINCT=1] [MODE=run] [RECORD=1]"; exit 2; }
	@$(RUN) wl3pc.sweep --script "$(SCRIPT)" $(if $(POWER_UP),--power-up "$(POWER_UP)") --variant "$(or $(VARIANT),0)" --mode "$(or $(MODE),step)" $(if $(RECORD),--record) $(if $(LEVELS),--levels "$(LEVELS)") $(if $(DISTINCT),--distinct) $(if $(ROOMS),--rooms) $(if $(JOBS),--jobs "$(JOBS)") $(if $(TICKS),--ticks "$(TICKS)")

wario-parity: ## Check the native Wario port against MOVIE's Wario trace (make wario-trace first); MODE=run runs it alone
	@$(RUN) wl3pc.godot wario-parity --movie "$(MOVIE)" $(if $(MODE),--mode "$(MODE)")

state-check: ## Load stored state SHA and rebuild it from its recorded origin
	@test -n "$(SHA)" || { echo "usage: make state-check SHA=<sha256 of a stored state>"; exit 2; }
	@$(ORACLE) state-check "$(SHA)"

refbuild: ## Rebuild the pinned disassembly in build/refbuild and compare with the ROM
	@$(RUN) wl3pc.refbuild

references: ## Clone missing pinned reference checkouts into external/
	@$(RUN) wl3pc.references fetch

godot: ## Download, verify, and unpack the pinned Godot build into local/toolchain
	@$(RUN) wl3pc.toolchain godot

rgbds: ## Build the pinned RGBDS into local/toolchain (reference build only)
	@$(RUN) wl3pc.toolchain rgbds

install-hook: ## Install the optional pre-commit hook if no hook exists
	@hooks_path=$$(git config --get core.hooksPath); \
	if [ -n "$$hooks_path" ]; then echo "core.hooksPath is $$hooks_path; call tools/hooks/pre-commit from your hook there."; exit 1; fi; \
	hook=$$(git rev-parse --git-path hooks)/pre-commit; \
	if [ -e "$$hook" ]; then echo "$$hook already exists; not replacing it. Call tools/hooks/pre-commit from it."; exit 1; fi; \
	printf '#!/bin/sh\nexec "$$(git rev-parse --show-toplevel)/tools/hooks/pre-commit" "$$@"\n' > "$$hook"; \
	chmod +x "$$hook"; echo "installed $$hook"

verify-clean: ## Clone HEAD to a temp dir and run the ROM-free checks there
	@tools/verify_clean_checkout.sh

clean: ## Remove build/ and dist/ outputs (never local/ or external/)
	rm -rf $(ROOT)/build $(ROOT)/dist

_need-venv:
	@test -x $(ROOT)/.venv/bin/python || { echo "No .venv: run 'make venv' first."; exit 1; }
