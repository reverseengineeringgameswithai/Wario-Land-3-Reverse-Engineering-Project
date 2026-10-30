"""Decode the game over screen's data (WL3-052): its framesets, OAM tables, palettes, graphics, and maps.

Question: what does the game over screen, after the hidden figure's fight is lost and the map's save
screen, load?
Evidence (ElectroDeoxys/warioland3 @560fce6, verified byte-identical to the identified ROM): the screen
runs in _GameOverStateTable (36:7277, src/engine/game_over/state_table.asm) in bank $36.
InitGameOverScreen (src/engine/game_over/core.asm) calls LoadGameOverPals (load_gfx.asm), which loads
Pals_db509 and Pals_db549 into the temporary palette sets and copies one palette of Pals_86ad5 (bank
$21) over wTempPals2's first; LoadGameOverGfx decompresses GameOverGfx to VRAM 0's $8000 and copies $80
tiles of WarioSleepGfx (76:6800, uncompressed) over its start; Func_db4cf decompresses GameOverAttrmap
and GameOverTilemap to BG map 0 (all with Decompress). Wario is animated with UpdateObjAnim in bank $2a
(Frameset_aaccb, then Frameset_aace2 after A) and drawn by LoadGameOverSprite (OAM_aab5c, bank $2a,
src/home/load_game_over_sprite.asm); the text object (wMenuObj1) with Frameset_dbbf5 in bank $36, drawn
by Func_db4e9 (OAM_dbbd2).
Research note: docs/02-research/game-over.md.
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
from .block_functions import MalformedDataError
from .clear import decode_oam_table
from .golf import decode_frameset
from .rle import decompress

FORMAT = "wl3pc.game_over"
FORMAT_VERSION = 1
EXTRACTOR_VERSION = 1
# Wario's framesets (Frameset_aaccb asleep, Frameset_aace2 waking; bank $2a) and the text's
# (Frameset_dbbf5, bank $36).
FRAMESETS = tuple(BankedAddress.parse(text) for text in ("2a:6ccb", "2a:6ce2", "36:7bf5"))
OAM_TABLES = tuple(BankedAddress.parse(text) for text in (
    "2a:6b5c",  # OAM_aab5c (LoadGameOverSprite: Wario)
    "36:7bd2",  # OAM_dbbd2 (Func_db4e9: the text)
))
COMPRESSED = tuple(BankedAddress.parse(text) for text in (
    "36:7589",  # GameOverGfx (to VRAM 0's $8000)
    "36:7aee",  # GameOverTilemap (BG map 0)
    "36:7b8f",  # GameOverAttrmap (BG map 0's attributes)
))
RAW = {
    "76:6800": 0x800,  # WarioSleepGfx: the $80 tiles LoadGameOverGfx copies to VRAM 0's $8000
}
PALETTES = {
    "36:7509": 0x40,  # Pals_db509 (wTempPals1)
    "36:7549": 0x40,  # Pals_db549 (wTempPals2)
    "21:6ad5": 0x08,  # Pals_86ad5 (one palette, over wTempPals2's first)
}


def decode(rom: bytes) -> dict[str, Any]:
    view = RomView(rom)
    return {"framesets": {str(where): decode_frameset(view, where) for where in FRAMESETS},
            "oam_tables": {str(where): decode_oam_table(view, where) for where in OAM_TABLES},
            "gfx": {"compressed": {str(where): decompress(view, where, 0x2000)[0].hex() for where in COMPRESSED},
                    "raw": {key: view.read_banked(BankedAddress.parse(key), size).hex() for key, size in RAW.items()},
                    "palettes": {key: view.read_banked(BankedAddress.parse(key), size).hex()
                                 for key, size in PALETTES.items()}}}


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
                       "extractor": "wl3pc.extract.game_over", "extractor_version": EXTRACTOR_VERSION,
                       "tools_version": TOOLS_VERSION, "layout_evidence": bf.DISASSEMBLY},
    })
    payload = canonical_json(document)
    target = out_dir / ("exploratory" if is_exploratory else "wl3-original")
    changed = write_immutable(target / "game_over.json", payload)
    return {"path": str(target / "game_over.json"), "sha256": sha256_bytes(payload), "changed": changed,
            "document": document}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="extract-game-over", description=__doc__.splitlines()[0])
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
    document = result["document"]
    print(f"wrote {result['path']} ({'updated' if result['changed'] else 'unchanged'}) sha256 {result['sha256']}")
    print(f"  {len(document['framesets'])} framesets, {len(document['oam_tables'])} OAM tables, "
          f"{len(document['gfx']['compressed'])} compressed graphics and maps")
    return 0


if __name__ == "__main__":
    sys.exit(main())
