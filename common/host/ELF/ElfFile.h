
#pragma once

#include <string>
#include <vector>

/*========================== Elf Structures ===================================*/

#define ELF_CLASS_32_BIT 1
#define ELF_CLASS_64_BIT 2

#define ELF_DATA_LE 1
#define ELF_DATA_BE 2

#define EV_CURRENT 1

struct elf_ident {
        char magic[4];
        char e_class;
        char data;
        char version;
        char osabi;
        char abi_version;
        char pad[7];
} __attribute__ ((packed));

class ElfFile {

	public:

		ElfFile();
		~ElfFile();

		void addSection(const std::string& name, const std::vector<uint8_t>& contents);

		void writeOutput(char* filename);

	private:

};

