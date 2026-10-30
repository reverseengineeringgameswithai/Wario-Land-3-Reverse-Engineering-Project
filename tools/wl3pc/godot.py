"""Drive the pinned Godot build: import, headless tests, smoke runs, Linux export, interactive run.

Godot can exit 0 after script errors, so every step also fails on
"SCRIPT ERROR", "Parse Error", or "ERROR:" lines in its output.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from .paths import CONTENT_OUT_DIR, DEFAULT_ROM, PROJECT_ROOT
from .provenance import ROM_DERIVED_MARKER
from .repo_check import contains_fragment, looks_like_gb_rom, rom_fragments
from .toolchain import godot_binary

GAME = PROJECT_ROOT / "game"
DIST = PROJECT_ROOT / "dist" / "linux"
EXECUTABLE = DIST / "wl3pc.x86_64"
GOLDEN = GAME / "tests" / "golden" / "walk-jump.synthetic.json"
ERROR_RE = re.compile(r"^(SCRIPT ERROR|ERROR:|Parse Error)", re.MULTILINE)
REQUIRED_IN_PACK = ("assets/content/synthetic/pack.json", "assets/traces/walk-jump.json", "res://scenes/main.tscn")
# Built by `make room-pack` from the local ROM (WL3-013); never bundled into an export.
EXTRACTED_PACK = CONTENT_OUT_DIR / "packs" / "wl3-level-00-room-001"


CAPTURES = PROJECT_ROOT / "local" / "captures"
ORIGINAL_CONTENT = CONTENT_OUT_DIR / "wl3-original"
PARITY_SCRIPT = "res://tests/parity/wario_parity.gd"


class StepFailed(RuntimeError):
    pass


def _godot() -> Path:
    binary = godot_binary()
    if not binary.exists():
        raise StepFailed(f"Godot not found at {binary}; run `make godot` or set GODOT")
    return binary


def run_godot(args: list[str], label: str, cwd: Path | None = None, timeout: int = 600,
              executable: Path | None = None) -> str:
    command = [str(executable or _godot()), *args]
    result = subprocess.run(command, cwd=cwd, capture_output=True, text=True, timeout=timeout, check=False)
    output = result.stdout + result.stderr
    log = PROJECT_ROOT / "build" / f"godot-{label}.log"
    log.parent.mkdir(parents=True, exist_ok=True)
    log.write_text(output)
    errors = ERROR_RE.findall(output)
    if result.returncode != 0 or errors:
        tail = "\n".join(output.strip().splitlines()[-15:])
        raise StepFailed(f"{label}: exit {result.returncode}, {len(errors)} error line(s); log {log}\n{tail}")
    return output


def selftest_result(output: str) -> dict:
    for line in output.splitlines():
        if line.startswith("WL3PC_SELFTEST "):
            return json.loads(line.split(" ", 1)[1])
    raise StepFailed("no WL3PC_SELFTEST line in output")


def compare_golden(result: dict, where: str) -> None:
    golden = json.loads(GOLDEN.read_text())
    for key in ("content_sha256", "state_stream_sha256", "final", "ticks"):
        if result[key] != golden[key]:
            raise StepFailed(f"{where}: {key} differs from {GOLDEN.relative_to(PROJECT_ROOT)}")


def do_import() -> None:
    run_godot(["--headless", "--path", str(GAME), "--import"], "import")
    print("godot import: OK")


def do_test() -> None:
    do_import()
    output = run_godot(["--headless", "--path", str(GAME), "-s", "res://tests/run_tests.gd"], "test")
    print("\n".join(l for l in output.splitlines() if l.startswith(("FAIL", "SKIP", "godot tests"))))


def do_smoke() -> None:
    do_import()
    result = selftest_result(run_godot(["--headless", "--path", str(GAME), "--", "--selftest"], "smoke"))
    compare_golden(result, "editor smoke")
    print(f"smoke: OK (synthetic trace, {result['ticks']} ticks, final x={result['final']['x']} y={result['final']['y']})")


def run_extracted(args: list[str], label: str, cwd: Path | None = None,
                  executable: Path | None = None) -> dict | None:
    """Selftest against the extracted pack through --content-dir; None (labelled SKIPPED) without one."""
    manifest = EXTRACTED_PACK / "pack.json"
    if not manifest.exists():
        print(f"{label}: SKIPPED (no extracted pack at {EXTRACTED_PACK}; run `make room-pack`)")
        return None
    result = selftest_result(run_godot([*args, "--", "--selftest", f"--content-dir={EXTRACTED_PACK}"],
                                       label, cwd=cwd, executable=executable))
    expected = [a["subject"] for a in json.loads(manifest.read_text())["approximations"]]
    if result["origin"] != "original-extracted" or result["approximations"] != expected:
        raise StepFailed(f"{label}: the runtime did not report the pack's origin and labelled approximations")
    return result


def do_smoke_extracted() -> None:
    do_import()
    result = run_extracted(["--headless", "--path", str(GAME)], "smoke-extracted")
    if result is not None:
        print(f"smoke-extracted: OK (pack {result['pack']}, {len(result['approximations'])} labelled "
              f"approximation(s), {result['ticks']} ticks, final x={result['final']['x']} y={result['final']['y']}; "
              "provisional physics, not parity evidence)")


def elf_machine(path: Path) -> str:
    header = path.read_bytes()[:20]
    if header[:4] != b"\x7fELF":
        raise StepFailed(f"{path} is not an ELF executable")
    machine = int.from_bytes(header[18:20], "little")
    return {0x3E: "x86_64", 0xB7: "aarch64"}.get(machine, hex(machine)) + ("" if header[4] == 2 else " (32-bit)")


def check_pack(pack: Path) -> None:
    data = pack.read_bytes()
    problems = []
    if ROM_DERIVED_MARKER.encode() in data:
        problems.append("contains ROM-derived content marker")
    if b"res://tests/" in data or b"tests/unit/" in data:
        problems.append("contains test files")
    if looks_like_gb_rom(data):
        problems.append("looks like a Game Boy ROM")
    if DEFAULT_ROM.exists() and contains_fragment(data, rom_fragments(DEFAULT_ROM.read_bytes())) is not None:
        problems.append("contains bytes copied from the local ROM")
    for required in REQUIRED_IN_PACK:
        if required.encode() not in data:
            problems.append(f"missing {required}")
    if problems:
        raise StepFailed(f"{pack}: " + "; ".join(problems))
    print(f"pack check: OK ({len(data)} bytes; no marker, test files, ROM image, or ROM fragments)")


def do_export() -> None:
    do_import()
    if DIST.exists():
        shutil.rmtree(DIST)
    DIST.mkdir(parents=True)
    run_godot(["--headless", "--path", str(GAME), "--export-release", "Linux", str(EXECUTABLE)], "export")
    pack = EXECUTABLE.with_suffix(".pck")
    if not EXECUTABLE.exists() or not pack.exists():
        raise StepFailed(f"export did not produce {EXECUTABLE.name} and {pack.name}")
    print(f"exported {EXECUTABLE.relative_to(PROJECT_ROOT)} ({elf_machine(EXECUTABLE)}) + {pack.name}")
    check_pack(pack)
    with tempfile.TemporaryDirectory(prefix="wl3pc-export-") as temp:
        sandbox = Path(temp)
        for item in (EXECUTABLE, pack):
            shutil.copy2(item, sandbox / item.name)
        exe = sandbox / EXECUTABLE.name
        bundled = selftest_result(run_godot(["--headless", "--", "--selftest"], "export-run", cwd=sandbox, executable=exe))
        compare_golden(bundled, "exported build")
        external = selftest_result(run_godot(
            ["--headless", "--", "--selftest", f"--content-dir={GAME / 'assets/content/synthetic'}",
             f"--mods-dir={PROJECT_ROOT / 'mods/examples'}"], "export-run-mods", cwd=sandbox, executable=exe))
        if external["mods"] != ["low-gravity-ledge"]:
            raise StepFailed("exported build did not apply the example mod from the filesystem")
        extracted = run_extracted(["--headless"], "export-run-extracted", cwd=sandbox, executable=exe)
        level = do_smoke_level(executable=exe, cwd=sandbox, label="export-run-level")
    print(f"export run: OK outside the checkout ({sandbox}); bundled content matches golden; "
          "filesystem content + example mod loaded"
          + ("; extracted pack loaded from local/ with its labels" if extracted else "")
          + ("; extracted level 0 run by the ported Wario" if level else ""))


def do_run(mods: str | None, content: str | None = None, level: str | None = None, save: str | None = None) -> None:
    user_args = [f"--mods-dir={Path(mods).resolve()}"] if mods else []
    if content:
        user_args.append(f"--content-dir={Path(content).resolve()}")
    if level is not None:
        if not (ORIGINAL_CONTENT / "levels" / f"level-{int(level, 0):02x}.json").exists():
            raise StepFailed(f"no extracted level {level} in {ORIGINAL_CONTENT}; run `make extract`")
        user_args = [f"--original-dir={ORIGINAL_CONTENT}", f"--level={int(level, 0)}"]
    if save is not None:
        user_args = [f"--original-dir={ORIGINAL_CONTENT}", f"--save={save_file(save)}"]
    subprocess.run([str(_godot()), "--path", str(GAME), *(["--", *user_args] if user_args else [])], check=False)


WALK_TRACE = GAME / "assets" / "traces" / "walk-right-300.json"
# The oracle's walk capture stops at the solid block in column 6 of ROOM_001 (docs/02-research/emulator-oracle.md).
WALK_END = {"x": 88, "y": 752}


def do_smoke_level(executable: Path | None = None, cwd: Path | None = None, label: str = "smoke-level") -> dict | None:
    """The ported Wario from level 0's start under the walk input; None (labelled SKIPPED) without content."""
    if not (ORIGINAL_CONTENT / "levels" / "level-00.json").exists():
        print(f"{label}: SKIPPED (no extracted level in {ORIGINAL_CONTENT}; run `make extract`)")
        return None
    args = ["--headless"] if executable else ["--headless", "--path", str(GAME)]
    result = selftest_result(run_godot([*args, "--", "--selftest", f"--original-dir={ORIGINAL_CONTENT}", "--level=0",
                                        f"--trace={WALK_TRACE}"], label, cwd=cwd, executable=executable))
    final = result["final"]
    if result["unported_first_tick"]:
        raise StepFailed(f"{label}: the walk reached unported routines {result['unported_first_tick']}")
    if {"x": final["x"], "y": final["y"]} != WALK_END or final["state"] != 1:
        raise StepFailed(f"{label}: walk ended at {final}, the oracle stops at {WALK_END} walking")
    compared = "final position only"
    oracle = CAPTURES / "walk-right-300.wario.json"
    if oracle.exists():
        trace = json.loads(oracle.read_text())
        names = [v["name"] for v in trace["variables"]]
        columns = [names.index(name) for name in ("wWarioXPos", "wWarioYPos", "wCameraSCX", "wCameraSCY")]
        expected = [[frame[c] for c in columns] for frame in trace["frames"][1:]]
        if result["positions"] != expected:
            first = next(i for i, (a, b) in enumerate(zip(result["positions"], expected)) if a != b)
            raise StepFailed(f"{label}: tick {first}: native {result['positions'][first]}, oracle {expected[first]}")
        compared = f"all {len(expected)} Wario and camera positions equal the oracle Wario trace"
    print(f"{label}: OK (level 0 from its start, walk input: ends at ({final['x']}, {final['y']}) walking; {compared})")
    return result


def wario_trace_for(movie: Path) -> Path:
    """The oracle Wario trace of a movie (or the trace itself), as `make wario-trace` names it."""
    if movie.name.endswith(".wario.json"):
        return movie
    return CAPTURES / f"{movie.name.split('.')[0]}.wario.json"


# wState inside a level visit: playing, the clear screen, the pause menu, golf, Action Help (after
# a power-up's treasure), a key's pause (src/constants/state_constants.asm).
LEVEL_VISIT_STATES = (0x02, 0x03, 0x04, 0x05, 0x07, 0x08)
# The title and New Game's language selection: from a level only after a reset (Init, WL3-057).
TITLE_STATES = (0x00, 0x0E)


def level_visits(trace: dict) -> list[tuple[int, int, int]]:
    """Each visit to a level as (window start, window end, wLevel): from the end of the previous
    visit (or frame 0) to the first frame the game leaves the level (its clear screen included) for
    the map or anything else; a reset's title (the level's save resets the game) stays with the visit
    to the first frame out of it, so a run compares what the reset loaded. The window keeps the frames
    before the level for its start, and the last keeps those after it (the map and its save screen,
    checked with the visit)."""
    names = [variable["name"] for variable in trace["variables"]]
    state_at, level_at = names.index("wState"), names.index("wLevel")
    visits: list[tuple[int, int, int]] = []
    window_start, entered, level, reset = 0, None, 0, False
    for index, frame in enumerate(trace["frames"]):
        if reset:
            if frame[state_at] in TITLE_STATES:
                continue
            visits.append((window_start, index, level))
            window_start, reset = index, False
        if entered is None:
            if frame[state_at] == 0x02:
                entered, level = index, frame[level_at]
        elif frame[state_at] in TITLE_STATES:
            entered, reset = None, True
        elif frame[state_at] not in LEVEL_VISIT_STATES:
            visits.append((window_start, index, level))
            window_start, entered = index, None
    if entered is not None or reset:
        visits.append((window_start, len(trace["frames"]), level))
    elif visits:
        visits[-1] = (visits[-1][0], len(trace["frames"]), visits[-1][2])
    return visits


def do_wario_parity(movie: str | None, mode: str) -> None:
    """Compare the native Wario port with an oracle Wario trace (WL3-012); fails on any difference.
    A trace that visits levels more than once is checked a visit at a time, each with its level."""
    if not movie:
        raise StepFailed("usage: make wario-parity MOVIE=local/recordings/NAME.recording.json [MODE=run]")
    trace = wario_trace_for(Path(movie)).resolve()
    if not trace.exists():
        raise StepFailed(f"no Wario trace at {trace}; run `make wario-trace MOVIE={movie}` first")
    if not (ORIGINAL_CONTENT / "wario_movement.json").exists():
        raise StepFailed(f"no extracted movement tables in {ORIGINAL_CONTENT}; run `make extract`")
    visits = level_visits(json.loads(trace.read_text(encoding="utf-8")))
    if len(visits) <= 1:
        _wario_parity_window(trace, mode, None)
        return
    failed = []
    for number, (start, end, level) in enumerate(visits, 1):
        print(f"visit {number} of {len(visits)}: level ${level:02x}, frames {start}-{end - 1}")
        try:
            _wario_parity_window(trace, mode, (start, end))
        except StepFailed as error:
            print(f"  FAILED: {error}")
            failed.append(f"visit {number} (level ${level:02x}): {error}")
    if failed:
        raise StepFailed("; ".join(failed))


def save_file(save: str) -> Path | str:
    """A battery save named by its SHA-256 in the oracle's store, or a file; "none" for an empty cartridge
    RAM (a new game)."""
    if save == "none":
        return save
    path = (PROJECT_ROOT / "local" / "oracle" / "saves" / f"{save}.sav" if re.fullmatch(r"[0-9a-f]{64}", save)
            else Path(save).resolve())
    if not path.is_file() or path.stat().st_size != 0x8000:
        raise StepFailed(f"{save}: not a stored save's SHA-256 or a 32 KiB battery save")
    return path


def power_on_save(start: dict) -> str | None:
    """A power-on start's battery save for a run from power-on (WL3-055) and the step check's resets
    (Init loads it, WL3-057): the stored save's path, "" for an empty cartridge RAM, or None when the
    movie does not start at power-on."""
    if start.get("kind") != "power-on":
        return None
    ram = start.get("cartridge_ram", {})
    if ram.get("source") != "file":
        return ""
    path = PROJECT_ROOT / "local" / "oracle" / "saves" / f"{ram['sha256']}.sav"
    if not path.exists():
        raise StepFailed(f"the movie's save {ram['sha256'][:12]} is not in {path.parent}")
    return str(path)


def movie_loads(trace: Path) -> list[Path]:
    """The loads wl3pc.oracle_save captured during the trace's movie (`make save-load-check`, or the module
    with the movie's name), in order: power-on's, then each reset's (local/captures/save-load/NAME-loadN.json)."""
    name = trace.name.removesuffix(".wario.json")
    found = {int(path.stem.rsplit("-load", 1)[1]): path for path in SAVE_LOAD_CAPTURES.glob(f"{name}-load*.json")
             if path.stem.rsplit("-load", 1)[1].isdigit()}
    return [found[number] for number in sorted(found)]


def _wario_parity_window(trace: Path, mode: str, window: tuple[int, int] | None) -> None:
    """One run of the parity script (on the whole trace, or a window of it) and its report."""
    args = ["--headless", "--path", str(GAME), "-s", PARITY_SCRIPT, "--", f"--trace={trace}",
            f"--content-dir={ORIGINAL_CONTENT}", f"--mode={mode}"]
    if window is not None:
        args += [f"--from={window[0]}", f"--to={window[1]}"]
    save = power_on_save(json.loads(trace.read_text(encoding="utf-8")).get("start", {}))
    if save is not None and (window is None or window[0] == 0):
        args.append(f"--power-on-save={save}")
        loads = movie_loads(trace)
        if mode == "run" and loads:
            args.append(f"--loads={','.join(str(path) for path in loads)}")
    output = run_godot(args, "wario-parity")
    line = next((l for l in output.splitlines() if l.startswith("WARIO_PARITY ")), None)
    if line is None:
        raise StepFailed("the parity script printed no result")
    result = json.loads(line.removeprefix("WARIO_PARITY "))
    if "error" in result:
        raise StepFailed(result["error"])
    if result["mode"] == "run":
        what = "Wario, objects, interactions, and camera" if result.get("with_objects") else "Wario and camera"
        print(f"wario-parity run: {result['frames_compared']} whole frames ({what}) from frame "
              f"{result.get('start_frame')} matched; stopped: {result.get('stopped', 'a difference')}"
              + (f" at frame {result['stopped_at_frame']}" if "stopped_at_frame" in result else ""))
        from_map = result.get("from_map", {})
        if from_map.get("checked"):
            start = "from power-on" if from_map.get("power_on") else "from the map"
            print(f"  {start}: {from_map['loops']} screen loops matched ({from_map['by_screen']}), then"
                  f" {from_map.get('entry_loops', '?')} loops into the level; entered natively:"
                  f" {from_map.get('entered', False)}" + (f"; stopped: {from_map['stopped']} at frame"
                  f" {from_map['stopped_at_frame']}" if "stopped_at_frame" in from_map else ""))
            if from_map.get("diffs"):
                print(f"    {from_map['diffs']}")
        if result.get("diffs"):
            print(f"    {str(result['diffs'])[:1500]}")
        for number, differing, examples in result.get("loads", []):
            what = "power-on's" if number == 1 else f"reset {number - 1}'s"
            if differing < 0:
                print(f"  load {number} ({what}): not checked {examples}")
            else:
                print(f"  load {number} ({what}): SRAM {'equal to' if differing == 0 else f'{differing} bytes differ from'}"
                      f" the original's after ValidateSaveData" + (f": {examples}" if examples else ""))
        temple = result.get("temple", {})
        if temple.get("vram_checked") or temple.get("screens_checked"):
            print(f"  the fight's drawing: {temple['vram_matched']} of {temple['vram_checked']} VRAM snapshots match;"
                  f" {temple['screens_matched']} of {temple['screens_checked']} screens identical; the figure's"
                  f" SetBGPals calls as the original's in {temple['palette_calls_matched']} of"
                  f" {temple['palette_calls_checked']} frames")
            if temple.get("examples"):
                print(f"    first difference: {str(temple['examples'][0])[:1500]}")
        if result.get("within_level"):
            print(f"  within the level natively: {sum(result['within_level'].values())} screen loops matched"
                  f" ({result['within_level']})")
            if result.get("within_level_seeded"):
                print(f"    seeded when first seen: {result['within_level_seeded']}")
        screens = result.get("screens", {})
        if screens.get("checked"):
            then = "from power-on natively" if result.get("power_on") else "then natively"
            print(f"  {then}: {screens['loops']} screen loops matched ({screens['by_screen']}); stopped:"
                  f" {screens['stopped']}" + (f" at frame {screens['stopped_at_frame']} ({screens['screen']},"
                  f" {screens.get('differences', 0)} differences)" if "stopped_at_frame" in screens else ""))
            if screens.get("diffs"):
                print(f"    {screens['diffs']}")
            if screens.get("seeded"):
                print(f"    seeded when first seen: {screens['seeded']}")
            if screens.get("stopped") == "a difference":
                raise StepFailed(f"the screens after the level differ natively at frame {screens['stopped_at_frame']}")
        if result["mismatched"]:
            raise StepFailed(f"native differs at frame {result['stopped_at_frame']}: {result['diffs']}")
        if any(differing > 0 for _number, differing, _examples in result.get("loads", [])):
            raise StepFailed("a load's SRAM differs from the original's")
        if temple.get("examples"):
            raise StepFailed("the fight's drawing differs")
        return
    unported = sorted(result["unported"].items(), key=lambda item: -item[1])
    print(f"wario-parity: {result['matched']} of {result['matched'] + result['mismatched']} compared updates "
          f"match ({result['updates']} Wario updates in the trace)"
          + (f"; the original's {result['div_reads']} rDIV reads replayed" if result.get("div_reads") else ""))
    for state, counts in sorted(result["by_state"].items()):
        print(f"  state {state}: {counts['matched']} matched, {counts['mismatched']} differ, "
              f"{counts['unported']} reach an unported routine")
    print("  not compared: " + ", ".join(f"{name} ({count})" for name, count in unported[:12])
          + (f", and {len(unported) - 12} more" if len(unported) > 12 else ""))
    camera = result.get("camera", {})
    if camera.get("checked"):
        modes = ", ".join(f"{mode}: {c['matched']}" + (f" ({c['mismatched']} differ)" if c["mismatched"] else "")
                          for mode, c in sorted(camera["by_mode"].items()))
        print(f"  camera: {camera['matched']} of {camera['updates']} runs match (by wCameraConfigFlags {modes})")
        if camera["mismatched"]:
            raise StepFailed(f"{camera['mismatched']} camera runs differ")
    objects = result.get("objects", {})
    if objects.get("checked"):
        functions = sorted(objects["by_function"].items(), key=lambda item: -sum(item[1].values()))
        print(f"  objects: {objects['matched']} of {objects['matched'] + objects['mismatched']} ported slot updates match"
              f" over {objects['runs']} UpdateObjects runs")
        for key, counts in functions[:12]:
            print(f"    {key}: {counts['matched']} matched, {counts['mismatched']} differ, {counts['unported']} unported")
        if objects["mismatched"]:
            print(f"    first difference: {objects['examples'][0]}")
            raise StepFailed(f"{objects['mismatched']} object slot updates differ")
    interactions = result.get("interactions", {})
    if interactions.get("checked"):
        print(f"  interactions: {interactions['matched']} of {interactions['matched'] + interactions['mismatched']} ported"
              f" ProcessInteractions runs match, {interactions['matched_with_changes']} of them with an effect"
              f" ({interactions['with_changes']} of {interactions['runs']} runs had one in the original;"
              f" unported: {interactions['unported'] or 'none'})")
        if interactions["mismatched"]:
            print(f"    first difference: {interactions['examples'][0]}")
            raise StepFailed(f"{interactions['mismatched']} interaction runs differ")
    spawns = result.get("spawns", {})
    if spawns.get("checked"):
        print(f"  edge spawns: {spawns['matched']} of {spawns['runs']} frames' streamed edges leave the same slots"
              f" ({spawns['with_spawns']} with a new object in the original; {spawns['created_elsewhere']} transient"
              f" objects the next frame's own code created are set apart)")
        if spawns["mismatched"]:
            print(f"    first difference: {spawns['examples'][0]}")
            raise StepFailed(f"{spawns['mismatched']} frames' edge spawns differ")
    golf = result.get("golf", {})
    if golf.get("checked"):
        print(f"  golf: {golf['matched']} of {golf['matched'] + golf['mismatched']} compared game loops match"
              f" ({golf['loops']} in the trace; unported: {golf['unported'] or 'none'})")
        if golf["mismatched"]:
            print(f"    first difference: {golf['examples'][0]}")
            raise StepFailed(f"{golf['mismatched']} golf loops differ")
        vram, screens = golf.get("vram", {}), golf.get("screens", {})
        if vram.get("checked") or screens.get("checked"):
            print(f"  golf drawing: {vram.get('matched', 0)} of {vram.get('checked', 0)} VRAM snapshots match on the bytes"
                  f" golf wrote; {screens.get('matched', 0)} of {screens.get('checked', 0)} screens identical")
            if vram.get("examples") or screens.get("examples"):
                print(f"    first difference: {(vram.get('examples') or screens.get('examples'))[0]}")
                raise StepFailed("golf's drawing differs")
    clear = result.get("clear", {})
    if clear.get("checked"):
        exits = clear.get("exits", {})
        print(f"  clear screen: {clear['matched']} of {clear['matched'] + clear['mismatched']} compared game loops match"
              f" ({clear['loops']} in the trace; unported: {clear['unported'] or 'none'}); its way out:"
              f" {exits.get('matched', 0)} of {exits.get('checked', 0)}")
        if clear["mismatched"]:
            print(f"    first difference: {clear['examples'][0]}")
            raise StepFailed(f"{clear['mismatched']} clear screen loops differ")
        if exits.get("matched", 0) != exits.get("checked", 0):
            print(f"    first difference: {[r for r in exits['results'] if r['diffs']][0]}")
            raise StepFailed("the clear screen's way out differs")
        drawn = clear.get("drawn", {})
        if drawn.get("vram_checked") or drawn.get("screens_checked"):
            print(f"  clear screen drawing: {drawn['vram_matched']} of {drawn['vram_checked']} VRAM snapshots match on the"
                  f" bytes it wrote; {drawn['screens_matched']} of {drawn['screens_checked']} screens identical")
            if drawn.get("examples"):
                print(f"    first difference: {drawn['examples'][0]}")
                raise StepFailed("the clear screen's drawing differs")
    action_help = result.get("action_help", {})
    if action_help.get("checked"):
        exits = action_help.get("exits", {})
        print(f"  Action Help: {action_help['matched']} of {action_help['matched'] + action_help['mismatched']} compared"
              f" game loops match ({action_help['loops']} in the trace; unported: {action_help['unported'] or 'none'});"
              f" its way out: {exits.get('matched', 0)} of {exits.get('checked', 0)}")
        if action_help["mismatched"]:
            print(f"    first difference: {action_help['examples'][0]}")
            raise StepFailed(f"{action_help['mismatched']} Action Help loops differ")
        if exits.get("matched", 0) != exits.get("checked", 0):
            print(f"    first difference: {[r for r in exits['results'] if r['diffs']][0]}")
            raise StepFailed("Action Help's way out differs")
        drawn = action_help.get("drawn", {})
        if drawn.get("vram_checked") or drawn.get("screens_checked"):
            print(f"  Action Help drawing: {drawn['vram_matched']} of {drawn['vram_checked']} VRAM snapshots match on"
                  f" the bytes it wrote; {drawn['screens_matched']} of {drawn['screens_checked']} screens identical")
            if drawn.get("examples"):
                print(f"    first difference: {drawn['examples'][0]}")
                raise StepFailed("Action Help's drawing differs")
    pause_menu = result.get("pause_menu", {})
    if pause_menu.get("checked") and pause_menu["matched"] + pause_menu["mismatched"]:
        exits = pause_menu.get("exits", {})
        print(f"  pause menu and saves: {pause_menu['matched']} of {pause_menu['matched'] + pause_menu['mismatched']} compared"
              f" game loops match ({pause_menu['loops']} in the pause menu's table; unported:"
              f" {pause_menu['unported'] or 'none'}); its way out: {exits.get('matched', 0)} of {exits.get('checked', 0)}")
        if pause_menu["mismatched"]:
            print(f"    first difference: {pause_menu['examples'][0]}")
            raise StepFailed(f"{pause_menu['mismatched']} pause menu loops differ")
        if exits.get("matched", 0) != exits.get("checked", 0):
            print(f"    first difference: {[r for r in exits['results'] if r['diffs']][0]}")
            raise StepFailed("the pause menu's way out differs")
        drawn = pause_menu.get("drawn", {})
        if drawn.get("vram_checked") or drawn.get("screens_checked"):
            print(f"  save screen drawing: {drawn['vram_matched']} of {drawn['vram_checked']} VRAM snapshots match on"
                  f" the bytes it wrote; {drawn['screens_matched']} of {drawn['screens_checked']} screens identical")
            if drawn.get("examples"):
                print(f"    first difference: {drawn['examples'][0]}")
                raise StepFailed("the save screen's drawing differs")
    overworld = result.get("overworld", {})
    if overworld.get("checked") and overworld["matched"] + overworld["mismatched"]:
        exits = overworld.get("exits", {})
        print(f"  map: {overworld['matched']} of {overworld['matched'] + overworld['mismatched']} compared game loops"
              f" match ({overworld['loops']} in the trace; unported: {overworld['unported'] or 'none'}); its ways out:"
              f" {exits.get('matched', 0)} of {exits.get('checked', 0)}")
        if overworld["mismatched"]:
            print(f"    first difference: {overworld['examples'][0]}")
            raise StepFailed(f"{overworld['mismatched']} map loops differ")
        if exits.get("matched", 0) != exits.get("checked", 0):
            print(f"    first difference: {[r for r in exits['results'] if r['diffs']][0]}")
            raise StepFailed("the map's way out differs")
        drawn = overworld.get("drawn", {})
        if drawn.get("vram_checked") or drawn.get("screens_checked"):
            print(f"  map drawing: {drawn['vram_matched']} of {drawn['vram_checked']} VRAM snapshots match on the"
                  f" bytes it wrote; {drawn['screens_matched']} of {drawn['screens_checked']} screens identical")
            if drawn.get("examples"):
                print(f"    first difference: {drawn['examples'][0]}")
                raise StepFailed("the map's drawing differs")
    for key, what in (("title", "title"), ("language_selection", "language selection"),
                      ("golf_building", "golf building"), ("credits", "credits"),
                      ("game_over", "game over"), ("perfect", "Perfect screen")):
        screen = result.get(key, {})
        if not (screen.get("checked") and screen["matched"] + screen["mismatched"]):
            continue
        exits = screen.get("exits", {})
        print(f"  {what}: {screen['matched']} of {screen['matched'] + screen['mismatched']} compared game loops match"
              f" ({screen['loops']} in the trace; unported: {screen['unported'] or 'none'}); its ways out:"
              f" {exits.get('matched', 0)} of {exits.get('checked', 0)}")
        if screen["mismatched"]:
            print(f"    first difference: {screen['examples'][0]}")
            raise StepFailed(f"{screen['mismatched']} {what} loops differ")
        if exits.get("matched", 0) != exits.get("checked", 0):
            print(f"    first difference: {[r for r in exits['results'] if r['diffs']][0]}")
            raise StepFailed(f"the {what}'s way out differs")
        drawn = screen.get("drawn", {})
        if drawn.get("vram_checked") or drawn.get("screens_checked"):
            print(f"  {what} drawing: {drawn['vram_matched']} of {drawn['vram_checked']} VRAM snapshots match on the"
                  f" bytes it wrote; {drawn['screens_matched']} of {drawn['screens_checked']} screens identical")
            if drawn.get("examples"):
                print(f"    first difference: {drawn['examples'][0]}")
                raise StepFailed(f"the {what}'s drawing differs")
    transitions = result.get("transitions", {})
    if transitions.get("checked"):
        doors = sum(1 for r in transitions["results"] if r["door"])
        print(f"  room transitions: {transitions['matched']} of {transitions['checked']} match "
              f"({doors} through doors; same game loops and state at the next update)")
        for r in transitions["results"]:
            spawn = "identical" if not r["spawn_diffs"] else f"{len(r['spawn_diffs'])} bytes differ"
            after = "identical" if not r["object_diffs"] else f"{len(r['object_diffs'])} bytes differ"
            unported_note = f" (unported: {r['object_unported']})" if r["object_unported"] else ""
            print(f"    frame {r['frame']} to room-list entry {r['room'][1]}: {r['spawned']} objects spawned, {spawn};"
                  f" after the room start's updates, {after}{unported_note}")
        if transitions["matched"] != transitions["checked"]:
            bad = [r for r in transitions["results"]
                   if r["diffs"] or r["unported"] or r["loops"] != r["expected_loops"]]
            raise StepFailed(f"room transitions differ: {bad[:3]}")
    start = result.get("start", {})
    if not start.get("checked") and "resumed" in start.get("reason", ""):
        print(f"  level start: not checked ({start['reason']})")
    if start.get("checked"):
        print(f"  level start: {'identical' if not start['diffs'] else start['diffs']} "
              f"(native start against the oracle before its first update, frame {start['frame']})")
        if start.get("objects_checked"):
            spawn = "identical" if not start["spawn_diffs"] else f"differ: {dict(list(start['spawn_diffs'].items())[:8])}"
            after = "identical" if not start["object_diffs"] else f"differ: {dict(list(start['object_diffs'].items())[:8])}"
            unported_note = f"; unported: {start['object_unported']}" if start["object_unported"] else ""
            print(f"    its objects: {start['spawned']} spawned, {spawn}; after two updates, {after}{unported_note}")
    if result["mismatched"]:
        raise StepFailed(f"{result['mismatched']} updates differ; rerun the script with --out=FILE for examples")
    if start.get("checked") and (start["diffs"] or start["unported"]):
        raise StepFailed(f"the native level start differs: {start}")
    if start.get("objects_checked") and (start["spawn_diffs"] or (start["object_diffs"] and not start["object_unported"])):
        raise StepFailed("the native level start's objects differ")
    spawn_failures = [r for r in transitions.get("results", []) if r.get("spawn_diffs")]
    if spawn_failures:
        raise StepFailed(f"spawning differs after {len(spawn_failures)} transitions: {spawn_failures[0]['spawn_diffs']}")


SAVE_LOAD_CAPTURES = PROJECT_ROOT / "local" / "captures" / "save-load"


def do_save_load_parity() -> None:
    """The save's load at power-on (SaveLoad, WL3-055) against every capture wl3pc.oracle_save made."""
    if not any(SAVE_LOAD_CAPTURES.glob("*.json")):
        print(f"save-load-parity: SKIPPED (no captures in {SAVE_LOAD_CAPTURES}; run `make save-load-check`)")
        return
    output = run_godot(["--headless", "--path", str(GAME), "-s", "res://tests/parity/save_load_parity.gd", "--",
                        f"--captures={SAVE_LOAD_CAPTURES}"], "save-load-parity")
    line = next((l for l in output.splitlines() if l.startswith("SAVE_LOAD_PARITY ")), None)
    if line is None:
        raise StepFailed("the save load check printed no result")
    result = json.loads(line.removeprefix("SAVE_LOAD_PARITY "))
    print(f"save-load-parity: {result['matched']} of {result['captures']} loads equal the original's, byte for byte"
          " (WRAM0 but the stack and wROMBank, WRAMX banks 1 and 2, SRAM banks 0-3)")
    for name, check in sorted(result["results"].items()):
        if check.get("differences"):
            print(f"  {name}: {check['differences']} bytes differ: {check['examples'][:6]}")
    if result["matched"] != result["captures"]:
        raise StepFailed(f"{result['captures'] - result['matched']} loads differ")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="godot", description=__doc__.splitlines()[0])
    parser.add_argument("step", choices=["import", "test", "smoke", "smoke-extracted", "smoke-level", "export", "run",
                                         "wario-parity", "save-load-parity"])
    parser.add_argument("--level", help="`run`: play this extracted level (number) with the ported Wario")
    parser.add_argument("--save", help="`run`: start at power-on with this battery save (a file, a stored save's"
                                       " SHA-256, or none for a new game): the title, the map, the levels")
    parser.add_argument("--mods", help="mods directory for `run`")
    parser.add_argument("--content", help="content pack directory for `run` (default: the bundled synthetic pack)")
    parser.add_argument("--movie", help="`wario-parity`: a recording or trace with a Wario trace, or the trace")
    parser.add_argument("--mode", default="step", choices=["step", "run"], help="`wario-parity` mode")
    args = parser.parse_args(argv)
    try:
        {"import": do_import, "test": do_test, "smoke": do_smoke, "smoke-extracted": do_smoke_extracted,
         "smoke-level": do_smoke_level, "export": do_export,
         "wario-parity": lambda: do_wario_parity(args.movie, args.mode),
         "save-load-parity": do_save_load_parity}.get(
            args.step, lambda: do_run(args.mods, args.content, args.level, args.save))()
    except StepFailed as error:
        print(f"godot {args.step}: FAILED: {error}", file=sys.stderr)
        return 1
    except subprocess.TimeoutExpired as error:
        print(f"godot {args.step}: timed out after {error.timeout}s", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
