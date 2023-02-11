/*

slurmlink.y : SLURM16 Linker

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
%{


#include <cstdio>
#include <iostream>
#include "AST.h"
#include <unistd.h>
#include <string.h>
#include "Linker.h"

  using namespace std;

  extern "C" int yylex();
  extern "C" int yywrap();
  extern "C" int yyparse();
  extern "C" FILE *yyin;
  extern int line_num;

  AST g_ast;

  void yyerror(const char *s);

%}

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

%token KEEP
%token NOLOAD
%token PROVIDE
%token ALIGN
%token SECTIONS
%token COLON
%token OPEN_BRACE CLOSE_BRACE
%token MEMORY ORIGIN LENGTH
%token SEMICOLON
%token COMMA HEX
%token END ENDL
%token TIMES OPEN_PARENTHESIS
%token CLOSE_PARENTHESIS PLUS MINUS MULT SHL SHR AND OR NOT XOR
%token DIV
%token OPEN_SQUARE_BRACKET CLOSE_SQUARE_BRACKET
%token NEG
%token ASSIGN
%token RIGHT_ANGLE

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

link : body_section { cout << "Parsed linker script" << endl; } ;

expression: 
	INT    { g_ast.push_number($1); 	} |
	HEXVAL { g_ast.push_number($1); 	} |	
	STRING { g_ast.push_symbol($1);		} |
	ALIGN OPEN_PARENTHESIS expression CLOSE_PARENTHESIS { g_ast.push_align(); } |
	expression SHL expression	{ g_ast.push_lshift(); } |
	expression SHR expression	{ g_ast.push_rshift(); } |
	expression PLUS expression	{ g_ast.push_add(); }	 |	
	expression MINUS expression	{ g_ast.push_subtract(); }  |
	expression MULT expression	{ g_ast.push_mult(); } |
	expression DIV expression	{ g_ast.push_div(); } |
	OPEN_PARENTHESIS expression CLOSE_PARENTHESIS | 
	MINUS expression %prec NEG 	{ g_ast.push_unary_neg(); }
	;


asgn: STRING ASSIGN expression SEMICOLON ENDL {g_ast.addAssign(line_num, $1); } ;

body_section: body_lines ;
body_lines: body_lines body_line | body_line ;

body_line: 	asgn { g_ast.consumeGlobalAssignment(); }  | 
		memory_block 	| 
		sections_block  | 
		blank_line;

blank_line: ENDL;

/* MEMORY blocks */

memory_block: memory_start optional_open_brace memory_statements CLOSE_BRACE { g_ast.finaliseMemoryBlock(line_num); };

memory_start: MEMORY | MEMORY ENDL;

optional_open_brace: OPEN_BRACE | OPEN_BRACE ENDL;

memory_statements: memory_statements memory_statement | memory_statement;

memory_statement: STRING OPEN_PARENTHESIS STRING CLOSE_PARENTHESIS COLON memory_attributes ENDL { g_ast.addMemoryStatement(line_num, $1, $3); } |
		  STRING COLON memory_attributes ENDL { g_ast.addMemoryStatement(line_num, $1, NULL); };

memory_attributes: memory_attributes COMMA memory_attribute | 
		   memory_attribute;

memory_attribute: 
	ORIGIN ASSIGN expression 	{ g_ast.addMemoryOrigin(line_num);}	|
	LENGTH ASSIGN expression	{ g_ast.addMemoryLength(line_num);}	;

/* SECTIONS blocks */

sections_block: sections_start OPEN_BRACE sections_statements CLOSE_BRACE {g_ast.finaliseSectionsBlock(line_num); }
					;

sections_start: SECTIONS | SECTIONS ENDL;

sections_statements: sections_statements sections_statement | sections_statement;

sections_statement:
		ENDL |
		section_block ENDL {g_ast.consumeSectionBlock(line_num); } |
		asgn { g_ast.consumeSectionsAssignment(line_num); } |
		PROVIDE OPEN_PARENTHESIS STRING ASSIGN expression CLOSE_PARENTHESIS SEMICOLON ENDL {g_ast.addProvide(line_num, $3);}; 

section_block: section_block_start OPEN_BRACE section_block_statements CLOSE_BRACE section_block_end | 
		section_block_start ENDL OPEN_BRACE section_block_statements CLOSE_BRACE section_block_end ;   

section_block_start: 
		STRING COLON { g_ast.setCurrentSectionBlockName($1); } | 
		STRING OPEN_PARENTHESIS NOLOAD CLOSE_PARENTHESIS COLON { g_ast.setCurrentSectionBlockName($1); };	

section_block_statements: section_block_statements section_block_statement | section_block_statement;

section_block_statement:
		asgn {g_ast.addSectionBlockAssignment(); } |
		KEEP OPEN_PARENTHESIS section_block_statement_section_list CLOSE_PARENTHESIS ENDL {g_ast.addKeepSectionBlockStatement(line_num); } |
		section_block_statement_section_list ENDL {g_ast.addSectionBlockStatement(line_num); }|
		ENDL;
			
section_block_statement_section_list: STRING OPEN_PARENTHESIS section_list CLOSE_PARENTHESIS {g_ast.addSectionBlockStatementSectionList($1); }	|
					MULT OPEN_PARENTHESIS section_list CLOSE_PARENTHESIS {g_ast.addSectionBlockStatementSectionList(strdup("*")); }
					;  

section_list: section_list STRING {g_ast.pushSectionName($2);} |
		STRING 		  {g_ast.pushSectionName($1);} 
		;

section_block_end: 
		RIGHT_ANGLE STRING ENDL {g_ast.setCurrentSectionBlockMemory($2); }| 
		ENDL;
%%

void printUsage(char *arg0)
{
	std::cout << "Usage: " << arg0 << " [-o <output.elf>] -s <linker_script.ld> <files.o>" << std::endl;
	std::cout << std::endl;
	std::cout << "		options: " << std::endl;
	std::cout << "			-o: output file (elf format) " << std::endl;

}

FILE* myfile;

int main(int argc, char** argv) {

	if (argc < 3)
	{
		printUsage(argv[0]);
		exit(EXIT_FAILURE);
	}

	char *outputFile = nullptr;
	char c;

	char *linkerScript = nullptr; 

	while ((c = getopt (argc, argv, "os:")) != -1)
	switch (c)
	{
		case 'o':
			outputFile = strdup(optarg);
			break;
		case 's':
			linkerScript = strdup(optarg);
			break;
		default:
			printUsage(argv[0]);
			exit(EXIT_FAILURE);
	}

	if (outputFile == nullptr)
		outputFile = strdup("a.out");

	if (linkerScript == nullptr)
	{
		std::cout << "ERROR: no linker script" << std::endl;
		printUsage(argv[0]);
		return -1;
	}

	if (optind == argc)
	{
		std::cout << "ERROR: no input files" << std::endl;
		printUsage(argv[0]);
		return -1;
	}

	// open a file handle to a particular file:
	myfile = fopen(linkerScript, "r");
	// make sure it's valid:
	if (!myfile) {
		std::cout << "I can't open input file!" << endl;
		printUsage(argv[0]);
		return -1;
	}
	// set lex to read from it instead of defaulting to STDIN:
	yyin = myfile;

	// parse through the input until there is no more:

	do {
		yyparse();
	} while (!feof(yyin));

	//g_ast.print();

	Linker l(&g_ast);

	for (int i = optind; i < argc; i++)
		l.loadElfFile(argv[i]);

	l.link(outputFile);

	std::cout << "Linking complete, have a nice day..." << std::endl;

}

void yyerror(const char *s) {
	cout << "Parse error on line " << (line_num + 1) << ": " << s << endl;
	// might as well halt now:
	exit(-1);
}

int yywrap() {
	return 1;
}
