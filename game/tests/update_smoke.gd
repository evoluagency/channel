extends SceneTree
## CP004: contratos em Godot, offline, sem tocar em arquivos de salvamento.
const CONTRACT = preload("res://scripts/updates/update_contract.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var checks: Dictionary = {}
    var manifest := {
        "schema_version": 2, "game": "Valdora", "channel": "alpha",
        "revision": 1, "min_client_code": 102, "modules": []
    }
    checks["manifest_v2"] = CONTRACT.validate_manifest(manifest).is_empty()
    var wrong: Dictionary = manifest.duplicate(true)
    wrong["game"] = "Outro jogo"
    checks["rejeita_outro_jogo"] = not CONTRACT.validate_manifest(wrong).is_empty()
    wrong = manifest.duplicate(true)
    wrong["min_client_code"] = 999
    checks["rejeita_cliente_antigo"] = not CONTRACT.validate_manifest(wrong).is_empty()
    checks["id_valido"] = CONTRACT.valid_id("guide_01")
    checks["rejeita_traversal"] = not CONTRACT.valid_id("../secrets")
    checks["sha_valido"] = CONTRACT.valid_sha("a".repeat(64))
    checks["sha_invalido"] = not CONTRACT.valid_sha("xyz")
    var module := {
        "id": "guide", "version": 1, "kind": "data",
        "url": CONTRACT.ORIGIN + "modules/guide-1.json",
        "sha256": "a".repeat(64), "bytes": 428
    }
    wrong = manifest.duplicate(true)
    wrong["modules"] = [module]
    checks["data_manifest_valido"] = CONTRACT.validate_manifest(wrong).is_empty()
    var invalid_module: Dictionary = module.duplicate(true)
    invalid_module["url"] = "https://example.com/a.json"
    wrong["modules"] = [invalid_module]
    checks["rejeita_url_externa"] = not CONTRACT.validate_manifest(wrong).is_empty()
    wrong["modules"] = [module, module]
    checks["rejeita_duplicacao"] = not CONTRACT.validate_manifest(wrong).is_empty()
    var data := {"schema_version": 1, "module_id": "guide", "title": "Manual", "actions": [
        {"id": "arena", "label": "Abrir arena", "command": "open_combat"}
    ]}
    checks["comandos_validos"] = CONTRACT.validate_data(data, "guide")
    data["actions"][0]["command"] = "execute_script"
    checks["rejeita_codigo_remoto"] = not CONTRACT.validate_data(data, "guide")
    checks["estado_vazio_invalido"] = not CONTRACT.valid_state({})
    var passed := 0
    for k in checks.keys():
        if checks[k]:
            passed += 1
    var success := passed == checks.size()
    print("[VALDORA_CP004_OTA] ", JSON.stringify({"ok": success, "passed": passed, "total": checks.size(), "checks": checks}))
    quit(0 if success else 1)
