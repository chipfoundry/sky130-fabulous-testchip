// SPDX-FileCopyrightText: © 2026 Leo Moser
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module chip_core #(
    parameter NUM_BIDIR_PADS
    )(
    input  logic clk,       // clock
    input  logic rst_n,     // reset (active low)
    
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


    assign spi_sclk_o = '0;
    assign spi_sclk_en_o = '0;
    

    assign spi_cs_n_o = '0;
    assign spi_cs_n_en_o = '0;
    

    assign spi_mosi_o = '0;
    assign spi_mosi_en_o = '0;
    

    assign spi_miso_o = '0;
    assign spi_miso_en_o = '0;

    assign config_busy_o = '0;
    assign config_done_o = '0;

    // Pinout:
    // 0 - clock
    // 1 - reset
    // 3:2 - FPGA select
    // 4 - active/passive select
    // 8:5 - SPI

    // -----------------

    // Reset with asynchronous assertion and synchronous relase
    logic [1:0] rst_nd;
    logic rst_n_sync;
    
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            rst_nd <= '0;
        end else begin
            rst_nd[0] <= 1'b1;
            rst_nd[1] <= rst_nd[0];
        end
    end
    
    assign rst_n_sync = rst_nd[1];
    
    // -----------------
    
    
    // At startup, trigger configuration
    // when fpga_mode_sync == 1'b0
    logic startup_trigger;
    always_ff @(posedge clk, negedge rst_n_sync) begin
        if (!rst_n_sync) begin
            startup_trigger <= 1'b1;
        end else begin
            startup_trigger <= 1'b0;
        end
    end

/*
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

    always_comb begin
        // On reset, set SPI to tri-state
        if (!fpga_rst_n_sync) begin
            // Default output
            fpga_sclk_o = 1'b0;
            fpga_cs_n_o = 1'b0;
            fpga_mosi_o = 1'b0;
            fpga_miso_o = 1'b0;
        
            // Tri-state
            fpga_sclk_en_o = 1'b0;
            fpga_cs_n_en_o = 1'b0;
            fpga_mosi_en_o = 1'b0;
            fpga_miso_en_o = 1'b0;
            
            // Receiver not selected
            spi_receiver_sclk_i = 1'b0;
            spi_receiver_cs_ni  = 1'b1;
            spi_receiver_mosi_i = 1'b0;
            
            // Controller not selected
            spi_controller_miso_i = 1'b0;
            
            // No bitstream
            spi_bitstream_data  = '0;
            spi_bitstream_valid = '0;
            
            // Slot and trigger
            spi_controller_slot_i   = '0;
            spi_controller_start_i  = '0;
        end else begin
            // Default output
            fpga_sclk_o = 1'b0;
            fpga_cs_n_o = 1'b0;
            fpga_mosi_o = 1'b0;
            fpga_miso_o = 1'b0;
            
            // Receiver not selected
            spi_receiver_sclk_i = 1'b0;
            spi_receiver_cs_ni  = 1'b1;
            spi_receiver_mosi_i = 1'b0;
            
            // Controller not selected
            spi_controller_miso_i = 1'b0;

            if (fpga_mode_sync == 1'b0) begin
                // SPI Controller
                fpga_sclk_en_o = 1'b1;
                fpga_cs_n_en_o = 1'b1;
                fpga_mosi_en_o = 1'b1;
                fpga_miso_en_o = 1'b0;
                
                fpga_sclk_o = spi_controller_sclk_o;
                fpga_cs_n_o = spi_controller_cs_no;
                fpga_mosi_o = spi_controller_mosi_o;
                spi_controller_miso_i = fpga_miso_i;
                
                // Re-route bitstream
                spi_bitstream_data  = spi_controller_bitstream_data_o;
                spi_bitstream_valid = spi_controller_bitstream_valid_o;
                
                // Slot and trigger
                spi_controller_slot_i   = startup_trigger ? '0 : fpga_config_slot_i; // Always boot from slot 0
                spi_controller_start_i  = startup_trigger || (fpga_config_trigger_i && !(fabric_config_busy || fabric_spi_controller_busy));
                
            end else begin
                // SPI receiver
                fpga_sclk_en_o = 1'b0;
                fpga_cs_n_en_o = 1'b0;
                fpga_mosi_en_o = 1'b0;
                fpga_miso_en_o = 1'b1;
                
                spi_receiver_sclk_i = fpga_sclk_i;
                spi_receiver_cs_ni  = fpga_cs_n_i;
                spi_receiver_mosi_i = fpga_mosi_i;
                fpga_miso_o = spi_receiver_miso_o;
                
                // Re-route bitstream
                spi_bitstream_data  = spi_receiver_bitstream_data_o;
                spi_bitstream_valid = spi_receiver_bitstream_valid_o;
                
                // Slot and trigger
                spi_controller_slot_i   = '0;
                spi_controller_start_i  = '0;
            end
        end
    end
    
    fabric_spi_receiver fabric_spi_receiver (
        .clk_i  (fpga_clk_i),
        .rst_ni (fpga_rst_n_sync),
        
        // Bitstream data
        .bitstream_data_o   (spi_receiver_bitstream_data_o),
        .bitstream_valid_o  (spi_receiver_bitstream_valid_o),
        
        // Enable the SPI receiver
        .enable_i   (fpga_mode_sync == 1'b1),
        
        // SPI
        .sclk_i     (spi_receiver_sclk_i),
        .cs_ni      (spi_receiver_cs_ni),
        .mosi_i     (spi_receiver_mosi_i),
        .miso_o     (spi_receiver_miso_o)
    );

    // bitstream size: 0x1698
    // bitstream word size: 0x5A6
    fabric_spi_controller #(
        .BITSTREAM_LENGTH_WORDS (32'h5A6), // TODO
        .SLOT_OFFSET_WORDS      (32'h800), // TODO
        .NUM_SLOTS              (1)
    ) fabric_spi_controller (
        .clk_i  (clk_),
        .rst_ni (rst_n_sync),
        
        // Start reading data at selected slot
        .start_i    (startup_trigger),
        .slot_i     ('0),
        
        // Bitstream data
        .bitstream_data_o    (spi_controller_bitstream_data_o),
        .bitstream_valid_o   (spi_controller_bitstream_valid_o),
        
        // Reading in progress
        .busy_o     (fabric_spi_controller_busy),
        
        // SPI
        .sclk_o     (spi_controller_sclk_o),
        .cs_no      (spi_controller_cs_no),
        .mosi_o     (spi_controller_mosi_o),
        .miso_i     (spi_controller_miso_i)
    );
*/
    // -----------------

    logic select_output;
    assign select_output = bidir_in[NUM_BIDIR_PADS-1];


    wire [12-1:0]      small_io_west_in_i;
    wire [12-1:0]      small_io_west_out_o;
    wire [12-1:0]      small_io_west_oe_o;

    wire [12-1:0]      small_io_east_in_i;
    wire [12-1:0]      small_io_east_out_o;
    wire [12-1:0]      small_io_east_oe_o;

    wire [12-1:0]      medium_io_west_in_i;
    wire [12-1:0]      medium_io_west_out_o;
    wire [12-1:0]      medium_io_west_oe_o;

    wire [12-1:0]      medium_io_east_in_i;
    wire [12-1:0]      medium_io_east_out_o;
    wire [12-1:0]      medium_io_east_oe_o;

    wire [24-1:0]      large_io_west_in_i;
    wire [24-1:0]      large_io_west_out_o;
    wire [24-1:0]      large_io_west_oe_o;

    wire [12-1:0]      large_io_east_in_i;
    wire [12-1:0]      large_io_east_out_o;
    wire [12-1:0]      large_io_east_oe_o;

    // Set all bidir as output
    assign bidir_oe = rst_n_sync ? (select_output ?
                          {'0, medium_io_east_oe_o, medium_io_west_oe_o, small_io_east_oe_o, small_io_west_oe_o} :
                          {'0, large_io_east_oe_o, large_io_west_oe_o}
                          ) : '0;
    assign bidir_out =  select_output ? 
                          {'1, medium_io_east_out_o, medium_io_west_out_o, small_io_east_out_o, small_io_west_out_o} :
                          {'1, large_io_east_out_o, large_io_west_out_o};
    
    assign small_io_west_in_i = bidir_in[12-1:0];
    assign small_io_east_in_i = bidir_in[24-1:12];

    assign medium_io_west_in_i = bidir_in[36-1:24];
    assign medium_io_east_in_i = bidir_in[48-1:36];

    assign large_io_west_in_i = bidir_in[24-1:0];
    assign large_io_east_in_i = bidir_in[36-1:24];

    // ------------------------------------
    
    logic [1:0] fabric_select;
    assign fabric_select = bidir_in[3:2];
    
    // 45 I/Os

    // 6*2*2=24
    // 6*2*2=24
    // 12*2*2=48
    
    // 6*2+6*4 = 12+24 = 32
    
    // SPI active / passive
    // 4 (3) + 4 (3)
    // bitbang = 2
    // 10 or 8
    
    // select FPGA: 2 pins
    // select output: 1 pin
    
    // TODO reset = tri-state
    // TODO sync reset
    
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
    
    wire [31:0] bitstream_data;
    wire        bitstream_valid;

    fabric_bitbang fabric_bitbang (
        .clk_i   (clk),
        .rst_ni  (rst_n_sync),

        .sample_i (bidir_in[0]),
        .data_i   (bidir_in[1]),

        // Bitstream data
        .bitstream_data_o   (bitstream_data),
        .bitstream_valid_o  (bitstream_valid)
    );

    wire fabric_sys_reset_small;
    wire fabric_sys_reset_medium;
    wire fabric_sys_reset_large;

    fabric_config #(
        .FABRIC_NUM_COLUMNS (FABRIC_SMALL_NUM_COLUMNS),
        .FABRIC_NUM_ROWS    (FABRIC_SMALL_NUM_ROWS)
    ) fabric_config_small (
        .clk_i   (clk),
        .rst_ni  (rst_n_sync),
        
        // Bitstream data
        .bitstream_data_i   (bitstream_data),
        .bitstream_valid_i  (bitstream_valid),
        
        // Configuration in progress
        .busy_o         (fabric_sys_reset_small),
        
        // Fabric is configured
        .configured_o   (),
        
        // To the fabric
        .frame_data_o   (frame_data_small),
        .frame_strobe_o (frame_strobe_small)
    );
    
    fabric_config #(
        .FABRIC_NUM_COLUMNS (FABRIC_MEDIUM_NUM_COLUMNS),
        .FABRIC_NUM_ROWS    (FABRIC_MEDIUM_NUM_ROWS)
    ) fabric_config_medium (
        .clk_i   (clk),
        .rst_ni  (rst_n_sync),
        
        // Bitstream data
        .bitstream_data_i   (bitstream_data),
        .bitstream_valid_i  (bitstream_valid),
        
        // Configuration in progress
        .busy_o         (fabric_sys_reset_medium),
        
        // Fabric is configured
        .configured_o   (),
        
        // To the fabric
        .frame_data_o   (frame_data_medium),
        .frame_strobe_o (frame_strobe_medium)
    );
    
    fabric_config #(
        .FABRIC_NUM_COLUMNS (FABRIC_LARGE_NUM_COLUMNS),
        .FABRIC_NUM_ROWS    (FABRIC_LARGE_NUM_ROWS)
    ) fabric_config_large (
        .clk_i   (clk),
        .rst_ni  (rst_n_sync),
        
        // Bitstream data
        .bitstream_data_i   (bitstream_data),
        .bitstream_valid_i  (bitstream_valid),
        
        // Configuration in progress
        .busy_o         (fabric_sys_reset_large),
        
        // Fabric is configured
        .configured_o   (),
        
        // To the fabric
        .frame_data_o   (frame_data_large),
        .frame_strobe_o (frame_strobe_large)
    );

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
        
        .Tile_X0Y7_SYS_RESET_RESET_top (fabric_sys_reset_small),
        
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
        
        .Tile_X0Y7_SYS_RESET_RESET_top (fabric_sys_reset_medium),
        
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
        
        .Tile_X0Y13_SYS_RESET_RESET_top (fabric_sys_reset_large),
        
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
