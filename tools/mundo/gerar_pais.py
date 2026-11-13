#!/usr/bin/env python3
"""Gera game/data/mundo/BR.json a partir do Natural Earth (admin 1, 1:10m).

Python puro (só a biblioteca padrão). Mesma fonte e mesmos parâmetros dão o
mesmo arquivo, byte a byte.

Uso:
  python3 -I tools/mundo/gerar_pais.py                 # baixa (se preciso), confere e gera
  python3 -I tools/mundo/gerar_pais.py --fonte F.geojson --saida X.json
  python3 -I tools/mundo/gerar_pais.py --fator 0.002 --relatorio

A fonte bruta (cerca de 40 MB) não é versionada: fica em tools/mundo/.cache/
(ignorada pelo git) e é conferida pelo SHA-256 abaixo antes de usar.

Etapas:
  1. lê os 27 estados (adm0_a3 = BRA) e as bordas dos outros países;
  2. descarta ilhas pequenas (ILHA_MIN_KM2);
  3. quebra os contornos em arcos (trechos com os mesmos donos: divisa entre
     dois estados, fronteira com outro país ou litoral), para cada divisa ser
     simplificada uma vez só e os vizinhos continuarem encaixados;
  4. simplifica cada arco com Douglas-Peucker na projeção de área igual
     (Albers da América do Sul, elipsoide WGS 84), com tolerância proporcional
     ao tamanho do estado (FATOR_TOL);
  5. arredonda as coordenadas para 0,0001 grau (cerca de 11 m);
  6. calcula área, centroide, ponto do rótulo, litoral, fronteira externa e
     vizinhos sobre a geometria final, e grava o JSON.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import sys
import urllib.request
from collections import defaultdict

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.dirname(os.path.dirname(AQUI))

FONTE_COMMIT = "ca96624a56bd078437bca8184e78163e5039ad19"
FONTE_ARQUIVO = "geojson/ne_10m_admin_1_states_provinces.geojson"
FONTE_URL = f"https://raw.githubusercontent.com/nvkelso/natural-earth-vector/{FONTE_COMMIT}/{FONTE_ARQUIVO}"
FONTE_SHA256 = "22d0e3ad85eb3e27f17cabf8ba2d50e554fbc27a87796ff891d958185da62fb5"
FONTE_CACHE = os.path.join(AQUI, ".cache", "ne_10m_admin_1_states_provinces.geojson")

# Tolerância do Douglas-Peucker por estado: FATOR_TOL x raiz da área (o "diâmetro"),
# limitada a [TOL_MIN_M, TOL_MAX_M]. Com 0,002, o erro fica em cerca de 2 px quando o
# estado ocupa 1080 px da tela. Cada arco usa a menor tolerância entre os estados que
# o tocam, para a divisa ser uma só dos dois lados.
FATOR_TOL = 0.002
TOL_MIN_M = 100.0
TOL_MAX_M = 2500.0
ILHA_MIN_KM2 = 100.0       # polígonos menores são descartados (ex.: Fernando de Noronha)
QUANT = 10000              # coordenadas gravadas como inteiros de 0,0001 grau
FORMATO = "mundo-pais/1"

NOMES = {
    "AC": "Acre", "AL": "Alagoas", "AP": "Amapá", "AM": "Amazonas", "BA": "Bahia",
    "CE": "Ceará", "DF": "Distrito Federal", "ES": "Espírito Santo", "GO": "Goiás",
    "MA": "Maranhão", "MT": "Mato Grosso", "MS": "Mato Grosso do Sul",
    "MG": "Minas Gerais", "PA": "Pará", "PB": "Paraíba", "PR": "Paraná",
    "PE": "Pernambuco", "PI": "Piauí", "RJ": "Rio de Janeiro",
    "RN": "Rio Grande do Norte", "RS": "Rio Grande do Sul", "RO": "Rondônia",
    "RR": "Roraima", "SC": "Santa Catarina", "SP": "São Paulo", "SE": "Sergipe",
    "TO": "Tocantins",
}

# --- Projeção Albers de área igual no elipsoide WGS 84 (Snyder, 1987, cap. 14) ---
_A = 6378137.0
_F = 1 / 298.257223563
_E2 = _F * (2 - _F)
_E = math.sqrt(_E2)
_LAT1, _LAT2, _LAT0, _LON0 = map(math.radians, (-5.0, -42.0, -32.0, -60.0))


def _q(phi: float) -> float:
    s = math.sin(phi)
    return (1 - _E2) * (s / (1 - _E2 * s * s) - (1 / (2 * _E)) * math.log((1 - _E * s) / (1 + _E * s)))


def _m(phi: float) -> float:
    s = math.sin(phi)
    return math.cos(phi) / math.sqrt(1 - _E2 * s * s)


_M1, _M2 = _m(_LAT1), _m(_LAT2)
_Q1, _Q2, _Q0 = _q(_LAT1), _q(_LAT2), _q(_LAT0)
_N = (_M1 * _M1 - _M2 * _M2) / (_Q2 - _Q1)
_C = _M1 * _M1 + _N * _Q1
_RHO0 = _A * math.sqrt(_C - _N * _Q0) / _N
PROJECAO = "Albers de área igual, WGS 84, paralelos -5 e -42, origem -32/-60"


def projetar(lon: float, lat: float) -> tuple[float, float]:
    rho = _A * math.sqrt(_C - _N * _q(math.radians(lat))) / _N
    th = _N * (math.radians(lon) - _LON0)
    return rho * math.sin(th), _RHO0 - rho * math.cos(th)


def desprojetar(x: float, y: float) -> tuple[float, float]:
    dy = _RHO0 - y
    rho = math.copysign(math.hypot(x, dy), _N)  # n < 0 no hemisfério sul
    th = math.atan2(x / rho, dy / rho)
    q = (_C - (rho * _N / _A) ** 2) / _N
    phi = math.asin(max(-1.0, min(1.0, q / 2)))
    for _ in range(20):
        s = math.sin(phi)
        d = ((1 - _E2 * s * s) ** 2 / (2 * math.cos(phi))) * (
            q / (1 - _E2) - s / (1 - _E2 * s * s) + (1 / (2 * _E)) * math.log((1 - _E * s) / (1 + _E * s)))
        phi += d
        if abs(d) < 1e-12:
            break
    return math.degrees(_LON0 + th / _N), math.degrees(phi)


# --- Geometria plana (metros) ---
def area_anel(p: list) -> float:
    s = 0.0
    n = len(p)
    for i in range(n):
        x1, y1 = p[i]
        x2, y2 = p[(i + 1) % n]
        s += x1 * y2 - x2 * y1
    return s / 2


def centroide_anel(p: list) -> tuple[float, float, float]:
    a = cx = cy = 0.0
    n = len(p)
    for i in range(n):
        x1, y1 = p[i]
        x2, y2 = p[(i + 1) % n]
        c = x1 * y2 - x2 * y1
        a += c
        cx += (x1 + x2) * c
        cy += (y1 + y2) * c
    a /= 2
    return a, cx / (6 * a), cy / (6 * a)


def dentro(x: float, y: float, aneis: list) -> bool:
    ins = False
    for p in aneis:
        n = len(p)
        for i in range(n):
            x1, y1 = p[i]
            x2, y2 = p[(i + 1) % n]
            if (y1 > y) != (y2 > y) and x < x1 + (y - y1) * (x2 - x1) / (y2 - y1):
                ins = not ins
    return ins


def dist_seg(px, py, ax, ay, bx, by) -> float:
    dx, dy = bx - ax, by - ay
    L = dx * dx + dy * dy
    t = 0.0 if L == 0 else max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / L))
    return math.hypot(px - ax - t * dx, py - ay - t * dy)


def ponto_rotulo(aneis: list) -> tuple[float, float]:
    """Ponto interno mais distante da borda (busca em grade, refinada 4 vezes)."""
    xs = [x for p in aneis for x, _ in p]
    ys = [y for p in aneis for _, y in p]
    segs = [(p[i][0], p[i][1], p[(i + 1) % len(p)][0], p[(i + 1) % len(p)][1]) for p in aneis for i in range(len(p))]

    def folga(x, y):
        if not dentro(x, y, aneis):
            return -1.0
        return min(dist_seg(x, y, *s) for s in segs)

    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    melhor = (-2.0, (x0 + x1) / 2, (y0 + y1) / 2)
    for _ in range(4):
        g = 24
        for i in range(g + 1):
            for j in range(g + 1):
                x = x0 + (x1 - x0) * i / g
                y = y0 + (y1 - y0) * j / g
                f = folga(x, y)
                if f > melhor[0]:
                    melhor = (f, x, y)
        wx, wy = (x1 - x0) / 6, (y1 - y0) / 6
        x0, x1, y0, y1 = melhor[1] - wx, melhor[1] + wx, melhor[2] - wy, melhor[2] + wy
    return melhor[1], melhor[2]


def douglas_peucker(pts: list, tol: float) -> list:
    """Mantém os extremos; devolve os índices mantidos (ordem crescente)."""
    n = len(pts)
    if n <= 2:
        return list(range(n))
    manter = [False] * n
    manter[0] = manter[-1] = True
    pilha = [(0, n - 1)]
    while pilha:
        i, j = pilha.pop()
        ax, ay = pts[i]
        bx, by = pts[j]
        dmax, k = -1.0, -1
        for m in range(i + 1, j):
            d = dist_seg(pts[m][0], pts[m][1], ax, ay, bx, by)
            if d > dmax:
                dmax, k = d, m
        if k >= 0 and dmax > tol:
            manter[k] = True
            pilha.append((i, k))
            pilha.append((k, j))
    return [i for i in range(n) if manter[i]]


def _orient(p, q, r) -> int:
    v = (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])
    return (v > 0) - (v < 0)


def _no_segmento(p, q, r) -> bool:
    """r colinear com pq está dentro do segmento (inclusive extremos)?"""
    return min(p[0], q[0]) <= r[0] <= max(p[0], q[0]) and min(p[1], q[1]) <= r[1] <= max(p[1], q[1])


def segmentos_conflitam(a, b, c, d) -> bool:
    """Dois segmentos (inteiros) se cruzam ou se sobrepõem fora de um extremo comum."""
    comuns = {a, b} & {c, d}
    o1, o2, o3, o4 = _orient(a, b, c), _orient(a, b, d), _orient(c, d, a), _orient(c, d, b)
    if comuns:
        if len(comuns) == 2:
            return True  # segmento repetido
        # extremo comum: só conflita se forem colineares e se sobrepuserem
        if o1 == 0 and o2 == 0:
            outro1 = b if a in comuns else a
            outro2 = d if c in comuns else c
            return _no_segmento(c, d, outro1) or _no_segmento(a, b, outro2)
        return False
    if o1 != o2 and o3 != o4:
        return True
    return ((o1 == 0 and _no_segmento(a, b, c)) or (o2 == 0 and _no_segmento(a, b, d))
            or (o3 == 0 and _no_segmento(c, d, a)) or (o4 == 0 and _no_segmento(c, d, b)))


def arcos_que_cruzam(arcos: list, celula: int = 2000) -> set:
    """Índices dos arcos com segmentos em conflito (entre si ou com outro arco)."""
    segs = []
    for k, a in enumerate(arcos):
        for i in range(len(a) - 1):
            segs.append((a[i], a[i + 1], k, i))
    grade = defaultdict(list)
    for s, (p, q, _, _) in enumerate(segs):
        for gx in range(min(p[0], q[0]) // celula, max(p[0], q[0]) // celula + 1):
            for gy in range(min(p[1], q[1]) // celula, max(p[1], q[1]) // celula + 1):
                grade[(gx, gy)].append(s)
    ruins = set()
    vistos = set()
    for lista in grade.values():
        for x in range(len(lista)):
            for y in range(x + 1, len(lista)):
                s1, s2 = lista[x], lista[y]
                if (s1, s2) in vistos:
                    continue
                vistos.add((s1, s2))
                p, q, k1, i1 = segs[s1]
                r, t, k2, i2 = segs[s2]
                if k1 == k2 and abs(i1 - i2) == 1:
                    continue  # vizinhos no mesmo arco
                if k1 == k2 and {i1, i2} == {0, len(arcos[k1]) - 2} and arcos[k1][0] == arcos[k1][-1]:
                    continue  # fecho de anel isolado
                if segmentos_conflitam(p, q, r, t):
                    ruins.add(k1)
                    ruins.add(k2)
    return ruins


# --- Fonte ---
def sha256(caminho: str) -> str:
    h = hashlib.sha256()
    with open(caminho, "rb") as f:
        for bloco in iter(lambda: f.read(1 << 20), b""):
            h.update(bloco)
    return h.hexdigest()


def obter_fonte(caminho: str | None) -> str:
    if caminho is None:
        caminho = FONTE_CACHE
        if not os.path.exists(caminho):
            os.makedirs(os.path.dirname(caminho), exist_ok=True)
            print(f"baixando {FONTE_URL}", file=sys.stderr)
            urllib.request.urlretrieve(FONTE_URL, caminho + ".parcial")
            os.replace(caminho + ".parcial", caminho)
    s = sha256(caminho)
    if s != FONTE_SHA256:
        sys.exit(f"SHA-256 da fonte não confere: {s} (esperado {FONTE_SHA256})")
    return caminho


def poligonos(g: dict) -> list:
    return g["coordinates"] if g["type"] == "MultiPolygon" else [g["coordinates"]]


def chave(pt) -> tuple[float, float]:
    return (float(pt[0]), float(pt[1]))


# --- Geração ---
def tolerancia_estado(area_m2: float, fator: float) -> float:
    return max(TOL_MIN_M, min(TOL_MAX_M, fator * math.sqrt(area_m2)))


def gerar(fonte: str, fator: float, ilha_min_km2: float) -> tuple[dict, dict]:
    with open(fonte, encoding="utf-8") as f:
        dados = json.load(f)

    externas = set()  # arestas de outros países (para separar fronteira de litoral)
    estados: dict[str, list] = {}
    for ft in dados["features"]:
        pr = ft["properties"]
        if pr.get("adm0_a3") == "BRA":
            uf = pr["postal"]
            aneis = []
            for poly in poligonos(ft["geometry"]):
                anel = [chave(p) for p in poly[0]]  # sem buracos: nenhum estado tem
                if anel[0] == anel[-1]:
                    anel.pop()
                if abs(area_anel([projetar(*p) for p in anel])) / 1e6 >= ilha_min_km2:
                    aneis.append(anel)
            estados[uf] = aneis
        else:
            for poly in poligonos(ft["geometry"]):
                for r in poly:
                    for i in range(len(r) - 1):
                        externas.add(frozenset((chave(r[i]), chave(r[i + 1]))))

    if sorted(estados) != sorted(NOMES):
        sys.exit(f"esperava as 27 UFs, veio {sorted(estados)}")

    # Classe de cada aresta: (donos, tipo). tipo: 'divisa', 'exterior', 'mar'.
    donos = defaultdict(set)
    for uf, aneis in estados.items():
        for anel in aneis:
            for i in range(len(anel)):
                donos[frozenset((anel[i], anel[(i + 1) % len(anel)]))].add(uf)

    def classe(a, b):
        e = frozenset((a, b))
        d = donos[e]
        if len(d) >= 2:
            return ("divisa",) + tuple(sorted(d))
        return ("exterior" if e in externas else "mar", next(iter(d)))

    # Quebra em arcos. Um vértice é junção (em todos os anéis que o usam) quando a
    # classe da aresta muda nele em algum anel ou quando tem mais de dois vizinhos
    # (ex.: o ponto onde o DF encosta no MG na fonte).
    viz_vert = defaultdict(set)
    juncao = set()
    for uf, aneis in estados.items():
        for anel in aneis:
            n = len(anel)
            for i in range(n):
                viz_vert[anel[i]].add(anel[i - 1])
                viz_vert[anel[i]].add(anel[(i + 1) % n])
                if classe(anel[i - 1], anel[i]) != classe(anel[i], anel[(i + 1) % n]):
                    juncao.add(anel[i])
    juncao |= {v for v, s in viz_vert.items() if len(s) > 2}
    arcos: dict[tuple, int] = {}
    lista_arcos: list[list] = []
    tipo_arco: list[tuple] = []
    aneis_arcos: dict[str, list] = {}
    for uf in sorted(estados):
        aneis_arcos[uf] = []
        for anel in estados[uf]:
            n = len(anel)
            cl = [classe(anel[i], anel[(i + 1) % n]) for i in range(n)]
            juncoes = [i for i in range(n) if anel[i] in juncao]
            if not juncoes:  # anel inteiro de uma classe só (ilha): começa no menor vértice
                ini = min(range(n), key=lambda i: anel[i])
                juncoes = [ini]
                rot = anel[ini:] + anel[:ini] + [anel[ini]]
                trechos = [(rot, cl[0])]
            else:
                trechos = []
                for k, j in enumerate(juncoes):
                    fim = juncoes[(k + 1) % len(juncoes)]
                    seq = []
                    i = j
                    while True:
                        seq.append(anel[i])
                        if i == fim and len(seq) > 1:
                            break
                        i = (i + 1) % n
                    trechos.append((seq, cl[j]))
            refs = []
            for seq, c in trechos:
                t = tuple(seq)
                if t in arcos:
                    refs.append(arcos[t])
                elif t[::-1] in arcos:
                    refs.append(~arcos[t[::-1]])
                else:
                    arcos[t] = len(lista_arcos)
                    refs.append(len(lista_arcos))
                    lista_arcos.append(list(seq))
                    tipo_arco.append(c)
            aneis_arcos[uf].append(refs)

    # Tolerância por estado (área da fonte) e por arco (a menor entre os donos).
    tol_uf = {uf: tolerancia_estado(sum(abs(area_anel([projetar(*p) for p in a])) for a in aneis), fator)
              for uf, aneis in estados.items()}

    # Simplifica cada arco uma vez (em metros) e arredonda. Arcos que passam a se
    # cruzar (ou a se sobrepor) têm a tolerância reduzida à metade e são refeitos,
    # até não sobrar cruzamento.
    xy_arcos = [[projetar(*p) for p in seq] for seq in lista_arcos]
    tol_arco = [min(tol_uf[u] for u in c[1:]) for c in tipo_arco]

    def simplificar(k: int) -> list:
        seq, xy, tol_m = lista_arcos[k], xy_arcos[k], tol_arco[k]
        if tol_m < 1:
            idx = list(range(len(seq)))
        elif seq[0] == seq[-1]:  # anel isolado: divide no vértice mais distante do início
            m = max(range(len(xy)), key=lambda i: (xy[i][0] - xy[0][0]) ** 2 + (xy[i][1] - xy[0][1]) ** 2)
            idx = douglas_peucker(xy[:m + 1], tol_m) + [m + i for i in douglas_peucker(xy[m:], tol_m)[1:]]
            if len(idx) < 5:  # garante pelo menos um triângulo
                idx = sorted(set(idx) | {len(xy) // 3, 2 * len(xy) // 3})
        else:
            idx = douglas_peucker(xy, tol_m)
        return [(round(seq[i][0] * QUANT), round(seq[i][1] * QUANT)) for i in idx]

    simples: list[list] = [simplificar(k) for k in range(len(lista_arcos))]
    refinos = 0
    while True:
        ruins = arcos_que_cruzam(simples)
        if not ruins:
            break
        for k in sorted(ruins):
            tol_arco[k] /= 2
            simples[k] = simplificar(k)
        refinos += len(ruins)
    print(f"arcos: {len(simples)}; refeitos por cruzamento: {refinos}", file=sys.stderr)

    def montar(refs):
        pts = []
        for r in refs:
            a = simples[r] if r >= 0 else simples[~r][::-1]
            pts.extend(a[1:] if pts else a)
        if pts[0] == pts[-1]:
            pts.pop()
        # remove repetições consecutivas criadas pelo arredondamento
        out = [p for i, p in enumerate(pts) if p != pts[i - 1]]
        return out

    def km_arco(a):
        tot = 0.0
        for i in range(len(a) - 1):
            x1, y1 = projetar(a[i][0] / QUANT, a[i][1] / QUANT)
            x2, y2 = projetar(a[i + 1][0] / QUANT, a[i + 1][1] / QUANT)
            tot += math.hypot(x2 - x1, y2 - y1)
        return tot / 1000

    divisas = defaultdict(float)
    litoral = defaultdict(float)
    exterior = defaultdict(float)
    for a, c in zip(simples, tipo_arco):
        L = km_arco(a)
        if c[0] == "divisa":
            for uf in c[1:]:
                for v in c[1:]:
                    if v != uf:
                        divisas[(uf, v)] += L
        elif c[0] == "mar":
            litoral[c[1]] += L
        else:
            exterior[c[1]] += L

    saida_estados = []
    relatorio = {}
    for uf in sorted(estados):
        aneis_q = [montar(refs) for refs in aneis_arcos[uf]]
        aneis_ll = []
        for anel in aneis_q:
            if area_anel(anel) < 0:  # anti-horário em lon/lat
                anel = anel[::-1]
            aneis_ll.append(anel)
        aneis_xy = [[projetar(x / QUANT, y / QUANT) for x, y in anel] for anel in aneis_ll]
        area = cx = cy = 0.0
        for p in aneis_xy:
            a, x, y = centroide_anel(p)
            area += a
            cx += a * x
            cy += a * y
        cx, cy = cx / area, cy / area
        clon, clat = desprojetar(cx, cy)
        rx, ry = ponto_rotulo(aneis_xy)
        rlon, rlat = desprojetar(rx, ry)
        todos = [p for anel in aneis_ll for p in anel]
        viz = sorted(v for (u, v) in divisas if u == uf)
        e = {
            "uf": uf,
            "nome": NOMES[uf],
            "area_km2": round(area / 1e6),
            "centroide": [round(clon, 4), round(clat, 4)],
            "rotulo": [round(rlon, 4), round(rlat, 4)],
            "caixa": [min(p[0] for p in todos), min(p[1] for p in todos),
                      max(p[0] for p in todos), max(p[1] for p in todos)],
            "litoral": litoral[uf] > 0,
            "litoral_km": round(litoral[uf]),
            "fronteira_exterior_km": round(exterior[uf]),
            "vizinhos": viz,
            "divisas_km": {v: round(divisas[(uf, v)]) for v in viz},
            "poligonos": [[c for p in anel for c in p] for anel in aneis_ll],
        }
        saida_estados.append(e)
        relatorio[uf] = {"vertices": len(todos), "poligonos": len(aneis_ll), "tol": tol_uf[uf]}

    doc = {
        "formato": FORMATO,
        "pais": "BR",
        "nome": "Brasil",
        "fonte": {
            "nome": "Natural Earth, Admin 1 (estados e províncias), escala 1:10m",
            "licenca": "domínio público (naturalearthdata.com/about/terms-of-use)",
            "repositorio": "github.com/nvkelso/natural-earth-vector",
            "commit": FONTE_COMMIT,
            "arquivo": FONTE_ARQUIVO,
            "sha256": FONTE_SHA256,
        },
        "geracao": {
            "script": "tools/mundo/gerar_pais.py",
            "projecao_area": PROJECAO,
            "tolerancia": f"Douglas-Peucker por arco; {fator:g} x raiz da área do estado, entre {TOL_MIN_M:g} e {TOL_MAX_M:g} m; divisa usa a menor dos dois lados",
            "ilha_min_km2": ilha_min_km2,
            "coordenadas": "inteiros em 1/10000 de grau, [lon, lat, lon, lat, ...], anel externo anti-horário, sem repetir o primeiro ponto",
        },
        "estados": saida_estados,
    }
    return doc, relatorio


def serializar(doc: dict) -> str:
    """JSON compacto e determinístico, um estado por linha."""
    def c(v):
        return json.dumps(v, ensure_ascii=False, separators=(",", ":"), sort_keys=True)
    cab = {k: v for k, v in doc.items() if k != "estados"}
    linhas = [c(cab)[:-1] + ',"estados":[']
    linhas += [c(e) + ("," if i < len(doc["estados"]) - 1 else "") for i, e in enumerate(doc["estados"])]
    linhas.append("]}")
    return "\n".join(linhas) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--fonte", help="GeoJSON já baixado (conferido pelo SHA-256)")
    ap.add_argument("--saida", default=os.path.join(RAIZ, "game", "data", "mundo", "BR.json"))
    ap.add_argument("--fator", type=float, default=FATOR_TOL, help="tolerância / raiz da área (padrão %(default)s)")
    ap.add_argument("--ilha-min", type=float, default=ILHA_MIN_KM2, help="km² (padrão %(default)s)")
    ap.add_argument("--relatorio", action="store_true", help="imprime vértices por estado")
    a = ap.parse_args()
    fonte = obter_fonte(a.fonte)
    doc, rel = gerar(fonte, a.fator, a.ilha_min)
    texto = serializar(doc)
    os.makedirs(os.path.dirname(os.path.abspath(a.saida)), exist_ok=True)
    with open(a.saida, "w", encoding="utf-8", newline="\n") as f:
        f.write(texto)
    tam = len(texto.encode("utf-8"))
    vt = sum(r["vertices"] for r in rel.values())
    print(f"{a.saida}: {tam} bytes, {vt} vértices, fator {a.fator:g}, sha256 {hashlib.sha256(texto.encode()).hexdigest()}")
    if a.relatorio:
        for uf in sorted(rel):
            e = next(x for x in doc["estados"] if x["uf"] == uf)
            print(f"  {uf} tol={rel[uf]['tol']:5.0f}m vert={rel[uf]['vertices']:5d} pol={rel[uf]['poligonos']} area={e['area_km2']:8d} "
                  f"litoral={e['litoral_km']:5d} ext={e['fronteira_exterior_km']:5d} viz={','.join(e['vizinhos'])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
