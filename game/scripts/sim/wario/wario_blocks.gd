class_name WarioBlocks
extends WarioParticles
## Wario's collision probes and the block handlers they reach, ported from
## src/engine/level/collisions.asm and src/engine/level/block_functions.asm
## (ElectroDeoxys/warioland3 @560fce6). Each function names the routine it ports.
##
## A probe sets hPos to a point, finds the map byte there (GetBlockPtr), and runs the
## handler of that byte's block ID with wCollisionPoints set to the probe kind
## (ProcessBlock). Handlers return a result and may move hYPos onto a surface, set
## interaction flags, or replace the block. Paths into code that is not ported yet are
## recorded in `unported` by routine name instead of being guessed.

## Cracked and breakable block families: handler ID -> [family, replacement block].
const BREAKABLE: Dictionary = {
	"h06_4cb4": ["cracked", 0x78], "h06_4cb8": ["cracked", 0x79], "h06_4cbc": ["cracked", 0x7A],
	"h06_4cc0": ["cracked", 0x7B], "h06_4cc4": ["cracked", 0x7C], "h06_4cc8": ["cracked", 0x7D],
	"h06_4ccc": ["cracked", 0x7E], "h06_4cd0": ["cracked", 0x7F],
	"h06_4d60": ["non_cracked", 0x78], "h06_4d64": ["non_cracked", 0x79], "h06_4d68": ["non_cracked", 0x7A],
	"h06_4d6c": ["non_cracked", 0x7B], "h06_4d70": ["non_cracked", 0x7C], "h06_4d74": ["non_cracked", 0x7D],
	"h06_4d78": ["non_cracked", 0x7E], "h06_4d7c": ["non_cracked", 0x7F],
	"h06_49fb": ["colour_coin", 0x78], "h06_49ff": ["colour_coin", 0x79], "h06_4a03": ["colour_coin", 0x7A],
	"h06_4a07": ["colour_coin", 0x7B], "h06_4a0b": ["colour_coin", 0x7C], "h06_4a0f": ["colour_coin", 0x7D],
	"h06_4a13": ["colour_coin", 0x7E],
	"h06_544b": ["bonfire", 0x78], "h06_544f": ["bonfire", 0x79], "h06_5453": ["bonfire", 0x7A],
	"h06_5457": ["bonfire", 0x7B], "h06_545b": ["bonfire", 0x7C], "h06_545f": ["bonfire", 0x7D],
	"h06_5463": ["bonfire", 0x7E],
	"h06_53fb": ["enemy", 0x78], "h06_53ff": ["enemy", 0x79], "h06_5403": ["enemy", 0x7A],
	"h06_5407": ["enemy", 0x7B], "h06_540b": ["enemy", 0x7C], "h06_540f": ["enemy", 0x7D],
	"h06_5413": ["enemy", 0x7E], "h06_5417": ["enemy", 0x7F],
	"h06_5497": ["doughnut", 0x78], "h06_549b": ["doughnut", 0x79], "h06_549f": ["doughnut", 0x7A],
	"h06_54a3": ["doughnut", 0x7B],
}
## The multi-block breakables: handler ID -> [family, replacement block, direction passed on].
const MULTI_BLOCK: Dictionary = {
	# Func_18aa8 (1), _18aec (3), _18b2d (2), _18b71 (4)
	"h06_4aa6": ["snow1", 0x78, 1], "h06_4aea": ["snow1", 0x78, 3], "h06_4b23": ["snow1", 0x7A, 2],
	"h06_4b2b": ["snow1", 0x78, 2], "h06_4b67": ["snow1", 0x7A, 4], "h06_4b6f": ["snow1", 0x78, 4],
	# Func_18bb5, _18bf9, _18c3a, _18c7e
	"h06_4bb3": ["snow3", 0x78, 1], "h06_4bf7": ["snow3", 0x78, 3], "h06_4c30": ["snow3", 0x7A, 2],
	"h06_4c38": ["snow3", 0x78, 2], "h06_4c74": ["snow3", 0x7A, 4], "h06_4c7c": ["snow3", 0x78, 4],
	# Func_18e2c (1), _18ec0 (3), _18f7d (2), _19011 (4)
	"h06_4e0e": ["cracked", 0x79, 1], "h06_4e1a": ["cracked", 0x7C, 1], "h06_4e26": ["cracked", 0x7F, 1],
	"h06_4e2a": ["cracked", 0x78, 1], "h06_4ea2": ["cracked", 0x79, 3], "h06_4eae": ["cracked", 0x7C, 3],
	"h06_4ebe": ["cracked", 0x78, 3], "h06_4f5f": ["cracked", 0x79, 2], "h06_4f6b": ["cracked", 0x7C, 2],
	"h06_4f7b": ["cracked", 0x78, 2], "h06_4ff3": ["cracked", 0x79, 4], "h06_4fff": ["cracked", 0x7C, 4],
	"h06_5007": ["cracked", 0x7E, 4], "h06_500f": ["cracked", 0x78, 4],
	# Func_190fe (1), _191b3 (3), _19291 (2), _19346 (4)
	"h06_50e4": ["non_cracked", 0x7A, 1], "h06_50e8": ["non_cracked", 0x7B, 1], "h06_50fc": ["non_cracked", 0x78, 1],
	"h06_5199": ["non_cracked", 0x7A, 3], "h06_519d": ["non_cracked", 0x7B, 3], "h06_51b1": ["non_cracked", 0x78, 3],
	"h06_5277": ["non_cracked", 0x7A, 2], "h06_527b": ["non_cracked", 0x7B, 2], "h06_528f": ["non_cracked", 0x78, 2],
	"h06_532c": ["non_cracked", 0x7A, 4], "h06_5330": ["non_cracked", 0x7B, 4], "h06_5344": ["non_cracked", 0x78, 4],
	# Func_19522 (1), _19560 (3), _1959b (2), YarnBlockCollision (4)
	"h06_5518": ["string", 0x7A, 1], "h06_5520": ["string", 0x78, 1], "h06_5552": ["string", 0x79, 3],
	"h06_5556": ["string", 0x7A, 3], "h06_555e": ["string", 0x78, 3], "h06_558d": ["string", 0x79, 2],
	"h06_5599": ["string", 0x78, 2], "h06_55cb": ["string", 0x79, 4], "h06_55d7": ["string", 0x78, 4],
}
const COLLISION_THROWN_OBJ: int = 1  # wBlockFuncSpecialCollision

var level: LevelCollision = null
## Handler IDs run since the last update() began, with probe kinds (for parity reports).
var handlers_run: Dictionary = {}
const DIV_BREAK_BLOCK: int = 0x06_562C  # BreakBlock's rDIV read
const COIN_COOLDOWN: int = 100
const OBJ_PARAMS_COIN: int = 0x4E5A  # ObjParams_Coin (bank $19)
const OBJ_PARAMS_COLOUR_COIN: int = 0x4E6D  # ObjParams_ColourCoin (bank $19)


# --- ProcessBlock and probes ---------------------------------------------------------------

## GetBlockPtr (home/decompress_level_data.asm): the map row and column of hPos.
func get_block_ptr() -> void:
	block_row = ((hi(hYPos) & 0x0F) << 4) | (lo(hYPos) >> 4)
	block_column = ((hi(hXPos) & 0x0F) << 4) | (lo(hXPos) >> 4)


## ProcessBlock (06:4000): run the handler of the block at wBlockPtr.
func process_block() -> int:
	wIsInWaterOrSand = 0
	var value: int = level.block_at(block_row, block_column)
	if value < 0:
		value = replay_outside_read(_block_address())
	if value < 0:
		note_unported("ProcessBlock outside the decoded map (row %d, column %d)" % [block_row, block_column])
		return 0
	return run_handler(level.handler_for(wLevelRoomID, value))


## GetBlockPtr's address for (block_row, block_column): page $a0 + row, folded into SRAM banks 1-3
## by $20 at a time from $c0 (rows 0-95); a row past that wraps below $a0 (a row above 0 is page
## $9f, VRAM). Only reads the map rows do not cover use it.
func _block_address() -> int:
	var page: int = (block_row + 0xA0) & 0xFF
	if page >= 0xC0:
		page -= 0x20
		if page >= 0xC0:
			page -= 0x20
	return (page << 8) | block_column


## Func_19b51 (DOWN), Func_19b7b (UNK1), Func_19b8b (UNK2), Func_19b9b (UNK3), Func_19bc3 (UNK4),
## Func_19beb (UNK5), Func_19bfb (UNK6), Func_19c0b (UNK7): probe hPos with one collision kind.
func probe(points: int) -> int:
	get_block_ptr()
	wCollisionPoints = points
	return process_block()


## Func_19bd3: the block one row above wBlockPtr, keeping hPos and wCollisionPoints.
func process_block_above() -> int:
	block_row -= 1
	return process_block()


## Func_19b3a: clear the interaction flags, then probe hPos for presence (UNK7).
func probe_presence() -> int:
	wWaterInteraction = 0
	wLadderInteraction = 0
	wRoomTransitionParam = 0
	wIsInSand = 0
	wIsNearFence = 0
	wIsInAirCurrent = 0
	return probe(COLLISION_UNK7)


## Func_19b25 ("collision on top"): presence 4 px above Wario's position.
func probe_presence_top() -> int:
	hXPos = wWarioXPos
	hYPos = word(wWarioYPos - 4)
	return probe_presence()


## Func_19afb: presence $18 px above Wario's position.
func probe_presence_18() -> int:
	hXPos = wWarioXPos
	hYPos = word(wWarioYPos - 0x18)
	return probe_presence()


## Func_19acd: presence 12 px above Wario's position (the water above him while swimming).
func probe_presence_12() -> int:
	hXPos = wWarioXPos
	hYPos = word(wWarioYPos - 0x0C)
	return probe_presence()


## Func_19b12: presence at Wario's position.
func probe_presence_centre() -> int:
	hYPos = wWarioYPos
	hXPos = wWarioXPos
	return probe_presence()


# --- Collision checks (collisions.asm) -----------------------------------------------------

## CheckFrontCollision: the bottom corner on the side Wario faces; returns b.
func check_front_collision() -> int:
	wBlockFuncBreakFlag = 1
	if wDirection == DIRECTION_LEFT:
		return check_bottom_left_collision()
	return check_bottom_right_collision()


## CheckBottomRightCollision
func check_bottom_right_collision() -> int:
	var flat: bool = wTransformation == TRANSFORMATION_FLAT_WARIO
	hXPos = word(wWarioXPos + byte(wCollisionBoxRight - 1))
	hYPos = word(wWarioYPos - byte(byte(-wCollisionBoxBottom) + (1 if flat else 7)))
	return _front_collision()


## CheckBottomLeftCollision
func check_bottom_left_collision() -> int:
	var flat: bool = wTransformation == TRANSFORMATION_FLAT_WARIO
	hXPos = word(wWarioXPos - byte(byte(-wCollisionBoxLeft) - 1))
	hYPos = word(wWarioYPos - byte(byte(-wCollisionBoxBottom) + (1 if flat else 7)))
	return _front_collision()


## .got_collision_coords of both bottom-corner checks.
func _front_collision() -> int:
	wc0dc = lo(hYPos) & 0xF0
	var b: int = probe(COLLISION_UNK4)
	if (b & 0x0F) == 0:
		return _front_collision_above()
	if wAttackCounter != 0:
		# Func_19823: an attack also breaks into the block above.
		wBlockFuncBreakFlag = 1
		process_block_above()
		wUnused_c18d = 1
		return 1
	return b


## Func_19832: when the corner is free, check the block above it unless it is in the box's top row.
func _front_collision_above() -> int:
	if wIsCrouching != 0:
		wUnused_c18d = 0
		return 0
	if wc0dc == (byte(lo(wWarioYPos) + wCollisionBoxTop + 2) & 0xF0):
		wUnused_c18d = 0
		return 0
	wBlockFuncBreakFlag = 1
	var b: int = process_block_above()
	if (b & 0x0F) == 0:
		return b
	if (wJumpVelTable != 0 or wAttackCounter != 0 or wWaterInteraction != 0 or wIsCrouching != 0
			or wIsOnSteppableObject != 0 or wTransformation != 0 or wIsInSand != 0):
		return b
	# A low gap: Wario steps 2 px into it and crouches.
	var right: bool
	if (wJoypadDown & PAD_RIGHT) != 0:
		right = true
	elif (wJoypadDown & PAD_LEFT) != 0:
		right = false
	else:
		right = wDirection != DIRECTION_LEFT
	if right:
		move_wario_right(2)
	else:
		move_wario_left(2)
	# farcall CrouchOrSlide, then b = 0: the caller carries on (a walk still takes its step).
	crouch_or_slide()
	wUnused_c18d = 0
	return 0


## CrouchOrSlide lives in WarioSim; collision code reaches it through this hook.
func crouch_or_slide() -> void:
	note_unported("CrouchOrSlide")


## Func_198c7: the centre point for ground (DOWN); resets wWarioSlopeInteraction.
func _centre_ground() -> int:
	wWarioSlopeInteraction = 0
	hYPos = wWarioYPos
	hXPos = wWarioXPos
	return probe(COLLISION_DOWN)


## CheckCentreCollision: ground under the centre, then under both bottom corners (UNK2); returns b.
func check_centre_collision() -> int:
	var b: int = _centre_ground()
	if b != 0:
		return b
	hXPos = word(wWarioXPos - byte(byte(-wCollisionBoxLeft) - 3))
	hYPos = wWarioYPos
	b = probe(COLLISION_UNK2)
	if b != 0:
		return b
	hXPos = word(wWarioXPos + byte(wCollisionBoxRight - 3))
	hYPos = wWarioYPos
	b = probe(COLLISION_UNK2)
	if b != 0:
		return b
	if wIsOnSteppableObject != 0:
		hYPos = wWarioYPos
		return wIsOnSteppableObject
	return b


## Func_19942: the point 2 px above the collision box (UNK5).
func _up_centre() -> int:
	if wTransformation != TRANSFORMATION_PUFFY_WARIO:
		wBlockFuncBreakFlag = 1
	hXPos = wWarioXPos
	hYPos = word(wWarioYPos - byte(byte(-wCollisionBoxTop) + 2))
	return probe(COLLISION_UNK5)


## CheckUpCollision: above the centre, then above both top corners (UNK3); returns b.
func check_up_collision() -> int:
	wJumpCollision = 1
	var b: int = _up_centre()
	if b != 0:
		return b
	wJumpCollision = 0
	if wTransformation != TRANSFORMATION_PUFFY_WARIO:
		wBlockFuncBreakFlag = 1
	var above: int = word(wWarioYPos - byte(byte(-wCollisionBoxTop) + 2))
	hXPos = word(wWarioXPos - byte(byte(-wCollisionBoxLeft) - 3))
	hYPos = above
	b = probe(COLLISION_UNK3)
	if b != 0:
		return b
	if wTransformation != TRANSFORMATION_PUFFY_WARIO:
		wBlockFuncBreakFlag = 1
	hXPos = word(wWarioXPos + byte(wCollisionBoxRight - 3))
	hYPos = above
	return probe(COLLISION_UNK3)


## CheckAirborneCollision: landing under the centre (UNK1), then both bottom corners (UNK6).
func check_airborne_collision() -> int:
	wWarioSlopeInteraction = 0
	if wIsSmashAttacking != 0:
		wBlockFuncBreakFlag = 1
	hYPos = wWarioYPos
	hXPos = wWarioXPos
	var b: int = probe(COLLISION_UNK1)
	if b != 0:
		return b
	if wIsSmashAttacking != 0:
		wBlockFuncBreakFlag = 1
	hXPos = word(wWarioXPos - byte(byte(-wCollisionBoxLeft) - 3))
	hYPos = wWarioYPos
	b = probe(COLLISION_UNK6)
	if b != 0:
		return b
	if wIsOnSteppableObject != 0:
		return wIsOnSteppableObject
	if wIsSmashAttacking != 0:
		wBlockFuncBreakFlag = 1
	hXPos = word(wWarioXPos + byte(wCollisionBoxRight - 3))
	hYPos = wWarioYPos
	b = probe(COLLISION_UNK6)
	if b != 0:
		return b
	if wIsOnSteppableObject != 0:
		return wIsOnSteppableObject
	return b


## IsOnSlipperyGround (home/wario_mechanics2.asm): ground under both bottom corners.
func is_on_slippery_ground() -> int:
	wIsOnSlipperyGround = 0
	hXPos = word(wWarioXPos - byte(byte(-wCollisionBoxLeft) - 3))
	hYPos = wWarioYPos
	probe(COLLISION_DOWN)
	if wIsOnSlipperyGround != 0:
		return wIsOnSlipperyGround
	hXPos = word(wWarioXPos + byte(wCollisionBoxRight - 3))
	hYPos = wWarioYPos
	probe(COLLISION_DOWN)
	return wIsOnSlipperyGround


# --- Movement (home/move_wario.asm) -----------------------------------------------------------

func move_wario_right(b: int) -> void:
	wCameraXDelta = byte(wCameraXDelta + b)
	wWarioXPos = word(wWarioXPos + b)


func move_wario_left(b: int) -> void:
	wCameraXDelta = byte(wCameraXDelta - b)
	wWarioXPos = word(wWarioXPos - b)


func move_wario_down(b: int) -> void:
	wCameraYDelta = byte(wCameraYDelta + b)
	wWarioYPos = word(wWarioYPos + b)


func move_wario_up(b: int) -> void:
	wCameraYDelta = byte(wCameraYDelta - b)
	wWarioYPos = word(wWarioYPos - b)


## MoveWarioUp_WithoutCameraOffset and MoveWarioDown_WithoutCameraOffset (the surface's bobbing).
func move_wario_up_without_camera_offset(b: int) -> void:
	wWarioYPos = word(wWarioYPos - b)


func move_wario_down_without_camera_offset(b: int) -> void:
	wWarioYPos = word(wWarioYPos + b)


# --- Block handlers (block_functions.asm) ------------------------------------------------------

## Run a handler by ID; returns what ProcessBlock leaves in a.
func run_handler(handler: String) -> int:
	handlers_run["%s/%02x" % [handler, wCollisionPoints]] = true
	match handler:
		"h06_4020":
			return block_free()
		"h06_4032":
			return block_solid()
		"h06_409f":
			return block_1809f()
		"h06_40b5":
			return block_180b5()
		"h06_40d9":
			return block_right_slope()
		"h06_4129":
			return block_18129()
		"h06_413f":
			return block_1813f()
		"h06_4163":
			return block_left_slope()
		"h06_4208":
			return block_floor()
		"h06_41ac":
			return block_water()
		"h06_41c8":
			return block_current(CURRENT_RIGHT)
		"h06_41d8":
			return block_current(CURRENT_UP)
		"h06_41e8":
			return block_current(CURRENT_LEFT)
		"h06_41f8":
			return block_current(CURRENT_DOWN)
		"h06_423f":
			return block_water_surface()
		"h06_48c4":
			return block_non_submersible_water()
		"h06_484c":
			return block_sand()
		"h06_42c3":
			return block_ladder()
		"h06_42dc":
			return block_182dc()
		"h06_42e5":
			return block_ladder_top()
		"h06_42fe":
			return block_182fe()
		"h06_45cb":
			return block_door()
		"h06_4262":
			return block_18262()
		"h06_4336":
			return block_non_solid_spike()
		"h06_439c":
			return block_solid_spike()
		"h06_4727":
			return block_underwater_door(false)
		"h06_47de":
			return block_187de()
		"h06_480c":
			return block_walkthrough_pipe()
		"h06_4868":
			return block_18868()
		"h06_494d":
			return block_air_current()
		"h06_428c":
			return block_switch()
		"h06_442a":
			return block_down_pipe(true)
		"h06_4461":
			return block_down_pipe(false)
		"h06_44fc":
			return block_up_pipe(true)
		"h06_4533":
			return block_up_pipe(false)
		"h06_47b0":
			return block_187b0()
		"h06_4821":
			return block_light_source()
		"h06_48ba":
			return block_188ba()
		"h06_4934":
			return block_fence()
		"h06_4997":
			return block_slippery(true)
		"h06_49ae":
			return block_slippery(false)
		"h06_49c5":
			return block_cloud_platform_1()
		"h06_49d4":
			return block_cloud_platform_2()
		"h06_45fa":
			return block_minigame_door()
		"h06_4402":
			return block_water_spike()
		"h06_46f9":
			return block_underwater_door()
		"h06_48e0":
			return block_fire()
		"h06_49df":
			return block_small_gap()
		"h06_49f1":
			return block_189f1()
	if MULTI_BLOCK.has(handler):
		var entry: Array = MULTI_BLOCK[handler]
		match entry[0]:
			"cracked":
				return multi_cracked_block_collision(entry[1], entry[2])
			"non_cracked":
				return multi_non_cracked_block_collision(entry[1], entry[2])
			"string":
				return multi_string_block_collision(entry[1], entry[2])
			"snow1", "snow3":
				return multi_snowball_block_collision(entry[1], entry[2], entry[0] == "snow3")
	if BREAKABLE.has(handler):
		var family: String = BREAKABLE[handler][0]
		var replacement: int = BREAKABLE[handler][1]
		match family:
			"cracked":
				return cracked_block_collision(replacement, false)
			"colour_coin":
				return cracked_block_collision(replacement, true)
			"non_cracked":
				return non_cracked_block_collision(replacement)
			"bonfire":
				return bonfire_block_collision(replacement)
			"enemy":
				return enemy_block_collision(replacement)
			"doughnut":
				return doughnut_block_collision(replacement)
	note_unported("block handler %s" % handler)
	return 0


## BlockFunc_Water: water for objects (wIsInWaterOrSand) and, where Wario's presence probe
## (UNK7) finds it, for him.
func block_water() -> int:
	wIsInWaterOrSand = 1
	if wBlockFuncWarioFlag != 0 and (wCollisionPoints & COLLISION_UNK7) != 0:
		wWaterInteraction = SUBMERSIBLE_WATER
	return block_free()


## BlockFunc_Sand: free; sand for objects, and for Wario's presence probe (UNK7).
func block_sand() -> int:
	wIsInWaterOrSand = 1
	if wBlockFuncWarioFlag != 0 and (wCollisionPoints & COLLISION_UNK7) != 0:
		wIsInSand = 1
	return block_free()


## BlockFunc_RightCurrent, _UpCurrent, _LeftCurrent, _DownCurrent: water, with a current for
## Wario's presence probe.
func block_current(current: int) -> int:
	if (wCollisionPoints & COLLISION_UNK7) != 0:
		wWaterCurrent = current
	return block_water()


## BlockFunc_WaterSurface: a floor for UNK1; water but in the surface's bottom two lines, where
## DOWN and UNK2 probes find it solid (and wet).
func block_water_surface() -> int:
	if (wCollisionPoints & COLLISION_UNK1) != 0:
		return block_floor()
	if (lo(hYPos) & 0x0E) != 0 or (wCollisionPoints & (COLLISION_DOWN | COLLISION_UNK2)) == 0:
		return block_water()
	wIsInWaterOrSand = 1
	return block_solid()


## BlockFunc_NonSubmersibleWater: water Wario cannot swim down into.
func block_non_submersible_water() -> int:
	wIsInWaterOrSand = 1
	if wBlockFuncWarioFlag != 0 and (wCollisionPoints & COLLISION_UNK7) != 0:
		wWaterInteraction = NON_SUBMERSIBLE_WATER
	return block_free()


## BlockFunc_Free
func block_free() -> int:
	wBlockFuncBreakFlag = 0
	wBlockFuncSpecialCollision = 0
	wUnused_c18d = 0
	return 0


## BlockFunc_Solid: snaps hYPos to the top of the block.
func block_solid() -> int:
	wBlockFuncBreakFlag = 0
	wBlockFuncSpecialCollision = 0
	if wBlockFuncWarioFlag != 0 and wWarioSlopeInteraction != 0 and (wCollisionPoints & COLLISION_UNK4) != 0:
		wUnused_c18d = 0
		return 0
	hYPos = (hYPos & 0xFF00) | (lo(hYPos) & 0xF0)
	wUnused_c18d = 1
	return 1


## Func_18064: the result of every slope.
func result_slope() -> int:
	wBlockFuncBreakFlag = 0
	wBlockFuncSpecialCollision = 0
	wUnused_c18d = 0x10
	return 0x10


## Func_1808c
func result_zero() -> int:
	wBlockFuncBreakFlag = 0
	wBlockFuncSpecialCollision = 0
	wUnused_c18d = 0
	return 0


## BlockFunc_1809f: the block above a right slope, for DOWN only.
func block_1809f() -> int:
	if (wCollisionPoints & COLLISION_DOWN) == 0:
		return block_free()
	hYPos = word(hYPos + 0x10)
	return right_slope_collision()


## BlockFunc_180b5: the block below a right slope.
func block_180b5() -> int:
	if wBlockFuncWarioFlag != 0 and wWarioState == WST_ATTACKING_AIRBORNE:
		return block_solid()
	if (wCollisionPoints & (COLLISION_DOWN | COLLISION_UNK1)) == 0:
		return block_free()
	hYPos = word(hYPos - 0x10)
	return right_slope_collision()


## BlockFunc_RightSlope
func block_right_slope() -> int:
	if (wCollisionPoints & (COLLISION_DOWN | COLLISION_UNK1)) == 0:
		return block_free()
	if (wCollisionPoints & COLLISION_UNK1) != 0:
		# Landing above the diagonal (x + y < $10 within the block) is free.
		if (lo(hYPos) & 0x0F) + (lo(hXPos) & 0x0F) < 0x10:
			return block_free()
	return right_slope_collision()


## RightSlopeCollision: hYPos onto the diagonal.
func right_slope_collision() -> int:
	var c: int = 0x10 - (lo(hXPos) & 0x0F)
	hYPos = word(((hYPos & 0xFF00) | (lo(hYPos) & 0xF0)) + c)
	if (wCollisionPoints & (COLLISION_DOWN | COLLISION_UNK1)) != 0:
		if wBlockFuncWarioFlag != 0:
			wWarioSlopeInteraction = ON_SLOPE | RIGHT_SLOPE
		else:
			wObjSlopeInteraction = ON_SLOPE | RIGHT_SLOPE
	return result_slope()


## BlockFunc_18129: the block above a left slope, for DOWN only.
func block_18129() -> int:
	if (wCollisionPoints & COLLISION_DOWN) == 0:
		return block_free()
	hYPos = word(hYPos + 0x10)
	return left_slope_collision()


## BlockFunc_1813f: the block below a left slope.
func block_1813f() -> int:
	if wBlockFuncWarioFlag != 0 and wWarioState == WST_ATTACKING_AIRBORNE:
		return block_solid()
	if (wCollisionPoints & (COLLISION_DOWN | COLLISION_UNK1)) == 0:
		return block_free()
	hYPos = word(hYPos - 0x10)
	return left_slope_collision()


## BlockFunc_LeftSlope
func block_left_slope() -> int:
	if (wCollisionPoints & (COLLISION_DOWN | COLLISION_UNK1)) == 0:
		return block_free()
	if (wCollisionPoints & COLLISION_UNK1) != 0:
		# Landing above the diagonal (x >= y within the block) is free.
		if (lo(hXPos) & 0x0F) >= (lo(hYPos) & 0x0F):
			return block_free()
	return left_slope_collision()


## LeftSlopeCollision: hYPos onto the diagonal.
func left_slope_collision() -> int:
	if (wCollisionPoints & (COLLISION_DOWN | COLLISION_UNK1)) != 0:
		var c: int = (lo(hXPos) & 0x0F) + 2
		hYPos = word(((hYPos & 0xFF00) | (lo(hYPos) & 0xF0)) + c)
		if wBlockFuncWarioFlag != 0:
			wWarioSlopeInteraction = ON_SLOPE | LEFT_SLOPE
		else:
			wObjSlopeInteraction = ON_SLOPE | LEFT_SLOPE
	return result_slope()


## BlockFunc_Floor: a one-way platform, solid to DOWN and UNK2 and near its top for landing.
func block_floor() -> int:
	wc1ca = 1
	var points: int = wCollisionPoints
	var catch: bool = (points & (COLLISION_DOWN | COLLISION_UNK2)) != 0
	if not catch:
		if (points & (COLLISION_UNK3 | COLLISION_UNK4 | COLLISION_UNK5 | COLLISION_UNK7)) != 0:
			return block_free()
		if (lo(hYPos) & 0x0F) >= 5:
			return block_free()
	if wBlockFuncWarioFlag == 0:
		return block_solid()
	if wWarioState == WST_ZOMBIE_LANDING or wWarioState == WST_ZOMBIE_SLIPPING_THROUGH_FLOOR:
		return block_free()
	return block_solid()


## BlockFunc_Ladder
func block_ladder() -> int:
	if wBlockFuncWarioFlag == 0 or (wCollisionPoints & COLLISION_UNK7) == 0:
		return block_free()
	wLadderInteraction = LADDER_COLLISION
	return result_zero()


## BlockFunc_182dc: solid to objects; to Wario, a ladder's top (Func_182ec).
func block_182dc() -> int:
	if wBlockFuncWarioFlag == 0:
		return block_solid()
	return block_ladder_top()


## BlockFunc_LadderTop and Func_182ec
func block_ladder_top() -> int:
	if wBlockFuncWarioFlag == 0 or (wCollisionPoints & COLLISION_UNK7) == 0:
		return block_floor()
	wLadderInteraction = LADDER_UNDERNEATH
	return result_zero()


## BlockFunc_182fe: a ladder that also starts room transition 5.
func block_182fe() -> int:
	if wBlockFuncWarioFlag == 0 or (wCollisionPoints & COLLISION_UNK7) == 0:
		return block_free()
	wLadderInteraction = LADDER_COLLISION
	wRoomTransitionParam = ROOMTRANSITION_5 | ROOMTRANSITIONF_RELOAD_OBJECTS
	return block_free()


## BlockFunc_Door: Up while idling (or slipping, or idling with a grab) enters the door.
func block_door() -> int:
	if wBlockFuncWarioFlag == 0 or (wCollisionPoints & COLLISION_UNK7) == 0:
		return block_free()
	if (wJoypadPressed & PAD_UP) == 0:
		return block_free()
	if wWarioState != WST_IDLING and wWarioState != 0x30 and wWarioState != 0x1F:
		return block_free()
	wRoomTransitionParam = (ROOMTRANSITION_DOOR | ROOMTRANSITIONF_DOOR | ROOMTRANSITIONF_RELOAD_OBJECTS
			| ROOMTRANSITIONF_DELAY)
	enter_door()
	return block_free()


## BlockFunc_WaterSpike: water that stings Wario (SetState_WaterStung) unless invincible or
## already stung.
func block_water_spike() -> int:
	if wBlockFuncWarioFlag != 0 and wInvincibleCounter == 0 and wWarioState != WST_WATER_STUNG:
		set_state_water_stung()
	return block_water()


## BlockFunc_UnderwaterDoor: water; for Wario's presence probe (untransformed or invisible), deep
## water and, with Up pressed, the underwater door's room transition, the block itself free.
## BlockFunc_18727 is the same door without reloading the objects (`reload` false).
func block_underwater_door(reload: bool = true) -> int:
	if wBlockFuncWarioFlag == 0:
		return block_water()
	if wTransformation != 0 and wTransformation != TRANSFORMATION_INVISIBLE_WARIO:
		return block_water()
	if (wCollisionPoints & COLLISION_UNK7) == 0:
		return block_water()
	wWaterInteraction = SUBMERSIBLE_WATER
	if (wJoypadPressed & PAD_UP) != 0:
		wRoomTransitionParam = (ROOMTRANSITION_UNDERWATER_DOOR | ROOMTRANSITIONF_DOOR
				| (ROOMTRANSITIONF_RELOAD_OBJECTS if reload else 0))
	return block_free()


## BlockFunc_187de: water; Wario's presence there is room transition 4, reloading the objects.
func block_187de() -> int:
	if wBlockFuncWarioFlag != 0 and (wCollisionPoints & COLLISION_UNK7) != 0:
		wRoomTransitionParam = ROOMTRANSITION_4 | ROOMTRANSITIONF_RELOAD_OBJECTS
	return block_water()


## BlockFunc_18262: free to Wario; to objects (wc1ca set) solid below and for UNK2, free for UNK3-5
## and 7, otherwise solid only in its top 5 px.
func block_18262() -> int:
	if wBlockFuncWarioFlag != 0:
		return block_free()
	wc1ca = 1
	if (wCollisionPoints & (COLLISION_DOWN | COLLISION_UNK2)) != 0:
		return block_solid()
	if (wCollisionPoints & (COLLISION_UNK3 | COLLISION_UNK4 | COLLISION_UNK5 | COLLISION_UNK7)) != 0:
		return block_free()
	return block_solid() if (lo(hYPos) & 0x0F) < 5 else block_free()


## BlockFunc_NonSolidSpike: free; it stings Wario (turning him round) unless he is invincible,
## already stung, or passing through (wca94 2): SetState_Stung, or for one vulnerable in a
## transformation (wca94 1) Func_206eb, which ends the transformation first.
func block_non_solid_spike() -> int:
	_spike_sting()
	return block_free()


## BlockFunc_SolidSpike: the same sting, but solid.
func block_solid_spike() -> int:
	_spike_sting()
	return block_solid()


func _spike_sting() -> void:
	if wBlockFuncWarioFlag == 0 or wInvincibleCounter != 0 or wca94 == 2:
		return
	if wWarioState == WST_STUNG or wWarioState == WST_STUNG_RECOVERY:
		return
	wDirection = DIRECTION_RIGHT if wDirection == DIRECTION_LEFT else DIRECTION_LEFT
	if wca94 == 0:
		set_state_stung()
	elif wca94 == 1:
		sting_out_of_transformation()


## SetState_Stung and Func_206eb live in WarioSim; the spike reaches them through these hooks.
func set_state_stung() -> void:
	note_unported("SetState_Stung")


func sting_out_of_transformation() -> void:
	note_unported("Func_206eb")


## BlockFunc_Switch: solid; Wario's head (UNK3, UNK5) flips it ($08), remembers it (wSwitchState,
## as it was), toggles wSwitchStateUpdated (the blocks change at the next room start), and shakes
## the ground for 16 frames if it is still (DoGroundShake; SFX_SWITCH and the redraw presentation).
func block_switch() -> int:
	if wBlockFuncWarioFlag == 0 or (wCollisionPoints & (COLLISION_UNK3 | COLLISION_UNK5)) == 0:
		return block_solid()
	var value: int = level.block_at(block_row, block_column)
	wSwitchState = value
	level.set_block(block_row, block_column, value ^ 0x08)
	wSwitchStateUpdated ^= 1
	if wGroundShakeCounter == 0:
		wGroundShakeCounter = 16
		wIsWarioGroundShaking = 0
	return block_solid()


## BlockFunc_AirCurrent: free; Wario's presence in it (not invincible) is wIsInAirCurrent, and
## untransformed it makes him Fan Wario (bumped by touches, vulnerable to stings).
func block_air_current() -> int:
	if wBlockFuncWarioFlag == 0 or (wCollisionPoints & COLLISION_UNK7) == 0 or wInvincibleCounter != 0:
		return block_free()
	wIsInAirCurrent = 1
	if wTransformation != 0:
		return block_free()
	wTransformation = TRANSFORMATION_FAN
	wTouchState = TOUCH_BUMP
	wStingTouchState = TOUCH_VULNERABLE
	wca94 = 1
	set_state_fan_start()
	return block_free()


## SetState_FanStart lives in WarioSim; the air current reaches it through this hook.
func set_state_fan_start() -> void:
	note_unported("SetState_FanStart")


## BlockFunc_WalkthroughPipe: free; Invisible Wario is himself again (without invincibility).
func block_walkthrough_pipe() -> int:
	if wBlockFuncWarioFlag != 0 and wTransformation == TRANSFORMATION_INVISIBLE_WARIO:
		recover_from_transformation_without_invincibility()
	return block_free()


## BlockFunc_18868: free, but to Vampire Wario solid, and his presence in it puts him beside it
## (left of it from its left half, right of it from its right half).
func block_18868() -> int:
	if wBlockFuncWarioFlag == 0 or wTransformation != TRANSFORMATION_VAMPIRE_WARIO:
		return block_free()
	if (wCollisionPoints & COLLISION_UNK7) == 0:
		return block_solid()
	var base: int = (wWarioXPos & 0xFF00) | (lo(wWarioXPos) & 0xF0)
	if (lo(wWarioXPos) & 0x08) == 0:
		wWarioXPos = word(base - wCollisionBoxRight)
	else:
		wWarioXPos = word(base + byte(0x10 - wCollisionBoxLeft))
	return block_solid()


## BlockFunc_SmallGap: free to objects and to Flat Wario, solid to Wario otherwise.
func block_small_gap() -> int:
	if wBlockFuncWarioFlag == 0 or wTransformation == TRANSFORMATION_FLAT_WARIO:
		return block_free()
	return block_solid()


## BlockFunc_189f1: free to objects, a floor to Wario.
func block_189f1() -> int:
	if wBlockFuncWarioFlag == 0:
		return block_free()
	return block_floor()


## BlockFunc_Fire: free to objects, to Wario's ground probes (DOWN, UNK1, UNK2, UNK6), and while he
## is invincible or in a lasting transformation; otherwise Wario catches fire (Hot Wario for 600
## frames, SetState_OnFire_ResetStateCounter; the music not simulated). That path returns through
## hCallFunc, which leaves its caller's ROM bank ($06) in a, and skips BlockFunc_Free's clearing.
func block_fire() -> int:
	if wBlockFuncWarioFlag == 0 or (wCollisionPoints & (COLLISION_DOWN | COLLISION_UNK1 | COLLISION_UNK2 | COLLISION_UNK6)) != 0 \
			or wInvincibleCounter != 0 or (wTransformation & TRANSFORMATIONF_PERSISTENT) != 0:
		return block_free()
	wTransformation = TRANSFORMATION_HOT_WARIO
	wTransformationProgress = 1
	wTouchState = TOUCH_BUMP
	wStingTouchState = TOUCH_BUMP
	wca94 = 2
	wTransformationDuration = HOT_WARIO_DURATION
	wWarioStateCounter = 0
	set_state_on_fire()
	return 0x06


## SetState_OnFire lives in WarioSim; the fire block reaches it through this hook.
func set_state_on_fire() -> void:
	note_unported("SetState_OnFire")


## SetState_WaterStung lives in WarioSim; the water spike reaches it through this hook.
func set_state_water_stung() -> void:
	note_unported("SetState_WaterStung")


## EnterDoor lives in WarioSim; the door handler reaches it through this hook.
func enter_door() -> void:
	note_unported("EnterDoor")


## BlockFunc_DownPipe_Left and _Right: solid; Wario idling on it (or idling holding something)
## with Down held goes down the pipe (EnterPipeDown).
func block_down_pipe(left: bool) -> int:
	if wBlockFuncWarioFlag == 0 or (wWarioState != WST_IDLING and wWarioState != WST_GRAB_IDLING):
		return block_solid()
	if (wCollisionPoints & COLLISION_DOWN) == 0 or (wJoypadDown & PAD_DOWN) == 0:
		return block_solid()
	_centre_on_pipe(left)
	enter_pipe(true)
	return block_solid()


## BlockFunc_UpPipe_Left and _Right: solid; Wario airborne under it (or airborne holding
## something) with Up held goes up the pipe (EnterPipeUp).
func block_up_pipe(left: bool) -> int:
	if wBlockFuncWarioFlag == 0 or (wWarioState != WST_AIRBORNE and wWarioState != WST_GRAB_AIRBORNE):
		return block_solid()
	if (wCollisionPoints & COLLISION_UNK5) == 0 or (wJoypadDown & PAD_UP) == 0:
		return block_solid()
	_centre_on_pipe(left)
	enter_pipe(false)
	return block_solid()


## On the pipe's middle: from its left half's block, x & $f0 + $18 (carrying into the high byte);
## from its right half's, x & $f0 + $08.
func _centre_on_pipe(left: bool) -> void:
	if left:
		wWarioXPos = word((wWarioXPos & 0xFF00) + (lo(wWarioXPos) & 0xF0) + 0x18)
	else:
		wWarioXPos = (wWarioXPos & 0xFF00) | ((lo(wWarioXPos) & 0xF0) + 0x08)


## EnterPipeDown and EnterPipeUp live in WarioSim; the pipe handlers reach them through this hook.
func enter_pipe(_down: bool) -> void:
	note_unported("EnterPipeDown" if _down else "EnterPipeUp")


## BlockFunc_MinigameDoor: as a door, from idling (or idling holding something), into the golf
## minigame's room.
func block_minigame_door() -> int:
	if wBlockFuncWarioFlag == 0 or (wCollisionPoints & COLLISION_UNK7) == 0:
		return block_free()
	if (wJoypadPressed & PAD_UP) == 0:
		return block_free()
	if wWarioState != WST_IDLING and wWarioState != WST_GRAB_IDLING:
		return block_free()
	wRoomTransitionParam = (ROOMTRANSITION_GOLF | ROOMTRANSITIONF_DOOR | ROOMTRANSITIONF_RELOAD_OBJECTS
			| ROOMTRANSITIONF_DELAY)
	enter_door()
	return block_free()


## BlockFunc_LightSource: free; light turns Zombie Wario back (SetState_ZombieRecovering) and
## Vampire Wario too (RecoverFromTransformation_WithoutInvincibility).
func block_light_source() -> int:
	if wBlockFuncWarioFlag != 0:
		if wTransformation == TRANSFORMATION_ZOMBIE_WARIO:
			set_state_zombie_recovering()
		elif wTransformation == TRANSFORMATION_VAMPIRE_WARIO:
			recover_from_transformation_without_invincibility()
	return block_free()


## SetState_ZombieRecovering and RecoverFromTransformation_WithoutInvincibility live in WarioSim;
## the light source reaches them through these hooks.
func set_state_zombie_recovering() -> void:
	note_unported("SetState_ZombieRecovering")


func recover_from_transformation_without_invincibility() -> void:
	note_unported("RecoverFromTransformation_WithoutInvincibility")


## BlockFunc_188ba: solid to objects, free to Wario.
func block_188ba() -> int:
	if wBlockFuncWarioFlag == 0:
		return block_solid()
	return block_free()


## BlockFunc_Fence: for Wario's presence probe (UNK7), near a fence (Func_1808c's result);
## otherwise free.
func block_fence() -> int:
	if wBlockFuncWarioFlag == 0 or (wCollisionPoints & COLLISION_UNK7) == 0:
		return block_free()
	wIsNearFence = 1
	return result_zero()


## BlockFunc_SlipperySolid and BlockFunc_SlipperyFloor: solid (or a floor), slippery under
## Wario's feet (DOWN).
func block_slippery(solid: bool) -> int:
	if wBlockFuncWarioFlag != 0 and (wCollisionPoints & COLLISION_DOWN) != 0:
		wIsOnSlipperyGround = 1
	return block_solid() if solid else block_floor()


## BlockFunc_CloudPlatform1: a floor while the room's palette cycle is below 4 or at 7.
func block_cloud_platform_1() -> int:
	if wRoomPalCycleIndex == 7 or wRoomPalCycleIndex < 4:
		return block_floor()
	return block_free()


## BlockFunc_CloudPlatform2: a floor from the room's palette cycle's index 3.
func block_cloud_platform_2() -> int:
	if wRoomPalCycleIndex < 3:
		return block_free()
	return block_floor()


## BlockFunc_187b0: room transition 4.
func block_187b0() -> int:
	if wBlockFuncWarioFlag == 0 or (wCollisionPoints & COLLISION_UNK7) == 0:
		return block_free()
	wRoomTransitionParam = ROOMTRANSITION_4 | ROOMTRANSITIONF_RELOAD_OBJECTS
	return block_free()


## CrackedBlockCollision and CrackedBlockWithColourCoinCollision (which has no robo-mouse checks).
func cracked_block_collision(replacement: int, colour_coin: bool) -> int:
	if not colour_coin:
		if wBlockFuncSpecialCollision == COLLISION_ROBO_MOUSE_BREAK:
			return func_19423(replacement)
		if wBlockFuncSpecialCollision == COLLISION_ROBO_MOUSE_FREE:
			return block_free()
	if wBlockFuncBreakFlag == 0:
		return block_solid()
	var points: int = wCollisionPoints
	if (points & COLLISION_UNK4) != 0:
		if wAttackCounter == 0 and wIsRolling == 0:
			return block_solid()
	elif (points & (COLLISION_UNK5 | COLLISION_UNK3)) != 0:
		if wPowerUpLevel < HEAD_SMASH_HELMET:
			return block_solid()
		if wJumpVelTable == 0 and wSwimVelIndex == 0:
			return block_solid()
	elif (points & (COLLISION_UNK1 | COLLISION_UNK6)) == 0:
		return block_solid()
	break_block(replacement, colour_coin)
	if wIsRolling != 0 or wTransformation == TRANSFORMATION_FAT_WARIO:
		return block_free()
	if wIsSmashAttacking != 0:
		return block_solid() if wPowerUpLevel < SUPER_JUMP_SLAM_OVERALLS else block_free()
	return block_solid() if wPowerUpLevel < GARLIC else block_free()


## NonCrackedBlockCollision
func non_cracked_block_collision(replacement: int) -> int:
	if wBlockFuncSpecialCollision == COLLISION_ROBO_MOUSE_BREAK:
		return func_19423(replacement)
	if wBlockFuncSpecialCollision == COLLISION_ROBO_MOUSE_FREE:
		return block_free()
	if wBlockFuncBreakFlag == 0:
		return block_solid()
	var points: int = wCollisionPoints
	if wTransformation == TRANSFORMATION_FAT_WARIO:
		if (points & (COLLISION_UNK1 | COLLISION_UNK6)) != 0:
			return _break_non_cracked(replacement)
		return block_solid()
	if wPowerUpLevel < GARLIC:
		return block_solid()
	if (points & COLLISION_UNK4) != 0:
		if wAttackCounter != 0 or wIsRolling != 0:
			return _break_non_cracked(replacement)
		return block_solid()
	if (points & (COLLISION_UNK5 | COLLISION_UNK3)) != 0:
		if wPowerUpLevel < HEAD_SMASH_HELMET:
			return block_solid()
		if wJumpVelTable != 0 or wSwimVelIndex != 0:
			return _break_non_cracked(replacement)
		return block_solid()
	if (points & (COLLISION_UNK1 | COLLISION_UNK6)) != 0 and wPowerUpLevel >= SUPER_JUMP_SLAM_OVERALLS:
		return _break_non_cracked(replacement)
	return block_solid()


## Func_18df1
func _break_non_cracked(replacement: int) -> int:
	break_block(replacement)
	return block_free() if wIsRolling != 0 else block_solid()


# --- Multi-block breakables (block_functions.asm, ProcessMultiBlock) --------------------------

## wcedb and wcedc: the last block of a chain broken, where ProcessMultiBlock looks for the next.
var multi_block_row: int = 0
var multi_block_column: int = 0


## Func_18e2c (direction 1), Func_18ec0 (3), Func_18f7d (2), and Func_19011 (4): free while a
## chain's direction is set; in a chain (bit 4 and up), broken at once and passed on (Func_18f32); otherwise as a
## cracked block (the robo-mouse breaks it as a chain does), the break passed on and Wario's
## floor transition set (Func_19086).
func multi_cracked_block_collision(replacement: int, direction: int) -> int:
	if (wMultiBlockParam & 0x07) != 0:
		return block_free()
	if (wMultiBlockParam & 0xF8) != 0:
		wMultiBlockParam = (wMultiBlockParam & 0xF8) | direction
		return _multi_break_free(replacement)
	if wBlockFuncSpecialCollision == COLLISION_ROBO_MOUSE_FREE:
		return block_free()
	if wBlockFuncSpecialCollision == COLLISION_ROBO_MOUSE_BREAK:
		wMultiBlockParam = direction
		return _multi_break_free(replacement)
	if wBlockFuncBreakFlag == 0:
		return block_solid()
	var points: int = wCollisionPoints
	if (points & COLLISION_UNK4) != 0:
		if wAttackCounter == 0 and wIsRolling == 0:
			return block_solid()
	elif (points & (COLLISION_UNK5 | COLLISION_UNK3)) != 0:
		if wPowerUpLevel < HEAD_SMASH_HELMET:
			return block_solid()
		if wJumpVelTable == 0 and wSwimVelIndex == 0:
			return block_solid()
	elif (points & (COLLISION_UNK1 | COLLISION_UNK6)) == 0:
		return block_solid()
	wMultiBlockParam = direction
	_multi_record()
	wIsFloorTransition = 1
	break_block(replacement)
	if wIsRolling != 0 or wTransformation == TRANSFORMATION_FAT_WARIO:
		return block_free()
	if wIsSmashAttacking != 0:
		return block_solid() if wPowerUpLevel < SUPER_JUMP_SLAM_OVERALLS else block_free()
	return block_solid() if wPowerUpLevel < GARLIC else block_free()


## Func_190fe (direction 1), Func_191b3 (3), Func_19291 (2), and Func_19346 (4): solid while a
## chain's direction is set; in a chain, broken and passed on (Func_19246); otherwise as a non-cracked
## block, the break passed on and Wario's floor transition set (Func_193dc, then Func_18df1). Rolling
## into Func_190fe's needs the Super Jump Slam Overalls; into the other three it does not.
func multi_non_cracked_block_collision(replacement: int, direction: int) -> int:
	if (wMultiBlockParam & 0x07) != 0:
		return block_solid()
	if (wMultiBlockParam & 0xF8) != 0:
		wMultiBlockParam = (wMultiBlockParam & 0xF8) | direction
		return _multi_break_free(replacement)
	if wBlockFuncSpecialCollision == COLLISION_ROBO_MOUSE_FREE:
		return block_free()
	if wBlockFuncSpecialCollision == COLLISION_ROBO_MOUSE_BREAK:
		wMultiBlockParam = direction
		return _multi_break_free(replacement)
	if wBlockFuncBreakFlag == 0:
		return block_solid()
	var points: int = wCollisionPoints
	var breaks: bool
	if wTransformation == TRANSFORMATION_FAT_WARIO:
		breaks = (points & (COLLISION_UNK1 | COLLISION_UNK6)) != 0
	elif wPowerUpLevel < GARLIC:
		breaks = false
	elif (points & COLLISION_UNK4) != 0:
		if wAttackCounter != 0:
			breaks = true
		elif wIsRolling != 0:
			breaks = direction != 1 or wPowerUpLevel >= SUPER_JUMP_SLAM_OVERALLS
		else:
			breaks = false
	elif (points & (COLLISION_UNK5 | COLLISION_UNK3)) != 0:
		breaks = wPowerUpLevel >= HEAD_SMASH_HELMET and (wJumpVelTable != 0 or wSwimVelIndex != 0)
	elif (points & (COLLISION_UNK1 | COLLISION_UNK6)) != 0:
		breaks = wPowerUpLevel >= SUPER_JUMP_SLAM_OVERALLS
	else:
		breaks = false
	if not breaks:
		return block_solid()
	wMultiBlockParam = direction
	_multi_record()
	wIsFloorTransition = 1
	return _break_non_cracked(replacement)


## Func_19522 (direction 1), Func_19560 (3), Func_1959b (2), and YarnBlockCollision (4): free
## while a chain's direction is set; in a chain, broken and passed on; to objects solid; only a ball
## of string breaks it (and passes it on).
func multi_string_block_collision(replacement: int, direction: int) -> int:
	if (wMultiBlockParam & 0x07) != 0:
		return block_free()
	if (wMultiBlockParam & 0xF8) != 0:
		wMultiBlockParam = (wMultiBlockParam & 0xF8) | direction
		return _multi_break_free(replacement)
	if wBlockFuncWarioFlag == 0 or wTransformation != TRANSFORMATION_BALL_O_STRING_WARIO:
		return block_solid()
	wMultiBlockParam = direction
	return _multi_break_free(replacement)


## Func_18aa8 to _18b71 (a snowball) and Func_18bb5 to _18c7e (`big`: the big snowball, progress
## 3): as the string blocks, broken by Snowman Wario rolled into a snowball (progress 1 or more).
func multi_snowball_block_collision(replacement: int, direction: int, big: bool) -> int:
	if (wMultiBlockParam & 0x07) != 0:
		return block_free()
	if (wMultiBlockParam & 0xF8) != 0:
		wMultiBlockParam = (wMultiBlockParam & 0xF8) | direction
		return _multi_break_free(replacement)
	if wBlockFuncWarioFlag == 0 or wTransformation != TRANSFORMATION_SNOWMAN_WARIO:
		return block_solid()
	if (wTransformationProgress != 3) if big else (wTransformationProgress < 1):
		return block_solid()
	wMultiBlockParam = direction
	return _multi_break_free(replacement)


## wcedb and wcedc take the block's position (wcedf its byte, never read).
func _multi_record() -> void:
	multi_block_row = block_row
	multi_block_column = block_column


## Func_18f32 and Func_19246: recorded, broken, free.
func _multi_break_free(replacement: int) -> int:
	_multi_record()
	break_block(replacement)
	return block_free()


## ProcessMultiBlock.ProcessBlocks: the chain in one frame. From the block last broken, the next in
## the direction given is processed with a chain's bit set; a multi-block breakable there breaks and
## passes the direction on, anything else ends the chain, and the sub-state returns.
func process_multi_blocks() -> void:
	wMultiBlockParam = byte((wMultiBlockParam & 0x0F) + 0x10)
	while true:
		match wMultiBlockParam & 0x07:
			1:
				block_row = multi_block_row
				block_column = multi_block_column + 1
			2:
				block_row = multi_block_row
				block_column = multi_block_column - 1
			3:
				block_row = multi_block_row - 1
				block_column = multi_block_column
			_:
				block_row = multi_block_row + 1
				block_column = multi_block_column
		wMultiBlockParam &= 0xF8
		process_block()
		if (wMultiBlockParam & 0x07) == 0:
			break
	wMultiBlockParam = 0
	wIsFloorTransition = 0


## BonfireBlockCollision: only Hot Wario engulfed in flames breaks it.
func bonfire_block_collision(replacement: int) -> int:
	if wBlockFuncWarioFlag == 0:
		return block_solid()
	if wTransformation == TRANSFORMATION_HOT_WARIO and wTransformationProgress >= 2:
		break_block(replacement)
		return block_free()
	return block_solid()


## EnemyBlockCollision (BlockFunc_EnemyBlock_78-7f): solid; only a thrown object breaks it.
func enemy_block_collision(replacement: int) -> int:
	if wBlockFuncSpecialCollision != COLLISION_THROWN_OBJ:
		return block_solid()
	return func_19423(replacement)


## DoughnutBlockCollision (BlockFunc_DoughnutBlock_78-7b): solid; Fat Wario's feet (UNK1, UNK6)
## break it (BreakBlock), and it is still solid that probe.
func doughnut_block_collision(replacement: int) -> int:
	if wBlockFuncWarioFlag != 0 and wTransformation == TRANSFORMATION_FAT_WARIO \
			and (wCollisionPoints & (COLLISION_UNK1 | COLLISION_UNK6)) != 0:
		break_block(replacement)
	return block_solid()


## Func_19423 (an object breaking a block: a thrown one through an enemy block, the robo-mouse
## through a cracked or non-cracked one): the block becomes `replacement` (bit 7 kept), and when
## the object is on screen it breaks as BreakBlock breaks one (debris and maybe a coin); off screen
## there is only the sound. The redraw it queues (Func_e2b, on screen only) is presentation.
func func_19423(replacement: int) -> int:
	if cur_object_on_screen():
		break_block(replacement)
	else:
		var old: int = level.block_at(block_row, block_column)
		level.set_block(block_row, block_column, (old & 0x80) | replacement)
	return block_free()


## wCurObjFlags' OBJFLAG_ON_SCREEN, for the block handlers an object's probe runs; ObjectSim's.
func cur_object_on_screen() -> bool:
	return false


## The map write every breaking path makes, then BreakBlock: a coin at the block, setting
## wCoinCooldown, when rDIV & 3 is 0 and the cooldown is clear. The colour-coin blocks call
## BreakBlockWithColourCoin instead, which always leaves a colour coin. The debris particle
## (CreateParticleInBlock) and the tile redraw are presentation.
func break_block(replacement: int, colour_coin: bool = false) -> void:
	var old: int = level.block_at(block_row, block_column)
	level.set_block(block_row, block_column, (old & 0x80) | replacement)
	# hPos is kept around the debris (CreateParticleInBlock moves it to the block's bottom middle).
	var saved_y: int = hYPos
	var saved_x: int = hXPos
	create_particle_in_block(PARTICLE_DEBRIS, block_row, block_column)
	var y: int = hYPos
	var x: int = hXPos
	_break_block_coin(colour_coin, y, x)
	hYPos = saved_y
	hXPos = saved_x


func _break_block_coin(colour_coin: bool, y: int, x: int) -> void:
	if colour_coin:
		create_block_coin(OBJ_PARAMS_COLOUR_COIN, y, x)
		return
	if (read_div(DIV_BREAK_BLOCK) & 0b11) != 0 or wCoinCooldown != 0:
		return
	wCoinCooldown = COIN_COOLDOWN
	create_block_coin(OBJ_PARAMS_COIN, y, x)


## The coin a broken block leaves. The object slots are ObjectSim's, which creates it; Wario's
## variables do not depend on it.
func create_block_coin(_params: int, _y: int, _x: int) -> void:
	pass
