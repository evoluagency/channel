#!/usr/bin/env python3
"""Simula as compensações de tamanho (DESENHO_MUNDO_v0.1.md, seção 4) nos 27 estados.

Modelo (só tempo; recursos não travam, porque a pergunta é o efeito do tamanho):
- 2 obras simultâneas; tempo(n) = 30 s x fator x 1,28^(n-1) (fator 2 no QG, 1 nos prédios),
  multiplicado pelo tempo de obra do estado;
- prédios construíveis = (% do QG) x lotes, % interpolada da tabela da seção 7 dos
  componentes; nenhum prédio passa do nível do QG;
- política fixa: 1) novo prédio se houver lote liberado; 2) subir o prédio mais baixo
  abaixo do QG; 3) subir o QG. Uma obra do QG por vez;
- produção/h = soma de 1,12^(n-1) x produção por lote x eficiência de transporte;
  poder = soma de 40 x n^1,55 (x produção por lote, na variante "poder compensado").

Compensações (proposta):
  produção por lote  d(L) = (80 / L)^GAMA
  transporte         t(L) = 1 - TAU x (raiz(L / 40) - 1)
  tempo de obra      b(L) = (L / 80)^BETA

Uso: python3 -I tools/mundo/simular_lotes.py [--sem] [--md]
"""
from __future__ import annotations

import argparse
import heapq
import json
import math
import os

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.dirname(os.path.dirname(AQUI))

# Recomendado na sessão 1.3 (busca em grade: menor diferença maior/menor ao longo de 180 dias).
GAMA, TAU, BETA = 0.75, 0.0, 0.0
SLOTS = 2
PCT_QG = [(1, .15), (5, .30), (10, .45), (15, .60), (20, .75), (25, .85), (30, .95)]
DIAS = (3, 7, 30, 90, 180)


def pct(q: int) -> float:
    for (a, pa), (b, pb) in zip(PCT_QG, PCT_QG[1:]):
        if a <= q <= b:
            return pa + (pb - pa) * (q - a) / (b - a)
    return PCT_QG[-1][1]


def comp(L: int, ligado: bool):
    if not ligado:
        return 1.0, 1.0, 1.0
    return (80 / L) ** GAMA, 1 - TAU * (math.sqrt(L / 40) - 1), (L / 80) ** BETA


def simular(L: int, ligado: bool) -> dict:
    d, t, b = comp(L, ligado)
    qg = 1
    predios: list[int] = []   # níveis
    ocupado: set = set()      # índices de prédio em obra (-1 = QG)
    fila = []                 # (fim, alvo)
    agora = 0.0
    marcos = {}
    pend = sorted(x * 86400 for x in DIAS)

    def foto():
        prod = sum(1.12 ** (n - 1) for n in predios) * d * t
        poder = sum(40 * n ** 1.55 for n in predios)
        return {"qg": qg, "predios": len(predios), "prod": prod, "poder": poder, "poder_c": poder * d}

    def iniciar():
        while len(fila) < SLOTS:
            cap = int(pct(qg) * L)
            if len(predios) + sum(1 for _, a in fila if a == "novo") < cap:
                fila.append((agora + 30 * b, "novo"))
                continue
            livres = [i for i, n in enumerate(predios) if n < qg and i not in ocupado]
            if livres:
                i = min(livres, key=lambda i: (predios[i], i))
                ocupado.add(i)
                fila.append((agora + 30 * 1.28 ** predios[i] * b, i))
                continue
            if -1 not in ocupado and qg < 30:
                ocupado.add(-1)
                fila.append((agora + 60 * 1.28 ** qg * b, -1))
                continue
            break
        heapq.heapify(fila)

    iniciar()
    while pend:
        if not fila:
            agora = pend[0]
        else:
            fim, alvo = heapq.heappop(fila)
            while pend and pend[0] < fim:
                agora = pend.pop(0)
                marcos[round(agora / 86400)] = foto()
            agora = fim
            if alvo == "novo":
                predios.append(1)
            elif alvo == -1:
                qg += 1
                ocupado.discard(-1)
            else:
                predios[alvo] += 1
                ocupado.discard(alvo)
            iniciar()
            continue
        marcos[round(agora / 86400)] = foto()
        pend.pop(0)
    return marcos


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--perfis", default=os.path.join(RAIZ, "game", "data", "mundo", "BR_perfis.json"))
    ap.add_argument("--md", action="store_true", help="tabela em Markdown")
    a = ap.parse_args()
    est = sorted(json.load(open(a.perfis, encoding="utf-8"))["estados"], key=lambda e: e["area_oficial_km2"])
    res = {}
    for e in est:
        res[e["uf"]] = {lig: simular(e["lotes"], lig) for lig in (False, True)}
    for lig, rot in ((False, "SEM compensação"), (True, f"COM compensação (gama {GAMA}, tau {TAU}, beta {BETA})")):
        print(f"\n### {rot}: valor relativo à mediana dos 27 (1,00 = mediana)\n")
        for chave, nome in (("prod", "produção/h"), ("poder", "poder"), ("poder_c", "poder compensado")):
            if not lig and chave == "poder_c":
                continue
            med = {dia: sorted(res[u][lig][dia][chave] for u in res)[13] for dia in DIAS}
            print(f"**{nome}**\n")
            print("| UF | lotes | " + " | ".join(f"dia {x}" for x in DIAS) + " |")
            print("|---|---|" + "---|" * len(DIAS))
            for e in est:
                u = e["uf"]
                print(f"| {u} | {e['lotes']} | " + " | ".join(f"{res[u][lig][x][chave] / med[x]:.2f}".replace(".", ",") for x in DIAS) + " |")
            amp = {x: max(res[u][lig][x][chave] for u in res) / min(res[u][lig][x][chave] for u in res) for x in DIAS}
            print("| maior/menor | | " + " | ".join(f"{amp[x]:.2f}".replace(".", ",") for x in DIAS) + " |\n")
    print("QG no dia (DF / AM, com compensação):", [(x, res['DF'][True][x]['qg'], res['AM'][True][x]['qg']) for x in DIAS])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
