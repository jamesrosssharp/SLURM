/*
 *
 *	CPU Hazard: computes hazards
 *
 *
 */

module slurm16_cpu_hazard #(parameter BITS = 16, REGISTER_BITS = 4) 
(
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

	output hazard_1,
	output hazard_2,
	output hazard_3
);

`include "cpu_decode_functions.v"
`include "slurm16_cpu_defs.v"

// Determine hazard registers to propagate from p0

reg [REGISTER_BITS - 1:0] hazard_reg0_r = {REGISTER_BITS {1'b0}};
assign 	hazard_reg0 = hazard_reg0_r;

reg 	modifies_flags0_r = 1'b0;
assign  modifies_flags0 = modifies_flags0_r;

always @(*)
begin

	hazard_reg0_r = {REGISTER_BITS{1'b0}};	

	/* verilator lint_off CASEX */
	casex (instruction)
		INSTRUCTION_CASEX_ALUOP_SINGLE_REG : begin /* alu op reg */
			hazard_reg0_r 	= reg_src_from_ins(instruction); // source is destination in this case
		end
		INSTRUCTION_CASEX_COND_MOV, INSTRUCTION_CASEX_ALUOP_REG_REG, INSTRUCTION_CASEX_ALUOP_REG_IMM: begin /* alu op */
			case (alu_op_from_ins(instruction))
				5'd12, 5'd13:;	
				default:
					hazard_reg0_r 	= reg_dest_from_ins(instruction);
			endcase
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
		INSTRUCTION_CASEX_BYTE_LOAD_SX:
			hazard_reg0_r = reg_dest_from_ins(instruction);
		INSTRUCTION_CASEX_PEEK_POKE: begin /* io peek? */
			if (is_io_poke_from_ins(instruction) == 1'b0) begin
				hazard_reg0_r = reg_dest_from_ins(instruction);
			end
		end
		INSTRUCTION_CASEX_THREE_REG_COND_ALU: begin
			hazard_reg0_r 	= reg_3dest_from_ins(instruction);
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

reg hazard_1_r;
reg hazard_2_r;
reg hazard_3_r;

assign hazard_1 = hazard_1_r;
assign hazard_2 = hazard_2_r;
assign hazard_3 = hazard_3_r;

always @(*)
begin
	hazard_1_r = 1'b0;
	hazard_2_r = 1'b0;
	hazard_3_r = 1'b0;

	if (regA_sel0 != R0) begin
		if (regA_sel0 == hazard_reg1)
			hazard_1_r = 1'b1;
		if (regA_sel0 == hazard_reg2)
			hazard_2_r = 1'b1;
		if (regA_sel0 == hazard_reg3)
			hazard_3_r = 1'b1;
	end

	if (regB_sel0 != R0) begin
		if (regB_sel0 == hazard_reg1)
			hazard_1_r = 1'b1;
		if (regB_sel0 == hazard_reg2)
			hazard_2_r = 1'b1;
		if (regB_sel0 == hazard_reg3)
			hazard_3_r = 1'b1;
	end

	casex(instruction)
		INSTRUCTION_CASEX_BRANCH: begin /* branch */
			if (uses_flags_for_branch(instruction)) begin
				if (modifies_flags1) hazard_1_r = 1'b1;
				if (modifies_flags2) hazard_2_r = 1'b1;
				if (modifies_flags3) hazard_3_r = 1'b1;
			end
		end
		default: ;
	endcase
end

endmodule
