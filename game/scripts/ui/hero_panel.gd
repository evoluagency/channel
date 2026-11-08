extends PanelContainer
## CP002-B: interface leve, sem instanciar 31 modelos ou efeitos de combate.
signal close_requested
signal roster_changed(next_state: Dictionary)

const HERO_SYSTEM := preload("res://scripts/heroes/hero_system.gd")

var catalog: Dictionary = {}
var roster: Dictionary = {}
var selected_id: String = ""
var hero_list: VBoxContainer
var formation_row: HBoxContainer
var details: Label
var status_label: Label

func set_catalog_and_roster(next_catalog: Dictionary, next_roster: Dictionary) -> void:
    catalog = next_catalog
    roster = HERO_SYSTEM.normalize_roster(next_roster, catalog)
    selected_id = str(roster.get("selected_hero_id", "hero_pietro_001"))
    if is_node_ready():
        _refresh()

func _style() -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = Color("#192336f5")
    s.corner_radius_top_left = 17
    s.corner_radius_top_right = 17
    s.corner_radius_bottom_left = 17
    s.corner_radius_bottom_right = 17
    s.content_margin_left = 17
    s.content_margin_right = 17
    s.content_margin_top = 14
    s.content_margin_bottom = 14
    return s

func _ready() -> void:
    var viewport: Vector2 = get_viewport().get_visible_rect().size
    size = Vector2(minf(1130.0, viewport.x - 36.0), minf(570.0, viewport.y - 36.0))
    position = (viewport - size) * 0.5
    mouse_filter = Control.MOUSE_FILTER_STOP
    add_theme_stylebox_override("panel", _style())
    var root_box := VBoxContainer.new()
    root_box.add_theme_constant_override("separation", 10)
    add_child(root_box)
    var header := HBoxContainer.new()
    var title := Label.new()
    title.text = "HERÓIS  ·  TEMPORADA 1 — PRÉVIA TÉCNICA"
    title.add_theme_font_size_override("font_size", 24)
    title.add_theme_color_override("font_color", Color("#e8c48e"))
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title)
    var close_button := Button.new()
    close_button.text = "FECHAR  ✕"
    close_button.custom_minimum_size = Vector2(145, 48)
    close_button.pressed.connect(func(): close_requested.emit())
    header.add_child(close_button)
    root_box.add_child(header)
    var line := HBoxContainer.new()
    line.size_flags_vertical = Control.SIZE_EXPAND_FILL
    line.add_theme_constant_override("separation", 16)
    root_box.add_child(line)
    var left := ScrollContainer.new()
    left.custom_minimum_size.x = 250
    left.size_flags_vertical = Control.SIZE_EXPAND_FILL
    line.add_child(left)
    hero_list = VBoxContainer.new()
    hero_list.custom_minimum_size.x = 232
    hero_list.add_theme_constant_override("separation", 7)
    left.add_child(hero_list)
    var right := ScrollContainer.new()
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right.size_flags_vertical = Control.SIZE_EXPAND_FILL
    line.add_child(right)
    details = Label.new()
    details.custom_minimum_size.x = 565
    details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    details.add_theme_font_size_override("font_size", 17)
    details.add_theme_color_override("font_color", Color("#eee9dc"))
    right.add_child(details)
    var formation_title := Label.new()
    formation_title.text = "FORMAÇÃO  ·  toque no espaço para posicionar o herói selecionado"
    formation_title.add_theme_font_size_override("font_size", 15)
    formation_title.add_theme_color_override("font_color", Color("#e8c48e"))
    root_box.add_child(formation_title)
    formation_row = HBoxContainer.new()
    formation_row.add_theme_constant_override("separation", 7)
    root_box.add_child(formation_row)
    var controls := HBoxContainer.new()
    var remove_button := Button.new()
    remove_button.text = "RETIRAR SELECIONADO DA FORMAÇÃO"
    remove_button.custom_minimum_size.y = 40
    remove_button.pressed.connect(_remove_selected)
    controls.add_child(remove_button)
    status_label = Label.new()
    status_label.text = "Dados de demonstração: desbloqueios históricos ainda não ativos."
    status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    status_label.add_theme_font_size_override("font_size", 13)
    status_label.add_theme_color_override("font_color", Color("#c9c2ac"))
    controls.add_child(status_label)
    root_box.add_child(controls)
    _refresh()

func _clear_nodes(container: Node) -> void:
    for n in container.get_children():
        container.remove_child(n)
        n.queue_free()

func _hero_name(hero_id: String) -> String:
    if hero_id.is_empty():
        return "Vazio"
    var hero: Dictionary = HERO_SYSTEM.hero_by_id(catalog, hero_id)
    return str(hero.get("display_name", "?"))

func _select(hero_id: String) -> void:
    selected_id = hero_id
    roster["selected_hero_id"] = hero_id
    roster_changed.emit(roster.duplicate(true))
    _refresh()

func _on_slot(slot: String) -> void:
    var result: Dictionary = HERO_SYSTEM.assign(roster, catalog, slot, selected_id)
    if not bool(result.get("ok", false)):
        status_label.text = str(result.get("message", "Posição indisponível"))
        return
    roster = result["state"]
    roster_changed.emit(roster.duplicate(true))
    status_label.text = "%s adicionado à formação." % _hero_name(selected_id)
    _refresh()

func _remove_selected() -> void:
    roster = HERO_SYSTEM.remove_selected(roster, catalog)
    roster_changed.emit(roster.duplicate(true))
    status_label.text = "%s retirado da formação." % _hero_name(selected_id)
    _refresh()

func _refresh() -> void:
    if hero_list == null or details == null or formation_row == null:
        return
    _clear_nodes(hero_list)
    _clear_nodes(formation_row)
    var heroes: Array = catalog.get("heroes", [])
    for hero in heroes:
        var hero_id: String = str(hero.get("hero_id", ""))
        var btn := Button.new()
        btn.custom_minimum_size = Vector2(220, 57)
        btn.text = "%s  ·  %s" % [str(hero.get("display_name", "")), str(hero.get("period_title_t1", ""))]
        btn.add_theme_font_size_override("font_size", 15)
        btn.disabled = hero_id == selected_id
        btn.pressed.connect(_select.bind(hero_id))
        hero_list.add_child(btn)
    var selected: Dictionary = HERO_SYSTEM.hero_by_id(catalog, selected_id)
    if selected.is_empty():
        details.text = "Catálogo não disponível."
        return
    var attrs: Dictionary = selected.get("attributes_level1", {})
    var derived: Dictionary = HERO_SYSTEM.derived_stats(selected)
    var skills: Dictionary = selected.get("skills", {})
    var basic: Dictionary = skills.get("basic", {})
    var active: Dictionary = skills.get("active_1", {})
    var passive: Dictionary = skills.get("passive", {})
    var appearance: Dictionary = selected.get("appearance", {})
    var lines: Array[String] = [
        "%s   |   %s   |   %s" % [str(selected.get("display_name","")), str(selected.get("class","")).capitalize(), str(selected.get("force","")).capitalize()],
        "Idade: %s  ·  Altura: %s cm  ·  %s" % [str(selected.get("age_at_introduction", "")), str(appearance.get("height_cm", "")), str(selected.get("formation_position",""))],
        str(appearance.get("description", "")),
        "",
        "ATRIBUTOS — NÍVEL 1",
        "VIG %d     FOR %d     TEC %d     INT %d     ESP %d     AGI %d" % [int(attrs.get("VIG",0)),int(attrs.get("FOR",0)),int(attrs.get("TEC",0)),int(attrs.get("INT",0)),int(attrs.get("ESP",0)),int(attrs.get("AGI",0))],
        "PV %d     Foco %d     Ataque %d     Defesa %d" % [int(derived.get("HP",0)),int(derived.get("focus",0)),int(derived.get("physical_attack",0)),int(derived.get("physical_defense",0))],
        "",
        "HABILIDADES",
        "Básica: %s — %s" % [str(basic.get("name","")), str(basic.get("description",""))],
        "Ativa: %s (Foco %s; recarga %s rodadas)" % [str(active.get("name","")), str(active.get("focus_cost_proposed","?")), str(active.get("cooldown_rounds_proposed","?"))],
        str(active.get("description","")),
        "Passiva: %s — %s" % [str(passive.get("name","")), str(passive.get("description",""))],
        "",
        "HISTÓRIA",
        str(selected.get("lore_proposal","")),
        "",
        "VISUAL T1",
        str(selected.get("visual_t1_proposal",""))
    ]
    details.text = "\n".join(lines)
    var formation: Dictionary = roster.get("formation", {})
    for slot in HERO_SYSTEM.SLOTS:
        var btn := Button.new()
        btn.custom_minimum_size = Vector2(178, 56)
        btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var short_slot: String = "FRENTE" if slot.begins_with("vanguarda") else "TRÁS"
        var index: String = slot.get_slice("_", 1)
        btn.text = "%s %s\n%s" % [short_slot, index, _hero_name(str(formation.get(slot,"")))]
        btn.pressed.connect(_on_slot.bind(slot))
        formation_row.add_child(btn)
