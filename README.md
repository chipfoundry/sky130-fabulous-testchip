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
> This repository contains a collection of fabrics using the [fabulous-tiles](https://github.com/mole99/fabulous-tiles) tile libraries.

To clone the repository with submodules:
```bash
git clone --recurse-submodules https://github.com/ShekharShwetank/sky130-fabulous-testchip.git
```

---

## 1. Abstract / Executive Summary
The `sky130-fabulous-testchip` project is a high-density, multi-fabric FPGA research vehicle implemented in the SkyWater 130nm (Sky130) process node. It leverages the **FABulous** (Framework for Architecture and Blueprint of Universal Logic) ecosystem to demonstrate the feasibility of embedded FPGA (eFPGA) IP in open-source ASIC flows. The project provides a complete lifecycle—from individual logic tile hardening to full chip-level stitching and automated user-design validation.

## 2. Architecture Overview
The system architecture follows a hierarchical modular approach designed for scalability and physical verification integrity.

| Layer | Component | Description |
| :--- | :--- | :--- |
| **L1: Tile IP** | `ip/fabulous-tiles` | Primitive logic blocks (LUT4, Switch Matrices, IO Blocks). Hardened as GDSII macros using OpenLane. |
| **L2: Fabric** | `fabrics/` | Systematic arrangements of L1 tiles into grids (Small: 24 IO, Medium: 24 IO, Large: 48 IO). |
| **L3: Wrapper** | `src/` | ASIC top-level logic (`chip_top.sv`) providing clock gating, power management, and IO pad mapping. |
| **L4: Toolchain** | `user_designs/` | Synthesis, Place & Route (PnR), and Bitstream generation pipeline for third-party RTL. |

---

## 3. Prerequisites & Dependencies
System requirements are categorized by their role in the implementation lifecycle.

### 3.1. System Level (Host OS)
*   **Operating System**: Linux (Ubuntu 22.04+ recommended).
*   **Environment Manager**: [Nix Package Manager](https://nixos.org/download.html) (Mandatory for toolchain hermeticity).

### 3.2. Application Level (EDA Tools)
*   **Synthesis**: Yosys 0.62+
*   **PnR**: NextPNR-Generic (with FABulous 2.0 uarch support).
*   **Simulation**: Icarus Verilog & Cocotb.
*   **ASIC Flow**: LibreLane & OpenROAD.

---

## 4. Environment Provisioning
Nix is utilized to provision a deterministic development environment, ensuring that all contributors use identical tool versions.

### 4.1. Entering the Development Environment
**Directory**: Root (`/`)
**Environment**: nix-shell
```bash
# Resolve channel dependencies
export NIX_PATH=nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz

# Initialize the hermetic shell
nix-shell
```
> [!NOTE]
> The `--run` or interactive `nix-shell` ensures that all Python dependencies (`pyyaml`, `fasm`) and EDA binaries are available in the `$PATH` without polluting the host system.

---

## 5. Installation & Build Procedure

### 5.1. Stage 1: IP Tile Hardening
Tiles must be physically implemented before fabric assembly.

**Directory**: `ip/fabulous-tiles`
**Environment**: nix-shell

#### Build Options & Examples:
| Goal | Command | Technical Justification |
| :--- | :--- | :--- |
| **Harden All Tiles** | `make all` | Executes the full batch implementation of the selected library. |
| **Specific Tile** | `python3 tiles.py LUT4x8_ha` | Accelerates development by hardening only one primitive (e.g., LUT). |
| **Open in GUI** | `make LUT4x8_ha-openroad` | Launches OpenROAD GUI for physical layout inspection. |
| **View GDS** | `make LUT4x8_ha-klayout` | Opens the final GDSII view in KLayout for DRC/LVS check. |

#### Configuration Variables:
*   `PDK`: `sky130A` (default) or `ihp-sg13g2`.
*   `TILE_LIBRARY`: `classic` (default) - The logic architecture to implement.

```bash
# Transition to IP directory
cd ip/fabulous-tiles

# Generate all tiles for the Sky130A PDK using the 'classic' library
PDK=sky130A TILE_LIBRARY=classic make all
```

---

### 5.2. Stage 2: Fabric Stitching
Aggregating hardened tiles into a routable FPGA grid.

**Directory**: Root (`/`)
**Environment**: nix-shell

#### Fabric Targets:
| Target | Complexity | Build Command |
| :--- | :--- | :--- |
| **Small** | 24 I/O Pins | `make classic_fabric_chipfoundry_small` |
| **Medium**| 24 I/O Pins | `make classic_fabric_chipfoundry_medium` |
| **Large** | 48 I/O Pins | `make classic_fabric_chipfoundry_large` |

#### Visualization:
To inspect the stitched fabric in the ASIC flow:
```bash
# Return to root
cd ../../
# Implement the large fabric macro
make classic_fabric_chipfoundry_large
# Open Large Fabric in OpenROAD
make classic_fabric_chipfoundry_large-openroad
# Open Medium Fabric in KLayout
make classic_fabric_chipfoundry_medium-klayout
```

---

### 5.3. Stage 3: User Design Compilation
Compiling Verilog RTL into a bitstream compatible with the target fabric.

**Directory**: `user_designs/`
**Environment**: nix-shell

#### Manual Compilation Example:
```bash
# Navigate to design directory
cd user_designs/designs/classic/counter

# Compile for a specific fabric size
FABRIC=classic_fabric_chipfoundry_small make clean all
```

#### Automated Validation Suite:
To verify all 12 designs across all 3 fabric sizes (36 unique combinations):
```bash
# Navigate to user design directory
cd user_designs

# Run the comprehensive validation suite (Tests 12 designs across 3 fabrics)
./test_all_fabrics.sh
```

---

## 6. Configuration Matrix
Build behavior is controlled via environment variables.

| Variable | Default | Technical Role |
| :--- | :--- | :--- |
| `PDK` | `sky130A` | Targets the specific Process Design Kit for physical implementation. |
| `FABRIC` | `classic_fabric_10x10` | Defines the grid geometry and IO mapping for bitstream generation. |
| `TILE_LIBRARY` | `classic` | Selects the primitive cell library used during synthesis. |
| `EMULATION` | `None` | If set to a design name, enables accelerated RTL emulation in simulation. |

---

## 7. Simulation & Verification

**Directory**: `tb/`
**Environment**: nix-shell

### 7.1. RTL Verification Modes

#### Accelerated RTL Emulation:
Simulates the fabric with the bitstream pre-loaded into memory (bypasses serial configuration for speed).
```bash
# Directory: tb/
cd tb
export EMULATION=counter
export FABRIC=classic_fabric_chipfoundry_large
python3 fabric_tb.py
```

#### Full Configuration Test:
Simulates the bitstream being uploaded via the configuration interface bit-by-bit.
```bash
unset EMULATION
python3 fabric_tb.py
```

### 7.2. Waveform Inspection
Waveforms are dumped in FST format for analysis in GTKWave.
```bash
# Open waveforms for the last simulation run
gtkwave sim_build/*.fst
```

### 7.3. Common Failure Modes
| Symptom | Cause | Remediation |
| :--- | :--- | :--- |
| `FileNotFoundError: .vh` | Synthesis failure | Check `build_log.txt` in the design directory for unmapped primitives. |
| `nextpnr` Timeout | Routing Congestion | Reduce logic density or increase I/O availability via a larger fabric. |
| `KeyError: clk` | PCF Mismatch | Ensure `generated_constraints.pcf` matches the discovered ports in the synthesis JSON. |
| `Icarus Syntax Error` | Cache Corruption | Execute `rm -rf tb/sim_build` to force a clean compilation. |

---

## 8. Custom Design Implementation
Procedure to implement, verify, and scale a custom RTL design across the FABulous fabrics.

### 1. Environment & Directory Setup
Ensure you are in the root directory and the Nix environment is active.
```bash
# Directory: /
nix-shell
mkdir -p user_designs/designs/classic/my_custom_design
```

### 2. Design Integration
1.  **RTL Source**: Place your Verilog file in the new directory. The top module name must match the filename.
    ```bash
    # File: user_designs/designs/classic/my_custom_design/my_custom_design.v
    # Directory context: user_designs/designs/classic/my_custom_design/
    ```
2.  **Local Makefile**: Create a minimal Makefile to inherit the project's build rules.
    ```makefile
    # File: user_designs/designs/classic/my_custom_design/Makefile
    include ../../../makefile.include
    ```

### Phase 3: Synthesis & Bitstream Generation
Generate the bitstream for your target fabric (e.g., Large).
```bash
# Directory: user_designs/designs/classic/my_custom_adder/
FABRIC=classic_fabric_chipfoundry_large make clean all
```
 
The `make all` target triggers a three-stage pipeline:
- `yosys`: Synthesizes RTL to a JSON netlist using the FABulous techmap.
- `generate_pcf.py`: Automatically discovers ports and maps them to the nearest available fabric I/O pins.
- `nextpnr-generic`: Performs the final Place & Route and generates the `.bit` file.

### Phase 4: Functional Verification (cocotb)
1.  **Create Testbench**: Define your simulation logic in Python.
    ```python
    # File: tb/testcases/classic/my_custom_design.py
    import cocotb
    from ..common import PCF, get_pcf_path, upload_bitstream, fabric, tile_library
    
    @cocotb.test()
    async def test_my_custom_design(dut):
        testname = "my_custom_design"
        pcf = PCF(dut, get_pcf_path(proj_path, fabric, tile_library, testname))
        # ... your test logic here ...
    ```
2.  **Run Fast Emulation**: Verify the logic without waiting for the serial configuration delay.
    ```bash
    # Directory: tb/
    export EMULATION=my_custom_design
    export FABRIC=classic_fabric_chipfoundry_large
    python3 fabric_tb.py
    ```

### 5. Multi-Fabric Validation Sweep
Ensure your design is portable across all fabric sizes offered by the test chip.
```bash
# Directory: user_designs/
./test_all_fabrics.sh my_custom_design

or to test a specific fabric:
./test_all_fabrics.sh --design my_custom_design --fabric large

```
This script will build and verify your design against Small, Medium, and Large fabrics, generating a compatibility report in `build_results.log`.

---

## 9. References
*   [FABulous Project](https://github.com/FPGA-Research-Manchester/FABulous)
*   [fabulous-tiles](https://github.com/mole99/fabulous-tiles)
*   [LibreLane](https://github.com/librelane/librelane)