#include <string>
#include <set>
#include <iostream>
#include <vector>
#include <map>

#define YYSTYPE atributos

using namespace std;

string structVetor = "struct Vetor {\n\tvoid* data;\n\tint tamanho;\n\tint capacidade;\n\tsize_t tam_elemento;\n};\n\n";

struct atributos
{
    string label;
    string tamanho;
    string traducao;
    string tipo;
    int nivelAcesso = 0;
    string id_original;
};

struct Variavel
{
    string nome;
    string tipo;
    string id;
    string tamanho;
    bool ehDinamico = false;
    int numDimensoes = 0;

};
bool operator<(const Variavel& a, const Variavel& b)
{
    return a.id < b.id;
}

struct Funcao
{
    string nome;
    string prototipo;
    string tipo_retorno;
    string parametros;
    string id;
};
bool operator<(const Funcao& a, const Funcao& b)
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
bool hasReturned = false;
string returnType;
void yyerror(string);
set<Variavel> variaveis;
set<Funcao> funcoes;
set<string> free_vars;
vector<map<string, Variavel>> pilha_escopos;
vector<WDarg> pilha_wd;

vector<string> split(const string& s, const string& delimiter)
{
    vector<string> tokens;
    size_t start = 0, end;
    while ((end = s.find(delimiter, start)) != string::npos)
    {
        tokens.push_back(s.substr(start, end - start));
        start = end + delimiter.length();
    }
    tokens.push_back(s.substr(start));
    return tokens;
}

string genId()
{
    return "t" + to_string(var_temp_qnt++);
}

string genLabel()
{
    return "L" + to_string(label_qnt++);
}

void genPrototipo(Funcao& f)
{
    if (f.parametros == "")
    {
        f.prototipo = f.tipo_retorno + " " + f.id + "();\n";
        return;
    }
    string args = "";
    int n_args = 0;
    for (const auto& param : split(f.parametros, " "))
    {
        if (!args.empty())
            args += ", ";
        args += param + " arg" + to_string(n_args++);
    }

    f.prototipo = f.tipo_retorno + " " + f.id + "(" + args + ");\n";
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
    // verifica se a variável já foi declarada como função
    for (const auto& func : funcoes)
    {
        if (func.nome == nome_var)
        {
            yyerror("Erro: '" + nome_var + "' já foi declarado como função.");
            return;
        }
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

void declararFuncao(atributos& $1, string tipos, string retorno) {
    if ($1.label == "main") {
        yyerror("função main já declarada");
    }
    if ($1.label == "input" || $1.label == "print") {
        yyerror("função " + $1.label + " já existe");
    }

    for (const Variavel& var : variaveis) {
        if (var.nome == $1.label) {
            yyerror("variável " + $1.label + " já declarada");
        }
    }

    for (const Funcao& func : funcoes) {
        if (func.nome == $1.label && func.parametros == tipos) {
            yyerror("função " + $1.label + " já declarada");
        }
    }
    Funcao f;
    f.nome = $1.label;
    f.tipo_retorno = retorno;
    f.parametros = tipos;
    f.id = genId();
    genPrototipo(f);
    funcoes.insert(f);
    $1.traducao = $1.label;
}

Funcao getFuncao(const string& nome_funcao, const string& tipos)
{
    for (const Funcao& func : funcoes)
    {
        if (func.nome == nome_funcao && func.parametros == tipos)
        {
            return func;
        }
    }
    yyerror("Função '" + nome_funcao + "' com parâmetros do tipo '" + tipos + "' não encontrada.");
    Funcao f_erro;
    f_erro.nome = nome_funcao;
    f_erro.tipo_retorno = "error_not_found";
    f_erro.parametros = "";
    f_erro.id = "<error_id>";
    f_erro.prototipo = "<error_prototype>";
    return f_erro;
}

void setReturn(string type) {
    returnType = type;
    if (type == "void" || type == "main") {
        hasReturned = true;
    }
    else {
        hasReturned = false;
    }
}

string getReturn() {
    hasReturned = true;
    return returnType;
}

void updateTamanho(const string& nome_var, const string& novo_tamanho)
{
    if (pilha_escopos.empty())
    {
        yyerror("Erro Critico: Nao ha escopo ativo para atualizar o tamanho da variavel.");
        return;
    }
    map<string, Variavel>& escopo_atual = pilha_escopos.back();
    if (escopo_atual.count(nome_var))
    {
        escopo_atual[nome_var].tamanho = novo_tamanho;
    }
    else
    {
        yyerror("Variável '" + nome_var + "' não encontrada no escopo atual.");
    }
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

void genWDargs()
{
    wdUsed = (wdUsed) ? wdUsed : true;
    WDarg wd;
    wd.guards = genTempCode("int*");
    wd.count = genTempCode("int");
    wd.choice = genTempCode("int");
    wd.label = genLabel();
    wd.nCLAUSES = 0;
    pilha_wd.push_back(wd);
}

void delWDargs()
{
    if (!pilha_wd.empty())
    {
        pilha_wd.pop_back();
    }
    else
    {
        yyerror("Pilha de WDargs vazia.");
    }
}

void makeOp(atributos& $$, atributos $1, atributos $2, atributos $3)
{
    $$.label = genTempCode("int");
    if ($1.tipo == "bool")
    {
        yyerror("operação indisponível para tipo " + $1.tipo);
    }
    if ($3.tipo == "bool")
    {
        yyerror("operação indisponível para tipo " + $3.tipo);
    }
    if ($1.tipo != $3.tipo)
    {
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

bool isInteger(const string& s) {
    if (s.empty()) return false;
    size_t start = (s[0] == '-' || s[0] == '+') ? 1 : 0;
    if (start == s.size()) return false; // Only sign, no digits
    for (size_t i = start; i < s.size(); ++i) {
        if (!std::isdigit(s[i])) return false;
    }
    return true;
}

string zerarVetor(string id, int n)
{
    string inicio = genLabel();
    string fim = genLabel();
    string iterator = genTempCode("int");
    string cond = genTempCode("bool");
    return "\t" + iterator + " = 0;\n" + inicio + ":\n" + "\t" + cond + " = (" + iterator + " < " + to_string(n) + ");\n" + "\tif (!" + cond + ") goto " + fim + ";\n" + "\t" + id + "[" + iterator + "] = 0;\n" + "\t" + iterator + " = " + iterator + " + 1;\n" + "\tgoto " + inicio + ";\n" + fim + ":\n";
}

string replace(const string& original, const string& alvo, const string& novoValor)
{
    if (alvo.empty())
        return original;
    string resultado = original;
    size_t pos = 0;
    while ((pos = resultado.find(alvo, pos)) != string::npos)
    {
        resultado.replace(pos, alvo.length(), novoValor);
        pos += novoValor.length();
    }
    return resultado;
}


string len(string buffer, string tamanho, string cond, string label)
{
    string c = genTempCode("char");
    string cp = genTempCode("char*");
    string output = "\t" + tamanho + " = 0;\n" + label + ":\n\t"
        + cp + " = " + buffer + "+" + tamanho + ";\n\t"
        + c + " = *" + cp + ";\n\t"
        + cond + " = (" + c + " != '\\0');\n"
        + "\tif (!" + cond + ") goto " + label + "_end;\n"
        + "\t" + tamanho + " = " + tamanho + " + 1;\n"
        + "\tgoto " + label + ";\n" + label + "_end:\n\t"
        + "\t" + tamanho + " = " + tamanho + " - 1;\n\t"
        + cp + " = " + tamanho + " + " + buffer + ";\n\t"
        + "*" + cp + " = '\\0';\n";
    return output;
}

string genStringcmp() {
    Variavel v1, v2, v3;
    v1.nome = "c1";
    v1.tipo = "char";
    v1.id = "c1";
    v2.nome = "c2";
    v2.tipo = "char";
    v2.id = "c2";
    v3.nome = "b";
    v3.tipo = "bool";
    v3.id = "b";
    variaveis.insert(v1);
    variaveis.insert(v2);
    variaveis.insert(v3);
    return "bool stringcmp(char* s1, char* s2) {\n"
        "\tchar c1;\n"   // <-- Declarada localmente
        "\tchar c2;\n"   // <-- Declarada localmente
        "\tbool b;\n"    // <-- Declarada localmente
        "L0:\n"
        "\tc1 = *s1;\n"
        "\tc2 = *s2;\n"
        "\tb = (c1 != c2);\n"
        "\tif (b) goto L1;\n"
        "\tb = c1 == '\\0';\n"
        "\tif (b) goto L2;\n"
        "\ts1 = s1 + 1;\n"
        "\ts2 = s2 + 1;\n"
        "\tgoto L0;\n"
        "L1:\n"
        "\treturn F;\n"
        "L2:\n"
        "\treturn T;\n}\n";
}

// Função auxiliar que gera o código C para a operação append
// e REGISTRA as variáveis temporárias que cria.
string append_code(string vet_id, string tipo_base, string val_label) {
    string l_realloc = genLabel();
    string cond_realloc = genTempCode("bool"); // Usa genTempCode
    string nova_capacidade = genTempCode("int");  // Usa genTempCode
    string cond_nova_cap = genTempCode("bool"); // Usa genTempCode

    string code;
    code += "\t" + cond_realloc + " = " + vet_id + ".tamanho == " + vet_id + ".capacidade;\n";
    code += "\tif (!" + cond_realloc + ") goto " + l_realloc + ";\n";
    code += "\t" + cond_nova_cap + " = " + vet_id + ".capacidade == 0;\n";
    code += "\t" + nova_capacidade + " = " + cond_nova_cap + " ? 8 : " + vet_id + ".capacidade * 2;\n";
    code += "\t" + vet_id + ".data = realloc(" + vet_id + ".data, " + nova_capacidade + " * " + vet_id + ".tam_elemento);\n";
    code += "\t" + vet_id + ".capacidade = " + nova_capacidade + ";\n";
    code += l_realloc + ":\n";
    
    // Diferencia se estamos adicionando um valor (int, float) ou outra struct Vetor
    if (tipo_base == "struct Vetor") {
        code += "\t((struct Vetor*)" + vet_id + ".data)[" + vet_id + ".tamanho] = " + val_label + ";\n";
    } else {
        code += "\t((" + tipo_base + "*)" + vet_id + ".data)[" + vet_id + ".tamanho] = " + val_label + ";\n";
    }
    
    code += "\t" + vet_id + ".tamanho = " + vet_id + ".tamanho + 1;\n";
    return code;
}