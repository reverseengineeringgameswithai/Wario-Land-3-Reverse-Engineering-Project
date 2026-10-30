"""Editable input movie for the emulator oracle, in the style of a TAS editor.

The movie is one held-button set per frame. Frame `f` is the machine state after
`f` frames from the movie's start; `inputs[f]` is held while frame `f` runs.
Compressed save states every `interval` frames (the "greenzone") make seeking to
any frame cheap. An edit at frame `f` discards every state after `f`; if the
current frame was later than `f`, the session rewinds to `f` (an editor may
seek back afterwards), so what is shown always follows from the inputs.

Movies are saved as `wl3pc.oracle-recording` documents, so `oracle replay` and
captures accept them. Research note: docs/02-research/emulator-oracle.md.
"""

from __future__ import annotations

import json
import zlib
from io import BytesIO
from pathlib import Path
from typing import Any, Callable

from . import oracle

CHECKPOINT_EVERY = oracle.CHECKPOINT_EVERY
UNDO_LIMIT = 200
COUNTER = oracle.SAMPLE_ADDRESSES["wGlobalCounter"]


class TasSession:
    def __init__(
        self,
        rom: bytes,
        start: dict[str, Any],
        inputs: list[frozenset[str]] | None = None,
        interval: int = 10,
        open_emulator: Callable[[bytes, dict[str, Any]], Any] = oracle.start_from,
        digest: Callable[[Any], str] = oracle.ram_digest,
        *,
        markers: dict[int, str] | None = None,
    ) -> None:
        self.rom, self.start, self.interval, self.digest = rom, start, interval, digest
        self.pyboy = open_emulator(rom, start)
        self.inputs: list[frozenset[str]] = list(inputs or [])
        self.markers: dict[int, str] = dict(markers or {})  # frame -> label, shifted by inserts and deletes
        self.frame = 0
        # Unknown at the start (a save state may hold buttons): the first frame sets every button.
        self.held: frozenset[str] | None = None
        self.states: dict[int, tuple[bytes, frozenset[str] | None]] = {}
        self.counters: dict[int, int] = {0: self.pyboy.memory[COUNTER]}
        self.undo_stack: list[tuple[list[frozenset[str]], dict[int, str]]] = []
        self.dirty = False
        self._snapshot()

    # --- emulation ---------------------------------------------------------------

    def _snapshot(self) -> None:
        buffer = BytesIO()
        self.pyboy.save_state(buffer)
        self.states[self.frame] = (zlib.compress(buffer.getvalue(), 1), self.held)

    def _load(self, frame: int) -> None:
        data, held = self.states[frame]
        self.pyboy.load_state(BytesIO(zlib.decompress(data)))
        self.frame, self.held = frame, held

    def input_at(self, frame: int) -> frozenset[str]:
        return self.inputs[frame] if frame < len(self.inputs) else frozenset()

    def _step(self, render: bool) -> None:
        held = self.input_at(self.frame)
        oracle.apply_held(self.pyboy, self.held, held)
        self.held = held
        self.pyboy.tick(1, render)
        self.frame += 1
        self.counters[self.frame] = self.pyboy.memory[COUNTER]
        if self.frame % self.interval == 0 and self.frame not in self.states:
            self._snapshot()

    def advance(self, live: frozenset[str] | None = None, render: bool = True) -> None:
        """Run one frame. With `live`, the movie records it at the current frame first."""
        if live is not None:
            self._write(self.frame, live)
        self._step(render)

    def seek(self, frame: int) -> None:
        """Make `frame` current, emulating from the nearest earlier state (the target frame is rendered)."""
        frame = max(0, frame)
        if frame != self.frame:
            self._goto(frame, reuse_current=True)

    def _goto(self, frame: int, reuse_current: bool) -> None:
        # Restore strictly before the target when possible, so the last step renders the screen.
        nearest = max([k for k in self.states if k < frame] or [0])
        if not (reuse_current and nearest <= self.frame < frame):
            self._load(nearest)
        while self.frame < frame:
            self._step(render=self.frame == frame - 1)

    # --- editing -----------------------------------------------------------------

    def _invalidate(self, frame: int) -> None:
        """Input at `frame` changed: states and counters after it no longer follow from the inputs."""
        for k in [k for k in self.states if k > frame]:
            del self.states[k]
        for k in [k for k in self.counters if k > frame]:
            del self.counters[k]
        if self.frame > frame:
            self._goto(frame, reuse_current=False)
        self.dirty = True

    def _write(self, frame: int, held: frozenset[str]) -> None:
        if frame < len(self.inputs) and self.inputs[frame] == held:
            return
        while len(self.inputs) <= frame:
            self.inputs.append(frozenset())
        self.inputs[frame] = held
        self._invalidate(frame)

    def remember(self) -> None:
        """Save the inputs and markers for undo before a user edit (one call per gesture)."""
        self.undo_stack.append((list(self.inputs), dict(self.markers)))
        del self.undo_stack[:-UNDO_LIMIT]

    def undo(self) -> bool:
        if not self.undo_stack:
            return False
        previous, self.markers = self.undo_stack.pop()
        first = next((f for f in range(max(len(previous), len(self.inputs)))
                      if (previous[f] if f < len(previous) else None) != (self.inputs[f] if f < len(self.inputs) else None)),
                     None)
        self.inputs = previous
        if first is not None:
            self._invalidate(first)
        return True

    def set_input(self, frame: int, held: frozenset[str]) -> None:
        self._write(frame, frozenset(held))

    def toggle(self, frame: int, button: str) -> bool:
        """Flip one button at `frame`; returns its new state."""
        held = self.input_at(frame)
        pressed = button not in held
        self._write(frame, held | {button} if pressed else held - {button})
        return pressed

    def insert(self, frame: int, count: int = 1, inputs: list[frozenset[str]] | None = None) -> None:
        """Insert `count` empty frames (or the given inputs) before `frame`; later markers move with them."""
        if frame <= len(self.inputs):
            block = list(inputs) if inputs is not None else [frozenset()] * count
            self.inputs[frame:frame] = block
            self.markers = {(f + len(block) if f >= frame else f): label for f, label in self.markers.items()}
            self._invalidate(frame)

    def delete(self, frame: int, count: int = 1) -> None:
        """Delete frames; markers on them go, later markers move back."""
        if frame < len(self.inputs):
            count = min(count, len(self.inputs) - frame)
            del self.inputs[frame:frame + count]
            self.markers = {(f - count if f >= frame + count else f): label
                            for f, label in self.markers.items() if not frame <= f < frame + count}
            self._invalidate(frame)

    def copy(self, first: int, last: int) -> list[frozenset[str]]:
        return [self.input_at(f) for f in range(first, last + 1)]

    def paste(self, frame: int, inputs: list[frozenset[str]]) -> None:
        """Overwrite frames from `frame` on with `inputs` (extending the movie if needed)."""
        if not inputs:
            return
        while len(self.inputs) < frame + len(inputs):
            self.inputs.append(frozenset())
        self.inputs[frame:frame + len(inputs)] = list(inputs)
        self._invalidate(frame)

    def set_marker(self, frame: int, label: str | None) -> None:
        """Add or relabel a marker; None removes it."""
        if label is None:
            self.markers.pop(frame, None)
        else:
            self.markers[frame] = label
        self.dirty = True

    def truncate(self, frame: int) -> None:
        if frame < len(self.inputs):
            del self.inputs[frame:]
            self._invalidate(frame)

    def save_state_here(self, movie: str | None = None) -> dict[str, Any]:
        """Store the current machine state with how to rebuild it; return a start for a new movie."""
        buffer = BytesIO()
        self.pyboy.save_state(buffer)
        origin = {
            "start": self.start, "frame": self.frame, "movie": movie, "ram_sha256": self.digest(self.pyboy),
            "input": oracle.make_trace(self.inputs[:self.frame], f"Frames 0-{self.frame - 1} of {movie or 'a movie'}")
            if self.frame else None,
        }
        sha = oracle.store_put("state", buffer.getvalue(), {"origin": origin})
        return oracle.state_start(sha, oracle.boot_rom_of(self.start), origin)

    def export_save(self) -> str:
        """Store the current cartridge RAM as a battery save; return its SHA-256."""
        return oracle.store_put("save", oracle.cartridge_ram_bytes(self.pyboy),
                                {"exported_from": oracle.describe_start(self.start), "frame": self.frame})

    # --- inspection --------------------------------------------------------------

    def known_until(self) -> int:
        """Highest frame whose emulated result is known for the current inputs."""
        return max(self.counters)

    def lag(self, frame: int) -> bool | None:
        """True if no game loop finished while `frame` ran (wGlobalCounter did not advance); None if unknown."""
        if frame in self.counters and frame + 1 in self.counters:
            return self.counters[frame + 1] == self.counters[frame]
        return None

    def ram(self) -> dict[str, int]:
        return {name: oracle.read_value(self.pyboy, address, size) for name, address, size in oracle.SAMPLES}

    def screen(self) -> Any:
        return self.pyboy.screen.ndarray

    # --- files -------------------------------------------------------------------

    def to_recording(self) -> dict[str, Any]:
        """The movie as an oracle recording, with checkpoints taken by re-emulating it from the start."""
        if not self.inputs:
            raise oracle.OracleError("the movie is empty; record or enter at least one frame first")
        current = self.frame
        checkpoints = []
        self.seek(0)
        last = len(self.inputs) - 1
        while self.frame < len(self.inputs):
            self._step(render=False)
            tick = self.frame - 1
            if (tick + 1) % CHECKPOINT_EVERY == 0 or tick == last:
                checkpoints.append({"tick": tick, "ram_sha256": self.digest(self.pyboy)})
        self._goto(current, reuse_current=False)  # the pass did not render; show the current frame again
        return {
            "format": "wl3pc.oracle-recording", "format_version": oracle.FORMAT_VERSION,
            "marker": oracle.ROM_DERIVED_MARKER,
            "rom_sha256": oracle.sha256_bytes(self.rom), "emulator": oracle.emulator_config(), "start": self.start,
            "input": oracle.make_trace(self.inputs, "Edited in the WL3PC TAS editor"),
            "checkpoints": checkpoints,
            **({"markers": [{"tick": f, "label": label} for f, label in sorted(self.markers.items())]}
               if self.markers else {}),
        }

    @staticmethod
    def markers_from(recording: dict[str, Any]) -> dict[int, str]:
        return {m["tick"]: m["label"] for m in recording.get("markers", [])}

    @staticmethod
    def inputs_from(recording: dict[str, Any]) -> list[frozenset[str]]:
        events = oracle.check_trace(recording["input"])
        inputs, held, index = [], frozenset(), 0
        for tick in range(recording["input"]["ticks"]):
            if index < len(events) and events[index][0] == tick:
                held = events[index][1]
                index += 1
            inputs.append(held)
        return inputs

    def close(self) -> None:
        self.pyboy.stop(save=False)


def check_with_emulator(rom: bytes) -> str:
    """Seeking, editing, and saving against PyBoy must match straight replays bit for bit."""
    start = oracle.route_start("ootw-day1-start")
    # Buttons change on, just before, and just after snapshot frames (interval 10).
    inputs = [frozenset({"right", "a"} if f % 23 in (9, 10, 11) else {"right"} if f % 41 < 30 else {"left"})
              for f in range(240)]
    reference = oracle.start_from(rom, start)
    expected = [oracle.ram_digest(reference)]
    oracle.play(reference, oracle.make_trace(inputs, "check"), lambda _t: expected.append(oracle.ram_digest(reference)))
    reference.stop(save=False)

    tas = TasSession(rom, start, inputs)
    for target in (240, 37, 10, 11, 9, 200, 0, 123, 239, 61):
        tas.seek(target)
        if oracle.ram_digest(tas.pyboy) != expected[target]:
            raise oracle.OracleError(f"seek to {target} does not match a straight replay")
    tas.seek(150)
    tas.toggle(40, "b")
    if tas.frame != 40:
        raise oracle.OracleError("an edit before the current frame did not rewind to it")
    tas.seek(150)
    edited = list(inputs)
    edited[40] = inputs[40] | {"b"}
    again = oracle.start_from(rom, start)
    oracle.play(again, oracle.make_trace(edited[:150], "check"))
    if oracle.ram_digest(again) != oracle.ram_digest(tas.pyboy):
        raise oracle.OracleError("an edit before the current frame did not re-emulate it exactly")
    again.stop(save=False)
    replayed = oracle.replay(rom, tas.to_recording())
    tas.close()
    return (f"seeks to 10 frames, an edit with re-emulation, and a saved movie "
            f"({replayed['ticks']} ticks, {replayed['checkpoints']} checkpoints) all match straight replays")


def check_starts(rom: bytes) -> str:
    """Every start kind against straight replays: boot ROM files, battery saves, and save states."""
    route, _ = oracle.load_route("ootw-day1-start")
    walk = json.loads((oracle.PROJECT_ROOT / "game/assets/traces/walk-right-300.json").read_text(encoding="utf-8"))
    walk_inputs = TasSession.inputs_from({"input": walk})

    def run(start: dict[str, Any], inputs: list[frozenset[str]]) -> str:
        pyboy = oracle.start_from(rom, start)
        if inputs:
            oracle.play(pyboy, oracle.make_trace(inputs, "check"))
        digest = oracle.ram_digest(pyboy)
        pyboy.stop(save=False)
        return digest

    # 1. A boot ROM given as a file behaves exactly like the same bytes used as PyBoy's default.
    bundled_path, _ = oracle.bundled_boot_rom()
    file_boot = oracle.power_on_start(boot_rom_sha=oracle.import_file("boot-rom", bundled_path))
    if run(file_boot, TasSession.inputs_from(route)) != route["ram_sha256"]:
        raise oracle.OracleError("a boot ROM given as a file does not reproduce the route")
    # 2. A save state taken mid-walk continues exactly like the straight walk.
    straight = run(oracle.route_start("ootw-day1-start"), walk_inputs)
    tas = TasSession(rom, oracle.route_start("ootw-day1-start"), walk_inputs)
    tas.seek(120)
    branch = tas.save_state_here("starts-check")
    save_sha = tas.export_save()
    tas.close()
    if run(branch, walk_inputs[120:]) != straight:
        raise oracle.OracleError("a movie from a save state does not continue like the straight replay")
    oracle.verify_state(rom, branch["sha256"])
    # A state saved by PyBoy outside the oracle (so no origin is known) is imported and continues the same.
    import tempfile
    pyboy = oracle.start_from(rom, oracle.route_start("ootw-day1-start"))
    oracle.play(pyboy, oracle.make_trace(walk_inputs[:150], "check"))
    with tempfile.TemporaryDirectory() as temp:
        outside = Path(temp) / "outside.state"
        with open(outside, "wb") as handle:
            pyboy.save_state(handle)
        pyboy.stop(save=False)
        imported = oracle.parse_start(f"state:{outside}")
    if imported["origin"] is not None or run(imported, walk_inputs[150:]) != straight:
        raise oracle.OracleError("an imported state file does not continue like the straight replay")
    # 3. A battery save is loaded into cartridge RAM at power-on, and runs reproducibly.
    with_save = oracle.power_on_start(save_sha=save_sha)
    pyboy = oracle.start_from(rom, with_save)
    loaded = oracle.cartridge_ram_bytes(pyboy) == oracle.store_get("save", save_sha)
    pyboy.stop(save=False)
    boot_inputs = [frozenset({"a"}) if f % 60 < 2 else frozenset() for f in range(3000)]
    first, second = run(with_save, boot_inputs), run(with_save, boot_inputs)
    empty = run(oracle.power_on_start(), boot_inputs)
    if not loaded or first != second or first == empty:
        raise oracle.OracleError("a battery-save start is not loaded, not reproducible, or has no effect")
    return ("boot ROM as a file reproduces the route; a state taken at frame 120 continues identically to the "
            "straight walk and rebuilds from its origin; an outside PyBoy state (frame 150) imports and continues identically; a battery save exported at that frame loads at power-on, "
            "replays identically, and changes the run from an empty save")
