`timescale 1 ns / 1 ps
module alu_tb;

reg CLK  = 1;

always #50 CLK <= !CLK; // ~ 10MHz

reg RSTb = 1'b0;

wire [31:0] PINS;
wire [7:0] INPUT_PINS; 

slurm16 #(
.CLOCK_FREQ(10000000)
) cpu0 (
	CLK,
	RSTb,
	PINS,
	INPUT_PINS
);

initial begin 
	#150 RSTb = 1'b1;
end



initial begin
    $dumpfile("cpu_mem_stall_test.vcd");
    $dumpvars(0, alu_tb);
	# 1000000 $finish;
end

genvar j;
for (j = 0; j < 16; j = j + 1) begin
    initial $dumpvars(0, cpu0.cpu0.reg0.regFileA[j]);
end

endmodule
