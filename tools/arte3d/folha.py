"""Monta as folhas de uma construção a partir dos PNG do render.gd.
Uso: python3 tools/arte3d/folha.py PASTA_PNG construcao "Nome" SAIDA_DIR
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

FAIXAS = [(1, "1 a 5", "Acampamento"), (2, "6 a 10", "Pré-fabricado"), (3, "11 a 15", "Concreto"),
          (4, "16 a 20", "Vidro e aço"), (5, "21 a 25", "Tecnológico"), (6, "26 a 30", "Elite")]
ALIANCAS = ["azul", "vermelha", "verde", "roxa", "amarela"]
FONTE = Path(__file__).with_name("fontes") / "Montserrat.ttf"
FUNDO = (214, 232, 245)
TINTA = (20, 32, 56)


def fonte(t, peso=700):
    f = ImageFont.truetype(str(FONTE), t)
    try:
        f.set_variation_by_axes([peso])
    except Exception:
        pass
    return f


def main():
    pasta, cons, nome, saida = Path(sys.argv[1]), sys.argv[2], sys.argv[3], Path(sys.argv[4])
    saida.mkdir(parents=True, exist_ok=True)
    # folha das seis faixas (mesma escala em todas)
    lado, topo = 560, 120
    folha = Image.new("RGB", (lado * 3, topo + lado * 2 + 20), FUNDO)
    d = ImageDraw.Draw(folha)
    d.text((30, 26), f"{nome} — seis faixas visuais", font=fonte(44, 800), fill=TINTA)
    d.text((30, 80), "Mesma escala em todas as faixas · render real no Godot 4.7.2 (GL Compatibility) · aliança azul", font=fonte(20, 500), fill=(70, 86, 110))
    for i, (f, niveis, rot) in enumerate(FAIXAS):
        im = Image.open(pasta / f"{cons}_f{f}_azul_folha.png").convert("RGB").crop((60, 10, 840, 810)).resize((lado, int(lado * 800 / 780)))
        x, y = (i % 3) * lado, topo + (i // 3) * lado
        folha.paste(im.crop((0, 0, lado, lado)), (x, y))
        l1, l2 = f"Faixa {f}", f"{rot} · nív. {niveis}"
        w = max(d.textlength(l1, font=fonte(22, 800)), d.textlength(l2, font=fonte(16, 600))) + 28
        d.rounded_rectangle((x + 12, y + 10, x + 12 + w, y + 68), 14, fill=(255, 255, 255))
        d.text((x + 26, y + 14), l1, font=fonte(22, 800), fill=TINTA)
        d.text((x + 26, y + 42), l2, font=fonte(16, 600), fill=(70, 86, 110))
    folha.save(saida / f"{cons}_folha_faixas.png", optimize=True)

    # detalhe da faixa 6 com as variações de aliança
    det = Image.open(pasta / f"{cons}_f6_azul_detalhe.png").convert("RGB")
    W = det.width + 520
    out = Image.new("RGB", (W, det.height), FUNDO)
    out.paste(det, (0, 0))
    d = ImageDraw.Draw(out)
    d.text((det.width + 20, 30), "Faixa 6 em detalhe", font=fonte(36, 800), fill=TINTA)
    d.text((det.width + 20, 78), "Cores de aliança (faixas 3 e 6)", font=fonte(22, 600), fill=(70, 86, 110))
    # grade simples: duas colunas (faixa 3 | faixa 6), cinco linhas
    tam = 245
    alt = int(tam * 0.9)
    for j, f in enumerate([3, 6]):
        d.text((det.width + 20 + j * (tam + 10) + 8, 120), f"Faixa {f}", font=fonte(20, 700), fill=TINTA)
        for i, a in enumerate(ALIANCAS):
            im = Image.open(pasta / f"{cons}_f{f}_{a}_alianca.png").convert("RGB").crop((100, 140, 800, 840)).resize((tam, tam)).crop((0, 0, tam, alt))
            x = det.width + 20 + j * (tam + 10)
            y = 150 + i * (alt + 8)
            out.paste(im, (x, y))
            d.text((x + 8, y + 6), a, font=fonte(16, 700), fill=TINTA)
    out.save(saida / f"{cons}_faixa6_detalhe_aliancas.png", optimize=True)


if __name__ == "__main__":
    main()
