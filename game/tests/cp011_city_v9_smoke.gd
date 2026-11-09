extends SceneTree
## CP011: região e primeira formação de estado offline, sem compartilhar dados do jogador.
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
    var archive := "res://tests/fixtures/city-9.zip"
    checks["manifest_v10"] = int(manifest.get("revision", 0)) == 10
    checks["module_v9"] = int(item.get("version", 0)) == 9
    checks["signed"] = CONTRACT.verify_file(item, archive)
    checks["mounted"] = ProjectSettings.load_resource_pack(ProjectSettings.globalize_path(archive), false)
    if not checks["mounted"]:
        _report(checks)
        return
    var resource = load("res://valdora_modules/city/entry.tscn")
    checks["scene_loaded"] = resource is PackedScene
    if not checks["scene_loaded"]:
        _report(checks)
        return
    var game = resource.instantiate()
    root.add_child(game)
    await process_frame
    game._cancel_name()
    checks["same_save_path"] = game.SAVE_PATH == "user://valdora_city_cp005_v1.json"
    checks["same_schema"] = game.SCHEMA == 1
    var old := {"schema_version":1, "name":"Nova Auren", "resources":{"madeira":180, "pedra":140}, "buildings":[], "revision":0}
    checks["legacy_save_valid"] = game._valid_city(old)
    game.city = game._new_city()
    game.city["name"] = "Nova Auren"
    game.city["resources"] = {"madeira":1000,"pedra":1000,"alimentos":1000}
    game.city["buildings"] = [
        {"type":"fundacao","x":5,"y":5,"level":1},
        {"type":"casa","x":6,"y":5,"level":1},
        {"type":"mercado","x":5,"y":4,"level":1},
        {"type":"poco","x":5,"y":6,"level":1},
        {"type":"torre","x":6,"y":6,"level":1}
    ]
    checks["initial_state_valid"] = game._valid_city(game.city)
    checks["four_npcs"] = game.REGION_IDS.size() == 4 and game._region_towns().size() == 4
    checks["no_state_early"] = not game._found_state() and not bool(game.city["state_founded"])
    checks["cannot_scout_before_vale"] = not game._scout_region("pedralta")
    checks["discover_vale"] = game._discover_neighbor() and "valeverde" in game.city["regional_discoveries"]
    checks["cant_pact_without_trade"] = not game._sign_regional_pact("valeverde")
    checks["cant_scout_before_trade"] = not game._scout_region("ribeirinha")
    checks["first_trade"] = game._trade_neighbor("food", 1700002000)
    checks["trade_persisted"] = game.city["npc_trades"] == 1 and game.city["npc_relation"] == 5
    checks["valeverde_pact"] = game._sign_regional_pact("valeverde")
    var before: Dictionary = game.snapshot_for_test()
    checks["no_duplicate_pact"] = not game._sign_regional_pact("valeverde") and game.snapshot_for_test() == before
    checks["unknown_scout_rejected"] = not game._scout_region("outroservidor")
    checks["unknown_pact_rejected"] = not game._sign_regional_pact("outroservidor")
    checks["scout_pedralta"] = game._scout_region("pedralta")
    checks["scout_ribeirinha"] = game._scout_region("ribeirinha")
    checks["scout_montesol"] = game._scout_region("montesol")
    checks["no_duplicate_scout"] = not game._scout_region("pedralta")
    checks["map_first_mission"] = game._mission_ready("fronteiras")
    checks["pact_pedralta"] = game._sign_regional_pact("pedralta")
    checks["second_pact_quest"] = game._mission_ready("tratados")
    checks["pact_ribeirinha"] = game._sign_regional_pact("ribeirinha")
    checks["pact_montesol"] = game._sign_regional_pact("montesol")
    checks["regional_five_cities"] = game._regional_status()["members"] == 5
    checks["regional_unique"] = game.city["regional_pacts"].size() == 4 and game.city["regional_discoveries"].size() == 4
    checks["state_requirements"] = game._state_requirements_met()
    checks["found_state"] = game._found_state()
    checks["governor_name"] = game.city["state_name"] == "Estado de Nova Auren"
    checks["no_second_foundation"] = not game._found_state()
    checks["state_quest"] = game._mission_ready("primeiro_estado")
    checks["state_saved"] = bool(game._read_save(game.SAVE_PATH).get("state_founded",false))
    checks["missions_claimed_once"] = game._claim_mission("fronteiras") and not game._claim_mission("fronteiras")
    var bad = game.city.duplicate(true)
    bad["regional_discoveries"].append("invalido")
    checks["reject_invalid_region"] = not game._valid_city(bad)
    bad = game.city.duplicate(true)
    bad["regional_pacts"].append("valeverde")
    checks["reject_duplicate_pact"] = not game._valid_city(bad)
    bad = game.city.duplicate(true)
    bad["state_name"] = ""
    checks["reject_unnamed_state"] = not game._valid_city(bad)
    bad = game.city.duplicate(true)
    bad["regional_pacts"] = []
    checks["reject_forged_state"] = not game._valid_city(bad)
    checks["final_save_valid"] = game._valid_city(game.city)
    game.queue_free()
    _report(checks)

func _report(checks: Dictionary) -> void:
    var passed := 0
    for key in checks:
        if bool(checks[key]):
            passed += 1
    var success := passed == checks.size()
    print("[VALDORA_CP011_CITY9] ", JSON.stringify({"success":success,"passed":passed,"total":checks.size(),"checks":checks}))
    quit(0 if success else 1)
