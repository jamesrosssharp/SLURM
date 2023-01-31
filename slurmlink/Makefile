
all: slurmlink

SRC	=	slurmlink.tab.c	\
		lex.yy.c	\
		AST.cpp

slurmlink: $(SRC)
	g++ $(SRC) -o slurmlink

 
slurmlink.tab.c: slurmlink.y
	bison -d slurmlink.y

lex.yy.c: slurmlink.lex
	flex slurmlink.lex


