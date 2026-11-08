#!/usr/bin/env python3
"""CP003 combat isolation survives CP004 base APK version bump (no remote combat authority)."""
import json
from pathlib import Path

game = Path(__file__).resolve().parents[1]
combat = (game / "scripts/combat/pve_engine.gd").read_text()
smoke = (game / "tests/combat_smoke.gd").read_text()
preset = (game / "export_presets.cfg").read_text()
catalog = json.loads((game / "data/valdora_heroes_v0.1.json").read_text())

checks = {
    "engine_refcounted_no_scene": combat.startswith("extends RefCounted\n"),
    "pure_entrypoints": all(s in combat for s in [
        "static func begin_battle(", "static func advance_round(", "static func simulate(",
        "static func damage_amount(", "static func result_digest("]),
    "no_file_io": all(s not in combat for s in [
        "FileAccess", "DirAccess", "ResourceSaver", "user://", "FileAccess.open"]),
    "no_network_or_cloud": all(s not in combat for s in [
        "HTTPRequest", "HTTPClient", "MultiplayerPeer", "Supabase", "load_resource_pack"]),
    "deterministic_prng": "RNG_MULTIPLIER := 48271" in combat and "randi(" not in combat and "randf(" not in combat,
    "eight_round_limit": "const MAX_ROUNDS := 8" in combat,
    "four_hero_limit": "const MAX_HEROES := 4" in combat,
    "no_rewards": '"reward_issued": false' in combat,
    "no_3d_dependencies": all(s not in combat for s in ["Node3D", "CharacterBody3D", "Camera3D", "AnimationPlayer"]),
    "gdtest_exists": (game / "tests/combat_smoke.gd").is_file() and "VALDORA_CP003_COMBAT" in smoke,
    "four_approved_heroes": [x["display_name"] for x in catalog["heroes"]] == ["Pietro", "Henzo", "Giulia", "Arthur"],
    "no_change_android_identity": 'package/unique_name="ink.evolu.valdora"' in preset,
    "no_change_android_version": "version/code=102" in preset and 'version/name="0.4.0-alpha"' in preset,
    "arena_no_file_io": all(s not in (game / "scripts/combat/arena_panel.gd").read_text() for s in ["FileAccess", "DirAccess", "user://", "HTTPRequest", "Supabase"]),
    "arena_isolated_render": "SubViewport.new()" in (game / "scripts/combat/arena_panel.gd").read_text(),
    "no_change_release_artifact": 'export_path="dist/Valdora.apk"' in preset,
}
for name, passed in checks.items():
    print(("PASS" if passed else "FAIL") + " CP003 " + name)
assert all(checks.values()), "CP003 static contract failed"
print("PASS: %d CP003 static checks" % len(checks))
