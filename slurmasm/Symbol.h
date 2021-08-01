#pragma once

#include <vector>
#include <map>
#include <string>

struct Statement;

struct Symbol
{
    char* string;
    int32_t value = 0;
	bool evaluated = false;

    std::vector<Statement*> referredBy;
    Statement* definedIn;
};

using SymbolTable = std::map<std::string, Symbol>;
