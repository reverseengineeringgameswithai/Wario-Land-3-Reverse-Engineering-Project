"""TAS editing model (tools/wl3pc/tas.py) against a small deterministic fake machine."""

import hashlib
import json
from io import BytesIO

import pytest

from wl3pc import oracle
from wl3pc.tas import COUNTER, TasSession


class FakeMachine:
    """Each tick folds the held buttons into an accumulator; some frames 'lag' (no counter step)."""

    def __init__(self):
        self.pressed, self.acc, self.counter = set(), 0, 0
        self.memory = self

    def __getitem__(self, address):
        assert address == COUNTER
        return self.counter & 0xFF

    def button_press(self, button):
        self.pressed.add(button)

    def button_release(self, button):
        self.pressed.discard(button)

    def tick(self, count, render):
        for _ in range(count):
            self.acc = (self.acc * 31 + sum(1 << oracle.BUTTONS.index(b) for b in self.pressed) + 7) % 1_000_003
            if self.acc % 5:
                self.counter += 1

    def save_state(self, buffer):
        buffer.write(json.dumps([sorted(self.pressed), self.acc, self.counter]).encode())

    def load_state(self, buffer):
        pressed, self.acc, self.counter = json.loads(buffer.read())
        self.pressed = set(pressed)

    def stop(self, save):
        pass


def digest(machine):
    return hashlib.sha256(json.dumps([machine.acc, machine.counter]).encode()).hexdigest()


def session(inputs=None, interval=4):
    return TasSession(b"rom", {"kind": "power-on"}, inputs, interval, lambda rom, start: FakeMachine(), digest)


def movie(n):
    return [frozenset({"right"} if i % 3 else {"right", "a"}) if i % 7 else frozenset() for i in range(n)]


def linear(inputs, frames):
    fresh = session(inputs)
    out = [digest(fresh.pyboy)]
    for _ in range(frames):
        fresh.advance()
        out.append(digest(fresh.pyboy))
    return out


def test_seeking_anywhere_matches_playing_straight_through():
    inputs = movie(40)
    expected = linear(inputs, 40)
    tas = session(inputs)
    for target in (17, 3, 40, 0, 39, 12, 12, 25, 8, 33, 1):
        tas.seek(target)
        assert tas.frame == target and digest(tas.pyboy) == expected[target], target


def test_an_edit_before_the_current_frame_rewinds_to_it():
    inputs = movie(30)
    tas = session(inputs)
    tas.seek(30)
    tas.toggle(9, "b")
    edited = list(inputs)
    edited[9] = inputs[9] | {"b"}
    expected = linear(edited, 30)
    assert tas.frame == 9 and digest(tas.pyboy) == expected[9]
    assert max(tas.states) <= 9 and tas.known_until() == 9 and tas.dirty
    tas.seek(30)  # an editor's "restore position"
    assert digest(tas.pyboy) == expected[30]


def test_an_edit_at_the_current_frame_keeps_the_current_state():
    tas = session(movie(20))
    tas.seek(10)
    before = digest(tas.pyboy)
    tas.set_input(10, frozenset({"left"}))
    assert digest(tas.pyboy) == before and tas.known_until() == 10


def test_recording_overwrites_then_appends():
    tas = session(movie(5))
    tas.seek(3)
    for held in ({"up"}, {"up", "a"}, {"down"}, set()):
        tas.advance(frozenset(held))
    assert tas.inputs[3:] == [frozenset({"up"}), frozenset({"up", "a"}), frozenset({"down"}), frozenset()]
    assert len(tas.inputs) == 7 and tas.frame == 7
    assert digest(tas.pyboy) == linear(tas.inputs, 7)[7]


def test_insert_delete_truncate_and_undo():
    inputs = movie(12)
    tas = session(inputs)
    tas.seek(12)
    tas.remember()
    tas.insert(2, 3)
    assert tas.inputs[2:5] == [frozenset()] * 3 and tas.inputs[5:] == inputs[2:]
    tas.remember()
    tas.delete(0, 2)
    assert tas.inputs[:3] == [frozenset()] * 3
    assert tas.undo() and tas.undo()
    assert tas.inputs == inputs and tas.frame == 0  # the delete at 0 rewound there; edits never move forward
    tas.seek(12)
    assert digest(tas.pyboy) == linear(inputs, 12)[12]
    assert not tas.undo()
    tas.truncate(5)
    assert len(tas.inputs) == 5


def test_lag_frames_are_reported_once_known():
    tas = session(movie(20))
    assert tas.lag(0) is None
    tas.seek(20)
    flags = [tas.lag(f) for f in range(20)]
    assert None not in flags and True in flags and False in flags
    assert tas.lag(20) is None


def test_saved_movie_has_replayable_checkpoints():
    inputs = movie(130)
    tas = session(inputs)
    tas.seek(50)
    recording = tas.to_recording()
    expected = linear(inputs, 130)
    assert [c["tick"] for c in recording["checkpoints"]] == [59, 119, 129]
    assert all(c["ram_sha256"] == expected[c["tick"] + 1] for c in recording["checkpoints"])
    assert tas.frame == 50
    assert TasSession.inputs_from(recording) == inputs
    assert oracle.check_trace(recording["input"])


def test_an_empty_movie_cannot_be_saved():
    with pytest.raises(oracle.OracleError, match="empty"):
        session([]).to_recording()


def test_markers_follow_inserts_and_deletes_and_undo():
    tas = session(movie(20))
    tas.set_marker(5, "jump")
    tas.set_marker(12, "door")
    tas.remember()
    tas.insert(8, 3)
    assert tas.markers == {5: "jump", 15: "door"}
    tas.remember()
    tas.delete(4, 2)                     # frame 5 is deleted with its marker
    assert tas.markers == {13: "door"}
    assert tas.undo() and tas.markers == {5: "jump", 15: "door"}
    assert tas.undo() and tas.markers == {5: "jump", 12: "door"} and tas.inputs == movie(20)
    tas.set_marker(5, None)
    assert tas.markers == {12: "door"}


def test_copy_paste_overwrites_and_paste_insert_shifts():
    inputs = movie(10)
    tas = session(inputs)
    block = tas.copy(1, 3)
    assert block == inputs[1:4]
    tas.paste(8, block)                  # runs past the end: the movie grows to 11 frames
    assert tas.inputs[8:11] == block and len(tas.inputs) == 11
    tas.set_marker(9, "m")
    tas.insert(2, inputs=block)
    assert tas.inputs[2:5] == block and tas.markers == {12: "m"}
    tas.seek(len(tas.inputs))
    assert digest(tas.pyboy) == linear(tas.inputs, len(tas.inputs))[-1]


def test_markers_are_saved_with_the_movie():
    tas = session(movie(70))
    tas.set_marker(3, "start of jump")
    recording = tas.to_recording()
    assert recording["markers"] == [{"tick": 3, "label": "start of jump"}]
    assert TasSession.markers_from(recording) == {3: "start of jump"}
    assert "markers" not in session(movie(70)).to_recording()
