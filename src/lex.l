%{
#include <string>

%}

ESPACO [ \t]
DIGITO [0-9]
LETRA [A-Za-z_]

DELIM {ESPACO}+
NUM {DIGITO}+
REAL {NUM}+("."{NUM}+)?
CHAR ((\"({LETRA}|{NUM})\")|('({LETRA}|{NUM})'))
STRING (\"([^"\\]*(\\.[^"\\]*)*)\")|(\'([^"\\]*(\\.[^"\\]*)*)\')
COMMENT (\/\/\ .*\n?)|(\/\*(.|\n)*\*\/) 

ID {LETRA}({LETRA}|{NUM})*
TIPO_VAR int|float|char|bool|string

BOOL T|F

%%

"\n"		{ nLinha++; nColuna = 1; }

{DELIM} 	{ nColuna += yyleng; }

"main"		{ nColuna += yyleng; return TK_MAIN;}

"if"        { nColuna += yyleng; return TK_IF; }
"else"|"helcio"      { nColuna += yyleng; return TK_ELSE; }
"for"       { nColuna += yyleng; return TK_LACO; }
"do"        { nColuna += yyleng; return TK_DO; }
{TIPO_VAR} { nColuna += yyleng; yylval.label = yytext; yylval.tipo = yytext; return TK_TIPO; }

[(){}[\];,]	{ nColuna += yyleng; return *yytext; }

[+\-*/]		{ nColuna += yyleng; yylval.label = yytext; return TK_ARITMETICO; }
"++"|"--"    { nColuna += yyleng; yylval.label = yytext; return TK_UNARIO; }
"+="|"-="|"*="|"/="	{ nColuna += yyleng; yylval.label = yytext; return TK_PREGUICA; }


"!="|"<="|">="|"=="|"<"|">"		{ nColuna += yyleng; yylval.label = yytext; return TK_RELACIONAL; }
[\^?~]	{ nColuna += yyleng; return *yytext; }

[=]		    { nColuna += yyleng; return *yytext; }


{NUM}|(-{NUM})	{ nColuna += yyleng; yylval.label = yytext; return TK_NUM; }
{REAL}|(-{REAL}) { nColuna += yyleng; yylval.label = yytext; return TK_REAL; }
{CHAR}		{ nColuna += yyleng; yylval.label = yytext; return TK_CHAR; }
{STRING}	{ nColuna += yyleng; yylval.label = yytext; return TK_STRING; }
{COMMENT}	{ nColuna += yyleng;}
{BOOL}      { nColuna += yyleng; yylval.label = yytext; return TK_BOOL; }

"print"     { nColuna += yyleng; return TK_PRINT; }

{ID}		{ nColuna += yyleng; yylval.label = yytext; return TK_ID; }

.			{ nColuna += yyleng; *yytext; }

%%
