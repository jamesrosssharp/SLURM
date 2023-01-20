
#pragma once

#include <string>
#include "ExpressionNode.h"

#include <map>

enum SymbolType {
	SYMBOL_LABEL,
	SYMBOL_CONSTANT
};

struct Symbol {

	enum SymbolType type;

	std::string name;

	bool evaluated;

	int value;

	// Defined in?
	
	// Referred by?	
};


class SymbolTable {

	public:

		void print();

	private:

		std::map<std::string, Symbol> m_symtab;
};

