// SPDX-FileCopyrightText: © 2026 FABulous Contributors
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module all_ones (
    `ifdef CLASSIC_FABRIC_CHIPFOUNDRY_LARGE
    output wire [48-1:0] all
    `else
    output wire [24-1:0] all
    `endif
);

    assign all = '1;

endmodule
