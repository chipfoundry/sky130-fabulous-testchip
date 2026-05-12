// SPDX-FileCopyrightText: © 2026 Leo Moser
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module chip_top #(
    // Power/ground pads for core
    parameter NUM_VCCD_PADS = 4,
    parameter NUM_VSSD_PADS = 4,
    
    // Power/ground pads for I/O
    parameter NUM_VDDIO_PADS = 4,
    parameter NUM_VSSIO_PADS = 4,
    
    // Signal pads
    parameter NUM_BIDIR_PADS  = 36
    )(
    `ifdef USE_POWER_PINS
    inout  wire [NUM_VCCD_PADS -1:0] VCCD_PAD,
    inout  wire [NUM_VSSD_PADS -1:0] VSSD_PAD,
    inout  wire [NUM_VDDIO_PADS-1:0] VDDIO_PAD,
    inout  wire [NUM_VSSIO_PADS-1:0] VSSIO_PAD,
    `endif
    inout  wire clk_PAD,
    inout  wire rst_n_PAD,
    
    inout  wire spi_mode_PAD,
    
    inout  wire spi_sclk_PAD,
    inout  wire spi_cs_n_PAD,
    inout  wire spi_mosi_PAD,
    inout  wire spi_miso_PAD,

    inout  wire [1:0] fpga_select_PAD,

    inout  wire config_busy_PAD,
    
    inout  wire global_enable_PAD,
    
    inout  wire [NUM_BIDIR_PADS-1:0] bidir_PAD
);
    `ifdef USE_POWER_PINS
    wire VDDIO;
    wire VSSIO;
    wire VCCD;
    wire VSSD;
    
    //wire VSWITCH;
    //wire VCCHIB;
    wire VDDA;
    wire VSSA;
    
    // VDDIO_Q/VSSIO_Q are connected to VDDIO/VSSIO
    // through metal resistors in the pad cells
    wire VDDIO_Q;
    wire VSSIO_Q;
    `endif

    wire AMUXBUS_A;
    wire AMUXBUS_B;

    wire clk_PAD2CORE;
    wire rst_n_PAD2CORE;

    // 0 = active SPI
    // 1 = passive SPI
    wire spi_mode_PAD2CORE;
    
    wire spi_sclk_PAD2CORE;
    wire spi_sclk_CORE2PAD;
    wire spi_sclk_CORE2PAD_OE;

    wire spi_cs_n_PAD2CORE;
    wire spi_cs_n_CORE2PAD;
    wire spi_cs_n_CORE2PAD_OE;

    wire spi_mosi_PAD2CORE;
    wire spi_mosi_CORE2PAD;
    wire spi_mosi_CORE2PAD_OE;

    wire spi_miso_PAD2CORE;
    wire spi_miso_CORE2PAD;
    wire spi_miso_CORE2PAD_OE;

    wire [1:0] fpga_select_PAD2CORE;

    wire config_busy_CORE2PAD;

    wire global_enable_PAD2CORE;

    wire [NUM_BIDIR_PADS-1:0] bidir_PAD2CORE;
    wire [NUM_BIDIR_PADS-1:0] bidir_CORE2PAD;
    wire [NUM_BIDIR_PADS-1:0] bidir_CORE2PAD_OE;
    
    // Connect power domains!
    generate
    for (genvar i=0; i<2*4; i++) begin : vcchib_vccd_and_vswitch_vddio_slices
        // VCCHIB to VCCD
        // VSWITCH to VDDIO
        (* keep *)
        sky130_ef_io__connect_vcchib_vccd_and_vswitch_vddio_slice_20um vcchib_vccd_and_vswitch_vddio_slice (
            `ifdef USE_POWER_PINS
            .VSWITCH    (VDDIO),
            .VCCHIB     (VCCD)
            `endif
        );
    end
    for (genvar i=0; i<2*4; i++) begin : vdda_vddio_and_vssa_vssio_slices
        // VDDA to VDDIO
        // VSSA to VSSIO
        (* keep *)
        sky130_ef_io__connect_vdda_vddio_and_vssa_vssio_slice_20um vdda_vddio_and_vssa_vssio_slice (
            `ifdef USE_POWER_PINS
            .VDDA       (VDDA),
            .VSSA       (VSSA)
            `endif
        );
    end
    endgenerate

    // Supply the ENABLE_H signal for the I/Os from the outside
    (* keep *)
    sky130_ef_io__analog_esd_pad global_enable_pad (
        /*`ifdef USE_POWER_PINS
        .VCCD       (VCCD),
        .VCCHIB     (VCCD),
        .VDDA       (VDDA),
        .VDDIO      (VDDIO),
        .VDDIO_Q    (VDDIO_Q),
        .VSSA       (VSSA),
        .VSSD       (VSSD),
        .VSSIO      (VSSIO),
        .VSSIO_Q    (VSSIO_Q),
        .VSWITCH    (VDDIO),
        `endif*/
        .AMUXBUS_A  (AMUXBUS_A),
        .AMUXBUS_B  (AMUXBUS_B),
        .P_PAD       (global_enable_PAD),
        .P_CORE      (global_enable_PAD2CORE)
    );

    // Power/ground pad instances
    generate
    for (genvar i=0; i<NUM_VDDIO_PADS; i++) begin : vddio_pads
        (* keep *)
        sky130_ef_io__vddio_hvc_clamped_pad vddio_pad  (
            `ifdef USE_POWER_PINS
            .VDDIO      (VDDIO),
            .VDDIO_Q    (VDDIO_Q),
            .VDDA       (VDDA),
            .VCCD       (VCCD),
            .VSWITCH    (VDDIO),
            .VCCHIB     (VCCD),
            .VSSA       (VSSA),
            .VSSD       (VSSD),
            .VSSIO_Q    (VSSIO_Q),
            .VSSIO      (VSSIO),
            .VDDIO_PAD  (VDDIO_PAD[i]),
            `endif
            .AMUXBUS_A  (AMUXBUS_A),
            .AMUXBUS_B  (AMUXBUS_B)
        );
    end
    for (genvar i=0; i<NUM_VSSIO_PADS; i++) begin : vssio_pads
        (* keep *)
        sky130_ef_io__vssio_hvc_clamped_pad vssio_pad  (
            `ifdef USE_POWER_PINS
            .VDDIO      (VDDIO),
            .VDDIO_Q    (VDDIO_Q),
            .VDDA       (VDDA),
            .VCCD       (VCCD),
            .VSWITCH    (VDDIO),
            .VCCHIB     (VCCD),
            .VSSA       (VSSA),
            .VSSD       (VSSD),
            .VSSIO_Q    (VSSIO_Q),
            .VSSIO      (VSSIO),
            .VSSIO_PAD  (VSSIO_PAD[i]),
            `endif
            .AMUXBUS_A  (AMUXBUS_A),
            .AMUXBUS_B  (AMUXBUS_B)
        );
    end
    for (genvar i=0; i<NUM_VCCD_PADS; i++) begin : vccd_pads
        (* keep *)
        sky130_ef_io__vccd_lvc_clamped_pad vccd_pad  (
            `ifdef USE_POWER_PINS
            .VDDIO       (VDDIO),
            .VDDIO_Q     (VDDIO_Q),
            .VDDA        (VDDA),
            .VCCD        (VCCD),
            .VSWITCH     (VDDIO),
            .VCCHIB      (VCCD),
            .VSSA        (VSSA),
            .VSSD        (VSSD),
            .VSSIO_Q     (VSSIO_Q),
            .VSSIO       (VSSIO),
            .VCCD_PAD    (VCCD_PAD[i]),
            `endif
            .AMUXBUS_A   (AMUXBUS_A),
            .AMUXBUS_B   (AMUXBUS_B)
        );
    end
    for (genvar i=0; i<NUM_VSSD_PADS; i++) begin : vssd_pads
        (* keep *)
        sky130_ef_io__vssd_lvc_clamped_pad vssd_pad  (
            `ifdef USE_POWER_PINS
            .VDDIO       (VDDIO),
            .VDDIO_Q     (VDDIO_Q),
            .VDDA        (VDDA),
            .VCCD        (VCCD),
            .VSWITCH     (VDDIO),
            .VCCHIB      (VCCD),
            .VSSA        (VSSA),
            .VSSD        (VSSD),
            .VSSIO_Q     (VSSIO_Q),
            .VSSIO       (VSSIO),
            .VSSD_PAD    (VSSD_PAD[i]),
            `endif
            .AMUXBUS_A   (AMUXBUS_A),
            .AMUXBUS_B   (AMUXBUS_B)
        );
    end
    endgenerate

    // Signal IO pad instances

    // Clock
    
    wire clock_TIE_HI_ESD;
    wire clock_TIE_LO_ESD;

    sky130_ef_io__gpiov2_pad clock_pad (
        `ifdef USE_POWER_PINS
        .VDDIO      (VDDIO),
        .VDDIO_Q    (VDDIO_Q),
        .VDDA       (VDDA),
        .VCCD       (VCCD),
        .VSWITCH    (VDDIO),
        .VCCHIB     (VCCD),
        .VSSA       (VSSA),
        .VSSD       (VSSD),
        .VSSIO_Q    (VSSIO_Q),
        .VSSIO      (VSSIO),
        `endif
        .OUT             ('0),
        .OE_N            ('1),
        .HLD_H_N         (clock_TIE_HI_ESD),
        .ENABLE_H        (global_enable_PAD2CORE),
        .ENABLE_INP_H    (clock_TIE_HI_ESD),
        .ENABLE_VDDA_H   (clock_TIE_HI_ESD),
        .ENABLE_VSWITCH_H(clock_TIE_HI_ESD),
        .ENABLE_VDDIO    ('1),
        .INP_DIS         ('0),
        .IB_MODE_SEL     ('0),
        .VTRIP_SEL       ('0),
        .SLOW            ('0),
        .HLD_OVR         ('0),
        .ANALOG_EN       ('0),
        .ANALOG_SEL      ('0),
        .ANALOG_POL      ('0),
        .DM              (3'b001),
        .PAD             (clk_PAD),
        .PAD_A_NOESD_H   (),
        .PAD_A_ESD_0_H   (),
        .PAD_A_ESD_1_H   (),
        .AMUXBUS_A       (AMUXBUS_A),
        .AMUXBUS_B       (AMUXBUS_B),
        .IN              (clk_PAD2CORE),
        .IN_H            (),
        .TIE_HI_ESD      (clock_TIE_HI_ESD),
        .TIE_LO_ESD      (clock_TIE_LO_ESD)
    );
    
    // Reset
    
    wire reset_TIE_HI_ESD;
    wire reset_TIE_LO_ESD;
    
    sky130_ef_io__gpiov2_pad reset_pad (
        `ifdef USE_POWER_PINS
        .VDDIO      (VDDIO),
        .VDDIO_Q    (VDDIO_Q),
        .VDDA       (VDDA),
        .VCCD       (VCCD),
        .VSWITCH    (VDDIO),
        .VCCHIB     (VCCD),
        .VSSA       (VSSA),
        .VSSD       (VSSD),
        .VSSIO_Q    (VSSIO_Q),
        .VSSIO      (VSSIO),
        `endif
        .OUT             ('0),
        .OE_N            ('1),
        .HLD_H_N         (reset_TIE_HI_ESD),
        .ENABLE_H        (global_enable_PAD2CORE),
        .ENABLE_INP_H    (reset_TIE_HI_ESD),
        .ENABLE_VDDA_H   (reset_TIE_HI_ESD),
        .ENABLE_VSWITCH_H(reset_TIE_HI_ESD),
        .ENABLE_VDDIO    ('1),
        .INP_DIS         ('0),
        .IB_MODE_SEL     ('0),
        .VTRIP_SEL       ('0),
        .SLOW            ('0),
        .HLD_OVR         ('0),
        .ANALOG_EN       ('0),
        .ANALOG_SEL      ('0),
        .ANALOG_POL      ('0),
        .DM              (3'b001),
        .PAD             (rst_n_PAD),
        .PAD_A_NOESD_H   (),
        .PAD_A_ESD_0_H   (),
        .PAD_A_ESD_1_H   (),
        .AMUXBUS_A       (AMUXBUS_A),
        .AMUXBUS_B       (AMUXBUS_B),
        .IN              (rst_n_PAD2CORE),
        .IN_H            (),
        .TIE_HI_ESD      (reset_TIE_HI_ESD),
        .TIE_LO_ESD      (reset_TIE_LO_ESD)
    );

    // SPI Mode
    
    wire spi_mode_TIE_HI_ESD;
    wire spi_mode_TIE_LO_ESD;
    
    sky130_ef_io__gpiov2_pad spi_mode_pad (
        `ifdef USE_POWER_PINS
        .VDDIO      (VDDIO),
        .VDDIO_Q    (VDDIO_Q),
        .VDDA       (VDDA),
        .VCCD       (VCCD),
        .VSWITCH    (VDDIO),
        .VCCHIB     (VCCD),
        .VSSA       (VSSA),
        .VSSD       (VSSD),
        .VSSIO_Q    (VSSIO_Q),
        .VSSIO      (VSSIO),
        `endif
        .OUT             ('0),
        .OE_N            ('1),
        .HLD_H_N         (spi_mode_TIE_HI_ESD),
        .ENABLE_H        (global_enable_PAD2CORE),
        .ENABLE_INP_H    (spi_mode_TIE_HI_ESD),
        .ENABLE_VDDA_H   (spi_mode_TIE_HI_ESD),
        .ENABLE_VSWITCH_H(spi_mode_TIE_HI_ESD),
        .ENABLE_VDDIO    ('1),
        .INP_DIS         ('0),
        // CMOS input buffer
        .IB_MODE_SEL     ('0),
        .VTRIP_SEL       ('0),
        .SLOW            ('0),
        .HLD_OVR         ('0),
        .ANALOG_EN       ('0),
        .ANALOG_SEL      ('0),
        .ANALOG_POL      ('0),
        // Disable output buffer, input buffer enabled
        .DM              (3'b001),
        .PAD             (spi_mode_PAD),
        .PAD_A_NOESD_H   (),
        .PAD_A_ESD_0_H   (),
        .PAD_A_ESD_1_H   (),
        .AMUXBUS_A       (AMUXBUS_A),
        .AMUXBUS_B       (AMUXBUS_B),
        .IN              (spi_mode_PAD2CORE),
        .IN_H            (),
        .TIE_HI_ESD      (spi_mode_TIE_HI_ESD),
        .TIE_LO_ESD      (spi_mode_TIE_LO_ESD)
    );
    
    // SPI SCLK
    
    wire spi_sclk_TIE_HI_ESD;
    wire spi_sclk_TIE_LO_ESD;

    sky130_ef_io__gpiov2_pad spi_sclk_pad (
        `ifdef USE_POWER_PINS
        .VDDIO      (VDDIO),
        .VDDIO_Q    (VDDIO_Q),
        .VDDA       (VDDA),
        .VCCD       (VCCD),
        .VSWITCH    (VDDIO),
        .VCCHIB     (VCCD),
        .VSSA       (VSSA),
        .VSSD       (VSSD),
        .VSSIO_Q    (VSSIO_Q),
        .VSSIO      (VSSIO),
        `endif
        .OUT             (spi_sclk_CORE2PAD),
        .OE_N            (! spi_sclk_CORE2PAD_OE),
        .HLD_H_N         (spi_sclk_TIE_HI_ESD),
        .ENABLE_H        (global_enable_PAD2CORE),
        .ENABLE_INP_H    (spi_sclk_TIE_HI_ESD),
        .ENABLE_VDDA_H   (spi_sclk_TIE_HI_ESD),
        .ENABLE_VSWITCH_H(spi_sclk_TIE_HI_ESD),
        .ENABLE_VDDIO    ('1),
        .INP_DIS         ('0),
        .IB_MODE_SEL     ('0),
        .VTRIP_SEL       ('0),
        .SLOW            ('0),
        .HLD_OVR         ('0),
        .ANALOG_EN       ('0),
        .ANALOG_SEL      ('0),
        .ANALOG_POL      ('0),
        .DM              (spi_sclk_CORE2PAD_OE ? 3'b110 : 3'b001),
        .PAD             (spi_sclk_PAD),
        .PAD_A_NOESD_H   (),
        .PAD_A_ESD_0_H   (),
        .PAD_A_ESD_1_H   (),
        .AMUXBUS_A       (AMUXBUS_A),
        .AMUXBUS_B       (AMUXBUS_B),
        .IN              (spi_sclk_PAD2CORE),
        .IN_H            (),
        .TIE_HI_ESD      (spi_sclk_TIE_HI_ESD),
        .TIE_LO_ESD      (spi_sclk_TIE_LO_ESD)
    );

    // SPI CS_N
    
    wire spi_cs_n_TIE_HI_ESD;
    wire spi_cs_n_TIE_LO_ESD;

    sky130_ef_io__gpiov2_pad spi_cs_n_pad (
        `ifdef USE_POWER_PINS
        .VDDIO      (VDDIO),
        .VDDIO_Q    (VDDIO_Q),
        .VDDA       (VDDA),
        .VCCD       (VCCD),
        .VSWITCH    (VDDIO),
        .VCCHIB     (VCCD),
        .VSSA       (VSSA),
        .VSSD       (VSSD),
        .VSSIO_Q    (VSSIO_Q),
        .VSSIO      (VSSIO),
        `endif
        .OUT             (spi_cs_n_CORE2PAD),
        .OE_N            (! spi_cs_n_CORE2PAD_OE),
        .HLD_H_N         (spi_cs_n_TIE_HI_ESD),
        .ENABLE_H        (global_enable_PAD2CORE),
        .ENABLE_INP_H    (spi_cs_n_TIE_HI_ESD),
        .ENABLE_VDDA_H   (spi_cs_n_TIE_HI_ESD),
        .ENABLE_VSWITCH_H(spi_cs_n_TIE_HI_ESD),
        .ENABLE_VDDIO    ('1),
        .INP_DIS         ('0),
        .IB_MODE_SEL     ('0),
        .VTRIP_SEL       ('0),
        .SLOW            ('0),
        .HLD_OVR         ('0),
        .ANALOG_EN       ('0),
        .ANALOG_SEL      ('0),
        .ANALOG_POL      ('0),
        .DM              (spi_cs_n_CORE2PAD_OE ? 3'b110 : 3'b001),
        .PAD             (spi_cs_n_PAD),
        .PAD_A_NOESD_H   (),
        .PAD_A_ESD_0_H   (),
        .PAD_A_ESD_1_H   (),
        .AMUXBUS_A       (AMUXBUS_A),
        .AMUXBUS_B       (AMUXBUS_B),
        .IN              (spi_cs_n_PAD2CORE),
        .IN_H            (),
        .TIE_HI_ESD      (spi_cs_n_TIE_HI_ESD),
        .TIE_LO_ESD      (spi_cs_n_TIE_LO_ESD)
    );

    // SPI MOSI
    
    wire spi_mosi_TIE_HI_ESD;
    wire spi_mosi_TIE_LO_ESD;

    sky130_ef_io__gpiov2_pad spi_mosi_pad (
        `ifdef USE_POWER_PINS
        .VDDIO      (VDDIO),
        .VDDIO_Q    (VDDIO_Q),
        .VDDA       (VDDA),
        .VCCD       (VCCD),
        .VSWITCH    (VDDIO),
        .VCCHIB     (VCCD),
        .VSSA       (VSSA),
        .VSSD       (VSSD),
        .VSSIO_Q    (VSSIO_Q),
        .VSSIO      (VSSIO),
        `endif
        .OUT             (spi_mosi_CORE2PAD),
        .OE_N            (! spi_mosi_CORE2PAD_OE),
        .HLD_H_N         (spi_mosi_TIE_HI_ESD),
        .ENABLE_H        (global_enable_PAD2CORE),
        .ENABLE_INP_H    (spi_mosi_TIE_HI_ESD),
        .ENABLE_VDDA_H   (spi_mosi_TIE_HI_ESD),
        .ENABLE_VSWITCH_H(spi_mosi_TIE_HI_ESD),
        .ENABLE_VDDIO    ('1),
        .INP_DIS         ('0),
        .IB_MODE_SEL     ('0),
        .VTRIP_SEL       ('0),
        .SLOW            ('0),
        .HLD_OVR         ('0),
        .ANALOG_EN       ('0),
        .ANALOG_SEL      ('0),
        .ANALOG_POL      ('0),
        .DM              (spi_mosi_CORE2PAD_OE ? 3'b110 : 3'b001),
        .PAD             (spi_mosi_PAD),
        .PAD_A_NOESD_H   (),
        .PAD_A_ESD_0_H   (),
        .PAD_A_ESD_1_H   (),
        .AMUXBUS_A       (AMUXBUS_A),
        .AMUXBUS_B       (AMUXBUS_B),
        .IN              (spi_mosi_PAD2CORE),
        .IN_H            (),
        .TIE_HI_ESD      (spi_mosi_TIE_HI_ESD),
        .TIE_LO_ESD      (spi_mosi_TIE_LO_ESD)
    );

    // SPI MISO
    
    wire spi_miso_TIE_HI_ESD;
    wire spi_miso_TIE_LO_ESD;

    sky130_ef_io__gpiov2_pad spi_miso_pad (
        `ifdef USE_POWER_PINS
        .VDDIO      (VDDIO),
        .VDDIO_Q    (VDDIO_Q),
        .VDDA       (VDDA),
        .VCCD       (VCCD),
        .VSWITCH    (VDDIO),
        .VCCHIB     (VCCD),
        .VSSA       (VSSA),
        .VSSD       (VSSD),
        .VSSIO_Q    (VSSIO_Q),
        .VSSIO      (VSSIO),
        `endif
        .OUT             (spi_miso_CORE2PAD),
        .OE_N            (! spi_miso_CORE2PAD_OE),
        .HLD_H_N         (spi_miso_TIE_HI_ESD),
        .ENABLE_H        (global_enable_PAD2CORE),
        .ENABLE_INP_H    (spi_miso_TIE_HI_ESD),
        .ENABLE_VDDA_H   (spi_miso_TIE_HI_ESD),
        .ENABLE_VSWITCH_H(spi_miso_TIE_HI_ESD),
        .ENABLE_VDDIO    ('1),
        .INP_DIS         ('0),
        .IB_MODE_SEL     ('0),
        .VTRIP_SEL       ('0),
        .SLOW            ('0),
        .HLD_OVR         ('0),
        .ANALOG_EN       ('0),
        .ANALOG_SEL      ('0),
        .ANALOG_POL      ('0),
        .DM              (spi_miso_CORE2PAD_OE ? 3'b110 : 3'b001),
        .PAD             (spi_miso_PAD),
        .PAD_A_NOESD_H   (),
        .PAD_A_ESD_0_H   (),
        .PAD_A_ESD_1_H   (),
        .AMUXBUS_A       (AMUXBUS_A),
        .AMUXBUS_B       (AMUXBUS_B),
        .IN              (spi_miso_PAD2CORE),
        .IN_H            (),
        .TIE_HI_ESD      (spi_miso_TIE_HI_ESD),
        .TIE_LO_ESD      (spi_miso_TIE_LO_ESD)
    );

    // FPGA Select

    generate
    for (genvar i=0; i<2; i++) begin : fpga_selects
        wire TIE_HI_ESD;
        wire TIE_LO_ESD;
    
        sky130_ef_io__gpiov2_pad fpga_select_pad (
            `ifdef USE_POWER_PINS
            .VDDIO      (VDDIO),
            .VDDIO_Q    (VDDIO_Q),
            .VDDA       (VDDA),
            .VCCD       (VCCD),
            .VSWITCH    (VDDIO),
            .VCCHIB     (VCCD),
            .VSSA       (VSSA),
            .VSSD       (VSSD),
            .VSSIO_Q    (VSSIO_Q),
            .VSSIO      (VSSIO),
            `endif
            .OUT             ('0),
            .OE_N            ('1),
            .HLD_H_N         (TIE_HI_ESD),
            .ENABLE_H        (global_enable_PAD2CORE),
            .ENABLE_INP_H    (TIE_HI_ESD),
            .ENABLE_VDDA_H   (TIE_HI_ESD),
            .ENABLE_VSWITCH_H(TIE_HI_ESD),
            .ENABLE_VDDIO    ('1),
            .INP_DIS         ('0),
            .IB_MODE_SEL     ('0),
            .VTRIP_SEL       ('0),
            .SLOW            ('0),
            .HLD_OVR         ('0),
            .ANALOG_EN       ('0),
            .ANALOG_SEL      ('0),
            .ANALOG_POL      ('0),
            .DM              (3'b001),
            .PAD             (fpga_select_PAD[i]),
            .PAD_A_NOESD_H   (),
            .PAD_A_ESD_0_H   (),
            .PAD_A_ESD_1_H   (),
            .AMUXBUS_A       (AMUXBUS_A),
            .AMUXBUS_B       (AMUXBUS_B),
            .IN              (fpga_select_PAD2CORE[i]),
            .IN_H            (),
            .TIE_HI_ESD      (TIE_HI_ESD),
            .TIE_LO_ESD      (TIE_LO_ESD)
        );
    end
    endgenerate

    // Config Busy

    wire config_busy_TIE_HI_ESD;
    wire config_busy_TIE_LO_ESD;

    sky130_ef_io__gpiov2_pad config_busy_pad (
        `ifdef USE_POWER_PINS
        .VDDIO      (VDDIO),
        .VDDIO_Q    (VDDIO_Q),
        .VDDA       (VDDA),
        .VCCD       (VCCD),
        .VSWITCH    (VDDIO),
        .VCCHIB     (VCCD),
        .VSSA       (VSSA),
        .VSSD       (VSSD),
        .VSSIO_Q    (VSSIO_Q),
        .VSSIO      (VSSIO),
        `endif
        .OUT             (config_busy_CORE2PAD),
        .OE_N            ('0),
        .HLD_H_N         (config_busy_TIE_HI_ESD),
        .ENABLE_H        (global_enable_PAD2CORE),
        .ENABLE_INP_H    (config_busy_TIE_HI_ESD),
        .ENABLE_VDDA_H   (config_busy_TIE_HI_ESD),
        .ENABLE_VSWITCH_H(config_busy_TIE_HI_ESD),
        .ENABLE_VDDIO    ('1),
        .INP_DIS         ('0),
        .IB_MODE_SEL     ('0),
        .VTRIP_SEL       ('0),
        .SLOW            ('0),
        .HLD_OVR         ('0),
        .ANALOG_EN       ('0),
        .ANALOG_SEL      ('0),
        .ANALOG_POL      ('0),
        .DM              (3'b110),
        .PAD             (config_busy_PAD),
        .PAD_A_NOESD_H   (),
        .PAD_A_ESD_0_H   (),
        .PAD_A_ESD_1_H   (),
        .AMUXBUS_A       (AMUXBUS_A),
        .AMUXBUS_B       (AMUXBUS_B),
        .IN              (),
        .IN_H            (),
        .TIE_HI_ESD      (config_busy_TIE_HI_ESD),
        .TIE_LO_ESD      (config_busy_TIE_LO_ESD)
    );

    generate
    for (genvar i=0; i<NUM_BIDIR_PADS; i++) begin : bidirs
        wire TIE_HI_ESD;
        wire TIE_LO_ESD;
    
        sky130_ef_io__gpiov2_pad bidir_pad (
            `ifdef USE_POWER_PINS
            .VDDIO      (VDDIO),
            .VDDIO_Q    (VDDIO_Q),
            .VDDA       (VDDA),
            .VCCD       (VCCD),
            .VSWITCH    (VDDIO),
            .VCCHIB     (VCCD),
            .VSSA       (VSSA),
            .VSSD       (VSSD),
            .VSSIO_Q    (VSSIO_Q),
            .VSSIO      (VSSIO),
            `endif
            .OUT             (bidir_CORE2PAD[i]),
            .OE_N            (! bidir_CORE2PAD_OE[i]),
            .HLD_H_N         (TIE_HI_ESD),
            .ENABLE_H        (global_enable_PAD2CORE),
            .ENABLE_INP_H    (TIE_HI_ESD),
            .ENABLE_VDDA_H   (TIE_HI_ESD),
            .ENABLE_VSWITCH_H(TIE_HI_ESD),
            .ENABLE_VDDIO    ('1),
            .INP_DIS         ('0),
            .IB_MODE_SEL     ('0),
            .VTRIP_SEL       ('0),
            .SLOW            ('0),
            .HLD_OVR         ('0),
            .ANALOG_EN       ('0),
            .ANALOG_SEL      ('0),
            .ANALOG_POL      ('0),
            .DM              (bidir_CORE2PAD_OE[i] ? 3'b110 : 3'b001),
            .PAD             (bidir_PAD[i]),
            .PAD_A_NOESD_H   (),
            .PAD_A_ESD_0_H   (),
            .PAD_A_ESD_1_H   (),
            .AMUXBUS_A       (AMUXBUS_A),
            .AMUXBUS_B       (AMUXBUS_B),
            .IN              (bidir_PAD2CORE[i]),
            .IN_H            (),
            .TIE_HI_ESD      (TIE_HI_ESD),
            .TIE_LO_ESD      (TIE_LO_ESD)
        );
    end
    endgenerate

    // Core design

    (* keep *) chip_core #(
        .NUM_BIDIR_PADS  (NUM_BIDIR_PADS)
    ) i_chip_core (
        .clk_i          (clk_PAD2CORE),
        .rst_ni         (rst_n_PAD2CORE),
        
        .spi_mode_i     (spi_mode_PAD2CORE),
    
        .spi_sclk_i     (spi_sclk_PAD2CORE),
        .spi_sclk_o     (spi_sclk_CORE2PAD),
        .spi_sclk_en_o  (spi_sclk_CORE2PAD_OE),
            
        .spi_cs_n_i     (spi_cs_n_PAD2CORE),
        .spi_cs_n_o     (spi_cs_n_CORE2PAD),
        .spi_cs_n_en_o  (spi_cs_n_CORE2PAD_OE),
            
        .spi_mosi_i     (spi_mosi_PAD2CORE),
        .spi_mosi_o     (spi_mosi_CORE2PAD),
        .spi_mosi_en_o  (spi_mosi_CORE2PAD_OE),
            
        .spi_miso_i     (spi_miso_PAD2CORE),
        .spi_miso_o     (spi_miso_CORE2PAD),
        .spi_miso_en_o  (spi_miso_CORE2PAD_OE),

        .fpga_select_i  (fpga_select_PAD2CORE),

        .config_busy_o  (config_busy_CORE2PAD),
        .config_done_o  ( ),
        
        .bidir_in   (bidir_PAD2CORE),
        .bidir_out  (bidir_CORE2PAD),
        .bidir_oe   (bidir_CORE2PAD_OE)
    );
    
    // Logos
    
    (* keep *) caravel_logo caravel_logo ();
    (* keep *) caravel_motto caravel_motto ();
    (* keep *) open_source open_source ();
    (* keep *) project_id_textblock project_id_textblock ();
    (* keep *) logo_fabulous logo_fabulous ();

endmodule

`default_nettype wire
