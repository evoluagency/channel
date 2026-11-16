#!/usr/bin/env python3
"""Gera a textura de cada herói do Valdora PvP a partir da textura-paleta do KayKit (CC0).

Lê game/data/pvp/herois.json e grava game/assets/pvp/personagens/herois/<id>.png (256 x 256).
Cada faixa [coluna, linha] da grade 8 x 4 recebe a cor do herói, mantendo o degradê
original (a luminância relativa de cada pixel). Uso: python3 -I tools/pvp/recolorir_herois.py
"""
import json
from pathlib import Path
from PIL import Image

RAIZ = Path(__file__).resolve().parents[2] / "game"
PERS = RAIZ / "assets/pvp/personagens"
TEX = {"Rogue": "Rogue_rogue_texture.png", "Rogue_Hooded": "Rogue_Hooded_rogue_texture.png",
       "Knight": "Knight_knight_texture.png", "Barbarian": "Barbarian_barbarian_texture.png",
       "Mage": "Mage_mage_texture.png"}
LADO = 256


def lum(c):
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2] + 1e-3


def hexa(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def main():
    dados = json.loads((RAIZ / "data/pvp/herois.json").read_text(encoding="utf-8"))
    saida = PERS / "herois"
    saida.mkdir(exist_ok=True)
    for h in dados["herois"]:
        im = Image.open(PERS / TEX[h["base"]]).convert("RGB").resize((LADO, LADO), Image.BILINEAR)
        px = im.load()
        cw, ch = LADO // 8, LADO // 4
        for chave, cor in h["cores"].items():
            c, r = (int(x) for x in chave.split(","))
            alvo = hexa(cor)
            meio = px[c * cw + cw // 2, r * ch + ch // 2]
            base = lum(meio)
            for y in range(r * ch, (r + 1) * ch):
                for x in range(c * cw, (c + 1) * cw):
                    k = min(1.6, lum(px[x, y]) / base)
                    px[x, y] = tuple(max(0, min(255, int(v * k))) for v in alvo)
        im.save(saida / f"{h['id']}.png", optimize=True)
        print("ok", h["id"], h["base"])


if __name__ == "__main__":
    main()
