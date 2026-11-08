extends Control
## Valdora CP005 - primeira cidade modular independente. Sem conexão com saldo legado.
## Cena carregada por ZIP OTA assinado; somente user://valdora_city_cp005_v1.json é gravado.

const SAVE_PATH := "user://valdora_city_cp005_v1.json"
const SCHEMA := 1
const W := 12
const H := 10
const HALF_W := 40.0
const HALF_H := 21.0
const BUILD_TYPES := ["fundacao", "casa", "fazenda", "serraria", "pedreira", "torre"]
const LABELS := {"fundacao": "Fundar", "casa": "Casa", "fazenda": "Fazenda", "serraria": "Serraria", "pedreira": "Pedreira", "torre": "Torre"}
const COSTS := {
    "fundacao": {"madeira": 0, "pedra": 0},
    "casa": {"madeira": 25, "pedra": 10},
    "fazenda": {"madeira": 15, "pedra": 5},
    "serraria": {"madeira": 15, "pedra": 15},
    "pedreira": {"madeira": 20, "pedra": 15},
    "torre": {"madeira": 30, "pedra": 40}
}
const TERRITORIES := ["Centro urbano", "Campos férteis", "Bosque de madeira", "Pedreira", "Rio e doca", "Ruínas antigas", "Mina de ferro", "Torre de vigia"]

var city: Dictionary = {}
var selected_type := "fundacao"
var selected_tile := Vector2i(-1, -1)
var zoom := 0.93
var map_origin := Vector2(493, 147)
var dragging := false
var dragging_touch := false
var press_position := Vector2.ZERO
var last_position := Vector2.ZERO
var pan_distance := 0.0
var title_label: Label
var resource_label: Label
var status_label: Label
var selected_label: Label
var territory_label: Label
var editor: ConfirmationDialog
var editor_input: LineEdit

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    _load_city()
    _create_ui()
    queue_redraw()
    if str(city.get("name", "")).is_empty():
        call_deferred("_ask_name")

func _new_city() -> Dictionary:
    return {"schema_version": SCHEMA, "name": "", "resources": {"madeira": 180, "pedra": 140}, "buildings": [], "revision": 0}

func _valid_city(value: Variant) -> bool:
    if typeof(value) != TYPE_DICTIONARY:
        return false
    var data: Dictionary = value
    if data.get("schema_version") != SCHEMA or typeof(data.get("name")) != TYPE_STRING:
        return false
    if str(data["name"]).length() > 24 or typeof(data.get("revision")) != TYPE_INT:
        return false
    var resources = data.get("resources")
    if typeof(resources) != TYPE_DICTIONARY:
        return false
    for key in ["madeira", "pedra"]:
        if typeof(resources.get(key)) != TYPE_INT or int(resources[key]) < 0 or int(resources[key]) > 999999:
            return false
    var all_buildings = data.get("buildings")
    if typeof(all_buildings) != TYPE_ARRAY or all_buildings.size() > W * H:
        return false
    var occupied: Dictionary = {}
    var foundations := 0
    for raw in all_buildings:
        if typeof(raw) != TYPE_DICTIONARY:
            return false
        var item: Dictionary = raw
        var kind := str(item.get("type", ""))
        if not BUILD_TYPES.has(kind) or typeof(item.get("x")) != TYPE_INT or typeof(item.get("y")) != TYPE_INT:
            return false
        var x: int = item["x"]
        var y: int = item["y"]
        if not _in_bounds(Vector2i(x, y)) or _terrain(x, y) == "agua":
            return false
        var unique := "%d:%d" % [x, y]
        if occupied.has(unique):
            return false
        occupied[unique] = true
        if kind == "fundacao":
            foundations += 1
    return foundations <= 1

func _read_save(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null or file.get_length() > 32768:
        return {}
    var content := file.get_as_text()
    file.close()
    var parsed = JSON.parse_string(content)
    return parsed if _valid_city(parsed) else {}

func _load_city() -> void:
    city = _read_save(SAVE_PATH)
    if city.is_empty():
        city = _read_save(SAVE_PATH + ".bak")
    if city.is_empty():
        city = _new_city()

func _write_save(data: Dictionary) -> bool:
    if not _valid_city(data):
        return false
    var temp := SAVE_PATH + ".tmp"
    var output := FileAccess.open(temp, FileAccess.WRITE)
    if output == null:
        return false
    output.store_string(JSON.stringify(data))
    output.flush()
    output.close()
    if _read_save(temp).is_empty():
        return false
    var previous := _read_save(SAVE_PATH)
    if not previous.is_empty():
        var backup := FileAccess.open(SAVE_PATH + ".bak.tmp", FileAccess.WRITE)
        if backup == null:
            return false
        backup.store_string(JSON.stringify(previous))
        backup.flush()
        backup.close()
        if DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_PATH + ".bak.tmp"), ProjectSettings.globalize_path(SAVE_PATH + ".bak")) != OK:
            return false
    return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(SAVE_PATH)) == OK

func _style(hex: String) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = Color(hex)
    s.corner_radius_top_left = 12
    s.corner_radius_top_right = 12
    s.corner_radius_bottom_left = 12
    s.corner_radius_bottom_right = 12
    s.border_color = Color("#7b9eae")
    s.border_width_left = 1
    s.border_width_top = 1
    s.border_width_right = 1
    s.border_width_bottom = 1
    s.content_margin_left = 13
    s.content_margin_right = 13
    s.content_margin_top = 8
    s.content_margin_bottom = 8
    return s

func _label(text_value: String, font_size: int = 18, color := Color("#f4f5e4")) -> Label:
    var l := Label.new()
    l.text = text_value
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", color)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return l

func _button(text_value: String, action: Callable) -> Button:
    var b := Button.new()
    b.text = text_value
    b.custom_minimum_size = Vector2(109, 48)
    b.add_theme_font_size_override("font_size", 17)
    b.pressed.connect(action)
    return b

func _create_ui() -> void:
    var top := PanelContainer.new()
    top.add_theme_stylebox_override("panel", _style("#102a40eb"))
    top.set_anchors_preset(Control.PRESET_TOP_WIDE)
    top.offset_left = 10
    top.offset_right = -224 # reservado para o FECHAR MÓDULO do aplicativo-base
    top.offset_top = 8
    top.offset_bottom = 68
    add_child(top)
    var head := HBoxContainer.new()
    head.add_theme_constant_override("separation", 18)
    top.add_child(head)
    title_label = _label("VALDORA · CIDADE", 24, Color("#ffe5a6"))
    title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    head.add_child(title_label)
    resource_label = _label("", 18)
    head.add_child(resource_label)

    var side := PanelContainer.new()
    side.add_theme_stylebox_override("panel", _style("#142c42ef"))
    side.anchor_left = 1.0
    side.anchor_right = 1.0
    side.anchor_top = 0.0
    side.anchor_bottom = 1.0
    side.offset_left = -315
    side.offset_right = -12
    side.offset_top = 85
    side.offset_bottom = -102
    add_child(side)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 10)
    side.add_child(column)
    column.add_child(_label("TERRITÓRIOS DA CIDADE", 21, Color("#ffd986")))
    var rename := _button("EDITAR NOME", Callable(self, "_ask_name"))
    rename.custom_minimum_size = Vector2(0, 42)
    column.add_child(rename)
    selected_label = _label("Selecione uma construção e toque no terreno.", 17)
    column.add_child(selected_label)
    column.add_child(_label("Zonas existentes", 17, Color("#ffd986")))
    territory_label = _label("", 15)
    territory_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_child(territory_label)
    status_label = _label("", 16, Color("#e2e6b8"))
    column.add_child(status_label)

    var bottom := PanelContainer.new()
    bottom.add_theme_stylebox_override("panel", _style("#142c42f2"))
    bottom.anchor_left = 0.0
    bottom.anchor_right = 1.0
    bottom.anchor_top = 1.0
    bottom.anchor_bottom = 1.0
    bottom.offset_left = 10
    bottom.offset_right = -315
    bottom.offset_top = -92
    bottom.offset_bottom = -8
    add_child(bottom)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 7)
    bottom.add_child(row)
    for kind in BUILD_TYPES:
        row.add_child(_button(str(LABELS[kind]), Callable(self, "_select_type").bind(kind)))
    var plus := _button("ZOOM +", Callable(self, "_change_zoom").bind(0.10))
    plus.custom_minimum_size = Vector2(80, 48)
    row.add_child(plus)
    var minus := _button("ZOOM -", Callable(self, "_change_zoom").bind(-0.10))
    minus.custom_minimum_size = Vector2(80, 48)
    row.add_child(minus)

    editor = ConfirmationDialog.new()
    editor.title = "Nomear cidade de Valdora"
    editor.ok_button_text = "SALVAR NOME"
    editor.confirmed.connect(_save_name)
    add_child(editor)
    var wrap := VBoxContainer.new()
    editor.add_child(wrap)
    wrap.add_child(_label("Dê um nome à sua cidade (3 a 24 caracteres).", 16))
    editor_input = LineEdit.new()
    editor_input.max_length = 24
    editor_input.custom_minimum_size = Vector2(320, 45)
    wrap.add_child(editor_input)
    _refresh_ui()

func _refresh_ui() -> void:
    title_label.text = "VALDORA · " + (str(city["name"]) if not str(city["name"]).is_empty() else "CIDADE SEM NOME")
    resource_label.text = "Madeira: %d   Pedra: %d" % [int(city["resources"]["madeira"]), int(city["resources"]["pedra"])]
    var cost: Dictionary = COSTS[selected_type]
    selected_label.text = "Construção: %s\nCusto: %d madeira / %d pedra" % [LABELS[selected_type], cost["madeira"], cost["pedra"]]
    var region_name := _territory(selected_tile.x, selected_tile.y) if _in_bounds(selected_tile) else "Toque num lote"
    territory_label.text = "Área: %s\n\n%s\n\nMapa local: %d x %d lotes\nEdifícios: %d\n\nArraste para mover.\nUse ZOOM para aproximar." % [region_name, "\n".join(TERRITORIES), W, H, city["buildings"].size()]

func _set_status(message: String) -> void:
    status_label.text = message

func _ask_name() -> void:
    editor_input.text = str(city["name"])
    editor.popup_centered()
    editor_input.grab_focus()

func _save_name() -> void:
    var clean := editor_input.text.strip_edges().replace("\n", "").replace("\r", "")
    if clean.length() < 3 or clean.length() > 24:
        _set_status("Nome inválido: use de 3 a 24 caracteres.")
        return
    var next: Dictionary = city.duplicate(true)
    next["name"] = clean
    next["revision"] = int(next["revision"]) + 1
    if _write_save(next):
        city = next
        _set_status("Cidade nomeada e salva no dispositivo.")
        _refresh_ui()
    else:
        _set_status("Falha ao salvar nome; dados anteriores preservados.")

func _select_type(kind: String) -> void:
    if BUILD_TYPES.has(kind):
        selected_type = kind
        _refresh_ui()
        _set_status("Toque em um lote livre para construir.")

func _change_zoom(diff: float) -> void:
    zoom = clampf(zoom + diff, 0.67, 1.35)
    queue_redraw()

func _in_bounds(tile: Vector2i) -> bool:
    return tile.x >= 0 and tile.y >= 0 and tile.x < W and tile.y < H

func _terrain(x: int, y: int) -> String:
    if x <= 1 and y >= 7:
        return "agua"
    if x >= 9 and y <= 2:
        return "rocha"
    if x <= 2 and y <= 3:
        return "ruinas"
    if x <= 3 and y >= 5:
        return "floresta"
    if x >= 7 and y >= 6:
        return "campo"
    return "grama"

func _territory(x: int, y: int) -> String:
    if not _in_bounds(Vector2i(x, y)):
        return "Fora do mapa"
    match _terrain(x, y):
        "agua": return "Rio e doca"
        "rocha": return "Pedreira / mina de ferro"
        "ruinas": return "Ruínas antigas"
        "floresta": return "Bosque de madeira"
        "campo": return "Campos férteis"
    if x > 7 and y > 3:
        return "Torre de vigia"
    if x < 4:
        return "Vila artesã"
    return "Centro urbano"

func _iso(x: float, y: float) -> Vector2:
    return map_origin + Vector2((x - y) * HALF_W, (x + y) * HALF_H) * zoom

func _uniso(point: Vector2) -> Vector2i:
    var local := (point - map_origin) / zoom
    var u := local.x / HALF_W
    var v := local.y / HALF_H
    return Vector2i(roundi((u + v) / 2.0), roundi((v - u) / 2.0))

func _on_plot_clicked(pos: Vector2) -> void:
    var tile := _uniso(pos)
    if not _in_bounds(tile):
        return
    selected_tile = tile
    var current := _at(tile)
    if not current.is_empty():
        _set_status("Lote ocupado: %s. Não será substituído." % str(LABELS[current["type"]]))
    else:
        _try_build(tile)
    _refresh_ui()
    queue_redraw()

func _at(tile: Vector2i) -> Dictionary:
    for item in city["buildings"]:
        if int(item["x"]) == tile.x and int(item["y"]) == tile.y:
            return item
    return {}

func _has_foundation() -> bool:
    for item in city["buildings"]:
        if item["type"] == "fundacao":
            return true
    return false

func _try_build(tile: Vector2i) -> void:
    var ground := _terrain(tile.x, tile.y)
    if ground == "agua":
        _set_status("Rio não construível nesta versão.")
        return
    if selected_type == "fundacao" and _has_foundation():
        _set_status("A fundação já existe. Escolha outra construção.")
        return
    if selected_type != "fundacao" and not _has_foundation():
        _set_status("Construa primeiro a fundação da cidade.")
        return
    if selected_type == "fazenda" and ground != "campo":
        _set_status("Fazenda precisa de Campos Férteis.")
        return
    if selected_type == "serraria" and ground != "floresta":
        _set_status("Serraria precisa do Bosque de Madeira.")
        return
    if selected_type == "pedreira" and ground != "rocha":
        _set_status("Pedreira precisa de terreno rochoso.")
        return
    var cost: Dictionary = COSTS[selected_type]
    var next: Dictionary = city.duplicate(true)
    for key in ["madeira", "pedra"]:
        if int(next["resources"][key]) < int(cost[key]):
            _set_status("Recursos insuficientes para essa construção.")
            return
    for key in ["madeira", "pedra"]:
        next["resources"][key] = int(next["resources"][key]) - int(cost[key])
    next["buildings"].append({"type": selected_type, "x": tile.x, "y": tile.y})
    next["revision"] = int(next["revision"]) + 1
    if _write_save(next):
        city = next
        _set_status("%s construída e salva!" % LABELS[selected_type])
    else:
        _set_status("Falha ao salvar. Nenhum recurso foi consumido.")

func _map_area(pos: Vector2) -> bool:
    return pos.x >= 12.0 and pos.x < size.x - 322.0 and pos.y >= 82.0 and pos.y < size.y - 105.0

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed and _map_area(mb.position):
            _change_zoom(0.09)
            get_viewport().set_input_as_handled()
        elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed and _map_area(mb.position):
            _change_zoom(-0.09)
            get_viewport().set_input_as_handled()
        elif mb.button_index == MOUSE_BUTTON_LEFT:
            if mb.pressed and _map_area(mb.position):
                dragging = true
                press_position = mb.position
                last_position = mb.position
                pan_distance = 0.0
                get_viewport().set_input_as_handled()
            elif not mb.pressed and dragging:
                dragging = false
                if pan_distance < 12.0:
                    _on_plot_clicked(mb.position)
                get_viewport().set_input_as_handled()
    elif event is InputEventMouseMotion and dragging:
        var motion := event as InputEventMouseMotion
        var delta := motion.position - last_position
        map_origin += delta
        last_position = motion.position
        pan_distance += delta.length()
        queue_redraw()
        get_viewport().set_input_as_handled()
    elif event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed and _map_area(touch.position):
            dragging_touch = true
            press_position = touch.position
            last_position = touch.position
            pan_distance = 0.0
            get_viewport().set_input_as_handled()
        elif not touch.pressed and dragging_touch:
            dragging_touch = false
            if pan_distance < 15.0:
                _on_plot_clicked(touch.position)
            get_viewport().set_input_as_handled()
    elif event is InputEventScreenDrag and dragging_touch:
        var drag := event as InputEventScreenDrag
        var delta := drag.position - last_position
        map_origin += delta
        last_position = drag.position
        pan_distance += delta.length()
        queue_redraw()
        get_viewport().set_input_as_handled()
    elif event is InputEventMagnifyGesture:
        var gesture := event as InputEventMagnifyGesture
        if _map_area(gesture.position):
            zoom = clampf(zoom * gesture.factor, 0.67, 1.35)
            queue_redraw()
            get_viewport().set_input_as_handled()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("#9cd6e8"))
    draw_rect(Rect2(Vector2(8, 76), Vector2(maxf(50.0, size.x - 326.0), maxf(50.0, size.y - 175.0))), Color("#b4d4ac"))
    # Tiles pintados primeiro; estruturas depois, para manter a ordem isométrica.
    for y in range(H):
        for x in range(W):
            var p := _iso(float(x), float(y))
            var hw := HALF_W * zoom
            var hh := HALF_H * zoom
            var tile := PackedVector2Array([p + Vector2(0, -hh), p + Vector2(hw, 0), p + Vector2(0, hh), p + Vector2(-hw, 0)])
            var ground := _terrain(x, y)
            var c := Color("#8fbd65")
            match ground:
                "agua": c = Color("#42a8d0")
                "rocha": c = Color("#95a1a2")
                "ruinas": c = Color("#c0be87")
                "floresta": c = Color("#4c9d56")
                "campo": c = Color("#d0c96c")
            if (x + y) % 2 == 0:
                c = c.lightened(0.055)
            draw_colored_polygon(tile, c)
            draw_polyline(PackedVector2Array([tile[0], tile[1], tile[2], tile[3], tile[0]]), c.darkened(0.16), 1.0)
            if selected_tile == Vector2i(x, y):
                draw_polyline(PackedVector2Array([tile[0], tile[1], tile[2], tile[3], tile[0]]), Color("#fcea60"), 4.0)
    for depth in range(W + H - 1):
        for x in range(W):
            var y := depth - x
            if y < 0 or y >= H:
                continue
            var kind := _terrain(x, y)
            var p := _iso(float(x), float(y))
            if kind == "floresta" and _at(Vector2i(x, y)).is_empty():
                _tree(p, 0.75)
            elif kind == "rocha" and _at(Vector2i(x, y)).is_empty():
                _stone(p)
            elif kind == "ruinas" and _at(Vector2i(x, y)).is_empty() and (x + y) % 2 == 0:
                _ruin(p)
            var building := _at(Vector2i(x, y))
            if not building.is_empty():
                _draw_building(p, str(building["type"]))

func _tree(p: Vector2, scale_factor: float = 1.0) -> void:
    var h := 30.0 * zoom * scale_factor
    var q := p + Vector2(0, -9.0 * zoom)
    draw_line(q, q + Vector2(0, 13.0 * zoom), Color("#735338"), 4.0 * zoom)
    draw_colored_polygon(PackedVector2Array([q + Vector2(0, -h), q + Vector2(-13, 4) * zoom, q + Vector2(13, 4) * zoom]), Color("#317e46"))
    draw_colored_polygon(PackedVector2Array([q + Vector2(0, -h * 0.7), q + Vector2(-15, 11) * zoom, q + Vector2(15, 11) * zoom]), Color("#238354"))

func _stone(p: Vector2) -> void:
    var s := zoom
    draw_colored_polygon(PackedVector2Array([p + Vector2(-17, 3) * s, p + Vector2(-8, -15) * s, p + Vector2(11, -19) * s, p + Vector2(19, 0) * s, p + Vector2(10, 8) * s]), Color("#bac1bb"))
    draw_colored_polygon(PackedVector2Array([p + Vector2(-8, -15) * s, p + Vector2(11, -19) * s, p + Vector2(5, 1) * s]), Color("#e1dfcd"))

func _ruin(p: Vector2) -> void:
    var s := zoom
    draw_rect(Rect2(p + Vector2(-12, -25) * s, Vector2(7, 26) * s), Color("#cab98e"))
    draw_rect(Rect2(p + Vector2(7, -21) * s, Vector2(7, 21) * s), Color("#ad9b80"))
    draw_line(p + Vector2(-11, -23) * s, p + Vector2(13, -22) * s, Color("#efe2a7"), 4.0 * s)

func _draw_building(p: Vector2, kind: String) -> void:
    var s := zoom
    var w := 22.0 * s
    var h := (41.0 if kind == "fundacao" else (34.0 if kind == "torre" else 24.0)) * s
    var wall := Color("#e5d6ac")
    var roof := Color("#327fc4")
    if kind == "casa":
        roof = Color("#db8954")
    elif kind == "fazenda":
        roof = Color("#c89d42")
    elif kind == "serraria":
        roof = Color("#6b8d43")
    elif kind == "pedreira":
        wall = Color("#b6baba")
        roof = Color("#8b9b9b")
    elif kind == "torre":
        roof = Color("#3e5d99")
    draw_colored_polygon(PackedVector2Array([p + Vector2(-w, -h), p + Vector2(0, -h + 11*s), p + Vector2(0, 9*s), p + Vector2(-w, 0)]), wall.darkened(0.14))
    draw_colored_polygon(PackedVector2Array([p + Vector2(0, -h + 11*s), p + Vector2(w, -h), p + Vector2(w, 0), p + Vector2(0, 9*s)]), wall)
    draw_colored_polygon(PackedVector2Array([p + Vector2(0, -h - 18*s), p + Vector2(w+4*s, -h-1*s), p + Vector2(0, -h+13*s), p + Vector2(-w-4*s, -h-1*s)]), roof)
    draw_line(p + Vector2(0, -h - 18*s), p + Vector2(w+4*s, -h-1*s), roof.lightened(0.2), 2.5*s)
    if kind == "fundacao" or kind == "torre":
        draw_rect(Rect2(p + Vector2(-4, -h-30*s), Vector2(8, 13)*s), Color("#f7e3a2"))
        draw_line(p + Vector2(0, -h-31*s), p + Vector2(0, -h-49*s), Color("#6b6353"), 2*s)
        draw_colored_polygon(PackedVector2Array([p + Vector2(0, -h-48*s), p + Vector2(17, -h-45*s), p + Vector2(0, -h-39*s)]), Color("#386fd0"))
    if kind == "fazenda":
        draw_line(p + Vector2(-w-10*s, -3*s), p + Vector2(-w-17*s, -12*s), Color("#ad842b"), 3*s)

func snapshot_for_test() -> Dictionary:
    return city.duplicate(true)