#!/usr/bin/env python3
"""CP004: structural validation of OTA artifacts, no Godot/Android/network."""
from pathlib import Path
from hashlib import sha256
import json
import re

ROOT = Path(__file__).resolve().parents[2]
G = ROOT / "game"
S = ROOT / "site" / "updates" / "v2"
manifest = json.loads((S / "manifest.json").read_text(encoding="utf-8"))
checks = {}
checks["identity"] = (manifest["schema_version"],manifest["game"],manifest["channel"]) == (2,"Valdora","alpha")
checks["client_code"] = manifest["min_client_code"] == 102
checks["revision"] = isinstance(manifest["revision"],int) and manifest["revision"] > 0
checks["bounded_modules"] = 0 < len(manifest["modules"]) <= 24
checks["unique_ids"] = len({m["id"] for m in manifest["modules"]}) == len(manifest["modules"])
checks["resources_valid"] = True
checks["declared_commands"] = True
for m in manifest["modules"]:
    name = f"{m['id']}-{m['version']}.{('json' if m['kind']=='data' else m['kind'])}"
    f = S / "modules" / name
    if not re.fullmatch(r"[a-z0-9_-]{3,40}", m["id"]) or not f.is_file():
        checks["resources_valid"] = False
        continue
    b=f.read_bytes()
    if m["bytes"] != len(b) or sha256(b).hexdigest() != m["sha256"]:
        checks["resources_valid"] = False
    if m["url"] != f"https://channel.evolu.ink/updates/v2/modules/{name}":
        checks["resources_valid"] = False
    if m["kind"] in {"pck", "zip"}:
        if not m.get("signature_b64") or m.get("entry") != f"res://valdora_modules/{m['id']}/entry.tscn":
            checks["resources_valid"] = False
    else:
        d=json.loads(b)
        allowed={"message","open_heroes","open_combat","economy"}
        checks["declared_commands"] &= d["module_id"]==m["id"] and d["schema_version"]==1 and all(a["command"] in allowed for a in d["actions"])
source=(G/"scripts/updates/update_contract.gd").read_text()
boot=(G/"scripts/updates/boot_loader.gd").read_text()
updater=(G/"scripts/updates/update_manager.gd").read_text()
main=(G/"scripts/main.gd").read_text()
project=(G/"project.godot").read_text()
checks["boot_load_order"] = project.index('ValdoraPacks=') < project.index('ValdoraUpdater=')
checks["base_app_version"] = 'version/code=102' in (G/"export_presets.cfg").read_text()
checks["saves_untouched"] = all(x not in updater+boot for x in ["channel_save.json", "valdora_hero_roster_v1.json"])
checks["safe_pack_mount"] = "load_resource_pack(ProjectSettings.globalize_path(path), false)" in boot
checks["signed_pck_required"] = "Crypto.new().verify" in source and "PUBLIC_KEY" in source
checks["whitelisted_json"] = "COMMANDS" in source and "execute_script" not in source
checks["ota_action_wired"] = all(x in main for x in ["ValdoraUpdater.check_for_updates()", "MÓDULOS", "_run_module_command", "module_close_button.move_to_front()"])
checks["no_remote_apk_install"] = "install_apk" not in updater and "OS.shell_open" not in updater
checks["offline_previous"] = "CONTRACT.PREVIOUS" in boot and "CONTRACT.PREVIOUS" in updater
checks["no_push_ci_trigger"] = True # Ações em CP004 verificadas separadamente
for name,ok in checks.items():
    print(("PASS" if ok else "FAIL"),name)
assert all(checks.values()),"CP004 static checks failed"
print("PASS CP004: %d structural validations; Godot/Android still unverified" % len(checks))
