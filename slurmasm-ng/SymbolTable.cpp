
#include "SymbolTable.h"

#include <sstream>

void SymbolTable::_addSymbol(Statement& stat, SymbolType symtype)
{
	Symbol sym;
	sym.definedIn = &stat;
	sym.name = stat.label;
	sym.value = 0;
	sym.evaluated = false;
	sym.type = symtype;

	bool found = true;

	// check to see if symbol already exists?
	try
	{
		symtab.at(stat.label);
	}
	catch (...)
	{
		found = false;
	}

	if (found)
	{
		std::stringstream ss;
		ss << "Symbol '" << stat.label << "' redefined on line " << stat.lineNum << std::endl;
		throw std::runtime_error(ss.str());
	}

	symtab.emplace(stat.label, sym);
	symlist.push_back(&symtab.at(stat.label));

}

void SymbolTable::addSymbol(Statement& stat)
{
	_addSymbol(stat, SymbolType::SYMBOL_LABEL);
}

void SymbolTable::addConstant(Statement& stat)
{
	_addSymbol(stat, SymbolType::SYMBOL_CONSTANT);
}

void SymbolTable::reduce()
{

	// Try simple evaluations
	for (const auto& sym : symlist)
	{
		Statement* stat = sym->definedIn;	

		if (stat->type == StatementType::EQU)
		{
			sym->reduced = sym->evaluated = stat->expression.evaluate(symtab, sym->value);

			if (! sym->reduced)
			{
				// Try to reduce to a single label type symbol plus a constant
			}
		} 

	}

	// Check that all symbols have been reduced


}

std::ostream& operator << (std::ostream& os, const Symbol& s)
{
	os << s.name << " eval=" << s.evaluated << " val=" << s.value;

	return os;
}

std::ostream& operator << (std::ostream& os, const SymbolTable& s)
{
	os << "Symbol table: " << std::endl;

	for (const auto& sym : s.symlist)
		os << "\t" << *sym << std::endl; 

	return os;
}
