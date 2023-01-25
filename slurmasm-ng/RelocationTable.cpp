
#include "RelocationTable.h"


std::ostream& operator << (std::ostream& os, const RelocationTable& r)
{
	os << "Relocation table: " << std::endl;

	for (const auto& kv : r)
	{
		auto sec = kv.first;

		os << "\tSection " << sec << ":" << std::endl;

		for (const auto& rel : kv.second)
		{	
			os << "\t\t" << rel << std::endl;
		}

	}

	return os;
}
