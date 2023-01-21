
#pragma once

#include <string>
#include "ExpressionNode.h"
#include <map>

#include "Statement.h"

#include <vector>

#include "SymTab_t.h"

struct SymbolTable {

	SymTab_t symtab;
	std::vector<Symbol*> symlist;

	void addSymbol(Statement& stat); 
	void addConstant(Statement& stat); 
	void reduce(); 

private:
	void _addSymbol(Statement& stat, SymbolType symtype); 

};

std::ostream& operator << (std::ostream& os, const SymbolTable& s);
std::ostream& operator << (std::ostream& os, const Symbol& s);
