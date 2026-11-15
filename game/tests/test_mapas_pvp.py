"""Mapas do Valdora PvP (Desarmar, v0.1): confere as regras de equilíbrio e o JSON gravado.
Uso: python3 -I game/tests/test_mapas_pvp.py"""
import json
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(RAIZ / "tools" / "pvp"))
import mapas as M  # noqa: E402

falhas = []
total = 0


def caso(nome, cond, det=""):
    global total
    total += 1
    if not cond:
        falhas.append(f"{nome} {det}")
        print(f"  FALHOU {nome} {det}")


def main():
    caso("5 mapas", len(M.MAPAS) == 5, str(len(M.MAPAS)))
    caso("ids únicos", len({m["id"] for m in M.MAPAS}) == 5)
    gravado = json.loads((RAIZ / "game" / "data" / "pvp" / "mapas_v0.1.json").read_text(encoding="utf-8"))
    por_id = {m["id"]: m for m in gravado["mapas"]}
    for m in M.MAPAS:
        g = M.ler(m)
        caso(f"{m['id']}: grade 24 x 32", len(g) == 32 and all(len(l) == 24 for l in g))
        caso(f"{m['id']}: borda fechada", set(g[0]) == {"#"} and set(g[-1]) == {"#"} and all(l[0] == "#" and l[-1] == "#" for l in g))
        for ch in "TDAB123":
            caso(f"{m['id']}: tem '{ch}'", any(ch in l for l in g))
        r = M.analisar(m)
        prob = M.regras(r)
        caso(f"{m['id']}: regras de equilíbrio", not prob, str(prob))
        caso(f"{m['id']}: JSON igual à fonte", por_id.get(m["id"], {}).get("grade") == m["grade"])
        caso(f"{m['id']}: nomes de áreas", len(m["areas"]) >= 5)
        img = RAIZ / "game" / "docs" / "imagens" / "pvp" / "mapas" / f"mapa_{m['id']}.png"
        caso(f"{m['id']}: planta em PNG", img.exists())
    print(f"test_mapas_pvp: {total - len(falhas)}/{total}")
    return 1 if falhas else 0


if __name__ == "__main__":
    sys.exit(main())
