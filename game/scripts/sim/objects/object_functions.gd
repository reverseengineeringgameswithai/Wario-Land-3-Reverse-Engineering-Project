class_name ObjectFunctions
extends ObjectStates
## Each ported object's own functions, by translation from src/engine/level/objects/*.asm: the
## musical coin and the Spearhead. A function is found by the bank and pointer the game keeps in
## OBJ_UPDATE_FUNCTION (bank "Object Functions 1" + the ID's high nibble), as the reference build
## labels them. States an object reaches that are not ported are named in `unported`.
## Research note: docs/02-research/objects.md.

const COIN_FUNC: int = 0x18_7383  # CoinFunc
const COIN_FUNC_COLOUR_COIN: int = 0x18_7394  # CoinFunc.ColourCoin
const COIN_FUNC_UPDATE: int = 0x18_73B2  # CoinFunc.Update
const OBJ_INTERACTION_COLOUR_COIN: int = 0x4A
const TORCH_FUNC: int = 0x10_4BA9  # TorchFunc
const TORCH_FUNC_UPDATE: int = 0x10_4BD1
const TORCH_NO_EMBERS_FUNC: int = 0x10_4B9D  # TorchNoEmbersFunc
const TORCH_NO_EMBERS_FUNC_UPDATE: int = 0x10_4BA8
const TORCH_EMBER_LEFT_1_FUNC: int = 0x10_4C3F  # TorchEmberLeft1Func
const TORCH_EMBER_RIGHT_1_FUNC: int = 0x10_4C44
const TORCH_EMBER_LEFT_2_FUNC: int = 0x10_4C49
const TORCH_EMBER_RIGHT_2_FUNC: int = 0x10_4C4E
const TORCH_EMBER_COMMON_FUNC_DESTROY: int = 0x10_4C92  # TorchEmberCommonFunc.Destroy
const OBJ_PARAMS_TORCH_EMBER_LEFT_1: int = 0x4E80  # bank $19
const OBJ_PARAMS_TORCH_EMBER_RIGHT_1: int = 0x4E93
const OBJ_PARAMS_TORCH_EMBER_LEFT_2: int = 0x4EA6
const OBJ_PARAMS_TORCH_EMBER_RIGHT_2: int = 0x4EB9
const FRAMESET_68359: int = 0x4359
const FRAMESET_68360: int = 0x4360
const GREY_CHEST_FUNC: int = 0x13_48B6  # GreyChestFunc (red, green, and blue follow)
const RED_CHEST_FUNC: int = 0x13_48BF
const GREEN_CHEST_FUNC: int = 0x13_48C8
const BLUE_CHEST_FUNC: int = 0x13_48D1
const CHEST_FUNC_UPDATE: int = 0x13_48FE  # ChestFunc.Update
const CHEST_FUNC_RET: int = 0x13_491C  # ChestFunc.Ret
const CHEST_FUNC_OPEN: int = 0x13_491D  # ChestFunc.Open
const GREY_TREASURE_FUNC: int = 0x13_4970  # GreyTreasureFunc (red, green, and blue follow)
const RED_TREASURE_FUNC: int = 0x13_4975
const GREEN_TREASURE_FUNC: int = 0x13_497A
const BLUE_TREASURE_FUNC: int = 0x13_497F
const OBJ_PARAMS_GREY_TREASURE: int = 0x4A40  # bank $19; red, green, and blue follow every $15
const OBJ_INTERACTION_GREY_TREASURE: int = 0x14
const GREY_TREASURE: int = 1 << 4  # wKeyAndTreasureFlags: GREY_TREASURE_F
const FRAMESET_68000: int = 0x4000
const FRAMESET_68003: int = 0x4003
const FRAMESET_68060: int = 0x4060
const FRAMESET_681BE: int = 0x41BE  # the treasures', every 5 bytes
const SILKY_FUNC: int = 0x10_6D1D  # SilkyFunc
const SILKY_FUNC_INIT: int = 0x10_6D27
const SILKY_FUNC_UPDATE: int = 0x10_6D3B
const DIV_SILKY_WAIT: int = 0x10_6EA6  # SilkyFunc's rDIV reads: .Func_42e95, .asm_42f44, .Func_430f6
const DIV_SILKY_WALK: int = 0x10_6F4D
const DIV_SILKY_TURN: int = 0x10_70FF
const DIV_FUNC_6305F: int = 0x18_7061  # Func_6305f's rDIV read
const OBJ_INTERACTION_SILKY: int = 0x19
const FRAMESET_68744: int = 0x4744
const FRAMESET_6874D: int = 0x474D
const FRAMESET_68756: int = 0x4756
const FRAMESET_6875F: int = 0x475F
const FRAMESET_68768: int = 0x4768
const FRAMESET_68771: int = 0x4771
const FRAMESET_6877A: int = 0x477A
const FRAMESET_68783: int = 0x4783
const FRAMESET_6879E: int = 0x479E  # Silky thrown, facing left
const FRAMESET_687A7: int = 0x47A7  # facing right
const FRAMESET_6878C: int = 0x478C
const FRAMESET_68795: int = 0x4795
const FRAMESET_687B0: int = 0x47B0
const FRAMESET_687BB: int = 0x47BB
const FRAMESET_687C6: int = 0x47C6
const KEY_FUNC: int = 0x13_4992  # KeyFunc
const KEY_FUNC_UPDATE: int = 0x13_49B7  # KeyFunc.Update
const FRAMESET_6804F: int = 0x404F
const MUSICAL_COIN_FUNC: int = 0x13_49D4  # MusicalCoinFunc
const MUSICAL_COIN_FUNC_UPDATE: int = 0x13_49F9  # MusicalCoinFunc.Update
const SPEARHEAD_FUNC: int = 0x10_4040  # SpearheadFunc
const SPEARHEAD_FUNC_INIT: int = 0x10_404E  # SpearheadFunc.Init
const SPEARHEAD_FUNC_UPDATE: int = 0x10_4069  # SpearheadFunc.Update
const SMALL_LEAF_FUNC: int = 0x10_76EA  # SmallLeafFunc
const SMALL_LEAF_FUNC_INIT: int = 0x10_7700
const SMALL_LEAF_FUNC_UPDATE_4: int = 0x10_770F
const SMALL_LEAF_FUNC_UPDATE_1: int = 0x10_771B
const SMALL_LEAF_FUNC_UPDATE_2: int = 0x10_774A
const SMALL_LEAF_FUNC_UPDATE_3: int = 0x10_777A
const WEBBER_FUNC: int = 0x10_4825  # WebberFunc
const WEBBER_FUNC_UPDATE: int = 0x10_4895
const WEBBER_PROJECTILE_FUNC: int = 0x10_4AB1  # WebberProjectileFunc
const WEBBER_PROJECTILE_FUNC_DESTROY: int = 0x10_4B05
const OBJ_PARAMS_WEBBER_PROJECTILE: int = 0x47A0  # ObjParams_WebberProjectile (bank $19)
const FUNC_3326: int = 0x3326  # home bank: knocked right (Func_62840)
const FUNC_3317: int = 0x3317  # home bank: knocked left (Func_62898)
const FUNC_3407: int = 0x3407  # home bank: knocked right without Garlic's (Func_6283a)
const FUNC_33F8: int = 0x33F8  # home bank: knocked left without Garlic's (Func_62892)
const FUNC_3173: int = 0x3173  # home bank: Func_62e57
const STARS_FUNC_SET_FLAGS: int = 0x13_4893  # StarsFunc_SetFlags
const STARS_FUNC_WITH_Y_OFFSET: int = 0x13_487C  # StarsFunc_WithYOffset
const BIRD_FUNC: int = 0x10_7278  # BirdFunc
const BIRD_FUNC_INIT: int = 0x10_7282
const BIRD_FUNC_UPDATE: int = 0x10_7362
const BIRD_FUNC_FLY_OFF: int = 0x10_7353  # BirdFunc.Func_43353
const BIRD_FUNC_STUNNED: int = 0x10_740B  # BirdFunc.Func_4340b (the blue bird, hit)
const BIRD_FUNC_RECOVER: int = 0x10_7427  # BirdFunc.Func_43427
const BLUE_BIRD: int = 0x0D
const OBJ_PARAMS_BIRD_STARS_1: int = 0x49C2  # bank $19
const OBJ_PARAMS_BIRD_STARS_2: int = 0x49D7
const FRAMESET_687C9: int = 0x47C9
const FRAMESET_687CE: int = 0x47CE
const FRAMESET_687D3: int = 0x47D3
const FRAMESET_687E4: int = 0x47E4
const FRAMESET_687F5: int = 0x47F5
const FRAMESET_687FA: int = 0x47FA
const FRAMESET_687FF: int = 0x47FF
const FRAMESET_682A4: int = 0x42A4
const FRAMESET_682A9: int = 0x42A9
const FRAMESET_682B2: int = 0x42B2
const FRAMESET_682B7: int = 0x42B7
const FRAMESET_682C2: int = 0x42C2
const FRAMESET_682C5: int = 0x42C5
const FRAMESET_682D1: int = 0x42D1
const FRAMESET_682D6: int = 0x42D6
const FRAMESET_682DB: int = 0x42DB
const FRAMESET_682E2: int = 0x42E2
const FUTAMOGU_FUNC: int = 0x10_46C4  # FutamoguFunc
const FUTAMOGU_FUNC_UPDATE: int = 0x10_4743
const FRAMESET_68319: int = 0x4319
const FRAMESET_68336: int = 0x4336
const FRAMESET_68343: int = 0x4343
const FRAMESET_68348: int = 0x4348
const FRAMESET_68351: int = 0x4351
const OBJSTATE_3A: int = 0x3A
const FRAMESET_68A9F: int = 0x4A9F
const FRAMESET_68AA8: int = 0x4AA8
const FRAMESET_68ABB: int = 0x4ABB
# Object framesets (bank $1a pointers).
const FRAMESET_68036: int = 0x4036
const FRAMESET_681D2: int = 0x41D2
const FRAMESET_681DB: int = 0x41DB
const FRAMESET_681E4: int = 0x41E4
const FRAMESET_681ED: int = 0x41ED
const FRAMESET_68292: int = 0x4292  # the Spearhead's full throw
const FRAMESET_6829B: int = 0x429B
const FRAMESET_681F6: int = 0x41F6
const FRAMESET_681FF: int = 0x41FF
const FRAMESET_68208: int = 0x4208
const FRAMESET_68213: int = 0x4213
const FRAMESET_6821E: int = 0x421E
const FRAMESET_68229: int = 0x4229
const FRAMESET_6824F: int = 0x424F
const FRAMESET_6825A: int = 0x425A
const FRAMESET_68265: int = 0x4265
const FRAMESET_6826E: int = 0x426E
const FRAMESET_68234: int = 0x4234  # the Spearhead asleep
const FRAMESET_6827C: int = 0x427C  # the Spearhead waking
const FRAMESET_68287: int = 0x4287
const FRAMESET_68277: int = 0x4277


func object_functions() -> Dictionary:
	return {
		COIN_FUNC: coin_func,
		COIN_FUNC_COLOUR_COIN: coin_func_colour_coin,
		COIN_FUNC_UPDATE: coin_update,
		TORCH_FUNC: torch_func,
		TORCH_FUNC_UPDATE: torch_update,
		TORCH_NO_EMBERS_FUNC: torch_no_embers_func,
		TORCH_NO_EMBERS_FUNC_UPDATE: torch_no_embers_update,
		TORCH_EMBER_LEFT_1_FUNC: torch_ember_left_1,
		TORCH_EMBER_RIGHT_1_FUNC: torch_ember_right_1,
		TORCH_EMBER_LEFT_2_FUNC: torch_ember_left_2,
		TORCH_EMBER_RIGHT_2_FUNC: torch_ember_right_2,
		TORCH_EMBER_COMMON_FUNC_DESTROY: _torch_ember_destroy,
		GREY_CHEST_FUNC: grey_chest_func,
		RED_CHEST_FUNC: red_chest_func,
		GREEN_CHEST_FUNC: green_chest_func,
		BLUE_CHEST_FUNC: blue_chest_func,
		CHEST_FUNC_UPDATE: chest_update,
		CHEST_FUNC_RET: chest_ret,
		CHEST_FUNC_OPEN: chest_open,
		GREY_TREASURE_FUNC: grey_treasure_func,
		RED_TREASURE_FUNC: red_treasure_func,
		GREEN_TREASURE_FUNC: green_treasure_func,
		BLUE_TREASURE_FUNC: blue_treasure_func,
		SILKY_FUNC: silky_func,
		SILKY_FUNC_INIT: silky_init,
		SILKY_FUNC_UPDATE: silky_update,
		KEY_FUNC: key_func,
		KEY_FUNC_UPDATE: musical_coin_update,
		MUSICAL_COIN_FUNC: musical_coin_func,
		MUSICAL_COIN_FUNC_UPDATE: musical_coin_update,
		SPEARHEAD_FUNC: spearhead_func,
		SPEARHEAD_FUNC_INIT: spearhead_init,
		SPEARHEAD_FUNC_UPDATE: spearhead_update,
		STARS_FUNC: stars_func,
		STARS_FUNC_WITH_Y_OFFSET: stars_func_with_y_offset,
		FUNC_4C860: func_4c860,
		FUNC_3326: func_62840,
		FUNC_3317: func_62898,
		FUNC_3407: func_6283a,
		FUNC_33F8: func_62892,
		FUNC_3173: func_62e57,
		STARS_FUNC_SET_FLAGS: stars_func_set_flags,
		BIRD_FUNC: bird_func,
		BIRD_FUNC_INIT: bird_init,
		BIRD_FUNC_UPDATE: bird_update,
		BIRD_FUNC_FLY_OFF: bird_fly_off,
		BIRD_FUNC_STUNNED: bird_stunned,
		BIRD_FUNC_RECOVER: bird_recover,
		WEBBER_FUNC: webber_func,
		WEBBER_FUNC_UPDATE: webber_update,
		WEBBER_PROJECTILE_FUNC: webber_projectile_func,
		WEBBER_PROJECTILE_FUNC_DESTROY: _webber_projectile_destroy,
		FUTAMOGU_FUNC: futamogu_func,
		FUTAMOGU_FUNC_UPDATE: futamogu_update,
		SMALL_LEAF_FUNC: small_leaf_func,
		SMALL_LEAF_FUNC_INIT: _small_leaf_init,
		SMALL_LEAF_FUNC_UPDATE_1: _small_leaf_update_1,
		SMALL_LEAF_FUNC_UPDATE_2: _small_leaf_update_2,
		SMALL_LEAF_FUNC_UPDATE_3: _small_leaf_update_3,
		SMALL_LEAF_FUNC_UPDATE_4: _small_leaf_update_4,
	}


# --- Musical coin (objects/musical_coin.asm) -----------------------------------------------

func musical_coin_func() -> void:
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, MUSICAL_COIN_FUNC_UPDATE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_object_frameset_ptr(FRAMESET_68036)
	set_cur(OBJ_COLLBOX_RIGHT, 1)
	set_cur(OBJ_COLLBOX_LEFT, -17)
	set_cur(OBJ_COLLBOX_BOTTOM, -7)


func musical_coin_update() -> void:
	if cur(OBJ_STATE) != OBJSTATE_18:
		return
	set_cur(OBJ_FLAGS, 0)
	clear_cur_object_from_map()


# --- Coins (objects/coin.asm) --------------------------------------------------------------

## CoinFunc: the coin a broken block leaves. One in 64 (by wGlobalCounter) becomes a colour coin.
## Frames 0-7 are the coin's turn, 8-15 the colour coin's; OBJ_FRAMESET_PTR's two bytes count the
## frames' duration and the frames left in the turn instead of pointing at a frameset.
func coin_func() -> void:
	if ((wGlobalCounter - 1) & 0b111111) == 0:
		set_cur(OBJ_INTERACTION_TYPE, (cur(OBJ_INTERACTION_TYPE) & HEAVY_OBJ) | OBJ_INTERACTION_COLOUR_COIN)
		coin_func_colour_coin()
		return
	_coin_start(0)


## CoinFunc.ColourCoin (the colour-coin blocks' coin starts here).
func coin_func_colour_coin() -> void:
	_coin_start(8)


func _coin_start(frame: int) -> void:
	set_cur(OBJ_FRAME, frame)
	set_cur_word(OBJ_UPDATE_FUNCTION, COIN_FUNC_UPDATE & 0xFFFF)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	coin_update()


## CoinFunc.Update: in water or sand (OBJ_FRAMESET_OFFSET) only on even frames. The turn slows as
## OBJ_VAR_1 counts up to 150; then the state.
func coin_update() -> void:
	set_cur(OBJ_FRAME_DURATION, 2)
	if cur(OBJ_FRAMESET_OFFSET) != 0 and (wGlobalCounter & 1) != 0:
		return
	var speed: int = 4
	var count: int = cur(OBJ_VAR_1)
	if count < 150:
		count += 1
		set_cur(OBJ_VAR_1, count)
		speed = 3 if count >= 100 else 2 if count >= 50 else 1
	set_cur(OBJ_FRAMESET_PTR, cur(OBJ_FRAMESET_PTR) - 1)
	if cur(OBJ_FRAMESET_PTR) == 0:
		set_cur(OBJ_FRAMESET_PTR, speed)
		set_cur(OBJ_FRAMESET_PTR + 1, cur(OBJ_FRAMESET_PTR + 1) - 1)
		if cur(OBJ_FRAMESET_PTR + 1) != 0:
			set_cur(OBJ_FRAME, cur(OBJ_FRAME) + 1)
		else:
			set_cur(OBJ_FRAMESET_PTR + 1, 8)
			set_cur(OBJ_FRAME, cur(OBJ_FRAME) - 7)
	match cur(OBJ_STATE):
		0x00: _coin_move_start(0x02, 4)
		0x01: _coin_move_start(0x03, 4)
		0x02: _coin_move(DATA_602C0, true)
		0x03: _coin_move(DATA_602C0, false)
		0x04: _coin_move_start(0x06, 5)
		0x05: _coin_move_start(0x07, 5)
		0x06: _coin_move(DATA_602E0, true)
		0x07: _coin_move(DATA_602E0, false)
		0x08: _coin_move_start(0x0A, 6)
		0x09: _coin_move_start(0x0B, 6)
		0x0A: _coin_move(DATA_60300, true)
		0x0B: _coin_move(DATA_60300, false)
		0x0C:
			_coin_restart(0x0E)
			_coin_fall(true)
		0x0D:
			_coin_restart(0x0F)
			_coin_fall(false)
		0x0E: _coin_fall(true)
		0x0F: _coin_fall(false)
		0x10: _coin_slide(true)
		0x11: _coin_slide(false)
		0x12, 0x16:
			set_cur(OBJ_STATE, cur(OBJ_STATE) + 1)
			set_cur(OBJ_STATE_DURATION, 100 if cur(OBJ_FRAMESET_OFFSET) == 0 else 50)
		0x13: _coin_rest()
		0x14:
			_coin_restart(0x15)
			_coin_drop()
		0x15: _coin_drop()
		0x17: _coin_blink()
		0x18:
			set_cur(OBJ_FLAGS, 0)
		0x19:  # .Init
			set_cur(OBJ_ACTION, 15 | (1 << NO_ACTIONS_F))
			set_cur(OBJ_STATE, 0x1A)
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
		0x1A:  # .StartMovement: away from Wario
			var wario: int = byte(wWarioScreenXPos + 0x2A)
			set_cur(OBJ_STATE, 0x06 if byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < wario else 0x07)
		_:
			note_unported("CoinFunc state %02x" % cur(OBJ_STATE))


## A state that starts a table: OBJ_STATE, OBJ_VAR_3 from the table's start.
func _coin_restart(state: int) -> void:
	set_cur(OBJ_STATE, state)
	set_cur(OBJ_VAR_3, 0)


## move_coin's start: the bounce `state` for `duration` frames.
func _coin_move_start(state: int, duration: int) -> void:
	_coin_restart(state)
	set_cur(OBJ_STATE_DURATION, duration)
	_coin_move(DATA_602C0 if state <= 0x03 else DATA_602E0 if state <= 0x07 else DATA_60300, (state & 1) == 0)


## move_coin and its tail: a bounce along `table`, OBJ_VAR_2 pixels a frame; a wall ahead (UNK4)
## turns it into a fall the other way, and the bounce's end into a fall this way.
func _coin_move(table: int, left: bool) -> void:
	add_y_signed(table_step(table, 0))
	if left:
		move_object_left_by_var2()
	else:
		move_object_right_by_var2()
	set_hpos_from_object(-8, -4 if left else 3)
	if (object_probe(COLLISION_UNK4) & 0x0F) != 0:
		set_cur(OBJ_STATE, 0x0D if left else 0x0C)
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_STATE, 0x0C if left else 0x0D)


## .FallLeft and .FallRight: gravity (FallingYVel_Light); on the floor (UNK1) the next bounce by
## the fall's speed (hffa0), OBJ_VAR_2 slowing; in the air, a wall ahead turns the fall.
func _coin_fall(left: bool) -> void:
	if left:
		move_object_left_by_var2()
	else:
		move_object_right_by_var2()
	add_y_signed(table_step(FALLING_Y_VEL_LIGHT, 0))
	set_hpos_from_object()
	if object_probe(COLLISION_UNK1) != 0:
		store_object_y_from_hpos()
		if cur(OBJ_VAR_2) != 0:
			set_cur(OBJ_VAR_2, cur(OBJ_VAR_2) - 1)
		var bounce: int = 0x08
		if hffa0 < 2:
			bounce = 0x10
		elif hffa0 < 3:
			bounce = 0x00
		elif hffa0 < 4:
			bounce = 0x04
		set_cur(OBJ_STATE, bounce if left else bounce + 1)
		return
	if wIsInWaterOrSand != 0:
		set_cur(OBJ_FRAMESET_OFFSET, wIsInWaterOrSand)
	set_hpos_from_object(-4, -4 if left else 3)
	if (object_probe(COLLISION_UNK4) & 0x0F) != 0:
		set_cur(OBJ_STATE, 0x0D if left else 0x0C)


## .State10 and .State11: sliding on the floor, OBJ_VAR_2 dropping every 32 frames until it stops
## (OBJSTATE $12); a wall ahead turns it, a slope (DOWN $10) carries it, and no floor under either
## edge (UNK2) makes it fall.
func _coin_slide(left: bool) -> void:
	if cur(OBJ_VAR_2) == 0:
		set_cur(OBJ_STATE, 0x12)
		return
	if (wGlobalCounter & 0b11111) == 0:
		set_cur(OBJ_VAR_2, cur(OBJ_VAR_2) - 1)
	set_hpos_from_object(-4, -4 if left else 3)
	if (object_probe(COLLISION_UNK4) & 0x0F) != 0:
		set_cur(OBJ_STATE, 0x11 if left else 0x10)
		return
	if left:
		move_object_left_by_var2()
	else:
		move_object_right_by_var2()
	set_hpos_from_object()
	var down: int = object_probe(COLLISION_DOWN)
	store_object_y_from_hpos()
	if down == 0x10:
		return
	hXPos = word(cur_x() + (-4 if left else 3))
	if object_probe(COLLISION_UNK2) != 0:
		return
	hXPos = word(cur_x() + (3 if left else -4))
	if object_probe(COLLISION_UNK2) != 0:
		return
	set_cur(OBJ_STATE, 0x0C if left else 0x0D)


## .State13: resting for OBJ_STATE_DURATION; with no floor (DOWN) it drops (OBJSTATE $14).
func _coin_rest() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_STATE, 0x16)
		return
	set_hpos_from_object()
	if object_probe(COLLISION_DOWN) != 0:
		return
	set_cur(OBJ_STATE, 0x14)


## .State15: dropping (the table at $4040) until the floor (UNK1), then resting again.
func _coin_drop() -> void:
	add_y_signed(table_step(DATA_60040, 0))
	set_hpos_from_object()
	if object_probe(COLLISION_UNK1) != 0:
		store_object_y_from_hpos()
		set_cur(OBJ_STATE, 0x12)
	if wIsInWaterOrSand != 0:
		set_cur(OBJ_FRAMESET_OFFSET, wIsInWaterOrSand)


## .State17: blinking for OBJ_STATE_DURATION (hidden one frame in four), then gone.
func _coin_blink() -> void:
	var duration: int = cur(OBJ_STATE_DURATION)
	if duration == 0:
		set_cur(OBJ_FLAGS, 0)
		return
	duration -= 1
	set_cur(OBJ_STATE_DURATION, duration)
	if (duration & 0b11) == 0:
		set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_ON_SCREEN) | OBJFLAG_INVISIBLE)
	else:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)


# --- Torches (objects/torch.asm) ----------------------------------------------------------

## TorchFunc: a burning torch that drops embers (OBJ_STATE_DURATION counts which comes next).
func torch_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, TORCH_FUNC_UPDATE & 0xFFFF)
	_torch_start()


## TorchNoEmbersFunc: the same torch, without embers.
func torch_no_embers_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, TORCH_NO_EMBERS_FUNC_UPDATE & 0xFFFF)
	_torch_start()


## TorchNoEmbersFunc.Update
func torch_no_embers_update() -> void:
	pass


func _torch_start() -> void:
	set_object_frameset_ptr(FRAMESET_68360)
	set_cur(OBJ_STATE_DURATION, 0)
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur(OBJ_COLLBOX_RIGHT, 6)
	set_cur(OBJ_COLLBOX_LEFT, -7)
	set_cur(OBJ_COLLBOX_BOTTOM, -3)


## TorchFunc.Update: every 128 frames a pair of embers, the first left and then (the next frame)
## right, alternating fast and slow pairs.
func torch_update() -> void:
	var next: int = 0
	var params: int = OBJ_PARAMS_TORCH_EMBER_RIGHT_2
	match cur(OBJ_STATE_DURATION):
		0:
			if (wGlobalCounter & 0b1111111) != 0:
				return
			next = 1
			params = OBJ_PARAMS_TORCH_EMBER_LEFT_1
		1:
			next = 2
			params = OBJ_PARAMS_TORCH_EMBER_RIGHT_1
		2:
			if (wGlobalCounter & 0b1111111) != 0:
				return
			next = 3
			params = OBJ_PARAMS_TORCH_EMBER_LEFT_2
	set_cur(OBJ_STATE_DURATION, next)
	create_object_from_cur_obj_pos(params)


func torch_ember_left_1() -> void:
	_torch_ember(-1, false)


func torch_ember_right_1() -> void:
	_torch_ember(1, false)


func torch_ember_left_2() -> void:
	_torch_ember(-1, true)


func torch_ember_right_2() -> void:
	_torch_ember(1, true)


## TorchEmberLeft1Func to TorchEmberRight2Func and TorchEmberCommonFunc: an ember drifts sideways
## (a pixel a frame, or every other frame when `slow`) and falls along Data_60320; it burns out
## where it lands (UNK1) or when an action set its state.
func _torch_ember(dx: int, slow: bool) -> void:
	if not slow:
		move_object_x(dx)
	elif dx < 0:
		move_object_left_slow()
	else:
		move_object_right_slow()
	apply_obj_y_movement(DATA_60320)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	if cur(OBJ_STATE) == 0:
		set_hpos_from_object()
		if object_probe(COLLISION_UNK1) == 0:
			return
		store_object_y_from_hpos()
	set_cur_word(OBJ_UPDATE_FUNCTION, TORCH_EMBER_COMMON_FUNC_DESTROY & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_68359)
	set_cur(OBJ_STATE_DURATION, 24)


## TorchEmberCommonFunc.Destroy: 24 frames burning out, then gone.
func _torch_ember_destroy() -> void:
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_FLAGS, 0)


# --- Chests and treasures (objects/chests.asm) ---------------------------------------------

func grey_chest_func() -> void:
	_chest_func(0)


func red_chest_func() -> void:
	_chest_func(1)


func green_chest_func() -> void:
	_chest_func(2)


func blue_chest_func() -> void:
	_chest_func(3)


## GreyChestFunc to BlueChestFunc: a chest whose treasure was taken is gone (DeinitChest);
## otherwise ChestFunc: shut, without collision, waiting.
func _chest_func(colour: int) -> void:
	if (wKeyAndTreasureFlags & (GREY_TREASURE << colour)) != 0:
		set_cur(OBJ_FLAGS, 0)
		return
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, CHEST_FUNC_UPDATE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED) | OBJSUBFLAG_UNK_4)
	set_object_frameset_ptr(FRAMESET_68000)
	set_cur(OBJ_COLLBOX_RIGHT, 13)
	set_cur(OBJ_COLLBOX_LEFT, -14)


## ChestFunc.Update: opened with the right key (OBJSTATE_18), once Wario stops moving by himself.
func chest_update() -> void:
	if cur(OBJ_STATE) != OBJSTATE_18 or wAutoMoveState != 0:
		return
	set_object_frameset_ptr(FRAMESET_68003)
	set_cur(OBJ_STATE_DURATION, 86)
	set_cur_word(OBJ_UPDATE_FUNCTION, CHEST_FUNC_OPEN & 0xFFFF)


## ChestFunc.Ret
func chest_ret() -> void:
	pass


## ChestFunc.Open: 86 frames opening, then open, and the treasure of its colour rises out of it.
func chest_open() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_object_frameset_ptr(FRAMESET_68060)
	set_cur_word(OBJ_UPDATE_FUNCTION, CHEST_FUNC_RET & 0xFFFF)
	# Grey, red, or green by the chest's interaction type; anything else is blue.
	var colour: int = (cur(OBJ_INTERACTION_TYPE) & INTERACTION_MASK) - OBJ_INTERACTION_GREY_TREASURE
	if colour < 0 or colour > 2:
		colour = 3
	create_object_at_relative_pos(OBJ_PARAMS_GREY_TREASURE + 0x15 * colour)


func grey_treasure_func() -> void:
	_treasure_func(0)


func red_treasure_func() -> void:
	_treasure_func(1)


func green_treasure_func() -> void:
	_treasure_func(2)


func blue_treasure_func() -> void:
	_treasure_func(3)


## TreasureFunc: after OBJ_STATE_DURATION (from its params), the treasure's own frameset.
func _treasure_func(colour: int) -> void:
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	if cur(OBJ_STATE_DURATION) == 0:
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_object_frameset_ptr(FRAMESET_681BE + 5 * colour)


# --- Keys (objects/key.asm) ----------------------------------------------------------------

## KeyFunc: as the musical coin, with its own frameset and box; KeyFunc.Update is the coin's own
## code (wait for OBJSTATE_18, then clear the slot and the map cell).
func key_func() -> void:
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, KEY_FUNC_UPDATE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_object_frameset_ptr(FRAMESET_6804F)
	set_cur(OBJ_COLLBOX_RIGHT, 4)
	set_cur(OBJ_COLLBOX_LEFT, -5)
	set_cur(OBJ_COLLBOX_BOTTOM, -4)


# --- Stars (objects/stars.asm) ------------------------------------------------------------

## StarsFunc: what a vanished object becomes; it clears itself after OBJ_STATE_DURATION.
func stars_func() -> void:
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_FLAGS, 0)


## StarsFunc_SetFlags: stars created from params become StarsFunc, without collision.
func stars_func_set_flags() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, STARS_FUNC & 0xFFFF)
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED) | OBJFLAG_NO_COLLISION)
	stars_func()


## StarsFunc_WithYOffset (ObjParams_StarsAbove): moved to Wario, 4 px lower, then as
## StarsFunc_SetFlags.
func stars_func_with_y_offset() -> void:
	set_cur_word(OBJ_Y_POS, wWarioYPos + 4)
	set_cur_word(OBJ_X_POS, wWarioXPos)
	stars_func_set_flags()


# --- Silky (objects/silky.asm) -------------------------------------------------------------

## SilkyFunc: .Init on the next update.
func silky_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, SILKY_FUNC_INIT & 0xFFFF)


## SilkyFunc.Init: visible, then .Default.
func silky_init() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, SILKY_FUNC_UPDATE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	_silky_default()


## SilkyFunc.Update's table, by OBJ_STATE. Shared states go to the ported routines the home bank's
## entries jump to; Silky's own are below. Paths into unported code are named.
func silky_update() -> void:
	var state: int = cur(OBJ_STATE)
	match state:
		0x00, 0x0D, 0x0E, 0x1D, 0x1E, 0x1F, 0x2A, 0x2B, 0x2C, 0x2E, 0x2F, 0x3A, 0x3D, 0x3E, 0x5A, 0x5B, 0x5C, 0x5D:
			_silky_default()
		0x01:
			_silky_walk_start()
		0x02, 0x08:
			_silky_wobble_start(0x38)
		0x03, 0x09:
			_silky_wobble_start(0x39)
		0x04:
			_silky_knocked_start(0x34)
		0x05:
			_silky_knocked_start(0x35)
		0x28:
			_silky_knocked_start(0x58)
		0x29:
			_silky_knocked_start(0x59)
		0x0B:
			enemy_stun_start(0x3B)
		0x0C:
			enemy_stun_start(0x3C)
		0x0F:
			_silky_lie_start()
		0x10:
			_silky_get_up_start()
		0x11:
			_silky_fall_start()
		0x12:
			enemy_12()
		0x13:
			_silky_turn_start()
		0x14:
			_silky_tumble_start(0x44)
		0x15:
			_silky_tumble_start(0x45)
		0x16:
			_silky_slide_start(0x46)
			enemy_slide(true)
		0x17:
			_silky_slide_start(0x47)
			enemy_slide(false)
		0x06, 0x07:
			enemy_picked_up_start(state == 0x06)
		0x18, 0x19, 0x48, 0x49:
			enemy_held(state, FRAMESET_6877A, FRAMESET_68783)
		0x4C, 0x4D:
			enemy_full_throw_start(state == 0x4C, FRAMESET_6879E, FRAMESET_687A7)
		0x2D:
			_silky_wait()
		0x31:
			_silky_walk()
		0x3B:
			enemy_stunned(true)
		0x3C:
			enemy_stunned(false)
		0x3F:
			enemy_lie()
		0x40:
			enemy_get_up()
		0x43:
			_silky_turn()
		0x46:
			enemy_slide(true)
		0x47:
			enemy_slide(false)
		_:
			if not common_enemy_state(state):
				note_unported("SilkyFunc state %02x" % state)


## The standard enemies' state table (Silky's, Para-Goom's, and others' share its layout): the
## entries the home bank's trampolines fill, by state, run the shared routines they jump to. False
## for an enemy's own states; entries into shared code not ported are named.
func common_enemy_state(state: int) -> bool:
	match state:
		0x0A:
			vanish_object()  # VanishObject2
		0x1A:
			func_6303f()  # Func_3263
		0x1B:
			func_63050()  # Func_3272
		0x1C:
			func_6305f()  # Func_3281
		0x20:
			func_62e8f()  # Func_3191
		0x21:
			func_62f76()  # Func_31af
		0x22:
			func_62eaa()  # Func_31cd
		0x23:
			func_62f91()  # Func_31eb
		0x24:
			func_62e74()  # Func_3209
		0x25:
			func_62f5b()  # Func_3227
		0x26:
			func_62c9f()  # Func_3245
		0x27:
			func_62d7d()  # Func_3254
		0x30:
			obj_state_fall()
		0x32:
			obj_state_bump_left()
		0x33:
			obj_state_bump_right()
		0x34:
			func_62840()  # Func_3326
		0x35:
			func_62898()  # Func_3317
		0x36, 0x37:
			picked_up(state == 0x36)  # Func_3335, Func_3344: Func_61f54, Func_620a6
		0x38, 0x53:
			func_62faa(DATA_602E0)  # Func_31fa: Func_62fa7
		0x39, 0x52:
			func_62ec3(DATA_602E0)  # Func_31dc: Func_62ec0
		0x41:
			obj_state_standing_fall()
		0x42:
			func_62926()  # Func_3371
		0x44, 0x56:
			func_62ca8()  # Func_32cc
		0x45, 0x57:
			func_62d86()  # Func_32db
		0x4A, 0x4B:
			charge_held(state == 0x4B)  # Func_3380, Func_338f: Func_62382, Func_6247b
		0x4E, 0x4F:
			thrown_flight(state == 0x4E)  # Func_339e, Func_33ad: Func_62574, Func_62605
		0x50:
			func_62ec3(DATA_602C0)  # Func_31a0: Func_62ea5
		0x51:
			func_62faa(DATA_602C0)  # Func_31be: Func_62f8c
		0x54:
			func_62ec3(DATA_60300)  # Func_3218: Func_62e8a
		0x55:
			func_62faa(DATA_60300)  # Func_3236: Func_62f71
		0x58:
			func_62892()  # Func_33f8
		0x59:
			func_6283a()  # Func_3407
		0x5E, 0x5F:
			full_throw_flight(state == 0x5E)  # ObjState_FullThrowLeft, _Right
		_:
			return false
	return true


## The standard enemies' picked-up start (OBJSTATE_PICKED_UP_LEFT_START, _RIGHT_START): the rise's
## table (Data_601c0 or Data_601e0) from its first entry, then Func_61f54 or Func_620a6.
func enemy_picked_up_start(left: bool) -> void:
	set_cur(OBJ_STATE, OBJSTATE_PICKED_UP_LEFT if left else OBJSTATE_PICKED_UP_RIGHT)
	var table: int = DATA_601C0 if left else DATA_601E0
	set_cur(OBJ_VAR_3, table >> 8)
	set_cur(OBJ_VAR_2, table & 0xFF)
	set_cur(OBJ_VAR_1, 1)
	picked_up(left)


## OBJSTATE_18 and _19: grabbed (`grab` given OBJSTATE_48 or _49 sets it with the object's frameset
## and box, grabbed); OBJSTATE_48 and _49: held by Func_622bd with Wario facing left, by Func_621fb
## facing right, HDIR flipped and the other state grabbed when he faces the other way.
func held_turning(state: int, grab: Callable) -> void:
	var left: bool = state == 0x18 or state == 0x48
	if state == 0x18 or state == 0x19:
		grab.call(OBJSTATE_48 if left else OBJSTATE_49)
	if (wDirection == DIRECTION_LEFT) != left:
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) ^ OBJSUBFLAG_HDIR)
		left = not left
		grab.call(OBJSTATE_48 if left else OBJSTATE_49)
	held(not left)


## held_turning with one frameset (none for -1) and the box kept: Barrel 2's, the Rock's, Count
## Richtertoffen's, Brrr Bear's, Hebarii's.
func carried_object_held(state: int, frameset: int) -> void:
	held_turning(state, grab_held.bind(frameset, frameset, []))


## held_turning with the frameset by HDIR and the box's sides (`box`: left, right; empty, kept): the
## standard enemies' (-6 and 5).
func enemy_held(state: int, frameset: int, frameset_hdir: int, box: Array = [-6, 5]) -> void:
	held_turning(state, grab_held.bind(frameset, frameset_hdir, box))


func grab_held(state: int, frameset: int, frameset_hdir: int, box: Array) -> void:
	set_cur(OBJ_STATE, state)
	if frameset != -1:
		set_object_frameset_ptr(frameset_hdir if hdir() else frameset)
	if not box.is_empty():
		set_collbox_x(box[0], box[1])
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_GRABBED)


## OBJSTATE_FULL_THROW_LEFT_START and _RIGHT_START: the full throw's state and frameset (by HDIR),
## then its flight.
func enemy_full_throw_start(left: bool, frameset: int, frameset_hdir: int) -> void:
	set_cur(OBJ_STATE, OBJSTATE_FULL_THROW_LEFT if left else OBJSTATE_FULL_THROW_RIGHT)
	set_object_frameset_ptr(frameset_hdir if hdir() else frameset)
	full_throw_flight(left)


## Func_6303f (OBJSTATE_1A): shaken by the ground: a pause ($1b, 7 frames).
func func_6303f() -> void:
	set_cur(OBJ_STATE, 0x1B)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_STATE_DURATION, 7)


## Func_63050 (OBJSTATE_1B): meanwhile Func_629a6; then falling standing ($11).
func func_63050() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		func_629a6()
		return
	set_cur(OBJ_STATE, OBJSTATE_STANDING_FALL_START)


## Func_6305f (OBJSTATE_1C, a lying enemy shaken): a wobble one way or the other by bit 0 of rDIV.
func func_6305f() -> void:
	set_cur(OBJ_STATE, OBJSTATE_WOBBLE_LEFT if (read_div(DIV_FUNC_6305F) & 1) != 0 else OBJSTATE_WOBBLE_RIGHT)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_2, 1)
	set_cur(OBJ_STATE_DURATION, 4)


## .Default: harmless (OBJ_INTERACTION_01), falling, facing Wario.
func _silky_default() -> void:
	set_interaction(OBJ_INTERACTION_01)
	set_cur(OBJ_STATE, OBJSTATE_FALL)
	var right: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
	set_hdir(right)
	set_cur(OBJ_VAR_3, 0)
	set_object_frameset_ptr(FRAMESET_6874D if right else FRAMESET_68744)
	if right:
		set_collbox_x(-7, 7)
	else:
		set_collbox_x(-8, 6)


func set_hdir(right: bool) -> void:
	if right:
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) | OBJSUBFLAG_HDIR)
	else:
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_HDIR)


## .Func_42eca: walking (OBJSTATE $31) the way it faces.
func _silky_walk_start() -> void:
	set_interaction(OBJ_INTERACTION_01)
	set_cur(OBJ_STATE, 0x31)
	if hdir():
		set_collbox_x(-7, 7)
		set_object_frameset_ptr(FRAMESET_6874D)
	else:
		set_collbox_x(-8, 6)
		set_object_frameset_ptr(FRAMESET_68744)


## .Func_42e7b: falling standing (OBJSTATE $41).
func _silky_fall_start() -> void:
	set_cur(OBJ_STATE, 0x41)
	set_cur(OBJ_VAR_3, 0)
	set_object_frameset_ptr(FRAMESET_6874D if hdir() else FRAMESET_68744)


## The ground shake: a wobble one way or the other by bit 0 of rDIV (read at `site`). The
## standard enemies each have this code (Silky's, Para-Goom's).
func ground_shake_wobble(site: int) -> bool:
	if wGroundShakeCounter < 0x10:
		return false
	set_cur(OBJ_STATE, OBJSTATE_WOBBLE_LEFT_START | (read_div(site) & 1))
	return true


## .Func_42e95 (OBJSTATE $2d): the wind-up before the string; when it runs out Silky is dangerous
## (OBJ_INTERACTION_SILKY) and spits; with no wind-up left it walks on (.asm_42f44).
func _silky_wait() -> void:
	if cur(OBJ_STATE_DURATION) == 0:
		_silky_step()
		return
	if ground_shake_wobble(DIV_SILKY_WAIT):
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_interaction(OBJ_INTERACTION_SILKY)
	set_object_frameset_ptr(FRAMESET_6875F if hdir() else FRAMESET_68756)


## .Func_42ef8 (OBJSTATE $31): with Wario level with it (within 15 rows) and ahead, the wind-up
## ($23 frames, OBJSTATE $2d); behind it, a turn ($13). Otherwise (or with Wario already a ball of
## string) it walks on.
func _silky_walk() -> void:
	if wTransformation != TRANSFORMATION_BALL_O_STRING_WARIO:
		var dy: int = byte(byte(cur(OBJ_SCREEN_Y_POS) + 0x2A) - byte(wWarioScreenYPos + 0x2A))
		if dy < 0x0F or dy >= 0xF1:
			var left_of_wario: bool = byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A)
			if left_of_wario != hdir():
				set_cur(OBJ_STATE, 0x13)
				return
			set_object_frameset_ptr(FRAMESET_687BB if left_of_wario else FRAMESET_687B0)
			set_cur(OBJ_STATE_DURATION, 0x23)
			set_cur(OBJ_STATE, 0x2D)
			return
	_silky_step()


## .asm_42f44: a step half a pixel a frame along the floor; no floor under it makes it fall
## ($11); a wall ahead (UNK4) or the floor's end turns it ($13).
func _silky_step() -> void:
	if ground_shake_wobble(DIV_SILKY_WALK):
		return
	set_hpos_from_object()
	if object_probe(COLLISION_DOWN) == 0:
		set_cur(OBJ_STATE, 0x11)
		return
	store_object_y_from_hpos()
	var fine_x: int = cur(OBJ_X_POS) & 0x0F
	if hdir():
		if fine_x + 7 >= 0x10 and (process_block_on_right() & 0x0F) == 0:
			set_cur(OBJ_STATE, 0x13)
			return
		set_hpos_from_object(-4, 7)
		if object_probe(COLLISION_UNK4) == 0:
			move_object_right_slow()
			return
	else:
		if fine_x < 8 and (process_block_on_left() & 0x0F) == 0:
			set_cur(OBJ_STATE, 0x13)
			return
		set_hpos_from_object(-4, -8)
		if object_probe(COLLISION_UNK4) == 0:
			move_object_left_slow()
			return
	set_cur(OBJ_STATE, 0x13)


## .Func_43126/.Func_43130 (and from OBJSTATE_08/09): a wobble ($38 left, $39 right).
func _silky_wobble_start(state: int) -> void:
	set_cur(OBJ_ACTION, 0x8F)
	set_cur(OBJ_STATE, state)
	set_object_frameset_ptr(FRAMESET_68795 if hdir() else FRAMESET_6878C)
	set_cur(OBJ_STATE_DURATION, 4)
	set_cur(OBJ_VAR_2, 2)
	set_cur(OBJ_VAR_3, 0)
	set_collbox_x(-6, 5)
	set_interaction(OBJ_INTERACTION_00)


## .Func_431a0 to .Func_431be: knocked away (`state`), OBJ_SUBSTATE's low nibble cleared.
func _silky_knocked_start(state: int) -> void:
	set_cur(OBJ_STATE, state)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & 0xF0)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_2, 2)
	set_object_frameset_ptr(FRAMESET_687C6)
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)


## .Func_43162/.Func_43169: stunned ($3b, $3c), the animation held (Para-Goom's .Func_41954 and
## .Func_4195b are the same code).
func enemy_stun_start(state: int) -> void:
	set_cur(OBJ_STATE, state)
	set_cur(OBJ_FRAME_DURATION, 0)
	set_cur(OBJ_FRAMESET_OFFSET, 0)
	set_cur(OBJ_VAR_2, 2)


## .Func_4317a/.Func_4318d: pushed while OBJ_VAR_2 lasts (Func_62bce, Func_62ae5), then a turn
## (Para-Goom's .Func_4196c and .Func_4197f are the same code).
func enemy_stunned(left: bool) -> void:
	set_cur(OBJ_FRAME_DURATION, 0)
	set_cur(OBJ_FRAMESET_OFFSET, 0)
	if cur(OBJ_VAR_2) == 0:
		set_cur(OBJ_STATE, 0x13)
	elif left:
		func_62bce()
	else:
		func_62ae5()


## .Func_43083 (OBJSTATE_0F): lying for 100 frames ($3f); a ground shake knocks it ($1c).
func _silky_lie_start() -> void:
	set_cur(OBJ_STATE, 0x3F)
	set_object_frameset_ptr(FRAMESET_68783 if hdir() else FRAMESET_6877A)
	set_cur(OBJ_STATE_DURATION, 0x64)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)
	enemy_lie()


## .Func_430a0 (Para-Goom's .Func_417b1 is the same code)
func enemy_lie() -> void:
	if wGroundShakeCounter >= 0x10:
		set_cur(OBJ_STATE, 0x1C)
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		func_628ea()
		return
	set_cur(OBJ_STATE, OBJSTATE_10)


## .Func_430ba (OBJSTATE_10): getting up for 7 frames ($40), then .Default.
func _silky_get_up_start() -> void:
	set_cur(OBJ_STATE, 0x40)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_STATE_DURATION, 7)
	enemy_get_up()


## .Func_430c8 (Spear Bot's .Func_463eb is the same code)
func enemy_get_up() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		func_629a6()
		return
	set_cur(OBJ_STATE, 0)


## .Func_43263 (OBJSTATE_12): no actions for 31 frames, Func_62926 ($42) (Spear Bot's .Func_465a0 is
## the same code).
func enemy_12() -> void:
	set_cur(OBJ_ACTION, 0x9F)
	set_cur(OBJ_STATE, 0x42)
	set_cur(OBJ_VAR_3, 0)
	set_interaction(OBJ_INTERACTION_00)


## .Func_430d5 (OBJSTATE $13): turning for $23 frames ($43).
func _silky_turn_start() -> void:
	set_cur(OBJ_STATE, 0x43)
	set_object_frameset_ptr(FRAMESET_68771 if hdir() else FRAMESET_68768)
	set_cur(OBJ_STATE_DURATION, 0x23)
	set_interaction(OBJ_INTERACTION_01)


## .Func_430f6: the turn (Func_62908 meanwhile: it falls if the floor goes), then walking the
## other way.
func _silky_turn() -> void:
	if ground_shake_wobble(DIV_SILKY_TURN):
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		func_62908()
		return
	set_cur(OBJ_STATE, 0x01)
	set_hdir(not hdir())


## .Func_4304b/.Func_43053: tumbling ($44, $45).
func _silky_tumble_start(state: int) -> void:
	set_cur(OBJ_STATE, state)
	set_object_frameset_ptr(FRAMESET_68783 if hdir() else FRAMESET_6877A)
	set_cur(OBJ_VAR_2, 2)
	set_cur(OBJ_VAR_3, 0)
	set_collbox_x(-6, 5)
	set_interaction(OBJ_INTERACTION_00)


## .Func_42fe5/.Func_43018: sliding ($46, $47).
func _silky_slide_start(state: int) -> void:
	set_cur(OBJ_STATE, state)
	set_object_frameset_ptr(FRAMESET_68783 if hdir() else FRAMESET_6877A)
	set_collbox_x(-6, 5)
	set_interaction(OBJ_INTERACTION_00)


## .Func_4300a/.Func_4303d: pushed while OBJ_VAR_2 lasts (Func_62ae5, Func_62bce), then lying
## (Para-Goom's .Func_41723 and .Func_41759 are the same code).
func enemy_slide(first: bool) -> void:
	if cur(OBJ_VAR_2) == 0:
		set_cur(OBJ_STATE, OBJSTATE_0F)
	elif first:
		func_62ae5()
	else:
		func_62bce()


# --- Birds (objects/bird.asm) -------------------------------------------------------------

## BirdFunc: .Init on the next update.
func bird_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, BIRD_FUNC_INIT & 0xFFFF)


## BirdFunc.Init: visible, facing Wario.
func bird_init() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, BIRD_FUNC_UPDATE & 0xFFFF)
	set_cur(OBJ_COLLBOX_RIGHT, 6)
	set_cur(OBJ_COLLBOX_LEFT, -7)
	set_cur(OBJ_COLLBOX_BOTTOM, -6)
	set_cur(OBJ_STATE_DURATION, 0)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	_bird_face(byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A))


## OBJSUBFLAG_HDIR and the frameset facing right (set) or left.
func _bird_face(right: bool) -> void:
	if right:
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) | OBJSUBFLAG_HDIR)
		set_object_frameset_ptr(FRAMESET_687E4)
	else:
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_HDIR)
		set_object_frameset_ptr(FRAMESET_687D3)


## BirdFunc.Update: by OBJ_STATE, which actions set (a hit makes stars, an attack knocks it away).
func bird_update() -> void:
	var state: int = cur(OBJ_STATE)
	match state:
		0x00:
			_bird_watch()
		0x2F:
			_bird_take_off()
		0x0B:
			_bird_hit(OBJ_PARAMS_BIRD_STARS_1)
		0x0C:
			_bird_hit(OBJ_PARAMS_BIRD_STARS_2)
		0x0A:
			func_62e57()
		0x28:
			_bird_knocked(FUNC_33F8)
		0x29:
			_bird_knocked(FUNC_3407)
		0x04:
			_bird_knocked(FUNC_3326)
		0x05:
			_bird_knocked(FUNC_3317)
		_:
			_bird_knocked(FUNC_3407 if (state & 1) == 0 else FUNC_33F8)


## .Func_432c2: on screen, it turns round when OBJ_STATE_DURATION runs out; with Wario within $18
## rows, ahead of it and near enough ($70 ahead to the right, $90 to the left), it takes off
## towards him (OBJSTATE $2f, after $23 frames); behind it, it turns ($0c frames).
func _bird_watch() -> void:
	if (cur(OBJ_FLAGS) & OBJFLAG_ON_SCREEN) == 0:
		return
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) != 0:
			return
		_bird_face(not hdir())
	var dy: int = byte(byte(cur(OBJ_SCREEN_Y_POS) + 0x2A) - byte(wWarioScreenYPos + 0x2A))
	if dy >= 0x18 and dy < 0xE8:
		return
	var object_x: int = byte(cur(OBJ_SCREEN_X_POS) + 0x2A)
	var wario_x: int = byte(wWarioScreenXPos + 0x2A)
	var dx: int = byte(object_x - wario_x)
	if object_x < wario_x:
		if not hdir():
			_bird_turn()
			return
		if dx < 0x90:
			return
		set_object_frameset_ptr(FRAMESET_687CE)
	else:
		if hdir():
			_bird_turn()
			return
		if dx >= 0x70:
			return
		set_object_frameset_ptr(FRAMESET_687C9)
	set_cur(OBJ_STATE_DURATION, 0x23)
	set_cur(OBJ_STATE, 0x2F)


func _bird_turn() -> void:
	set_object_frameset_ptr(FRAMESET_687FF)
	set_cur(OBJ_STATE_DURATION, 0x0C)


## .Func_43342: the wind-up, then flying 2 px a frame the way it faces.
func _bird_take_off() -> void:
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		return
	_bird_fly()


## .asm_43358
func _bird_fly() -> void:
	move_object_x(2 if hdir() else -2)


## .Func_43353: flying off, ignoring actions.
func bird_fly_off() -> void:
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	_bird_fly()


## .asm_4338f/.asm_43394: hit (OBJSTATE_0B or 0C): the first time stars appear and the bird flies
## off (the blue bird stops, stunned, for $14 frames); hit again, it is knocked away.
func _bird_hit(stars: int) -> void:
	set_cur(OBJ_STATE, 0)
	if (cur(OBJ_FLAGS) & OBJFLAG_NO_COLLISION) != 0:
		_bird_knocked(FUNC_33F8 if hdir() else FUNC_3407)
		return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	if cur(OBJ_ID) == BLUE_BIRD:
		set_cur_word(OBJ_UPDATE_FUNCTION, BIRD_FUNC_STUNNED & 0xFFFF)
		set_cur(OBJ_STATE_DURATION, 0x14)
		return
	set_cur_word(OBJ_UPDATE_FUNCTION, BIRD_FUNC_FLY_OFF & 0xFFFF)
	create_object_at_relative_pos(stars)


## .asm_433e8: knocked away by a home-bank update function at 2 px a frame.
func _bird_knocked(function: int) -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	set_cur_word(OBJ_UPDATE_FUNCTION, function)
	set_cur(OBJ_VAR_2, 2)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	set_object_frameset_ptr(FRAMESET_687FA if hdir() else FRAMESET_687F5)


## .Func_4340b: the blue bird stunned; then it turns, waiting ($0c frames).
func bird_stunned() -> void:
	set_cur(OBJ_ACTION, 0x81)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	_bird_turn()
	set_cur_word(OBJ_UPDATE_FUNCTION, BIRD_FUNC_RECOVER & 0xFFFF)


## .Func_43427: when that runs out it takes off the other way (OBJ_STATE 1 sends it to
## .Func_43342 from then on).
func bird_recover() -> void:
	set_cur(OBJ_ACTION, 0x81)
	if cur(OBJ_STATE) != 0:
		_bird_take_off()
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_STATE, 1)
	if hdir():
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_HDIR)
		set_object_frameset_ptr(FRAMESET_687C9)
	else:
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) | OBJSUBFLAG_HDIR)
		set_object_frameset_ptr(FRAMESET_687CE)


# --- Webber (objects/webber.asm) ----------------------------------------------------------

## WebberFunc: a spider on its thread. It fires a projectile (every 128 frames, 4 times), then hangs
## still; stood on, it sinks with Wario and climbs back to where it started (OBJ_VAR_1/2). The low
## nibble of OBJ_SUBSTATE is its routine.
func webber_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, WEBBER_FUNC_UPDATE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur(OBJ_COLLBOX_RIGHT, -2)
	set_cur(OBJ_COLLBOX_LEFT, -16)
	set_cur(OBJ_COLLBOX_BOTTOM, -4)
	set_cur(OBJ_VAR_1, cur(OBJ_Y_POS))
	set_cur(OBJ_VAR_2, cur(OBJ_Y_POS + 1))
	set_cur(OBJ_VAR_3, 4)
	_webber_set_routine(2, FRAMESET_682B7, 64)


## The routine in OBJ_SUBSTATE's low nibble, a frameset, and (when given) OBJ_STATE_DURATION.
func _webber_set_routine(routine: int, frameset: int, duration: int = -1) -> void:
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK) | routine)
	set_object_frameset_ptr(frameset)
	if duration >= 0:
		set_cur(OBJ_STATE_DURATION, duration)


func webber_update() -> void:
	var state: int = cur(OBJ_STATE)
	if state == OBJSTATE_ATTACKED_LEFT_START or state == OBJSTATE_ATTACKED_RIGHT_START:
		var left: bool = state == OBJSTATE_ATTACKED_LEFT_START
		set_cur_word(OBJ_UPDATE_FUNCTION, FUNC_3326 if left else FUNC_3317)
		set_object_frameset_ptr(FRAMESET_682C2 if left else FRAMESET_682C5)
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK)
		set_cur(OBJ_VAR_3, 0)
		set_cur(OBJ_VAR_2, 2)
		set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
		return
	if state == OBJSTATE_VANISH_TOUCH:
		set_cur(OBJ_STATE, 0)
		if hdir():
			vanish_object()
			return
		set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK) | 5)
		set_cur(OBJ_VAR_3, 0)
		set_object_frameset_ptr(FRAMESET_682A9)
		set_cur(OBJ_STATE_DURATION, 48)
		return
	if state != 0:
		# Any other state (a bump, a wobble): climb up the thread.
		set_cur(OBJ_STATE, 0)
		_webber_set_routine(6, FRAMESET_682D1, 50)
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_NO_COLLISION)
	match cur(OBJ_SUBSTATE) & 0x0F:
		0, 1:
			_webber_idle()
		2:
			_webber_fire_projectile()
		3:
			_webber_move_back_to_start()
		4:
			_webber_shake()
		5:
			_webber_smash_attacked()
		6:
			_webber_climb()
		7:
			if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) == 0:
				_webber_set_move_to_start_pos()
			else:
				set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
		8:
			_webber_special_idle()
		var routine:
			note_unported("WebberFunc routine %d" % routine)


func _webber_set_move_to_start_pos() -> void:
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & (OBJSUBFLAGS_MASK ^ OBJSUBFLAG_HDIR)) | 3)
	set_cur(OBJ_VAR_3, 5)
	set_object_frameset_ptr(FRAMESET_682B2)


func _webber_set_idle() -> void:
	_webber_set_routine(1, FRAMESET_682A4)


func _webber_set_shake() -> void:
	set_cur(OBJ_SUBSTATE, (cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK) | 4)
	set_cur(OBJ_VAR_3, 0)
	set_object_frameset_ptr(FRAMESET_682A9)
	set_cur(OBJ_STATE_DURATION, 48)


func _webber_shaken() -> bool:
	if wGroundShakeCounter >= 0x10:
		_webber_set_shake()
		return true
	return false


## .MoveBackToStartPosition: up or down a pixel a frame (half that, with Wario on it) to the start.
func _webber_move_back_to_start() -> void:
	if _webber_shaken():
		return
	var start: int = cur(OBJ_VAR_1) | (cur(OBJ_VAR_2) << 8)
	var y: int = cur_y()
	if y == start:
		_webber_set_idle()
		return
	var up: bool = y > start
	if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) != 0:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
		if (wGlobalCounter & 1) == 0:
			return
		if up:
			move_wario_up(1)
			handle_upwards_floor_transition()
		else:
			move_wario_down(1)
			handle_downwards_floor_transition()
	elif cur(OBJ_FRAME_DURATION) != 0:
		set_cur(OBJ_FRAME_DURATION, cur(OBJ_FRAME_DURATION) - 1)
	if up:
		move_object_up()
	else:
		move_object_down()


func _webber_shake() -> void:
	if cur(OBJ_VAR_3) != 15:
		apply_obj_y_movement(DATA_604A0)
		set_hpos_from_object()
		if object_probe(COLLISION_UNK1) == 0:
			return
		store_object_y_from_hpos()
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) | OBJSUBFLAG_HDIR)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_webber_set_move_to_start_pos()
	elif wGroundShakeCounter >= 0x11:
		_webber_set_shake()


func _webber_idle() -> void:
	if _webber_shaken():
		return
	if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) != 0:
		_webber_set_routine(7, FRAMESET_682D6)
		return
	if (wGlobalCounter & 0x7F) != 0:
		return
	set_cur(OBJ_VAR_3, cur(OBJ_VAR_3) - 1)
	if cur(OBJ_VAR_3) != 0:
		_webber_set_routine(2, FRAMESET_682B7, 64)
		return
	_webber_set_routine(8, FRAMESET_682E2, 162)


func _webber_smash_attacked() -> void:
	if _webber_shaken():
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_webber_set_move_to_start_pos()
		return
	if hdir():
		return
	var super_slam: bool = wram1[W_EFFECTIVE_POWER_UP] >= SUPER_JUMP_SLAM_OVERALLS
	apply_obj_y_movement(DATA_60490 if super_slam else DATA_603F0)
	set_hpos_from_object()
	if object_probe(COLLISION_UNK1) == 0:
		return
	if super_slam:
		vanish_object()
		return
	store_object_y_from_hpos()
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) | OBJSUBFLAG_HDIR)


func _webber_fire_projectile() -> void:
	if _webber_shaken():
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_webber_set_idle()
		return
	if cur(OBJ_STATE_DURATION) == 40:
		create_object_at_relative_pos(OBJ_PARAMS_WEBBER_PROJECTILE)


func _webber_climb() -> void:
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	if _webber_shaken():
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_webber_set_move_to_start_pos()
	elif cur(OBJ_STATE_DURATION) >= 20:
		move_object_up()


func _webber_special_idle() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_VAR_3, 5)
		_webber_set_idle()
		return
	if _webber_shaken():
		return
	if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) == 0:
		return
	_webber_set_routine(7, FRAMESET_682D6)


## WebberProjectileFunc: falls a pixel a frame, drifting half a pixel towards Wario, and bursts
## (.Destroy, 24 frames) on the ground or when anything changes its state.
func webber_projectile_func() -> void:
	if byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A):
		move_object_right_slow()
	else:
		move_object_left_slow()
	move_object_down()
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) | OBJFLAG_NO_COLLISION)
	if cur(OBJ_STATE) == 0:
		set_hpos_from_object()
		if object_probe(COLLISION_UNK1) == 0:
			return
		store_object_y_from_hpos()
	set_cur_word(OBJ_UPDATE_FUNCTION, WEBBER_PROJECTILE_FUNC_DESTROY & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_682DB)
	set_cur(OBJ_STATE_DURATION, 24)


func _webber_projectile_destroy() -> void:
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		set_cur(OBJ_FLAGS, 0)


# --- Futamogu (objects/futamogu.asm) ---------------------------------------------------------

## FutamoguFunc: a mole to stand on. It remembers where it started (OBJ_VAR_1/2); stood on, it
## climbs back there half a pixel a frame, carrying Wario; a smash pushes it into the ground.
func futamogu_func() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, FUTAMOGU_FUNC_UPDATE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_object_frameset_ptr(FRAMESET_68319)
	set_cur(OBJ_VAR_1, cur(OBJ_Y_POS))
	set_cur(OBJ_VAR_2, cur(OBJ_Y_POS + 1))
	set_cur(OBJ_COLLBOX_RIGHT, 5)
	set_cur(OBJ_COLLBOX_LEFT, -21)
	set_cur(OBJ_COLLBOX_BOTTOM, 4)


func futamogu_update() -> void:
	var state: int = cur(OBJ_STATE)
	if state == 0:
		_futamogu_idle()
	elif state == OBJSTATE_SPECIAL_3:
		_futamogu_climb()
	elif state == OBJSTATE_SPECIAL_2:
		if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) != 0:
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
		else:
			_futamogu_set_idle()
	elif state == OBJSTATE_ATTACKED_LEFT:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) == 0:
			_futamogu_set_idle()
	elif state == OBJSTATE_VANISH_TOUCH:
		if hdir():
			_futamogu_vanish()
			return
		set_cur(OBJ_STATE, OBJSTATE_3A)
		set_cur(OBJ_VAR_3, 0)
		set_object_frameset_ptr(FRAMESET_68348)
		set_cur(OBJ_STATE_DURATION, 48)
	elif state == OBJSTATE_3A:
		_futamogu_fall()
	elif (state & 0xFE) == OBJSTATE_ATTACKED_LEFT_START:
		set_cur(OBJ_STATE, OBJSTATE_ATTACKED_LEFT)
		set_object_frameset_ptr(FRAMESET_68351)
		set_cur(OBJ_STATE_DURATION, 16)
	else:
		_futamogu_set_idle()


func _futamogu_at_start() -> bool:
	return cur(OBJ_Y_POS) == cur(OBJ_VAR_1) and cur(OBJ_Y_POS + 1) == cur(OBJ_VAR_2)


func _futamogu_set_idle() -> void:
	set_object_frameset_ptr(FRAMESET_68319)
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_NO_COLLISION)
	set_cur(OBJ_STATE, 0)


func _futamogu_set_shake() -> void:
	set_cur(OBJ_STATE, OBJSTATE_ATTACKED_LEFT)
	set_object_frameset_ptr(FRAMESET_68348)
	set_cur(OBJ_STATE_DURATION, 32)


func _futamogu_idle() -> void:
	if wGroundShakeCounter >= 0x10:
		_futamogu_set_shake()
		return
	if not _futamogu_at_start():
		set_cur(OBJ_STATE, OBJSTATE_SPECIAL_3)
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_HDIR)
		set_object_frameset_ptr(FRAMESET_68336)
		return
	if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) == 0:
		return
	set_cur(OBJ_STATE, OBJSTATE_SPECIAL_2)
	set_object_frameset_ptr(FRAMESET_68343)


## .Climb: back up to the start, carrying a standing Wario up half a pixel a frame.
func _futamogu_climb() -> void:
	if wGroundShakeCounter >= 0x10:
		_futamogu_set_shake()
		return
	if _futamogu_at_start():
		_futamogu_set_idle()
		return
	if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) != 0:
		set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
		if (wGlobalCounter & 1) == 0:
			return
		move_wario_up(1)
		handle_upwards_floor_transition()
		move_object_up()
		return
	if cur(OBJ_FRAME_DURATION) != 0:
		set_cur(OBJ_FRAME_DURATION, cur(OBJ_FRAME_DURATION) - 1)
	move_object_up()


## .Fall: pushed into the ground (Data_603f0, or Data_60490 with the Super Jump Slam Overalls,
## which vanish it) for OBJ_STATE_DURATION frames, stopping at the ground.
func _futamogu_fall() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_futamogu_set_idle()
		return
	if hdir():
		return
	var super_slam: bool = wram1[W_EFFECTIVE_POWER_UP] >= SUPER_JUMP_SLAM_OVERALLS
	apply_obj_y_movement(DATA_60490 if super_slam else DATA_603F0)
	set_hpos_from_object()
	if object_probe(COLLISION_UNK1) == 0:
		return
	if super_slam:
		_futamogu_vanish()
		return
	store_object_y_from_hpos()
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) | OBJSUBFLAG_HDIR)


func _futamogu_vanish() -> void:
	set_cur(OBJ_VAR_2, 8)
	move_object_left_by_var2()
	vanish_object()


# --- Small leaf (objects/small_leaf.asm) ---------------------------------------------------

## SmallLeafFunc: a leaf to stand on. Stepped on, it sinks for 40 frames, disappears for $9b frames,
## comes back over 40 frames, and starts again; an attack or a bump makes it vanish (Func_3173).
func small_leaf_func() -> void:
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE) | OBJFLAG_NO_COLLISION)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	set_cur(OBJ_COLLBOX_RIGHT, 0x06)
	set_cur(OBJ_COLLBOX_LEFT, 0xF9)
	set_cur(OBJ_COLLBOX_BOTTOM, 0xF3)
	_small_leaf_init()


func _small_leaf_init() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, SMALL_LEAF_FUNC_UPDATE_1 & 0xFFFF)
	set_object_frameset_ptr(FRAMESET_68A9F)


func _small_leaf_update_4() -> void:
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_small_leaf_init()


## An attack (states $04/$05) or a vanish touch ($0a) makes the leaf vanish; any other state is reset.
func _small_leaf_hit() -> bool:
	var state: int = cur(OBJ_STATE)
	if state == OBJSTATE_VANISH_TOUCH or (state & 0xFE) == OBJSTATE_ATTACKED_LEFT_START:
		func_62e57()
		return true
	set_cur(OBJ_STATE, 0)
	return false


func _small_leaf_update_1() -> void:
	set_one_way_platform_action()
	if _small_leaf_hit():
		return
	if (cur(OBJ_FLAGS) & OBJFLAG_STEPPED) == 0:
		return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED)
	set_object_frameset_ptr(FRAMESET_68AA8)
	set_cur(OBJ_STATE_DURATION, 0x28)
	set_cur_word(OBJ_UPDATE_FUNCTION, SMALL_LEAF_FUNC_UPDATE_2 & 0xFFFF)


func _small_leaf_update_2() -> void:
	if _small_leaf_hit():
		return
	if cur(OBJ_STATE_DURATION) < 0x0F:
		set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_STATE_DURATION, 0x9B)
	set_cur(OBJ_FLAGS, (cur(OBJ_FLAGS) & ~OBJFLAG_STEPPED) | OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, SMALL_LEAF_FUNC_UPDATE_3 & 0xFFFF)


func _small_leaf_update_3() -> void:
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_object_frameset_ptr(FRAMESET_68ABB)
	set_cur(OBJ_STATE_DURATION, 0x28)
	set_cur_word(OBJ_UPDATE_FUNCTION, SMALL_LEAF_FUNC_UPDATE_4 & 0xFFFF)


# --- Spearhead (objects/spearhead.asm) -----------------------------------------------------

func spearhead_func() -> void:
	set_cur_word(OBJ_UPDATE_FUNCTION, SPEARHEAD_FUNC_INIT & 0xFFFF)
	set_cur(OBJ_VAR_1, 0)


func spearhead_init() -> void:
	set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_INVISIBLE)
	set_cur_word(OBJ_UPDATE_FUNCTION, SPEARHEAD_FUNC_UPDATE & 0xFFFF)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_UNINITIALISED)
	if (wDayNight & 1) != 0:
		_spearhead_sleep_start()  # night
		return
	_spearhead_default()


## SpearheadFunc.Update: the state's handler.
func spearhead_update() -> void:
	var state: int = cur(OBJ_STATE)
	match state:
		0x00, 0x0D, 0x0E, 0x1D, 0x1E, 0x1F, 0x2A, 0x2B, 0x2C, 0x3A, 0x3D, 0x3E, 0x5A, 0x5B, 0x5C, 0x5D:
			_spearhead_default()
		OBJSTATE_LAND:
			_spearhead_land()
		OBJSTATE_VANISH_TOUCH:
			vanish_object()
		OBJSTATE_BUMP_LEFT_START, OBJSTATE_BUMP_RIGHT_START:
			_spearhead_bump_start(state == OBJSTATE_BUMP_LEFT_START)
		OBJSTATE_ATTACKED_LEFT_START:
			_spearhead_attacked_start(OBJSTATE_ATTACKED_LEFT)
		OBJSTATE_ATTACKED_RIGHT_START:
			_spearhead_attacked_start(OBJSTATE_ATTACKED_RIGHT)
		0x28:
			_spearhead_attacked_start(OBJSTATE_58)
		0x29:
			_spearhead_attacked_start(OBJSTATE_59)
		OBJSTATE_WOBBLE_LEFT_START:
			_spearhead_wobble_start(OBJSTATE_WOBBLE_LEFT)
		OBJSTATE_WOBBLE_RIGHT_START:
			_spearhead_wobble_start(OBJSTATE_WOBBLE_RIGHT)
		OBJSTATE_0B:
			_spearhead_state_0b_0c(OBJSTATE_3B)
		OBJSTATE_0C:
			_spearhead_state_0b_0c(OBJSTATE_3C)
		OBJSTATE_0F:
			set_cur(OBJ_STATE, OBJSTATE_3F)
			set_cur(OBJ_STATE_DURATION, 100)
			set_cur(OBJ_FLAGS, cur(OBJ_FLAGS) & ~OBJFLAG_GRABBED)
			_spearhead_state_3f()
		OBJSTATE_10:
			set_cur(OBJ_STATE, OBJSTATE_40)
			set_cur(OBJ_VAR_3, 0)
			set_cur(OBJ_STATE_DURATION, 7)
			_spearhead_state_40()
		OBJSTATE_STANDING_FALL_START:
			set_cur(OBJ_STATE, OBJSTATE_STANDING_FALL)
			set_cur(OBJ_VAR_3, 0)
			set_object_frameset_ptr(FRAMESET_681DB if hdir() else FRAMESET_681D2)
		OBJSTATE_12:
			set_cur(OBJ_ACTION, 31 | (1 << 7))
			set_cur(OBJ_STATE, OBJSTATE_42)
			set_cur(OBJ_VAR_3, 0)
			set_interaction(OBJ_INTERACTION_00)
		OBJSTATE_TURN_AROUND_START:
			_spearhead_turn_around_start()
		OBJSTATE_14:
			_spearhead_state_14_15(OBJSTATE_44)
		OBJSTATE_15:
			_spearhead_state_14_15(OBJSTATE_45)
		OBJSTATE_STUN_LEFT_START, OBJSTATE_STUN_RIGHT_START:
			var left: bool = state == OBJSTATE_STUN_LEFT_START
			set_cur(OBJ_STATE, OBJSTATE_STUN_LEFT if left else OBJSTATE_STUN_RIGHT)
			set_object_frameset_ptr(FRAMESET_681ED if hdir() else FRAMESET_681E4)
			set_collbox_x(-6, 5)
			set_interaction(OBJ_INTERACTION_00)
			_spearhead_stun(left)
		OBJSTATE_20:
			func_62e8f()
		OBJSTATE_21:
			func_62f76()
		OBJSTATE_22:
			func_62eaa()
		OBJSTATE_23:
			func_62f91()
		OBJSTATE_24:
			func_62e74()
		OBJSTATE_25:
			func_62f5b()
		OBJSTATE_26:
			func_62c9f()
		OBJSTATE_27:
			func_62d7d()
		OBJSTATE_SPECIAL_1:
			_spearhead_sleep()
		OBJSTATE_SPECIAL_2:
			_spearhead_angry()
		OBJSTATE_SPECIAL_3:
			_spearhead_wake_up()
		OBJSTATE_FALL:
			obj_state_fall()
		OBJSTATE_WALK:
			_spearhead_walk()
		OBJSTATE_BUMP_LEFT:
			obj_state_bump_left()
		OBJSTATE_BUMP_RIGHT:
			obj_state_bump_right()
		OBJSTATE_ATTACKED_LEFT:
			func_62840()
		OBJSTATE_ATTACKED_RIGHT:
			func_62898()
		OBJSTATE_WOBBLE_LEFT, OBJSTATE_53:
			func_62fa7_from_state()
		OBJSTATE_WOBBLE_RIGHT, OBJSTATE_52:
			func_62ec3(DATA_602E0)
		OBJSTATE_3B:
			_spearhead_state_3b_3c(false)
		OBJSTATE_3C:
			_spearhead_state_3b_3c(true)
		OBJSTATE_3F:
			_spearhead_state_3f()
		OBJSTATE_40:
			_spearhead_state_40()
		OBJSTATE_STANDING_FALL:
			obj_state_standing_fall()
		OBJSTATE_42:
			func_62926()
		OBJSTATE_TURN_AROUND:
			_spearhead_turn_around()
		OBJSTATE_44, OBJSTATE_56:
			func_62ca8()
		OBJSTATE_45, OBJSTATE_57:
			func_62d86()
		OBJSTATE_STUN_LEFT:
			_spearhead_stun(true)
		OBJSTATE_STUN_RIGHT:
			_spearhead_stun(false)
		OBJSTATE_50:
			func_62ec3(DATA_602C0)
		OBJSTATE_51:
			func_62faa(DATA_602C0)
		OBJSTATE_54:
			func_62ec3(DATA_60300)
		OBJSTATE_55:
			func_62faa(DATA_60300)
		OBJSTATE_PICKED_UP_LEFT_START, OBJSTATE_PICKED_UP_RIGHT_START:
			enemy_picked_up_start(state == OBJSTATE_PICKED_UP_LEFT_START)
		OBJSTATE_18, OBJSTATE_19, OBJSTATE_48, OBJSTATE_49:
			enemy_held(state, FRAMESET_681E4, FRAMESET_681ED)
		OBJSTATE_FULL_THROW_LEFT_START, OBJSTATE_FULL_THROW_RIGHT_START:
			enemy_full_throw_start(state == OBJSTATE_FULL_THROW_LEFT_START, FRAMESET_68292, FRAMESET_6829B)
		0x1A, 0x1B, 0x1C, 0x36, 0x37, 0x4A, 0x4B, 0x4E, 0x4F, 0x58, 0x59, 0x5E, 0x5F:
			common_enemy_state(state)  # the same shared routines as the standard enemies'
		_:
			note_unported("SpearheadFunc state $%02x" % state)


## Func_62fa7: the rightward hop along Data_602e0 (OBJSTATE_WOBBLE_LEFT and OBJSTATE_53).
func func_62fa7_from_state() -> void:
	func_62faa(DATA_602E0)


## .Default: sting off, falling, facing Wario (HDIR set when he is to the right).
func _spearhead_default() -> void:
	set_interaction(OBJ_INTERACTION_01)
	set_cur(OBJ_STATE, OBJSTATE_FALL)
	if byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A):
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) | OBJSUBFLAG_HDIR)
		set_cur(OBJ_VAR_3, 0)
		set_collbox_x(-7, 9)
		set_object_frameset_ptr(FRAMESET_681DB)
	else:
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_HDIR)
		set_cur(OBJ_VAR_3, 0)
		set_collbox_x(-10, 6)
		set_object_frameset_ptr(FRAMESET_681D2)


## .SleepStart (the night start): asleep, the sting in.
func _spearhead_sleep_start() -> void:
	set_interaction(OBJ_INTERACTION_01)
	set_cur(OBJ_STATE, OBJSTATE_SPECIAL_1)
	set_object_frameset_ptr(FRAMESET_68234)
	set_collbox_x(-6, 5)


## .Sleep: facing away from Wario (HDIR clear while he is to the right), waking when he comes
## within 32 pixels each way on screen (then turning to him after 32 frames, .WakeUp);
## otherwise the ground shake wobbles it, and without ground it falls.
func _spearhead_sleep() -> void:
	if byte(cur(OBJ_SCREEN_X_POS) + 0x2A) < byte(wWarioScreenXPos + 0x2A):
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & ~OBJSUBFLAG_HDIR)
	else:
		set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) | OBJSUBFLAG_HDIR)
	var dy: int = byte(cur(OBJ_SCREEN_Y_POS) - wWarioScreenYPos)
	var dx: int = byte(cur(OBJ_SCREEN_X_POS) - wWarioScreenXPos)
	if (dy < 32 or dy >= 0x100 - 32) and (dx < 32 or dx >= 0x100 - 32):
		set_cur(OBJ_STATE, OBJSTATE_SPECIAL_3)
		if hdir():
			set_collbox_x(-7, 9)
			set_object_frameset_ptr(FRAMESET_68287)
		else:
			set_object_frameset_ptr(FRAMESET_6827C)
		set_cur(OBJ_STATE_DURATION, 32)
		return
	if _spearhead_shaken(0x10_41C8):
		return
	set_hpos_from_object()
	if object_probe(COLLISION_DOWN) == 0:
		set_cur(OBJ_STATE, OBJSTATE_STANDING_FALL_START)
		return
	store_object_y_from_hpos()


## .Land: walking again, the sting coming back after 10 frames; after the long stun (OBJ_VAR_1 =
## $ff) it lands angry with the sting out (.LandWithSting).
func _spearhead_land() -> void:
	if cur(OBJ_VAR_1) == 0xFF:
		set_interaction(OBJ_INTERACTION_FRONT_STING)
		set_cur(OBJ_STATE, OBJSTATE_SPECIAL_2)
		if hdir():
			set_collbox_x(-7, 9)
			set_object_frameset_ptr(FRAMESET_68213)
		else:
			set_collbox_x(-10, 6)
			set_object_frameset_ptr(FRAMESET_68208)
		set_cur(OBJ_STATE_DURATION, 32)
		return
	set_interaction(OBJ_INTERACTION_01)
	set_cur(OBJ_STATE, OBJSTATE_WALK)
	if hdir():
		set_collbox_x(-7, 9)
		set_object_frameset_ptr(FRAMESET_681DB)
	else:
		set_collbox_x(-10, 6)
		set_object_frameset_ptr(FRAMESET_681D2)
	set_cur(OBJ_STATE_DURATION, 10)


## The ground shake makes a Spearhead wobble one way or the other, by bit 0 of rDIV (read at
## `site`): OBJSTATE_WOBBLE_LEFT_START or _RIGHT_START.
func _spearhead_shaken(site: int) -> bool:
	if wGroundShakeCounter < 0x10:
		return false
	set_cur(OBJ_STATE, OBJSTATE_WOBBLE_LEFT_START | (read_div(site) & 1))
	return true


## .Angry: after 32 frames, walking.
func _spearhead_angry() -> void:
	if _spearhead_shaken(0x10_42B3):
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		return
	set_cur(OBJ_VAR_1, 0)
	set_cur(OBJ_STATE, OBJSTATE_WALK)
	set_object_frameset_ptr(FRAMESET_681DB if hdir() else FRAMESET_681D2)


## .WakeUp: after OBJ_STATE_DURATION, turn around.
func _spearhead_wake_up() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) == 0:
		_spearhead_turn_around_start()


## .Walk: the sting comes out when OBJ_STATE_DURATION runs out; then walk half a pixel a frame
## along the ground, turning at a wall or the ground's end.
func _spearhead_walk() -> void:
	if _spearhead_shaken(0x10_4318):
		return
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) == 0:
			set_interaction(OBJ_INTERACTION_FRONT_STING)
		return
	set_hpos_from_object()
	if object_probe(COLLISION_DOWN) == 0:
		set_cur(OBJ_STATE, OBJSTATE_STANDING_FALL_START)
		return
	store_object_y_from_hpos()
	if hdir():
		if (cur(OBJ_X_POS) & 0x0F) + 9 >= 16:
			if (process_block_on_right() & 0x0F) == 0:
				set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND_START)
				return
		set_hpos_from_object(-4, 9)
		if object_probe(COLLISION_UNK4) == 0:
			move_object_right_slow()
			return
	else:
		if (cur(OBJ_X_POS) & 0x0F) < 10:
			if (process_block_on_left() & 0x0F) == 0:
				set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND_START)
				return
		set_hpos_from_object(-4, -10)
		if object_probe(COLLISION_UNK4) == 0:
			move_object_left_slow()
			return
	set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND_START)


## .BumpLeftStart and .BumpRightStart.
func _spearhead_bump_start(left: bool) -> void:
	if left:
		set_cur(OBJ_STATE, OBJSTATE_BUMP_LEFT)
		set_object_frameset_ptr(FRAMESET_681F6 if hdir() else FRAMESET_6826E)
	else:
		set_cur(OBJ_STATE, OBJSTATE_BUMP_RIGHT)
		set_object_frameset_ptr(FRAMESET_68265 if hdir() else FRAMESET_681FF)
	# `ld [hld], a ; OBJ_VAR_3` writes at hl = OBJ_STATE_DURATION, where SetObjectFramesetPtr left it.
	set_cur(OBJ_STATE_DURATION, 12)
	set_cur(OBJ_VAR_2, 2)
	set_collbox_x(-6, 5)
	set_interaction(OBJ_INTERACTION_01)


## .StunLeft and .StunRight: pushed while OBJ_VAR_2 lasts, then OBJSTATE_0F.
func _spearhead_stun(left: bool) -> void:
	if cur(OBJ_VAR_2) != 0:
		if left:
			func_62ae5()
		else:
			func_62bce()
		return
	set_cur(OBJ_STATE, OBJSTATE_0F)


## .State14 and .State15 (.Func_40478): tumble start.
func _spearhead_state_14_15(state: int) -> void:
	set_cur(OBJ_STATE, state)
	set_object_frameset_ptr(FRAMESET_681ED if hdir() else FRAMESET_681E4)
	set_cur(OBJ_VAR_2, 2)
	set_cur(OBJ_VAR_3, 0)
	set_collbox_x(-6, 5)
	set_interaction(OBJ_INTERACTION_00)


## .State3f: on its back for OBJ_STATE_DURATION, falling if the ground goes (Func_628ea).
func _spearhead_state_3f() -> void:
	if wGroundShakeCounter >= 0x10:
		set_cur(OBJ_STATE, OBJSTATE_1C)
		return
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		func_628ea()
		return
	set_cur(OBJ_STATE, OBJSTATE_10)


## .State40: the hop back up (Func_629a6), then .Default with OBJ_VAR_1 = $ff.
func _spearhead_state_40() -> void:
	set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
	if cur(OBJ_STATE_DURATION) != 0:
		func_629a6()
		return
	set_cur(OBJ_STATE, OBJSTATE_00)
	set_cur(OBJ_VAR_1, 0xFF)


## .TurnAroundStart: OBJ_STATE_DURATION 48, then OBJ_VAR_1 ($1c) more.
func _spearhead_turn_around_start() -> void:
	set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND)
	set_object_frameset_ptr(FRAMESET_6825A if hdir() else FRAMESET_6824F)
	set_cur(OBJ_STATE_DURATION, 48)
	set_cur(OBJ_VAR_1, 0x1C)


## .TurnAround: the sting goes in when OBJ_STATE_DURATION runs out, and after OBJ_VAR_1 more frames
## the Spearhead lands facing the other way; meanwhile it falls if the ground goes (Func_62908).
func _spearhead_turn_around() -> void:
	if _spearhead_shaken(0x10_4513):
		return
	if cur(OBJ_STATE_DURATION) != 0:
		set_cur(OBJ_STATE_DURATION, cur(OBJ_STATE_DURATION) - 1)
		if cur(OBJ_STATE_DURATION) == 0:
			set_collbox_x(-6, 5)
			set_interaction(OBJ_INTERACTION_01)
			set_object_frameset_ptr(FRAMESET_68229 if hdir() else FRAMESET_6821E)
		func_62908()
		return
	set_cur(OBJ_VAR_1, cur(OBJ_VAR_1) - 1)
	if cur(OBJ_VAR_1) != 0:
		func_62908()
		return
	set_cur(OBJ_STATE, OBJSTATE_LAND)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) ^ OBJSUBFLAG_HDIR)


## .WobbleLeftStart and .WobbleRightStart.
func _spearhead_wobble_start(state: int) -> void:
	set_cur(OBJ_ACTION, 15 | (1 << 7))
	set_cur(OBJ_STATE, state)
	set_object_frameset_ptr(FRAMESET_681ED if hdir() else FRAMESET_681E4)
	set_cur(OBJ_STATE_DURATION, 4)
	set_cur(OBJ_VAR_2, 2)
	set_cur(OBJ_VAR_3, 0)
	set_collbox_x(-6, 5)
	set_interaction(OBJ_INTERACTION_00)


## .State0b and .State0c: the animation held at its start, OBJ_VAR_2 = 2.
func _spearhead_state_0b_0c(state: int) -> void:
	set_cur(OBJ_STATE, state)
	set_cur(OBJ_FRAME_DURATION, 0)
	set_cur(OBJ_FRAMESET_OFFSET, 0)
	set_cur(OBJ_VAR_2, 2)


## .State3b (pushed right, Func_62bce) and .State3c (pushed left, Func_62ae5), then turn around.
func _spearhead_state_3b_3c(push_left: bool) -> void:
	set_cur(OBJ_FRAME_DURATION, 0)
	set_cur(OBJ_FRAMESET_OFFSET, 0)
	if cur(OBJ_VAR_2) != 0:
		if push_left:
			func_62ae5()
		else:
			func_62bce()
		return
	set_cur(OBJ_STATE, OBJSTATE_TURN_AROUND_START)


## .AttackedLeftStart, .AttackedRightStart, .State28, .State29: knocked away along Data_60180.
func _spearhead_attacked_start(state: int) -> void:
	set_cur(OBJ_STATE, state)
	set_cur(OBJ_SUBSTATE, cur(OBJ_SUBSTATE) & OBJSUBFLAGS_MASK)
	set_cur(OBJ_VAR_3, 0)
	set_cur(OBJ_VAR_2, 2)
	set_cur(OBJ_ACTION, (1 << NO_ACTIONS_F) | 1)
	set_object_frameset_ptr(FRAMESET_68277)
