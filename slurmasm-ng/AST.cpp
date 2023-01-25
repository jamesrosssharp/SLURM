
#include "AST.h"
#include <exception>
#include <stdexcept>
#include <map>

#include "Relocation.h"

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

OpCode AST::convertOpCode(char* opcode)
{
	std::string s(opcode);

	for (auto & c: s)
		c = toupper(c);

	return OpCode_convertOpCode(s);

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

std::ostream& operator << (std::ostream& os, const Statement& s)
{

	os << "Statement line " << s.lineNum << " : ";
	
	switch(s.type)
	{
		case StatementType::ONE_REGISTER_OPCODE_AND_EXPRESSION:
		{
			os << s.opcode << " " << s.regDest << "," << s.expression;
		
	}
		break;
		//case StatementType::TWO_REGISTER_OPCODE:
		//	os << s.opcode << " " << s.regDest << " " << s.regSrc << std::endl;
		//break;
		//case StatementType::THREE_REGISTER_OPCODE:
		//	os << s.opcode << " " << s.regDest << " " << s.regSrc2 << " " << s.regSrc << std::endl;
		//break;
		//case StatementType::INDIRECT_ADDRESSING_OPCODE:
		//	os << s.opcode << " " << s.regDest << " " << s.regInd << " " << s.regOffset << std::endl;
		//break;
		//case StatementType::INDIRECT_ADDRESSING_OPCODE_WITH_EXPRESSION:
		//	os << s.opcode << " " << s.regDest << " " << s.regInd << " " << s.expression << std::endl;
		//break;
		case StatementType::OPCODE_WITH_EXPRESSION:
			os << s.opcode << " " << s.expression;
		break;
		//case StatementType::PSEUDO_OP_WITH_EXPRESSION:
		//	os << s.pseudoOp << " " << s.expression << std::endl;
		//break;
		//case StatementType::STANDALONE_OPCODE:
		//	os << s.opcode << std::endl;
		//break;
		case StatementType::LABEL:
			os << s.label << ":";
		break;
		//case StatementType::TIMES:
		//	os << "times" << " " << s.expression << " ";
		//break;
		case StatementType::EQU:
			os << "EQU" << " " << s.label << " " << s.expression;
		break;
	}

	os << "\t";

	for (const auto b : s.assembledBytes)
		os << std::hex << std::setfill('0') << std::setw(2) << (int)b << " ";

	os << std::endl;

	return os;
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
				m_symbolTable.addSymbol(s);
			}
			else if (s.type == StatementType::EQU)
			{
				m_symbolTable.addConstant(s);
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
					s.expression.reduce_to_label_plus_const(m_symbolTable.symtab);
					break;	
			}	
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
