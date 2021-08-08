`timescale 1 ns / 1 ps
module slurm16_tb;

parameter BITS 				= 16; 	/* 16 bit data */
parameter ADDRESS_BITS 		= 16; 	/* 16 bit address */

reg CLK  = 1;

always #10 CLK <= !CLK; // ~ 50MHz

reg RSTb = 1'b0;

initial begin 
	#50 RSTb = 1'b1;
end

slurm16 slm0 (
	CLK,
	RSTb
);

initial begin
    $dumpfile("slurm16.vcd");
    $dumpvars(0, slurm16_tb);
    # 100000 $finish;
end

endmodule
