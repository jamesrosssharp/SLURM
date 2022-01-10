/*
 *	Instruction decoder: decode instruction in pipeline stage 1 (or stage 0 for hazards - separate instance) to
 *  determine which registers to load, etc.
 *
 */

module slurm16_cpu_decode #(parameter BITS = 16, ADDRESS_BITS = 16, REGISTER_BITS = 4)
(
	input CLK,
	input RSTb,

	input [BITS - 1:0] instruction,		/* instruction in pipeline slot 1 (or 0 for hazard decoder) */

	output [REGISTER_BITS - 1:0] regA_sel, /* register A select */
	output [REGISTER_BITS - 1:0] regB_sel  /* register B select */
);

`include "cpu_decode_functions.v"
`include "cpu_defs.v"

reg [REGISTER_BITS - 1:0] regARdAddr_r;
reg [REGISTER_BITS - 1:0] regBRdAddr_r;
 
assign regA_sel = regARdAddr_r;
assign regB_sel = regBRdAddr_r;
 
always @(*)
begin
	regARdAddr_r = 4'd0;	// Default: read r0 (=0)
	regBRdAddr_r = 4'd0;    // ...

	casex (instruction)
		INSTRUCTION_CASEX_NOP:	;	/* nop */
		INSTRUCTION_CASEX_RET_IRET:	begin	/* ret / iret */
			regARdAddr_r = LINK_REGISTER; // add iret later when needed
		end
		INSTRUCTION_CASEX_ALUOP_SINGLE_REG: begin /* alu op reg */
			regBRdAddr_r	= reg_src_from_ins(instruction);
		end
		INSTRUCTION_CASEX_ALUOP_REG_REG:	begin	/* alu op, reg reg */
			regARdAddr_r	= reg_dest_from_ins(instruction);
			regBRdAddr_r	= reg_src_from_ins(instruction);
		end
		INSTRUCTION_CASEX_ALUOP_REG_IMM:	begin	/* alu op, reg imm */
			regARdAddr_r 		= reg_dest_from_ins(instruction);	
		end
		INSTRUCTION_CASEX_BRANCH:	begin /* branch */
			regARdAddr_r	= reg_branch_ind_from_ins(instruction);
		end
		INSTRUCTION_CASEX_LOAD_STORE: begin /* memory, reg, reg + immediate index */ 
			regBRdAddr_r 		= reg_idx_from_ins(instruction);	
			regARdAddr_r 		= reg_dest_from_ins(instruction);	
		end
		INSTRUCTION_CASEX_PEEK_POKE: begin /* io peek / poke reg, reg + immediate index*/
			regBRdAddr_r 		= reg_idx_from_ins(instruction);	
			regARdAddr_r 		= reg_dest_from_ins(instruction);		
		end
		default: ;
	endcase
end

endmodule
