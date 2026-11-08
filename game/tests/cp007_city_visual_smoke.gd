extends SceneTree
## CP007: módulos e UI isométrica sem alterar o formato de salvamento CP005.
const CONTRACT := preload("res://scripts/updates/update_contract.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var checks: Dictionary = {}
    var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/manifest.json"))
    var info: Dictionary = {}
    for item in manifest.get("modules", []):
        if str(item.get("id", "")) == "city":
            info = item
    var zip_path := "res://tests/fixtures/city-5.zip"
    checks["revision6"] = manifest.get("revision") == 6
    checks["signed_v5"] = info.get("version") == 5 and CONTRACT.verify_file(info, zip_path)
    checks["mounted"] = ProjectSettings.load_resource_pack(ProjectSettings.globalize_path(zip_path), false)
    if not checks["mounted"]:
        _report(checks)
        return
    var scene = load("res://valdora_modules/city/entry.tscn")
    checks["scene"] = scene is PackedScene
    if not checks["scene"]:
        _report(checks)
        return
    var city = scene.instantiate()
    root.add_child(city)
    await process_frame
    checks["save_path"] = city.SAVE_PATH == "user://valdora_city_cp005_v1.json"
    checks["save_schema"] = city.snapshot_for_test().get("schema_version") == 1
    checks["name_form"] = city.editor_overlay is ColorRect and city.editor_input is LineEdit
    checks["toolbar_scroll"] = city.build_buttons.has("inspecionar") and city.build_buttons.has("melhorar") and city.build_buttons.has("casa")
    checks["objective_label"] = city.objective_label != null and city.objective_label is Label
    city.city = city._new_city()
    city._refresh_ui()
    checks["start_objective"] = city._objective().contains("Nomeie")
    var empty_before: Dictionary = city.snapshot_for_test()
    city._select_type("inspecionar")
    city._on_plot_clicked(city._iso(5.0,5.0))
    checks["inspection_no_debit"] = city.snapshot_for_test() == empty_before
    checks["inspection_territory"] = city.selected_tile == Vector2i(5,5)
    city.city["name"] = "Nova Auren"
    city.city["buildings"].append({"type":"fundacao","x":5,"y":5,"level":1})
    checks["foundation_objective"] = city._objective().contains("Casa")
    city.city["buildings"].append({"type":"casa","x":6,"y":5,"level":2})
    checks["population_derived"] = city._city_population() == 12
    checks["mission_progress"] = city._objective().contains("Fazenda")
    checks["model_unchanged"] = city._valid_city(city.city)
    # Regressão de construção: salvar e mudar de ferramenta sem perder o tipo original.
    city.city = city._new_city()
    city._select_type("fundacao")
    city._try_build(Vector2i(5,5))
    checks["foundation_built"] = city._has_foundation() and city.selected_type == "inspecionar"
    checks["foundation_status"] = city.status_label.text.contains("Cidade fundada")
    city._select_type("casa")
    city._try_build(Vector2i(6,5))
    checks["house_built"] = city._at(Vector2i(6,5)).get("type") == "casa"
    checks["house_status"] = city.status_label.text.contains("Casa construída")
    checks["resources_paid"] = city.city["resources"]["madeira"] == 155 and city.city["resources"]["pedra"] == 130
    checks["save_disk"] = city._read_save(city.SAVE_PATH).get("buildings", []).size() == 2
    city.queue_free()
    _report(checks)

func _report(checks: Dictionary) -> void:
    var passed := 0
    for key in checks:
        if bool(checks[key]):
            passed += 1
    print("[VALDORA_CP007_VISUAL] ", JSON.stringify({"success":passed == checks.size(),"passed":passed,"total":checks.size(),"checks":checks}))
    quit(0 if passed == checks.size() else 1)
