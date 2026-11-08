extends SceneTree
## CP006: prove that a signed namespace-constrained ZIP can mount during play.
const CONTRACT := preload("res://scripts/updates/update_contract.gd")
const BOOT := preload("res://scripts/updates/boot_loader.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var document = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/manifest.json"))
    var entry: Dictionary = {}
    for item in document.get("modules", []):
        if str(item.get("id", "")) == "welcome":
            entry = item
    var fixture := "res://tests/fixtures/welcome-1.zip"
    var boot = BOOT.new()
    var checks: Dictionary = {}
    checks["signed_file"] = not entry.is_empty() and CONTRACT.verify_file(entry, fixture)
    checks["namespace"] = boot._zip_namespace_ok(fixture, "welcome", "res://valdora_modules/welcome/entry.tscn")
    checks["reject_wrong_namespace"] = not boot._zip_namespace_ok(fixture, "different", "res://valdora_modules/different/entry.tscn")
    checks["mounted_live"] = boot.mount_verified(entry, fixture)
    checks["entry_available"] = boot.is_loaded("welcome") and boot.get_entry("welcome") == "res://valdora_modules/welcome/entry.tscn"
    var scene := ResourceLoader.load("res://valdora_modules/welcome/entry.tscn", "", ResourceLoader.CACHE_MODE_REPLACE_DEEP)
    checks["resource_visible_live"] = scene is PackedScene
    if scene is PackedScene:
        var node: Node = scene.instantiate()
        checks["valid_control_root"] = node is Control
        node.free()
    else:
        checks["valid_control_root"] = false
    var forged: Dictionary = entry.duplicate(true)
    forged["signature_b64"] = "A".repeat(512)
    checks["reject_forged_signature"] = not boot.mount_verified(forged, fixture)
    var passed := 0
    for value in checks.values():
        if bool(value):
            passed += 1
    print("[VALDORA_CP006_LIVE] ", JSON.stringify({"passed":passed, "total":checks.size(), "checks":checks}))
    boot.free()
    quit(0 if passed == checks.size() else 1)
