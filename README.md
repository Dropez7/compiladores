# Compilador da linguagem Maphra
Maphra é uma linguagem de programação criada na disciplina de compiladores do curso de Ciência da Computação da UFRRJ, a linguagem é baseada na tradução de expressões para código de 3 endereços em C.
![peixinho](img/peixinho.svg)


## Olá, Mundo!
O programa mais simples que pode ser escrito em Maphra:

```maphra
func main() {
    print("Olá Mundo a partir de Maphra!");
}
```

## Recursos da Linguagem

### 1. Sintaxe Básica

#### Quebras de Linha
Cada linha de código pode ou não terminar com `;`, seu uso é facultativo:

```maphra
print("Olá");
print("Mundo")
```

#### Comentários
Suporta comentários de linha única e de múltiplas linhas, como em C:

```maphra
// Este é um comentário de uma linha.

/*
  Este é um comentário
  de múltiplas linhas.
*/
```

---

### 2. Tipos e Variáveis

#### Tipos Primitivos
Suporta os tipos: `int`, `float`, `bool` (`T` para verdadeiro, `F` para falso) e `string`.

#### Declaração e Atribuição

```maphra
// Declaração explícita
int a;
a = 10;
float b = 3.14;
bool c = T;
string d = "Olá!";

// Declaração implícita (o tipo 'int' é inferido)
variavel_nova = 2025;
```

#### Troca de Variáveis

```maphra
int x = 10;
int y = 20;
x, y = y, x; // Agora x = 20 e y = 10
```

---

### 3. Operadores e Expressões

#### Aritméticos
```maphra
a = 10 + 5; // Soma
b = a - 5;  // Subtração
c = b * 2;  // Multiplicação
d = c / 4;  // Divisão

d++;        // Pós-incremento
d--;        // Pós-decremento
d += 10;    // Atribuição com soma
```

#### Lógicos
```maphra
a ^ b     // E lógico
a ? b     // OU lógico
~a        // Negacão lógica
```

#### Condicional (Ternário)
```maphra
int idade = 21;
string status = "Maior de idade" if idade >= 18 else "Menor de idade";
print(status);
```

---

### 4. Entrada e Saída (I/O)

```maphra
string nome = "Maphra";
print("Bem-vindo à linguagem", nome);

int idade = input("Digite sua idade: ");
print("Daqui a 10 anos, você terá:", idade + 10);
```

---

### 5. Estruturas de Controle

#### if / else
```maphra
a = 3;
b = 3;

if (a < b) {
print("'a' é menor que 'b'");
} else if (a == b) {
    print("'a' é igual a 'b'");
} else {
    print("'a' é maior que 'b'");
}
```

#### switch
```maphra
int num = 1;

switch (num) {
    opt 1:
        print("É o numero 1");
        break;
    dafoe:
        print("Não sei que número é.");
}
```

---

### 6. Laços de Repetição

#### Estilo C
```maphra
for (i = 0; i < 5; i++) {
    if (i == 3) { continue; }
    print(i);
}
```

#### Estilo "while"
```maphra
int j = 3;
for (j > 0) {
    print(j);
    j--;
}
```

#### Estilo "do-while"
```maphra
int k = 0;
do {
    print("Executou!");
    k++;
} for (k < 1);
```

---

### 7. Funções e Structs

#### Funções
```maphra
func soma(int a, int b) : int {
    return a + b;
}

func saudacao(string nome) {
    print("Olá,", nome);
}
```

#### Structs
```maphra
struct Ponto {
    float x;
    float y;
}

struct Retangulo {
    Ponto superior_esquerdo;
    Ponto inferior_direito;
}
```

#### Métodos com `bind`
```maphra
bind Retangulo calcularArea() : float {
    float base = this.inferior_direito.x - this.superior_esquerdo.x;
    float altura = this.superior_esquerdo.y - this.inferior_direito.y;
    return base * altura;
}

func main() {
    Retangulo r;
    // ... inicializa os pontos de r ...
    print("A área é:", r.calcularArea());
}
```

---

### 8. Vetores Dinâmicos

#### Declaração e Métodos
```maphra
string cores[];
cores.append("vermelho");
cores.append("verde");
print("Tamanho:", cores.len());
cores.remove(0);
```

#### Acesso, Slices, for-in
```maphra
int numeros[];
numeros.append(10);
numeros.append(20);
numeros.append(30);
numeros.append(40);

print("Primeiro elemento:", numeros[0]);

int fatia[] = numeros[1:3];

for (int el in fatia) {
    print(el);
}
```

#### Matrizes (vetores de vetores)
```maphra
int matriz[][];
matriz.append([1, 2, 3]);
matriz.append([4, 5, 6]);

print(matriz[0][1]); // Saída: 2
```

---

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