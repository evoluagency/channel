#!/usr/bin/env python3
"""Confere os dados v0.3 (sessão 1.5) e as metas de ritmo e economia na simulação.

Metas do dono: 15 min/dia chega ao nível 20 da Prefeitura por volta do dia 30 e ao 30 por volta
do dia 60; o pagante médio (passe) chega ao 30 na metade do tempo; a moeda não perde valor;
nenhuma região fica claramente melhor (±3%). Na v0.3: regiões especializadas com comércio entre
estados, impostos só na venda com faixas de capacidade de pagamento, tesouro com teto, Centro
tecnológico, produção do passe não vendável e bônus de recém-chegado.
"""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(RAIZ / "tools" / "mundo"))
import simular_economia as se  # noqa: E402

V02 = RAIZ / "game" / "data" / "mundo_componentes_v0.2.json"
V03 = RAIZ / "game" / "data" / "mundo_componentes_v0.3.json"
d = json.loads(V03.read_text(encoding="utf-8"))
c = {x["id"]: x for x in d["construcoes"]}
ck = {}

# dados
ck["15_construcoes"] = len(c) == 15 and {"pref", "ban", "tec"} <= set(c) and "hq" not in c
ck["30_niveis"] = all([n["nivel"] for n in x["niveis"]] == list(range(1, 31)) for x in c.values())
ck["tempo_cresce"] = all(a["tempo_s"] <= b["tempo_s"] for x in c.values() for a, b in zip(x["niveis"], x["niveis"][1:]))
ck["custo_cresce"] = all(a["custo_valor"] <= b["custo_valor"] for x in c.values() for a, b in zip(x["niveis"], x["niveis"][1:]))
ck["6_faixas_visuais"] = all(len(x["visual_faixas"]) == 6 for x in c.values())
ck["desbloqueio_valido"] = all(1 <= x["desbloqueio_prefeitura"] <= 30 and (x["requisito"] is None or x["requisito"]["id"] in c) for x in c.values())
ck["requisito_antes"] = all(x["requisito"] is None or c[x["requisito"]["id"]]["desbloqueio_prefeitura"] <= x["desbloqueio_prefeitura"] for x in c.values())
v02 = {x["id"]: x for x in json.loads(V02.read_text(encoding="utf-8"))["construcoes"]}
ck["curvas_v02_sem_mudanca"] = all(c[k]["niveis"] == v02[k]["niveis"] for k in v02)
pq = d["pesquisa"]["niveis"]
ck["pesquisa_10_niveis_crescentes"] = len(pq) == 10 and all(a["tempo_s"] <= b["tempo_s"] and a["custo_valor"] <= b["custo_valor"] for a, b in zip(pq, pq[1:]))
ck["pesquisa_5_linhas"] = set(d["pesquisa"]["linhas"]) == set(se.LINHAS)
fortes = d["regioes"]["fortes"]
ck["regioes_2_fortes"] = len(fortes) == 5 and all(len(v) == 2 for v in fortes.values())
ck["nordeste_aprovado"] = sorted(fortes["Nordeste"]) == ["alimentos", "materiais"]
ck["impostos_faixas"] = d["impostos"]["estadual"]["faixa"] == [0.0, 0.30] and d["impostos"]["federal"]["faixa"] == [0.0, 0.30] \
    and [f["faixa"] for f in d["impostos"]["faixas_capacidade"]] == ["verde", "amarela", "vermelha"]
ck["passe_nao_vende"] = d["passe"]["producao_extra_vendavel"] is False
ck["migracao_e_venda_so_em_moeda"] = d["migracao_paises"]["reserva_minima"]["fracao_valor_cidade"] == 0.25 \
    and d["venda_cidade"]["preco"]["moeda_do_jogo"] is True and "dia 60" in d["migracao_paises"]["abre"]
with tempfile.TemporaryDirectory() as tmp:
    for nome, ger, ref in (("v02", "gerar_componentes_v02.py", V02), ("v03", "gerar_componentes_v03.py", V03)):
        out = Path(tmp) / f"{nome}.json"
        subprocess.run([sys.executable, "-I", str(RAIZ / "tools" / "mundo" / ger), "--saida", str(out)], check=True, capture_output=True)
        ck[f"gerador_{nome}_deterministico"] = out.read_bytes() == ref.read_bytes()

# simulação
ags, hist = se.simular(70)
R = se.resumo(ags, hist)
dia = R["dia"]
ck["p15_nivel20_dia_27_a_32"] = 27 <= dia["p15"][20] <= 32
ck["p15_nivel30_dia_55_a_65"] = 55 <= dia["p15"][30] <= 65
ck["passe_metade_do_tempo"] = 27 <= dia["pag"][30] <= 33 and dia["pag"][30] <= 0.55 * dia["p15"][30]
ck["p15_nivel15_perto_do_dia_15"] = 11 <= dia["p15"][15] <= 17
ck["ordem_dos_perfis"] = dia["pag"][20] < dia["p30"][20] < dia["p15"][20] < dia["p5"][20]
g = [a for a in ags if a.perfil == "p15"]
for k in ("poder", "prod_h"):
    m = [sum(x[k] for x in a.hist[:60]) for a in g]
    med = sum(m) / len(m)
    ck[f"regioes_{k}_3pct"] = all(abs(v / med - 1) <= 0.03 for v in m)
ck["regioes_ritmo_2_dias"] = R["reg_d30"] <= 2.0
ck["comercio_entre_jogadores_15_a_35pct"] = 0.15 <= R["comercio"] <= 0.35
ck["moeda_guardada_abaixo_de_1_dia"] = R["my_max"] < 1.0
ck["sistema_quase_nao_vende"] = R["compra_sistema"] < 0.02
ck["bonus_obras_publicas_ate_6pct"] = 0 < R["bonus_pub"] <= 2 * se.OBRA_PUB_BONUS_MAX + 1e-9
ck["tesouro_no_teto"] = all(h["saldo_est"] <= se.TESOURO_TETO_DIAS * max(h["imp_est"], 1e-9) * 1.5 + 1 for h in hist[14:60])
# reserva de migração no nível 30: entre 3 e 8 dias de produção (cara, mas alcançável)
r30 = [se.RESERVA_MIGRACAO * a.valor_cidade() / (24 * se.YREF[30]) for a in ags if a.qg == 30]
ck["reserva_migracao_3_a_8_dias"] = bool(r30) and all(3 <= x <= 8 for x in r30)
# passe: o que o pagante vende nunca passa da produção sem o passe
for a in ags:
    if a.perfil != "pag":
        continue
    vend = sum(x.get("venda_jogadores", 0) / se.Mercado.preco_jog("materiais") + x.get("venda_sistema", 0) / 0.85 for x in a.hist)
    livre = sum(x.get("producao_valor", 0) for x in a.hist) * (1 - se.PASSE_PROD / (1 + se.PASSE_PROD + 0.3))
    ck.setdefault("passe_producao_extra_nao_vendida", True)
    ck["passe_producao_extra_nao_vendida"] &= vend <= livre and all(v <= a.estoque[r] + 1e-6 for r, v in a.vinc.items())
# fontes e drenos do sistema (o comércio entre jogadores é transferência)
fon = sum(a.peso * v for a in ags for x in a.hist[7:60] for k, v in x.items() if k in se.FLUXOS and v > 0)
dre = -sum(a.peso * v for a in ags for x in a.hist[7:60] for k, v in x.items() if k in se.FLUXOS and v < 0)
ck["fontes_e_drenos_equilibrados_10pct"] = abs(fon - dre) / fon <= 0.10
ck["faixas_imposto"] = [se.faixa_imposto(t) for t in (0.10, 0.20, 0.30, 0.40, 0.50)] == ["verde", "verde", "amarela", "amarela", "vermelha"]
ck["deterministico"] = [a.dia_qg for a in se.simular(20)[0]] == [a.dia_qg for a in se.simular(20)[0]]
# recém-chegado: com o bônus chega antes, e o corte somado respeita o teto
rc = {(cc, pf): dd for cc, pf, dd in se.recem_chegado(cortes=(0.0, se.RECEM_CORTE), dias=60)}
ck["recem_chegado_alcanca_antes"] = rc[(se.RECEM_CORTE, "p15")][27] <= rc[(0.0, "p15")][27] - 7
ck["recem_e_passe_com_teto"] = rc[(se.RECEM_CORTE, "pag")][30] >= 25

falhas = [k for k, v in ck.items() if not v]
print(f"economia_mundo {len(ck) - len(falhas)}/{len(ck)} falhas={falhas}")
raise SystemExit(1 if falhas else 0)
