# Compilador da linguagem Maphra
Maphra é uma linguagem de programação criada na disciplina de compiladores do curso de Ciência da Computação da UFRRJ, a linguagem é baseada na tradução de expressões para código de 3 endereços em C.
![peixinho](img/peixinho.svg)


## Recursos da Linguagem

### 1. Sintaxe Básica

#### Quebras de Linha
Cada linha de código pode ou não terminar com `;`, seu uso é facultativo:

```go
print("Hello");
print("World!")
```

#### Comentários
Suporta comentários de linha única e de múltiplas linhas:

```go
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

```go
int a
a = 10
float b = 3.14
bool c = T
string d = "Olá!"

e = 2025
```

#### Troca de Variáveis

```go
int x = 10;
int y = 20;
x, y = y, x;
```

---

### 3. Operadores e Expressões

#### Aritméticos
```go
a = 10 + 5;
b = a - 5; 
c = b * 2; 
d = c / 4;

d++;       
d--;       
d += 10;   
```

#### Lógicos
```go
a ^ b
a ? b
~a   
```

#### Condicional (Ternário)
```go
int idade = 21;
string status = "Maior de idade" if idade >= 18 else "Menor de idade";
print(status);
```

---

### 4. Entrada e Saída (I/O)

```go
print("É possível imprimir diversos argumentos", 1, 3.14, foo)

int a = input("Digite um número: ")
string b
b = input("Digite uma string: ")
```

---

### 5. Estruturas de Controle

#### if / else
```go
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
```go
foo = "hello"

switch (foo) {
  case "hello":
    print("foo é hello")
    break
  case "world":
    print("foo é world")
    break
  dafoe:
    print("foo não é nem hello nem world")
}
```

---

### 6. Laços de Repetição

#### for
```go
for (i = 0; i < 5; i++) {
    if (i == 3) { 
        continue;
    }
    print(i);
}
```

#### while
```go
int j = 5;
for (j > 0) {
    if (j == 2) {
        break
    }
    print(j);
    j--;
}
```

#### do-while
```go
int k = 0;
do {
    print(k);
    k++;
} for (k < 1);
```

---

### 7. Funções e Structs

#### Funções
As funções são declaradas com a palavra-chave `func`, o tipo de retorno é opcional, caso não seja declarado, a função retornará `void`

```go
func soma(int a, int b): int {
  return a + b
}

func saudacao(string name){
  print("Hello,", name + "!")
}
```

Funções são identificadas pelo nome e seus argumentos, o que permite a sobrecarga de funções

```go
func produto(int a, int b): int {
  return a * b
}

func produto(Point p): int {
  return p.x * p.y
}
```

#### Structs
Structs são suportados como em C

```
struct Point {
  int x
  int y
}
```
Também é possível criar structs aninhados

```go
struct Square {
  Point p1
  Point p2
  Point p3
  Point p4
}
```
Além disso, é possível definir métodos para os structs utilizando a palavra-chave `bind`

```go
bind Square getArea(): int {
  return (this.p2.x - this.p1.x) * (this.p3.y - this.p1.y)
}
```

Variáveis básicas como `int`, `float`, `bool` e `string` também permitem a criação de métodos

```go
bind float squared(float a): float {
  return a * a
}
```

---

### 8. Vetores Dinâmicos

#### Declaração e Métodos
```go
string cores[];
cores.append("vermelho");
cores.append("verde");
print("Tamanho:", cores.len());
cores.remove(0);
```

#### Acesso, Slices, for-in
```go
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
```go
int matriz[][]
matriz.append([1, 2, 3])
matriz.append([4, 5, 6])

print(matriz[0][1])
```

---

#### `wd` (`wheeldecide`)

Por fim, os comandos guardados de Djikstra também são suportados através da palavra-chave `wd` (ou `wheeldecide`)

```go
wheeldecide {
  opt T {
    print("o sorteado foi 1")
  }
  opt T {
    print("o sorteado foi 2")
  }
  opt T {
    print("o sorteado foi 3")
  }
}
```
Também é possível fazer um loop

```
do wd {
    opt q1 > q2 {
        q1, q2 = q2, q1
    }
    opt q2 > q3 {
        q2, q3 = q3, q2
    }
    opt q3 > q4 {
        q3, q4 = q4, q3
    }
}
```