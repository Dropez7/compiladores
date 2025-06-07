# Compilador da linguagem Maphra
![peixinho](img/peixinho.svg)

## TO-DO (Etapa 1)
- [X] Expressão com soma
  - Fazer a soma sobre inteiros funcionar.

Código na LP: 
```C
1 + 2 + 3;
```

Código Intermediário:
```C
T1 = 2;
T2 = 3;
T3 = T1 + T2;
T4 = 1;
T5 = T4 + T3;
```

---
- [X] Expressão com os Demais Operadores Aritméticos  
  - Fazer as demais operações aritméticas sobre inteiros funcionarem.

Código na LP:
```C
1 + 2 * 3;
```

Código Intermediário:
```C
T1 = 2;
T2 = 3;
T3 = T1 * T2;
T4 = 1;
T5 = T4 + T3;
```

---
- [X] Declaração das Cédulas de Memória Usadas  
  - Deverá declarar antes do código todas as cédulas de memória utilizadas.

Código na LP:
```C
1 + 2 * 3;
```

Código Intermediário:
```C
int T1;
int T2;
int T3;
int T4;
int T5;

T1 = 2;
T2 = 3;
T3 = T1 * T2;
T4 = 1;
T5 = T4 + T3;
```

**OBS:** Nesse momento, já é possível compilar esse código em C. A principal dificuldade passa a ser a necessidade de impressão do resultado para verificar se a conta está correta.

---
- [X] Desenvolvimento do Parênteses
  - Deverá permitir o uso de parênteses nas expressões.

Código na LP:
```C
(1 + 2) * 3;
```

Código Intermediário:
```C
int T1;
int T2;
int T3;
int T4;
int T5;

T1 = 1;
T2 = 2;
T3 = T1 + T2;
T4 = 3;
T5 = T4 * T3;
```

---
- [X] Atribuição  
  - Deverá permitir a atribuição a uma variável e sua utilização em expressões.

Código na LP:
```C
A = (A + 2) * 3;
```

Código Intermediário:
```C
int T1;
int T2;
int T3;
int T4;
int T5;

T1 = A;
T2 = 2;
T3 = T1 + T2;
T4 = 3;
T5 = T4 * T3;
A = T5;
```

**OBS:** Esse código volta a ter problemas de compilação, pois ainda não resolvemos a alocação da variável no código intermediário.

---
- [X] Declaração  
  - Deverá criar uma tabela de símbolos para representar as cédulas de memória alocadas pelo usuário. Esse é um exemplo de declaração explícita, mas outras variações de design são possíveis.

Código na LP:
```C
int A;
A = (A + 2) * 3;
```

Código Intermediário:
```C
int T1;
int T2;
int T3;
int T4;
int T5;

T2 = 2;
T3 = T1 + T2;
T4 = 3;
T5 = T4 * T3;
T1 = T5;
```

**OBS:** É possível adicionar comentários ao código gerado para facilitar a depuração.

---
- [X] Tipo Float  
  - Deverá ser possível utilizar o tipo `float`. Para isso, será necessário alterar a tabela de símbolos para armazenar o tipo da variável. Além disso, será preciso carregar o tipo resultante entre os nós da expressão.

Código na LP:
```C
int A;
A = (A + 2) * 3.0;
```

Código Intermediário:
```C
int T1;
int T2;
int T3;
float T4;
int T5;

T2 = 2;
T3 = T1 + T2;
T4 = 3.0;
T5 = T4 * T3;
A = T5;
```

---
- [X] Tipos char e boolean  
  - Deverá ser possível declarar e utilizar variáveis dos tipos `char` e `boolean`.

Código na LP:
```C
char C;
C = 'a';

bool B;
B = T;
```

Código Intermediário:
```C
char T1;
int T2;

T1 = 'a';
T2 = 1;
```

**OBS:** Lembrando que não existe tipo `bool` no código intermediário. Contudo, macros podem ser usadas para melhorar a legibilidade do código.

---

- [X] Operadores Relacionais  
  - Permitir expressões com operadores relacionais (`<`, `<=`, `>`, `>=`, `==`, `!=`). O resultado da operação deve ser tratado como valor lógico.

Código na LP:
```C
bool R;
R = 3 < 5;
```

Código Intermediário:
```C
int T1;
int T2;
int T3;
int T4;

T1 = 3;
T2 = 5;
T3 = T1 < T2;
T4 = T3;
```

---
- [X] Operadores Lógicos  
  - Implementar os operadores lógicos `&&`, `||` e `!`. Deve-se verificar a compatibilidade de tipos nas expressões lógicas.

Código na LP:
```C
bool B1;
bool B2;
bool R;
R = B1 ^ ~B2;
```

Código Intermediário:
```C
int T1;
int T2;
int T3;
int T4;
int T5;

T2 = !T1;
T4 = T3 && T2;
T5 = T4;
```

---
- [X] 11 Conversão Implícita  
  - Deverá ocorrer a conversão automática de `int` para `float` em expressões mistas. Essa conversão deve ser aplicada na geração do código intermediário. Será necessário criar uma tabela de conversão para determinar os tipos resultantes. Estratégias como as usadas em Ada não serão aceitas.

Código na LP:
```C
float F;
int I;
F = I + 2.5;
```

Código Intermediário:
```C
int T1;
float T2;
float T3;
float T4;
float T5;

T2 = (float) T1;
T3 = 2.5;
T4 = T2 + T3;
T5 = T4;
```

**OBS:** A conversão pode ser validada na análise semântica para evitar operações inválidas.

---
- [X] Conversão Explícita  
  - Permitir expressões com casting explícito. A conversão deverá ser aplicada diretamente no código intermediário.

Código na LP:
```C
int I;
float F;
I = (int) F;
```

Código Intermediário:
```C
float T1;
float T2;
int T3;
int T4;

T2 = T1;
T3 = (int) T2;
T4 = T3;
```

**OBS:** O cast explícito pode ser validado na análise semântica para evitar conversões inválidas.