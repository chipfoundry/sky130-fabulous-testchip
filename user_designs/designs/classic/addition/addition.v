// SPDX-FileCopyrightText: © 2026 FABulous Contributors
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module addition (
    `ifdef CLASSIC_FABRIC_CHIPFOUNDRY_LARGE
    input  wire [5:0] a,
    input  wire [5:0] b,
    output wire [7:0] c
    `else
    input  wire [4:0] a,
    input  wire [4:0] b,
    output wire [9:0] c
    `endif
);

    assign c = a + b;

endmodule
