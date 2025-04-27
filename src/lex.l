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
ID {LETRA}({LETRA}|{NUM})*
TIPO_VAR int|float|char|bool

BOOL T|F

%%

"\n"		{ nLinha++; nColuna = 1; }

{DELIM} 	{ nColuna += yyleng; }

"main"		{ nColuna += yyleng; return TK_MAIN;}

{TIPO_VAR} { nColuna += yyleng; yylval.label = yytext; yylval.tipo = yytext; return TK_TIPO; }

[(){}[\];,]	{ nColuna += yyleng; return *yytext; }

[+\-*/]		{ nColuna += yyleng; yylval.label = yytext; return TK_ARITMETICO; }

"!="		{ nColuna += yyleng; return TK_DIFERENTE; }
"<="		{ nColuna += yyleng; return TK_MENOR_IGUAL; }
">="		{ nColuna += yyleng; return TK_MAIOR_IGUAL; }
"=="		{ nColuna += yyleng; return TK_IGUAL_IGUAL; }
[\^?~<>]	{ nColuna += yyleng; return *yytext; }

[=]		    { nColuna += yyleng; return *yytext; }


{NUM}		{ nColuna += yyleng; yylval.label = yytext; return TK_NUM; }
{REAL}		{ nColuna += yyleng; yylval.label = yytext; return TK_REAL; }
{CHAR}		{ nColuna += yyleng; yylval.label = yytext; return TK_CHAR; }
{BOOL}      { nColuna += yyleng; yylval.label = yytext; return TK_BOOL; }

{ID}		{ nColuna += yyleng; yylval.label = yytext; return TK_ID; }

.			{ nColuna += yyleng; *yytext; }

%%
