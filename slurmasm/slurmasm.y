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
// returns as an object of type "yystype".  But tokens could be of any
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
  char *mopcval;
  char *pseudoopval;
}
%define parse.error verbose

%token COMMA HEX
%token END ENDL
%token TIMES OPEN_PARENTHESIS
%token CLOSE_PARENTHESIS PLUS MINUS MULT SHL SHR AND OR NOT XOR
%token DIV LABEL
%token EQU PC
%token OPEN_SQUARE_BRACKET CLOSE_SQUARE_BRACKET

 // define the "terminal symbol" token types I'm going to use (in CAPS
 // by convention), and associate each with a field of the union:
%token <ival> INT
%token <hval> HEXVAL
%token <sval> STRING
%token <lsval> STR_LITERAL
%token <cval> CH_LITERAL
%token <regval> REG
%token <opcval> OPCODE
%token <mopcval> MOPCODE
%token <pseudoopval> PSEUDOOP

%%

asm: body_section footer { cout << "Parsed asm file" << endl; } ;

op_code : op_code_0 | op_code_1 | op_code_2 | op_code_3 | op_code_4 | op_code_5 | op_code_6 | op_code_7 | op_code_8 | op_code_9 | op_code_10 | op_code_11 | op_code_12 | op_code_13 | op_code_14 | op_code_15 |
			op_code_16 | op_code_17 | op_code_18;

op_code_0 : OPCODE REG ENDL { g_ast.addOneRegisterOpcode(line_num - 1, $1,$2); } ;
op_code_1 : OPCODE REG COMMA REG ENDL { g_ast.addTwoRegisterOpcode(line_num - 1, $1,$2,$4); } ;
op_code_2 : OPCODE REG COMMA REG COMMA REG ENDL { g_ast.addThreeRegisterOpcode(line_num - 1, $1,$2,$4,$6); } ;
op_code_3 : OPCODE REG COMMA expressions ENDL { g_ast.addOneRegisterAndExpressionOpcode(line_num - 1, $1, $2); } ;
op_code_4 : OPCODE expressions ENDL { g_ast.addExpressionOpcode(line_num - 1, $1); } ;
op_code_5 : OPCODE ENDL { g_ast.addStandaloneOpcode(line_num - 1, $1); } ;
op_code_6 : OPCODE OPEN_SQUARE_BRACKET REG CLOSE_SQUARE_BRACKET ENDL { g_ast.addIndirectAddressingOpcode(line_num - 1, $1, $3); }
op_code_7 : OPCODE OPEN_SQUARE_BRACKET REG COMMA expressions CLOSE_SQUARE_BRACKET ENDL { g_ast.addIndirectAddressingOpcodeWithRegAndExpression(line_num - 1, $1, $3); }
op_code_8 : OPCODE OPEN_SQUARE_BRACKET REG CLOSE_SQUARE_BRACKET COMMA REG ENDL { g_ast.addIndirectAddressingOpcodeWithRegister(line_num - 1, $1, $3, $6); }
op_code_9 : OPCODE REG COMMA OPEN_SQUARE_BRACKET REG CLOSE_SQUARE_BRACKET ENDL { g_ast.addIndirectAddressingOpcodeWithRegister(line_num - 1, $1, $5, $2); }
op_code_10 : OPCODE OPEN_SQUARE_BRACKET REG PLUS CLOSE_SQUARE_BRACKET COMMA REG ENDL { g_ast.addIndirectAddressingOpcodeWithPostincrement(line_num - 1, $1, $3, $7); }
op_code_11 : OPCODE OPEN_SQUARE_BRACKET REG MINUS CLOSE_SQUARE_BRACKET COMMA REG ENDL { g_ast.addIndirectAddressingOpcodeWithPostdecrement(line_num - 1, $1, $3, $7); }
op_code_12: OPCODE REG COMMA OPEN_SQUARE_BRACKET REG PLUS CLOSE_SQUARE_BRACKET  ENDL { g_ast.addIndirectAddressingOpcodeWithPostincrement(line_num - 1, $1, $5, $2); }
op_code_13 : OPCODE REG COMMA OPEN_SQUARE_BRACKET REG MINUS CLOSE_SQUARE_BRACKET ENDL { g_ast.addIndirectAddressingOpcodeWithPostdecrement(line_num - 1, $1, $5, $2); }
op_code_14 : OPCODE REG COMMA OPEN_SQUARE_BRACKET expressions CLOSE_SQUARE_BRACKET ENDL { g_ast.addIndirectAddressingOpcodeWithExpression(line_num - 1, $1, $2); }
op_code_15 : OPCODE OPEN_SQUARE_BRACKET expressions CLOSE_SQUARE_BRACKET COMMA REG ENDL { g_ast.addIndirectAddressingOpcodeWithExpression(line_num - 1, $1, $6); }
op_code_16 : OPCODE REG COMMA OPEN_SQUARE_BRACKET REG COMMA expressions CLOSE_SQUARE_BRACKET ENDL { g_ast.addIndirectAddressingOpcodeWithIndexAndExpression(line_num - 1, $1, $2, $5); }
op_code_17 : OPCODE OPEN_SQUARE_BRACKET REG COMMA expressions CLOSE_SQUARE_BRACKET COMMA REG ENDL { g_ast.addIndirectAddressingOpcodeWithIndexAndExpression(line_num - 1, $1, $8, $3); }
op_code_18 : OPCODE reglist ENDL { g_ast.addReglistOpcode(line_num - 1, $1); }

expressions: expressions expression | expression ;
expression: hexval | integer | open_parenthesis | close_parenthesis | plus | minus|
            mult | div | and | or | shl | shr | not | xor | string | str_literal | ch_literal;

reglist: reglist OR reg | reg;

reg: REG { g_ast.addRegisterToReglist($1); }


str_literal:            STR_LITERAL         { g_ast.addStringLiteralToCurrentStatementExpression($1); }
ch_literal:             CH_LITERAL          { g_ast.addCharLiteralToCurrentStatementExpression($1); }
string:                 STRING              { g_ast.addStringToCurrentStatementExpression($1); }
open_parenthesis:       OPEN_PARENTHESIS    { g_ast.addLeftParenthesisToCurrentStatementExpression(); }
close_parenthesis:      CLOSE_PARENTHESIS   { g_ast.addRightParenthesisToCurrentStatementExpression(); }
plus :                  PLUS                { g_ast.addPlusToCurrentStatementExpression(); }
minus :                 MINUS               { g_ast.addMinusToCurrentStatementExpression(); }
mult:                   MULT                { g_ast.addMultToCurrentStatementExpression(); }
div:                    DIV                 { g_ast.addDivToCurrentStatementExpression(); }
and :                   AND                 { g_ast.addAndToCurrentStatementExpression(); }
or :                    OR                  { g_ast.addOrToCurrentStatementExpression(); }
not :                   NOT                 { g_ast.addNotToCurrentStatementExpression(); }
xor :                   XOR                 { g_ast.addXorToCurrentStatementExpression(); }
shl :                   SHL                 { g_ast.addShiftLeftToCurrentStatementExpression();}
shr :                   SHR                 { g_ast.addShiftRightToCurrentStatementExpression();}
hexval:                 HEXVAL              { g_ast.addUIntToCurrentStatementExpresion($1);}
integer:                INT                 { g_ast.addIntToCurrentStatementExpression($1); }

equ: STRING EQU expressions ENDL {g_ast.addEqu(line_num - 1, $1); } ;

times_line: times ;

times: TIMES expressions { g_ast.addTimes(line_num); } ;

pseudoop_line: pseudoop ;

pseudoop: PSEUDOOP expressions ENDL { g_ast.addExpressionPseudoOp(line_num - 1, $1); } ;

label: STRING LABEL ENDL { g_ast.addLabel(line_num - 1, $1); } ;

body_section: body_lines ;
body_lines: body_lines body_line | body_line ;

body_line: op_code | times | pseudoop | label | equ | blank_line;

blank_line: ENDLS;

footer: END ENDLS;
ENDLS: ENDLS ENDL | ENDL ;
%%

void printUsage(char *arg0)
{
    std::cout << "Usage: " << arg0 << " [-t <bin|elf>] [-o <output.o>] <file.asm>" << std::endl;
    std::cout << std::endl;
    std::cout << "      options: " << std::endl;
    std::cout << "          -t: type (bin / elf) " << std::endl;

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

    while ((c = getopt (argc, argv, "t:o:")) != -1)
    switch (c)
    {
        case 't':
            type = strdup(optarg);
            break;
        case 'o':
            outputFile = strdup(optarg);
            break;
        default:
            printUsage(argv[0]);
            exit(EXIT_FAILURE);
    }

    if (optind == argc)
    {
        std::cout << "ERROR: no input files" << std::endl;
    }

    // open a file handle to a particular file:
    FILE *myfile = fopen(argv[optind], "r");
    // make sure it's valid:
    if (!myfile) {
    cout << "I can't open Test.asm file!" << endl;
    return -1;
    }
    // set lex to read from it instead of defaulting to STDIN:
    yyin = myfile;

    // parse through the input until there is no more:

    do {
    yyparse();
    } while (!feof(yyin));

    //cout << g_ast << endl;

    // build symbol table

    cout << "Building symbol table..." << endl;

    g_ast.buildSymbolTable();

    // first pass assemble

    cout << "First pass assembly..." << endl;

    g_ast.firstPassAssemble();

    // resolve symbols

    cout << "Resolving symbols..." << endl;

    g_ast.resolveSymbols();

    // evaluate expressions

    cout << "Evaluating expressions..." << endl;

    g_ast.evaluateExpressions();

    // generate assembly

    cout << "Assembling..." << endl;

    g_ast.assemble();

    g_ast.printAssembly();

    // TODO: relaxation to remove unnecessary NOPs introduced when assembling
    // after symbols are known - how to do this?


    // output binary file

    cout << "Writing output..." << endl;

    g_ast.writeBinOutput(outputFile == nullptr ? "out.bin" : outputFile);

}

void yyerror(const char *s) {
    cout << "Parse error on line " << line_num << ": " << s << endl;
    // might as well halt now:
    exit(-1);
}
