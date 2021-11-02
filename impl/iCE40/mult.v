/*
 *  ice40 multiplier
 *
 *
 */

module mult (
    input [15:0] A,
    input [15:0] B,
    output [31:0] out
);

SB_MAC16 my_16x16_mult (
    .A(A),
    .B(B),
    .C(16'h0000),
    .D(16'h0000),
    .O(out),
    .CLK(0),
    .CE(1),
    .IRSTTOP(0),
    .IRSTBOT(0),
    .ORSTTOP(0),
    .ORSTBOT(0),
    .AHOLD(1),
    .BHOLD(1),
    .CHOLD(0),
    .DHOLD(0),
    .OHOLDTOP(0),
    .OHOLDBOT(0),
    .OLOADTOP(0),
    .OLOADBOT(0),
    .ADDSUBTOP(0),
    .ADDSUBBOT(0),
    .CO(),
    .CI(0),
// MAC cascading ports
    .ACCUMCI(),
    .ACCUMCO(),
    .SIGNEXTIN(0),
    .SIGNEXTOUT()     
);

defparam my_16x16_mult.B_SIGNED                            = 1'b0 ;
defparam my_16x16_mult.A_SIGNED                            = 1'b0 ;
defparam my_16x16_mult.BOTOUTPUT_SELECT                    = 2'b11 ;
defparam my_16x16_mult.TOPOUTPUT_SELECT                    = 2'b11 ;

endmodule

