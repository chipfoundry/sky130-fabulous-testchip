#!/usr/bin/env python3
"""
Auto-generate PCF constraint files for different fabric sizes.

This script parses a fabric CSV to discover available I/O locations, then
generates a PCF file that assigns top-level ports to available I/O pins
in a consistent, portable manner across all fabrics.

Usage:
    # Basic indexed mapping (all[N])
    python3 generate_pcf.py <fabric_csv> <output_pcf>
    
    # Intelligent port discovery (requires synthesized JSON)
    python3 generate_pcf.py <fabric_csv> <design_json> <output_pcf>
"""

import sys
import csv
import json
from pathlib import Path


def parse_fabric_csv(csv_path):
    """
    Parse a grid-style FABulous fabric CSV to find I/O tiles and coordinates.
    """
    grid = []
    in_fabric = False
    with open(csv_path, 'r') as f:
        for line in f:
            line = line.strip()
            if not line: continue
            if line.startswith("FabricBegin"):
                in_fabric = True
                continue
            if line.startswith("FabricEnd") or line.startswith("ParametersBegin"):
                in_fabric = False
                break
            if in_fabric:
                grid.append(line.split(','))

    if not grid:
        print(f"Error: No fabric grid found in {csv_path}")
        sys.exit(1)

    total_rows = len(grid)
    io_list = []
    
    for r_idx, row in enumerate(grid):
        # Y coordinate typically decreases as we move down the CSV rows
        y_coord = total_rows - 1 - r_idx
        for c_idx, tile_type in enumerate(row):
            if 'IO' in tile_type:
                x_coord = c_idx
                # Each IO tile has A and B ports
                for pin in ['A', 'B']:
                    io_list.append((str(x_coord), str(y_coord), pin))

    # Sort IOs to have a deterministic mapping (X then Y then Port)
    io_list.sort(key=lambda x: (int(x[0]), int(x[1]), x[2]))
    return io_list


def discover_ports(design_json):
    """
    Load top module ports from synthesized JSON.
    """
    if not Path(design_json).exists():
        print(f"Warning: Design JSON {design_json} not found. Falling back to indexed mapping.")
        return None, [], []
        
    with open(design_json, 'r') as f:
        data = json.load(f)
    
    top_module_name = None
    for name, mod in data['modules'].items():
        if mod.get('attributes', {}).get('top'):
            top_module_name = name
            break
    if not top_module_name:
        for name in data['modules']:
            if not name.startswith('$'):
                top_module_name = name
                break
    if not top_module_name:
        top_module_name = list(data['modules'].keys())[0]

    ports = data['modules'][top_module_name]['ports']
    
    clk_signals = []
    other_signals = []
    
    sorted_port_names = sorted(ports.keys())
    for port_name in sorted_port_names:
        port = ports[port_name]
        bits = port['bits']
        if len(bits) == 1:
            if port_name in ['clk', 'clk1', 'clk2']:
                clk_signals.append(port_name)
            else:
                other_signals.append(port_name)
        else:
            for i in range(len(bits)):
                other_signals.append(f"{port_name}[{i}]")
                
    return top_module_name, clk_signals, other_signals


def generate_pcf(fabric_csv, output_pcf, design_json=None):
    """
    Generate the PCF file.
    """
    io_list = parse_fabric_csv(fabric_csv)
    print(f"Found {len(io_list)} available I/O pins")

    pcf_lines = [
        f"# Auto-generated PCF for {Path(fabric_csv).stem}",
        f"# Total available I/O pins: {len(io_list)}",
        ""
    ]

    pool = io_list.copy()

    if design_json:
        top_name, clk_sigs, other_sigs = discover_ports(design_json)
        if top_name:
            print(f"Discovered ports for module: {top_name}")
            
            # Mapping clocks near GBUF (Top/Right-ish)
            clk_pool = sorted(pool, key=lambda x: (int(x[1]), int(x[0])), reverse=True)
            for sig in sorted(clk_sigs):
                if clk_pool:
                    pin = clk_pool.pop(0)
                    pcf_lines.append(f"set_io {sig} X{pin[0]}Y{pin[1]}/{pin[2]}")
                    pool.remove(pin)
            
            # Mapping other signals
            for i, sig in enumerate(other_sigs):
                if i < len(pool):
                    pin = pool[i]
                    pcf_lines.append(f"set_io {sig} X{pin[0]}Y{pin[1]}/{pin[2]}")
                else:
                    print(f"Warning: Not enough pins for {sig}")
    
    # Always include indexed all[N] mapping for compatibility (if not already used)
    pcf_lines.append("\n# Indexed I/O assignments (fallback/generic)")
    existing_ios = set()
    if design_json:
        # Extract names already in pcf_lines
        import re
        for line in pcf_lines:
            m = re.match(r"set_io\s+([\w\[\]\.]+)", line)
            if m:
                existing_ios.add(m.group(1))

    for i, (x, y, p) in enumerate(io_list):
        sig_name = f"all[{i}]"
        if sig_name not in existing_ios:
            pcf_lines.append(f"set_io {sig_name} X{x}Y{y}/{p}")

    with open(output_pcf, 'w') as f:
        f.write("\n".join(pcf_lines) + "\n")
    print(f"✓ Generated PCF: {output_pcf}")


if __name__ == "__main__":
    if len(sys.argv) == 3:
        # Basic mode
        generate_pcf(sys.argv[1], sys.argv[2])
    elif len(sys.argv) == 4:
        # Intelligent mode
        generate_pcf(sys.argv[1], sys.argv[3], sys.argv[2])
    else:
        print(__doc__)
        sys.exit(1)
