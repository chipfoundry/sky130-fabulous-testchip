# FABulous Fabric Simulation Suite

This directory contains the [cocotb](https://www.cocotb.org/)-based simulation environment for verifying RTL designs on FABulous FPGA fabrics.

## 1. Verification Methodologies

### 1.1. RTL Emulation Mode (Accelerated)
Loads a pre-compiled bitstream directly into the fabric's configuration memory at `t=0`.
```bash
# Directory: tb/
export PDK=sky130A
export FABRIC=classic_fabric_chipfoundry_large
export TILE_LIBRARY=classic
export EMULATION=counter

python3 fabric_tb.py
```
> Accelerates functional verification of user logic by bypassing the multi-millisecond serial bitstream configuration phase.

### 1.2. Full RTL Simulation (Gate-Level Accuracy)
Tests the entire serial configuration interface and the internal configuration chain.
```bash
unset EMULATION
python3 fabric_tb.py
```
> Required to verify the integrity of the FPGA's configuration logic and serial clock-data synchronization.

## 2. Validation Benchmarks (Large Fabric)

**Reference Configuration**: Sky130A PDK | `classic_fabric_chipfoundry_large`

| Testcase | Status | Verification Note |
| :--- | :--- | :--- |
| `all_ones` | PASS | Verified with dynamic 48-pin PCF mapping. |
| `all_zeros` | PASS | |
| `passthrough` | PASS | |
| `addition` | PASS | |
| `counter` | PASS | |
| `multiplication`| PASS | |
| `macc_8x8_20` | PASS | |
| `ram_32x4_2r_1w`| PASS | |
| `sys_reset` | PASS | |
| `register_file` | FAIL | Routing timeout due to logic density (Missing Hard Macros). |

## 3. Technical Findings & Root Causes

### 3.1. Design Scaling Limits
- **PDK Compatibility**: Designs hard-coded for non-Sky130 primitives (e.g., IHP SRAM) will fail synthesis.
- **Architectural Constraints**: Large memories (`register_file`) cannot be built efficiently from LUTs. A fabric grid containing dedicated BRAM tiles is required for closure.

### 3.2. Automated Constraints Synchronization
The testbench utilizes a **Dynamic PCF Discovery** helper. It automatically parses `generated_constraints.pcf` from the design directory to ensure that simulation signals are applied to the exact physical pins mapped during the build stage.

---