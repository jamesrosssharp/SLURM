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

	input is_executing,
	input load_pc,
	
	input [BITS - 1:0] instruction, /* p0 pipeline slot instruction*/

	input [REGISTER_BITS - 1:0] regA_sel0,		/* registers that pipeline0 instruction will read from */
	input [REGISTER_BITS - 1:0] regB_sel0,

	output [REGISTER_BITS - 1:0] hazard_reg0,	/*  export hazard computation, it will move with pipeline in pipeline module */
	output modifies_flags0,						/*  export flag hazard conditions */ 

	input [REGISTER_BITS - 1:0] hazard_reg1,	/* import pipelined hazards */
	input [REGISTER_BITS - 1:0] hazard_reg2,
	input [REGISTER_BITS - 1:0] hazard_reg3,
	input modifies_flags1,
	input modifies_flags2,
	input modifies_flags3,

	output stall,
	output stall_start,
	output stall_end,

	output hazard1_but_23_clear
);

`include "cpu_decode_functions.v"
`include "cpu_defs.v"

// Determine hazard registers to propagate from p0

reg [REGISTER_BITS - 1:0] hazard_reg0_r;
assign 					  hazard_reg0 = hazard_reg0_r;

reg 	modifies_flags0_r;
assign  modifies_flags0 = modifies_flags0_r;

always @(*)
begin

	hazard_reg0_r = {REGISTER_BITS{1'b0}};	

	casex (instruction)
		INSTRUCTION_CASEX_ALUOP_SINGLE_REG : begin /* alu op reg */
			hazard_reg0_r 	= reg_src_from_ins(instruction); // source is destination in this case
		end
		INSTRUCTION_CASEX_ALUOP_REG_REG, INSTRUCTION_CASEX_ALUOP_REG_IMM: begin /* alu op */
			hazard_reg0_r 	= reg_dest_from_ins(instruction);
		end
		INSTRUCTION_CASEX_BRANCH: begin /* branch */
			if (is_branch_link_from_ins(instruction) == 1'b1) begin
				hazard_reg0_r   = LINK_REGISTER; /* link register */
			end
		end
		INSTRUCTION_CASEX_BYTE_LOAD_STORE, INSTRUCTION_CASEX_LOAD_STORE:	begin /* load store */
			if (is_load_store_from_ins(instruction) == 1'b0) begin /* load */
				// write back value 
				hazard_reg0_r = reg_dest_from_ins(instruction);
			end	
		end
		INSTRUCTION_CASEX_PEEK_POKE: begin /* io peek? */
			if (is_io_poke_from_ins(instruction) == 1'b0) begin
				hazard_reg0_r = reg_dest_from_ins(instruction);
			end
		end
		default: ;
	endcase
end

// Determine flag hazards to propagate

always @(*)
begin

	modifies_flags0_r = 1'b0;

	casex (instruction)
		INSTRUCTION_CASEX_ALUOP_SINGLE_REG,
		INSTRUCTION_CASEX_ALUOP_REG_REG, INSTRUCTION_CASEX_ALUOP_REG_IMM: begin /* alu op */
			modifies_flags0_r = 1'b1;
		end
		default: ;
	endcase
end

// Compute if a hazard occurs

reg hazard_23;

always @(*)
begin

	hazard_23 = 1'b0;

	if (regA_sel0 != R0) begin
		if (regA_sel0 == hazard_reg2)
			hazard_23 = 1'b1;
// We don't need register hazards from stage 3??
//		if (regA_sel0 == hazard_reg3)
//			hazard_23 = 1'b1;
	end

	if (regB_sel0 != R0) begin

		if (regB_sel0 == hazard_reg2)
			hazard_23 = 1'b1;
//		if (regB_sel0 == hazard_reg3)
//			hazard_23 = 1'b1;
	end

	casex(instruction)
		INSTRUCTION_CASEX_BRANCH: begin /* branch */
			if (uses_flags_for_branch(instruction)) begin
				if (modifies_flags2) hazard_23 = 1'b1;
				if (modifies_flags3) hazard_23 = 1'b1;
			end
		end
	endcase
end

reg hazard1; 

always @(*)
begin

	hazard1 = 1'b0;

	if (regA_sel0 != R0) begin

		if (regA_sel0 == hazard_reg1)
			hazard1 = 1'b1;
	end

	if (regB_sel0 != R0) begin

		if (regB_sel0 == hazard_reg1)
			hazard1 = 1'b1;
	end

	casex(instruction)
		INSTRUCTION_CASEX_BRANCH: begin /* branch */
			if (uses_flags_for_branch(instruction)) begin
				if (modifies_flags1) hazard1 = 1'b1;
			end
		end
	endcase
end

wire hazard = hazard1 || hazard_23;

assign hazard1_but_23_clear = hazard1 && !hazard_23;

// Stall flag

reg stall_r, prev_stall_r;

assign stall 		= stall_r || prev_stall_r;
assign stall_start 	= stall_r == 1'b1 && prev_stall_r == 1'b0;
assign stall_end 	= stall_r == 1'b0 && prev_stall_r == 1'b1;

always @(posedge CLK)
begin
	prev_stall_r <= stall_r;
	if (RSTb == 1'b0) begin
		stall_r <= 1'b0;	
	end
	if (load_pc) begin
		stall_r <= 1'b0;
		prev_stall_r <= 1'b0;
	end
	else if (hazard && is_executing)
		stall_r <= 1'b1;
	else if ((stall_r == 1'b1) && !hazard && is_executing)
		stall_r <= 1'b0;
end

endmodule
