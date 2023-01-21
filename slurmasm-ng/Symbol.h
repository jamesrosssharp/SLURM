
#pragma once

#include <vector>

enum SymbolType {
	SYMBOL_LABEL,
	SYMBOL_CONSTANT
};

class Statement;


struct Symbol {

	enum SymbolType type;

	std::string name;

	bool evaluated;
	bool reduced;

	int value;

	// Defined in?
	Statement* definedIn;

	// Referred by?	
	std::vector<Statement*> referredBy;

};


