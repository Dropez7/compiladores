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
					"#include <stdlib.h>\n"
					"#include <time.h>\n"
					"#define bool int\n"
					"#define T 1\n"
					"#define F 0\n\n"
					"int main(void) {\n";
	if (wdUsed) {
		codigo += "\tunsigned long long int ulli;\n"
				  "\tulli = time(NULL);\n"
				  "\tsrand(ulli);\n";
	}
	for (const Variavel& var : variaveis) {
		if (var.nome == var.id.substr(1)) {
			codigo += "\t" + var.tipo + " " + var.id + ";\n";
		} else {
			codigo += "\t" + var.tipo + " " + var.id + "; // " + var.nome + "\n";
		}
	}
	
	codigo += "\n";
	codigo += traducao;
	for (const string& var : free_vars) {
		codigo += "\tfree(" + var + ");\n";
	}
	codigo += "\treturn 0;\n";
	codigo += "}";
	
	cout << codigo << endl;
}

%}


%token TK_NUM TK_REAL TK_CHAR TK_BOOL TK_STRING
%token TK_MAIN TK_ID TK_PRINT TK_INPUT
%token TK_TIPO TK_UNARIO TK_ABREVIADO
%token TK_IF TK_ELSE TK_LACO TK_DO
%token TK_BREAK TK_CONTINUE
%token TK_WHEELDECIDE TK_OPTION
%token TK_RELACIONAL


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

S : 		TK_MAIN '(' ')' BLOCO
			{
				genCodigo($4.traducao);
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
			// TODO: arrumar numero negativo
			/* | TK_LACO TK_ID E TK_POTOPOTO E BLOCO
            {
                if ($3.tipo != "int" || $5.tipo != "int") {
                    yyerror("range do for deve ser de números inteiros");
                }
                
                declararVariavel($2.label, "int");
                Variavel v = getVariavel($2.label);
                
                string inicio = genLabel();
                string fim = genLabel();
                string condicao = genTempCode("bool");
                string incremento = genTempCode("int");
                
                // Determina se é crescente ou decrescente  
                string temp_check = genTempCode("bool");
                string loop_crescente = genLabel();
                string loop_decrescente = genLabel();
                string check_decrescente = "\t" + temp_check + " = " + $3.label + " > " + $5.label + ";\n";
                
                $$.traducao = $3.traducao + $5.traducao + check_decrescente +
                    "\t" + v.id + " = " + $3.label + ";\n" +
                    "\tif (" + temp_check + ") goto " + loop_decrescente + ";\n" +
                    
                    // Loop crescente
                    loop_crescente + ":\n" +
                    "\t" + condicao + " = " + v.id + " <= " + $5.label + ";\n" +
                    "\tif (!" + condicao + ") goto " + fim + ";\n" +
                    $6.traducao +
                    "\t" + incremento + " = " + v.id + " + 1;\n" +
                    "\t" + v.id + " = " + incremento + ";\n" +
                    "\tgoto " + loop_crescente + ";\n" +
                    
                    // Loop decrescente  
                    loop_decrescente + ":\n" +
                    "\t" + condicao + " = " + v.id + " >= " + $5.label + ";\n" +
                    "\tif (!" + condicao + ") goto " + fim + ";\n" +
                    $6.traducao +
                    "\t" + incremento + " = " + v.id + " - 1;\n" +
                    "\t" + v.id + " = " + incremento + ";\n" +
                    "\tgoto " + loop_decrescente + ";\n" +
                    
                    fim + ":\n";
            } */
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
					$$.tamanho = to_string(stoi($1.tamanho) + stoi($3.tamanho));
					free_vars.insert($$.label);
				} else {
					makeOp($$, $1, $2, $3);	
				}
			} 
			| E '-' E { makeOp($$, $1, $2, $3);} | E '*' E {makeOp($$, $1, $2, $3);} | E '/' E {makeOp($$, $1, $2, $3);}
			| E TK_RELACIONAL E
			{
				$$.label = genTempCode("bool");
				if ($1.tipo == "char" || $1.tipo == "char*" || $1.tipo == "bool") {
					yyerror("operação indisponível para tipo " + $1.tipo);
				}
				if ($3.tipo == "char" || $3.tipo == "char*" || $3.tipo == "bool") {
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
				declararVariavel($2.label, $1.label,"");
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
			| TK_CHAR
			{
				std::string s = $1.label;
				// replace " with '
				std::replace(s.begin(), s.end(), '\"', '\'');


				$$.label = genTempCode("char");
				$$.traducao = "\t" + $$.label + " = " + s + ";\n";
				$$.tipo = "char";
			}
			| TK_STRING
			{
				string s = $1.label;
				// remove quotes
				s = s.substr(1, s.length() - 2);
				$$.tamanho = to_string(s.length()); 
				$$.label = genTempCode("char*");
				$$.traducao = "\t" + $$.label + " = malloc(" + to_string((s.length() + 1) * sizeof(char)) + ");\n"
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
				$$.label = genTempCode(v.tipo);
				$$.traducao = "\t" + $$.label + " = " + v.id + ";\n";
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
			| TK_TIPO TK_ID '=' TK_INPUT '(' OPTIONAL ')'
			{
                if ($1.tipo == "string") {
                    // Para strings, precisamos alocar dinamicamente
                    declararVariavel($2.label, $1.tipo, "256");
                    Variavel v = getVariavel($2.label);
                    
                    string buffer = genTempCode("char*");
                    string tamanho = genTempCode("int");
					string cond = genTempCode("bool");
					string l1 = genLabel();
                    
                    $$.traducao = $6.traducao +
                        "\t" + buffer + " = malloc(256);\n" +  // Buffer temporário
                        "\tfgets(" + buffer + ", 256, stdin);\n" +             // Lê até 255 chars + \0
                        len(buffer, tamanho, cond, l1) + 
                        "\t" + v.id + " = malloc(" + tamanho + ");\n" +  // Aloca tamanho exato
                        "\tstrcpy(" + v.id + ", " + buffer + ");\n" +          // Copia string
                        "\tfree(" + buffer + ");\n";                          // Libera buffer temporário
                    
                    // Marca a variável para ser liberada no final
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

				declararVariavel($2.label, $1.label, "0");
				Variavel v = getVariavel($2.label);
				$$.traducao = $2.traducao + $6.traducao + "\tscanf(\"" + mask + "\", &" + v.id + ");\n";
				}

			}
			| TK_PRINT '(' ARGS ')'
			{
				$$.traducao = $3.traducao + "\tprintf(\"\\n\");\n";
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
ARGS:       E ',' ARGS
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
