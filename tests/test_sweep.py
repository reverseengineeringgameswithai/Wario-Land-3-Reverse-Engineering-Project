"""Coverage sweeps (wl3pc.sweep) on invented parity results, without an emulator or ROM."""

import pytest

from wl3pc import sweep


def test_names_and_levels_follow_level_movie():
    assert sweep.sweep_name("wander", None) == "wander"
    assert sweep.sweep_name("wander", 9) == "wander-pu9"
    assert sweep.sweep_name("wander", 9, 3600) == "wander-pu9-t3600" and sweep.sweep_name("left", None, 1200) == "left"
    assert sweep.level_ids(0)[:3] == ["00", "08", "10"] and sweep.level_ids(0)[-1] == "c0"
    assert sweep.level_ids(4)[:2] == ["04", "0c"] and len(sweep.level_ids(4)) == 25
    with pytest.raises(ValueError):
        sweep.level_ids(8)


def test_variants_parse_and_repeated_level_data_is_left_out():
    assert sweep.parse_variants("4") == [4] and sweep.parse_variants("1,2,3") == [1, 2, 3]
    with pytest.raises(ValueError):
        sweep.parse_variants("3,8")
    # Invented level data: day 1 and 3 repeat days 0 and 2; nights 5 and 7 repeat night 4, and
    # night 6 is new. Days are not compared with nights.
    data = {0: "a", 1: "a", 2: "b", 3: "b", 4: "a", 5: "a", 6: "c", 7: "a"}
    ids = sweep.distinct_level_ids([1, 2, 3, 5, 6, 7], lambda level: (level // 8, data[level % 8]))
    assert ids == [f"{level * 8 + 2:02x}" for level in range(25)] + [f"{level * 8 + 6:02x}" for level in range(25)]


def test_room_starts_are_named_after_their_level():
    rooms = {0x00: [0, 1, 4], 0x08: [0], 0x10: [0, 2]}
    assert sweep.room_ids(["00", "08", "10"], lambda level: rooms[level]) == ["00r01", "00r04", "10r02"]
    assert sweep.split_id("10r02") == ("10", "02") and sweep.split_id("10") == ("10", None)


def test_step_results_are_totalled_and_a_difference_names_its_level():
    results = {
        "00": {"mode": "step", "matched": 10, "mismatched": 0, "updates": 12, "unported": {"state $97": 2},
               "objects": {"matched": 20, "mismatched": 0, "unported": {"Func_x": 1}},
               "interactions": {"matched": 12, "mismatched": 0, "unported": {}}},
        "08": {"mode": "step", "matched": 5, "mismatched": 1, "updates": 6, "unported": {"state $97": 3},
               "objects": {"matched": 7, "mismatched": 0}, "interactions": {"matched": 6, "mismatched": 0}},
    }
    summary = sweep.summarize(results)
    assert summary["wario"] == {"matched": 15, "mismatched": 1, "updates": 18}
    assert summary["objects"] == {"matched": 27, "mismatched": 0}
    assert summary["unported"]["wario"] == {"state $97": 5}
    assert summary["unported"]["objects"] == {"Func_x": 1}
    assert summary["mismatched_levels"] == ["08"]


def test_run_results_count_the_levels_run_to_the_end():
    results = {"00": {"mode": "run", "stopped": "end of trace", "mismatched": 0},
               "08": {"mode": "run", "stopped": "ObjInteraction $28", "stopped_at_frame": 482, "mismatched": 0}}
    summary = sweep.summarize(results)
    assert summary["to_the_end"] == 1
    assert summary["stopped"] == {"08": "ObjInteraction $28 (frame 482)"}
    assert summary["mismatched_levels"] == []
    assert summary["screens"] == {"checked": 0, "to_the_end": 0, "differ": []}


def test_run_results_count_the_screens_run_on_after_a_level():
    results = {"00": {"mode": "run", "stopped": "end of trace", "mismatched": 0,
                      "screens": {"checked": True, "stopped": "end of trace"}},
               "08": {"mode": "run", "stopped": "end of trace", "mismatched": 0,
                      "screens": {"checked": True, "stopped": "a difference", "stopped_at_frame": 900}},
               "10": {"mode": "run", "stopped": "end of trace", "mismatched": 0, "screens": {"checked": False}}}
    assert sweep.summarize(results)["screens"] == {"checked": 2, "to_the_end": 1, "differ": ["08"]}


def test_the_regression_sweeps_are_the_thirty_four_named_in_the_vault():
    assert len(sweep.REGRESSION) == 34
    assert len(set(sweep.REGRESSION)) == 34
    names = {sweep.sweep_dir(sweep.sweep_name(script, power_up), sweep.parse_variants(variants), rooms, "step").name
             for script, power_up, variants, _, rooms in sweep.REGRESSION}
    assert {"wander-v0-step", "wander-pu9-v123567-rooms-step", "left-jump-v4-rooms-step"} <= names


def test_the_regression_report_totals_the_sweeps_and_fails_on_a_difference():
    def summary(mode, mismatched=(), differ=()):
        common = {"script": "wander", "power_up": None, "variants": [0], "rooms": False, "levels": 25,
                  "mismatched_levels": list(mismatched)}
        if mode == "run":
            return {**common, "to_the_end": 25, "screens": {"checked": 0, "to_the_end": 0, "differ": list(differ)}}
        return {**common, "wario": {"matched": 10, "mismatched": 0, "updates": 10},
                "objects": {"matched": 5, "mismatched": 0}, "interactions": {"matched": 3, "mismatched": 0},
                "unported": {"wario": {}, "objects": {}, "interactions": {}}}
    lines, failed = sweep.regression_report([{"step": summary("step"), "run": summary("run")}] * 2)
    assert not failed
    assert lines[0].startswith("step: 2 sweeps, 50 movies; Wario 20 matched, 0 differ")
    assert lines[1].startswith("run: 2 sweeps, 50 movies, 50 to the end")
    assert sweep.regression_report([{"run": summary("run", differ=["08"])}])[1]
    assert sweep.regression_report([{"step": summary("step", mismatched=["10"])}])[1]
