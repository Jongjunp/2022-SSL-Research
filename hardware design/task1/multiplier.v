////////////////////////////////////////////////////////////////////////////////
// Multiplier
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps 

module Multiplier
#(
    parameter WIDTH                             = 8,
    parameter INTEGERWIDTH                      = 4,
    parameter FRACTIONWIDTH                     = 4
 )
 (
    input signed wire[WIDTH-1:0]                operand_a,
    input signed wire[WIDTH-1:0]                operand_b,
    //output ports
    output signed logic[WIDTH-1:0]              add_result
 );

    always @ (*) begin
        assign add_result = operand_a + operand_b;
    end
    
endmodule
