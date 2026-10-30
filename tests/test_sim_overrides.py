"""The simulation's classes form one chain (WarioRam to LevelSim), and GDScript lets a subclass
redefine a method without a word. A helper named like one higher up silently replaces it for
every LevelSim, while the Wario step (WarioSim alone) still runs the original, so only a whole-frame
run shows it. Every redefinition must be one of the intended hooks below."""

import re
from pathlib import Path

SIM = Path(__file__).resolve().parents[1] / "game" / "scripts" / "sim"

# (method, the class that declares it, the class that redefines it on purpose)
HOOKS = {
    ("crouch_or_slide", "WarioBlocks", "WarioSim"),
    ("set_state_water_stung", "WarioBlocks", "WarioSim"),
    ("set_state_on_fire", "WarioBlocks", "WarioSim"),
    ("recover_from_transformation_without_invincibility", "WarioBlocks", "WarioSim"),
    ("sting_out_of_transformation", "WarioBlocks", "WarioSim"),
    ("set_state_stung", "WarioBlocks", "WarioSim"),
    ("enter_pipe", "WarioBlocks", "WarioSim"),
    ("enter_door", "WarioBlocks", "WarioSim"),
    ("set_state_zombie_recovering", "WarioBlocks", "WarioSim"),
    ("set_state_fan_start", "WarioBlocks", "WarioSim"),
    ("cur_object_on_screen", "WarioBlocks", "ObjectSim"),
    ("create_block_coin", "WarioBlocks", "ObjectSim"),
    ("note_unported", "WarioRam", "ObjectSim"),
    ("object_functions", "ObjectSim", "ObjectFunctions"),
    ("object_functions", "ObjectSim", "EnemyFunctions"),
    ("object_functions", "ObjectSim", "DeviceFunctions"),
    ("object_functions", "ObjectSim", "BossFunctions"),
    ("object_functions", "ObjectSim", "HiddenFigureFunctions"),
    ("_init", "ScreenSim", "GolfSim"),
    ("_init", "ScreenSim", "MenuScreenSim"),
    ("_init", "ScreenSim", "PauseMenuSim"),  # SRAM banks 2 and 3 for SaveLevel's map backup
    ("ram_read", "ScreenSim", "GolfSim"),
    ("ram_write", "ScreenSim", "GolfSim"),
    ("ram_read", "ScreenSim", "MenuScreenSim"),
    ("ram_write", "ScreenSim", "MenuScreenSim"),
    ("ram_known", "ScreenSim", "GolfSim"),  # the WRAM0 bytes a parity run seeds
    ("ram_known", "ScreenSim", "MenuScreenSim"),
    ("load_data", "MenuScreenSim", "OverworldCommon"),
    ("loaded", "MenuScreenSim", "OverworldCommon"),
    ("_init_prologue", "OverworldCutscenes", "OverworldPrologue"),  # the cutscenes' stubs, the prologue's port
    ("_prologue_func", "OverworldCutscenes", "OverworldPrologue"),
}


def classes() -> dict[str, tuple[str | None, list[str]]]:
    found = {}
    for path in SIM.rglob("*.gd"):
        text = path.read_text()
        name = re.search(r"^class_name (\w+)", text, re.M)
        base = re.search(r"^extends (\w+)", text, re.M)
        if name:
            found[name.group(1)] = (base.group(1) if base else None,
                                    re.findall(r"^(?:static )?func (\w+)\(", text, re.M))
    return found


def redefinitions(found: dict[str, tuple[str | None, list[str]]]) -> set[tuple[str, str, str]]:
    result = set()
    for leaf in found:
        chain = []
        name = leaf
        while name in found:
            chain.append(name)
            name = found[name][0]
        owner: dict[str, str] = {}
        for name in reversed(chain):
            for method in found[name][1]:
                if method in owner:
                    result.add((method, owner[method], name))
                owner.setdefault(method, name)
    return result


def test_the_chain_is_found():
    found = classes()
    for name in ("WarioRam", "WarioBlocks", "WarioSim", "ObjectSim", "DeviceFunctions", "LevelSim"):
        assert name in found


def test_only_hooks_are_redefined():
    assert redefinitions(classes()) - HOOKS == set()


def test_a_helper_named_like_one_above_is_caught():
    found = {"A": (None, ["helper", "hook"]), "B": ("A", ["hook"]), "C": ("B", ["helper"])}
    assert redefinitions(found) == {("hook", "A", "B"), ("helper", "A", "C")}
