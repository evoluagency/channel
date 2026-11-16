"""Regressão estática da direção de arte da sessão 1.7 (arte conceitual do dono).

Confere, sem Godot, que a luz dourada, o céu, o kit de ornamentos e a praça 3D dos menus
continuam ligados e que nada disso cria colisão nova.
Uso: python3 -I game/tests/test_pvp_arte_conceitual.py
"""
import pathlib
import re
import sys

RAIZ = pathlib.Path(__file__).resolve().parents[2]
VIS = RAIZ / "game/scripts/pvp/visual"
falhas = []


def ok(cond, msg):
    print(("  ok    " if cond else "  FALHA ") + msg)
    if not cond:
        falhas.append(msg)


def ler(p):
    return (RAIZ / p).read_text(encoding="utf-8") if (RAIZ / p).exists() else ""


cen = ler("game/scripts/pvp/visual/cenario.gd")
orn = ler("game/scripts/pvp/visual/ornamentos.gd")
ceu = ler("game/scripts/pvp/visual/ceu.gdshader")
praca = ler("game/scripts/pvp/visual/praca_valdora.gd")
fundo = ler("game/scripts/ui/pvp/pvp_fundo.gd")
sup = ler("game/scripts/pvp/visual/superficie.gdshader")
checar = ler("tools/godot_checar_scripts.sh")

# luz e cor
ok("shader_type sky" in ceu and "nuvens" in ceu, "céu estilizado com nuvens")
ok('preload("res://scripts/pvp/visual/ceu.gdshader")' in cen, "arenas usam o céu estilizado")
ok("AMBIENT_SOURCE_COLOR" in cen, "ambiente por cor (sombra quente, não azul do céu)")
ok("TONE_MAPPER_FILMIC" in cen and "glow_enabled = true" in cen, "tonemap filmic e brilho leve")
ok("fog_enabled = true" in cen, "neblina de profundidade")
ok("RIM =" in sup, "contorno de luz de desenho animado no shader")
for mapa in ["esplanada", "porto", "ladeira", "estacao", "represa"]:
    bloco = re.search(r'"%s": \{(.*?)\n\t\},' % mapa, cen, re.S)
    ok(bloco is not None and '"ambiente"' in bloco.group(1) and '"nuvens"' in bloco.group(1), f"tema {mapa}: ambiente e nuvens")

# ornamentos: só malha visual
for nome in ["arcada", "cupula", "estandarte", "floreira", "trepadeira", "arvore", "lampiao", "flores"]:
    ok(f"func {nome}(" in orn, f"ornamento {nome}")
for proibido in ["CollisionShape3D", "StaticBody3D", "PhysicsBody", "add_child"]:
    ok(proibido not in orn, f"ornamentos sem {proibido}")
ok("orn.preparar(" in cen and "_ornar(" in cen, "cenário usa o kit nos cinco mapas")
for marco in ["_cristo(", "_theatro(", "_elevador_lacerda(", "_ver_o_peso("]:
    ok(marco in cen, f"marco regional {marco[1:-1]}")

# menus com praça 3D
ok("SubViewport" in fundo and "praca_valdora.gd" in fundo, "fundo dos menus é a praça 3D")
ok("UPDATE_DISABLED" in fundo, "praça para de renderizar quando o fundo some")
ok("cupula(" in praca and "estandarte(" in praca and "arcada(" in praca, "praça com cúpula, estandartes e arcada")
ok("CollisionShape3D" not in praca, "praça sem colisão")

# verificador de sintaxe não pode dar falso 0 erros
ok("exit 2" in checar and "não encontrado" in checar, "godot_checar_scripts.sh falha sem o binário")

print(f"ARTE_CONCEITUAL {'PASSOU' if not falhas else 'FALHOU'} ({len(falhas)} falhas)")
sys.exit(1 if falhas else 0)
