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
%left NOT

// define the "terminal symbol" token types 
%token <ival> INT
%token <hval> HEXVAL
%token <sval> STRING
%token <lsval> STR_LITERAL
%token <cval> CH_LITERAL
%token <regval> REG
%token <regval> XREG
%token <opcval> OPCODE
%token <pseudoopval> PSEUDOOP
%token <sectionval> SECTION
%token <condval> COND

%%

asm : body_section footer { cout << "Parsed asm file" << endl; } ;

op_code : op_code_0 | op_code_1 | op_code_2 | op_code_3 | op_code_4 | op_code_5 | op_code_6 |
	  op_code_7 | op_code_8 | op_code_9 | op_code_10 | op_code_11 | op_code_12 | op_code_13 | 
	  op_code_14 | op_code_15 | op_code_16 ; 

/* one register + expression opcode */
op_code_0 : OPCODE REG COMMA expression ENDL { g_ast.addOneRegisterAndExpressionOpcode(line_num, $1, $2); } ;

/* opcode with expression */
op_code_1 : OPCODE expression ENDL { g_ast.addExpressionOpcode(line_num, $1); } ;

/* standalone opcode */
op_code_2 : OPCODE ENDL { g_ast.addStandaloneOpcode(line_num, $1); } ;

/* three register condition alu operation */
op_code_3 : COND REG COMMA REG COMMA REG ENDL { g_ast.addThreeRegCondOpcode(line_num, $1, $2, $4, $6); } ;

/* two register operation */
op_code_4 : OPCODE REG COMMA REG ENDL { g_ast.addTwoRegisterOpcode(line_num, $1, $2, $4); } ;

/* two register conditional operation */
op_code_5 : COND REG COMMA REG ENDL { g_ast.addTwoRegisterCondOpcode(line_num, $1, $2, $4); } ;

/* one register alu operation */
op_code_6 : OPCODE REG ENDL { g_ast.addOneRegisterOpcode(line_num, $1, $2); } ; 

/* one register indirect operation */
op_code_7: OPCODE OPEN_SQUARE_BRACKET REG CLOSE_SQUARE_BRACKET ENDL { g_ast.addOneRegisterIndirectOpcode(line_num, $1, $3); } ; 

/* one register indirect operation with expression */
op_code_8: OPCODE OPEN_SQUARE_BRACKET REG COMMA expression CLOSE_SQUARE_BRACKET ENDL { g_ast.addOneRegisterIndirectOpcodeWithExpression(line_num, $1, $3); }; 

/* two register indirect operation - ld, in */
op_code_9: OPCODE REG COMMA OPEN_SQUARE_BRACKET REG CLOSE_SQUARE_BRACKET ENDL { g_ast.addTwoRegisterIndirectOpcodeA(line_num, $1, $2, $5); }; 

/* two register indirect operation with expression - ld, in */
op_code_10: OPCODE REG COMMA OPEN_SQUARE_BRACKET REG COMMA expression CLOSE_SQUARE_BRACKET ENDL { g_ast.addTwoRegisterIndirectOpcodeWithExpressionA(line_num, $1, $2, $5); }; 

/* two register indirect operation - st, out */
op_code_11: OPCODE OPEN_SQUARE_BRACKET REG CLOSE_SQUARE_BRACKET COMMA REG ENDL { g_ast.addTwoRegisterIndirectOpcodeB(line_num, $1, $3, $6); }; 

/* two register indirect operation with expression - st, out */
op_code_12: OPCODE OPEN_SQUARE_BRACKET REG COMMA expression CLOSE_SQUARE_BRACKET COMMA REG ENDL { g_ast.addTwoRegisterIndirectOpcodeWithExpressionB(line_num, $1, $3, $8); }; 

/* two register indirect operation with expression - ld, in - r0 implied */
op_code_13: OPCODE REG COMMA OPEN_SQUARE_BRACKET expression CLOSE_SQUARE_BRACKET ENDL { g_ast.addTwoRegisterIndirectOpcodeWithExpressionA(line_num, $1, $2, strdup("r0")); }; 

/* two register indirect operation with expression - st, out - r0 implied */
op_code_14: OPCODE OPEN_SQUARE_BRACKET expression CLOSE_SQUARE_BRACKET COMMA REG ENDL { g_ast.addTwoRegisterIndirectOpcodeWithExpressionB(line_num, $1, strdup("r0"), $6); }; 

/* register to extended register ALU op */
op_code_15: OPCODE XREG COMMA REG {g_ast.addRegisterToExtendedRegisterALUOp(line_num, $1, $2, $4); }

/* extended register to register ALU op */
op_code_16: OPCODE REG COMMA XREG {g_ast.addExtendedRegisterToRegisterALUOp(line_num, $1, $2, $4); }

/* expressions */
expression: 
	INT    { g_ast.push_number($1); 	} |
	HEXVAL { g_ast.push_number($1); 	} |	
	STRING { g_ast.push_symbol($1);		} |
	CH_LITERAL 			{ g_ast.push_char_literal($1); } |
	expression SHL expression	{ g_ast.push_lshift(); }    |
	expression SHR expression	{ g_ast.push_rshift(); }    |
	expression PLUS expression	{ g_ast.push_add(); }	    |	
	expression MINUS expression	{ g_ast.push_subtract(); }  |
	expression MULT expression	{ g_ast.push_mult(); } 	    |
	expression DIV expression	{ g_ast.push_div(); } 	    |
	OPEN_PARENTHESIS expression CLOSE_PARENTHESIS 		    | 
	MINUS expression %prec NEG 	{ g_ast.push_unary_neg(); } |
	NOT expression 			{ g_ast.push_bitwise_complement(); }
	;

/* pseudo op codes */

pseudo_op: pseudo_op_code | times;

pseudo_op_code: pseudo_op1 | pseudo_op2 | pseudo_op3;

/* e.g. .function, .global etc */
pseudo_op1: PSEUDOOP expression ENDL { g_ast.addPseudoOpWithExpression(line_num, $1); };

/* e.g. .endfunc */
pseudo_op2: PSEUDOOP ENDL { g_ast.addPseudoOp(line_num, $1); };

/* e.g. dw "Hello world!" */
pseudo_op3: PSEUDOOP STR_LITERAL ENDL { g_ast.addPseudoOpWithStringLiteral(line_num, $1, $2); }

times: TIMES expression op_code { g_ast.addTimes(line_num); } |
       TIMES expression pseudo_op_code { g_ast.addTimes(line_num); } ;

equ: STRING EQU expression ENDL {g_ast.addEqu(line_num, $1); } ;

body_section: body_lines ;
body_lines: body_lines body_line | body_line ;

body_line: equ | blank_line | label | op_code | pseudo_op ;

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
	bool verbose = false;

	while ((c = getopt (argc, argv, "o:v")) != -1)
	switch (c)
	{
		case 'o':
			outputFile = strdup(optarg);
			break;
		case 'v':
			verbose = true;
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

	// Generate repeated assemblies given by the times statement
	g_ast.generateTimesMacros();

	// Handle ".align" statements
	g_ast.handleAlignStatements();

	// Handle global and weak symbols
	g_ast.handleGlobalAndWeakSymbols();

	// Compute length of functions
	g_ast.determineFunctionsAndLengths();

	// Resolve label symbols
	g_ast.resolveSymbols();

	// Generate relocations for each section	
	g_ast.generateRelocationTables();

	if (verbose)
	{
		g_ast.printSymbolTable();
		g_ast.print();
		g_ast.printRelocationTable();
	}

	std::cout << "Generating ELF output..." << std::endl;

	g_ast.writeElfFile(outputFile);

}

void yyerror(const char *s) {
	cout << "Parse error on line " << (line_num + 1) << ": " << s << endl;
	// might as well halt now:
	exit(-1);
}
