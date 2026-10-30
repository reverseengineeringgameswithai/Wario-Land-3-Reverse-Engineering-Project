import pytest

from synthetic_rom import build_rom
from test_rooms import at
from wl3pc.address import BankedAddress
from wl3pc.extract import wario_movement as wm
from wl3pc.extract.block_functions import MalformedDataError

# A miniature layout over a 64 KiB synthetic ROM: a 4-step walk table, two 3-step jump tables, two framesets.
LAYOUT = wm.MovementLayout(
    rom_id="synthetic",
    walk_vel_table=BankedAddress(0, 0x2000),
    walk_vel_entries=4,
    jump_vel_tables=(("knock_back", BankedAddress(0, 0x2010)), ("normal", BankedAddress(0, 0x2013))),
    jump_vel_entries=3,
    framesets=(BankedAddress(1, 0x4000), BankedAddress(1, 0x4010)),
    animation_bank=1,
)


def synthetic(extra=None) -> bytes:
    patches = {
        0x2000: bytes([0, 1, 2, 4]),
        0x2010: bytes([0xFE, 0x00, 0x03]),  # -2, 0, 3
        0x2013: bytes([0xFC, 0xFF, 0x01]),  # -4, -1, 1
        at(1, 0x4000): bytes([1, 1, 2, 2, 3, 1, 0xFF]),
        at(1, 0x4010): bytes([0xFF]),  # an empty frameset ends at once
    }
    patches.update(extra or {})
    return bytes(build_rom(size=0x10000, patches=patches))


def test_decodes_tables_as_unsigned_walk_and_signed_jump_steps():
    document = wm.decode(synthetic(), LAYOUT)
    assert document["walk_vel_table"] == {"location": "00:2000", "steps": [0, 1, 2, 4]}
    assert [(t["id"], t["name"], t["steps"]) for t in document["jump_vel_tables"]] == [
        (1, "knock_back", [-2, 0, 3]), (2, "normal", [-4, -1, 1])]


def test_framesets_are_keyed_by_the_pointer_the_game_stores():
    framesets = wm.decode(synthetic(), LAYOUT)["framesets"]
    assert framesets["4000"] == {"location": "01:4000", "pairs": [[1, 1], [2, 2], [3, 1]]}
    assert framesets["4010"]["pairs"] == []
    # Outside the animation bank, by bank and pointer.
    other = wm.MovementLayout("synthetic", LAYOUT.walk_vel_table, 4, LAYOUT.jump_vel_tables, 3,
                              (BankedAddress(1, 0x4000),), animation_bank=0x02)
    assert list(wm.decode(synthetic(), other)["framesets"]) == ["01:4000"]


def test_a_frameset_without_terminator_is_refused():
    unterminated = synthetic({at(1, 0x4010): bytes([5, 1] * 70)})
    with pytest.raises(MalformedDataError, match="no \\$ff terminator"):
        wm.decode(unterminated, LAYOUT)


def test_a_frameset_at_the_end_of_its_bank_is_refused_not_read_across():
    layout = wm.MovementLayout("synthetic", LAYOUT.walk_vel_table, 4, LAYOUT.jump_vel_tables, 3,
                               (BankedAddress(1, 0x7FFE),))
    with pytest.raises(MalformedDataError):
        wm.decode(synthetic({at(1, 0x7FFE): bytes([7, 1])}), layout)


def test_world_layout_matches_the_disassembly_constants():
    layout = wm.WL3_WORLD_MOVEMENT_LAYOUT
    # WalkVelTable is indexed up to $1b (ApplyWalkVelocity) and jump tables up to MAX_JUMP_VEL_INDEX ($27).
    assert (layout.walk_vel_entries, layout.jump_vel_entries) == (0x1C, 0x28)
    starts = [where.address for _, where in layout.jump_vel_tables]
    # The five jump tables are consecutive in bank 0 and the walk table follows them.
    assert sorted(starts) == [0x18A7 + 0x28 * i for i in range(5)]
    assert layout.walk_vel_table.address == 0x18A7 + 0x28 * 5
    # "Wario OAM 1", and "Wario OAM 2" for the treasure scene
    assert {where.bank for where in layout.framesets} == {0x05, 0x77, 0x7F} and layout.animation_bank == 0x05
