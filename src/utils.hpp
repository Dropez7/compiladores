#include <string>
#include <set>
#include <iostream>
#include <vector>
#include <map>

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
bool operator<(const Variavel &a, const Variavel &b)
{
    return a.id < b.id;
}

int yylex();
int yyparse();
int var_temp_qnt;
int label_qnt;
int nLinha = 1;
int nColuna = 1;
void yyerror(string);
set<Variavel> variaveis;
set<string> free_vars;
vector<map<string, Variavel>> pilha_escopos;

string genId()
{
    return "t" + to_string(var_temp_qnt++);
}

string genLabel()
{
    return "L" + to_string(label_qnt++);
}

void entrar_escopo()
{
    pilha_escopos.emplace_back();
}

void sair_escopo()
{
    if (!pilha_escopos.empty())
        pilha_escopos.pop_back();
    else
        yyerror("pilha de escopo vazia!");
}

void declararVariavel(const string &nome_var, const string &tipo_var)
{
    if (pilha_escopos.empty())
    {
        yyerror("Não há escopo ativo para declarar a variável '" + nome_var + "'.");
        return;
    }

    map<string, Variavel> &escopo_atual = pilha_escopos.back();

    if (escopo_atual.count(nome_var))
    {
        yyerror("Variável '" + nome_var + "' já declarada neste escopo (linha " + to_string(nLinha) + ").");
        return;
    }

    Variavel v;
    v.nome = nome_var;
    v.tipo = (tipo_var == "string") ? "char*" : tipo_var;
    v.id = genId();
    variaveis.insert(v);

    escopo_atual[nome_var] = v;
}

// busca variavel no escopo
Variavel getVariavel(const string &nome_var, bool turnOffError = false)
{
    if (pilha_escopos.empty())
    {
        yyerror("Tentativa de buscar variável '" + nome_var + "' sem escopos ativos.");
        Variavel v_erro;
        v_erro.nome = nome_var;
        v_erro.tipo = "error_no_scope";
        v_erro.id = "<error_id>";
        return v_erro;
    }
    for (auto it_escopo = pilha_escopos.rbegin(); it_escopo != pilha_escopos.rend(); ++it_escopo)
    {
        const map<string, Variavel> &escopo_para_busca = *it_escopo;
        if (escopo_para_busca.count(nome_var))
        {
            return escopo_para_busca.at(nome_var);
        }
    }
    if (!turnOffError)
    {
        yyerror("Variável '" + nome_var + "' não declarada no escopo atual (linha " + to_string(nLinha) + ").");
    }
    Variavel v_erro;
    v_erro.nome = nome_var;
    v_erro.tipo = "error_not_found";
    v_erro.id = "<error_id>";
    return v_erro;
}

// gera as variáveis temporárias
string genTempCode(string tipo)
{
    if (pilha_escopos.empty())
    {
        yyerror("Erro Critico: Nao ha escopo ativo para declarar a variavel temporaria.");
    }
    if (tipo == "string")
    {
        tipo = "char*";
    }
    map<string, Variavel> &escopo_atual = pilha_escopos.back();

    Variavel v;
    v.nome = to_string(var_temp_qnt);
    v.tipo = tipo;
    v.id = genId();
    variaveis.insert(v);

    escopo_atual[v.nome] = v;
    return v.id;
}

string convertImplicit(atributos a, atributos b, Variavel v)
{
    if (v.tipo != b.tipo)
    {
        string tipos = v.tipo + b.tipo;
        if (tipos == "intfloat")
        {
            return a.traducao + b.traducao + "\t" + v.id + " = (int) " + b.label + ";\n";
        }
        else if (tipos == "floatint")
        {
            return a.traducao + b.traducao + "\t" + v.id + " = (float) " + b.label + ";\n";
        }
        else
        {
            yyerror("atribuição incompatível (esperando " + v.tipo + ", recebeu " + b.tipo + ")");
        }
    }
    else
    {
        return a.traducao + b.traducao + "\t" + v.id + " = " + b.label + ";\n";
    }
}

bool checkIsPossible(string t1, string t2)
{
    if (t1 == "int" && t2 == "float")
    {
        return true;
    }
    if (t1 == "float" && t2 == "int")
    {
        return true;
    }
    if (t1 == "int" && t2 == "int")
    {
        return true;
    }
    if (t1 == "float" && t2 == "float")
    {
        return true;
    }
    return false;
}