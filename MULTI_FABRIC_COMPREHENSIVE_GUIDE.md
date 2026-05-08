# Multi-Fabric FPGA Build System

A comprehensive, end-to-end walkthrough for the `sky130-fabulous-testchip` ecosystem. It covers everything from generating individual logic tiles to validating complex user designs across multiple fabric sizes.

---

## 1. System Overview

The FABulous FPGA flow is divided into three distinct layers:

1.  **Layer 1: IP Generation (Tiles)**: Physical implementation of individual FPGA components (LUTs, Switch Matrices, IO blocks) using OpenLane/OpenROAD.
2.  **Layer 2: Fabric Construction**: Assembling tiles into a grid to create a complete FPGA fabric (Small, Medium, or Large).
3.  **Layer 3: User Design Validation**: Compiling Verilog designs onto the generated fabric to verify functionality, timing, and routing.

---

## 2. Environment Setup (CRITICAL)

This repository uses **Nix** to ensure toolchain consistency. You **must** be inside the Nix environment for any build command to work.

### Entering the Shell
From the root of the repository:
```bash
# Set NIX_PATH if you encounter hostname errors
export NIX_PATH=nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz

# Enter the shell
nix-shell
```

### Verified Tools
- **Yosys 0.62+**: For synthesis.
- **NextPNR-Generic**: For place and route (with FABulous 2.0 support).
- **OpenLane 2 / OpenROAD**: For tile hardening.
- **Python 3.13+**: With `pyyaml` and `fasm` libraries.

---

## 3. Stage 1: IP & Tile Generation

Before a fabric can be built, the individual tiles must be hardened (GDS generation).

### Building Logic Tiles
Tiles are managed in `ip/fabulous-tiles`. You can build all tiles or specific ones.

**Build all tiles for Sky130:**
```bash
cd ip/fabulous-tiles
PDK=sky130A TILE_LIBRARY=classic make all
```

**Build a specific tile (e.g., W_TT_IF2):**
```bash
PDK=sky130A TILE_LIBRARY=classic python3 tiles.py W_TT_IF2
```

### Verification (DRC/LVS)
The tile generation flow automatically runs a full manufacturability report at the end (Stage 71).
- ✅ **Antenna**: Checks for charge accumulation during manufacturing.
- ✅ **LVS (Layout vs Schematic)**: Ensures the physical gates match the Verilog netlist.
- ✅ **DRC (Design Rule Check)**: Ensures the layout follows Sky130 manufacturing rules.

**Viewing results:**
Logs and reports are saved in `ip/fabulous-tiles/tiles/classic/<TILE_NAME>/runs/RUN_<DATE>/`.

---

## 4. Stage 2: Fabric Construction

A "Fabric" is a grid of tiles defined by a CSV file.

### Fabric Definitions
- **Small**: `fabrics/classic_fabric_chipfoundry_small/`
- **Medium**: `fabrics/classic_fabric_chipfoundry_medium/`
- **Large**: `fabrics/classic_fabric_chipfoundry_large/`

Each directory contains a `.csv` file defining the tile grid. The build system uses these CSVs to determine where I/O pins and logic blocks are located.

---

## 5. Stage 3: User Design Validation

This is where you test your RTL designs on the FPGA.

### Step 1: Manual Design Build
Navigate to a specific design and specify the target fabric.

```bash
cd user_designs/designs/classic/counter
FABRIC=classic_fabric_chipfoundry_small make clean all
```

### Step 2: The Intelligent PCF System
Our system features an **Auto-Discovery PCF Generator**. You no longer need to manually write pin constraints.
1.  **Discovery**: It reads your synthesized `.json` to find ports (e.g., `clk`, `a[7:0]`).
2.  **Extraction**: It reads the Fabric CSV to find available IO pads.
3.  **Mapping**: It generates `generated_constraints.pcf` automatically.

### Step 3: Running the Full Test Suite
To verify all 12 designs across all 3 fabrics (36 combinations):

```bash
cd user_designs
./test_all_fabrics.sh
```

**Understanding the Matrix Output:**
- **PASS (P)**: Fully built and routed.
- **SKIP (S)**: Skipped because the design needs more I/O pins than the fabric provides (e.g., 28 pins needed, 24 available).
- **FAIL (F)**: Build failed or timed out.
- **TIMEOUT**: Design is too complex to route on that fabric without hard macros (e.g., `register_file`).

---

## 6. Advanced Debugging

### Viewing Detailed Build Logs
If a design fails in the automated suite, you can inspect the full log:
`user_designs/designs/classic/<DESIGN>/build_log.txt`

### Common Failure: IHP SRAM
The `ihp_sram_1024x32_1rw` design will fail unless you have the IHP PDK libraries. It instantiates a black-box memory block that the generic Sky130 flow cannot synthesize.

### Tuning the Build
You can adjust the timeout in `test_all_fabrics.sh` if you have a slow machine or extremely complex designs:
```bash
# Change to 5 minutes for massive designs
FABRIC="$fabric" TILE_LIBRARY="$TILE_LIBRARY" timeout 300s make clean all ...
```

---

## 7. Adding New Content

- **New Design**: Add a folder in `user_designs/designs/classic/`. Copy the `Makefile` from `counter`.
- **New Tile**: Add the tile logic to `ip/fabulous-tiles/tiles/` and update `tiles.py`.
- **New Fabric**: Create a new folder in `fabrics/` with a grid CSV.

---

*Ensure all toolchains are updated via the provided Nix configurations.*
