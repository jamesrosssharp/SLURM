
%{
#include "slurmasm-ng.tab.h"
using namespace std;
#define YY_DECL extern "C" int yylex()
int line_num = 0;

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
\#    { BEGIN(COMMENT); }
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

\.align|dw|dd|db|\.global|\.function|\.endfunc|\.weak|\.extern|\.section {yylval.pseudoopval = strdup(yytext); return PSEUDOOP; }

\.times {return TIMES; }

equ {return EQU; }

adc|add|and|asr|ba|bc|bl|bnc|bns|bnz|bs|bz|bv|bnv|cc|cs|cz|imm|iret|ld|lsl|lsr|mov|nop|or|ret|rol|rolc|rorc|sbb|sc|ss|st|sub|sz|xor|cmp|test|in|out|sleep|sti|cli|stf|rsf|mul|mulu|umulu|bne|beq|bge|blt|ble|bgt|ldb|ldbsx|stb|bltu|bleu|bgtu|bgeu|rrn|rln|bswap { yylval.sval = strdup(yytext); return OPCODE; }

(add|adc|and|or|sbb|sub|xor|mov|mul|mulu|umulu)(\.c|\.nc|\.z|\.nz|\.s|\.s|\.v|\.nv|\.le|\.lt|\.ge|\.gt|\.eq|\.ne|\.ltu|\.leu|.\gtu|.\geu) { yylval.condval = strdup(yytext); return COND; }
 
r0|r1|r2|r3|r4|r5|r6|r7|r8|r9|r10|r11|r12|r13|r14|r15 {yylval.regval = strdup(yytext); return REG; }

x[0-9]+ {yylval.regval = strdup(yytext); return XREG; }

[a-zA-Z_\.]+[a-zA-Z0-9_\.]*   {
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
%%
