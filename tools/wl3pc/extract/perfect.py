"""Decode the Perfect screen's data (WL3-052): its frameset, OAM table, palettes, graphics, and maps.

Question: what does the Perfect screen, after a perfect game's credits, load?
Evidence (ElectroDeoxys/warioland3 @560fce6, verified byte-identical to the identified ROM): the screen
runs in _PerfectStateTable (37:4000, src/engine/perfect/state_table.asm) in bank $37.
InitPerfectScreen (src/engine/perfect/core.asm) calls LoadPerfectPals, which loads Pals_dc173 and
Pals_dc1fb into the temporary palette sets; LoadPerfectGfx decompresses PerfectGfx to VRAM 0's $8000,
and Func_dc13e PerfectAttrmap and PerfectTilemap to BG map 0 (all with Decompress). UpdatePerfectScreen
cycles wTempPals1's palettes 5-7 through Pals_dc1b3, Pals_dc1cb, and Pals_dc1e3 (3 palettes each) and
back to Pals_dc173's (Func_dc101 to Func_dc125). Its one object (wMenuObj1) is animated with
UpdateObjAnim in bank $37 (Frameset_dd848) and drawn by Func_dc158 (OAM_dd710).
Research note: docs/02-research/perfect.md.
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

FORMAT = "wl3pc.perfect"
FORMAT_VERSION = 1
EXTRACTOR_VERSION = 1
# The object's frameset (Frameset_dd848, bank $37).
FRAMESETS = (BankedAddress.parse("37:5848"),)
OAM_TABLES = (BankedAddress.parse("37:5710"),)  # OAM_dd710 (Func_dc158)
COMPRESSED = tuple(BankedAddress.parse(text) for text in (
    "37:423b",  # PerfectGfx (to VRAM 0's $8000)
    "37:5417",  # PerfectTilemap (BG map 0)
    "37:55b5",  # PerfectAttrmap (BG map 0's attributes)
))
PALETTES = {
    "37:4173": 0x40,  # Pals_dc173 (wTempPals1; its palettes 5-7 again by Func_dc101)
    "37:41b3": 0x18,  # Pals_dc1b3 (Func_dc10d: wTempPals1's palettes 5-7)
    "37:41cb": 0x18,  # Pals_dc1cb (Func_dc119)
    "37:41e3": 0x18,  # Pals_dc1e3 (Func_dc125)
    "37:41fb": 0x40,  # Pals_dc1fb (wTempPals2)
}


def decode(rom: bytes) -> dict[str, Any]:
    view = RomView(rom)
    return {"framesets": {str(where): decode_frameset(view, where) for where in FRAMESETS},
            "oam_tables": {str(where): decode_oam_table(view, where) for where in OAM_TABLES},
            "gfx": {"compressed": {str(where): decompress(view, where, 0x2000)[0].hex() for where in COMPRESSED},
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
                       "extractor": "wl3pc.extract.perfect", "extractor_version": EXTRACTOR_VERSION,
                       "tools_version": TOOLS_VERSION, "layout_evidence": bf.DISASSEMBLY},
    })
    payload = canonical_json(document)
    target = out_dir / ("exploratory" if is_exploratory else "wl3-original")
    changed = write_immutable(target / "perfect.json", payload)
    return {"path": str(target / "perfect.json"), "sha256": sha256_bytes(payload), "changed": changed,
            "document": document}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="extract-perfect", description=__doc__.splitlines()[0])
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
    print(f"  {len(document['framesets'])} frameset, {len(document['oam_tables'])} OAM table, "
          f"{len(document['gfx']['compressed'])} compressed graphics and maps")
    return 0


if __name__ == "__main__":
    sys.exit(main())
