"""Decode the hidden figure's fight's drawing data (WL3-052): its graphics, maps, and palettes.

Question: what does the Temple's level (the hidden figure's fight, level $c8) show, and from where?
Evidence (ElectroDeoxys/warioland3 @560fce6, verified byte-identical to the identified ROM): InitLevel's
.final_battle (src/engine/level/init.asm) farcalls LoadHiddenFigureGfx (36:741e,
src/engine/game_over/load_gfx.asm) instead of LCDC_DEFAULT: .LoadPals takes Pals_db000 into wTempPals1
and Pals_db040 (5 palettes) into wTempPals2 from palette 3; .LoadTiles copies $180 tiles of
HiddenFigure2Gfx to VRAM 1's $8000 and of HiddenFigure1Gfx to VRAM 0's $8000 (uncompressed);
.LoadMap decompresses HiddenFigure2Map and HiddenFigure4Map to VRAM 1's BG maps 0 and 1 (the
attributes) and HiddenFigure1Map and HiddenFigure3Map to VRAM 0's (the tiles). The fight's objects
(src/engine/level/objects/hidden_figure.asm, bank $13) write BG palettes 0-5 with SetBGPals:
Func_4cfe0's flash (Pals_4d04b, then Pals_4d01b or Pals_4d07b by w1d15a) and Func_4d005 (Pals_4d01b
or Pals_4d07b). The objects' OAM table (OAM_18c88a, 63:488a) is objects.json's.
Research note: docs/02-research/objects.md (item 85).
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
from .rle import decompress

FORMAT = "wl3pc.temple"
FORMAT_VERSION = 1
EXTRACTOR_VERSION = 1
COMPRESSED = tuple(BankedAddress.parse(text) for text in (
    "36:7068",  # HiddenFigure1Map (VRAM 0's BG map 0: the figure's tiles)
    "36:7193",  # HiddenFigure2Map (VRAM 1's BG map 0: its attributes)
    "36:723b",  # HiddenFigure3Map (VRAM 0's BG map 1: the window's tiles)
    "36:7268",  # HiddenFigure4Map (VRAM 1's BG map 1: the window's attributes)
))
RAW = {
    "36:4000": 0x1800,  # HiddenFigure1Gfx: $180 tiles to VRAM 0's $8000
    "36:5800": 0x1800,  # HiddenFigure2Gfx: $180 tiles to VRAM 1's $8000
}
PALETTES = {
    "36:7000": 0x40,  # Pals_db000 (wTempPals1: the BG palettes)
    "36:7040": 0x28,  # Pals_db040 (wTempPals2's OBJ palettes 3-7)
    "13:501b": 0x30,  # Pals_4d01b (SetBGPals: BG palettes 0-5)
    "13:504b": 0x30,  # Pals_4d04b (Func_4cfe0's flash)
    "13:507b": 0x30,  # Pals_4d07b
}


def decode(rom: bytes) -> dict[str, Any]:
    view = RomView(rom)
    return {"gfx": {"compressed": {str(where): decompress(view, where, 0x2000)[0].hex() for where in COMPRESSED},
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
                       "extractor": "wl3pc.extract.temple", "extractor_version": EXTRACTOR_VERSION,
                       "tools_version": TOOLS_VERSION, "layout_evidence": bf.DISASSEMBLY},
    })
    payload = canonical_json(document)
    target = out_dir / ("exploratory" if is_exploratory else "wl3-original")
    changed = write_immutable(target / "temple.json", payload)
    return {"path": str(target / "temple.json"), "sha256": sha256_bytes(payload), "changed": changed,
            "document": document}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="extract-temple", description=__doc__.splitlines()[0])
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
    print(f"  {len(document['gfx']['raw'])} tile sets, {len(document['gfx']['compressed'])} maps, "
          f"{len(document['gfx']['palettes'])} palette sets")
    return 0


if __name__ == "__main__":
    sys.exit(main())
