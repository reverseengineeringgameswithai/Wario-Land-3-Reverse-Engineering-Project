class_name LevelView
extends Node2D
## Draws an extracted level: each block from its room's decoded block sheet
## (rooms/room-NNN-blocks.png, tools/wl3pc/extract/room_gfx.py), then Wario's sprite as DrawWario
## left it (LevelSim.drawn_wario, from wario_sprites.json), then the blocks' pixels that the
## original draws over sprites (rooms/room-NNN-priority.png). Without the sheets, or with the
## collision view on (F2), blocks are drawn by handler kind in flat colours and Wario as his
## collision box. Presentation only: it reads LevelSim and never changes it.
## The view's top-left corner is the scroll the original shows (LevelSim.displayed_camera_x/y,
## whose low bytes are wSCX/wSCY), and OAM positions are relative to it, as on the screen.

const BLOCK_PX: int = 16
const COLOURS: Dictionary = {
	"sky": Color("#9cc8e8"), "solid": Color("#5a4632"), "floor": Color("#c8a050"), "slope": Color("#7a6040"),
	"ladder": Color("#d0d0d0"), "breakable": Color("#a07850"), "door": Color("#304890"),
	"transition": Color("#40a060"), "water": Color("#3070c0"), "unknown": Color("#ff00ff"),
	"wario": Color("#e8d020"), "outline": Color("#202020"),
}
## Handler IDs the port implements, by what they look like.
const KINDS: Dictionary = {
	"h06_4020": "free", "h06_4032": "solid", "h06_4208": "floor", "h06_42e5": "floor",
	"h06_40d9": "slope_right", "h06_40b5": "solid", "h06_409f": "free",
	"h06_4163": "slope_left", "h06_413f": "solid", "h06_4129": "free",
	"h06_42c3": "ladder", "h06_42fe": "ladder", "h06_45cb": "door", "h06_47b0": "transition",
}

var _sim: LevelSim
var _camera: Camera2D
var _rooms_dir: String = ""
## Room record number -> Texture2D of its 128 blocks, 16 a row (null if not extracted).
var _block_sheets: Dictionary = {}
## Room record number -> Texture2D of the same blocks, only the pixels drawn over sprites.
var _priority_sheets: Dictionary = {}
var _sprites: WarioSprites
## pair_sheet key -> ImageTexture.
var _sprite_textures: Dictionary = {}
var _object_sprites: ObjectSprites
var _object_textures: Dictionary = {}
var show_collision: bool = false
## The golf minigame's screens (WL3-050): its VRAM as each golf loop leaves it, drawn as the LCD
## draws it.
var _golf_vram: GolfVram
## The level's clear screens (WL3-043), drawn the same way.
var _clear_vram: ClearVram
var _clear_loops: int = 0
## Action Help (WL3-051), drawn the same way.
var _action_help_vram: ActionHelpVram
var _action_help_loops: int = 0
## The map (WL3-052) and its save screen, drawn the same way.
var _overworld_vram: OverworldVram
var _overworld_loops: int = 0
var _save_screen_vram: SaveScreenVram
var _pause_menu_loops: int = 0
## The title (WL3-055), drawn the same way.
var _title_vram: TitleVram
var _title_loops: int = 0
## The credits (WL3-052), drawn the same way.
var _credits_vram: CreditsVram
var _credits_loops: int = 0
## The game over screen (WL3-052), drawn the same way.
var _game_over_vram: GameOverVram
var _game_over_loops: int = 0
## The Perfect screen (WL3-052), drawn the same way.
var _perfect_vram: PerfectVram
var _perfect_loops: int = 0
## The hidden figure's fight (WL3-052), drawn the same way from InitLevel's LoadHiddenFigureGfx on.
var _temple_vram: TempleVram
## The game's resets drawn (Init clears VRAM; the screens start over).
var _resets: int = 0
var _cgb_screen := CgbScreen.new()
var _screen_texture: ImageTexture
var _golf_loops: int = 0


func _ready() -> void:
	_camera = Camera2D.new()
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(_camera)
	_camera.make_current()


func show_level(sim: LevelSim, rooms_dir: String = "", sprites: WarioSprites = null,
		object_sprites: ObjectSprites = null) -> void:
	_sim = sim
	_rooms_dir = rooms_dir
	_sprites = sprites
	_object_sprites = object_sprites
	refresh()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_F2:
		show_collision = not show_collision
		queue_redraw()


## A sheet (`suffix` "blocks" or "priority") of the room record the current room-list entry uses:
## built from its decoded graphics as the room's animation leaves them (RoomSheets), or the
## extracted PNG of its static graphics without them.
func _sheet(cache: Dictionary, suffix: String) -> Texture2D:
	var room: int = int(_sim.level.room_fields.get(_sim.wLevelRoomID, {}).get("room", -1))
	var animated: Texture2D = _animated_sheet(room, suffix == "priority")
	if animated != null:
		return animated
	if not cache.has(room):
		var path: String = _rooms_dir.path_join("room-%03d-%s.png" % [room, suffix])
		var image: Image = Image.load_from_file(path) if not _rooms_dir.is_empty() and FileAccess.file_exists(path) else null
		cache[room] = ImageTexture.create_from_image(image) if image != null else null
	return cache[room]


var _room_sheets: Dictionary = {}  # room -> RoomSheets (null if its graphics are not decoded)
var _animated_textures: Dictionary = {}


func _animated_sheet(room: int, priority: bool) -> Texture2D:
	if _rooms_dir.is_empty():
		return null
	if not _room_sheets.has(room):
		_room_sheets[room] = RoomSheets.load_file(_rooms_dir.path_join("room-%03d.gfx.json" % room), _sim.room_animation)
	var sheets: RoomSheets = _room_sheets[room]
	if sheets == null:
		return null
	var tiles: Array = _sim.shown_animated_tiles()
	var room_pals: int = _sim.shown_room_pals()
	var key: String = "%d/%d/%d/%d/%s" % [room, int(tiles[0]), int(tiles[1]), room_pals, priority]
	if not _animated_textures.has(key):
		_animated_textures[key] = ImageTexture.create_from_image(sheets.sheet(int(tiles[0]), int(tiles[1]), room_pals, priority))
	return _animated_textures[key]


## After each game loop: what a title, credits, game over, Perfect, golf, clear screen, Action Help, map,
## or save screen loop's screen load and V-Blank wrote to VRAM.
func after_loop() -> void:
	if _sim == null:
		return
	if _sim.resets != _resets:
		_resets = _sim.resets
		_forget_screens()
	if _sim.title != null and _sim.title.loops != _title_loops:
		_title_loops = _sim.title.loops
		if _title_vram == null:
			_title_vram = TitleVram.new(_sim.title.document)
		_title_vram.update(_sim.title)
	if _sim.credits != null and _sim.credits.loops != _credits_loops:
		_credits_loops = _sim.credits.loops
		if _credits_vram == null:
			_credits_vram = CreditsVram.new(_sim.credits.document)
		_credits_vram.update(_sim.credits)
	if _sim.game_over != null and _sim.game_over.loops != _game_over_loops:
		_game_over_loops = _sim.game_over.loops
		if _game_over_vram == null:
			_game_over_vram = GameOverVram.new(_sim.game_over.document)
		_game_over_vram.update(_sim.game_over)
	if _sim.perfect != null and _sim.perfect.loops != _perfect_loops:
		_perfect_loops = _sim.perfect.loops
		if _perfect_vram == null:
			_perfect_vram = PerfectVram.new(_sim.perfect.document)
		_perfect_vram.update(_sim.perfect)
	if _sim.golf != null and _sim.golf.loops != _golf_loops:
		_golf_loops = _sim.golf.loops
		if _golf_vram == null:
			_golf_vram = GolfVram.new(_sim.golf.document, _sim.room_animation)
		_golf_vram.update(_sim.golf, _sim)
	if _sim.wState == LevelSim.ST_GOLF_BUILDING:
		_from_golf_building = true
		if _sim.wSubState != 0:
			_into_golf_building = false
		elif _last_state == LevelSim.ST_OVERWORLD:
			_into_golf_building = true
	elif _sim.wState != LevelSim.ST_OVERWORLD or _sim.wSubState != 0:
		_from_golf_building = false
	_last_state = _sim.wState
	if _sim.clear != null and _sim.clear.loops != _clear_loops:
		_clear_loops = _sim.clear.loops
		if _clear_vram == null:
			_clear_vram = ClearVram.new(_sim.clear.document, _sim.room_animation)
		_clear_vram.update(_sim.clear, _sim)
	if _sim.action_help != null and _sim.action_help.loops != _action_help_loops:
		_action_help_loops = _sim.action_help.loops
		if _action_help_vram == null:
			_action_help_vram = ActionHelpVram.new(_sim.action_help.document, _sim.room_animation)
		_action_help_vram.update(_sim.action_help, _sim)
	if _sim.wState == LevelSim.ST_LEVEL and _sim.wLevel == LevelSim.THE_TEMPLE and _sim.hidden_figure_gfx_loads > 0:
		if _temple_vram == null:
			_temple_vram = TempleVram.new(_temple_document(), _sim.room_animation, _sprites, _object_sprites)
		_temple_vram.update(_sim)
	_overworld_after_loop()


## temple.json beside the rooms' directory ({} without it: the figure's screen is not drawn).
func _temple_document() -> Dictionary:
	var path: String = _rooms_dir.get_base_dir().path_join("temple.json")
	if _rooms_dir.is_empty() or not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## After a reset (Init: VRAM cleared, the screens' state with it): no screen's VRAM, as at power-on.
func _forget_screens() -> void:
	_golf_vram = null
	_golf_loops = 0
	_clear_vram = null
	_clear_loops = 0
	_action_help_vram = null
	_action_help_loops = 0
	_overworld_vram = null
	_overworld_loops = 0
	_save_screen_vram = null
	_pause_menu_loops = 0
	_title_vram = null
	_title_loops = 0
	_credits_vram = null
	_credits_loops = 0
	_game_over_vram = null
	_game_over_loops = 0
	_perfect_vram = null
	_perfect_loops = 0
	_temple_vram = null


## The map's loop: entered from a level (the first loop of its sub-state 0, the level's fade out) it
## starts on VRAM and palettes the level left; back from the save screen (which puts VRAM back,
## LoadBackupVRAM) its palettes are as the save screen's last fade left them, white.
func _overworld_after_loop() -> void:
	var map: OverworldSim = _sim.overworld
	if map != null and map.loops != _overworld_loops:
		_overworld_loops = map.loops
		var entered: bool = _sim.wState == LevelSim.ST_OVERWORLD and _sim.wSubState == 0 and _sim.wPalFadeCounter == 1
		if _overworld_vram == null or entered:
			_overworld_vram = OverworldVram.new(map.document)
		_overworld_vram.update(map)
	var pause: PauseMenuSim = _sim.pause_menu_screen
	if pause != null and pause.loops != _pause_menu_loops:
		_pause_menu_loops = pause.loops
		if _save_screen_vram == null:
			_save_screen_vram = SaveScreenVram.new(pause.document)
		_save_screen_vram.update(pause, _sim)
		if _sim.wState == LevelSim.ST_OVERWORLD and _overworld_vram != null:
			_overworld_vram.faded_to_white()


func refresh() -> void:
	_camera.position = Vector2(_sim.displayed_camera_x, _sim.displayed_camera_y)
	queue_redraw()


## What a handler looks like: the port's own table first, then the disassembly label if known.
func kind_of(handler: String) -> String:
	if KINDS.has(handler):
		return KINDS[handler]
	if WarioBlocks.BREAKABLE.has(handler):
		return "breakable"
	var label: String = String(_sim.level.handler_labels.get(handler, ""))
	for pair: Array in [["Water", "water"], ["Current", "water"], ["Door", "door"], ["Block", "breakable"]]:
		if pair[0] in label:
			return pair[1]
	return "unknown"


func _draw() -> void:
	if _sim == null:
		return
	var view := Rect2(Vector2(_sim.displayed_camera_x, _sim.displayed_camera_y) - Vector2(8, 8), Vector2(176, 160))
	if (_sim.wState == LevelSim.ST_TITLE or _sim.wState == TitleSim.ST_LANGUAGE_SELECTION) and _sim.title != null:
		_draw_title(view)
		return
	if _sim.wState == LevelSim.ST_CREDITS and _sim.credits != null:
		_draw_credits(view)
		return
	if _sim.wState == LevelSim.ST_GAME_OVER and _sim.game_over != null:
		_draw_game_over(view)
		return
	if _sim.wState == LevelSim.ST_PERFECT and _sim.perfect != null:
		_draw_perfect(view)
		return
	if _golf_shown():
		_draw_golf(view)
		return
	if _into_golf_building and _overworld_vram != null and not _overworld_vram.screen.is_empty():
		# The map's fade into the golf building (FastFadeToWhite), drawn as white over the map.
		_draw_overworld(view)
		draw_rect(view, Color(1, 1, 1, float(_sim.wPalFadeCounter) / float(LevelSim.FADE_STEPS)))
		return
	if _clear_shown():
		_draw_clear(view)
		return
	if _sim.wState == ClearSim.ST_ACTION_HELP:
		_draw_action_help(view)
		return
	if _overworld_shown():
		_draw_overworld(view)
		return
	if _sim.wState == LevelSim.ST_PAUSE_MENU and _sim.wSubState >= PauseMenuSim.SST_PAUSE_18:
		_draw_save_screen(view)
		return
	if (_sim.wState == LevelSim.ST_PAUSE_MENU and _sim.pause_menu_screen != null
			and not _sim.wSubState in PAUSE_LEVEL_SHOWN):
		_draw_pause_menu(view)
		return
	if _sim.level == null:  # from power-on, until the map enters a level (InitLevel loads it)
		draw_rect(view, Color.WHITE)
		return
	if _temple_shown():
		_draw_screen(_temple_vram, _temple_vram.oam, TempleVram.LCDC, TempleVram.WX, view, _temple_vram.wy,
				[[0, _temple_vram.scx]], [[0, _temple_vram.scy]])
		_draw_transition(view)
		if _sim.wState == LevelSim.ST_PAUSE_MENU:
			_draw_pause_fade_over_level(view)
		return
	draw_rect(view, COLOURS["sky"])
	var first_column: int = maxi(0, int(view.position.x) / BLOCK_PX)
	var first_row: int = maxi(0, int(view.position.y) / BLOCK_PX)
	var sheet: Texture2D = null if show_collision else _sheet(_block_sheets, "blocks")
	_draw_blocks(sheet, first_row, first_column, true)
	if sheet != null and _sprites != null and _sprites.can_draw(_sim.drawn_wario):
		# Back to front, the reverse of OAM order: objects behind Wario, Wario, objects over him.
		_draw_objects(false)
		_draw_wario_sprite()
		_draw_objects(true)
		_draw_particles()
		var priority: Texture2D = _sheet(_priority_sheets, "priority")
		if priority != null:
			_draw_blocks(priority, first_row, first_column, false)
	elif sheet == null or not _sim.drawn_wario.is_empty():
		_draw_objects(false)
		_draw_wario()
		_draw_objects(true)
	_draw_transition(view)
	if _sim.wState == LevelSim.ST_PAUSE_MENU:
		_draw_pause_fade_over_level(view)


## The blocks in view from `sheet`, or by handler kind when there is no sheet and `kinds` is set.
func _draw_blocks(sheet: Texture2D, first_row: int, first_column: int, kinds: bool) -> void:
	for row: int in range(first_row, mini(LevelCollision.HEIGHT, first_row + 11)):
		for column: int in range(first_column, mini(LevelCollision.WIDTH, first_column + 12)):
			var value: int = _sim.level.block_at(row, column)
			if value < 0:
				continue
			if sheet != null:
				var block: int = value & 0x7F
				draw_texture_rect_region(sheet, Rect2(column * BLOCK_PX, row * BLOCK_PX, BLOCK_PX, BLOCK_PX),
						Rect2((block % 16) * BLOCK_PX, (block / 16) * BLOCK_PX, BLOCK_PX, BLOCK_PX))
			elif kinds:
				_draw_block(kind_of(_sim.level.handler_for(_sim.wLevelRoomID, value)), column * BLOCK_PX, row * BLOCK_PX)


## The objects DrawObjects drew (LevelSim.drawn_objects) that go over (`over_wario`) or behind Wario,
## each as its OAM entries, later entries first so earlier ones end up on top.
func _draw_objects(over_wario: bool) -> void:
	if _object_sprites == null:
		return
	var origin := Vector2(_sim.displayed_camera_x, _sim.displayed_camera_y)
	var drawn: Array = _sim.drawn_objects.duplicate()
	drawn.reverse()
	for item: Dictionary in drawn:
		if bool(item["over_wario"]) != over_wario or not _object_sprites.can_draw(item):
			continue
		var entries: Array = _object_sprites.entries(item)
		entries.reverse()
		for entry: Array in entries:
			var oam_y: int = entry[0]
			var oam_x: int = entry[1]
			if oam_x == 0 or oam_x >= 168 or oam_y == 0 or oam_y >= 160:
				continue
			var attributes: int = entry[3]
			var obj_palette: int = attributes & 7
			var colours: Array = _object_sprites.palette(_sim.drawn_object_group, obj_palette)
			if colours.is_empty():
				continue
			var bank: int = (attributes >> 3) & 1
			var key: String = "%d/%d/%d/%d" % [_sim.drawn_object_group, bank, obj_palette, attributes & 0x60]
			if not _object_textures.has(key):
				_object_textures[key] = ImageTexture.create_from_image(
						_object_sprites.pair_sheet(_sim.drawn_object_group, bank, colours, obj_palette, attributes))
			draw_texture_rect_region(_object_textures[key], Rect2(origin + Vector2(oam_x - 8, oam_y - 16), Vector2(8, 16)),
					Rect2(WarioSprites.pair_rect(entry[2])))


## The particles UpdateParticles drew (first in OAM, so over every other sprite), from VRAM bank 0:
## Wario's tile set below $80, the common graphics above; OBJ palettes 0-1 are Wario's, 2 the
## particles'.
func _draw_particles() -> void:
	if _object_sprites == null or not _sprites.can_draw(_sim.drawn_wario):
		return
	var origin := Vector2(_sim.displayed_camera_x, _sim.displayed_camera_y)
	var tile_set: String = _sim.drawn_wario["tile_set"]
	var drawn: Array = _sim.drawn_particles.duplicate()
	drawn.reverse()
	for item: Dictionary in drawn:
		if not _object_sprites.can_draw(item):
			continue
		var entries: Array = _object_sprites.entries(item)
		entries.reverse()
		for entry: Array in entries:
			var oam_y: int = entry[0]
			var oam_x: int = entry[1]
			if oam_x == 0 or oam_x >= 168 or oam_y == 0 or oam_y >= 160:
				continue
			var attributes: int = entry[3]
			var obj_palette: int = attributes & 7
			var colours: Array = []
			var palette_key: String = "particles"
			if obj_palette < WarioSprites.OBJ_PALETTES:
				palette_key = "%s/%d" % [_sim.drawn_wario["palettes"], obj_palette]
				colours = _sprites.palettes[_sim.drawn_wario["palettes"]][obj_palette]
			elif obj_palette == 2:
				colours = _object_sprites.particle_palette
			if colours.is_empty() or ((attributes >> 3) & 1) != 0:
				continue
			var key: String = "particles/%s/%s/%d" % [tile_set, palette_key, attributes & 0x60]
			if not _object_textures.has(key):
				_object_textures[key] = ImageTexture.create_from_image(_object_sprites.bank0_sheet(tile_set,
						_sprites.tile_sets[tile_set], colours, palette_key, attributes))
			draw_texture_rect_region(_object_textures[key], Rect2(origin + Vector2(oam_x - 8, oam_y - 16), Vector2(8, 16)),
					Rect2(WarioSprites.pair_rect(entry[2])))


## Wario's OAM entries as the hardware draws 8x16 sprites: at (OAM x - 8, OAM y - 16) on the screen,
## hidden at OAM x 0 or 168+ and OAM y 0 or 160+, earlier entries over later ones. His tables never
## set the OBJ priority bit or VRAM bank 1 (checked by make sprite-check), so neither is drawn.
func _draw_wario_sprite() -> void:
	var drawn: Dictionary = _sim.drawn_wario
	var origin := Vector2(_sim.displayed_camera_x, _sim.displayed_camera_y)
	var entries: Array = _sprites.entries(drawn)
	entries.reverse()
	for entry: Array in entries:
		var oam_y: int = entry[0]
		var oam_x: int = entry[1]
		if oam_x == 0 or oam_x >= 168 or oam_y == 0 or oam_y >= 160:
			continue
		var attributes: int = entry[3]
		if (attributes & 7) >= WarioSprites.OBJ_PALETTES:
			continue
		var key: String = "%s/%s/%d/%d" % [drawn["tile_set"], drawn["palettes"], attributes & 7, attributes & 0x60]
		if not _sprite_textures.has(key):
			_sprite_textures[key] = ImageTexture.create_from_image(
					_sprites.pair_sheet(drawn["tile_set"], drawn["palettes"], attributes & 7, attributes))
		draw_texture_rect_region(_sprite_textures[key], Rect2(origin + Vector2(oam_x - 8, oam_y - 16), Vector2(8, 16)),
				Rect2(WarioSprites.pair_rect(entry[2])))


## The hidden figure's fight from InitLevel's load on (its fade in, the fight, the pause menu over it,
## and ST_EPILOGUE's fade to white, each fade drawn as white over it): the frame after the loop, as
## its V-Blank leaves VRAM, the OAM, the palettes, and the scroll (TempleVram).
func _temple_shown() -> bool:
	if _temple_vram == null or _temple_vram.screen.is_empty() or _sim.wLevel != LevelSim.THE_TEMPLE:
		return false
	return _sim.wState != LevelSim.ST_LEVEL or _sim.wSubState >= LevelSim.SST_SLOW_FADE_FROM_WHITE


## Room transitions as overlays: white for the fades (FastFadeToWhite, SlowFadeFromWhite), white
## while the next room starts, and black closing in for the door effect. Approximations: the
## original steps every palette colour towards white and draws the door effect with BG tiles.
## The golf minigame is not ported: white from its fade in until the level comes back.
func _draw_transition(view: Rect2) -> void:
	var fade: float = float(_sim.wPalFadeCounter) / float(LevelSim.FADE_STEPS)
	if _sim.wState == LevelSim.ST_OVERWORLD:  # the level's fade out into the map (FastFadeToWhite)
		draw_rect(view, Color(1, 1, 1, fade if _sim.wSubState == 0 else 1.0))
		return
	if _sim.wState == LevelSim.ST_CLEAR:  # the fade out into the clear screen
		draw_rect(view, Color(1, 1, 1, fade))
		return
	if _sim.wState == LevelSim.ST_GOLF:
		draw_rect(view, Color(1, 1, 1, fade if _sim.wSubState == 0 else 1.0))
		return
	if _sim.wState == LevelSim.ST_EPILOGUE:  # after the hidden figure's fight: a fade step every fourth loop
		draw_rect(view, Color(1, 1, 1, fade if _sim.wSubState == 0 else 1.0))
		return
	match _sim.wSubState:
		LevelSim.SST_FAST_FADE_TO_WHITE:
			draw_rect(view, Color(1, 1, 1, fade))
		LevelSim.SST_START_ROOM_FROM_TRANSITION:
			draw_rect(view, Color.WHITE)
		LevelSim.SST_SLOW_FADE_FROM_WHITE:
			draw_rect(view, Color(1, 1, 1, 1.0 - fade))
		LevelSim.SST_DOOR_TRANSITION:
			draw_rect(view, Color(0, 0, 0, float(_sim.wDoorTransitionCounter) / float(LevelSim.DOOR_TRANSITION_STEPS)))


## Golf's screens from its lobby's start to its return: the next frame's LCD registers are those
## its V-Blank sets (a hole's LCDC and window from golf RAM, otherwise LCDC_DEFAULT).
func _golf_shown() -> bool:
	if _golf_vram == null or _golf_vram.screen.is_empty():
		return false
	if _sim.wState == LevelSim.ST_GOLF_BUILDING:
		return not _into_golf_building
	if _sim.wState == LevelSim.ST_OVERWORLD:  # the map's fade out of the golf building
		return _sim.wSubState == 0 and _from_golf_building
	return _sim.wState == LevelSim.ST_GOLF and _sim.wSubState >= LevelSim.SST_GOLF_INIT_LOBBY


## Whether the golf building's fade is the map's into it (its first sub-state, entered from the map),
## whether the map's first sub-state follows the golf building (its fade out of the building's
## screen), and the state of the last loop.
var _into_golf_building: bool = false
var _from_golf_building: bool = false
var _last_state: int = -1


## The clear screens from the treasure screen's start to the way out.
func _clear_shown() -> bool:
	return (_sim.wState == LevelSim.ST_CLEAR and _sim.wSubState >= 1 and _clear_vram != null
			and not _clear_vram.screen.is_empty())


## A screen of `vram` with the OAM and registers, at the camera's place.
func _draw_screen(vram: ScreenVram, oam: PackedByteArray, lcdc: int, wx: int, view: Rect2, wy: int = 0,
		scx_lines: Array = [], scy_lines: Array = []) -> void:
	var pixels: PackedByteArray = _cgb_screen.render(vram, oam, lcdc, _sim.wSCX, _sim.wSCY, wx, wy, [], scx_lines,
			scy_lines)
	var image := Image.create_from_data(CgbScreen.WIDTH, CgbScreen.HEIGHT, false, Image.FORMAT_RGB8, pixels)
	if _screen_texture == null:
		_screen_texture = ImageTexture.create_from_image(image)
	else:
		_screen_texture.update(image)
	draw_rect(view, Color.WHITE)
	draw_texture(_screen_texture, Vector2(_sim.displayed_camera_x, _sim.displayed_camera_y))


## The clear screen and its fades (_ClearScreenStateTable's sub-states), as white over it; the LCD
## is off while a screen loads.
func _draw_clear(view: Rect2) -> void:
	_draw_screen(_clear_vram, _sim.clear.wVirtualOAM, GolfSim.LCDC_DEFAULT, 0, view)
	var steps: int = LevelSim.FADE_STEPS_BY_SPEED[_sim.wFadeSpeed] if _sim.wFadeSpeed < 3 else LevelSim.FADE_STEPS
	var fade: float = float(_sim.wPalFadeCounter) / float(steps)
	match _sim.wSubState:
		ClearSim.SST_CLEAR_TIME_ATTACK, ClearSim.SST_CLEAR_MUSICAL_COINS:
			draw_rect(view, Color(1, 1, 1, fade))
		2, 6, 10:
			draw_rect(view, Color(1, 1, 1, 1.0 - fade))
		1, 5, 9:
			draw_rect(view, Color.WHITE)


## Action Help and its fades (_ActionHelpStateTable's sub-states) as white over it: the screen
## before it fading out (the clear screen's after a level's clear, the title's start menu for its
## demos, or the pause menu), the LCD off while it loads, its screen fading in, and out (to the pause
## menu, which ReturnToPauseMenuFromActionHelp loads while the LCD is off).
func _draw_action_help(view: Rect2) -> void:
	var fade: float = float(_sim.wPalFadeCounter) / float(LevelSim.FADE_STEPS_BY_SPEED[2])
	var shown: bool = _action_help_vram != null and not _action_help_vram.screen.is_empty()
	if _sim.wSubState == 0:
		var way_in: int = _sim.wPowerUpLevel & (ActionHelpSim.ACTION_HELP_LEVEL_CLEAR | ActionHelpSim.ACTION_HELP_TITLE_SCREEN)
		if way_in == ActionHelpSim.ACTION_HELP_TITLE_SCREEN and _title_vram != null and not _title_vram.screen.is_empty():
			_draw_screen(_title_vram, _sim.title.wVirtualOAM, GolfSim.LCDC_DEFAULT, 0, view)
		elif way_in == 0 and _save_screen_vram != null and _save_screen_vram.screen == "pause_menu":
			_draw_screen(_save_screen_vram, _sim.pause_menu_screen.wVirtualOAM, GolfSim.LCDC_BGMAP1, 0, view)
		elif _clear_vram != null and not _clear_vram.screen.is_empty() and _sim.clear != null:
			_draw_screen(_clear_vram, _sim.clear.wVirtualOAM, GolfSim.LCDC_DEFAULT, 0, view)
		draw_rect(view, Color(1, 1, 1, fade))
	elif _sim.wSubState >= 2 and _sim.wSubState <= 4 and shown:
		_draw_screen(_action_help_vram, _sim.action_help.wVirtualOAM, GolfSim.LCDC_BGMAP1, 0, view)
		if _sim.wSubState == 2:
			draw_rect(view, Color(1, 1, 1, 1.0 - fade))
		elif _sim.wSubState == 4:
			draw_rect(view, Color(1, 1, 1, fade))
	else:
		draw_rect(view, Color.WHITE)


## The title and its fades (TitleStateTable's sub-states), as white over it: power-on's white screen
## fading to white, the LCD off while the screen loads, the fade in, the intro with its layers' scroll,
## the fade at its end (modelled in TitleVram), the start menu, the fade to Time Attack's
## description, and the description (its Japanese rows moved mid-frame). The language selection the same way: the title fading out, the LCD off, its screen
## fading in, and the screen.
func _draw_title(view: Rect2) -> void:
	var language: bool = _sim.wState == TitleSim.ST_LANGUAGE_SELECTION
	var substate: int = _sim.wSubState
	var shown: bool = substate in [0, 2, 3] if language else (substate >= 2 and substate <= 8) or substate == 0x0A
	if _title_vram == null or _title_vram.screen.is_empty() or not shown:
		draw_rect(view, Color.WHITE)
		return
	_draw_screen(_title_vram, _sim.title.wVirtualOAM, GolfSim.LCDC_DEFAULT, 0, view, 0, _sim.title.scx_lines(_sim.wSCX),
			_sim.title.scy_lines(_sim.wSCY))
	var steps: int = LevelSim.FADE_STEPS_BY_SPEED[_sim.wFadeSpeed] if _sim.wFadeSpeed < 3 else LevelSim.FADE_STEPS
	var fade: float = float(_sim.wPalFadeCounter) / float(steps)
	if substate == 2:
		draw_rect(view, Color(1, 1, 1, 1.0 - fade))
	elif substate == 8 or (language and substate == 0):
		draw_rect(view, Color(1, 1, 1, fade))


## The credits and their fades (_CreditsStateTable's sub-states), as white over them: the fade to
## white and the LCD off while the screen loads, the fade in, the text scrolling by the music box, and
## its close-up over the whole screen (the window; its fade in modelled in CreditsVram).
func _draw_credits(view: Rect2) -> void:
	var substate: int = _sim.wSubState
	if _credits_vram == null or _credits_vram.screen.is_empty() or substate < 2:
		draw_rect(view, Color.WHITE)
		return
	_draw_screen(_credits_vram, _sim.credits.wVirtualOAM, _credits_vram.lcdc, _credits_vram.wx, view, _credits_vram.wy)
	if substate == 2:
		draw_rect(view, Color(1, 1, 1, 1.0 - float(_sim.wPalFadeCounter) / float(LevelSim.FADE_STEPS)))


## The game over screen and its fades (_GameOverStateTable's sub-states), as white over it: the fade to
## white and the LCD off while the screen loads, the fade in, the screen dropping in with Wario asleep
## and waking (its scroll, wSCY), and the fade to white before Init.
func _draw_game_over(view: Rect2) -> void:
	var substate: int = _sim.wSubState
	if _game_over_vram == null or _game_over_vram.screen.is_empty() or substate < 2 or substate > 5:
		draw_rect(view, Color.WHITE)
		return
	_draw_screen(_game_over_vram, _sim.game_over.wVirtualOAM, GolfSim.LCDC_DEFAULT, 0, view)
	var fade: float = float(_sim.wPalFadeCounter) / float(LevelSim.FADE_STEPS)
	if substate == 2:
		draw_rect(view, Color(1, 1, 1, 1.0 - fade))
	elif substate == 5:
		draw_rect(view, Color(1, 1, 1, fade))


## The Perfect screen and its fades (_PerfectStateTable's sub-states), as white over it: the fade to
## white (over the credits) and the LCD off while the screen loads, the fade in, and the screen (its
## fades in to each palette set modelled in PerfectVram).
func _draw_perfect(view: Rect2) -> void:
	var substate: int = _sim.wSubState
	if substate == 0 and _credits_vram != null and not _credits_vram.screen.is_empty() and _sim.credits != null:
		_draw_screen(_credits_vram, _sim.credits.wVirtualOAM, _credits_vram.lcdc, _credits_vram.wx, view,
				_credits_vram.wy)
		draw_rect(view, Color(1, 1, 1, float(_sim.wPalFadeCounter) / float(LevelSim.FADE_STEPS_BY_SPEED[2])))
		return
	if _perfect_vram == null or _perfect_vram.screen.is_empty() or substate < 2:
		draw_rect(view, Color.WHITE)
		return
	_draw_screen(_perfect_vram, _sim.perfect.wVirtualOAM, GolfSim.LCDC_DEFAULT, 0, view)
	if substate == 2:
		draw_rect(view, Color(1, 1, 1, 1.0 - float(_sim.wPalFadeCounter) / float(LevelSim.FADE_STEPS_BY_SPEED[2])))


## The map from its first screen's set-up on (before it, the level fading out): the frame after this
## loop, as its V-Blank left VRAM, the palettes (its fades' too: they are modelled), and the registers;
## white while the LCD is off.
func _overworld_shown() -> bool:
	return (_sim.wState == LevelSim.ST_OVERWORLD and _overworld_vram != null
			and not _overworld_vram.screen.is_empty())


func _draw_overworld(view: Rect2) -> void:
	if (_overworld_vram.lcdc & 0x80) == 0:
		draw_rect(view, Color.WHITE)
		return
	_draw_screen(_overworld_vram, _sim.overworld.wVirtualOAM, _overworld_vram.lcdc, _overworld_vram.wx, view,
			_overworld_vram.wy)


## The map's save screen (_PauseMenuStateTable from SST_PAUSE_18) and its fades, as white over it: the
## map fading out, the LCD off while the screen loads, the screen's fades in (white: its palettes are
## known once they end), the bar, the "complete" box, and its fades out.
## The pause menu from a level and the level's save (sub-states below SST_PAUSE_18), as the map's
## save screen: the level fading out to white (0) and back in after the menu (6, 7: drawn over the
## level), the LCD off while a screen loads, the menu (3, from BG map 1) and the save screen's bar
## and "complete" box ($0b, $0f), each fading out to white (4, 8, $0c). The fades in are drawn white:
## the palettes are known once they end (ADR-0002).
const PAUSE_LEVEL_SHOWN: Array = [0x00, 0x06, 0x07]


func _draw_pause_menu(view: Rect2) -> void:
	var fade: float = float(_sim.wPalFadeCounter) / float(LevelSim.FADE_STEPS_BY_SPEED[2])
	var vram: SaveScreenVram = _save_screen_vram
	if vram == null or vram.screen.is_empty() or not _sim.wSubState in [0x03, 0x04, 0x08, 0x0B, 0x0C, 0x0F]:
		draw_rect(view, Color.WHITE)
		return
	var lcdc: int = GolfSim.LCDC_BGMAP1 if vram.screen == "pause_menu" else GolfSim.LCDC_DEFAULT
	_draw_screen(vram, _sim.pause_menu_screen.wVirtualOAM, lcdc, 0, view)
	if _sim.wSubState in [0x04, 0x08, 0x0C]:
		draw_rect(view, Color(1, 1, 1, fade))


## Over the level: the fade out to white before the menu, and the fade back in after it.
func _draw_pause_fade_over_level(view: Rect2) -> void:
	var fade: float = float(_sim.wPalFadeCounter) / float(LevelSim.FADE_STEPS_BY_SPEED[2])
	if _sim.wSubState == 0x00:
		draw_rect(view, Color(1, 1, 1, fade))
	elif _sim.wSubState == 0x06:
		draw_rect(view, Color(1, 1, 1, 1.0 - fade))


func _draw_save_screen(view: Rect2) -> void:
	var fade: float = float(_sim.wPalFadeCounter) / float(LevelSim.FADE_STEPS_BY_SPEED[2])
	var shown: bool = _save_screen_vram != null and not _save_screen_vram.screen.is_empty()
	match _sim.wSubState:
		0x18:  # SlowFadeBGToWhite from the map
			if _overworld_vram != null and not _overworld_vram.screen.is_empty() and _sim.overworld != null:
				_draw_screen(_overworld_vram, _sim.overworld.wVirtualOAM, _overworld_vram.lcdc, _overworld_vram.wx,
						view, _overworld_vram.wy)
			draw_rect(view, Color(1, 1, 1, fade))
		0x1B, 0x1F:
			if shown:
				_draw_screen(_save_screen_vram, _sim.pause_menu_screen.wVirtualOAM, GolfSim.LCDC_DEFAULT, 0, view)
			else:
				draw_rect(view, Color.WHITE)
		0x1C, 0x20:
			if shown:
				_draw_screen(_save_screen_vram, _sim.pause_menu_screen.wVirtualOAM, GolfSim.LCDC_DEFAULT, 0, view)
			draw_rect(view, Color(1, 1, 1, fade if shown else 1.0))
		_:
			draw_rect(view, Color.WHITE)


func _draw_golf(view: Rect2) -> void:
	_draw_screen(_golf_vram, _sim.golf.wVirtualOAM, _golf_vram.lcdc, _golf_vram.wx, view)
	# The fades (_GolfStateTable's and _GolfBuildingStateTable's sub-states, and the map's fade out of
	# the building), as white over the screen like the level's; the LCD is off while a screen loads.
	var fade: float = float(_sim.wPalFadeCounter) / float(LevelSim.FADE_STEPS)
	if _sim.wState == LevelSim.ST_OVERWORLD:
		draw_rect(view, Color(1, 1, 1, fade))
		return
	match _sim.wSubState:
		GolfSim.SST_GOLF_HOLE, GolfSim.SST_GOLF_EXIT, GolfSim.SST_GOLF_CLEAR:
			draw_rect(view, Color(1, 1, 1, fade))
		2, 6, 12:
			draw_rect(view, Color(1, 1, 1, 1.0 - fade))
		1, 5, 11:
			draw_rect(view, Color.WHITE)


func _draw_block(kind: String, x: int, y: int) -> void:
	var size: Vector2 = Vector2(BLOCK_PX, BLOCK_PX)
	match kind:
		"free":
			pass
		"floor":
			draw_rect(Rect2(x, y, BLOCK_PX, 4), COLOURS["floor"])
		"slope_right":  # the surface rises to the right (RightSlopeCollision)
			draw_colored_polygon(PackedVector2Array([Vector2(x, y + 16), Vector2(x + 16, y), Vector2(x + 16, y + 16)]),
					COLOURS["slope"])
		"slope_left":  # the surface rises to the left (LeftSlopeCollision)
			draw_colored_polygon(PackedVector2Array([Vector2(x, y), Vector2(x + 16, y + 16), Vector2(x, y + 16)]),
					COLOURS["slope"])
		"ladder":
			draw_rect(Rect2(x + 3, y, 2, 16), COLOURS["ladder"])
			draw_rect(Rect2(x + 11, y, 2, 16), COLOURS["ladder"])
			draw_rect(Rect2(x + 3, y + 6, 10, 2), COLOURS["ladder"])
		"breakable":
			draw_rect(Rect2(Vector2(x, y), size), COLOURS["breakable"])
			draw_rect(Rect2(x + 1, y + 1, 14, 14), COLOURS["outline"], false, 1.0)
		"unknown":
			draw_rect(Rect2(x + 1, y + 1, 14, 14), COLOURS["unknown"], false, 1.0)
		_:
			draw_rect(Rect2(Vector2(x, y), size), COLOURS.get(kind, COLOURS["unknown"]))


## Wario's collision box (signed offsets from his position, the bottom centre) and a facing mark.
func _draw_wario() -> void:
	var x: int = _sim.wWarioXPos
	var y: int = _sim.wWarioYPos
	var left: int = _signed(_sim.wCollisionBoxLeft)
	var top: int = _signed(_sim.wCollisionBoxTop)
	var box := Rect2(x + left, y + top, _signed(_sim.wCollisionBoxRight) - left, _signed(_sim.wCollisionBoxBottom) - top + 1)
	draw_rect(box, COLOURS["wario"])
	draw_rect(box, COLOURS["outline"], false, 1.0)
	var eye_x: float = box.end.x - 5 if _sim.wDirection == WarioRam.DIRECTION_RIGHT else box.position.x + 3
	draw_rect(Rect2(eye_x, box.position.y + 5, 2, 2), COLOURS["outline"])


static func _signed(value: int) -> int:
	return value - 0x100 if value >= 0x80 else value
