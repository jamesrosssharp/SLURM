/*
 *
 *	SLURM16 Instruction decoder
 *
 *	Determine registers to select for subsequent operations
 *
 */

module slurm16_cpu_decode #(parameter BITS = 16, ADDRESS_BITS = 16, REGISTER_BITS = 7)
(
	input CLK,
	input RSTb,

	input [BITS - 1:0] instruction,		/* instruction in pipeline slot 1 (or 0 for hazard decoder) */

	output reg [REGISTER_BITS - 1:0] regA_sel = 7'd0, /* register A select */
	output reg [REGISTER_BITS - 1:0] regB_sel = 7'd0 /* register B select */
);

`include "cpu_decode_functions.v"
`include "slurm16_cpu_defs.v"

always @(*)
begin
	regA_sel = 7'd0;	// Default: read r0 (=0)
	regB_sel = 7'd0;	// ...

	
	casex (instruction)
		INSTRUCTION_CASEX_NOP:	;	/* nop */
		INSTRUCTION_CASEX_RET_IRET:	begin	/* ret / iret */
			if (is_ret_or_iret(instruction) == 1'b0)
				regA_sel = LINK_REGISTER;
			else 
				regA_sel = INTERRUPT_LINK_REGISTER;
		end
		INSTRUCTION_CASEX_ALUOP_SINGLE_REG: begin /* alu op reg */
			regB_sel	= reg_src_from_ins(instruction);
		end
		INSTRUCTION_CASEX_ALUOP_REG_REG, INSTRUCTION_CASEX_THREE_REG_COND_ALU:	begin	/* alu op, reg reg */
			regA_sel	= reg_dest_from_ins(instruction);
			regB_sel	= reg_src_from_ins(instruction);
		end
		INSTRUCTION_CASEX_COND_MOV:	begin	/* conditional move, reg reg */
			regA_sel	= reg_dest_from_ins(instruction);
			regB_sel	= reg_src_from_ins(instruction);
		end
		INSTRUCTION_CASEX_ALUOP_REG_IMM:	begin	/* alu op, reg imm */
			regA_sel 		= reg_dest_from_ins(instruction);	
		end
		INSTRUCTION_CASEX_BRANCH:	begin /* branch */
			regA_sel	= reg_branch_ind_from_ins(instruction);
		end
		INSTRUCTION_CASEX_LOAD_STORE, INSTRUCTION_CASEX_BYTE_LOAD_STORE, INSTRUCTION_CASEX_BYTE_LOAD_SX: begin /* memory, reg, reg + immediate index */ 
			regB_sel 		= reg_idx_from_ins(instruction);	
			regA_sel 		= reg_dest_from_ins(instruction);	
		end
		INSTRUCTION_CASEX_PEEK_POKE: begin /* io peek / poke reg, reg + immediate index*/
			regB_sel 		= reg_idx_from_ins(instruction);	
			regA_sel 		= reg_dest_from_ins(instruction);		
		end
		INSTRUCTION_CASEX_ALU_REG_EXREG: begin /* alu op, reg (src) to exreg (dest) */
			regA_sel = reg_src_from_ins(instruction);
			regB_sel = reg_extended_from_ins(instruction);
		end
		INSTRUCTION_CASEX_ALU_EXREG_REG: begin /* alu op, exreg (src) to reg (dest) */
			regA_sel = reg_extended_from_ins(instruction);
			regB_sel = reg_src_from_ins(instruction);
		end
		default: ;
	endcase
end

endmodule
