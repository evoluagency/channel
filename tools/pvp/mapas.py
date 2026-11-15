"""Mapas do Valdora PvP, modo Desarmar (sessão 1.6, v0.1): planta, rotas e tempos.

Cada mapa é uma grade de texto (24 colunas x 32 linhas, célula de 3 m: 72 x 96 m).
Embaixo fica a base 1 (ataque); em cima, a base 2 (defesa), como na planta de referência do dono.

  #  parede        c  cobertura (caixa, mureta, carro; bloqueia a passagem)
  .  chão          1 2 3  portas das três rotas (esquerda, meio, direita); contam como chão
  T  base 1 (ataque)      D  base 2 (defesa)
  A  ponto A (plantio)    B  ponto B (plantio)

Regras conferidas (e no teste game/tests/test_mapas_pvp.py):
  - as três portas são o único caminho entre as metades do mapa, e cada uma sozinha basta;
  - ataque chega a cada ponto entre 12 e 26 s; defesa entre 3 e 11 s; defesa chega ao menos 5 s antes;
  - os pontos A e B ficam a pelo menos 30 m um do outro;
  - a defesa troca de ponto (A <-> B) em até 16 s.
Velocidade de corrida: 5 m/s. Caminho mais curto em 8 direções, sem cortar quina.

Uso: python3 -I tools/pvp/mapas.py [PASTA_IMAGENS]
  grava game/data/pvp/mapas_v0.1.json e, se houver Pillow, as plantas em PNG.
"""
import heapq
import json
import math
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
CELULA = 3.0
VELOCIDADE = 5.0

MAPAS = [
    {
        "id": "esplanada", "nome": "Esplanada", "cidade": "Brasília",
        "tema": "praça cívica com galeria coberta, pátio central e jardim",
        "areas": [["Galeria", 1, 16], ["Pátio", 11, 16], ["Jardim", 21, 16], ["Rampa", 11, 7],
                  ["Espelho d'água", 11, 24], ["Colunata", 3, 6], ["Pérgola", 19, 6]],
        "grade": [
            "########################",
            "#########DDDDDD#########",
            "#.......#DDDDDD#.......#",
            "#.AAAA..#......#..BBBB.#",
            "#.AAAA..........c.BBBB.#",
            "#.AAAA.c...cc.....BBBB.#",
            "#.......####..####.....#",
            "##..##..####..####..##.#",
            "#...##.........c....##.#",
            "#...#..c..####......#..#",
            "#...#.....####...c..#..#",
            "#..##...............##.#",
            "#..##.c..........c..##.#",
            "#..#######.....######..#",
            "#..#######22222#######.#",
            "#11#######.....#####333#",
            "#..##.....c........##..#",
            "#..##......####....##..#",
            "#..#...c...####..c..#..#",
            "#..#.......####.....#..#",
            "#..#..##........##..#..#",
            "#..#..##...cc...##..#..#",
            "#..#...........c....#..#",
            "#..######..........###.#",
            "#.......####...####....#",
            "#...c...####...####..c.#",
            "#......................#",
            "#........c....c........#",
            "##.......TTTTTT.......##",
            "###......TTTTTT......###",
            "######...........#######",
            "########################",
        ],
    },
    {
        "id": "porto", "nome": "Porto", "cidade": "Rio de Janeiro",
        "tema": "armazéns, pátio de contêineres e cais aberto junto à água",
        "areas": [["Armazém", 1, 10], ["Contêineres", 10, 18], ["Cais", 20, 18], ["Guindaste", 13, 9],
                  ["Doca", 20, 4], ["Escritório", 3, 21]],
        "grade": [
            "########################",
            "#######DDDDDD###########",
            "#......DDDDDD......#####",
            "#.....##########...#####",
            "#....c....c.##..c...####",
            "#...........##.........#",
            "#......c....##...BBBBB.#",
            "###..####......cBBBBB..#",
            "#AAAA####.......BBBBB..#",
            "#AAAA####..c.c..BBBBB..#",
            "#AAAA####.......####.c.#",
            "#AAAA......c....####...#",
            "#...........c...####...#",
            "#..######.....#######..#",
            "#11######22222#######33#",
            "#..######.....#######..#",
            "#..##..c....c...##.....#",
            "#..##.cc..c..cc.##.....#",
            "#..##...........##..c..#",
            "#..#..cc..cc..cc.#.....#",
            "#..#.............#..c..#",
            "#..#..c..####..c.#.....#",
            "#..#.............#.....#",
            "#..######....#####..c..#",
            "#.........c............#",
            "#...c...............c..#",
            "#......................#",
            "#.....c.........c......#",
            "##.......TTTTTT.......##",
            "###......TTTTTT......###",
            "######...........#######",
            "########################",
        ],
    },
    {
        "id": "ladeira", "nome": "Ladeira", "cidade": "Salvador",
        "tema": "igreja no alto, casario colorido, escadaria e becos em diagonal",
        "areas": [["Ladeira", 1, 18], ["Escadaria", 11, 18], ["Beco", 21, 18], ["Igreja", 18, 8],
                  ["Mercado", 2, 11], ["Mirante", 21, 2]],
        "grade": [
            "########################",
            "#########DDDDDD#########",
            "#........DDDDDD........#",
            "#..............####....#",
            "#..........c....####...#",
            "#......................#",
            "#BBBB..####......AAAAAA#",
            "#BBBB..####......AAAAAA#",
            "#BBBB..####......AAAAAA#",
            "#BBBB....c...###..c....#",
            "####......c..###.......#",
            "#..#......c..###..###..#",
            "#..............c..###..#",
            "#..#######.....######..#",
            "#11#######22222######33#",
            "#..#######.....######..#",
            "#..###.....c.....###...#",
            "#...##..........###....#",
            "#.c..##...cc...###..c..#",
            "#.....##.......##......#",
            "##.....##..c..##....####",
            "###.....#.....#........#",
            "####....c.........c....#",
            "#####..............##..#",
            "#......c.....####......#",
            "#.............####..c..#",
            "#...c..................#",
            "#......................#",
            "##.......TTTTTT.......##",
            "###......TTTTTT......###",
            "######...........#######",
            "########################",
        ],
    },
    {
        "id": "estacao", "nome": "Estação", "cidade": "São Paulo",
        "tema": "estação de trem com plataformas, bilheteria e passarelas",
        "areas": [["Bilheteria", 3, 1], ["Plataforma", 19, 1], ["Trilhos", 11, 7], ["Túnel", 1, 18],
                  ["Hall", 11, 20], ["Passarela", 21, 18]],
        "grade": [
            "########################",
            "#########DDDDDD#########",
            "#BBBBB..#DDDDDD#..AAAA.#",
            "#BBBBB..#......#..AAAA.#",
            "#BBBBB............AAAA.#",
            "#.......c....c.........#",
            "#..########..#######...#",
            "#......................#",
            "#..c.....c.....c.....c.#",
            "#...######....######...#",
            "#.....c............c...#",
            "#...........##.........#",
            "#..c........##......c..#",
            "#..#######.....######..#",
            "#11#######22222######33#",
            "#..#######.....######..#",
            "#..#...c........c...#..#",
            "#..#..####....####..#..#",
            "#..#................#..#",
            "#..#..c..######..c..#..#",
            "#..#.....######.....#..#",
            "#..#..c..........c..#..#",
            "#..#....####..####..#..#",
            "#..................c...#",
            "#....c.......c.........#",
            "#...c...............c..#",
            "#......................#",
            "#........c....c........#",
            "##.......TTTTTT.......##",
            "###......TTTTTT......###",
            "######...........#######",
            "########################",
        ],
    },
    {
        "id": "represa", "nome": "Represa", "cidade": "Pará",
        "tema": "usina hidrelétrica, rio no meio com três pontes e vila de ribeirinhos",
        "areas": [["Ponte velha", 4, 14], ["Ponte da usina", 13, 14], ["Ponte da vila", 20, 14],
                  ["Turbinas", 3, 7], ["Vila", 18, 12], ["Serraria", 4, 20]],
        "grade": [
            "########################",
            "##############DDDDDD####",
            "#.............DDDDDD...#",
            "#.AAAAA.........c......#",
            "#.AAAAA...####.........#",
            "#.AAAAA...####...####..#",
            "#......c..####...####..#",
            "#..##..........c.......#",
            "#..##.....c.........c..#",
            "#.......####....BBBBB..#",
            "#..c....####..c.BBBBB..#",
            "#...............BBBBB..#",
            "#.....c.......c........#",
            "###11#######22#####33###",
            "###11#######22#####33###",
            "###11#######22#####33###",
            "#......................#",
            "#..c....##.....##...c..#",
            "#.......##..c..##......#",
            "#..###.........c...###.#",
            "#..###..c..##......###.#",
            "#..........##...c......#",
            "#.....c..........c.....#",
            "#..####....c....####...#",
            "#..####.........####...#",
            "#......c.....c.........#",
            "#......................#",
            "#........c....c........#",
            "##.......TTTTTT.......##",
            "###......TTTTTT......###",
            "######...........#######",
            "########################",
        ],
    },
]


def ler(m):
    g = m["grade"]
    assert len(g) == 32, (m["id"], len(g))
    for i, linha in enumerate(g):
        assert len(linha) == 24, (m["id"], i, len(linha), linha)
    return g


def livre(c):
    return c not in "#c"


def celulas(g, ch):
    return [(x, y) for y, linha in enumerate(g) for x, c in enumerate(linha) if c in ch]


def centro(cs):
    return (sum(x for x, _ in cs) / len(cs), sum(y for _, y in cs) / len(cs))


def dijkstra(g, origens, bloqueios=()):
    h, w = len(g), len(g[0])
    dist = {}
    fila = []
    for o in origens:
        dist[o] = 0.0
        fila.append((0.0, o))
    heapq.heapify(fila)
    pai = {}
    while fila:
        d, (x, y) = heapq.heappop(fila)
        if d > dist.get((x, y), 1e9):
            continue
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                if dx == 0 and dy == 0:
                    continue
                nx, ny = x + dx, y + dy
                if not (0 <= nx < w and 0 <= ny < h):
                    continue
                c = g[ny][nx]
                if not livre(c) or c in bloqueios:
                    continue
                if dx and dy and (not livre(g[y][nx]) or not livre(g[ny][x]) or g[y][nx] in bloqueios or g[ny][x] in bloqueios):
                    continue  # sem cortar quina
                nd = d + (math.sqrt(2) if dx and dy else 1.0)
                if nd < dist.get((nx, ny), 1e9):
                    dist[(nx, ny)] = nd
                    pai[(nx, ny)] = (x, y)
                    heapq.heappush(fila, (nd, (nx, ny)))
    return dist, pai


def caminho(pai, fim):
    c = [fim]
    while c[-1] in pai:
        c.append(pai[c[-1]])
    return c[::-1]


def tempo(dist, alvo):
    """Segundos até a célula mais próxima do conjunto alvo."""
    d = min(dist.get(c, 1e9) for c in alvo)
    return d * CELULA / VELOCIDADE, min(alvo, key=lambda c: dist.get(c, 1e9))


def analisar(m):
    g = ler(m)
    T, D = celulas(g, "T"), celulas(g, "D")
    A, B = celulas(g, "A"), celulas(g, "B")
    r = {"id": m["id"]}
    dt, pt = dijkstra(g, T)
    dd, pd = dijkstra(g, D)
    r["ataque_A_s"], fa = tempo(dt, A)
    r["ataque_B_s"], fb = tempo(dt, B)
    r["defesa_A_s"], _ = tempo(dd, A)
    r["defesa_B_s"], _ = tempo(dd, B)
    da, _ = dijkstra(g, A)
    r["rotacao_AB_s"], _ = tempo(da, B)
    ca, cb = centro(A), centro(B)
    r["distancia_AB_m"] = math.dist(ca, cb) * CELULA
    r["rotas"] = {}
    for k, nome in (("1", "esquerda"), ("2", "meio"), ("3", "direita")):
        outras = "123".replace(k, "")
        d, _ = dijkstra(g, T, bloqueios=outras)
        r["rotas"][nome] = min(d.get(c, 1e9) for c in D) < 1e9
    d0, _ = dijkstra(g, T, bloqueios="123")
    r["corte_pelas_portas"] = min(d0.get(c, 1e9) for c in D) >= 1e9
    r["caminho_A"] = caminho(pt, fa)
    r["caminho_B"] = caminho(pt, fb)
    return r


def regras(r):
    """Lista de problemas (vazia = mapa dentro das regras)."""
    p = []
    for s in "AB":
        a, d = r[f"ataque_{s}_s"], r[f"defesa_{s}_s"]
        if not 12 <= a <= 26:
            p.append(f"ataque até {s} em {a:.1f} s (12 a 26)")
        if not 3 <= d <= 11:
            p.append(f"defesa até {s} em {d:.1f} s (3 a 11)")
        if a - d < 5:
            p.append(f"defesa chega a {s} só {a - d:.1f} s antes (mínimo 5)")
    if r["distancia_AB_m"] < 30:
        p.append(f"A e B a {r['distancia_AB_m']:.0f} m (mínimo 30)")
    if r["rotacao_AB_s"] > 16:
        p.append(f"rotação A-B em {r['rotacao_AB_s']:.1f} s (máximo 16)")
    for k, ok in r["rotas"].items():
        if not ok:
            p.append(f"rota da {k} não liga as bases")
    if not r["corte_pelas_portas"]:
        p.append("há caminho entre as metades fora das três portas")
    return p


# ---------------------------------------------------------------- planta em PNG

def desenhar(m, r, arquivo, escala=30):
    from PIL import Image, ImageDraw, ImageFont
    g = m["grade"]
    w, h = len(g[0]) * escala, len(g) * escala
    topo = 70
    im = Image.new("RGB", (w + 40, h + topo + 20), (12, 12, 12))
    d = ImageDraw.Draw(im, "RGBA")
    fonte = RAIZ / "game" / "assets" / "fontes" / "Montserrat.ttf"

    def f(t, peso=700):
        ft = ImageFont.truetype(str(fonte), t)
        try:
            ft.set_variation_by_axes([peso])
        except Exception:
            pass
        return ft

    ox, oy = 20, topo
    d.text((20, 14), f"{m['nome']} · {m['cidade']}", font=f(28, 800), fill=(240, 240, 240))
    d.text((20, 46), m["tema"], font=f(14, 500), fill=(160, 160, 160))
    cores = {"#": (58, 58, 58), "c": (165, 165, 165), "T": (28, 44, 32), "D": (46, 33, 26),
             "A": (64, 36, 36), "B": (36, 44, 70)}
    d.rounded_rectangle((ox - 6, oy - 6, ox + w + 6, oy + h + 6), 10, fill=(14, 14, 14), outline=(44, 44, 44), width=2)
    for y, linha in enumerate(g):
        for x, c in enumerate(linha):
            if c in cores:
                x0, y0 = ox + x * escala, oy + y * escala
                pad = 4 if c == "c" else 0
                d.rectangle((x0 + pad, y0 + pad, x0 + escala - 1 - pad, y0 + escala - 1 - pad), fill=cores[c])
    # portas das rotas (linha tracejada)
    for k in "123":
        for x, y in celulas(g, k):
            x0, y0 = ox + x * escala, oy + y * escala
            for i in range(0, escala, 6):
                d.line((x0 + i, y0 + escala // 2, x0 + i + 3, y0 + escala // 2), fill=(170, 170, 170), width=2)
    # rotas de ataque mais curtas até A e B
    for nome, cor in (("caminho_A", (240, 120, 110)), ("caminho_B", (120, 180, 255))):
        pts = [(ox + (x + 0.5) * escala, oy + (y + 0.5) * escala) for x, y in r[nome]]
        d.line(pts, fill=cor + (230,), width=5, joint="curve")
    # rótulos
    for s, letra, cor in (("T", "Base 1 · ataque", (230, 240, 230)), ("D", "Base 2 · defesa", (245, 230, 220))):
        cx, cy = centro(celulas(g, s))
        t = f(17, 700)
        tw = d.textlength(letra, font=t)
        d.text((ox + (cx + 0.5) * escala - tw / 2, oy + (cy + 0.5) * escala - 11), letra, font=t, fill=cor)
    for s, cor in (("A", (255, 150, 140)), ("B", (150, 190, 255))):
        cx, cy = centro(celulas(g, s))
        t = f(54, 900)
        d.text((ox + (cx + 0.5) * escala - 18, oy + (cy + 0.5) * escala - 34), s, font=t, fill=cor)
    for nome, x, y in m["areas"]:
        t = f(15, 700)
        tw = d.textlength(nome, font=t)
        cx, cy = ox + (x + 0.5) * escala, oy + (y + 0.5) * escala
        d.rounded_rectangle((cx - tw / 2 - 12, cy - 15, cx + tw / 2 + 12, cy + 15), 15, fill=(40, 40, 40, 235), outline=(80, 80, 80))
        d.text((cx - tw / 2, cy - 10), nome, font=t, fill=(225, 225, 225))
    rod = (f"Ataque: A {r['ataque_A_s']:.0f} s · B {r['ataque_B_s']:.0f} s   Defesa: A {r['defesa_A_s']:.0f} s · "
           f"B {r['defesa_B_s']:.0f} s   Rotação A-B {r['rotacao_AB_s']:.0f} s   (72 x 96 m)")
    im2 = Image.new("RGB", (im.width, im.height + 36), (12, 12, 12))
    im2.paste(im, (0, 0))
    ImageDraw.Draw(im2).text((20, im.height + 4), rod, font=f(15, 600), fill=(190, 190, 190))
    im2.save(arquivo, optimize=True)


def main():
    pasta = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    saida = []
    ok = True
    for m in MAPAS:
        r = analisar(m)
        prob = regras(r)
        ok &= not prob
        print(f"{m['id']:10s} ataque A {r['ataque_A_s']:5.1f} B {r['ataque_B_s']:5.1f} | defesa A {r['defesa_A_s']:5.1f} "
              f"B {r['defesa_B_s']:5.1f} | rotação {r['rotacao_AB_s']:5.1f} | A-B {r['distancia_AB_m']:4.0f} m | "
              f"rotas {r['rotas']} corte {r['corte_pelas_portas']} | {'OK' if not prob else prob}")
        saida.append({k: v for k, v in m.items()} | {
            "celula_m": CELULA, "velocidade_ms": VELOCIDADE,
            "medidas": {k: (round(v, 1) if isinstance(v, float) else v) for k, v in r.items() if not k.startswith("caminho")}})
        if pasta:
            pasta.mkdir(parents=True, exist_ok=True)
            desenhar(m, r, pasta / f"mapa_{m['id']}.png")
    dados = {"schema": "valdora.pvp.mapas.v0.1", "modo": "desarmar",
             "legenda": {"#": "parede", "c": "cobertura", ".": "chão", "1": "porta da rota esquerda",
                         "2": "porta da rota do meio", "3": "porta da rota direita", "T": "base 1 (ataque)",
                         "D": "base 2 (defesa)", "A": "ponto A", "B": "ponto B"},
             "mapas": saida}
    arq = RAIZ / "game" / "data" / "pvp" / "mapas_v0.1.json"
    arq.parent.mkdir(parents=True, exist_ok=True)
    arq.write_text(json.dumps(dados, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
