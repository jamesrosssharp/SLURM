
#include "SymbolTable.h"

#include <sstream>

void SymbolTable::_addSymbol(Statement& stat, SymbolType symtype, const std::string& section)
{
	Symbol sym;
	sym.definedIn = &stat;
	sym.name = stat.label;
	sym.value = 0;
	sym.evaluated = false;
	sym.type = symtype;
	sym.section = section;

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

void SymbolTable::addSymbol(Statement& stat, const std::string& section)
{
	_addSymbol(stat, SymbolType::SYMBOL_LABEL, section);
}

void SymbolTable::addConstant(Statement& stat, const std::string& section)
{
	_addSymbol(stat, SymbolType::SYMBOL_CONSTANT, section);
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
				sym->reduced = stat->expression.reduce_to_label_plus_const(symtab);

			}
		} 

	}

	// Check that all EQU symbols have been reduced

	for (const auto& sym : symlist)
	{
		if (sym->type == SymbolType::SYMBOL_CONSTANT && ! sym->reduced )
		{

			Statement* stat = sym->definedIn;	

			std::stringstream ss;
			ss << "Expression on line " << stat->lineNum << " could not be reduced to either a constant or a single label plus a constant. " << std::endl;

			throw std::runtime_error(ss.str());
	

		}
	}

}

std::ostream& operator << (std::ostream& os, const Symbol& s)
{
	os << s.name << " section=" << s.section << " eval=" << s.evaluated << " redu=" << s.reduced << " val=" << s.value;

	return os;
}

std::ostream& operator << (std::ostream& os, const SymbolTable& s)
{
	os << "Symbol table: " << std::endl;

	for (const auto& sym : s.symlist)
		if (sym->type == SymbolType::SYMBOL_LABEL)
			os << "\t" << *sym << std::endl; 

	return os;
}
