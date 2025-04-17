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
void yyerror(string);
string gentempcode(string tipo);
set<string> variaveis_declaradas;
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
				string codigo = "/*Compilador FOCA*/\n"
								"#include <iostream>\n"
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
				$$.label = gentempcode("bool");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " + " + $3.label + ";\n";
			}
			| E '-' E
			{
				$$.label = gentempcode("bool");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " - " + $3.label + ";\n";
			}
			| E '*' E
			{
				$$.label = gentempcode("bool");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " * " + $3.label + ";\n";
			}
			| E '/' E
			{
				$$.label = gentempcode("bool");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " / " + $3.label + ";\n";
			}
			| '(' E ')'
			{
				$$ = $2;
			}
			| E '^' E
			{
				$$.label = gentempcode("bool");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " && " + $3.label + ";\n";
				$$.tipo = "bool";
			}
			| E '?' E
			{
				$$.label = gentempcode("bool");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " || " + $3.label + ";\n";
				$$.tipo = "bool";
			}
			| '~' E
			{
				$$.label = gentempcode("bool");
				$$.traducao = $1.traducao + "\t" + $$.label + 
					" = !" + $1.label + ";\n";
				$$.tipo = "bool";
			}
			| E '<' E
			{
				$$.label = gentempcode("bool");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " < " + $3.label + ";\n";
				$$.tipo = "bool";
			}
			| E '>' E
			{
				$$.label = gentempcode("bool");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " > " + $3.label + ";\n";
				$$.tipo = "bool";
			}
			| E TK_IGUAL_IGUAL E
			{
				$$.label = gentempcode("bool");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " == " + $3.label + ";\n";
				$$.tipo = "bool";
			}
			| E TK_DIFERENTE E
			{
				$$.label = gentempcode("bool");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " != " + $3.label + ";\n";
				$$.tipo = "bool";
			}
			| E TK_MAIOR_IGUAL E
			{
				$$.label = gentempcode("bool");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " >= " + $3.label + ";\n";
				$$.tipo = "bool";
			}
			| E TK_MENOR_IGUAL E
			{
				$$.label = gentempcode("bool");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + 
					" = " + $1.label + " <= " + $3.label + ";\n";
				$$.tipo = "bool";
			}
			| TK_TIPO TK_ID '=' E
			{
				Variavel v;
				v.nome = $2.label;
				v.tipo = $1.label;

				if (v.tipo != $4.tipo) {
					yyerror("Erro: atribuição incompatível (esperado" + v.tipo + ", recebeu " + $4.tipo + ")");
				}
				
				variaveis.insert(v);
				$$.traducao = $2.traducao + $4.traducao + "\t" + $2.label + " = " + $4.label + ";\n";
			}
			| TK_TIPO TK_ID
			{
				Variavel v;
				v.nome = $2.label;
				v.tipo = $1.label;
				variaveis.insert(v);
			}
			| TK_NUM
			{
				$$.label = gentempcode("int");
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				$$.tipo = "int";
			}
			| TK_REAL 
			{
				$$.label = gentempcode("float");
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				$$.tipo = "float";
			}
			| TK_CHAR
			{
				std::string s = $1.label;
				std::replace(s.begin(), s.end(), '\"', '\'');
				
				
				$$.label = gentempcode("char");
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
					yyerror("Erro: valor booleano inválido");
				}

				$$.label = gentempcode("bool");
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
					yyerror("Erro: variável não declarada " + $1.label);
				}
				// variaveis.insert($1.label); // <-- registra o uso
				$$.label = gentempcode(tipo);
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
			}

			;

%%

#include "lex.yy.c"

int yyparse();

string gentempcode(string tipo)
{
	var_temp_qnt++;
	string nome = "t" + to_string(var_temp_qnt);
	Variavel v;
	v.nome = nome;
	v.tipo = tipo;
	variaveis.insert(v);
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
