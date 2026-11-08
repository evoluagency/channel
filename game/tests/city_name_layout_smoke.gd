extends SceneTree
## CP006 hotfix - formulário de nomeação mobile, persistência e ZIP assinado.
const CONTRACT = preload("res://scripts/updates/update_contract.gd")
func _initialize() -> void:
    call_deferred("_run")
func _save_visible(n: Node) -> bool:
    if n is Button and n.text == "SALVAR" and n.is_visible_in_tree():
        return true
    for child in n.get_children():
        if _save_visible(child):
            return true
    return false
func _run() -> void:
    var checks: Dictionary = {}
    var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/manifest.json"))
    var module: Dictionary = {}
    for item in manifest.get("modules", []):
        if str(item.get("id", "")) == "city":
            module = item
            break
    var archive := "res://tests/fixtures/city-5.zip"
    checks["current_revision"] = manifest.get("revision") == 6
    checks["signed_city_latest"] = module.get("version") == 5 and CONTRACT.verify_file(module, archive)
    checks["zip_mounted"] = ProjectSettings.load_resource_pack(ProjectSettings.globalize_path(archive), false)
    if not checks["zip_mounted"]:
        _report(checks)
        return
    var packed = load("res://valdora_modules/city/entry.tscn")
    checks["scene_loaded"] = packed is PackedScene
    if not checks["scene_loaded"]:
        _report(checks)
        return
    var city = packed.instantiate()
    root.add_child(city)
    await process_frame
    city._ask_name()
    await process_frame
    checks["inline_overlay"] = city.editor_overlay is ColorRect and city.editor_overlay.visible
    checks["button_visible"] = _save_visible(city.editor_overlay)
    checks["input_present"] = city.editor_input is LineEdit and city.editor_input.max_length == 24
    checks["save_path_unchanged"] = city.SAVE_PATH == "user://valdora_city_cp005_v1.json"
    city.editor_input.text = "Nova Auren"
    city._on_name_submitted("Nova Auren")
    checks["name_saved"] = city.snapshot_for_test().get("name") == "Nova Auren"
    checks["save_persisted"] = city._read_save(city.SAVE_PATH).get("name") == "Nova Auren"
    checks["overlay_closed"] = not city.editor_overlay.visible
    city._ask_name()
    city.editor_input.text = "AB"
    city._save_name()
    checks["invalid_rejected"] = city.snapshot_for_test().get("name") == "Nova Auren"
    checks["inline_error"] = city.editor_overlay.visible and city.editor_error.text.contains("Nome inválido")
    city._cancel_name()
    checks["cancel_closes"] = not city.editor_overlay.visible
    city.queue_free()
    _report(checks)
func _report(checks: Dictionary) -> void:
    var passed := 0
    for value in checks.values():
        if bool(value):
            passed += 1
    print("[VALDORA_CITY_NAME_CP006] ", JSON.stringify({"passed":passed,"total":checks.size(),"checks":checks}))
    quit(0 if passed == checks.size() else 1)
