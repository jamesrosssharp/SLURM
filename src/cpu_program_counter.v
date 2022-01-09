/*
 *
 *	CPU program counter: program counter for slurm16 cpu
 *
 *
 */

module slurm16_cpu_program_counter #(parameter ADDRESS_BITS = 16)
(
	input CLK,
	input RSTb,

	output [ADDRESS_BITS - 1 : 0] pc,

	input  [ADDRESS_BITS - 1 : 0] pc_in,	/* PC in for load (branch, ret etc) */
	input load_pc,							/* load the PC */

	input is_fetching,	/* CPU is fetching instructions - increment PC */

	input stall,		/* pipeline is stalled */
	input stall_start,  /* pipeline has started to stall */
	input stall_end	/* pipeline is about to end stall */
);

reg [ADDRESS_BITS - 1 : 0] pc_r;

assign pc = pc_r;

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		pc_r <= {ADDRESS_BITS{1'b0}};  /* Come out of reset at address 0x0000 - the start of the boot ROM */
	end else begin
		if (load_pc == 1'b1) 
			pc_r <= pc_in;
		else if (is_fetching && !(stall && !stall_end))
			pc_r <= pc_r + 1;
	end
end

endmodule
