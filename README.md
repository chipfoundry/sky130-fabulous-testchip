# sky130 FABulous Test Chip

A test chip with three FABulous FPGA fabrics (Small, Medium, and Large).

<p align="center">
  <a href="img/chip_top.png">
    <img src="img/chip_top.png" alt="chip layout" width=35%>
  </a>
</p>

> [!NOTE]
> To build the chip, enable the following PDK version using ciel: `d815bb30c9afdf9e264c276a8a2b533108dea3d0`
> In addition, the following LibreLane branch must be used: `nix shell github:librelane/librelane/leo/padring-orientation`

---

## 1. System Overview

The FABulous FPGA flow in this repository is divided into three distinct layers:

1.  **Layer 1: IP Generation (Tiles)**: Physical implementation of individual FPGA components (LUTs, Switch Matrices, IO blocks) using OpenLane/OpenROAD.
2.  **Layer 2: Fabric Construction**: Assembling tiles into a grid to create a complete FPGA fabric.
3.  **Layer 3: User Design Validation**: Compiling Verilog designs onto the generated fabric to verify functionality, timing, and routing.

---

## 2. Requirements & Setup

### Clone with Submodules
This repository contains a collection of fabrics using the [fabulous-tiles](https://github.com/mole99/fabulous-tiles) tile libraries.
```bash
git clone --recurse-submodules https://github.com/ShekharShwetank/sky130-fabulous-testchip.git
```

### Environment Setup (Nix)
This project uses **Nix** to ensure toolchain consistency. 
```bash
# Set NIX_PATH if you encounter hostname/download errors
export NIX_PATH=nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz

# Enter the shell
nix-shell
```

---

## 3. Stage 1: IP & Tile Generation

Before a fabric can be built, the individual tiles must be hardened.
Tiles are managed in `ip/fabulous-tiles`. 

**Build all tiles for Sky130:**
```bash
cd ip/fabulous-tiles
PDK=sky130A TILE_LIBRARY=classic make all
```

**Verify Tiles (DRC/LVS):**
The flow automatically runs Stage 71 (Manufacturability Report) to verify Antenna, LVS, and DRC status. Results are saved in `ip/fabulous-tiles/tiles/classic/<TILE_NAME>/runs/`.

---

## 4. Stage 2: Stitch the Fabrics

Once the tiles are implemented, you can stitch them into a full fabric. Current fabrics under `fabrics/` include:
- `classic_fabric_chipfoundry_small` (24 I/O pins)
- `classic_fabric_chipfoundry_medium` (24 I/O pins)
- `classic_fabric_chipfoundry_large` (48 I/O pins)

**Implement all fabrics:**
```bash
make all
```

**Implement a single fabric:**
```bash
make classic_fabric_chipfoundry_large
```

---

## 5. Stage 3: Implement User Designs (Step-by-Step)

Our system features an **Auto-Discovery PCF Generator**. You no longer need to manually write pin constraints for different fabrics.

### Step 1: Build a Specific Design
Navigate to a design directory and specify the target fabric:
```bash
cd user_designs/designs/classic/counter
FABRIC=classic_fabric_chipfoundry_small make clean all
```

### Step 2: Automated Validation Suite
To verify 12 different designs across all 3 fabric sizes (36 combinations total):
```bash
cd user_designs
./test_all_fabrics.sh
```

### Understanding the Results:
- **PASS (P)**: Fully built and routed.
- **SKIP (S)**: Design needs more I/O pins than the fabric provides (e.g., 28 pins needed, 24 available).
- **FAIL (F)**: Build failed or timed out.
- **TIMEOUT**: Design is too complex to route on that fabric without hard macros (e.g., `register_file`).

---

## 6. Simulate the Fabric

After generating the bitstreams, you can simulate the fabric using cocotb.

#### RTL "Emulation" (Fast)
Initializes the fabric bits with the bitstream for faster simulation.
```bash
export EMULATE=counter
cd tb; python3 fabric_tb.py
```

#### RTL Simulation (Full)
Runs all available test cases for the selected fabric.
```bash
cd tb; python3 fabric_tb.py
```

---

## 7. Advanced Debugging

### Viewing Detailed Build Logs
If a design fails in the automated suite, inspect the full log here:
`user_designs/designs/classic/<DESIGN>/build_log.txt`

### Common Failure: IHP SRAM
The `ihp_sram_1024x32_1rw` design requires the IHP PDK libraries. It will fail in the generic Sky130 flow as it instantiates a PDK-specific black-box.

---

*Ensure all toolchains are updated via the provided Nix configurations.*
