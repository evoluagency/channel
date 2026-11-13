#!/usr/bin/env python3
"""Confere game/data/mundo/BR.json e BR_perfis.json (marcos M1 e M2 do DESENHO_MUNDO_v0.1.md).

A regeneração da geometria precisa da fonte Natural Earth em tools/mundo/.cache/
(cerca de 40 MB, baixada por tools/mundo/gerar_pais.py). Sem ela, a checagem de
determinismo da geometria aparece como PULADA (não conta como falha) e o resto roda.
"""
import hashlib, json, math, os, subprocess, sys, tempfile
from collections import defaultdict
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
DADOS = RAIZ / "game" / "data" / "mundo"
FERR = RAIZ / "tools" / "mundo"
pais = json.loads((DADOS / "BR.json").read_text(encoding="utf-8"))
perf = json.loads((DADOS / "BR_perfis.json").read_text(encoding="utf-8"))
G = {e["uf"]: e for e in pais["estados"]}
P = {e["uf"]: e for e in perf["estados"]}

UFS = set("AC AL AP AM BA CE DF ES GO MA MT MS MG PA PB PR PE PI RJ RN RS RO RR SC SP SE TO".split())
COSTEIROS = set("AP PA MA PI CE RN PB PE AL SE BA ES RJ SP PR SC RS".split())
# Divisas conhecidas. Na fonte (Natural Earth) o DF só encosta no MG num ponto; fica só com GO.
DIVISAS = {
    "AC": "AM RO", "AL": "BA PE SE", "AP": "PA", "AM": "AC MT PA RO RR",
    "BA": "AL ES GO MG PE PI SE TO", "CE": "PB PE PI RN", "DF": "GO", "ES": "BA MG RJ",
    "GO": "BA DF MG MS MT TO", "MA": "PA PI TO", "MT": "AM GO MS PA RO TO",
    "MS": "GO MG MT PR SP", "MG": "BA ES GO MS RJ SP", "PA": "AM AP MA MT RR TO",
    "PB": "CE PE RN", "PR": "MS SC SP", "PE": "AL BA CE PB PI", "PI": "BA CE MA PE TO",
    "RJ": "ES MG SP", "RN": "CE PB", "RS": "SC", "RO": "AC AM MT", "RR": "AM PA",
    "SC": "PR RS", "SP": "MG MS PR RJ", "SE": "AL BA", "TO": "BA GO MA MT PA PI",
}
# Diferença de área aceita: ±5%. Exceção registrada: a fonte usa o limite AC–AM
# anterior à revisão do IBGE, e o Acre sai cerca de 6% menor (o Amazonas, maior).
TOL_AREA = {"AC": 7.0}
CAMPOS_G = {"uf", "nome", "area_km2", "centroide", "rotulo", "caixa", "litoral", "litoral_km",
            "fronteira_exterior_km", "vizinhos", "divisas_km", "poligonos"}
CAMPOS_P = {"uf", "nome", "regiao", "area_oficial_km2", "area_calculada_km2", "diferenca_area_pct",
            "peso", "vagas_base", "capital_federal", "capital", "bioma_dominante", "biomas", "litoral",
            "litoral_km", "vizinhos", "vocacao", "bonus_regiao_pct"}
RECURSOS = {"alimentos", "materiais", "metal", "energia"}
BIOMAS = {"Amazônia", "Cerrado", "Caatinga", "Mata Atlântica", "Pantanal", "Pampa"}


def lotes_formula(a):
    return int(math.floor(max(40, min(120, 40 + 32.9 * math.log10(a / 5760))) + 0.5))


def aneis(e):
    return [list(zip(p[0::2], p[1::2])) for p in e["poligonos"]]


def dist_borda_km(uf, lon, lat):
    """0 se o ponto está dentro do estado; senão a distância aproximada até a borda, em km."""
    x, y = lon * 1e4, lat * 1e4
    dentro = False
    melhor = float("inf")
    k = math.cos(math.radians(lat))
    for r in aneis(G[uf]):
        for i in range(len(r)):
            (x1, y1), (x2, y2) = r[i], r[(i + 1) % len(r)]
            if (y1 > y) != (y2 > y) and x < x1 + (y - y1) * (x2 - x1) / (y2 - y1):
                dentro = not dentro
            dx, dy = (x2 - x1) * k, y2 - y1
            L = dx * dx + dy * dy
            t = 0 if L == 0 else max(0, min(1, ((x - x1) * k * dx + (y - y1) * dy) / L))
            melhor = min(melhor, math.hypot((x - x1) * k - t * dx, y - y1 - t * dy))
    return 0.0 if dentro else melhor / 1e4 * 111.2


def orient(p, q, r):
    v = (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])
    return (v > 0) - (v < 0)


def cruzamentos():
    """Pares de segmentos (de todos os estados) que se cruzam fora de extremos comuns."""
    segs = set()
    for e in pais["estados"]:
        for r in aneis(e):
            for i in range(len(r)):
                a, b = r[i], r[(i + 1) % len(r)]
                segs.add((min(a, b), max(a, b)))
    segs = sorted(segs)
    grade = defaultdict(list)
    for k, (a, b) in enumerate(segs):
        for gx in range(min(a[0], b[0]) // 2000, max(a[0], b[0]) // 2000 + 1):
            for gy in range(min(a[1], b[1]) // 2000, max(a[1], b[1]) // 2000 + 1):
                grade[(gx, gy)].append(k)
    ruins = set()
    for cel in grade.values():
        for x in range(len(cel)):
            for y in range(x + 1, len(cel)):
                (a, b), (c, d) = segs[cel[x]], segs[cel[y]]
                if len({a, b, c, d}) < 4:
                    if len({a, b, c, d}) == 3:  # extremo comum: conflito só se colineares sobrepostos
                        o = (orient(a, b, c), orient(a, b, d))
                        if o == (0, 0):
                            outro = [p for p in (c, d) if p not in (a, b)][0]
                            com = [p for p in (a, b) if p in (c, d)][0]
                            alvo = [p for p in (a, b) if p != com][0]
                            if (outro[0] - com[0]) * (alvo[0] - com[0]) + (outro[1] - com[1]) * (alvo[1] - com[1]) > 0:
                                ruins.add((cel[x], cel[y]))
                    continue
                o1, o2, o3, o4 = orient(a, b, c), orient(a, b, d), orient(c, d, a), orient(c, d, b)
                if o1 * o2 <= 0 and o3 * o4 <= 0 and not (o1 == o2 == 0 and max(a, b) < min(c, d)):
                    ruins.add((cel[x], cel[y]))
    return len(ruins)


checks = {}
checks["27_ufs_unicas"] = len(pais["estados"]) == 27 and set(G) == UFS and len(P) == 27 and set(P) == UFS
checks["formato"] = pais["formato"] == "mundo-pais/1" and perf["formato"] == "mundo-perfis/1"
checks["fonte_registrada"] = len(pais["fonte"]["sha256"]) == 64 and len(pais["fonte"]["commit"]) == 40 \
    and "domínio público" in pais["fonte"]["licenca"] and (FERR / "FONTE.md").exists()
checks["campos_geometria"] = all(set(e) == CAMPOS_G for e in pais["estados"])
checks["campos_perfis"] = all(set(e) == CAMPOS_P and all(v not in (None, "", [], {}) or k == "vizinhos" for k, v in e.items())
                              for e in perf["estados"])
dif = {uf: 100 * (G[uf]["area_km2"] / P[uf]["area_oficial_km2"] - 1) for uf in UFS}
checks["area_5pct_ibge"] = all(abs(d) <= TOL_AREA.get(uf, 5.0) for uf, d in dif.items())
checks["area_total_1pct"] = abs(sum(G[u]["area_km2"] for u in UFS) / sum(P[u]["area_oficial_km2"] for u in UFS) - 1) < 0.01
checks["vizinhos_conhecidos"] = all(G[uf]["vizinhos"] == sorted(DIVISAS[uf].split()) for uf in UFS)
checks["vizinhos_simetricos"] = all(uf in G[v]["vizinhos"] and G[uf]["divisas_km"][v] == G[v]["divisas_km"][uf]
                                    for uf in UFS for v in G[uf]["vizinhos"])
checks["df_so_go_sp_4"] = G["DF"]["vizinhos"] == ["GO"] and G["SP"]["vizinhos"] == ["MG", "MS", "PR", "RJ"]
checks["litoral_17"] = {u for u in UFS if G[u]["litoral"]} == COSTEIROS and \
    all((G[u]["litoral_km"] > 0) == G[u]["litoral"] for u in UFS)
checks["fronteira_exterior"] = {u for u in UFS if G[u]["fronteira_exterior_km"] > 0} == \
    set("AC AM AP MS MT PA PR RO RR RS SC".split())
checks["centroide_na_caixa"] = all(e["caixa"][0] <= e[c][0] * 1e4 <= e["caixa"][2] and e["caixa"][1] <= e[c][1] * 1e4 <= e["caixa"][3]
                                   for e in pais["estados"] for c in ("centroide", "rotulo"))
checks["poligonos_validos"] = all(len(p) >= 6 and len(p) % 2 == 0 for e in pais["estados"] for p in e["poligonos"])
checks["sem_cruzamentos"] = cruzamentos() == 0
checks["peso_formula"] = all(P[u]["peso"] == lotes_formula(P[u]["area_oficial_km2"]) for u in UFS)
checks["peso_40_120"] = all(40 <= P[u]["peso"] <= 120 for u in UFS) and P["DF"]["peso"] == 40 and P["AM"]["peso"] == 120
ordem = sorted(UFS, key=lambda u: P[u]["area_oficial_km2"])
checks["peso_monotonico"] = all(P[a]["peso"] <= P[b]["peso"] for a, b in zip(ordem, ordem[1:]))
hab = [u for u in ordem if u != "DF"]
checks["vagas_2000_df_capital"] = sum(P[u]["vagas_base"] for u in UFS) == 2000 and P["DF"]["vagas_base"] == 0 \
    and [u for u in UFS if P[u]["capital_federal"]] == ["DF"] and all(P[u]["vagas_base"] > 0 for u in hab) \
    and all(P[a]["vagas_base"] <= P[b]["vagas_base"] for a, b in zip(hab, hab[1:]))
checks["capitais_no_estado"] = all(dist_borda_km(u, P[u]["capital"]["lon"], P[u]["capital"]["lat"]) <= 2.0 for u in UFS)
checks["perfis_coerentes"] = all(P[u]["vizinhos"] == G[u]["vizinhos"] and P[u]["litoral"] == G[u]["litoral"]
                                 and P[u]["area_calculada_km2"] == G[u]["area_km2"] for u in UFS)
checks["biomas_regioes"] = all(P[u]["bioma_dominante"] == P[u]["biomas"][0] and set(P[u]["biomas"]) <= BIOMAS
                               and 2 <= len(P[u]["bonus_regiao_pct"]) <= 3 and set(P[u]["bonus_regiao_pct"]) <= RECURSOS
                               and sum(P[u]["bonus_regiao_pct"].values()) == 20 for u in UFS)
checks["tamanho_ate_1MB"] = (DADOS / "BR.json").stat().st_size <= 1_000_000

with tempfile.TemporaryDirectory() as tmp:
    saidas = []
    for i in range(2):
        s = Path(tmp) / f"perfis{i}.json"
        subprocess.run([sys.executable, "-I", str(FERR / "gerar_perfis.py"), "--saida", str(s)], check=True, capture_output=True)
        saidas.append(hashlib.sha256(s.read_bytes()).hexdigest())
    checks["determinismo_perfis"] = saidas[0] == saidas[1] == hashlib.sha256((DADOS / "BR_perfis.json").read_bytes()).hexdigest()
    pulado = []
    if (FERR / ".cache" / "ne_10m_admin_1_states_provinces.geojson").exists():
        saidas = []
        for i in range(2):
            s = Path(tmp) / f"br{i}.json"
            subprocess.run([sys.executable, "-I", str(FERR / "gerar_pais.py"), "--saida", str(s)], check=True, capture_output=True)
            saidas.append(hashlib.sha256(s.read_bytes()).hexdigest())
        checks["determinismo_geometria"] = saidas[0] == saidas[1] == hashlib.sha256((DADOS / "BR.json").read_bytes()).hexdigest()
    else:
        pulado.append("determinismo_geometria (fonte ausente; rode tools/mundo/gerar_pais.py uma vez)")

failed = [k for k, v in checks.items() if not v]
print(f"mundo_brasil {len(checks)-len(failed)}/{len(checks)} falhas={failed}" + (f" pulado={pulado}" if pulado else ""))
if "area_5pct_ibge" in failed:
    print("  áreas fora:", {u: round(d, 1) for u, d in dif.items() if abs(d) > TOL_AREA.get(u, 5.0)})
raise SystemExit(1 if failed else 0)
