#!/usr/bin/env bash
# Confere a sintaxe de todos os scripts GDScript do PvP (e dos testes PvP) com o Godot.
# Um erro de sintaxe faz os smokes travarem em vez de falhar; esta checagem falha na hora.
# Uso: GODOT=/caminho/godot tools/godot_checar_scripts.sh
set -u
G="${GODOT:-godot}"
# Sem o binário a checagem não pode dizer "0 erros": falha explicitamente.
if ! command -v "$G" >/dev/null 2>&1 && [ ! -x "$G" ]; then
  echo "Godot não encontrado ($G). Defina GODOT=/caminho/godot."; exit 2
fi
cd "$(dirname "$0")/../game" || exit 2
falhas=0
for f in $(ls scripts/pvp/*.gd scripts/pvp/visual/*.gd scripts/ui/pvp/*.gd tests/pvp_*.gd 2>/dev/null); do
  saida="$(timeout 60 "$G" --headless --path . --check-only -s "$f" 2>&1 | grep -E 'SCRIPT ERROR|Parse Error|Compile Error' || true)"
  if [ -n "$saida" ]; then
    echo "ERRO  $f"; echo "$saida" | head -3 | sed 's/^/      /'; falhas=$((falhas+1))
  fi
done
echo "Scripts PvP com erro: $falhas"
[ "$falhas" -eq 0 ]
