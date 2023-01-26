%{


#include <cstdio>
#include <iostream>
#include "AST.h"
#include <unistd.h>
#include <string.h>

  using namespace std;

  // stuff from flex that bison needs to know about:
  extern "C" int yylex();
  extern "C" int yyparse();
  extern "C" FILE *yyin;
  extern int line_num;

  AST g_ast;

  void yyerror(const char *s);

%}

// Bison fundamentally works by asking flex to get the next token, which it
// returns as an object of type "yystype".	But tokens could be of any
// arbitrary data type!  So we deal with that in Bison by defining a C union
// holding each of the types of tokens that Flex could return, and have Bison
// use that union instead of "int" for the definition of "yystype":
%union {
  int ival;
  unsigned int hval;
  char *sval;
  char *lsval;
  char *cval;
  char *regval;
  char *opcval;
  char *pseudoopval;
  char *sectionval;
  char *condval;
}
%define parse.error verbose

%token COMMA HEX
%token END ENDL
%token TIMES OPEN_PARENTHESIS
%token CLOSE_PARENTHESIS PLUS MINUS MULT SHL SHR AND OR NOT XOR
%token DIV LABEL
%token EQU PC
%token OPEN_SQUARE_BRACKET CLOSE_SQUARE_BRACKET
%token NEG

%left SHL SHR
%left PLUS MINUS
%left MULT DIV
%left NEG

// define the "terminal symbol" token types 
%token <ival> INT
%token <hval> HEXVAL
%token <sval> STRING
%token <lsval> STR_LITERAL
%token <cval> CH_LITERAL
%token <regval> REG
%token <opcval> OPCODE
%token <pseudoopval> PSEUDOOP
%token <sectionval> SECTION
%token <condval> COND

%%

asm : body_section footer { cout << "Parsed asm file" << endl; } ;

op_code : op_code_0 | op_code_1 | op_code_2; 

op_code_0 : OPCODE REG COMMA expression ENDL { g_ast.addOneRegisterAndExpressionOpcode(line_num, $1, $2); } ;
op_code_1 : OPCODE expression ENDL { g_ast.addExpressionOpcode(line_num, $1); } ;
op_code_2 : OPCODE ENDL { g_ast.addStandaloneOpcode(line_num, $1); } ;


expression: 
	INT    { g_ast.push_number($1); 	} |
	HEXVAL { g_ast.push_number($1); 	} |	
	STRING { g_ast.push_symbol($1);		} |
	expression SHL expression	{ g_ast.push_lshift(); } |
	expression SHR expression	{ g_ast.push_rshift(); } |
	expression PLUS expression	{ g_ast.push_add(); }	 |	
	expression MINUS expression	{ g_ast.push_subtract(); }  |
	expression MULT expression	{ g_ast.push_mult(); } |
	expression DIV expression	{ g_ast.push_div(); } |
	OPEN_PARENTHESIS expression CLOSE_PARENTHESIS | 
	MINUS expression %prec NEG 	{ g_ast.push_unary_neg(); }
	;


equ: STRING EQU expression ENDL {g_ast.addEqu(line_num, $1); } ;

body_section: body_lines ;
body_lines: body_lines body_line | body_line ;

body_line: equ | blank_line | label | op_code;

label: STRING LABEL ENDL { g_ast.addLabel(line_num, $1); } ;

blank_line: ENDL;

footer: END ENDLS;
ENDLS: ENDLS ENDL | ENDL ;
%%

void printUsage(char *arg0)
{
	std::cout << "Usage: " << arg0 << " [-o <output.o>] <file.asm>" << std::endl;
	std::cout << std::endl;
	std::cout << "		options: " << std::endl;
	std::cout << "			-o: output file (elf format) " << std::endl;

}

int main(int argc, char** argv) {

	if (argc == 1)
	{
		printUsage(argv[0]);
		exit(EXIT_FAILURE);
	}

	char *outputFile = nullptr;
	char *type = nullptr;
	char c;

	while ((c = getopt (argc, argv, "o:")) != -1)
	switch (c)
	{
		case 'o':
			outputFile = strdup(optarg);
			break;
		default:
			printUsage(argv[0]);
			exit(EXIT_FAILURE);
	}

	if (outputFile == nullptr)
		outputFile = strdup("a.out");

	if (optind == argc)
	{
		std::cout << "ERROR: no input files" << std::endl;
	}

	// open a file handle to a particular file:
	FILE *myfile = fopen(argv[optind], "r");
	// make sure it's valid:
	if (!myfile) {
		std::cout << "I can't open input file!" << endl;
		return -1;
	}
	// set lex to read from it instead of defaulting to STDIN:
	yyin = myfile;

	// parse through the input until there is no more:

	do {
		yyparse();
	} while (!feof(yyin));

	// Build and simplify symbol table
	g_ast.buildSymbolTable();
	g_ast.reduceSymbolTable();

	// Simplify all expressions
	g_ast.reduceAllExpressions();

	// Generate assembly
	g_ast.assemble();	

	// Resolve label symbols
	g_ast.resolveSymbols();

	// Generate relocations for each section	
	g_ast.generateRelocationTables();

	g_ast.printSymbolTable();
	g_ast.print();
	g_ast.printRelocationTable();

	std::cout << "Generating ELF output..." << std::endl;

	g_ast.writeElfFile(outputFile);

}

void yyerror(const char *s) {
	cout << "Parse error on line " << (line_num + 1) << ": " << s << endl;
	// might as well halt now:
	exit(-1);
}
