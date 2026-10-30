"""Splitting a trace into level visits (wl3pc.godot.level_visits) on invented frames."""

from wl3pc.godot import level_visits


def _trace(states: list[tuple[int, int]]) -> dict:
    return {"variables": [{"name": "wState"}, {"name": "wLevel"}], "frames": [list(state) for state in states]}


def test_pause_golf_a_keys_pause_the_clear_screen_and_action_help_stay_inside_a_visit():
    trace = _trace([(1, 0), (2, 0x45), (4, 0x45), (2, 0x45), (5, 0x45), (2, 0x45), (8, 0x45), (2, 0x45),
                    (3, 0x45), (7, 0x45), (1, 0x45), (4, 0x45), (1, 0x45)])
    assert level_visits(trace) == [(0, 13, 0x45)], "the last visit keeps the map and its save screen after it"


def test_leaving_for_the_map_ends_a_visit_and_the_next_keeps_its_lead_in():
    trace = _trace([(1, 0), (2, 0x45), (2, 0x45), (1, 0x45), (1, 0x41), (2, 0x41), (8, 0x41), (1, 0x41)])
    assert level_visits(trace) == [(0, 3, 0x45), (3, 8, 0x41)]
    trace = _trace([(1, 0), (2, 0x45), (1, 0x45), (2, 0x41), (1, 0x41), (1, 0x41)])
    assert level_visits(trace) == [(0, 2, 0x45), (2, 6, 0x41)]


def test_a_resets_title_stays_with_the_visit_it_left():
    trace = _trace([(1, 0), (2, 0x45), (4, 0x45), (0, 0x45), (0, 0x45), (2, 0x45), (2, 0x45)])
    assert level_visits(trace) == [(0, 5, 0x45), (5, 7, 0x45)], "the save's reset, Continue into the level"
    trace = _trace([(2, 0x45), (0, 0x45), (0x0E, 0x45), (1, 0x45), (2, 0x41)])
    assert level_visits(trace) == [(0, 3, 0x45), (3, 5, 0x41)], "the next visit keeps its lead-in on the map"
    assert level_visits(_trace([(2, 0x45), (0, 0x45), (0, 0x45)])) == [(0, 3, 0x45)], "to the end"


def test_a_trace_that_never_enters_a_level_has_no_visit():
    assert level_visits(_trace([(1, 0), (0, 0)])) == []
