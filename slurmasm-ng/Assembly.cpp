

#include "Assembly.h"
#include "slurm16InstructionSet.h"

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
		case OpCode::UMULU:
			aluOp = 14;
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
			aluOp = 25;
			break;
		case OpCode::CS:
			aluOp = 26;
			break;
		case OpCode::SS:
			aluOp = 27;
			break;
		case OpCode::BSWAP:
			aluOp = 15;
			break;
		case OpCode::CMP:
			aluOp = 12;
			break;		
		case OpCode::TEST:
			aluOp = 13;
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

	printf("op: %x\n", op);

	assembledBytes.push_back(op & 0xff);
	assembledBytes.push_back(op >> 8);

}

void Assembly::assembleBranch(int linenum, OpCode opcode, Register regIdx, int expressionValue, std::vector<uint8_t>& assembledBytes)
{


}

