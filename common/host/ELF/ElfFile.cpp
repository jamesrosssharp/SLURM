
#include "ElfFile.h"

#include <iostream>
#include <iomanip>

#include <cstdio>

/*====================== Static elf structure helpers =====================*/

static void fill_elf_ident(struct elf_ident* i)
{
	i->magic[0] = 0x7f;
	i->magic[1] = 'E';
	i->magic[2] = 'L';
	i->magic[3] = 'F';

        i->e_class 	= ELF_CLASS_32_BIT;
        i->data 	= ELF_DATA_LE;
        i->version	= EV_CURRENT;
        i->osabi	= 0;
        i->abi_version  = 0;

	for (int j = 0; j < sizeof(i->pad); j++)
		i->pad[j] = 0;

}




/*==================== ELF File class =====================================*/

ElfFile::ElfFile()
{

}

ElfFile::~ElfFile()
{

}

void ElfFile::addSection(const std::string& name, const std::vector<uint8_t>& contents)
{

	std::cout << "Adding section: " << name << std::endl;

	for (const auto& a : contents)
		std::cout << std::hex << std::setw(2) << std::setfill('0') << (int) a << " ";

	std::cout << std::endl;

}

void ElfFile::writeOutput(char* filename)
{

	FILE* outf = fopen(filename, "wb");
	if (outf == NULL)
		throw std::runtime_error("Could not open file for writing!");	

	struct elf_ident i;

	fill_elf_ident(&i);

	if (fwrite(&i, sizeof(i), 1, outf) != 1)
		throw std::runtime_error("Error writing ident to ELF file!");
	


	fclose(outf);
}

