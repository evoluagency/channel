"""Regressão estática dos ajustes visuais PvP, sem GitHub Actions e sem APK.
Executar: python3 -I game/tests/test_pvp_visual_quality.py
Não substitui capturas visuais, análise de FPS nem ensaio Android real.
"""
from pathlib import Path

GAME = Path(__file__).resolve().parents[1]
project = (GAME / "project.godot").read_text(encoding="utf-8")
menu = (GAME / "scripts/ui/pvp/pvp_menu.gd").read_text(encoding="utf-8")
video = (GAME / "scripts/pvp/visual/qualidade_video.gd").read_text(encoding="utf-8")
cenario = (GAME / "scripts/pvp/visual/cenario.gd").read_text(encoding="utf-8")
shader = (GAME / "scripts/pvp/visual/superficie.gdshader").read_text(encoding="utf-8")
arena = (GAME / "scripts/pvp/pvp_arena.gd").read_text(encoding="utf-8")

checks = {
    "GL Compatibility mantido": 'rendering_method.mobile="gl_compatibility"' in project,
    "3D nativo e UI expansível": all(x in project for x in [
        'window/stretch/mode="canvas_items"',
        'window/stretch/aspect="expand"',
        'scaling_3d/scale=1.0',
    ]),
    "MSAA 3D 2x padrão": "anti_aliasing/quality/msaa_3d=1" in project,
    "Qualidade carregada no início": 'ValdoraVideo="*res://scripts/pvp/visual/qualidade_video.gd"' in project,
    "Configuração persistente": all(x in video for x in ["ConfigFile.new()", "cfg.load(SALVO)", "cfg.save(SALVO)"]),
    "Perfis de MSAA": all(x in video for x in [
        "Viewport.MSAA_DISABLED", "Viewport.MSAA_2X", "Viewport.MSAA_4X"
    ]),
    "Resolução real configurável": 'vp.scaling_3d_scale = escala_3d' in video,
    "Sombras por cenário": '"valdora_sombras"' in video and '"valdora_sombras"' in cenario,
    "FPS configurável": "Engine.max_fps = fps" in video,
    "Botões de vídeo funcionais": all(x in menu for x in [
        "_selecionar_video.bind(", "video.definir(categoria, valor)",
        "video.restaurar()", "video.aplicar()", "video.valor_de("
    ]),
    "Suavização de padrões": all(x in shader for x in [
        "cobertura_micro(", "fwidth(", "ruido(uv * 40.0)", "ruido(uv * 30.0)"
    ]),
    "Arena e mapa preservados": all(x in arena for x in [
        'const DADOS := "res://data/pvp/mapas_v0.1.json"',
        'CENARIO.new().montar(self)', '_paredes()', '_coberturas()'
    ]),
}
for name, ok in checks.items():
    print(f"{'PASS' if ok else 'FAIL'} {name}")
print(f"VISUAL_QUALITY {sum(checks.values())}/{len(checks)}")
raise SystemExit(0 if all(checks.values()) else 1)
