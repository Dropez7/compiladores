%{
#include <iostream>
#include <string>
#include <sstream>
#include <set>
#include <algorithm>
#include "src/utils.hpp"

void genCodigo(string traducao) {
	string codigo = "/*Compilador MAPHRA*/\n"
					"#include <string.h>\n"
					"#include <stdio.h>\n"
					"#define bool int\n"
					"#define T 1\n"
					"#define F 0\n\n"
					"int main(void) {\n";

	for (const Variavel& var : variaveis) {
		if (var.nome == var.id.substr(1)) {
			codigo += "\t" + var.tipo + " " + var.id + ";\n";
		} else {
			codigo += "\t" + var.tipo + " " + var.id + "; // " + var.nome + "\n";
		}
	}
	
	codigo += "\n";
	codigo += traducao;
	codigo += "\treturn 0;\n";
	codigo += "}";
	
	cout << codigo << endl;
}

%}


%token TK_NUM
%token TK_MAIN TK_ID TK_REAL TK_CHAR TK_BOOL TK_PRINT
%token TK_TIPO TK_ARITMETICO
%token TK_IF TK_ELSE
%token TK_RELACIONAL





%start S

%left '^' '?' '~'
%left '<' '>' TK_IGUAL_IGUAL TK_DIFERENTE TK_MAIOR_IGUAL TK_MENOR_IGUAL

%left '+' '-'
%left '*' '/'
%left '(' ')'


%%

S : 		TK_TIPO TK_MAIN '(' ')' BLOCO
			{
				genCodigo($5.traducao);
			}
			| { entrar_escopo(); } COMANDOS
			{
				genCodigo($2.traducao);
			}
			;

			;
BLOCO : '{' { entrar_escopo(); } COMANDOS '}'
			{
				sair_escopo();
				$$.traducao = $3.traducao;
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
			|
			E
			{
				$$ = $1;
			}
			| BLOCO
			{
				$$ = $1;
			}
			| TK_IF E BLOCO
			{
				if ($2.tipo != "bool") {
					yyerror("condição deve ser do tipo booleano");
				}
				string label = genLabel();
				$$.traducao = $2.traducao + "\tif (!" + $2.label + ") goto " + label + ";\n\t" + $3.traducao + "\t" + label + ":\n";
			}
			| TK_IF E BLOCO TK_ELSE COMANDO
			{
				if ($2.tipo != "bool") {
					yyerror("condição deve ser do tipo booleano");
				}
				string l1 = genLabel();
				string l2 = genLabel();
				$$.traducao = $2.traducao + "\tif (!" + $2.label + ") goto " + l1 + ";\n\t" +
					$3.traducao + "\tgoto " + l2 + ";\n" +
					l1 + ":\n\t" + $5.traducao + "\n" +
					l2 + ":\n";
			}
			;

E 			: BLOCO
			{
				$$.traducao = $1.traducao;
			}
			| E TK_ARITMETICO E
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
					" = " + $1.label + " " + $2.label + " " + $3.label + ";\n";
			}
			| E TK_RELACIONAL E
			{
				$$.label = genTempCode("bool");
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
					" = " + $1.label + " " + $2.label + " " + $3.label + ";\n";
				$$.tipo = "bool";
			}
			| '(' E ')'
			{
				$$ = $2;
			}
			| E '^' E
			{
				$$.label = genTempCode("bool");
				if ($1.tipo != "bool" || $3.tipo != "bool") {
					yyerror("operação (^) indisponível para tipo " + $1.tipo + " e " + $3.tipo);
				}
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label +
					" = " + $1.label + " && " + $3.label + ";\n";
				$$.tipo = "bool";
			}
			| E '?' E
			{
				if ($1.tipo != "bool") {
					yyerror("operação (?) indisponível para tipo " + $1.tipo);
				}
				$$.label = genTempCode("bool");
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label +
					" = " + $1.label + " || " + $3.label + ";\n";
				$$.tipo = "bool";
			}
			| '~' E
			{
				if ($1.tipo != "bool") {
					yyerror("operação (~) indisponível para tipo " + $1.tipo);
				}
				$$.label = genTempCode("bool");
				$$.traducao = $1.traducao + "\t" + $$.label +
					" = !" + $1.label + ";\n";
				$$.tipo = "bool";
			}
			// int(3.14)
			| TK_TIPO '(' E ')'
			{
				if (checkIsPossible($1.tipo, $3.tipo)) {
					$$.label = genTempCode($1.tipo);
					$$.traducao = $3.traducao + "\t" + $$.label + " = (" + $1.tipo + ") " + $3.label + ";\n";
				} else {
					yyerror("conversão inválida de " + $3.tipo + " para " + $1.tipo);
				}
			}
			// A, B = B, A
			| TK_ID ',' TK_ID '=' TK_ID ',' TK_ID
			{
				if (!($1.label == $7.label && $3.label == $5.label)) {
					                    yyerror("Troca inválida");
				}
                		Variavel v1 = getVariavel($1.label);
                		Variavel v2 = getVariavel($3.label);
                		if (v1.tipo != v2.tipo) {
                    			yyerror("Operação entre tipos inválidos (" + v1.tipo + ", " + v2.tipo + ")");
                		}
                		string temp_var = genTempCode(v1.tipo);
                		string l1 = "\t" + temp_var + " = " + v1.nome + ";\n";
                		string l2 = "\t" + v1.nome + " = " + v2.nome + ";\n";
                		string l3 = "\t" + v2.nome + " = " + temp_var + ";\n";
                		$$.traducao = l1 + l2 + l3;
			}
			// int A
			| TK_TIPO TK_ID
			{
				declararVariavel($2.label, $1.label);
			}
			// A = 2
			| TK_ID '=' E
			{
				Variavel v = getVariavel($1.label, true);
				bool found = v.id != "<error_id>";
				if (!found) {
					declararVariavel($1.label, $3.tipo);
					v = getVariavel($1.label);
				}
				$$.traducao = convertImplicit($1, $3, v);
			}
			// int A = 2
			| TK_TIPO TK_ID '=' E
			{
				declararVariavel($2.label, $1.label);
				Variavel v = getVariavel($2.label);
				$$.traducao = convertImplicit($2, $4, v);
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
				if ($1.label != "T" && $1.label != "F") {
					yyerror("valor booleano inválido");
				}

				$$.label = genTempCode("bool");
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				$$.tipo = "bool";
			}
			| TK_ID
			{
				Variavel v = getVariavel($1.label);
				$$.label = genTempCode(v.tipo);
				$$.traducao = "\t" + $$.label + " = " + v.id + ";\n";
				$$.tipo = v.tipo;
			}
			// print - PROVISÓRIO
			| TK_PRINT '(' TK_ID ')'
			{
				string mask;
				Variavel v = getVariavel($3.label);
				switch (v.tipo[0]) {
					case 'i':
					case 'b':
						mask = "%d";
						break;
					case 'f':
						mask = "%f";
						break;
					case 'c':
						mask = "%c";
						break;
				}
				$$.traducao = $3.traducao + "\tprintf(\"" + v.nome + ": " + mask + "\\n\", " + v.id + ");\n";
			}
			;

%%

#include "lex.yy.c"

int main(int argc, char* argv[])
{
	var_temp_qnt = 0;
	entrar_escopo();
	yyparse();
	sair_escopo();

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
