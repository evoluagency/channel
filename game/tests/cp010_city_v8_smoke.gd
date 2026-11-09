extends SceneTree
## CP010: missão, administração, abastecimento e Valeverde com relógio injetado.
const CONTRACT = preload("res://scripts/updates/update_contract.gd")

func _initialize() -> void:
    call_deferred("_run")

func _build(city: Node, kind: String, at: Vector2i) -> void:
    city._select_type(kind)
    city._try_build(at)

func _run() -> void:
    var checks: Dictionary = {}
    var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/manifest.json"))
    var module: Dictionary = {}
    for item in manifest.get("modules", []):
        if str(item.get("id", "")) == "city":
            module = item
    var packed_path := "res://tests/fixtures/city-8.zip"
    checks["manifest_9"] = int(manifest.get("revision", 0)) == 9
    checks["module_8"] = int(module.get("version", 0)) == 8
    checks["signed"] = CONTRACT.verify_file(module, packed_path)
    checks["mounted"] = ProjectSettings.load_resource_pack(ProjectSettings.globalize_path(packed_path), false)
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
    var legacy := {"schema_version":1, "name":"Auren", "resources":{"madeira":180, "pedra":140}, "buildings":[], "revision":0}
    checks["legacy_save_valid"] = city._valid_city(legacy)
    checks["save_path"] = city.SAVE_PATH == "user://valdora_city_cp005_v1.json"
    checks["schema_unchanged"] = city.SCHEMA == 1
    checks["civic_ui"] = city.civic_overlay != null and city.civic_scroll_content != null
    checks["civic_hidden"] = not city.civic_overlay.visible
    city._open_civic()
    checks["civic_open"] = city.civic_overlay.visible
    city._close_civic()
    checks["civic_close"] = not city.civic_overlay.visible

    city.city = city._new_city()
    checks["optional_fields_init"] = city._valid_city(city.city) and city.city["claimed_missions"].size() == 0 and not city.city["npc_discovered"]
    var bad := city.city.duplicate(true)
    bad["claimed_missions"] = ["unknown"]
    checks["reject_bad_mission"] = not city._valid_city(bad)
    bad = city.city.duplicate(true)
    bad["claimed_missions"] = ["fundacao", "fundacao"]
    checks["reject_duplicate_mission"] = not city._valid_city(bad)
    bad = city.city.duplicate(true)
    bad["npc_relation"] = 101
    checks["reject_relation"] = not city._valid_city(bad)
    bad = city.city.duplicate(true)
    bad["food_shortage_cycles"] = -1
    checks["reject_negative_shortage"] = not city._valid_city(bad)
    city.city["name"] = "Nova Auren"
    checks["not_discovered_early"] = not city._discover_neighbor()
    _build(city,"fundacao",Vector2i(5,5))
    _build(city,"casa",Vector2i(6,5))
    checks["named_and_housed"] = city._has_foundation() and city._has_kind("casa") and city._city_population() == 6
    checks["upkeep"] = city._food_upkeep_rate() == 2
    checks["mission_eligible"] = city._mission_ready("fundacao") and city._mission_ready("abrigo")
    checks["mission_claim"] = city._claim_mission("fundacao")
    var reward_resources: Dictionary = city.city["resources"].duplicate(true)
    checks["mission_once"] = not city._claim_mission("fundacao") and city.city["resources"] == reward_resources
    checks["mission_persisted"] = "fundacao" in city._read_save(city.SAVE_PATH).get("claimed_missions", [])
    _build(city,"fazenda",Vector2i(8,7))
    _build(city,"serraria",Vector2i(2,5))
    _build(city,"pedreira",Vector2i(10,1))
    checks["production_unchanged"] = int(city._production_rates()["madeira"]) == 8 and int(city._production_rates()["pedra"]) == 5 and int(city._production_rates()["alimentos"]) == 10
    var origin := 1700000000
    city.city["last_collection_unix"] = origin
    var estimate: Dictionary = city._production_estimate(origin + 1800)
    checks["3_cycles"] = int(estimate["cycles"]) == 3 and int(estimate["gains"]["alimentos"]) == 30
    var before_food := int(city.city["resources"].get("alimentos", 0))
    checks["collect_with_upkeep"] = city._collect_production_at(origin + 1800)
    checks["food_consumed"] = int(city.city["resources"]["alimentos"]) == before_food + 30 - 6
    checks["no_double_collection"] = not city._collect_production_at(origin + 1800)
    checks["idle_cap"] = int(city._production_estimate(origin + 100000)["cycles"]) == city.MAX_IDLE_CYCLES
    _build(city,"poco",Vector2i(5,6))
    _build(city,"praca",Vector2i(6,6))
    _build(city,"mercado",Vector2i(5,4))
    var services: Dictionary = city._services_report()
    checks["service_coverage"] = int(services["service_coverage"]) > 0 and int(services["population"]) == 6
    checks["service_quest"] = city._mission_ready("servicos")
    checks["discover"] = city._discover_neighbor() and bool(city.city["npc_discovered"])
    checks["discover_once"] = not city._discover_neighbor()
    checks["npc_mission"] = city._mission_ready("vizinhanca")
    var trade_at := 1700002000
    checks["trade_food"] = city._trade_neighbor("food", trade_at)
    checks["trade_cooldown"] = not city._trade_neighbor("food", trade_at)
    checks["relation"] = int(city.city["npc_relation"]) == 5 and int(city.city["npc_trades"]) == 1
    checks["trade_mission"] = city._mission_ready("intercambio")
    checks["trade_persisted"] = int(city._read_save(city.SAVE_PATH).get("npc_trades", 0)) == 1
    checks["unknown_offer_rejected"] = not city._trade_neighbor("bogus", trade_at + 900)
    checks["not_able_clock_backwards"] = not city._trade_neighbor("food", trade_at - 60)
    # Sem fazenda, com moradores e serraria: coleta usa alimento guardado e nunca cria saldo negativo.
    var no_farm: Array = []
    for item in city.city["buildings"]:
        if str(item["type"]) != "fazenda":
            no_farm.append(item)
    city.city["buildings"] = no_farm
    city.city["resources"]["alimentos"] = 0
    city.city["last_collection_unix"] = origin
    checks["food_shortage_collected"] = city._collect_production_at(origin + 600)
    checks["food_shortage_nonnegative"] = int(city.city["resources"]["alimentos"]) == 0 and int(city.city["food_shortage_cycles"]) >= 1
    checks["shortage_save"] = int(city._read_save(city.SAVE_PATH).get("food_shortage_cycles", 0)) >= 1
    checks["still_no_double"] = not city._collect_production_at(origin + 600)
    checks["city_state_valid"] = city._valid_city(city.city)
    city.queue_free()
    _report(checks)

func _report(checks: Dictionary) -> void:
    var count := 0
    for result in checks.values():
        if bool(result):
            count += 1
    print("[VALDORA_CP010_CITY8] ", JSON.stringify({"success":count == checks.size(),"passed":count,"total":checks.size(),"checks":checks}))
    quit(0 if count == checks.size() else 1)
