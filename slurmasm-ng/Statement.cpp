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
	}
}

void Statement::_assemble_opcode_and_expression(int expressionValue)
{
	switch (opcode)
	{
		case OpCode::BA:
			Assembly::assembleBranch(lineNum, opcode, Register::r0, expressionValue, assembledBytes);
			break;
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
	}


}

void Statement::reset()
{
	lineNum = 0;

	expression.reset();

	type = StatementType::None;

	label = nullptr;

	assembledBytes.clear();

	timesStatement = nullptr;
	repetitionCount = 1;
}

