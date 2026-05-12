// SPDX-FileCopyrightText: © 2026 Leo Moser
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module chip_core #(
    parameter NUM_BIDIR_PADS
    )(
    input  logic clk_i,      // clock
    input  logic rst_ni,     // reset (active low)
    
    // SPI mode
    // if mode == 0: SPI controller
    // if mode == 1: SPI receiver
    input  logic spi_mode_i,
    
    input  logic spi_sclk_i,
    output logic spi_sclk_o,
    output logic spi_sclk_en_o,
    
    input  logic spi_cs_n_i,
    output logic spi_cs_n_o,
    output logic spi_cs_n_en_o,
    
    input  logic spi_mosi_i,
    output logic spi_mosi_o,
    output logic spi_mosi_en_o,
    
    input  logic spi_miso_i,
    output logic spi_miso_o,
    output logic spi_miso_en_o,

    input  logic [1:0] fpga_select_i,

    output logic config_busy_o,
    output logic config_done_o,
    
    // FPGA I/Os
    input  wire [NUM_BIDIR_PADS-1 :0] bidir_in,   // Input value
    output wire [NUM_BIDIR_PADS-1 :0] bidir_out,  // Output value
    output wire [NUM_BIDIR_PADS-1 :0] bidir_oe    // Output enable
);

    // Synchronizers

    logic spi_mode_sync;
    synchronizer synchronizer_spi_mode (
        .clk_i  (clk_i),
        .in_i   (spi_mode_i),
        .out_o  (spi_mode_sync)
    );

    logic [1:0] fpga_select_sync;
    synchronizer #(
        .BITS (2)
    ) synchronizer_fpga_select (
        .clk_i  (clk_i),
        .in_i   (fpga_select_i),
        .out_o  (fpga_select_sync)
    );

    logic spi_sclk_sync, spi_cs_n_sync, spi_mosi_sync, spi_miso_sync;
    synchronizer #(
        .BITS (4)
    ) synchronizer_spi (
        .clk_i  (clk_i),
        .in_i   ({spi_sclk_i, spi_cs_n_i, spi_mosi_i, spi_miso_i}),
        .out_o  ({spi_sclk_sync, spi_cs_n_sync, spi_mosi_sync, spi_miso_sync})
    );

    // Reset with asynchronous assert and synchronous release
    logic [1:0] rst_nd;
    logic rst_n_sync;
    
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if (!rst_ni) begin
            rst_nd <= '0;
        end else begin
            rst_nd[0] <= 1'b1;
            rst_nd[1] <= rst_nd[0];
        end
    end
    
    assign rst_n_sync = rst_nd[1];
    
    // At startup, trigger configuration
    // when fpga_mode_sync == 1'b0
    logic startup_trigger;
    always_ff @(posedge clk_i, negedge rst_n_sync) begin
        if (!rst_n_sync) begin
            startup_trigger <= 1'b1;
        end else begin
            startup_trigger <= 1'b0;
        end
    end

    // SPI receiver
    logic spi_receiver_sclk_i;
    logic spi_receiver_cs_ni;
    logic spi_receiver_mosi_i;
    logic spi_receiver_miso_o;
    
    // SPI controller
    logic spi_controller_sclk_o;
    logic spi_controller_cs_no;
    logic spi_controller_mosi_o;
    logic spi_controller_miso_i;

    logic [31:0] spi_bitstream_data, spi_controller_bitstream_data_o, spi_receiver_bitstream_data_o;
    logic        spi_bitstream_valid, spi_controller_bitstream_valid_o, spi_receiver_bitstream_valid_o;

    always_comb begin
        // On reset, set SPI pins to tri-state
        if (!rst_n_sync) begin
            // Default output
            spi_sclk_o = 1'b0;
            spi_cs_n_o = 1'b0;
            spi_mosi_o = 1'b0;
            spi_miso_o = 1'b0;
        
            // Tri-state
            spi_sclk_en_o = 1'b0;
            spi_cs_n_en_o = 1'b0;
            spi_mosi_en_o = 1'b0;
            spi_miso_en_o = 1'b0;
            
            // Receiver not selected
            spi_receiver_sclk_i = 1'b0;
            spi_receiver_cs_ni  = 1'b1;
            spi_receiver_mosi_i = 1'b0;
            
            // Controller not selected
            spi_controller_miso_i = 1'b0;
            
            // No bitstream
            spi_bitstream_data  = '0;
            spi_bitstream_valid = '0;
        end else begin
            // Default bitstream
            spi_bitstream_data  = '0;
            spi_bitstream_valid = '0;
        
            // Default output
            spi_sclk_o = 1'b0;
            spi_cs_n_o = 1'b0;
            spi_mosi_o = 1'b0;
            spi_miso_o = 1'b0;
            
            // Receiver not selected
            spi_receiver_sclk_i = 1'b0;
            spi_receiver_cs_ni  = 1'b1;
            spi_receiver_mosi_i = 1'b0;
            
            // Controller not selected
            spi_controller_miso_i = 1'b0;

            if (spi_mode_sync == 1'b0) begin
                // SPI Controller
                spi_sclk_en_o = 1'b1;
                spi_cs_n_en_o = 1'b1;
                spi_mosi_en_o = 1'b1;
                spi_miso_en_o = 1'b0;
                
                spi_sclk_o = spi_controller_sclk_o;
                spi_cs_n_o = spi_controller_cs_no;
                spi_mosi_o = spi_controller_mosi_o;
                spi_controller_miso_i = spi_miso_sync;
                
                // Re-route bitstream
                spi_bitstream_data  = spi_controller_bitstream_data_o;
                spi_bitstream_valid = spi_controller_bitstream_valid_o;
            end else begin
                // SPI receiver
                spi_sclk_en_o = 1'b0;
                spi_cs_n_en_o = 1'b0;
                spi_mosi_en_o = 1'b0;
                spi_miso_en_o = 1'b1;
                
                spi_receiver_sclk_i = spi_sclk_sync;
                spi_receiver_cs_ni  = spi_cs_n_sync;
                spi_receiver_mosi_i = spi_mosi_sync;
                spi_miso_o = spi_receiver_miso_o;
                
                // Re-route bitstream
                spi_bitstream_data  = spi_receiver_bitstream_data_o;
                spi_bitstream_valid = spi_receiver_bitstream_valid_o;
            end
        end
    end
    
    fabric_spi_receiver fabric_spi_receiver (
        .clk_i  (clk_i),
        .rst_ni (rst_n_sync),
        
        // Bitstream data
        .bitstream_data_o   (spi_receiver_bitstream_data_o),
        .bitstream_valid_o  (spi_receiver_bitstream_valid_o),
        
        // Enable the SPI receiver
        .enable_i   (spi_mode_sync == 1'b1),
        
        // SPI
        .sclk_i     (spi_receiver_sclk_i),
        .cs_ni      (spi_receiver_cs_ni),
        .mosi_i     (spi_receiver_mosi_i),
        .miso_o     (spi_receiver_miso_o)
    );

    fabric_spi_controller #(
        // Use bitstream length of large fabric
        .BITSTREAM_LENGTH_WORDS (32'h119A),
        .SLOT_OFFSET_WORDS      (32'h119A),
        .NUM_SLOTS              (2)
    ) fabric_spi_controller (
        .clk_i  (clk_i),
        .rst_ni (rst_n_sync),
        
        // Start reading data at selected slot
        .start_i    (startup_trigger && spi_mode_sync == 1'b0),
        .slot_i     ('0),
        
        // Bitstream data
        .bitstream_data_o    (spi_controller_bitstream_data_o),
        .bitstream_valid_o   (spi_controller_bitstream_valid_o),
        
        // Reading in progress
        .busy_o     ( ),
        
        // SPI
        .sclk_o     (spi_controller_sclk_o),
        .cs_no      (spi_controller_cs_no),
        .mosi_o     (spi_controller_mosi_o),
        .miso_i     (spi_controller_miso_i)
    );

    // -----------------

    logic [12-1:0]      small_io_west_in_i;
    logic [12-1:0]      small_io_west_out_o;
    logic [12-1:0]      small_io_west_oe_o;

    logic [12-1:0]      small_io_east_in_i;
    logic [12-1:0]      small_io_east_out_o;
    logic [12-1:0]      small_io_east_oe_o;

    logic [12-1:0]      medium_io_west_in_i;
    logic [12-1:0]      medium_io_west_out_o;
    logic [12-1:0]      medium_io_west_oe_o;

    logic [12-1:0]      medium_io_east_in_i;
    logic [12-1:0]      medium_io_east_out_o;
    logic [12-1:0]      medium_io_east_oe_o;

    logic [24-1:0]      large_io_west_in_i;
    logic [24-1:0]      large_io_west_out_o;
    logic [24-1:0]      large_io_west_oe_o;

    logic [12-1:0]      large_io_east_in_i;
    logic [12-1:0]      large_io_east_out_o;
    logic [12-1:0]      large_io_east_oe_o;

    logic [36-1:0] fpga_in;
    logic [36-1:0] fpga_out;
    logic [36-1:0] fpga_oe;
    
    assign fpga_in = bidir_in[36-1:0];
    assign bidir_out = fpga_out;
    assign bidir_oe = fpga_oe;

    always_comb begin
        // Defaults
        small_io_west_in_i = '0;
        small_io_east_in_i = '0;
        
        medium_io_west_in_i = '0;
        medium_io_east_in_i = '0;
        
        large_io_west_in_i = '0;
        large_io_east_in_i = '0;

        fpga_out = '0;
        fpga_oe  = '0;

        // Reset deasserted
        if (rst_n_sync == 1'b1) begin
            case (fpga_select_sync)
                // Large FPGA
                2'd0: begin
                    large_io_west_in_i = fpga_in[24-1:0];
                    large_io_east_in_i = fpga_in[36-1:24];
                    
                    fpga_out = {large_io_east_out_o, large_io_west_out_o};
                    fpga_oe  = {large_io_east_oe_o, large_io_west_oe_o};
                end
                // Small FPGA
                2'd1: begin
                    small_io_west_in_i = fpga_in[12-1:0];
                    small_io_east_in_i = fpga_in[24-1:12];
                    
                    fpga_out = {12'b0, small_io_east_out_o, small_io_west_out_o};
                    fpga_oe  = {12'b0, small_io_east_oe_o, small_io_west_oe_o};
                end
                // Medium FPGA
                2'd2: begin
                    medium_io_west_in_i = fpga_in[12-1:0];
                    medium_io_east_in_i = fpga_in[24-1:12];
                    
                    fpga_out = {12'b0, medium_io_east_out_o, medium_io_west_out_o};
                    fpga_oe  = {12'b0, medium_io_east_oe_o, medium_io_west_oe_o};
                end
                // No FPGA
                2'd3: begin
                end
            endcase
        end
    end
    
    parameter FABRIC_SMALL_NUM_COLUMNS = 6;
    parameter FABRIC_SMALL_NUM_ROWS = 8;
    
    parameter FABRIC_MEDIUM_NUM_COLUMNS = 10;
    parameter FABRIC_MEDIUM_NUM_ROWS = 8;
    
    parameter FABRIC_LARGE_NUM_COLUMNS = 15;
    parameter FABRIC_LARGE_NUM_ROWS = 14;
    
    parameter FRAME_BITS_PER_ROW = 32;
    parameter MAX_FRAMES_PER_COL = 20;

    wire [(FRAME_BITS_PER_ROW*FABRIC_SMALL_NUM_ROWS)-1:0]    frame_data_small;
    wire [(MAX_FRAMES_PER_COL*FABRIC_SMALL_NUM_COLUMNS)-1:0] frame_strobe_small;
    
    wire [(FRAME_BITS_PER_ROW*FABRIC_MEDIUM_NUM_ROWS)-1:0]    frame_data_medium;
    wire [(MAX_FRAMES_PER_COL*FABRIC_MEDIUM_NUM_COLUMNS)-1:0] frame_strobe_medium;
    
    wire [(FRAME_BITS_PER_ROW*FABRIC_LARGE_NUM_ROWS)-1:0]    frame_data_large;
    wire [(MAX_FRAMES_PER_COL*FABRIC_LARGE_NUM_COLUMNS)-1:0] frame_strobe_large;

    wire config_busy_small;
    wire config_busy_medium;
    wire config_busy_large;

    wire config_done_small;
    wire config_done_medium;
    wire config_done_large;

    fabric_config #(
        .FABRIC_NUM_COLUMNS (FABRIC_SMALL_NUM_COLUMNS),
        .FABRIC_NUM_ROWS    (FABRIC_SMALL_NUM_ROWS)
    ) fabric_config_small (
        .clk_i   (clk_i),
        .rst_ni  (rst_n_sync && fpga_select_sync == 2'd1),
        
        // Bitstream data
        .bitstream_data_i   (spi_bitstream_data),
        .bitstream_valid_i  (spi_bitstream_valid),
        
        // Configuration in progress
        .busy_o         (config_busy_small),
        
        // Fabric is configured
        .configured_o   (config_done_small),
        
        // To the fabric
        .frame_data_o   (frame_data_small),
        .frame_strobe_o (frame_strobe_small)
    );
    
    fabric_config #(
        .FABRIC_NUM_COLUMNS (FABRIC_MEDIUM_NUM_COLUMNS),
        .FABRIC_NUM_ROWS    (FABRIC_MEDIUM_NUM_ROWS)
    ) fabric_config_medium (
        .clk_i   (clk_i),
        .rst_ni  (rst_n_sync && fpga_select_sync == 2'd2),
        
        // Bitstream data
        .bitstream_data_i   (spi_bitstream_data),
        .bitstream_valid_i  (spi_bitstream_valid),
        
        // Configuration in progress
        .busy_o         (config_busy_medium),
        
        // Fabric is configured
        .configured_o   (config_done_medium),
        
        // To the fabric
        .frame_data_o   (frame_data_medium),
        .frame_strobe_o (frame_strobe_medium)
    );
    
    fabric_config #(
        .FABRIC_NUM_COLUMNS (FABRIC_LARGE_NUM_COLUMNS),
        .FABRIC_NUM_ROWS    (FABRIC_LARGE_NUM_ROWS)
    ) fabric_config_large (
        .clk_i   (clk_i),
        .rst_ni  (rst_n_sync && fpga_select_sync == 2'd0),
        
        // Bitstream data
        .bitstream_data_i   (spi_bitstream_data),
        .bitstream_valid_i  (spi_bitstream_valid),
        
        // Configuration in progress
        .busy_o         (config_busy_large),
        
        // Fabric is configured
        .configured_o   (config_done_large),
        
        // To the fabric
        .frame_data_o   (frame_data_large),
        .frame_strobe_o (frame_strobe_large)
    );

    always_comb begin
        // Defaults
        config_busy_o = '0;
        config_done_o = '0;

        // Reset deasserted
        if (rst_n_sync == 1'b1) begin
            case (fpga_select_sync)
                // Large FPGA
                2'd0: begin
                    config_busy_o = config_busy_large;
                    config_done_o = config_done_large;
                end
                // Small FPGA
                2'd1: begin
                    config_busy_o = config_busy_small;
                    config_done_o = config_done_small;
                end
                // Medium FPGA
                2'd2: begin
                    config_busy_o = config_busy_medium;
                    config_done_o = config_done_medium;
                end
                // No FPGA
                2'd3: begin
                end
            endcase
        end
    end
    
    /*
    fabric = "small"


    for i in range(6):
        for j, bel in enumerate(["A", "B"]):
            print(f".Tile_X0Y{1+i}_{bel}_OUT_top ({fabric}_io_west_in_i[{i*2+j}]),")
            print(f".Tile_X0Y{1+i}_{bel}_IN_top  ({fabric}_io_west_out_o[{i*2+j}]),")
            print(f".Tile_X0Y{1+i}_{bel}_EN_top  ({fabric}_io_west_oe_o[{i*2+j}]),")

    for i in range(6):
        for j, bel in enumerate(["A", "B"]):
            print(f".Tile_X5Y{1+i}_{bel}_OUT_top ({fabric}_io_east_in_i[{i*2+j}]),")
            print(f".Tile_X5Y{1+i}_{bel}_IN_top  ({fabric}_io_east_out_o[{i*2+j}]),")
            print(f".Tile_X5Y{1+i}_{bel}_EN_top  ({fabric}_io_east_oe_o[{i*2+j}]),")
    */
    
    classic_fabric_chipfoundry_small i_classic_fabric_chipfoundry_small (
        .FrameData            (frame_data_small),
        .FrameStrobe          (frame_strobe_small),
        
        .Tile_X0Y7_SYS_RESET_RESET_top (config_busy_small),
        
        .Tile_X0Y1_A_OUT_top (small_io_west_in_i[0]),
        .Tile_X0Y1_A_IN_top  (small_io_west_out_o[0]),
        .Tile_X0Y1_A_EN_top  (small_io_west_oe_o[0]),
        .Tile_X0Y1_B_OUT_top (small_io_west_in_i[1]),
        .Tile_X0Y1_B_IN_top  (small_io_west_out_o[1]),
        .Tile_X0Y1_B_EN_top  (small_io_west_oe_o[1]),
        .Tile_X0Y2_A_OUT_top (small_io_west_in_i[2]),
        .Tile_X0Y2_A_IN_top  (small_io_west_out_o[2]),
        .Tile_X0Y2_A_EN_top  (small_io_west_oe_o[2]),
        .Tile_X0Y2_B_OUT_top (small_io_west_in_i[3]),
        .Tile_X0Y2_B_IN_top  (small_io_west_out_o[3]),
        .Tile_X0Y2_B_EN_top  (small_io_west_oe_o[3]),
        .Tile_X0Y3_A_OUT_top (small_io_west_in_i[4]),
        .Tile_X0Y3_A_IN_top  (small_io_west_out_o[4]),
        .Tile_X0Y3_A_EN_top  (small_io_west_oe_o[4]),
        .Tile_X0Y3_B_OUT_top (small_io_west_in_i[5]),
        .Tile_X0Y3_B_IN_top  (small_io_west_out_o[5]),
        .Tile_X0Y3_B_EN_top  (small_io_west_oe_o[5]),
        .Tile_X0Y4_A_OUT_top (small_io_west_in_i[6]),
        .Tile_X0Y4_A_IN_top  (small_io_west_out_o[6]),
        .Tile_X0Y4_A_EN_top  (small_io_west_oe_o[6]),
        .Tile_X0Y4_B_OUT_top (small_io_west_in_i[7]),
        .Tile_X0Y4_B_IN_top  (small_io_west_out_o[7]),
        .Tile_X0Y4_B_EN_top  (small_io_west_oe_o[7]),
        .Tile_X0Y5_A_OUT_top (small_io_west_in_i[8]),
        .Tile_X0Y5_A_IN_top  (small_io_west_out_o[8]),
        .Tile_X0Y5_A_EN_top  (small_io_west_oe_o[8]),
        .Tile_X0Y5_B_OUT_top (small_io_west_in_i[9]),
        .Tile_X0Y5_B_IN_top  (small_io_west_out_o[9]),
        .Tile_X0Y5_B_EN_top  (small_io_west_oe_o[9]),
        .Tile_X0Y6_A_OUT_top (small_io_west_in_i[10]),
        .Tile_X0Y6_A_IN_top  (small_io_west_out_o[10]),
        .Tile_X0Y6_A_EN_top  (small_io_west_oe_o[10]),
        .Tile_X0Y6_B_OUT_top (small_io_west_in_i[11]),
        .Tile_X0Y6_B_IN_top  (small_io_west_out_o[11]),
        .Tile_X0Y6_B_EN_top  (small_io_west_oe_o[11]),
        .Tile_X5Y1_A_OUT_top (small_io_east_in_i[0]),
        .Tile_X5Y1_A_IN_top  (small_io_east_out_o[0]),
        .Tile_X5Y1_A_EN_top  (small_io_east_oe_o[0]),
        .Tile_X5Y1_B_OUT_top (small_io_east_in_i[1]),
        .Tile_X5Y1_B_IN_top  (small_io_east_out_o[1]),
        .Tile_X5Y1_B_EN_top  (small_io_east_oe_o[1]),
        .Tile_X5Y2_A_OUT_top (small_io_east_in_i[2]),
        .Tile_X5Y2_A_IN_top  (small_io_east_out_o[2]),
        .Tile_X5Y2_A_EN_top  (small_io_east_oe_o[2]),
        .Tile_X5Y2_B_OUT_top (small_io_east_in_i[3]),
        .Tile_X5Y2_B_IN_top  (small_io_east_out_o[3]),
        .Tile_X5Y2_B_EN_top  (small_io_east_oe_o[3]),
        .Tile_X5Y3_A_OUT_top (small_io_east_in_i[4]),
        .Tile_X5Y3_A_IN_top  (small_io_east_out_o[4]),
        .Tile_X5Y3_A_EN_top  (small_io_east_oe_o[4]),
        .Tile_X5Y3_B_OUT_top (small_io_east_in_i[5]),
        .Tile_X5Y3_B_IN_top  (small_io_east_out_o[5]),
        .Tile_X5Y3_B_EN_top  (small_io_east_oe_o[5]),
        .Tile_X5Y4_A_OUT_top (small_io_east_in_i[6]),
        .Tile_X5Y4_A_IN_top  (small_io_east_out_o[6]),
        .Tile_X5Y4_A_EN_top  (small_io_east_oe_o[6]),
        .Tile_X5Y4_B_OUT_top (small_io_east_in_i[7]),
        .Tile_X5Y4_B_IN_top  (small_io_east_out_o[7]),
        .Tile_X5Y4_B_EN_top  (small_io_east_oe_o[7]),
        .Tile_X5Y5_A_OUT_top (small_io_east_in_i[8]),
        .Tile_X5Y5_A_IN_top  (small_io_east_out_o[8]),
        .Tile_X5Y5_A_EN_top  (small_io_east_oe_o[8]),
        .Tile_X5Y5_B_OUT_top (small_io_east_in_i[9]),
        .Tile_X5Y5_B_IN_top  (small_io_east_out_o[9]),
        .Tile_X5Y5_B_EN_top  (small_io_east_oe_o[9]),
        .Tile_X5Y6_A_OUT_top (small_io_east_in_i[10]),
        .Tile_X5Y6_A_IN_top  (small_io_east_out_o[10]),
        .Tile_X5Y6_A_EN_top  (small_io_east_oe_o[10]),
        .Tile_X5Y6_B_OUT_top (small_io_east_in_i[11]),
        .Tile_X5Y6_B_IN_top  (small_io_east_out_o[11]),
        .Tile_X5Y6_B_EN_top  (small_io_east_oe_o[11])
    );

    classic_fabric_chipfoundry_medium i_classic_fabric_chipfoundry_medium (
        .FrameData            (frame_data_medium),
        .FrameStrobe          (frame_strobe_medium),
        
        .Tile_X0Y7_SYS_RESET_RESET_top (config_busy_medium),
        
        .Tile_X0Y1_A_OUT_top (medium_io_west_in_i[0]),
        .Tile_X0Y1_A_IN_top  (medium_io_west_out_o[0]),
        .Tile_X0Y1_A_EN_top  (medium_io_west_oe_o[0]),
        .Tile_X0Y1_B_OUT_top (medium_io_west_in_i[1]),
        .Tile_X0Y1_B_IN_top  (medium_io_west_out_o[1]),
        .Tile_X0Y1_B_EN_top  (medium_io_west_oe_o[1]),
        .Tile_X0Y2_A_OUT_top (medium_io_west_in_i[2]),
        .Tile_X0Y2_A_IN_top  (medium_io_west_out_o[2]),
        .Tile_X0Y2_A_EN_top  (medium_io_west_oe_o[2]),
        .Tile_X0Y2_B_OUT_top (medium_io_west_in_i[3]),
        .Tile_X0Y2_B_IN_top  (medium_io_west_out_o[3]),
        .Tile_X0Y2_B_EN_top  (medium_io_west_oe_o[3]),
        .Tile_X0Y3_A_OUT_top (medium_io_west_in_i[4]),
        .Tile_X0Y3_A_IN_top  (medium_io_west_out_o[4]),
        .Tile_X0Y3_A_EN_top  (medium_io_west_oe_o[4]),
        .Tile_X0Y3_B_OUT_top (medium_io_west_in_i[5]),
        .Tile_X0Y3_B_IN_top  (medium_io_west_out_o[5]),
        .Tile_X0Y3_B_EN_top  (medium_io_west_oe_o[5]),
        .Tile_X0Y4_A_OUT_top (medium_io_west_in_i[6]),
        .Tile_X0Y4_A_IN_top  (medium_io_west_out_o[6]),
        .Tile_X0Y4_A_EN_top  (medium_io_west_oe_o[6]),
        .Tile_X0Y4_B_OUT_top (medium_io_west_in_i[7]),
        .Tile_X0Y4_B_IN_top  (medium_io_west_out_o[7]),
        .Tile_X0Y4_B_EN_top  (medium_io_west_oe_o[7]),
        .Tile_X0Y5_A_OUT_top (medium_io_west_in_i[8]),
        .Tile_X0Y5_A_IN_top  (medium_io_west_out_o[8]),
        .Tile_X0Y5_A_EN_top  (medium_io_west_oe_o[8]),
        .Tile_X0Y5_B_OUT_top (medium_io_west_in_i[9]),
        .Tile_X0Y5_B_IN_top  (medium_io_west_out_o[9]),
        .Tile_X0Y5_B_EN_top  (medium_io_west_oe_o[9]),
        .Tile_X0Y6_A_OUT_top (medium_io_west_in_i[10]),
        .Tile_X0Y6_A_IN_top  (medium_io_west_out_o[10]),
        .Tile_X0Y6_A_EN_top  (medium_io_west_oe_o[10]),
        .Tile_X0Y6_B_OUT_top (medium_io_west_in_i[11]),
        .Tile_X0Y6_B_IN_top  (medium_io_west_out_o[11]),
        .Tile_X0Y6_B_EN_top  (medium_io_west_oe_o[11]),
        .Tile_X9Y1_A_OUT_top (medium_io_east_in_i[0]),
        .Tile_X9Y1_A_IN_top  (medium_io_east_out_o[0]),
        .Tile_X9Y1_A_EN_top  (medium_io_east_oe_o[0]),
        .Tile_X9Y1_B_OUT_top (medium_io_east_in_i[1]),
        .Tile_X9Y1_B_IN_top  (medium_io_east_out_o[1]),
        .Tile_X9Y1_B_EN_top  (medium_io_east_oe_o[1]),
        .Tile_X9Y2_A_OUT_top (medium_io_east_in_i[2]),
        .Tile_X9Y2_A_IN_top  (medium_io_east_out_o[2]),
        .Tile_X9Y2_A_EN_top  (medium_io_east_oe_o[2]),
        .Tile_X9Y2_B_OUT_top (medium_io_east_in_i[3]),
        .Tile_X9Y2_B_IN_top  (medium_io_east_out_o[3]),
        .Tile_X9Y2_B_EN_top  (medium_io_east_oe_o[3]),
        .Tile_X9Y3_A_OUT_top (medium_io_east_in_i[4]),
        .Tile_X9Y3_A_IN_top  (medium_io_east_out_o[4]),
        .Tile_X9Y3_A_EN_top  (medium_io_east_oe_o[4]),
        .Tile_X9Y3_B_OUT_top (medium_io_east_in_i[5]),
        .Tile_X9Y3_B_IN_top  (medium_io_east_out_o[5]),
        .Tile_X9Y3_B_EN_top  (medium_io_east_oe_o[5]),
        .Tile_X9Y4_A_OUT_top (medium_io_east_in_i[6]),
        .Tile_X9Y4_A_IN_top  (medium_io_east_out_o[6]),
        .Tile_X9Y4_A_EN_top  (medium_io_east_oe_o[6]),
        .Tile_X9Y4_B_OUT_top (medium_io_east_in_i[7]),
        .Tile_X9Y4_B_IN_top  (medium_io_east_out_o[7]),
        .Tile_X9Y4_B_EN_top  (medium_io_east_oe_o[7]),
        .Tile_X9Y5_A_OUT_top (medium_io_east_in_i[8]),
        .Tile_X9Y5_A_IN_top  (medium_io_east_out_o[8]),
        .Tile_X9Y5_A_EN_top  (medium_io_east_oe_o[8]),
        .Tile_X9Y5_B_OUT_top (medium_io_east_in_i[9]),
        .Tile_X9Y5_B_IN_top  (medium_io_east_out_o[9]),
        .Tile_X9Y5_B_EN_top  (medium_io_east_oe_o[9]),
        .Tile_X9Y6_A_OUT_top (medium_io_east_in_i[10]),
        .Tile_X9Y6_A_IN_top  (medium_io_east_out_o[10]),
        .Tile_X9Y6_A_EN_top  (medium_io_east_oe_o[10]),
        .Tile_X9Y6_B_OUT_top (medium_io_east_in_i[11]),
        .Tile_X9Y6_B_IN_top  (medium_io_east_out_o[11]),
        .Tile_X9Y6_B_EN_top  (medium_io_east_oe_o[11])
    );
    
    classic_fabric_chipfoundry_large i_classic_fabric_chipfoundry_large (
        .FrameData            (frame_data_large),
        .FrameStrobe          (frame_strobe_large),
        
        .Tile_X0Y13_SYS_RESET_RESET_top (config_busy_large),
        
        .Tile_X0Y1_A_OUT_top (large_io_west_in_i[0]),
        .Tile_X0Y1_A_IN_top  (large_io_west_out_o[0]),
        .Tile_X0Y1_A_EN_top  (large_io_west_oe_o[0]),
        .Tile_X0Y1_B_OUT_top (large_io_west_in_i[1]),
        .Tile_X0Y1_B_IN_top  (large_io_west_out_o[1]),
        .Tile_X0Y1_B_EN_top  (large_io_west_oe_o[1]),
        .Tile_X0Y2_A_OUT_top (large_io_west_in_i[2]),
        .Tile_X0Y2_A_IN_top  (large_io_west_out_o[2]),
        .Tile_X0Y2_A_EN_top  (large_io_west_oe_o[2]),
        .Tile_X0Y2_B_OUT_top (large_io_west_in_i[3]),
        .Tile_X0Y2_B_IN_top  (large_io_west_out_o[3]),
        .Tile_X0Y2_B_EN_top  (large_io_west_oe_o[3]),
        .Tile_X0Y3_A_OUT_top (large_io_west_in_i[4]),
        .Tile_X0Y3_A_IN_top  (large_io_west_out_o[4]),
        .Tile_X0Y3_A_EN_top  (large_io_west_oe_o[4]),
        .Tile_X0Y3_B_OUT_top (large_io_west_in_i[5]),
        .Tile_X0Y3_B_IN_top  (large_io_west_out_o[5]),
        .Tile_X0Y3_B_EN_top  (large_io_west_oe_o[5]),
        .Tile_X0Y4_A_OUT_top (large_io_west_in_i[6]),
        .Tile_X0Y4_A_IN_top  (large_io_west_out_o[6]),
        .Tile_X0Y4_A_EN_top  (large_io_west_oe_o[6]),
        .Tile_X0Y4_B_OUT_top (large_io_west_in_i[7]),
        .Tile_X0Y4_B_IN_top  (large_io_west_out_o[7]),
        .Tile_X0Y4_B_EN_top  (large_io_west_oe_o[7]),
        .Tile_X0Y5_A_OUT_top (large_io_west_in_i[8]),
        .Tile_X0Y5_A_IN_top  (large_io_west_out_o[8]),
        .Tile_X0Y5_A_EN_top  (large_io_west_oe_o[8]),
        .Tile_X0Y5_B_OUT_top (large_io_west_in_i[9]),
        .Tile_X0Y5_B_IN_top  (large_io_west_out_o[9]),
        .Tile_X0Y5_B_EN_top  (large_io_west_oe_o[9]),
        .Tile_X0Y6_A_OUT_top (large_io_west_in_i[10]),
        .Tile_X0Y6_A_IN_top  (large_io_west_out_o[10]),
        .Tile_X0Y6_A_EN_top  (large_io_west_oe_o[10]),
        .Tile_X0Y6_B_OUT_top (large_io_west_in_i[11]),
        .Tile_X0Y6_B_IN_top  (large_io_west_out_o[11]),
        .Tile_X0Y6_B_EN_top  (large_io_west_oe_o[11]),
        .Tile_X0Y7_A_OUT_top (large_io_west_in_i[12]),
        .Tile_X0Y7_A_IN_top  (large_io_west_out_o[12]),
        .Tile_X0Y7_A_EN_top  (large_io_west_oe_o[12]),
        .Tile_X0Y7_B_OUT_top (large_io_west_in_i[13]),
        .Tile_X0Y7_B_IN_top  (large_io_west_out_o[13]),
        .Tile_X0Y7_B_EN_top  (large_io_west_oe_o[13]),
        .Tile_X0Y8_A_OUT_top (large_io_west_in_i[14]),
        .Tile_X0Y8_A_IN_top  (large_io_west_out_o[14]),
        .Tile_X0Y8_A_EN_top  (large_io_west_oe_o[14]),
        .Tile_X0Y8_B_OUT_top (large_io_west_in_i[15]),
        .Tile_X0Y8_B_IN_top  (large_io_west_out_o[15]),
        .Tile_X0Y8_B_EN_top  (large_io_west_oe_o[15]),
        .Tile_X0Y9_A_OUT_top (large_io_west_in_i[16]),
        .Tile_X0Y9_A_IN_top  (large_io_west_out_o[16]),
        .Tile_X0Y9_A_EN_top  (large_io_west_oe_o[16]),
        .Tile_X0Y9_B_OUT_top (large_io_west_in_i[17]),
        .Tile_X0Y9_B_IN_top  (large_io_west_out_o[17]),
        .Tile_X0Y9_B_EN_top  (large_io_west_oe_o[17]),
        .Tile_X0Y10_A_OUT_top (large_io_west_in_i[18]),
        .Tile_X0Y10_A_IN_top  (large_io_west_out_o[18]),
        .Tile_X0Y10_A_EN_top  (large_io_west_oe_o[18]),
        .Tile_X0Y10_B_OUT_top (large_io_west_in_i[19]),
        .Tile_X0Y10_B_IN_top  (large_io_west_out_o[19]),
        .Tile_X0Y10_B_EN_top  (large_io_west_oe_o[19]),
        .Tile_X0Y11_A_OUT_top (large_io_west_in_i[20]),
        .Tile_X0Y11_A_IN_top  (large_io_west_out_o[20]),
        .Tile_X0Y11_A_EN_top  (large_io_west_oe_o[20]),
        .Tile_X0Y11_B_OUT_top (large_io_west_in_i[21]),
        .Tile_X0Y11_B_IN_top  (large_io_west_out_o[21]),
        .Tile_X0Y11_B_EN_top  (large_io_west_oe_o[21]),
        .Tile_X0Y12_A_OUT_top (large_io_west_in_i[22]),
        .Tile_X0Y12_A_IN_top  (large_io_west_out_o[22]),
        .Tile_X0Y12_A_EN_top  (large_io_west_oe_o[22]),
        .Tile_X0Y12_B_OUT_top (large_io_west_in_i[23]),
        .Tile_X0Y12_B_IN_top  (large_io_west_out_o[23]),
        .Tile_X0Y12_B_EN_top  (large_io_west_oe_o[23]),
        .Tile_X14Y1_A_OUT_top (large_io_east_in_i[0]),
        .Tile_X14Y1_A_IN_top  (large_io_east_out_o[0]),
        .Tile_X14Y1_A_EN_top  (large_io_east_oe_o[0]),
        .Tile_X14Y2_A_OUT_top (large_io_east_in_i[1]),
        .Tile_X14Y2_A_IN_top  (large_io_east_out_o[1]),
        .Tile_X14Y2_A_EN_top  (large_io_east_oe_o[1]),
        .Tile_X14Y3_A_OUT_top (large_io_east_in_i[2]),
        .Tile_X14Y3_A_IN_top  (large_io_east_out_o[2]),
        .Tile_X14Y3_A_EN_top  (large_io_east_oe_o[2]),
        .Tile_X14Y4_A_OUT_top (large_io_east_in_i[3]),
        .Tile_X14Y4_A_IN_top  (large_io_east_out_o[3]),
        .Tile_X14Y4_A_EN_top  (large_io_east_oe_o[3]),
        .Tile_X14Y5_A_OUT_top (large_io_east_in_i[4]),
        .Tile_X14Y5_A_IN_top  (large_io_east_out_o[4]),
        .Tile_X14Y5_A_EN_top  (large_io_east_oe_o[4]),
        .Tile_X14Y6_A_OUT_top (large_io_east_in_i[5]),
        .Tile_X14Y6_A_IN_top  (large_io_east_out_o[5]),
        .Tile_X14Y6_A_EN_top  (large_io_east_oe_o[5]),
        .Tile_X14Y7_A_OUT_top (large_io_east_in_i[6]),
        .Tile_X14Y7_A_IN_top  (large_io_east_out_o[6]),
        .Tile_X14Y7_A_EN_top  (large_io_east_oe_o[6]),
        .Tile_X14Y8_A_OUT_top (large_io_east_in_i[7]),
        .Tile_X14Y8_A_IN_top  (large_io_east_out_o[7]),
        .Tile_X14Y8_A_EN_top  (large_io_east_oe_o[7]),
        .Tile_X14Y9_A_OUT_top (large_io_east_in_i[8]),
        .Tile_X14Y9_A_IN_top  (large_io_east_out_o[8]),
        .Tile_X14Y9_A_EN_top  (large_io_east_oe_o[8]),
        .Tile_X14Y10_A_OUT_top (large_io_east_in_i[9]),
        .Tile_X14Y10_A_IN_top  (large_io_east_out_o[9]),
        .Tile_X14Y10_A_EN_top  (large_io_east_oe_o[9]),
        .Tile_X14Y11_A_OUT_top (large_io_east_in_i[10]),
        .Tile_X14Y11_A_IN_top  (large_io_east_out_o[10]),
        .Tile_X14Y11_A_EN_top  (large_io_east_oe_o[10]),
        .Tile_X14Y12_A_OUT_top (large_io_east_in_i[11]),
        .Tile_X14Y12_A_IN_top  (large_io_east_out_o[11]),
        .Tile_X14Y12_A_EN_top  (large_io_east_oe_o[11])
    );

endmodule

`default_nettype wire
