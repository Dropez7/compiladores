# Guia de Recursos da Linguagem MAPHRA

Este documento demonstra as principais funcionalidades e a sintaxe da linguagem de programação MAPHRA.

## 1. Definições Globais

É possível declarar `structs` e variáveis em escopo global, fora de qualquer função.

### Structs

A linguagem suporta a definição de estruturas de dados (`struct`), que podem inclusive ser aninhadas.

```
struct Ponto {
    float x;
    float y;
}

struct Retangulo {
    Ponto superior_esquerdo;
    Ponto inferior_direito;
    string nome;
}
```

### Variáveis Globais

Variáveis podem ser declaradas e inicializadas em escopo global.

```
int id_global = 100;
```

## 2. Funções e Métodos

### Funções Padrão

Funções podem ter um tipo de retorno explícito (ex: `: float`) ou implícito (`void`).

```
// Função com retorno explícito
func calcularArea(Retangulo r) : float {
    float base = r.inferior_direito.x - r.superior_esquerdo.x;
    float altura = r.superior_esquerdo.y - r.inferior_direito.y;
    return base * altura;
}

// Procedimento (retorno void)
func imprimirPonto(Ponto p) {
    print("Ponto(x:", p.x, ", y:", p.y, ")");
}
```

### Métodos com `bind`

É possível "vincular" uma função a uma `struct` para que ela atue como um método. A palavra-chave `this` se refere à instância do objeto.

```
struct Circulo {
    float raio;
}

// Vincula a função 'area' à struct 'Circulo'
bind Circulo area() : float {
    return 3.14159 * this.raio * this.raio;
}

func main() {
    Circulo c;
    c.raio = 10.0;
    print(c.area()); // Chama o método vinculado
}

```

## 3. A Função `main` e Recursos da Linguagem

A execução do programa começa na função `main`.

### 3.1. Tipos, Declarações e I/O

#### Tipos Primitivos e Declaração

A linguagem suporta os tipos `int`, `float`, `bool` e `string`. A declaração pode ser explícita ou implícita (com inferência de tipo).

```
// Declaração explícita
int idade = 30;
float pi_aprox = 3.14;
bool compilador_legal = T; // T para true, F para false
string mensagem = "Olá, Mundo!";

// Declaração implícita (tipo 'int' é inferido)
variavel_nova = 2025;
```

#### Entrada e Saída (I/O)

- `print()`: Exibe um ou mais valores na saída.
- `input()`: Lê uma string da entrada, opcionalmente com uma mensagem.

```
print("Bem-vindo,", nome, "!");

string nome_usuario = input("Digite seu nome: ");
```

### 3.2. Operadores e Expressões

#### Operadores Lógicos e Relacionais

- Lógicos: `^` (AND), `?` (OR), `~` (NOT)
- Relacionais: `==`, `!=`, `<`, `>`, `<=`, `>=`

```
idade = 20;
compilador_legal = T;

if (idade > 18 ^ compilador_legal) {
    print("Idade maior que 18 E compilador é legal.");
}

if (~compilador_legal) {
    print("O compilador NÃO é legal.");
}
```

#### Troca de Variáveis

Uma sintaxe especial permite a troca de valores entre duas variáveis.

```
int a = 10;
int b = 99;
a, b = b, a; // Agora a = 99 e b = 10
```

#### Cast (Conversão de Tipo)

Conversão explícita de um tipo para outro.

```
float valor_quebrado = 3.14;
int valor_inteiro = int(valor_quebrado); // Resulta em 3
```

#### Expressão Condicional (Ternário)

Permite escrever uma expressão `if-else` em uma única linha.

```
int idade = 21;
string status = "Maior de idade" if idade >= 18 else "Menor de idade";

print("A pessoa é " + ("adulta" if idade >= 18 else "jovem") + ".");
```

### 3.3. Estruturas de Controle

#### `if / else` e `switch`

Controle de fluxo condicional padrão. O `switch` utiliza a palavra-chave `option`.

```
// if-else
a = 1;
b = 2;

if (a < b) {
    print("'a' é menor que 'b'.");
}

// switch
switch(a) {
    option 10: print("a é 10."); break;
    option 99: print("a é 99."); break;
    default: print("outro valor.");
}
```

#### Laços de Repetição (`for`)

A linguagem suporta múltiplos estilos de laço com a palavra-chave `for`.

```
// 1. Estilo C, com break e continue
for (i = 0; i < 10; i++) {
    if (i == 7) { break; }
    print(i);
}

// 2. Estilo "while"
int j = 3;
for (j > 0) {
    print(j);
    j--;
}

// 3. Estilo "do-while" (usa 'do' e 'for')
int k = 0;
do {
    print("Executou pelo menos uma vez!");
    k++;
} for (k < 1);

// 4. Estilo "foreach" (com 'in')
string palavras[];
palavras.append("Compilador");
palavras.append("é");
palavras.append("legal");

for (string p in palavras) {
    print(p);
}
```

### 3.4. Vetores Dinâmicos (Arrays)

Vetores são dinâmicos e podem crescer em tempo de execução.

#### Declaração e Métodos

```
// Declara um vetor de strings
string cores[];

// Adiciona elementos
cores.append("vermelho");
cores.append("verde");

// Acessa o tamanho
print("Tamanho:", cores.len()); // Saída: 2

// Remove um elemento pelo índice
cores.remove(0); // Remove "vermelho"
```

#### Acesso a Elementos e Slices (Fatias)

O acesso pode ser feito por índice ou por "slice" para criar um sub-vetor.

```

int numeros[];
numeros.append(10);
numeros.append(20);
numeros.append(30);
numeros.append(40);

// Cria um novo vetor 'fatia' com os elementos [20, 30]
int fatia[] = numeros[1:3];
for (int el in fatia) {
    print(el); // Saída: 20, 30
}
```

#### Matrizes (Vetor de Vetores)

Matrizes são implementadas como vetores de vetores.

```
int matriz[][];
    matriz.append([1, 2, 3]);
    matriz.append([4, 5, 6]);

    print(matriz[0][1]); // Saída: 2
```

### 3.5. Comandos Especiais

#### `wheeldecide` (`wd`)

Executa **aleatoriamente uma** das cláusulas cuja condição seja verdadeira.

```
wd {
        opt 1 > 0 print("Opção A") // pode executar esta
        opt 2 > 0 print("Opção B") // ou pode executar esta
    }
```

#### Laço `do-wd`

Executa o bloco `wd` repetidamente enquanto **pelo menos uma** das condições for verdadeira.

```
int contador = 2;
do wd {
    opt contador > 0 {
        print("Executando o DO-WD, contador =", contador);
        contador--;
    }
}
// O laço termina quando 'contador' chega a 0.
```

Exemplo interessante para demonstração:

```
func main() {
    int vida_jogador = 10;
    int vida_monstro = 15;

    print("Uma batalha começou!");

    do wd {
        // Opção 1: Atacar o monstro. Só é válida se ambos estiverem vivos.
        opt vida_jogador > 0 ^ vida_monstro > 0 {
            print("Você ataca o monstro!");
            vida_monstro = vida_monstro - 5;
            print("Vida do monstro:", vida_monstro);
        }

        // Opção 2: O monstro ataca. Só é válida se ambos estiverem vivos.
        opt vida_jogador > 0 ^ vida_monstro > 0 {
            print("O monstro ataca você!");
            vida_jogador = vida_jogador - 3;
            print("Sua vida:", vida_jogador);
        }

        // Opção 3: Fim da batalha por vitória.
        opt vida_monstro <= 0 {
            print("Você venceu a batalha!");
            break; // Sai do laço do-wd
        }

        // Opção 4: Fim da batalha por derrota.
        opt vida_jogador <= 0 {
            print("Você foi derrotado!");
            break; // Sai do laço do-wd
        }
    }

    print("A batalha terminou.");
}
```
