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
    string traducaoAlt;
    string tipo;
    int nivelAcesso = 0;
    bool ehDinamico = false;
    int numDimensoes = 0;
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
    string c_parametros;
    string id;
};
bool operator<(const Funcao& a, const Funcao& b)
{
    return a.id < b.id;
}

struct Metodo
{
    string nome;
    string prototipo;
    string tipo_retorno;
    string parametros;
    string id;
    string tipo_objeto; 
};
bool operator<(const Metodo& a, const Metodo& b)
{
    return a.id < b.id;
}

struct TipoStruct {
    string id;
    set<Variavel> atributos;
};
bool operator<(const TipoStruct& a, const TipoStruct& b)
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
bool strCompared = false;
bool vectorUsed = false;
bool removeUsed = false;
bool sliceUsed = false;
bool canBreak = false;
bool canContinue = false;
bool hasReturned = false;
bool inMetodo = false;
string returnType;
string structVetor = "struct Vetor {\n\tvoid* data;\n\tint tamanho;\n\tint capacidade;\n\tsize_t tam_elemento;\n};\n\n";
string tipoMetodo;
void yyerror(string);
set<Variavel> variaveis;
set<Funcao> funcoes;
set<Metodo> metodos;
set<TipoStruct> structs;
vector<string> structDef;
set<string> free_vars;
vector<string> vetores_a_liberar;
vector<map<string, Variavel>> pilha_escopos;
vector<WDarg> pilha_wd;

string replace(const string&, const string&, const string&);

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

bool isDefaultType(const string& tipo) {
    return tipo == "int" || tipo == "float" || tipo == "char*" || tipo == "bool" || tipo == "string";
}

void genPrototipo(Funcao& f)
{
    if (f.parametros.empty())
    {
        f.prototipo = f.tipo_retorno + " " + f.id + "(void);\n";
        return;
    }

    string c_param_list_str = "";
    vector<string> param_types = split(f.parametros, " ");
    bool first = true;

    for (const auto& type : param_types)
    {
        if (type.empty()) continue;

        if (!first) {
            c_param_list_str += ", ";
        }

        string c_type;

        if (type.length() > 2 && type.substr(type.length() - 2) == "[]")
        {
            c_type = "struct Vetor";
        }
        else if (!isDefaultType(type))
        {
            c_type = "struct " + type;
        }
        else
        {
            c_type = type;
        }

        c_param_list_str += c_type;
        first = false;
    }

    f.prototipo = f.tipo_retorno + " " + f.id + "(" + c_param_list_str + ");\n";
}

// gera as variáveis temporárias
string genTempCode(string tipo)
{
    if (pilha_escopos.empty())
    {
        yyerror("Erro Critico: Nao ha escopo ativo para declarar a variavel temporaria.");
    }
    string tipo_c = replace(tipo, "string", "char*");

    map<string, Variavel>& escopo_atual = pilha_escopos.back();

    Variavel v;
    v.nome = to_string(var_temp_qnt);
    v.tipo = tipo_c;
    v.id = genId();
    variaveis.insert(v);

    escopo_atual[v.nome] = v;
    return v.id;
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

void declararVariavel(const string& nome_var, const string& tipo_var, const string& tamanho, int numDimensoes = 0)
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
    v.numDimensoes = numDimensoes; 

    // Simplificação: se tem dimensões, é dinâmico.
    if (numDimensoes > 0) {
        v.ehDinamico = true;
    }

    variaveis.insert(v);
    escopo_atual[nome_var] = v;
}

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

void declararFuncao(atributos& $1, string tipos, string retorno, string c_params_traducao) {
    for (const Funcao& func : funcoes) {
        if (func.nome == $1.label && func.parametros == tipos) {
            yyerror("Função '" + $1.label + "' com a mesma assinatura já foi declarada.");
            return;
        }
    }
    if ($1.label == "main") {
        yyerror("função main já declarada");
    }

    Funcao f;
    f.nome = $1.label;
    f.tipo_retorno = retorno;
    f.parametros = tipos;
    f.id = genId();

    string params_limpo = replace(c_params_traducao, ") {\n", "");
    f.prototipo = f.tipo_retorno + " " + f.id + "(" + params_limpo + ");\n";

    funcoes.insert(f);
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

void declararMetodo(const atributos& $1, const string& tipo_objeto, const string& tipos, const string& retorno)
{
    for (const Metodo& met : metodos)
    {
        if (met.nome == $1.label && met.parametros == tipos && met.tipo_objeto == tipo_objeto)
        {
            yyerror("Método '" + $1.label + "' já declarado para o tipo '" + tipo_objeto + "'.");
        }
    }

    Metodo m;
    m.nome = $1.label;
    m.tipo_retorno = retorno;
    m.parametros = tipos;
    m.id = genId();
    m.tipo_objeto = tipo_objeto;
    metodos.insert(m);
}

Metodo getMetodo(const string& nome_metodo, const string& tipo_objeto, const string& tipos)
{
    for (const Metodo& met : metodos)
    {
        if (met.nome == nome_metodo && met.parametros == tipos && met.tipo_objeto == tipo_objeto)
        {
            return met;
        }
    }
    yyerror("Método '" + nome_metodo + "' com parâmetros do tipo '" + tipos + "' não encontrado para o tipo '" + tipo_objeto + "'.");
    Metodo m_erro;
    m_erro.nome = nome_metodo;
    m_erro.tipo_retorno = "error_not_found";
    m_erro.parametros = "";
    m_erro.id = "<error_id>";
    m_erro.tipo_objeto = "<error_object_type>";
    return m_erro;
}

void entrarMetodo(string tipo) {
    inMetodo = true;
    tipoMetodo = tipo + "|" + genTempCode(tipo);
}

void sairMetodo() {
    inMetodo = false;
}

void declararStruct(const string& nome_struct, const string& atributos)
{
    if (nome_struct == "Vetor") {
        yyerror("Nome de estrutura reservado");
    }
    for (const TipoStruct& ts : structs)
    {
        if (ts.id == nome_struct)
        {
            yyerror("Estrutura '" + nome_struct + "' já declarada.");
            return;
        }
    }
    TipoStruct ts;
    ts.id = "struct " + nome_struct;
    vector<string> attrs = split(atributos, " ");
    for (int i = 0; i < attrs.size(); i += 2)
    {
        Variavel v;
        v.tipo = attrs[i];
        v.id = attrs[i + 1];
        for (const Variavel& var : ts.atributos) {
            if (var.id == v.id) {
                yyerror("Múltiplos atributos '" + v.id + "' na estrutura '" + nome_struct + "'.");
                return;
            }
        }
        ts.atributos.insert(v);
    }
    structs.insert(ts);
}

TipoStruct getStruct(const string& nome_struct)
{
    string nome = "struct " + nome_struct;
    for (const TipoStruct& ts : structs)
    {
        if (ts.id == nome)
        {
            return ts;
        }
    }
    yyerror("Estrutura '" + nome_struct + "' não encontrada.");
    TipoStruct ts_erro;
    ts_erro.id = nome_struct;
    return ts_erro;
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
    if ($1.tipo == $2.tipo) {
        $$.label = genTempCode($1.tipo);
    }
    else {
        $$.label = genTempCode("float");
    }
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

        else if (v.tipo == "string" && b.tipo == "char*")
        {
            return a.traducao + b.traducao + "\t" + v.id + " = " + b.label + ";\n";
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
    if (start == s.size()) return false;
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
    return "\t" + iterator + " = 0;\n" + inicio + ":\n" + "\t" + cond + " = (" + iterator + " >= " + to_string(n) + ");\n\tif (" + cond + ") goto " + fim + ";\n" + "\t" + id + "[" + iterator + "] = 0;\n" + "\t" + iterator + " = " + iterator + " + 1;\n" + "\tgoto " + inicio + ";\n" + fim + ":\n";
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
        + cond + " = (" + c + " == '\\0');\n"
        + "\tif (" + cond + ") goto " + label + "_end;\n"
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

string append_code(string vet_id, string tipo_base, string val_label) {

    string l_realloc_fim = genLabel();
    string l_ternario_else = genLabel();
    string l_ternario_fim = genLabel();

    string cond_realloc = genTempCode("bool");
    string nova_capacidade = genTempCode("int");
    string cond_nova_cap = genTempCode("bool");
    string tam_bytes = genTempCode("size_t");
    string novo_dado_ptr = genTempCode("void*");
    string cast_ptr = genTempCode(tipo_base + "*");
    string dest_ptr = genTempCode(tipo_base + "*");

    string code;

    code += "\t" + cond_realloc + " = " + vet_id + ".tamanho != " + vet_id + ".capacidade;\n";
    code += "\tif (" + cond_realloc + ") goto " + l_realloc_fim + ";\n";

    code += "\t" + cond_nova_cap + " = " + vet_id + ".capacidade != 0;\n";
    code += "\tif (" + cond_nova_cap + ") goto " + l_ternario_else + ";\n";
    code += "\t" + nova_capacidade + " = 8;\n";
    code += "\tgoto " + l_ternario_fim + ";\n";
    code += l_ternario_else + ":\n";
    code += "\t" + nova_capacidade + " = " + vet_id + ".capacidade * 2;\n";
    code += l_ternario_fim + ":\n";

    code += "\t" + tam_bytes + " = " + nova_capacidade + " * " + vet_id + ".tam_elemento;\n";
    code += "\t" + novo_dado_ptr + " = realloc(" + vet_id + ".data, " + tam_bytes + ");\n";
    code += "\t" + vet_id + ".data = " + novo_dado_ptr + ";\n";
    code += "\t" + vet_id + ".capacidade = " + nova_capacidade + ";\n";

    code += l_realloc_fim + ":\n";

    code += "\t" + cast_ptr + " = (" + tipo_base + "*)" + vet_id + ".data;\n";
    code += "\t" + dest_ptr + " = " + cast_ptr + " + " + vet_id + ".tamanho;\n";
    code += "\t*" + dest_ptr + " = " + val_label + ";\n";


    code += "\t" + vet_id + ".tamanho = " + vet_id + ".tamanho + 1;\n";

    return code;
}


// Função que implementa a lógica do slice
string genSliceFunction() {
    return
        "\nstruct Vetor __maphra_slice(struct Vetor* original, int start, int end) {\n"
        "    struct Vetor novo_vetor;\n"
        "    int num_elementos;\n"
        "    size_t total_bytes;\n"
        "    char* src_ptr;\n"
        "    int temp_cond;\n"
        "    int temp_val;\n"
        "    char* temp_ptr;\n\n"
        "    temp_cond = start < 0;\n"
        "    if (temp_cond) goto L_START_DEFAULT;\n"
        "    goto L_START_OK;\n"
        "L_START_DEFAULT:\n"
        "    start = 0;\n"
        "L_START_OK:\n"
        "    temp_cond = end < 0;\n"
        "    if (temp_cond) goto L_END_DEFAULT;\n"
        "    goto L_END_OK;\n"
        "L_END_DEFAULT:\n"
        "    temp_ptr = (char*)original; temp_ptr = temp_ptr + 8; /*offsetof(tamanho)*/\n"
        "    end = *((int*)temp_ptr);\n"
        "L_END_OK:\n\n"
        "    temp_ptr = (char*)original; temp_ptr = temp_ptr + 8; /*offsetof(tamanho)*/\n"
        "    temp_val = *((int*)temp_ptr);\n"
        "    temp_cond = start > end;\n"
        "    if (temp_cond) goto L_BOUNDS_ERROR;\n"
        "    temp_cond = start > temp_val;\n"
        "    if (temp_cond) goto L_BOUNDS_ERROR;\n"
        "    temp_cond = end > temp_val;\n"
        "    if (temp_cond) goto L_BOUNDS_ERROR;\n"
        "    goto L_BOUNDS_OK;\n"
        "L_BOUNDS_ERROR:\n"
        "    printf(\"Erro de execução: slice fora dos limites.\\n\");\n"
        "    exit(1);\n"
        "L_BOUNDS_OK:\n\n"
        "    num_elementos = end - start;\n"
        "    novo_vetor.tamanho = num_elementos;\n"
        "    novo_vetor.capacidade = num_elementos;\n"
        "    temp_ptr = (char*)original; temp_ptr = temp_ptr + 16; /*offsetof(tam_elemento)*/\n"
        "    novo_vetor.tam_elemento = *((size_t*)temp_ptr);\n\n"
        "    temp_cond = num_elementos > 0;\n"
        "    if (temp_cond) goto L_ALLOC_DATA;\n"
        "    novo_vetor.data = NULL;\n"
        "    goto L_ALLOC_END;\n"
        "L_ALLOC_DATA:\n"
        "    total_bytes = num_elementos * novo_vetor.tam_elemento;\n"
        "    novo_vetor.data = malloc(total_bytes);\n"
        "    temp_ptr = (char*)original; /*offsetof(data) is 0*/\n"
        "    temp_ptr = *((char**)temp_ptr);\n"
        "    temp_val = start * novo_vetor.tam_elemento;\n"
        "    src_ptr = temp_ptr + temp_val;\n"
        "    memcpy(novo_vetor.data, src_ptr, total_bytes);\n"
        "L_ALLOC_END:\n\n"
        "    return novo_vetor;\n"
        "}\n";
}

string genRemoveCode(){
    return
        "\nvoid __maphra_remove_element(struct Vetor* v, int index) {\n"
        "    int t_cond, t_size, t_move, t_offset_dest, t_offset_src;\n"
        "    char* p_base; char *p_dest, *p_src;\n"
        "\n"
        "    t_cond = v == NULL; if(t_cond) goto L_REM_EXIT;\n"
        "    t_size = *((int*)((char*)v + 8)); // v->tamanho\n"
        "    t_cond = t_size == 0; if(t_cond) goto L_REM_EXIT;\n"
        "    t_cond = index < 0; if(t_cond) goto L_REM_EXIT;\n"
        "    t_cond = index >= t_size; if(t_cond) goto L_REM_EXIT;\n"
        "\n"
        "    t_move = t_size - index; t_move = t_move - 1;\n"
        "    t_cond = t_move > 0; if(!t_cond) goto L_REM_NO_MOVE;\n"
        "\n"
        "    p_base = *((char**)((char*)v + 0)); // v->data\n"
        "    size_t elem_size = *((size_t*)((char*)v + 16)); // v->tam_elemento\n"
        "    t_offset_dest = index * elem_size;\n"
        "    p_dest = p_base + t_offset_dest;\n"
        "\n"
        "    t_offset_src = index + 1; t_offset_src = t_offset_src * elem_size;\n"
        "    p_src = p_base + t_offset_src;\n"
        "\n"
        "    size_t bytes_to_move = t_move * elem_size;\n"
        "    memmove(p_dest, p_src, bytes_to_move);\n"
        "\n"
        "L_REM_NO_MOVE:\n"
        "    t_size = t_size - 1;\n"
        "    *((int*)((char*)v + 8)) = t_size; // v->tamanho = t_size\n"
        "\n"
        "L_REM_EXIT:\n"
        "    return;\n"
        "}\n";
}