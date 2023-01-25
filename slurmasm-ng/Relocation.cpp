
#include "Relocation.h"
#include <ostream>

std::ostream& operator << (std::ostream& os, const Relocation& r)
{
	os << r.sym->name << " + ";
	os << r.offset << " @ ";

	os << std::dec <<  r.address << " ";

	return os;
}
