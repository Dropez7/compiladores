#include <string>
#include <set>
#include <iostream>

#define YYSTYPE atributos

using namespace std;


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
int var_temp_qnt;
int nLinha = 1;
int nColuna = 1;
void yyerror(string);
set<Variavel> variaveis;

int yyparse();

void isAvailable(string nome)
{
    // verifica se o nome da variavel inclui __var_tmp
    if (nome.find("__var_tmp") != string::npos) {
        yyerror("nome de variável reservado " + nome);
    }

    // verifica se a variável já foi declarada anteriormente
    for (const Variavel& var : variaveis) {
        if (var.nome == nome) {
            yyerror("variável já declarada " + nome);
        }
    }
}

// gera as variáveis temporárias
string genTempCode(string tipo)
{
    var_temp_qnt++;
    string nome = "__var_tmp" + to_string(var_temp_qnt);
    Variavel v;
    v.nome = nome;
    v.tipo = tipo;
    variaveis.insert(v);
    return nome;
}

// procura a variável na lista de variáveis declaradas
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
