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
    var arena_panel: Control = game.get("combat_panel") as Control
    results["arena_built"] = arena_panel != null and is_instance_valid(arena_panel)
    results["arena_has_subviewport"] = arena_panel != null and (arena_panel.get("viewport_3d") as SubViewport) != null
    game.call("_open_combat")
    results["arena_opens"] = arena_panel != null and arena_panel.visible
    results["arena_pauses_world"] = bool(game.get("game_paused_for_dialogue"))
    var combat_initial: Dictionary = arena_panel.get("battle_state") if arena_panel != null else {}
    results["arena_battle_active"] = str(combat_initial.get("status", "")) == "active"
    var combat_start_round: int = int(combat_initial.get("round", -1))
    var round_ok: bool = arena_panel.take_turn("manual") if arena_panel != null else false
    var combat_advanced: Dictionary = arena_panel.get("battle_state") if arena_panel != null else {}
    results["arena_manual_turn"] = round_ok and int(combat_advanced.get("round", -1)) == combat_start_round + 1
    results["arena_animates_events"] = bool(arena_panel.get("animating")) if arena_panel != null else false
    results["arena_blocks_multiple_taps"] = not bool(arena_panel.take_turn("auto")) if arena_panel != null else false
    game.call("_close_combat")
    results["arena_closes"] = arena_panel != null and not arena_panel.visible
    results["world_unpaused_after_arena"] = not bool(game.get("game_paused_for_dialogue"))
    results["economy_intact_after_combat"] = int(game.get("coins")) >= 0 and int(game.get("bank_coins")) >= 0
    game.call("_run_diagnostics")
    var passed := 0
    for key in results.keys():
        if results[key]:
            passed += 1
    var ok := passed == results.size()
    print("[CHANNEL_ENGINE_SMOKE] ", JSON.stringify({"ok": ok, "passed": passed, "total": results.size(), "checks": results}))
    quit(0 if ok else 1)