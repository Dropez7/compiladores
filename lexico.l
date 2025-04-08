%{
#include <string>

%}

ESPACO [ \t]
DIGITO [0-9]
LETRA [A-Za-z_]

DELIM {ESPACO}+
NUM {DIGITO}+
REAL {NUM}+("."{NUM}+)?
CHAR \"({LETRA}|{NUM})\"
ID {LETRA}({LETRA}|{NUM})*
TIPO_VAR int|float|char|bool

BOOL T|F

%%

"\n"		{}

{DELIM} 	{}

"main"		{return TK_MAIN;}

"int"       { yylval.label = yytext; return TK_TIPO_INT; }
"float"     { yylval.label = yytext; return TK_TIPO_FLOAT; }
"char"      { yylval.label = yytext; return TK_TIPO_CHAR; }
"bool"      { yylval.label = yytext; return TK_TIPO_BOOL; }

[(){}[\];,]	{ return *yytext; }

[+\-*/]		{ return *yytext; }

"="		    { return '='; }

{NUM}		{ yylval.label = yytext; return TK_NUM; }
{REAL}		{ yylval.label = yytext; return TK_REAL; }
{CHAR}		{ yylval.label = yytext; return TK_CHAR; }
{BOOL}      { yylval.label = yytext; return TK_BOOL; }

{ID}		{ yylval.label = yytext; return TK_ID; }
{TIPO_VAR}	{ yylval.label = yytext; return TIPO_VAR; }

.			{ *yytext; }

%%
