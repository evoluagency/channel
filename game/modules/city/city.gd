extends Control
## Valdora CP011 - Cidade v9: expedições, acordos regionais e primeiro estado NPC offline.
## Cena carregada por ZIP OTA assinado; somente user://valdora_city_cp005_v1.json é gravado.

const SAVE_PATH := "user://valdora_city_cp005_v1.json"
const SCHEMA := 1
const PRODUCE_SECONDS := 600 # ciclo 10 minutos
const MAX_IDLE_CYCLES := 48 # máximo 8 horas offline por coleta
const RESOURCE_LIMIT := 999999
const TRADE_COOLDOWN := 900 # 15 minutos, mundo offline; não sincronizado com multiplayer
const MISSION_IDS := ["fundacao", "abrigo", "primeira_safra", "industria", "servicos", "vizinhanca", "intercambio", "fronteiras", "tratados", "primeiro_estado"]
const REGION_IDS := ["valeverde", "pedralta", "ribeirinha", "montesol"]
const PRODUCTIVE_TYPES := ["fazenda", "serraria", "pedreira"]
const W := 12
const H := 10
const HALF_W := 40.0
const HALF_H := 21.0
const BUILD_TYPES := ["fundacao", "casa", "fazenda", "serraria", "pedreira", "torre", "estrada", "jardim", "praca", "poco", "quartel", "mercado"]
const LABELS := {"fundacao": "Fundar", "casa": "Casa", "fazenda": "Fazenda", "serraria": "Serraria", "pedreira": "Pedreira", "torre": "Torre", "estrada": "Estrada", "jardim": "Jardim", "praca": "Praça", "poco": "Poço", "quartel": "Quartel", "mercado": "Mercado"}
const COSTS := {
    "fundacao": {"madeira": 0, "pedra": 0},
    "casa": {"madeira": 25, "pedra": 10},
    "fazenda": {"madeira": 15, "pedra": 5},
    "serraria": {"madeira": 15, "pedra": 15},
    "pedreira": {"madeira": 20, "pedra": 15},
    "torre": {"madeira": 30, "pedra": 40},
    "estrada": {"madeira": 5, "pedra": 0},
    "jardim": {"madeira": 8, "pedra": 2},
    "praca": {"madeira": 16, "pedra": 24},
    "poco": {"madeira": 10, "pedra": 15},
    "quartel": {"madeira": 45, "pedra": 55},
    "mercado": {"madeira": 35, "pedra": 20}
}
const TERRITORIES := ["Centro urbano", "Campos férteis", "Bosque de madeira", "Pedreira", "Rio e doca", "Ruínas antigas", "Mina de ferro", "Torre de vigia"]

var city: Dictionary = {}
var selected_type := "fundacao"
var build_buttons: Dictionary = {}
var objective_label: Label
var production_label: Label
var production_button: Button
var civic_overlay: ColorRect
var civic_scroll_content: VBoxContainer
var civic_map: Control
var production_ui_accumulator := 0.0
var resident_clock := 0.0
var animation_phase := 0.0
var animation_accumulator := 0.0
var show_grid := false
var dusk_mode := false
var grid_button: Button
var dusk_button: Button
var move_origin := Vector2i(-1, -1)
var selected_tile := Vector2i(-1, -1)
var zoom := 0.93
var map_origin := Vector2(450, 149)
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
var editor_overlay: ColorRect
var editor_input: LineEdit
var editor_error: Label

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    _load_city()
    _create_ui()
    queue_redraw()
    if str(city.get("name", "")).is_empty():
        call_deferred("_ask_name")

func _process(delta: float) -> void:
    # Animacao visual de baixa frequencia; zero alteracoes em economia/saves.
    if not visible:
        return
    resident_clock += minf(delta, 0.2)
    production_ui_accumulator += delta
    if production_ui_accumulator >= 4.0:
        production_ui_accumulator = 0.0
        _refresh_production_label()
    animation_accumulator += delta
    if animation_accumulator >= 0.24:
        animation_phase = fmod(animation_phase + animation_accumulator * 1.9, TAU)
        animation_accumulator = 0.0
        queue_redraw()

func _new_city() -> Dictionary:
    return {"schema_version": SCHEMA, "name": "", "resources": {"madeira": 180, "pedra": 140, "alimentos": 0}, "buildings": [], "revision": 0, "visual_style": "azul", "last_collection_unix": _now(), "collection_count": 0, "claimed_missions": [], "npc_discovered": false, "npc_trades": 0, "npc_relation": 0, "last_trade_unix": 0, "food_shortage_cycles": 0, "regional_discoveries": [], "regional_pacts": [], "state_founded": false, "state_name": ""}

func _whole_number(value: Variant) -> bool:
    if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
        return false
    return float(value) == float(int(value))

func _valid_city(value: Variant) -> bool:
    if typeof(value) != TYPE_DICTIONARY:
        return false
    var data: Dictionary = value
    if data.get("schema_version") != SCHEMA or typeof(data.get("name")) != TYPE_STRING:
        return false
    if str(data["name"]).length() > 24 or not _whole_number(data.get("revision")) or int(data["revision"]) < 0:
        return false
    # Campo opcional: saves anteriores ao CP008 continuam válidos.
    if str(data.get("visual_style", "azul")) not in ["azul", "terracota", "bosque"]:
        return false
    var resources = data.get("resources")
    if typeof(resources) != TYPE_DICTIONARY:
        return false
    for key in ["madeira", "pedra"]:
        if not _whole_number(resources.get(key)) or int(resources[key]) < 0 or int(resources[key]) > RESOURCE_LIMIT:
            return false
    # Campos opcionais: retrocompatibilidade com todos os saves CP005-CP008.
    if resources.has("alimentos") and (not _whole_number(resources["alimentos"]) or int(resources["alimentos"]) < 0 or int(resources["alimentos"]) > RESOURCE_LIMIT):
        return false
    if data.has("last_collection_unix") and (not _whole_number(data["last_collection_unix"]) or int(data["last_collection_unix"]) < 0 or int(data["last_collection_unix"]) > 4102444800):
        return false
    if data.has("collection_count") and (not _whole_number(data["collection_count"]) or int(data["collection_count"]) < 0 or int(data["collection_count"]) > 1000000):
        return false
    # Contratos CP010 opcionais e sem ampliação do schema para preservar saves CP005-CP009.
    var claimed = data.get("claimed_missions", [])
    if typeof(claimed) != TYPE_ARRAY or claimed.size() > MISSION_IDS.size():
        return false
    var claimed_seen: Dictionary = {}
    for mission in claimed:
        if typeof(mission) != TYPE_STRING or str(mission) not in MISSION_IDS or claimed_seen.has(mission):
            return false
        claimed_seen[mission] = true
    if data.has("npc_discovered") and typeof(data["npc_discovered"]) != TYPE_BOOL:
        return false
    for key in ["npc_trades", "npc_relation", "food_shortage_cycles"]:
        if data.has(key) and (not _whole_number(data[key]) or int(data[key]) < 0 or int(data[key]) > 1000000):
            return false
    if data.has("npc_relation") and int(data["npc_relation"]) > 100:
        return false
    if data.has("last_trade_unix") and (not _whole_number(data["last_trade_unix"]) or int(data["last_trade_unix"]) < 0 or int(data["last_trade_unix"]) > 4102444800):
        return false
    # CP011: lista de cidades NPC visitadas e tratados; opcional nos saves legados.
    var discovered = data.get("regional_discoveries", [])
    var pacts = data.get("regional_pacts", [])
    if typeof(discovered) != TYPE_ARRAY or typeof(pacts) != TYPE_ARRAY:
        return false
    if discovered.size() > REGION_IDS.size() or pacts.size() > REGION_IDS.size():
        return false
    var seen_discovered: Dictionary = {}
    var seen_pacts: Dictionary = {}
    for entry in discovered:
        if typeof(entry) != TYPE_STRING or str(entry) not in REGION_IDS or seen_discovered.has(entry):
            return false
        seen_discovered[entry] = true
    for entry in pacts:
        if typeof(entry) != TYPE_STRING or str(entry) not in REGION_IDS or seen_pacts.has(entry) or not seen_discovered.has(entry):
            return false
        seen_pacts[entry] = true
    if data.has("state_founded") and typeof(data["state_founded"]) != TYPE_BOOL:
        return false
    if data.has("state_name") and (typeof(data["state_name"]) != TYPE_STRING or str(data["state_name"]).length() > 60):
        return false
    if bool(data.get("state_founded", false)) and (pacts.size() != REGION_IDS.size() or str(data.get("state_name", "")).length() < 3):
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
        if not BUILD_TYPES.has(kind) or not _whole_number(item.get("x")) or not _whole_number(item.get("y")):
            return false
        var x: int = item["x"]
        var y: int = item["y"]
        if not _in_bounds(Vector2i(x, y)) or _terrain(x, y) == "agua":
            return false
        var unique := "%d:%d" % [x, y]
        if occupied.has(unique):
            return false
        occupied[unique] = true
        var level = item.get("level", 1)
        if not _whole_number(level) or int(level) < 1 or int(level) > 3:
            return false
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
    # Uma única migração não destrutiva. Nenhuma produção retroativa sem relógio base.
    var migrated := false
    if not city["resources"].has("alimentos"):
        city["resources"]["alimentos"] = 0
        migrated = true
    if not city.has("last_collection_unix"):
        city["last_collection_unix"] = _now()
        migrated = true
    if not city.has("collection_count"):
        city["collection_count"] = 0
        migrated = true
    for key in ["claimed_missions", "npc_discovered", "npc_trades", "npc_relation", "last_trade_unix", "food_shortage_cycles"]:
        if not city.has(key):
            match key:
                "claimed_missions": city[key] = []
                "npc_discovered": city[key] = false
                _: city[key] = 0
            migrated = true
    if not city.has("regional_discoveries"):
        city["regional_discoveries"] = ["valeverde"] if bool(city.get("npc_discovered", false)) else []
        migrated = true
    if not city.has("regional_pacts"):
        city["regional_pacts"] = []
        migrated = true
    if not city.has("state_founded"):
        city["state_founded"] = false
        migrated = true
    if not city.has("state_name"):
        city["state_name"] = ""
        migrated = true
    if bool(city.get("npc_discovered", false)) and "valeverde" not in city["regional_discoveries"]:
        city["regional_discoveries"].append("valeverde")
        migrated = true
    if migrated:
        _write_save(city)

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
    b.custom_minimum_size = Vector2(79, 48)
    b.add_theme_font_size_override("font_size", 15)
    b.add_theme_color_override("font_color", Color("#ffe7ae"))
    b.add_theme_stylebox_override("normal", _style("#143751"))
    b.add_theme_stylebox_override("hover", _style("#285a76"))
    b.add_theme_stylebox_override("pressed", _style("#385e79"))
    b.pressed.connect(action)
    return b

func _create_ui() -> void:
    var top := PanelContainer.new()
    top.add_theme_stylebox_override("panel", _style("#071e36f2"))
    top.set_anchors_preset(Control.PRESET_TOP_WIDE)
    top.offset_left = 10
    top.offset_right = -224 # reservado para o FECHAR MÓDULO do aplicativo-base
    top.offset_top = 8
    top.offset_bottom = 68
    add_child(top)
    var head := HBoxContainer.new()
    head.add_theme_constant_override("separation", 18)
    top.add_child(head)
    title_label = _label("VALDORA · MINHA CIDADE", 23, Color("#ffe0a0"))
    title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    head.add_child(title_label)
    resource_label = _label("", 18)
    head.add_child(resource_label)

    var side := PanelContainer.new()
    side.add_theme_stylebox_override("panel", _style("#0a253eef"))
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
    column.add_theme_constant_override("separation", 7)
    side.add_child(column)
    column.add_child(_label("TERRITÓRIOS · CIDADE v9", 20, Color("#ffdb83")))
    var rename := _button("EDITAR NOME", Callable(self, "_ask_name"))
    rename.custom_minimum_size = Vector2(0, 40)
    column.add_child(rename)
    var government := _button("GOVERNO · MISSÕES · REGIÃO", Callable(self, "_open_civic"))
    government.custom_minimum_size = Vector2(0, 42)
    column.add_child(government)
    objective_label = _label("", 16, Color("#f8d68d"))
    column.add_child(objective_label)
    production_label = _label("", 14, Color("#badce9"))
    column.add_child(production_label)
    production_button = _button("COLETAR PRODUÇÃO", Callable(self, "_collect_production"))
    production_button.custom_minimum_size = Vector2(0, 42)
    column.add_child(production_button)
    var divider := HSeparator.new()
    column.add_child(divider)
    selected_label = _label("Selecione a ação e toque no terreno.", 16)
    column.add_child(selected_label)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    column.add_child(scroll)
    territory_label = _label("", 15)
    territory_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(territory_label)
    status_label = _label("", 15, Color("#f2dfb7"))
    status_label.custom_minimum_size.y = 45
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
    var button_scroll := ScrollContainer.new()
    button_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    button_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    button_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bottom.add_child(button_scroll)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 7)
    button_scroll.add_child(row)
    var inspect := _button("INSPECIONAR", Callable(self, "_select_type").bind("inspecionar"))
    inspect.custom_minimum_size = Vector2(124, 49)
    build_buttons["inspecionar"] = inspect
    row.add_child(inspect)
    for kind in BUILD_TYPES:
        var b := _button(str(LABELS[kind]), Callable(self, "_select_type").bind(kind))
        b.custom_minimum_size = Vector2(100, 49)
        build_buttons[kind] = b
        row.add_child(b)
    for kind in ["mover", "melhorar"]:
        var b := _button(kind.to_upper(), Callable(self, "_select_type").bind(kind))
        b.custom_minimum_size = Vector2(104, 49)
        build_buttons[kind] = b
        row.add_child(b)
    var style_btn := _button("ESTILO", Callable(self, "_cycle_style"))
    style_btn.custom_minimum_size = Vector2(108, 49)
    row.add_child(style_btn)
    grid_button = _button("GRADE", Callable(self, "_toggle_grid"))
    grid_button.custom_minimum_size = Vector2(101, 49)
    row.add_child(grid_button)
    dusk_button = _button("CREPÚSCULO", Callable(self, "_toggle_dusk"))
    dusk_button.custom_minimum_size = Vector2(137, 49)
    row.add_child(dusk_button)
    for caption in ["ZOOM +", "ZOOM -"]:
        var diff := 0.10 if caption == "ZOOM +" else -0.10
        var b := _button(caption, Callable(self, "_change_zoom").bind(diff))
        b.custom_minimum_size = Vector2(99, 49)
        row.add_child(b)

    # CP006-UI: overlay no próprio jogo; não abre uma janela nativa maior que a tela.
    editor_overlay = ColorRect.new()
    editor_overlay.name = "Nomear cidade · Valdora"
    editor_overlay.color = Color("#06172bdc")
    editor_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    editor_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(editor_overlay)

    var editor_position := CenterContainer.new()
    editor_position.anchor_left = 0.0
    editor_position.anchor_top = 0.0
    editor_position.anchor_right = 1.0
    editor_position.anchor_bottom = 0.67  # mantém campo e botão acima do teclado Android.
    editor_position.mouse_filter = Control.MOUSE_FILTER_STOP
    editor_overlay.add_child(editor_position)

    var editor_card := PanelContainer.new()
    editor_card.custom_minimum_size = Vector2(480, 0)
    editor_card.add_theme_stylebox_override("panel", _style("#112c42"))
    editor_position.add_child(editor_card)

    var form := VBoxContainer.new()
    form.add_theme_constant_override("separation", 12)
    editor_card.add_child(form)
    form.add_child(_label("NOME DA CIDADE", 24, Color("#ffe5a6")))
    form.add_child(_label("Escolha entre 3 e 24 caracteres.", 16))

    var line := HBoxContainer.new()
    line.add_theme_constant_override("separation", 10)
    form.add_child(line)
    editor_input = LineEdit.new()
    editor_input.max_length = 24
    editor_input.placeholder_text = "Ex.: Nova Auren"
    editor_input.custom_minimum_size = Vector2(288, 50)
    editor_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    editor_input.text_submitted.connect(_on_name_submitted)
    line.add_child(editor_input)

    var save := _button("SALVAR", Callable(self, "_save_name"))
    save.custom_minimum_size = Vector2(116, 50)
    line.add_child(save)

    editor_error = _label("Confirme com SALVAR ou Enter no teclado.", 15, Color("#b4d8d6"))
    form.add_child(editor_error)
    var cancel := _button("CANCELAR", Callable(self, "_cancel_name"))
    cancel.custom_minimum_size = Vector2(110, 43)
    form.add_child(cancel)
    editor_overlay.hide()
    _create_civic_overlay()
    _refresh_ui()

func _city_population() -> int:
    var estimate := 0
    for building in city["buildings"]:
        if str(building["type"]) == "casa":
            estimate += 6 * int(building.get("level", 1))
    return estimate

func _objective() -> String:
    if str(city["name"]).is_empty():
        return "ETAPA 1 · Nomeie sua cidade"
    if not _has_foundation():
        return "ETAPA 2 · Construa a fundação"
    for kind in ["casa", "fazenda", "serraria", "pedreira", "torre"]:
        if not _has_kind(kind):
            return "PRÓXIMO OBJETIVO · %s" % LABELS[kind]
    if int(city.get("collection_count", 0)) == 0:
        return "PRÓXIMO OBJETIVO · Coletar produção"
    for mission in _mission_definitions():
        if str(mission["id"]) not in city.get("claimed_missions", []) and _mission_ready(str(mission["id"])):
            return "MISSÃO DISPONÍVEL · %s" % str(mission["title"])
    return "NÚCLEO URBANO · Governo e região disponíveis"

func _has_kind(kind: String) -> bool:
    for item in city["buildings"]:
        if str(item["type"]) == kind:
            return true
    return false

func _refresh_mode_buttons() -> void:
    for key in build_buttons:
        var b: Button = build_buttons[key]
        b.modulate = Color("#ffd777") if str(key) == selected_type else Color.WHITE

func _refresh_ui() -> void:
    title_label.text = "VALDORA · " + (str(city["name"]) if not str(city["name"]).is_empty() else "CIDADE SEM NOME")
    resource_label.text = "MADEIRA %d   PEDRA %d   ALIM. %d   POP. ~%d" % [int(city["resources"]["madeira"]), int(city["resources"]["pedra"]), int(city["resources"].get("alimentos", 0)), _city_population()]
    _refresh_production_label()
    if objective_label != null:
        objective_label.text = _objective()
    if BUILD_TYPES.has(selected_type):
        var cost: Dictionary = COSTS[selected_type]
        selected_label.text = "%s · %d madeira / %d pedra" % [LABELS[selected_type], cost["madeira"], cost["pedra"]]
    elif selected_type == "mover":
        selected_label.text = "Mover: edifício → terreno vazio"
    elif selected_type == "melhorar":
        selected_label.text = "Melhorar: edifício até nível 3"
    else:
        selected_label.text = "Inspecionar: toque nos territórios"
    var area_name := _territory(selected_tile.x, selected_tile.y) if _in_bounds(selected_tile) else "Escolha um lote no mapa"
    var details := ""
    if _in_bounds(selected_tile):
        var building := _at(selected_tile)
        if not building.is_empty():
            details = "
Estrutura: %s · Nível %d" % [LABELS[str(building["type"])], int(building.get("level", 1))]
        else:
            details = "
Terreno livre" if _terrain(selected_tile.x, selected_tile.y) != "agua" else "
Área de água"
    territory_label.text = "REGIÃO
%s%s

LOTES: %d × %d
CONSTRUÇÕES: %d

Arraste o mapa para explorar. Use o menu inferior para construir e melhorar." % [area_name, details, W, H, city["buildings"].size()]
    objective_label.text = "ETAPA: %s  ·  Estilo: %s\n%s" % [_city_stage(), str(city.get("visual_style", "azul")).capitalize(), _objective()]
    _refresh_mode_buttons()
    if grid_button != null:
        grid_button.text = "GRADE: ON" if show_grid else "GRADE"
    if dusk_button != null:
        dusk_button.text = "DIA" if dusk_mode else "CREPÚSCULO"

func _set_status(message: String) -> void:
    status_label.text = message

func _ask_name() -> void:
    editor_input.text = str(city["name"])
    editor_error.text = "Confirme com SALVAR ou Enter no teclado."
    editor_overlay.show()
    editor_overlay.move_to_front()
    editor_input.call_deferred("grab_focus")

func _cancel_name() -> void:
    editor_overlay.hide()
    editor_input.release_focus()

func _on_name_submitted(_value: String) -> void:
    _save_name()

func _save_name() -> void:
    var clean := editor_input.text.strip_edges().replace("\n", "").replace("\r", "")
    if clean.length() < 3 or clean.length() > 24:
        editor_error.text = "Nome inválido: informe de 3 a 24 caracteres."
        _set_status("Nome inválido: use de 3 a 24 caracteres.")
        return
    var next: Dictionary = city.duplicate(true)
    next["name"] = clean
    next["revision"] = int(next["revision"]) + 1
    if _write_save(next):
        city = next
        editor_overlay.hide()
        editor_input.release_focus()
        _set_status("Cidade nomeada e salva no dispositivo.")
        _refresh_ui()
    else:
        editor_error.text = "Não foi possível salvar. Tente novamente."
        _set_status("Falha ao salvar nome; dados anteriores preservados.")

func _select_type(kind: String) -> void:
    if BUILD_TYPES.has(kind) or kind in ["mover", "melhorar", "inspecionar"]:
        selected_type = kind
        move_origin = Vector2i(-1, -1)
        _refresh_ui()
        _set_status("Toque em um lote para consultar." if kind == "inspecionar" else ("Escolha um lote." if BUILD_TYPES.has(kind) else ("Selecione um edifício para mover." if kind == "mover" else "Selecione um edifício para melhorar.")))

func _city_stage() -> String:
    var built := 0
    for building in city["buildings"]:
        if str(building["type"]) != "estrada":
            built += 1
    if built < 2:
        return "Assentamento"
    if built < 5:
        return "Vila"
    if built < 9:
        return "Vila fortificada"
    return "Cidade em formação"

func _cycle_style() -> void:
    var styles := ["azul", "terracota", "bosque"]
    var current := str(city.get("visual_style", "azul"))
    var next_style := str(styles[(styles.find(current) + 1) % styles.size()])
    var next: Dictionary = city.duplicate(true)
    next["visual_style"] = next_style
    next["revision"] = int(next["revision"]) + 1
    if _write_save(next):
        city = next
        _set_status("Identidade visual salva: %s." % next_style.capitalize())
        _refresh_ui()
        queue_redraw()
    else:
        _set_status("Não foi possível salvar o estilo. Preferência anterior mantida.")

func _toggle_grid() -> void:
    show_grid = not show_grid
    _refresh_ui()
    queue_redraw()

func _toggle_dusk() -> void:
    dusk_mode = not dusk_mode
    _refresh_ui()
    queue_redraw()

func _roof_color() -> Color:
    match str(city.get("visual_style", "azul")):
        "terracota": return Color("#cc7452")
        "bosque": return Color("#4f9266")
        _: return Color("#326cc2")

func _banner_color() -> Color:
    match str(city.get("visual_style", "azul")):
        "terracota": return Color("#a52e47")
        "bosque": return Color("#2d9453")
        _: return Color("#3264d3")

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
    if selected_type == "inspecionar":
        _set_status("Território selecionado: %s" % _territory(tile.x, tile.y))
    elif selected_type == "mover":
        _move_selection(tile)
    elif selected_type == "melhorar":
        _upgrade_building(tile)
    elif not current.is_empty():
        _set_status("Lote ocupado: %s. Escolha MOVER ou MELHORAR." % str(LABELS[current["type"]]))
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
    next["buildings"].append({"type": selected_type, "x": tile.x, "y": tile.y, "level": 1})
    if selected_type in PRODUCTIVE_TYPES:
        # Mudança de taxa de produção não reivindica períodos anteriores.
        next["last_collection_unix"] = _now()
    next["revision"] = int(next["revision"]) + 1
    if _write_save(next):
        city = next
        var built_kind := selected_type
        selected_type = "inspecionar"
        _set_status("Cidade fundada e salva!" if built_kind == "fundacao" else "%s construída e salva!" % LABELS[built_kind])
    else:
        _set_status("Falha ao salvar. Nenhum recurso foi consumido.")

func _terrain_allows(kind: String, ground: String) -> bool:
    if ground == "agua":
        return false
    if kind == "fazenda":
        return ground == "campo"
    if kind == "serraria":
        return ground == "floresta"
    if kind == "pedreira":
        return ground == "rocha"
    return true

func _move_selection(tile: Vector2i) -> void:
    if move_origin == Vector2i(-1, -1):
        var selected := _at(tile)
        if selected.is_empty() or str(selected["type"]) == "fundacao":
            _set_status("Selecione um edifício existente (exceto fundação).")
            return
        move_origin = tile
        _set_status("Escolha um lote livre para mover o edifício.")
        return
    if not _at(tile).is_empty() or tile == move_origin:
        _set_status("Destino ocupado. Escolha outro lote.")
        return
    var origin_building := _at(move_origin)
    if origin_building.is_empty() or not _terrain_allows(str(origin_building["type"]), _terrain(tile.x, tile.y)):
        _set_status("Terreno incompatível com este edifício.")
        return
    var next: Dictionary = city.duplicate(true)
    for item in next["buildings"]:
        if int(item["x"]) == move_origin.x and int(item["y"]) == move_origin.y:
            item["x"] = tile.x
            item["y"] = tile.y
            break
    next["revision"] = int(next["revision"]) + 1
    if _write_save(next):
        city = next
        move_origin = Vector2i(-1, -1)
        _set_status("Edifício reposicionado, sem custo extra.")
    else:
        _set_status("Mudança não salva; planta anterior preservada.")

func _upgrade_building(tile: Vector2i) -> void:
    var item := _at(tile)
    if item.is_empty() or str(item.get("type", "")) == "estrada":
        _set_status("Escolha um edifício válido para melhorar.")
        return
    var level := int(item.get("level", 1))
    if level >= 3:
        _set_status("Edifício já está no nível máximo desta etapa.")
        return
    var wood_cost := 15 * (level + 1)
    var stone_cost := 10 * (level + 1)
    if int(city["resources"]["madeira"]) < wood_cost or int(city["resources"]["pedra"]) < stone_cost:
        _set_status("Melhoria requer %d madeira e %d pedra." % [wood_cost, stone_cost])
        return
    var next: Dictionary = city.duplicate(true)
    next["resources"]["madeira"] = int(next["resources"]["madeira"]) - wood_cost
    next["resources"]["pedra"] = int(next["resources"]["pedra"]) - stone_cost
    for building in next["buildings"]:
        if int(building["x"]) == tile.x and int(building["y"]) == tile.y:
            building["level"] = level + 1
            break
    if str(item.get("type", "")) in PRODUCTIVE_TYPES:
        next["last_collection_unix"] = _now()
    next["revision"] = int(next["revision"]) + 1
    if _write_save(next):
        city = next
        _set_status("Edifício evoluiu para nível %d." % (level + 1))
    else:
        _set_status("Falha na gravação. Recursos preservados.")

func _map_area(pos: Vector2) -> bool:
    return pos.x >= 12.0 and pos.x < size.x - 322.0 and pos.y >= 82.0 and pos.y < size.y - 105.0

func _unhandled_input(event: InputEvent) -> void:
    if (editor_overlay != null and editor_overlay.visible) or (civic_overlay != null and civic_overlay.visible):
        return # impede construção/movimentação atrás dos painéis.
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
    var map_right := maxf(150.0, size.x - 326.0)
    var map_height := maxf(150.0, size.y - 175.0)
    draw_rect(Rect2(Vector2.ZERO, size), Color("#9bd5e5"))
    draw_rect(Rect2(Vector2(8, 76), Vector2(map_right, map_height)), Color("#86b6ab"))
    # Fundo atmosférico leve e não interativo; as áreas de construção seguem independentes.
    for i in range(7):
        var mx := 40.0 + float(i) * 160.0
        var peak := 98.0 + float((i * 31) % 57)
        draw_colored_polygon(PackedVector2Array([Vector2(mx - 110, 310), Vector2(mx, peak), Vector2(mx + 145, 310)]), Color("#577a83"))
        draw_colored_polygon(PackedVector2Array([Vector2(mx - 22, peak + 32), Vector2(mx, peak), Vector2(mx + 28, peak + 43), Vector2(mx + 14, peak + 36)]), Color("#d9e7dc"))
    draw_rect(Rect2(Vector2(8, 340), Vector2(map_right, maxf(4, map_height - 264))), Color("#8aaf7e"))
    # Primeiro o solo com profundidade. O lado rebaixado reforça leitura 2.5D.
    for y in range(H):
        for x in range(W):
            var p := _iso(float(x), float(y))
            var hw := HALF_W * zoom
            var hh := HALF_H * zoom
            var tile := PackedVector2Array([p + Vector2(0, -hh), p + Vector2(hw, 0), p + Vector2(0, hh), p + Vector2(-hw, 0)])
            var ground := _terrain(x, y)
            var c := Color("#92c469")
            match ground:
                "agua": c = Color("#379ed0")
                "rocha": c = Color("#a1aba7")
                "ruinas": c = Color("#c5ba8c")
                "floresta": c = Color("#57a65c")
                "campo": c = Color("#d3cb70")
            if (x + y) % 2 == 0:
                c = c.lightened(0.07)
            var height_px := 4.5 * zoom
            if ground != "agua":
                var skirt := PackedVector2Array([tile[3], tile[2], tile[1], tile[1] + Vector2(0, height_px), tile[2] + Vector2(0, height_px), tile[3] + Vector2(0, height_px)])
                draw_colored_polygon(skirt, c.darkened(0.27))
            draw_colored_polygon(tile, c)
            if show_grid:
                draw_polyline(PackedVector2Array([tile[0], tile[1], tile[2], tile[3], tile[0]]), c.darkened(0.17), maxf(0.7, zoom))
            if ground == "agua":
                var wave := sin(animation_phase + float(x * 3 + y * 2)) * 3.0 * zoom
                draw_line(p + Vector2(-15 * zoom, wave), p + Vector2(2 * zoom, wave - 3 * zoom), Color("#b0e7ef88"), 1.8 * zoom)
                draw_line(p + Vector2(4 * zoom, 7 * zoom - wave), p + Vector2(20 * zoom, 7 * zoom - wave), Color("#d1f0e999"), 1.4 * zoom)
            if selected_tile == Vector2i(x, y):
                draw_polyline(PackedVector2Array([tile[0], tile[1], tile[2], tile[3], tile[0]]), Color("#f9d373"), 4.0)
    # Pintura isométrica por profundidade. Cada construção é redesenhada independentemente.
    for depth in range(W + H - 1):
        for x in range(W):
            var y := depth - x
            if y < 0 or y >= H:
                continue
            var kind := _terrain(x, y)
            var p := _iso(float(x), float(y))
            var building := _at(Vector2i(x, y))
            if building.is_empty():
                match kind:
                    "floresta":
                        _tree(p + Vector2(-9, 2) * zoom, 0.70)
                        if (x + y) % 3 == 0:
                            _tree(p + Vector2(14, 4) * zoom, 0.53)
                    "rocha": _stone(p)
                    "ruinas":
                        if (x + y) % 2 == 0:
                            _ruin(p)
                    "campo":
                        _field(p)
                    "grama":
                        if (x * 7 + y * 11) % 5 == 0:
                            _bush(p)
            else:
                _draw_building(p, str(building["type"]), int(building.get("level", 1)), Vector2i(x, y))
    _draw_citizens()
    _draw_city_life_details()
    if dusk_mode:
        draw_rect(Rect2(Vector2(8, 76), Vector2(map_right, map_height)), Color("#091f4f38"))
    # A small in-scene content revision identifier; the APK version stays unchanged.
    draw_string(ThemeDB.fallback_font, Vector2(17, 109), "CIDADE · v8  |  " + _city_stage(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#102a45"))

func _field(p: Vector2) -> void:
    var s := zoom
    for i in range(4):
        var offset := float(i) * 6.0 - 9.0
        draw_line(p + Vector2(-24, offset + 5) * s, p + Vector2(3, offset - 8) * s, Color("#f2d975"), 2.2 * s)

func _bush(p: Vector2) -> void:
    var s := zoom
    draw_circle(p + Vector2(-5, -3) * s, 4.5 * s, Color("#2c8850"))
    draw_circle(p + Vector2(3, -4) * s, 5.2 * s, Color("#3b9b58"))
    draw_circle(p + Vector2(0, -8) * s, 4.0 * s, Color("#5da94e"))

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

func _draw_prism(p: Vector2, width: float, height: float, wall: Color, roof: Color) -> void:
    var s := zoom
    var w := width * s
    var h := height * s
    draw_colored_polygon(PackedVector2Array([p+Vector2(-w,-h), p+Vector2(0,-h+11*s), p+Vector2(0,9*s), p+Vector2(-w,0)]), wall.darkened(0.18))
    draw_colored_polygon(PackedVector2Array([p+Vector2(0,-h+11*s), p+Vector2(w,-h), p+Vector2(w,0), p+Vector2(0,9*s)]), wall)
    draw_colored_polygon(PackedVector2Array([p+Vector2(0,-h-15*s), p+Vector2(w+5*s,-h-2*s), p+Vector2(0,-h+13*s), p+Vector2(-w-5*s,-h-2*s)]), roof)
    draw_line(p+Vector2(0,-h-15*s), p+Vector2(w+5*s,-h-2*s), roof.lightened(0.28), 2.1*s)

func _draw_road(p: Vector2, tile: Vector2i) -> void:
    var s := zoom
    var road := Color("#bd9c70")
    draw_colored_polygon(PackedVector2Array([p+Vector2(0,-15)*s,p+Vector2(28,0)*s,p+Vector2(0,15)*s,p+Vector2(-28,0)*s]), road)
    for delta in [Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1)]:
        var neighbor: Vector2i = tile + delta
        if _in_bounds(neighbor) and str(_at(neighbor).get("type", "")) == "estrada":
            var toward := (_iso(float(neighbor.x), float(neighbor.y)) - p) * 0.43
            draw_line(p, p + toward, road.lightened(0.08), 12*s)
            draw_line(p, p + toward, Color("#debd88"), 5*s)
    draw_circle(p, 3.0*s, Color("#e0c59a"))

func _draw_banner(p: Vector2, tall: float) -> void:
    var s := zoom
    var top := p + Vector2(0, -tall)*s
    draw_line(top, top + Vector2(0, -23)*s, Color("#5f5346"), 2.1*s)
    draw_colored_polygon(PackedVector2Array([top+Vector2(0,-22)*s,top+Vector2(19,-16)*s,top+Vector2(0,-9)*s]), _banner_color())

func _draw_chimney(p: Vector2, phase_shift: float) -> void:
    var s := zoom
    draw_rect(Rect2(p + Vector2(0,-36)*s, Vector2(7,15)*s), Color("#d3bca0"))
    for i in range(2):
        var float_up := fmod(animation_phase * 8.0 + float(i) * 9.0 + phase_shift, 19.0)
        draw_circle(p + Vector2(7.0 + sin(animation_phase+phase_shift)*4.0, -38.0 - float_up)*s, 3.2*s, Color("#e2e8df88"))

func _draw_farm_detail(p: Vector2) -> void:
    var s := zoom
    for n in range(4):
        var v := float(n)
        draw_line(p+Vector2(-33+v*6,3)*s, p+Vector2(-24+v*6,12)*s, Color("#ecca59"), 2.7*s)
        draw_line(p+Vector2(-28+v*6,0)*s, p+Vector2(-28+v*6,-7)*s, Color("#cfa638"), 1.5*s)

func _draw_sawmill_detail(p: Vector2) -> void:
    var s := zoom
    for n in range(3):
        draw_line(p+Vector2(-28,3+n*5)*s, p+Vector2(-11,3+n*5)*s, Color("#77462b"), 4.1*s)
    draw_circle(p+Vector2(26,-4)*s, 8*s, Color("#b9bdbb"))
    draw_circle(p+Vector2(26,-4)*s, 4*s, Color("#805d38"))

func _draw_plaza_detail(p: Vector2, kind: String, level: int) -> void:
    var s := zoom
    if kind == "jardim":
        draw_colored_polygon(PackedVector2Array([p+Vector2(-27,0)*s,p+Vector2(0,-14)*s,p+Vector2(27,0)*s,p+Vector2(0,14)*s]), Color("#4d9c5e"))
        for i in range(4+level):
            var xx := float((i*11)%35)-17.0
            var yy := float((i*7)%13)-5.0
            draw_circle(p+Vector2(xx,yy)*s, 3.5*s, Color("#f8b26b") if i%2==0 else Color("#ffe7ad"))
        _bush(p+Vector2(0,-13)*s)
    elif kind == "praca":
        draw_colored_polygon(PackedVector2Array([p+Vector2(-29,0)*s,p+Vector2(0,-17)*s,p+Vector2(29,0)*s,p+Vector2(0,17)*s]), Color("#c7b99b"))
        draw_colored_polygon(PackedVector2Array([p+Vector2(-13,-3)*s,p+Vector2(0,-11)*s,p+Vector2(13,-3)*s,p+Vector2(0,5)*s]), Color("#accbe2"))
        draw_circle(p+Vector2(0,-11)*s, 5*s, Color("#77c7df"))
        if level>1:
            _draw_banner(p+Vector2(25,-4)*s, 15)
    elif kind == "poco":
        draw_colored_polygon(PackedVector2Array([p+Vector2(-17,0)*s,p+Vector2(0,-11)*s,p+Vector2(17,0)*s,p+Vector2(0,11)*s]), Color("#c6bca1"))
        draw_circle(p+Vector2(0,-4)*s, 12*s, Color("#a8a9a1"))
        draw_circle(p+Vector2(0,-4)*s, 8*s, Color("#3e9bbf"))
        draw_line(p+Vector2(-11,-5)*s,p+Vector2(-11,-24)*s,Color("#805c3a"),2.5*s)
        draw_line(p+Vector2(11,-5)*s,p+Vector2(11,-24)*s,Color("#805c3a"),2.5*s)
        draw_line(p+Vector2(-12,-24)*s,p+Vector2(12,-24)*s,Color("#b88b4f"),3*s)

func _draw_building(p: Vector2, kind: String, level: int = 1, tile: Vector2i = Vector2i(-1, -1)) -> void:
    var s := zoom
    if kind == "estrada":
        _draw_road(p, tile)
        return
    if kind in ["jardim", "praca", "poco"]:
        _draw_plaza_detail(p, kind, level)
        return
    var width := 21.0 + float(level-1)*3.0
    var height := (48.0 if kind=="fundacao" else (47.0 if kind=="torre" else 26.0)) + float(level-1)*9.0
    var wall := Color("#e4d6b4")
    var roof := _roof_color()
    match kind:
        "casa": roof = roof.lightened(0.12)
        "fazenda": roof = Color("#d9a64e")
        "serraria": roof = Color("#648852")
        "pedreira":
            roof = Color("#839a9f")
            wall = Color("#b9beb8")
        "torre": roof = _roof_color().darkened(0.18)
        "quartel": roof = Color("#65788a")
        "mercado": roof = Color("#bc7859")
    # Common lightweight isometric footprint and roof.
    _draw_prism(p, width, height, wall, roof)
    if kind == "fundacao":
        # Main hall and crowned battlements distinguish the capital building.
        for i in range(3):
            draw_rect(Rect2(p+Vector2(-width+float(i)*14.0,-height-9.0)*s,Vector2(10,12)*s),Color("#d6c6a2"))
        draw_rect(Rect2(p+Vector2(-8,-12)*s,Vector2(17,22)*s),Color("#65472f"))
        draw_rect(Rect2(p+Vector2(-4,-12)*s,Vector2(9,16)*s),Color("#a58155"))
        _draw_banner(p+Vector2(0,-height-16)*s, 3)
    elif kind == "casa":
        draw_rect(Rect2(p+Vector2(-12,-height+12)*s,Vector2(8,10)*s),Color("#dc9b55"))
        draw_rect(Rect2(p+Vector2(6,-height+11)*s,Vector2(8,10)*s),Color("#507fa4"))
        draw_rect(Rect2(p+Vector2(-3,0)*s,Vector2(8,9)*s),Color("#7c533c"))
        if (tile.x+tile.y)%3==0:
            _draw_chimney(p+Vector2(7,-height+5)*s,float(tile.x))
    elif kind == "fazenda":
        _draw_farm_detail(p)
        draw_colored_polygon(PackedVector2Array([p+Vector2(5,-height-20)*s,p+Vector2(21,-height-7)*s,p+Vector2(10,-height+9)*s]),Color("#f9df8d"))
    elif kind == "serraria":
        _draw_sawmill_detail(p)
    elif kind == "pedreira":
        _stone(p+Vector2(19,11)*s)
        draw_line(p+Vector2(-29,7)*s,p+Vector2(-15,-1)*s,Color("#785943"),3*s)
    elif kind == "torre":
        for n in range(3):
            draw_rect(Rect2(p+Vector2(-21+n*14,-height-8)*s,Vector2(10,13)*s),Color("#e5d8b5"))
        draw_rect(Rect2(p+Vector2(-6,-height+11)*s,Vector2(12,13)*s),Color("#415c6e"))
        _draw_banner(p+Vector2(0,-height-17)*s, 2)
    elif kind == "quartel":
        draw_rect(Rect2(p+Vector2(-13,-height+7)*s,Vector2(8,15)*s),Color("#50637e"))
        draw_line(p+Vector2(-29,9)*s,p+Vector2(-14,-6)*s,Color("#b0a084"),3*s)
        draw_line(p+Vector2(29,9)*s,p+Vector2(14,-6)*s,Color("#b0a084"),3*s)
        _draw_banner(p+Vector2(14,-height-15)*s, 6)
    elif kind == "mercado":
        for i in range(3):
            draw_rect(Rect2(p+Vector2(-29+float(i)*15,5)*s,Vector2(14,6)*s),Color("#aa683d"))
        draw_colored_polygon(PackedVector2Array([p+Vector2(-31,-1)*s,p+Vector2(-10,-13)*s,p+Vector2(8,-2)*s]),Color("#f5d78d"))
        draw_colored_polygon(PackedVector2Array([p+Vector2(4,-3)*s,p+Vector2(23,-16)*s,p+Vector2(32,-1)*s]),_banner_color())
    if level>=2:
        draw_circle(p+Vector2(-width+6,-height-9)*s,3.0*s,Color("#ffe29b"))
    if level>=3:
        draw_circle(p+Vector2(width-7,-height-9)*s,3.0*s,Color("#ffe29b"))

func _food_upkeep_rate() -> int:
    # Duas unidades de alimento por residência nível 1 a cada ciclo de 10 min.
    # Taxa escalonada com a população; o jogo permanece funcional sem alimentos.
    if not _has_foundation():
        return 0
    return int(ceili(float(_city_population()) / 6.0)) * 2

func _services_report() -> Dictionary:
    var residents := _city_population()
    var service_capacity := 0
    var defense := 0
    for item in city["buildings"]:
        var level := int(item.get("level", 1))
        match str(item["type"]):
            "poco": service_capacity += 12 * level
            "praca": service_capacity += 14 * level
            "jardim": service_capacity += 5 * level
            "mercado": service_capacity += 15 * level
            "torre": defense += 10 * level
            "quartel": defense += 18 * level
    var service_score := 100 if residents == 0 else mini(100, int(floor(100.0 * float(service_capacity) / float(residents))))
    var food_rate := _food_upkeep_rate()
    var gross_food := int(_production_rates()["alimentos"])
    var supply := "SEM MORADORES" if residents == 0 else ("ESTÁVEL" if gross_food >= food_rate else "ATENÇÃO")
    return {"population": residents, "service_coverage": service_score, "service_capacity": service_capacity, "defense": defense, "food_upkeep": food_rate, "food_production": gross_food, "food_status": supply, "shortage_cycles": int(city.get("food_shortage_cycles", 0))}

func _mission_definitions() -> Array[Dictionary]:
    return [
        {"id":"fundacao", "title":"Primeiro assentamento", "hint":"Nomeie e funde sua cidade", "wood":20, "stone":10, "food":0},
        {"id":"abrigo", "title":"Abrigo para moradores", "hint":"Construa uma casa", "wood":12, "stone":0, "food":15},
        {"id":"primeira_safra", "title":"Primeira colheita", "hint":"Construa uma fazenda", "wood":0, "stone":0, "food":25},
        {"id":"industria", "title":"Ofícios e materiais", "hint":"Construa serraria e pedreira", "wood":30, "stone":20, "food":0},
        {"id":"servicos", "title":"Qualidade de vida", "hint":"Construa poço e praça", "wood":12, "stone":15, "food":20},
        {"id":"vizinhanca", "title":"Primeiro contato", "hint":"Descubra a cidade vizinha Valeverde", "wood":15, "stone":0, "food":25},
        {"id":"intercambio", "title":"Acordo comercial", "hint":"Conclua uma troca com Valeverde", "wood":20, "stone":20, "food":0},
        {"id":"fronteiras", "title":"Cartografia regional", "hint":"Descubra três cidades NPC", "wood":25, "stone":0, "food":20},
        {"id":"tratados", "title":"Conselho dos prefeitos", "hint":"Firmar dois tratados municipais", "wood":30, "stone":25, "food":0},
        {"id":"primeiro_estado", "title":"Primeiro estado de Valdora", "hint":"Unir sua cidade a quatro cidades NPC", "wood":30, "stone":40, "food":40}
    ]

func _mission_ready(id: String) -> bool:
    match id:
        "fundacao": return not str(city.get("name", "")).is_empty() and _has_foundation()
        "abrigo": return _has_kind("casa")
        "primeira_safra": return _has_kind("fazenda")
        "industria": return _has_kind("serraria") and _has_kind("pedreira")
        "servicos": return _has_kind("poco") and _has_kind("praca")
        "vizinhanca": return bool(city.get("npc_discovered", false))
        "intercambio": return int(city.get("npc_trades", 0)) > 0
        "fronteiras": return city.get("regional_discoveries", []).size() >= 3
        "tratados": return city.get("regional_pacts", []).size() >= 2
        "primeiro_estado": return bool(city.get("state_founded", false))
    return false

func _claim_mission(id: String) -> bool:
    if id not in MISSION_IDS or id in city.get("claimed_missions", []) or not _mission_ready(id):
        _set_status("Missão não disponível ou já resgatada.")
        return false
    var mission: Dictionary = {}
    for item in _mission_definitions():
        if str(item["id"]) == id:
            mission = item
            break
    if mission.is_empty():
        return false
    var next: Dictionary = city.duplicate(true)
    next["claimed_missions"].append(id)
    for kind in ["madeira", "pedra", "alimentos"]:
        var reward_key := "wood" if kind == "madeira" else ("stone" if kind == "pedra" else "food")
        next["resources"][kind] = mini(RESOURCE_LIMIT, int(next["resources"].get(kind, 0)) + int(mission[reward_key]))
    next["revision"] = int(next["revision"]) + 1
    if not _write_save(next):
        _set_status("Falha ao gravar a missão. Recompensa não concedida.")
        return false
    city = next
    _refresh_ui()
    _set_status("Missão concluída: %s" % str(mission["title"]))
    _refresh_civic()
    return true

func _discover_neighbor() -> bool:
    if bool(city.get("npc_discovered", false)):
        _set_status("Valeverde já aparece no mapa regional.")
        return false
    if not _has_foundation() or not _has_kind("casa"):
        _set_status("Construa a fundação e uma casa para explorar a região.")
        return false
    var next: Dictionary = city.duplicate(true)
    next["npc_discovered"] = true
    if not next.has("regional_discoveries"):
        next["regional_discoveries"] = []
    if "valeverde" not in next["regional_discoveries"]:
        next["regional_discoveries"].append("valeverde")
    next["revision"] = int(next["revision"]) + 1
    if not _write_save(next):
        _set_status("Não foi possível registrar a descoberta.")
        return false
    city = next
    _refresh_ui()
    _set_status("Valeverde descoberta. Relações comerciais liberadas.")
    _refresh_civic()
    return true

func _trade_neighbor(kind: String, now: int) -> bool:
    if not bool(city.get("npc_discovered", false)) or not _has_kind("mercado"):
        _set_status("Descubra Valeverde e construa um mercado para negociar.")
        return false
    var offers := {
        "food": {"cost": "madeira", "cost_amount": 24, "receive": "alimentos", "receive_amount": 36},
        "stone": {"cost": "alimentos", "cost_amount": 30, "receive": "pedra", "receive_amount": 18}
    }
    if not offers.has(kind):
        return false
    var last := int(city.get("last_trade_unix", 0))
    if now < last or (last > 0 and now - last < TRADE_COOLDOWN):
        _set_status("A caravana de Valeverde retorna em breve (15 min).")
        return false
    var offer: Dictionary = offers[kind]
    if int(city["resources"].get(str(offer["cost"]), 0)) < int(offer["cost_amount"]):
        _set_status("Recursos insuficientes para o comércio regional.")
        return false
    var next: Dictionary = city.duplicate(true)
    next["resources"][str(offer["cost"])] = int(next["resources"][str(offer["cost"])]) - int(offer["cost_amount"])
    next["resources"][str(offer["receive"])] = mini(RESOURCE_LIMIT, int(next["resources"].get(str(offer["receive"]), 0)) + int(offer["receive_amount"]))
    next["npc_trades"] = mini(1000000, int(next.get("npc_trades", 0)) + 1)
    next["npc_relation"] = mini(100, int(next.get("npc_relation", 0)) + 5)
    next["last_trade_unix"] = now
    next["revision"] = int(next["revision"]) + 1
    if not _write_save(next):
        _set_status("Troca não registrada. Recursos preservados.")
        return false
    city = next
    _refresh_ui()
    _set_status("Troca confirmada com Valeverde. Relação +5.")
    _refresh_civic()
    return true

func _open_civic() -> void:
    if editor_overlay != null and editor_overlay.visible:
        return
    civic_overlay.show()
    civic_overlay.move_to_front()
    _refresh_civic()

func _close_civic() -> void:
    civic_overlay.hide()

func _civic_text(text_value: String, color: Color = Color("#d4e6e7")) -> Label:
    var label := _label(text_value, 16, color)
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    return label

func _create_civic_overlay() -> void:
    civic_overlay = ColorRect.new()
    civic_overlay.color = Color("#06182bdf")
    civic_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    civic_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(civic_overlay)
    var frame := CenterContainer.new()
    frame.anchor_right = 1.0
    frame.anchor_bottom = 1.0
    civic_overlay.add_child(frame)
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(770, 0)
    panel.add_theme_stylebox_override("panel", _style("#102b40"))
    frame.add_child(panel)
    var column := VBoxContainer.new()
    column.custom_minimum_size = Vector2(710, 0)
    column.add_theme_constant_override("separation", 7)
    panel.add_child(column)
    var header := HBoxContainer.new()
    column.add_child(header)
    var title := _label("CONSELHO DA CIDADE · VALDORA", 22, Color("#f3d58c"))
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title)
    header.add_child(_button("FECHAR", Callable(self, "_close_civic")))
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(710, 380)
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    column.add_child(scroll)
    civic_scroll_content = VBoxContainer.new()
    civic_scroll_content.add_theme_constant_override("separation", 10)
    civic_scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(civic_scroll_content)
    civic_overlay.hide()

func _refresh_civic() -> void:
    if civic_scroll_content == null:
        return
    for previous in civic_scroll_content.get_children():
        civic_scroll_content.remove_child(previous)
        previous.queue_free()
    var health := _services_report()
    civic_scroll_content.add_child(_civic_text("SERVIÇOS PÚBLICOS", Color("#ffe4a2")))
    civic_scroll_content.add_child(_civic_text("Moradores: %d   Cobertura: %d%%   Defesa: %d" % [health["population"],health["service_coverage"],health["defense"]]))
    civic_scroll_content.add_child(_civic_text("Alimentos: +%d / -%d por ciclo · %s" % [health["food_production"],health["food_upkeep"],health["food_status"]]))
    if int(health["shortage_cycles"]) > 0:
        civic_scroll_content.add_child(_civic_text("Histórico de falta de alimentos: %d ciclo(s)." % int(health["shortage_cycles"]), Color("#ffd59c")))
    civic_scroll_content.add_child(HSeparator.new())
    civic_scroll_content.add_child(_civic_text("MISSÕES DA CIDADE", Color("#ffe4a2")))
    for quest in _mission_definitions():
        var mission_id := str(quest["id"])
        var claimed: bool = mission_id in city.get("claimed_missions", [])
        var ready := _mission_ready(mission_id)
        var line := HBoxContainer.new()
        civic_scroll_content.add_child(line)
        var message := _civic_text("%s · %s" % [str(quest["title"]), str(quest["hint"])])
        line.add_child(message)
        var reward := _button("CONCLUÍDA" if claimed else ("RESGATAR" if ready else "PENDENTE"), Callable(self,"_claim_mission").bind(mission_id))
        reward.custom_minimum_size = Vector2(110, 45)
        reward.disabled = claimed or not ready
        line.add_child(reward)
    civic_scroll_content.add_child(HSeparator.new())
    civic_scroll_content.add_child(_civic_text("REGIÃO · VALEVERDE", Color("#ffe4a2")))
    var region := Control.new()
    region.custom_minimum_size = Vector2(680, 147)
    region.draw.connect(Callable(self,"_draw_region_preview").bind(region))
    civic_scroll_content.add_child(region)
    civic_scroll_content.add_child(_civic_text("Uma cidade administrada por NPCs. Diplomacia local offline; sem jogadores reais."))
    var known := bool(city.get("npc_discovered", false))
    civic_scroll_content.add_child(_civic_text("Estado: %s   ·   Relação: %d/100   ·   Trocas: %d" % [("DESCONHECIDA" if not known else "DESCOBERTA"), int(city.get("npc_relation", 0)), int(city.get("npc_trades", 0))]))
    var discover := _button("EXPLORAR FRONTEIRA", Callable(self,"_discover_neighbor"))
    discover.disabled = known or not _has_kind("casa") or not _has_foundation()
    civic_scroll_content.add_child(discover)
    if known:
        civic_scroll_content.add_child(_civic_text("Comércio requer mercado. Uma caravana a cada 15 minutos."))
        for offer in [
            {"kind":"food", "text":"Trocar 24 madeira por 36 alimentos"},
            {"kind":"stone", "text":"Trocar 30 alimentos por 18 pedra"}
        ]:
            var button := _button(str(offer["text"]), Callable(self,"_on_trade").bind(str(offer["kind"])))
            button.disabled = not _has_kind("mercado")
            civic_scroll_content.add_child(button)
    civic_scroll_content.add_child(HSeparator.new())
    civic_scroll_content.add_child(_civic_text("CONSELHO REGIONAL · 5 CIDADES", Color("#ffe4a2")))
    civic_scroll_content.add_child(_civic_text("As outras cidades são administradas por NPCs. Nenhuma é um jogador real."))
    for town in _region_towns():
        var id := str(town["id"])
        var discovered: bool = id in city.get("regional_discoveries", [])
        var joined: bool = id in city.get("regional_pacts", [])
        var row := HBoxContainer.new()
        civic_scroll_content.add_child(row)
        var flag := "TRATADO" if joined else ("DESCOBERTA" if discovered else "INEXPLORADA")
        var label := _civic_text("%s · %s · %s" % [str(town["name"]), str(town["specialty"]), flag])
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(label)
        var action := _button("TRATADO" if joined else ("NEGOCIAR" if discovered else "EXPLORAR"), Callable(self, "_regional_action").bind(id))
        action.disabled = joined
        action.custom_minimum_size = Vector2(115, 43)
        row.add_child(action)
    var region_status := _regional_status()
    civic_scroll_content.add_child(_civic_text("Cidades vinculadas: %d/5 · Expedições: %d/4 · Tratados: %d/4" % [int(region_status["members"]), int(region_status["discovered"]), int(region_status["pacts"])]))
    civic_scroll_content.add_child(_civic_text("Fundar estado requer quatro tratados, mercado, defesa e cobertura de serviços acima de 50%."))
    if bool(city.get("state_founded", false)):
        civic_scroll_content.add_child(_civic_text("GOVERNO REGIONAL: %s · Governador: você (NPCs aliados)." % str(city.get("state_name", "")), Color("#ffe4a2")))
    else:
        var found := _button("FUNDAR ESTADO", Callable(self, "_found_state"))
        found.disabled = not _state_requirements_met()
        civic_scroll_content.add_child(found)

func _draw_region_preview(canvas: Control) -> void:
    # Miniatura geográfica procedural, isolada do mapa construível e sem texturas.
    var w := maxf(580.0, canvas.size.x)
    var h := 147.0
    canvas.draw_rect(Rect2(0, 0, w, h), Color("#164868"))
    var land := PackedVector2Array([
        Vector2(10, 70),Vector2(52, 33),Vector2(148, 17),Vector2(271, 43),
        Vector2(375, 19),Vector2(514, 34),Vector2(w-10, 83),
        Vector2(w-49, 127),Vector2(510, 138),Vector2(350, 122),
        Vector2(227, 140),Vector2(94, 123)
    ])
    canvas.draw_colored_polygon(land,Color("#598f5a"))
    canvas.draw_polyline(land, Color("#b6c480"), 2.0)
    canvas.draw_line(Vector2(161, 82),Vector2(w-162, 83), Color("#d1b27c"), 5.0)
    canvas.draw_line(Vector2(161, 82),Vector2(w-162, 83), Color("#7b684f"), 1.0)
    for i in range(7):
        var x := 59.0 + float(i) * 68.0
        canvas.draw_colored_polygon(PackedVector2Array([Vector2(x,52),Vector2(x+20,19),Vector2(x+39,52)]),Color("#345b49"))
    canvas.draw_circle(Vector2(161, 82),17,Color("#e5bf64"))
    canvas.draw_circle(Vector2(161, 82),10,Color("#2c6598"))
    var known := bool(city.get("npc_discovered", false))
    canvas.draw_circle(Vector2(w-162, 83),17,Color("#d4b17e" if known else "#78858c"))
    canvas.draw_circle(Vector2(w-162, 83),10,Color("#5b9c72" if known else "#455b6a"))
    canvas.draw_string(ThemeDB.fallback_font,Vector2(85,118),"SUA CIDADE",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#ffffff"))
    canvas.draw_string(ThemeDB.fallback_font,Vector2(w-254,118),"VALEVERDE" if known else "REGIÃO A EXPLORAR",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#ffffff"))
    # Marcadores compactos dos novos distritos, sem mapa estático pesado.
    for i in range(1, REGION_IDS.size()):
        var id := str(REGION_IDS[i])
        var discovered: bool = id in city.get("regional_discoveries", [])
        var joined: bool = id in city.get("regional_pacts", [])
        var x := 260.0 + 87.0 * float(i - 1)
        var y := 42.0 if i % 2 == 0 else 122.0
        canvas.draw_circle(Vector2(x, y), 7.0, Color("#efc872" if joined else ("#78b2a2" if discovered else "#708290")))
        canvas.draw_circle(Vector2(x, y), 3.0, Color("#142f47"))

func _region_towns() -> Array[Dictionary]:
    return [
        {"id":"valeverde", "name":"Valeverde", "specialty":"agricultura"},
        {"id":"pedralta", "name":"Pedralta", "specialty":"pedra e fortificações"},
        {"id":"ribeirinha", "name":"Ribeirinha", "specialty":"rios e comércio"},
        {"id":"montesol", "name":"Montesol", "specialty":"ofícios e vigia"}
    ]

func _regional_status() -> Dictionary:
    var discoveries: Array = city.get("regional_discoveries", [])
    var pacts: Array = city.get("regional_pacts", [])
    return {"discovered": discoveries.size(), "pacts": pacts.size(), "members": 1 + pacts.size(), "state_founded": bool(city.get("state_founded", false))}

func _regional_action(id: String) -> void:
    if id in city.get("regional_discoveries", []):
        _sign_regional_pact(id)
    else:
        _scout_region(id)

func _scout_region(id: String) -> bool:
    if id not in REGION_IDS or id in city.get("regional_discoveries", []):
        return false
    if id == "valeverde":
        return _discover_neighbor()
    if not bool(city.get("npc_discovered", false)) or not _has_kind("mercado") or int(city.get("npc_trades", 0)) < 1:
        _set_status("Explore Valeverde e negocie uma vez antes de avançar à região.")
        return false
    if int(city["resources"]["madeira"]) < 12 or int(city["resources"].get("alimentos", 0)) < 8:
        _set_status("Expedição requer 12 madeira e 8 alimentos.")
        return false
    var next: Dictionary = city.duplicate(true)
    next["resources"]["madeira"] = int(next["resources"]["madeira"]) - 12
    next["resources"]["alimentos"] = int(next["resources"].get("alimentos", 0)) - 8
    next["regional_discoveries"].append(id)
    next["revision"] = int(next["revision"]) + 1
    if not _write_save(next):
        _set_status("Falha ao registrar expedição; recursos preservados.")
        return false
    city = next
    _refresh_ui()
    _refresh_civic()
    _set_status("Uma nova cidade NPC foi descoberta na região.")
    return true

func _sign_regional_pact(id: String) -> bool:
    if id not in REGION_IDS or id not in city.get("regional_discoveries", []) or id in city.get("regional_pacts", []):
        return false
    if not _has_kind("mercado") or not _has_kind("casa"):
        _set_status("Tratados exigem mercado e moradores na cidade.")
        return false
    if id == "valeverde" and (int(city.get("npc_relation", 0)) < 5 or int(city.get("npc_trades", 0)) < 1):
        _set_status("Valeverde exige ao menos uma caravana comercial.")
        return false
    if id != "valeverde" and int(_services_report()["service_coverage"]) < 40:
        _set_status("Apoio regional exige 40% de cobertura de serviços.")
        return false
    if int(city["resources"]["madeira"]) < 18 or int(city["resources"]["pedra"]) < 12 or int(city["resources"].get("alimentos", 0)) < 10:
        _set_status("Tratado requer 18 madeira, 12 pedra e 10 alimentos.")
        return false
    var next: Dictionary = city.duplicate(true)
    next["resources"]["madeira"] = int(next["resources"]["madeira"]) - 18
    next["resources"]["pedra"] = int(next["resources"]["pedra"]) - 12
    next["resources"]["alimentos"] = int(next["resources"]["alimentos"]) - 10
    next["regional_pacts"].append(id)
    next["revision"] = int(next["revision"]) + 1
    if not _write_save(next):
        _set_status("Falha ao salvar tratado; recursos preservados.")
        return false
    city = next
    _refresh_ui()
    _refresh_civic()
    _set_status("Tratado municipal confirmado. Cidades vinculadas: %d/5." % (1 + next["regional_pacts"].size()))
    return true

func _state_requirements_met() -> bool:
    if bool(city.get("state_founded", false)) or city.get("regional_pacts", []).size() != REGION_IDS.size():
        return false
    if city.get("regional_discoveries", []).size() != REGION_IDS.size() or not _has_kind("mercado"):
        return false
    var health := _services_report()
    if int(health["service_coverage"]) < 50 or int(health["defense"]) < 10:
        return false
    return _has_foundation() and not str(city.get("name", "")).is_empty()

func _found_state() -> bool:
    if not _state_requirements_met():
        _set_status("Ainda faltam tratados, serviços ou defesa para fundar o estado.")
        return false
    var next: Dictionary = city.duplicate(true)
    next["state_founded"] = true
    next["state_name"] = "Estado de " + str(city["name"])
    next["revision"] = int(next["revision"]) + 1
    if not _write_save(next):
        _set_status("Falha ao registrar a fundação do estado.")
        return false
    city = next
    _refresh_ui()
    _refresh_civic()
    _set_status("Estado formado: %s. Sua cidade lidera quatro cidades NPC." % str(next["state_name"]))
    return true

func _on_trade(kind: String) -> void:
    _trade_neighbor(kind, _now())

func _now() -> int:
    return int(Time.get_unix_time_from_system())

func _production_rates() -> Dictionary:
    var rates := {"madeira": 0, "pedra": 0, "alimentos": 0}
    if not _has_foundation():
        return rates
    for structure in city["buildings"]:
        var amount := int(structure.get("level", 1))
        match str(structure.get("type", "")):
            "serraria": rates["madeira"] += 8 * amount
            "pedreira": rates["pedra"] += 5 * amount
            "fazenda": rates["alimentos"] += 10 * amount
    return rates

func _production_estimate(now: int) -> Dictionary:
    var rates := _production_rates()
    var since := int(city.get("last_collection_unix", now))
    var elapsed := maxi(0, now - since)
    var cycles := mini(MAX_IDLE_CYCLES, elapsed / PRODUCE_SECONDS)
    var gains := {}
    for key in ["madeira", "pedra", "alimentos"]:
        gains[key] = int(rates[key]) * cycles
    return {"cycles": cycles, "gains": gains, "rates": rates, "wait_seconds": maxi(0, PRODUCE_SECONDS - (elapsed % PRODUCE_SECONDS)), "capped": elapsed >= MAX_IDLE_CYCLES * PRODUCE_SECONDS}

func _refresh_production_label() -> void:
    if production_label == null:
        return
    var estimate := _production_estimate(_now())
    var rate: Dictionary = estimate["rates"]
    var gains: Dictionary = estimate["gains"]
    if int(rate["madeira"]) + int(rate["pedra"]) + int(rate["alimentos"]) == 0:
        production_label.text = "PRODUÇÃO · Construa fazenda, serraria ou pedreira."
        if production_button != null:
            production_button.disabled = true
        return
    var upkeep := _food_upkeep_rate()
    production_label.text = "A CADA 10 MIN: +%d madeira / +%d pedra / +%d alimentos\nMORADORES: -%d alimento/ciclo  ·  A COLETAR: %d ciclos" % [int(rate["madeira"]), int(rate["pedra"]), int(rate["alimentos"]), upkeep, int(estimate["cycles"])]
    if production_button != null:
        production_button.disabled = int(estimate["cycles"]) < 1

func _collect_production() -> void:
    _collect_production_at(_now())

func _collect_production_at(now: int) -> bool:
    # Sem recompensa dupla: timestamp + saldo no mesmo save atômico.
    var estimate := _production_estimate(now)
    var cycles := int(estimate["cycles"])
    if cycles < 1:
        _set_status("Produção ainda não disponível. Ciclos de 10 minutos.")
        return false
    var rates: Dictionary = estimate["rates"]
    if int(rates["madeira"]) + int(rates["pedra"]) + int(rates["alimentos"]) == 0:
        _set_status("Construa fazenda, serraria ou pedreira para produzir.")
        return false
    var next: Dictionary = city.duplicate(true)
    var received := []
    for key in ["madeira", "pedra", "alimentos"]:
        var old_amount := int(next["resources"].get(key, 0))
        var final_amount := mini(RESOURCE_LIMIT, old_amount + int(estimate["gains"][key]))
        next["resources"][key] = final_amount
        received.append(final_amount - old_amount)
    # Abastecimento: desconta alimentos somente na coleta, na mesma transação do ganho.
    # Nunca torna o saldo negativo ou destrói estruturas; carência é sinalizada ao governo.
    var food_before := int(next["resources"].get("alimentos", 0))
    var upkeep := mini(RESOURCE_LIMIT, _food_upkeep_rate() * cycles)
    next["resources"]["alimentos"] = maxi(0, food_before - upkeep)
    var shortage := maxi(0, upkeep - food_before)
    var shortage_cycles := 0 if shortage == 0 else int(ceili(float(shortage) / float(maxi(1, _food_upkeep_rate()))))
    next["food_shortage_cycles"] = mini(1000000, int(city.get("food_shortage_cycles", 0)) + shortage_cycles)
    # Se o jogador ficou mais de 8 h offline, descarta o excesso com limite de recuperação.
    next["last_collection_unix"] = now if bool(estimate["capped"]) else int(city.get("last_collection_unix", now)) + cycles * PRODUCE_SECONDS
    next["collection_count"] = mini(1000000, int(city.get("collection_count", 0)) + 1)
    next["revision"] = int(next["revision"]) + 1
    if not _write_save(next):
        _set_status("Erro ao salvar coleta. Recursos anteriores preservados.")
        return false
    city = next
    _refresh_ui()
    var shortage_note := " · ATENÇÃO: faltaram alimentos." if shortage > 0 else ""
    _set_status("Produção: +%d madeira, +%d pedra; alimentos líquidos: %d.%s" % [int(received[0]), int(received[1]), int(city["resources"].get("alimentos", 0)), shortage_note])
    return true

func _draw_city_life_details() -> void:
    # Ambientação de baixo custo: luzes nas casas e atividades produtivas.
    var s := zoom
    for structure in city["buildings"]:
        var kind := str(structure["type"])
        if kind not in ["mercado", "fazenda", "serraria", "pedreira", "praca", "poco", "quartel"]:
            continue
        var p := _iso(float(structure["x"]), float(structure["y"]))
        match kind:
            "mercado":
                for k in range(2):
                    draw_circle(p + Vector2(-13 + k * 21, 7) * s, 3.0 * s, Color("#d18e45"))
            "fazenda":
                var bob := sin(resident_clock * 1.4 + float(structure["x"])) * 2.0
                draw_line(p + Vector2(18, -3) * s, p + Vector2(18 + bob, -13) * s, Color("#8c713a"), 2 * s)
            "serraria":
                draw_line(p + Vector2(21, 10) * s, p + Vector2(33, 10) * s, Color("#865032"), 5.0 * s)
            "pedreira":
                draw_circle(p + Vector2(17, 6) * s, 4 * s, Color("#a4b4ae"))
            "praca":
                draw_circle(p + Vector2(0, -13) * s, (5.0 + sin(resident_clock * 2.0)) * s, Color("#9ad5ed"))
            "poco":
                draw_line(p + Vector2(0, -10) * s, p + Vector2(0, -20) * s, Color("#8cbccc"), 2 * s)
            "quartel":
                draw_line(p + Vector2(24, -11) * s, p + Vector2(24, -23) * s, Color("#675b4b"), 2 * s)

func _draw_citizens() -> void:
    if not _has_foundation():
        return
    # Rotas cosméticas determinísticas; não são agentes de servidor nem alteram o saldo.
    var homes := []
    var jobs := []
    var center := Vector2(5.0, 5.0)
    for item in city["buildings"]:
        var location := Vector2(float(item["x"]), float(item["y"]))
        if str(item["type"]) == "fundacao":
            center = location
        if str(item["type"]) == "casa":
            homes.append(location)
        if str(item["type"]) in ["fazenda", "serraria", "pedreira", "mercado", "quartel", "praca"]:
            jobs.append({"location": location, "kind": str(item["type"])})
    if homes.is_empty():
        homes.append(center)
    if jobs.is_empty():
        jobs.append({"location": center + Vector2(0.7, 0.0), "kind": "praca"})
    var count := mini(12, maxi(2, _city_population() / 5))
    for i in range(count):
        var origin: Vector2 = homes[i % homes.size()]
        var job: Dictionary = jobs[i % jobs.size()]
        var destination: Vector2 = job["location"]
        var progress := fmod(resident_clock * (0.10 + float(i % 3) * 0.019) + float(i) * 0.23, 2.0)
        var t := progress if progress <= 1.0 else 2.0 - progress
        var tile_position := origin.lerp(destination, t) + Vector2(0.13 * float(i % 2), 0.15 * float(i % 3))
        var p := _iso(tile_position.x, tile_position.y)
        var s := zoom
        # Pequena sombra, corpo, cabeça e cor relacionada ao trabalho.
        var coat := Color("#577aa3")
        match str(job["kind"]):
            "fazenda": coat = Color("#c59b45")
            "serraria": coat = Color("#715332")
            "pedreira": coat = Color("#6a7980")
            "mercado": coat = Color("#b96a60")
            "quartel": coat = Color("#4767ac")
        draw_circle(p + Vector2(0, 2) * s, 3.3 * s, Color("#2d594b88"))
        draw_line(p + Vector2(0, -2) * s, p + Vector2(0, -10) * s, coat, 3.3 * s)
        draw_circle(p + Vector2(0, -13) * s, 3.2 * s, Color("#edc18c"))
        draw_line(p + Vector2(-3, -15) * s, p + Vector2(3, -15) * s, coat.darkened(0.15), 1.5 * s)

func snapshot_for_test() -> Dictionary:
    return city.duplicate(true)
