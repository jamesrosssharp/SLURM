
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

	void addSymbol(Statement& stat, const std::string& section); 
	void addConstant(Statement& stat, const std::string& section); 
	void reduce(); 

private:
	void _addSymbol(Statement& stat, SymbolType symtype, const std::string& section); 

};

std::ostream& operator << (std::ostream& os, const SymbolTable& s);
std::ostream& operator << (std::ostream& os, const Symbol& s);
