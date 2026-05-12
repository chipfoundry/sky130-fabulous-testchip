// SPDX-FileCopyrightText: © 2026 Leo Moser
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module synchronizer #(
    parameter BITS=1,
    parameter STAGES=2
)(
    input  logic            clk_i,
    input  logic [BITS-1:0] in_i,
    output logic [BITS-1:0] out_o
);

    logic [STAGES-1:0][BITS-1:0] shift_reg;
    
    always_ff @(posedge clk_i) begin
        shift_reg <= {shift_reg[STAGES-2:0], in_i};
    end
    
    assign out_o = shift_reg[STAGES-1];

endmodule

`default_nettype wire
