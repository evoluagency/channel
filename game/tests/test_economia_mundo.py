#!/usr/bin/env python3
"""Confere as curvas v0.2 (sessão 1.4) e as metas de ritmo e economia na simulação.

Metas do dono: 15 min/dia chega ao nível 20 da Prefeitura por volta do dia 30 e ao 30 por volta
do dia 60; o pagante médio (passe) chega ao 30 na metade do tempo; a moeda não perde valor;
nenhuma região fica claramente melhor.
"""
import json
import math
import os
import subprocess
import sys
import tempfile
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(RAIZ / "tools" / "mundo"))
import simular_economia as se  # noqa: E402

DADOS = RAIZ / "game" / "data" / "mundo_componentes_v0.2.json"
d = json.loads(DADOS.read_text(encoding="utf-8"))
c = {x["id"]: x for x in d["construcoes"]}
ck = {}

# dados
ck["14_construcoes"] = len(c) == 14 and "pref" in c and "ban" in c and "hq" not in c
ck["30_niveis"] = all([n["nivel"] for n in x["niveis"]] == list(range(1, 31)) for x in c.values())
ck["tempo_cresce"] = all(a["tempo_s"] <= b["tempo_s"] for x in c.values() for a, b in zip(x["niveis"], x["niveis"][1:]))
ck["custo_cresce"] = all(a["custo_valor"] <= b["custo_valor"] for x in c.values() for a, b in zip(x["niveis"], x["niveis"][1:]))
tp = [n["tempo_s"] / 3600 for n in c["pref"]["niveis"]]
ck["inicio_rapido"] = tp[7] <= 2.01 and tp[9] <= 8.01  # nível 8 em 2 h, 10 em 8 h
ck["degrau_suave"] = all(b / a <= 2.01 for a, b in zip(tp[8:14], tp[9:15]) if a > 0)  # no máximo dobra
ck["platô_3_a_4_dias"] = 3.0 <= tp[29] / 24 <= 4.0
ck["desbloqueio_valido"] = all(1 <= x["desbloqueio_prefeitura"] <= 30 and (x["requisito"] is None or x["requisito"]["id"] in c) for x in c.values())
ck["requisito_antes"] = all(x["requisito"] is None or c[x["requisito"]["id"]]["desbloqueio_prefeitura"] <= x["desbloqueio_prefeitura"] for x in c.values())
with tempfile.TemporaryDirectory() as tmp:
    out = Path(tmp) / "v02.json"
    subprocess.run([sys.executable, "-I", str(RAIZ / "tools" / "mundo" / "gerar_componentes_v02.py"), "--saida", str(out)],
                   check=True, capture_output=True)
    ck["gerador_deterministico"] = out.read_bytes() == DADOS.read_bytes()

# simulação
ags, hist = se.simular(66)


def dia(perfil, n):
    g = [a for a in ags if a.perfil == perfil]
    return sum(a.dia_qg.get(n, 99) for a in g) / len(g)


ck["p15_nivel20_dia_27_a_32"] = 27 <= dia("p15", 20) <= 32
ck["p15_nivel30_dia_55_a_65"] = 55 <= dia("p15", 30) <= 65
ck["passe_metade_do_tempo"] = 27 <= dia("pag", 30) <= 33 and dia("pag", 30) <= 0.55 * dia("p15", 30)
ck["p15_nivel15_perto_do_dia_15"] = 11 <= dia("p15", 15) <= 17
ck["ordem_dos_perfis"] = dia("pag", 20) < dia("p30", 20) < dia("p15", 20) < dia("p5", 20)
g = [a for a in ags if a.perfil == "p15"]
for k in ("poder", "prod_h"):
    m = [sum(x[k] for x in a.hist[:60]) for a in g]
    ck[f"regioes_{k}_ate_3pct"] = max(m) / min(m) <= 1.03
ck["regioes_ritmo_1_dia"] = max(a.dia_qg[30] for a in g) - min(a.dia_qg[30] for a in g) <= 1.0
my = []
for dd in range(13, 60):
    m = sum(a.peso * a.hist[dd]["moeda"] for a in ags)
    y = sum(a.peso * a.hist[dd]["prod_h"] * 24 for a in ags)
    my.append(m / y)
ck["moeda_guardada_abaixo_de_1_dia"] = max(my) < 1.0
ck["precos_na_faixa"] = all(abs(h["preco"][r] / se.PRECO_REF[r] - 1) <= se.FAIXA_PRECO + 1e-9 for h in hist for r in se.RES)
fon = sum(a.peso * v for a in ags for x in a.hist[7:60] for k, v in x.items() if k not in ("dia", "qg", "moeda", "prod_h", "poder", "producao_valor") and v > 0)
dre = -sum(a.peso * v for a in ags for x in a.hist[7:60] for k, v in x.items() if k not in ("dia", "qg", "moeda", "prod_h", "poder", "producao_valor") and v < 0)
ck["fontes_e_drenos_equilibrados_10pct"] = abs(fon - dre) / fon <= 0.10
ck["deterministico"] = [a.dia_qg for a in se.simular(20)[0]] == [a.dia_qg for a in se.simular(20)[0]]

falhas = [k for k, v in ck.items() if not v]
print(f"economia_mundo {len(ck) - len(falhas)}/{len(ck)} falhas={falhas}")
raise SystemExit(1 if falhas else 0)
