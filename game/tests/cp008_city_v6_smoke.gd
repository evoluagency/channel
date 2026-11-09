extends SceneTree
## CP008 — teste de integração do pacote assinado, visualização e saves anteriores.
const CONTRACT := preload("res://scripts/updates/update_contract.gd")
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var checks: Dictionary = {}
    var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/manifest.json"))
    var module: Dictionary = {}
    for row in manifest.get("modules", []):
        if str(row.get("id", "")) == "city":
            module = row
    var zipfile := "res://tests/fixtures/city-6.zip"
    checks["revision7"] = manifest.get("revision",0) == 7
    checks["signed_v6"] = module.get("version",0) == 6 and CONTRACT.verify_file(module,zipfile)
    checks["live_pack"] = ProjectSettings.load_resource_pack(ProjectSettings.globalize_path(zipfile), false)
    if not checks["live_pack"]:
        _report(checks)
        return
    var packed = load("res://valdora_modules/city/entry.tscn")
    checks["packed_scene"] = packed is PackedScene
    if not checks["packed_scene"]:
        _report(checks)
        return
    var city = packed.instantiate()
    root.add_child(city)
    await process_frame
    city.city = city._new_city()
    city._refresh_ui()
    checks["save_path"] = city.SAVE_PATH == "user://valdora_city_cp005_v1.json"
    checks["schema1"] = city.snapshot_for_test().get("schema_version") == 1
    var old_save := {"schema_version":1,"name":"Antiga Auren","resources":{"madeira":70,"pedra":80},"buildings":[],"revision":1}
    checks["legacy_compatible"] = city._valid_city(old_save)
    var unsafe: Dictionary = old_save.duplicate(true)
    unsafe["visual_style"] = "../../secrets"
    checks["style_rejected"] = not city._valid_city(unsafe)
    checks["all_types"] = all_types(city)
    var before: Dictionary = city.snapshot_for_test()
    city._toggle_grid()
    city._toggle_dusk()
    checks["visual_toggles"] = city.show_grid and city.dusk_mode
    checks["no_save_change"] = city.snapshot_for_test() == before
    city._cycle_style()
    checks["theme_persisted"] = city.snapshot_for_test().get("visual_style") == "terracota"
    checks["theme_disk"] = city._read_save(city.SAVE_PATH).get("visual_style") == "terracota"
    checks["initial_stage"] = city._city_stage() == "Assentamento"
    city._select_type("fundacao")
    city._try_build(Vector2i(5,5))
    checks["foundation"] = city._has_foundation()
    city._select_type("casa")
    city._try_build(Vector2i(6,5))
    checks["house"] = city._at(Vector2i(6,5)).get("type") == "casa"
    city._select_type("melhorar")
    city._upgrade_building(Vector2i(6,5))
    checks["house_upgrade"] = int(city._at(Vector2i(6,5)).get("level",0)) == 2
    city._select_type("jardim")
    city._try_build(Vector2i(6,6))
    checks["garden"] = city._at(Vector2i(6,6)).get("type") == "jardim"
    city._select_type("poco")
    city._try_build(Vector2i(5,6))
    checks["well"] = city._at(Vector2i(5,6)).get("type") == "poco"
    city._select_type("praca")
    city._try_build(Vector2i(5,4))
    checks["plaza"] = city._at(Vector2i(5,4)).get("type") == "praca"
    city._select_type("mercado")
    city._try_build(Vector2i(4,4))
    checks["market"] = city._at(Vector2i(4,4)).get("type") == "mercado"
    city._select_type("estrada")
    city._try_build(Vector2i(3,4))
    checks["road"] = city._at(Vector2i(3,4)).get("type") == "estrada"
    city._select_type("inspecionar")
    var previous: Dictionary = city.snapshot_for_test()
    city._on_plot_clicked(city._iso(3.0,4.0))
    checks["inspection_no_charge"] = city.snapshot_for_test() == previous
    checks["progress_stage"] = city._city_stage() != "Assentamento"
    checks["persisted_structures"] = city._read_save(city.SAVE_PATH).get("buildings",[]).size() == city.snapshot_for_test().get("buildings",[]).size()
    checks["style_roof"] = city._roof_color() == Color("#cc7452")
    checks["inhabitants_active"] = city._has_foundation()
    city.queue_free()
    _report(checks)
func all_types(city: Node) -> bool:
    for kind in ["jardim","praca","poco","quartel","mercado","estrada"]:
        if not city.BUILD_TYPES.has(kind):
            return false
    return true
func _report(checks: Dictionary) -> void:
    var passed := 0
    for value in checks.values():
        if bool(value):
            passed += 1
    print("[VALDORA_CP008_CITY6] ", JSON.stringify({"passed":passed,"total":checks.size(),"checks":checks}))
    quit(0 if passed == checks.size() else 1)
