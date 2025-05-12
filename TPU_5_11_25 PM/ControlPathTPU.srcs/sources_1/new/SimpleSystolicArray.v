`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/* 
// TO - D0
// Run a test on
//  - MathStandin (PASSED)
//  - addMultMatrix (PASSED)
//  - SimpleSystolicArray (PASSED)
//  - shifterCounter


*/
//////////////////////////////////////////////////////////////////////////////////
`define BIT_WIDTH 16
`define ROWS 4
`define COLS 4


/*
module shifterCounter(
    input run,
    input [15:0] number,
    output reg [4:0] sft
    );
 
    always @ (posedge run)
        casez (number) 
            16'b1xxxxxxxxxxxxxxx : sft = 4'd0 ;
            16'b01xxxxxxxxxxxxxx : sft = 4'd1 ;
            16'b001xxxxxxxxxxxxx : sft = 4'd2 ;
            16'b0001xxxxxxxxxxxx : sft = 4'd3 ;
            16'b00001xxxxxxxxxxx : sft = 4'd4 ;
            16'b000001xxxxxxxxxx : sft = 4'd5 ;
            16'b0000001xxxxxxxxx : sft = 4'd6 ;
            16'b00000001xxxxxxxx : sft = 4'd7 ;
            16'b000000001xxxxxxx : sft = 4'd8 ;
            16'b0000000001xxxxxx : sft = 4'd9 ;
            16'b00000000001xxxxx : sft = 4'd10;
            16'b000000000001xxxx : sft = 4'd11;
            16'b0000000000001xxx : sft = 4'd12;
            16'b00000000000001xx : sft = 4'd13;
            16'b000000000000001x : sft = 4'd14;
            16'b0000000000000001 : sft = 4'd15;
            default : sft = 4'd15;
        endcase
endmodule

module ieeeHalfPrecisonMultiplier(
    input reset, clk,
    input [15:0] A_val, B_val, 
    output reg [15:0] C_val,
    output reg [3:0] state
    );
    
    reg [15:0] C;
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

    shifterCounter shift_a_m (clk, a_m, shft_a_m);
    shifterCounter shift_b_m (clk, b_m, shft_b_m);
    shifterCounter shift_c_m (clk, c_m, shft_c_m);
    

    always@(posedge clk) begin 

        if (reset == 1) 
        begin
            C = 32'b0; // WARNING this is 32 bits!!!
            state = return_c;
        end
        else state = find_sem;

        case (state)
            find_sem : 
            begin 
                s_a = A_val[15];
                s_b = B_val[15];
                a_e = A_val[14:10] - 15;
                b_e = B_val[14:10] - 15;
                a_m = A_val[9:0];
                b_m = B_val[9:0];
                state = inf_NaN_zero;
            end

            inf_NaN_zero : 
            begin 
                //check for Non-numbers (nan)
                // if a or b is NaN then c is NaN
                if ((a_e == 16 && a_m != 0) || (b_e == 16 && b_m != 0)) 
                begin
                    C = NaN;
                    state = return_c;
                end
                // check for infitity
                // if a is inf and b is 0, then c is NaN
                // else c is inf
                else if ((a_e == 16) && (a_m == 0))
                    if ($signed(b_e) == -15 && b_m == 0) 
                    begin
                        C = NaN;
                        state = return_c;
                    end
                    else begin 
                        C[15] = s_a;
                        C[14:0] = inf; 
                        state = return_c;
                    end

                // if b is inf and a is 0, then c is NaN
                // else c is inf
                else if ((b_e == 16) && (b_m == 0))
                    if ($signed(a_e) == -15 && a_m == 0)begin
                        C = NaN;
                        state = return_c;
                    end
                    else begin 
                        C[15] = s_b;
                        C[14:0] = inf;
                        state = return_c;
                    end

                // check for zeros
                // if a or b is zero, than c is zero
                else if (($signed(a_e) == -15 && a_m == 0) || ($signed(b_e) == -16 && b_m == 0)) begin 
                    C[15] = s_a ^ s_b;
                    C[14:0] = zero;
                    state = return_c;
                end
                else begin
                // Denormalise a exponent
                    if ($signed(a_e) == -15)
                        a_e = -14;
                    else
                        a_m[10] <= 1;
                // Denormalise b exponent
                    if ($signed(b_e) == -15)
                        b_e = -14;
                    else
                        b_m[10] = 1;
                    state = norm_a;
                end
            end

            // Normalize A
            norm_a : 
            begin 
                a_m = a_m << shft_a_m;
                a_e = a_e - shft_a_m;
                state = norm_b;
            end

            // Normalize B
            norm_b : 
            begin 
                b_m = a_m << shft_b_m;
                b_e = b_e - shft_b_m;
                state = mult_0;
            end
            
            mult_0 : 
            begin 
                s_c = s_a ^ s_b;
                c_e = a_e + a_e + 1;
                product = a_m * b_m;
                state = mult_1;
            end
            mult_1 : 
            begin 
                c_m = product[21:12];
                guard = product[11];
                round_bit = product[10];
                sticky = (product[9:0] != 0);
                state = norm_1;
            end

            norm_1 :
            begin
                if (c_m[10] == 0) begin
                    c_e = c_e - 1;
                    c_m = c_m << 1;
                    c_m[0] = guard;
                    guard = round_bit;
                    round_bit = 0;
                end
                state = norm_2;
            end
            norm_2:
            begin
                if ($signed(c_e) < -15) begin
                    c_e = c_e + 1;
                    c_m = c_m >> 1;
                    guard = c_m[0];
                    round_bit <= guard;
                    sticky = sticky | round_bit;
                end
                state = round;
            end
            round : 
            begin 
                if (guard && (round_bit | sticky | c_m[0])) begin
                c_m <= c_m + 1;
                if (c_m == 10'b1)
                    c_e =c_e + 1;
                end
                state <=pack_c;
            end
            pack_c : 
            begin 
                C[9:0] = c_m[9:0];
                C[14:10] = c_e[4:0] + 15;
                C[15] = s_c;
                if ($signed(c_e) == -15 && c_m[10] == 0)
                    C[14:10] = 0;
                if ($signed(c_e) > 16) begin 
                    C[9:0] = 0;
                    C[14:10] = 31;
                    C[15] = s_c;
                end
                state = return_c;
            end
            return_c :
                C_val = C;
        endcase
    end

endmodule


// this module can only take unsigned binary numbers.
// no negative numbers
*/
module mathStandin(
    input [15:0] A, B,
    input [31:0] C,
    output [31:0] Cp
    );
    
    assign Cp = C + A*B;
    
endmodule

module addMultMatrix (
    input [15:0] 
        a00, a01, a02, a03,
        a10, a11, a12, a13,
        a20, a21, a22, a23,
        a30, a31, a32, a33,
        
    input [15:0] 
        b00, b01, b02, b03,
        b10, b11, b12, b13,
        b20, b21, b22, b23,
        b30, b31, b32, b33,
        
    input [31:0] 
        c00, c01, c02, c03,
        c10, c11, c12, c13,
        c20, c21, c22, c23,
        c30, c31, c32, c33,
        
    output [31:0] 
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

module SimpleSystolicArray(
    input clk,
    input [2:0] YZctrl,
    input [15:0] 
        a0x, a1x, a2x, a3x,
    input [15:0] 
        bx0, bx1, bx2, bx3,
    output reg rdyGive, // this is to tell the controls that the C matrix is ready to take.
    output reg [31:0] 
        c00, c01, c02, c03,
        c10, c11, c12, c13,
        c20, c21, c22, c23,
        c30, c31, c32, c33
    );
    
    parameter
        reset     = 2'b00, // must be run first when first ran,
        run       = 2'b01, //
        outputC   = 2'b10, // Controls want an output for C.
        pause     = 2'b11, // pauses the systolic array. all check and calculation values are kept in place.
        ding      = 4'd8,
        running   = 2'b01,
        waiting   = 2'b10,
        clearC    = 2'b11;

        // ding means that the Systolic array is ready and will store C matrix until controller wants to take the matrix.
        
    reg [3:0] clk_count;
    reg [15:0]
        a01, a02, a03,
        a11, a12, a13,
        a21, a22, a23,
        a31, a32, a33,
        
        b10, b11, b12, b13,
        b20, b21, b22, b23,
        b30, b31, b32, b33;
    
    reg [31:0]
        ci00, ci01, ci02, ci03,
        ci10, ci11, ci12, ci13,
        ci20, ci21, ci22, ci23,
        ci30, ci31, ci32, ci33;
    
    wire [31:0]
        cp00, cp01, cp02, cp03,
        cp10, cp11, cp12, cp13,
        cp20, cp21, cp22, cp23,
        cp30, cp31, cp32, cp33;
              
    reg [1:0] sysArrState; 
            // determines the state that the systolic array is in.
            // only applicable if run is current global state (ie YZctrl)
    reg matrixWasInitialized;
    
    addMultMatrix CTicPlusOne (
        a0x, a01, a02, a03,
        a1x, a11, a12, a13,
        a2x, a21, a22, a23,
        a3x, a31, a32, a33,
        
        bx0, bx1, bx2, bx3,
        b10, b11, b12, b13,
        b20, b21, b22, b23,
        b30, b31, b32, b33,
        
        ci00, ci01, ci02, ci03,
        ci10, ci11, ci12, ci13,
        ci20, ci21, ci22, ci23,
        ci30, ci31, ci32, ci33,
        
        cp00, cp01, cp02, cp03,
        cp10, cp11, cp12, cp13,
        cp20, cp21, cp22, cp23,
        cp30, cp31, cp32, cp33
    );

    always @ (posedge clk) begin
        
        case (YZctrl)
            // this should initialize all values to zero
            // reset should be run before running anything through the systolic array.
            // counters and anything that should have an initial value should be put here.
            // including C matrix.
          
            reset : begin
                rdyGive = 0; 
               { a01, a02, a03,
                 a11, a12, a13,
                 a21, a22, a23,
                 a31, a32, a33 } <= 192'b0;
                 
               { b10, b11, b12, b13,
                 b20, b21, b22, b23,
                 b30, b31, b32, b33 } <= 192'b0;
                 
                { ci00, ci01, ci02, ci03,
                  ci10, ci11, ci12, ci13,
                  ci20, ci21, ci22, ci23,
                  ci30, ci31, ci32, ci33 } <= 512'b0;
                  
                { c00, c01, c02, c03,
                  c10, c11, c12, c13,
                  c20, c21, c22, c23,
                  c30, c31, c32, c33 } <= 512'b0;
                 
                 clk_count <= 4'b0;
                 
                 // this is here because when reset is set back to 0, and the controls indicate
                 // to start computing C matrix, then I want it to immediately start running.
                 sysArrState <= running;
                 matrixWasInitialized = 1;
                 
            end
            // this is where a lot of the work will go into.
            // this will be the step that takes inputs from A and B and computes a cycle of C matrix values
            // this module will also have a clock counter so we know when C matrix is ready.
            run : begin 
                if (!matrixWasInitialized)
                    sysArrState = waiting;
                case (sysArrState)
                    clearC : begin
                       rdyGive = 0; 
                       { a01, a02, a03,
                         a11, a12, a13,
                         a21, a22, a23,
                         a31, a32, a33 } <= 192'b0;
                         
                       { b10, b11, b12, b13,
                         b20, b21, b22, b23,
                         b30, b31, b32, b33 } <= 192'b0;
                         
                        { ci00, ci01, ci02, ci03,
                          ci10, ci11, ci12, ci13,
                          ci20, ci21, ci22, ci23,
                          ci30, ci31, ci32, ci33 } <= 512'b0;
                        
                        { c00, c01, c02, c03,
                          c10, c11, c12, c13,
                          c20, c21, c22, c23,
                          c30, c31, c32, c33 } <= 512'b0;
                                 
                          clk_count <= 4'b0; 
                    end
                    running : begin
                        rdyGive = 0;
                        
                        if (clk_count == ding) begin
                            sysArrState = waiting;
                        end
                        else begin
                            // do the mathy stuff here
                            //as you wish ;)
                            
                            // setting the registers of C values to C_plus_ab
                             {ci00, ci01, ci02, ci03,
                              ci10, ci11, ci12, ci13,
                              ci20, ci21, ci22, ci23,
                              ci30, ci31, ci32, ci33}
                             <=  
                             {cp00, cp01, cp02, cp03,
                              cp10, cp11, cp12, cp13,
                              cp20, cp21, cp22, cp23,
                              cp30, cp31, cp32, cp33};
                            
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
                        // this is the only place that C matrix is
                        rdyGive = 1;
                    end
                    endcase
            end
            outputC : begin 
                if (rdyGive && matrixWasInitialized) begin
                    { c00, c01, c02, c03,
                      c10, c11, c12, c13,
                      c20, c21, c22, c23,
                      c30, c31, c32, c33 }
                     <=  
                    { cp00, cp01, cp02, cp03,
                      cp10, cp11, cp12, cp13,
                      cp20, cp21, cp22, cp23,
                      cp30, cp31, cp32, cp33 };
                      
                    // this is here so that when the YZctrls switch back to running after taking the C matrix, 
                    // the systolic array will ititize values before calculating first. 
                    sysArrState <= clearC;
                end
                else begin
                    { c00, c01, c02, c03,
                      c10, c11, c12, c13,
                      c20, c21, c22, c23,
                      c30, c31, c32, c33 } <= 512'b0;
                end 
                rdyGive = 0;
            end
            pause : begin 
                // do nothing here.
                // no values are changed.
                // the systolic array has been paused until the YZctrls say to begin again.
            end
        endcase
        
    end
endmodule

//This systolic array uses output stationary method to calculate matrices
// while inputs and weights are fed in a "wavefront" manner, outputs remain in the systolic array
// once calculations finish, one needs to peak into each PE element to pull data
// The other common types are input stationary and weight stationary. sometimes more efficient, but this was easier to implement
//==================TOP MODULE===================
`include "Constants.v"
module Top_Module(
    input reset, clk, start,
    output reg [15:0] a0x,a1x,a2x,a3x, b0x,b1x,b2x,b3x,
    output reg [`BIT_WIDTH*2-1:0] c_data0,c_data1,c_data2,c_data3,
    output reg execution_finished,
    output array_ready_output
    );
    
//index wires TO ROM
reg [`BIT_WIDTH-1:0] a_index0, a_index1, a_index2,a_index3;
reg [`BIT_WIDTH-1:0] b_index0, b_index1, b_index2,b_index3;
reg [`BIT_WIDTH-1:0] c_index;
//output wires from ROM
wire [`BIT_WIDTH-1:0] a_data0,a_data1,a_data2,a_data3;
wire [`BIT_WIDTH-1:0] b_data0,b_data1,b_data2,b_data3;
reg [`BIT_WIDTH*2-1:0] c_data0,c_data1,c_data2,c_data3;
reg [`BIT_WIDTH*2-1:0] c_temp0,c_temp1,c_temp2,c_temp3;
//output from systollic array
wire [`BIT_WIDTH * 2 -1:0] c_out [0:`ROWS * `COLS - 1];
//controlls to systollic array
reg [2:0] YZctrl;
// ROM instantiation

ROM_A rom_a_inst(
    .clk(clk),
    .index0(a_index0), .index1(a_index1), .index2(index2),.index3(b_index3),
    .data0(b_data0),.data1(b_data1),.data2(b_data2),.data3(b_data3)
    );
    
RAM_C RAM_C_inst(
    .clk(clk),
    .index(c_index),
    .data0(c_data0),.data1(c_data1),.data2(c_data2),.data3(c_data3)
    );
    
SimpleSystolicArray systolic_inst(
    .clk(clk), .YZctrl(YZctrl),
    .a0x(a0x), .a1x(a1x), .a2x(a2x), .a3x(a3x),
    .bx0(b0x), .bx1(b1x), .bx2(b2x), .bx3(b3x),
    .rdyGive(array_ready_output),
    .c00(c_out[0]), .c01(c_out[1]), .c02(c_out[2]), .c03(c_out[3]),
    .c10(c_out[4]), .c11(c_out[5]), .c12(c_out[6]), .c13(c_out[7]),
    .c20(c_out[8]), .c21(c_out[9]), .c22(c_out[10]), .c23(c_out[11]),
    .c30(c_out[12]), .c31(c_out[13]), .c32(c_out[14]), .c33(c_out[15])
    );
    
//state machine declaration
//there are missing states so that we may build upon as needed
parameter IDLE = 3'b000, FEED =3'b001, COMPUTE = 3'b010, PULL = 3'b011, DONE = 3'b100;
reg [2:0] STATE, NEXT_STATE;

//counter instantiation These are to keep track of ROM feeding cycles
reg signed [`ROWS + `COLS - 1 :0] cycle_counter; //Tells logic what you are feeding now
reg signed [`ROWS + `COLS - 1 :0] next_cycle_counter; //Tells ROM what you are fetching next

always @(posedge clk or posedge reset) begin
    if(reset) STATE <= IDLE;
    else STATE <= NEXT_STATE;
end
always @(*) begin
        NEXT_STATE <= STATE;
        case (STATE)
                IDLE : if(start) NEXT_STATE <= FEED;
                
                FEED : NEXT_STATE <= (cycle_counter <= `ROWS+`COLS - 1) ? FEED : COMPUTE;
                
                COMPUTE:begin
                        if (array_ready_output) begin
                            next_cycle_counter <= 0;
                            cycle_counter <= -1;
                            NEXT_STATE <= PULL;
                            YZctrl <= 2'b10;
                        end 
                        else NEXT_STATE <= COMPUTE;
                    end
                    PULL : NEXT_STATE <= (cycle_counter < `ROWS-1)? PULL : DONE;
                    
                    DONE : begin end //DO nothing you are done :)
                    
                    default: NEXT_STATE <= STATE;
                endcase
            end
            
always @(posedge clk or posedge reset) begin
    if(reset) begin
        next_cycle_counter <=0;
        cycle_counter <= -1; //this is so that this counter lags behind next_cycle_counter
        YZctrl <= 2'b00; //this resets array
        //I wanted to reset the a0x... registers here, but its a little easier to debug when it shows X
        //signifying that we are in idle state and have yet started to feed from ROM
        end
        else begin
            case(STATE)
            
            IDLE : begin
                // prefetch first set of data while waiting
                a_index0 <= next_cycle_counter;
                a_index1 <= next_cycle_counter-1;
                a_index2 <= next_cycle_counter-2;
                a_index3 <= next_cycle_counter-3;
                b_index0 <= next_cycle_counter;
                b_index1 <= next_cycle_counter-1;
                b_index2 <= next_cycle_counter-2;
                b_index3 <= next_cycle_counter-3;
            end
            FEED: begin
            
            //==========GENERATE ROM ADDRESS===============
            //Rom expects a Row/column index and thats what this is
            //the ROM_A will map A[0][aindex0] ; A[1][aindex1]; M[2][aindex2]; M[3][aindex3]
            //This value is read in this clock cycle into a_data0 to a_data3
            //like wise for b
            //this is responsible for calculating the adresses so that wavefront can be formed
            a_index0 <= next_cycle_counter;
            a_index1 <= next_cycle_counter-1;
            a_index2 <= next_cycle_counter-2;
            a_index3 <= next_cycle_counter-3;
            b_index0 <= next_cycle_counter;
            b_index1 <= next_cycle_counter-1;
            b_index2 <= next_cycle_counter-2;
            b_index3 <= next_cycle_counter-3;
            
            //============FEED TO ARRAY LOGIC==================
            //This block takes the value from ROM output and puts it into the aXx registers
            //This is also responsible for adding zeroes into the cascading for delaying feed
            //These registers are currently set as outputs for debuggin, but can be connected to systollic array.
            if(cycle_counter >=0) begin
                YZctrl <= 2'b01;
                    a0x <= (cycle_counter - 0 >= 0 && cycle_counter <= `COLS - 1) ? a_data0 : 16'b0;
                    a1x <= (cycle_counter - 1 >= 0 && cycle_counter - 1 <= `COLS-1) ? a_data1 : 16'b0;
                    a2x <= (cycle_counter - 2 >= 0 && cycle_counter - 2 <= `COLS-1) ? a_data2 : 16'b0;
                    a3x <= (cycle_counter - 3 >= 0 && cycle_counter - 3 <= `COLS-1) ? a_data3 : 16'b0;
                    b0x <= (cycle_counter - 0 >= 0 && cycle_counter - 0 <= `ROWS - 1) ? b_data0 : 16'b0;
                    b1x <= (cycle_counter - 1 >= 0 && cycle_counter - 1 <= `ROWS-1) ? b_data1 : 16'b0;
                    b2x <= (cycle_counter - 2 >= 0 && cycle_counter - 2 <= `ROWS-1) ? b_data2 : 16'b0;
                    b3x <= (cycle_counter - 3 >= 0 && cycle_counter - 3 <= `ROWS-1) ? b_data3 : 16'b0;
                end
                //============UPDATE COUNTER============
                //These counters keeps the feeding pipelined and in check
                //Next_clock_cycle leads cycle_count by 1
                //this is so that in each cycle, next_Cycle is queeing up the next adresses and ROM values
                //while cycle_counter is writing the current ROM values to the a0x... registers
                next_cycle_counter <= next_cycle_counter + 1;
                cycle_counter <= cycle_counter + 1;
                //This repeats this state until 2n-1 rows have been read (matrix has been read and inserted into array)
                //need to calculate how many clock cycles until array itself has completed its calculation
                //i was intendeding to feed this into the Compute state to signify that reading is done, but computation is still ongoing
            end
            COMPUTE: begin
                //This is where feeding from ROM has completed, the left and top elements have recieved all data
                //THis should just be sending 0 to array and wait for last element to calculate
                //Last element calculates at
                //I calculated that this is how many cycles from it takes to complete the co67mputation, but i dont know tho
            end
            PULL: begin
                c_temp0 <= c_out[next_cycle_counter * `ROWS];
                c_temp1 <= c_out[next_cycle_counter * `ROWS + 1];
                c_temp2 <= c_out[next_cycle_counter * `ROWS + 2];
                c_temp3 <= c_out[next_cycle_counter * `ROWS + 3];
            if(cycle_counter >= 0) begin
                c_data0 <= c_temp0;
                c_data1 <= c_temp1;
                c_data2 <= c_temp2;
                c_data3 <= c_temp3;
                c_index <= cycle_counter;
            end
                next_cycle_counter <= next_cycle_counter + 1;
                cycle_counter <= cycle_counter + 1;
            end
                DONE: begin
                    execution_finished <= 1;
                    //RElax you are finished
                end
            endcase
        end
    end
endmodule
