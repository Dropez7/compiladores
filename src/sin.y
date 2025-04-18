%{
#include <iostream>
#include <string>
#include <sstream>
#include <set>
#include <algorithm> 


#define YYSTYPE atributos

using namespace std;

int var_temp_qnt;

struct atributos
{
	string label;
	string traducao;
	string tipo;
};

struct Variavel
{
	string nome;
	string tipo;
};
bool operator<(const Variavel& a, const Variavel& b) {
	return a.nome < b.nome;
}


int yylex(void);
int nLinha = 1;
int nColuna = 1;
void yyerror(string);
string genTempCode(string tipo);
Variavel getVariavel(string nome);
set<Variavel> variaveis;
%}


%token TK_NUM
%token TK_MAIN TK_ID TK_REAL TK_CHAR TK_BOOL
%token TK_FIM TK_ERROR TIPO_VAR
%token NEWLINE
%token TK_TIPO

%token TK_SOMA TK_SUB TK_MUL TK_DIV
%token TK_DIFERENTE TK_MENOR_IGUAL TK_MAIOR_IGUAL TK_IGUAL_IGUAL





%start S

%left '^' '?' '~'
%left '<' '>' TK_IGUAL_IGUAL TK_DIFERENTE TK_MAIOR_IGUAL TK_MENOR_IGUAL

%left '+' '-'
%left '*' '/'
%left '(' ')'


%%

S 			: TK_TIPO TK_MAIN '(' ')' BLOCO
			{
				string codigo = "/*Compilador MAPHRA*/\n"
								"#include<string.h>\n"
								"#include<stdio.h>\n"
								"#define bool int\n\n"
								"int main(void) {\n";
				
				for (const Variavel& var : variaveis)
					codigo += "\t" + var.tipo + " " + var.nome + ";\n";
					//         \t tipo nome;

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
				$$.label = genTempCode("int");
				if ($1.tipo == "char" || $1.tipo == "bool") {
					yyerror("operação indisponível para tipo " + $1.tipo);
				}
				if ($3.tipo == "char" || $3.tipo == "bool") {
					yyerror("operação indisponível para tipo " + $3.tipo);
				}
				if ($1.tipo != $3.tipo) {
					// converte tudo para float
					$1.traducao += ($1.tipo != "float") ? "\t" + $$.label + " = (float) " + $1.label + ";\n" : "";
					$3.traducao += ($3.tipo != "float") ? "\t" + $$.label + " = (float) " + $3.label + ";\n" : "";
				}
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " + " + $3.label + ";\n";
			}
			| E '-' E
			{
				$$.label = genTempCode("int");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " - " + $3.label + ";\n";
			}
			| E '*' E
			{
				$$.label = genTempCode("int");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " * " + $3.label + ";\n";
			}
			| E '/' E
			{
				$$.label = genTempCode("int");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " / " + $3.label + ";\n";
			}
			| '(' E ')'
			{
				$$ = $2;
			}
			| E '^' E
			{
				$$.label = genTempCode("bool");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " && " + $3.label + ";\n";
				$$.tipo = "bool";
			}
			| E '?' E
			{
				$$.label = genTempCode("bool");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " || " + $3.label + ";\n";
				$$.tipo = "bool";
			}
			| '~' E
			{
				$$.label = genTempCode("bool");
				$$.traducao = $1.traducao + "\t" + $$.label + 
					" = !" + $1.label + ";\n";
				$$.tipo = "bool";
			}
			| E '<' E
			{
				$$.label = genTempCode("bool");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " < " + $3.label + ";\n";
				$$.tipo = "bool";
			}
			| E '>' E
			{
				$$.label = genTempCode("bool");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " > " + $3.label + ";\n";
				$$.tipo = "bool";
			}
			| E TK_IGUAL_IGUAL E
			{
				$$.label = genTempCode("bool");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " == " + $3.label + ";\n";
				$$.tipo = "bool";
			}
			| E TK_DIFERENTE E
			{
				$$.label = genTempCode("bool");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " != " + $3.label + ";\n";
				$$.tipo = "bool";
			}
			| E TK_MAIOR_IGUAL E
			{
				$$.label = genTempCode("bool");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " >= " + $3.label + ";\n";
				$$.tipo = "bool";
			}
			| E TK_MENOR_IGUAL E
			{
				$$.label = genTempCode("bool");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " <= " + $3.label + ";\n";
				$$.tipo = "bool";
			}
			// int A
			| TK_TIPO TK_ID
			{
				Variavel v;
				v.nome = $2.label;
				v.tipo = $1.label;
				variaveis.insert(v);
			}
			// A = 2
			| TK_ID '=' E
			{
				string tipo = "bug";
				for (const Variavel& var : variaveis) {
					if (var.nome == $1.label) {
						tipo = var.tipo;
						break;
					}
				}
				if (tipo == "bug") {
					// declaração implícita
					Variavel v;
					v.nome = $1.label;
					v.tipo = $3.tipo;
					variaveis.insert(v);
				}
				$$.traducao = $1.traducao + $3.traducao + "\t" + $1.label + " = " + $3.label + ";\n";
			}
			// int A = 2
			| TK_TIPO TK_ID '=' E
			{
				Variavel v;
				v.nome = $2.label;
				v.tipo = $1.label;

				if (v.tipo != $4.tipo) {
					yyerror("atribuição incompatível (esperando " + v.tipo + ", recebeu " + $4.tipo + ")");
				}
				
				variaveis.insert(v);
				$$.traducao = $2.traducao + $4.traducao + "\t" + $2.label + " = " + $4.label + ";\n";
			}
			| TK_NUM
			{
				$$.label = genTempCode("int");
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				$$.tipo = "int";
			}
			| TK_REAL 
			{
				$$.label = genTempCode("float");
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				$$.tipo = "float";
			}
			| TK_CHAR
			{
				std::string s = $1.label;
				// replace " with '
				std::replace(s.begin(), s.end(), '\"', '\'');
				
				
				$$.label = genTempCode("char");
				$$.traducao = "\t" + $$.label + " = " + s + ";\n";
				$$.tipo = "char";
			}
			| TK_BOOL 
			{

				if($1.label == "T") {
					$1.label = "1";
				} else if ($1.label == "F") {
					$1.label = "0";
				} else {
					yyerror("valor booleano inválido");
				}

				$$.label = genTempCode("bool");
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				$$.tipo = "bool";
			}
			| TK_ID
			{
				string tipo = "bug";
				for (const Variavel& var : variaveis) {
					if (var.nome == $1.label) {
						tipo = var.tipo;
						break;
					}
				}
				if (tipo == "bug") {
					yyerror("variável não declarada " + $1.label);
				}
				$$.label = genTempCode(tipo);
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				$$.tipo = tipo;
			}

			;

%%

#include "lex.yy.c"

int yyparse();

string genTempCode(string tipo)
{
	var_temp_qnt++;
	string nome = "t" + to_string(var_temp_qnt);
	Variavel v;
	v.nome = nome;
	v.tipo = tipo;
	variaveis.insert(v);
	return nome;
}

Variavel getVariavel(string nome) 
{
	Variavel v;
	v.nome = nome;
	v.tipo = "bug";
	for (const Variavel& var : variaveis) {
		if (var.nome == nome) {
			v = var;
			break;
		}
	}
	if (v.tipo == "bug") {
		yyerror("variável não declarada " + nome);
	}
	return v;
}

int main(int argc, char* argv[])
{
	var_temp_qnt = 0;

	yyparse();

	return 0;
}

void yyerror(string MSG)
{
	if (MSG != "syntax error")
	{
		cout << "Erro (Ln " << nLinha << ", Col " << nColuna << "): " << MSG << endl;
	} else
	{
		cout << "Erro (Ln " << nLinha << ", Col " << nColuna << "): " << yytext << endl;
	}
	exit(0);
}
	
