#include "Statement.h"

#include "ExpressionNode.h"
#include "AST.h"

#include <string.h>
#include <sstream>
#include <iostream>

void Statement::assemble()
{


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

