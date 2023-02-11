
all: slurmlink

SRC	=	slurmlink.tab.c	\
		lex.yy.c	\
		AST.cpp		\
		Expression.cpp	\
		MemoryStatement.cpp

HEADERS = 	AST.h	\
		Expression.h	\
		MemoryStatement.h


slurmlink: $(SRC) $(HEADERS)
	g++ $(SRC) -o slurmlink

 
slurmlink.tab.c: slurmlink.y
	bison -d slurmlink.y

lex.yy.c: slurmlink.lex
	flex slurmlink.lex


