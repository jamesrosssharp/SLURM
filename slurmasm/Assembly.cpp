#include "Assembly.h"

#include <sstream>


void Assembly::makeArithmeticInstructionWithImmediate(OpCode opcode, Register regDest, int32_t value, std::vector<uint16_t>& assembledWords, uint32_t lineNum)
{

	uint16_t op 	= 0;
	uint16_t aluOp 	= 0;

    if (((uint32_t)value & 0xffff) != (uint32_t)value)
    {
        std::stringstream ss;
        ss << "Error: expression will not fit in 16 bits on line " << lineNum << std::endl;
        throw std::runtime_error(ss.str());
    }

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
		case OpCode::CMP:
			aluOp = 12;
			break;		
		case OpCode::TEST:
			aluOp = 13;
			break;
		default:
		{
	        std::stringstream ss;
            ss << "Unsupported ALU operation for reg, immediate mode on line " << lineNum << std::endl;
            throw std::runtime_error(ss.str());  
		}
	}


	if (value >= 0 && value < 16)
    {
		op = SLRM_ALU_REG_IMM_INSTRUCTION | ((aluOp & 0xf) << 8) | ((int)regDest << 4) | ((uint16_t)value);

        if (assembledWords.size() == 2)
    	{
		    assembledWords[0] = SLRM_IMM_INSTRUCTION;
        	assembledWords[1] = op;
		}
		else
        	assembledWords[0] = op;
    }
	else
	{	
        if (assembledWords.size() != 2)
        {
            std::stringstream ss;
            ss << "Error: not enough space allocated for instruction on line " << lineNum << std::endl;
            throw std::runtime_error(ss.str());
        }
		assembledWords[0] = SLRM_IMM_INSTRUCTION | ((uint32_t)value >> 4);
	
		op = SLRM_ALU_REG_IMM_INSTRUCTION | ((aluOp & 0xf) << 8) | ((int)regDest << 4) | ((uint16_t)value & 0xf);
        assembledWords[1] = op;
	}

}

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
			aluOp = 28;
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
            ss << "Upsupported ALU operation on line " << lineNum << std::endl;
            throw std::runtime_error(ss.str());  
		}
	}
}

void Assembly::makeThreeRegisterArithmeticInstruction(OpCode opcode,
                                         Register regDest,
                                         Register regSrc, Register regSrc2, std::vector<uint16_t>& assembledWords,
                                         uint32_t lineNum)
{

	uint16_t op 	= 0;
	uint16_t aluOp 	= 0;
	
	get_aluOp(opcode, lineNum, aluOp);

	op = SLRM_ALU_REG_REG_REG_INSTRUCTION | ((aluOp & 0xf) << 9) | ((int)regDest << 6) | ((int)regSrc2 << 3) | ((int)regSrc);

    assembledWords[0] = op;

}

void Assembly::makeExtendedArithmeticInstruction(OpCode opcode,
                                         Register regDest, std::vector<uint16_t>& assembledWords,
                                         uint32_t lineNum)
{

	uint16_t op 	= 0;
	uint16_t aluOp 	= 0;

	get_aluOp(opcode, lineNum, aluOp);

	op = SLRM_ALU_SINGLE_REG_INSTRUCTION | ((aluOp & 0xf) << 4) | ((int)regDest);

    assembledWords[0] = op;

}



void Assembly::makeArithmeticInstruction(OpCode opcode,
                                         Register regDest,
                                         Register regSrc, std::vector<uint16_t>& assembledWords,
                                         uint32_t lineNum)
{

	uint16_t op 	= 0;
	uint16_t aluOp 	= 0;

	get_aluOp(opcode, lineNum, aluOp);

	op = SLRM_ALU_REG_REG_INSTRUCTION | ((aluOp & 0xf) << 8) | ((int)regDest << 4) | ((int)regSrc);

    assembledWords[0] = op;

}

static uint16_t get_branch(OpCode opcode, int lineNum)
{
	uint16_t branch = 0;

	switch (opcode)
	{
		case OpCode::BZ:
			branch = 0;
			break;
		case OpCode::BNZ:
			branch = 1;
			break;
		case OpCode::BS:
			branch = 2;
			break;
		case OpCode::BNS:
			branch = 3;
			break;
		case OpCode::BC:
			branch = 4;
			break;
		case OpCode::BNC:
			branch = 5;
			break;
		case OpCode::BA:
			branch = 6;
			break;
		case OpCode::BL:
			branch = 7;
			break;
		default:
		{
	        std::stringstream ss;
            ss << "Upsupported branch operation on line " << lineNum << std::endl;
            throw std::runtime_error(ss.str());  
		}
	}

	return branch;
}

void Assembly::makeFlowControlInstruction(OpCode opcode, uint32_t address, uint32_t target, Register reg, uint32_t lineNum,
                                       std::vector<uint16_t>& assembledWords, bool regIndirect)
{
	uint16_t branch = 0;
	
	branch = get_branch(opcode, lineNum);

	uint16_t op;

	op = SLRM_BRANCH_INSTRUCTION | (branch << 8) | ((uint16_t)target & 0xf) | ((uint16_t)reg << 4);
	
	if (target >= 0 && target < 16)
    {
        if (assembledWords.size() == 2)
		{
            assembledWords[0] = SLRM_IMM_INSTRUCTION;
        	assembledWords[1] = op;
		}
		else
		{
        	assembledWords[0] = op;
		}
    }
	else
	{	
        if (assembledWords.size() != 2)
        {
            std::stringstream ss;
            ss << "Error: not enough space allocated for instruction on line " << lineNum << std::endl;
            throw std::runtime_error(ss.str());
        }
		assembledWords[0] = SLRM_IMM_INSTRUCTION | ((uint32_t)target >> 4);
        assembledWords[1] = op;
	}

}

void Assembly::makeRelativeFlowControlInstruction(OpCode opcode, uint32_t address, uint32_t target, uint32_t lineNum,
                                           std::vector<uint16_t>& assembledWords)
{

	uint16_t branch = 0;
	uint16_t op;

	branch = get_branch(opcode, lineNum);

	int16_t diff = target - address - 2; // need to subtract two, because PC will have already advanced once the instruction is in the pipeline
	
	if ((diff < -256) || (diff > 255))
	{
        std::stringstream ss;
		ss << "Error: relative branch out of range on line " << lineNum << std::endl;
		throw std::runtime_error(ss.str());
	}

	op = SLRM_RELATIVE_BRANCH_INSTRUCTION | (branch << 10) | ((uint16_t)diff & 0x1ff);	
	assembledWords[0] = op;
}

void Assembly::makeLoadStore(OpCode opcode, uint32_t lineNum, std::vector<uint16_t>& assembledWords, Register regInd, Register regDest, bool postIncrement, bool postDecrement)
{

	uint16_t PI = postIncrement ? 0 : 1;
	uint16_t PD = postDecrement ? 0 : 1;

	uint16_t LS = 0;

	switch (opcode)
	{
		case OpCode::LD:
			LS = 0;
			break;
		case OpCode::ST:
			LS = 1;
			break; 
		default:
		{
	        std::stringstream ss;
            ss << "Upsupported load store operation on line " << lineNum << std::endl;
            throw std::runtime_error(ss.str());  
		}
	}

	uint16_t op = SLRM_INDEX_REGISTER_MEMORY_INSTRUCTION | (PD << 10) | (PI << 9) | (LS << 8) | ((uint16_t)regDest << 4) | ((uint16_t)regInd); 	
	assembledWords[0] = op;
}



void Assembly::makeLoadStoreWithExpression(OpCode opcode, uint32_t lineNum, std::vector<uint16_t>& assembledWords, int32_t value,
                                           Register regDest)
{
	uint16_t LS = 0;

	switch (opcode)
	{
		case OpCode::LD:
			LS = 0;
			break;
		case OpCode::ST:
			LS = 1;
			break; 
		default:
		{
	        std::stringstream ss;
            ss << "Upsupported load store operation on line " << lineNum << std::endl;
            throw std::runtime_error(ss.str());  
		}
	}

	uint16_t op = SLRM_IMMEDIATE_MEMORY_INSTRUCTION  | (LS << 8) | ((uint16_t)regDest << 4) | ((uint16_t)value & 0xf); 	
	
	if (value >= 0 && value < 16)
    {
		if (assembledWords.size() == 2)
    	{
		    assembledWords[0] = SLRM_IMM_INSTRUCTION;
        	assembledWords[1] = op;
		}
		else 	
			assembledWords[0] = op;
	}
	else
	{
        if (assembledWords.size() != 2)
        {
            std::stringstream ss;
            ss << "Error: not enough space allocated for instruction on line " << lineNum << std::endl;
            throw std::runtime_error(ss.str());
        }
		assembledWords[0] = SLRM_IMM_INSTRUCTION | ((uint16_t)value >> 4);
        assembledWords[1] = op;
	}

}

void Assembly::makeLoadStoreWithIndexAndExpression(OpCode opcode, uint32_t lineNum, std::vector<uint16_t>& assembledWords, int32_t value,
                                           Register regDest, Register regInd)
{
	uint16_t LS = 0;

	std::cout << "Expression: " << value << std::endl;

	switch (opcode)
	{
		case OpCode::LD:
			LS = 0;
			break;
		case OpCode::ST:
			LS = 1;
			break; 
		default:
		{
	        std::stringstream ss;
            ss << "Upsupported load store operation on line " << lineNum << std::endl;
            throw std::runtime_error(ss.str());  
		}
	}

	uint16_t op = SLRM_IMMEDIATE_PLUS_REG_MEMORY_INSTRUCTION | (LS << 8) | ((uint16_t)regDest << 4) | ((uint16_t)value & 0xf) | ((uint16_t)regInd << 9); 	
	
	if (value >= 0 && value < 16)
    {
		if (assembledWords.size() == 2)
    	{
		    assembledWords[0] = SLRM_IMM_INSTRUCTION;
        	assembledWords[1] = op;
		}
		else 	
			assembledWords[0] = op;
	}
	else
	{
        if (assembledWords.size() != 2)
        {
            std::stringstream ss;
            ss << "Error: not enough space allocated for instruction on line " << lineNum << std::endl;
            throw std::runtime_error(ss.str());
        }
		assembledWords[0] = SLRM_IMM_INSTRUCTION | ((uint16_t)value >> 4);
        assembledWords[1] = op;
	}
}


void Assembly::makePortIO(OpCode opcode, uint32_t lineNum, std::vector<uint16_t>& assembledWords, int32_t value,
                                           Register regDest, Register regInd)
{
	uint16_t LS = 0;

	switch (opcode)
	{
		case OpCode::IN:
			LS = 0;
			break;
		case OpCode::OUT:
			LS = 1;
			break; 
		default:
		{
	        std::stringstream ss;
            ss << "Upsupported load store operation on line " << lineNum << std::endl;
            throw std::runtime_error(ss.str());  
		}
	}

	uint16_t op = SLRM_PORT_INSTRUCTION | (LS << 8) | ((uint16_t)regDest << 4) | ((uint16_t)value & 0xf) | ((uint16_t)regInd << 9); 	
	
	if (value >= 0 && value < 16)
    {
		if (assembledWords.size() == 2)
    	{
		    assembledWords[0] = SLRM_IMM_INSTRUCTION;
        	assembledWords[1] = op;
		}
		else 	
			assembledWords[0] = op;
	}
	else
	{
        if (assembledWords.size() != 2)
        {
            std::stringstream ss;
            ss << "Error: not enough space allocated for instruction on line " << lineNum << std::endl;
            throw std::runtime_error(ss.str());
        }
		assembledWords[0] = SLRM_IMM_INSTRUCTION | ((uint16_t)value >> 4);
        assembledWords[1] = op;
	}
}




void Assembly::makeIncDecInstruction(OpCode opcode, std::vector<uint16_t>& assembledWords,  uint32_t lineNum, Register reg)
{
	uint16_t op;

	switch (opcode)
	{
		default:
		{
	        std::stringstream ss;
            ss << "Upsupported reglist operation on line " << lineNum << std::endl;
            throw std::runtime_error(ss.str());  
		}
	}

	assembledWords[0] = op | ((uint16_t)reg & 0x0f); 
}

