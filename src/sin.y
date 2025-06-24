%{
#include <iostream>
#include <string>
#include <sstream>
#include <set>
#include <algorithm>
#include "src/utils.hpp"

void genCodigo(string traducao) {
	string func = genStringcmp();
	string codigo = "/*Compilador MAPHRA*/\n"
					"#include <string.h>\n"
					"#include <stdio.h>\n"
					"#include <stdlib.h>\n"
					"#include <time.h>\n"
					"#define bool int\n"
					"#define T 1\n"
					"#define F 0\n\n";
	// define os protótipos de todas as funções
	// torna redundante a ordem de definição
	for (const Funcao& func : funcoes) {
			codigo += func.prototipo;
	}
	codigo += "\n";
	// declara todas as variáveis como globais
	// facilita o gerenciamento de memória
	for (const Variavel& var : variaveis) {
		if (var.nome == var.id.substr(1)) {
			codigo += "" + var.tipo + " " + var.id + ";\n";
		} else {
			codigo += "" + var.tipo + " " + var.id + "; // " + var.nome + "\n";
		}
	}
	
	codigo += "\n" + func + "\n" + traducao;
	
	cout << codigo << endl;
}

%}


%token TK_NUM TK_REAL TK_BOOL TK_STRING
%token TK_MAIN TK_ID TK_PRINT TK_INPUT
%token TK_TIPO TK_UNARIO TK_ABREVIADO
%token TK_RELACIONAL
%token TK_IF TK_ELSE TK_LACO TK_DO
%token TK_SWITCH TK_DEFAULT
%token TK_BREAK TK_CONTINUE
%token TK_WHEELDECIDE TK_OPTION
%token TK_FUNCAO TK_RETURN TK_NULL
%token T_LBRACKET T_RBRACKET

%start S

%right '='
%right TK_UNARIO
%right TK_ABREVIADO
%left '?'
%left '^'
%left TK_RELACIONAL
%left '+' '-'
%left '*' '/'
%right '~'
%nonassoc '(' ')'


%%

S : 		FUNCOES
			{
				genCodigo($1.traducao);
			}
			;
FUNCOES  :  FUNCAO FUNCOES
			{
				$$.traducao = $1.traducao + $2.traducao;
			}
			|
			{
				$$.traducao = "";
			}
			;
FUNCAO:     TK_FUNCAO TK_MAIN '(' ')' { setReturn("main"); } BLOCO
			{
				$$.traducao += "int main(void) {\n";
				if (wdUsed) {
					$$.traducao += "\tunsigned long long int ulli;\n"
								   "\tulli = time(NULL);\n"
								   "\tsrand(ulli);\n";
				}
				$$.traducao += $6.traducao + "END:\n";
				for (const string& var : free_vars) {
					$$.traducao += "\tfree(" + var + ");\n";
				}
				$$.traducao += "\treturn 0;\n}";
			}
			| TK_FUNCAO TK_ID { entrar_escopo(); } '(' ARGS ')' TIPO BLOCO
			{
				declararFuncao($2, $5.tipo, $7.label);
				Funcao f = getFuncao($2.label, $5.tipo);
				if (!hasReturned) {
					yyerror("função " + $2.label + " não possui retorno");
				}
				if ($7.label == "void") {
					$$.traducao = $7.label + " " + f.id + "(" + $5.traducao + $8.traducao + "}\n\n";
				} else {
					$$.traducao = $7.label + " " + f.id + "(" + $5.traducao + $8.traducao + "}\n\n";
				}
				hasReturned = false; // reseta o retorno 
			}
			;
TIPO        :  ':' TK_TIPO { setReturn($2.tipo); }
			{
				$$ = $2;
			}
			|
			{
				setReturn("void");
				$$.label = "void";
			}
			;
ARGS 		: TK_TIPO TK_ID ',' ARGS
			{
				declararVariavel($2.label, $1.label, "");
				Variavel v = getVariavel($2.label);
				$$.tipo = v.tipo + " " + $4.tipo; // multiplos tipos
				$$.traducao = v.tipo + " " + v.id + ", " + $4.traducao;
			}
			| TK_TIPO TK_ID
			{
				declararVariavel($2.label, $1.label, "");
				Variavel v = getVariavel($2.label);
				$$.tipo = v.tipo;
				$$.traducao = v.tipo + " " + v.id + ") {\n";
			}
			|
			{
				$$.tipo = "";
				$$.traducao = ") {\n";
			}
			;
CALL_ARGS   : E ',' CALL_ARGS
			{
				$$.tipo = $1.tipo + " " + $3.tipo; // multiplos tipos
				$$.traducao = $1.label + ", " + $3.traducao;
			}
			| E
			{
				$$.tipo = $1.tipo;
				$$.traducao = $1.label + ");\n";
			}
			|
			{
				$$.tipo = "";
				$$.traducao = ");\n";
			}
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
				$$.traducao = $2.traducao + "\tif (!" + $2.label + ") goto " + label + ";\n" + $3.traducao + label + ":\n";
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
			| TK_WHEELDECIDE '{' { genWDargs(); } BLOCO_DECIDE '}'
			{
				WDarg wd = pilha_wd.back();
				string cond = genTempCode("bool");
				string random = genTempCode("int");
				
				string meio = "\t" + cond + " = " + wd.count + " != 0;\n"
				+ "\tif (!" + cond + ") goto " + wd.label + ";\n"
				+ "\t" + random + " = rand();\n"
				+ "\t" + wd.choice + " = " + random + " % " + wd.count + ";\n";
				for (int i = 2; i <= wd.nCLAUSES; i++) {
					// remove todos os placeholders exceto o primeiro
					$4.traducao = replace($4.traducao, "placeholder" + to_string(i), "");
				}
				// adiciona o meio logo após a checagem das cláusulas,
				// caso todas elas sejam falsas, pula pro final
				$4.traducao = replace($4.traducao, "placeholder1", meio);
				$$.traducao = "\t" + wd.guards + " = malloc(" + to_string(wd.nCLAUSES * 4) + ");\n"
				+ zerarVetor(wd.guards, wd.nCLAUSES) + "\t" + wd.count + " = 0;\n"
				+ $4.traducao + wd.label + ":\n\tfree(" + wd.guards + ");\n";
				delWDargs();
			}
			| TK_DO TK_WHEELDECIDE '{' { genWDargs(); } BLOCO_DECIDE '}'
			{
				canBreak = false; // não tem sentido esse laço possuir continue
				WDarg wd = pilha_wd.back();
				string cond = genTempCode("bool");
				string random = genTempCode("int");
				string fim = genLabel();

				string meio = "\t" + cond + " = " + wd.count + " != 0;\n"
				+ "\tif (!" + cond + ") goto " + fim + ";\n"
				+ "\t" + random + " = rand();\n"
				+ "\t" + wd.choice + " = " + random + " % " + wd.count + ";\n";
				for (int i = 2; i <= wd.nCLAUSES; i++) {
					// remove todos os placeholders exceto o primeiro
					$5.traducao = replace($5.traducao, "placeholder" + to_string(i), "");
				}
				$5.traducao = replace($5.traducao, "placeholder1", meio);
				$5.traducao = replace($5.traducao, "BREAK", fim); // adiciona os breaks se existirem
				$$.traducao = "\t" + wd.guards + " = malloc(" + to_string(wd.nCLAUSES * 4) + ");\n"
				+ zerarVetor(wd.guards, wd.nCLAUSES) + wd.label + ":\n\t" + wd.count + " = 0;\n"
				+ $5.traducao + fim + ":\n\tfree(" + wd.guards + ");\n";
				delWDargs();
			}
			| TK_LACO E BLOCO
			{
				canBreak = false;
				canContinue = false;
				if ($2.tipo != "bool") {
					yyerror("condição deve ser do tipo booleano");
				}
				string inicio = genLabel();
				string fim = genLabel();
				$3.traducao = replace($3.traducao, "CONTINUE", inicio);
				$3.traducao = replace($3.traducao, "BREAK", fim);
				$$.traducao = inicio + ":\n" + $2.traducao +  "\tif (!" + $2.label + ") goto " + fim + ";\n" +
					$3.traducao + "\tgoto " + inicio + ";\n" +
					fim + ":\n"; 
			}
			| TK_DO BLOCO TK_LACO E
			{
				canBreak = false;
				canContinue = false;
				if ($4.tipo != "bool") {
					yyerror("condição deve ser do tipo booleano");
				}
				string inicio = genLabel();
				string fim = genLabel();
				$2.traducao = replace($2.traducao, "CONTINUE", inicio);
				$2.traducao = replace($2.traducao, "BREAK", fim);
				$$.traducao = inicio + ":\n" + $2.traducao + $4.traducao + "\tif (!" + $4.label + ") goto " + fim + ";\n" +
					$3.traducao + "\tgoto " + inicio + ";\n" +
					fim + ":\n";
			}
			| TK_LACO '(' E ';' E ';' E ')' BLOCO
            {
				canBreak = false;
				canContinue  = false;
				if ($3.traducao.find("implicitamente") == string::npos) {
			        yyerror("Variável '" + $3.label + "' já declarada neste escopo.");
				}
				
				if ($5.tipo != "bool") {
                    yyerror("condição deve ser do tipo booleano");
                }
                string inicio = genLabel();
                string fim = genLabel();
				$9.traducao = replace($9.traducao, "CONTINUE", inicio);
				$9.traducao = replace($9.traducao, "BREAK", fim);
                $$.traducao = $3.traducao + 
                    inicio + ":\n" + $5.traducao + "\tif (!" + $5.label + ") goto " + fim + ";\n" +
                    $9.traducao + $7.traducao + "\tgoto " + inicio + ";\n" +
                    fim + ":\n";
            }
			| TK_SWITCH E '{' BLOCO_SWITCH '}'
			{
				if ($4.tipo != "" && $4.tipo != $2.tipo) {
					yyerror("tipo da expressão do switch deve ser igual ao tipo dos cases");
				}
				auto conds = split($4.traducao, "\nCONDICOES\n");
				// reorganiza o vetor de tras pra frente
				reverse(conds.begin(), conds.end());
				// coloca o ultimo elemento no inicio
				conds.insert(conds.begin(), conds.back());
				conds.pop_back();
				// cria uma string com as condições
				string condicoes = "";
				for (const string& cond : conds) {
					if (cond != "") {
						condicoes += cond;
					}
				}				

				$4.traducao = condicoes;
				string fim = genLabel();
				$4.traducao = replace($4.traducao, "TEMP", $2.label);
				$4.traducao = replace($4.traducao, "SWITCH_END", fim);
				$4.traducao = replace($4.traducao, "BREAK", fim);
				$$.traducao = $2.traducao + $4.traducao + fim + ":\n";
			}
            ;
BLOCO_SWITCH: TK_OPTION E ':' COMANDOS BLOCO_SWITCH
            {
                $$.tipo = $2.tipo;
                if ($5.traducao != "" && $2.tipo != $5.tipo && $5.tipo != "dafoe") {
                    yyerror("tipo do case deve ser igual ao tipo do switch");
                }
                string label = genLabel();
                string cond = genTempCode("bool");
				if ($5.tipo == "dafoe") {
					$$.traducao = $2.traducao + "\t" + cond + " = " + $2.label + " == TEMP;\n\tif (" + cond + ") goto " 
					+ label + ";\n" + $5.traducao + "\nCONDICOES\n" + label + ":\n"+ $4.traducao;
				} else if ($2.tipo == "char*") {
					$$.traducao = $2.traducao + "\t" + cond + " = stringcmp(" + $2.label + ", TEMP);\n\tif (" + cond + ") goto " 
					+ label + ";\n" + $5.traducao + "\nCONDICOES\n" + label + ":\n"+ $4.traducao;
				
				} else {
					$$.traducao = $2.traducao + "\t" + cond + " = " + $2.label + " == TEMP;\n\tif (" + cond + ") goto " 
					+ label + ";\n" + $5.traducao + "\nCONDICOES\n" + label + ":\n"+ $4.traducao;
				}
            }
            | TK_DEFAULT ':' COMANDOS
            {
				$$.tipo = "dafoe";
                $$.traducao = $3.traducao + "\tgoto SWITCH_END;\n";
            }
            | // sumidouro
            {
                $$.traducao = "";
            }
            ;
BLOCO_DECIDE: TK_OPTION E COMANDO BLOCO_DECIDE
			{
				if ($2.tipo != "bool") {
					yyerror("condição deve ser do tipo booleano");
				}

				WDarg& wd = pilha_wd.back();
				wd.nCLAUSES++;
				string fim1 = genLabel();
				string cond = genTempCode("bool");
				string fim2 = genLabel();
				$$.traducao = $2.traducao + "\tif(!" + $2.label +") goto " + fim1 + ";\n\t" 
				+ wd.guards + "[" + wd.count + "] = " + to_string(wd.nCLAUSES) + ";\n\t" 
				+ wd.count + " = " + wd.count + "+ 1;\n\t" 
				+ fim1 + ":\n" + $4.traducao + "placeholder" + to_string(wd.nCLAUSES) + "\t" 
				+ cond + " = " + wd.guards + "[" + wd.choice + "] == " + to_string(wd.nCLAUSES) 
				+ ";\n\tif(!" + cond + ") goto " + fim2 + ";\n" + $3.traducao
				+ "\tgoto " + wd.label + ";\n" + fim2 + ":\n";
				
			}
			| // sumidouro
			;
E 			: BLOCO
			{
				$$.traducao = $1.traducao;
			}
			| E '+' E
			{
				if ($1.tipo == "char*" && $3.tipo == "char*") {
					$$.label = genTempCode("char*");
					string x0 = genTempCode("int");
					string x1 = genTempCode("int");
					string x2 = genTempCode("int");
					string x3 = genTempCode("int");
					string x4 = genTempCode("char*");
					$$.traducao = $1.traducao + $3.traducao 
						+ "\t" + x0 + " = " + $1.tamanho + ";\n" //x0 = len(string)
						+ "\t" + x1 + " = " + $3.tamanho + ";\n" // x1 = len(string)
						+ "\t" + x2 + " = " + x0 + " + " + x1 + ";\n"  // x2 = x0 + x1
						+ "\t" + x3 + " = " + x2 + " + 1;\n"           // x3 = x2 + 1
						+ "\t" + x4 + " = malloc(" + x3 + ");\n"       // x4 = malloc(x3)
						+ "\tstrcpy(" + x4 + ", " + $1.label + ");\n"  // strcpy(x4, s1.id)
						+ "\tstrcat(" + x4 + ", " + $3.label + ");\n"  // strcat(x4, s2.id)
						+ "\t" + $$.label + " = " + x4 + ";\n";        // s1.id = x4
					$$.tipo = "char*";
					if (isInteger($1.tamanho) && isInteger($3.tamanho)) {
						$$.tamanho = to_string(stoi($1.tamanho) + stoi($3.tamanho));
					} else { // se um deles não é inteiro, a variável foi obtida pelo input()
						$$.tamanho = x3; // por acaso x3 já possuí o tamanho das 2 strings
					}
					free_vars.insert($$.label);
				} else {
					makeOp($$, $1, $2, $3);	
				}
			} 
			| E '-' E { makeOp($$, $1, $2, $3);} | E '*' E {makeOp($$, $1, $2, $3);} | E '/' E {makeOp($$, $1, $2, $3);}
			| E TK_RELACIONAL E
			{
				$$.label = genTempCode("bool");
				if ($1.tipo == "char*" && $3.tipo == "char*" && $2.label == "==") {
					$$.traducao = $1.traducao + $3.traducao + 
						"\t" + $$.label + " = stringcmp(" + $1.label + ", " + $3.label + ");\n";
				} else if ($1.tipo == "char*" && $3.tipo == "char*" && $2.label == "!=") {
					$$.traducao = $1.traducao + $3.traducao + 
						"\t" + $$.label + " = stringcmp(" + $1.label + ", " + $3.label + ");\n" +
						"\t" + $$.label + " = !" + $$.label + ";\n";
				} else {
					if ($1.tipo == "char*" || $1.tipo == "bool") {
						yyerror("operação indisponível para tipo " + $1.tipo);
					}
					if ($3.tipo == "char*" || $3.tipo == "bool") {
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
				$$.tipo = "bool";
			}
			| TK_ID TK_UNARIO
			{
				string op = $2.label.substr(0, 1);
				Variavel v = getVariavel($1.label);
				$$.traducao = $1.traducao + "\t" + v.id + " = " + v.id + " " + op + " 1;\n";
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
                		string l1 = "\t" + temp_var + " = " + v1.id + ";\n";
                		string l2 = "\t" + v1.id + " = " + v2.id + ";\n";
                		string l3 = "\t" + v2.id + " = " + temp_var + ";\n";
                		$$.traducao = l1 + l2 + l3;
			}
			// int A
			| TK_TIPO TK_ID
			{
				declararVariavel($2.label, $1.label, "");
			}
			// A = 2
			| TK_ID '=' E
			{
				Variavel v = getVariavel($1.label, true);
				bool found = v.id != "<error_id>";
				string msg = (found) ? "\n" : " // variável " + $1.label + " declarada implicitamente\n";
				if (!found) {
					declararVariavel($1.label, $3.tipo, $3.tamanho);
					v = getVariavel($1.label);
				}
				string traducao = convertImplicit($1, $3, v);
				$$.traducao = traducao.substr(0, traducao.length() - 1) + msg;
			}
			// int A = 2
			| TK_TIPO TK_ID '=' E
			{
				declararVariavel($2.label, $1.label, $4.tamanho);
				Variavel v = getVariavel($2.label);
				$$.traducao = convertImplicit($2, $4, v);
			}
			| TK_ID TK_ABREVIADO E
			{
				Variavel v = getVariavel($1.label);
				if (v.tipo != $3.tipo) {
					yyerror("Operação entre tipos inválidos (" + v.tipo + ", " + $3.tipo + ")");
				}
				string op = $2.label.substr(0, 1);
				$$.traducao = $1.traducao + $3.traducao + "\t" + v.id + " = " + v.id + " " + op + " " + $3.label + ";\n";
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
			| TK_STRING
			{
				string s = $1.label;
				// remove quotes
				s = s.substr(1, s.length() - 2);
				$$.tamanho = to_string(s.length()); 
				$$.label = genTempCode("char*");
				$$.traducao = "\t" + $$.label + " = malloc(" + to_string((s.length() + 1)) + ");\n"
					+ "\tstrcpy(" + $$.label + ", \"" + s + "\");\n";
				$$.tipo = "char*";
				free_vars.insert($$.label); // marca para liberar memória
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
				$$.label = v.id;
				$$.tipo = v.tipo;
				$$.tamanho = v.tamanho;
			}
			| TK_BREAK
			{
				if (canBreak) {
					$$.traducao = "\tgoto BREAK;\n";
				} else {
					yyerror("break fora de laço");
				}
			}
			| TK_CONTINUE
			{
				if (canContinue) {
					$$.traducao = "\tgoto CONTINUE;\n";
				} else {
					yyerror("continue fora de laço");
				}
			}
			| TK_ID '(' CALL_ARGS ')'
			{
				if ($1.label == "main") {
					yyerror("função main não pode ser chamada");
				}

				Funcao f = getFuncao($1.label, $3.tipo);
				if (f.tipo_retorno != "void") {
					$$.label = genTempCode(f.tipo_retorno);
					$$.traducao = "\t" + $$.label + " = " + f.id + "(" + $3.traducao;
					$$.tipo = f.tipo_retorno;
				} else {
					$$.tipo = "void";
					$$.traducao = "\t" + f.id + "(" + $3.traducao;
				}
			}
			// int A = input()
			| TK_TIPO TK_ID '=' TK_INPUT '(' OPTIONAL ')'
			{
                if ($1.tipo == "string") {
					string tamanho = genTempCode("int");
                    string buffer = genTempCode("char*");
					string cond = genTempCode("bool");
					string l1 = genLabel();
                    
                    // como não sabemos o tamanho, o tamanho é a própria variável 'tamanho' que será calculada
                    declararVariavel($2.label, $1.tipo, tamanho);
                    Variavel v = getVariavel($2.label);
                    
                    $$.traducao = $6.traducao +
                        "\t" + buffer + " = malloc(256);\n" + 
                        "\tfgets(" + buffer + ", 256, stdin);\n" +
                        len(buffer, tamanho, cond, l1) + 
                        "\t" + v.id + " = malloc(" + tamanho + ");\n" +
                        "\tstrcpy(" + v.id + ", " + buffer + ");\n" +
                        "\tfree(" + buffer + ");\n";
                    
                    free_vars.insert(v.id);
                } else {				
					string mask;
					switch ($1.tipo[0]) {
						case 'i':
							mask = "%d";
							break;
						case 'f':
							mask = "%f";
							break;
						case 'c':
							mask = "%c";
					}

					declararVariavel($2.label, $1.label, "");
					Variavel v = getVariavel($2.label);
					$$.traducao = $2.traducao + $6.traducao + "\tscanf(\"" + mask + "\", &" + v.id + ");\n";
				}

			}
			// A = input()
			| TK_ID '=' TK_INPUT '(' OPTIONAL ')'
			{
                if ($1.tipo == "string") {
					string tamanho = genTempCode("int");
                    string buffer = genTempCode("char*");
					string cond = genTempCode("bool");
					string l1 = genLabel();
                    
                    Variavel v = getVariavel($2.label);
					updateTamanho(v.nome, tamanho);
                    
                    $$.traducao = $5.traducao +
                        "\t" + buffer + " = malloc(256);\n" + 
                        "\tfgets(" + buffer + ", 256, stdin);\n" +
                        len(buffer, tamanho, cond, l1) + 
                        "\t" + v.id + " = malloc(" + tamanho + ");\n" +
                        "\tstrcpy(" + v.id + ", " + buffer + ");\n" +
                        "\tfree(" + buffer + ");\n";
                    
                    free_vars.insert(v.id);
                } else {				
					string mask;
					switch ($1.tipo[0]) {
						case 'i':
							mask = "%d";
							break;
						case 'f':
							mask = "%f";
							break;
						case 'c':
							mask = "%c";
					}

					Variavel v = getVariavel($2.label);
					$$.traducao = $1.traducao + $5.traducao + "\tscanf(\"" + mask + "\", &" + v.id + ");\n";
				}

			}
			| TK_PRINT '(' PRINT_ARGS ')'
			{
				$$.traducao = $3.traducao + "\tprintf(\"\\n\");\n";
			}
			| TK_RETURN TK_NULL
			{
				string type = getReturn();
				if (type == "void") {
					$$.traducao = "\treturn;\n";
				} else if (type == "main") {
					$$.traducao = "\tgoto END;\n";
				} else if (type == "int" || type == "bool") {
					$$.traducao = "\treturn 0;\n";
				} else if (type == "float") {
					$$.traducao = "\treturn 0.0;\n";
				} else if (type == "string") {
					$$.traducao = "\treturn '\\0';\n";
				}
			}
			| TK_RETURN E
			{
				if ($2.tipo != getReturn()) {
					yyerror("tipo de retorno errado (esperado: " + getReturn() + ", recebido: " + $2.tipo + ")");
				}
				$$.traducao = $2.traducao + "\treturn " + $2.label + ";\n";
			}
			// Arrays e Vetores - Estáticos
			| TK_TIPO TK_ID lista_dimensoes
			{
				string nome_var = $2.label;
				string tipo_base = ($1.tipo == "string") ? "char" : $1.tipo;

				// define tipo como int*, int**, etc.
				string tipo_var = tipo_base + string($3.dimensoes.size(), '*');

				// calcula o total de elementos para eventual inicialização
				int total_size = 1;
				string tamanho_str = "";
				for (size_t i = 0; i < $3.dimensoes.size(); ++i) {
					total_size *= $3.dimensoes[i];
					tamanho_str += (i == 0 ? "" : "*") + to_string($3.dimensoes[i]);
				}

				declararVariavel(nome_var, tipo_var, tamanho_str);

				Variavel v = getVariavel(nome_var);

				string initCode = gerarAlocacaoRecursiva(v.id, tipo_base, $3.dimensoes);

				$$ = $2;
				$$.traducao = initCode;
			}
			| acesso_vetor
			| acesso_vetor '=' E {
				 
				// O tipo do elemento do vetor (ex: "int")
				string tipo_destino = $1.tipo; 
				
				// O tipo da expressão à direita (ex: "int" ou "float")
				string tipo_origem = $3.tipo; 
				
				// A variável temporária ou constante da expressão (ex: "t10" ou "100")
				string rhs_label = $3.label;

				// Se os tipos são diferentes, verifica se a conversão implícita é possível
				if (tipo_destino != tipo_origem)
				{
					// Usa a função que você já tem em utils.hpp
					if (checkIsPossible(tipo_destino, tipo_origem))
					{
						// Adiciona um cast na geração do código, se necessário
						rhs_label = "(" + tipo_destino + ") " + $3.label;
					}
					else
					{
						yyerror("atribuição incompatível (esperando " + tipo_destino + ", recebeu " + tipo_origem + ")");
					}
				}

				// 2. Geração de Código
				// A tradução final é:
				// - O código para calcular os índices (já em $1.traducao)
				// - O código para calcular a expressão (já em $3.traducao)
				// - A nova linha de atribuição
				$$.traducao = $1.traducao + $3.traducao + "\t" + $1.label + " = " + rhs_label + ";\n";
			}

			| TK_TIPO TK_ID T_LBRACKET T_RBRACKET ';' // Adicionei o ';' que provavelmente faltava
			{
				// 1. O tipo base é o que vem do token (ex: "int")
				string tipo_base = $1.label;
				declararVariavel($2.label, tipo_base, "");

				// 2. Busca a variável que acabamos de criar e a marca como dinâmica
				Variavel& v = pilha_escopos.back()[$2.label];
				v.ehDinamico = true;

				// 3. Adiciona a DEFINIÇÃO da struct Vetor ao cabeçalho (APENAS UMA VEZ)
				if (!definicao_vetor_impressa) {
					cabecalho_global += "struct Vetor {\n";
					cabecalho_global += "\tvoid* data;\n";
					cabecalho_global += "\tint tamanho;\n";
					cabecalho_global += "\tint capacidade;\n";
					cabecalho_global += "\tsize_t tam_elemento;\n};\n\n";
					definicao_vetor_impressa = true;
				}

				// 4. Gera o código de INICIALIZAÇÃO da variável
				$$.traducao = "\tstruct Vetor " + v.id + ";\n";
				$$.traducao += "\t" + v.id + ".tamanho = 0;\n";
				$$.traducao += "\t" + v.id + ".capacidade = 0;\n";
				$$.traducao += "\t" + v.id + ".data = NULL;\n";
				$$.traducao += "\t" + v.id + ".tam_elemento = sizeof(" + tipo_base + ");\n";
			}
			;

lista_dimensoes: lista_dimensoes T_LBRACKET TK_NUM T_RBRACKET
			{
				$$ = $1;
				int dim = stoi($3.label);
				if (dim <= 0) yyerror("Dimensão inválida em vetor.");
				$$.dimensoes.push_back(dim);
			}
			| T_LBRACKET TK_NUM T_RBRACKET
			{
				int dim = stoi($2.label);
				if (dim <= 0) yyerror("Dimensão inválida em vetor.");
				$$.dimensoes = vector<int>{dim};
			};

acesso_vetor:  TK_ID T_LBRACKET E T_RBRACKET
			{
				// 1. Busca a variável (ex: 'matriz') na tabela de símbolos.
				Variavel v = getVariavel($1.label);

				// 2. Validação Semântica
				if (v.tipo.find("*") == string::npos) {
					yyerror("variável '" + v.nome + "' não é um vetor/ponteiro.");
				}
				if ($3.tipo != "int") {
					yyerror("índice do vetor deve ser um inteiro.");
				}

				// 3. Geração de Código
				// O label resultante é o próprio acesso em C.
				$$.label = v.id + "[" + $3.label + "]";

				// A tradução acumula o código gerado pela expressão do índice.
				$$.traducao = $1.traducao + $3.traducao;

				// 4. Determina o tipo resultante. Se era int***, agora é int**.
				string tipo_resultante = v.tipo;
				tipo_resultante.pop_back(); // Remove um '*'
				$$.tipo = tipo_resultante;
			}
			| acesso_vetor T_LBRACKET E T_RBRACKET
			{
				// 1. '$1' já contém os dados do acesso anterior (ex: 'matriz[i]').

				// 2. Validação Semântica
				if ($1.tipo.find("*") == string::npos) {
					yyerror("tentativa de indexar uma variável que não é vetor/ponteiro.");
				}
				if ($3.tipo != "int") {
					yyerror("índice do vetor deve ser um inteiro.");
				}

				// 3. Geração de Código
				// Concatena o novo acesso ao label anterior.
				$$.label = $1.label + "[" + $3.label + "]";

				// A tradução acumula o código gerado.
				$$.traducao = $1.traducao + $3.traducao;

				// 4. Determina o tipo resultante. Se era int**, agora é int*.
				string tipo_resultante = $1.tipo;
				tipo_resultante.pop_back(); // Remove um '*'
				$$.tipo = tipo_resultante;
			}
			;
OPTIONAL:   E
			{
				if ($1.tipo != "char*") {
					yyerror("mensagem deve ser do tipo string");
				}
				$$.traducao = $1.traducao + "\tprintf(\"%s\", " + $1.label + ");\n";
			}
			| /* vazio */
			{	
				$$.traducao = "";
			}
			; 
PRINT_ARGS:       E ',' PRINT_ARGS
			{
				if ($1.tipo == "char*") {
					$$.traducao = $1.traducao + "\tprintf(\"%s\", " + $1.label 
					+ ");\n\tprintf(\" \");\n";
				} else if ($1.tipo == "bool") {
					string tmp = genTempCode("bool");
					string l1 = genLabel();
					string l2 = genLabel();
					$$.traducao = $1.traducao + "\t" + tmp + " = " + $1.label + " == 1;\n"
					+ "\tif (!" + tmp + ") goto " + l1 + ";\n\tprintf(\"T \");\n\tgoto " + l2 
					+ ";\n" + l1 + ":\n\tprintf(\"F \");\n" + l2 + ":\n";
				} else {
					string mask;
					switch ($1.tipo[0]) {
					case 'i':
						mask = "%d";
						break;
					case 'f':
						mask = "%f";
						break;
					case 'c':
						mask = "%c";
					}
					$$.traducao = $1.traducao + "\tprintf(\"" + mask + "\", " + $1.label 
					+ ");\n\tprintf(\" \");\n"; 
				}
				$$.traducao = $$.traducao + $3.traducao;
			}
			| E
			{
				if ($1.tipo == "char*") {
					$$.traducao = $1.traducao + "\tprintf(\"%s\", " + $1.label + ");\n";
				} else if ($1.tipo == "bool") {
					string tmp = genTempCode("bool");
					string l1 = genLabel();
					string l2 = genLabel();
					$$.traducao = $1.traducao + "\t" + tmp + " = " + $1.label + " == 1;\n"
					+ "\tif (!" + tmp + ") goto " + l1 + ";\n\tprintf(\"T\");\n\tgoto " + l2 
					+ ";\n" + l1 + ":\n\tprintf(\"F\");\n" + l2 + ":\n";
				} else {
					string mask;
					switch ($1.tipo[0]) {
					case 'i':
					case 'b':
						mask = "%d";
						break;
					case 'f':
						mask = "%f";
						break;
					case 'c':
						mask = "%c";
					}
					$$.traducao = $1.traducao + "\tprintf(\"" + mask + "\", " + $1.label + ");\n"; 
				}
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
