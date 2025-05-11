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
// TESTING SYMPLESYSTOLICARRAY MODULE :IN PROGRESS:
    reg clk;
    reg [2:0] YZctrl;
    reg [15:0] 
        a0x, a1x, a2x, a3x;
    reg [15:0] 
        bx0, bx1, bx2, bx3;
    wire rdyGive; // this is to tell the controls that the C matrix is ready to take.
//    wire [31:0] 
//        c00, c01, c02, c03,
//        c10, c11, c12, c13,
//        c20, c21, c22, c23,
//        c30, c31, c32, c33;
    wire [31:0] C [0:3][0:3];
        
// ROM data

wire [15:0] A [0:6][0:3];


assign 
    {A[0][0], A[1][0], A[2][0], A[3][0],
     A[1][1], A[2][1], A[3][1], A[4][1],
     A[2][2], A[3][2], A[4][2], A[5][2],
     A[3][3], A[4][3], A[5][3], A[6][3] }
     =
    {16'd1, 16'd2, 16'd3, 16'd4,       
     16'd5, 16'd6, 16'd7, 16'd8,       
     16'd9, 16'd10, 16'd11, 16'd12,       
     16'd13, 16'd14, 16'd15, 16'd16 };     
/*     
    {16'd1, 16'd0, 16'd0, 16'd0,
     16'd0, 16'd1, 16'd0, 16'd0,
     16'd0, 16'd0, 16'd1, 16'd0,
     16'd0, 16'd0, 16'd0, 16'd1 };
*/

//assign A[0][0] = 16'd1; // 1
assign A[0][1] = 16'b0;
assign A[0][2] = 16'b0;
assign A[0][3] = 16'b0;
//assign A[1][0] = 16'd0; // 0
//assign A[1][1] = 16'd0; // 0
assign A[1][2] = 16'b0;
assign A[1][3] = 16'b0;
//assign A[2][0] = 16'd0; // 0
//assign A[2][1] = 16'd1; // 1
//assign A[2][2] = 16'd0; // 0
assign A[2][3] = 16'b0;
//assign A[3][0] = 16'd0; // 0
//assign A[3][1] = 16'd0; // 0
//assign A[3][2] = 16'd0; // 0
//assign A[3][3] = 16'd0; // 0
assign A[4][0] = 16'b0;
//assign A[4][1] = 16'd0; // 0
//assign A[4][2] = 16'd1; // 1
//assign A[4][3] = 16'd0; // 0
assign A[5][0] = 16'b0;
assign A[5][1] = 16'b0;
//assign A[5][2] = 16'd0; // 0
//assign A[5][3] = 16'd0; // 0
assign A[6][0] = 16'b0;
assign A[6][1] = 16'b0; 
assign A[6][2] = 16'b0;
//assign A[6][3] = 16'd1; // 0


wire [15:0] B [0:6][0:3];
assign 
    {B[0][0], B[1][1], B[2][2], B[3][3],
     B[1][0], B[2][1], B[3][2], B[4][3],
     B[2][0], B[3][1], B[4][2], B[5][3],
     B[3][0], B[4][1], B[5][2], B[6][3] }
     =
    {16'd1, 16'd2, 16'd3, 16'd4,       
     16'd5, 16'd6, 16'd7, 16'd8,       
     16'd9, 16'd10, 16'd11, 16'd12,       
     16'd13, 16'd14, 16'd15, 16'd16 }; 

//assign B[0][0] = 16'd1; // 1
assign B[0][1] = 16'b0;
assign B[0][2] = 16'b0;
assign B[0][3] = 16'b0;
//assign B[1][0] = 16'd0; // 0
//assign B[1][1] = 16'd0; // 0
assign B[1][2] = 16'b0;
assign B[1][3] = 16'b0;
//assign B[2][0] = 16'd0; // 0
//assign B[2][1] = 16'd1; // 1
//assign B[2][2] = 16'd0; // 0
assign B[2][3] = 16'b0;
//assign B[3][0] = 16'd0; // 0
//assign B[3][1] = 16'd0; // 0
//assign B[3][2] = 16'd0; // 0
//assign B[3][3] = 16'd0; // 0
assign B[4][0] = 16'b0;
//assign B[4][1] = 16'd0; // 0
//assign B[4][2] = 16'd1; // 1
//assign B[4][3] = 16'd0; // 0
assign B[5][0] = 16'b0;
assign B[5][1] = 16'b0;
//assign B[5][2] = 16'd0; // 0
//assign B[5][3] = 16'd0; // 0
assign B[6][0] = 16'b0;
assign B[6][1] = 16'b0; 
assign B[6][2] = 16'b0;
//assign B[6][3] = 16'd1; // 0


        
SimpleSystolicArray uut(
    .clk(clk),
    .YZctrl(YZctrl),
    .a0x(a0x), .a1x(a1x), .a2x(a2x), .a3x(a3x),
    .bx0(bx0), .bx1(bx1), .bx2(bx2), .bx3(bx3),
    .rdyGive(rdyGive), // this is to tell the controls that the C matrix is ready to take. 
    .c00(C[0][0]), .c01(C[0][1]), .c02(C[0][2]), .c03(C[0][3]),
    .c10(C[1][0]), .c11(C[1][1]), .c12(C[1][2]), .c13(C[1][3]),
    .c20(C[2][0]), .c21(C[2][1]), .c22(C[2][2]), .c23(C[2][3]),
    .c30(C[3][0]), .c31(C[3][1]), .c32(C[3][2]), .c33(C[3][3]) 
    );   
    reg [3:0] i;
    
    initial begin
        YZctrl = 2'b0;
        clk = 1;
        #10;
        clk = 0;
        i = 0;
        YZctrl = 2'b01;
        for (i = 0; i < 7; i = i + 1) begin  
            {a0x, a1x, a2x, a3x} = {A[i][0], A[i][1], A[i][2], A[i][3]};
            {bx0, bx1, bx2, bx3} = {B[i][0], B[i][1], B[i][2], B[i][3]};
            #1;
            clk = 1;
            #1;
            clk = 0;
            #8;
        end
        while (!rdyGive) begin 
            {a0x, a1x, a2x, a3x} = {16'b0, 16'b0, 16'b0, 16'b0};
            {bx0, bx1, bx2, bx3} = {16'b0, 16'b0, 16'b0, 16'b0};
            clk = 1;
            #1;
            clk = 0;
            #9;
        end
        while (rdyGive) begin 
            YZctrl = 2'b10;
            clk = 1;
            #1;
            clk = 0;
            #9;
        end
       
    end

// TESTING ADDMULTMATRIX MODULE :PASSED:
/*
// Matrix A
    reg [15:0]
        a00, a01, a02, a03,
        a10, a11, a12, a13,
        a20, a21, a22, a23,
        a30, a31, a32, a33;
// Matrix B
    reg [15:0]
        b00, b01, b02, b03,
        b10, b11, b12, b13,
        b20, b21, b22, b23,
        b30, b31, b32, b33;
// Matrix C
    reg [31:0] 
        c00, c01, c02, c03,
        c10, c11, c12, c13,
        c20, c21, c22, c23,
        c30, c31, c32, c33;
    wire [31:0] 
        cp00, cp01, cp02, cp03,
        cp10, cp11, cp12, cp13,
        cp20, cp21, cp22, cp23,
        cp30, cp31, cp32, cp33;
         

addMultMatrix uut(
    .a00(a00), .a01(a01), .a02(a02), .a03(a03),
    .a10(a10), .a11(a11), .a12(a12), .a13(a13),
    .a20(a20), .a21(a21), .a22(a22), .a23(a23),
    .a30(a30), .a31(a31), .a32(a32), .a33(a33),
    
    .b00(b00), .b01(b01), .b02(b02), .b03(b03),
    .b10(b10), .b11(b11), .b12(b12), .b13(b13),
    .b20(b20), .b21(b21), .b22(b22), .b23(b23),
    .b30(b30), .b31(b31), .b32(b32), .b33(b33),
    
    .c00(c00), .c01(c01), .c02(c02), .c03(c03),
    .c10(c10), .c11(c11), .c12(c12), .c13(c13),
    .c20(c20), .c21(c21), .c22(c22), .c23(c23),
    .c30(c30), .c31(c31), .c32(c32), .c33(c33),
    
    .cp00(cp00), .cp01(cp01), .cp02(cp02), .cp03(cp03),
    .cp10(cp10), .cp11(cp11), .cp12(cp12), .cp13(cp13),
    .cp20(cp20), .cp21(cp21), .cp22(cp22), .cp23(cp23),
    .cp30(cp30), .cp31(cp31), .cp32(cp32), .cp33(cp33)
);

initial begin 
  { a00, a01, a02, a03,
    a10, a11, a12, a13,
    a20, a21, a22, a23,
    a30, a31, a32, a33 }
    =
  {  16'd1,  16'd2,  16'd3,  16'd4,
     16'd5,  16'd6,  16'd7,  16'd8,
     16'd9, 16'd10, 16'd11, 16'd12,
    16'd11, 16'd10,  16'd9,  16'd8 };
    
  { b00, b01, b02, b03,
    b10, b11, b12, b13,
    b20, b21, b22, b23,
    b30, b31, b32, b33 }
    =
  {  16'd1,  16'd2,  16'd3,  16'd4,
     16'd5,  16'd6,  16'd7,  16'd8,
     16'd9, 16'd10, 16'd11, 16'd12,
    16'd11, 16'd10,  16'd9,  16'd8 };
    
  { c00, c01, c02, c03,
    c10, c11, c12, c13,
    c20, c21, c22, c23,
    c30, c31, c32, c33 }
    =
  {  32'd2,  32'd2,  32'd2,  32'd2,
     32'd2,  32'd2,  32'd2,  32'd2,
     32'd2,  32'd2,  32'd2,  32'd2,
     32'd2,  32'd2,  32'd2,  32'd2 };

end
*/

// TESTING MATH STANDIN MODULE :PASSED:
/*
reg [15:0] A, B;
    reg [31:0] C;
    wire [31:0] Cp;        

mathStandin uut(
    .A(A), .B(B), .C(C),
    .Cp(Cp)
);

initial begin 
    A = 16'h11; // 17
    B = 16'h02; // 2
    C = 32'h0009;
    // result should be Cp = AB + C = 17*2 + 9 = 43
    // Cp = 31'h002B
    #10;
    A = 16'h11; // 17
    B = 16'h04; // 4
    C = 32'h0008; // 8
   // result should be Cp = AB + C = 17*4 + 8 = 76
    // Cp = 31'h004C
    #10;
    A = 16'h28; // 40
    B = 16'h03; // 3
    C = 32'h004D; // 77
   // result should be Cp = AB + C = 197
    // Cp = 31'h00C5
    #10;
    A = 16'h0E; // 14
    B = 16'h04; // 4
    C = 32'h05A4; // 1444
   // result should be Cp = AB + C = 1500
    // Cp = 31'h05DC
    #10;
    A = 16'h02; // 2
    B = 16'h05; // 5
    C = 32'h0063; // 99
   // result should be Cp = AB + C = 109
    // Cp = 31'h006D

end
*/

// TESTING IEEEHALFPRECISIONMULTIPLIER :FAILED:
/*
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
        
        *//*
        //testing for zero function
        A_val = 16'b0000000000000000; // A_val = 0
        B_val = 16'b0100100000000000; // B_val = 8
        // expecting C_val to be 0
        // 0000000000000000
        *//*
        
        for (i = 0; i < 16; i = i + 1) begin 
            clk = clk + 1'b1;
            #10;
        end
    end
*/ 

endmodule
