
#include "AST.h"
#include <exception>
#include <stdexcept>
#include <map>
#include <sstream>

#include "Relocation.h"
#include <host/ELF/ElfFile.h>

#include "ExReg.h"

AST::AST()
{

}

AST::~AST()
{

}
	
void AST::push_stack(ExpressionNode* item)
{
	m_stack.push_back(item);	
}

bool AST::pop_stack(ExpressionNode** item)
{
	if (m_stack.empty()) return false;
	*item = m_stack.back();
	m_stack.pop_back();
	return true;
}

void AST::push_number(int number)
{
	ExpressionNode* item = new ExpressionNode();
	item->type = ITEM_NUMBER;
	item->val.value = number;
	item->left = item->right = NULL;
	push_stack(item);
}


void AST::push_binary(enum ItemType type)
{
	ExpressionNode* item = new ExpressionNode();
	item->type = type;

	if (!pop_stack(&item->right))
		throw std::runtime_error("Parse error!");

	if (!pop_stack(&item->left))
		throw std::runtime_error("Parse error!");

	push_stack(item);
}

void AST::push_lshift()
{
	push_binary(ITEM_LSHIFT);
}

void AST::push_rshift()
{
	push_binary(ITEM_RSHIFT);
}

void AST::push_add()
{
	push_binary(ITEM_ADD);
}

void AST::push_subtract()
{
	push_binary(ITEM_SUBTRACT);
}

void AST::push_mult()
{
	push_binary(ITEM_MULT);
}

void AST::push_div()
{
	push_binary(ITEM_DIV);
}

void AST::push_unary_neg()
{
	ExpressionNode* item = new ExpressionNode();
	item->type = ITEM_UNARY_NEG;

	if (!pop_stack(&item->left))
		throw std::runtime_error("Parse error!");

	item->right = NULL;

	push_stack(item);

}

void AST::push_char_literal(char *string)
{
	ExpressionNode* item = new ExpressionNode();
	item->type = ITEM_NUMBER;
	
	std::string str = string;

	if (str == "\\n")
		item->val.value = '\n';
	else if (str == "\\r")
		item->val.value = '\r';
	else if (str == "\\0")
		item->val.value = '\0';
	else
		item->val.value = (int)string[0];
	
	item->left = item->right = NULL;
	push_stack(item);
}

void AST::push_bitwise_complement()
{
	ExpressionNode* item = new ExpressionNode();
	item->type = ITEM_COMPL;

	if (!pop_stack(&item->left))
		throw std::runtime_error("Parse error!");

	item->right = NULL;

	push_stack(item);

}

void AST::push_symbol(char *symbol)
{
	ExpressionNode* item = new ExpressionNode();
	item->type = ITEM_SYMBOL;
	item->val.name = symbol;
	item->left = item->right = NULL;
	push_stack(item);
}

void AST::addEqu(int linenum, char* label)
{
	m_currentStatement.lineNum = linenum;
	m_currentStatement.type = StatementType::EQU;
	m_currentStatement.expression.lineNum = linenum;
	m_currentStatement.expression.root = m_stack.back();
	m_stack.pop_back();
	m_currentStatement.label = label;
	m_sectionStatements[m_currentSection].push_back(m_currentStatement);
	m_currentStatement.reset();

}

void AST::addLabel(int linenum, char* label)
{
	m_currentStatement.lineNum = linenum;
	m_currentStatement.label = label;
	m_currentStatement.type = StatementType::LABEL;
	m_sectionStatements[m_currentSection].push_back(m_currentStatement);
	m_currentStatement.reset();
}

void AST::addOneRegisterAndExpressionOpcode(int linenum, char* opcode, char* regDest)
{
	m_currentStatement.lineNum = linenum;
	m_currentStatement.opcode = convertOpCode(opcode);
	m_currentStatement.regDest = convertReg(regDest);
	m_currentStatement.type = StatementType::ONE_REGISTER_OPCODE_AND_EXPRESSION;
	m_currentStatement.expression.lineNum = linenum;
	m_currentStatement.expression.root = m_stack.back();
	m_stack.pop_back();
	m_sectionStatements[m_currentSection].push_back(m_currentStatement);
	m_currentStatement.reset();

}

void AST::addExpressionOpcode(int linenum, char* opcode)
{
	m_currentStatement.lineNum = linenum;
	m_currentStatement.opcode = convertOpCode(opcode);
	m_currentStatement.type = StatementType::OPCODE_WITH_EXPRESSION;
	m_currentStatement.expression.lineNum = linenum;
	m_currentStatement.expression.root = m_stack.back();
	m_stack.pop_back();
	m_sectionStatements[m_currentSection].push_back(m_currentStatement);
	m_currentStatement.reset();

}

void AST::addStandaloneOpcode(int linenum, char* opcode)
{
	m_currentStatement.lineNum = linenum;
	m_currentStatement.opcode = convertOpCode(opcode);
	m_currentStatement.type = StatementType::STANDALONE_OPCODE;
	m_currentStatement.expression.lineNum = linenum;
	m_sectionStatements[m_currentSection].push_back(m_currentStatement);
	m_currentStatement.reset();
}

void AST::addThreeRegCondOpcode(int line_num, char* cond, char* regdest, char* regsrc1, char* regsrc2)
{
	std::string c = cond;

	std::string opcode = c.substr(0, c.find_first_of('.'));
	std::string cc = c.substr(c.find_first_of('.') + 1); 

	m_currentStatement.lineNum = line_num;
	m_currentStatement.opcode = convertOpCode(opcode);
	m_currentStatement.cond = convertCond(cc);
	
	m_currentStatement.regDest = convertReg(regdest);
	m_currentStatement.regSrc = convertReg(regsrc1);
	m_currentStatement.regSrc2 = convertReg(regsrc2);

	m_currentStatement.type = StatementType::THREE_REGISTER_COND_OPCODE;
	m_sectionStatements[m_currentSection].push_back(m_currentStatement);
	m_currentStatement.reset();
}

void AST::addTwoRegisterOpcode(int line_num, char* opcode, char* regdest, char* regsrc)
{
	m_currentStatement.lineNum = line_num;
	m_currentStatement.opcode = convertOpCode(opcode);
	m_currentStatement.regDest = convertReg(regdest);
	m_currentStatement.regSrc = convertReg(regsrc);
	m_currentStatement.type = StatementType::TWO_REGISTER_OPCODE;
	m_sectionStatements[m_currentSection].push_back(m_currentStatement);
	m_currentStatement.reset();
}

void AST::addTwoRegisterCondOpcode(int line_num, char* cond, char* regdest, char* regsrc)
{
	std::string c = cond;

	std::string opcode = c.substr(0, c.find_first_of('.'));
	std::string cc = c.substr(c.find_first_of('.') + 1); 

	m_currentStatement.lineNum = line_num;
	m_currentStatement.opcode = convertOpCode(opcode);
	m_currentStatement.cond = convertCond(cc);
	
	m_currentStatement.regDest = convertReg(regdest);
	m_currentStatement.regSrc = convertReg(regsrc);
	m_currentStatement.type = StatementType::TWO_REGISTER_COND_OPCODE;
	m_sectionStatements[m_currentSection].push_back(m_currentStatement);
	m_currentStatement.reset();

}

void AST::addOneRegisterOpcode(int line_num, char* opcode, char* regdest)
{
	m_currentStatement.lineNum = line_num;
	m_currentStatement.opcode = convertOpCode(opcode);
	m_currentStatement.regDest = convertReg(regdest);
	m_currentStatement.type = StatementType::ONE_REGISTER_OPCODE;
	m_sectionStatements[m_currentSection].push_back(m_currentStatement);
	m_currentStatement.reset();
}

void AST::addOneRegisterIndirectOpcode(int line_num, char* opcode, char* regidx)
{
	m_currentStatement.lineNum = line_num;
	m_currentStatement.opcode = convertOpCode(opcode);
	m_currentStatement.regInd = convertReg(regidx);
	m_currentStatement.type = StatementType::ONE_REGISTER_INDIRECT_OPCODE;
	m_sectionStatements[m_currentSection].push_back(m_currentStatement);
	m_currentStatement.reset();
}

void AST::addOneRegisterIndirectOpcodeWithExpression(int line_num, char* opcode, char* regidx)
{
	m_currentStatement.lineNum = line_num;
	m_currentStatement.opcode = convertOpCode(opcode);
	m_currentStatement.regInd = convertReg(regidx);
	m_currentStatement.type = StatementType::ONE_REGISTER_INDIRECT_OPCODE_AND_EXPRESSION;
	m_currentStatement.expression.lineNum = line_num;
	m_currentStatement.expression.root = m_stack.back();
	m_stack.pop_back();
	m_sectionStatements[m_currentSection].push_back(m_currentStatement);
	m_currentStatement.reset();
}

void AST::addTwoRegisterIndirectOpcodeA(int line_num, char* opcode, char* regdest, char* regidx)
{
	m_currentStatement.lineNum = line_num;
	m_currentStatement.opcode = convertOpCode(opcode);
	m_currentStatement.regInd = convertReg(regidx);
	m_currentStatement.regDest = convertReg(regdest);
	m_currentStatement.type = StatementType::TWO_REGISTER_INDIRECT_OPCODE_A;
	m_sectionStatements[m_currentSection].push_back(m_currentStatement);
	m_currentStatement.reset();
}

void AST::addTwoRegisterIndirectOpcodeWithExpressionA(int line_num, char* opcode, char* regdest, char* regidx)
{
	m_currentStatement.lineNum = line_num;
	m_currentStatement.opcode = convertOpCode(opcode);
	m_currentStatement.regInd = convertReg(regidx);
	m_currentStatement.regDest = convertReg(regdest);
	m_currentStatement.type = StatementType::TWO_REGISTER_INDIRECT_OPCODE_AND_EXPRESSION_A;
	m_currentStatement.expression.lineNum = line_num;
	m_currentStatement.expression.root = m_stack.back();
	m_stack.pop_back();
	m_sectionStatements[m_currentSection].push_back(m_currentStatement);
	m_currentStatement.reset();
}

void AST::addTwoRegisterIndirectOpcodeB(int line_num, char* opcode, char* regidx, char* regdest)
{
	m_currentStatement.lineNum = line_num;
	m_currentStatement.opcode = convertOpCode(opcode);
	m_currentStatement.regInd = convertReg(regidx);
	m_currentStatement.regDest = convertReg(regdest);
	m_currentStatement.type = StatementType::TWO_REGISTER_INDIRECT_OPCODE_B;
	m_sectionStatements[m_currentSection].push_back(m_currentStatement);
	m_currentStatement.reset();
}

void AST::addTwoRegisterIndirectOpcodeWithExpressionB(int line_num, char* opcode, char* regidx, char* regdest)
{
	m_currentStatement.lineNum = line_num;
	m_currentStatement.opcode = convertOpCode(opcode);
	m_currentStatement.regInd = convertReg(regidx);
	m_currentStatement.regDest = convertReg(regdest);
	m_currentStatement.type = StatementType::TWO_REGISTER_INDIRECT_OPCODE_AND_EXPRESSION_B;
	m_currentStatement.expression.lineNum = line_num;
	m_currentStatement.expression.root = m_stack.back();
	m_stack.pop_back();
	m_sectionStatements[m_currentSection].push_back(m_currentStatement);
	m_currentStatement.reset();
}

void AST::addPseudoOp(int line_num, char *pseudo_op)
{
	//std::cout << "Pseudo op: " << line_num << " " << pseudo_op << std::endl;	
	m_currentStatement.lineNum = line_num;
	m_currentStatement.pseudoOp = convertPseudoOp(pseudo_op);
	m_currentStatement.type = StatementType::PSEUDO_OP;

	m_sectionStatements[m_currentSection].push_back(m_currentStatement);
	
	// Sanity check

	switch (m_currentStatement.pseudoOp)
	{
		case PseudoOp::ENDFUNC:
			m_currentSection = m_prevSection;
			break;
		default:
		{
			std::stringstream ss;
			ss << "Pseudo Op " << m_currentStatement.pseudoOp << "cannot be stand-alone on line " << line_num << std::endl;	
			throw std::runtime_error(ss.str());
		}	
	}


	m_currentStatement.reset();
}

void AST::addPseudoOpWithExpression(int line_num, char *pseudo_op)
{
	//std::cout << "Pseudo op with expression: " << line_num << " " << pseudo_op << std::endl;	

	m_currentStatement.lineNum = line_num;
	m_currentStatement.pseudoOp = convertPseudoOp(pseudo_op);
	m_currentStatement.type = StatementType::PSEUDO_OP_WITH_EXPRESSION;
	m_currentStatement.expression.lineNum = line_num;
	m_currentStatement.expression.root = m_stack.back();
	m_stack.pop_back();

	// Some pseudo ops need to be processed now.
	switch (m_currentStatement.pseudoOp)
	{
		case PseudoOp::SECTION:
			if (m_currentStatement.expression.isString())
			{
				m_currentSection = "." + std::string(m_currentStatement.expression.getString());
			}
			else
			{
				std::stringstream ss;
				ss << "Pseudo Op " << m_currentStatement.pseudoOp << "takes only a single string (section name) on line " << line_num << std::endl;	
				throw std::runtime_error(ss.str());
			}
			break;
		case PseudoOp::EXTERN:
			if (m_currentStatement.expression.isString())
			{
				m_currentStatement.label = m_currentStatement.expression.getString();
			}
			else
			{
				std::stringstream ss;
				ss << "Pseudo Op " << m_currentStatement.pseudoOp << "takes only a single string (symbol name) on line " << line_num << std::endl;	
				throw std::runtime_error(ss.str());
			}
			break;
		case PseudoOp::FUNCTION:
			if (m_currentStatement.expression.isString())
			{
				m_prevSection = m_currentSection;
				m_currentSection = m_currentSection + "." + std::string(m_currentStatement.expression.getString());
			}
			else
			{
				std::stringstream ss;
				ss << "Pseudo Op " << m_currentStatement.pseudoOp << "takes only a single string (symbol name) on line " << line_num << std::endl;	
				throw std::runtime_error(ss.str());
			}
			break;
		default:
			break;
	}

	m_sectionStatements[m_currentSection].push_back(m_currentStatement);
	m_currentStatement.reset();
}

std::string substituteSpecialChars(char* stringLit)
{
    std::string newString;

    uint32_t pos = 0;
    uint32_t newPos = 0;

    while (1)
    {
        if (stringLit[pos] == '\0')
        {
            break;
        }

        if (stringLit[pos] == '\\')
        {
            pos++;
            switch (stringLit[pos])
            {
                case 'n':
                    newString  += '\n';
                    break;
                case 'r':
                    newString  += '\r';
                    break;
                case '0':
                    newString += '\0';
                    break;
            }
        }
        else
        {
            newString += stringLit[pos];
        }
        pos++;
    }

    return newString;
}



void AST::addPseudoOpWithStringLiteral(int line_num, char* pseudo_op, char* string)
{

	m_currentStatement.lineNum = line_num;
	m_currentStatement.pseudoOp = convertPseudoOp(pseudo_op);
	m_currentStatement.type = StatementType::PSEUDO_OP_WITH_STRING_LITERAL;
	m_currentStatement.str_literal = substituteSpecialChars(string);
	m_sectionStatements[m_currentSection].push_back(m_currentStatement);
	m_currentStatement.reset();
} 

void AST::addTimes(int line_num)
{
	//std::cout << "Times: " << line_num << std::endl;

	Statement& s = m_sectionStatements[m_currentSection].back();

	s.hasTimes = true;
	s.timesExpression.lineNum = line_num;
	s.timesExpression.root = m_stack.back();
	m_stack.pop_back();

}

void AST::addRegisterToExtendedRegisterALUOp(int line_num, char* opcode, char* extended_reg, char* reg)
{
	//std::cout << "Reg2ex: " << line_num << " " << opcode << " " << extended_reg << "," << reg << std::endl;

	m_currentStatement.regX.parse(line_num, extended_reg);

	m_currentStatement.lineNum = line_num;
	m_currentStatement.opcode = convertOpCode(opcode);
	m_currentStatement.regSrc = convertReg(reg);
	m_currentStatement.type = StatementType::REGISTER_TO_EXTENDED_REGISTER_ALU_OP;
	
	m_sectionStatements[m_currentSection].push_back(m_currentStatement);
	m_currentStatement.reset();

} 

void AST::addExtendedRegisterToRegisterALUOp(int line_num, char* opcode, char* reg, char* extended_reg)
{
//	std::cout << "ex2reg: " << line_num << " " << opcode << " " << reg << "," << extended_reg << std::endl;

	m_currentStatement.regX.parse(line_num, extended_reg);

	m_currentStatement.lineNum = line_num;
	m_currentStatement.opcode = convertOpCode(opcode);
	m_currentStatement.regDest = convertReg(reg);
	m_currentStatement.type = StatementType::EXTENDED_REGISTER_TO_REGISTER_ALU_OP;

	m_sectionStatements[m_currentSection].push_back(m_currentStatement);
	m_currentStatement.reset();

} 

OpCode AST::convertOpCode(std::string s)
{

	for (auto & c: s)
		c = toupper(c);

	return OpCode_convertOpCode(s);

}

PseudoOp AST::convertPseudoOp(std::string s)
{

	for (auto & c: s)
		c = toupper(c);

	return PseudoOp_convertPseudoOp(s);

}



Cond AST::convertCond(std::string s)
{

	for (auto & c: s)
		c = toupper(c);

	return Cond_convertCond(s);

}



Register AST::convertReg(char* reg)
{

	std::string s(reg);

	for (auto & c: s)
		c = tolower(c);

	if (s == "r0")
	{
		return Register::r0;
	}
	else if (s == "r1")
	{
		return Register::r1;
	}
	else if (s == "r2")
	{
		return Register::r2;
	}
	else if (s == "r3")
	{
		return Register::r3;
	}
	else if (s == "r4")
	{
		return Register::r4;
	}
	else if (s == "r5")
	{
		return Register::r5;
	}
	else if (s == "r6")
	{
		return Register::r6;
	}
	else if (s == "r7")
	{
		return Register::r7;
	}
	else if (s == "r8")
	{
		return Register::r8;
	}
	else if (s == "r9")
	{
		return Register::r9;
	}
	else if (s == "r10")
	{
		return Register::r10;
	}
	else if (s == "r11")
	{
		return Register::r11;
	}
	else if (s == "r12")
	{
		return Register::r12;
	}
	else if (s == "r13")
	{
		return Register::r13;
	}
	else if (s == "r14")
	{
		return Register::r14;
	}
	else if (s == "r15")
	{
		return Register::r15;
	}


	return Register::None;
}

void AST::print()
{
	std::cout << "Assembled AST:" << std::endl;

	// Iterate over sections, statements, etc
	for (const auto& kv : m_sectionStatements)
	{
		auto sec = kv.first;

		std::cout << "\tSection " << sec << ":" << std::endl;

		for (const auto& stat : kv.second)
		{	
			std::cout << "\t\t" << stat;
		}

	}
}

void AST::buildSymbolTable()
{
	// Iterate over sections, statements, etc
	for (auto& kv : m_sectionStatements)
	{
		auto sec = kv.first;

		for (auto& s : kv.second)
		{	
			// For each statement, if it is a LABEL or 
			// an EQU, add it to the symbol table		

			if (s.type == StatementType::LABEL)
			{
				m_symbolTable.addSymbol(s, sec);
			}
			else if (s.type == StatementType::EQU)
			{
				m_symbolTable.addConstant(s, sec);
			}
			else if (s.type == StatementType::PSEUDO_OP_WITH_EXPRESSION)
			{
				if (s.pseudoOp == PseudoOp::EXTERN)
				{
					m_symbolTable.addSymbol(s, "");
				}
			}
		}

	}

}

/*
 *	Simplifies all EQU constants to most basic form.
 *	
 */
void AST::reduceSymbolTable()
{
	m_symbolTable.reduce();
}

void AST::printSymbolTable()
{
	std::cout << m_symbolTable << std::endl;
}

void AST::reduceAllExpressions()
{
	// Iterate over sections, statements, etc
	for (auto& kv : m_sectionStatements)
	{
		auto sec = kv.first;

		for (auto& s : kv.second)
		{	
			switch (s.type)
			{
				case StatementType::LABEL:
				case StatementType::EQU:
				case StatementType::ONE_REGISTER_OPCODE_AND_EXPRESSION:
				case StatementType::OPCODE_WITH_EXPRESSION:
				case StatementType::ONE_REGISTER_INDIRECT_OPCODE_AND_EXPRESSION:
				case StatementType::TWO_REGISTER_INDIRECT_OPCODE_AND_EXPRESSION_A:
				case StatementType::TWO_REGISTER_INDIRECT_OPCODE_AND_EXPRESSION_B:
					s.expression.add_undefined_symbols_to_symtab(s, m_symbolTable);
					s.expression.reduce_to_label_plus_const(m_symbolTable.symtab);
					break;
				case StatementType::PSEUDO_OP_WITH_EXPRESSION:
					switch (s.pseudoOp)
					{
						case PseudoOp::ALIGN:
						case PseudoOp::DB:
						case PseudoOp::DW:
						case PseudoOp::DD:
							s.expression.reduce_to_label_plus_const(m_symbolTable.symtab);
							break; 
					}
					break;
			}	
			
			if (s.hasTimes)
				s.timesExpression.reduce_to_label_plus_const(m_symbolTable.symtab);
		}

	}
}

void AST::assemble()
{
	// Iterate over sections, statements, etc
	for (auto& kv : m_sectionStatements)
	{
		auto sec = kv.first;

		for (auto& s : kv.second)
		{	
			s.assemble();
		}

	}
}

void AST::resolveSymbols()
{

	for (auto& kv : m_sectionStatements)
	{
		auto sec = kv.first;

		int sec_address = 0;

		for (auto& s : kv.second)
		{	
			switch (s.type)
			{
				case StatementType::LABEL:
					s.annotateLabel(m_symbolTable.symtab, sec, sec_address);	
					break;
				default:
					sec_address += s.assembledBytes.size();
					break;
			}	
		}

	}
}

void AST::generateRelocationTables()
{
	for (auto& kv : m_sectionStatements)
	{
		auto sec = kv.first;

		int sec_address = 0;
		
		std::vector<Relocation> vec;
	
		for (auto& s : kv.second)
		{	
			Relocation rel;

			if (s.createRelocation(rel, m_symbolTable.symtab, sec, sec_address))
			{
				vec.push_back(rel);
			}			

			sec_address += s.assembledBytes.size();
		}

		// Emplace in relocation table
		m_relocationTable.emplace(sec, vec);
	}
}


void AST::printRelocationTable()
{
	std::cout << m_relocationTable << std::endl;
}

void AST::writeElfFile(char* outputFile)
{

	ElfFile e;

	// Add sections first

	for (auto& kv : m_sectionStatements)
	{
		auto sec = kv.first;

		int sec_address = 0;
		
		std::vector<uint8_t> vec;
	
		for (auto& s : kv.second)
		{	
			for (const auto& a : s.assembledBytes)
				vec.push_back(a);
		}

		e.addSection(sec, vec);
	}

	// Now add symbols
	e.beginSymbolTable();

	for (Symbol* sym : m_symbolTable.symlist)
	{
		if (sym->type == SYMBOL_LABEL)
		{
			e.addSymbol(sym->name, sym->section, sym->value, sym->e_bind, sym->e_type, sym->size);
		}
	}

	e.finaliseSymbolTable();
	
	// Add relocations

	for (auto& kv : m_relocationTable)
	{
		auto sec = kv.first;

		e.beginRelocationTable(sec);

		for (const auto& rel : kv.second)
		{
			e.addRelocation(rel.sym->name, rel.offset, rel.address);
		}

		e.finaliseRelocationTable();

	}

	// Write output
	e.writeOutput(outputFile);
}

void AST::generateTimesMacros()
{
	for (auto& kv : m_sectionStatements)
	{
		auto sec = kv.first;

		for (auto& s : kv.second)
		{	
	
			if (s.hasTimes)
			{
				if (s.timesExpression.is_const)
				{
					s.repetitionCount = s.timesExpression.getValue(); 
				}
				else
				{
					std::stringstream ss;
					ss << ".TIMES expression not reducible to a constant on line " << s.lineNum << std::endl;	
					throw std::runtime_error(ss.str());
				}

				std::vector<uint8_t> v;
		
				for (auto c : s.assembledBytes)
					v.push_back(c);
			
				// Do the actual repetition of the assembled bytes specified by the times macro
				for (int i = 0; i < s.repetitionCount - 1; i++)
					for (const auto& a : v)
						s.assembledBytes.push_back(a);

			}

		}
	}
}

void AST::handleAlignStatements()
{
	for (auto& kv : m_sectionStatements)
	{
		auto sec = kv.first;

		uint32_t sec_address = 0;

		for (auto& s : kv.second)
		{	

			switch (s.type)
			{
				case StatementType::PSEUDO_OP_WITH_EXPRESSION:
				{
					switch (s.pseudoOp)
					{
						case PseudoOp::ALIGN:		

							if (s.expression.is_const)
							{
								
								uint32_t a = s.expression.getValue(); 
								uint32_t align_add = ((sec_address + a-1) / a) * a;

								int32_t delta = align_add - sec_address;

								for (int i = 0; i < delta; i++)
									s.assembledBytes.push_back(0);
							}
							else
							{
								std::stringstream ss;
								ss << ".ALIGN expression not reducible to a constant on line " << s.lineNum << std::endl;	
								throw std::runtime_error(ss.str());
							}



							break;
						default:
							break;
					}
				}
				break;
				default:
					break;
			}
	
			sec_address += s.assembledBytes.size();

		}
	}
}

void AST::handleGlobalAndWeakSymbols()
{
	// Search through all statements, and find .GLOBAL and .WEAK statements.
	// Mark corresponding symbols as appropriate.

	for (auto& kv : m_sectionStatements)
	{
		auto sec = kv.first;

		for (auto& s : kv.second)
		{	

			switch (s.type)
			{
				case StatementType::PSEUDO_OP_WITH_EXPRESSION:
				{
					switch (s.pseudoOp)
					{
						case PseudoOp::GLOBAL:		
							if (s.expression.isString())
							{
								std::string n = s.expression.getString();

								try {
									Symbol& sym = m_symbolTable.symtab.at(n);
									sym.e_bind = STB_GLOBAL;
								} 
								catch (...)
								{
									std::stringstream ss;
									ss << ".GLOBAL statement for undeclared symbol '" << n << "'on line " << s.lineNum << std::endl;	
									throw std::runtime_error(ss.str());
								}

							}
							else
							{
								std::stringstream ss;
								ss << ".GLOBAL statement must take a single string, the symbol name, on line " << s.lineNum << std::endl;	
								throw std::runtime_error(ss.str());
							}
				
							break;
						case PseudoOp::WEAK:
							if (s.expression.isString())
							{
								std::string n = s.expression.getString();
								Symbol& sym = m_symbolTable.symtab.at(n);
								sym.e_bind = STB_WEAK;
							}
							else
							{
								std::stringstream ss;
								ss << ".GLOBAL statement must take a single string, the symbol name, on line " << s.lineNum << std::endl;	
								throw std::runtime_error(ss.str());
							}
				

							break;
						default:
							break;
					}
				}
				break;
				default:
					break;
			}
	
		}
	}


}

void AST::determineFunctionsAndLengths()
{
	// Search through all statements, mark functions. Compute function length. Store against symbol.

	for (auto& kv : m_sectionStatements)
	{
		auto sec = kv.first;

		uint32_t sec_address = 0;

		std::string cur_func = "";
		uint32_t func_start = 0;

		for (auto& s : kv.second)
		{	

			switch (s.type)
			{
				case StatementType::PSEUDO_OP_WITH_EXPRESSION:
				{
					switch (s.pseudoOp)
					{
						case PseudoOp::FUNCTION:		

							if (s.expression.isString())
							{
								cur_func = s.expression.getString();
								func_start = sec_address;			
							}
							else
							{
								std::stringstream ss;
								ss << ".FUNCTION takes a single string, name of function, as a parameter " << s.lineNum << std::endl;	
								throw std::runtime_error(ss.str());
							}
							break;
						default:
							break;
					}
				}
				break;
				case StatementType::PSEUDO_OP:
				{	
					switch (s.pseudoOp)
					{
						case PseudoOp::ENDFUNC:
						{	uint32_t size = sec_address - func_start;
						
							try {
								Symbol& sym = m_symbolTable.symtab.at(cur_func);
								sym.size = size;
								sym.e_type = STT_FUNC;
							} 
							catch (...)
							{
								std::stringstream ss;
								ss << ".ENDFUNC without a function on line " << s.lineNum << std::endl;	
								throw std::runtime_error(ss.str());
							}

							break;
						}
						default:
							break;
					}
				}
				break;	
				default:
					break;
			}
	
			sec_address += s.assembledBytes.size();

		}
	}

}

