
#pragma once

#include "OpCode.h"
#include "Cond.h"
#include "types.h"

#include <vector>

namespace Assembly 
{
	void assembleRegisterImmediateALUOp(int linenum, OpCode opcode, Register regDest, int expressionValue, std::vector<uint8_t>& assembledBytes);
	void assembleBranch(int linenum, OpCode opcode, Register regIdx, int expressionValue, std::vector<uint8_t>& assembledBytes);
	void assembleRetIRet(int lineNum, OpCode opcode, std::vector<uint8_t>& assembledBytes);
	void assembleTwoRegisterALUOp(int lineNum, OpCode opcode, Register regDest, Register regSrc, std::vector<uint8_t>& assembledBytes);
	void assembleCondMovOp(int lineNum, Cond cond, Register regDest, Register regSrc, std::vector<uint8_t>& assembledBytes);
	void assembleCondAluOp(int lineNum, OpCode opcode, Cond cond, Register regDest, Register regSrc, Register regSrc2, std::vector<uint8_t>& assembledBytes);
	void assembleOneRegAluOp(int lineNum, OpCode opcode, Register regDest, std::vector<uint8_t>& assembledBytes);
	void assembleMemoryOp(int lineNum, OpCode opcode, Register regDest, Register regInd, int expressionValue, std::vector<uint8_t>& assembledBytes);
	void assembleIntFlagOp(int lineNum, OpCode opcode, std::vector<uint8_t>& assembledBytes);
	void assembleSleep(int lineNum, std::vector<uint8_t>& assembledBytes);
	void assembleNop(int lineNum, std::vector<uint8_t>& assembledBytes);
}
