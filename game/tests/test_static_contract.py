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
checks['diagnostic_checks_present'] = source.count('results["') == 22 and 'CHANNEL_DIAGNOSTIC' in source
checks['diagnostic_enabled_for_alpha'] = 'const ALPHA_DIAGNOSTICS_ENABLED := true' in source and 'if ALPHA_DIAGNOSTICS_ENABLED:' in source and 'if OS.is_debug_build():' not in source
checks['no_live_cloud_required'] = all(s not in source for s in ['Supabase','MultiplayerPeer']) and (root/'scripts/content_updater.gd').exists()
checks['android_32_64'] = all(s in presets for s in ('architectures/armeabi-v7a=true','architectures/arm64-v8a=true'))
checks['android_package_and_version'] = all(s in presets for s in ('ink.evolu.valdora','version/code=103','version/name="0.4.1-alpha"'))
checks['engine_smoke_script'] = (root/'tests/smoke.gd').is_file() and 'CHANNEL_ENGINE_SMOKE' in (root/'tests/smoke.gd').read_text()
for key, ok in checks.items():
 print(('PASS' if ok else 'FAIL')+' '+key)
assert all(checks.values()), 'contract validation failed'
print('PASS: %d static contract tests. Godot runtime not executed.' % len(checks))

# Alpha 0.1.2: teste visivel mesmo quando o Android nao sinaliza debug.
assert "const ALPHA_DIAGNOSTICS_ENABLED := true" in source
assert "if ALPHA_DIAGNOSTICS_ENABLED:" in source
assert "if OS.is_debug_build():" not in source
print("OK alpha 0.2: diagnostic button remains enabled for development")

# Contract checks for a data-only, non-executable, HTTPS update channel.
from hashlib import sha256
manifest = __import__('json').loads((root/'site_updates/manifest.json').read_text())
payload_path = root/'site_updates/content/valdora-1.json'
payload = __import__('json').loads(payload_path.read_text())
updater = (root/'scripts/content_updater.gd').read_text()
checks_update = {
    'game_label': 'package/name="Valdora"' in presets and 'brand.text = "VALDORA' in source,
    'package_id_isolated': 'package/unique_name="ink.evolu.valdora"' in presets,
    'version_advanced': 'version/code=103' in presets,
    'internet_permission': 'permissions/internet=true' in presets,
    'manifest_contract': manifest['game']=='Valdora' and manifest['required_client_version']=='0.2.0',
    'content_integrity': sha256(payload_path.read_bytes()).hexdigest()==manifest['content']['sha256'],
    'content_schema': payload['schema_version']==1 and payload['content_version']==manifest['content_version'],
    'whitelisted_texts': set(payload['strings']) <= {'welcome','merchant','bank','blacksmith','guard'},
    'no_executable_downloads': 'load_resource_pack' not in updater and updater.count('HTTPRequest.new()') == 2,
    'offline_savings_preserved': 'user://channel_save.json' in source and 'user://valdora_content_state.json' in updater and 'config/name="EVOLU Channel — Valdora"' in (root/'project.godot').read_text(),
    'domain_restriction': 'https://channel.evolu.ink/updates/content/' in updater and 'SHA256' in updater,
    'manual_update_button': 'ATUALIZAR' in source and 'check_for_updates' in updater,
}
for key,ok in checks_update.items(): print(('PASS' if ok else 'FAIL')+' '+key)
assert all(checks_update.values())
print('PASS %d content update contracts; engine/network still require device validation.' % len(checks_update))

# Diagnosticos: status de erro exposto ao HUD e codigos Godot/HTTP no log.
updater_code=(root/'scripts/content_updater.gd').read_text()
assert '_explain_network_error("manifesto", result, response_code)' in updater_code
assert '_explain_network_error("conteudo", result, response_code)' in updater_code
assert 'HTTPRequest.RESULT_CANT_RESOLVE' in updater_code
assert 'HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR' in updater_code
assert 'stage=%s result=%d http=%d' in updater_code
assert '_notify(message)' in source
print('PASS alpha 0.2.1: HTTP/DNS/TLS diagnostics shown and offline preserved')

# CP002-B: catálogo original e contrato da interface.
hero_data=json.loads((root/'data/valdora_heroes_v0.1.json').read_text())
hero_system=(root/'scripts/heroes/hero_system.gd').read_text()
hero_panel=(root/'scripts/ui/hero_panel.gd').read_text()
assert [h['display_name'] for h in hero_data['heroes']] == ['Pietro', 'Henzo', 'Giulia', 'Arthur']
assert len({h['hero_id'] for h in hero_data['heroes']}) == 4
assert all(sum(h['attributes_level1'].values()) == 66 for h in hero_data['heroes'])
assert 'user://valdora_hero_roster_v1.json' in hero_system and 'user://channel_save.json' not in hero_system
assert 'HERO_SYSTEM.load_catalog()' in source and 'HERO_PANEL.new()' in source
assert '22' in str(source.count('results["'))
assert 'data/*.json' in presets and 'updates/trust/*.pub' in presets
assert 'ink.evolu.valdora' in presets
assert (root/'tests/hero_smoke.gd').is_file()
print('PASS: CP002-B catalog, formation, persistence and Android package contracts.')

# CP003-C: arena visual, controles táticos e assinatura preservada.
arena=(root/'scripts/combat/arena_panel.gd').read_text()
assert 'SubViewportContainer.new()' in arena and 'SubViewport.new()' in arena
assert 'own_world_3d = true' in arena and 'scene_camera.current = true' in arena
assert 'ENGINE.advance_round(' in arena and 'playback_queue' in arena
assert all(command in arena for command in ['take_turn("none")', 'take_turn("auto")', 'take_turn("manual")'])
assert 'COMBAT_ARENA.new()' in source and 'combat_panel.configure(hero_catalog, hero_state)' in source
assert 'cp003_repetibilidade' in source and 'cp003_arena' in source
assert 'package/unique_name="ink.evolu.valdora"' in presets and 'version/code=103' in presets
assert 'FileAccess' not in arena and 'SAVE_PATH' not in arena
print('PASS: CP003-C arena, tactical controls, save isolation and stable Android identity.')
