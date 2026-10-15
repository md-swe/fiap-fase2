from collections import deque

# constantes da modelagem
VELOCIDADE_FINAL = 2.0
RESERVA_PCT = 10.0
MARGEM_M = 5.0


def main():
    print("MGPEB Inicializado")

    # lista de módulos (dados de voo: altitude, velocidade, desaceleracao, consumo)
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
            {
                "nome": "Energia",
                "prio": 4,
                "combustivel": 79,
                "integridade": 85,
                "oxigenio": 80,
                "temperatura": 25,
                "comunicacao": True,
                "altitude": 120,
                "velocidade": 25,
                "desaceleracao": 4.0,
                "consumo": 1.8
                },
            {
                "nome": "Laboratório",
                "prio": 1,
                "combustivel": 21,
                "integridade": 98,
                "oxigenio": 95,
                "temperatura": 21,
                "comunicacao": True,
                "altitude": 100,
                "velocidade": 20,
                "desaceleracao": 4.0,
                "consumo": 1.5
                },
            {
                "nome": "Médico",
                "prio": 3,
                "combustivel": 45,
                "integridade": 70,
                "oxigenio": 75,
                "temperatura": 30,
                "comunicacao": False,
                "altitude": 50,
                "velocidade": 20,
                "desaceleracao": 4.0,
                "consumo": 1.6
                },
            {
                "nome": "Logístico",
                "prio": 2,
                "combustivel": 80,
                "integridade": 90,
                "oxigenio": 85,
                "temperatura": 24,
                "comunicacao": True,
                "altitude": 200,
                "velocidade": 30,
                "desaceleracao": 2.5,
                "consumo": 7.0
                },
            ]

    ordenar(modulos)
    print("Ordem de prioridade:", ", ".join(m["nome"] for m in modulos))

    # fila (FIFO): o de maior prioridade pousa primeiro - precisamos da lib deque pra poder usar queues de forma mais fácil
    fila = deque(modulos)

    # pilha (LIFO): guarda o resultado de cada módulo processado
    pilha = []

    while fila:
        m = fila.popleft()
        autorizado, motivos = cheque_pouso(m)
        viavel, motivo, acionamento, tempo, necessario = calcular_pouso(m)

        print(f"\n{m['nome']}: POUSO {'AUTORIZADO' if autorizado else 'NEGADO'}")

        for motivo_negado in motivos:
            print(f"- {motivo_negado}")

        print(f"Frenagem {'VIÁVEL' if viavel else 'NÃO VIÁVEL'} - {motivo}")

        print(f"Acionamento: {acionamento:.1f} m; Tempo: {tempo:.1f} s; "
              f"Combustível: {necessario:.2f}%")

        # o pouso só é liberado se ambas as avaliações passarem
        pilha.append((m["nome"], autorizado and viavel))

    print("\nDecisão final (do último processado ao primeiro):")

    while pilha:
        nome, liberado = pilha.pop()
        print(f"{nome}: {'LIBERADO' if liberado else 'NÃO LIBERADO'}")

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


# modelagem física
def calcular_pouso(m):
    v, a = m["velocidade"], m["desaceleracao"]

    # d_f = (v0^2 - vf^2) / (2 a_f)
    distancia = (v**2 - VELOCIDADE_FINAL**2) / (2 * a)
    # t_f = (v0 - vf) / a_f
    tempo = (v - VELOCIDADE_FINAL) / a
    # F_necessário = q * t_f
    necessario = m["consumo"] * tempo
    # combustível disponível menos a reserva
    utilizavel = max(0, m["combustivel"] - RESERVA_PCT)
    # h_acionamento = d_f + h_margem
    acionamento = distancia + MARGEM_M

    viavel = False
    if necessario > utilizavel:
        motivo = "Combustível insuficiente"
    elif m["altitude"] < acionamento:
        motivo = "Frenagem deveria ter começado antes"
    else:
        viavel = True
        motivo = "Combustível suficiente e altitude adequada"
    return viavel, motivo, acionamento, tempo, necessario


# bubble sort por prioridade, da maior para a menor
def ordenar(lista):
    for x in range(len(lista)):
        for i in range(len(lista) - x - 1):
            if lista[i]["prio"] < lista[i + 1]["prio"]:
                lista[i], lista[i + 1] = lista[i + 1], lista[i]


if __name__ == "__main__":
    main()
