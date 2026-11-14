"""Cidade 3D (sessão 1.6, M8): confere as contagens gravadas pela medição e pelo smoke.

Fontes (geradas no Godot 4.7.2 oficial, GL Compatibility, ver tools/arte3d/LEIAME.md):
  game/docs/logs/cidade3d/contagens_construcoes.json   (smoke_cidade.gd)
  game/docs/logs/cidade3d/contagens_<cenario>*.json    (cidade.gd --medir)
Sem Godot: só lê os JSON. Uso: python3 -I game/tests/test_cidade3d.py
"""
import json
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
LOGS = RAIZ / "game" / "docs" / "logs" / "cidade3d"
DADOS = RAIZ / "game" / "data" / "mundo_componentes_v0.3.json"
ARTE = RAIZ / "tools" / "arte3d"

# Orçamento do M8 para a cidade cheia no nível 30 (com sombra, janela 540 x 1170).
MAX_CHAMADAS = 200
MAX_TRIANGULOS = 400_000
MAX_SUPERFICIES = 5

falhas = []
total = 0


def caso(nome, cond, detalhe=""):
    global total
    total += 1
    if not cond:
        falhas.append(f"{nome} {detalhe}")
        print(f"  FALHOU {nome} {detalhe}")


def ler(nome):
    return json.loads((LOGS / nome).read_text(encoding="utf-8"))


def receitas_cidade():
    """Lê o mapa id -> receita de cidade.gd."""
    txt = (ARTE / "cidade.gd").read_text(encoding="utf-8")
    bloco = txt.split("const RECEITAS := {", 1)[1].split("}", 1)[0]
    pares = {}
    for parte in bloco.replace("\n", " ").split(","):
        if ":" in parte:
            k, v = parte.split(":")
            pares[k.strip().strip('"')] = v.strip().strip('"')
    return pares


def main():
    dados = json.loads(DADOS.read_text(encoding="utf-8"))
    ids = [c["id"] for c in dados["construcoes"]]
    rec = receitas_cidade()

    # 1. receitas: as 15 do JSON v0.3, com arquivo, e Prefeitura no lugar do Quartel-general
    caso("15 construções no JSON v0.3", len(ids) == 15, str(len(ids)))
    caso("cidade cobre os 15 ids", sorted(rec) == sorted(ids), str(sorted(set(ids) ^ set(rec))))
    for i, r in rec.items():
        caso(f"receita {r}.gd existe", (ARTE / "construcoes" / f"{r}.gd").exists())
    caso("receita do Quartel-general renomeada", not (ARTE / "construcoes" / "quartel_general.gd").exists())
    pref = (ARTE / "construcoes" / "prefeitura.gd").read_text(encoding="utf-8")
    caso("letreiro da Prefeitura", '"PREFEITURA"' in pref and '"QG"' not in pref)
    img = RAIZ / "game" / "docs" / "imagens" / "componentes"
    for r in rec.values():
        caso(f"folha {r}", (img / f"{r}_folha_faixas.png").exists() and (img / f"{r}_faixa6_detalhe_aliancas.png").exists())
    caso("catálogo das 15", (img / "catalogo_15_construcoes.png").exists())

    # 2. fusão por construção e faixa
    cc = ler("contagens_construcoes.json")
    caso("90 combinações fundidas", len(cc) == 90, str(len(cc)))
    for chave, l in cc.items():
        caso(f"{chave} sem avisos", not l["avisos"], str(l["avisos"]))
        caso(f"{chave} superfícies <= {MAX_SUPERFICIES}", 1 <= l["superficies_lod0"] <= MAX_SUPERFICIES, str(l["superficies_lod0"]))
        caso(f"{chave} LOD1 <= LOD0", l["triangulos_lod1"] <= l["triangulos_lod0"])
        caso(f"{chave} modo cidade <= folha", l["triangulos_lod0"] <= l["triangulos_folha"])
    pecas = sum(l["pecas"] for l in cc.values())
    sup = sum(l["superficies_lod0"] for l in cc.values())
    caso("fusão corta as malhas em 20x ou mais", pecas >= 20 * sup, f"{pecas} peças -> {sup} superfícies")
    for nova in ("ban", "tec"):
        for f in range(1, 7):
            l = cc[f"{nova}|{f}"]
            caso(f"{nova} faixa {f} tem arte (não é provisória)", l["pecas"] >= 20, str(l["pecas"]))

    # 3. composição: o cenário n30 segue as regras do nível 30
    n30 = ler("contagens_n30.json")
    comp = n30["montagem"]["composicao"]
    prod_por_tipo = 2 + 30 // 10          # formulas.producao_por_tipo
    max_alo = 1 + 30 // 8                  # simular_economia.max_alo
    for p in ("est", "usi", "min", "ene"):
        caso(f"n30: {p} = {prod_por_tipo}", comp.get(p) == prod_por_tipo, str(comp.get(p)))
    caso(f"n30: alojamentos = {max_alo}", comp.get("alo") == max_alo, str(comp.get("alo")))
    for u in ("pref", "ban", "tec", "bas", "rad", "ent", "par", "agu", "hel"):
        caso(f"n30: {u} = 1", comp.get(u) == 1, str(comp.get(u)))
    caso("n30: 80 lotes", sum(comp.values()) == 80)
    cheia = ler("contagens_cheia.json")
    caso("cheia: 80 lotes ocupados", sum(cheia["montagem"]["composicao"].values()) == 80 and "vazio" not in cheia["montagem"]["composicao"])

    # 4. desempenho medido
    for nome in ("contagens_cheia.json", "contagens_n30.json", "contagens_misto.json"):
        m = ler(nome)
        caso(f"{nome}: sombra ligada e fusão", m["sombra"] and m["fusao"])
        caso(f"{nome}: janela retrato", m["janela"][1] > m["janela"][0])
        for z, v in m["zooms"].items():
            caso(f"{nome} {z}: chamadas <= {MAX_CHAMADAS}", 0 < v["chamadas_desenho"] <= MAX_CHAMADAS, str(v["chamadas_desenho"]))
            caso(f"{nome} {z}: triângulos <= {MAX_TRIANGULOS}", 0 < v["triangulos"] <= MAX_TRIANGULOS, str(v["triangulos"]))
        caso(f"{nome}: LOD 0 de perto e 1 de longe", m["zooms"]["perto"]["lod"] == 0 and m["zooms"]["longe"]["lod"] == 1)
    sf = ler("contagens_cheia_sem_fusao.json")
    for z in ("perto", "padrao", "medio", "longe"):
        a, b = sf["zooms"][z]["chamadas_desenho"], cheia["zooms"][z]["chamadas_desenho"]
        caso(f"fusão corta chamadas em 10x ou mais ({z})", a >= 10 * b, f"{a} -> {b}")
    ss = ler("contagens_cheia_sem_sombra.json")
    caso("sem sombra gasta menos", ss["zooms"]["padrao"]["chamadas_desenho"] < cheia["zooms"]["padrao"]["chamadas_desenho"])

    print(f"test_cidade3d: {total - len(falhas)}/{total}")
    return 1 if falhas else 0


if __name__ == "__main__":
    sys.exit(main())
