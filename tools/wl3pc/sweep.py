"""Coverage sweeps: one scripted movie per level, compared with the native port (WL3-044, WL3-046).

A sweep takes a script (`oracle_levels.SCRIPTS`), an optional power-up level, and level variants
(day 1-4 are 0-3, night 1-4 are 4-7), and for each of the 25 levels (`wLevel` = level * 8 +
variant) records the movie and its Wario trace if they are missing (`make level-movie`,
`make wario-trace`, so the oracle's interpreter and the extraction are the usual ones), then runs
`wario_parity.gd` on the trace in step or run mode. With `distinct`, a level's variant whose room
list and block map are those of an earlier variant of the same time of day is left out (SelectLevel
picks 1-3 by treasures collected; most levels share some). With `rooms`, each level is instead
started in each of its other room-list entries that has a spawn (`make level-movie ROOM=…`; IDs
"LLrRR"). The results go to local/reviews/sweeps/NAME-vVARIANTS[-rooms]-MODE/ (one JSON per level
and a summary); the summary is printed, and the sweep fails when anything compared differs.
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import Any, Callable

from .extract import level_headers, level_maps
from .extract.block_functions import MalformedDataError
from .godot import CAPTURES, GAME, ORIGINAL_CONTENT, PARITY_SCRIPT, StepFailed, run_godot
from .paths import PROJECT_ROOT, rom_path_from_env
from .rom import inspect_bytes, read_rom, require_known

NUM_LEVELS = 25
RECORDINGS = PROJECT_ROOT / "local" / "recordings"
SWEEPS = PROJECT_ROOT / "local" / "reviews" / "sweeps"


DEFAULT_TICKS = 1200  # `make level-movie`'s length, left out of the movies' names


def sweep_name(script: str, power_up: int | None, ticks: int = DEFAULT_TICKS) -> str:
    """The movies' suffix, as `make level-movie` names them."""
    name = script if power_up is None else f"{script}-pu{power_up}"
    return name if ticks == DEFAULT_TICKS else f"{name}-t{ticks}"


def level_ids(variant: int) -> list[str]:
    if not 0 <= variant < 8:
        raise ValueError(f"variant {variant} is not one of 0-7")
    return [f"{level * 8 + variant:02x}" for level in range(NUM_LEVELS)]


def parse_variants(text: str) -> list[int]:
    """"4" or "1,2,3": the variants in order, each 0-7."""
    variants = [int(part) for part in text.split(",")]
    for variant in variants:
        level_ids(variant)
    return variants


def distinct_level_ids(variants: list[int], key: Callable[[int], Any]) -> list[str]:
    """level_ids over `variants`, without a wLevel whose `key` (its level data) is that of an earlier
    variant of the same time of day (0-3 by day, 4-7 by night)."""
    ids = []
    for variant in variants:
        for level in range(NUM_LEVELS):
            this = key(level * 8 + variant)
            if any(key(level * 8 + earlier) == this for earlier in range(variant & ~3, variant)):
                continue
            ids.append(f"{level * 8 + variant:02x}")
    return ids


def room_ids(levels: list[str], rooms_of: Callable[[int], list[int]]) -> list[str]:
    """Each level's room starts other than entry 0, as "LLrRR" IDs."""
    return [f"{level}r{room:02x}" for level in levels for room in rooms_of(int(level, 16)) if room != 0]


def split_id(level_id: str) -> tuple[str, str | None]:
    """"00r05" -> ("00", "05"); "00" -> ("00", None)."""
    level, _, room = level_id.partition("r")
    return level, room or None


def level_rooms(rom: bytes) -> Callable[[int], list[int]]:
    """wLevel -> its room-list entries that have a spawn (SetWarioPositionToSpawn finds one), each
    header once (an entry repeating an earlier entry's header starts the same way)."""
    headers = level_headers.decode(rom)
    maps = level_maps.decode(rom)["maps"]
    fields_at = {header["location"]: header["fields"] for header in headers["headers"]}

    def rooms(level: int) -> list[int]:
        entry = headers["levels"][level]
        if entry["status"] != "decoded":
            return []
        room_list = next(item for item in headers["lists"] if item["location"] == entry["list"])
        level_map = next(m for m in maps if level in m["used_by_levels"])
        rows = [bytes.fromhex(row) for row in level_map["object_rows"]]
        found, seen = [], set()
        for index, location in enumerate(room_list["entries"]):
            if location is None or location in seen:
                continue
            seen.add(location)
            fields = fields_at[location]
            try:
                level_maps.find_spawn(rows, fields["spawn_x"], fields["spawn_y"])
            except MalformedDataError:
                continue
            found.append(index)
        return found
    return rooms


def level_data_key(rom: bytes) -> Callable[[int], Any]:
    """wLevel -> (its room list, its block map), decoded from the ROM."""
    report = inspect_bytes(rom, "rom")
    require_known(report, level_maps.WL3_WORLD_MAP_LAYOUT.rom_id)
    levels = level_headers.decode(rom)["levels"]
    maps = level_maps.decode(rom)["maps"]

    def key(level: int) -> Any:
        return (levels[level].get("list"),
                next((m["location"] for m in maps if level in m["used_by_levels"]), None))
    return key


def summarize(results: dict[str, dict[str, Any]]) -> dict[str, Any]:
    """Totals over the levels' parity results (step or run mode), and what was left unported."""
    summary: dict[str, Any] = {"levels": len(results), "mismatched_levels": []}
    unported: dict[str, dict[str, int]] = {"wario": {}, "objects": {}, "interactions": {}}

    def tally(kind: str, names: dict[str, int] | None) -> None:
        for name, count in (names or {}).items():
            unported[kind][name] = unported[kind].get(name, 0) + count

    if all(result.get("mode") == "run" for result in results.values()):
        summary["mode"] = "run"
        summary["to_the_end"] = sum(1 for r in results.values() if r.get("stopped") == "end of trace")
        summary["stopped"] = {level: f"{r.get('stopped')} (frame {r.get('stopped_at_frame')})"
                              for level, r in results.items() if r.get("stopped") != "end of trace"}
        summary["mismatched_levels"] = sorted(level for level, r in results.items() if r.get("mismatched"))
        # The screens after a level that ends, run on natively (WL3-052).
        screens = [r["screens"] for r in results.values() if r.get("screens", {}).get("checked")]
        summary["screens"] = {"checked": len(screens),
                              "to_the_end": sum(1 for s in screens if s.get("stopped") == "end of trace"),
                              "differ": sorted(level for level, r in results.items()
                                               if r.get("screens", {}).get("stopped") == "a difference")}
        return summary
    summary["mode"] = "step"
    totals = {"wario": [0, 0, 0], "objects": [0, 0], "interactions": [0, 0]}
    for level, result in sorted(results.items()):
        totals["wario"][0] += result.get("matched", 0)
        totals["wario"][1] += result.get("mismatched", 0)
        totals["wario"][2] += result.get("updates", 0)
        objects = result.get("objects", {})
        interactions = result.get("interactions", {})
        totals["objects"][0] += objects.get("matched", 0)
        totals["objects"][1] += objects.get("mismatched", 0)
        totals["interactions"][0] += interactions.get("matched", 0)
        totals["interactions"][1] += interactions.get("mismatched", 0)
        if result.get("mismatched") or objects.get("mismatched") or interactions.get("mismatched"):
            summary["mismatched_levels"].append(level)
        tally("wario", result.get("unported"))
        tally("objects", objects.get("unported"))
        tally("interactions", interactions.get("unported"))
    summary["wario"] = {"matched": totals["wario"][0], "mismatched": totals["wario"][1], "updates": totals["wario"][2]}
    summary["objects"] = {"matched": totals["objects"][0], "mismatched": totals["objects"][1]}
    summary["interactions"] = {"matched": totals["interactions"][0], "mismatched": totals["interactions"][1]}
    summary["unported"] = {kind: dict(sorted(names.items(), key=lambda item: -item[1]))
                           for kind, names in unported.items()}
    return summary


def _record(level_id: str, script: str, power_up: int | None, name: str, ticks: int = DEFAULT_TICKS) -> None:
    movie = RECORDINGS / f"level-{level_id}-{name}.recording.json"
    level, room = split_id(level_id)
    commands = []
    if not movie.exists():
        commands.append(["make", "-s", "level-movie", f"LEVEL=0x{level}", f"SCRIPT={script}"]
                        + ([] if power_up is None else [f"POWER_UP={power_up}"])
                        + ([] if room is None else [f"ROOM=0x{room}"])
                        + ([] if ticks == DEFAULT_TICKS else [f"TICKS={ticks}"]))
    commands.append(["make", "-s", "wario-trace", f"MOVIE={movie}"])
    for command in commands:
        result = subprocess.run(command, cwd=PROJECT_ROOT, capture_output=True, text=True, check=False)
        if result.returncode != 0:
            raise StepFailed(f"{' '.join(command)}: exit {result.returncode}\n{result.stderr[-500:]}")


# The regression sweeps run after every change (WL3-044 to WL3-049): script, power-up level, variants,
# distinct, rooms. Their 11,082 movies are named by sweep_name and the level IDs below.
REGRESSION: tuple[tuple[str, int | None, str, bool, bool], ...] = tuple(
    [(script, power_up, variants, distinct, rooms)
     for script, power_up in (("wander", None), ("right-jump", None), ("right-attack", None),
                              ("right-crouch", None), ("wander", 9), ("right-attack", 9))
     for variants, distinct, rooms in (("0", False, False), ("4", False, False), ("1,2,3,5,6,7", True, False),
                                       ("0", False, True))]
    + [("left-jump", None, "0", False, True), ("left-attack", None, "0", False, True),
       ("wander", None, "4", False, True), ("right-attack", None, "4", False, True),
       ("wander", None, "1,2,3,5,6,7", True, True), ("right-attack", None, "1,2,3,5,6,7", True, True),
       ("right-jump", None, "1,2,3,5,6,7", True, True), ("left-jump", None, "4", False, True),
       ("wander", 9, "4", False, True), ("wander", 9, "1,2,3,5,6,7", True, True)])
DEFAULT_CHUNK = 6  # movies a Godot process checks in turn (both modes each)
SNAPSHOTS = PROJECT_ROOT / "build" / "snapshots"
BATCHES = PROJECT_ROOT / "build" / "sweep-batches"


def sweep_dir(name: str, variants: list[int], rooms: bool, mode: str) -> Path:
    return SWEEPS / f"{name}-v{''.join(map(str, variants))}{'-rooms' if rooms else ''}-{mode}"


def sweep_levels(variants: list[int], distinct: bool, rooms: bool, rom: bytes) -> list[str]:
    levels = (distinct_level_ids(variants, level_data_key(rom)) if distinct
              else [level for variant in variants for level in level_ids(variant)])
    return room_ids(levels, level_rooms(rom)) if rooms else levels


def _parity_batch(checks: list[dict[str, str]], game: Path, content: Path) -> dict[str, dict[str, Any]]:
    """Several checks ({"id", "trace", "mode"}) in one Godot process (wario_parity.gd --batch): the
    process starts once instead of once a check. Returns each check's result by its id."""
    BATCHES.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", suffix=".json", dir=BATCHES, delete=False) as handle:
        json.dump(checks, handle)
        batch = Path(handle.name)
    try:
        output = run_godot(["--headless", "--path", str(game), "-s", PARITY_SCRIPT, "--", f"--batch={batch}",
                            f"--content-dir={content}"], "sweep", timeout=1800 * len(checks))
    finally:
        batch.unlink(missing_ok=True)
    results: dict[str, dict[str, Any]] = {}
    for line in output.splitlines():
        if line.startswith("WARIO_PARITY_JOB "):
            _, check, payload = line.split(" ", 2)
            results[check] = json.loads(payload)
    missing = [check["id"] for check in checks if check["id"] not in results]
    if missing:
        raise StepFailed(f"the parity script printed no result for {', '.join(missing)}")
    return results


def run_sweeps(specs: list[tuple[str, int | None, list[int], bool, bool]], modes: list[str], jobs: int = 1,
               record: bool = False, levels: list[str] | None = None, ticks: int = DEFAULT_TICKS,
               chunk: int = DEFAULT_CHUNK, game: Path = GAME, content: Path = ORIGINAL_CONTENT,
               progress: bool = True) -> list[dict[str, dict[str, Any]]]:
    """The sweeps `specs` (script, power-up, variants, distinct, rooms) in `modes`, their movies in one
    pool: the longest traces first, `chunk` movies a Godot process, each movie checked in every mode by
    the same process, `jobs` processes at once. Each sweep's results and summary are written as one
    sweep alone writes them. Returns each sweep's summaries by mode."""
    rom = read_rom(rom_path_from_env()) if any(distinct or rooms for _, _, _, distinct, rooms in specs) else b""
    tasks: list[tuple[int, str, Path]] = []  # (sweep, level, trace)
    for index, (script, power_up, variants, distinct, rooms) in enumerate(specs):
        name = sweep_name(script, power_up, ticks)
        for mode in modes:
            sweep_dir(name, variants, rooms, mode).mkdir(parents=True, exist_ok=True)
        for level in levels if levels is not None else sweep_levels(variants, distinct, rooms, rom):
            trace = CAPTURES / f"level-{level}-{name}.wario.json"
            if not trace.exists():
                if not record:
                    print(f"  {name} level {level}: no trace (SKIPPED; RECORD=1 records it)", flush=True)
                    continue
                _record(level, script, power_up, name, ticks)
            tasks.append((index, level, trace.resolve()))
    tasks.sort(key=lambda task: -task[2].stat().st_size)
    results: list[dict[str, dict[str, dict[str, Any]]]] = [{mode: {} for mode in modes} for _ in specs]

    def one(group: list[tuple[int, str, Path]]) -> None:
        checks = [{"id": f"{n}:{mode}", "trace": str(trace), "mode": mode}
                  for n, (_, _, trace) in enumerate(group) for mode in modes]
        found = _parity_batch(checks, game, content)
        for n, (index, level, _) in enumerate(group):
            script, power_up, variants, _, rooms = specs[index]
            for mode in modes:
                result = found[f"{n}:{mode}"]
                out = sweep_dir(sweep_name(script, power_up, ticks), variants, rooms, mode)
                (out / f"level-{level}.json").write_text(json.dumps(result, indent=1, sort_keys=True) + "\n")
                results[index][mode][level] = result
        if progress:
            print(f"  {len(group)} movies checked ({', '.join(level for _, level, _ in group)})", flush=True)

    groups = [tasks[at:at + max(1, chunk)] for at in range(0, len(tasks), max(1, chunk))]
    with ThreadPoolExecutor(max_workers=max(1, jobs)) as pool:
        for future in [pool.submit(one, group) for group in groups]:
            future.result()  # re-raise a failed step
    summaries: list[dict[str, dict[str, Any]]] = []
    for index, (script, power_up, variants, distinct, rooms) in enumerate(specs):
        by_mode: dict[str, dict[str, Any]] = {}
        for mode in modes:
            summary = summarize(results[index][mode])
            summary.update({"script": script, "power_up": power_up, "variants": variants, "distinct": distinct,
                            "rooms": rooms, "ticks": ticks})
            out = sweep_dir(sweep_name(script, power_up, ticks), variants, rooms, mode)
            (out / "summary.json").write_text(json.dumps(summary, indent=1, sort_keys=True) + "\n")
            by_mode[mode] = summary
        summaries.append(by_mode)
    return summaries


def run_sweep(script: str, power_up: int | None, variants: list[int], mode: str, record: bool,
              levels: list[str] | None = None, distinct: bool = False, rooms: bool = False,
              jobs: int = 1, ticks: int = DEFAULT_TICKS) -> dict[str, Any]:
    return run_sweeps([(script, power_up, variants, distinct, rooms)], [mode], jobs, record, levels, ticks)[0][mode]


def snapshot(label: str) -> tuple[Path, Path]:
    """game/ and the extracted content copied to build/snapshots/LABEL, so the sweeps check them as
    they are while game/ and the content change."""
    where = SNAPSHOTS / label
    if where.exists():
        shutil.rmtree(where)
    shutil.copytree(GAME, where / "game", symlinks=True)
    shutil.copytree(ORIGINAL_CONTENT, where / "content", symlinks=True)
    return where / "game", where / "content"


def snapshot_label() -> str:
    """The commit (and "-dirty" when game/ or the tools have uncommitted changes)."""
    head = subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=PROJECT_ROOT, capture_output=True, text=True,
                          check=False).stdout.strip() or "unknown"
    dirty = subprocess.run(["git", "status", "--porcelain", "--", "game", "tools"], cwd=PROJECT_ROOT,
                           capture_output=True, text=True, check=False).stdout.strip()
    return head + ("-dirty" if dirty else "")


def regression_report(summaries: list[dict[str, dict[str, Any]]]) -> tuple[list[str], bool]:
    """Totals over the regression sweeps, as lines, and whether anything differed."""
    lines: list[str] = []
    failed = False
    modes = summaries[0].keys() if summaries else []
    for mode in modes:
        movies = sum(s[mode]["levels"] for s in summaries)
        mismatched = [(f"{s[mode]['script']}{'' if s[mode]['power_up'] is None else '-pu' + str(s[mode]['power_up'])}"
                       f" v{''.join(map(str, s[mode]['variants']))}{' rooms' if s[mode]['rooms'] else ''}",
                       s[mode]["mismatched_levels"]) for s in summaries if s[mode]["mismatched_levels"]]
        failed = failed or bool(mismatched)
        if mode == "run":
            ended = sum(s[mode]["to_the_end"] for s in summaries)
            differ = [level for s in summaries for level in s[mode].get("screens", {}).get("differ", [])]
            failed = failed or bool(differ)
            lines.append(f"run: {len(summaries)} sweeps, {movies} movies, {ended} to the end; screens after a level"
                         f" differ in {len(differ)}; mismatched: {mismatched or 'none'}")
        else:
            wario = [sum(s[mode]["wario"][k] for s in summaries) for k in ("matched", "mismatched")]
            objects = [sum(s[mode]["objects"][k] for s in summaries) for k in ("matched", "mismatched")]
            interactions = [sum(s[mode]["interactions"][k] for s in summaries) for k in ("matched", "mismatched")]
            unported = sum(sum(names.values()) for s in summaries for names in s[mode]["unported"].values())
            lines.append(f"step: {len(summaries)} sweeps, {movies} movies; Wario {wario[0]:,} matched, {wario[1]} differ;"
                         f" objects {objects[0]:,}, {objects[1]}; interactions {interactions[0]:,}, {interactions[1]};"
                         f" unported {unported}; mismatched: {mismatched or 'none'}")
    return lines, failed


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--script", help="one sweep's script (or --all)")
    parser.add_argument("--all", action="store_true", help="the regression sweeps (REGRESSION), in one pool")
    parser.add_argument("--power-up", type=int, default=None)
    parser.add_argument("--variant", type=parse_variants, default=[0],
                        help="0-3 days 1-4, 4-7 nights 1-4; several as 1,2,3")
    parser.add_argument("--distinct", action="store_true",
                        help="leave out a variant whose level data is an earlier variant's")
    parser.add_argument("--jobs", type=int, default=1, help="Godot processes at once")
    parser.add_argument("--chunk", type=int, default=DEFAULT_CHUNK, help="movies a Godot process checks in turn")
    parser.add_argument("--rooms", action="store_true",
                        help="start each level in each of its other room-list entries with a spawn")
    parser.add_argument("--mode", default="step", choices=["step", "run"])
    parser.add_argument("--modes", default="step,run", help="--all: the modes, each movie checked in all by one process")
    parser.add_argument("--snapshot", action="store_true",
                        help="check a copy of game/ and the content (build/snapshots/COMMIT), so they can change meanwhile")
    parser.add_argument("--record", action="store_true", help="record missing movies and traces")
    parser.add_argument("--levels", default=None, help="comma-separated wLevel values in hex (default: all 25)")
    parser.add_argument("--ticks", type=int, default=DEFAULT_TICKS, help="the movies' length (other than 1200: -tN)")
    args = parser.parse_args(argv)
    if args.all == bool(args.script):
        parser.error("give --script or --all")
    game, content = GAME, ORIGINAL_CONTENT
    if args.snapshot:
        label = snapshot_label()
        game, content = snapshot(label)
        print(f"sweep: checking the snapshot build/snapshots/{label}", flush=True)
    try:
        if args.all:
            modes = [mode for mode in args.modes.split(",") if mode]
            specs = [(script, power_up, parse_variants(variants), distinct, rooms)
                     for script, power_up, variants, distinct, rooms in REGRESSION]
            summaries = run_sweeps(specs, modes, args.jobs, chunk=args.chunk, game=game, content=content,
                                   progress=False)
            lines, failed = regression_report(summaries)
            print("\n".join(lines))
            return 1 if failed else 0
        summary = run_sweeps([(args.script, args.power_up, args.variant, args.distinct, args.rooms)], [args.mode],
                             args.jobs, args.record, args.levels.split(",") if args.levels else None, args.ticks,
                             args.chunk, game, content)[0][args.mode]
    except (StepFailed, ValueError) as error:
        print(f"sweep: {error}", file=sys.stderr)
        return 1
    print(json.dumps(summary, indent=1, sort_keys=True))
    if summary["mismatched_levels"]:
        print(f"sweep: DIFFERENCES on levels {', '.join(summary['mismatched_levels'])}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
