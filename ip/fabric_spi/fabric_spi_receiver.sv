// SPDX-FileCopyrightText: © 2025 Leo Moser <leo.moser@pm.me>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

/*
This SPI receiver waits until it has received 4 bytes of data over SPI.
Once 4 bytes have been received, the 32 bit word is written to
bitstream_data_o and bitstream_valid_o is pulsed.
*/

module fabric_spi_receiver (
    input  logic  clk_i,
    input  logic  rst_ni,
    
    // Bitstream data
    output logic [31:0] bitstream_data_o,
    output logic        bitstream_valid_o,
    
    // Enable the SPI receiver
    input logic  enable_i,
    
    // SPI
    input  logic sclk_i,
    input  logic cs_ni,
    input  logic mosi_i,
    output logic miso_o
);
    // CPOL = 0, CPHA = 0

    logic [31:0] shift_register;
    logic [4:0] shift_cnt;
    
    // Detect spi_clk edge
    logic spi_sclk_delayed;
    always_ff @(posedge clk_i) begin
        spi_sclk_delayed <= sclk_i;
    end
    
    logic spi_sclk_falling, spi_sclk_rising;
    assign spi_sclk_rising = !spi_sclk_delayed && sclk_i;
    assign spi_sclk_falling = spi_sclk_delayed && !sclk_i;
    
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if (!rst_ni) begin
            shift_register <= '0;
            shift_cnt      <= '0;
            bitstream_valid_o <= 1'b0;
        end else begin
            bitstream_valid_o <= 1'b0;
        
            if (enable_i && !cs_ni && spi_sclk_falling) begin
                // Read the command
                shift_register <= {shift_register[30:0], mosi_i};
                shift_cnt <= shift_cnt + 1;
                
                if (shift_cnt == 31) begin
                    bitstream_valid_o <= 1'b1;
                end
            end
        end
    end
    
    assign bitstream_data_o = shift_register;
    assign miso_o = 1'b0;

endmodule
