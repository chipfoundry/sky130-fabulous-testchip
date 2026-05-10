# SPDX-FileCopyrightText: © 2025 Leo Moser <leomoser99@gmail.com>
# SPDX-License-Identifier: Apache-2.0

import os
import re
import math
import random
from pathlib import Path
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer, Edge, RisingEdge, FallingEdge
from cocotb.regression import TestFactory
from cocotb_tools.runner import get_runner
from cocotb.types import LogicArray, Logic

proj_path = Path(__file__).resolve().parent
fabric = os.getenv("FABRIC", "classic_fabric_10x10")

if __name__ == "__main__":

    sim = os.getenv("SIM", "icarus")
    pdk_root = os.getenv("PDK_ROOT", Path("~/.ciel").expanduser())
    pdk = os.getenv("PDK", "sky130A")
    scl = os.getenv("SCL", "sky130A_stdcell")
    gl = os.getenv("GL", None)
    emulation = os.getenv("EMULATION", False)
    tile_library = os.getenv("TILE_LIBRARY", "classic")
    
    tiles_path = Path(proj_path / ".." / "ip" / "fabulous-tiles")
    primitives_path = Path(tiles_path) / "primitives"
    tile_library_path = Path(tiles_path) / "tiles" / tile_library

    primitives_files = list(primitives_path.glob('**/fabulous/*.v'))
    tile_files = list(tile_library_path.glob(f'**/macro/{pdk}/fabulous/*.v'))

    #print(f"Primitive sources: {primitives_files}")
    #print(f"Tile sources: {tile_files}")
    
    sources = []
    defines = {}
    test_filter = None
    
    if emulation:
        vh_file = proj_path / f'../user_designs/designs/{tile_library}/{emulation}/{emulation}.vh'
        if not vh_file.exists():
            print(f"Error: Bitstream header not found at {vh_file}")
            print(f"Make sure to build the design first: FABRIC={fabric} make -C user_designs/designs/{tile_library}/{emulation} all")
            exit(1)
        sources.append(vh_file)
        defines = {"EMULATION": True}
        test_filter = "test_" + emulation
    
    sources.extend(primitives_files)
    sources.extend(tile_files)
    
    # Add models pack
    sources.append(tiles_path / "models_pack.v")

    # Add custom cells
    sources.append(tiles_path / "custom.v")
    
    # Add simulation patches
    sources.append(proj_path / ".." / "src" / "sim_primitives_patch.v")

    # Add fabric netlist
    sources.append(proj_path / f'../fabrics/{fabric}/macro/{pdk}/fabulous/{fabric}.v')

    hdl_toplevel = fabric

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel=hdl_toplevel,
        defines=defines,
        always=True,
        clean=True,
        timescale=("1ns", "1ps"),
        waves=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        test_module="testcases",
        plusargs=['-fst'],
        waves=True,
        test_filter=test_filter,
    )
