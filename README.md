# Compilador da linguagem Maphra
Maphra é uma linguagem de programação criada na disciplina de compiladores do curso de Ciência da Computação da UFRRJ, a linguagem é baseada na tradução de expressões para código de 3 endereços em C.
![peixinho](img/peixinho.svg)

 ## Quebras de linha
 Cada linha escrita pode ou não terminar com `;`, o uso é facultativo

```go
print("hello");
print("world")
```
## Comentários
Comentários de uma linha são feitos com `//`

```go
// Este é um comentário de uma linha
```
Comentários de múltiplas linhas são feitos com `/*` e `*/`

```go
/* Este é um comentário
de múltiplas linhas */
```

## Declarações/Atribuições
Declarações explícitas são suportadas

```go
int a
a = 10
float b = 3.14
```

Assim como declarações implícitas

```go
c = "hello world"
```

Também é possível trocar 2 variáveis previamente declaradas

```go
a = 10
b = 20
a, b = b, a
```

O tipo operador ternário também está presente

```go
a = 5 if (5 > 3) else 10
```

Declarações do tipo `bool` são feitas com as letras `T` e `F`

```go
bool a = T
bool b = F
```

## Operações
Operações aritméticas são suportadas normalmente

```go
a = 10 + 10
b = 10 - 5
c = 10 * 2
d = 10 / 2
```
Assim como operadores unários e atribuições simplificadas

```go
a++
a--
a += 5
a -= 2
a *= 3
a /= 2
```

Também existem os operadores lógicos `a ^ b` (and), `a ? b` (or) e `~a` (not)

## Entrada/Saída

A entrada e saída de dados é feita através das funções `print` e `input`

```go
print("É possível imprimir diversos argumentos", 1, 3.14, foo)

int a = input("Digite um número: ")
string b
b = input("Digite uma string: ")
```

## Strings

As strings em Maphra são dinâmicas, também é possível realizar algumas operações como:

```go
foo = "hello"
bar = "world"
foobar = foo + " " + bar
x = foobar.len()
```

## Vetores

## Funções
As funções são declaradas com a palavra-chave `func`, o tipo de retorno é opcional, caso não seja declarado, a função retornará `void`

```go
func soma(int a, int b): int {
  return a + b
}

func greeting(string name){
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

## Structs
Maphra possuí suporte a structs

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

## Comandos de controle/repetição
Maphra suporta os comandos básicos de controle como `if`, `else` (este que pode ser substituído por `helcio`) e `switch`

```go
if (1 < 2) {
  print("1 é menor que 2")
} else if (1 == 2) {
  print("1 é igual a 2")
} helcio {
  print("1 é maior que 2")
}
```

```
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

Os comandos de repetição `for`, `while`, e `do while` também são suportados

```go
for (int i = 0; i < 10; i++) {
  print(i)
}

for (i < 5) {
  print(i)
  i++
}

do {
  print(i)
  i++
} for (i < 5)
```

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

