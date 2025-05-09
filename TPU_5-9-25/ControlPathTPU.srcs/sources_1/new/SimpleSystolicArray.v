`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/09/2025 12:58:50 AM
// Design Name: 
// Module Name: SimpleSystolicArray
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
parameter
    A_B_reg_size = 'd15,
    C_reg_size = 'd31;
    

module findlargestOne(
    input clk,
    input [A_B_reg_size:0] number,
    output reg [4:0] sft
    );

    always@(posedge clk) 
        casez (number) 
            16'b1xxxxxxxxxxxxxxx : sft <= 4'd0 ;
            16'b01xxxxxxxxxxxxxx : sft <= 4'd1 ;
            16'b001xxxxxxxxxxxxx : sft <= 4'd2 ;
            16'b0001xxxxxxxxxxxx : sft <= 4'd3 ;
            16'b00001xxxxxxxxxxx : sft <= 4'd4 ;
            16'b000001xxxxxxxxxx : sft <= 4'd5 ;
            16'b0000001xxxxxxxxx : sft <= 4'd6 ;
            16'b00000001xxxxxxxx : sft <= 4'd7 ;
            16'b000000001xxxxxxx : sft <= 4'd8 ;
            16'b0000000001xxxxxx : sft <= 4'd9 ;
            16'b00000000001xxxxx : sft <= 4'd10;
            16'b000000000001xxxx : sft <= 4'd11;
            16'b0000000000001xxx : sft <= 4'd12;
            16'b00000000000001xx : sft <= 4'd13;
            16'b000000000000001x : sft <= 4'd14;
            16'b0000000000000001 : sft <= 4'd15;
            default : sft <= 4'd15;
        endcase
endmodule

module ieeeHalfPrecisonMultiplier(
    input reset, clk,
    input [A_B_reg_size:0] A_val, B_val, 
    output reg [A_B_reg_size:0] C_val,
    output reg [3:0] state
    );
    
    reg [A_B_reg_size:0] C;
    reg s_a, s_b, s_c;
    reg [4:0] a_e, b_e, c_e;
    reg [10:0] a_m, b_m, c_m;
    wire [4:0] shft_a_m, sft_b_m, sft_c_m;
    // reg [3:0] state;
    reg [21:0] product;
    reg guard, round_bit, sticky;

     parameter 
        find_sem       = 4'd1,
        inf_NaN_zero   = 4'd2,
        norm_a         = 4'd3,
        norm_b         = 4'd4,
        mult_0         = 4'd5,
        mult_1         = 4'd6,
        norm_1         = 4'd7,
        norm_2         = 4'd8,
        round          = 4'd9,
        pack_c         = 4'd10,
        return_c       = 4'd11,
        inf            = 15'b111110000000000,
        NaN            = 16'b1111111111111111,
        zero           = 15'b0;

    findlargestOne shift_a_m (clk, a_m, shft_a_m);
    findlargestOne shift_b_m (clk, b_m, shft_b_m);
    findlargestOne shift_c_m (clk, c_m, shft_c_m);
    

    always@(posedge clk) begin 

        if (reset == 1) 
        begin
            C = 32'b0; // WARNING this is 32 bits!!!
            state <= return_c;
        end
        else
            state <= find_sem;

        case (state)
            find_sem : 
            begin 
                s_a <= A_val[15];
                s_b <= B_val[15];
                a_e <= A_val[14:10] - 15;
                b_e <= B_val[14:10] - 15;
                a_m <= A_val[9:0];
                b_m <= B_val[9:0];
                state <= inf_NaN_zero;
            end

            inf_NaN_zero : 
            begin 
                //check for Non-numbers (nan)
                // if a or b is NaN then c is NaN
                if ((a_e == 16 && a_m != 0) || (b_e == 16 && b_m != 0)) 
                begin
                    C = NaN;
                    state <= return_c;
                end
                // check for infitity
                // if a is inf and b is 0, then c is NaN
                // else c is inf
                else if ((a_e == 16) && (a_m == 0))
                    if ($signed(b_e) == -15 && b_m == 0) 
                    begin
                        C = NaN;
                        state <= return_c;
                    end
                    else begin 
                        C[15] = s_a;
                        C[14:0] = inf; 
                        state <= return_c;
                    end

                // if b is inf and a is 0, then c is NaN
                // else c is inf
                else if ((b_e == 16) && (b_m == 0))
                    if ($signed(a_e) == -15 && a_m == 0)begin
                        C = NaN;
                        state <= return_c;
                    end
                    else begin 
                        C[15] = s_b;
                        C[14:0] = inf;
                        state <= return_c;
                    end

                // check for zeros
                // if a or b is zero, than c is zero
                else if (($signed(a_e) == -15 && a_m == 0) || ($signed(b_e) == -16 && b_m == 0)) begin 
                    C[15] = s_a ^ s_b;
                    C[14:0] = zero;
                    state <= return_c;
                end
                else begin
                // Denormalise a exponent
                    if ($signed(a_e) == -15)
                        a_e <= -14;
                    else
                        a_m[10] <= 1;
                // Denormalise b exponent
                    if ($signed(b_e) == -15)
                        b_e <= -14;
                    else
                        b_m[10] <= 1;
                    state <= norm_a;
                end
            end

            // Normalize A
            norm_a : 
            begin 
                a_m <= a_m << shft_a_m;
                a_e <= a_e - shft_a_m;
                state <= norm_b;
            end

            // Normalize B
            norm_b : 
            begin 
                b_m <= a_m << shft_b_m;
                b_e <= b_e - shft_b_m;
                state <= mult_0;
            end
            
            mult_0 : 
            begin 
                s_c <= s_a ^ s_b;
                c_e <= a_e + a_e + 1;
                product <= a_m * b_m;
                state <= mult_1;
            end
            mult_1 : 
            begin 
                c_m <= product[21:12];
                guard <= product[11];
                round_bit <= product[10];
                sticky <= (product[9:0] != 0);
                state <= norm_1;
            end

            norm_1 :
            begin
                if (c_m[10] == 0) begin
                    c_e <= c_e - 1;
                    c_m <= c_m << 1;
                    c_m[0] <= guard;
                    guard <= round_bit;
                    round_bit <= 0;
                end
                state <= norm_2;
            end
            norm_2:
            begin
                if ($signed(c_e) < -15) begin
                    c_e <= c_e + 1;
                    c_m <= c_m >> 1;
                    guard <= c_m[0];
                    round_bit <= guard;
                    sticky <= sticky | round_bit;
                end
                state <= round;
            end
            round : 
            begin 
                if (guard && (round_bit | sticky | c_m[0])) begin
                c_m <= c_m + 1;
                if (c_m == 10'b1)
                    c_e <=c_e + 1;
                end
                state <=pack_c;
            end
            pack_c : 
            begin 
                C[9:0] <= c_m[9:0];
                C[14:10] <= c_e[4:0] + 15;
                C[15] = s_c;
                if ($signed(c_e) == -15 && c_m[10] == 0)
                    C[14:10] <= 0;
                if ($signed(c_e) > 16) begin 
                    C[9:0] <= 0;
                    C[14:10] <= 31;
                    C[15] <= s_c;
                end
                state <= return_c;
            end
            return_c :
                C_val = C;
        endcase
    end

endmodule

module mathStandin(
    input [A_B_reg_size:0] A, B,
    input [C_reg_size:0] C,
    output [C_reg_size:0] Cp
    );
    
    assign Cp = C + A*B;
    
endmodule

module addMultMatrix (
    input [A_B_reg_size:0] 
        a00, a01, a02, a03,
        a10, a11, a12, a13,
        a20, a21, a22, a23,
        a30, a31, a32, a33,
    input [A_B_reg_size:0] 
        b00, b01, b02, b03,
        b10, b11, b12, b13,
        b20, b21, b22, b23,
        b30, b31, b32, b33,
    input [C_reg_size:0] 
        c00, c01, c02, c03,
        c10, c11, c12, c13,
        c20, c21, c22, c23,
        c30, c31, c32, c33,
    output [C_reg_size:0] 
        cp00, cp01, cp02, cp03,
        cp10, cp11, cp12, cp13,
        cp20, cp21, cp22, cp23,
        cp30, cp31, cp32, cp33
    );
    
    mathStandin m00 (a00, b00, c00, cp00);
    mathStandin m01 (a01, b01, c01, cp01);
    mathStandin m02 (a02, b02, c02, cp02);
    mathStandin m03 (a03, b03, c03, cp03);
    mathStandin m10 (a10, b10, c10, cp10);
    mathStandin m11 (a11, b11, c11, cp11);
    mathStandin m12 (a12, b12, c12, cp12);
    mathStandin m13 (a13, b13, c13, cp13);
    mathStandin m20 (a20, b20, c20, cp20);
    mathStandin m21 (a21, b21, c21, cp21);
    mathStandin m22 (a22, b22, c22, cp22);
    mathStandin m23 (a23, b23, c23, cp23);
    mathStandin m30 (a30, b30, c30, cp30);
    mathStandin m31 (a31, b31, c31, cp31);
    mathStandin m32 (a32, b32, c32, cp32);
    mathStandin m33 (a33, b33, c33, cp33);
    
    
endmodule

/* TO - D0
// Run a test on
//  - MathStandin
//  - addMultMatrix
//  - SimpleSystolicArray


*/

module SimpleSystolicArray(
    input clk,
    input [2:0] YZctrl,
    input [A_B_reg_size:0] 
        a0x, a1x, a2x, a3x,
    input [A_B_reg_size:0] 
        bx0, bx1, bx2, bx3,
    output reg rdyTake, rdyGive,
    output reg [C_reg_size:0] 
        c00, c01, c02, c03,
        c10, c11, c12, c13,
        c20, c21, c22, c23,
        c30, c31, c32, c33
    );
    
    parameter
        reset     = 2'b00, 
        run       = 2'b01, 
        outputC   = 2'b10, 
        clearC    = 2'b11,
        ding      = 4'd8, // NOT CORRECT VALUE for sure.
        waiting   = 1'b0,
        running   = 1'b1;
        // ding means that the Systolic array is and will store C matrix until controller wants to take the matrix.
        
    reg [3:0] clk_count;
    reg [A_B_reg_size:0]
        a01, a02, a03,
        a11, a12, a13,
        a21, a22, a23,
        a31, a32, a33,
        
        b10, b11, b12, b13,
        b20, b21, b22, b23,
        b30, b31, b32, b33;
    
    wire [C_reg_size:0]
        ci00, ci01, ci02, ci03,
        ci10, ci11, ci12, ci13,
        ci20, ci21, ci22, ci23,
        ci30, ci31, ci32, ci33;
    
    reg [C_reg_size:0]
        cp00, cp01, cp02, cp03,
        cp10, cp11, cp12, cp13,
        cp20, cp21, cp22, cp23,
        cp30, cp31, cp32, cp33;
              
    reg sysArrState; // determines the state that the systolic array is in. only applicable if run is current global state.
    
    addMultMatrix CTicPlusOne (
        a0x, a01, a02, a03,
        a1x, a11, a12, a13,
        a2x, a21, a22, a23,
        a3x, a31, a32, a33,
        
        bx0, bx1, bx2, bx3,
        b10, b11, b12, b13,
        b20, b21, b22, b23,
        b30, b31, b32, b33,
        
        c00, c01, c02, c03,
        c10, c11, c12, c13,
        c20, c21, c22, c23,
        c30, c31, c32, c33,
        
        ci00, ci01, ci02, ci03,
        ci10, ci11, ci12, ci13,
        ci20, ci21, ci22, ci23,
        ci30, ci31, ci32, ci33
    );
    
    always @ (posedge clk) begin
        case (YZctrl0)
            // this should initialize all values to zero
            // reset should be run before running anything through the systolic array.
            // counters and anything that should have an initial value should be put here.
            // including C matrix.
            reset : begin 
               { a01, a02, a03,
                 a11, a12, a13,
                 a21, a22, a23,
                 a31, a32, a33 }      = 192'b0;
                 
               { b10, b11, b12, b13,
                 b20, b21, b22, b23,
                 b30, b31, b32, b33 } = 192'b0;
                 
                 clk_count = 4'b0;
                 
            end
            // this is where a lot of the work will go into.
            // this will be the step that takes inputs from A and B and outputs a cycle of C matrix values
            // this module will also have a clock counter so we know when C matrix is ready.
            run : begin 
                case (sysArrState)
                    running : begin
                        //something here
                        if (clk_count == ding) begin
                            sysArrState <= waiting;
                        end
                        
                        else begin
                            // do the mathy stuff here
                            //as you wish ;)
                            
                            // setting the registers of C values to C_plus_ab
                             {cp00, cp01, cp02, cp03,
                              cp10, cp11, cp12, cp13,
                              cp20, cp21, cp22, cp23,
                              cp30, cp31, cp32, cp33}
                             <=  
                             {ci00, ci01, ci02, ci03,
                              ci10, ci11, ci12, ci13,
                              ci20, ci21, ci22, ci23,
                              ci30, ci31, ci32, ci33};
                            
                           // delaying b([x+1]K) <-  b(xK)
                             {b10, b11, b12, b13}
                             <= 
                             {bx0, bx1, bx2, bx3};
                             
                             {b20, b21, b22, b23}
                             <= 
                             {b10, b11, b12, b13};
                             
                             {b30, b31, b32, b33}
                             <= 
                             {b20, b21, b22, b23};
                             
                           // delaying a([x+1]K) <-  a(xK)
                             {a01, a11, a21, a31}
                             <= 
                             {a0x, a1x, a2x, a3x};
                             
                             {a02, a12, a22, a32}
                             <= 
                             {a01, a11, a21, a31};
                             
                             {a03, a13, a23, a33}
                             <= 
                             {a02, a12, a22, a32};
                                 
                            clk_count = clk_count + 1;
                        end
                    end
                    waiting : begin
                        // do nothing here. ensure that the C matrix is protected and do not take any a or b inputs.
                        rdyTake = 1;
                    end
                    endcase
            end
        endcase
        
        if (clk_count == 1'b1) begin 
            transA = delayA;
            transB = delayB;
            C_plusAB = delayC;
            clk_count = clk_count + 1'b1;
        end
        else begin
            clk_count = clk_count + 1'b1;
        end
    // do stuff here
endmodule
