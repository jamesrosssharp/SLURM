#pragma once

#include <vector>
#include <cstdint>

#include "types.h"
#include "slurm16InstructionSet.h"



class Assembly
{
public:

	static void makeArithmeticInstructionWithImmediate(OpCode opcode,
						   		Register reg,
						   		int32_t immediate, std::vector<uint16_t>& assembledWords,
						   		uint32_t lineNum);

	static void makeArithmeticInstruction(OpCode opcode,
						   Register regDest,
						   Register regSrc, std::vector<uint16_t>& assembledWords,
						   uint32_t lineNum);
	static void makeExtendedArithmeticInstruction(OpCode opcode,
						   Register regSrcDest, std::vector<uint16_t>& assembledWords,
						   uint32_t lineNum);
	static void makeThreeRegisterArithmeticInstruction(OpCode opcode,
						   Register regDest,
						   Register regSrc, Register regSrc2,
						   std::vector<uint16_t>& assembledWords,
						   uint32_t lineNum);


	static void makeFlowControlInstruction(OpCode opcode, uint32_t address, uint32_t target, Register reg, uint32_t lineNum,
										   std::vector<uint16_t>& assembledWords, bool regIndirect);

	static void makeRelativeFlowControlInstruction(OpCode opcode, uint32_t address, uint32_t target, uint32_t lineNum,
										   std::vector<uint16_t>& assembledWords);

	static void makeLoadStoreWithExpression(OpCode opcode, uint32_t lineNum, std::vector<uint16_t>& words, int32_t value,
											Register regDest, bool isByte = false);
	static void makeLoadStoreWithIndexAndExpression(OpCode opcode, uint32_t lineNum, std::vector<uint16_t>& words, int32_t value,
											Register regDest, Register regInd, bool isByte = false);
	static void makeLoadStore(OpCode opcode, uint32_t lineNum, std::vector<uint16_t>& words, Register regInd, Register regDest, bool isByte = false);

	static void makeIncDecInstruction(OpCode opcode, std::vector<uint16_t>& words,	uint32_t lineNum, Register reg);
 
	static void makePortIO(OpCode opcode, uint32_t lineNum, std::vector<uint16_t>& words, int32_t value,
											Register regDest, Register regInd);
  
	static void makeConditionalMov(OpCode opcode,
						   Register regDest,
						   Register regSrc, std::vector<uint16_t>& assembledWords,
						   uint32_t lineNum);
	
};

