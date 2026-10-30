"""Per-frame traces of Wario's variables from the emulator oracle, for native movement parity (WL3-012).

A trace lists named WRAM/HRAM variables and their values before the first tick (frames[0]) and after
every tick (frames[t + 1] after tick t). Multi-byte values are big-endian, as the game stores them;
signed bytes (the collision box) are kept raw.

Frame boundaries do not fall at a fixed point of the game loop: after a slow frame, the next frame's
UpdateJoypad can run before the emulator's frame ends (observed when an attack loads Wario's
graphics). So the trace also records every Wario update exactly, through execution hooks: the
variables on entry to UpdateWarioStates (07:4000, after UpdateJoypad) and on entry to UpdateObjects
(18:5348), which UpdateLevel calls next on all three of its paths with no Wario code in between.
The native parity check runs one update from `before` and compares with `after`; object code and
interactions, which run later in the frame, are outside the comparison.
Research note: docs/02-research/wario-movement.md.
"""

from __future__ import annotations

import base64
import gzip
from dataclasses import dataclass
from typing import Any, Callable

from . import oracle
from .provenance import ROM_DERIVED_MARKER, sha256_bytes

FORMAT_VERSION = 1
# (name, address, size); addresses from the reference .sym (ElectroDeoxys @560fce6), checked by a test.
WARIO_VARIABLES: tuple[tuple[str, int, int], ...] = (
    ("wGlobalCounter", 0xC08F, 1), ("wJoypadDown", 0xC093, 1), ("wJoypadPressed", 0xC094, 1),
    ("wState", 0xC09B, 1), ("wSubState", 0xC09C, 1), ("wLevelRoomID", 0xC0A0, 1), ("wRoom", 0xC0C9, 1),
    ("wCameraConfigFlags", 0xC0BA, 1), ("wCameraYDelta", 0xC0C2, 1), ("wCameraXDelta", 0xC0C3, 1),
    ("wCollisionPoints", 0xC0D6, 1), ("wRoomTransitionParam", 0xC0D7, 1), ("wWaterInteraction", 0xC0DB, 1),
    ("wc0dc", 0xC0DC, 1), ("wIsOnSlipperyGround", 0xC0DE, 1), ("wWarioSlopeInteraction", 0xC189, 1),
    ("wUnused_c18d", 0xC18D, 1), ("wWarioAnimationEnded", 0xC1A8, 1), ("wFloorTransitionTimer", 0xC1A9, 1),
    ("wFloorTransitionDir", 0xC1AA, 1), ("wLadderInteraction", 0xC1C7, 1), ("wIsNearFence", 0xC1C8, 1),
    ("wIsInAirCurrent", 0xC1C9, 1), ("wc1ca", 0xC1CA, 1), ("wLevel", 0xCA06, 1),
    ("wPowerUpLevel", 0xCA3C, 1), ("wWarioYPos", 0xCA61, 2), ("wWarioXPos", 0xCA63, 2),
    ("wFrameDuration", 0xCA67, 1), ("wAnimationFrame", 0xCA68, 1), ("wDirection", 0xCA69, 1),
    ("wCollisionBoxTop", 0xCA6F, 1), ("wCollisionBoxBottom", 0xCA70, 1), ("wCollisionBoxLeft", 0xCA71, 1),
    ("wCollisionBoxRight", 0xCA72, 1), ("wIsFloorTransition", 0xCA73, 1), ("wJumpVelTable", 0xCA74, 1),
    ("wJumpVelIndex", 0xCA75, 1),
    ("wDoFullJump", 0xCA76, 1), ("wJumpingUpwards", 0xCA77, 1), ("wFloor", 0xCA78, 1),
    ("wWarioFramesetPtr", 0xCA81, 2), ("wWarioState", 0xCA83, 1), ("wWarioStateCounter", 0xCA84, 1),
    ("wWarioStateCycles", 0xCA85, 1), ("wWalkVelIndex", 0xCA86, 1), ("wAttackCounter", 0xCA89, 1),
    ("wIsIntangible", 0xCA8A, 1), ("wIsCrouching", 0xCA8B, 1), ("wInvincibleCounter", 0xCA8C, 1),
    ("wTransformation", 0xCA8E, 1),
    ("wTransformationProgress", 0xCA8F, 1),
    ("wIsTurning", 0xCA95, 1), ("wIsSmashAttacking", 0xCA96, 1), ("wGroundShakeCounter", 0xCA97, 1),
    ("wIsGettingOffLadder", 0xCA99, 1), ("wGrabState", 0xCA9A, 1), ("wIsRolling", 0xCA9D, 1),
    ("wIsInSand", 0xCAA0, 1),
    ("wCoinCooldown", 0xCAC2, 1), ("wCameraSCY", 0xCAC4, 2), ("wCameraSCX", 0xCAC6, 2),
    ("wIsOnSteppableObject", 0xCAC9, 1), ("wJumpCollision", 0xCED2, 1),
    ("wSFXLoopCounter", 0xCEED, 1), ("hYPos", 0xFFA8, 2), ("hXPos", 0xFFAA, 2),
    # The level camera (src/engine/level/camera.asm) and the scroll registers' shadows.
    ("wSCY", 0xC083, 1), ("wSCX", 0xC085, 1), ("wCameraRoomXScrollLimit", 0xC0B5, 1),
    ("wRoomLowerYLimit", 0xC0B6, 1), ("wRoomUpperYLimit", 0xC0B7, 1), ("wRoomLeftXLimit", 0xC0B8, 1),
    ("wRoomRightXLimit", 0xC0B9, 1), ("wLevelEdgeUpdateFlags", 0xC0BB, 1), ("wSCYShake", 0xC0BC, 1),
    ("wScrollDownEdge", 0xC0BD, 1), ("wScrollUpEdge", 0xC0BE, 1), ("wScrollLeftEdge", 0xC0BF, 1),
    ("wScrollRightEdge", 0xC0C0, 1), ("wc0d4", 0xC0D4, 1), ("wc0d5", 0xC0D5, 1),
    ("wIsDMATransferPending", 0xC1A0, 1), ("wPrevWarioScreenYPos", 0xCA5E, 1), ("wCamRightSpacing", 0xCA5F, 1),
    ("wCamLeftSpacing", 0xCA60, 1), ("wWarioScreenYPos", 0xCA87, 1), ("wWarioScreenXPos", 0xCA88, 1),
    ("wCameraRoomYScrollLimit", 0xCAC8, 1),
    # What DrawWario draws (src/home/sprite.asm) and the graphics behind it (LoadWarioGfx, SetWarioPal).
    ("wWarioFrame", 0xCA65, 1), ("wWarioAttributes", 0xCA66, 1), ("wWarioPalsPtr", 0xCA79, 2),
    ("wDMASourceBank", 0xCA7B, 1), ("wDMASourcePtr", 0xCA7C, 2), ("wWarioOAMBank", 0xCA7E, 1),
    ("wWarioOAMPtr", 0xCA7F, 2), ("wInvisibleFrame", 0xCA8D, 1),
    # Globals the objects read (WL3-035).
    ("wDayNight", 0xCA3B, 1), ("wccec", 0xCCEC, 1), ("wLevelEndScreen", 0xCED4, 1), ("wObjectGroup", 0xC0C8, 1),
    ("wSwitchStateUpdated", 0xCA6A, 1), ("wSwitchState", 0xCA6B, 1),
    ("wShootGoals", 0x01_D144, 1),  # WRAMX bank 1 ("Level Objects WRAM"): bank << 16 | address
    ("wAutoMoveState", 0xCA9B, 1), ("wPickedUpWiggleCounter", 0xCA9E, 1), ("wPickedUpFrameCounter", 0xCA9F, 1),
    ("wIsMinigameCleared", 0xCAC1, 1), ("wMultiBlockParam", 0xCEDA, 1),
    # What interactions read and change (WL3-035).
    ("wTouchState", 0xCA93, 1), ("wStingTouchState", 0xCA92, 1), ("wca94", 0xCA94, 1), ("wNumCoins", 0xCA04, 2),
    ("wNumMusicalCoins", 0xCA5C, 1),
    # Keys, treasures, and the key's pause (WL3-040).
    ("wKeyAndTreasureFlags", 0xCA5B, 1), ("wTimer", 0xCEE5, 1), ("wResetDisabled", 0xC09A, 1),
    # What a golf visit depends on outside the level (WL3-050): the price and the holes by the
    # treasures (BCD), the coin message by the language.
    ("wNumCollectedTreasures", 0xCA39, 2), ("wLanguage", 0xCA46, 1),
    # A level resumed from a save (bits 2-5): StartRoom_FromLevelStart then skips its setup.
    ("wceef", 0xCEEF, 1),
    # The treasures' byte holding TRUCK_WHEEL, the only one a level reads (CartVariableFunc's
    # IsTreasureCollected): wTreasuresCollected + 7 in WRAMX bank 2.
    ("wTreasuresCollected7", 0x02_D007, 1),
    # Transformations' timers (WL3-034).
    ("wTransformationDuration", 0xCA90, 2),
    # The particles' (WL3-040).
    ("wCurParticleAnimEnded", 0xCCE6, 1),
    # The room's animated tiles and palette cycle (WL3-037).
    ("wAnimatedTilesGroup", 0xC1AB, 1), ("wAnimatedTilesFrameDuration", 0xC1AC, 1), ("wAnimatedTilesGfx", 0xC1AD, 1),
    ("wAnimatedTilesFrame", 0xC1AE, 1), ("wAnimatedTilesFrameCount", 0xC1AF, 1), ("wRoomPalCycle", 0xC1B0, 1),
    ("wRoomPalCycleDuration", 0xC1B1, 1), ("wRoomPalCycleIndex", 0xC1B4, 1), ("wRoomPalCycleCounter", 0xC1B5, 1),
    ("wRoomAnimatedTilesEnabled", 0xCED8, 1), ("wRoomAnimatedPalsEnabled", 0xCED9, 1),
    # Water (WL3-034).
    ("wSwimVelIndex", 0xCA6D, 1), ("wWaterSurfaceFloatingCounter", 0xCA6E, 1), ("wSwimmingDirectionInput", 0xCA9C, 1),
    ("wc0e0", 0xC0E0, 1), ("wc0e1", 0xC0E1, 1), ("wIsInWaterOrSand", 0xC0DD, 1), ("wWaterCurrent", 0xCEE0, 1),
    ("wLastWaterCurrent", 0xCEE1, 1), ("wCurWaterCurrent", 0xCEE2, 1),
    # The hidden figure's fight (the Temple, WL3-048): its shake and the scroll and window it keeps.
    ("wHiddenFigureSCYShake", 0xC089, 1), ("wc08a", 0xC08A, 1), ("wc08b", 0xC08B, 1), ("wc08c", 0xC08C, 1),
    ("wc08d", 0xC08D, 1),
)


UPDATE_WARIO_STATES = (0x07, 0x4000)  # UpdateWarioStates
# The room animations' first instruction is `ldh a, [rLY]` (skipped late in the frame): hooked at the
# next, where register A holds the line read. 0: UpdateRoomAnimatedTiles, 1: UpdateRoomAnimatedPals.
ANIMATION_CALLS = ((0x34, 0x4002), (0x00, 0x2A79))
# UpdateRoomAnimatedTiles copies a frame's 8 tiles to VRAM 8 bytes at a time, each after waiting for
# an H-Blank (.loop_copy_tiles, its first `ld a, [hli]` past the waits): while the frame is drawn,
# so lines drawn before a chunk's H-Blank show the old tiles. The line of each chunk is recorded.
ANIMATION_COPY_CHUNK = (0x34, 0x4052)
R_LY = 0xFF44
# Every `ldh a, [rDIV]` in the game, as the address of the instruction after it, where register A
# holds what was read. rDIV is the hardware timer: the game's only randomness, which a port cannot
# derive from the game state, so the trace records each read for a native run to replay. Found by
# labelling each read in a copy of the pinned disassembly (local labels emit no bytes; the rebuilt
# ROM was identical) and checked against the ROM by tests/test_rom_integration.py.
# ProcessBlock (06:4000) reads its block byte with `ld a, [hl]` at 06:4013; hooked at the next
# instruction, a read outside the map rows the trace records (SRAM banks 1 and 2, pages $a0-$bf) goes
# into `div_reads`, in the game's order, with OUTSIDE_BLOCK_BANK for its bank and HL for its address:
# GetBlockPtr wraps a row above 0 to page $9f (VRAM) and rows past 63 into SRAM bank 3, ROM, or VRAM.
PROCESS_BLOCK_READ = (0x06, 0x4014)
W_BLOCK_PTR_BANK = 0xCCE9
OUTSIDE_BLOCK_BANK = 0xFF
DIV_READS = (
    (0x72, 0x4a3a),  # PickAndLoadGolfHole
    (0x06, 0x562c),  # BreakBlock
    (0x14, 0x484b),  # AnonsterSilkFunc
    (0x11, 0x66f0),  # BeamBotFunc
    (0x11, 0x6735),  # BeamBotFunc
    (0x11, 0x6772),  # BeamBotFunc
    (0x11, 0x69bb),  # BeamBotFunc
    (0x12, 0x4178),  # BrrrBearFunc
    (0x12, 0x41d3),  # BrrrBearFunc
    (0x12, 0x43ce),  # BrrrBearFunc
    (0x14, 0x4c48),  # DollBoyFunc
    (0x14, 0x50f3),  # DollBoyBarrelFunc
    (0x12, 0x5595),  # FallingSnowSpawnerFunc
    (0x11, 0x6ced),  # FireBotFunc
    (0x11, 0x6d41),  # FireBotFunc
    (0x11, 0x6e0b),  # FireBotFunc
    (0x11, 0x6e27),  # FireBotFunc
    (0x11, 0x6e96),  # FireBotFunc
    (0x11, 0x70c3),  # FireBotFunc
    (0x12, 0x622d),  # HebariiFunc
    (0x13, 0x4c7d),  # HiddenFigureFunc
    (0x12, 0x6503),  # SmallOctohonFunc
    (0x10, 0x5520),  # ParaGoomFunc
    (0x10, 0x5538),  # ParaGoomFunc
    (0x10, 0x55a1),  # ParaGoomFunc
    (0x10, 0x5878),  # ParaGoomFunc
    (0x10, 0x58cd),  # ParaGoomFunc
    (0x10, 0x6ea6),  # SilkyFunc
    (0x10, 0x6f4d),  # SilkyFunc
    (0x10, 0x70ff),  # SilkyFunc
    (0x11, 0x6068),  # SpearBotFunc
    (0x11, 0x60af),  # SpearBotFunc
    (0x11, 0x6179),  # SpearBotFunc
    (0x11, 0x6195),  # SpearBotFunc
    (0x11, 0x6204),  # SpearBotFunc
    (0x11, 0x642a),  # SpearBotFunc
    (0x10, 0x41c8),  # SpearheadFunc
    (0x10, 0x42b3),  # SpearheadFunc
    (0x10, 0x4318),  # SpearheadFunc
    (0x10, 0x4513),  # SpearheadFunc
    (0x14, 0x5429),  # YellowBellyBodyFunc
    (0x14, 0x5504),  # YellowBellyBodyFunc
    (0x18, 0x7061),  # Func_6305f
    (0x20, 0x6846),  # HandleBottomBar
    # The Temple's rocks: a macro's expansions (HandleTempleRock1Fall to 6, Rock7Bounce to 10), each
    # rock's .Spawn and .Update (the bounces' .Spawn only); the list had held only each macro's last.
    (0x56, 0x4123), (0x56, 0x4159),  # HandleTempleRock1Fall
    (0x56, 0x4228), (0x56, 0x425e),  # HandleTempleRock2Fall
    (0x56, 0x417a), (0x56, 0x41b0),  # HandleTempleRock3Fall
    (0x56, 0x427f), (0x56, 0x42b5),  # HandleTempleRock4Fall
    (0x56, 0x41d1), (0x56, 0x4207),  # HandleTempleRock5Fall
    (0x56, 0x42d6),  # HandleTempleRock6Fall
    (0x56, 0x430c),  # HandleTempleRock6Fall
    (0x56, 0x4366), (0x56, 0x43ad), (0x56, 0x43f4),  # HandleTempleRock7Bounce to 9
    (0x56, 0x4440),  # HandleTempleRock10Bounce
    (0x56, 0x4873),  # Func_15868e
)
# Object checkpoints (WL3-035), in UpdateLevel's order: UpdateObjects, then SetWarioScreenPos, then
# ProcessInteractions, then DrawObjects_NoPriority. The object slots are wObjects in WRAM bank 1.
OBJECT_CHECKPOINTS = ((0x18, 0x5348), (0x02, 0x78D3), (0x08, 0x4000), (0x18, 0x564E))
# WRAM bank 1 from wObjects: 8 slots of 32 bytes, wCurObj, wObjDataPointers, and the objects' globals
# up to wEffectivePowerUp ($d14a), then the hidden figure's fight's to w1d162 (older traces stop at
# $d15f).
OBJECTS_BANK, OBJECTS_START, OBJECTS_SIZE = 1, 0xD000, 0x163
# The particles: wParticles (4 slots of 16 bytes), wNumParticles, and wCurParticleIndex.
PARTICLES_START, PARTICLES_SIZE = 0xCCA0, 0x42
FRAME_END = len(OBJECT_CHECKPOINTS)  # a block change's `seen` when first seen after the frame
UPDATE_OBJECTS = (0x18, 0x5348)  # UpdateObjects: UpdateLevel's next call after every Wario update
# UpdateLevel's camera code follows its call of ClearUnusedVirtualOAM on all three paths and ends at
# .asm_8229 (02:4229); the Hidden Figure camera skips it.
CLEAR_UNUSED_VIRTUAL_OAM = (0x00, 0x03B9)
UPDATE_LEVEL_AFTER_CAMERA = (0x02, 0x4229)
# With the Hidden Figure camera (the Temple) UpdateLevel skips .asm_8229: its .asm_8227, `jr
# .check_end_screen`, which only that camera reaches, ends the camera's run instead.
UPDATE_LEVEL_HIDDEN_FIGURE_CAMERA = (0x02, 0x4227)
# The screens with their own state tables (golf, WL3-050; the level's clear screen, WL3-043; Action
# Help, WL3-051; the map and the pause menu, WL3-052) are traced at each of their game loops
# (ScreenTrace): the variables they share with the game, their own RAM, and the virtual OAM; every
# SCREEN_VRAM_EVERY-th loop of a visit both VRAM banks, and the screen at the end of that tick. A RAM
# range's address says which memory it is: SRAM from $a000 and WRAMX from $d000 in the range's bank,
# WRAM0 from $c000. Each visit's loops are counted too: the frames alone cannot place
# the short loop that enters it.
W_STATE, ST_TITLE, ST_OVERWORLD, ST_CLEAR, ST_PAUSE_MENU, ST_GOLF, ST_ACTION_HELP = 0xC09B, 0x00, 0x01, 0x03, 0x04, 0x05, 0x07
ST_CREDITS, ST_GOLF_BUILDING, ST_GAME_OVER, ST_PERFECT, ST_LANGUAGE_SELECTION = 0x09, 0x0A, 0x0C, 0x0D, 0x0E
W_GLOBAL_COUNTER = 0xC08F
# The golf minigame's state for its port (WL3-050), recorded at each _GolfStateTable call: the
# variables golf reads or writes outside its own RAM (its OAM buffer and the V-Blank function pointer
# are presentation), and the live part of the golf RAM in WRAMX bank 1: w1d800 to wGolfCourseScore,
# and wGolfHoleData to the golf objects' end (wGolfParaGoomGhost's last byte, $dc9b).
GOLF_VARIABLES: tuple[tuple[str, int, int], ...] = (
    ("wGlobalCounter", 0xC08F, 1), ("wJoypadDown", 0xC093, 1), ("wJoypadPressed", 0xC094, 1),
    ("wSubState", 0xC09C, 1), ("wSCY", 0xC083, 1), ("wSCX", 0xC085, 1), ("wNumCoins", 0xCA04, 2),
    ("wNumCollectedTreasures", 0xCA39, 2), ("wGolfBestScores", 0xCA42, 4), ("wLanguage", 0xCA46, 1),
    ("wIsMinigameCleared", 0xCAC1, 1), ("wRoomAnimatedTilesEnabled", 0xCED8, 1),
    ("wPalFadeCounter", 0xC187, 1), ("wFadeSpeed", 0xCED7, 1), ("wVirtualOAMByteSize", 0xC095, 1),
)
# The golf building's (_GolfBuildingStateTable, 72:4570, WL3-050): golf's variables, with the state and
# wTransitionParam (ReturnToMap), the musical coin flags (CheckHasAllMusicalCoinFlags), and the
# animated tiles' (its menu's set-up); the temporary palettes; and golf RAM's menu bytes and
# wGolfHoleRAMStart to the golf objects' end (the course's tile map and attributes and w1db00's
# palettes before the hole's data).
GOLF_BUILDING_VARIABLES: tuple[tuple[str, int, int], ...] = GOLF_VARIABLES + (
    ("wState", 0xC09B, 1), ("wTransitionParam", 0xCEE3, 1), ("wMusicalCoinFlags", 0xCA3E, 4),
    ("wAnimatedTilesFrameDuration", 0xC1AC, 1),
    ("wAnimatedTilesGfx", 0xC1AD, 1), ("wAnimatedTilesFrame", 0xC1AE, 1), ("wAnimatedTilesFrameCount", 0xC1AF, 1),
)
# The clear screen's (_ClearScreenStateTable, 35:4000): what it reads and writes in WRAM0, the
# musical coin flags, the BG tile queue, the level time, wcee4 and wTimer's two bytes (the level's
# port keeps one), its objects and timers in WRAMX bank 3 (w3d50d to wMenuObj11's end), and the
# treasures in WRAMX bank 2 (wTreasuresCollected to wOWLevel).
CLEAR_VARIABLES: tuple[tuple[str, int, int], ...] = (
    ("wGlobalCounter", 0xC08F, 1), ("wJoypadDown", 0xC093, 1), ("wJoypadPressed", 0xC094, 1),
    ("wState", 0xC09B, 1), ("wSubState", 0xC09C, 1), ("wSCY", 0xC083, 1), ("wSCX", 0xC085, 1),
    ("wResetDisabled", 0xC09A, 1), ("wAllMusicalCoinsLevel", 0xC0E7, 1),
    ("wMusicalCoinVisualCounter", 0xC0E8, 1), ("wTransitionParam", 0xCEE3, 1),
    ("wNumMusicBoxes", 0xCEF2, 1), ("wPowerUpLevel", 0xCA3C, 1), ("wNumCollectedTreasures", 0xCA39, 2),
    ("wLevelEndScreen", 0xCED4, 1), ("wKeyAndTreasureFlags", 0xCA5B, 1), ("wNumMusicalCoins", 0xCA5C, 1),
    ("wLevel", 0xCA06, 1), ("wGameModeFlags", 0xCA3D, 1), ("wDayNight", 0xCA3B, 1), ("wNumCoins", 0xCA04, 2),
    ("wTimeAttackResult", 0xC0E5, 1), ("wAnimatedTilesFrameDuration", 0xC1AC, 1), ("wAnimatedTilesGfx", 0xC1AD, 1),
    ("wAnimatedTilesFrame", 0xC1AE, 1), ("wAnimatedTilesFrameCount", 0xC1AF, 1),
    ("wRoomAnimatedTilesEnabled", 0xCED8, 1), ("wPalFadeCounter", 0xC187, 1), ("wFadeSpeed", 0xCED7, 1),
    ("wVirtualOAMByteSize", 0xC095, 1),
)
# Action Help's (_ActionHelpStateTable, 7e:4000): what it reads and writes in WRAM0 and HRAM (the
# demo power-up), the palettes it loads (wTempPals1 and 2), the Wario tiles' pending DMA, wTimer's
# byte, and its objects in WRAMX bank 3 (w3d500 to wMenuObj7AnimationEnded).
ACTION_HELP_VARIABLES: tuple[tuple[str, int, int], ...] = (
    ("wGlobalCounter", 0xC08F, 1), ("wJoypadDown", 0xC093, 1), ("wJoypadPressed", 0xC094, 1),
    ("wState", 0xC09B, 1), ("wSubState", 0xC09C, 1), ("wSCY", 0xC083, 1), ("wSCX", 0xC085, 1),
    ("wPowerUpLevel", 0xCA3C, 1), ("wTransformation", 0xCA8E, 1), ("hDemoPowerUp", 0xFFFC, 1),
    ("wDayNight", 0xCA3B, 1), ("wTempBank", 0xC0AC, 1), ("wAnimatedTilesFrameDuration", 0xC1AC, 1),
    ("wAnimatedTilesGfx", 0xC1AD, 1), ("wAnimatedTilesFrame", 0xC1AE, 1), ("wAnimatedTilesFrameCount", 0xC1AF, 1),
    ("wRoomAnimatedTilesEnabled", 0xCED8, 1), ("wPalFadeCounter", 0xC187, 1), ("wFadeSpeed", 0xCED7, 1),
    ("wVirtualOAMByteSize", 0xC095, 1),
)
# What a save keeps in WRAM0: "Progress WRAM" and "Level WRAM" (wSaveCounter to wcaa1's palettes).
PROGRESS_WRAM = (0, 0xCA00, 0xC1)
# The map's (OverworldStateTable, 20:4392): the variables it shares with the game, the temporary
# palettes, the progress, all of WRAMX bank 2 (the map's RAM, with the treasures and wOWLevel), and
# w3d500.
OVERWORLD_VARIABLES: tuple[tuple[str, int, int], ...] = (
    ("wGlobalCounter", 0xC08F, 1), ("wJoypadDown", 0xC093, 1), ("wJoypadPressed", 0xC094, 1),
    ("wState", 0xC09B, 1), ("wSubState", 0xC09C, 1), ("wSCY", 0xC083, 1), ("wSCX", 0xC085, 1),
    ("wTempBank", 0xC0AC, 1), ("wRoomAnimatedTilesEnabled", 0xCED8, 1), ("wTransitionParam", 0xCEE3, 1),
    ("wPalFadeCounter", 0xC187, 1), ("wFadeSpeed", 0xCED7, 1), ("wVirtualOAMByteSize", 0xC095, 1),
)
# The pause menu's state table's (_PauseMenuStateTable, 7c:4000), which also runs the map's save
# screen: the variables, the temporary palettes, the progress, the level time, the tile queue,
# wUnused_IsPaused, wTransitionParam to wcef1 (the checksums), the treasures to wOWLevel, w3d280's
# palettes, w3d500 to wMenuObj11's end, and SRAM bank 0 (where a save goes).
PAUSE_MENU_VARIABLES: tuple[tuple[str, int, int], ...] = (
    ("wGlobalCounter", 0xC08F, 1), ("wJoypadDown", 0xC093, 1), ("wJoypadPressed", 0xC094, 1),
    ("wState", 0xC09B, 1), ("wSubState", 0xC09C, 1), ("wSCY", 0xC083, 1), ("wSCX", 0xC085, 1),
    ("wTempBank", 0xC0AC, 1), ("wSRAMBank", 0xC08E, 1), ("wResetDisabled", 0xC09A, 1),
    ("wRoomAnimatedTilesEnabled", 0xCED8, 1), ("wAnimatedTilesFrameDuration", 0xC1AC, 1),
    ("wAnimatedTilesGfx", 0xC1AD, 1), ("wAnimatedTilesFrame", 0xC1AE, 1), ("wAnimatedTilesFrameCount", 0xC1AF, 1),
    ("wPalFadeCounter", 0xC187, 1), ("wFadeSpeed", 0xCED7, 1), ("wVirtualOAMByteSize", 0xC095, 1),
    ("wPendingSubState", 0xCED5, 1),
)
# The title's (TitleStateTable, 01:402b, WL3-055): the variables (with the intro's three background
# layers' scroll, WL3-056), the temporary palettes, the progress
# (the save's load leaves it; the start menu reads wceef and wGameModeFlags), wTransitionParam to wcef1
# (wcee4, wTimer, wceef), and w3d500 to wMenuObj11's end (the start menu's selection and objects).
TITLE_VARIABLES: tuple[tuple[str, int, int], ...] = (
    ("wGlobalCounter", 0xC08F, 1), ("wJoypadDown", 0xC093, 1), ("wJoypadPressed", 0xC094, 1),
    ("wState", 0xC09B, 1), ("wSubState", 0xC09C, 1), ("wSCY", 0xC083, 1), ("wSCX", 0xC085, 1),
    ("wTempBank", 0xC0AC, 1), ("wRoomAnimatedTilesEnabled", 0xCED8, 1), ("wPalFadeCounter", 0xC187, 1),
    ("wFadeSpeed", 0xCED7, 1), ("wVirtualOAMByteSize", 0xC095, 1), ("hDemoPowerUp", 0xFFFC, 1),
    ("wIntroBGXOffsetFar", 0xC086, 1), ("wIntroBGXOffsetCentre", 0xC087, 1), ("wIntroBGXOffsetNear", 0xC088, 1),
)
# New Game's language selection's (LanguageSelectionStateTable, 01:4831, WL3-056): the title's RAM and
# its variables but the intro's; wLanguage is in the progress.
LANGUAGE_SELECTION_VARIABLES: tuple[tuple[str, int, int], ...] = TITLE_VARIABLES[:-3]
# The credits (_CreditsStateTable, bank $58, in GFX RAM): the variables the screens share, the timers,
# and the transition the epilogue left.
CREDITS_VARIABLES: tuple[tuple[str, int, int], ...] = (
    ("wGlobalCounter", 0xC08F, 1), ("wJoypadDown", 0xC093, 1), ("wJoypadPressed", 0xC094, 1),
    ("wState", 0xC09B, 1), ("wSubState", 0xC09C, 1), ("wSCY", 0xC083, 1), ("wSCX", 0xC085, 1),
    ("wTempBank", 0xC0AC, 1), ("wPalFadeCounter", 0xC187, 1), ("wFadeSpeed", 0xCED7, 1),
    ("wVirtualOAMByteSize", 0xC095, 1), ("wTransitionParam", 0xCEE3, 1),
)
# The virtual OAM the screens' sprites are built in, copied to OAM at V-Blank.
W_VIRTUAL_OAM, OAM_SIZE = 0xCC00, 0xA0
SCREEN_VRAM_EVERY = 32
# The hidden figure's fight (the Temple, level $c8; WL3-052) is drawn from VRAM like a screen
# (LoadHiddenFigureGfx): at every SCREEN_VRAM_EVERY-th Wario update in it, both VRAM banks at the
# update (temple_vram, [frame, bank 0, bank 1]) and the screen at the end of that tick (temple_screens,
# [frame, gzipped RGB]). The palettes a level writes while its frame is drawn, one palette an
# H-Blank (SetBGPals, SetWarioPal), are recorded with the line of each write (pal_writes).
W_LEVEL, THE_TEMPLE, ST_LEVEL = 0xCA06, 0xC8, 0x02
SET_BG_PALS_WRITE = (0x00, 0x35FB)  # SetBGPals' first rBGPD write of a palette, after wait_hblank
SET_WARIO_PAL_WRITE = (0x00, 0x1B34)  # SetWarioPal's first rOBPD write of a palette


@dataclass(frozen=True)
class ScreenLayout:
    """A screen traced at each game loop of its state table: its key in the trace, the hook, the
    wState it runs in, its variables, and its RAM ranges ((WRAM bank, start, size); bank 0 is WRAM0)."""

    name: str
    hook: tuple[int, int]
    state: int
    variables: tuple[tuple[str, int, int], ...]
    ram: tuple[tuple[int, int, int], ...]


SCREENS = (
    ScreenLayout("golf", (0x72, 0x4000), ST_GOLF, GOLF_VARIABLES, ((1, 0xD800, 6), (1, 0xDB40, 0x15C))),
    ScreenLayout("golf_building", (0x72, 0x4570), ST_GOLF_BUILDING, GOLF_BUILDING_VARIABLES,
                 ((0, 0xC000, 0x80), (1, 0xD800, 6), (1, 0xD900, 0x39C))),
    ScreenLayout("clear", (0x35, 0x4000), ST_CLEAR, CLEAR_VARIABLES,
                 ((0, 0xCA3E, 4), (0, 0xCE01, 6), (0, 0xC0E2, 3), (0, 0xCEE4, 3), (3, 0xD50D, 0x7D),
                  (2, 0xD000, 0x10))),
    ScreenLayout("action_help", (0x7E, 0x4000), ST_ACTION_HELP, ACTION_HELP_VARIABLES,
                 ((0, 0xC000, 0x80), (0, 0xC1A0, 8), (0, 0xCEE5, 1), (3, 0xD500, 0x6A))),
    ScreenLayout("overworld", (0x20, 0x4392), ST_OVERWORLD, OVERWORLD_VARIABLES,
                 ((0, 0xC000, 0x80), PROGRESS_WRAM, (2, 0xD000, 0x1000), (3, 0xD500, 1))),
    ScreenLayout("pause_menu", (0x7C, 0x4000), ST_PAUSE_MENU, PAUSE_MENU_VARIABLES,
                 ((0, 0xC000, 0x80), PROGRESS_WRAM, (0, 0xC0E2, 3), (0, 0xCE01, 6), (0, 0xCED6, 1),
                  (0, 0xCEE3, 0x0F), (2, 0xD000, 0x10), (3, 0xD280, 0x80), (3, 0xD500, 0x8A),
                  (0, 0xA000, 0x2000))),
    ScreenLayout("title", (0x01, 0x4039), ST_TITLE, TITLE_VARIABLES,
                 ((0, 0xC000, 0x80), PROGRESS_WRAM, (0, 0xCEE3, 0x0F), (3, 0xD500, 0x8A))),
    ScreenLayout("language_selection", (0x01, 0x483F), ST_LANGUAGE_SELECTION, LANGUAGE_SELECTION_VARIABLES,
                 ((0, 0xC000, 0x80), PROGRESS_WRAM, (0, 0xCEE3, 0x0F), (3, 0xD500, 0x8A))),
    # The credits: the temporary palettes, wCreditsPage, wCreditsBGMapPtr, wCreditsTextBuffer to
    # wCreditsPalsMapPtr's end, wcee4 and wTimer, and w3d500 to wMenuObj1's end (the music box).
    ScreenLayout("credits", (0x58, 0x4000), ST_CREDITS, CREDITS_VARIABLES,
                 ((0, 0xC000, 0x80), (0, 0xC084, 1), (0, 0xCCF0, 2), (0, 0xCE01, 0x6D), (0, 0xCEE4, 2),
                  (3, 0xD500, 0x2B))),
    # The game over screen (_GameOverStateTable, bank $36) and the Perfect screen (_PerfectStateTable,
    # bank $37), both in GFX RAM: the temporary palettes, wcee4 and wTimer, and w3d500 to wMenuObj1's
    # end (their Wario and objects); the Perfect screen also the progress (wGameModeFlags) and
    # wUnused_c186.
    ScreenLayout("game_over", (0x36, 0x7277), ST_GAME_OVER, CREDITS_VARIABLES,
                 ((0, 0xC000, 0x80), (0, 0xCEE4, 2), (3, 0xD500, 0x2B))),
    ScreenLayout("perfect", (0x37, 0x4000), ST_PERFECT, CREDITS_VARIABLES,
                 ((0, 0xC000, 0x80), PROGRESS_WRAM, (0, 0xC186, 1), (0, 0xCEE4, 2), (3, 0xD500, 0x2B))),
)


class ScreenTrace:
    """One screen's records: `updates` ([frame, values, RAM, virtual OAM, how many div_reads came
    before] at each loop), `loops` ([frame of a visit's first loop, its loops]), `vram` ([update, VRAM
    bank 0, bank 1]) and `screens` ([update, gzipped RGB]) every SCREEN_VRAM_EVERY-th loop of a visit."""

    def __init__(self, layout: ScreenLayout, pyboy: Any, frames: list[list[int]], div_reads: list[list[int]]) -> None:
        self.layout, self.pyboy, self.frames, self.div_reads = layout, pyboy, frames, div_reads
        self.loops: list[list[int]] = []  # [frame of a visit's first loop, its loops, the last loop's counter]
        self.updates: list[list[Any]] = []
        self.vram: list[list[Any]] = []
        self.screens: list[list[Any]] = []
        self.pending: list[int] = []  # [update, frame]: the screen to take when that frame ends

    def read_ram(self) -> bytes:
        return b"".join(read_range(self.pyboy, bank, start, size) for bank, start, size in self.layout.ram)

    def on_loop(self, _context: Any) -> None:
        memory = self.pyboy.memory
        self.updates.append([len(self.frames), [oracle.read_value(self.pyboy, address, size)
                                                for _, address, size in self.layout.variables],
                             self.read_ram().hex(), bytes(memory[W_VIRTUAL_OAM:W_VIRTUAL_OAM + OAM_SIZE]).hex(),
                             len(self.div_reads)])
        counter = memory[W_GLOBAL_COUNTER]
        if self.loops and (self.loops[-1][2] + 1) & 0xFF == counter:
            self.loops[-1][1:] = [self.loops[-1][1] + 1, counter]
        else:
            self.loops.append([len(self.frames), 1, counter])
        if self.loops[-1][1] % SCREEN_VRAM_EVERY == 0:
            self.vram.append([len(self.updates) - 1, read_vram(self.pyboy, 0).hex(), read_vram(self.pyboy, 1).hex()])
            # The frame drawn after this loop's start, with what it held, ends with this tick.
            self.pending[:] = [len(self.updates) - 1, len(self.frames)]

    def on_frame(self) -> None:
        if self.pending and self.pending[1] == len(self.frames) - 1:
            self.screens.append([self.pending[0], screen_rgb_gz(self.pyboy)])
            self.pending.clear()

    def output(self) -> dict[str, Any]:
        name = self.layout.name
        return {f"{name}_loops": [visit[:2] for visit in self.loops],
                f"{name}_variables": [{"name": variable, "address": f"{address:04x}", "size": size}
                                      for variable, address, size in self.layout.variables],
                f"{name}_ram": [{"bank": bank, "address": f"{start:04x}", "size": size}
                                for bank, start, size in self.layout.ram],
                f"{name}_updates": self.updates, f"{name}_vram": self.vram, f"{name}_screens": self.screens}


def read_range(pyboy: Any, bank: int, start: int, size: int) -> bytes:
    """A traced RAM range: WRAM0 as mapped, or SRAM or WRAMX in its bank. PyBoy refuses a banked
    slice that ends at its region's end ($c000, $e000), so the last byte is read alone."""
    memory = pyboy.memory
    if 0xC000 <= start < 0xD000:
        return bytes(memory[start:start + size])
    head = bytes(memory[bank, start:start + size - 1]) if size > 1 else b""
    return head + bytes([memory[bank, start + size - 1]])


def screen_rgb_gz(pyboy: Any) -> str:
    """The screen as 160x144 RGB bytes, gzipped and in base64."""
    rgba = pyboy.screen.ndarray
    return base64.b64encode(gzip.compress(rgba[:, :, :3].tobytes(), mtime=0)).decode("ascii")


def read_vram(pyboy: Any, bank: int) -> bytes:
    """VRAM bank `bank` whole; PyBoy refuses a slice ending at $a000, so the last byte is read alone."""
    return bytes(pyboy.memory[bank, 0x8000:0x9FFF]) + bytes([pyboy.memory[bank, 0x9FFF]])

# The level block map lives in SRAM from sLevelBlockObjectMap (01:a000): one 256-byte page per row, 32 rows
# per bank, LEVEL_WIDTH (160) blocks per row, 48 rows (docs/02-research/level-block-maps.md).
MAP_ROWS, MAP_WIDTH, ROWS_PER_BANK = 48, 160, 32
# The block map is read whole, both SRAM banks: below the 48 decoded rows the game reads what SRAM
# holds (a spawn on the last row stands Wario on row 48).
BLOCK_MAP_ROWS = 64


def read_object_rows(pyboy: Any) -> list[bytes]:
    """The object map as the game holds it now: 80 bytes from $b0 of each row's page, a nibble a block
    (the even column high)."""
    rows = []
    for row in range(MAP_ROWS):
        bank, page = 1 + row // ROWS_PER_BANK, 0xA000 + (row % ROWS_PER_BANK) * 0x100
        # PyBoy refuses a slice ending at $c000, so the page's last byte is read on its own.
        rows.append(bytes(pyboy.memory[bank, page + 0xB0:page + 0xFF]) + bytes([pyboy.memory[bank, page + 0xFF]]))
    return rows


def read_variable(pyboy: Any, address: int, size: int) -> int:
    """A traced variable; one above $ffff is banked WRAM (bank << 16 | address), read in its bank."""
    if address <= 0xFFFF:
        return oracle.read_value(pyboy, address, size)
    value = 0
    for offset in range(size):
        value = (value << 8) | pyboy.memory[address >> 16, (address & 0xFFFF) + offset]
    return value


def read_block_rows(pyboy: Any) -> list[bytes]:
    """The level block map as the game holds it now (blocks keep bit 7), all 64 rows of SRAM."""
    rows = []
    for row in range(BLOCK_MAP_ROWS):
        bank, page = 1 + row // ROWS_PER_BANK, 0xA000 + (row % ROWS_PER_BANK) * 0x100
        rows.append(bytes(pyboy.memory[bank, page:page + MAP_WIDTH]))
    return rows


def read_gap_rows(pyboy: Any) -> list[bytes]:
    """The 16 bytes after each block-map row's 160 ($a0-$af of its SRAM page), all 64 rows: the
    level's decompressors never write them, yet a probe past the map's right edge reads them."""
    rows = []
    for row in range(BLOCK_MAP_ROWS):
        bank, page = 1 + row // ROWS_PER_BANK, 0xA000 + (row % ROWS_PER_BANK) * 0x100
        rows.append(bytes(pyboy.memory[bank, page + MAP_WIDTH:page + MAP_WIDTH + 16]))
    return rows


def wario_trace(rom: bytes, start: dict[str, Any], trace: dict[str, Any],
                open_emulator: Callable[[bytes, dict[str, Any]], Any] = oracle.start_from) -> dict[str, Any]:
    """Run `trace` from `start` and record WARIO_VARIABLES before the first tick and after every tick.

    The block map in SRAM is recorded once at the start (with the unwritten bytes after each row,
    `block_gap_rows`, which nothing is known to change) and then as changes ([frame, row, column, value,
    seen], `frame` indexing `frames`), so a check can see broken blocks and object flags as the game did.
    `seen` is the object checkpoint at which the change was first seen in that frame (4: the frame's
    end), so a check rerunning the objects or the interactions applies only the changes made before.
    `updates` lists every Wario update as [frame, before, after] (see the module docstring),
    `camera_updates` every run of UpdateLevel's camera code the same way, and `object_checkpoints`
    the variables and object slots at OBJECT_CHECKPOINTS, in the order they ran.
    """
    pyboy = open_emulator(rom, start)
    frames: list[list[int]] = []
    initial_rows = read_block_rows(pyboy)
    gap_rows = read_gap_rows(pyboy)
    rows = list(initial_rows)
    changes: list[list[int]] = []
    initial_object_rows = read_object_rows(pyboy)
    object_rows = list(initial_object_rows)
    object_changes: list[list[int]] = []
    updates: list[list[Any]] = []
    pending: list[list[int]] = []
    camera_updates: list[list[Any]] = []
    camera_pending: list[list[int]] = []

    def values() -> list[int]:
        return [read_variable(pyboy, address, size) for _, address, size in WARIO_VARIABLES]

    temple_vram: list[list[Any]] = []
    temple_screens: list[list[Any]] = []
    temple_pending: list[int] = []  # the frame whose screen to take when its tick ends
    temple_updates = [0]
    pal_writes: list[list[int]] = []

    def enter_wario(_context: Any) -> None:
        pending[:] = [values()]
        memory = pyboy.memory
        if memory[W_STATE] == ST_LEVEL and memory[W_LEVEL] == THE_TEMPLE:
            temple_updates[0] += 1
            if temple_updates[0] % SCREEN_VRAM_EVERY == 0:
                temple_vram.append([len(frames), read_vram(pyboy, 0).hex(), read_vram(pyboy, 1).hex()])
                temple_pending[:] = [len(frames)]

    def pal_write(kind: int) -> Callable[[Any], None]:
        def record(_context: Any) -> None:
            if pyboy.memory[W_STATE] == ST_LEVEL:
                pal_writes.append([len(frames), kind, pyboy.memory[R_LY], pyboy.register_file.B,
                                   pyboy.register_file.HL])
        return record

    def enter_objects(_context: Any) -> None:
        if pending:
            # The update ran during the tick whose sample will be frames[len(frames)].
            updates.append([len(frames), pending[0], values()])
            pending.clear()

    def enter_camera(_context: Any) -> None:
        camera_pending[:] = [values()]

    def leave_camera(_context: Any) -> None:
        if camera_pending:
            camera_updates.append([len(frames), camera_pending[0], values()])
            camera_pending.clear()

    object_checkpoints: list[list[Any]] = []
    div_reads: list[list[int]] = []
    animation_calls: list[list[int]] = []
    screen_traces = [ScreenTrace(layout, pyboy, frames, div_reads) for layout in SCREENS]

    animation_copies: list[list[int]] = []

    def animation_copy(_context: Any) -> None:
        animation_copies.append([len(frames), pyboy.memory[R_LY]])

    def animation_call(kind: int) -> Callable[[Any], None]:
        def record(_context: Any) -> None:
            animation_calls.append([len(frames), kind, pyboy.register_file.A])
        return record

    def div_read(bank: int, address: int) -> Callable[[Any], None]:
        def record(_context: Any) -> None:
            div_reads.append([len(frames), len(object_checkpoints), bank, address, pyboy.register_file.A])
        return record

    def outside_block_read(_context: Any) -> None:
        address = pyboy.register_file.HL
        if not (pyboy.memory[W_BLOCK_PTR_BANK] in (1, 2) and 0xA0 <= address >> 8 < 0xC0):
            div_reads.append([len(frames), len(object_checkpoints), OUTSIDE_BLOCK_BANK, address,
                              pyboy.register_file.A])

    def note_block_changes(frame: int, seen: int) -> None:
        for index, now in enumerate(read_block_rows(pyboy)):
            if now != rows[index]:
                changes.extend([frame, index, column, now[column], seen]
                               for column in range(MAP_WIDTH) if now[column] != rows[index][column])
                rows[index] = now

    def checkpoint(index: int) -> Callable[[Any], None]:
        def record(_context: Any) -> None:
            note_block_changes(len(frames), index)
            objects = bytes(pyboy.memory[OBJECTS_BANK, OBJECTS_START:OBJECTS_START + OBJECTS_SIZE])
            particles = bytes(pyboy.memory[PARTICLES_START:PARTICLES_START + PARTICLES_SIZE])
            object_checkpoints.append([len(frames), index, values(), objects.hex(), particles.hex()])
        return record

    if hasattr(pyboy, "hook_register"):
        for index, (bank, address) in enumerate(OBJECT_CHECKPOINTS):
            if (bank, address) != UPDATE_OBJECTS:
                pyboy.hook_register(bank, address, checkpoint(index), None)

        def enter_objects_and_checkpoint(context: Any) -> None:
            enter_objects(context)
            checkpoint(0)(context)

        pyboy.hook_register(*UPDATE_WARIO_STATES, enter_wario, None)
        pyboy.hook_register(*UPDATE_OBJECTS, enter_objects_and_checkpoint, None)
        pyboy.hook_register(*CLEAR_UNUSED_VIRTUAL_OAM, enter_camera, None)
        pyboy.hook_register(*UPDATE_LEVEL_AFTER_CAMERA, leave_camera, None)
        pyboy.hook_register(*UPDATE_LEVEL_HIDDEN_FIGURE_CAMERA, leave_camera, None)
        for bank, address in DIV_READS:
            pyboy.hook_register(bank, address, div_read(bank, address), None)
        pyboy.hook_register(*PROCESS_BLOCK_READ, outside_block_read, None)
        for screen in screen_traces:
            pyboy.hook_register(*screen.layout.hook, screen.on_loop, None)
        for kind, (bank, address) in enumerate(ANIMATION_CALLS):
            pyboy.hook_register(bank, address, animation_call(kind), None)
        pyboy.hook_register(*ANIMATION_COPY_CHUNK, animation_copy, None)
        pyboy.hook_register(*SET_BG_PALS_WRITE, pal_write(0), None)
        pyboy.hook_register(*SET_WARIO_PAL_WRITE, pal_write(1), None)

    def sample(_tick: int | None = None) -> None:
        frames.append(values())
        for screen in screen_traces:
            screen.on_frame()
        if temple_pending and temple_pending[0] == len(frames) - 1:
            temple_screens.append([temple_pending[0], screen_rgb_gz(pyboy)])
            temple_pending.clear()
        note_block_changes(len(frames) - 1, FRAME_END)
        for index, now in enumerate(read_object_rows(pyboy)):
            if now != object_rows[index]:
                object_changes.extend([len(frames) - 1, index, offset, now[offset]]
                                      for offset in range(len(now)) if now[offset] != object_rows[index][offset])
                object_rows[index] = now

    sample()
    # The traced screens' ticks are rendered, for their screens, and the Temple's; other levels' are
    # not needed.
    rendered = {layout.state for layout in SCREENS}
    oracle.play(pyboy, trace, sample, lambda _tick: pyboy.memory[W_STATE] in rendered
                or (pyboy.memory[W_STATE] == ST_LEVEL and pyboy.memory[W_LEVEL] == THE_TEMPLE))
    pyboy.stop(save=False)
    document = {
        "format": "wl3pc.oracle-wario-trace", "format_version": FORMAT_VERSION, "marker": ROM_DERIVED_MARKER,
        "rom_sha256": sha256_bytes(rom), "emulator": oracle.emulator_config(), "start": start, "input": trace,
        "variables": [{"name": name, "size": size,
                       "address": f"{address:04x}" if address <= 0xFFFF else f"{address >> 16:02x}:{address & 0xFFFF:04x}"}
                      for name, address, size in WARIO_VARIABLES],
        "frames": frames,
        "block_rows": [row.hex() for row in initial_rows],
        "block_gap_rows": [row.hex() for row in gap_rows],
        "block_changes": changes,
        "updates": updates,
        "camera_updates": camera_updates,
        "object_checkpoints": object_checkpoints,
        "object_rows": [row.hex() for row in initial_object_rows],
        "object_changes": object_changes,
        "div_reads": div_reads,
        "animation_calls": animation_calls,
        "animation_copies": animation_copies,
        "pal_writes": pal_writes,
        "temple_vram": temple_vram,
        "temple_screens": temple_screens,
    }
    for screen in screen_traces:
        document.update(screen.output())
    return document
