extends TestCase
## Particles on invented framesets (no ROM bytes): slots taken in turn, an animation that frees its
## slot at the end, wCurParticleAnimEnded, the slide dust that follows Wario, the glow that stays,
## the owl's rise off the screen, and the magic that follows Wario until he stops.


func _sim() -> LevelSim:
	var sim := LevelSim.new()
	# Two frames, shown 2 and 1 frames more after their first.
	var pairs: Array = [[3, 1], [4, 0]]
	sim.load_particle_framesets({"particles": {"framesets": {"549a": pairs, "54c5": pairs, "575a": pairs,
			"57b4": pairs, "58e7": pairs}}})
	return sim


func test_particles_take_the_slots_in_turn_at_hpos() -> void:
	var sim: LevelSim = _sim()
	sim.hYPos = 0x0123
	sim.hXPos = 0x0456
	for i: int in 5:
		sim.create_particle(WarioParticles.PARTICLE_DUST)
	assert_eq([sim.wNumParticles, sim.wCurParticleIndex], [4, 1], "the fifth replaces the first")
	assert_eq(sim.wParticles.slice(0, 6), PackedByteArray([4, 0, 0x01, 0x23, 0x04, 0x56]))


func test_debris_plays_its_frameset_once_and_frees_its_slot() -> void:
	var sim: LevelSim = _sim()
	sim.create_particle_in_block(WarioParticles.PARTICLE_DEBRIS, 3, 6)
	assert_eq([sim.wParticles[2], sim.wParticles[3], sim.wParticles[5]], [0, 0x40, 0x68], "the block's bottom middle")
	var frames: Array = []
	var ended: Array = []
	for frame: int in 6:
		sim.update_particles()
		frames.append(sim.wParticles[WarioParticles.PARTICLE_STRUCT_FRAME])
		ended.append(sim.wCurParticleAnimEnded)
	assert_eq(frames, [3, 3, 4, 4, 4, 4], "each pair lasts its duration and one frame more")
	assert_eq(ended, [0, 0, 0, 1, 1, 1], "the end is seen once; with no particles left nothing runs")
	assert_eq([sim.wParticles[0], sim.wNumParticles], [0, 0])


func test_slide_dust_follows_wario_while_he_slides() -> void:
	var sim: LevelSim = _sim()
	sim.wWarioState = WarioRam.WST_SLIDING
	sim.create_particle(WarioParticles.PARTICLE_SLIDE_DUST_RIGHT)
	sim.update_particles()
	sim.wWarioYPos = 0x0100
	sim.wWarioXPos = 0x0200
	sim.update_particles()
	assert_eq([sim.wParticles[2], sim.wParticles[3], sim.wParticles[4], sim.wParticles[5]], [0x00, 0xF4, 0x01, 0xF4],
			"12 px up and behind him")
	sim.wWarioState = WarioRam.WST_ROLLING
	sim.update_particles()
	assert_eq(sim.wNumParticles, 0)


func test_the_treasure_glow_stays_and_signals_each_loop() -> void:
	var sim: LevelSim = _sim()
	sim.create_particle(WarioRam.PARTICLE_TREASURE_GLOW)
	var ended: Array = []
	for frame: int in 8:
		sim.update_particles()
		ended.append(sim.wCurParticleAnimEnded)
	assert_eq(ended, [0, 0, 0, 1, 0, 0, 0, 1])
	assert_eq(sim.wNumParticles, 1)


func test_the_treasure_clear_waits_for_the_glow() -> void:
	var sim: LevelSim = _sim()
	sim.wWarioState = WarioRam.WST_GET_TREASURE_CLEAR
	sim.wLevelEndScreen = 0x81
	sim.wJoypadDown = WarioRam.PAD_A
	sim.wCurParticleAnimEnded = 0
	sim.update_state_get_treasure_clear()
	assert_eq(sim.wLevelEndScreen, 0x81)
	sim.wCurParticleAnimEnded = 1
	sim.update_state_get_treasure_clear()
	assert_eq(sim.wLevelEndScreen, 0x01, "A cut the 180 frames short; the level may end")


func test_the_owl_rises_until_its_sprite_is_below_the_screen() -> void:
	var sim: LevelSim = _sim()
	sim.hYPos = 0x0104
	sim.hXPos = 0x0050
	sim.wSCY = 0x00
	sim.create_particle(WarioParticles.PARTICLE_OWL)
	sim.update_particles()
	assert_eq([sim.wParticles[2], sim.wParticles[3], sim.wCurSpriteYCoord], [0x01, 0x04, 0x14], "not moved at first")
	sim.update_particles()
	assert_eq([sim.wParticles[2], sim.wParticles[3]], [0x01, 0x02], "2 px up")
	sim.update_particles()
	sim.update_particles()
	assert_eq([sim.wParticles[2], sim.wParticles[3], sim.wCurSpriteYCoord], [0x00, 0xFE, 0x0E], "across the page")
	assert_eq(sim.wNumParticles, 1)
	sim.wSCY = 0x40  # its sprite now wraps to the bottom: 0xfc + 16 - 0x40
	sim.update_particles()
	assert_eq([sim.wCurSpriteYCoord, sim.wNumParticles, sim.wParticles[0]], [0xCC, 0, 0], "gone at $c0 and below")


func test_magic_follows_wario_until_he_stops() -> void:
	var sim: LevelSim = _sim()
	sim.hYPos = 0x0010
	sim.hXPos = 0x0020
	sim.create_particle(WarioParticles.PARTICLE_MAGIC_1)
	sim.wWarioYPos = 0x0130
	sim.wWarioXPos = 0x0240
	sim.update_particles()
	assert_eq([sim.wParticles[3], sim.wParticles[5]], [0x10, 0x20], "where it was made at first")
	sim.update_particles()
	assert_eq(sim.wParticles.slice(2, 6), PackedByteArray([0x01, 0x30, 0x02, 0x40]), "then at Wario")
	assert_eq([sim.hYPos, sim.hXPos], [0x0130, 0x0240], "through hPos")
	sim.wWarioState = WarioRam.WST_MAGIC_STOPPING
	sim.update_particles()
	assert_eq([sim.wNumParticles, sim.wParticles[0]], [0, 0])


func test_a_particle_note_outlives_warios_update() -> void:
	var sim := LevelSim.new()  # no framesets loaded
	sim.create_particle(WarioParticles.PARTICLE_DUST)
	sim.wCameraConfigFlags = 1 << 1  # CAM_XSCROLL1: Wario's update through update(), which clears the notes
	sim.wFloorTransitionDir = 1  # and returns at once
	sim.update_level_wario()
	assert_eq(sim.unported, PackedStringArray(["particle frameset 03:54c5"]))
