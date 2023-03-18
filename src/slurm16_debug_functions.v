/*
 *	(C) 2022 J. R. Sharp
 *
 * 	See LICENSE for software license details
 *
 *	debug functions
 *
 */


// 16 bytes = 16 characters
function [127:0] disassemble;
input [31:0] ins;
begin
	casex (ins)
		INSTRUCTION_CASEX_NOP:
			disassemble = "nop"; 
		INSTRUCTION_CASEX_RET_IRET:
			case (ins[0])
				1'b0:
					disassemble = "ret";
				1'b1:			
					disassemble = "iret";		
			endcase
		INSTRUCTION_CASEX_ALUOP_SINGLE_REG:
			case ({1'b1, ins[7:4]})
				
				ALU5_ASR:
					disassemble = "asr";
				ALU5_LSR:
					disassemble = "lsr";
				ALU5_LSL:
					disassemble = "lsl";
				ALU5_ROLC:
					disassemble = "rolc";
				ALU5_RORC:
					disassemble = "rorc";
				ALU5_ROL:
					disassemble = "rol";
				ALU5_ROR:
					disassemble = "ror";
				ALU5_CC:
					disassemble = "cc";
				ALU5_SC:
					disassemble = "sc";
				ALU5_CZ:
					disassemble = "cz";			
				ALU5_SZ:
					disassemble = "sz";
				ALU5_CS:
					disassemble = "cs";
				ALU5_SS:
					disassemble = "ss";
				ALU5_STF:
					disassemble = "stf";
				ALU5_RSF:
					disassemble = "rsf";
				default:
					disassemble = "?";
			endcase
		INSTRUCTION_CASEX_INTERRUPT_EN:
			case (ins[0])
				1'b0:
					disassemble = "cli";
				1'b1:
					disassemble = "sti";
			endcase 
		INSTRUCTION_CASEX_SLEEP:
			disassemble = "sleep";
		INSTRUCTION_CASEX_IMM:
			disassemble = "imm";
		INSTRUCTION_CASEX_ALUOP_REG_REG,
		INSTRUCTION_CASEX_ALUOP_REG_IMM:
			case ({1'b0, ins[11:8]})
				ALU5_MOV:  
					disassemble = "mov";
				ALU5_ADD: 
					disassemble = "add";
				ALU5_ADC:  
					disassemble = "adc";
				ALU5_SUB:  
					disassemble = "sub";
				ALU5_SBB:  
					disassemble = "sbb";
				ALU5_AND:  
					disassemble = "and";
				ALU5_OR:   
					disassemble = "or";
				ALU5_XOR:  
					disassemble = "xor";
				ALU5_MUL:  
					disassemble = "mul";
				ALU5_MULU: 
					disassemble = "mulu";			
				ALU5_RRN:  
					disassemble = "rrn";
				ALU5_RLN:  
					disassemble = "rln";
				ALU5_CMP:  
					disassemble = "cmp";
				ALU5_TST: 
					disassemble = "test";
				ALU5_UMULU: 
					disassemble = "umulu";
				ALU5_BSWAP: 
					disassemble = "bswap";
			endcase
		INSTRUCTION_CASEX_BRANCH:
			case (ins[11:8])
				COND_EQ:
					disassemble = "beq";
				COND_NZ: 
					disassemble = "bnz";
				COND_NE: 
					disassemble = "bne";
				COND_S:
					disassemble = "bs";
				COND_NS: 
					disassemble = "bns";
				COND_C:
					disassemble = "bc";
				COND_NC: 
					disassemble = "bnc";
				COND_V:  
					disassemble = "bv";
				COND_NV:  
					disassemble = "bnv";
				COND_LT:
					disassemble = "blt";
				COND_LE:
					disassemble = "ble";
				COND_GT: 
					disassemble = "bgt";
				COND_GE:
					disassemble = "bge";
				COND_LEU: 
					disassemble = "bleu";
				COND_GTU: 
					disassemble = "bgtu";
				COND_A:  
					disassemble = "ba";
				COND_L: 
					disassemble = "bl";
			endcase
		INSTRUCTION_CASEX_BYTE_LOAD_STORE:	
			if (ins[12] == 1'b0)
				disassemble = "ldb";
			else
				disassemble = "stb";
		INSTRUCTION_CASEX_LOAD_STORE:
			if (ins[12] == 1'b0)
				disassemble = "ld";
			else
				disassemble = "st";
		INSTRUCTION_CASEX_PEEK_POKE:	
			if (ins[12] == 1'b0)
				disassemble = "in";
			else
				disassemble = "out";
		INSTRUCTION_CASEX_ALU_REG_EXREG,
		INSTRUCTION_CASEX_ALU_EXREG_REG:
			disassemble = "alu.exreg";
	endcase
end
endfunction
