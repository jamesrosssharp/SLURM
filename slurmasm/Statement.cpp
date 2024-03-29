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
	assembledBytes.clear();
	useBytes = false;

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
				case OpCode::MUL:
				case OpCode::MULU:
				case OpCode::UMULU:
				case OpCode::BNE:
				case OpCode::BEQ:
				case OpCode::BGT:
				case OpCode::BGE:
				case OpCode::BLT:
				case OpCode::BLE:
				case OpCode::LDB:
				case OpCode::LDBSX:
				case OpCode::STB:
				case OpCode::BLEU:
				case OpCode::BLTU:
				case OpCode::BGEU:
				case OpCode::BGTU:


					if (expressionCanFitIn4Bits)
						assembledWords.resize(1 * repetitionCount);
					else
						assembledWords.resize(2 * repetitionCount);
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

					uint16_t size = exprValue - curAddress%exprValue;

					printf("Align: %d\n", size);

					useBytes = true;

					assembledBytes.resize(size);

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

					if (exprValue < caddr)
					{
						std::stringstream ss;
						ss << "Error: invalid padto expression on line " << lineNum << std::endl;
						throw std::runtime_error(ss.str());
					}

					assembledBytes.resize(exprValue - caddr);
					useBytes = true;

					break;
				}
				case PseudoOp::DW:
				{
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
				}
				case PseudoOp::DB:
				{
					useBytes = true;
					// If DW string literal, then set the word count to the length of the string

					char* stringLit;

					if (expression.isStringLiteral(stringLit))
					{
						assembledBytes.resize(repetitionCount * Expression::stringLength(stringLit));
					}
					else
					{
						assembledBytes.resize(1 * repetitionCount);
					}
					break;
				}
				case PseudoOp::DD:
					// Do we need this?
					break;
			}

			break;
		default:
			break;
	}

	if (useBytes)
		curAddress += assembledBytes.size();
	else
		curAddress += 2*assembledWords.size();

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
				case OpCode::IRET:
					words[0] = SLRM_IRET_INSTRUCTION;
					break;
				case OpCode::NOP:
					words[0] = SLRM_NOP_INSTRUCTION;
					break;
				case OpCode::CLI:
					words[0] = SLRM_CLI_INSTRUCTION;
					break;
				case OpCode::STI:
					words[0] = SLRM_STI_INSTRUCTION;
					break;
				case OpCode::SLEEP:
					words[0] = SLRM_SLEEP_INSTRUCTION;
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
				case OpCode::STF:
				case OpCode::RSF:

					Assembly::makeExtendedArithmeticInstruction(opcode,
										 regDest,
										 words,
										 lineNum);
					break;
				
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
				case OpCode::MUL:
				case OpCode::MULU:
				case OpCode::UMULU:
					Assembly::makeArithmeticInstruction(opcode,
										 regDest,
										 regSrc, words,
										 lineNum);
					break; 
				case OpCode::MOVC:
				case OpCode::MOVNC:
				case OpCode::MOVZ:
				case OpCode::MOVNZ:
				case OpCode::MOVS:
				case OpCode::MOVNS:
				case OpCode::MOVV:
				case OpCode::MOVNV:
				case OpCode::MOVEQ:
				case OpCode::MOVNE:
				case OpCode::MOVLT:
				case OpCode::MOVLE:
				case OpCode::MOVGT:
				case OpCode::MOVGE:
				case OpCode::MOVLTU:
				case OpCode::MOVLEU:
				case OpCode::MOVGTU:
				case OpCode::MOVGEU:
					Assembly::makeConditionalMov(opcode, regDest, regSrc, words, lineNum);
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
				default:
				{
					std::stringstream ss;
					ss << "Error: opcode does not support three register mode on line " << lineNum << std::endl;
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
				case OpCode::MUL:
				case OpCode::MULU:
				case OpCode::UMULU:
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
				case OpCode::BLE:
				case OpCode::BLT:
				case OpCode::BEQ:
				case OpCode::BNE:
				case OpCode::BGT:
				case OpCode::BGE:
				case OpCode::BLEU:
				case OpCode::BLTU:
				case OpCode::BGEU:
				case OpCode::BGTU:

				

					Assembly::makeFlowControlInstruction(opcode, address, expression.value, Register::r0, lineNum,
										   words, false);

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
					Assembly::makeLoadStore(opcode, lineNum, words, regInd, regDest);
					break;	
				case OpCode::LDB:
				case OpCode::STB:
				case OpCode::LDBSX:
					Assembly::makeLoadStore(opcode, lineNum, words, regInd, regDest, true);
					break;

		
				case OpCode::BA:
				case OpCode::BL:
				case OpCode::BZ:
				case OpCode::BNZ:
				case OpCode::BS:
				case OpCode::BNS:
				case OpCode::BC:
				case OpCode::BNC:
				case OpCode::BGE:
				case OpCode::BGT:
				case OpCode::BLEU:
				case OpCode::BLTU:
				case OpCode::BGEU:
				case OpCode::BEQ:
				case OpCode::BNE:
				case OpCode::BLE:
				case OpCode::BLT:
	
			
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
				case OpCode::BGE:
				case OpCode::BGT:
				case OpCode::BLEU:
				case OpCode::BLTU:
				case OpCode::BGEU:
				case OpCode::BEQ:
				case OpCode::BNE:
				case OpCode::BLE:
				case OpCode::BLT:
	

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
				case OpCode::LDB:
				case OpCode::STB:
				case OpCode::LDBSX:
					Assembly::makeLoadStoreWithExpression(opcode, lineNum, words, expression.value, regDest, true);
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
				case OpCode::LDB:
				case OpCode::LDBSX:
				case OpCode::STB:
					Assembly::makeLoadStoreWithIndexAndExpression(opcode, lineNum, words, expression.value, regDest, regInd, true);
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

				case PseudoOp::DB:
					useBytes = true;
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

	if (useBytes) {
		
		if (assembledBytes.size() != words.size() * repetitionCount)
			assembledBytes.resize(words.size() * repetitionCount);

		for (int i = 0; i < repetitionCount; i++)
			for (int j = 0; j < words.size(); j++)
			{
				assembledBytes[i*words.size() + j] = words[j];
			}

	} else {	

		if (assembledWords.size() != words.size() * repetitionCount)
			assembledWords.resize(words.size() * repetitionCount);

		for (int i = 0; i < repetitionCount; i++)
			for (int j = 0; j < words.size(); j++)
			{
				assembledWords[i*words.size() + j] = words[j];
			}
	}

	if (useBytes)
		curAddress += assembledBytes.size();
	else
		curAddress += 2*assembledWords.size();

}

