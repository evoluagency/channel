#!/usr/bin/env python3
"""Folha de conferência: contornos simplificados dos 27 estados, sigla e lotes.

Lê game/data/mundo/BR.json e BR_perfis.json e grava um PNG (Pillow). Projeção de
desenho: equirretangular com a longitude escalada por cos(-15°), só para olhar.

Uso: python3 -I tools/mundo/folha_conferencia.py [--saida game/docs/imagens/mundo/BR_conferencia.png]
"""
from __future__ import annotations

import argparse
import json
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFont

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.dirname(os.path.dirname(AQUI))
FONTE = os.path.join(RAIZ, "tools", "arte3d", "fontes", "Montserrat.ttf")

COR_REGIAO = {
    "Norte": (139, 190, 150), "Nordeste": (236, 196, 120), "Centro-Oeste": (222, 160, 120),
    "Sudeste": (150, 175, 220), "Sul": (190, 160, 210),
}
FUNDO = (246, 244, 238)
MAR = (214, 230, 240)
DIVISA = (60, 60, 60)
TEXTO = (25, 25, 25)


def fonte(tam: int, peso: int = 700):
    f = ImageFont.truetype(FONTE, tam)
    try:
        f.set_variation_by_axes([peso])
    except Exception:
        pass
    return f


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--pais", default=os.path.join(RAIZ, "game", "data", "mundo", "BR.json"))
    ap.add_argument("--perfis", default=os.path.join(RAIZ, "game", "data", "mundo", "BR_perfis.json"))
    ap.add_argument("--saida", default=os.path.join(RAIZ, "game", "docs", "imagens", "mundo", "BR_conferencia.png"))
    ap.add_argument("--largura", type=int, default=2000)
    a = ap.parse_args()
    pais = json.load(open(a.pais, encoding="utf-8"))
    perfis = {p["uf"]: p for p in json.load(open(a.perfis, encoding="utf-8"))["estados"]}

    k = math.cos(math.radians(-15))
    cx = [c for e in pais["estados"] for c in (e["caixa"][0], e["caixa"][2])]
    cy = [c for e in pais["estados"] for c in (e["caixa"][1], e["caixa"][3])]
    x0, x1, y0, y1 = min(cx) / 1e4, max(cx) / 1e4, min(cy) / 1e4, max(cy) / 1e4
    marg, topo, rodape = 40, 110, 150
    esc = (a.largura - 2 * marg - 110) / ((x1 - x0) * k)
    alt = int(topo + (y1 - y0) * esc + rodape)
    W = a.largura

    def P(lon, lat):
        return (marg + (lon - x0) * k * esc, topo + (y1 - lat) * esc)

    img = Image.new("RGB", (W, alt), FUNDO)
    d = ImageDraw.Draw(img)
    d.rectangle([marg - 10, topo - 10, W - marg + 10, alt - rodape + 10], fill=MAR)
    for e in pais["estados"]:
        cor = COR_REGIAO[perfis[e["uf"]]["regiao"]]
        for anel in e["poligonos"]:
            pts = [P(anel[i] / 1e4, anel[i + 1] / 1e4) for i in range(0, len(anel), 2)]
            d.polygon(pts, fill=cor)
    for e in pais["estados"]:
        for anel in e["poligonos"]:
            pts = [P(anel[i] / 1e4, anel[i + 1] / 1e4) for i in range(0, len(anel), 2)]
            d.line(pts + [pts[0]], fill=DIVISA, width=2)

    f_uf, f_lt = fonte(30, 800), fonte(22, 600)
    f_uf_p, f_lt_p = fonte(20, 800), fonte(16, 600)
    pequenos = {"DF", "SE", "AL", "RJ", "ES", "RN", "PB"}
    deslocar = {"RN": (55, -35), "PB": (70, 5), "AL": (75, 25), "SE": (65, 55), "ES": (70, 20), "RJ": (55, 60)}
    for e in pais["estados"]:
        uf = e["uf"]
        x, y = P(*e["rotulo"])
        t1, t2 = uf, str(perfis[uf]["lotes"])
        fu, fl = (f_uf_p, f_lt_p) if uf in pequenos else (f_uf, f_lt)
        if uf in deslocar:
            dx, dy = deslocar[uf]
            d.line([(x, y), (x + dx, y + dy)], fill=TEXTO, width=2)
            d.ellipse([x - 3, y - 3, x + 3, y + 3], fill=TEXTO)
            x, y = x + dx + 18, y + dy
        d.text((x, y), t1, font=fu, fill=TEXTO, anchor="ms")
        d.text((x, y + 4), t2, font=fl, fill=TEXTO, anchor="mt")

    d.text((marg, 30), "Brasil: 27 estados, sigla e lotes", font=fonte(40, 800), fill=TEXTO)
    d.text((marg, 78), "Contornos simplificados de game/data/mundo/BR.json (Natural Earth 1:10m, domínio público)",
           font=fonte(20, 500), fill=TEXTO)
    yl = alt - rodape + 30
    xl = marg
    for reg, cor in COR_REGIAO.items():
        d.rectangle([xl, yl, xl + 26, yl + 26], fill=cor, outline=DIVISA)
        d.text((xl + 34, yl + 2), reg, font=fonte(20, 600), fill=TEXTO)
        xl += 230
    tam = os.path.getsize(a.pais)
    nv = sum(len(an) // 2 for e in pais["estados"] for an in e["poligonos"])
    d.text((marg, yl + 45), "Lotes = round(clamp(40 + 32,9 × log10(área IBGE / 5760), 40, 120)). "
           f"Arquivo: {tam // 1000} KB, {nv} vértices.", font=fonte(20, 500), fill=TEXTO)
    d.text((marg, yl + 75), pais["geracao"]["tolerancia"], font=fonte(18, 500), fill=TEXTO)
    os.makedirs(os.path.dirname(os.path.abspath(a.saida)), exist_ok=True)
    img.save(a.saida, optimize=True)
    print(f"{a.saida}: {W}x{alt}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
