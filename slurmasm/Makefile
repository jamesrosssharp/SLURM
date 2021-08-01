
all: slurmasm

slurmasm:	slurmasm.tab.c lex.yy.c AST.cpp AST.h Expression.h Expression.cpp Statement.cpp Statement.h Symbol.h types.h Assembly.h Assembly.cpp
	g++ slurmasm.tab.c lex.yy.c AST.cpp Expression.cpp Statement.cpp Assembly.cpp -std=c++11 -lfl -I../common -o slurmasm

slurmasm.tab.c: slurmasm.y
	bison -d slurmasm.y

lex.yy.c: slurmasm.lex
	flex slurmasm.lex

install: slurmasm
	cp slurmasm ../bin

clean:
	rm lex.yy.c slurmastm.tab.c slurmasm
