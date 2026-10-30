"""Compare the original's background on screen with one composed from decoded room graphics (WL3-018).

At chosen frames of a movie, the emulator's screen is compared pixel by pixel with a background
built from the level block map in SRAM, the decoded blocks of the room being played (room_gfx),
and the scroll each scanline was drawn with (PyBoy's screen.tilemap_position_list, with the high
bytes taken from wCameraSCX/SCY). Registers read after the frame are not enough: while the camera
moves they can already hold the next frame's scroll, and OAM the next frame's sprites. So pixels
under any sprite in OAM after this frame or the one before are left out, and only the background
is judged. Colours are compared in the CGB's 5-bit units (PyBoy draws a channel c as c << 3).
Research note: docs/02-research/room-graphics.md.
"""

from __future__ import annotations

from typing import Any

from . import oracle
from .extract import room_gfx, wario_sprites
from .oracle_wario import WARIO_VARIABLES, read_block_rows

R_LCDC = 0xFF40
OAM = 0xFE00
SCREEN_W, SCREEN_H = 160, 144
W_CAMERA_SCY, W_CAMERA_SCX, W_ROOM = 0xCAC4, 0xCAC6, 0xC0C9
W_STATE = 0xC09B  # wState


def nearest_with_low_byte(value: int, low: int) -> int:
    """The 16-bit value nearest `value` whose low byte is `low` (the full scroll behind SCX or SCY)."""
    base = (value & 0xFF00) | low
    return min((base - 0x100, base, base + 0x100), key=lambda v: abs(v - value)) & 0xFFFF


def sprite_mask(pyboy: Any) -> set[tuple[int, int]]:
    """Screen pixels covered by any OAM sprite (8x8, or 8x16 when LCDC bit 2 is set)."""
    tall = pyboy.memory[R_LCDC] & 0x04
    covered: set[tuple[int, int]] = set()
    for i in range(40):
        y, x = pyboy.memory[OAM + 4 * i] - 16, pyboy.memory[OAM + 4 * i + 1] - 8
        for dy in range(16 if tall else 8):
            for dx in range(8):
                if 0 <= x + dx < SCREEN_W and 0 <= y + dy < SCREEN_H:
                    covered.add((x + dx, y + dy))
    return covered


# The room's animation (WL3-037): VRAM bank 1's tiles $70-$77 and the BG palettes.
W_ANIMATED_TILES_GFX, W_ANIMATED_TILES_FRAME = 0xC1AD, 0xC1AE
W_ROOM_PAL_CYCLE, W_ROOM_PAL_CYCLE_INDEX = 0xC1B0, 0xC1B4
ANIMATED_TILES_VRAM = 0x9700  # v1Tiles2 tile $70
ANIMATED_TILES_BYTES = 8 * room_gfx.TILE_BYTES
INIT_ROOM_ANIMATED_PALS = (0x30, 0x4095)
UPDATE_ROOM_ANIMATED_PALS_WRITE = (0x00, 0x2AA6)  # UpdateRoomAnimatedPals.ok: a cycle step is written


def animated_document(document: dict[str, Any], animation: dict[str, Any], gfx: int, frame: int,
                      room_pals: int) -> dict[str, Any]:
    """The room's graphics with tiles $70-$77 of its special tiles from animated-tiles graphics `gfx`
    at `frame` (-1: its own) and RoomPals entry `room_pals` as palettes (-1: its own)."""
    out = dict(document)
    if gfx >= 0:
        special = bytearray.fromhex(document["special_tiles"])
        data = bytes.fromhex(animation["animated_tiles_gfx"][str(gfx)])
        start = room_gfx.ANIMATED_TILES_FIRST * room_gfx.TILE_BYTES
        special[start:start + ANIMATED_TILES_BYTES] = data[frame * ANIMATED_TILES_BYTES:(frame + 1) * ANIMATED_TILES_BYTES]
        out["special_tiles"] = bytes(special).hex()
    if room_pals >= 0:
        out["palettes"] = animation["room_pals"][str(room_pals)]
    return out


def animation_variant(pyboy: Any, document: dict[str, Any], animation: dict[str, Any] | None,
                      pals_written: bool) -> tuple[int, int, int] | str:
    """(gfx, frame, RoomPals entry) the screen should show, -1 for the room's own; or why it cannot
    be told: VRAM's animated tiles must be the frame the RAM names or the room's own."""
    if animation is None:
        return (-1, 0, -1)
    vram = bytes(pyboy.memory[1, ANIMATED_TILES_VRAM:ANIMATED_TILES_VRAM + ANIMATED_TILES_BYTES])
    gfx, frame = pyboy.memory[W_ANIMATED_TILES_GFX], pyboy.memory[W_ANIMATED_TILES_FRAME]
    data = animation["animated_tiles_gfx"].get(str(gfx))
    own = bytes.fromhex(document["special_tiles"])[room_gfx.ANIMATED_TILES_FIRST * room_gfx.TILE_BYTES:][:ANIMATED_TILES_BYTES]
    if data is not None and vram == bytes.fromhex(data)[frame * ANIMATED_TILES_BYTES:(frame + 1) * ANIMATED_TILES_BYTES]:
        tiles = (gfx, frame)
    elif vram == own:
        tiles = (-1, 0)
    else:
        return "VRAM's animated tiles are neither the frame named nor the room's own"
    room_pals = -1
    if pals_written:
        cycle = animation["pal_cycles"][pyboy.memory[W_ROOM_PAL_CYCLE]]
        room_pals = cycle["palettes"][pyboy.memory[W_ROOM_PAL_CYCLE_INDEX]]
    return (tiles[0], tiles[1], room_pals)


def compare_frame(pyboy: Any, rooms: dict[int, dict[str, Any]],
                  previous_sprites: set[tuple[int, int]] | None = None, animation: dict[str, Any] | None = None,
                  pals_written: bool = False) -> dict[str, Any]:
    """Compare the screen just drawn with the composed background (as the room's animation leaves
    it, with `animation`); returns counts and differing tiles."""
    if pyboy.memory[R_LCDC] & 0x10:
        return {"compared": 0, "matched": 0, "skipped": "LCDC selects $8000 tile data (not the level's layout)"}
    room = pyboy.memory[W_ROOM]
    if room not in rooms:
        return {"compared": 0, "matched": 0, "skipped": f"room {room} graphics not decoded"}
    blocks = rooms[room]["blocks"]
    variant = animation_variant(pyboy, rooms[room]["document"], animation, pals_written) if "document" in rooms[room] \
        else (-1, 0, -1)
    if isinstance(variant, str):
        return {"room": room, "compared": 0, "matched": 0, "skipped": variant}
    if variant != (-1, 0, -1):
        variants = rooms[room].setdefault("variants", {})
        if variant not in variants:
            document = animated_document(rooms[room]["document"], animation or {}, *variant)
            variants[variant] = [room_gfx.block_pixels(document, b) for b in range(room_gfx.BLOCKS)]
        blocks = variants[variant]
    lines = pyboy.screen.tilemap_position_list  # per scanline: [SCX, SCY, WX, WY] as drawn
    camera_x16 = oracle.read_value(pyboy, W_CAMERA_SCX, 2)
    camera_y16 = oracle.read_value(pyboy, W_CAMERA_SCY, 2)
    rows = read_block_rows(pyboy)
    screen = pyboy.screen.ndarray  # height x width x RGBA
    covered = sprite_mask(pyboy) | (previous_sprites or set())
    compared = matched = 0
    differing: dict[tuple[int, int], int] = {}
    for py in range(SCREEN_H):
        line_x = nearest_with_low_byte(camera_x16, lines[py][0])
        line_y = nearest_with_low_byte(camera_y16, lines[py][1])
        for px in range(SCREEN_W):
            if (px, py) in covered:
                continue
            lx, ly = (line_x + px) & 0xFFFF, (line_y + py) & 0xFFFF
            row, column = ly >> 4, lx >> 4
            if row >= len(rows) or column >= len(rows[0]):
                continue
            block = rows[row][column] & 0x7F
            expected = blocks[block][(ly & 15) * 16 + (lx & 15)]
            if expected is None:
                continue
            compared += 1
            if tuple(int(screen[py][px][c]) >> 3 for c in range(3)) == expected:
                matched += 1
            else:
                key = (block, ((ly >> 3) & 1) * 2 + ((lx >> 3) & 1))
                differing[key] = differing.get(key, 0) + 1
    first = [nearest_with_low_byte(camera_x16, lines[0][0]), nearest_with_low_byte(camera_y16, lines[0][1])]
    return {"room": room, "camera": first, "compared": compared, "matched": matched, "animation": list(variant),
            "differing_tiles": [{"block": b, "tile": k, "pixels": n} for (b, k), n in sorted(differing.items())]}


def screen_check(rom: bytes, start: dict[str, Any], trace: dict[str, Any], ticks: list[int],
                 room_documents: dict[int, dict[str, Any]], animation: dict[str, Any] | None = None) -> dict[str, Any]:
    """Play `trace` from `start` and compare the screen after each tick in `ticks`; with `animation`
    (rooms/animation.json) as the room's animated tiles and palette cycle leave it."""
    rooms = {room: {"blocks": [room_gfx.block_pixels(doc, b) for b in range(room_gfx.BLOCKS)], "document": doc}
             for room, doc in room_documents.items()}
    pyboy = oracle.start_from(rom, start)
    wanted = set(ticks)
    results: dict[int, dict[str, Any]] = {}
    previous: dict[int, set[tuple[int, int]]] = {}
    pals = {"written": False}  # a palette cycle step since the room loaded

    def on_init_pals(_context: Any) -> None:
        pals["written"] = False

    def on_write_pals(_context: Any) -> None:
        pals["written"] = True

    if animation is not None and hasattr(pyboy, "hook_register"):
        pyboy.hook_register(*INIT_ROOM_ANIMATED_PALS, on_init_pals, None)
        pyboy.hook_register(*UPDATE_ROOM_ANIMATED_PALS_WRITE, on_write_pals, None)

    def after(tick: int) -> None:
        if tick + 1 in wanted:
            previous[tick + 1] = sprite_mask(pyboy)
        if tick in wanted:
            results[tick] = compare_frame(pyboy, rooms, previous.pop(tick, None), animation, pals["written"])

    oracle.play(pyboy, trace, after, render=lambda tick: tick in wanted)
    pyboy.stop(save=False)
    return {"frames": {str(tick): results[tick] for tick in sorted(results)}}


# --- Wario's sprite (WL3-038) ------------------------------------------------------------------

DRAW_WARIO = (0x00, 0x0D9E)  # DrawWario
LEVEL_VBLANK_FUNC = (0x00, 0x0C4C)  # LevelVBlankFunc: tile transfer, scroll, and OAM transfer
SET_WARIO_PAL = (0x00, 0x1AF6)  # SetWarioPal: hl = the palettes; writes OBJ palettes 0-1 at once
W_VIRTUAL_OAM, W_VIRTUAL_OAM_BYTE_SIZE = 0xCC00, 0xC095
R_LY = 0xFF44
ST_LEVEL, SST_UPDATE_LEVEL = 2, 3
TRANSFORMATION_INVISIBLE_WARIO = 0x06
SPRITES_PER_LINE = 10
SNAPSHOT = ("wState", "wSubState", "wWarioFrame", "wWarioAttributes", "wWarioPalsPtr", "wDMASourceBank",
            "wDMASourcePtr", "wWarioOAMBank", "wWarioOAMPtr", "wInvisibleFrame", "wTransformation",
            "wWarioScreenYPos", "wWarioScreenXPos")


def wario_oam_entries(sprites: dict[str, Any], draw: dict[str, int]) -> list[list[int]] | None:
    """The OAM entries LoadSprite writes for a DrawWario snapshot, or None if its table is not decoded."""
    table = sprites["oam_tables"].get(f"{draw['wWarioOAMBank']:02x}:{draw['wWarioOAMPtr']:04x}")
    if table is None or draw["wWarioFrame"] >= len(table["frames"]):
        return None
    return [[(y + draw["wWarioScreenYPos"]) & 0xFF, (x + draw["wWarioScreenXPos"]) & 0xFF, tile,
             attributes ^ draw["wWarioAttributes"]] for y, x, tile, attributes in table["frames"][draw["wWarioFrame"]]]


def drawn(draw: dict[str, int]) -> bool:
    """DrawWario's visibility test (it increments wInvisibleFrame first while invisible)."""
    if draw["wTransformation"] == TRANSFORMATION_INVISIBLE_WARIO:
        return ((draw["wInvisibleFrame"] + 1) & 0b11110010) == 0b11110000
    return draw["wInvisibleFrame"] == 0


def _tile_pair(tiles: bytes, tile: int) -> list[list[int]]:
    size = room_gfx.TILE_BYTES
    return [room_gfx.decode_tile(tiles[n * size:(n + 1) * size]) for n in (tile & 0xFE, tile | 1)]


def compare_wario(pyboy: Any, rooms: dict[int, dict[str, Any]], sprites: dict[str, Any], shown: dict[str, Any],
                  palette_at: Any) -> dict[str, Any]:
    """Compare Wario's pixels on the screen just drawn with his decoded sprite.

    `shown` is the last LevelVBlankFunc before this frame: the virtual OAM it transferred and the
    DrawWario snapshot of the loop before it. Per scanline the first ten sprites in OAM order are
    drawn and the lowest index with an opaque pixel wins (CGB). A pixel is judged where that is one
    of Wario's entries (other sprites' opacity comes from their tiles in VRAM after the frame); a
    BG tile with priority and colour index 1-3 shows instead. Lines where Wario's palette changed
    (SetWarioPal writes the registers at once) are left out.
    """
    draw, oam = shown["draw"], shown["virtual_oam"]
    first = draw["oam_start"] // 4
    count = len(wario_oam_entries(sprites, draw) or [])
    tiles = bytes.fromhex(sprites["tile_sets"][f"{draw['wDMASourceBank']:02x}:{draw['wDMASourcePtr']:04x}"]["tiles"])
    room = pyboy.memory[W_ROOM]
    blocks = rooms[room]["info"] if room in rooms else None
    lines = pyboy.screen.tilemap_position_list
    camera_x16 = oracle.read_value(pyboy, W_CAMERA_SCX, 2)
    camera_y16 = oracle.read_value(pyboy, W_CAMERA_SCY, 2)
    rows = read_block_rows(pyboy)
    screen = pyboy.screen.ndarray
    compared = matched = behind_bg = hidden_by_others = palette_lines = undecoded_palette_lines = 0
    differing: list[list[int]] = []
    pairs: dict[int, list[list[int]]] = {}
    others: dict[tuple[int, int], list[list[int]]] = {}
    by_palette: dict[str, int] = {}
    for py in range(SCREEN_H):
        palette = palette_at(py)
        selected = [i for i in range(40) if 0 <= py - (oam[4 * i] - 16) < 16][:SPRITES_PER_LINE]
        if not any(first <= i < first + count for i in selected):
            continue
        if palette is None:
            palette_lines += 1
            continue
        if f"03:{palette:04x}" not in sprites["palettes"]:
            undecoded_palette_lines += 1
            continue
        colours = sprites["palettes"][f"03:{palette:04x}"]["colours"]
        for px in range(SCREEN_W):
            winner = None
            for i in selected:
                y, x, tile, attributes = oam[4 * i:4 * i + 4]
                if not 0 <= px - (x - 8) < 8:
                    continue
                sx, sy = px - (x - 8), py - (y - 16)
                sx = 7 - sx if attributes & 0x20 else sx
                sy = 15 - sy if attributes & 0x40 else sy
                if not first <= i < first + count:
                    # Another sprite: whether it covers Wario here depends on its own tile, read from VRAM.
                    key = (attributes & 0x08, tile)
                    if key not in others:
                        bank = (attributes >> 3) & 1
                        others[key] = _tile_pair(bytes(pyboy.memory[bank, 0x8000:0x9000]), tile)
                    if others[key][sy // 8][(sy % 8) * 8 + sx] != 0:
                        winner = ("other", i)
                        break
                    continue
                if tile not in pairs:
                    pairs[tile] = _tile_pair(tiles, tile)
                index = pairs[tile][sy // 8][(sy % 8) * 8 + sx]
                if index != 0:
                    winner = ("wario", attributes, index)
                    break
            if winner is None:
                continue
            if winner[0] == "other":
                hidden_by_others += 1
                continue
            expected = tuple(colours[winner[1] & 7][winner[2]])
            if blocks is not None:
                lx = (nearest_with_low_byte(camera_x16, lines[py][0]) + px) & 0xFFFF
                ly = (nearest_with_low_byte(camera_y16, lines[py][1]) + py) & 0xFFFF
                if (ly >> 4) < len(rows) and (lx >> 4) < len(rows[0]):
                    info = blocks[rows[ly >> 4][lx >> 4] & 0x7F][(ly & 15) * 16 + (lx & 15)]
                    if info is not None and info[1] != 0 and (info[2] or winner[1] & 0x80):
                        expected = info[0]
                        behind_bg += 1
            compared += 1
            by_palette[f"{palette:04x}"] = by_palette.get(f"{palette:04x}", 0) + 1
            actual = tuple(int(screen[py][px][c]) >> 3 for c in range(3))
            if actual == expected:
                matched += 1
            elif len(differing) < 8:
                differing.append([px, py, list(expected), list(actual)])
    return {"compared": compared, "matched": matched, "behind_bg": behind_bg, "hidden_by_other_sprites": hidden_by_others,
            "lines_with_a_palette_change": palette_lines, "lines_with_an_undecoded_palette": undecoded_palette_lines,
            "by_palette": by_palette, "differing": differing}


def object_oam_entries(tables: dict[str, Any], slot: bytes) -> list[list[int]] | None:
    """UpdateObjSprite's OAM entries for a slot (32 bytes as WRAM holds them), or None if its table
    is not decoded."""
    key = f"{0x60 | ((slot[0x07] >> 4) & 7):02x}:{slot[0x10] | (slot[0x11] << 8):04x}"
    table = tables.get(key)
    if not isinstance(table, list) or slot[0x0F] >= len(table):
        return None
    return [[(y + slot[0x0D]) & 0xFF, (x + slot[0x0E]) & 0xFF, tile, attributes]
            for y, x, tile, attributes in table[slot[0x0F]]]


# The particles (WL3-042): each ParticleAnim_* draws through LoadParticleSprite from one OAM table of
# bank $03, at the particle's low position bytes plus the OAM offsets, less wSCY/wSCX (or the
# camera's low bytes for one camera configuration), attributes unchanged.
UPDATE_PARTICLES = (0x03, 0x4A26)
W_PARTICLES, PARTICLES_SIZE = 0xCCA0, 0x42
PARTICLE_OAM_TABLES = {**{particle: "520e" for particle in range(0x01, 0x0A)}, 0x0A: "5532", 0x0B: "55ae",
                       0x0C: "562b", 0x0D: "5716", 0x0E: "5763", 0x0F: "57bd", 0x10: "580d", 0x11: "580d",
                       0x12: "580d"}
PARTICLE_CAMERA_CONFIG = 0x3C  # CAM_XSCROLL2 | CAM_TRANSITIONS | CAM_BORDER_RIGHT | CAM_BORDER_LEFT
W_SCY, W_SCX, W_CAMERA_CONFIG_FLAGS, W_WARIO_STATE = 0xC083, 0xC085, 0xC0BA, 0xCA83
WST_BOUNCY_AIRBORNE = 0x92


def drawn_particles(before: bytes, after: bytes, wario_state: int) -> list[tuple[int, bytes]]:
    """(ID, slot as UpdateParticles left it) for each particle it drew: those active when it began
    (a particle that ends this frame is drawn first), but a bouncy jump Wario no longer makes."""
    if before[0x40] == 0:  # wNumParticles: UpdateParticles returns at once
        return []
    drawn_now = []
    for slot in range(4):
        particle = before[16 * slot]
        if particle == 0 or (particle == 0x0A and wario_state != WST_BOUNCY_AIRBORNE):
            continue
        drawn_now.append((particle, after[16 * slot:16 * slot + 16]))
    return drawn_now


def particle_oam_entries(tables: dict[str, Any], particle: int, slot: bytes, scy: int, scx: int) -> list[list[int]] | None:
    """LoadParticleSprite's OAM entries for a particle, or None if its table is not decoded."""
    table = tables.get(PARTICLE_OAM_TABLES.get(particle, ""))
    if not isinstance(table, list) or slot[8] >= len(table):
        return None
    y, x = (slot[3] + 16 - scy) & 0xFF, (slot[5] + 8 - scx) & 0xFF
    return [[(ty + y) & 0xFF, (tx + x) & 0xFF, tile, attributes] for ty, tx, tile, attributes in table[slot[8]]]


def drawn_object_slots(slots: bytes, priority: bool) -> list[bytes]:
    """The slots DrawObjects_NoPriority (priority) or DrawObjects_WithPriority draws, in slot order."""
    wanted = 0x01 | 0x02 | (0x80 if priority else 0)  # ACTIVE, ON_SCREEN, PRIORITY; not INVISIBLE
    return [slots[32 * i:32 * i + 32] for i in range(8) if slots[32 * i] & 0x93 == wanted]


def sprite_check(rom: bytes, start: dict[str, Any], trace: dict[str, Any], sprites: dict[str, Any],
                 room_documents: dict[int, dict[str, Any]], objects: dict[str, Any] | None = None) -> dict[str, Any]:
    """Play `trace` and check Wario's sprite against the decoded tile sets, OAM tables, and palettes.

    At every LevelVBlankFunc after a level loop that drew Wario: the OAM entries LoadSprite wrote
    against the decoded frame (at the index wVirtualOAMByteSize held). After every tick: Wario's
    tiles in VRAM ($8000, bank 0) against the decoded set wDMASourceBank:wDMASourcePtr names, and
    the screen's Wario pixels (compare_wario) where his table and palette are decoded.
    """
    rooms = {room: {"info": [room_gfx.block_pixel_info(doc, b) for b in range(room_gfx.BLOCKS)]}
             for room, doc in room_documents.items()}
    by_name = {name: (address, size) for name, address, size in WARIO_VARIABLES}
    pyboy = oracle.start_from(rom, start)
    now = {"tick": 0, "draw": None}
    shown_by_tick: dict[int, dict[str, Any]] = {}
    palette_changes: list[tuple[int, int, int]] = []  # (tick, LY, palettes)
    oam = {"checked": 0, "matched": 0, "not_decoded": {}, "invisible": 0, "differing": []}
    vram = {"checked": 0, "matched": 0, "not_decoded": 0, "differing_ticks": []}
    screen = {"frames": 0, "compared": 0, "matched": 0, "behind_bg": 0, "hidden_by_other_sprites": 0,
              "lines_with_a_palette_change": 0, "lines_with_an_undecoded_palette": 0, "by_palette": {},
              "hidden_by_table": {}, "palette_changes": 0, "skipped": {}, "differing": []}

    def snapshot() -> dict[str, int]:
        values = {name: oracle.read_value(pyboy, *by_name[name]) for name in SNAPSHOT}
        values["oam_start"] = pyboy.memory[W_VIRTUAL_OAM_BYTE_SIZE]
        return values

    def on_draw(_context: Any) -> None:
        values = snapshot()
        now["draw"] = values if (values["wState"], values["wSubState"]) == (ST_LEVEL, SST_UPDATE_LEVEL) else None

    def on_vblank(_context: Any) -> None:
        draw, now["draw"] = now["draw"], None
        record = {"draw": draw, "virtual_oam": bytes(pyboy.memory[W_VIRTUAL_OAM:W_VIRTUAL_OAM + 0xA0])}
        shown_by_tick[now["tick"]] = record
        check_objects(record)
        if draw is None:
            return
        if not drawn(draw):
            oam["invisible"] += 1
            return
        expected = wario_oam_entries(sprites, draw)
        if expected is None:
            key = f"{draw['wWarioOAMBank']:02x}:{draw['wWarioOAMPtr']:04x}"
            oam["not_decoded"][key] = oam["not_decoded"].get(key, 0) + 1
            return
        first = draw["oam_start"]
        fits = expected[:max(0, (0xA0 - first) // 4)]
        actual = [list(record["virtual_oam"][first + 4 * i:first + 4 * i + 4]) for i in range(len(fits))]
        oam["checked"] += 1
        if actual == fits:
            oam["matched"] += 1
        elif len(oam["differing"]) < 8:
            oam["differing"].append({"tick": now["tick"], "expected": fits, "actual": actual})

    def on_set_pal(_context: Any) -> None:
        palette_changes.append((now["tick"], pyboy.memory[R_LY], pyboy.register_file.HL))

    # Objects: the slots and the particles' share of OAM when DrawObjects_NoPriority starts, and
    # their entries in the transfer that follows (WL3-039).
    tables = (objects or {}).get("object_groups", {}).get("oam_tables", {})
    object_report = {"checked": 0, "matched": 0, "not_decoded": {}, "differing": [], "vram_groups": {}}
    groups = (objects or {}).get("object_groups", {}).get("groups", [])

    particle_tables = (objects or {}).get("particles", {}).get("oam_tables", {})
    particle_report = {"checked": 0, "matched": 0, "not_decoded": {}, "differing": []}

    def on_update_particles(_context: Any) -> None:
        camera = pyboy.memory[W_CAMERA_CONFIG_FLAGS] == PARTICLE_CAMERA_CONFIG
        scy = pyboy.memory[W_CAMERA_SCY + 1] if camera else pyboy.memory[W_SCY]
        scx = pyboy.memory[W_CAMERA_SCX + 1] if camera else pyboy.memory[W_SCX]
        now["particles"] = (bytes(pyboy.memory[W_PARTICLES:W_PARTICLES + PARTICLES_SIZE]), scy, scx,
                            pyboy.memory[W_VIRTUAL_OAM_BYTE_SIZE] // 4)

    def on_draw_objects(_context: Any) -> None:
        before = now.pop("particles", None)
        if before is not None:
            after = bytes(pyboy.memory[W_PARTICLES:W_PARTICLES + PARTICLES_SIZE])
            now["particles_drawn"] = (drawn_particles(before[0], after, pyboy.memory[W_WARIO_STATE]), before[1], before[2],
                                      before[3])
        now["objects"] = (bytes(pyboy.memory[1, 0xD000:0xD100]), pyboy.memory[W_VIRTUAL_OAM_BYTE_SIZE] // 4)
        group = pyboy.memory[0xC0C8]  # wObjectGroup
        if groups and group < len(groups) and f"{group:02x}" not in object_report["vram_groups"]:
            # The enemy graphics in VRAM bank 1 against the group's decoded image, once per group, over
            # the bytes its four slot loads write (a short slot leaves earlier VRAM contents after it).
            vram1 = bytes(pyboy.memory[1, 0x8000:0x8FFF]) + bytes([pyboy.memory[1, 0x8FFF]])
            want = bytes.fromhex(groups[group]["enemy_vram"])
            spans = groups[group].get("enemy_vram_written") or [[0, len(want)]]
            object_report["vram_groups"][f"{group:02x}"] = all(vram1[s:e] == want[s:e] for s, e in spans)

    def on_draw_objects_after_wario(_context: Any) -> None:
        now["after_wario"] = pyboy.memory[W_VIRTUAL_OAM_BYTE_SIZE] // 4

    def check_particles(record: dict[str, Any]) -> None:
        drawn_now = now.pop("particles_drawn", None)
        if drawn_now is None or record["draw"] is None or not particle_tables:
            return
        particles, scy, scx, index = drawn_now
        for particle, slot in particles:
            expected = particle_oam_entries(particle_tables, particle, slot, scy, scx)
            if expected is None:
                key = f"{particle:02x}"
                particle_report["not_decoded"][key] = particle_report["not_decoded"].get(key, 0) + 1
                return  # later entries' places are unknown
            fits = expected[:max(0, 40 - index)]
            actual = [list(record["virtual_oam"][4 * (index + i):4 * (index + i) + 4]) for i in range(len(fits))]
            particle_report["checked"] += 1
            if actual == fits:
                particle_report["matched"] += 1
            elif len(particle_report["differing"]) < 8:
                particle_report["differing"].append({"tick": now["tick"], "particle": particle, "expected": fits,
                                                     "actual": actual})
            index += len(fits)

    def check_objects(record: dict[str, Any]) -> None:
        check_particles(record)
        drawn_now = now.pop("objects", None)
        draw = record["draw"]
        if drawn_now is None or draw is None or not tables:
            return
        slots, index = drawn_now
        after_wario = now.pop("after_wario", None)
        oam_bytes = record["virtual_oam"]
        for priority in (True, False):
            if not priority:
                if after_wario is None:
                    return
                index = after_wario  # where DrawObjects_WithPriority started (after Wario's entries)
            for slot in drawn_object_slots(slots, priority):
                expected = object_oam_entries(tables, slot)
                if expected is None:
                    key = f"{0x60 | ((slot[7] >> 4) & 7):02x}:{slot[0x10] | (slot[0x11] << 8):04x}"
                    object_report["not_decoded"][key] = object_report["not_decoded"].get(key, 0) + 1
                    return  # later entries' places are unknown
                fits = expected[:max(0, 40 - index)]
                actual = [list(oam_bytes[4 * (index + i):4 * (index + i) + 4]) for i in range(len(fits))]
                object_report["checked"] += 1
                if actual == fits:
                    object_report["matched"] += 1
                elif len(object_report["differing"]) < 8:
                    object_report["differing"].append({"tick": now["tick"], "expected": fits, "actual": actual})
                index += len(fits)

    pyboy.hook_register(*DRAW_WARIO, on_draw, None)
    pyboy.hook_register(*LEVEL_VBLANK_FUNC, on_vblank, None)
    pyboy.hook_register(*SET_WARIO_PAL, on_set_pal, None)
    pyboy.hook_register(*UPDATE_PARTICLES, on_update_particles, None)
    pyboy.hook_register(*DRAW_OBJECTS_NO_PRIORITY, on_draw_objects, None)
    pyboy.hook_register(*DRAW_OBJECTS_WITH_PRIORITY, on_draw_objects_after_wario, None)
    last_shown: dict[str, Any] = {"record": None, "tiles": None}
    # Wario's palettes when a frame starts: SetWarioPal and StartRoom both name them in wWarioPalsPtr.
    palettes_at_start = {"value": oracle.read_value(pyboy, *by_name["wWarioPalsPtr"])}

    def palette_lines(tick: int, before: int) -> Any:
        changes = sorted((ly, hl) for t, ly, hl in palette_changes if t == tick and ly < SCREEN_H)

        def palette_at(py: int) -> int | None:
            current = before
            for ly, hl in changes:
                if abs(py - ly) <= 1:
                    return None  # the registers change during or next to this line
                if ly < py:
                    current = hl
            return current
        return palette_at

    def after(tick: int) -> None:
        record = last_shown["record"]  # the last V-Blank transfer before this frame was drawn
        if record is not None and record["draw"] is not None and drawn(record["draw"]):
            draw = record["draw"]
            key = f"{draw['wDMASourceBank']:02x}:{draw['wDMASourcePtr']:04x}"
            reason = None
            if pyboy.memory[W_STATE] != ST_LEVEL:
                reason = "outside the level (the clear screen, overworld, or menus; not ported)"
            elif wario_oam_entries(sprites, draw) is None:
                reason = "OAM table not decoded"
            elif key not in sprites["tile_sets"]:
                reason = "tile set not decoded"
            elif pyboy.memory[W_ROOM] not in rooms:
                reason = "room graphics not decoded"
            elif last_shown["tiles"] != key:
                reason = "VRAM tiles differ from the named set"
            if reason is None:
                result = compare_wario(pyboy, rooms, sprites, record, palette_lines(tick, palettes_at_start["value"]))
                screen["frames"] += 1
                for name in ("compared", "matched", "behind_bg", "hidden_by_other_sprites",
                             "lines_with_a_palette_change", "lines_with_an_undecoded_palette"):
                    screen[name] += result[name]
                for name, n in result["by_palette"].items():
                    screen["by_palette"][name] = screen["by_palette"].get(name, 0) + n
                if result["hidden_by_other_sprites"]:
                    table = f"{draw['wWarioOAMBank']:02x}:{draw['wWarioOAMPtr']:04x}"
                    screen["hidden_by_table"][table] = screen["hidden_by_table"].get(table, 0) + result["hidden_by_other_sprites"]
                if result["differing"] and len(screen["differing"]) < 8:
                    screen["differing"].append({"tick": tick, "pixels": result["differing"]})
            else:
                screen["skipped"][reason] = screen["skipped"].get(reason, 0) + 1
        palettes_at_start["value"] = oracle.read_value(pyboy, *by_name["wWarioPalsPtr"])
        # What the next frame shows: this tick's V-Blank transfer, if the loop finished in time.
        if tick in shown_by_tick:
            last_shown["record"] = shown_by_tick.pop(tick)
            draw = last_shown["record"]["draw"]
            if draw is not None:
                key = f"{draw['wDMASourceBank']:02x}:{draw['wDMASourcePtr']:04x}"
                tiles = bytes(pyboy.memory[0, 0x8000:0x8800])
                if key in sprites["tile_sets"]:
                    vram["checked"] += 1
                    if tiles == bytes.fromhex(sprites["tile_sets"][key]["tiles"]):
                        vram["matched"] += 1
                        last_shown["tiles"] = key
                    else:
                        last_shown["tiles"] = None
                        if len(vram["differing_ticks"]) < 8:
                            vram["differing_ticks"].append(tick)
                else:
                    vram["not_decoded"] += 1
                    last_shown["tiles"] = None
        now["tick"] = tick + 1

    oracle.play(pyboy, trace, after, render=lambda tick: True)
    pyboy.stop(save=False)
    screen["palette_changes"] = len(palette_changes)
    return {"oam": oam, "vram": vram, "screen": screen, "objects": object_report, "particles": particle_report}


# --- The native window against the original's screen ------------------------------------------

def other_sprite_pixels(pyboy: Any, oam: bytes, wario: range | set[int]) -> set[tuple[int, int]]:
    """Screen pixels where a sprite outside `wario` (OAM indices kept) is opaque, per scanline among
    the first ten sprites, with the tiles read from VRAM."""
    covered: set[tuple[int, int]] = set()
    vram = [bytes(pyboy.memory[bank, 0x8000:0x9000]) for bank in (0, 1)]
    for py in range(SCREEN_H):
        for i in [i for i in range(40) if 0 <= py - (oam[4 * i] - 16) < 16][:SPRITES_PER_LINE]:
            if i in wario:
                continue
            y, x, tile, attributes = oam[4 * i:4 * i + 4]
            sy = py - (y - 16)
            sy = 15 - sy if attributes & 0x40 else sy
            pair = _tile_pair(vram[(attributes >> 3) & 1], tile)
            for dx in range(8):
                sx = 7 - dx if attributes & 0x20 else dx
                if 0 <= x - 8 + dx < SCREEN_W and pair[sy // 8][(sy % 8) * 8 + sx] != 0:
                    covered.add((x - 8 + dx, py))
    return covered


DRAW_OBJECTS_NO_PRIORITY = (0x18, 0x564E)  # DrawObjects_NoPriority: the particles are in OAM by now
DRAW_OBJECTS_WITH_PRIORITY = (0x18, 0x56D7)  # DrawObjects_WithPriority: Wario's entries are in by now


def window_check(rom: bytes, start: dict[str, Any], trace: dict[str, Any], shots: dict[int, bytes],
                 sprites: dict[str, Any]) -> dict[str, Any]:
    """Compare the native window's screenshots after given ticks (raw RGB, 160 x 144) with the
    original's screen after the same ticks, in 5-bit colour: every pixel, the background, Wario,
    the objects, and the particles (the OAM entries before the objects: dust, stars)."""
    pyboy = oracle.start_from(rom, start)
    by_name = {name: (address, size) for name, address, size in WARIO_VARIABLES}
    now: dict[str, Any] = {"tick": 0, "draw": None, "shown": None}
    shown_by_tick: dict[int, dict[str, Any]] = {}
    results: dict[int, dict[str, Any]] = {}

    def on_draw(_context: Any) -> None:
        values = {name: oracle.read_value(pyboy, *by_name[name]) for name in SNAPSHOT}
        values["oam_start"] = pyboy.memory[W_VIRTUAL_OAM_BYTE_SIZE]
        now["draw"] = values

    def on_vblank(_context: Any) -> None:
        shown_by_tick[now["tick"]] = {"draw": now["draw"], "particles": now.get("particles", 0),
                                      "virtual_oam": bytes(pyboy.memory[W_VIRTUAL_OAM:W_VIRTUAL_OAM + 0xA0])}
        now["draw"] = None

    def on_draw_objects(_context: Any) -> None:
        now["particles"] = pyboy.memory[W_VIRTUAL_OAM_BYTE_SIZE] // 4

    pyboy.hook_register(*DRAW_WARIO, on_draw, None)
    pyboy.hook_register(*LEVEL_VBLANK_FUNC, on_vblank, None)
    pyboy.hook_register(*DRAW_OBJECTS_NO_PRIORITY, on_draw_objects, None)

    def after(tick: int) -> None:
        if tick in shots:
            shown = now["shown"]
            draw = shown["draw"] if shown is not None else None
            entries = wario_oam_entries(sprites, draw) if draw is not None and drawn(draw) else []
            if shown is None or entries is None:
                results[tick] = {"skipped": "Wario's frame is not decoded"}
            else:
                left_out: set[tuple[int, int]] = set()
                particle_pixels = other_sprite_pixels(pyboy, shown["virtual_oam"], range(shown["particles"], 40))
                first = draw["oam_start"] // 4 if draw is not None else 0
                kept = set(range(shown["particles"])) | set(range(first, first + len(entries)))
                object_pixels = other_sprite_pixels(pyboy, shown["virtual_oam"], kept) - left_out
                screen, shot = pyboy.screen.ndarray, shots[tick]
                compared = matched = 0
                differing: list[list[int]] = []
                for py in range(SCREEN_H):
                    for px in range(SCREEN_W):
                        if (px, py) in left_out:
                            continue
                        compared += 1
                        k = (py * SCREEN_W + px) * 3
                        native = [shot[k] >> 3, shot[k + 1] >> 3, shot[k + 2] >> 3]
                        original = [int(screen[py][px][c]) >> 3 for c in range(3)]
                        if native == original:
                            matched += 1
                        elif len(differing) < 8:
                            differing.append([px, py, native, original])
                results[tick] = {"compared": compared, "matched": matched, "left_out": len(left_out),
                                 "object_pixels": len(object_pixels), "particle_pixels": len(particle_pixels),
                                 "wario_drawn": bool(entries),
                                 "differing": differing}
        if tick in shown_by_tick:
            now["shown"] = shown_by_tick.pop(tick)
        now["tick"] = tick + 1

    oracle.play(pyboy, trace, after, render=lambda tick: tick in shots)
    pyboy.stop(save=False)
    return {"ticks": {str(tick): results[tick] for tick in sorted(results)}}


def route_lead_in(rom: bytes, route: dict[str, Any]) -> tuple[int, int]:
    """(UpdateLevel loops the route runs after its level starts, wGlobalCounter in the first): what a
    native level start needs before the route's end, from UpdateObjects calls in sub-state 3."""
    pyboy = oracle.start_from(rom, route["start"])
    counters: list[int] = []

    def on_objects(_context: Any) -> None:
        if pyboy.memory[0xC09C] == SST_UPDATE_LEVEL:
            counters.append(pyboy.memory[0xC08F])

    pyboy.hook_register(*OBJECT_UPDATE, on_objects, None)
    oracle.play(pyboy, route["input"])
    pyboy.stop(save=False)
    if not counters:
        raise ValueError("the route never reaches UpdateLevel")
    return len(counters), counters[0]


OBJECT_UPDATE = (0x18, 0x5348)  # UpdateObjects
