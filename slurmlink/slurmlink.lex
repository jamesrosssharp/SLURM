
%{
#include "slurmlink.tab.h"
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
\"  { g_str_idx = 0; BEGIN(STRING_LITERAL); }
<STRING_LITERAL>\n { ++line_num; }
<STRING_LITERAL>\" { BEGIN(INITIAL); g_string[g_str_idx] = '\0'; yylval.sval = strdup(g_string); return STR_LITERAL; }
<STRING_LITERAL>. { if (g_str_idx < MAX_STRING - 2) g_string[g_str_idx++] = yytext[0];};

\'  { g_str_idx = 0; BEGIN(CHAR_LITERAL); }
<CHAR_LITERAL>\n { ++line_num; }
<CHAR_LITERAL>\' { BEGIN(INITIAL); g_string[g_str_idx] = '\0'; yylval.sval = strdup(g_string); return CH_LITERAL; }
<CHAR_LITERAL>. { if (g_str_idx < MAX_STRING - 2) g_string[g_str_idx++] = yytext[0];};


[0-9]+         { yylval.ival = atoi(yytext); return INT; }
0x[0-9a-fA-F]+|[0-9a-fA-F]+h         { yylval.ival = strtol(yytext, NULL, 16); return HEXVAL; }

[a-zA-Z]+[a-zA-Z0-9_\.]*   {
    yylval.sval = strdup(yytext);
    return STRING;
}

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
=		{ return ASSIGN; }
;		{ return SEMICOLON; }


%%
