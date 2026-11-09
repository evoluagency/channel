extends SceneTree
## CP009: evolução urbana e produção determinística com save do CP005-CP008.
const CONTRACT = preload("res://scripts/updates/update_contract.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var checks: Dictionary = {}
    var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/manifest.json"))
    var item: Dictionary = {}
    for raw in manifest.get("modules", []):
        if str(raw.get("id", "")) == "city":
            item = raw
    var archive := "res://tests/fixtures/city-7.zip"
    checks["manifest_revision"] = int(manifest.get("revision", 0)) == 8
    checks["module_v7"] = int(item.get("version", 0)) == 7
    checks["signature"] = CONTRACT.verify_file(item, archive)
    checks["mount"] = ProjectSettings.load_resource_pack(ProjectSettings.globalize_path(archive), false)
    if not checks["mount"]:
        _report(checks)
        return
    var resource = load("res://valdora_modules/city/entry.tscn")
    checks["scene"] = resource is PackedScene
    if not checks["scene"]:
        _report(checks)
        return
    var city = resource.instantiate()
    root.add_child(city)
    await process_frame
    checks["ui_production"] = city.production_label != null and city.production_button != null
    checks["save_path"] = city.SAVE_PATH == "user://valdora_city_cp005_v1.json"
    # Save CP008 deve ser aceito sem os novos campos.
    var previous: Dictionary = {
        "schema_version": 1, "name": "Auren", "resources": {"madeira": 180, "pedra": 140},
        "buildings": [], "revision": 0, "visual_style": "azul"
    }
    checks["legacy_accepted"] = city._valid_city(previous)
    checks["food_negative_rejected"] = not city._valid_city({
        "schema_version": 1, "name": "Auren", "resources": {"madeira": 180, "pedra": 140, "alimentos": -1},
        "buildings": [], "revision": 0
    })
    checks["future_date_rejected"] = not city._valid_city({
        "schema_version": 1, "name": "Auren", "resources": {"madeira": 180, "pedra": 140},
        "buildings": [], "revision": 0, "last_collection_unix": 5000000000
    })
    city.city = city._new_city()
    checks["init_food"] = int(city.city["resources"].get("alimentos", -1)) == 0
    checks["save_compatible"] = city._valid_city(city.city)
    city._select_type("fundacao")
    city._try_build(Vector2i(5, 5))
    checks["foundation"] = city._has_foundation()
    city._select_type("fazenda")
    city._try_build(Vector2i(8, 7))
    city._select_type("serraria")
    city._try_build(Vector2i(2, 5))
    city._select_type("pedreira")
    city._try_build(Vector2i(10, 1))
    checks["three_industries"] = city._has_kind("fazenda") and city._has_kind("serraria") and city._has_kind("pedreira")
    var rates: Dictionary = city._production_rates()
    checks["rates"] = int(rates["alimentos"]) == 10 and int(rates["madeira"]) == 8 and int(rates["pedra"]) == 5
    # Relógio injetado: resultados repetíveis e sem esperar tempo real.
    var start := 1700000000
    city.city["last_collection_unix"] = start
    var quote: Dictionary = city._production_estimate(start + 1800)
    checks["three_cycles"] = int(quote["cycles"]) == 3
    checks["earned"] = int(quote["gains"]["madeira"]) == 24 and int(quote["gains"]["pedra"]) == 15 and int(quote["gains"]["alimentos"]) == 30
    var before_resources: Dictionary = city.city["resources"].duplicate(true)
    checks["first_claim"] = city._collect_production_at(start + 1800)
    checks["balance"] = int(city.city["resources"]["madeira"]) == int(before_resources["madeira"]) + 24 and int(city.city["resources"]["alimentos"]) == 30
    var count_after := int(city.city["collection_count"])
    checks["no_double_claim"] = not city._collect_production_at(start + 1800) and int(city.city["collection_count"]) == count_after
    checks["persistence"] = int(city._read_save(city.SAVE_PATH).get("collection_count", 0)) == count_after
    var offline: Dictionary = city._production_estimate(start + 100000)
    checks["idle_cap"] = int(offline["cycles"]) == 48 and bool(offline["capped"])
    checks["idle_collected"] = city._collect_production_at(start + 100000) and int(city.city["last_collection_unix"]) == start + 100000
    checks["no_idle_repeat"] = not city._collect_production_at(start + 100000)
    checks["staff_draw_only"] = city.has_method("_draw_citizens") and city.has_method("_draw_city_life_details")
    city.queue_free()
    _report(checks)

func _report(checks: Dictionary) -> void:
    var passed := 0
    for value in checks.values():
        if bool(value):
            passed += 1
    print("[VALDORA_CP009_CITY7] ", JSON.stringify({"success": passed == checks.size(), "passed": passed, "total": checks.size(), "checks": checks}))
    quit(0 if passed == checks.size() else 1)
