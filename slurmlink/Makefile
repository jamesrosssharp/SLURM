
all: slurmlink

SRC	=	slurmlink.tab.c	\
		lex.yy.c	\
		AST.cpp		\
		Expression.cpp	\
		MemoryStatement.cpp	\
		Assignment.cpp		\
		SectionsStatement.cpp	\
		SectionBlockStatement.cpp	\
		SectionBlockStatementSectionList.cpp	\
		Linker.cpp				\
		../common/host/ELF/ElfFile.cpp	

HEADERS = 	AST.h			\
		Expression.h		\
		ExpressionNode.h	\
		MemoryStatement.h	\
		Assignment.h		\
		SectionBlockStatementSectionList.h	\
		SectionBlockStatement.h			\
		SectionsStatement.h			\
		Linker.h				\
		../common/host/ELF/ElfFile.h		\
		LinkerSection.h				\
		LinkerSymbol.h				\
		LinkerSymtab.h				\
		LinkerRelocation.h

slurmlink: $(SRC) $(HEADERS)
	g++ $(SRC) -o slurmlink -I../common 

 
slurmlink.tab.c: slurmlink.y
	bison -d slurmlink.y

lex.yy.c: slurmlink.lex
	flex slurmlink.lex


