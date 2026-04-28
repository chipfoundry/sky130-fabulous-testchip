// SPDX-FileCopyrightText: © 2025 LibreLane Template Contributors
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
    parameter NUM_BIDIR_PADS  = 45
    )(
    `ifdef USE_POWER_PINS
    inout  wire [NUM_VCCD_PADS -1:0] VCCD_PAD,
    inout  wire [NUM_VSSD_PADS -1:0] VSSD_PAD,
    inout  wire [NUM_VDDIO_PADS-1:0] VDDIO_PAD,
    inout  wire [NUM_VSSIO_PADS-1:0] VSSIO_PAD,
    `endif
    inout  wire clk_PAD,
    inout  wire rst_n_PAD,
    inout  wire [NUM_BIDIR_PADS-1:0] bidir_PAD
);
    `ifdef USE_POWER_PINS
    wire VDDIO;
    wire VSSIO;
    wire VCCD;
    wire VSSD;
    
    wire VSWITCH;
    wire VCCHIB;
    wire VDDA;
    wire VSSA;
    
    // VDDIO_Q/VSSIO_Q are connected to VDDIO/VSSIO
    // through metal resistors in the pad cells
    wire VDDIO_Q;
    wire VSSIO_Q;

    wire AMUXBUS_A;
    wire AMUXBUS_B;
    `endif

    wire clk_PAD2CORE;
    wire rst_n_PAD2CORE;
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
        .ENABLE_H        (clock_TIE_HI_ESD),
        .ENABLE_INP_H    (clock_TIE_HI_ESD),
        .ENABLE_VDDA_H   (clock_TIE_LO_ESD),
        .ENABLE_VSWITCH_H(clock_TIE_LO_ESD),
        .ENABLE_VDDIO    ('1),
        .INP_DIS         ('0),
        .IB_MODE_SEL     ('0),
        .VTRIP_SEL       ('0),
        .SLOW            ('0),
        .HLD_OVR         ('0),
        .ANALOG_EN       ('0),
        .ANALOG_SEL      ('0),
        .ANALOG_POL      ('0),
        .DM              ('0),
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
        .ENABLE_H        (reset_TIE_HI_ESD),
        .ENABLE_INP_H    (reset_TIE_HI_ESD),
        .ENABLE_VDDA_H   (reset_TIE_LO_ESD),
        .ENABLE_VSWITCH_H(reset_TIE_LO_ESD),
        .ENABLE_VDDIO    ('1),
        .INP_DIS         ('0),
        .IB_MODE_SEL     ('0),
        .VTRIP_SEL       ('0),
        .SLOW            ('0),
        .HLD_OVR         ('0),
        .ANALOG_EN       ('0),
        .ANALOG_SEL      ('0),
        .ANALOG_POL      ('0),
        .DM              ('0),
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
            .ENABLE_H        (TIE_HI_ESD),
            .ENABLE_INP_H    (TIE_HI_ESD),
            .ENABLE_VDDA_H   (TIE_LO_ESD),
            .ENABLE_VSWITCH_H(TIE_LO_ESD),
            .ENABLE_VDDIO    ('1),
            .INP_DIS         ('0),
            .IB_MODE_SEL     ('0),
            .VTRIP_SEL       ('0),
            .SLOW            ('0),
            .HLD_OVR         ('0),
            .ANALOG_EN       ('0),
            .ANALOG_SEL      ('0),
            .ANALOG_POL      ('0),
            .DM              ('0),
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
        .clk        (clk_PAD2CORE),
        .rst_n      (rst_n_PAD2CORE),
        .bidir_in   (bidir_PAD2CORE),
        .bidir_out  (bidir_CORE2PAD),
        .bidir_oe   (bidir_CORE2PAD_OE)
    );

endmodule

`default_nettype wire
