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
    string tamanho;
    string traducao;
    string tipo;
};

struct Variavel
{
    string nome;
    string tipo;
    string id;
    string tamanho;
};
bool operator<(const Variavel& a, const Variavel& b)
{
    return a.id < b.id;
}

struct WDarg
{
    string guards;
    string count;
    string choice;
    string label;
    int nCLAUSES;
};

int yylex();
int yyparse();
int var_temp_qnt;
int label_qnt;
int nLinha = 1;
int nColuna = 1;
bool wdUsed = false;
bool canBreak = false;
bool canContinue = false;
void yyerror(string);
set<Variavel> variaveis;
set<string> free_vars;
vector<map<string, Variavel>> pilha_escopos;
vector<WDarg> pilha_wd;

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

void declararVariavel(const string& nome_var, const string& tipo_var, const string& tamanho)
{
    if (pilha_escopos.empty())
    {
        yyerror("Não há escopo ativo para declarar a variável '" + nome_var + "'.");
        return;
    }

    map<string, Variavel>& escopo_atual = pilha_escopos.back();

    if (escopo_atual.count(nome_var))
    {
        yyerror("Variável '" + nome_var + "' já declarada neste escopo.");
        return;
    }

    Variavel v;
    v.nome = nome_var;
    v.tipo = (tipo_var == "string") ? "char*" : tipo_var;
    v.id = genId();
    v.tamanho = tamanho;
    variaveis.insert(v);

    escopo_atual[nome_var] = v;
}

// busca variavel no escopo
Variavel getVariavel(const string& nome_var, bool turnOffError = false)
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
        const map<string, Variavel>& escopo_para_busca = *it_escopo;
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
    map<string, Variavel>& escopo_atual = pilha_escopos.back();

    Variavel v;
    v.nome = to_string(var_temp_qnt);
    v.tipo = tipo;
    v.id = genId();
    variaveis.insert(v);

    escopo_atual[v.nome] = v;
    return v.id;
}

void genWDargs() {
    wdUsed = (wdUsed) ? wdUsed : true;
    WDarg wd;
    wd.guards = genTempCode("int*");
    wd.count = genTempCode("int");
    wd.choice = genTempCode("int");
    wd.label = genLabel();
    wd.nCLAUSES = 0;
    pilha_wd.push_back(wd);
}

void delWDargs() {
    if (!pilha_wd.empty()) {
        pilha_wd.pop_back();
    }
    else {
        yyerror("Pilha de WDargs vazia.");
    }
}

void makeOp(atributos& $$, atributos $1, atributos $2, atributos $3)
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
    return a.traducao + b.traducao + "\t" + v.id + " = " + b.label + ";\n";
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

string zerarVetor(string id, int n) {
    string inicio = genLabel();
    string fim = genLabel();
    string iterator = genTempCode("int");
    string cond = genTempCode("bool");
    return "\t" + iterator + " = 0;\n"
        + inicio + ":\n"
        + "\t" + cond + " = (" + iterator + " < " + to_string(n) + ");\n"
        + "\tif (!" + cond + ") goto " + fim + ";\n"
        + "\t" + id + "[" + iterator + "] = 0;\n"
        + "\t" + iterator + " = " + iterator + " + 1;\n"
        + "\tgoto " + inicio + ";\n"
        + fim + ":\n";
}

string replace(const string& original, const string& alvo, const string& novoValor) {
    if (alvo.empty()) return original;
    string resultado = original;
    size_t pos = 0;
    while ((pos = resultado.find(alvo, pos)) != string::npos) {
        resultado.replace(pos, alvo.length(), novoValor);
        pos += novoValor.length();
    }
    return resultado;
}