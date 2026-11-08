extends SceneTree
## CP005: teste headless da expansão de cidade montada de ZIP.

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var checks: Dictionary = {}
    var zip_path := ProjectSettings.globalize_path("res://tests/fixtures/city-1.zip")
    checks["zip_mounted"] = ProjectSettings.load_resource_pack(zip_path, false)
    if not checks["zip_mounted"]:
        _report(checks)
        return
    var source = load("res://valdora_modules/city/entry.tscn")
    checks["scene_loaded"] = source is PackedScene
    if not checks["scene_loaded"]:
        _report(checks)
        return
    var city: Control = source.instantiate()
    checks["root_control"] = city is Control
    root.add_child(city)
    await process_frame
    checks["state_created"] = city.snapshot_for_test().get("schema_version") == 1
    checks["no_legacy_save"] = not city.SAVE_PATH == "user://channel_save.json"
    city.editor_input.text = "Auren Nova"
    city._save_name()
    checks["name_saved"] = city.snapshot_for_test().get("name") == "Auren Nova"
    city._select_type("fundacao")
    city._try_build(Vector2i(5, 5))
    checks["foundation"] = city.snapshot_for_test()["buildings"].size() == 1
    city._select_type("casa")
    city._try_build(Vector2i(6, 5))
    checks["house"] = city.snapshot_for_test()["buildings"].size() == 2
    var saved: Dictionary = city._read_save(city.SAVE_PATH)
    checks["persistence"] = saved.get("name") == "Auren Nova" and saved.get("buildings", []).size() == 2
    var before := city.snapshot_for_test()
    city._on_plot_clicked(city._iso(6.0, 5.0))
    checks["no_duplicate_debit"] = city.snapshot_for_test() == before
    checks["reject_corruption"] = not city._valid_city({"schema_version":1,"name":"x","revision":1,"resources":{"madeira":-1,"pedra":10},"buildings":[]})
    city.queue_free()
    _report(checks)

func _report(checks: Dictionary) -> void:
    var passed := 0
    for key in checks:
        if bool(checks[key]):
            passed += 1
    var success := passed == checks.size()
    print("[VALDORA_CP005] ", JSON.stringify({"success": success, "passed": passed, "total": checks.size(), "checks": checks}))
    quit(0 if success else 1)