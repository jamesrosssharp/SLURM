module tb;

reg CLK = 1'b0;
reg RSTb = 1'b0;

wire [15:0] pc;
reg  [15:0] pc_in = 16'haa55;

reg load_pc 	= 1'b0;
reg is_fetching  = 1'b1;
reg stall		= 1'b0;
reg stall_start = 1'b0;
reg stall_end   = 1'b0;

always #50 CLK <= !CLK; // ~ 10MHz

initial begin 
	#150 RSTb = 1'b1;
end

slurm16_cpu_program_counter #(.ADDRESS_BITS(16)) pc0
(
    CLK,
    RSTb,
    pc,
    pc_in,    	   /* PC in for load (branch, ret etc) */
    load_pc,       /* load the PC */
    is_fetching,   /* CPU is fetching instructions - increment PC */
  	stall,         /* pipeline is stalled */
    stall_start,   /* pipeline has started to stall */
    stall_end      /* pipeline is about to end stall */
);

// stimuli

initial begin
	#500 load_pc = 1'b1;
	#100 load_pc = 1'b0;
	#10000 is_fetching = 1'b0;
end

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);
	# 20000 $finish;
end

endmodule
