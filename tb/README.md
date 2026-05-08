# FABulous Fabric Simulation Suite

This directory contains the [cocotb](https://www.cocotb.org/)-based simulation environment for the FABulous FPGA fabrics.

## 1. Running Simulations

### Prerequisites
Ensure you are in the Nix environment:
```bash
nix-shell
```

### RTL Emulation Mode (Recommended)
This mode loads a pre-compiled bitstream into the fabric's configuration memory at the start of simulation. It is much faster than the full configuration flow.

```bash
export PDK=sky130A
export FABRIC=classic_fabric_chipfoundry_large
export TILE_LIBRARY=classic
export EMULATION=counter

python3 fabric_tb.py
```

### Full RTL Simulation
To test the entire configuration flow (uploading the bitstream bit-by-bit), unset the `EMULATION` variable:
```bash
unset EMULATION
python3 fabric_tb.py
```

## 2. Recent Validation Results (Large Fabric)

**Environment**: Sky130A PDK | `classic_fabric_chipfoundry_large`

| Testcase | Status | Notes |
| :--- | :--- | :--- |
| `all_ones` | PASS | Verified with dynamic PCF mapping |
| `all_zeros` | PASS | |
| `passthrough` | PASS | |
| `addition` | PASS | |
| `counter` | PASS | |
| `multiplication`| PASS | |
| `macc_8x8_20` | PASS | |
| `ram_32x4_2r_1w`| PASS | |
| `sys_reset` | PASS | |
| `register_file` | FAIL | Missing BRAM/RegFile Hard Macros in logic-only fabric |

## 3. Technical Findings

### Why do some tests fail?
- **PDK Mismatches**: Designs like `ihp_sram` are hard-coded for the IHP SG13G2 PDK and will not synthesize correctly for Sky130A without modification.
- **Architectural Limits**: The `register_file` design is too dense to be built solely out of logic LUTs (Distributed RAM). To fix this, a fabric grid containing dedicated Memory Tiles (BRAM) must be used.
- **Bitstream Errors**: If a simulation fails with a "Bitstream not found" error, ensure the user design has been successfully built for the target fabric in the `user_designs/` directory.

### Intelligent Pin Mapping
The simulation suite is integrated with the **Auto-Discovery PCF Generator**. It automatically looks for a `generated_constraints.pcf` in the design directory to ensure the simulation stimuli match the physical bitstream mapping.

---
*Maintained as part of the Multi-Fabric Build System stabilization.*
