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
//  	for(j = 0; j < 511; j = j + 1)
//        $dumpvars(0, slm0.mem0.theRam.RAM[32768 - 512 + j]);
	# 100000 $finish;
end

genvar j;
for (j = 0; j < 512; j = j + 1) begin
	initial $dumpvars(0, slm0.mem0.theRam.RAM[32768 - 512 + j]);
end  


endmodule
