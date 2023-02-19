/*

Disassembly.cpp : SLURM16 Disassembly

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

#include "Disassembly.h"
#include "host/SLURM/slurm16InstructionSet.h"

#include <vector>
#include <tuple>
#include <sstream>
#include <iomanip>

typedef std::string (*ins_handler_t)(uint16_t op, uint16_t imm_hi);

void createAluOp(uint16_t alu_op, std::stringstream& dis)
{
	switch (alu_op)
	{
		case 0:
			dis << "mov";
			break;
		case 1:
			dis << "add";
			break;
		case 2:
			dis << "adc";
			break;
        	case 3:
			dis << "sub";
			break;
		case 4:
			dis << "sbb";
			break;
		default: 
			dis << "???";
			break;
	}
}

static std::string handle_alu_reg_imm(uint16_t op, uint16_t imm_hi)
{
	std::stringstream dis;

	uint16_t alu_op = (op & 0x0f00) >> 8;

	createAluOp(alu_op, dis);

	uint16_t rdest = (op & 0x00f0) >> 4; 

	dis << " r" << rdest;
	
	int16_t imm = (imm_hi << 4) | (op & 0x000f);

	dis << ", 0x" << std::hex <<  imm;

	return dis.str();

}

static std::string handle_alu_reg_reg(uint16_t op, uint16_t imm_hi)
{
	std::stringstream dis;

	uint16_t alu_op = (op & 0x0f00) >> 8;

	createAluOp(alu_op, dis);

	uint16_t rdest = (op & 0x00f0) >> 4; 

	dis << " r" << rdest;
	
	uint16_t rsrc = (op & 0x000f);

	dis << ", r" <<  rsrc;

	return dis.str();
}

static std::string handle_ret_iret(uint16_t opcode, uint16_t imm)
{
	if (opcode & 1)
		return "iret";
	
	return "ret";
}

static std::string handle_branch(uint16_t op, uint16_t imm_hi)
{
	std::stringstream dis;

	uint16_t branch = (op & 0x0f00) >> 8;

	switch (branch)
	{
		case 0:
			dis << "bz  ";
			break;
		case 14:
			dis << "ba  ";
			break;
		case 15:
			dis << "bl  ";
			break;
		default: 
			dis << "??? ";
			break;
	}

	uint16_t rdest = (op & 0x00f0) >> 4; 

	dis << "[r" << rdest;
	
	int16_t imm = (imm_hi << 4) | (op & 0x000f);

	dis << ", 0x" << std::hex <<  imm << "]";

	return dis.str();
}

void createCond(uint16_t cond, std::stringstream& dis)
{
	switch (cond)
	{
		case 0:
			dis << "eq";
			break;
		case 1:
			dis << "ne";
			break;
		case 2:
			dis << "s";
			break;
		case 3:
			dis << "ns";
			break;
		case 4:
			dis << "ltu";
			break;
		case 5:
			dis << "geu";
			break;
		case 6:
			dis << "v";
			break;
		case 7:
			dis << "nv";
			break;
		case 8:
			dis << "lt";
			break;
		case 9:
			dis << "le";
			break;
		case 10:
			dis << "gt";
			break;
		case 11:
			dis << "ge";
			break;
		case 12:
			dis << "leu";
			break;
		case 13:
			dis << "gtu";
			break;
		case 14:
			dis << "a";
			break;
		case 15:
			dis << "a";
			break;
		default: 
			dis << "?";
			break;
	}
}

static std::string handle_cond_mov(uint16_t op, uint16_t imm_hi)
{
	std::stringstream dis;

	uint16_t cond = (op & 0x0f00) >> 8;

	dis << "mov.";

	createCond(cond, dis);

	uint16_t rdest = (op & 0x00f0) >> 4; 

	dis << " r" << rdest;

	uint16_t rsrc = (op & 0x000f); 

	dis << ", r" << rsrc;
	
	return dis.str();
}

static std::string handle_three_reg_cond_alu(uint16_t op, uint16_t imm_hi)
{
	std::stringstream dis;

	uint16_t cond = (imm_hi & 0x0f0) >> 4;
	uint16_t aluOp = (imm_hi & 0x00f);
	
	createAluOp(aluOp, dis);
	dis << ".";
	createCond(cond, dis);

	uint16_t rdest = (op & 0x0f00) >> 8; 

	dis << " r" << rdest;

	uint16_t rsrc = (op & 0x00f0) >> 4; 

	dis << ", r" << rsrc;

	uint16_t rsrc2 = (op & 0x000f); 

	dis << ", r" << rsrc2;
	
	return dis.str();
}

std::vector<std::tuple<uint16_t, uint16_t, ins_handler_t>> ins_handlers = {
	{SLRM_ALU_REG_IMM_INSTRUCTION, SLRM_ALU_REG_IMM_INSTRUCTION_MASK, handle_alu_reg_imm},
	{SLRM_ALU_REG_REG_INSTRUCTION, SLRM_ALU_REG_REG_INSTRUCTION_MASK, handle_alu_reg_reg},
	{SLRM_IRET_INSTRUCTION, SLRM_IRET_INSTRUCTION_MASK, handle_ret_iret},
	{SLRM_RET_INSTRUCTION, SLRM_RET_INSTRUCTION_MASK, handle_ret_iret},
	{SLRM_BRANCH_INSTRUCTION, SLRM_BRANCH_INSTRUCTION_MASK, handle_branch},
	{SLRM_CONDITIONAL_MOV_INSTRUCTION, SLRM_CONDITIONAL_MOV_INSTRUCTION_MASK, handle_cond_mov},
	{SLRM_THREE_REG_COND_ALU_INSTRUCTION, SLRM_THREE_REG_COND_ALU_INSTRUCTION_MASK, handle_three_reg_cond_alu},			
}; 

std::string Disassembly::disassemble(uint8_t* bytes)
{

	std::string dis;

	// Check for preceing imm

	uint16_t imm_hi = 0;

	if ((*(bytes + 1) & 0xf0) == 0x10)
	{
		uint16_t imm = *(bytes) | (*(bytes + 1) << 8);
		imm_hi = imm & 0x0fff;
		bytes += 2;
	}

	// Is the next instruction an imm?? could happen, but would be strange...

	if ((*bytes + 1) & 0xf0 == 0x10)
	{
		dis = " ?? ";
	}
	else // Otherwise, we have another instruction. Disassemble it.
	{
		uint16_t op = *(bytes) | (*(bytes + 1) << 8);

		for (const auto& tup : ins_handlers)
		{
		//	printf("%x %x %x\n", std::get<1>(tup), std::get<0>(tup), op);

			if ((op & std::get<1>(tup)) == std::get<0>(tup))
			{
				ins_handler_t handler = std::get<2>(tup);
				dis = handler(op, imm_hi);
				break;
			}
		}
	}

	while (dis.size() < 16) dis += " ";

	return dis;
}

