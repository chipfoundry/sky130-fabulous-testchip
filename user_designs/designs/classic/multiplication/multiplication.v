// SPDX-FileCopyrightText: © 2026 FABulous Contributors
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module multiplication (
    `ifdef CLASSIC_FABRIC_CHIPFOUNDRY_LARGE
    input  wire [ 5:0] a,
    input  wire [ 5:0] b,
    output wire [11:0] product
    `else
    input  wire [ 4:0] a,
    input  wire [ 4:0] b,
    output wire [ 9:0] product
    `endif
);

    assign product = a * b;

endmodule
