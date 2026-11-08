extends SceneTree
## CP006 Cidade v2: valida evolução, vias, personalização e preservação do save.
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var checks: Dictionary = {}
    var path := "res://tests/fixtures/city-2.zip"
    checks["zip_mounted"] = ProjectSettings.load_resource_pack(ProjectSettings.globalize_path(path), false)
    var scene = ResourceLoader.load("res://valdora_modules/city/entry.tscn")
    checks["scene_loaded"] = scene is PackedScene
    if not checks["scene_loaded"]:
        print("[VALDORA_CITY_V2] ", JSON.stringify(checks))
        quit(1)
        return
    var obj: Control = scene.instantiate()
    root.add_child(obj)
    obj.city = obj._new_city()
    obj.city["name"] = "Cidade Exemplo"
    obj._select_type("fundacao")
    obj._try_build(Vector2i(5, 4))
    checks["foundation"] = obj.city["buildings"].size() == 1
    obj._select_type("casa")
    obj._try_build(Vector2i(6, 4))
    checks["house"] = obj.city["buildings"].size() == 2
    obj._select_type("estrada")
    obj._try_build(Vector2i(5, 5))
    checks["road"] = obj.city["buildings"].size() == 3 and obj._at(Vector2i(5, 5)).get("type") == "estrada"
    obj._select_type("melhorar")
    obj._upgrade_building(Vector2i(6, 4))
    checks["upgrade"] = int(obj._at(Vector2i(6, 4)).get("level", 1)) == 2
    obj._select_type("mover")
    obj._move_selection(Vector2i(6, 4))
    obj._move_selection(Vector2i(7, 4))
    checks["moved"] = obj._at(Vector2i(6, 4)).is_empty() and int(obj._at(Vector2i(7, 4)).get("level", 1)) == 2
    checks["saved"] = obj._read_save(obj.SAVE_PATH).get("name") == "Cidade Exemplo"
    checks["old_save_supported"] = obj._valid_city({"schema_version":1,"name":"Antiga","revision":1,"resources":{"madeira":180,"pedra":140},"buildings":[{"type":"fundacao","x":5,"y":4}]})
    checks["legacy_save_isolated"] = obj.SAVE_PATH != "user://channel_save.json"
    var count := 0
    for k in checks:
        if checks[k]:
            count += 1
    print("[VALDORA_CITY_V2] ", JSON.stringify({"passed":count,"total":checks.size(),"checks":checks}))
    obj.free()
    quit(0 if count == checks.size() else 1)
