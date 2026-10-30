extends TestCase
## Runtime content loading, shared invalid fixtures, and data-only mods.

const PACK: String = "res://assets/content/synthetic"


func _fixtures(kind: String) -> String:
	return repo_path("tests/fixtures/content").path_join(kind)


func test_loads_bundled_pack() -> void:
	var loader := ContentLoader.new()
	var pack: ContentPack = loader.load_pack(PACK)
	assert_true(pack != null, "loaded: %s" % loader.errors)
	if pack == null:
		return
	assert_eq(pack.id, "synthetic-testbed")
	assert_eq(pack.origin, "synthetic")
	assert_true(pack.movement.provisional, "synthetic movement is marked provisional")
	assert_eq((pack.rooms["testbed"] as RoomData).width(), 24, "room width")
	assert_eq(pack.start_room, "testbed")


func test_loads_same_pack_from_filesystem_path() -> void:
	var loader := ContentLoader.new()
	var external: ContentPack = loader.load_pack(ProjectSettings.globalize_path(PACK))
	var bundled: ContentPack = ContentLoader.new().load_pack(PACK)
	assert_true(external != null, "external load: %s" % loader.errors)
	if external != null and bundled != null:
		assert_eq(external.content_hash(), bundled.content_hash(), "same content via filesystem")


func test_example_mod_changes_parameters_and_layout_only_in_effective_copy() -> void:
	var loader := ContentLoader.new()
	var pack: ContentPack = loader.load_pack(PACK)
	var base_hash: String = pack.content_hash()
	assert_true(loader.apply_mods_from_dir(pack, repo_path("mods/examples")), "mods: %s" % loader.errors)
	assert_eq(pack.movement.gravity, 2, "gravity override")
	assert_eq(pack.movement.jump_velocity, -56, "jump override")
	assert_eq((pack.rooms["testbed"] as RoomData).rows[5].substr(2, 4), "====", "tile patch")
	assert_eq(Array(pack.applied_mods), ["low-gravity-ledge"])
	assert_true(pack.content_hash() != base_hash, "hash reflects the mod")
	assert_eq(ContentLoader.new().load_pack(PACK).content_hash(), base_hash, "base pack unchanged")


func test_invalid_mods_are_rejected_without_side_effects() -> void:
	var dirs: PackedStringArray = DirAccess.get_directories_at(_fixtures("invalid-mods"))
	assert_true(dirs.size() >= 6, "fixtures present")
	for name: String in dirs:
		var loader := ContentLoader.new()
		var pack: ContentPack = loader.load_pack(PACK)
		var before: String = pack.content_hash()
		var ok: bool = loader.apply_mod_file(pack, _fixtures("invalid-mods").path_join(name).path_join("mod.json"))
		assert_true(not ok and not loader.errors.is_empty(), "%s should be rejected" % name)
		assert_eq(pack.content_hash(), before, "%s left the pack unchanged" % name)


func test_version_2_pack_exposes_labelled_approximations() -> void:
	var loader := ContentLoader.new()
	var pack: ContentPack = loader.load_pack(_fixtures("valid-packs").path_join("approximations"))
	assert_true(pack != null, "loaded: %s" % loader.errors)
	if pack == null:
		return
	assert_eq(pack.approximations.size(), 2, "approximation count")
	assert_eq(pack.approximations[0], {"subject": "room/r/legend/B", "behaves_as": "solid",
		"original": "breakable block", "task": "WL3-026"})
	assert_true(not pack.approximations[1].has("task"), "task is optional")
	assert_eq((pack.rooms["r"] as RoomData).legend["B"], "solid", "the approximated cell uses a real material")


func test_version_1_hash_is_unaffected_by_approximation_support() -> void:
	var pack: ContentPack = ContentLoader.new().load_pack(PACK)
	assert_true(pack.approximations.is_empty(), "v1 packs carry no approximations")
	assert_eq(pack.content_hash(), "ac9656ac945f182ec775841cd74e1c0de419f83eac86d74a32e83cdceba4549c",
		"recorded synthetic content hash")


func test_invalid_packs_are_rejected() -> void:
	var dirs: PackedStringArray = DirAccess.get_directories_at(_fixtures("invalid-packs"))
	assert_true(dirs.size() >= 11, "fixtures present")
	for name: String in dirs:
		var loader := ContentLoader.new()
		var pack: ContentPack = loader.load_pack(_fixtures("invalid-packs").path_join(name))
		assert_true(pack == null and not loader.errors.is_empty(), "%s should be rejected" % name)


func test_traces_load_and_invalid_traces_are_rejected() -> void:
	var loader := ContentLoader.new()
	var trace: InputTrace = loader.load_trace("res://assets/traces/walk-jump.json")
	assert_true(trace != null, "trace: %s" % loader.errors)
	if trace != null:
		assert_eq(trace.ticks, 220)
		assert_eq(trace.held_at(0), InputBits.RIGHT)
		assert_eq(trace.held_at(136), InputBits.RIGHT | InputBits.A)
		assert_eq(trace.held_at(219), 0)
	for name: String in DirAccess.get_files_at(_fixtures("invalid-traces")):
		var bad := ContentLoader.new()
		assert_true(bad.load_trace(_fixtures("invalid-traces").path_join(name)) == null, "%s should be rejected" % name)


func test_missing_files_fail_clearly() -> void:
	var loader := ContentLoader.new()
	assert_true(loader.load_pack("/nonexistent/wl3pc-pack") == null, "missing pack")
	assert_true(loader.errors.size() > 0 and loader.errors[0].contains("not found"), "message: %s" % loader.errors)
