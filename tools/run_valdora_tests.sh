#!/usr/bin/env bash
# Valdora — todos os testes locais em um comando, sem GitHub Actions e sem custo.
#
# Uso: tools/run_valdora_tests.sh [--py | --all | --historico]
#   (sem opção)  testes Python + os 8 testes Godot que os workflows rodam hoje
#   --py         só os testes Python (não precisa de Godot)
#   --all        também os smokes extras que devem passar hoje (CP005, CP007,
#                layout de nome e OTA remoto; este último precisa de rede até
#                channel.evolu.ink)
#   --historico  --all + os smokes CP008, CP009 e CP010, presos às revisões 7, 8
#                e 9 do manifesto: contra o manifesto atual falham por desenho.
#
# Fixtures: antes dos smokes o script copia site/updates/v2/manifest.json e os
# módulos *.zip para game/tests/fixtures/, como faz o workflow valdora-cp004-ota.
# Essas cópias são ignoradas pelo git (game/.gitignore).
#
# Godot: usa a variável GODOT ou "godot" no PATH. Versão esperada: 4.7.2
# (Linux x86_64, zip SHA-256 cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4,
#  o mesmo conferido pelo workflow valdora-cp004-ota).
# Saída: 0 = tudo passou; 1 = algum teste falhou; 2 = Godot ausente (a parte Python rodou).

set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

MODE="${1:-default}"
case "$MODE" in default|--py|--all|--historico) ;; *) echo "Opção desconhecida: $MODE"; sed -n 3,15p "$0"; exit 2 ;; esac

GODOT_BIN="${GODOT:-godot}"
TIMEOUT_S="${VALDORA_SMOKE_TIMEOUT:-120}"
LOGDIR="$(mktemp -d)"
NAMES=(); RESULTS=()

run() { # run "nome" timeout comando...
  local name="$1" t="$2"; shift 2
  local log="$LOGDIR/${name//[^A-Za-z0-9_.-]/_}.log"
  if timeout "$t" "$@" >"$log" 2>&1; then
    NAMES+=("$name"); RESULTS+=("PASSOU"); printf '  PASSOU  %s\n' "$name"
  else
    local rc=$?
    NAMES+=("$name"); RESULTS+=("FALHOU")
    printf '  FALHOU  %s (código %s%s)\n' "$name" "$rc" "$([ "$rc" = 124 ] && echo ', timeout')"
    tail -n 8 "$log" | sed 's/^/          /'
  fi
}

echo "== Python (contratos e validações estáticas)"
run "tools_validate"            60 python3 -I game/tools_validate.py
run "test_static_contract"      60 python3 -I game/tests/test_static_contract.py
run "test_combat_static"        60 python3 -I game/tests/test_combat_static_contract.py
run "test_ota_contract"         60 python3 -I game/tests/test_ota_contract.py
run "ota_manifest --verify"     60 python3 -I tools/ota_manifest.py --verify-existing

GODOT_MISSING=0
if [ "$MODE" != "--py" ]; then
  echo "== Godot headless"
  if ! command -v "$GODOT_BIN" >/dev/null 2>&1 && [ ! -x "$GODOT_BIN" ]; then
    GODOT_MISSING=1
    echo "  Godot não encontrado (\"$GODOT_BIN\"). Defina GODOT=/caminho/do/godot ou ponha o 4.7.2 no PATH."
  else
    VER="$("$GODOT_BIN" --version 2>/dev/null | head -n1)"
    echo "  versão: ${VER:-desconhecida}"
    case "$VER" in 4.7.2*) ;; *) echo "  AVISO: a versão esperada é 4.7.2." ;; esac
    # Fixtures que os smokes leem de res://tests/fixtures/ (mesma cópia do workflow cp004-ota).
    mkdir -p game/tests/fixtures
    cp site/updates/v2/manifest.json game/tests/fixtures/manifest.json
    cp site/updates/v2/modules/*.zip game/tests/fixtures/
    run "godot import" 300 "$GODOT_BIN" --headless --editor --path game --quit
    SMOKES=(core_smoke hero_smoke combat_smoke smoke update_smoke pck_smoke cp006_live_smoke cp011_city_v9_smoke)
    if [ "$MODE" = "--all" ] || [ "$MODE" = "--historico" ]; then
      SMOKES+=(remote_update_smoke city_name_layout_smoke cp005_city_smoke cp007_city_visual_smoke)
    fi
    if [ "$MODE" = "--historico" ]; then
      echo "  AVISO: CP008, CP009 e CP010 exigem manifesto nas revisões 7, 8 e 9; contra o atual falham por desenho."
      SMOKES+=(cp008_city_v6_smoke cp009_city_v7_smoke cp010_city_v8_smoke)
    fi
    for s in "${SMOKES[@]}"; do
      run "$s" "$TIMEOUT_S" "$GODOT_BIN" --headless --path game --script "res://tests/$s.gd"
    done
  fi
fi

PASS=0; FAIL=0
for r in "${RESULTS[@]}"; do [ "$r" = "PASSOU" ] && PASS=$((PASS+1)) || FAIL=$((FAIL+1)); done
echo "== Resumo: $PASS passaram, $FAIL falharam (logs em $LOGDIR)"
[ "$GODOT_MISSING" = 1 ] && echo "   Parte Godot NÃO executada."
[ "$FAIL" -gt 0 ] && exit 1
[ "$GODOT_MISSING" = 1 ] && exit 2
exit 0
