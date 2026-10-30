import copy
from pathlib import Path

import pytest

from wl3pc import content
from wl3pc.paths import PROJECT_ROOT

PACK = PROJECT_ROOT / "game/assets/content/synthetic"
FIXTURES = Path(__file__).parent / "fixtures/content"


def test_synthetic_pack_traces_and_example_mods_are_valid():
    base = content.load_pack(PACK)
    assert base["pack"]["origin"] == "synthetic"
    assert base["movement"]["provisional"] is True
    for trace in sorted((PROJECT_ROOT / "game/assets/traces").glob("*.json")):
        content.load_trace(trace)
    mods = content.mod_files(PROJECT_ROOT / "mods/examples")
    assert mods, "at least one example mod"
    for mod in mods:
        content.apply_mod(content.load_pack(PACK), mod)


def test_example_mod_changes_parameters_and_layout_without_touching_base():
    base = content.load_pack(PACK)
    pristine = copy.deepcopy(base)
    modded = content.load_pack(PACK)
    content.apply_mod(modded, PROJECT_ROOT / "mods/examples/low-gravity-ledge/mod.json")
    assert modded["movement"]["gravity"] == 2
    assert modded["rooms"]["testbed"]["rows"][5][2:6] == "===="
    assert base == pristine


@pytest.mark.parametrize("case", sorted(p.name for p in (FIXTURES / "invalid-mods").iterdir()))
def test_invalid_mods_are_rejected(case):
    with pytest.raises(content.ContentError):
        content.apply_mod(content.load_pack(PACK), FIXTURES / "invalid-mods" / case / "mod.json")


@pytest.mark.parametrize("case", sorted(p.name for p in (FIXTURES / "invalid-packs").iterdir()))
def test_invalid_packs_are_rejected(case):
    with pytest.raises(content.ContentError):
        content.load_pack(FIXTURES / "invalid-packs" / case)


def test_version_2_pack_with_labelled_approximations_is_valid():
    loaded = content.load_pack(FIXTURES / "valid-packs" / "approximations")
    subjects = [a["subject"] for a in loaded["pack"]["approximations"]]
    assert subjects == ["room/r/legend/B", "start"]
    assert loaded["rooms"]["r"]["legend"]["B"] == "solid"


def test_symlinked_files_are_rejected(tmp_path):
    pack = tmp_path / "pack"
    (pack / "rooms").mkdir(parents=True)
    for name in ("pack.json", "movement.json"):
        (pack / name).write_text((PACK / name).read_text())
    (pack / "rooms" / "testbed.json").symlink_to(PACK / "rooms" / "testbed.json")
    with pytest.raises(content.ContentError, match="symbolic links"):
        content.load_pack(pack)
