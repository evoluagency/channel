#!/usr/bin/env bash
# Gera os PNG e as folhas de uma construção. Uso: tools/arte3d/gerar.sh construcao "Nome" [PASTA_PNG]
set -euo pipefail
cd "$(dirname "$0")"
G="${GODOT:-godot}"
C="$1"; N="$2"; S="${3:-/tmp/arte3d/$C}"
J="1:azul:folha,2:azul:folha,3:azul:folha,4:azul:folha,5:azul:folha,6:azul:folha,6:azul:detalhe"
for a in azul vermelha verde roxa amarela; do J="$J,3:$a:alianca,6:$a:alianca"; done
[ -d .godot ] || "$G" --headless --editor --path . --quit >/dev/null 2>&1 || true
timeout 300 xvfb-run -a -s "-screen 0 1600x1600x24" "$G" --path . --rendering-driver opengl3 -- \
  --construcao="$C" --saida="$S" --trabalhos="$J" 2>&1 | grep -E "SCRIPT ERROR|Parse Error|ERROR: .*res://" || true
python3 folha.py "$S" "$C" "$N" ../../game/docs/imagens/componentes
# prévia reduzida para conferência rápida
python3 -c "
from PIL import Image
im = Image.open('../../game/docs/imagens/componentes/${C}_folha_faixas.png')
im.resize((im.width * 2 // 3, im.height * 2 // 3)).save('${S}/previa.png')"
