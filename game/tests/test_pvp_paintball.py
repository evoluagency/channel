"""Regressão estática do PvP da sessão 1.8 (paintball, heróis KayKit, interface da arte).
Executar: python3 -I game/tests/test_pvp_paintball.py
Confere arquivos, dados e contratos sem Godot; o comportamento é provado pelos smokes
pvp_arena_smoke.gd (tinta, bots, pistola, granada) e pvp_menu_smoke.gd (telas).
"""
import json
from pathlib import Path

G = Path(__file__).resolve().parents[1]
falhas = []


def ok(c, m):
    print(("ok    " if c else "FALHOU ") + m)
    if not c:
        falhas.append(m)


def ler(p):
    return (G / p).read_text(encoding="utf-8")


# heróis
herois = json.loads(ler("data/pvp/herois.json"))["herois"]
ok(len(herois) == 11 and len({h["id"] for h in herois}) == 11, "11 heróis com id único")
nilo = [h for h in herois if h["id"] == "nilo"]
ok(bool(nilo) and nilo[0]["origem"] == "Brasil", "Nilo é o herói do Brasil (decisão do dono)")
for h in herois:
    ok((G / f"assets/pvp/personagens/herois/{h['id']}.png").exists(), f"textura de {h['id']}")
    ok((G / f"assets/pvp/personagens/{h['base']}.glb").exists(), f"corpo {h['base']} de {h['id']}")
# KayKit: licença CC0 conferida e GLB podados
lic = ler("assets/pvp/personagens/LICENSE_KayKit_Adventurers.txt")
ok("Creative Commons Zero, CC0" in lic, "licença CC0 do KayKit versionada")
for glb in (G / "assets/pvp/personagens").glob("*.glb"):
    ok(glb.stat().st_size < 1_200_000, f"{glb.name} podado ({glb.stat().st_size // 1024} KB)")
# aparências
aps = json.loads(ler("data/pvp/aparencias.json"))["aparencias"]
ok(len(aps) == 30 and len({a["id"] for a in aps}) == 30, "30 aparências do marcador")
shader = ler("scripts/pvp/visual/pintura_marcador.gdshader")
for t in sorted({a["tipo"] for a in aps} - {0}):
    ok(f"tipo == {t})" in shader, f"shader trata o padrão {t}")
for e in sorted({a.get("emblema", 0) for a in aps} - {0}):
    ok(f"emblema == {e})" in shader, f"shader trata o emblema {e}")
# tinta
tinta = ler("scripts/pvp/pvp_tinta.gd")
ok("MultiMeshInstance3D" in tinta and "MAX_RESPINGOS" in tinta, "bolas e respingos em MultiMesh")
ok("func granada(" in tinta and "func explodir(" in tinta, "granada de tinta")
ok("INSTANCE_CUSTOM" in ler("scripts/pvp/visual/tinta_respingo.gdshader"), "cor do respingo por INSTANCE_CUSTOM (GL Compatibility)")
jog = ler("scripts/pvp/pvp_jogador.gd")
ok("arena.tinta.disparar(" in jog and "_animar_arma(" in jog, "jogador dispara tinta e anima o marcador")
ok('"Pistola"' in jog and '"Granada"' in jog, "três armas no jogador")
# bots e arena
arena = ler("scripts/pvp/pvp_arena.gd")
ok("func caminho(" in arena and "for i in 9:" in arena, "arena com 9 bots e caminho pela grade")
ok("collision_layer = 2" in ler("scripts/pvp/pvp_bot.gd"), "bots na camada 2 (o smoke de colisão da grade usa a 1)")
# interface
hud = ler("scripts/pvp/pvp_hud.gd")
ok("RETRATOS" in hud and "CONFRONTO 5 × 5" in hud and "_rotulo_escudo" in hud, "HUD com retratos, modo e escudo")
menu = ler("scripts/ui/pvp/pvp_menu.gd")
ok(all(x in menu for x in ['["inicio", "base", "Base"]', '["herois", "herois", "Heróis"]', '["arsenal", "arsenal", "Arsenal"]', '["modos", "missoes", "Missões"]']), "barra BASE, HERÓIS, ARSENAL, MISSÕES")
ok("VITRINE.new()" in menu and "_salvar_perfil()" in menu, "vitrine 3D e perfil salvo")
ok("TorusMesh" in ler("scripts/ui/pvp/pvp_vitrine.gd"), "pedestal com anel aceso")
# nada de nomes de outros jogos nos dados novos
proibidos = ["fortnite", "valorant", "free fire", "pubg", "overwatch", "splatoon", "call of duty"]
texto = (ler("data/pvp/herois.json") + ler("data/pvp/aparencias.json")).lower()
ok(not any(p in texto for p in proibidos), "sem nomes de outros jogos")

print("TEST_PVP_PAINTBALL", "PASSOU" if not falhas else f"FALHOU ({len(falhas)})")
raise SystemExit(1 if falhas else 0)
