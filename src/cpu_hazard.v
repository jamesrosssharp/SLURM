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

	output hazard1
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
		INSTRUCTION_CASEX_LOAD_STORE:	begin /* load store */
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

reg hazard;

always @(*)
begin

	hazard = 1'b0;

	if (regA_sel0 != R0) begin

		if (regA_sel0 == hazard_reg1)
			hazard = 1'b1;
		if (regA_sel0 == hazard_reg2)
			hazard = 1'b1;
		if (regA_sel0 == hazard_reg3)
			hazard = 1'b1;
	end

	if (regB_sel0 != R0) begin

		if (regB_sel0 == hazard_reg1)
			hazard = 1'b1;
		if (regB_sel0 == hazard_reg2)
			hazard = 1'b1;
		if (regB_sel0 == hazard_reg3)
			hazard = 1'b1;
	end

	casex(instruction)
		INSTRUCTION_CASEX_BRANCH: begin /* branch */
			if (modifies_flags1) hazard = 1'b1;
			if (modifies_flags2) hazard = 1'b1;
			if (modifies_flags3) hazard = 1'b1;
		end
	endcase
end

assign hazard1 = 1'b0; // TODO: remove

// Stall count

reg [2:0] stall_count_r;

localparam STALL_START_COUNT = 3'b11;

assign stall 		= stall_count_r != 3'b000;
assign stall_start 	= (stall_count_r == STALL_START_COUNT);
assign stall_end 	= (stall_count_r == 3'b001);

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		stall_count_r <= 3'b000;	
	end
	else if (stall_count_r == 3'b000 && hazard)
		stall_count_r <= STALL_START_COUNT;
	else if (stall_count_r > 3'b000 && is_executing)
		stall_count_r <= stall_count_r - 1;
end

endmodule
