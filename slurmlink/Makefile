
all: slurmlink

SRC	=	slurmlink.tab.c	\
		lex.yy.c	\
		AST.cpp		\
		Expression.cpp	\
		MemoryStatement.cpp	\
		Assignment.cpp

HEADERS = 	AST.h			\
		Expression.h		\
		ExpressionNode.h	\
		MemoryStatement.h	\
		Assignment.h		\
		SectionBlockStatementSectionList.h	\
		SectionBlockStatement.h


slurmlink: $(SRC) $(HEADERS)
	g++ $(SRC) -o slurmlink

 
slurmlink.tab.c: slurmlink.y
	bison -d slurmlink.y

lex.yy.c: slurmlink.lex
	flex slurmlink.lex


