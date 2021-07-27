`timescale 1 ns / 1 ps
module alu_tb;

parameter REG_BITS  = 3; 	/* 8 registers */
parameter BITS 		= 16; 	/* 16 bit registers */

reg RSTb = 0;
reg CLK  = 1;

always #10 CLK <= !CLK; // ~ 50MHz

initial begin
    #100 RSTb <= 1;
end

reg [BITS - 1:0] A;
reg [BITS - 1:0] B;
reg [3:0] aluOp;
wire [BITS - 1 : 0] aluOut;
wire C;
wire Z;
wire S;


alu
#(.BITS(16)) my_alu
(
	CLK,
	RSTb,
	A,
	B,
	aluOp,
	aluOut,
	C,
	Z,
	S
);

initial begin
	#205 A <= 16'h0003;
		B <= 16'h0002;
		aluOp <= 4'd7;
	#20 A <= 16'hff00;
		B <= 16'h0055;
		aluOp <= 4'd12;	
	#20 aluOp <= 4'd3; 
end

initial begin
    $dumpfile("alu.vcd");
    $dumpvars(0, alu_tb);
    # 100000 $finish;
end

endmodule
