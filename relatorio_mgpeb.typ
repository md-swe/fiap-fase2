#set page(paper: "a4", margin: 2.5cm)
#set text(lang: "pt", region: "br", size: 12pt)
#set par(justify: true)
#set heading(numbering: "1.")
#set math.equation(numbering: "(1)")

// trechos de código com fundo cinza e fonte menor
#show raw: set text(size: 9pt)
#show raw.where(block: true): block.with(fill: luma(245), inset: 8pt, radius: 3pt, width: 100%)

#let boxed(it) = align(center)[
  #box(stroke: 0.6pt, inset: 8pt)[
    #set math.equation(numbering: none)
    #it
  ]
]

#align(center)[ #text(
    size: 16pt, weight: "bold",
  )[ Relatório do Módulo de Gerenciamento de Pouso e Estabilização ] ]

#align(center)[ #text(
    size: 12pt,
  )[Cap 1 - A Aurora Ajusta a Trajetória na Aproximação a Marte - MGPEB ] ]

#align(center)[ #text(
    size: 10pt,
  )[Murilo da Silva Dias RM: 575146] ]

#v(1em)

= Introdução

O Módulo de Gerenciamento de Pouso e Estabilização é um dos módulos presentes na
Missão Aurora Siger. Ele é responsável, principalmente, por organizar os pousos
da colônia. Para isso, ele foi equipado com capacidades de leitura de status dos
outros módulos. Com esses dados, ele é capaz de determinar a capacidade de pouso
de cada um dos módulos presentes na nave.

= Contextualização Histórica e Arquitetural

== A Missão Aurora Siger

A Aurora Siger é uma missão espacial fictícia, criada para este projeto, que
busca estabelecer uma colônia a partir de módulos independentes: Habitação,
Energia, Laboratório, Médico e Logístico. Como cada módulo chega com um estado
diferente, é preciso um sistema que organize quem pousa primeiro e decida se o
pouso é seguro. Esse é o papel do MGPEB.

== Antecedentes

Frear com propulsores e decidir o momento do acionamento é um problema clássico
da exploração espacial. Na Apollo 11, em 1969, o computador do módulo lunar
descartou as tarefas menos importantes para manter as essenciais à descida,
ideia próxima à da fila de prioridade do MGPEB. O pouso propulsivo voltou a ser
central no rover Curiosity (2012) e nos foguetes reutilizáveis (2015). O MGPEB é
uma versão didática e simplificada desse problema.

== Evolução do MGPEB

+ *Estado dos módulos:* ordenação por prioridade e verificação das condições (`cheque_pouso`).
+ *Modelagem física:* cálculo da frenagem, ainda com os mesmos dados de voo para
  todos.
+ *Dados de voo por módulo:* decisão final combinando autorização e viabilidade.
+ *Estruturas lineares:* fila para a ordem de pouso e pilha para os resultados.

== Arquitetura

O MGPEB é um fluxo em uma só direção: dados, ordenação, fila, avaliação, pilha e
decisão final. Ele apenas lê os dados dos outros módulos e recomenda uma
decisão, sem controlar os propulsores.

#figure(
  text(
    size: 10.5pt, table(
      columns: (auto, auto, 1fr), align: (left, left, left), table.header[*Camada*][*Componentes*][*Responsabilidade*], [Dados], [`modulos`, constantes], [Estado, dados de voo e parâmetros do modelo.], [Organização], [`ordenar`, `fila`], [Ordem em que os módulos são atendidos.], [Decisão], [`cheque_pouso`, `calcular_pouso`], [Autorização de pouso e viabilidade da frenagem.], [Registro], [`pilha`], [Resultado de cada módulo processado.], [Apresentação], [`print`], [Resultado e motivos mostrados ao operador.],
    ),
  ), caption: [Camadas da arquitetura do MGPEB.],
)

= O Algoritmo de Pouso

A decisão do MGPEB é feita através de um algoritmo relativamente simples, que
combina com a modelagem do fenômeno de desaceleração. Ele segue cinco etapas:
população dos dados, ordenação por prioridade, criação das estruturas, avaliação
de cada módulo (autorização e frenagem) e decisão final.

== População dos dados
O algoritmo começa com a população dos seguintes dados:

- As constantes para desaceleração dos módulos
- Informações dos módulos que desejam pousar

```py
VELOCIDADE_FINAL = 2.0
RESERVA_PCT = 10.0
MARGEM_M = 5.0

...
modulos = [
{
  "nome": "Habitação",
  "prio": 5,
  "combustivel": 54,
  "integridade": 95,
  "oxigenio": 90,
  "temperatura": 22,
  "comunicacao": True,
  "altitude": 90,
  "velocidade": 22,
  "desaceleracao": 4.0,
  "consumo": 1.4
},
...
```

Cada módulo é um dicionário da lista `modulos`, com seu estado e seus dados de
voo: altitude (m), velocidade de descida (m/s), desaceleração (m/s²) e consumo
(pontos percentuais por segundo). As constantes definem a velocidade final (2
m/s), a reserva de combustível (10%) e a margem de altitude (5 m). Todos os
valores são ilustrativos.

== Ordenação dos módulos

Os módulos são ordenados por prioridade, com o algoritmo de ordenação simples
Bubble Sort. Foi criada uma função `ordenar`, fora da `main` por questões de
legibilidade.

```py
def main():
...

ordenar(modulos)

...

def ordenar(lista):
    for x in range(len(lista)):
        for i in range(len(lista) - x - 1):
            if lista[i]["prio"] < lista[i + 1]["prio"]:
                lista[i], lista[i + 1] = lista[i + 1], lista[i]
```

O Bubble Sort compara vizinhos e troca os que estão fora de ordem, deixando o
módulo de maior prioridade no início da lista. Depois de ordenada, a ordem de
prioridade dos módulos é impressa.

```py
print("Ordem de prioridade:", ", ".join(m["nome"] for m in modulos))
```

== Determinação das estruturas de dados

Para armazenar os módulos em ordem de prioridade, criamos uma fila, onde o que
tem a maior prioridade pousa primeiro.

```py
# Usando a biblioteca deque para facilitar no uso de filas.
fila = deque(modulos)
```

Para armazenar os resultados dos cheques de autorização e pouso, usamos uma
pilha

```py
# Aqui, uma lista é o suficiente para representar uma pilha, já que temos os métodos de lista: append() e pop()
pilha = []
```

A fila é FIFO (o primeiro a entrar é o primeiro a sair, com `popleft()`) e a
pilha é LIFO (o último a entrar é o primeiro a sair, com `append()` e `pop()`).

#figure(
  table(
    columns: (auto, auto, 1fr), align: (left, left, left), table.header[*Estrutura*][*Variável*][*Função no algoritmo*], [Lista], [`modulos`, `motivos`], [Guarda os módulos e os motivos de negação de pouso.], [Fila (FIFO)], [`fila`], [Define a ordem de atendimento por prioridade.], [Pilha (LIFO)], [`pilha`], [Guarda o resultado de cada módulo já processado.],
  ), caption: [Estruturas lineares utilizadas no algoritmo.],
)

== Decisão de pouso

O algoritmo é feito em duas partes. Primeiro, ele confere cinco condições dos
módulos:
```py
def cheque_pouso(m):
    motivos = []
    if m["combustivel"] < 50:
        motivos.append("Combustível abaixo de 50%")
    if m["integridade"] < 80:
        motivos.append("Integridade estrutural em níveis perigosos")
    if m["oxigenio"] < 70:
        motivos.append("Nível de oxigênio insuficiente")
    if not 18 <= m["temperatura"] <= 28:
        motivos.append("Temperatura fora da faixa de segurança")
    if not m["comunicacao"]:
        motivos.append("Sistema de comunicação falho")
    return not motivos, motivos
```

Cada condição que falha adiciona um motivo à lista `motivos`. Se a lista termina
vazia, `not motivos` é verdadeiro e o pouso está autorizado.

#figure(
  table(
    columns: (auto, auto), align: (left, left), table.header[*Condição*][*Critério para passar*], [Combustível], [pelo menos 50%], [Integridade estrutural], [pelo menos 80%], [Nível de oxigênio], [pelo menos 70%], [Temperatura], [entre 18 °C e 28 °C], [Comunicação], [sistema funcionando],
  ), caption: [Critérios de autorização de pouso.],
)

Essa primeira parte olha apenas para o estado do módulo, sem considerar a física
da descida.

=== Circuito lógico simplificado

#figure(
  image("images/i_negacao.png", height: 40%), caption: [Motivos de negação de pouso.],
)
#figure(
  image("images/i_autorizacao.png", height: 25%), caption: [Autorização de pouso.],
)

== Planejamento da frenagem

Na segunda parte, o algoritmo verifica se o módulo consegue frear a tempo e com
combustível suficiente. A função `calcular_pouso` usa conceitos da cinemática,
com as seguintes hipóteses:

- A velocidade de descida é conhecida e positiva.
- A desaceleração produzida pelos propulsores é constante.
- O consumo de combustível é constante.
- A velocidade final desejada é de $2 thin "m/s"$.
- Uma reserva de combustível de $10 %$ deve ser preservada.
- Uma margem adicional de altitude de $5 thin "m"$ é utilizada como precaução.

Como exemplo, usamos o módulo Laboratório: velocidade de descida de
$20 thin "m/s"$, desaceleração de $4 thin "m/s"^2$, consumo de $"1,5" %$ por
segundo, $21 %$ de combustível e altitude de $100 thin "m"$.

```py
def calcular_pouso(m):
    v, a = m["velocidade"], m["desaceleracao"]
    ...
```

=== Distância de frenagem

A distância mínima de frenagem vem da equação de Torricelli, com uma
desaceleração positiva $a_f$ oposta ao movimento:

$ v_f^2 = v_0^2 - 2 a_f d_f $

Isolando $d_f$:

#boxed[$ d_f = (v_0^2 - v_f^2) / (2 a_f) $]

```py
# d_f = (v0^2 - vf^2) / (2 a_f)
distancia = (v**2 - VELOCIDADE_FINAL**2) / (2 * a)
```

Para o Laboratório:

$ d_f = (20^2 - 2^2) / (2 dot 4) = (400 - 4) / 8 $

#boxed[$ d_f = "49,5" thin "m" $]

=== Tempo de frenagem

Pela equação da velocidade no movimento uniformemente variado,
$v_f = v_0 - a_f t_f$:

#boxed[$ t_f = (v_0 - v_f) / a_f $]

```py
# t_f = (v0 - vf) / a_f
tempo = (v - VELOCIDADE_FINAL) / a
```

$ t_f = (20 - 2) / 4 $

#boxed[$ t_f = "4,5" thin "s" $]

=== Consumo de combustível

O consumo é uma taxa $q$ em pontos percentuais por segundo:

#boxed[$ F_"nec" = q thin t_f $]

```py
# F_necessário = q * t_f
necessario = m["consumo"] * tempo
```

$ F_"nec" = "1,5" dot "4,5" $

#boxed[$ F_"nec" = "6,75" % $]

O combustível utilizável é o disponível menos a reserva, e o `max(0, ...)` evita
valores negativos:

#boxed[$ F_"util" = max(0, F_"disp" - F_"res") $]

```py
# combustível disponível menos a reserva
utilizavel = max(0, m["combustivel"] - RESERVA_PCT)
```

$ F_"util" = 21 - 10 $

#boxed[$ F_"util" = 11 % $]

=== Altitude de acionamento

A altitude de acionamento soma a margem de segurança à distância de frenagem:

#boxed[$ h_"acion" = d_f + h_"margem" $]

```py
# h_acionamento = d_f + h_margem
acionamento = distancia + MARGEM_M
```

$ h_"acion" = "49,5" + 5 $

#boxed[$ h_"acion" = "54,5" thin "m" $]

=== Verificação de viabilidade

A função verifica primeiro o combustível e depois a altitude:

```py
viavel = False
if necessario > utilizavel:
    motivo = "Combustível insuficiente"
elif m["altitude"] < acionamento:
    motivo = "Frenagem deveria ter começado antes"
else:
    viavel = True
    motivo = "Combustível suficiente e altitude adequada"
return viavel, motivo, acionamento, tempo, necessario
```

Existem três resultados possíveis:

+ O combustível necessário é maior que o utilizável.
+ O módulo já está abaixo da altitude de acionamento.
+ Há combustível suficiente e altitude adequada.

No Laboratório, $"6,75" % < 11 %$ e $100 thin "m" > "54,5" thin "m"$, então a
frenagem é viável. A altitude calculada é apenas uma recomendação, e não um
comando de acionamento dos propulsores.

== Processamento da fila e decisão final

O programa retira os módulos da fila um por um e aplica as duas avaliações:
```py
while fila:
    m = fila.popleft()
    autorizado, motivos = cheque_pouso(m)
    viavel, motivo, acionamento, tempo, necessario = calcular_pouso(m)
    ...
    # o pouso só é liberado se ambas as avaliações passarem
    pilha.append((m["nome"], autorizado and viavel))
```

As avaliações são independentes, e o pouso só é liberado se as duas forem
verdadeiras (operação lógica E):

#figure(
  table(
    columns: (auto, auto, auto), align: center, table.header[*Autorizado*][*Frenagem viável*][*Liberado*], [Sim], [Sim], [*Sim*], [Sim], [Não], [Não], [Não], [Sim], [Não], [Não], [Não], [Não],
  ), caption: [Tabela-verdade da decisão de pouso.],
)

Por isso o Laboratório, apesar da frenagem viável, não é liberado: seu
combustível de $21 %$ está abaixo dos $50 %$ exigidos. Ao final, a pilha é
desempilhada, do último módulo processado para o primeiro:

```py
print("\nDecisão final (do último processado ao primeiro):")

while pilha:
    nome, liberado = pilha.pop()
    print(f"{nome}: {'LIBERADO' if liberado else 'NÃO LIBERADO'}")
```

= Resultados da Simulação

A tabela resume a execução, na ordem em que os módulos saíram da fila.

#figure(
  table(
    columns: (auto, auto, 1fr, 1fr, auto), align: (left, center, left, left, left), table.header[*Módulo*][*Prio.*][*Autorização*][*Frenagem*][*Decisão*], [Habitação], [5], [Autorizado], [Viável, acionar a $"65,0" thin "m"$], [*Liberado*], [Energia], [4], [Autorizado], [Viável, acionar a $"82,6" thin "m"$], [*Liberado*], [Médico], [3], [Negado: combustível, integridade, temperatura e comunicação], [Não viável: altitude de $50 thin "m"$ abaixo dos $"54,5" thin "m"$], [Não liberado], [Logístico], [2], [Autorizado], [Não viável: precisa de $"78,4" %$ e só há $70 %$ utilizáveis], [Não liberado], [Laboratório], [1], [Negado: combustível de $21 %$], [Viável, acionar a $"54,5" thin "m"$], [Não liberado],
  ), caption: [Resultado do MGPEB para cada módulo.],
)

Cada caso negado mostra um tipo de falha: o Médico falha por estado e por
altitude, o Logístico apenas na frenagem e o Laboratório apenas na autorização.

= ESG e Governança na Base Aurora Siger

O ESG (_Environmental, Social and Governance_) avalia o impacto e a
responsabilidade de um projeto. As regras do MGPEB expressam escolhas de valor:
quem pousa primeiro, quanto combustível guardar e quando negar um pouso. Esta
seção as relaciona aos três pilares.

== Pilar ambiental

A reserva de $10 %$ é uma regra de segurança e também de uso responsável do
combustível, difícil de repor em uma base distante. Um pouso falho gera
destroços e pode contaminar o local, o que o Tratado do Espaço Sideral (1967)
procura evitar.

== Pilar social

A ordem de prioridade reflete valores: Habitação e Energia pousam primeiro
porque sustentam a vida. Essa é uma decisão humana, a ser discutida com a
equipe. A simulação mostra uma tensão: o Médico tem o pouso negado por quatro
motivos, mas um módulo de saúde pode ser crítico em uma emergência. Por isso é
desejável um procedimento de exceção decidido por humanos, e a lista de motivos
permite que a equipe entenda e questione a decisão.

== Pilar de governança

O MGPEB recomenda e não comanda: a decisão final cabe a uma pessoa. Além disso:

- *Rastreabilidade:* a pilha só existe durante a execução, e um log permanente
  permitiria auditar as decisões.
- *Parâmetros:* limites, reserva, margem e prioridades são decisões de política e
  deveriam ser documentados e versionados.
- *Dados:* as entradas não são validadas, e um sensor defeituoso gera uma decisão
  errada.
- *Validação:* antes de uso real, seriam necessários testes independentes e
  análise de incertezas.

  Um sistema de apoio à decisão não elimina a responsabilidade humana, mas a torna
  mais informada.

  = Conclusão

  O MGPEB combina uma verificação de estado (autorização) com uma modelagem física
  da frenagem (viabilidade). A fila atende os módulos por prioridade e a pilha
  guarda os resultados. É um modelo inicial de apoio à decisão: para uso real,
  seriam necessários dados medidos, controle em tempo real e validação de
  segurança.
