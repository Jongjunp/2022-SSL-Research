////////////////////////////////////////////////////////////////////////////////
//Modified BFP FP converter
//
//
// 3. BFP arithmetic
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps 

module BFP_MAC
#(
    parameter FP32WIDTH                         = 32,
    parameter FP32MANTISSAWIDTH                 = 23,
    parameter FP32EXPONENTWIDTH                 = 8,
 )
 (
    //input ports
    input wire[FP32WIDTH-1:0]                   operand_a,
    input wire[FP32WIDTH-1:0]                   operand_b,
    //output ports
    output logic[FP32WIDTH-1:0]                 result
 );

    wire[FP32EXPONENTWIDTH-1:0]                 operand_a_exponent;
    wire[FP32MANTISSAWIDTH-1:0]                 operand_a_mantissa;
    wire                                        operand_a_sign;

    wire[FP32EXPONENTWIDTH-1:0]                 operand_b_exponent;
    wire[FP32MANTISSAWIDTH-1:0]                 operand_b_mantissa;
    wire                                        operand_b_sign;

    wire[FP32EXPONENTWIDTH-1:0]                 result_exponent;
    wire[FP32MANTISSAWIDTH-1:0]                 result_mantissa;
    wire                                        result_sign;

    //sign identification
    if (operand_a_sign == operand_b_sign) begin
        assign result_mantissa = operand_a_mantissa + operand_b_mantissa;

    end
    else begin 

    end



endmodule
