extends TestCase
## The ported level camera (LevelSim) on hand-set variables, without ROM data. Agreement with the
## original is checked against oracle traces (make wario-parity: every camera run of a movie).


## A transitions-mode room two sections wide (x 0-511) and one section tall (y 512-767).
func _sim() -> LevelSim:
	var sim := LevelSim.new()
	sim.load_room_camera({"upper_y_limit": 2, "lower_y_limit": 3, "left_x_limit": 0, "right_x_limit": 2,
			"camera_config": WarioRam.CAM_TRANSITIONS})
	sim.wDirection = WarioRam.DIRECTION_RIGHT
	sim.wWarioXPos = 0x0100
	sim.wWarioYPos = 0x02F0
	return sim


func test_scrolling_right_stops_at_the_rooms_right_edge() -> void:
	var sim := _sim()
	sim.wCameraSCX = 0x015E  # two pixels short of the last screen, (2 - 1) * 256 + 96
	sim.scroll_camera_right(4)
	assert_eq([sim.wCameraSCX, sim.wScrollRightEdge], [0x0160, 1], "clamped at the edge")
	var bordered := _sim()
	bordered.wCameraConfigFlags |= WarioRam.CAM_BORDER_RIGHT
	bordered.wCameraSCX = 0x013E
	bordered.scroll_camera_right(4)
	assert_eq(bordered.wCameraSCX, 0x0140, "a right border keeps $20 more in view")


func test_scrolling_left_stops_at_the_rooms_left_edge() -> void:
	var sim := _sim()
	sim.wCameraSCX = 0x0002
	sim.scroll_camera_left(4)
	assert_eq([sim.wCameraSCX, sim.wScrollLeftEdge], [0x0000, 1])


func test_movement_scrolls_by_the_delta_corrected_towards_the_spacing() -> void:
	var sim := _sim()
	sim.wCameraSCX = 0x0080
	sim.wCameraXDelta = 2
	sim.wWarioScreenXPos = 0x60  # right of the $58 spacing: the camera catches up by one more
	sim.level_scroll_horizontal()
	assert_eq([sim.wCameraSCX, sim.wCameraXDelta], [0x0083, 0], "moved 3, delta consumed")
	assert_eq(sim.wLevelEdgeUpdateFlags, WarioRam.LEVEL_EDGE_UPDATE_RIGHT, "a new column to draw")


func test_standing_still_drifts_one_pixel_a_frame_after_the_first() -> void:
	var sim := _sim()
	sim.wCameraSCX = 0x0080
	sim.wWarioScreenXPos = 0x50  # left of the spacing
	sim.level_scroll_horizontal()
	assert_eq(sim.wCameraSCX, 0x0080, "the first still frame waits")
	sim.level_scroll_horizontal()
	sim.level_scroll_horizontal()
	assert_eq(sim.wCameraSCX, 0x007E, "then 1 px a frame towards the spacing")


func test_the_initial_camera_is_capped_at_the_rooms_left_and_lower_edges() -> void:
	var sim := _sim()
	sim.wWarioXPos = 0x0038
	sim.set_initial_camera_scroll()
	sim.apply_initial_camera_scroll()
	# x - ($58 - 8) is negative: capped at the left limit; y - $60 + $90 reaches the lower limit.
	assert_eq([sim.wCameraRoomXScrollLimit, sim.wCameraSCX], [1, 0x0000], "left edge")
	assert_eq([sim.wCameraRoomYScrollLimit, sim.wCameraSCY], [0xFF, 0x0268], "lower edge, $68 into section 2")
	assert_eq([sim.wSCX, sim.wSCY], [0x00, 0x68], "scroll shadows")


func test_a_floor_transition_slides_the_camera_four_pixels_a_frame() -> void:
	var sim := _sim()
	sim.wCameraSCY = 0x0200
	sim.wFloorTransitionDir = WarioRam.FLOOR_TRANSITION_UP
	sim.wFloorTransitionTimer = 8
	sim.wIsFloorTransition = 1
	sim.update_camera()
	assert_eq([sim.wCameraSCY, sim.wFloorTransitionTimer, sim.wFloorTransitionDir], [0x0204, 4, WarioRam.FLOOR_TRANSITION_UP])
	sim.update_camera()
	assert_eq([sim.wCameraSCY, sim.wFloorTransitionTimer, sim.wFloorTransitionDir, sim.wIsFloorTransition],
			[0x0208, 0, 0, 0], "ends when the timer runs out")
	var waiting := _sim()
	waiting.wFloorTransitionDir = WarioRam.FLOOR_TRANSITION_UP
	waiting.wFloorTransitionTimer = 8
	waiting.wIsDMATransferPending = 1
	waiting.update_camera()
	assert_eq(waiting.wFloorTransitionTimer, 8, "a pending graphics transfer holds the slide")


func test_edges_are_streamed_one_column_and_one_row_a_frame() -> void:
	var sim := _sim()
	sim.wLevelEdgeUpdateFlags = (WarioRam.LEVEL_EDGE_UPDATE_RIGHT | WarioRam.LEVEL_EDGE_UPDATE_LEFT
			| WarioRam.LEVEL_EDGE_UPDATE_UP | WarioRam.LEVEL_EDGE_UPDATE_DOWN)
	sim.stream_level_edges()
	assert_eq(sim.wLevelEdgeUpdateFlags, WarioRam.LEVEL_EDGE_UPDATE_LEFT | WarioRam.LEVEL_EDGE_UPDATE_DOWN,
			"right before left, up before down")
	sim.stream_level_edges()
	assert_eq(sim.wLevelEdgeUpdateFlags, 0)
