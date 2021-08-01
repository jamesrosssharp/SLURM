#include "Assembly.h"

#include <sstream>


void Assembly::makeArithmeticInstructionWithImmediate(uint16_t opcode, Register reg, int32_t value, std::vector<uint16_t>& assembledWords, uint32_t lineNum)
{
    uint16_t op = opcode;

    int16_t val = value;

    if (((uint32_t)value & 0xffff) != (uint32_t)value)
    {
        std::stringstream ss;
        ss << "Error: expression will not fit in 16 bits on line " << lineNum << std::endl;
        throw std::runtime_error(ss.str());
    }

    if ((uint32_t)reg >= 16)
    {
        std::stringstream ss;
        ss << "Error: illegal register on line " << lineNum << std::endl;
        throw std::runtime_error(ss.str());
    }

    if (val >= 0 && val < 16)
    {
        op = op | ((uint32_t)reg << 4) | val;
        assembledWords[0] = op;

        if (assembledWords.size() == 2)
            assembledWords[1] = NOP_INSTRUCTION;

    }
    else
    {
        if (assembledWords.size() != 2)
        {
            std::stringstream ss;
            ss << "Error: not enough space allocated for instruction on line " << lineNum << std::endl;
            throw std::runtime_error(ss.str());
        }

        uint16_t imm = IMM_INSTRUCTION | (((uint16_t)val & 0xfff0) >> 4);
        assembledWords[0] = imm;
        op = op | ((uint32_t)reg << 4) | (val & 0x000f);
        assembledWords[1] = op;
    }

}


void Assembly::makeArithmeticInstruction(uint16_t opcode,
                                         Register regDest,
                                         Register regSrc, std::vector<uint16_t>& assembledWords,
                                         uint32_t lineNum)
{

    uint16_t op = opcode;

    if ((uint32_t)regDest >= 16)
    {
        std::stringstream ss;
        ss << "Error: illegal destination register on line " << lineNum << std::endl;
        throw std::runtime_error(ss.str());
    }

    if ((uint32_t)regSrc >= 16)
    {
        std::stringstream ss;
        ss << "Error: illegal source register on line " << lineNum << std::endl;
        throw std::runtime_error(ss.str());
    }

    op = op | ((uint16_t)regDest << 4) | ((uint16_t)regSrc);
    assembledWords[0] = op;

}


void Assembly::makeFlowControlInstruction(OpCode opcode, uint32_t address, uint32_t target, uint32_t lineNum,
                                       std::vector<uint16_t>& assembledWords)
{

    // sanity check absolute target address

    if ((target & 0xffffff) != target)
    {
        std::stringstream ss;
        ss << "Error: jump/call target outside of address space on " << lineNum << std::endl;
        throw std::runtime_error(ss.str());
    }

    // check if relative address is possible

    int32_t diff        = (target - address) / 2;
    bool    useRelative = false;

    if ((diff >= 0 && diff < 256) || (diff < 0 && diff >= -256))
    {
        useRelative = true;
    }

    uint16_t op = NOP_INSTRUCTION;

    switch (opcode)
    {
        case OpCode::JUMP:
            if (useRelative)
                op = JUMP_REL_INSTRUCTION;
            else
                op = JUMP_INSTRUCTION;
            break;
        case OpCode::JUMPC:
            if (useRelative)
                op = JUMPC_REL_INSTRUCTION;
            else
                op = JUMPC_INSTRUCTION;
            break;
        case OpCode::JUMPZ:
            if (useRelative)
                op = JUMPZ_REL_INSTRUCTION;
            else
                op = JUMPZ_INSTRUCTION;
            break;
        case OpCode::JUMPNC:
            if (useRelative)
                op = JUMPNC_REL_INSTRUCTION;
            else
                op = JUMPNC_INSTRUCTION;
            break;
        case OpCode::JUMPNZ:
            if (useRelative)
                op = JUMPNZ_REL_INSTRUCTION;
            else
                op = JUMPNZ_INSTRUCTION;
            break;
        case OpCode::CALL:
            if (useRelative)
                op = CALL_REL_INSTRUCTION;
            else
                op = CALL_INSTRUCTION;
            break;
        case OpCode::CALLC:
            if (useRelative)
                op = CALLC_REL_INSTRUCTION;
            else
                op = CALLC_INSTRUCTION;
            break;
        case OpCode::CALLZ:
            if (useRelative)
                op = CALLZ_REL_INSTRUCTION;
            else
                op = CALLZ_INSTRUCTION;
            break;
        case OpCode::CALLNC:
            if (useRelative)
                op = CALLNC_REL_INSTRUCTION;
            else
                op = CALLNC_INSTRUCTION;
            break;
        case OpCode::CALLNZ:
            if (useRelative)
                op = CALLNZ_REL_INSTRUCTION;
            else
                op = CALLNZ_INSTRUCTION;
            break;
        default:
        {
            std::stringstream ss;
            ss << "Error: invalid opcode on line " << lineNum << std::endl;
            throw std::runtime_error(ss.str());
        }

    }

    if (useRelative)
    {
        assembledWords[0] = op | (diff & 0x03ff);
        if (assembledWords.size() == 2)
            assembledWords[1] = NOP_INSTRUCTION;
    }
    else
    {
        if (assembledWords.size() != 2)
        {
            std::stringstream ss;
            ss << "Error: not enough space for flow control opcode on line " << lineNum << std::endl;
            throw std::runtime_error(ss.str());
        }

        if (target < 1024)
        {
            assembledWords[0] = op | ((target & 0x7fe) >> 1);
            assembledWords[1] = NOP_INSTRUCTION;
        }
        else
        {
            assembledWords[0] = IMM_INSTRUCTION | ((target & 0xfff800) >> 1);
            assembledWords[1] = op | ((target & 0x7fe) >> 1);
        }

    }


}

void Assembly::makeLoadStoreWithExpression(OpCode opcode, uint32_t lineNum, std::vector<uint16_t>& assembledWords, int32_t value,
                                           Register regInd, Register regDest)
{

    uint16_t op;

    int16_t idx = (int16_t)regInd - 24;

    if (idx < 0 || idx > 4)
    {
        std::stringstream ss;
        ss << "Error: illegal index register on line " << lineNum << std::endl;
        throw std::runtime_error(ss.str());
    }

    if ((uint16_t)regDest >= 16)
    {
        std::stringstream ss;
        ss << "Error: illegal destination/source register on line " << lineNum << std::endl;
        throw std::runtime_error(ss.str());
    }

    bool fitsIn4Bits = false;

    if (value >= 0 && value < 16)
        fitsIn4Bits = true;

    switch (opcode)
    {
        case OpCode::LDW:
            op = LDW_IMM_INSTRUCTION;
            break;
        case OpCode::STW:
            op = STW_IMM_INSTRUCTION;
            break;
        default:
        {
            std::stringstream ss;
            ss << "Error: opcode cannot take indirect addressing on line " << lineNum << std::endl;
            throw std::runtime_error(ss.str());

            break;
        }
    }

    op |= ((uint16_t)regInd & 0x03) << 8;
    op |= ((uint16_t)regDest & 0x0f) << 4;

    if (fitsIn4Bits)
    {
        assembledWords[0] = op | (((uint16_t)value & 0x0f) >> 1);
        assembledWords[1] = NOP_INSTRUCTION;
    }
    else
    {
        assembledWords[0] = IMM_INSTRUCTION | (((uint16_t)value & 0xfff0) >> 4);
        assembledWords[1] = op | ((uint16_t)value & 0x0f);
    }

}
