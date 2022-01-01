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
    regSrc2  = Register::None;
	regDest	 = Register::None;
    timesStatement = nullptr;
    repetitionCount = 1;
    assembledWords.clear();
    address = 0;
	postDecrement = false;
	postIncrement = false;
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
		case StatementType::ONE_REGISTER_OPCODE:
		case StatementType::THREE_REGISTER_OPCODE:
		case StatementType::TWO_REGISTER_OPCODE:
		case StatementType::STANDALONE_OPCODE:
		case StatementType::INDIRECT_ADDRESSING_OPCODE:
		case StatementType::INDIRECT_ADDRESSING_OPCODE_WITH_POSTINCREMENT:
		case StatementType::INDIRECT_ADDRESSING_OPCODE_WITH_POSTDECREMENT:
        {
            // shouldn't get here - this should be assembled directly

            std::stringstream ss;
            ss << "Error: not directly assembling line " << lineNum << std::endl;
            throw std::runtime_error(ss.str());

            break;
        }
        case StatementType::ONE_REGISTER_OPCODE_AND_EXPRESSION:
        case StatementType::OPCODE_WITH_EXPRESSION:
        case StatementType::INDIRECT_ADDRESSING_OPCODE_WITH_EXPRESSION:
        case StatementType::INDIRECT_ADDRESSING_OPCODE_WITH_REG_AND_EXPRESSION:
        case StatementType::INDIRECT_ADDRESSING_OPCODE_WITH_INDEX_AND_EXPRESSION:
		{

            // Assembly might have 1 or two bytes, depending if an imm instruction is needed


            // can expression be evaluated? If so, see if it's possible to fit any immediate value into
            // a 4 bit nibble, in which case we don't need an imm (and we don't need to relax it away later)

            bool expressionCanFitIn4Bits = false;

            int32_t exprValue = 0;

            if (expression.evaluate(exprValue, syms))
            {
                if (exprValue >= 0 && exprValue < 16)
                    expressionCanFitIn4Bits = true;
            }

            switch (opcode)
            {
				case OpCode::ADC:
				case OpCode::ADD:
				case OpCode::AND:
				case OpCode::BA:
				case OpCode::BC:
				case OpCode::BL:
				case OpCode::BNC:
				case OpCode::BNS:
				case OpCode::BNZ:
				case OpCode::BS:
				case OpCode::BZ:
				case OpCode::IMM:
				case OpCode::LD:
				case OpCode::IN:
				case OpCode::MOV:
				case OpCode::OR:
				case OpCode::OUT:
				case OpCode::SBB:
				case OpCode::SUB:
				case OpCode::ST:
				case OpCode::XOR:
				case OpCode::CMP:
				case OpCode::TEST:
					if (expressionCanFitIn4Bits)
                        assembledWords.resize(1 * repetitionCount);
                    else
                        assembledWords.resize(2 * repetitionCount);
                    break;
             	case OpCode::BL_REL:
				case OpCode::BA_REL:
				case OpCode::BZ_REL:
				case OpCode::BNZ_REL:
				case OpCode::BC_REL:
				case OpCode::BNC_REL:
				case OpCode::BS_REL:
				case OpCode::BNS_REL:
					assembledWords.resize(1 * repetitionCount);
					break;
			    default:
                {
                    std::stringstream ss;
                    ss << "Error: opcode cannot take expression on line " << lineNum << std::endl;
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

                    assembledWords.resize(exprValue - curAddress%exprValue);

                    break;
                }
				case PseudoOp::PADTO:
				{
				    int32_t exprValue = 0;

					int32_t caddr = curAddress;

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

					printf("CurAddress: %d\n", caddr);
					printf("ExprValue: %d\n",  exprValue);
					fflush(0);	

					if (exprValue < caddr)
					{
					   	std::stringstream ss;
						ss << "Error: invalid padto expression on line " << lineNum << std::endl;
						throw std::runtime_error(ss.str());
					}

		            assembledWords.resize(exprValue - caddr);

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

    curAddress += assembledWords.size();

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
            words.resize(1);
		 
		    switch (opcode)
            {
				case OpCode::CC:
				case OpCode::CS:
				case OpCode::CZ:
				case OpCode::SC:
				case OpCode::SS:
				case OpCode::SZ:
					Assembly::makeExtendedArithmeticInstruction(opcode,
                                         Register::r0, words,
                                         lineNum);
					break;
				case OpCode::RET:
					words[0] = SLRM_RET_INSTRUCTION;
					break;
        		case OpCode::NOP:
					words[0] = SLRM_NOP_INSTRUCTION;
					break;
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
			words.resize(1);

            switch (opcode)
            {
				case OpCode::ASR:
				case OpCode::LSR:
				case OpCode::LSL:
				case OpCode::ROLC:
				case OpCode::RORC:
				case OpCode::ROL:
				case OpCode::ROR:


			 		Assembly::makeExtendedArithmeticInstruction(opcode,
                                         regDest,
                                         words,
                                         lineNum);
            		break;
				case OpCode::INC:
				case OpCode::DEC:
				{
 				 	Assembly::makeIncDecInstruction(opcode,
      									 words,
                                         lineNum, regDest);
            		break;
                }
				default:
                {
            		std::stringstream ss;
                    ss << "Error: opcode does not support one register mode on line " << lineNum << std::endl;
                    throw std::runtime_error(ss.str());

                    break;
                }
			}
			break;
        }
		case StatementType::TWO_REGISTER_OPCODE:
        {
            words.resize(1);

            switch (opcode)
            {
				case OpCode::ADC:
				case OpCode::ADD:
				case OpCode::AND:
				case OpCode::MOV:
				case OpCode::OR:
				case OpCode::SBB:
				case OpCode::SUB:
				case OpCode::XOR:
				case OpCode::CMP:
				case OpCode::TEST:
			 		Assembly::makeArithmeticInstruction(opcode,
                                         regDest,
                                         regSrc, words,
                                         lineNum);
            		break; 
                default:
                {
            		std::stringstream ss;
                    ss << "Error: opcode does not support two register mode on line " << lineNum << std::endl;
                    throw std::runtime_error(ss.str());

                    break;
                }
            }

            break;
        }
       	case StatementType::THREE_REGISTER_OPCODE:
        {
            words.resize(1);

            switch (opcode)
            {
				case OpCode::ADC:
				case OpCode::ADD:
				case OpCode::AND:
				case OpCode::OR:
				case OpCode::SBB:
				case OpCode::SUB:
				case OpCode::XOR:
			 		Assembly::makeThreeRegisterArithmeticInstruction(opcode,
                                         regDest,
                                         regSrc, regSrc2, words,
                                         lineNum);
            		break; 
                default:
                {
            		std::stringstream ss;
                    ss << "Error: opcode does not support two register mode on line " << lineNum << std::endl;
                    throw std::runtime_error(ss.str());

                    break;
                }
            }

            break;
        }
		case StatementType::ONE_REGISTER_OPCODE_AND_EXPRESSION:
        {
            switch (opcode)
            {
           		case OpCode::ADC:
				case OpCode::ADD:
				case OpCode::AND:
				case OpCode::LSL:
				case OpCode::LSR:
				case OpCode::MOV:
				case OpCode::OR:
				case OpCode::ROL:
				case OpCode::ROLC:
				case OpCode::RORC:
				case OpCode::SBB:
				case OpCode::SUB:
				case OpCode::XOR:
				case OpCode::CMP:
				case OpCode::TEST:
			 		Assembly::makeArithmeticInstructionWithImmediate(opcode,
                                         regDest,
                                         expression.value, words,
                                         lineNum);
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
				case OpCode::BA:
				case OpCode::BC:
				case OpCode::BL:
				case OpCode::BNC:
				case OpCode::BNS:
				case OpCode::BNZ:
				case OpCode::BS:
				case OpCode::BZ:
					Assembly::makeFlowControlInstruction(opcode, address, expression.value, Register::r0, lineNum,
                                           words, false);

					break;
				case OpCode::BA_REL:
				case OpCode::BC_REL:
				case OpCode::BL_REL:
				case OpCode::BNC_REL:
				case OpCode::BNS_REL:
				case OpCode::BNZ_REL:
				case OpCode::BS_REL:
				case OpCode::BZ_REL:
					Assembly::makeRelativeFlowControlInstruction(opcode, address, expression.value, lineNum,
                                           words);

					break;
				case OpCode::IMM:
					words[0] = SLRM_IMM_INSTRUCTION | ((uint16_t)expression.value >> 4); 
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
			words.resize(1);

            switch (opcode)
            {
    			case OpCode::LD:
				case OpCode::ST:
           			Assembly::makeLoadStore(opcode, lineNum, words, regInd, regDest, postIncrement, postDecrement);
					break;	
			    case OpCode::BA:
			    case OpCode::BL:
			    case OpCode::BZ:
			    case OpCode::BNZ:
			    case OpCode::BS:
			    case OpCode::BNS:
			    case OpCode::BC:
				case OpCode::BNC:
					Assembly::makeFlowControlInstruction(opcode, address, 0, regInd, lineNum, words, true);
					break;	
				default:
                {
                    std::stringstream ss;
                    ss << "Error: opcode cannot take indirect addressing on line " << lineNum << std::endl;
                    throw std::runtime_error(ss.str());

                    break;
                }
            }

            break;
        }
        case StatementType::INDIRECT_ADDRESSING_OPCODE_WITH_REG_AND_EXPRESSION:
        {
			//words.resize(1);

            switch (opcode)
            {
			    case OpCode::BA:
			    case OpCode::BL:
			    case OpCode::BZ:
			    case OpCode::BNZ:
			    case OpCode::BS:
			    case OpCode::BNS:
			    case OpCode::BC:
				case OpCode::BNC:
					Assembly::makeFlowControlInstruction(opcode, address, expression.value, regInd, lineNum, words, true);
					break;	
				default:
                {
                    std::stringstream ss;
                    ss << "Error: opcode cannot take indirect addressing with register and expression on line " << lineNum << std::endl;
                    throw std::runtime_error(ss.str());

                    break;
                }
            }

            break;
        }
        case StatementType::INDIRECT_ADDRESSING_OPCODE_WITH_EXPRESSION:
        {
		    switch (opcode)
            {
    			case OpCode::LD:
				case OpCode::ST:
           			Assembly::makeLoadStoreWithExpression(opcode, lineNum, words, expression.value, regDest);
					break;	
			    default:
                {
                    std::stringstream ss;
                    ss << "Error: opcode cannot take indirect addressing on line " << lineNum << std::endl;
                    throw std::runtime_error(ss.str());

                    break;
                }
            }

           break;

        }
        case StatementType::INDIRECT_ADDRESSING_OPCODE_WITH_INDEX_AND_EXPRESSION:
        {
		    switch (opcode)
            {
    			case OpCode::LD:
				case OpCode::ST:
           			Assembly::makeLoadStoreWithIndexAndExpression(opcode, lineNum, words, expression.value, regDest, regInd);
					break;
				case OpCode::IN:
				case OpCode::OUT:
					Assembly::makePortIO(opcode, lineNum, words, expression.value, regDest, regInd);
					break;	
			    default:
                {
                    std::stringstream ss;
                    ss << "Error: opcode cannot take indirect addressing with register and immediate on line " << lineNum << std::endl;
                    throw std::runtime_error(ss.str());

                    break;
                }
            }

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


    curAddress += assembledWords.size();

}

