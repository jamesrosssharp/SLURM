
#pragma once

#include "OpCode.h"
#include "types.h"

#include <vector>

namespace Assembly {

	void assembleRegisterImmediateALUOp(int linenum, OpCode opcode, Register regDest, int expressionValue, std::vector<uint8_t>& assembledBytes);
	void assembleBranch(int linenum, OpCode opcode, Register regIdx, int expressionValue, std::vector<uint8_t>& assembledBytes);
	void assembleRetIRet(int lineNum, OpCode opcode, std::vector<uint8_t>& assembledBytes);
	void assembleTwoRegisterALUOp(int lineNum, OpCode opcode, Register regDest, Register regSrc, std::vector<uint8_t>& assembledBytes);

}
