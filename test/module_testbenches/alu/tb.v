module tb;

reg CLK = 1'b0;
reg RSTb = 1'b0;

always #50 CLK <= !CLK; // ~ 10MHz

initial begin 
	#150 RSTb = 1'b1;
end

reg [15:0] A;
reg [15:0] B;
reg [4:0] aluOp;
wire [15:0] aluOut;

wire execute = 1'b1;

wire C;
wire Z;
wire S;
wire V;

alu alu0
(
	CLK,
	RSTb,

	A,
	B,
	aluOp,
	aluOut,
	
	execute,

	C, /* carry flag */
	Z, /* zero flag */
	S, /* sign flag */
	V  /* signed overflow flag */

);





initial begin	

	// Add 5 + -7
	A <= 16'd5;
	B <= -16'd7; 
	aluOp <= 5'd1;

	#500
	// Add 32767 to 32767
	A <= 16'd32767;
	B <= 16'd32767;	

	#500

	A <= 16'd5;
	B <= -16'd7;
	aluOp <= 5'd3;

	#500
	A <= 16'd32767;
	B <= -16'd32768;

end

initial begin
	$dumpfile("dump.vcd");
	$dumpvars(0, tb);
	# 200000 $finish;
end

endmodule
