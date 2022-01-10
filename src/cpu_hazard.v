/*
 *
 *	CPU Hazard: manages hazards
 *
 *
 */

module slurm_cpu_hazard #(parameter BITS = 16, REGISTER_BITS = 4, ADDRESS_BITS = 16) 
(
	input CLK,
	input RSTb,

	input [BITS - 1:0] instruction_p0,

	input [REGISTER_BITS - 1:0] regA_sel0,
	input [REGISTER_BITS - 1:0] regB_sel0,

	output stall,
	output stall_start,
	output stall_end

);

// Determine hazard registers to propagate from p0

// Determine flag hazards to propagate

// Compute if a hazard occurs


endmodule
