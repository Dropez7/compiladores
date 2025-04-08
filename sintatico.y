%{
#include <iostream>
#include <string>
#include <sstream>
#include <set>



#define YYSTYPE atributos

using namespace std;

int var_temp_qnt;

struct atributos
{
	string label;
	string traducao;
};

int yylex(void);
void yyerror(string);
string gentempcode();
set<string> variaveis_declaradas;
set<string> variaveis_int;
set<string> variaveis_float;
set<string> variaveis_char;
set<string> variaveis_bool;
%}


%token TK_NUM
%token TK_MAIN TK_ID TK_REAL
%token TK_FIM TK_ERROR TIPO_VAR
%token NEWLINE
%token TK_TIPO_INT TK_TIPO_FLOAT TK_TIPO_CHAR TK_TIPO_BOOL



%start S

%left '+'

%%

S 			: TK_TIPO_INT TK_MAIN '(' ')' BLOCO
			{
				string codigo = "/*Compilador FOCA*/\n"
								"#include <iostream>\n"
								"#include<string.h>\n"
								"#include<stdio.h>\n"
								"int main(void) {\n";
				
				for (const auto& var : variaveis_int)
					codigo += "\tint " + var + ";\n";

				for (const auto& var : variaveis_float)
					codigo += "\tfloat " + var + ";\n";

				for (const auto& var : variaveis_char)
					codigo += "\tchar " + var + ";\n";
				
				for (const auto& var : variaveis_bool)
					codigo += "\tbool " + var + ";\n";

				for (const auto& var : variaveis_declaradas)
					codigo += "\ttemp " + var + ";\n";

				codigo += "\n";
								
				codigo += $5.traducao;
								
				codigo += 	"\treturn 0;"
							"\n}";

				cout << codigo << endl;
			}
			;

BLOCO		: '{' COMANDOS '}'
			{
				$$.traducao = $2.traducao;
			}
			;

COMANDOS	: COMANDO COMANDOS
			{
				$$.traducao = $1.traducao + $2.traducao;
			}
			|
			{
				$$.traducao = "";
			}
			;

COMANDO 	: E ';'
			{
				$$ = $1;
			}
			;

E 			: E '+' E
			{
				$$.label = gentempcode();
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " + " + $3.label + ";\n";
			}
			| E '-' E
			{
				$$.label = gentempcode();
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " - " + $3.label + ";\n";
			}
			| TK_TIPO_INT TK_ID '=' E
			{
				variaveis_int.insert($2.label); // <-- registra a variavel
				$$.traducao = $2.traducao + $4.traducao + "\t" + $2.label + " = " + $4.label + ";\n";
			}
			| TK_TIPO_FLOAT TK_ID '=' E
			{
				variaveis_float.insert($2.label); // <-- registra a variavel
				$$.traducao = $2.traducao + $4.traducao + "\t" + $2.label + " = " + $4.label + ";\n";
			}
			| TK_TIPO_CHAR TK_ID '=' E
			{
				variaveis_char.insert($2.label); // <-- registra a variavel
				$$.traducao = $2.traducao + $4.traducao + "\t" + $2.label + " = " + $4.label + ";\n";
			}
			| TK_TIPO_BOOL TK_ID '=' E
			{
				variaveis_bool.insert($2.label); // <-- registra a variavel
				$$.traducao = $2.traducao + $4.traducao + "\t" + $2.label + " = " + $4.label + ";\n";
			}

			| TK_NUM
			{
				$$.label = gentempcode();
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
			}
			| TK_REAL 
			{
				$$.label = gentempcode();
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
			}
			| TK_ID
			{
				variaveis_declaradas.insert($1.label); // <-- registra o uso
				$$.label = gentempcode();
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
			}

			;

%%

#include "lex.yy.c"

int yyparse();

string gentempcode()
{
	var_temp_qnt++;
	string nome = "t" + to_string(var_temp_qnt);
	variaveis_declaradas.insert(nome);
	return nome;
}

int main(int argc, char* argv[])
{
	var_temp_qnt = 0;

	yyparse();

	return 0;
}

void yyerror(string MSG)
{
	cout << MSG << endl;
	exit (0);
}				
