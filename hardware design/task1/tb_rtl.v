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
    //wire [WIDTH:0]              add_result;
    wire [(2*WIDTH)-1:0]        mul_result;

    Adder adder(op_a, op_b, add_result);
    //Multiplier multiplier(op_a, op_b, mul_result);

    initial i_clk = 1'b0;
    always #2.5 i_clk = -i_clk;

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
endmodule