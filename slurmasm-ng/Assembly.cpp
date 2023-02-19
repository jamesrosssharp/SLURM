

#include "Assembly.h"
#include "host/SLURM/slurm16InstructionSet.h"

#include <sstream>

static void get_aluOp(OpCode opcode, uint32_t lineNum, uint16_t& aluOp)
{
	switch (opcode)
	{
		case OpCode::MOV:
			aluOp = 0;
			break;
		case OpCode::ADD:
			aluOp = 1;
			break;
		case OpCode::ADC:
			aluOp = 2;
			break;			
		case OpCode::SUB:
			aluOp = 3;
			break;
		case OpCode::SBB:
			aluOp = 4;
			break;
		case OpCode::AND:
			aluOp = 5;
			break;
		case OpCode::OR:
			aluOp = 6;
			break;
		case OpCode::XOR:
			aluOp = 7;
			break;
		case OpCode::MUL:
			aluOp = 8;
			break;
		case OpCode::MULU:
			aluOp = 9;
			break;
		case OpCode::RRN:
			aluOp = 10;
			break;
		case OpCode::RLN:
			aluOp = 11;
			break;
		case OpCode::CMP:
			aluOp = 12;
			break;		
		case OpCode::TEST:
			aluOp = 13;
			break;
		case OpCode::UMULU:
			aluOp = 14;
			break;
		case OpCode::BSWAP:
			aluOp = 15;
			break;
		case OpCode::ASR:
			aluOp = 16;
			break;
		case OpCode::LSR:
			aluOp = 17;
			break;
		case OpCode::LSL:
			aluOp = 18;
			break;
		case OpCode::ROLC:
			aluOp = 19;
			break;
		case OpCode::RORC:
			aluOp = 20;
			break;
		case OpCode::ROL:
			aluOp = 21;
			break;
		case OpCode::ROR:
			aluOp = 22;
			break;
		case OpCode::CC:
			aluOp = 23;
			break;
		case OpCode::SC:
			aluOp = 24;
			break;
		case OpCode::CZ:
			aluOp = 25;
			break;
		case OpCode::SZ:
			aluOp = 26;
			break;
		case OpCode::CS:
			aluOp = 27;
			break;
		case OpCode::SS:
			aluOp = 28;
			break;
		case OpCode::STF:
			// Store flags.
			aluOp = 29;
			break;
		case OpCode::RSF:
			// Restore flags
			aluOp = 30;
			break;
		default:
		{
			std::stringstream ss;
			ss << "Unsupported ALU operation on line " << lineNum << std::endl;
			throw std::runtime_error(ss.str());  
		}
	}
}

static uint16_t get_branch(OpCode opcode, int lineNum)
{
	uint16_t branch = 0;

	switch (opcode)
	{
		case OpCode::BZ:
		case OpCode::BEQ:
			branch = 0;
			break;
		case OpCode::BNZ:
		case OpCode::BNE:
			branch = 1;
			break;
		case OpCode::BS:
			branch = 2;
			break;
		case OpCode::BNS:
			branch = 3;
			break;
		case OpCode::BC:
		case OpCode::BLTU:
			branch = 4;
			break;
		case OpCode::BNC:
		case OpCode::BGEU:
			branch = 5;
			break;
		case OpCode::BV:
			branch = 6;
			break;
		case OpCode::BNV:
			branch = 7;
			break;
		case OpCode::BLT:
			branch = 8;
			break;
		case OpCode::BLE:
			branch = 9;
			break;
		case OpCode::BGT:
			branch = 10;
			break;
		case OpCode::BGE:
			branch = 11;
			break;
		case OpCode::BLEU:
			branch = 12;
			break;
		case OpCode::BGTU:
			branch = 13;
			break;
		case OpCode::BA:
			branch = 14;
			break;
		case OpCode::BL:
			branch = 15;
			break;
		default:
		{
			std::stringstream ss;
			ss << "Unsupported branch operation on line " << lineNum << std::endl;
			throw std::runtime_error(ss.str());  
		}
	}

	return branch;
}



static uint16_t makeImm(int linenum, int expressionValue)
{
	if (expressionValue < -32768 || expressionValue > 65535)
	{
		std::stringstream ss;
		ss << "Value won't fit in 16 bits: " << linenum << std::endl;
		throw std::runtime_error(ss.str());  
	}

	uint16_t imm = SLRM_IMM_INSTRUCTION | ((uint16_t)expressionValue >> 4) & 0xfff;

	return imm;
}

void Assembly::assembleRegisterImmediateALUOp(int linenum, OpCode opcode, Register regDest, int expressionValue, std::vector<uint8_t>& assembledBytes)
{
	uint16_t aluOp = 0;
	get_aluOp(opcode, linenum, aluOp);

	if (expressionValue < 0 || expressionValue > 15)
	{
		uint16_t imm = makeImm(linenum, expressionValue);

		assembledBytes.push_back(imm & 0xff);
		assembledBytes.push_back(imm >> 8);
	}
	
	uint16_t op = SLRM_ALU_REG_IMM_INSTRUCTION | ((aluOp & 0xf) << 8) | ((int)regDest << 4) | ((uint16_t)expressionValue & 0xf);

	assembledBytes.push_back(op & 0xff);
	assembledBytes.push_back(op >> 8);

}

void Assembly::assembleBranch(int linenum, OpCode opcode, Register regIdx, int expressionValue, std::vector<uint8_t>& assembledBytes)
{

	uint16_t branch = 0;
	branch = get_branch(opcode, linenum);

	uint16_t op;

	uint16_t imm = makeImm(linenum, expressionValue);
 
	op = SLRM_BRANCH_INSTRUCTION | (branch << 8) | ((uint16_t)expressionValue & 0xf) | ((uint16_t)regIdx << 4);
	
	assembledBytes.push_back(imm & 0xff);
	assembledBytes.push_back(imm >> 8);

	assembledBytes.push_back(op & 0xff);
	assembledBytes.push_back(op >> 8);
}


void Assembly::assembleRetIRet(int lineNum, OpCode opcode, std::vector<uint8_t>& assembledBytes)
{
	uint16_t op;
	switch (opcode)
	{
		case OpCode::RET:
			op = SLRM_RET_INSTRUCTION; 
			break;
		case OpCode::IRET:
			op = SLRM_IRET_INSTRUCTION;
			break;
	}

	assembledBytes.push_back(op & 0xff);
	assembledBytes.push_back(op >> 8);

}

void Assembly::assembleTwoRegisterALUOp(int lineNum, OpCode opcode, Register regDest, Register regSrc, std::vector<uint8_t>& assembledBytes)
{
	uint16_t aluOp = 0;
	get_aluOp(opcode, lineNum, aluOp);

	uint16_t op = SLRM_ALU_REG_REG_INSTRUCTION | ((aluOp & 0xf) << 8) | ((int)regDest << 4) | ((uint16_t)regSrc & 0xf);

	assembledBytes.push_back(op & 0xff);
	assembledBytes.push_back(op >> 8);

}

void Assembly::assembleCondMovOp(int lineNum, Cond cond, Register regDest, Register regSrc, std::vector<uint8_t>& assembledBytes)
{
	uint16_t op = SLRM_CONDITIONAL_MOV_INSTRUCTION | (((uint32_t)cond & 0xf) << 8) | ((int)regDest << 4) | ((uint16_t)regSrc & 0xf);
 	
	assembledBytes.push_back(op & 0xff);
	assembledBytes.push_back(op >> 8);
}

void Assembly::assembleCondAluOp(int lineNum, OpCode opcode, Cond cond, Register regDest, Register regSrc, Register regSrc2, std::vector<uint8_t>& assembledBytes)
{
	uint16_t aluOp = 0;
	get_aluOp(opcode, lineNum, aluOp);

	uint16_t condValue = (((uint32_t)cond << 4) | aluOp) << 4;
	uint16_t imm = makeImm(lineNum, condValue);

	uint16_t op = SLRM_THREE_REG_COND_ALU_INSTRUCTION | ((int)regDest << 8) | ((uint16_t)regSrc << 4) | ((uint16_t)regSrc2);

	assembledBytes.push_back(imm & 0xff);
	assembledBytes.push_back(imm >> 8);

	assembledBytes.push_back(op & 0xff);
	assembledBytes.push_back(op >> 8);
}

void Assembly::assembleOneRegAluOp(int lineNum, OpCode opcode, Register regDest, std::vector<uint8_t>& assembledBytes)
{

	uint16_t aluOp = 0;
	get_aluOp(opcode, lineNum, aluOp);

	uint16_t op = SLRM_ALU_SINGLE_REG_INSTRUCTION | ((int)regDest << 8) | (((uint16_t)aluOp & 0xf) << 4) | ((uint16_t)regDest);

	assembledBytes.push_back(op & 0xff);
	assembledBytes.push_back(op >> 8);

}
