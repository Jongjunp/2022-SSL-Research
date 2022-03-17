////////////////////////////////////////////////////////////////////////////////
// Adder
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps 

module Adder
#(
    parameter WIDTH                             = 8,
    parameter INTEGERWIDTH                      = 4,
    parameter FRACTIONWIDTH                     = 4
 )
 (
    //input ports
    input signed wire[WIDTH-1:0]                operand_a,
    input signed wire[WIDTH-1:0]                operand_b,
    //output ports
    output signed logic[WIDTH-1:0]              add_result
 );

    always @ (operand_a, operand_b) begin
        add_result = operand_a + operand_b;
    end
    
endmodule
