
#pragma once

#include <vector>
#include <string>

#include <host/ELF/ElfFile.h>

enum SymbolType {
	SYMBOL_LABEL,
	SYMBOL_CONSTANT
};

class Statement;


struct Symbol {

	enum SymbolType type;

	std::string name = "UNDEF";

	/* symbol has been evaluated to a constant and value is the correct constant */
	bool evaluated = false;

	/* symbol has been evaluated to a constant or reduced to a label + constant */
	bool reduced = false;

	int value = 0;

	int size = 0;

	int8_t e_bind = STB_LOCAL;
	int8_t e_type = STT_OBJECT;

	// Defined in?
	Statement* definedIn = nullptr;

	// Referred by?	
	std::vector<Statement*> referredBy;

	std::string section;
};


