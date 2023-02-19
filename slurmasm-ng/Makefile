
all: slurmasm-ng

SRC = 	slurmasm-ng.tab.c \
      	lex.yy.c \
      	AST.cpp \
	SymbolTable.cpp	\
	Statement.cpp	\
	Expression.cpp	\
	OpCode.cpp	\
	Assembly.cpp	\
	Relocation.cpp	\
	RelocationTable.cpp	\
	../common/host/ELF/ElfFile.cpp	\
	Cond.cpp
      
INCLUDE =	AST.h	\
	  	ExpressionNode.h \
		SymbolTable.h	\
		Statement.h	\
		Expression.h	\
		types.h		\
		OpCode.h	\
		Assembly.h	\
		Relocation.h	\
		SymTab_t.h	\
		RelocationTable.h \
		../common/host/ELF/ElfFile.h	\
		Cond.h


slurmasm-ng:	$(SRC) $(INCLUDE)
	g++ $(SRC) -std=c++11 -lfl -I../common -o slurmasm-ng

slurmasm-ng.tab.c: slurmasm-ng.y
	bison -d slurmasm-ng.y

lex.yy.c: slurmasm-ng.lex
	flex slurmasm-ng.lex

install: slurmasm-ng
	cp slurmasm-ng ../bin

clean:
	rm lex.yy.c slurmasm-ng.tab.c slurmasm-ng *.o *.out
