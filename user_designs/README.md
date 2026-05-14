# FABulous User Design Harness

This directory provides the infrastructure for synthesizing, routing, and generating bitstreams for RTL designs targeting FABulous-based FPGA fabrics.

## 1. Directory Structure
*   `designs/`: Subdirectories categorized by tile architecture (e.g., `classic/`).
*   `scripts/`: Python-based automation for PCF generation and bitstream assembly.
*   `makefile.include`: Unified build rules inherited by all design subdirectories.

## 2. Implementation Pipeline

### 2.1. Prerequisites
The environment relies on specialized forks of Yosys and NextPNR. Access them via the Nix shell:
```bash
# Directory: user_designs/
nix develop # (or nix-shell)
```
**Note:** To generate the bitstreams you need to `pip3 install fasm`.

### 2.2. Targeted Multi-Fabric Validation
The `test_all_fabrics.sh` script automates the validation of designs across the entire fabric ecosystem (Small, Medium, and Large).

| Command | Technical Role |
| :--- | :--- |
| `./test_all_fabrics.sh` | Executes the full 36-test validation matrix. |
| `./test_all_fabrics.sh --design <NAME>` | Verifies a specific design across all three fabrics. |
| `./test_all_fabrics.sh --design <NAME> --fabric <SIZE>` | Targeted verification for a single design/fabric combination. |

### 2.3. Manual Build Process
Builds can be executed at the harness level or inside individual design directories.

**Global Environment Variables**:
| Variable | Default | Description |
| :--- | :--- | :--- |
| `FABRIC` | `classic_fabric_10x10` | Geometry target for bitstream mapping. |
| `TILE_LIBRARY`| `classic` | Primitive library selection. |

**Command Examples**:
```bash
# Build counter for Medium fabric
FABRIC=classic_fabric_chipfoundry_medium make counter

# Clean and rebuild addition for Large fabric
FABRIC=classic_fabric_chipfoundry_large make addition-clean addition
```

The following Make targets are available:

```
make counter-clean
make counter-synth
make counter-pnr
make counter-bit
make counter-hex
```

You can also enter the individual design directories and run make from there:

```
Commands:
 synth           ... Synthesize the user design
 pnr             ... Run Place and Route
 bitstream       ... Generate the bitstream
 clean           ... Delete all generated files
 help            ... Show this help message
```

## 3. Automated Constraints
The build system integrates the **Intelligent PCF Generator** (`scripts/generate_pcf.py`). This tool eliminates manual pin-mapping errors by:
1.  **Parsing Port Metadata**: Extracting exact bus widths from the Yosys synthesis JSON.
2.  **Strategic Mapping**: Assigning high-speed signals (clocks) to pins near Global Buffer (GBUF) tiles.
3.  **Conflict Resolution**: Using unique prefixes (`io[N]`) for generic pin-fill to prevent collisions with user RTL names during simulation.