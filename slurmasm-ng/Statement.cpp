#include "Statement.h"

#include "ExpressionNode.h"
#include "AST.h"

#include "OpCode.h"
#include "Assembly.h"

#include <string.h>
#include <sstream>
#include <iostream>

void Statement::_assemble_one_reg_opcode_and_expression(int expressionValue)
{
	switch (opcode)
	{
		case OpCode::MOV:
		case OpCode::ADD:
			Assembly::assembleRegisterImmediateALUOp(lineNum, opcode, regDest, expressionValue, assembledBytes);
			break;
		default: {
			std::stringstream ss;
			ss << "Unsupported opcode for one reg with expression on line " << lineNum << std::endl;	
			throw std::runtime_error(ss.str());
		}

	}
}

void Statement::_assemble_opcode_and_expression(int expressionValue)
{
	switch (opcode)
	{
		case OpCode::BA:
		case OpCode::BL:
			Assembly::assembleBranch(lineNum, opcode, Register::r0, expressionValue, assembledBytes);
			break;
		default: {
			std::stringstream ss;
			ss << "Unsupported opcode for opcode with expression on line " << lineNum << std::endl;	
			throw std::runtime_error(ss.str());
		}

	}
}

void Statement::_assemble_standalone_opcode()
{
	switch (opcode)
	{
		case OpCode::RET:
		case OpCode::IRET:
			Assembly::assembleRetIRet(lineNum, opcode, assembledBytes);
			break;
		default: {
			std::stringstream ss;
			ss << "Unsupported standalone opcode on line " << lineNum << std::endl;	
			throw std::runtime_error(ss.str());
		}

	}
}

void Statement::_assemble_two_register_opcode()
{
	switch (opcode)
	{
		case OpCode::ADD:
			Assembly::assembleTwoRegisterALUOp(lineNum, opcode, regDest, regSrc, assembledBytes);
			break;
		default: {
			std::stringstream ss;
			ss << "Unsupported two register opcode on line " << lineNum << std::endl;	
			throw std::runtime_error(ss.str());
		}
	}
}

void Statement::_assemble_two_register_cond_opcode()
{
	switch (opcode)
	{
		case OpCode::MOV:
			Assembly::assembleCondMovOp(lineNum, cond, regDest, regSrc, assembledBytes);
			break;
		default: {
			std::stringstream ss;
			ss << "Unsupported two register conditional opcode on line " << lineNum << std::endl;	
			throw std::runtime_error(ss.str());
		}
	}
}

void Statement::_assemble_three_register_cond_opcode()
{
	switch (opcode)
	{
		case OpCode::ADD:
		case OpCode::MOV:
			Assembly::assembleCondAluOp(lineNum, opcode, cond, regDest, regSrc, regSrc2, assembledBytes);
			break;
		default: {
			std::stringstream ss;
			ss << "Unsupported three register conditional opcode on line " << lineNum << std::endl;	
			throw std::runtime_error(ss.str());
		}
	}
}

void Statement::assemble()
{

	switch (type)
	{
		case StatementType::ONE_REGISTER_OPCODE_AND_EXPRESSION:
			if (expression.is_const)
			{
				// Expression is a constant, we can assemble and forget			
				_assemble_one_reg_opcode_and_expression(expression.getValue());	
			}
			else if (expression.is_label_plus_const)
			{
				// Else expression is a relocation. Assemble with value 0 for 
				// expression
				_assemble_one_reg_opcode_and_expression(0);	
			}
			else {
				// Shouldn't get here so bug out
				throw std::runtime_error("Expression not reduced. Weird?");	
			}

			break;
		case StatementType::OPCODE_WITH_EXPRESSION:
			if (expression.is_const)
			{
				// Expression is a constant, we can assemble and forget			
				_assemble_opcode_and_expression(expression.getValue());	
			}
			else if (expression.is_label_plus_const)
			{
				// Else expression is a relocation. Assemble with value 0 for 
				// expression
				_assemble_opcode_and_expression(0);	
			}
			else {
				// Shouldn't get here so bug out
				throw std::runtime_error("Expression not reduced. Weird?");	
			}

			break;
		case StatementType::STANDALONE_OPCODE:
			_assemble_standalone_opcode();
			break;
		case StatementType::EQU:
		case StatementType::LABEL:
			// NO assembly for these statements
			break;
		case StatementType::TWO_REGISTER_OPCODE:
			_assemble_two_register_opcode();
			break;
		case StatementType::TWO_REGISTER_COND_OPCODE:
			_assemble_two_register_cond_opcode();
			break;
		case StatementType::THREE_REGISTER_COND_OPCODE:
			_assemble_three_register_cond_opcode();
			break;
		default: {
			std::stringstream ss;
			ss << "Unsupported statement type on line " << lineNum << std::endl;	
			throw std::runtime_error(ss.str());
		}
	}


}

void Statement::reset()
{
	lineNum = 0;

	expression.reset();

	cond = Cond::None;

	type = StatementType::None;

	label = nullptr;

	assembledBytes.clear();

	timesStatement = nullptr;
	repetitionCount = 1;
}


void Statement::annotateLabel(SymTab_t& symTab, std::string section, int address)
{

	std::string sym = label;

	symTab[sym].value = address;
	symTab[sym].evaluated = true;
	symTab[sym].reduced = true;
}

bool Statement::createRelocation(Relocation& rel, SymTab_t &symtab, std::string sec, int address)
{

	if (type == StatementType::EQU)
		return false;

	if (!expression.is_label_plus_const)
		return false;

	rel.sym = &symtab[expression.root->left->val.name];

	rel.offset = expression.root->right->val.value;
	rel.address = address;

	return true;
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
		case StatementType::TWO_REGISTER_OPCODE:
		{
			os << s.opcode << " " << s.regDest << "," << s.regSrc;
		}
		break;
		case StatementType::TWO_REGISTER_COND_OPCODE:
		{
			os << s.opcode << "." << s.cond << " " << s.regDest << "," << s.regSrc;
		}
		break;
		case StatementType::THREE_REGISTER_COND_OPCODE:
			os << s.opcode << "." << s.cond << " "  << s.regDest << "," << s.regSrc << "," << s.regSrc2;
		break;
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
		case StatementType::STANDALONE_OPCODE:
			os << s.opcode;
		break;
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
	os << std::dec;

	os << std::endl;

	return os;
}


