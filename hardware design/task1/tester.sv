`timescale 1ns / 1ps 

module tester #(
    parameter WIDTH                 = 8
)
(
    input wire                  i_clk,
    output logic                o_resetn,

    output logic[WIDTH-1:0]     op_a,
    output logic[WIDTH-1:0]     op_b,

    output logic[WIDTH:0]       add_result,
    output logic[(2*WIDTH)-1:0] mul_result
);

    Adder(op_a, op_b, add_result);
    Multiplier(op_a, op_b, mul_result);

    initial
    begin
        #1;
        #5
        o_resetn = 1'b0;
        #10
        o_resetn = 1'b1;

        #5;
        op_a = 8'b0011_0000;
        op_b = 8'b0001_0100;

        #5;
        op_a = 8'b1111_1100;
        op_b = 8'b0000_0100;

        #100;
        $finish;
    end
    