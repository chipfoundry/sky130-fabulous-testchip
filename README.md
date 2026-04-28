# sky130 FABulous Test Chip

A test chip with three FABulous FPGA fabrics.

<p align="center">
  <a href="img/chip_top.png">
    <img src="img/chip_top.png" alt="chip layout" width=35%>
  </a>
</p>

> [!NOTE]
> To build the chip, enable the following PDK version using ciel: d815bb30c9afdf9e264c276a8a2b533108dea3d0
> In addition the following LibreLane branch must be used: `nix shell github:librelane/librelane/leo/padring-orientation`


This repository contains a collection of fabrics using the [fabulous-tiles](https://github.com/mole99/fabulous-tiles) tile libraries.

The fabrics can be found under `fabrics/`. Current fabrics include:

- classic_fabric_chipfoundry_small
- classic_fabric_chipfoundry_medium
- classic_fabric_chipfoundry_large

The prefix describes the tile library that is used, in this case `classic`.

The fabrics can be implemented with LibreLane using the FABulous plugin for LibreLane: [librelane_plugin_fabulous](https://github.com/mole99/librelane_plugin_fabulous).
See below for more information about stitching the fabric. 

A Continuous Integration (CI) setup implements the fabrics for the sky130A PDK.

## Requirements

> [!NOTE]
> Make sure to clone the repository with submodules!
>
>```console
>git clone --recurse-submodules <url>.git
>```
> or initialize the submodules after cloning:
>
>```console
> git submodule update --init --recursive
>```

For information on installing Nix with the FOSSi Foundation cache, please refer to the LibreLane documentation: https://librelane.readthedocs.io/en/stable/installation/nix_installation/index.html

## Stitch the Fabrics

As a prerequisite make sure that the tiles for the tile library that you are using have been implemented in `ip/fabulous-tiles`.
If that is the case, you can proceed by enabling a Nix shell with LibreLane in this repository:

```
nix-shell
```

To implement all fabrics, run:

```
make all
```

To implement a single fabric, run:

```
make classic_fabric_chipfoundry_large
```

After a fabrics has been implemented you can view it either in OpenROAD or KLayout by appending `-openroad` or `-klayout` to the fabric name.
For example, to view `classic_fabric_chipfoundry_large` in OpenROAD, run: `make classic_fabric_chipfoundry_large-openroad`.

## Implement User Designs

Please see the README in `user_designs/` on how to implement a user design for the fabrics.

## Simulate the Fabric

After you have generated the bitstreams for the user designs you can simulate the fabric.
You will again need the Nix shell from the root of this repository.

Again, use `PDK`, `FABRIC` and `TILE_LIBRARY` accordingly.

There are two ways to simulate the fabric:

#### RTL "Emulation"

In this case, "emulation" means that we simulate the fabric, however, without uploading the bitstream.
The configuration bits of the fabric are already initialized with the user design bitstream.
This has the benefit that simulation is much faster: no need to upload the bitstream and the Verilog simulator can prune dead branches. However, the disadvantage is that only a single user design can be run per simulation.

To emulate a user design, simply set EMULATE to its name:

```
export EMULATE=counter
```

Then, run the simulation using cocotb:

```
cd tb; python3 fabric_tb.py
```

#### RTL Simulation

To start the RTL simulation, simply run cocotb:

```
cd tb; python3 fabric_tb.py
```

And it will run all available test cases for the selected fabric and tile library.
