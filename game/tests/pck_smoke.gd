extends SceneTree
## CP004: prova de um ZIP real com SHA256, assinatura e carregamento Godot.
## O workflow copia a fixture do site para res://tests/fixtures/.
const CONTRACT := preload("res://scripts/updates/update_contract.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var fixture := "res://tests/fixtures/welcome-1.zip"
    var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/manifest.json"))
    var checks: Dictionary = {}
    checks["manifest_v2"] = typeof(manifest) == TYPE_DICTIONARY
    if not checks["manifest_v2"]:
        printerr("[VALDORA_CP004_PACK] manifesto inválido")
        quit(1)
        return
    var modules: Array = manifest.get("modules", [])
    var info: Dictionary = {}
    for row in modules:
        if str(row.get("id", "")) == "welcome":
            info = row
            break
    checks["signed_pack_present"] = not info.is_empty()
    checks["signature_and_hash"] = not info.is_empty() and CONTRACT.verify_file(info, fixture)
    checks["reject_missing_file"] = not info.is_empty() and not CONTRACT.verify_file(info, "res://tests/fixtures/non-existent.zip")
    var loaded := false
    var scene_ok := false
    if checks["signature_and_hash"]:
        loaded = ProjectSettings.load_resource_pack(ProjectSettings.globalize_path(fixture), false)
        if loaded:
            var scene := load("res://valdora_modules/welcome/entry.tscn")
            if scene is PackedScene:
                var instance: Node = scene.instantiate()
                scene_ok = instance is Control
                instance.queue_free()
    checks["pack_mounted"] = loaded
    checks["scene_loaded"] = scene_ok
    var passed: int = 0
    for name in checks:
        if bool(checks[name]):
            passed += 1
    var ok := passed == checks.size()
    print("[VALDORA_CP004_PACK] ", JSON.stringify({"ok": ok, "passed": passed, "total": checks.size(), "checks": checks}))
    quit(0 if ok else 1)
