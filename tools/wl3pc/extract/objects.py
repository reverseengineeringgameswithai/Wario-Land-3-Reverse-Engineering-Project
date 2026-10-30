"""Decode the level objects' data: their animation framesets (WL3-035).

Question: how do objects animate?
Evidence (ElectroDeoxys/warioland3 @560fce6, verified byte-identical to the identified ROM):
- UpdateObjectAnimation and UpdateObjectFrame (src/home/object_mechanics.asm) switch to the
  "Object Framesets" bank ($1a) and read (frame, duration) pairs from OBJ_FRAMESET_PTR until a
  $ff frame, which restarts the frameset.
- That section is only src/gfx/oam/object_framesets.asm: framesets back to back from $4000,
  none of them empty. So the bank decodes in order, and the first empty frameset is the padding
  after the section (checked against the reference build's labels).
- The object state routines (update_objects.asm) read velocity tables from
  src/data/object_movements.asm, which fills bank $18 from $4000 to $51ca (StandingFallYVel_Light
  to Data_6104a's end; UpdateObject_Temple follows). They index a table within its 256-byte page,
  so the bytes are kept whole, by address.
- LoadObjectGroupData (src/engine/level/load_objects.asm, bank $19) fills wObjDataPointers with
  DummyObjectData (its `ld bc` at $19:4003), then reads ObjectGroups[wObjectGroup] (4 bytes an entry:
  a common-objects table and a group): the common table's chest, key, and musical coin data pointers,
  then the group's data pointers (after a GFX bank offset byte and 4 GFX pointers) up to $ffff or 13.
  SpawnObject reads an entry's 8 bytes (src/data/object_data.asm `object_data`): ID, interaction type,
  box top, OAM pointer, update function, flags. The Temple's group (OBJECT_GROUP_HIDDEN_FIGURE, $f0)
  goes to LoadHiddenFigureData instead: from wObjDataPtr01 the words at its .pointers up to one
  whose high byte is $ff (its NULL, $ffff), or 13: HiddenFigureData alone; it loads no graphics or
  palettes.
- The same routine decompresses the group's 4 enemy graphics into VRAM bank 1 at $8000, $8400, $8800,
  and $8c00, from banks "Enemy Gfx 1 Slot 1-4" ($68-$6b) plus the group's GFX bank offset, and
  LoadObjPals copies the 4 palettes after the data pointer list to OBJ palettes 4-7; the common
  table's palette goes to OBJ palette 3. LoadLevelCommonGfxAndTreasures copies LevelsCommonGfx
  ($03:4000-$4800, the chest, key, and coins) to $8800 in VRAM bank 0, then LoadLevelTreasureData
  puts the level's treasure tiles over tiles $90-$9f (not extracted: per level, from save data).
  In the oracle, VRAM bank 1 equals the decoded group image in every group the owner's movie
  visits, and bank 0 from $8800 equals LevelsCommonGfx apart from those 16 tiles.
- UpdateObjSprite reads an object's OAM table in bank "Objects OAM 1" ($60) + bits 4-6 of its ID,
  laid out as Wario's (extract/wario_sprites.py): frame pointers, then (y, x, tile, attributes)
  frames ending at $80. The tables decoded are those the object data names, and the stars'.
Research note: docs/02-research/objects.md.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Any

from .. import TOOLS_VERSION
from ..address import BankedAddress, RomView
from ..known_roms import WL3_WORLD_EN_JA
from ..paths import CONTENT_OUT_DIR, rom_path_from_env
from ..provenance import ROM_DERIVED_MARKER, canonical_json, sha256_bytes, write_immutable
from ..rom import RomFormatError, UnknownRomError, inspect_bytes, read_rom, require_known
from . import block_functions as bf
from . import room_gfx, wario_movement, wario_sprites
from .block_functions import MalformedDataError
from .rle import decompress

FORMAT = "wl3pc.objects"
FORMAT_VERSION = 1
EXTRACTOR_VERSION = 45
OBJECT_FRAMESETS_BANK = 0x1A  # BANK("Object Framesets")
MOVEMENT_DATA = BankedAddress(0x18, 0x4000)  # object_movements.asm
MOVEMENT_DATA_SIZE = 0x11CB
# Data in the "Object Functions" banks, read by their objects with `ld a, [bc]` while their bank is
# mapped: what 1 and 2 start with (level.asm: 1's Data_40000, y offsets; 2's Data_44000, _44020,
# _44050, the bubble's drift), 3's Data_4a5a9 (the small Octohon's sway, octohon.asm), and 4's
# Data_4caed and _4cb0d (Muddee's stingers' offsets, muddee_stinger.asm), and 5's Data_54000 and
# _54010 (Shoot's kick: Wario's jump and the kicked ball's rise, level.asm); and 4's Data_4c000 to
# Data_4c800, up to Func_4c860 (the hidden figure's hands' paths, hidden_figure.asm).
BANK_DATA = ((BankedAddress(0x10, 0x4000), 0x40), (BankedAddress(0x11, 0x4000), 0x80),
             (BankedAddress(0x13, 0x4000), 0x860),
             (BankedAddress(0x12, 0x65A9), 0xF1), (BankedAddress(0x13, 0x4AED), 0x40),
             (BankedAddress(0x15, 0x4000), 0x20))
OBJECT_LOADING_BANK = 0x19  # "Object Loading": LoadObjectGroupData, SpawnObject, the object data
OBJECT_GROUPS = BankedAddress(0x19, 0x5009)  # ObjectGroups (LoadObjectGroupData's `ld hl`)
DUMMY_OBJECT_DATA_OPERAND = BankedAddress(0x19, 0x4004)  # the operand of `ld bc, DummyObjectData`
NUM_OBJECT_GROUPS = 146  # src/constants/object_constants.asm
HIDDEN_FIGURE_POINTERS = BankedAddress(0x19, 0x43BF)  # LoadHiddenFigureData.pointers
OBJ_DATA_POINTERS = 16  # wObjDataPointers: chest, key, musical coin, then 13
GROUP_DATA_POINTERS = 13
OBJECT_DATA_SIZE = 8
ENEMY_GFX_SLOT_BANKS = (0x68, 0x69, 0x6A, 0x6B)
ENEMY_GFX_SLOT_OFFSETS = (0x000, 0x400, 0x800, 0xC00)  # in VRAM bank 1 from $8000
ENEMY_VRAM_SIZE = 0x1000
OBJECTS_OAM_BANK = 0x60  # BANK("Objects OAM 1")
STARS_OAM = BankedAddress(0x63, 0x4000)  # OAM_18c000, set by VanishObject_NoSFX
# Tables of objects the game creates rather than spawns (src/data/object_params.asm), met in the
# owner's movie: OAM_180003 (the coin a broken block gives).
CREATED_OBJECT_OAM = (BankedAddress(0x60, 0x4003),)
# Object params (src/data/object_params.asm, bank $19) that ported code creates objects from: ID,
# interaction type, box, OAM and frameset pointers, state duration, vars 1-3, substate, state,
# update function, and flags (19 bytes), after a y and x offset for _CreateObjectAtRelativePos
# (True: 21 bytes); _CreateObjectFromCurObjPos's have none.
OBJECT_PARAMS = (
    (BankedAddress(0x19, 0x478B), True),  # ObjParams_HebariiProjectile (HebariiFunc)
    (BankedAddress(0x19, 0x47A0), True),  # ObjParams_WebberProjectile
    (BankedAddress(0x19, 0x49C2), True),  # ObjParams_BirdStars1
    (BankedAddress(0x19, 0x49D7), True),  # ObjParams_BirdStars2
    (BankedAddress(0x19, 0x481E), True),  # ObjParams_DoughnutLeft (DoughnuteerFunc)
    (BankedAddress(0x19, 0x4833), True),  # ObjParams_DoughnutRight
    (BankedAddress(0x19, 0x4848), True),  # ObjParams_DoughnutUpLeft
    (BankedAddress(0x19, 0x485D), True),  # ObjParams_DoughnutUpRight
    (BankedAddress(0x19, 0x48C6), True),  # ObjParams_ZombieHeadLeft (ZombieFunc)
    (BankedAddress(0x19, 0x48DB), True),  # ObjParams_ZombieHeadRight
    (BankedAddress(0x19, 0x48F0), True),  # ObjParams_StarsLeft (HammerBotFunc, stunned)
    (BankedAddress(0x19, 0x4905), True),  # ObjParams_StarsRight
    (BankedAddress(0x19, 0x49EC), True),  # ObjParams_SnowflakeLeft (BrrrBearFunc)
    (BankedAddress(0x19, 0x4A01), True),  # ObjParams_SnowflakeRight
    (BankedAddress(0x19, 0x4A40), True),  # ObjParams_GreyTreasure
    (BankedAddress(0x19, 0x4A55), True),  # ObjParams_RedTreasure
    (BankedAddress(0x19, 0x4A6A), True),  # ObjParams_GreenTreasure
    (BankedAddress(0x19, 0x4A7F), True),  # ObjParams_BlueTreasure
    (BankedAddress(0x19, 0x4CB6), True),  # ObjParams_Tadpole (TadpoleSpawnerFunc)
    (BankedAddress(0x19, 0x4E06), True),  # ObjParams_Omodon2 (OmodonmekaWithOmodon2Func)
    (BankedAddress(0x19, 0x4E1B), True),  # ObjParams_Omodon1
    (BankedAddress(0x19, 0x4DC7), True),  # ObjParams_HiddenFigureFace (HiddenFigureFunc)
    (BankedAddress(0x19, 0x4DDC), True),  # ObjParams_HiddenFigureLeftHand
    (BankedAddress(0x19, 0x4DF1), True),  # ObjParams_HiddenFigureRightHand
    (BankedAddress(0x19, 0x491A), True),  # ObjParams_BeamLeft (BeamBotFunc)
    (BankedAddress(0x19, 0x492F), True),  # ObjParams_BeamRight
    (BankedAddress(0x19, 0x4944), True),  # ObjParams_AppleLeft (ApplebyFunc)
    (BankedAddress(0x19, 0x4959), True),  # ObjParams_AppleRight
    (BankedAddress(0x19, 0x4B7B), True),  # ObjParams_SnakeFireLeft (SnakeFunc)
    (BankedAddress(0x19, 0x4B90), True),  # ObjParams_SnakeFireRight
    (BankedAddress(0x19, 0x4EDF), False),  # ObjParams_Bubble (BubbleHoleFunc)
    (BankedAddress(0x19, 0x4ECC), False),  # ObjParams_ElectricLampSpark (ElectricLampFunc)
    (BankedAddress(0x19, 0x4EF2), False),  # ObjParams_FallingSnow (FallingSnowSpawnerFunc)
    (BankedAddress(0x19, 0x4F05), False),  # ObjParams_StarsAbove (RoboMouseFunc)
    (BankedAddress(0x19, 0x4872), True),  # ObjParams_InvisibilityPotionLeft (MadSciensteinFunc)
    (BankedAddress(0x19, 0x4887), True),  # ObjParams_InvisibilityPotionRight
    (BankedAddress(0x19, 0x489C), True),  # ObjParams_InvisibilityPotionDropLeft
    (BankedAddress(0x19, 0x48B1), True),  # ObjParams_InvisibilityPotionDropRight
    (BankedAddress(0x19, 0x496E), True),  # ObjParams_SunFlameLeft (SunFunc)
    (BankedAddress(0x19, 0x4983), True),  # ObjParams_SunFlameRight
    (BankedAddress(0x19, 0x4998), True),  # ObjParams_MoonStarLeft (MoonFunc)
    (BankedAddress(0x19, 0x49AD), True),  # ObjParams_MoonStarRight
    (BankedAddress(0x19, 0x4A16), True),  # ObjParams_MizzouProjectileLeft (MizuuoFunc)
    (BankedAddress(0x19, 0x4A2B), True),  # ObjParams_MizzouProjectileRight
    (BankedAddress(0x19, 0x47DF), True),  # ObjParams_BigLeaf1 (BigLeafSpawnerFunc)
    (BankedAddress(0x19, 0x47F4), True),  # ObjParams_BigLeaf2
    (BankedAddress(0x19, 0x4809), True),  # ObjParams_BigLeaf3
    (BankedAddress(0x19, 0x4BCF), True),  # ObjParams_HighRollingRockLeft (WormwouldFunc)
    (BankedAddress(0x19, 0x4BE4), True),  # ObjParams_HighRollingRockRight
    (BankedAddress(0x19, 0x4BF9), True),  # ObjParams_LowRollingRockLeft
    (BankedAddress(0x19, 0x4C0E), True),  # ObjParams_LowRollingRockRight
    (BankedAddress(0x19, 0x4D73), True),  # ObjParams_MagicSpiralLeft (WolfenbossFunc)
    (BankedAddress(0x19, 0x4D88), True),  # ObjParams_MagicSpiralRight
    (BankedAddress(0x19, 0x4D9D), True),  # ObjParams_IgaguriLeft
    (BankedAddress(0x19, 0x4DB2), True),  # ObjParams_IgaguriRight
    (BankedAddress(0x19, 0x4F9D), False),  # ObjParams_Kuri (IgaguriFunc)
    (BankedAddress(0x19, 0x4BA5), True),  # ObjParams_DollBoyHammer (DollBoyFunc)
    (BankedAddress(0x19, 0x4E30), True),  # ObjParams_DollBoyHammerStarsLeft
    (BankedAddress(0x19, 0x4E45), True),  # ObjParams_DollBoyHammerStarsRight
    (BankedAddress(0x19, 0x4FB0), False),  # ObjParams_StarsCentre (DollBoyHammerFunc)
    (BankedAddress(0x19, 0x4BBA), True),  # ObjParams_HammerPlatform (HammerPlatformSpawnerFunc)
    (BankedAddress(0x19, 0x4F18), False),  # ObjParams_YellowBellyHead (YellowBellyBodyFunc)
    (BankedAddress(0x19, 0x4F2B), False),  # ObjParams_Pump
    (BankedAddress(0x19, 0x4C62), True),  # ObjParams_YellowBellyArrowLeft
    (BankedAddress(0x19, 0x4C77), True),  # ObjParams_YellowBellyArrowRight
    (BankedAddress(0x19, 0x4A94), True),  # ObjParams_AnonsterSilk1Left (AnonsterFunc)
    (BankedAddress(0x19, 0x4AA9), True),  # ObjParams_AnonsterSilk1Right
    (BankedAddress(0x19, 0x4ABE), True),  # ObjParams_AnonsterSilk2Left
    (BankedAddress(0x19, 0x4AD3), True),  # ObjParams_AnonsterSilk2Right
    (BankedAddress(0x19, 0x4AE8), True),  # ObjParams_AnonsterSilk3Left
    (BankedAddress(0x19, 0x4AFD), True),  # ObjParams_AnonsterSilk3Right
    (BankedAddress(0x19, 0x4B12), True),  # ObjParams_AnonsterWaveLeft
    (BankedAddress(0x19, 0x4B27), True),  # ObjParams_AnonsterWaveRight
    (BankedAddress(0x19, 0x4B3C), True),  # ObjParams_SilkPlatform1 (SilkPlatformsFunc)
    (BankedAddress(0x19, 0x4B51), True),  # ObjParams_SilkPlatform2
    (BankedAddress(0x19, 0x4B66), True),  # ObjParams_SilkPlatform3
    (BankedAddress(0x19, 0x4F51), False),  # ObjParams_ScrowlerTentacleRight (ScowlerFunc)
    (BankedAddress(0x19, 0x4F64), False),  # ObjParams_ScrowlerTentacleLeft
    (BankedAddress(0x19, 0x4CCB), True),  # ObjParams_InkLeft
    (BankedAddress(0x19, 0x4CE0), True),  # ObjParams_InkRight
    (BankedAddress(0x19, 0x4CF5), True),  # ObjParams_FloatingRing (FloatingRingSpawnerFunc)
    (BankedAddress(0x19, 0x4F77), False),  # ObjParams_MuddeeStinger1 (MuddeeFunc)
    (BankedAddress(0x19, 0x4F8A), False),  # ObjParams_MuddeeStinger2
    (BankedAddress(0x19, 0x4D0A), True),  # ObjParams_Skull1 (SkullSpawnerFunc)
    (BankedAddress(0x19, 0x4D1F), True),  # ObjParams_Skull2
    (BankedAddress(0x19, 0x4D34), True),  # ObjParams_Skull3
    (BankedAddress(0x19, 0x4D49), True),  # ObjParams_Skull4
    (BankedAddress(0x19, 0x4D5E), True),  # ObjParams_JamanoHat (JamanoFunc)
    (BankedAddress(0x19, 0x4C23), True),  # ObjParams_PalmTreeShort (PalmTreeSpawnerFunc)
    (BankedAddress(0x19, 0x4C38), True),  # ObjParams_PalmTreeMedium
    (BankedAddress(0x19, 0x4C4D), True),  # ObjParams_PalmTreeTall
    (BankedAddress(0x19, 0x4E5A), False),  # ObjParams_Coin (BreakBlock)
    (BankedAddress(0x19, 0x4E6D), False),  # ObjParams_ColourCoin (BreakBlockWithColourCoin)
    (BankedAddress(0x19, 0x4E80), False),  # ObjParams_TorchEmberLeft1 (TorchFunc)
    (BankedAddress(0x19, 0x4E93), False),  # ObjParams_TorchEmberRight1
    (BankedAddress(0x19, 0x4EA6), False),  # ObjParams_TorchEmberLeft2
    (BankedAddress(0x19, 0x4EB9), False),  # ObjParams_TorchEmberRight2
)
OBJECT_PARAMS_SIZE = 19
OBJECT_PARAMS_OFFSETS = 2
# The particles' framesets and OAM tables (src/engine/level/particles.asm, bank $03), named after
# their file offsets as each ParticleAnim_* loads them.
PARTICLES_BANK = 0x03
PARTICLE_FRAMESETS = (0x549A, 0x54BA, 0x54C5, 0x54EA, 0x54F3, 0x5502, 0x550B, 0x5525, 0x5591, 0x5622,
                      0x56E4, 0x56FD, 0x575A, 0x57B4, 0x5806, 0x58E7, 0x58F4, 0x5901)
PARTICLE_OAM_TABLES = (0x520E, 0x5532, 0x55AE, 0x562B, 0x5716, 0x5763, 0x57BD, 0x580D)
PARTICLE_PALETTE = BankedAddress(PARTICLES_BANK, 0x51FE)  # Pals_d1fe, OBJ palette 2 from each room start
LEVELS_COMMON_GFX = BankedAddress(0x03, 0x4000)  # LevelsCommonGfx, to $8800 in VRAM bank 0
LEVELS_COMMON_GFX_SIZE = 0x800
FRAMESET_END = 0xFF
BANK_END = 0x8000


def decode_framesets(rom: bytes, bank: int = OBJECT_FRAMESETS_BANK) -> dict[str, list[list[int]]]:
    """Every frameset of the bank, keyed by its 16-bit pointer in hex, as (frame, duration) pairs."""
    view = RomView(rom)
    data = view.read_banked(BankedAddress(bank, 0x4000), BANK_END - 0x4000)
    framesets: dict[str, list[list[int]]] = {}
    offset = 0
    while offset < len(data):
        start = offset
        pairs: list[list[int]] = []
        while offset < len(data) and data[offset] != FRAMESET_END:
            if offset + 1 >= len(data):
                raise MalformedDataError(f"frameset {bank:02x}:{0x4000 + start:04x} runs past the bank")
            pairs.append([data[offset], data[offset + 1]])
            offset += 2
        if offset >= len(data):
            raise MalformedDataError(f"frameset {bank:02x}:{0x4000 + start:04x} has no $ff terminator")
        offset += 1
        if not pairs:
            break  # the section's padding
        framesets[f"{0x4000 + start:04x}"] = pairs
    return framesets


def _word(view: RomView, bank: int, address: int) -> int:
    low, high = view.read_banked(BankedAddress(bank, address), 2)
    return low | (high << 8)


def decode_object_groups(rom: bytes) -> dict[str, Any]:
    """Each group's wObjDataPointers as LoadObjectGroupData leaves it, and every object data entry they name."""
    view = RomView(rom)
    bank = OBJECT_LOADING_BANK
    dummy = _word(view, DUMMY_OBJECT_DATA_OPERAND.bank, DUMMY_OBJECT_DATA_OPERAND.address)
    groups = []
    for index in range(NUM_OBJECT_GROUPS):
        entry = OBJECT_GROUPS.address + 4 * index
        common, group = _word(view, bank, entry), _word(view, bank, entry + 2)
        pointers = [dummy] * OBJ_DATA_POINTERS
        pointers[0:3] = [_word(view, bank, common + 2 * i) for i in range(3)]
        listed = group + 1 + 2 * 4  # after the GFX bank offset and the 4 GFX pointers
        for i in range(GROUP_DATA_POINTERS):
            value = _word(view, bank, listed + 2 * i)
            if value >> 8 == 0xFF:
                break
            pointers[3 + i] = value
        # What LoadObjectGroupData puts in VRAM bank 1 and OBJ palettes 4-7.
        gfx_offset = view.read_banked(BankedAddress(bank, group), 1)[0]
        vram = bytearray(ENEMY_VRAM_SIZE)
        written = []  # [start, end) of each slot's write; the rest keeps what VRAM held before
        for slot in range(4):
            source = BankedAddress(ENEMY_GFX_SLOT_BANKS[slot] + gfx_offset, _word(view, bank, group + 1 + 2 * slot))
            data, _ = decompress(view, source, ENEMY_VRAM_SIZE)
            start = ENEMY_GFX_SLOT_OFFSETS[slot]
            vram[start:start + len(data)] = data[:ENEMY_VRAM_SIZE - start]
            written.append([start, min(start + len(data), ENEMY_VRAM_SIZE)])
        pals_at = listed + 2 * min(GROUP_DATA_POINTERS, i + 1 if value >> 8 == 0xFF else GROUP_DATA_POINTERS)
        palettes = view.read_banked(BankedAddress(bank, pals_at), 32)
        common_palette = view.read_banked(BankedAddress(bank, common + 6), 8)
        groups.append({"common": f"{common:04x}", "group": f"{group:04x}",
                       "obj_data_pointers": [f"{value:04x}" for value in pointers],
                       "enemy_vram": bytes(vram).hex(), "enemy_vram_written": written, "palettes": room_gfx.decode_palettes(palettes + bytes(32))[:4],
                       "common_palette": room_gfx.decode_palettes(common_palette + bytes(56))[0]})
    hidden_figure = [dummy] * OBJ_DATA_POINTERS
    for i in range(GROUP_DATA_POINTERS):
        value = _word(view, bank, HIDDEN_FIGURE_POINTERS.address + 2 * i)
        if value >> 8 == 0xFF:
            break
        hidden_figure[3 + i] = value
    used = sorted({int(value, 16) for g in groups for value in g["obj_data_pointers"]}
                  | {value for value in hidden_figure if 0x4000 <= value < 0x8000})
    data = {f"{pointer:04x}": view.read_banked(BankedAddress(bank, pointer), OBJECT_DATA_SIZE).hex()
            for pointer in used}
    # Each object's OAM table: bank $60 + bits 4-6 of its ID, the pointer from its data.
    tables = {(where.bank, where.address) for where in (STARS_OAM, *CREATED_OBJECT_OAM)}
    for entry in data.values():
        raw = bytes.fromhex(entry)
        tables.add((OBJECTS_OAM_BANK + ((raw[0] >> 4) & 7), raw[3] | (raw[4] << 8)))
    oam_tables = {}
    for table_bank, pointer in sorted(tables):
        key = f"{table_bank:02x}:{pointer:04x}"
        if not 0x4000 <= pointer < 0x8000:
            oam_tables[key] = {"error": "not a ROMX pointer"}
            continue
        try:
            oam_tables[key] = wario_sprites.decode_oam_table(view, BankedAddress(table_bank, pointer))
        except MalformedDataError as error:
            oam_tables[key] = {"error": str(error)}
    params = {}
    for where, offsets in OBJECT_PARAMS:
        raw = view.read_banked(where, OBJECT_PARAMS_SIZE + (OBJECT_PARAMS_OFFSETS if offsets else 0))
        params[f"{where.address:04x}"] = raw.hex()
        fields = raw[OBJECT_PARAMS_OFFSETS:] if offsets else raw
        tables.add((OBJECTS_OAM_BANK + ((fields[0] >> 4) & 7), fields[6] | (fields[7] << 8)))
    for table_bank, pointer in sorted(tables):
        key = f"{table_bank:02x}:{pointer:04x}"
        if key not in oam_tables and 0x4000 <= pointer < 0x8000:
            oam_tables[key] = wario_sprites.decode_oam_table(view, BankedAddress(table_bank, pointer))
    common_gfx = view.read_banked(LEVELS_COMMON_GFX, LEVELS_COMMON_GFX_SIZE)
    return {"bank": f"{bank:02x}", "groups": groups,
            "hidden_figure_group": [f"{value:04x}" for value in hidden_figure], "object_data": data,
            "oam_tables": oam_tables, "object_params": params, "common_gfx": common_gfx.hex()}


def decode_particles(rom: bytes) -> dict[str, Any]:
    """The particles' framesets ((frame, duration) pairs to $ff) and OAM tables, keyed by pointer."""
    view = RomView(rom)
    framesets = {}
    for pointer in PARTICLE_FRAMESETS:
        framesets[f"{pointer:04x}"] = wario_movement.decode_frameset(view, BankedAddress(PARTICLES_BANK, pointer))
    tables = {f"{pointer:04x}": wario_sprites.decode_oam_table(view, BankedAddress(PARTICLES_BANK, pointer))
              for pointer in PARTICLE_OAM_TABLES}
    palette = room_gfx.decode_palettes(view.read_banked(PARTICLE_PALETTE, 8) + bytes(56))[0]
    return {"bank": f"{PARTICLES_BANK:02x}", "framesets": framesets, "oam_tables": tables, "palette": palette}


# Pneumo's bob (src/level.asm), at the start of object bank $11: signed Y steps to $80.
PNEUMO_BOB = BankedAddress(0x11, 0x4000)
PNEUMO_BOB_SIZE = 32
# The Omodon carrier's bob under Flat Wario (src/level.asm), at the start of object bank $10.
OMODON_BOB = BankedAddress(0x10, 0x4000)
OMODON_BOB_SIZE = 64
# A frameset pointer of 0 (the hand's until it first rises) makes UpdateObjectAnimation read ROM0
# from $0000, the reset vector and zeros: its pairs up to the first $ff at a pair boundary.
NULL_FRAMESET = BankedAddress(0x00, 0x0000)
# Framesets entered past their first pair, which restart there: Shoot jumping out of its ball
# (Frameset_6a022 + 2 and Frameset_6a03a + 2, shoot.asm).
MID_FRAMESETS = (BankedAddress(OBJECT_FRAMESETS_BANK, 0x6024), BankedAddress(OBJECT_FRAMESETS_BANK, 0x603C))


def decode(rom: bytes) -> dict[str, Any]:
    movement = RomView(rom).read_banked(MOVEMENT_DATA, MOVEMENT_DATA_SIZE)
    framesets = decode_framesets(rom)
    framesets[f"{NULL_FRAMESET.address:04x}"] = wario_movement.decode_frameset(RomView(rom), NULL_FRAMESET)
    for where in MID_FRAMESETS:
        framesets[f"{where.address:04x}"] = wario_movement.decode_frameset(RomView(rom), where)
    return {"framesets": {"bank": f"{OBJECT_FRAMESETS_BANK:02x}", "by_pointer": framesets},
            "movement_data": {"location": str(MOVEMENT_DATA), "bytes": movement.hex()},
            "bank_data": {str(location): RomView(rom).read_banked(location, size).hex()
                          for location, size in BANK_DATA},
            "object_groups": decode_object_groups(rom), "particles": decode_particles(rom),
            "pneumo_bob": {"location": str(PNEUMO_BOB),
                           "bytes": RomView(rom).read_banked(PNEUMO_BOB, PNEUMO_BOB_SIZE).hex()},
            "omodon_bob": {"location": str(OMODON_BOB),
                           "bytes": RomView(rom).read_banked(OMODON_BOB, OMODON_BOB_SIZE).hex()}}


def extract(rom_path: Path, out_dir: Path, exploratory: bool = False) -> dict[str, Any]:
    rom = read_rom(rom_path)
    report = inspect_bytes(rom, str(rom_path))
    require_known(report, WL3_WORLD_EN_JA.rom_id, exploratory=exploratory)
    is_exploratory = report.identity.status != "verified"
    document = decode(rom)
    document.update({
        "format": FORMAT, "format_version": FORMAT_VERSION, "marker": ROM_DERIVED_MARKER,
        "exploratory": is_exploratory,
        "provenance": {"rom_sha256": report.hashes.sha256, "rom_id": report.identity.rom_id,
                       "extractor": "wl3pc.extract.objects", "extractor_version": EXTRACTOR_VERSION,
                       "tools_version": TOOLS_VERSION, "layout_evidence": bf.DISASSEMBLY},
    })
    payload = canonical_json(document)
    target = out_dir / ("exploratory" if is_exploratory else "wl3-original")
    changed = write_immutable(target / "objects.json", payload)
    return {"path": str(target / "objects.json"), "sha256": sha256_bytes(payload), "changed": changed,
            "document": document}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="extract-objects", description=__doc__.splitlines()[0])
    parser.add_argument("--rom", type=Path, default=None)
    parser.add_argument("--out", type=Path, default=CONTENT_OUT_DIR)
    parser.add_argument("--exploratory", action="store_true", help="allow an unidentified ROM; output is marked")
    args = parser.parse_args(argv)
    try:
        result = extract(args.rom or rom_path_from_env(), args.out, args.exploratory)
    except FileNotFoundError as error:
        print(f"extract: missing input: {error.filename}", file=sys.stderr)
        return 2
    except (UnknownRomError, RomFormatError, MalformedDataError) as error:
        print(f"extract: {error}", file=sys.stderr)
        return 3
    framesets = result["document"]["framesets"]["by_pointer"]
    print(f"wrote {result['path']} ({'updated' if result['changed'] else 'unchanged'}) sha256 {result['sha256']}")
    print(f"  {len(framesets)} object framesets")
    return 0


if __name__ == "__main__":
    sys.exit(main())
