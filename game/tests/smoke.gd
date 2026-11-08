extends SceneTree
## Executa o mundo no motor real, sem alterar o saldo salvo.
## godot --headless --path . --script res://tests/smoke.gd

func _initialize() -> void:
    call_deferred("_run_smoke")

func _run_smoke() -> void:
    var packed := load("res://scenes/Main.tscn") as PackedScene
    if packed == null:
        printerr("CHANNEL SMOKE: cena principal inexistente")
        quit(1)
        return
    var game: Node = packed.instantiate()
    root.add_child(game)
    await process_frame
    var results: Dictionary = {}
    var player := game.get("player") as CharacterBody3D
    var camera := game.get("camera") as Camera3D
    var npcs := game.get("npcs") as Array
    results["scene_ready"] = game.is_inside_tree()
    results["character_created"] = player != null and is_instance_valid(player)
    results["camera_created"] = camera != null and camera.current
    results["four_npcs"] = npcs.size() == 4
    results["spawn_in_valdora"] = player != null and player.position.distance_to(Vector3(0, 0.2, 15)) < 1.5
    results["money_nonnegative"] = int(game.get("coins")) >= 0 and int(game.get("bank_coins")) >= 0

    if player != null:
        # Teleporte temporario no teste; nenhuma gravacao no progresso.
        player.global_position = Vector3(19, 0.2, -1)
        game.call("_interact")
        var dialogue := game.get("dialogue_layer") as PanelContainer
        results["merchant_dialogue"] = dialogue != null and dialogue.visible
        game.call("_close_dialogue")
        player.global_position = Vector3(27, 0.2, 4)
        game.call("_interact")
        results["bank_dialogue"] = dialogue != null and dialogue.visible
        game.call("_close_dialogue")
    else:
        results["merchant_dialogue"] = false
        results["bank_dialogue"] = false
    var hero_panel: Control = game.get("hero_panel") as Control
    results["hero_panel_built"] = hero_panel != null and is_instance_valid(hero_panel)
    game.call("_open_heroes")
    results["hero_panel_open"] = hero_panel != null and hero_panel.visible
    game.call("_close_heroes")
    results["hero_panel_close"] = hero_panel != null and not hero_panel.visible
    game.call("_run_diagnostics")
    var passed := 0
    for key in results.keys():
        if results[key]:
            passed += 1
    var ok := passed == results.size()
    print("[CHANNEL_ENGINE_SMOKE] ", JSON.stringify({"ok": ok, "passed": passed, "total": results.size(), "checks": results}))
    quit(0 if ok else 1)