%{
#include <iostream>
#include <string>
#include <sstream>
#include <set>
#include <algorithm>
#include "src/utils.hpp"

void genCodigo(string traducao) {
    // Cabeçalho padrão do C
    string codigo = "/*Compilador MAPHRA*/\n"
                  "#include <string.h>\n"
                  "#include <stdio.h>\n"
                  "#include <stdlib.h>\n"
                  "#include <time.h>\n"
                  "#define bool int\n"
                  "#define T 1\n"
                  "#define F 0\n\n";

    // Adiciona a definição da "struct Vetor" que foi gerada pelo parser
	if (vectorUsed) {
		codigo += structVetor;
	}

	// Declarações de structs
	for (const string& def : structDef) {
		codigo += def;
	}

	// Protótipos de Funções
    for (const Funcao& func : funcoes) {
        codigo += func.prototipo;
    }
    codigo += "\n";

    // Declarações de Variáveis Globais
    for (const Variavel& var : variaveis) {
        if (var.ehDinamico) {
            codigo += "struct Vetor " + var.id;
        } else {
            codigo += var.tipo + " " + var.id;
        }
		if (!isdigit(var.nome[0])) {
			 codigo += "; // " + var.nome + "\n";
		} else {
			codigo += ";\n";
		}
    }
    
    // Adiciona a função de comparação de string e o código traduzido
	if (strCompared) {
		codigo += "\n" + genStringcmp();
	}
    codigo += "\n" + traducao;
    
    // Imprime o código final
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
%token TK_FUNCAO TK_RETURN TK_NULL TK_STRUCT
%token TK_BIND TK_THIS
%token TK_APPEND

%start S

%right '='
%right TK_UNARIO
%right TK_ABREVIADO
%left '?'
%left '^'
%left TK_RELACIONAL
%left '.'
%left '+' '-'
%left '*' '/'
%right '~'
%nonassoc '(' ')'


%%

S : 		DECLARACOES
			{
				genCodigo($1.traducao);
			}
			;
DECLARACOES  :  FUNCAO DECLARACOES
			{
				$$.traducao = $1.traducao + $2.traducao;
			}
			| STRUCT DECLARACOES
			{
				$$.traducao = $1.traducao + $2.traducao;
			}
			|
			{
				$$.traducao = "";
			}
			;
STRUCT      : TK_STRUCT TK_ID '{' VAR_STRUCT '}'
			{
				declararStruct($2.label, $4.tipo);
				structDef.push_back("struct " + $2.label + " {\n" + $4.traducao + "};\n\n");
			}
			;
VAR_STRUCT   : TK_TIPO TK_ID VET ';' VAR_STRUCT
             {
                 $$.traducao = "\t" + $1.tipo + " " + $2.label + ";\n" + $5.traducao;
                 $$.tipo = $1.tipo + " " + $2.label + " " + $5.tipo; 
             }
             | TK_ID TK_ID VET ';' VAR_STRUCT
             {
                 TipoStruct ts = getStruct($1.label);
                 $$.traducao = "\t" + ts.id + " " + $2.label + ";\n" + $5.traducao;
                 $$.tipo = split(ts.id, " ")[1] + " " + $2.label + " " + $5.tipo;
             }
             | TK_TIPO TK_ID VET ';'
             {
                 $$.traducao = "\t" + $1.tipo + " " + $2.label + ";\n";
                 $$.tipo = $1.tipo + " " + $2.label;
             }
             | TK_ID TK_ID VET ';'
             {
                 TipoStruct ts = getStruct($1.label);
                 $$.traducao = "\t" + ts.id + " " + $2.label + ";\n";
                 $$.tipo = split(ts.id, " ")[1] + " " + $2.label;
             }
             ;
VET         : lista_colchetes_vazios
			{
				yyerror("vetores não são permitidos dentro de structs");
			}
			|
			{
				$$.traducao = "";
			}
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
				declararFuncao($2, $5.tipo, $7.label, $5.traducao);

				Funcao f = getFuncao($2.label, $5.tipo);
				if (!hasReturned) {
					yyerror("função " + $2.label + " não possui retorno");
				}
				if ($7.label == "void") {
					$$.traducao = $7.label + " " + f.id + "(" + $5.traducao + $8.traducao + "}\n\n";
				} else {
					$$.traducao = $7.label + " " + f.id + "(" + $5.traducao + $8.traducao + "}\n\n";
				}
				hasReturned = false; 
			}
			| TK_BIND TIPO_METODO TK_ID { entrar_escopo(); entrarMetodo($2.tipo); } '(' ARGS ')' TIPO BLOCO
			{
				string a = split(tipoMetodo, "|")[0];
				string b = split(tipoMetodo, "|")[1];
				$6.traducao = ($6.traducao == ") {\n") ? a + " " + b + $6.traducao : a + " " + b + ", " + $6.traducao;
				sairMetodo();
				declararMetodo($3, $2.tipo, $6.tipo, $8.label);
				Metodo m = getMetodo($3.label, $2.tipo, $6.tipo);
				if (!hasReturned) {
					yyerror("método " + $3.label + " não possui retorno");
				}

				if ($8.label == "void") {
					$$.traducao = $8.label + " " + m.id + "(" + $6.traducao + $9.traducao + "}\n\n";
				} else {
					$$.traducao = $8.label + " " + m.id + "(" + $6.traducao + $9.traducao + "}\n\n";
				}
			}
			;
TIPO_METODO: TK_TIPO
			{
				$$.tipo = $1.label;
			} 
			| TK_ID
			{
				TipoStruct ts = getStruct($1.label);
				$$.tipo = ts.id;
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
ARGS:        TK_TIPO TK_ID lista_colchetes_vazios ',' ARGS
             {
                 vectorUsed = true;
                 declararVariavel($2.label, $1.label, "", $3.nivelAcesso);
                 Variavel v = getVariavel($2.label);
                 $$.tipo = $1.label + "[] " + $5.tipo;
                 $$.traducao = "struct Vetor " + v.id + ", " + $5.traducao;
             }
             | TK_ID TK_ID lista_colchetes_vazios ',' ARGS
             {
                 vectorUsed = true;
                 TipoStruct ts = getStruct($1.label);
                 declararVariavel($2.label, ts.id, "", $3.nivelAcesso);
                 Variavel v = getVariavel($2.label);
                 $$.tipo = $1.label + "[] " + $5.tipo;
                 $$.traducao = "struct Vetor " + v.id + ", " + $5.traducao;
             }
             | TK_TIPO TK_ID lista_colchetes_vazios
             {
                 vectorUsed = true;
                 declararVariavel($2.label, $1.label, "", $3.nivelAcesso);
                 Variavel v = getVariavel($2.label);
                 $$.tipo = $1.label + "[]";
                 $$.traducao = "struct Vetor " + v.id + ") {\n";
             }
             | TK_ID TK_ID lista_colchetes_vazios
             {
                 vectorUsed = true;
                 TipoStruct ts = getStruct($1.label);
                 declararVariavel($2.label, ts.id, "", $3.nivelAcesso);
                 Variavel v = getVariavel($2.label);
                 $$.tipo = $1.label + "[]";
                 $$.traducao = "struct Vetor " + v.id + ") {\n";
             }
             | TK_TIPO TK_ID ',' ARGS
             {
                 declararVariavel($2.label, $1.label, "", 0);
                 Variavel v = getVariavel($2.label);
                 $$.tipo = v.tipo + " " + $4.tipo;
                 $$.traducao = v.tipo + " " + v.id + ", " + $4.traducao;
             }
             // NOVA REGRA: Parâmetro do tipo struct seguido por outros
             | TK_ID TK_ID ',' ARGS
             {
                TipoStruct ts = getStruct($1.label);
                declararVariavel($2.label, ts.id, "", 0);
                Variavel v = getVariavel($2.label);
                // Tipo para assinatura da função (ex: "Ponto")
                string sig_type = split(ts.id, " ")[1];
                $$.tipo = sig_type + " " + $4.tipo;
                // Tradução para C (ex: "struct Ponto t1, ...")
                $$.traducao = v.tipo + " " + v.id + ", " + $4.traducao;
             }
             | TK_TIPO TK_ID
             {
                 declararVariavel($2.label, $1.label, "", 0);
                 Variavel v = getVariavel($2.label);
                 $$.tipo = v.tipo;
                 $$.traducao = v.tipo + " " + v.id + ") {\n";
             }
             // NOVA REGRA: Parâmetro final do tipo struct
             | TK_ID TK_ID
             {
                 TipoStruct ts = getStruct($1.label);
                 declararVariavel($2.label, ts.id, "", 0);
                 Variavel v = getVariavel($2.label);
                 // Tipo para assinatura (ex: "Ponto")
                 $$.tipo = split(ts.id, " ")[1];
                 // Tradução para C (ex: "struct Ponto t2) {\n")
                 $$.traducao = v.tipo + " " + v.id + ") {\n";
             }
             ;
CALL_ARGS   : E ',' CALL_ARGS
			{
				$$.tipo = $1.tipo + " " + $3.tipo; // multiplos tipos
				$$.traducao = $1.label + ", " + $3.traducao;
				$$.traducaoAlt = $1.traducao + $3.traducaoAlt;
			}
			| E
			{
				$$.tipo = $1.tipo;
				$$.traducao = $1.label + ");\n";
				$$.traducaoAlt = $1.traducao;
			}
			|
			{
				$$.tipo = "";
				$$.traducao = ");\n";
				$$.traducaoAlt = "";
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
					strCompared = true;
					$$.traducao = $1.traducao + $3.traducao + 
						"\t" + $$.label + " = stringcmp(" + $1.label + ", " + $3.label + ");\n";
				} else if ($1.tipo == "char*" && $3.tipo == "char*" && $2.label == "!=") {
					strCompared = true;
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
			// Foo A (Foo é um struct)
			| TK_ID TK_ID
			{
				TipoStruct ts = getStruct($1.label);
				declararVariavel($2.label, ts.id, "");
			}
			| OP_PONTO '=' E
			{
				Variavel v;
				v.tipo = replace($1.tipo, "*", "");
				v.id = "*" + $1.label;
				$$.traducao = convertImplicit($1, $3, v);
			}
			| OP_PONTO
			{
				// Usando o membro de um struct como um R-value (ex: z = foo.c.x.y)
				// Se o tipo for fundamental, precisamos carregar o valor em um temporário.
				if (isDefaultType($1.tipo)) {
					 $$.label = genTempCode($1.tipo);
					 $$.traducao = $1.traducao + "\t" + $$.label + " = " + $1.label + ";\n";
					 $$.tipo = $1.tipo;
				} else {
					 $$.tipo = replace($1.tipo, "*", "");
					 $$.label = genTempCode($$.tipo);
					 $$.traducao = $1.traducao + "\t" + $$.label + " = *" + $1.label + ";\n";
				}
			}
			;
			// A += B
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
			$$.tamanho = v.tamanho;

			// Se for um vetor dinâmico, o tipo para a checagem de assinatura
			// da função deve indicar isso.
			if (v.ehDinamico) {
				// O tipo base pode ser "int" ou "struct bar"
				string base_type = v.tipo;
				// Se for um tipo struct, removemos o "struct " para a assinatura
				// Ex: "struct bar" -> "bar"
					if (base_type.rfind("struct ", 0) == 0) {
						base_type = base_type.substr(7);
					}
				// A assinatura de tipo para a função será "bar[]" ou "int[]"
				$$.tipo = base_type + "[]";
			} else {
				$$.tipo = v.tipo;
			}
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
			| TK_THIS
			{
				if (!inMetodo) {
					yyerror("'this' utilizado fora de um método");
				}
				$$.label = split(tipoMetodo, "|")[1];
				$$.tipo = split(tipoMetodo, "|")[0];
				$$.tipo = ($$.tipo == "string") ? "char*" : $$.tipo;
				
			}
			| TK_ID '(' CALL_ARGS ')'
			{
				if ($1.label == "main") {
					yyerror("função main não pode ser chamada");
				}

				Funcao f = getFuncao($1.label, $3.tipo);
				if (f.tipo_retorno != "void") {
					
					$$.label = genTempCode(f.tipo_retorno);
					$$.traducao = $3.traducaoAlt + "\t" + $$.label + " = " + f.id + "(" + $3.traducao;
					$$.tipo = f.tipo_retorno;
				} else {
					$$.tipo = "void";
					$$.traducao = $3.traducaoAlt + "\t" + f.id + "(" + $3.traducao;
				}
			}
			| OP_PONTO '.' METHOD '(' CALL_ARGS ')'
			{
				Variavel v = getVariavel($1.label, true); // <-- AGORA FUNCIONA CORRETAMENTE!
				if (v.id == "<error_id>") {
					v.id = ($3.label == "append") ? $1.label : "*" + $1.label;
					v.tipo = replace($1.tipo, "*", "");
					v.ehDinamico = $1.ehDinamico;
					v.numDimensoes = $1.numDimensoes;
				}
				if ($3.label == "append") {
					if (!v.ehDinamico) { 
						yyerror("O primeiro argumento de 'append' deve ser um vetor dinâmico.");
					}

					// CASO 1: append(matriz, [1,2,3]) -> Adicionando um vetor a uma matriz
					if ($5.tipo == "__vetor") { 
						if (v.numDimensoes != 2) { 
							yyerror("Tentativa de adicionar um vetor a uma matriz que não é 2D."); 
						}
						
						$$.traducao = $5.traducaoAlt; // Código que cria e preenche o vetor temporário
						$$.traducao += append_code(v.id, "struct Vetor", $5.label); // Adiciona a struct
					} 
					// CASO 2: append(vetor_1d, 42) -> Adicionando um valor a um vetor 1D
					else { 
						if (v.numDimensoes != 1) { 
							yyerror("Tentativa de adicionar um valor simples a uma matriz. Use a sintaxe de lista []."); 
						}
						if (v.tipo != $5.tipo && !checkIsPossible(v.tipo, $5.tipo)) { 
							yyerror("Tipo do valor '" + $5.label + "' incompatível com o tipo do vetor '" + v.nome + "'.");
						}
						
						string val_label = $5.label;
						if (v.tipo != $5.tipo) { val_label = "(" + v.tipo + ")" + val_label; }

						$$.traducao = $5.traducaoAlt;
						$$.traducao += append_code(v.id, v.tipo, val_label);
					}
				} else {				
					Metodo m = getMetodo($3.label, v.tipo, $5.tipo);
					$5.traducao = ($5.traducao == ");\n") ? v.id + $5.traducao : v.id + ", " + $5.traducao;
					
					if (m.tipo_retorno != "void") {
						$$.label = genTempCode(m.tipo_retorno);
						$$.traducao = $1.traducao + "\t" + $$.label + " = " + m.id + "(" + $5.traducao;
						$$.tipo = m.tipo_retorno;
					} else {
						$$.tipo = "void";
						$$.traducao = $1.traducao + $5.traducaoAlt + "\t" + m.id + "(" +  $5.traducao;
					}
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
			| TK_TIPO TK_ID lista_colchetes_vazios
			{
				vectorUsed = true;
				string tipo_base = $1.label;
				declararVariavel($2.label, tipo_base, "");

				Variavel& v = pilha_escopos.back()[$2.label];
				v.ehDinamico = true;
				v.numDimensoes = $3.nivelAcesso;
				variaveis.erase(v); 
				variaveis.insert(v);

				$$.traducao = "\tstruct Vetor " + v.id + ";\n";
				$$.traducao += "\t" + v.id + ".tamanho = 0;\n";
				$$.traducao += "\t" + v.id + ".capacidade = 0;\n";
				$$.traducao += "\t" + v.id + ".data = NULL;\n";
				string sizeof_arg;
				if (v.numDimensoes > 1) {
					// Se for 2D ou mais, o elemento é outro vetor.
					sizeof_arg = "struct Vetor";
				} else {
					// Se for 1D, o elemento é do tipo base.
					sizeof_arg = tipo_base;
				}
				$$.traducao += "\t" + v.id + ".tam_elemento = sizeof(" + sizeof_arg + ");\n";
			}
			// Foo A[] (Foo é um struct)
			| TK_ID TK_ID lista_colchetes_vazios
			{
				vectorUsed = true;
				TipoStruct ts = getStruct($1.label);
				string tipo_base = ts.id;
				declararVariavel($2.label, tipo_base, "");

				Variavel& v = pilha_escopos.back()[$2.label];
				v.ehDinamico = true;
				v.numDimensoes = $3.nivelAcesso;
				variaveis.erase(v); 
				variaveis.insert(v);

				$$.traducao = "\tstruct Vetor " + v.id + ";\n";
				$$.traducao += "\t" + v.id + ".tamanho = 0;\n";
				$$.traducao += "\t" + v.id + ".capacidade = 0;\n";
				$$.traducao += "\t" + v.id + ".data = NULL;\n";
				string sizeof_arg;
				if (v.numDimensoes > 1) {
					// Se for 2D ou mais, o elemento é outro vetor.
					sizeof_arg = "struct Vetor";
				} else {
					// Se for 1D, o elemento é do tipo base.
					sizeof_arg = tipo_base;
				}
				$$.traducao += "\t" + v.id + ".tam_elemento = sizeof(" + sizeof_arg + ");\n";
			}
			| acesso_vetor '=' E 
			{
				string tipo_destino = $1.tipo; 
				string tipo_origem = $3.tipo; 
				string rhs_label = $3.label;

				if (tipo_destino != tipo_origem)
				{
					if (checkIsPossible(tipo_destino, tipo_origem))
					{
						rhs_label = "(" + tipo_destino + ") " + $3.label;
					}
					else
					{
						yyerror("atribuição incompatível (esperando " + tipo_destino + ", recebeu " + tipo_origem + ")");
					}
				}

				$$.traducao = $1.traducao + $3.traducao + "\t" + $1.label + " = " + rhs_label + ";\n";
			}
			| acesso_vetor 
			| inicializacao_lista {
				$$ = $1; // Apenas repassa os atributos.
			}
			;
lista_colchetes_vazios: '[' ']'
			{
				// Caso base: encontrou o primeiro []. O nível/dimensão é 1.
				$$.nivelAcesso = 1;
			}
			| lista_colchetes_vazios '[' ']'
			{
				// Caso recursivo: encontrou mais um []. Incrementa o contador.
				$$.nivelAcesso = $1.nivelAcesso + 1;
			}
			;
METHOD      : TK_ID
			{
				$$ = $1;
			}
			| TK_APPEND
			{
				$$.label = "append";
			}
inicializacao_lista:
			'[' lista_elementos ']'
			{
				$$ = $2;
				$$.tipo = "__vetor"; 
			}
			;

lista_elementos: E
			{
				string tipo_base_lista = $1.tipo;
				
				Variavel temp_v;
				temp_v.nome = "temp_vet_" + to_string(var_temp_qnt);
				temp_v.id = genId();
				temp_v.tipo = tipo_base_lista;
				temp_v.ehDinamico = true;
				temp_v.numDimensoes = 1;
				variaveis.insert(temp_v);

				$$.traducao = $1.traducao; // Código da expressão do primeiro elemento.
				$$.traducao += "\tstruct Vetor " + temp_v.id + ";\n";
				$$.traducao += "\t" + temp_v.id + ".tamanho = 0;\n";
				$$.traducao += "\t" + temp_v.id + ".capacidade = 0;\n";
				$$.traducao += "\t" + temp_v.id + ".data = NULL;\n";
				$$.traducao += "\t" + temp_v.id + ".tam_elemento = sizeof(" + tipo_base_lista + ");\n";
				
				$$.traducao += append_code(temp_v.id, tipo_base_lista, $1.label);

				$$.label = temp_v.id; // O resultado é o ID do vetor temporário (ex: t2).
				$$.tipo = tipo_base_lista; // Guarda o tipo dos elementos.
			}
			| lista_elementos ',' E
			{
				$$ = $1; // Pega os atributos do vetor temporário já criado.
				if ($1.tipo != $3.tipo) { yyerror("Tipos mistos em lista de inicialização não são permitidos."); }
				
				$$.traducao += $3.traducao;
				$$.traducao += append_code($1.label, $1.tipo, $3.label);
			}
			;
			
acesso_vetor: TK_ID '[' E ']'
			{
				Variavel v = getVariavel($1.label);
				if (!v.ehDinamico) { yyerror("A variável '" + v.nome + "' não é um vetor dinâmico."); }
				if ($3.tipo != "int") { yyerror("O índice de um vetor deve ser um inteiro."); }

				$$.id_original = $1.label;
				$$.nivelAcesso = 1;

				if ($$.nivelAcesso < v.numDimensoes) {
					$$.tipo = "__vetor";
					$$.label = genTempCode("struct Vetor");
					$$.traducao = $1.traducao + $3.traducao;
					$$.traducao += "\t" + $$.label + " = *(((struct Vetor*)" + v.id + ".data) + " + $3.label + ");\n";
				} else {
					$$.tipo = v.tipo;
					$$.label = genTempCode(v.tipo);
					$$.traducao = $1.traducao + $3.traducao;
					$$.traducao += "\t" + $$.label + " = *((( " + v.tipo + "* )" + v.id + ".data) + " + $3.label + ");\n";
				}
			}
			| acesso_vetor '[' E ']'
			{
				$$.id_original = $1.id_original;
				Variavel v = getVariavel($$.id_original);
				if ($1.tipo != "__vetor") { yyerror("Tentativa de acesso multidimensional em um não-vetor."); }
				if ($3.tipo != "int") { yyerror("O índice de um vetor deve ser um inteiro."); }

				$$.nivelAcesso = $1.nivelAcesso + 1;
				string acesso_anterior_label = $1.label;

				if ($$.nivelAcesso < v.numDimensoes) {
					$$.tipo = "__vetor";
					$$.label = genTempCode("struct Vetor");
					$$.traducao = $1.traducao + $3.traducao;
					$$.traducao += "\t" + $$.label + " = *(((struct Vetor*)" + acesso_anterior_label + ".data) + " + $3.label + ");\n";
				} else {
					$$.tipo = v.tipo;
					$$.label = genTempCode(v.tipo);
					$$.traducao = $1.traducao + $3.traducao;
					$$.traducao += "\t" + $$.label + " = *((( " + v.tipo + "* )" + acesso_anterior_label + ".data) + " + $3.label + ");\n";
				}
			}
		;
			
OP_PONTO    : TK_ID
			{
				// Caso base para o início de uma cadeia de acesso, ex: 'foo'
				Variavel v = getVariavel($1.label);
				$$.label = v.id;         // Identificador C para a variável, ex: t0
				$$.tipo = v.tipo;         // Tipo da variável, ex: struct Foo
				$$.ehDinamico = v.ehDinamico;
				$$.numDimensoes = v.numDimensoes;
				$$.traducao = "";         // Sem código de preparação para a variável base
			}
			| TK_THIS
			{
				if (!inMetodo) {
					yyerror("'this' utilizado fora de um método");
				}
				$$.label = split(tipoMetodo, "|")[1];
				$$.tipo = split(tipoMetodo, "|")[0];
				$$.traducao = "";
			}
			| acesso_vetor
			{
				$$ = $1; // Repassa os atributos do acesso ao vetor.
			}
			| OP_PONTO '.' TK_ID
			{
				string lhs_type = $1.tipo;
				bool is_lhs_pointer = (lhs_type.find("*") != string::npos);
				string accessor = is_lhs_pointer ? "->" : ".";

				string struct_name;
				if(is_lhs_pointer) {
					lhs_type.pop_back(); 
				}
				vector<string> parts = split(lhs_type, " ");
				struct_name = (parts.size() > 1) ? parts[1] : parts[0];

				TipoStruct ts = getStruct(struct_name);

				Variavel member_attr;
				bool found = false;
				for (const Variavel& var : ts.atributos) {
					if (var.id == $3.label) {
						found = true;
						member_attr = var;
						break;
					}
				}
				if (!found) {
					yyerror("struct " + struct_name + " não possuí o campo " + $3.label);
				}

				// Lógica unificada: sempre obter um ponteiro para o membro
				string member_type_name = member_attr.tipo;
				string new_ptr_type;

				if (!isDefaultType(member_type_name)) {
					new_ptr_type = "struct " + member_type_name + "*";
				} else {
					new_ptr_type = member_type_name + "*";
				}

				$$.label = genTempCode(new_ptr_type); 
				$$.tipo = new_ptr_type;
				// Parênteses removidos e lógica unificada
				$$.traducao = $1.traducao + "\t" + $$.label + " = &" + $1.label + accessor + member_attr.id + ";\n";
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
						break;
					default:
						mask = "other";
					}
					if (mask == "other") {
						$$.traducao = $1.traducao + "\tprintf(\"<"  + $1.tipo + ">\");\n"; 
					} else {
						$$.traducao = $1.traducao + "\tprintf(\"" + mask + "\", " + $1.label + ");\n"; 
					}
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
