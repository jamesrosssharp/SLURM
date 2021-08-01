%{
#include "nbasm.tab.h"
using namespace std;
#define YY_DECL extern "C" int yylex()
int line_num = 1;

#define MAX_STRING 255
char g_string[MAX_STRING];
int g_str_idx = 0;

%}

%x COMMENTS
%x COMMENT
%x STRING_LITERAL
%x CHAR_LITERAL

%%
\/\*                    { BEGIN(COMMENTS); }
<COMMENTS>\*\/          { BEGIN(INITIAL);  }
<COMMENTS>\n      { ++line_num; }
<COMMENTS>.    ;
[ \t]          ;
\/\/    { BEGIN(COMMENT); }
<COMMENT>\n { ++line_num; BEGIN(INITIAL); return ENDL; }
<COMMENT>. ;
\"  { g_str_idx = 0; BEGIN(STRING_LITERAL); }
<STRING_LITERAL>\n { ++line_num; }
<STRING_LITERAL>\" { BEGIN(INITIAL); g_string[g_str_idx] = '\0'; yylval.sval = strdup(g_string); return STR_LITERAL; }
<STRING_LITERAL>. { if (g_str_idx < MAX_STRING - 2) g_string[g_str_idx++] = yytext[0];};

\'  { g_str_idx = 0; BEGIN(CHAR_LITERAL); }
<CHAR_LITERAL>\n { ++line_num; }
<CHAR_LITERAL>\' { BEGIN(INITIAL); g_string[g_str_idx] = '\0'; yylval.sval = strdup(g_string); return CH_LITERAL; }
<CHAR_LITERAL>. { if (g_str_idx < MAX_STRING - 2) g_string[g_str_idx++] = yytext[0];};


\.end            { return END; }
[0-9]+         { yylval.ival = atoi(yytext); return INT; }
0x[0-9a-fA-F]+|[0-9a-fA-F]+h         { yylval.ival = strtol(yytext, NULL, 16); return HEXVAL; }

\.org|\.align|dw|dd {yylval.pseudoopval = strdup(yytext); return PSEUDOOP; }
\.times {return TIMES; }

equ {return EQU; }

imm|add|adc|sub|sbb|and|or|xor|sla|slx|sl0|sl1|rl|sra|srx|sr0|sr1|rr { yylval.sval = strdup(yytext); return OPCODE; }
cmp|test|load|mul|muls|div|divs|bsl                                  { yylval.sval = strdup(yytext); return OPCODE; }
bsr|fmul|fdiv|fadd|fsub|fcmp|fint|fflt|nop|sleep|jump|jumpz|jumpc    { yylval.sval = strdup(yytext); return OPCODE; }
jumpnz|jumpnc                                                        { yylval.sval = strdup(yytext); return OPCODE; }
call|callz|callc|callnz|callnc|svc|ret|reti|rete                     { yylval.sval = strdup(yytext); return OPCODE; }
ldw|stw|inc|dec|incw|decw|ldspr|stspr|out|in                         { yylval.sval = strdup(yytext); return OPCODE; }

r0|r1|r2|r3|r4|r5|r6|r7|r8|r9|r10|r11|r12|r13|r14|r15|r16|s0|s1|s2|s3|s4|s5|s6|s7|s8|s9|s10|s11|s12|s13|s14|s15|s16 {yylval.regval = strdup(yytext); return REG; }

[a-zA-Z0-9_\.]+   {
    yylval.sval = strdup(yytext);
    return STRING;
}

\: { return LABEL; }

\(              { return OPEN_PARENTHESIS; }
\)              { return CLOSE_PARENTHESIS; }
\+              { return PLUS; }
\-              { return MINUS; }
\*              { return MULT; }
\/              { return DIV; }
\<\<            { return SHL; }
\>\>            { return SHR; }
\&             { return AND; }
\|             { return OR; }
\~|\!          { return NOT; }
\^             { return XOR; }
,              { return COMMA; }
\n             { ++line_num; return ENDL; }
\[             { return OPEN_SQUARE_BRACKET; }
\]             { return CLOSE_SQUARE_BRACKET; }
.              ;
%%
