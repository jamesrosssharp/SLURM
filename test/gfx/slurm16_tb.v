`timescale 1 ns / 1 ps
module slurm16_tb;

parameter BITS 				= 16; 	/* 16 bit data */
parameter ADDRESS_BITS 		= 16; 	/* 16 bit address */

reg CLK  = 1;

always #50 CLK <= !CLK; // ~ 10MHz

reg RSTb = 1'b0;

initial begin 
	#150 RSTb = 1'b1;
end

wire [31:0] PINS;
reg [7:0] IN_PINS = 8'h00;

slurm16 #(.CLOCK_FREQ(10000000)) slm0 (
	CLK,
	RSTb,
	PINS,
	IN_PINS
);


initial begin
    $dumpfile("slurm16.vcd");
    $dumpvars(0, slurm16_tb);
	# 1000000 $finish;
end

genvar j;
for (j = 0; j < 16; j = j + 1) begin
    initial $dumpvars(0, slm0.reg0.regFileA[j]);
end


endmodule
