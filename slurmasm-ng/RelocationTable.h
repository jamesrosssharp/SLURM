
#pragma once

#include "Relocation.h"

#include <map>
#include <string>
#include <vector>
#include <ostream>

using RelocationTable = std::map<std::string, std::vector<Relocation>>;

std::ostream& operator << (std::ostream& os, const RelocationTable& r);
