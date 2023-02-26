
#include "ElfFile.h"

#include <iostream>
#include <iomanip>
#include <cstring>

#include <cstdio>

#include <algorithm>

#include <sstream>

static int g_id = 0;

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

static bool validate_elf_header(elf_header32* e)
{
	// Check ident:
	// 	Check magic

	if (e->ident.magic[0] != 0x7f) return false;
	if (e->ident.magic[1] != 'E') return false;
	if (e->ident.magic[2] != 'L') return false;
	if (e->ident.magic[3] != 'F') return false;

	// 	Check rest of ident 
	if (e->ident.e_class != ELF_CLASS_32_BIT) return false;
        if (e->ident.data    != ELF_DATA_LE) return false;
        if (e->ident.version != EV_CURRENT) return false;
	
	// Check rest of header
	
        if (e->e_machine != EM_SLURM) return false;


	return true;
}

/*==================== ELF Section =======================================*/

ElfSection::~ElfSection()
{
	if (data != nullptr)
	{
		delete [] data;
		data = nullptr;
	}
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

void ElfFile::addSection(const std::string& name, const std::vector<uint8_t>& contents, uint32_t loadAddr)
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

	s.address = loadAddr;

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
	else if (name == ".bss" || name == ".stack")
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
		s.link = m_sections.size() - 1;
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

	m_sections.push_back(std::move(s));

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
	// 0th symbol is a dummy symbol

	ElfSymbol e;
	e.name = "";
	e.section = "";
	e.info = 0;
	e.other = 0;
	e.value = 0;
	m_symbols.push_back(e);	
}

void ElfFile::addSymbol(const std::string& sym_name, const std::string& sym_section, int value, uint8_t bind, uint8_t type, int size)
{
 	// Add symbol
 	
	ElfSymbol e;

	e.name = sym_name;
	e.section = sym_section;

	e.info = 0;
	e.set_info(bind, type);

	e.other = 0;

	e.value = value;

	e.size = size;

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
	// Sort symbol table - locals first

	std::sort(m_symbols.begin(), m_symbols.end(), [] (const ElfSymbol& e1, const ElfSymbol& e2) { 
			if (e1.is_local() && !e2.is_local()) return true;
			if (!e1.is_local() && e2.is_local()) return false;
			else return false; 
			});	
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

	int local_count = 0;
	
	for (auto& sym : m_symbols)
	{
		elf_sym32 esym;

		if (sym.is_local()) local_count ++;

		// TODO: We need a map

		if (sym.section == "ABS")
			sym.shndx = SHN_ABS;	
		else
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

	m_sections.back().info = local_count;
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
		
void ElfFile::writeOutput(const char* filename)
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

		if (sec.size && (sec.type != SHT_NOBITS))
		{
			if (fwrite(sec.data, sec.size, 1, outf) != 1)
			{
				throw std::runtime_error("Error writing section!");
			}
	
			off += sec.size;
		}		

	}

	// Write out section headers

	fseek(outf, sh_off, SEEK_SET);
	
	for (auto& sec : m_sections)
		write_elf_section_header(sec, outf);

	fclose(outf);
}

void ElfFile::loadSection(FILE* fil, uint32_t offset)
{
	// Load section header

	elf_sh32 s;

	fseek(fil, offset, SEEK_SET);

	if (fread(&s, sizeof(elf_sh32), 1, fil) != 1)
	{
		throw std::runtime_error("Error reading ELF section header!");
	}

	ElfSection ss;
	
	ss.name_offset 	= s.sh_name;
	ss.offset 	= s.sh_offset;
	ss.address 	= s.sh_addr;
	ss.type 	= s.sh_type;
	ss.flags 	= s.sh_flags;
	ss.info 	= s.sh_info;
	ss.link 	= s.sh_link;
	ss.align 	= s.sh_addralign;
	ss.entsize 	= s.sh_entsize;
	ss.size 	= s.sh_size;

	// Load section data

	//	Sanity check section size
	if (ss.size > 65536)
	{
		throw std::runtime_error("Section unusually large for a SLURM elf : corrupt file?");
	}

	if (ss.size != 0 )
	{

		fseek(fil, ss.offset, SEEK_SET);

		ss.data = new uint8_t[s.sh_size];
		memset(ss.data, 0, s.sh_size);

		if (ss.type != SHT_NOBITS)
		{
			if (fread(ss.data, 1, ss.size, fil) != ss.size)
			{
				std::cout << ss.type << std::endl;
				throw std::runtime_error("Error reading section data!");
			}
		}
	}

	// Add section

	m_sections.push_back(std::move(ss));
}

void ElfFile::createSymbolTableFromSection(int sec_idx)
{

	ElfSection *sym_sec = &m_sections[sec_idx];

	if (sym_sec->entsize != sizeof(elf_sym32))
	{
		std::cout << sym_sec->entsize << std::endl;
		throw std::runtime_error("Symbol table entry size not standard: corrupt file?");
	}

	if (sym_sec->link > m_sections.size())
		throw std::runtime_error("String table index is out of bounds: corrupt file?");

	ElfSection *str_tab = &m_sections[sym_sec->link];

	if (str_tab->type != SHT_STRTAB)
		throw std::runtime_error("String table index does not point to string table: corrupt file?");

 	uint32_t offset = 0;

	while (offset < sym_sec->size)
	{
		elf_sym32* esym = (elf_sym32*)&sym_sec->data[offset];

		ElfSymbol e;

		e.name_offset = esym->st_name;
		e.info = esym->st_info;
        	e.other = esym->st_other;
        	e.shndx = esym->st_shndx;
        	e.value = esym->st_value;
        	e.size = esym->st_size;

		// Get string from string table
		e.name = getStringFromStrTab(str_tab, e.name_offset);
	
		// Fill in section name
		if (e.shndx < m_sections.size())
			e.section = m_sections.at(e.shndx).name;
		else if (e.shndx == SHN_ABS)
			e.section = "ABS"; 

		m_symbols.push_back(e);

		offset += sizeof(elf_sym32);
	}


}

void ElfFile::createRelocationTableFromSection(int sec_idx)
{

	ElfSection *rela_sec = &m_sections[sec_idx];
	ElfSection *relocated_sec = &m_sections.at(rela_sec->info);
	// We don't care about accessing symbol table, as we have made sure there is only 1 symbol table.

	if (rela_sec->entsize != sizeof(elf_rela32))
	{
		throw std::runtime_error("Relocation table entry size not standard: corrupt file?");
	}

	uint32_t offset = 0;
	
	while (offset < rela_sec->size)
	{
		elf_rela32* rela = (elf_rela32*)&rela_sec->data[offset]; 

		ElfRelocation e;

		e.offset = rela->offset;
		e.info 	 = rela->info;
		e.addend = rela->addend;

		relocated_sec->relocation_table.push_back(e);

		offset += sizeof(elf_rela32);
	}

}


std::string ElfFile::getStringFromStrTab(const ElfSection* strtab, uint32_t name_offset)
{
	// Security: don't trust offsets in file
	uint32_t off = name_offset;
	while (off < strtab->size && strtab->data[off++] != 0);
	if (off > strtab->size)
	{
		throw std::runtime_error("Error: bad string index: corrupt file?");
	}
	return std::string((char*)&strtab->data[name_offset]);
} 

void ElfFile::load(const char* filename)
{

	FILE* inf = fopen(filename, "rb");

	if (inf == NULL)
	{
		throw std::runtime_error("Error opening file!");
	}	

	m_fname = filename;

	std::stringstream uniq;

	uniq << "f" << g_id++;
	
	m_uniqueId = uniq.str();

	elf_header32 e;

	if (fread(&e, sizeof(elf_header32), 1, inf) != 1)
	{
		throw std::runtime_error("Error reading ELF header!");
	}

	if (! validate_elf_header(&e))
	{
		throw std::runtime_error("File is not a SLURM16 Elf file!");
	}

	// Load section sections
	
	if (e.e_shentsize != sizeof(elf_sh32))
	{
		throw std::runtime_error("File does not have the expected section header size!");
	}

	// Sanity check number of sections ... slurm objects would never have more than 100
	
	if (e.e_shnum > 100)
	{
		throw std::runtime_error("Object file has more than 100 sections... corrupt file?");
	} 

	uint32_t offset = e.e_shoff;

	// We created a dummy section in the constructor... delete it
	m_sections.clear();

	for (int i = 0; i < e.e_shnum; i++)
	{
		loadSection(inf, offset);
		offset += sizeof(elf_sh32);		
	}

	// Fill in section names

	int shstrtab_idx = e.e_shstrndx;

	if (shstrtab_idx < 0 || shstrtab_idx >= e.e_shnum)
		throw std::runtime_error("String table index out of range!");

	ElfSection* strtab = &m_sections[shstrtab_idx];

	for (auto& sec : m_sections)
	{

		sec.name = getStringFromStrTab(strtab, sec.name_offset); 
	}

	// Create symbol table

	bool symtab_found = false;
	int  symtab_idx;
	int  i = 0;

	for (auto& sec : m_sections)
	{
		if (sec.type == SHT_SYMTAB)
		{
			if (symtab_found)
				throw std::runtime_error("Error: multiple symbol tables");

			symtab_found = true;
			symtab_idx = i;	
		}

		i++;
	}

	if (! symtab_found)
		throw std::runtime_error("Error: file has no symbol table : corrupt file?");

	createSymbolTableFromSection(symtab_idx);

	// Create relocation table
	
	i = 0;	

	for (auto& sec : m_sections)
	{
		if (sec.type == SHT_RELA)
		{
			createRelocationTableFromSection(i);
		}
		i++;
	}
}

void ElfFile::iterateOverProgbitsSections(progbitsIter_cb section_cb, void* user_data)
{
	for (auto& sec : m_sections)
	{
		if (sec.type == SHT_PROGBITS)
		{
			section_cb(&sec, user_data);
		}
	}
}

ElfSymbol* ElfFile::findSymbolBySectionAndAddress(const std::string& name, uint32_t offset)
{

	for (auto& sym : m_symbols)
	{
		if (sym.section == name && sym.value == offset)
			return &sym;
	}

	return nullptr;

}

ElfRelocation* ElfSection::findRelocationAtAddress(uint32_t offset)
{
	for (auto& rela : relocation_table)
	{
		if (rela.offset == offset) return &rela;
	}
	return nullptr;
}

void ElfFile::printRelocation(ElfRelocation* rela)
{
	int sym_idx = rela->getSymbolIndex();

	ElfSymbol& esym = m_symbols.at(sym_idx);

	std::cout << "<" << esym.name << " + " << rela->addend << ">";

}

bool ElfSection::isExecutableSection()
{
	return flags & SHF_EXECINSTR;
}
