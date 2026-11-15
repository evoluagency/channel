"""Regressão estrutural da direção de arte piloto da Esplanada.
Não usa GitHub Actions, não publica APK e não afirma equivalência visual com Last War.
Execução local: python3 -I game/tests/test_pvp_esplanada_visual.py
"""
from pathlib import Path
import json

root = Path(__file__).resolve().parents[1]
art = (root / "scripts/pvp/visual/esplanada_acabamento.gd").read_text(encoding="utf-8")
scene = (root / "scripts/pvp/visual/cenario.gd").read_text(encoding="utf-8")
arena = (root / "scripts/pvp/pvp_arena.gd").read_text(encoding="utf-8")
mapas = json.loads((root / "data/pvp/mapas_v0.1.json").read_text(encoding="utf-8"))
ids = {m["id"] for m in mapas["mapas"]}

checks = {
    "cinco mapas e Esplanada preservados": len(ids) == 5 and "esplanada" in ids,
    "camada exclusiva da Esplanada": 'if a.mapa.get("id", "") == "esplanada":' in scene,
    "carregamento único da camada": scene.count("ACABAMENTO_ESPLANADA.new()") == 1,
    "fachadas integradas": "acabamento.fachada(centro, sx, sz, alt, faces, borda)" in scene,
    "piso, mobiliário e entorno": all(
        f"acabamento.{name}()" in scene for name in ("pisos", "mobiliario", "entorno")
    ),
    "geometria de parede preservada": all(
        token in arena for token in ("_paredes()", "_coberturas()", "_cerca()")
    ),
    "nunca cria colisores": not any(token in art for token in (
        "CollisionShape3D.new", "StaticBody3D.new", "CollisionPolygon3D.new",
        "GridMap.new", "create_trimesh_collision", "create_convex_collision",
    )),
    "piso somente onde é livre": 'arena.letra(x, y) != "."' in art,
    "quiosques e floreiras só em cobertura": 'arena.letra(x, y) != "c"' in art,
    "pontos de bomba preservados": 'if arena.letra(x, y) != ".":' in art,
    "fachadas só em paredes": "if borda or sx * sz < 12.0:" in art,
    "qualidade escalável": 'match str(video.qualidade):' in art,
    "materiais agrupados": all(
        f'c.{method}(' in art for method in ("sup", "liso", "agua")
    ),
    "originalidade": "arte" in art.lower() or "original" in art.lower(),
    "sem downloads ou rede": not any(x in art for x in (
        "HTTPRequest", "HTTPClient", "OS.shell_open", "FileAccess.open",
    )),
}
for name, ok in checks.items():
    print(f"{'PASS' if ok else 'FAIL'} {name}")
print(f"ESPLANADA_VISUAL {sum(checks.values())}/{len(checks)}")
raise SystemExit(0 if all(checks.values()) else 1)
