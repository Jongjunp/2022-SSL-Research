`timescale 1ns / 1ps 

module tb_rtl;
    reg                         i_clk;
    wire                        i_resetn;
    //parameters
    localparam WIDTH            = 8;
    //signal declarations
    wire [WIDTH-1:0]            op_a;
    wire [WIDTH-1:0]            op_b;
    //output declarations
    wire [WIDTH:0]              add_result;
    wire [(2*WIDTH)-1:0]        mul_result;

    initial i_clk = 1'b0;
    always #2.5 i_clk = -i_clk;

    tester tester
    #(.WIDTH(WIDTH))
    (
        .i_clk(i_clk),
        .o_resetn()o_resetn,

        .op_a(op_a),
        .op_b(op_b),

        .add_result(add_result),
        .mul_result(mul_result)
    );