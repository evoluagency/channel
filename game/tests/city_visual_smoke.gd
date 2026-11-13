extends SceneTree
## Cidade na direção visual v1: barra superior fixa, sem texto de versão no mapa, fontes do módulo,
## alvos de toque e regras/save intactos. Usa o ZIP sem assinatura montado por tools/build_city_zip.py
## (tools/run_valdora_tests.sh o coloca em res://tests/fixtures/city_visual_trabalho.zip).

func _initialize() -> void:
    call_deferred("_run")

func _line_heights(node: Node, out: Array) -> void:
    for child in node.get_children():
        if child is Label and (child as Label).is_visible_in_tree():
            out.append(child)
        _line_heights(child, out)

func _run() -> void:
    var checks: Dictionary = {}
    var archive := ProjectSettings.globalize_path("res://tests/fixtures/city_visual_trabalho.zip")
    checks["zip_present"] = FileAccess.file_exists(archive)
    checks["mounted"] = checks["zip_present"] and ProjectSettings.load_resource_pack(archive, false)
    if not checks["mounted"]:
        _report(checks)
        return
    checks["fonts_in_module"] = FileAccess.file_exists("res://valdora_modules/city/fonts/Cinzel.ttf") and FileAccess.file_exists("res://valdora_modules/city/fonts/Montserrat.ttf")
    checks["licenses_in_module"] = FileAccess.file_exists("res://valdora_modules/city/fonts/OFL-Cinzel.txt") and FileAccess.file_exists("res://valdora_modules/city/fonts/OFL-Montserrat.txt")
    var resource = load("res://valdora_modules/city/entry.tscn")
    checks["scene_loaded"] = resource is PackedScene
    if not checks["scene_loaded"]:
        _report(checks)
        return
    var source := FileAccess.get_file_as_string("res://valdora_modules/city/city.gd")
    checks["no_version_text_in_map"] = not source.contains("CIDADE · v") and not source.contains("TERRITÓRIOS · CIDADE v")
    checks["no_core_dependency"] = not source.contains("res://scripts/") and not source.contains("preload(")
    var game = resource.instantiate()
    root.add_child(game)
    await process_frame
    game._cancel_name()
    checks["same_save_path"] = game.SAVE_PATH == "user://valdora_city_cp005_v1.json" and game.SCHEMA == 1
    checks["fonts_loaded"] = game.font_titulo is FontVariation and game.font_corpo is FontVariation \
        and (game.font_titulo.base_font as FontFile).data.size() > 10000 and (game.font_corpo.base_font as FontFile).data.size() > 10000
    checks["legacy_save_valid"] = game._valid_city({"schema_version":1,"name":"Nova Auren","resources":{"madeira":180,"pedra":140},"buildings":[],"revision":0})

    game.city = game._new_city()
    game.city["name"] = "Nova Auren Muito Longa 24"
    game.city["resources"] = {"madeira":999999,"pedra":999999,"alimentos":999999}
    game._refresh_ui()
    var sizes: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(960, 540), Vector2i(1600, 720)]
    var all_fixed := true
    var all_one_line := true
    var map_clear := true
    for sz in sizes:
        root.size = sz
        game.size = Vector2(sz)
        for i in 3:
            await process_frame
        var top: PanelContainer = game.title_label.get_parent().get_parent()
        if not is_equal_approx(top.size.y, 60.0):
            all_fixed = false
        var labels: Array = []
        _line_heights(top, labels)
        for l in labels:
            if (l as Label).autowrap_mode != TextServer.AUTOWRAP_OFF or (l as Label).size.y > 56.0:
                all_one_line = false
        # a barra termina antes de y=68 e antes do painel lateral (y=85): nada escurece o mapa abaixo disso
        if top.position.y + top.size.y > 70.0:
            map_clear = false
    checks["top_bar_60px_all_sizes"] = all_fixed
    checks["top_labels_single_line"] = all_one_line
    checks["top_bar_does_not_grow"] = map_clear
    checks["four_resource_pills"] = game.resource_pills.size() == 4 and str(game.resource_pills["madeira"].text).begins_with("MADEIRA ") and str(game.resource_pills["pop"].text).begins_with("POP.")
    checks["title_is_city_name_only"] = game.title_label.text == "Nova Auren Muito Longa 24"

    var touch_ok := true
    for key in game.build_buttons:
        if (game.build_buttons[key] as Button).custom_minimum_size.y < 48.0:
            touch_ok = false
    checks["touch_targets_48"] = touch_ok
    checks["panel_radius_18"] = (game._style("#10183a") as StyleBoxFlat).corner_radius_top_left == 18
    var min_font := 99
    var all_labels: Array = []
    _line_heights(game, all_labels)
    for l in all_labels:
        var fs: int = (l as Label).get_theme_font_size("font_size")
        if fs > 0 and fs < min_font:
            min_font = fs
    checks["min_font_14"] = min_font >= 14

    # Regras: mesmo fluxo de construção da v9.
    game.city = game._new_city()
    game.city["name"] = "Nova Auren"
    game.city["resources"] = {"madeira":1000,"pedra":1000,"alimentos":1000}
    game._refresh_ui()
    game.selected_type = "fundacao"
    game._try_build(Vector2i(5, 5))
    game.selected_type = "casa"
    game._try_build(Vector2i(6, 5))
    checks["rules_unchanged_build"] = game._at(Vector2i(5, 5)).get("type", "") == "fundacao" and game._at(Vector2i(6, 5)).get("type", "") == "casa"
    checks["costs_unchanged"] = game.COSTS["casa"] == {"madeira":25,"pedra":10} and game.COSTS["mercado"] == {"madeira":35,"pedra":20}
    checks["save_valid"] = game._valid_city(game.snapshot_for_test())
    game.queue_redraw()
    await process_frame
    checks["draw_ok"] = true
    _report(checks)

func _report(checks: Dictionary) -> void:
    var failed: Array[String] = []
    for key in checks:
        if not bool(checks[key]):
            failed.append(str(key))
    print("CITY_VISUAL_SMOKE %d/%d falhas=%s" % [checks.size() - failed.size(), checks.size(), failed])
    quit(0 if failed.is_empty() else 1)
