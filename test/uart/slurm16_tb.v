`timescale 1 ns / 1 ps
module slurm16_tb;

parameter BITS 				= 16; 	/* 16 bit data */
parameter ADDRESS_BITS 		= 16; 	/* 16 bit address */

reg CLK  = 1;

always #50 CLK <= !CLK; // ~ 10MHz

reg RSTb = 1'b0;

initial begin 
	#50 RSTb = 1'b1;
end

wire [15:0] PINS;

slurm16 #(.CLOCK_FREQ(10000000)) slm0 (
	CLK,
	RSTb,
	PINS
);


initial begin
    $dumpfile("slurm16.vcd");
    $dumpvars(0, slurm16_tb);
	# 5000000 $finish;
end

endmodule