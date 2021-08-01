#include "Statement.h"

#include "Expression.h"
#include "Assembly.h"
#include "AST.h"

#include <string.h>
#include <sstream>
#include <iostream>

void Statement::reset()
{
    lineNum  = 0;
    expression.reset();
    pseudoOp = PseudoOp::None;
    opcode	 = OpCode::None;
    type	 = StatementType::None;
    label	 = nullptr;
    regSrc	 = Register::None;
    regDest	 = Register::None;
    timesStatement = nullptr;
    repetitionCount = 1;
    assembledWords.clear();
    address = 0;
}

void Statement::firstPassAssemble(uint32_t& curAddress, SymbolTable& syms)
{

    address = curAddress;

    // Create dummy bytes for statement

    if (timesStatement != nullptr)
    {
        repetitionCount = timesStatement->expression.value;
    }

    switch (type)
    {
        case StatementType::STANDALONE_OPCODE:
        case StatementType::TWO_REGISTER_OPCODE:
        case StatementType::ONE_REGISTER_OPCODE:
        case StatementType::INDIRECT_ADDRESSING_OPCODE:
        {
            // shouldn't get here - this should be assembled directly

            std::stringstream ss;
            ss << "Error: not directly assembling line " << lineNum << std::endl;
            throw std::runtime_error(ss.str());

            break;
        }
        case StatementType::ONE_REGISTER_OPCODE_AND_EXPRESSION:
        case StatementType::OPCODE_WITH_EXPRESSION:
        {

            // Assembly might have 1 or two bytes, depending if an imm instruction is needed


            // can expression be evaluated? If so, see if it's possible to fit any immediate value into
            // a 4 bit nibble, in which case we don't need an imm

            bool expressionCanFitIn4Bits = false;

            int32_t exprValue = 0;

            if (expression.evaluate(exprValue, syms))
            {
                if (exprValue >= 0 && exprValue < 16)
                    expressionCanFitIn4Bits = true;
            }

            switch (opcode)
            {
                case OpCode::IMM:
                case OpCode::NOP:
                case OpCode::SLEEP:
                    // these instructions are all single word
                    assembledWords.resize(1 * repetitionCount);
                    break;
                case OpCode::ADD:
                case OpCode::ADC:
                case OpCode::SUB:
                case OpCode::SBB:
                case OpCode::AND:
                case OpCode::OR:
                case OpCode::XOR:
                case OpCode::CMP:
                case OpCode::TEST:
                case OpCode::LOAD:
                case OpCode::MUL:
                case OpCode::MULS:
                case OpCode::DIV:
                case OpCode::DIVS:
                    if (expressionCanFitIn4Bits)
                        assembledWords.resize(1 * repetitionCount);
                    else
                        assembledWords.resize(2 * repetitionCount);
                    break;
                case OpCode::BSL:
                case OpCode::BSR:
                    // barrel shift instructions are single word
                    assembledWords.resize(1 * repetitionCount);
                    break;
                case OpCode::JUMP:
                case OpCode::JUMPZ:
                case OpCode::JUMPC:
                case OpCode::JUMPNZ:
                case OpCode::JUMPNC:
                case OpCode::CALL:
                case OpCode::CALLZ:
                case OpCode::CALLC:
                case OpCode::CALLNZ:
                case OpCode::CALLNC:
                    // jumps and calls can be made relative. For now, assign 2 words to
                    // instruction as if it were absolute. We will optimise it to a single
                    // byte later on.
                    assembledWords.resize(2 * repetitionCount);
                    break;
                /*
                SVC:
                RET:
                RETI:
                RETE:
                LDW:
                STW:
                LDSPR:
                STSPR:
                case OpCode::SLA:
                case OpCode::SLX:
                case OpCode::SL0:
                case OpCode::SL1:
                case OpCode::RL:
                case OpCode::SRA:
                case OpCode::SRX:
                case OpCode::SR0:
                case OpCode::SR1:
                case OpCode::RR:
                    break;
                */
                default:
                {
                    std::stringstream ss;
                    ss << "Error: opcode cannot take expression on line " << lineNum << std::endl;
                    throw std::runtime_error(ss.str());
                }
            }

            break;
        }
        case StatementType::INDIRECT_ADDRESSING_OPCODE_WITH_EXPRESSION:
        {

            bool expressionCanFitIn4Bits = false;

            int32_t exprValue = 0;

            if (expression.evaluate(exprValue, syms))
            {
                if (exprValue >= 0 && exprValue < 16)
                    expressionCanFitIn4Bits = true;
            }

            switch (opcode)
            {
                case OpCode::LDW:
                case OpCode::STW:
                {
                    if (expressionCanFitIn4Bits)
                        assembledWords.resize(1 * repetitionCount);
                    else
                        assembledWords.resize(2 * repetitionCount);

                    break;
                }
                default:
                {
                    std::stringstream ss;
                    ss << "Error: opcode cannot take indirect addressing on line " << lineNum << std::endl;
                    throw std::runtime_error(ss.str());
                }
            }

            break;
        }
        case StatementType::PSEUDO_OP_WITH_EXPRESSION:

            switch (pseudoOp)
            {
                case PseudoOp::ALIGN:
                {
                    // No times used with align

                    if (repetitionCount != 1)
                    {
                        std::stringstream ss;
                        ss << "Error: times used with align on line " << lineNum << std::endl;
                        throw std::runtime_error(ss.str());
                    }

                    // check alignment expression is evaluable
                    // and that it is a multiple of sixteen bit
                    // words


                    int32_t exprValue = 0;

                    if (! expression.evaluate(exprValue, syms))
                    {
                        std::stringstream ss;
                        ss << "Error: could not evaluate align expression on line " << lineNum << std::endl;
                        throw std::runtime_error(ss.str());
                    }

                    if ((exprValue < 0) || ((exprValue & 1) != 0))
                    {
                        std::stringstream ss;
                        ss << "Error: invalid alignment expression on line " << lineNum << std::endl;
                        throw std::runtime_error(ss.str());
                    }

                    assembledWords.resize((exprValue - curAddress%exprValue) >> 1);

                    break;
                }
                case PseudoOp::DW:

                    // If DW string literal, then set the word count to the length of the string

                    char* stringLit;

                    if (expression.isStringLiteral(stringLit))
                    {
                        assembledWords.resize(repetitionCount * Expression::stringLength(stringLit));
                    }
                    else
                    {
                        assembledWords.resize(1 * repetitionCount);
                    }
                    break;
                case PseudoOp::DD:
                    if (expression.isStringLiteral(stringLit))
                    {
                        assembledWords.resize(2 * repetitionCount * Expression::stringLength(stringLit));
                    }
                    else
                    {
                        assembledWords.resize(2 * repetitionCount);
                    }
                    break;
            }

            break;
        default:
            break;
    }

    curAddress += assembledWords.size() * 2;

}

void Statement::assemble(uint32_t &curAddress)
{
    address = curAddress;

    // Create dummy bytes for statement

    if (timesStatement != nullptr)
    {
        repetitionCount = timesStatement->expression.value;
    }

    std::vector<uint16_t> words;

    words.resize(assembledWords.size() / repetitionCount);

    switch (type)
    {
        case StatementType::STANDALONE_OPCODE:
        {
            switch (opcode)
            {
                case OpCode::RET:
                {
                    words.resize(1);
                    words[0] =  NB_RET_INSTRUCTION;
                    break;
                }
                case OpCode::RETI:
                {
                    words.resize(1);
                    words[0] =  NB_RETI_INSTRUCTION;
                    break;
                }
                case OpCode::RETE:
                {
                    words.resize(1);
                    words[0] = NB_RETE_INSTRUCTION;
                }
                case OpCode::NOP:
                {
                    words.resize(1);
                    words[0] =  NB_NOP_INSTRUCTION;
                    break;
                }
                case OpCode::SLEEP:
                {
                    words.resize(1);
                    words[0] =  NB_SLEEP_INSTRUCTION;
                    break;
                }
                default:
                {
                    std::stringstream ss;
                    ss << "Error: opcode is not stand-alone on line " << lineNum << std::endl;
                    throw std::runtime_error(ss.str());

                    break;
                }
            }

            break;
        }
        case StatementType::ONE_REGISTER_OPCODE:
        {

            uint16_t op;

            bool useSPR = false;

            switch (opcode)
            {
                case OpCode::INCW:
                    op = Assembly::INCW_INSTRUCTION;
                    useSPR = true;
                    break;
                case OpCode::DECW:
                    op = Assembly::DECW_INSTRUCTION;
                    useSPR = true;
                    break;
                case OpCode::SL0:
                    op = Assembly::SL0_INSTRUCTION;
                    break;
                case OpCode::SL1:
                    op = Assembly::SL1_INSTRUCTION;
                    break;
                case OpCode::SLA:
                    op = Assembly::SLA_INSTRUCTION;
                    break;
                case OpCode::SLX:
                    op = Assembly::SLX_INSTRUCTION;
                    break;
                case OpCode::RL:
                    op = Assembly::RL_INSTRUCTION;
                    break;
                case OpCode::SR0:
                    op = Assembly::SR0_INSTRUCTION;
                    break;
                case OpCode::SR1:
                    op = Assembly::SR1_INSTRUCTION;
                    break;
                case OpCode::SRA:
                    op = Assembly::SRA_INSTRUCTION;
                    break;
                case OpCode::SRX:
                    op = Assembly::SRX_INSTRUCTION;
                    break;
                case OpCode::RR:
                    op = Assembly::RR_INSTRUCTION;
                    break;
                default:
                {
                    std::stringstream ss;
                    ss << "Error: opcode is not one register opcode on line " << lineNum << std::endl;
                    throw std::runtime_error(ss.str());

                    break;
                }
            }

            if (((uint16_t)regDest >= 16 && ! useSPR) ||
                    ((uint16_t)regDest < 16 && useSPR))
            {
                std::stringstream ss;
                ss << "Error: illegal destination/source register on line " << lineNum << std::endl;
                throw std::runtime_error(ss.str());

                break;
            }

            if (useSPR)
                op |= ((uint16_t)regDest - 16) << 4;
            else
                op |= ((uint16_t)regDest) << 4;

            words.resize(1);
            words[0] = op;

        }
        case StatementType::TWO_REGISTER_OPCODE:
        {
            words.resize(1);

            switch (opcode)
            {
                case OpCode::ADD:
                    Assembly::makeArithmeticInstruction(Assembly::ADD_REG_INSTRUCTION, regDest, regSrc, words, lineNum);
                    break;
                case OpCode::ADC:
                    Assembly::makeArithmeticInstruction(Assembly::ADC_REG_INSTRUCTION, regDest, regSrc, words, lineNum);
                    break;
                case OpCode::SUB:
                    Assembly::makeArithmeticInstruction(Assembly::SUB_REG_INSTRUCTION, regDest, regSrc, words, lineNum);
                    break;
                case OpCode::SBB:
                    Assembly::makeArithmeticInstruction(Assembly::SBB_REG_INSTRUCTION, regDest, regSrc, words, lineNum);
                    break;
                case OpCode::AND:
                    Assembly::makeArithmeticInstruction(Assembly::AND_REG_INSTRUCTION, regDest, regSrc, words, lineNum);
                    break;
                case OpCode::OR:
                    Assembly::makeArithmeticInstruction(Assembly::OR_REG_INSTRUCTION, regDest, regSrc, words, lineNum);
                    break;
                case OpCode::XOR:
                    Assembly::makeArithmeticInstruction(Assembly::XOR_REG_INSTRUCTION, regDest, regSrc, words, lineNum);
                    break;
                case OpCode::CMP:
                    Assembly::makeArithmeticInstruction(Assembly::CMP_REG_INSTRUCTION, regDest, regSrc, words, lineNum);
                    break;
                case OpCode::TEST:
                    Assembly::makeArithmeticInstruction(Assembly::TEST_REG_INSTRUCTION, regDest, regSrc, words, lineNum);
                    break;
                case OpCode::LOAD:
                    Assembly::makeArithmeticInstruction(Assembly::LOAD_REG_INSTRUCTION, regDest, regSrc, words, lineNum);
                    break;
                case OpCode::MUL:
                    Assembly::makeArithmeticInstruction(Assembly::MUL_REG_INSTRUCTION, regDest, regSrc, words, lineNum);
                    break;
                case OpCode::MULS:
                    Assembly::makeArithmeticInstruction(Assembly::MULS_REG_INSTRUCTION, regDest, regSrc, words, lineNum);
                    break;
                case OpCode::DIV:
                    Assembly::makeArithmeticInstruction(Assembly::DIV_REG_INSTRUCTION, regDest, regSrc, words, lineNum);
                    break;
                case OpCode::DIVS:
                    Assembly::makeArithmeticInstruction(Assembly::DIVS_REG_INSTRUCTION, regDest, regSrc, words, lineNum);
                    break;
                case OpCode::FMUL:
                    break;
                case OpCode::FDIV:
                    break;
                case OpCode::FADD:
                    break;
                case OpCode::FSUB:
                    break;
                case OpCode::FCMP:
                    break;
                case OpCode::FINT:
                    break;
                case OpCode::FFLT:
                    break;
                case OpCode::LDSPR:
                {
                    uint16_t op = Assembly::LDSPR_INSTRUCTION;

                    if ((uint32_t)regDest < 16)
                    {
                        std::stringstream ss;
                        ss << "Error: dest register is not an SPR on line " << lineNum << std::endl;
                        throw std::runtime_error(ss.str());
                    }

                    if ((uint32_t)regSrc > 15)
                    {
                        std::stringstream ss;
                        ss << "Error: source register is not a GPR on line " << lineNum << std::endl;
                        throw std::runtime_error(ss.str());
                    }

                    if ((uint32_t)regSrc & 1)
                    {
                        std::stringstream ss;
                        ss << "Error: source register must be r0, r2, r4, r6, r8, r10, r12, or r14 on line " << lineNum << std::endl;
                        throw std::runtime_error(ss.str());
                    }

                    op |= ((uint16_t)regDest - 16) << 4;
                    op |= (uint16_t)regSrc & 0xe;

                    words.resize(1);
                    words[0] = op;

                    break;
                }
                case OpCode::STSPR:
                {
                    uint16_t op = Assembly::STSPR_INSTRUCTION;

                    if ((uint32_t)regSrc < 16)
                    {
                        std::stringstream ss;
                        ss << "Error: src register is not an SPR on line " << lineNum << std::endl;
                        throw std::runtime_error(ss.str());
                    }

                    if ((uint32_t)regDest > 15)
                    {
                        std::stringstream ss;
                        ss << "Error: dest register is not a GPR on line " << lineNum << std::endl;
                        throw std::runtime_error(ss.str());
                    }

                    if ((uint32_t)regDest & 1)
                    {
                        std::stringstream ss;
                        ss << "Error: dest register must be r0, r2, r4, r6, r8, r10, r12, or r14 on line " << lineNum << std::endl;
                        throw std::runtime_error(ss.str());
                    }

                    op |= ((uint16_t)regDest & 0x0e) << 4;
                    op |= ((uint16_t)regSrc - 16);

                    words.resize(1);
                    words[0] = op;

                    break;

                }
                case OpCode::OUT:
                {
                    uint16_t op = Assembly::OUT_INSTRUCTION;

                    op |= ((uint16_t)regDest) << 4;
                    op |= ((uint16_t)regSrc);

                    words.resize(1);
                    words[0] = op;

                    break;
                }
                case OpCode::IN:
                {
                    uint16_t op = Assembly::IN_INSTRUCTION;

                    op |= ((uint16_t)regDest) << 4;
                    op |= ((uint16_t)regSrc);

                    words.resize(1);
                    words[0] = op;

                    break;
                }
            }

            break;
        }
        case StatementType::ONE_REGISTER_OPCODE_AND_EXPRESSION:
        {
            switch (opcode)
            {
                case OpCode::ADD:
                    Assembly::makeArithmeticInstructionWithImmediate(Assembly::ADD_IMM_INSTRUCTION, regDest, expression.value, words, lineNum);
                    break;
                case OpCode::ADC:
                    Assembly::makeArithmeticInstructionWithImmediate(Assembly::ADC_IMM_INSTRUCTION, regDest, expression.value, words, lineNum);
                    break;
                case OpCode::SUB:
                    Assembly::makeArithmeticInstructionWithImmediate(Assembly::SUB_IMM_INSTRUCTION, regDest, expression.value, words, lineNum);
                    break;
                case OpCode::SBB:
                    Assembly::makeArithmeticInstructionWithImmediate(Assembly::SBB_IMM_INSTRUCTION, regDest, expression.value, words, lineNum);
                    break;
                case OpCode::AND:
                    Assembly::makeArithmeticInstructionWithImmediate(Assembly::AND_IMM_INSTRUCTION, regDest, expression.value, words, lineNum);
                    break;
                case OpCode::OR:
                    Assembly::makeArithmeticInstructionWithImmediate(Assembly::OR_IMM_INSTRUCTION, regDest, expression.value, words, lineNum);
                    break;
                case OpCode::XOR:
                    Assembly::makeArithmeticInstructionWithImmediate(Assembly::XOR_IMM_INSTRUCTION, regDest, expression.value, words, lineNum);
                    break;
                case OpCode::CMP:
                    Assembly::makeArithmeticInstructionWithImmediate(Assembly::CMP_IMM_INSTRUCTION, regDest, expression.value, words, lineNum);
                    break;
                case OpCode::TEST:
                    Assembly::makeArithmeticInstructionWithImmediate(Assembly::TEST_IMM_INSTRUCTION, regDest, expression.value, words, lineNum);
                    break;
                case OpCode::LOAD:
                    Assembly::makeArithmeticInstructionWithImmediate(Assembly::LOAD_IMM_INSTRUCTION, regDest, expression.value, words, lineNum);
                    break;
                case OpCode::MUL:
                    Assembly::makeArithmeticInstructionWithImmediate(Assembly::MUL_IMM_INSTRUCTION, regDest, expression.value, words, lineNum);
                    break;
                case OpCode::MULS:
                    Assembly::makeArithmeticInstructionWithImmediate(Assembly::MULS_IMM_INSTRUCTION, regDest, expression.value, words, lineNum);
                    break;
                case OpCode::DIV:
                    Assembly::makeArithmeticInstructionWithImmediate(Assembly::DIV_IMM_INSTRUCTION, regDest, expression.value, words, lineNum);
                    break;
                case OpCode::DIVS:
                    Assembly::makeArithmeticInstructionWithImmediate(Assembly::DIVS_IMM_INSTRUCTION, regDest, expression.value, words, lineNum);
                    break;
                case OpCode::BSL:
                    Assembly::makeArithmeticInstructionWithImmediate(Assembly::BSL_INSTRUCTION, regDest, expression.value, words, lineNum);
                    break;
                case OpCode::BSR:
                    Assembly::makeArithmeticInstructionWithImmediate(Assembly::BSR_INSTRUCTION, regDest, expression.value, words, lineNum);
                    break;
                default:
                {
                    std::stringstream ss;
                    ss << "Error: opcode is not single register with expression on line " << lineNum << std::endl;
                    throw std::runtime_error(ss.str());

                    break;
                }
            }

            break;
        }
        case StatementType::OPCODE_WITH_EXPRESSION:
        {

            switch (opcode)
            {
                case OpCode::JUMP:
                case OpCode::JUMPZ:
                case OpCode::JUMPC:
                case OpCode::JUMPNZ:
                case OpCode::JUMPNC:
                case OpCode::CALL:
                case OpCode::CALLZ:
                case OpCode::CALLC:
                case OpCode::CALLNZ:
                case OpCode::CALLNC:
                    Assembly::makeFlowControlInstruction(opcode, address, expression.value, lineNum, words);
                    break;
                default:
                {
                    std::stringstream ss;
                    ss << "Error: opcode is not standalone with expression on line " << lineNum << std::endl;
                    throw std::runtime_error(ss.str());

                    break;
                }
            }

            break;
        }
        case StatementType::INDIRECT_ADDRESSING_OPCODE:
        {
            uint16_t op;

            int16_t idx = (int16_t)regInd - 24;

            if (idx < 0 || idx > 4)
            {
                std::stringstream ss;
                ss << "Error: illegal index register on line " << lineNum << std::endl;
                throw std::runtime_error(ss.str());

                break;
            }

            if ((uint16_t)regDest >= 16)
            {
                std::stringstream ss;
                ss << "Error: illegal destination/source register on line " << lineNum << std::endl;
                throw std::runtime_error(ss.str());

                break;
            }

            if ((uint16_t)regOffset >= 16)
            {
                std::stringstream ss;
                ss << "Error: illegal offset register on line " << lineNum << std::endl;
                throw std::runtime_error(ss.str());

                break;
            }

            switch (opcode)
            {
                case OpCode::LDW:

                    op = Assembly::LDW_REG_INSTRUCTION;

                    op |= idx << 8;
                    op |= (uint16_t)regDest << 4;
                    op |= (uint16_t)regOffset;

                    break;
                case OpCode::STW:

                    op = Assembly::STW_REG_INSTRUCTION;

                    op |= idx << 8;
                    op |= (uint16_t)regDest << 4;
                    op |= (uint16_t)regOffset;

                    break;
                default:
                {
                    std::stringstream ss;
                    ss << "Error: opcode cannot take indirect addressing on line " << lineNum << std::endl;
                    throw std::runtime_error(ss.str());

                    break;
                }
            }

            words.resize(1);
            words[0] = op;

            break;
        }
        case StatementType::INDIRECT_ADDRESSING_OPCODE_WITH_EXPRESSION:
        {

           //std::cout << "Indirect addressing opcode with expression " << *this << std::endl;

           Assembly::makeLoadStoreWithExpression(opcode, lineNum, words, expression.value, regInd, regDest);

           //std::cout << std::hex << words[0] << " " << words[1] << std::endl;

           break;

        }
        case StatementType::PSEUDO_OP_WITH_EXPRESSION:
        {
            switch (pseudoOp)
            {
                case PseudoOp::DW:
                {
                    // If the expression is a string literal, repeat the string literal repetition count number of times.

                    char* stringLit;

                    if (expression.isStringLiteral(stringLit))
                    {
                        char* substitutedString = Expression::substituteSpecialChars(stringLit);

                        uint32_t len = Expression::stringLength(substitutedString);

                        words.resize(len);

                        for (uint32_t i = 0; i < len; i++)
                        {
                            words[i] = (uint16_t)substitutedString[i];
                        }

                        delete [] substitutedString;
                    }
                    else
                    {
                        words.resize(1);
                        words[0] = expression.value;
                    }

                    break;
                }
                case PseudoOp::DD:
                {

                    break;
                }
            }

            break;
        }
        default:
            break;
    }

    // handle repetition count by repeating assembled bytes repetition count number of times.

    if (assembledWords.size() != words.size() * repetitionCount)
        assembledWords.resize(words.size() * repetitionCount);

    for (int i = 0; i < repetitionCount; i++)
        for (int j = 0; j < words.size(); j++)
        {
            assembledWords[i*words.size() + j] = words[j];
        }


    curAddress += assembledWords.size() * 2;

}

