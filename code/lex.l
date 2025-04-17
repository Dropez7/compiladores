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

"main"		{ return TK_MAIN;}

"int"|"float"|"char"|"bool" { yylval.label = yytext; return TK_TIPO; }

[(){}[\];,]	{ return *yytext; }

[+\-*/]		{ return *yytext; }

"!="		{ return TK_DIFERENTE; }
"<="		{ return TK_MENOR_IGUAL; }
">="		{ return TK_MAIOR_IGUAL; }
"=="		{ return TK_IGUAL_IGUAL; }
">"         { return '>'; }
"<"         { return '<'; }

[=]		    { return *yytext; }

[\^]		{ return *yytext; }
[?]	    	{ return *yytext; }
[~]		    { return *yytext; }

{NUM}		{ yylval.label = yytext; return TK_NUM; }
{REAL}		{ yylval.label = yytext; return TK_REAL; }
{CHAR}		{ yylval.label = yytext; return TK_CHAR; }
{BOOL}      { yylval.label = yytext; return TK_BOOL; }

{ID}		{ yylval.label = yytext; return TK_ID; }
{TIPO_VAR}	{ yylval.label = yytext; return TIPO_VAR; }

.			{ *yytext; }

%%
