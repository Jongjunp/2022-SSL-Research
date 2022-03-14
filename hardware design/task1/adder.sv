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
    parameter BFP8MANTISSAWIDTH                 = 8,
    parameter BFP8EXPONENTWIDTH                 = 8,

    parameter BFPRESULTEXPONENTWIDTH            = 8,
    parameter BFPRESULTMANTISSAWIDTH            = 17,
    parameter BFPTEMPRESULTMANTISSAWIDTH        = 16,
    parameter MACMULCOUNTERWIDTH                = 4,
    parameter PREPROCESSEDWIDTH                 = 9,
    parameter STATENUMBER                       = 7
 )
 (
    //primarily considered input
    input wire                                  clk,
    input wire                                  rst,                      

    //secondarily considered input
    input wire                                  enable_input,
    output logic                                valid_output,
    output logic                                ready_output,

    //input for bfp arithmetics (for MAC, Fused Multiply Add structure)
    input wire                                  bfp_a_sign_input,
    input wire                                  bfp_b_sign_input,
    input wire                                  bfp_c_sign_input,
    input wire [BFP8MANTISSAWIDTH-1:0]          bfp_a_mantissa_input,
    input wire [BFP8MANTISSAWIDTH-1:0]          bfp_b_mantissa_input,
    input wire [BFP8MANTISSAWIDTH-1:0]          bfp_c_mantissa_input,
    input wire [BFP8EXPONENTWIDTH-1:0]          bfp_a_block_exp_input,
    input wire [BFP8EXPONENTWIDTH-1:0]          bfp_b_block_exp_input,
    input wire [BFP8EXPONENTWIDTH-1:0]          bfp_c_block_exp_input,
    output logic                                bfp_result_sign_output,
    output logic [BFPRESULTMANTISSAWIDTH-1:0]   bfp_result_mantissa_output,
    output logic [BFPRESULTEXPONENTWIDTH-1:0]   bfp_result_exponent_output
 );
    ////////////////////////////////////////////////////////////////////////////
    //control module
    ////////////////////////////////////////////////////////////////////////////

    //local parameter and logics
    //1. States - One hot encoding
    localparam S_idle                           =7'b1000000;
    localparam S_MAC_mul_preprocessing          =7'b0100000;
    localparam S_MAC_mul_addition               =7'b0010000;
    localparam S_MAC_mul_shift                  =7'b0001000;
    localparam S_MAC_mul_postprocessing         =7'b0000100;
    localparam S_MAC_add                        =7'b0000010;
    localparam S_result                         =7'b0000001;

    //signals which will be sended to datapath module                         
    logic                                       initialize_all;
    logic                                       load_input;

    logic                                       add_exponent;
    logic                                       mac_mul_add_regs;
    logic                                       mac_mul_shift_regs;
    logic                                       mac_mul_decrease_counter;

    logic                                       mac_mul_postprocessing;

    logic                                       mac_add;

    //Declaration of flip flop to represent the state
    logic [STATENUMBER-1:0]                     state;
    logic [STATENUMBER-1:0]                     next_state;

    //registers to transfer the input values to actual datapath
    logic                                       bfp_a_sign_input_reg;
    logic                                       bfp_b_sign_input_reg;
    logic                                       bfp_c_sign_input_reg;
    logic [BFP8MANTISSAWIDTH-1:0]               bfp_a_mantissa_input_reg;
    logic [BFP8MANTISSAWIDTH-1:0]               bfp_b_mantissa_input_reg;
    logic [BFP8MANTISSAWIDTH-1:0]               bfp_c_mantissa_input_reg;
    logic [BFP8EXPONENTWIDTH-1:0]               bfp_a_exponent_input_reg;
    logic [BFP8EXPONENTWIDTH-1:0]               bfp_b_exponent_input_reg;
    logic [BFP8EXPONENTWIDTH-1:0]               bfp_c_exponent_input_reg;

    logic [BFPTEMPRESULTMANTISSAWIDTH-1:0]      tmp_bfp_result_mantissa_reg;  //before addition, we need to save the value from multiplication
    logic [BFPRESULTEXPONENTWIDTH-1:0]          tmp_bfp_result_exponent_reg;

    logic [MACMULCOUNTERWIDTH-1:0]              mac_mul_counter;
    logic [BFP8MANTISSAWIDTH-1:0]               mac_mul_temp_reg;  //as a role of "Q"
    logic [BFP8EXPONENTWIDTH-1:0]               mac_mul_temp_exp_reg;
    logic                                       mac_mul_temp_sign_reg;
    logic                                       mac_mul_carry;
    logic                                       mac_mul_exp_carry;
    logic                                       mac_add_carry;
    logic                                       mac_add_temp_sign_reg;
    logic [BFPRESULTEXPONENTWIDTH-1:0]          mac_add_temp_exponent_reg;
    logic [BFPRESULTMANTISSAWIDTH-1:0]          mac_add_temp_mantissa_reg;
    logic [BFPRESULTMANTISSAWIDTH-1:0]          mac_add_bfp_a_mantissa_reg;
    assign tmp_bfp_result_mantissa_reg = {mac_mul_temp_reg,bfp_b_mantissa_input_reg};

    //synchronous block
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= S_idle;
        end
        else begin
            state <= next_state;
        end
    end

    //indicate the upcoming next state
    always @ (state,enable_input) begin
        case (state)
            S_idle: begin
                if (enable_input&&~rst) begin
                    next_state <= S_MAC_mul_preprocessing;
                end
                else if (~enable_input&&~rst) begin
                    next_state <= S_result;
                end
                else begin
                    next_state <= S_idle;
                end
            end
            S_MAC_mul_preprocessing: begin
                next_state <= S_MAC_mul_addition;
            end
            S_MAC_mul_addition: begin
                next_state <= S_MAC_mul_shift;
            end
            S_MAC_mul_shift: begin
                if ((mac_mul_counter=={MACMULCOUNTERWIDTH{1'b0}})) begin
                    mac_mul_counter <= 4'b1000;
                    next_state <= S_MAC_mul_postprocessing;
                end
                else begin
                    next_state <= S_MAC_mul_addition;
                end
            end
            S_MAC_mul_postprocessing: begin
                next_state <= S_MAC_add;
            end
            S_MAC_add: begin
                next_state <= S_result;
            end
            S_result: begin
                if (enable_input&&~rst) begin
                    next_state <= S_MAC_mul_preprocessing;
                end
                else if (~enable_input&&~rst) begin
                    next_state <= S_result;
                end
                else begin
                    next_state <= S_idle;
                end
            end
        endcase
    end
    //send the instruction to datapath module wheenver state change
    always @(state) begin
        
        initialize_all <= 0;
        load_input <= 1;
        add_exponent <= 0;
        mac_mul_add_regs <= 0;
        mac_mul_shift_regs <= 0;
        mac_mul_decrease_counter <= 0;
        mac_mul_postprocessing <= 0;
        mac_add <= 0;
        ready_output <= 1;
        valid_output <= 0;

        case (state)
            S_idle: begin
                initialize_all                  <= 1;
            end
            S_MAC_mul_preprocessing: begin
                load_input                      <= 0;
                ready_output                    <= 0;
                add_exponent                    <= 1;
            end
            S_MAC_mul_addition: begin
                load_input                      <= 0;
                ready_output                    <= 0;
                mac_mul_decrease_counter        <= 1;
                if (bfp_b_mantissa_input_reg[0]) begin
                    mac_mul_add_regs            <= 1;
                end
            end
            S_MAC_mul_shift: begin
                load_input                      <= 0;
                ready_output                    <= 0;
                mac_mul_shift_regs              <= 1;
            end
            S_MAC_mul_postprocessing: begin
                load_input                      <= 0;
                ready_output                    <= 0;
                mac_mul_postprocessing          <= 1;
            end 
            S_MAC_add: begin
                load_input                      <= 0;
                ready_output                    <= 0;
                mac_add                         <= 1;       
            end
            S_result: begin 
                valid_output                     <= 1;
            end
            default: begin
                initialize_all                   <= 1;
            end
        endcase
    end

    ////////////////////////////////////////////////////////////////////////////
    //datapath module
    ////////////////////////////////////////////////////////////////////////////
    always @ (posedge clk) begin

        if (initialize_all) begin
            bfp_result_sign_output <= 1'b0;
            bfp_result_exponent_output <= {BFPRESULTEXPONENTWIDTH{1'b0}};
            bfp_result_mantissa_output <= {BFPRESULTMANTISSAWIDTH{1'b0}};
            bfp_a_sign_input_reg <= 1'b0;
            bfp_b_sign_input_reg <= 1'b0;
            bfp_c_sign_input_reg <= 1'b0;
            bfp_a_mantissa_input_reg <= {BFP8MANTISSAWIDTH{1'b0}};
            bfp_b_mantissa_input_reg <= {BFP8MANTISSAWIDTH{1'b0}};
            bfp_c_mantissa_input_reg <= {BFP8MANTISSAWIDTH{1'b0}};
            bfp_a_exponent_input_reg <= {BFP8EXPONENTWIDTH{1'b0}};
            bfp_b_exponent_input_reg <= {BFP8EXPONENTWIDTH{1'b0}};
            bfp_c_exponent_input_reg <= {BFP8EXPONENTWIDTH{1'b0}};
            mac_mul_temp_reg <= {BFP8MANTISSAWIDTH{1'b0}};
            mac_add_carry <= 1'b0;
            mac_mul_carry <= 1'b0;
            mac_add_temp_sign_reg <= 1'b0;
            mac_add_temp_exponent_reg <= {BFPRESULTEXPONENTWIDTH{1'b0}};
            mac_add_temp_mantissa_reg <= {BFPRESULTMANTISSAWIDTH{1'b0}};
            mac_add_bfp_a_mantissa_reg <= {BFPRESULTMANTISSAWIDTH{1'b0}};
            
        end

        if (load_input) begin
            bfp_a_sign_input_reg <= bfp_a_sign_input;
            bfp_b_sign_input_reg <= bfp_b_sign_input;
            bfp_c_sign_input_reg <= bfp_c_sign_input;
            bfp_a_mantissa_input_reg <= bfp_a_mantissa_input;
            bfp_b_mantissa_input_reg <= bfp_b_mantissa_input;
            bfp_c_mantissa_input_reg <= bfp_c_mantissa_input;
            bfp_a_exponent_input_reg <= bfp_a_block_exp_input;
            bfp_b_exponent_input_reg <= bfp_b_block_exp_input;
            bfp_c_exponent_input_reg <= bfp_c_block_exp_input;          
        end

        if (add_exponent) begin
            mac_mul_temp_sign_reg <= bfp_b_sign_input_reg ^ bfp_c_sign_input_reg;
            {mac_mul_exp_carry,mac_mul_temp_exp_reg} <= bfp_b_exponent_input_reg + bfp_c_exponent_input_reg-8'b01111111;
            mac_mul_counter <= 4'b1000;
        end
        if (mac_mul_add_regs) begin
            {mac_mul_carry,mac_mul_temp_reg} <= mac_mul_temp_reg + bfp_c_mantissa_input_reg;
        end
        if (mac_mul_shift_regs) begin
            {mac_mul_carry,mac_mul_temp_reg,bfp_b_mantissa_input_reg} <= {mac_mul_carry,mac_mul_temp_reg,bfp_b_mantissa_input_reg} >> 1;
        end
        if (mac_mul_decrease_counter) begin
            mac_mul_counter <= mac_mul_counter - 1;
        end
        if (mac_mul_postprocessing) begin
            mac_add_temp_mantissa_reg <= {1'b0,tmp_bfp_result_mantissa_reg};
            mac_add_bfp_a_mantissa_reg <= {3'b000,bfp_a_mantissa_input,6'b00000000};
        end
        if (mac_add) begin
            if (!(bfp_a_sign_input_reg^mac_mul_temp_sign_reg)) begin
                bfp_result_sign_output <= bfp_a_sign_input_reg;
                bfp_result_exponent_output <= mac_mul_temp_exp_reg;
                bfp_result_mantissa_output <= mac_add_temp_mantissa_reg+mac_add_bfp_a_mantissa_reg;
            end
            else begin
                if (mac_add_temp_mantissa_reg > mac_add_bfp_a_mantissa_reg) begin
                    bfp_result_sign_output <= mac_mul_temp_sign_reg;
                    bfp_result_exponent_output <= mac_mul_temp_exp_reg;
                    bfp_result_mantissa_output <= mac_add_temp_mantissa_reg-mac_add_bfp_a_mantissa_reg;
                end
                else if (mac_add_temp_mantissa_reg < mac_add_bfp_a_mantissa_reg) begin
                    bfp_result_sign_output <= bfp_a_sign_input_reg;
                    bfp_result_exponent_output <= mac_mul_temp_exp_reg;
                    bfp_result_mantissa_output <= mac_add_bfp_a_mantissa_reg-mac_add_temp_mantissa_reg;
                end
                else begin 
                    bfp_result_sign_output <= 1'b0;
                    bfp_result_exponent_output <= {BFPRESULTEXPONENTWIDTH{1'b0}};
                    bfp_result_mantissa_output <= {BFPRESULTMANTISSAWIDTH{1'b0}};
                end
            end
        end
        else begin
        end
    end
endmodule
