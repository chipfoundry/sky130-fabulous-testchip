// Behavioral models for missing Sky130 and Custom cells
// to support simulation without polluting the submodules.

// Sky130 Latch with complementary outputs
module LHQD1 (
    input wire D,
    input wire E,
    output reg Q,
    output reg QN
);
    always @(*) begin
        if (E) begin
            Q = D;
            QN = !D;
        end
    end
endmodule

// Buffered Custom Mux 4:1
module cus_mux41_buf (
    input wire A0, A1, A2, A3, 
    input wire S0, S0N, S1, S1N, 
    output wire X
);
    cus_mux41 core (
        .A0(A0), .A1(A1), .A2(A2), .A3(A3),
        .S0(S0), .S0N(S0N), .S1(S1), .S1N(S1N),
        .X(X)
    );
endmodule

// Buffered Custom Mux 8:1
module cus_mux81_buf (
    input wire A0, A1, A2, A3, A4, A5, A6, A7, 
    input wire S0, S0N, S1, S1N, S2, S2N, 
    output wire X
);
    cus_mux81 core (
        .A0(A0), .A1(A1), .A2(A2), .A3(A3), 
        .A4(A4), .A5(A5), .A6(A6), .A7(A7),
        .S0(S0), .S0N(S0N), .S1(S1), .S1N(S1N), .S2(S2), .S2N(S2N),
        .X(X)
    );
endmodule

// Buffered Custom Mux 16:1
module cus_mux161_buf (
    input wire A0, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, 
    input wire S0, S0N, S1, S1N, S2, S2N, S3, S3N, 
    output wire X
);
    cus_mux161 core (
        .A0(A0), .A1(A1), .A2(A2), .A3(A3), 
        .A4(A4), .A5(A5), .A6(A6), .A7(A7),
        .A8(A8), .A9(A9), .A10(A10), .A11(A11), 
        .A12(A12), .A13(A13), .A14(A14), .A15(A15),
        .S0(S0), .S0N(S0N), .S1(S1), .S1N(S1N), .S2(S2), .S2N(S2N), .S3(S3), .S3N(S3N),
        .X(X)
    );
endmodule
