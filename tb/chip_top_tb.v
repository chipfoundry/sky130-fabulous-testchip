// SPDX-FileCopyrightText: © 2025 Leo Moser <leo.moser@pm.me>
// SPDX-License-Identifier: Apache-2.0

module chip_top_tb;

    `ifdef USE_POWER_PINS
    wire VCCD;
    wire VSSD;
    wire VDDIO;
    wire VSSIO;
    `endif

    wire         clk_PAD;
    wire         rst_n_PAD;

    wire         spi_sclk_PAD;
    wire         spi_cs_n_PAD;
    wire         spi_mosi_PAD;
    wire         spi_miso_PAD;

    wire         spi_mode_PAD;
    
    wire [ 1:0]  fpga_select_PAD;
    
    wire         config_busy_PAD;
    wire         config_done_PAD;

    wire [35:0]  bidir_PAD;
    
    
    wire bidir_PAD_0;
    wire bidir_PAD_1;
    wire bidir_PAD_2;
    wire bidir_PAD_3;
    wire bidir_PAD_4;
    wire bidir_PAD_5;
    wire bidir_PAD_6;
    wire bidir_PAD_7;
    wire bidir_PAD_8;
    wire bidir_PAD_9;
    wire bidir_PAD_10;
    wire bidir_PAD_11;
    wire bidir_PAD_12;
    wire bidir_PAD_13;
    wire bidir_PAD_14;
    wire bidir_PAD_15;
    wire bidir_PAD_16;
    wire bidir_PAD_17;
    wire bidir_PAD_18;
    wire bidir_PAD_19;
    wire bidir_PAD_20;
    wire bidir_PAD_21;
    wire bidir_PAD_22;
    wire bidir_PAD_23;
    wire bidir_PAD_24;
    wire bidir_PAD_25;
    wire bidir_PAD_26;
    wire bidir_PAD_27;
    wire bidir_PAD_28;
    wire bidir_PAD_29;
    wire bidir_PAD_30;
    wire bidir_PAD_31;
    wire bidir_PAD_32;
    wire bidir_PAD_33;
    wire bidir_PAD_34;
    wire bidir_PAD_35;

    `ifdef BITSTREAM_FLASH
    
    // SPI Flash - Bitstream
    spiflash_powered i_spiflash_powered (
	    .csb (spi_cs_n_PAD),
	    .clk (spi_sclk_PAD),
	    .io0 (spi_mosi_PAD), // MOSI
	    .io1 (spi_miso_PAD), // MISO
	    .io2 (  ),
	    .io3 (  )
    );
    
    // Pull down z to 0
    //assign (pull1, pull0) spi_miso_PAD = 1'b0;
    
    `else

    //assign spi_cs_n_PAD = 1'b1;
    //assign spi_sclk_PAD = 1'b0;
    //assign spi_mosi_PAD = 1'b0;
    
    // Required for GL simulation
    pullup(spi_cs_n_PAD);
    pulldown(spi_sclk_PAD);

    `endif

    chip_top chip_top (
      `ifdef USE_POWER_PINS
      .VCCD,
      .VSSD,
      .VDDIO,
      .VSSIO,
      `endif

      .clk_PAD,
      .rst_n_PAD,

      .spi_mode_PAD,

      .spi_sclk_PAD,
      .spi_cs_n_PAD,
      .spi_mosi_PAD,
      .spi_miso_PAD,

      .fpga_select_PAD,

      .config_busy_PAD,
      .config_done_PAD,

      .bidir_PAD ({bidir_PAD_35, bidir_PAD_34, bidir_PAD_33, bidir_PAD_32, bidir_PAD_31, bidir_PAD_30, bidir_PAD_29, bidir_PAD_28, bidir_PAD_27, bidir_PAD_26, bidir_PAD_25, bidir_PAD_24, bidir_PAD_23, bidir_PAD_22, bidir_PAD_21, bidir_PAD_20, bidir_PAD_19, bidir_PAD_18, bidir_PAD_17, bidir_PAD_16, bidir_PAD_15, bidir_PAD_14, bidir_PAD_13, bidir_PAD_12, bidir_PAD_11, bidir_PAD_10, bidir_PAD_9, bidir_PAD_8, bidir_PAD_7, bidir_PAD_6, bidir_PAD_5, bidir_PAD_4, bidir_PAD_3, bidir_PAD_2, bidir_PAD_1, bidir_PAD_0})
  );

endmodule
