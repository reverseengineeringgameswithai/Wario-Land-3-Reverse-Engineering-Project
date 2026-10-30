class_name SimRunner
extends RefCounted
## Runs a tick-indexed input trace headlessly and summarises the result.


static func run_trace(pack: ContentPack, trace: InputTrace) -> Dictionary:
	var room: RoomData = pack.rooms[pack.start_room]
	var grid: CollisionGrid = room.build_grid()
	var state: PlayerState = pack.initial_state()
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	for tick: int in trace.ticks:
		PlayerSim.step(state, trace.held_at(tick), grid, pack.movement)
		hashing.update(JSON.stringify(state.snapshot(), "", true).to_utf8_buffer())
	return {
		"pack": pack.id,
		"mods": Array(pack.applied_mods),
		"content_sha256": pack.content_hash(),
		"ticks": trace.ticks,
		"final": state.snapshot(),
		"state_stream_sha256": hashing.finish().hex_encode(),
		"provisional_movement": pack.movement.provisional,
	}
