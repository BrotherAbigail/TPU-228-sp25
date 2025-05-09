`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/09/2025 01:08:47 AM
// Design Name: 
// Module Name: TestBenchTPU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module TestBenchTPU;
    reg reset, clk;
    reg [15:0] A_val, B_val; 
    wire [15:0] C_val;
    wire [3:0] state;
    reg [3:0] i;

ieeeHalfPrecisonMultiplier uut(
    .reset(reset), .clk(clk),
    .A_val(A_val), .B_val(B_val),
    .C_val(C_val), .state(state)
    );   
    
    initial begin 
        reset = 1;
        clk = 0;
        #10;
        clk = 1;
        #10;
        reset = 0;
        
        // testing multiplation.
        A_val = 16'b0100101110000000; // A_val = 15
        B_val = 16'b0100010000000000; // B_val = 4
        // expecting C_val to be 60
        // 0101001110000000
        
        /*
        //testing for zero function
        A_val = 16'b0000000000000000; // A_val = 0
        B_val = 16'b0100100000000000; // B_val = 8
        // expecting C_val to be 0
        // 0000000000000000
        */
        
        for (i = 0; i < 16; i = i + 1) begin 
            clk = clk + 1'b1;
            #10;
        end
    end 

endmodule
