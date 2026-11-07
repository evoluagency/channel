#!/usr/bin/env python3
"""Structural safety tests; no claim of Godot execution."""
from pathlib import Path
import re
import json
from zipfile import ZipFile

root = Path(__file__).resolve().parents[1]
source = (root / 'scripts/main.gd').read_text()
presets = (root / 'export_presets.cfg').read_text()
checks = {}
checks['birth_in_valdora_sector'] = bool(re.search(r'const START_POS\s*:=\s*Vector3\(0,\s*0\.2,\s*15\)',source)) and 'const WORLD_SIZE := 96.0' in source
checks['door_has_real_opening'] = all(s in source for s in ['var doorway_width := 2.7','var doorway_height := 3.6','var side_width := (width - doorway_width) / 2.0','var lintel_height := 5.4 - doorway_height']) and 'name + " fachada", pos' not in source
checks['door_passable_by_capsule'] = 2.7 > 2*0.42 and 3.6 > 2.4
checks['foundation_level_ground'] = 'pos + Vector3(0, -0.18, 0), Vector3(width, 0.36, depth)' in source
checks['threshold_level_ground'] = 'pos + Vector3(0, -0.06, front - 0.25), Vector3(doorway_width, 0.12, 1.0)' in source
checks['diagnostic_checks_present'] = source.count('results["') == 9 and 'CHANNEL_DIAGNOSTIC' in source
checks['diagnostic_enabled_for_alpha'] = 'const ALPHA_DIAGNOSTICS_ENABLED := true' in source and 'if ALPHA_DIAGNOSTICS_ENABLED:' in source and 'if OS.is_debug_build():' not in source
checks['no_live_cloud_required'] = all(s not in source for s in ['HTTPClient','HTTPRequest','Supabase','MultiplayerPeer'])
checks['android_32_64'] = all(s in presets for s in ('architectures/armeabi-v7a=true','architectures/arm64-v8a=true'))
checks['android_package_and_version'] = all(s in presets for s in ('ink.evolu.channel','version/code=3','version/name="0.1.2"'))
checks['engine_smoke_script'] = (root/'tests/smoke.gd').is_file() and 'CHANNEL_ENGINE_SMOKE' in (root/'tests/smoke.gd').read_text()
for key, ok in checks.items():
 print(('PASS' if ok else 'FAIL')+' '+key)
assert all(checks.values()), 'contract validation failed'
print('PASS: %d static contract tests. Godot runtime not executed.' % len(checks))
# Alpha 0.1.2: teste visivel mesmo quando o Android nao sinaliza debug.
assert "const ALPHA_DIAGNOSTICS_ENABLED := true" in source
assert "if ALPHA_DIAGNOSTICS_ENABLED:" in source
assert "if OS.is_debug_build():" not in source
print("OK alpha 0.1.2: diagnostic button not tied to debug build")
