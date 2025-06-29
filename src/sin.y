%{
#include <iostream>
#include <string>
#include <sstream>
#include <set>
#include <algorithm>
#include "src/utils.hpp"

// Em sintatico.y
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

    if (vectorUsed) {
        codigo += structVetor;
    }

    for (const string& def : structDef) {
        codigo += def;
    }

    for (const Funcao& func : funcoes) {
        codigo += func.prototipo;
    }

    if (removeUsed) {
        codigo += "void __maphra_remove_element(struct Vetor* v, int index);\n";
    }
	if (sliceUsed) { // <-- ADICIONAR
        codigo += "struct Vetor __maphra_slice(struct Vetor* original, int start, int end);\n";
    }
    codigo += "\n";

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
    
    if (strCompared) {
        codigo += "\n" + genStringcmp();
    }
    codigo += "\n" + traducao;
    
    // --- CORREÇÃO APLICADA AQUI ---
    // A string agora está no formato C/C++ tradicional, que o Yacc entende.
    if (removeUsed) {
        string remove_func_code =
            "\nvoid __maphra_remove_element(struct Vetor* v, int index) {\n"
            "    if (v == NULL || v->tamanho == 0 || index < 0 || index >= v->tamanho) {\n"
            "        return;\n"
            "    }\n"
            "    int elementos_para_mover = v->tamanho - index - 1;\n"
            "    if (elementos_para_mover > 0) {\n"
            "        char* dest = (char*)v->data + (index * v->tam_elemento);\n"
            "        char* src = (char*)v->data + ((index + 1) * v->tam_elemento);\n"
            "        memmove(dest, src, elementos_para_mover * v->tam_elemento);\n"
            "    }\n"
            "    v->tamanho--;\n"
            "}\n";
        codigo += remove_func_code;
    }

    if (sliceUsed) { // <-- ADICIONAR
        codigo += genSliceFunction();
    }


    // Imprime o código final
    cout << codigo << endl;
}

%}


%token TK_NUM TK_REAL TK_BOOL TK_STRING
%token TK_MAIN TK_ID TK_PRINT TK_INPUT
%token TK_TIPO TK_UNARIO TK_ABREVIADO
%token TK_RELACIONAL
%token TK_IF TK_ELSE TK_LACO TK_DO TK_IN 
%token TK_SWITCH TK_DEFAULT
%token TK_BREAK TK_CONTINUE
%token TK_WHEELDECIDE TK_OPTION
%token TK_FUNCAO TK_RETURN TK_NULL TK_STRUCT
%token TK_BIND TK_THIS
%token TK_APPEND TK_LEN TK_REMOVE 

%start S

%right '='
%left TK_ELSE
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
                string tipo_c = ($1.tipo == "string") ? "char*" : $1.tipo;
                 $$.traducao = "\t" + tipo_c + " " + $2.label + ";\n" + $5.traducao;
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
                string tipo_c = ($1.tipo == "string") ? "char*" : $1.tipo;
                 $$.traducao = "\t" + tipo_c + " " + $2.label + ";\n";
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
ARGS:       TK_TIPO TK_ID ',' ARGS
            {
                // Parâmetro primitivo (ex: int a, ...)
                declararVariavel($2.label, $1.label, "", 0);
                Variavel v = getVariavel($2.label);
                $$.tipo = v.tipo + " " + $4.tipo;
                $$.traducao = v.tipo + " " + v.id + ", " + $4.traducao;
            }
            | TK_ID TK_ID ',' ARGS
            {
                // Parâmetro de struct (ex: Ponto p1, ...)
                TipoStruct ts = getStruct($1.label);
                declararVariavel($2.label, ts.id, "", 0);
                Variavel v = getVariavel($2.label);
                $$.tipo = ts.id + " " + $4.tipo; // Assinatura CORRETA
                $$.traducao = v.tipo + " " + v.id + ", " + $4.traducao;
            }
            | TK_TIPO TK_ID
            {
                // Parâmetro final primitivo (ex: int a)
                declararVariavel($2.label, $1.label, "", 0);
                Variavel v = getVariavel($2.label);
                $$.tipo = v.tipo;
                $$.traducao = v.tipo + " " + v.id + ") {\n";
            }
            | TK_ID TK_ID
            {
                // Parâmetro final de struct (ex: Retangulo r)
                TipoStruct ts = getStruct($1.label);
                declararVariavel($2.label, ts.id, "", 0);
                Variavel v = getVariavel($2.label);
                $$.tipo = ts.id; // Assinatura CORRETA
                $$.traducao = v.tipo + " " + v.id + ") {\n";
            }
            // --- REGRAS PARA VETORES ---
            | TK_TIPO TK_ID lista_colchetes_vazios ',' ARGS
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
                // Assinatura CORRETA para vetores de struct
                $$.tipo = ts.id + "[] " + $5.tipo;
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
                // Assinatura CORRETA para vetor de struct final
                $$.tipo = ts.id + "[]";
                $$.traducao = "struct Vetor " + v.id + ") {\n";
            }
            | /* Vazio - sem argumentos */
            {
                $$.traducao = ") {\n";
                $$.tipo = "";
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
			| TK_LACO '(' TK_TIPO TK_ID TK_IN E ')' 
			{
				// --- AÇÃO NO MEIO DA REGRA ---
				// Este código executa DEPOIS de ler o ')', mas ANTES de analisar o BLOCO.
				entrar_escopo(); // 1. Entra no escopo do laço.
				declararVariavel($4.label, $3.tipo, ""); // 2. Declara a variável DENTRO do novo escopo.
			}
			BLOCO
			{
				// --- AÇÃO FINAL CORRIGIDA ---
				
				// 1. Obtenha a variável do item (ex: 'p'), que foi declarada no escopo do laço.
				Variavel item_var = getVariavel($4.label);

				// 2. Verificações de tipo usando os atributos de $6 (o 'E' para 'palavras') DIRETAMENTE.
				//    NÃO chame getVariavel($6.label) aqui!
				if (!$6.ehDinamico) { 
					yyerror("O laço 'for-in' só pode ser usado com vetores dinâmicos."); 
				}
				
				// Compara o tipo do item ('p') com o tipo base da coleção ('palavras')
				// Usamos $6.id_original, que agora guarda o tipo base (ex: "char*")
				if (item_var.tipo != $6.id_original) {
					yyerror("O tipo da variável '" + item_var.nome + "' (" + item_var.tipo + ") é incompatível com o tipo base do vetor (" + $6.id_original + ").");
				}

				// 3. Geração de Código (usando os atributos corretos)
				string inicio_laco = genLabel();
				string fim_laco = genLabel();
				string iterador = genTempCode("int");
				string colecao_id = $6.label; // Pega o identificador C ("t0") diretamente de E.

				$$.traducao = $6.traducao +
							"\t" + iterador + " = 0;\n" +
							inicio_laco + ":\n" +
							"\tif (" + iterador + " >= " + colecao_id + ".tamanho) goto " + fim_laco + ";\n" +
							// O cast usa o tipo da variável do item, que já está correto.
							"\t" + item_var.id + " = *(((" + item_var.tipo + "*)" + colecao_id + ".data) + " + iterador + ");\n" +
							$9.traducao + // Código do BLOCO
							"\t" + iterador + " = " + iterador + " + 1;\n" +
							"\tgoto " + inicio_laco + ";\n" +
							fim_laco + ":\n";
				
				sair_escopo(); // Sai do escopo do laço.
			}
			// REGRA CORRIGIDA PARA: for (Ponto p in meus_pontos) { ... }
			| TK_LACO '(' TK_ID TK_ID TK_IN E ')'
			{
				// --- AÇÃO NO MEIO DA REGRA ---
				entrar_escopo();
				TipoStruct ts = getStruct($3.label);
				declararVariavel($4.label, ts.id, "");
			}
			BLOCO
				{
					// --- AÇÃO FINAL CORRIGIDA ---
					
					// 1. Obtenha a variável do item (ex: 'p'), que foi declarada no escopo do laço.
					Variavel item_var = getVariavel($4.label);

					// 2. Verificações de tipo usando os atributos de $6 (o 'E' para 'palavras') DIRETAMENTE.
					//    NÃO chame getVariavel($6.label) aqui!
					if (!$6.ehDinamico) { 
						yyerror("O laço 'for-in' só pode ser usado com vetores dinâmicos."); 
					}
					
					// Compara o tipo do item ('p') com o tipo base da coleção ('palavras')
					// Usamos $6.id_original, que agora guarda o tipo base (ex: "char*")
					if (item_var.tipo != $6.id_original) {
						yyerror("O tipo da variável '" + item_var.nome + "' (" + item_var.tipo + ") é incompatível com o tipo base do vetor (" + $6.id_original + ").");
					}

					// 3. Geração de Código (usando os atributos corretos)
					string inicio_laco = genLabel();
					string fim_laco = genLabel();
					string iterador = genTempCode("int");
					string colecao_id = $6.label; // Pega o identificador C ("t0") diretamente de E.

					$$.traducao = $6.traducao +
								"\t" + iterador + " = 0;\n" +
								inicio_laco + ":\n" +
								"\tif (" + iterador + " >= " + colecao_id + ".tamanho) goto " + fim_laco + ";\n" +
								// O cast usa o tipo da variável do item, que já está correto.
								"\t" + item_var.id + " = *(((" + item_var.tipo + "*)" + colecao_id + ".data) + " + iterador + ");\n" +
								$9.traducao + // Código do BLOCO
								"\t" + iterador + " = " + iterador + " + 1;\n" +
								"\tgoto " + inicio_laco + ";\n" +
								fim_laco + ":\n";
					
					sair_escopo(); // Sai do escopo do laço.
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
			// a = expr1 (if_condition) else expr2
			| E TK_IF E TK_ELSE E
			{
				// --- a) Verificação de Tipos ---

				// A condição ($3) deve ser um booleano.
				if ($3.tipo != "bool") {
					yyerror("A condição da expressão condicional (if) deve ser do tipo booleano.");
				}

				// Os dois possíveis resultados ($1 e $5) devem ser de tipos compatíveis.
				string tipo_resultado;
				if ($1.tipo == $5.tipo) {
					tipo_resultado = $1.tipo;
				} else if (($1.tipo == "int" && $5.tipo == "float") || ($1.tipo == "float" && $5.tipo == "int")) {
					tipo_resultado = "float"; // Promove para float
				} else {
					yyerror("Tipos incompativeis nos resultados da expressão condicional: " + $1.tipo + " e " + $5.tipo);
				}

				// --- b) Geração de Código ---

				string label_false = genLabel();
				string label_fim = genLabel();
				
				// Cria uma variável temporária para guardar o resultado final.
				$$.label = genTempCode(tipo_resultado);
				$$.tipo = tipo_resultado;
				
				// Monta a tradução para C. A lógica é a mesma do ternário, mas os operandos mudam de lugar.
				$$.traducao = $3.traducao +                                        // 1. Código da CONDIÇÃO ($3)
							"\tif (!" + $3.label + ") goto " + label_false + ";\n" + // 2. Se a condição for falsa, pula
							$1.traducao +                                        // 3. Código da expressão VERDADEIRA ($1)
							"\t" + $$.label + " = " + $1.label + ";\n" +         // 4. Atribui o resultado VERDADEIRO
							"\tgoto " + label_fim + ";\n" +                      // 5. Pula para o fim
							label_false + ":\n" +                               // 6. Label para o bloco falso
							$5.traducao +                                        // 7. Código da expressão FALSA ($5)
							"\t" + $$.label + " = " + $5.label + ";\n" +         // 8. Atribui o resultado FALSO
							label_fim + ":\n";                                  // 9. Label do fim
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
				$$.label = v.id;            // Identificador C (ex: "t0")
				$$.tamanho = v.tamanho;
				$$.ehDinamico = v.ehDinamico; // *** ADICIONAR: Passa a flag se é vetor dinâmico ***
				
				if (v.ehDinamico) {
					// Para o 'for', precisamos do tipo base do vetor (ex: "char*", "struct Ponto")
					// Vamos guardá-lo em 'id_original', que você já tem na struct atributos.
					$$.id_original = v.tipo; 

					// Para checagem de tipo em chamadas de função, mantemos o formato "tipo[]"
					string base_type_sig = v.tipo;
					if (base_type_sig.rfind("struct ", 0) == 0) {
						base_type_sig = base_type_sig.substr(7);
					}
					$$.tipo = base_type_sig + "[]";
				} else {
					// Se não for dinâmico, os tipos são os mesmos.
					$$.tipo = v.tipo;
					$$.id_original = v.tipo;
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
				Variavel v = getVariavel($1.label, true);
				if (v.id == "<error_id>") {
					v.id = ($3.label == "append") ? $1.label : "*" + $1.label;
					
					// --- LÓGICA CORRIGIDA ---
					// Trata char* como um caso especial: ele É o tipo base.
					if ($1.tipo == "char*") {
						v.tipo = "char*";
					} else {
						// Para outros ponteiros (ex: Ponto*, Retangulo*), a lógica antiga funciona.
						v.tipo = replace($1.tipo, "*", "");
					}

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

						// --- NOVA LÓGICA DE CONVERSÃO ---

						string val_label = $5.label; // Nome do temporário C com o valor a ser inserido.
						string cast_code = "";       // Código extra para a conversão, se necessário.

						// Compara o tipo base do vetor (v.tipo) com o tipo do valor ($5.tipo)
						if (v.tipo != $5.tipo) {
							// Se os tipos são diferentes, checa se a conversão é possível.
							if (checkIsPossible(v.tipo, $5.tipo)) {
								// Conversão é possível! Ex: vetor de int, valor float.
								// 1. Gera um novo temporário para guardar o valor convertido.
								//    O tipo do temporário deve ser o tipo do vetor.
								string casted_temp = genTempCode(v.tipo);

								// 2. Gera o código C que faz o cast.
								cast_code = "\t" + casted_temp + " = (" + v.tipo + ")" + $5.label + ";\n";

								// 3. O valor a ser inserido agora é o temporário com o cast.
								val_label = casted_temp;

							} else {
								// Se os tipos são diferentes E a conversão NÃO é possível, então é um erro.
								yyerror("Tipo do valor '" + $5.label + "' (" + $5.tipo + ") incompatível com o tipo do vetor '" + v.nome + "' (" + v.tipo + ").");
							}
						}
					
					// O código de tradução final agora inclui o código do argumento,
					// o código do cast (se houver), e a chamada para a função append.
					$$.traducao = $5.traducaoAlt + cast_code + append_code(v.id, v.tipo, val_label);
				}
				} else if ($3.label == "len") { 
					if (!v.ehDinamico) {
						yyerror("O método 'len' só pode ser chamado em um vetor dinâmico.");
					}
					if ($5.tipo != "") { 
						yyerror("O método 'len' não aceita argumentos.");
					}

					// O resultado de len() é um inteiro.
					$$.tipo = "int";
					$$.label = genTempCode("int");

					// A tradução simplesmente acessa o campo .tamanho da struct Vetor.
					$$.traducao = $1.traducao + "\t" + $$.label + " = " + $1.label + ".tamanho;\n";
				} else if ($3.label == "remove") { // <-- ADICIONE ESTE BLOCO 'ELSE IF'
					removeUsed = true;
					if (!v.ehDinamico) {
						yyerror("O método 'remove' só pode ser chamado em um vetor dinâmico.");
					}
					if ($5.tipo != "int") { // $5 é CALL_ARGS
						yyerror("O método 'remove' espera um argumento do tipo inteiro (o índice).");
					}

					// remove() é um procedimento, não retorna valor.
					$$.tipo = "void";
					
					// A tradução gera uma chamada para nossa função auxiliar.
					// Passamos o endereço do nosso vetor (&) pois a função espera um ponteiro.
					$$.traducao = $1.traducao + $5.traducaoAlt + "\t__maphra_remove_element(&" + $1.label + ", " + $5.label + ");\n";

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
				string tipo_base_linguagem = $1.label;
				declararVariavel($2.label, tipo_base_linguagem, "");

				// Acessa a variável recém-declarada para obter suas informações
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
					sizeof_arg = "struct Vetor";
				} else {
					// --- CORREÇÃO AQUI ---
					// Use v.tipo, que já foi convertido para "char*", em vez de tipo_base_linguagem.
					sizeof_arg = v.tipo;
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
			| TK_TIPO TK_ID lista_colchetes_vazios '=' E
			{
				// 1. O lado direito (RHS) deve ser um vetor ou uma lista
				if (!$5.ehDinamico && $5.tipo != "__vetor") {
					yyerror("A inicialização de um vetor dinâmico requer outro vetor ou uma lista [].");
				}

				// 2. Declara o novo vetor (LHS, ex: 'meio')
				string tipo_base = ($5.id_original.empty()) ? $1.tipo : $5.id_original;
				declararVariavel($2.label, tipo_base, "");

				Variavel& v = pilha_escopos.back()[$2.label];
				v.ehDinamico = true;
				v.numDimensoes = $3.nivelAcesso;
				variaveis.erase(v);
				variaveis.insert(v);

				// 3. Gera o código de atribuição. O RHS ($5) já contém o código
				//    para criar o vetor (seja por slice ou lista).
				//    Só precisamos atribuir o resultado ao novo vetor 'v'.
				$$.traducao = $5.traducao;
				$$.traducao += "\t" + v.id + " = " + $5.label + "; // " + v.nome + "\n";
			}
			/* | acesso_vetor '=' E  */
			| acesso '=' E
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
			/* | acesso_vetor  */
			| acesso
			| inicializacao_lista {
				$$ = $1; // Apenas repassa os atributos.
			}
			;

acesso: TK_ID '[' E ']'  // Acesso a um elemento: v[i]
			{
				Variavel v = getVariavel($1.label);
				if (!v.ehDinamico) { yyerror("A variável '" + v.nome + "' não é um vetor dinâmico."); }
				if ($3.tipo != "int") { yyerror("O índice de um vetor deve ser um inteiro."); }

				// O resultado do acesso é um valor, então o colocamos em um temporário
				$$.tipo = v.tipo;
				$$.label = genTempCode(v.tipo);
				$$.traducao = $3.traducao; // Código para calcular o índice
				$$.traducao += "\t" + $$.label + " = * (((" + v.tipo + "*)" + v.id + ".data) + " + $3.label + ");\n";
				// Não é mais um vetor, então ehDinamico é falso
				$$.ehDinamico = false;
			}
			| TK_ID '[' optional_e ':' optional_e ']' // Slice: v[a:b]
			{
				sliceUsed = true; // Flag para gerar a função auxiliar
				Variavel v = getVariavel($1.label);
				if (!v.ehDinamico) { yyerror("Slices só podem ser feitos em vetores dinâmicos."); }

				string inicio = $3.label;
				string fim = $5.label;

				// Se o início ou o fim não foram especificados, usamos valores padrão.
				// Usamos "-1" como um marcador para a nossa função C saber que o valor foi omitido.
				if (inicio.empty()) {
					inicio = genTempCode("int");
					$$.traducao += "\t" + inicio + " = -1;\n";
				} else {
					if ($3.tipo != "int") yyerror("Índice de slice deve ser inteiro.");
					$$.traducao += $3.traducao;
				}

				if (fim.empty()) {
					fim = genTempCode("int");
					$$.traducao += "\t" + fim + " = -1;\n";
				} else {
					if ($5.tipo != "int") yyerror("Índice de slice deve ser inteiro.");
					$$.traducao += $5.traducao;
				}

				// O resultado de um slice é um NOVO vetor.
				$$.label = genTempCode("struct Vetor");
				$$.traducao += "\t" + $$.label + " = __maphra_slice(&" + v.id + ", " + inicio + ", " + fim + ");\n";
				
				// Propaga os atributos do novo vetor
				$$.ehDinamico = true;
				$$.tipo = v.tipo + "[]"; // O tipo ainda é um vetor do mesmo tipo base
				$$.id_original = v.tipo;
			}
			;

/* acesso_vetor: TK_ID '[' E ']'
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
		; */
optional_e: E
			{
				$$ = $1;
			}
			| /* vazio */
			{
				$$.label = "";
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
			| TK_LEN { 
				$$.label = "len"; 
			}
			| TK_REMOVE { 
				$$.label = "remove"; 
			}
            ;

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
			/* | acesso_vetor */
			| acesso
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
PRINT_ARGS:     E ',' PRINT_ARGS
            {
                // Unifica a checagem de tipo. Se for "char*" OU "string", trata como string.
                if ($1.tipo == "char*" || $1.tipo == "string") {
                    $$.traducao = $1.traducao + "\tprintf(\"%s\", " + $1.label + ");\n\tprintf(\" \");\n";
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
                        case 'i': mask = "%d"; break;
                        case 'f': mask = "%f"; break;
                        case 'c': mask = "%c"; break;
                        default:  mask = "other";
                    }
                    if (mask == "other") {
                        $$.traducao = $1.traducao + "\tprintf(\"<%s>\", \"" + $1.tipo + "\");\n";
                    } else {
                        $$.traducao = $1.traducao + "\tprintf(\"" + mask + "\", " + $1.label + ");\n\tprintf(\" \");\n";
                    }
                }
                $$.traducao += $3.traducao;
            }
            | E
            {
                // Unifica a checagem de tipo. Se for "char*" OU "string", trata como string.
                if ($1.tipo == "char*" || $1.tipo == "string") {
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
                        case 'i': case 'b': mask = "%d"; break;
                        case 'f': mask = "%f"; break;
                        case 'c': mask = "%c"; break;
                        default:  mask = "other";
                    }
                    if (mask == "other") {
                        $$.traducao = $1.traducao + "\tprintf(\"<%s>\", \"" + $1.tipo + "\");\n";
                    } else {
                        $$.traducao = $1.traducao + "\tprintf(\"" + mask + "\", " + $1.label + ");\n"; 
                    }
                }
            }

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
