
all: slurmasm-ng

slurmasm-ng:	slurmasm-ng.tab.c lex.yy.c AST.cpp AST.h
	g++ slurmasm-ng.tab.c lex.yy.c AST.cpp -std=c++11 -lfl -I../common -o slurmasm-ng

slurmasm-ng.tab.c: slurmasm-ng.y
	bison -d slurmasm-ng.y

lex.yy.c: slurmasm-ng.lex
	flex slurmasm-ng.lex

install: slurmasm
	cp slurmasm-ng ../bin

clean:
	rm lex.yy.c slurmasm-ng.tab.c slurmasm-ng
