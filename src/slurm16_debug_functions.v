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
	casez (ins)
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
		INSTRUCTION_CASEX_INTERRUPT:
			disassemble = "int";
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
		INSTRUCTION_CASEX_BRANCH:;
		INSTRUCTION_CASEX_LOAD_STORE:
				disassemble = "ld";
	endcase
end
endfunction
