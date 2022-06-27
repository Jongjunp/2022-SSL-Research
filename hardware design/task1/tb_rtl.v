`timescale 1ns / 1ps 

module tb_rtl;
    //signal declarations
    reg [3:0]             a, b;
    wire [3:0]            c;

    Adder adder(.a(a), .b(b), .c(c));

    initial begin
        a = 0;
        b = 0;
        #100;
        repeat (1000) begin
            a = a + 1;
            b = b + 2;
            #100;
        end
    end
endmodule