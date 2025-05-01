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
    string id;
};
bool operator<(const Variavel& a, const Variavel& b) {
    return a.id < b.id;
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
    // verifica se a variável já foi declarada anteriormente
    for (const Variavel& var : variaveis) {
        if (var.nome == nome) {
            yyerror("variável já declarada " + nome);
        }
    }
}

string genId()
{
    return "t" + to_string(var_temp_qnt++);
}

// gera as variáveis temporárias
string genTempCode(string tipo)
{
    string id = genId();
    Variavel v;
    v.id = id;
    v.tipo = tipo;
    variaveis.insert(v);
    return id;
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

string convertImplicit(atributos a, atributos b, Variavel v) {
    if (v.tipo != b.tipo) {
        string tipos = v.tipo + b.tipo;
        if (tipos == "intfloat") {
            return a.traducao + b.traducao + "\t" + v.id + " = (int) " + b.label + ";\n";
        }
        else if (tipos == "floatint") {
            return a.traducao + b.traducao + "\t" + v.id + " = (float) " + b.label + ";\n";
        }
        else {
            yyerror("atribuição incompatível (esperando " + v.tipo + ", recebeu " + b.tipo + ")");
        }
    }
    else {
        return a.traducao + b.traducao + "\t" + v.id + " = " + b.label + ";\n";
    }
}

bool checkIsPossible(string t1, string t2) {
    if (t1 == "int" && t2 == "float") {
        return true;
    } if (t1 == "float" && t2 == "int") {
        return true;
    } if (t1 == "int" && t2 == "int") {
        return true;
    } if (t1 == "float" && t2 == "float") {
        return true;
    }
    return false;
}