"""Decode Wario's movement tables and animation framesets.

Question: what per-frame steps does Wario move by, and how long do the animations that end
states (turning, landing) last?
Evidence (ElectroDeoxys/warioland3 @560fce6, verified byte-identical to the identified ROM):
- ApplyWalkVelocity (home/wario_mechanics1.asm) reads WalkVelTable[wWalkVelIndex] and increments
  the index, applying `and $fc` at $1b, so the table has $1c entries (src/data/levels/walk_vel_table.asm).
- ApplyJumpVelocity picks one of five tables by wJumpVelTable (JUMP_VEL_KNOCK_BACK = 1 ...
  JUMP_VEL_BOUNCY_HIGH_JUMP = 5) and caps the index at MAX_JUMP_VEL_INDEX ($27) while falling, so each
  table has $28 signed entries (src/data/levels/jump_vel_tables.asm, consecutive in bank 0).
- UpdateWarioAnimation (home/sprite.asm) reads (frame, duration) pairs from wWarioFramesetPtr in the
  "Wario OAM 1" bank until a $ff frame, which ends the animation and restarts it.
Research note: docs/02-research/wario-movement.md.
"""

from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .. import TOOLS_VERSION
from ..address import BankedAddress, RomBoundsError, RomView
from ..known_roms import WL3_WORLD_EN_JA
from ..paths import CONTENT_OUT_DIR, rom_path_from_env
from ..provenance import ROM_DERIVED_MARKER, canonical_json, sha256_bytes, sha256_file, write_immutable
from ..rom import RomFormatError, UnknownRomError, inspect_bytes, read_rom, require_known
from ..symbols import load_sym
from . import block_functions as bf
from .block_functions import MalformedDataError

FORMAT = "wl3pc.wario-movement"
FORMAT_VERSION = 1
EXTRACTOR_VERSION = 32
FRAMESET_END = 0xFF  # UpdateWarioAnimation: `cp $ff / jr z, .finished`
MAX_FRAMESET_PAIRS = 64  # a guard against reading past a missing terminator; no frameset is near it


@dataclass(frozen=True)
class MovementLayout:
    rom_id: str
    walk_vel_table: BankedAddress
    walk_vel_entries: int
    # In wJumpVelTable order: JUMP_VEL_KNOCK_BACK (1) to JUMP_VEL_BOUNCY_HIGH_JUMP (5)
    jump_vel_tables: tuple[tuple[str, BankedAddress], ...]
    jump_vel_entries: int
    # Framesets the native states use, by the pointer the game writes to wWarioFramesetPtr
    framesets: tuple[BankedAddress, ...]
    # "Wario OAM 1", where UpdateWarioAnimation usually reads them; others are keyed with their bank
    animation_bank: int = 0x05
    # HandleUnderwaterThrustingInput's speeds by wSwimVelIndex (0-39)
    swim_vel_tables: tuple[tuple[str, BankedAddress], ...] = ()
    swim_vel_entries: int = 40
    # UpdateState_FlatFalling's steps by wWalkVelIndex (0-39): "down" and "across"
    flat_fall_tables: tuple[tuple[str, BankedAddress], ...] = ()
    flat_fall_entries: int = 40
    bubble_drift_table: BankedAddress | None = None
    bubble_drift_entries: int = 47


WL3_WORLD_MOVEMENT_LAYOUT = MovementLayout(
    rom_id=WL3_WORLD_EN_JA.rom_id,
    walk_vel_table=BankedAddress(0x00, 0x196F),  # WalkVelTable
    walk_vel_entries=0x1C,
    jump_vel_tables=(
        ("knock_back", BankedAddress(0x00, 0x18F7)),  # JumpVelTable_KnockBack
        ("normal", BankedAddress(0x00, 0x18A7)),  # JumpVelTable_Normal
        ("high_jump", BankedAddress(0x00, 0x18CF)),  # JumpVelTable_HighJump
        ("bouncy_jump", BankedAddress(0x00, 0x191F)),  # JumpVelTable_BouncyJump
        ("bouncy_high_jump", BankedAddress(0x00, 0x1947)),  # JumpVelTable_BouncyHighJump
    ),
    jump_vel_entries=0x28,
    swim_vel_tables=(
        ("straight", BankedAddress(0x07, 0x786C)),  # SwimStraightVelTable
        ("vertical", BankedAddress(0x07, 0x7894)),  # Data_1f894 (up or down while thrusting sideways)
        ("diagonal", BankedAddress(0x07, 0x78BC)),  # SwimDiagonalVelTable
    ),
    flat_fall_tables=(
        ("down", BankedAddress(0x0A, 0x7664)),  # Data_2b664
        ("across", BankedAddress(0x0A, 0x768C)),  # Data_2b68c
    ),
    bubble_drift_table=BankedAddress(0x0A, 0x76B4),  # Data_2b6b4 (Func_2b56f, a bubble's drift)
    framesets=(
        BankedAddress(0x05, 0x4252), BankedAddress(0x05, 0x425F),  # idling, left and right (SetState_Idling)
        BankedAddress(0x05, 0x49B4), BankedAddress(0x05, 0x49C5),  # walking (Func_1e6ea)
        BankedAddress(0x05, 0x4CBE), BankedAddress(0x05, 0x4CC5),  # turning (SetState_Turning)
        BankedAddress(0x05, 0x5F8E), BankedAddress(0x05, 0x5F91),  # smash attack, airborne
        BankedAddress(0x05, 0x604E), BankedAddress(0x05, 0x6055),  # smash attack with the Super Jump Slam Overalls
        BankedAddress(0x05, 0x5FF2), BankedAddress(0x05, 0x6009),  # ground pound (DoGroundPound)
        BankedAddress(0x05, 0x5FB8), BankedAddress(0x05, 0x5FC5),  # ground shake (DoWarioGroundShake)
        BankedAddress(0x05, 0x63EC), BankedAddress(0x05, 0x640C),  # picking up (Func_20b6b)
        BankedAddress(0x05, 0x63F5), BankedAddress(0x05, 0x6415),  # picking up a heavy object
        BankedAddress(0x05, 0x4A20), BankedAddress(0x05, 0x4A23),  # grab idling (SetState_GrabIdling)
        BankedAddress(0x05, 0x49FE), BankedAddress(0x05, 0x4A0F),  # grab walking (Func_1ee88)
        BankedAddress(0x05, 0x5FA8), BankedAddress(0x05, 0x5FAB),  # grab airborne (SetState_GrabAirborne)
        BankedAddress(0x05, 0x5FEC), BankedAddress(0x05, 0x5FEF),  # grab smash attack, airborne
        BankedAddress(0x05, 0x605C), BankedAddress(0x05, 0x6063),  # grab smash attack with the Super Jump Slam Overalls
        BankedAddress(0x05, 0x6020), BankedAddress(0x05, 0x6037),  # grab ground pound
        BankedAddress(0x05, 0x5FD2), BankedAddress(0x05, 0x5FDF),  # grab ground shake
        BankedAddress(0x05, 0x642C), BankedAddress(0x05, 0x642F),  # throw charging (SetState_ThrowCharging)
        BankedAddress(0x05, 0x6432), BankedAddress(0x05, 0x6435),  # throw fully charged
        BankedAddress(0x05, 0x6438), BankedAddress(0x05, 0x6441),  # holding a full charge
        BankedAddress(0x05, 0x63FE), BankedAddress(0x05, 0x641E),  # throwing (Func_1de3f)
        BankedAddress(0x05, 0x6403), BankedAddress(0x05, 0x6423),  # throwing a full charge
        BankedAddress(0x05, 0x5FAE), BankedAddress(0x05, 0x5FB3),  # throwing airborne
        BankedAddress(0x05, 0x4CCC), BankedAddress(0x05, 0x4CE1),  # Crazy Wario: spinning (SetState_CrazySpinning)
        BankedAddress(0x7F, 0x4F9F), BankedAddress(0x7F, 0x4F6E),  # crazy, crazy airborne
        BankedAddress(0x7F, 0x4FD0), BankedAddress(0x7F, 0x4FD7),  # crazy turning
        BankedAddress(0x05, 0x5F94), BankedAddress(0x05, 0x5F97),  # airborne (SetState_Airborne)
        BankedAddress(0x05, 0x5F9A), BankedAddress(0x05, 0x5FA1),  # hard landing (DoHardLand)
        BankedAddress(0x05, 0x51E4), BankedAddress(0x05, 0x51FD),  # attacking (SetState_Attacking)
        BankedAddress(0x05, 0x521C), BankedAddress(0x05, 0x522D),  # attacking with Garlic
        BankedAddress(0x05, 0x5216), BankedAddress(0x05, 0x5219),  # bumping, attacking airborne
        BankedAddress(0x05, 0x523E), BankedAddress(0x05, 0x5249),  # attacking airborne with Garlic
        BankedAddress(0x05, 0x5F70), BankedAddress(0x05, 0x5F7F),  # bumping out of a roll
        BankedAddress(0x05, 0x4A26), BankedAddress(0x05, 0x4A2F),  # crouch walking
        BankedAddress(0x05, 0x4A38), BankedAddress(0x05, 0x4A3B),  # crouching, crouch sliding and airborne
        BankedAddress(0x05, 0x6708), BankedAddress(0x05, 0x671D),  # sliding (SetState_Sliding)
        BankedAddress(0x05, 0x66E6), BankedAddress(0x05, 0x66F7),  # rolling, rolling airborne
        BankedAddress(0x05, 0x58D6),  # ladder climbing (SetState_LadderClimbing)
        BankedAddress(0x05, 0x5900), BankedAddress(0x05, 0x58FD),  # ladder idling, left and right
        BankedAddress(0x05, 0x5903), BankedAddress(0x05, 0x5924),  # ladder scratching, left and right
        BankedAddress(0x05, 0x5945),  # ladder sliding
        BankedAddress(0x05, 0x5948),  # shaken off a ladder (SetState_LadderShakeStunned)
        BankedAddress(0x05, 0x4D0B), BankedAddress(0x05, 0x4D10),  # entering a door (EnterDoor)
        BankedAddress(0x05, 0x4D15), BankedAddress(0x05, 0x4D18),  # going through, and out of, a door
        BankedAddress(0x05, 0x4CF6),  # going through a pipe (EnterPipeDown, EnterPipeUp)
        BankedAddress(0x77, 0x4CC0), BankedAddress(0x77, 0x4CC9),  # Puffy Wario: inflating
        BankedAddress(0x77, 0x4D4E), BankedAddress(0x77, 0x4D57),  # rising
        BankedAddress(0x77, 0x4CE3), BankedAddress(0x77, 0x4CD8),  # turning
        BankedAddress(0x77, 0x4CEE), BankedAddress(0x77, 0x4D1E),  # deflating
        BankedAddress(0x77, 0x4D01), BankedAddress(0x77, 0x4D31),  # deflated
        BankedAddress(0x7F, 0x7D16), BankedAddress(0x7F, 0x7D10),  # split by a beam (SetState_SplitHit)
        BankedAddress(0x7F, 0x7D19), BankedAddress(0x7F, 0x7D13),  # knocked back
        BankedAddress(0x7F, 0x7CCF), BankedAddress(0x7F, 0x7C8E),  # splitting
        BankedAddress(0x7F, 0x5439), BankedAddress(0x7F, 0x581C),  # Vampire Wario: transforming, idling
        BankedAddress(0x7F, 0x5825), BankedAddress(0x7F, 0x582E),  # walking
        BankedAddress(0x7F, 0x5841), BankedAddress(0x7F, 0x583A),  # turning
        BankedAddress(0x7F, 0x540A), BankedAddress(0x7F, 0x5479),  # into a bat
        BankedAddress(0x7F, 0x545F), BankedAddress(0x7F, 0x546C),  # the bat idling
        BankedAddress(0x7F, 0x542C), BankedAddress(0x7F, 0x5434),  # the bat flying
        BankedAddress(0x7F, 0x5B2C),  # in a bubble (Func_2ac7d)
        BankedAddress(0x7F, 0x6D53),  # Owl Wario: grabbing the owl
        BankedAddress(0x7F, 0x6D7C), BankedAddress(0x7F, 0x6D91), BankedAddress(0x7F, 0x6DD0),  # slow
        BankedAddress(0x7F, 0x6DA6), BankedAddress(0x7F, 0x6DBB), BankedAddress(0x7F, 0x6DE5),  # fast
        BankedAddress(0x7F, 0x6DFE),  # letting go
        BankedAddress(0x7F, 0x7560), BankedAddress(0x7F, 0x75A3),  # Snowman Wario: turning into one
        BankedAddress(0x7F, 0x75F8), BankedAddress(0x7F, 0x75FB),  # idle
        BankedAddress(0x7F, 0x75E6), BankedAddress(0x7F, 0x75EF),  # walking
        BankedAddress(0x7F, 0x7605), BankedAddress(0x7F, 0x75FE),  # turning
        BankedAddress(0x7F, 0x760C), BankedAddress(0x7F, 0x7617),  # jumping, landing
        BankedAddress(0x7F, 0x7622), BankedAddress(0x7F, 0x7625),  # falling
        BankedAddress(0x7F, 0x7628), BankedAddress(0x7F, 0x7639),  # bumped
        BankedAddress(0x7F, 0x7956), BankedAddress(0x7F, 0x792B),  # the snowball: small
        BankedAddress(0x7F, 0x7963), BankedAddress(0x7F, 0x7938),  # medium
        BankedAddress(0x7F, 0x7970), BankedAddress(0x7F, 0x7945),  # big
        BankedAddress(0x7F, 0x7981),  # crashing
        BankedAddress(0x77, 0x437F), BankedAddress(0x77, 0x43C3),  # Fan Wario: starting
        BankedAddress(0x77, 0x4374), BankedAddress(0x77, 0x43B8),  # lifting
        BankedAddress(0x77, 0x438E), BankedAddress(0x77, 0x4389),  # turning
        BankedAddress(0x77, 0x4393),  # spinning
        BankedAddress(0x77, 0x4384), BankedAddress(0x77, 0x43C8),  # recovering
        BankedAddress(0x77, 0x4FB0),  # Magic Wario rising
        BankedAddress(0x77, 0x5313), BankedAddress(0x77, 0x5316), BankedAddress(0x77, 0x5323),  # the ball
        BankedAddress(0x77, 0x5230), BankedAddress(0x77, 0x5295),  # bouncing
        BankedAddress(0x77, 0x52F3), BankedAddress(0x77, 0x52F6),  # airborne
        BankedAddress(0x77, 0x526C), BankedAddress(0x77, 0x52D1), BankedAddress(0x77, 0x527A),  # shot
        BankedAddress(0x77, 0x52EE),  # thrown, sent up
        BankedAddress(0x77, 0x528E), BankedAddress(0x77, 0x5287),  # turning
        BankedAddress(0x77, 0x4904), BankedAddress(0x77, 0x48FB),  # launched (SetState_Launched)
        BankedAddress(0x77, 0x4926), BankedAddress(0x77, 0x490D),  # crashing
        BankedAddress(0x05, 0x4A71), BankedAddress(0x05, 0x4A6C),  # bumped by an enemy (SetState_EnemyBumping)
        BankedAddress(0x05, 0x4A79), BankedAddress(0x05, 0x4A76),  # bouncing off an enemy (Func_20939)
        BankedAddress(0x05, 0x7B79), BankedAddress(0x05, 0x7B76),  # electric: struck (ObjInteraction_Electric)
        BankedAddress(0x05, 0x7B8D), BankedAddress(0x05, 0x7B7C),  # electric: thrown back
        BankedAddress(0x05, 0x7B9E), BankedAddress(0x05, 0x7BAD),  # electric: dizzy
        BankedAddress(0x05, 0x7414),  # getting wrapped in string (ObjInteraction_Silky)
        BankedAddress(0x05, 0x741F), BankedAddress(0x05, 0x73FE),  # ball o' string
        BankedAddress(0x05, 0x742A), BankedAddress(0x05, 0x7409),  # knocked back, unwrapped
        BankedAddress(0x05, 0x7CE2),  # dizzy
        BankedAddress(0x05, 0x7E1B), BankedAddress(0x05, 0x7E3A),  # turning invisible
        BankedAddress(0x05, 0x6B38), BankedAddress(0x05, 0x6B49),  # set on fire (SetState_OnFire)
        BankedAddress(0x05, 0x6B14), BankedAddress(0x05, 0x6B1D),  # on fire
        BankedAddress(0x05, 0x6B26), BankedAddress(0x05, 0x6B2F),  # hot
        BankedAddress(0x05, 0x6E47), BankedAddress(0x05, 0x6E72),  # burnt
        # The treasure scene's, in "Wario OAM 2" (UpdateWarioAnimation from that bank).
        BankedAddress(0x7F, 0x446A), BankedAddress(0x7F, 0x4461),  # turning to the front
        BankedAddress(0x7F, 0x42AB),  # laughing
        BankedAddress(0x7F, 0x4446), BankedAddress(0x7F, 0x4439),  # turning back
        BankedAddress(0x7F, 0x42C4),  # opening the treasure
        BankedAddress(0x7F, 0x445A), BankedAddress(0x7F, 0x4453),  # turning to walk
        BankedAddress(0x7F, 0x430D),  # looking to the front
        BankedAddress(0x7F, 0x5D8B), BankedAddress(0x7F, 0x5D82),  # Ice Skatin': starting (SetState_IceSkatinStart)
        BankedAddress(0x7F, 0x5D97), BankedAddress(0x7F, 0x5D94),  # Ice Skatin'
        BankedAddress(0x7F, 0x5DA7), BankedAddress(0x7F, 0x5D9A),  # Ice Skatin': crashing
        BankedAddress(0x7F, 0x6EC4), BankedAddress(0x7F, 0x6EB4),  # grabbing and hanging from a rail (ObjInteraction_Rail)
        BankedAddress(0x7F, 0x48B6), BankedAddress(0x7F, 0x48B9),  # Zombie Wario: idling (SetState_ZombieIdling)
        BankedAddress(0x7F, 0x4870), BankedAddress(0x7F, 0x4879),  # zombie walking
        BankedAddress(0x7F, 0x489D), BankedAddress(0x7F, 0x4894),  # zombie turning
        BankedAddress(0x7F, 0x48A6), BankedAddress(0x7F, 0x48AB),  # zombie jumping (Func_29be1)
        BankedAddress(0x7F, 0x48B0), BankedAddress(0x7F, 0x48B3),  # zombie falling (Func_29bb9)
        BankedAddress(0x7F, 0x4948), BankedAddress(0x7F, 0x4953),  # zombie landing
        BankedAddress(0x7F, 0x48BC), BankedAddress(0x7F, 0x48D5),  # zombie landing on a floor, slipping
        BankedAddress(0x7F, 0x4928), BankedAddress(0x7F, 0x492B),  # zombie slipping through a floor
        BankedAddress(0x7F, 0x48EE), BankedAddress(0x7F, 0x490B),  # zombie landing after slipping
        BankedAddress(0x7F, 0x492E), BankedAddress(0x7F, 0x493B),  # zombie knocked back
        BankedAddress(0x7F, 0x4882), BankedAddress(0x7F, 0x488B),  # zombie writhing
        BankedAddress(0x7F, 0x4C6C), BankedAddress(0x7F, 0x4C5F),  # Bouncy Wario: in the air, on the floor
        BankedAddress(0x7F, 0x4C75),  # bouncy: against a ceiling
        BankedAddress(0x7F, 0x4C82), BankedAddress(0x7F, 0x4C85),  # bouncy: upside down, landing so
        BankedAddress(0x7F, 0x4CBF), BankedAddress(0x7F, 0x4CB2),  # bouncy: the last bounce
        BankedAddress(0x05, 0x55A0), BankedAddress(0x05, 0x55A3),  # diving from the surface, sinking
        BankedAddress(0x05, 0x5569), BankedAddress(0x05, 0x5573),  # diving, floating up
        BankedAddress(0x05, 0x5576), BankedAddress(0x05, 0x558B),  # swimming
        BankedAddress(0x05, 0x5554), BankedAddress(0x05, 0x555B),  # on the water surface
        BankedAddress(0x05, 0x5562), BankedAddress(0x05, 0x556C),  # thrusting (Prince Froggy's Gloves)
        BankedAddress(0x05, 0x55BE), BankedAddress(0x05, 0x55C5),  # thrusting
        BankedAddress(0x05, 0x55B0), BankedAddress(0x05, 0x55B7),  # trying to submerge
        BankedAddress(0x05, 0x55A6), BankedAddress(0x05, 0x55AB),  # submerged after sinking (Func_2ad6a)
        BankedAddress(0x05, 0x789C), BankedAddress(0x05, 0x78C3),  # Fat Wario: eating (ObjInteraction_Food)
        BankedAddress(0x05, 0x781C), BankedAddress(0x05, 0x781F),  # fat idling
        BankedAddress(0x05, 0x7822), BankedAddress(0x05, 0x782B),  # fat walking
        BankedAddress(0x05, 0x78F3), BankedAddress(0x05, 0x78EA),  # fat turning
        BankedAddress(0x05, 0x7834), BankedAddress(0x05, 0x7839),  # fat jumping (Func_290a1)
        BankedAddress(0x05, 0x783E), BankedAddress(0x05, 0x7841),  # fat falling (Func_290d6)
        BankedAddress(0x05, 0x7872), BankedAddress(0x05, 0x7887),  # fat landing, sinking
        BankedAddress(0x05, 0x78FC), BankedAddress(0x05, 0x7905),  # fat bumping
        BankedAddress(0x05, 0x7844), BankedAddress(0x05, 0x785B),  # fat recovering
        BankedAddress(0x05, 0x71BD), BankedAddress(0x05, 0x715F),  # Flat Wario: getting flat (SetState_FlatAirborne)
        BankedAddress(0x05, 0x718B), BankedAddress(0x05, 0x7175),  # flat idling, walking
        BankedAddress(0x05, 0x7190),  # flat jumping
        BankedAddress(0x05, 0x71B8), BankedAddress(0x05, 0x7186),  # flat falling, left and right
        BankedAddress(0x05, 0x7193),  # flat stretching (SetState_FlatStretching)
        BankedAddress(0x05, 0x719A), BankedAddress(0x05, 0x71A3),  # flat sinking, stretching underwater
        BankedAddress(0x05, 0x716C),  # flat squished, lifting
    ),
)


def _read(view: RomView, start: BankedAddress, length: int, what: str) -> bytes:
    try:
        return view.read_banked(start, length)
    except RomBoundsError as error:
        raise MalformedDataError(f"{what}: {error}") from error


def _signed(byte: int) -> int:
    return byte - 0x100 if byte >= 0x80 else byte


def decode_frameset(view: RomView, start: BankedAddress) -> list[list[int]]:
    """(frame, duration) pairs up to the $ff terminator, which must lie in the same bank."""
    limit = 0x4000 if start.bank == 0 else 0x8000
    data = _read(view, start, min(2 * MAX_FRAMESET_PAIRS, limit - start.address), f"frameset {start}")
    pairs: list[list[int]] = []
    for index in range(0, len(data), 2):
        if data[index] == FRAMESET_END:
            return pairs
        if index + 1 >= len(data):
            break
        pairs.append([data[index], data[index + 1]])
    raise MalformedDataError(f"frameset {start}: no $ff terminator within {len(data)} bytes")


def frameset_key(where: BankedAddress, animation_bank: int) -> str:
    if where.bank == animation_bank:
        return f"{where.address:04x}"
    return f"{where.bank:02x}:{where.address:04x}"


def decode(rom: bytes, layout: MovementLayout = WL3_WORLD_MOVEMENT_LAYOUT) -> dict[str, Any]:
    view = RomView(rom)
    walk = list(_read(view, layout.walk_vel_table, layout.walk_vel_entries, "WalkVelTable"))
    jumps = {name: [_signed(b) for b in _read(view, where, layout.jump_vel_entries, f"jump table {name}")]
             for name, where in layout.jump_vel_tables}
    return {
        "walk_vel_table": {"location": str(layout.walk_vel_table), "steps": walk},
        "jump_vel_tables": [{"id": index + 1, "name": name, "location": str(where), "steps": jumps[name]}
                            for index, (name, where) in enumerate(layout.jump_vel_tables)],
        "swim_vel_tables": {name: {"location": str(where),
                                   "steps": list(_read(view, where, layout.swim_vel_entries, f"swim table {name}"))}
                            for name, where in layout.swim_vel_tables},
        "flat_fall_tables": {name: {"location": str(where),
                                    "steps": list(_read(view, where, layout.flat_fall_entries, f"flat fall table {name}"))}
                             for name, where in layout.flat_fall_tables},
        **({"bubble_drift_table": {"location": str(layout.bubble_drift_table),
                                   "steps": list(_read(view, layout.bubble_drift_table, layout.bubble_drift_entries,
                                                       "bubble drift table"))}}
           if layout.bubble_drift_table else {}),
        # Keyed by the 16-bit pointer the game stores in wWarioFramesetPtr; those outside "Wario OAM 1"
        # (bank $05) by bank and pointer, as UpdateWarioAnimation reads them from the bank it is called in.
        "framesets": {frameset_key(where, layout.animation_bank): {"location": str(where), "pairs": decode_frameset(view, where)}
                      for where in layout.framesets},
    }


def annotate(document: dict[str, Any], symbols: dict[BankedAddress, str] | None) -> dict[str, Any]:
    """Attach optional labels. Labels never change decoded values."""
    if symbols is None:
        return document
    document["walk_vel_table"]["symbol"] = symbols.get(BankedAddress.parse(document["walk_vel_table"]["location"]))
    for item in [*document["jump_vel_tables"], *document["framesets"].values(),
                 *document.get("swim_vel_tables", {}).values(), *document.get("flat_fall_tables", {}).values()]:
        item["symbol"] = symbols.get(BankedAddress.parse(item["location"]))
    return document


def extract(rom_path: Path, out_dir: Path, sym_path: Path | None = None, exploratory: bool = False) -> dict[str, Any]:
    rom = read_rom(rom_path)
    report = inspect_bytes(rom, str(rom_path))
    require_known(report, WL3_WORLD_MOVEMENT_LAYOUT.rom_id, exploratory=exploratory)
    is_exploratory = report.identity.status != "verified"

    document = annotate(decode(rom), load_sym(sym_path) if sym_path else None)
    document.update({
        "format": FORMAT,
        "format_version": FORMAT_VERSION,
        "marker": ROM_DERIVED_MARKER,
        "exploratory": is_exploratory,
        "provenance": {
            "rom_sha256": report.hashes.sha256,
            "rom_id": report.identity.rom_id,
            "extractor": "wl3pc.extract.wario_movement",
            "extractor_version": EXTRACTOR_VERSION,
            "tools_version": TOOLS_VERSION,
            "layout_evidence": bf.DISASSEMBLY,
            "symbol_file_sha256": sha256_file(sym_path) if sym_path else None,
        },
    })
    payload = canonical_json(document)
    target_dir = out_dir / ("exploratory" if is_exploratory else "wl3-original")
    filename = "wario_movement.json"
    changed = write_immutable(target_dir / filename, payload)
    manifest = {
        "format": "wl3pc.extraction-manifest",
        "format_version": 1,
        "marker": ROM_DERIVED_MARKER,
        "rom_sha256": report.hashes.sha256,
        "files": {filename: {"sha256": sha256_bytes(payload), "format": FORMAT, "format_version": FORMAT_VERSION}},
    }
    write_immutable(target_dir / "manifest.wario_movement.json", canonical_json(manifest))
    return {"path": str(target_dir / filename), "sha256": sha256_bytes(payload), "changed": changed,
            "document": document}


def summarise(document: dict[str, Any]) -> str:
    walk = document["walk_vel_table"]["steps"]
    lines = [f"WalkVelTable: {len(walk)} steps {walk}"]
    for table in document["jump_vel_tables"]:
        lines.append(f"jump table {table['id']} ({table['name']}): {table['steps']}")
    for item in document["framesets"].values():
        lines.append(f"frameset {item['location']} {item.get('symbol') or ''}: (frame, duration) {item['pairs']}")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="extract-wario-movement", description=__doc__.splitlines()[0])
    parser.add_argument("--rom", type=Path, default=None)
    parser.add_argument("--out", type=Path, default=CONTENT_OUT_DIR)
    parser.add_argument("--symbols", type=Path, help="RGBDS .sym from a verified reference build (labels only)")
    parser.add_argument("--exploratory", action="store_true", help="allow an unidentified ROM; output is marked")
    args = parser.parse_args(argv)
    rom_path = args.rom or rom_path_from_env()
    try:
        result = extract(rom_path, args.out, args.symbols, args.exploratory)
    except FileNotFoundError as error:
        print(f"extract: missing input: {error.filename}", file=sys.stderr)
        return 2
    except (UnknownRomError, RomFormatError, MalformedDataError) as error:
        print(f"extract: {error}", file=sys.stderr)
        return 3
    print(f"wrote {result['path']} ({'updated' if result['changed'] else 'unchanged'}) sha256 {result['sha256']}")
    print(summarise(result["document"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
