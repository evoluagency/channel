"""Catálogo: as 15 construções nas seis faixas, numa só imagem.
Uso: python3 tools/arte3d/catalogo.py SAIDA.png PASTA_PNG_1 [PASTA_PNG_2 ...]
Procura <construcao>_f<faixa>_azul_folha.png nas pastas dadas."""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ORDEM = [("prefeitura", "Prefeitura"), ("alojamento", "Alojamento"), ("estufa", "Estufa"),
         ("usina", "Usina"), ("mineradora", "Mineradora"), ("central_energia", "Central de energia"),
         ("radar", "Radar e antena"), ("base_militar", "Base militar"), ("entreposto", "Entreposto"),
         ("via", "Via"), ("parque", "Parque"), ("estacao_agua", "Estação de água"), ("heliponto", "Heliponto"),
         ("banco", "Banco da cidade"), ("centro_tecnologico", "Centro tecnológico")]
FAIXAS = ["Acampamento", "Pré-fabricado", "Concreto", "Vidro e aço", "Tecnológico", "Elite"]
FONTE = Path(__file__).with_name("fontes") / "Montserrat.ttf"
FUNDO, TINTA = (214, 232, 245), (20, 32, 56)


def fonte(t, peso=700):
    f = ImageFont.truetype(str(FONTE), t)
    try:
        f.set_variation_by_axes([peso])
    except Exception:
        pass
    return f


def achar(pastas, nome):
    for p in pastas:
        f = Path(p) / nome
        if f.exists():
            return f
    raise FileNotFoundError(nome)


def main():
    saida, pastas = sys.argv[1], sys.argv[2:]
    lado, rot, topo = 230, 200, 110
    img = Image.new("RGB", (rot + lado * 6, topo + lado * len(ORDEM)), FUNDO)
    d = ImageDraw.Draw(img)
    d.text((20, 18), "MUNDO — 15 construções × 6 faixas (níveis 1, 6, 11, 16, 21, 26)", font=fonte(34, 800), fill=TINTA)
    for j, n in enumerate(FAIXAS):
        d.text((rot + j * lado + 12, 74), f"{j + 1} · {n}", font=fonte(17, 700), fill=(70, 86, 110))
    for i, (c, nome) in enumerate(ORDEM):
        y = topo + i * lado
        if i % 2 == 0:
            d.rectangle((0, y, img.width, y + lado), fill=(205, 225, 240))
        d.text((14, y + lado // 2 - 12), nome, font=fonte(17, 800), fill=TINTA)
        for f in range(1, 7):
            im = Image.open(achar(pastas, f"{c}_f{f}_azul_folha.png")).convert("RGB")
            im = im.crop((90, 150, 810, 870)).resize((lado, lado))
            img.paste(im, (rot + (f - 1) * lado, y))
    img.save(saida, optimize=True)


if __name__ == "__main__":
    main()
