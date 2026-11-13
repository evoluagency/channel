#!/usr/bin/env python3
"""Gera game/data/mundo_componentes_v0.2.json com as curvas aprovadas na sessão 1.4.

Fonte das curvas: tools/mundo/simular_economia.py (tempo da Prefeitura, custo ligado à produção,
receita por faixa, produção). Mantém textos e faixas visuais da v0.1; troca o Quartel-general
pela Prefeitura e acrescenta o Banco da cidade. Determinístico.

Uso: python3 -I tools/mundo/gerar_componentes_v02.py [--saida CAMINHO]
"""
from __future__ import annotations

import argparse
import copy
import json
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.dirname(os.path.dirname(AQUI))
sys.path.insert(0, AQUI)
import simular_economia as se  # noqa: E402

V01 = os.path.join(RAIZ, "game", "data", "mundo_componentes_v0.1.json")
SAIDA = os.path.join(RAIZ, "game", "data", "mundo_componentes_v0.2.json")

# fração do tempo e do custo da Prefeitura no mesmo nível
FRACAO = {
    "pref": (1.0, 1.0), "bas": (0.30, 0.40), "alo": (0.10, 0.10),
    "est": (0.03, 0.04), "usi": (0.03, 0.04), "min": (0.03, 0.04), "ene": (0.03, 0.04),
    "ban": (0.10, 0.10), "rad": (0.05, 0.05), "ent": (0.05, 0.05), "par": (0.05, 0.05),
    "agu": (0.05, 0.05), "hel": (0.05, 0.05), "via": (0.01, 0.01),
}
# Árvore de desbloqueio: nível da Prefeitura e prédio exigido (id, nível)
DESBLOQUEIO = {
    "pref": (1, None), "alo": (1, None), "est": (1, None), "usi": (1, None), "via": (1, None),
    "min": (2, ("usi", 2)), "ene": (3, ("min", 2)), "ban": (3, ("usi", 3)), "par": (4, ("alo", 3)),
    "agu": (5, ("est", 4)), "ent": (6, ("ban", 3)), "rad": (8, ("ene", 6)), "bas": (10, ("rad", 2)),
    "hel": (12, ("bas", 2)),
}
BANCO = {
    "id": "ban", "nome": "Banco da cidade", "origem_valdora": "—", "tipo": "ban", "base": 0,
    "unidade": "moedas protegidas",
    "funcao": "Guarda a moeda da cidade. A moeda é do sistema; cada cidade tem o seu banco.",
    "beneficio": "Protege a moeda até a capacidade do nível (12 h de produção de referência); o que passa fica no cofre, exposto a ataque. Rendimento de 1%/semana com teto, empréstimo pela nota fiscal.",
    "visual_faixas": ["Contêiner com cofre e placa", "Agência pré-fabricada com caixa eletrônico",
                      "Agência de concreto com colunas", "Torre de vidro com letreiro", "Centro financeiro com painéis e drones",
                      "Banco de elite com cúpula dourada e cofre iluminado"],
}


def r1(x: float) -> float:
    return round(x, 1) if x < 100 else float(round(x))


def gerar() -> dict:
    d = json.load(open(V01, encoding="utf-8"))
    out = {"schema": "mundo.componentes.v0.2",
           "status": "curvas aprovadas pelo dono em 13/11/2026 (sessão 1.4); nomes e arte do Banco pendentes",
           "niveis": 30,
           "formulas": {
               "tempo_prefeitura_h": "níveis 2 a 8 por âncoras (1 min a 2 h); do 9 em diante min(2 x 2^(n-8), %.0f x (1 - e^(-(n-8)/%.1f)))" % (se.T_MAX, se.T_K),
               "tempo_outros": "fração do tempo da Prefeitura no mesmo nível (campo fracao_tempo)",
               "custo_prefeitura_moedas": "%.2f x produção de referência/h no nível x tempo-base (h)" % se.ALFA_CUSTO,
               "custo_outros": "fração do custo da Prefeitura no mesmo nível (campo fracao_custo)",
               "receita": "1-4: materiais 70%% alimentos 30%%; 5-9: materiais 45%% metal 30%% alimentos 25%%; 10+: materiais 35%% metal 25%% energia 20%% alimentos 20%%",
               "producao": "base x 1,12^(n-1) por hora; offline até 8 h",
               "preco_referencia": se.PRECO_REF,
               "producao_por_tipo": "2 + nível da Prefeitura // 10",
               "poder": "40*n^1.55",
           },
           "producao_referencia_h": [round(x, 1) for x in se.YREF[1:31]],
           "faixas": d["faixas"], "construcoes": []}
    fontes = {c["id"]: c for c in d["construcoes"]}
    ordem = ["pref", "alo", "est", "usi", "min", "ene", "ban", "rad", "bas", "ent", "via", "par", "agu", "hel"]
    for cid in ordem:
        if cid == "pref":
            c = copy.deepcopy(fontes["hq"])
            c.update(id="pref", id_antigo="hq", nome="Prefeitura", origem_valdora="Fundação",
                     funcao="Centro da cidade. O nível da Prefeitura é o nível da cidade e limita todos os outros prédios.")
        elif cid == "ban":
            c = copy.deepcopy(BANCO)
        else:
            c = copy.deepcopy(fontes[cid])
        ft, fc = FRACAO[cid]
        nv, req = DESBLOQUEIO[cid]
        c.update(fracao_tempo=ft, fracao_custo=fc, desbloqueio_prefeitura=nv,
                 requisito=None if req is None else {"id": req[0], "nivel": req[1]})
        c.pop("desbloqueio_qg", None)
        c.pop("custo_nivel1", None)
        c.pop("fator_tempo", None)
        velhos = {x["nivel"]: x for x in c.get("niveis", [])}
        niveis = []
        for n in range(1, 31):
            base = se.custo("hq", n)
            vb = sum(v * fc * se.PRECO_REF[r] for r, v in base.items())
            k = max(1.0, 10.0 / vb) if vb > 0 else 1.0  # piso de 10 moedas de valor por obra
            custo = {r: r1(v * fc * k) for r, v in base.items()}
            t = se.tempo_h("hq", n) * ft * 3600
            x = {"nivel": n, "poder": round(40 * n ** 1.55, 1), "custo": custo,
                 "custo_valor": r1(sum(custo[r] * se.PRECO_REF[r] for r in custo)), "tempo_s": int(round(t))}
            if cid == "ban":
                x["valor"] = r1(12 * se.YREF[n])
            elif n in velhos and "valor" in velhos[n]:
                x["valor"] = velhos[n]["valor"]
                if "valor2" in velhos[n]:
                    x["valor2"] = velhos[n]["valor2"]
            niveis.append(x)
        for a, b in zip(niveis, niveis[1:]):  # custo nunca cai de um nível para o seguinte
            if b["custo_valor"] < a["custo_valor"]:
                b["custo"], b["custo_valor"] = dict(a["custo"]), a["custo_valor"]
        c["niveis"] = niveis
        if cid == "pref":
            c["pre_requisitos_por_nivel"] = "nível n exige Usina de materiais (a principal) no n-1 e, do 11 em diante, Base militar no n-1"
        out["construcoes"].append(c)
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--saida", default=SAIDA)
    a = ap.parse_args()
    dados = gerar()
    with open(a.saida, "w", encoding="utf-8") as fh:
        json.dump(dados, fh, ensure_ascii=False, indent=1)
        fh.write("\n")
    print(f"{a.saida}: {len(dados['construcoes'])} construções")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
