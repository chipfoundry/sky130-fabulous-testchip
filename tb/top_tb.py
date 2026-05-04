# SPDX-FileCopyrightText: © 2026 FABulous Contributors
# SPDX-FileCopyrightText: © 2025 Leo Moser <leomoser99@gmail.com>
# SPDX-License-Identifier: Apache-2.0

import os
import re
import sys
import math
import random
from pathlib import Path
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer, Edge, RisingEdge, FallingEdge
from cocotb.regression import TestFactory
from cocotb_tools.runner import get_runner
from cocotb.types import LogicArray, Logic

from cocotbext.spi import SpiBus, SpiConfig, SpiMaster

proj_path = Path(__file__).resolve().parent
fabric = os.getenv("FABRIC", "classic_fabric_chipfoundry_large")
tile_library = os.getenv("TILE_LIBRARY", "classic")
emulation = os.getenv("EMULATION", False)

fabric_data = {
    "classic_fabric_chipfoundry_large": {
        "select": 0,
        "rows" : 14,
        "columns" : 15,
        "lookup" : {
            "X0Y1/A" : "bidir_PAD_0",
            "X0Y1/B" : "bidir_PAD_1",
            "X0Y2/A" : "bidir_PAD_2",
            "X0Y2/B" : "bidir_PAD_3",
            "X0Y3/A" : "bidir_PAD_4",
            "X0Y3/B" : "bidir_PAD_5",
            "X0Y4/A" : "bidir_PAD_6",
            "X0Y4/B" : "bidir_PAD_7",
            "X0Y5/A" : "bidir_PAD_8",
            "X0Y5/B" : "bidir_PAD_9",
            "X0Y6/A" : "bidir_PAD_10",
            "X0Y6/B" : "bidir_PAD_11",
            "X0Y7/A" : "bidir_PAD_12",
            "X0Y7/B" : "bidir_PAD_13",
            "X0Y8/A" : "bidir_PAD_14",
            "X0Y8/B" : "bidir_PAD_15",
            "X0Y9/A" : "bidir_PAD_16",
            "X0Y9/B" : "bidir_PAD_17",
            "X0Y10/A" : "bidir_PAD_18",
            "X0Y10/B" : "bidir_PAD_19",
            "X0Y11/A" : "bidir_PAD_20",
            "X0Y11/B" : "bidir_PAD_21",
            "X0Y12/A" : "bidir_PAD_22",
            "X0Y12/B" : "bidir_PAD_23",

            "X14Y1/A" : "bidir_PAD_24",
            "X14Y2/A" : "bidir_PAD_25",
            "X14Y3/A" : "bidir_PAD_26",
            "X14Y4/A" : "bidir_PAD_27",
            "X14Y5/A" : "bidir_PAD_28",
            "X14Y6/A" : "bidir_PAD_29",
            "X14Y7/A" : "bidir_PAD_30",
            "X14Y8/A" : "bidir_PAD_31",
            "X14Y9/A" : "bidir_PAD_32",
            "X14Y10/A" : "bidir_PAD_33",
            "X14Y11/A" : "bidir_PAD_34",
            "X14Y12/A" : "bidir_PAD_35",
        },
    },
    "classic_fabric_chipfoundry_medium": {
        "select": 2,
        "rows" : 8,
        "columns" : 10,
        "lookup" : {
            "X0Y1/A" : "bidir_PAD_0",
            "X0Y1/B" : "bidir_PAD_1",
            "X0Y2/A" : "bidir_PAD_2",
            "X0Y2/B" : "bidir_PAD_3",
            "X0Y3/A" : "bidir_PAD_4",
            "X0Y3/B" : "bidir_PAD_5",
            "X0Y4/A" : "bidir_PAD_6",
            "X0Y4/B" : "bidir_PAD_7",
            "X0Y5/A" : "bidir_PAD_8",
            "X0Y5/B" : "bidir_PAD_9",
            "X0Y6/A" : "bidir_PAD_10",
            "X0Y6/B" : "bidir_PAD_11",

            "X9Y1/A" : "bidir_PAD_12",
            "X9Y1/B" : "bidir_PAD_13",
            "X9Y2/A" : "bidir_PAD_14",
            "X9Y2/B" : "bidir_PAD_15",
            "X9Y3/A" : "bidir_PAD_16",
            "X9Y3/B" : "bidir_PAD_17",
            "X9Y4/A" : "bidir_PAD_18",
            "X9Y4/B" : "bidir_PAD_19",
            "X9Y5/A" : "bidir_PAD_20",
            "X9Y5/B" : "bidir_PAD_21",
            "X9Y6/A" : "bidir_PAD_22",
            "X9Y6/B" : "bidir_PAD_23",
        },
    },
    "classic_fabric_chipfoundry_small": {
        "select": 1,
        "rows" : 8,
        "columns" : 6,
        "lookup" : {
            "X0Y1/A" : "bidir_PAD_0",
            "X0Y1/B" : "bidir_PAD_1",
            "X0Y2/A" : "bidir_PAD_2",
            "X0Y2/B" : "bidir_PAD_3",
            "X0Y3/A" : "bidir_PAD_4",
            "X0Y3/B" : "bidir_PAD_5",
            "X0Y4/A" : "bidir_PAD_6",
            "X0Y4/B" : "bidir_PAD_7",
            "X0Y5/A" : "bidir_PAD_8",
            "X0Y5/B" : "bidir_PAD_9",
            "X0Y6/A" : "bidir_PAD_10",
            "X0Y6/B" : "bidir_PAD_11",

            "X5Y1/A" : "bidir_PAD_12",
            "X5Y1/B" : "bidir_PAD_13",
            "X5Y2/A" : "bidir_PAD_14",
            "X5Y2/B" : "bidir_PAD_15",
            "X5Y3/A" : "bidir_PAD_16",
            "X5Y3/B" : "bidir_PAD_17",
            "X5Y4/A" : "bidir_PAD_18",
            "X5Y4/B" : "bidir_PAD_19",
            "X5Y5/A" : "bidir_PAD_20",
            "X5Y5/B" : "bidir_PAD_21",
            "X5Y6/A" : "bidir_PAD_22",
            "X5Y6/B" : "bidir_PAD_23",
        },
    },
}


async def clear_bitstream_spi(spi_master):
    if emulation:
        return

    print("Clearing the bitstream...")

    FRAME_BITS_PER_ROW = 32
    MAX_FRAMES_PER_COL = 20
    FRAME_SELECT_WIDTH = 5 # hardcoded, should be based on FABRIC_NUM_COLUMNS

    BITSTREAM_START = 0xFAB0FAB1
    DESYNC_FLAG = 20

    NUM_ROWS = fabric_data[fabric]["rows"]
    NUM_COLUMNS = fabric_data[fabric]["columns"]

    # Header
    await spi_master.write([0xFA, 0xB0, 0xFA, 0xB1])

    for column in reversed(range(NUM_COLUMNS)):
        for frame in reversed(range(MAX_FRAMES_PER_COL)):
            header = (column & 0x1F) << 27 | (1<<frame) & 0xFFFFF
            header_bytes = [(header & 0xFF000000) >> 24, (header & 0xFF0000) >> 16, (header & 0xFF00) >> 8, header & 0xFF]
            await spi_master.write(header_bytes)

            for row in reversed(range(NUM_ROWS)):
                await spi_master.write([0x00, 0x00, 0x00, 0x00])
    
    header = 1 << DESYNC_FLAG
    header_bytes = [(header & 0xFF000000) >> 24, (header & 0xFF0000) >> 16, (header & 0xFF00) >> 8, header & 0xFF]
    await spi_master.write(header_bytes)

async def upload_bitstream_spi(bitstream_path, spi_master):
    if emulation:
        return

    print("Writing the bitstream...")

    with open(bitstream_path, 'br') as f:
        data = f.read(4)
        while data:
            number = int.from_bytes(data, "big")
            
            number_bytes = []            
            for _ in range(4):
                number_bytes.append((number & 0xFF000000) >> 24)
                number = number << 8
            
            print(f'Bitstream data: {number_bytes}')
            await spi_master.write(number_bytes)

            data = f.read(4)

class PCF:
    "A class to read a PCF file and access the signals within cocotb."

    def __init__(self, dut, file, lookup):
        self.signals = {}
        self.top = dut._name
        print(f"Reading PCF file: {file}")
        with open(file, "r") as pcf_file:
            while line := pcf_file.readline():
                if match := re.match(r"\s*set_io\s+(?P<signal>\w+)(\[(?P<index>\d+)?\])?\s+X(?P<tilex>\d+)Y(?P<tiley>\d+)\/(?P<bel>\w+)", line):
                    signal = match.group("signal")
                    index = match.group("index")
                    tile_x = match.group("tilex")
                    tile_y = match.group("tiley")
                    bel = match.group("bel")

                    tile_bel = f"X{tile_x}Y{tile_y}/{bel}"
                    top_pad = lookup[tile_bel]
                    top_handle = eval(f"dut.{top_pad}", locals=dict(dut=dut))

                    if index is None:
                        index = 0
                    else:
                        index = int(index)
                    
                    # Add an index to a signal
                    if signal in self.signals:
                        self.signals[signal][index] = top_handle

                        # Sort by index
                        self.signals[signal] = dict(sorted(self.signals[signal].items()))
                    # Add a new signal
                    else:
                        self.signals[signal] = {
                             index: top_handle
                        }

    def write_gtkw(self, path, filter=None):
        "Write a gtkwave save file in order to view the selected signals"
        with open(path, "w") as outfile:
            outfile.write(f"@28\n")
            for signal_name, signal in self.signals.items():
                if filter is not None and signal_name in filter:
                    if len(signal) == 1:
                        outfile.write(f"#{{{signal_name}}} {self.top}.{signal[0]._name}\n")
                        outfile.write(f"@200\n")
                        outfile.write(f"-\n")
                        outfile.write(f"@28\n")
                    else:
                        bits = len(signal)
                        signals = [ self.top + "." + signal._name for index, signal in reversed(signal.items()) ]
                    
                        outfile.write(f"@c00022\n")
                        outfile.write(f"#{{{signal_name}[{bits-1}:0]}} {' '.join(signals)}\n")
                        outfile.write(f"@28\n")
                        for signal in signals:
                            outfile.write(f"{signal}\n")
                        outfile.write(f"@1401200\n")
                        outfile.write(f"-group_end\n")

                        outfile.write(f"@200\n")
                        outfile.write(f"-\n")

    def get(self, signal, index=None):
        "Get the value of a signal"
        #print(f"get {signal} {index}")
    
        # Get the full signal
        if index is None:
            return LogicArray("".join(str(bit.value) for bit in reversed(self.signals[signal].values())))
        # Get a single bit
        else:
            return Logic(self.signals[signal][index].value)
    
    def set(self, signal, value, index=None):
        "Set the value of a signal"
        #print(f"set {signal} {value} {index}")
        
        # Get the full signal
        if index is None:
            for index, bit in enumerate(reversed(value)):
                self.signals[signal][index].value = bit
        else:
            self.signals[signal][index].value = value

    def get_raw(self, signal, use, index=0):
        "Get the raw cocotb signal. Can be used for triggers."
        return self.signals[signal][index]

@cocotb.test()
async def test_all_ones(dut):
    """Load bitstream for all_ones"""

    testname = "all_ones"

    pcf = PCF(dut, proj_path / f"../fabrics/{fabric}/constraints.pcf", fabric_data[fabric]["lookup"])
    pcf.write_gtkw(f"{testname}.gtkw", ["all"])

    # Setup SPI
    spi_bus = SpiBus.from_prefix(dut, "spi", bus_separator="_", sclk_name="sclk_PAD", cs_name="cs_n_PAD", mosi_name='mosi_PAD', miso_name='miso_PAD')

    spi_config = SpiConfig(
        word_width = 8,
        sclk_freq  = 10e6,
        cpol       = False,
        cpha       = True,
        msb_first  = True,
        frame_spacing_ns = 500
    )

    spi_master = SpiMaster(spi_bus, spi_config)

    # Static setup
    dut.spi_mode_PAD.value = 1 # Configure FPGA as receiver
    dut.fpga_select_PAD.value = fabric_data[fabric]["select"] # Select FPGA

    cocotb.start_soon(Clock(dut.clk_PAD, 10, 'ns').start())

    # Assert reset
    dut.rst_n_PAD.value = 0
    await ClockCycles(dut.clk_PAD, 10)

    # Deassert reset
    dut.rst_n_PAD.value = 1
    await ClockCycles(dut.clk_PAD, 10)

    # Configure FPGA via SPI
    await cocotb.start_soon(clear_bitstream_spi(spi_master))
    await cocotb.start_soon(upload_bitstream_spi(proj_path / f'../user_designs/designs/{tile_library}/{testname}/{testname}.bit', spi_master))
    await ClockCycles(dut.clk_PAD, 10)

    assert pcf.get("all").to_unsigned() == LogicArray.from_signed(-1, len(pcf.get("all")))

@cocotb.test()
async def test_all_zeros(dut):
    """Load bitstream for all_zeros"""

    testname = "all_zeros"

    pcf = PCF(dut, proj_path / f"../fabrics/{fabric}/constraints.pcf", fabric_data[fabric]["lookup"])
    pcf.write_gtkw(f"{testname}.gtkw", ["all"])

    # Setup SPI
    spi_bus = SpiBus.from_prefix(dut, "spi", bus_separator="_", sclk_name="sclk_PAD", cs_name="cs_n_PAD", mosi_name='mosi_PAD', miso_name='miso_PAD')

    spi_config = SpiConfig(
        word_width = 8,
        sclk_freq  = 10e6,
        cpol       = False,
        cpha       = True,
        msb_first  = True,
        frame_spacing_ns = 500
    )

    spi_master = SpiMaster(spi_bus, spi_config)

    # Static setup
    dut.spi_mode_PAD.value = 1 # Configure FPGA as receiver
    dut.fpga_select_PAD.value = fabric_data[fabric]["select"] # Select FPGA

    cocotb.start_soon(Clock(dut.clk_PAD, 10, 'ns').start())

    # Assert reset
    dut.rst_n_PAD.value = 0
    await ClockCycles(dut.clk_PAD, 10)

    # Deassert reset
    dut.rst_n_PAD.value = 1
    await ClockCycles(dut.clk_PAD, 10)

    # Configure FPGA via SPI
    await cocotb.start_soon(clear_bitstream_spi(spi_master))
    await cocotb.start_soon(upload_bitstream_spi(proj_path / f'../user_designs/designs/{tile_library}/{testname}/{testname}.bit', spi_master))
    await ClockCycles(dut.clk_PAD, 10)

    assert pcf.get("all").to_unsigned() == LogicArray.from_unsigned(0, len(pcf.get("all")))

@cocotb.test()
async def test_passthrough(dut):
    """Load bitstream for passthrough"""

    testname = "passthrough"

    pcf = PCF(dut, proj_path / f"../fabrics/{fabric}/constraints.pcf", fabric_data[fabric]["lookup"])
    pcf.write_gtkw(f"{testname}.gtkw", ["a", "b"])

    # Setup SPI
    spi_bus = SpiBus.from_prefix(dut, "spi", bus_separator="_", sclk_name="sclk_PAD", cs_name="cs_n_PAD", mosi_name='mosi_PAD', miso_name='miso_PAD')

    spi_config = SpiConfig(
        word_width = 8,
        sclk_freq  = 10e6,
        cpol       = False,
        cpha       = True,
        msb_first  = True,
        frame_spacing_ns = 500
    )

    spi_master = SpiMaster(spi_bus, spi_config)

    # Static setup
    dut.spi_mode_PAD.value = 1 # Configure FPGA as receiver
    dut.fpga_select_PAD.value = fabric_data[fabric]["select"] # Select FPGA

    cocotb.start_soon(Clock(dut.clk_PAD, 10, 'ns').start())

    # Assert reset
    dut.rst_n_PAD.value = 0
    await ClockCycles(dut.clk_PAD, 10)

    # Deassert reset
    dut.rst_n_PAD.value = 1
    await ClockCycles(dut.clk_PAD, 10)

    # Configure FPGA via SPI
    await cocotb.start_soon(clear_bitstream_spi(spi_master))
    await cocotb.start_soon(upload_bitstream_spi(proj_path / f'../user_designs/designs/{tile_library}/{testname}/{testname}.bit', spi_master))
    await ClockCycles(dut.clk_PAD, 10)

    for i in range(32):
        # Get a random value
        value = random.randint(0, 2**len(pcf.get("a"))-1)

        pcf.set("a", LogicArray.from_unsigned(value, len(pcf.get("a"))))
        await Timer(10, unit="ns")
        assert(pcf.get("b").to_unsigned() == value)

@cocotb.test()
async def test_addition(dut):
    """Load bitstream for addition"""

    testname = "addition"

    pcf = PCF(dut, proj_path / f"../fabrics/{fabric}/constraints.pcf", fabric_data[fabric]["lookup"])
    pcf.write_gtkw(f"{testname}.gtkw", ["a", "b", "c"])

    # Setup SPI
    spi_bus = SpiBus.from_prefix(dut, "spi", bus_separator="_", sclk_name="sclk_PAD", cs_name="cs_n_PAD", mosi_name='mosi_PAD', miso_name='miso_PAD')

    spi_config = SpiConfig(
        word_width = 8,
        sclk_freq  = 10e6,
        cpol       = False,
        cpha       = True,
        msb_first  = True,
        frame_spacing_ns = 500
    )

    spi_master = SpiMaster(spi_bus, spi_config)

    # Static setup
    dut.spi_mode_PAD.value = 1 # Configure FPGA as receiver
    dut.fpga_select_PAD.value = fabric_data[fabric]["select"] # Select FPGA

    cocotb.start_soon(Clock(dut.clk_PAD, 10, 'ns').start())

    # Assert reset
    dut.rst_n_PAD.value = 0
    await ClockCycles(dut.clk_PAD, 10)

    # Deassert reset
    dut.rst_n_PAD.value = 1
    await ClockCycles(dut.clk_PAD, 10)

    # Configure FPGA via SPI
    await cocotb.start_soon(clear_bitstream_spi(spi_master))
    await cocotb.start_soon(upload_bitstream_spi(proj_path / f'../user_designs/designs/{tile_library}/{testname}/{testname}.bit', spi_master))
    await ClockCycles(dut.clk_PAD, 10)

    for i in range(32):
        # Get a random value
        value_a = random.randint(0, 2**len(pcf.get("a"))-1)
        value_b = random.randint(0, 2**len(pcf.get("b"))-1)
        
        result = value_a + value_b

        pcf.set("a", LogicArray.from_unsigned(value_a, len(pcf.get("a"))))
        pcf.set("b", LogicArray.from_unsigned(value_b, len(pcf.get("b"))))
        
        await Timer(10, unit="ns")
        assert(pcf.get("c").to_unsigned() == result)

@cocotb.test()
async def test_counter(dut):
    """Load bitstream for counter"""

    testname = "counter"

    pcf = PCF(dut, proj_path / f"../fabrics/{fabric}/constraints.pcf", fabric_data[fabric]["lookup"])
    pcf.write_gtkw(f"{testname}.gtkw", ["clk1", "clk2", "rst", "ena", "c"])

    # Reset
    pcf.set("clk1", Logic(0), index=0)
    pcf.set("clk2", Logic(0), index=0)
    pcf.set("rst", Logic(1), index=0)
    pcf.set("ena", Logic(1), index=0)
    await Timer(10, unit="ns")

    # Setup SPI
    spi_bus = SpiBus.from_prefix(dut, "spi", bus_separator="_", sclk_name="sclk_PAD", cs_name="cs_n_PAD", mosi_name='mosi_PAD', miso_name='miso_PAD')

    spi_config = SpiConfig(
        word_width = 8,
        sclk_freq  = 10e6,
        cpol       = False,
        cpha       = True,
        msb_first  = True,
        frame_spacing_ns = 500
    )

    spi_master = SpiMaster(spi_bus, spi_config)

    # Static setup
    dut.spi_mode_PAD.value = 1 # Configure FPGA as receiver
    dut.fpga_select_PAD.value = fabric_data[fabric]["select"] # Select FPGA

    cocotb.start_soon(Clock(dut.clk_PAD, 10, 'ns').start())

    # Assert reset
    dut.rst_n_PAD.value = 0
    await ClockCycles(dut.clk_PAD, 10)

    # Deassert reset
    dut.rst_n_PAD.value = 1
    await ClockCycles(dut.clk_PAD, 10)

    # Configure FPGA via SPI
    await cocotb.start_soon(clear_bitstream_spi(spi_master))
    await cocotb.start_soon(upload_bitstream_spi(proj_path / f'../user_designs/designs/{tile_library}/{testname}/{testname}.bit', spi_master))
    await ClockCycles(dut.clk_PAD, 10)

    # Start a clock on clk1
    clock = pcf.get_raw("clk1", "OUT")
    cocotb.start_soon(Clock(clock, 10, 'ns').start())

    await ClockCycles(clock, 10)
    
    pcf.set("rst", Logic(0), index=0)
    pcf.set("ena", Logic(0), index=0)

    await ClockCycles(clock, 10)

    pcf.set("ena", Logic(1), index=0)

    NUM_CYCLES = 123
    await ClockCycles(clock, NUM_CYCLES)

    assert pcf.get("c").to_unsigned() == NUM_CYCLES-1

#@cocotb.test(skip=os.getenv("GL", None) is not None)
async def test_multiplication(dut):
    """Load bitstream for multiplication"""

    testname = "multiplication"

    pcf = PCF(dut, proj_path / f"../fabrics/{fabric}/constraints.pcf", lookup)
    pcf.write_gtkw(f"{testname}.gtkw", ["a", "b", "product"])

    # Setup SPI
    spi_bus = SpiBus.from_prefix(dut, "spi", bus_separator="_", sclk_name="sclk_PAD", cs_name="cs_n_PAD", mosi_name='mosi_PAD', miso_name='miso_PAD')

    spi_config = SpiConfig(
        word_width = 8,
        sclk_freq  = 10e6,
        cpol       = False,
        cpha       = True,
        msb_first  = True,
        frame_spacing_ns = 500
    )

    spi_master = SpiMaster(spi_bus, spi_config)

    # Static setup
    dut.fpga_mode_PAD.value = 1 # Configure FPGA as receiver
    dut.fpga_config_slot_PAD.value = 0
    dut.fpga_config_trigger_PAD.value = 0

    cocotb.start_soon(Clock(dut.clk_PAD, 10, 'ns').start())

    # Assert reset
    dut.rst_n_PAD.value = 0
    await ClockCycles(dut.clk_PAD, 10)

    # Deassert reset
    dut.rst_n_PAD.value = 1
    await ClockCycles(dut.clk_PAD, 10)

    # Configure FPGA via SPI
    await cocotb.start_soon(clear_bitstream_spi(spi_master))
    await cocotb.start_soon(upload_bitstream_spi(proj_path / f'../user_designs/designs/{tile_library}/{testname}/{testname}.bit', spi_master))
    await ClockCycles(dut.clk_PAD, 10)

    for i in range(32):
        # Get a random value
        value_a = random.randint(0, 2**len(pcf.get("a"))-1)
        value_b = random.randint(0, 2**len(pcf.get("b"))-1)
        
        result = value_a * value_b

        pcf.set("a", LogicArray.from_unsigned(value_a, len(pcf.get("a"))))
        pcf.set("b", LogicArray.from_unsigned(value_b, len(pcf.get("b"))))
        
        await Timer(10, unit="ns")
        assert(pcf.get("product").to_unsigned() == result)

#@cocotb.test(skip=os.getenv("GL", None) is not None)
async def test_ihp_sram_1024x32_1rw(dut):
    """Load bitstream for ihp_sram_1024x32_1rw"""

    testname = "ihp_sram_1024x32_1rw"

    pcf = PCF(dut, proj_path / f"../fabrics/{fabric}/constraints.pcf", lookup)
    pcf.write_gtkw(f"{testname}.gtkw", ["clk1", "ram_addr", "ram_byte_sel", "ram_wen", "ram_men", "ram_ren", "ram_din_byte", "ram_dout_byte"])

    # Reset
    pcf.set("clk1", Logic(0), index=0)
    await Timer(10, unit="ns")

    # Setup SPI
    spi_bus = SpiBus.from_prefix(dut, "spi", bus_separator="_", sclk_name="sclk_PAD", cs_name="cs_n_PAD", mosi_name='mosi_PAD', miso_name='miso_PAD')

    spi_config = SpiConfig(
        word_width = 8,
        sclk_freq  = 10e6,
        cpol       = False,
        cpha       = True,
        msb_first  = True,
        frame_spacing_ns = 500
    )

    spi_master = SpiMaster(spi_bus, spi_config)

    # Static setup
    dut.fpga_mode_PAD.value = 1 # Configure FPGA as receiver
    dut.fpga_config_slot_PAD.value = 0
    dut.fpga_config_trigger_PAD.value = 0

    cocotb.start_soon(Clock(dut.clk_PAD, 10, 'ns').start())

    # Assert reset
    dut.rst_n_PAD.value = 0
    await ClockCycles(dut.clk_PAD, 10)

    # Deassert reset
    dut.rst_n_PAD.value = 1
    await ClockCycles(dut.clk_PAD, 10)

    # Configure FPGA via SPI
    await cocotb.start_soon(clear_bitstream_spi(spi_master))
    await cocotb.start_soon(upload_bitstream_spi(proj_path / f'../user_designs/designs/{tile_library}/{testname}/{testname}.bit', spi_master))
    await ClockCycles(dut.clk_PAD, 10)

    # Start a clock on clk1
    clock1 = pcf.get_raw("clk1", "OUT")
    cocotb.start_soon(Clock(clock1, 10, 'ns').start())
    
    await ClockCycles(clock1, 10)
    
    pcf.set("ram_men", Logic(1), index=0)
    pcf.set("ram_wen", Logic(0), index=0)
    pcf.set("ram_ren", Logic(0), index=0)
    pcf.set("ram_addr", LogicArray.from_unsigned(0, len(pcf.get("ram_addr"))))
    pcf.set("ram_byte_sel", LogicArray.from_unsigned(0, len(pcf.get("ram_byte_sel"))))
    pcf.set("ram_din_byte", LogicArray.from_unsigned(0, len(pcf.get("ram_din_byte"))))
    await ClockCycles(clock1, 1)
    
    pcf.set("ram_wen", Logic(1), index=0)
    pcf.set("ram_ren", Logic(0), index=0)
    
    data = [random.randint(0, 2**10-1) for _ in range(100)] # 4 KiB memory

    # Fill the memory with data
    for i in data:
        pcf.set("ram_addr", LogicArray.from_unsigned(i >> 2, len(pcf.get("ram_addr"))))
        pcf.set("ram_byte_sel", LogicArray.from_unsigned(i & 0x3, len(pcf.get("ram_byte_sel"))))
        pcf.set("ram_din_byte", LogicArray.from_unsigned(i & 0xFF, len(pcf.get("ram_din_byte"))))
        
        await ClockCycles(clock1, 1)

    pcf.set("ram_wen", Logic(0), index=0)
    pcf.set("ram_ren", Logic(1), index=0)
    
    # Read the same data
    for i in data:
        pcf.set("ram_addr", LogicArray.from_unsigned(i >> 2, len(pcf.get("ram_addr"))))
        pcf.set("ram_byte_sel", LogicArray.from_unsigned(i & 0x3, len(pcf.get("ram_byte_sel"))))
        await ClockCycles(clock1, 2)

        assert(pcf.get("ram_dout_byte").to_unsigned() == i & 0xFF)

#@cocotb.test(skip=os.getenv("GL", None) is not None)
async def test_mem_1024x32_1rw(dut):
    """Load bitstream for mem_1024x32_1rw"""

    testname = "mem_1024x32_1rw"

    pcf = PCF(dut, proj_path / f"../fabrics/{fabric}/constraints.pcf", lookup)
    pcf.write_gtkw(f"{testname}.gtkw", ["clk1", "ram_addr", "ram_byte_sel", "ram_wen", "ram_men", "ram_ren", "ram_din_byte", "ram_dout_byte"])

    # Reset
    pcf.set("clk1", Logic(0), index=0)
    await Timer(10, unit="ns")

    # Setup SPI
    spi_bus = SpiBus.from_prefix(dut, "spi", bus_separator="_", sclk_name="sclk_PAD", cs_name="cs_n_PAD", mosi_name='mosi_PAD', miso_name='miso_PAD')

    spi_config = SpiConfig(
        word_width = 8,
        sclk_freq  = 10e6,
        cpol       = False,
        cpha       = True,
        msb_first  = True,
        frame_spacing_ns = 500
    )

    spi_master = SpiMaster(spi_bus, spi_config)

    # Static setup
    dut.fpga_mode_PAD.value = 1 # Configure FPGA as receiver
    dut.fpga_config_slot_PAD.value = 0
    dut.fpga_config_trigger_PAD.value = 0

    cocotb.start_soon(Clock(dut.clk_PAD, 10, 'ns').start())

    # Assert reset
    dut.rst_n_PAD.value = 0
    await ClockCycles(dut.clk_PAD, 10)

    # Deassert reset
    dut.rst_n_PAD.value = 1
    await ClockCycles(dut.clk_PAD, 10)

    # Configure FPGA via SPI
    await cocotb.start_soon(clear_bitstream_spi(spi_master))
    await cocotb.start_soon(upload_bitstream_spi(proj_path / f'../user_designs/designs/{tile_library}/{testname}/{testname}.bit', spi_master))
    await ClockCycles(dut.clk_PAD, 10)

    # Start a clock on clk1
    clock1 = pcf.get_raw("clk1", "OUT")
    cocotb.start_soon(Clock(clock1, 10, 'ns').start())
    
    await ClockCycles(clock1, 10)
    
    pcf.set("ram_men", Logic(1), index=0)
    pcf.set("ram_wen", Logic(0), index=0)
    pcf.set("ram_ren", Logic(0), index=0)
    pcf.set("ram_addr", LogicArray.from_unsigned(0, len(pcf.get("ram_addr"))))
    pcf.set("ram_byte_sel", LogicArray.from_unsigned(0, len(pcf.get("ram_byte_sel"))))
    pcf.set("ram_din_byte", LogicArray.from_unsigned(0, len(pcf.get("ram_din_byte"))))
    await ClockCycles(clock1, 1)
    
    pcf.set("ram_wen", Logic(1), index=0)
    pcf.set("ram_ren", Logic(0), index=0)
    
    data = [random.randint(0, 2**10-1) for _ in range(100)] # 4 KiB memory

    # Fill the memory with data
    for i in data:
        pcf.set("ram_addr", LogicArray.from_unsigned(i >> 2, len(pcf.get("ram_addr"))))
        pcf.set("ram_byte_sel", LogicArray.from_unsigned(i & 0x3, len(pcf.get("ram_byte_sel"))))
        pcf.set("ram_din_byte", LogicArray.from_unsigned(i & 0xFF, len(pcf.get("ram_din_byte"))))
        
        await ClockCycles(clock1, 1)

    pcf.set("ram_wen", Logic(0), index=0)
    pcf.set("ram_ren", Logic(1), index=0)
    
    # Read the same data
    for i in data:
        pcf.set("ram_addr", LogicArray.from_unsigned(i >> 2, len(pcf.get("ram_addr"))))
        pcf.set("ram_byte_sel", LogicArray.from_unsigned(i & 0x3, len(pcf.get("ram_byte_sel"))))
        await ClockCycles(clock1, 2)

        assert(pcf.get("ram_dout_byte").to_unsigned() == i & 0xFF)

if __name__ == "__main__":

    sim = os.getenv("SIM", "icarus")
    pdk_root = os.getenv("PDK_ROOT", os.path.expanduser('~/.ciel'))
    pdk = os.getenv("PDK", "sky130A")
    scl = os.getenv("SCL", "sky130_fd_sc_hd")
    gl = os.getenv("GL", None)
    tile_library = os.getenv("TILE_LIBRARY", "classic")
    
    if emulation and gl:
        print("Error: EMULATION and GL can't be set at the same time.")
        sys.exit(1)
    
    hdl_toplevel = "chip_top_tb"
    
    tiles_path = Path(proj_path / ".." / "ip" / "fabulous-tiles")
    primitives_path = Path(tiles_path) / "primitives"
    tile_library_path = Path(tiles_path) / "tiles" / tile_library

    sources = []
    defines = {'FUNCTIONAL': 1}
    test_filter = None
    
    # TB wrapper
    sources.append(proj_path / f"chip_top_tb.v")
    
    # SCL models
    sources.append(Path(pdk_root) / pdk / "libs.ref" / scl / "verilog" / "primitives.v")
    sources.append(Path(pdk_root) / pdk / "libs.ref" / scl / "verilog" / f"{scl}.v")
    
    # IO models
    sources.append(Path(pdk_root) / pdk / "libs.ref" / "sky130_fd_io" / "verilog" / "sky130_ef_io.v")
    sources.append(Path(pdk_root) / pdk / "libs.ref" / "sky130_fd_io" / "verilog" / "sky130_fd_io.v")

    # Logos
    sources.append(proj_path / '../ip/caravel_logo/vh/caravel_logo.vh')
    sources.append(proj_path / '../ip/caravel_motto/vh/caravel_motto.vh')
    sources.append(proj_path / '../ip/open_source/vh/open_source.vh')
    sources.append(proj_path / '../ip/project_id_textblock/vh/project_id_textblock.vh')

    # RTL
    if not gl:
        if emulation:
            sources.append(proj_path / f'../user_designs/designs/{tile_library}/{emulation}/{emulation}.vh')
            defines["EMULATION"] = True
            test_filter = "test_" + emulation
    
        primitives_files = list(primitives_path.glob('**/fabulous/*.v'))
        tile_files = list(tile_library_path.glob(f'**/macro/{pdk}/fabulous/*.v'))

        #print(f"Primitive sources: {primitives_files}")
        #print(f"Tile sources: {tile_files}")
        
        sources.extend(primitives_files)
        sources.extend(tile_files)
    
        # Add models pack
        sources.append(tiles_path / "models_pack.v")

        # Add custom cells
        sources.append(tiles_path / "custom.v")

        # Add fabric RTL netlist
        sources.append(proj_path / f'../fabrics/classic_fabric_chipfoundry_large/macro/{pdk}/fabulous/classic_fabric_chipfoundry_large.v')
        sources.append(proj_path / f'../fabrics/classic_fabric_chipfoundry_medium/macro/{pdk}/fabulous/classic_fabric_chipfoundry_medium.v')
        sources.append(proj_path / f'../fabrics/classic_fabric_chipfoundry_small/macro/{pdk}/fabulous/classic_fabric_chipfoundry_small.v')
    
        sources.append(proj_path / f"../src/chip_top.sv")
        sources.append(proj_path / f"../src/chip_core.sv")
        sources.append(proj_path / f"../ip/fabric_config/fabric_config.sv")
        sources.append(proj_path / f"../ip/fabric_spi/fabric_spi_controller.sv")
        sources.append(proj_path / f"../ip/fabric_spi/fabric_spi_receiver.sv")
    
    # Gate-level
    else:
        # We use the unpowered netlist
        sources.append(proj_path / f"../final/nl/chip_top.nl.v")

        # Tile GL netlists
        tile_files = list(tile_library_path.glob(f'**/macro/{pdk}/nl/*.nl.v'))
        #print(f"Tile sources: {tile_files}")
        sources.extend(tile_files)
        
        # Fabric GL netlist
        sources.append(proj_path / f'../fabrics/{fabric}/macro/{pdk}/nl/{fabric}.nl.v')

        #defines["USE_POWER_PINS"] = False

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
        test_module="top_tb",
        plusargs=['-fst'],
        waves=True,
        test_filter=test_filter,
    )
