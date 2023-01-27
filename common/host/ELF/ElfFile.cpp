
#include "ElfFile.h"

#include <iostream>
#include <iomanip>
#include <cstring>

#include <cstdio>

/*====================== Static elf structure helpers =====================*/

static void fill_elf_ident(elf_ident* i)
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

static void fill_elf_header(elf_header32* h, int shnum)
{
	fill_elf_ident(&h->ident);

	h->e_type = ET_REL;
        h->e_machine = EM_SLURM;
        h->e_version = EV_CURRENT;
        h->e_entry = 0;
        h->e_phoff = 0;
        h->e_shoff = sizeof(elf_header32);	/* section headers offset just after this header */

        h->e_flags = 0;
        h->e_ehsize = 0;
        h->e_phentsize = 0;
        h->e_phnum = 0;
        h->e_shentsize = sizeof(elf_sh32);
        h->e_shnum = shnum;
        h->e_shstrndx = shnum - 1;

}

static void write_elf_section_header(const ElfSection& sec, FILE* outf)
{
	elf_sh32 e;

        e.sh_name = sec.name_offset;
        e.sh_type = sec.type;
        e.sh_flags = sec.flags;
        e.sh_addr = sec.address;
        e.sh_offset = sec.offset;
        e.sh_size = sec.size;
        e.sh_link = sec.link;
        e.sh_info = sec.info;
        e.sh_addralign = sec.align;
        e.sh_entsize = sec.entsize;

	if (fwrite(&e, sizeof(elf_sh32), 1, outf) != 1)
	{
		throw std::runtime_error("Error writing ELF section header!");
	}
}

static void fill_elf_sym(elf_sym32* esym, const ElfSymbol& sym)
{
	esym->st_name = sym.name_offset;
        esym->st_info = sym.info;
        esym->st_other = sym.other;
        esym->st_shndx = sym.shndx;
        esym->st_value = sym.value;
        esym->st_size = sym.size;
}

static void fill_elf_rela(elf_rela32* erela, const ElfRelocation& rela)
{
	erela->offset = rela.offset;
	erela->info = rela.info;
	erela->addend = rela.addend;
}



/*==================== ELF Section =======================================*/

ElfSection::~ElfSection()
{
	//if (data != nullptr)
	//	delete [] data;
	//data = nullptr;
}

/*==================== ELF File class =====================================*/

ElfFile::ElfFile()
{

	// Create the first, dummy section.
	
	addSection("", {});		

}

ElfFile::~ElfFile()
{

}

void ElfFile::addSection(const std::string& name, const std::vector<uint8_t>& contents)
{

#if 0
	std::cout << "Adding section: " << name << std::endl;

	for (const auto& a : contents)
		std::cout << std::hex << std::setw(2) << std::setfill('0') << (int) a << " ";

	std::cout << std::endl;
#endif

	ElfSection s;

	s.name = name;
	
	s.data = new uint8_t [contents.size()];

	memcpy(s.data, contents.data(), contents.size());

	s.size = contents.size(); 

	if (name == "")
	{
		s.type = SHT_NULL;
		s.flags = 0;
		s.info = 0;
		s.link = 0;
		s.align = 0;
	}
	else if (name == ".data")
	{
		s.type = SHT_PROGBITS;
		s.flags = SHF_WRITE;
		s.info = 0;
		s.link = 0;
		s.align = 2;
	}
	else if (name == ".bss")
	{
		s.type = SHT_NOBITS;
		s.flags = SHF_WRITE;
		s.info = 0;
		s.link = 0;
		s.align = 2;
	}
	else if (name == ".shstrtab" || name == ".strtab")
	{
		s.type = SHT_STRTAB;
		s.flags = 0;
		s.info = 0;
		s.link = 0;
		s.align = 0;
	}
	else if (name == ".symtab")
	{
		s.type = SHT_SYMTAB;
		s.flags = 0;
		s.info = 0;
		s.link = m_symbols.size() - 1;
		s.align = 0;
		s.entsize = sizeof(elf_sym32);
	}
	else if (name.substr(0,5) == ".rela")
	{
		s.type = SHT_RELA;
		s.flags = 0;
		s.info = 0;
		s.link = 0;
		s.align = 0;
		s.entsize = sizeof(elf_rela32);
	}
	else 
	{
		/* we assume, some kind of text section */
		s.type = SHT_PROGBITS;
		s.flags = SHF_EXECINSTR;
		s.info = 0;
		s.link = 0;
		s.align = 2;
	}

	m_sections.push_back(s);

}

void ElfFile::buildSectionHeaderStringTable()
{

	std::vector<uint8_t> data;

	uint32_t off = 0;
	for (auto& sec : m_sections)
	{
		sec.name_offset = off;

		for (const auto c : sec.name)
		{
			data.push_back(c);
			off++;
		}
		data.push_back(0);	
		off++;
	} 

	std::string n = ".shstrtab";

	for (const auto c : n)
	{
		data.push_back(c);
	}
	data.push_back(0);	
	

	addSection(n, data);

	m_sections.back().name_offset = off;

}

void ElfFile::beginSymbolTable()
{
	// Do nothing
}

void ElfFile::addSymbol(const std::string& sym_name, const std::string& sym_section, int value)
{
 	// Add symbol
 	
	ElfSymbol e;

	e.name = sym_name;
	e.section = sym_section;

	// TODO: Fix this
	e.info = 0;
	e.other = 0;

	e.value = value;

	m_symbols.push_back(e);	


}


int ElfFile::findSectionIdxByName(const std::string& name)
{
	int i = 0;
	for (const auto& sec : m_sections)
	{
		if (sec.name == name)
			return i;

		i++;
	}

	return 0;
}

void ElfFile::finaliseSymbolTable()
{
	// Build strtab
	
	std::vector<uint8_t> str_data;

	uint32_t off = 0;
	for (auto& sym : m_symbols)
	{
		sym.name_offset = off;

		for (const auto c : sym.name)
		{
			str_data.push_back(c);
			off++;
		}
		str_data.push_back(0);	
		off++;
	} 

	std::string strn = ".strtab";

	// Add strtab
	
	addSection(strn, str_data);

	// Build symtab
	
	std::vector<uint8_t> sym_data;

	for (auto& sym : m_symbols)
	{
		elf_sym32 esym;

		// TODO: We need a map
		sym.shndx = findSectionIdxByName(sym.section);

		fill_elf_sym(&esym, sym);

		uint8_t* ptr = (uint8_t*)&esym;

		for (int i = 0; i < sizeof(elf_sym32); i++)
		{
			sym_data.push_back(*ptr++);
		}		
	} 

	std::string symn = ".symtab";
	
	// Add symtab

	addSection(symn, sym_data);
}

void ElfFile::beginRelocationTable(const std::string& sec)
{
	m_relocations.clear();

	m_curRela_shndx = findSectionIdxByName(sec);
	m_curRela_secname = ".rela" + sec;

}

int ElfFile::findSymbolIdxByName(const std::string& name)
{
	int i = 0;
	for (const auto& sec : m_symbols)
	{
		if (sec.name == name)
			return i;

		i++;
	}

	return 0;
}



void ElfFile::addRelocation(const std::string& name, int32_t addend, uint32_t address)
{
	ElfRelocation e;

	e.offset = address;
	e.info   = findSymbolIdxByName(name) << 8 | 1; /* 1 = R_386_32 TODO: SLURM relocation types... */
	e.addend = addend;

	m_relocations.push_back(e);
}

void ElfFile::finaliseRelocationTable()
{
	std::vector<uint8_t> rela_data;

	for (auto& rela : m_relocations)
	{
		elf_rela32 erela;

		fill_elf_rela(&erela, rela);

		uint8_t* ptr = (uint8_t*)&erela;

		for (int i = 0; i < sizeof(elf_rela32); i++)
		{
			rela_data.push_back(*ptr++);
		}		
	} 

	// Add rel. tab

	addSection(m_curRela_secname, rela_data);

	m_sections.back().link = findSectionIdxByName(".symtab"); 
	m_sections.back().info = m_curRela_shndx;

}
		
void ElfFile::writeOutput(char* filename)
{

	// Build section header string table
	buildSectionHeaderStringTable();

	FILE* outf = fopen(filename, "wb");
	if (outf == NULL)
		throw std::runtime_error("Could not open file for writing!");	

	elf_header32 h;

	fill_elf_header(&h, m_sections.size());

	if (fwrite(&h, sizeof(h), 1, outf) != 1)
		throw std::runtime_error("Error writing ELF header!");
	
	// Leave space for section headers

	uint32_t off = sizeof(elf_header32);
	uint32_t sh_off = off;

	off += m_sections.size() * sizeof(elf_sh32);

	fseek(outf, off, SEEK_SET);

	// Write sections

	for (auto& sec : m_sections)
	{
		sec.offset = off;

		if (sec.size)
		{
			if (fwrite(sec.data, sec.size, 1, outf) != 1)
			{
				throw std::runtime_error("Error writing section!");
			}
		}		

		off += sec.size;
	}

	// Write out section headers

	fseek(outf, sh_off, SEEK_SET);
	
	for (auto& sec : m_sections)
		write_elf_section_header(sec, outf);


	fclose(outf);
}

