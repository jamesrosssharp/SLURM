
#pragma once

#include "OpCode.h"
#include "types.h"

#include <vector>

namespace Assembly {

	void assembleRegisterImmediateALUOp(int linenum, OpCode opcode, Register regDest, int expressionValue, std::vector<uint8_t>& assembledBytes);
	void assembleBranch(int linenum, OpCode opcode, Register regIdx, int expressionValue, std::vector<uint8_t>& assembledBytes);

}
