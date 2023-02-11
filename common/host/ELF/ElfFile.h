
#pragma once

#include <string>
#include <vector>
#include <cstdint>

#include <cstdio>
#include <cstdlib>

/*========================== Elf Structures ===================================*/

#define ELF_CLASS_32_BIT 1
#define ELF_CLASS_64_BIT 2

#define ELF_DATA_LE 1
#define ELF_DATA_BE 2

#define EV_CURRENT 1

#define ET_REL 1

#define EM_SLURM 0x4D53 // SM?

enum {
        SHT_NULL        = 0,
        SHT_PROGBITS    = 1,
        SHT_SYMTAB      = 2,
        SHT_STRTAB      = 3,
        SHT_RELA        = 4,
        SHT_HASH        = 5,
	SHT_DYNAMIC 	= 6,
	SHT_NOTE 	= 7,
	SHT_NOBITS 	= 8
};

enum {
	SHF_WRITE = 0x1,
	SHF_ALLOC = 0x2,
	SHF_EXECINSTR = 0x4
};

struct elf_ident {
        char magic[4];
        char e_class;
        char data;
        char version;
        char osabi;
        char abi_version;
        char pad[7];
} __attribute__ ((packed));

struct elf_header32 {
        elf_ident ident;
        uint16_t e_type;
        uint16_t e_machine;
        uint32_t e_version;
        uint32_t e_entry;
        uint32_t e_phoff;
        uint32_t e_shoff;

        uint32_t e_flags;
        uint16_t e_ehsize;
        uint16_t e_phentsize;
        uint16_t e_phnum;
        uint16_t e_shentsize;
        uint16_t e_shnum;
        uint16_t e_shstrndx;
} __attribute__ ((packed));

struct elf_sh32 {
        uint32_t sh_name;
        uint32_t sh_type;
        uint32_t sh_flags;
        uint32_t sh_addr;
        uint32_t sh_offset;
        uint32_t sh_size;
        uint32_t sh_link;
        uint32_t sh_info;
        uint32_t sh_addralign;
        uint32_t sh_entsize;
} __attribute__ ((packed));

struct elf_sym32 {
        uint32_t        st_name;
 	uint32_t        st_value;
        uint32_t        st_size;
	unsigned char   st_info;
        unsigned char   st_other;
        uint16_t        st_shndx;
} __attribute__ ((packed));

struct elf_rela32 {
	uint32_t offset;
	uint32_t info;
	int32_t addend;
} __attribute__ ((packed));

/*========================= ELF File class ===============================*/
struct ElfRelocation {
	uint32_t offset = 0;
	uint32_t info = 0;
	int32_t  addend = 0;

	// TODO: Accessor methods for obtaining symbol, etc.
};

struct ElfSection {

	// Move constructor to take hold of data (destructor will free data if not null)	
	ElfSection(ElfSection&& from)
	{
		name = std::move(from.name);
		name_offset = from.name_offset;
		offset = from.offset;
		address = from.address;
		type = from.type;
		flags = from.flags;
		info = from.info;
		link = from.link;
		align = from.align;
		entsize = from.entsize;
		data = from.data;
		from.data = nullptr;
		size = from.size;
		relocation_table = std::move(from.relocation_table);
	}

	ElfSection() {}

	std::string name;
	/* offset of name in string table */
	uint32_t name_offset = 0;

	/* file offset of section */
	uint32_t offset = 0;

	/* load address in memory of section */
	uint32_t address = 0;

	uint32_t type = 0;
	uint32_t flags = 0;
	uint32_t info = 0;
	uint32_t link = 0;
	/* section alignment */
	uint32_t align = 0;
	uint32_t entsize = 0;

	/* section data */
	uint8_t* data = nullptr;
	int size = 0;	// Size in bytes of section

	// We use move semantics to transfer data array to emplaced object in vector,
	// allowing destructor to free the memory
	~ElfSection();

	std::vector<ElfRelocation> relocation_table;

	ElfRelocation* findRelocationAtAddress(uint32_t offset);
	bool isExecutableSection();

};

struct ElfSymbol {

	std::string name;
	uint32_t name_offset = 0;

	std::string section;

	unsigned char   info = 0;
        unsigned char   other = 0;
        uint16_t        shndx = 0;
        uint32_t        value = 0;
        uint32_t        size = 0;
};

typedef void (*progbitsIter_cb)(ElfSection* e, void* user_data);

class ElfFile {

	public:

		ElfFile();
		~ElfFile();

		void addSection(const std::string& name, const std::vector<uint8_t>& contents);

		void writeOutput(char* filename);
		
		void beginSymbolTable();
		void addSymbol(const std::string& sym_name, const std::string& sym_section, int value);
		void finaliseSymbolTable();

		void beginRelocationTable(const std::string& sec);
		void addRelocation(const std::string& name, int32_t addend, uint32_t address);
		void finaliseRelocationTable();
	
		/* load an ELF file and create internal structures to be used in disassembly and linking */
		void load(const char* filename);

		/* iterate over all PROGBITS sections, and call callback */
		void iterateOverProgbitsSections(progbitsIter_cb section_cb, void* user_data);	

		ElfSymbol* findSymbolBySectionAndAddress(const std::string& name, uint32_t offset);

		void printRelocation(ElfRelocation* rela);

	private:

		int findSectionIdxByName(const std::string& name);
		int findSymbolIdxByName(const std::string& name);
		void buildSectionHeaderStringTable();

		void loadSection(FILE* fil, uint32_t offset);

		void createSymbolTableFromSection(int sec_idx);
		void createRelocationTableFromSection(int sec_idx);

		std::string getStringFromStrTab(const ElfSection* strtab, uint32_t name_offset); 

		std::vector<ElfSection> m_sections;
		std::vector<ElfSymbol> m_symbols;

		/* relocations for current section */
		std::vector<ElfRelocation> m_relocations;

		int m_curRela_shndx = 0;
		std::string m_curRela_secname;
};

