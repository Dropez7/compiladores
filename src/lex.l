%{
#include <string>

%}

ESPACO [ \t]
DIGITO [0-9]
LETRA [A-Za-z_]

DELIM {ESPACO}+
NUM {DIGITO}+
REAL {NUM}+("."{NUM}+)?
STRING (\"([^"\\]*(\\.[^"\\]*)*)\")|(\'([^"\\]*(\\.[^"\\]*)*)\')
COMMENT (\/\/\ .*\n?)|(\/\*(.|\n)*\*\/) 

ID {LETRA}({LETRA}|{NUM})*
TIPO_VAR int|float|bool|string


BOOL T|F

%%

"\n"		{ nLinha++; nColuna = 1; }

{DELIM} 	{ nColuna += yyleng; }

"main"		{ nColuna += yyleng; return TK_MAIN;}

"if"        { nColuna += yyleng; return TK_IF; }
"else"|"helcio"      { nColuna += yyleng; return TK_ELSE; }
"for"       { nColuna += yyleng; canBreak = true; canContinue = true; return TK_LACO; }
"in"        { nColuna += yyleng; return TK_IN; }
"do"        { nColuna += yyleng; canBreak = true; canContinue = true; return TK_DO; }
"break"     { nColuna += yyleng; return TK_BREAK; }
"continue"  { nColuna += yyleng; return TK_CONTINUE; }
"wd"|"wheeldecide" { nColuna += yyleng; return TK_WHEELDECIDE; }
"opt"|"option"   { nColuna += yyleng; return TK_OPTION; }
"default"|"dafoe" { nColuna += yyleng; return TK_DEFAULT; }
"switch"   { nColuna += yyleng; canBreak = true; return TK_SWITCH; }

"func"     { nColuna += yyleng; return TK_FUNCAO; }
"bind"     { nColuna += yyleng; return TK_BIND; }
"this"     { nColuna += yyleng; yylval.label = yytext; return TK_THIS; }
"return"   { nColuna += yyleng; return TK_RETURN; }
"null"     { nColuna += yyleng; return TK_NULL; }
"struct"   { nColuna += yyleng; return TK_STRUCT; }
{TIPO_VAR} { nColuna += yyleng; yylval.label = yytext; yylval.tipo = yytext; return TK_TIPO; }

[(){}[\]:;,\.]	{ nColuna += yyleng; return *yytext; }

[+\-*/]		{ nColuna += yyleng; yylval.label = yytext; return *yytext; }
"++"|"--"    { nColuna += yyleng; yylval.label = yytext; return TK_UNARIO; }
"+="|"-="|"*="|"/="	{ nColuna += yyleng; yylval.label = yytext; return TK_ABREVIADO; }


!=|<=|>=|==|<|>		{ nColuna += yyleng; yylval.label = yytext; return TK_RELACIONAL; }
[\^?~]	{ nColuna += yyleng; return *yytext; }

[=]		    { nColuna += yyleng; return *yytext; }


{NUM}|(-{NUM})	{ nColuna += yyleng; yylval.label = yytext; return TK_NUM; }
{REAL}|(-{REAL}) { nColuna += yyleng; yylval.label = yytext; return TK_REAL; }
{STRING}	{ nColuna += yyleng; yylval.label = yytext; return TK_STRING; }
{COMMENT}	{ nColuna += yyleng;}
{BOOL}      { nColuna += yyleng; yylval.label = yytext; return TK_BOOL; }

"print"     { nColuna += yyleng; return TK_PRINT; }
"input"     { nColuna += yyleng; return TK_INPUT; }
"append"    { nColuna += yyleng; return TK_APPEND; }
"len"       { nColuna += yyleng; return TK_LEN; }
"remove"    { nColuna += yyleng; return TK_REMOVE; } 

{ID}		{ nColuna += yyleng; yylval.label = yytext; return TK_ID; }

.			{ nColuna += yyleng; *yytext; }

%%
