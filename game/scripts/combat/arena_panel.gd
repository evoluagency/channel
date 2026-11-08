extends PanelContainer
## CP003-C — arena 3D de baixo custo, com comandos e reprodução visual de eventos.
## Visuais são marcadores provisórios, não os modelos finais dos quatro heróis.
## Não modifica economia, experiência, progresso ou saves.
signal close_requested

const ENGINE := preload("res://scripts/combat/pve_engine.gd")
const HERO_SYSTEM := preload("res://scripts/heroes/hero_system.gd")
const POSTURES := ["equilibrada", "cautelosa", "agressiva"]

var catalog: Dictionary = {}
var roster: Dictionary = {}
var battle_state: Dictionary = {}
var battle_serial: int = 0
var viewport_3d: SubViewport
var world_root: Node3D
var arena_actors: Node3D
var actor_nodes: Dictionary = {}
var scene_camera: Camera3D
var status_label: Label
var heroes_label: Label
var enemies_label: Label
var event_label: RichTextLabel
var posture_select: OptionButton
var hero_select: OptionButton
var target_select: OptionButton
var attack_button: Button
var auto_button: Button
var skill_button: Button
var playback_queue: Array = []
var playback_seconds: float = 0.0
var animating: bool = false
var seen_event_count: int = 0

func configure(next_catalog: Dictionary, next_roster: Dictionary) -> void:
    catalog = next_catalog
    roster = HERO_SYSTEM.normalize_roster(next_roster, catalog)
    if is_node_ready():
        begin_expedition()

static func default_enemies() -> Array:
    return [
        {"id": "enemy_stalker", "name": "Predador ancestral", "line": "front", "hp": 275, "attack": 37, "defense": 22, "initiative": 22, "attack_type": "physical"},
        {"id": "enemy_tracker", "name": "Caçador rival", "line": "back", "hp": 215, "attack": 34, "defense": 16, "initiative": 17, "attack_type": "physical"}
    ]

func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#101928f8")
    style.corner_radius_top_left = 18
    style.corner_radius_top_right = 18
    style.corner_radius_bottom_left = 18
    style.corner_radius_bottom_right = 18
    style.content_margin_left = 16
    style.content_margin_right = 16
    style.content_margin_top = 11
    style.content_margin_bottom = 11
    return style

func _label(text_value: String, font_size: int = 16, color_hex: String = "#ece6d8") -> Label:
    var label := Label.new()
    label.text = text_value
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color(color_hex))
    return label

func _button(text_value: String, height_px: float = 43.0) -> Button:
    var button := Button.new()
    button.text = text_value
    button.custom_minimum_size.y = height_px
    button.add_theme_font_size_override("font_size", 16)
    return button

func _ready() -> void:
    var screen: Vector2 = get_viewport().get_visible_rect().size
    size = Vector2(minf(1190.0, screen.x - 26.0), minf(689.0, screen.y - 20.0))
    position = (screen - size) * 0.5
    mouse_filter = Control.MOUSE_FILTER_STOP
    add_theme_stylebox_override("panel", _panel_style())

    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation", 7)
    add_child(layout)

    var header := HBoxContainer.new()
    var title := _label("VALDORA  |  ARENA TÁTICA · TEMPORADA 1", 22, "#f1cd8b")
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title)
    var restart := _button("REINICIAR", 39.0)
    restart.custom_minimum_size.x = 145
    restart.pressed.connect(begin_expedition)
    header.add_child(restart)
    var close_button := _button("FECHAR  ✕", 39.0)
    close_button.custom_minimum_size.x = 135
    close_button.pressed.connect(func() -> void: close_requested.emit())
    header.add_child(close_button)
    layout.add_child(header)

    status_label = _label("Preparando encontro...", 16, "#f0d49d")
    layout.add_child(status_label)

    var arena_view := SubViewportContainer.new()
    arena_view.name = "Arena 3D"
    arena_view.stretch = true
    arena_view.stretch_shrink = 2
    arena_view.custom_minimum_size.y = 270
    arena_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
    arena_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layout.add_child(arena_view)

    viewport_3d = SubViewport.new()
    viewport_3d.name = "Viewport 3D isolado"
    viewport_3d.size = Vector2i(890, 310)
    viewport_3d.own_world_3d = true
    viewport_3d.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
    arena_view.add_child(viewport_3d)

    _build_arena_scene()

    var teams := HBoxContainer.new()
    teams.add_theme_constant_override("separation", 16)
    heroes_label = _label("Heróis", 14)
    heroes_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    teams.add_child(heroes_label)
    enemies_label = _label("Adversários", 14)
    enemies_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    teams.add_child(enemies_label)
    layout.add_child(teams)

    var selection_row := HBoxContainer.new()
    selection_row.add_theme_constant_override("separation", 9)
    selection_row.add_child(_label("Postura", 15))
    posture_select = OptionButton.new()
    posture_select.custom_minimum_size.x = 157
    for posture in POSTURES:
        posture_select.add_item(posture.capitalize())
    selection_row.add_child(posture_select)
    selection_row.add_child(_label("Habilidade de", 15))
    hero_select = OptionButton.new()
    hero_select.custom_minimum_size.x = 178
    selection_row.add_child(hero_select)
    selection_row.add_child(_label("Priorizar", 15))
    target_select = OptionButton.new()
    target_select.custom_minimum_size.x = 190
    selection_row.add_child(target_select)
    layout.add_child(selection_row)

    var commands := HBoxContainer.new()
    commands.add_theme_constant_override("separation", 9)
    attack_button = _button("ATAQUE BÁSICO")
    attack_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    attack_button.pressed.connect(func() -> void: take_turn("none"))
    commands.add_child(attack_button)
    auto_button = _button("SEMIAUTOMÁTICO")
    auto_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    auto_button.pressed.connect(func() -> void: take_turn("auto"))
    commands.add_child(auto_button)
    skill_button = _button("ATIVAR HABILIDADE")
    skill_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    skill_button.pressed.connect(func() -> void: take_turn("manual"))
    commands.add_child(skill_button)
    layout.add_child(commands)

    event_label = RichTextLabel.new()
    event_label.name = "Eventos do combate"
    event_label.custom_minimum_size.y = 82
    event_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    event_label.scroll_following = true
    event_label.add_theme_font_size_override("normal_font_size", 14)
    layout.add_child(event_label)
    layout.add_child(_label("Protótipo offline: nenhum prêmio ou progressão é concedido.", 12, "#b7b9bb"))
    if not catalog.is_empty():
        begin_expedition()

func _material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.85
    return mat

func _mesh(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.mesh = mesh
    instance.position = pos
    instance.material_override = _material(color)
    parent.add_child(instance)
    return instance

func _build_arena_scene() -> void:
    world_root = Node3D.new()
    world_root.name = "Mundo de combate isolado"
    viewport_3d.add_child(world_root)
    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#263b4b")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#e6d5b0")
    env.ambient_light_energy = 0.65
    environment.environment = env
    world_root.add_child(environment)
    scene_camera = Camera3D.new()
    scene_camera.name = "Camera tática"
    scene_camera.position = Vector3(0.2, 10.5, 13.5)
    scene_camera.fov = 56.0
    scene_camera.current = true
    world_root.add_child(scene_camera)
    scene_camera.look_at(Vector3(0, 0.0, 0))
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-60, -20, 0)
    sun.light_energy = 0.9
    world_root.add_child(sun)
    var floor_mesh := PlaneMesh.new()
    floor_mesh.size = Vector2(17.0, 9.0)
    _mesh(world_root, floor_mesh, Vector3(0, -0.12, 0), Color("#69724b"))
    var divider_mesh := BoxMesh.new()
    divider_mesh.size = Vector3(0.06, 0.05, 8.0)
    _mesh(world_root, divider_mesh, Vector3(0, -0.04, 0), Color("#b9ab79"))
    for i in range(8):
        var stone := BoxMesh.new()
        stone.size = Vector3(0.45, 0.21, 0.4)
        _mesh(world_root, stone, Vector3(-7.6 + 2.1 * float(i), -0.03, -4.3), Color("#6f756e"))
    arena_actors = Node3D.new()
    arena_actors.name = "Combatentes visuais"
    world_root.add_child(arena_actors)

func _position_for(actor: Dictionary, index: int) -> Vector3:
    if str(actor["side"]) == "heroes":
        var front: bool = str(actor["line"]) == "front"
        var col: float = -2.0 if front else -4.5
        return Vector3(col, 0, -2.5 + float(index) * 1.65)
    var enemy_front: bool = str(actor["line"]) == "front"
    return Vector3(2.2 if enemy_front else 4.5, 0, -1.8 + float(index) * 2.3)

func _hero_palette(actor_id: String) -> Dictionary:
    match actor_id:
        "hero_pietro_001":
            return {"skin": Color("#d5a886"), "robe": Color("#566982"), "hair": Color("#b7985a")}
        "hero_henzo_002":
            return {"skin": Color("#6a3b2d"), "robe": Color("#40746a"), "hair": Color("#1c1918")}
        "hero_giulia_003":
            return {"skin": Color("#70442f"), "robe": Color("#bd9a64"), "hair": Color("#231d1b")}
        "hero_arthur_004":
            return {"skin": Color("#ddb99a"), "robe": Color("#9d493b"), "hair": Color("#d7bc73")}
    return {"skin": Color("#a4a2a1"), "robe": Color("#544c43"), "hair": Color("#333333")}

func _make_avatar(actor: Dictionary, index: int) -> void:
    var unit := Node3D.new()
    unit.name = str(actor["name"])
    unit.position = _position_for(actor, index)
    arena_actors.add_child(unit)
    actor_nodes[str(actor["id"])] = unit
    var palette: Dictionary = _hero_palette(str(actor["id"]))
    var torso := CapsuleMesh.new()
    torso.radius = 0.29
    torso.height = 1.05
    _mesh(unit, torso, Vector3(0, 0.67, 0), palette["robe"])
    var head := SphereMesh.new()
    head.radius = 0.23
    head.height = 0.43
    _mesh(unit, head, Vector3(0, 1.43, 0), palette["skin"])
    var hair := SphereMesh.new()
    hair.radius = 0.23
    hair.height = 0.20
    _mesh(unit, hair, Vector3(0, 1.62, -0.03), palette["hair"])
    var arm := BoxMesh.new()
    arm.size = Vector3(0.82, 0.17, 0.20)
    _mesh(unit, arm, Vector3(0, 0.88, 0), palette["skin"])
    var legs := BoxMesh.new()
    legs.size = Vector3(0.42, 0.48, 0.28)
    _mesh(unit, legs, Vector3(0, 0.18, 0), Color("#4a4237"))

func _populate_actors() -> void:
    for child in arena_actors.get_children():
        arena_actors.remove_child(child)
        child.queue_free()
    actor_nodes.clear()
    for side in ["heroes", "enemies"]:
        var party: Array = battle_state.get(side, [])
        for i in range(party.size()):
            _make_avatar(party[i], i)

func _fill_selections() -> void:
    hero_select.clear()
    target_select.clear()
    var heroes: Array = battle_state.get("heroes", [])
    for hero in heroes:
        hero_select.add_item(str(hero["name"]))
        hero_select.set_item_metadata(hero_select.item_count - 1, str(hero["id"]))
    var enemies: Array = battle_state.get("enemies", [])
    for enemy in enemies:
        if int(enemy["hp"]) > 0:
            var label: String = "%s (%s)" % [str(enemy["name"]), "frente" if str(enemy["line"]) == "front" else "trás"]
            target_select.add_item(label)
            target_select.set_item_metadata(target_select.item_count - 1, str(enemy["id"]))
    if hero_select.item_count > 0:
        hero_select.select(0)
    if target_select.item_count > 0:
        target_select.select(0)

func begin_expedition() -> bool:
    if catalog.is_empty():
        return false
    battle_serial += 1
    # Identificador local para o replay; não envolve relógio, servidor ou RNG global.
    battle_state = ENGINE.begin_battle(catalog, roster, default_enemies(), 202600 + battle_serial)
    playback_queue.clear()
    animating = false
    playback_seconds = 0.0
    seen_event_count = battle_state.get("events", []).size()
    if not bool(battle_state.get("ok", false)):
        if status_label != null:
            status_label.text = "Formação inválida: selecione de um a quatro heróis."
        _set_commands_enabled(false)
        return false
    _populate_actors()
    _fill_selections()
    if posture_select != null:
        posture_select.select(0)
    if event_label != null:
        event_label.clear()
        event_label.append_text("Encontro de demonstração iniciado. Sem recompensas.\n")
    _refresh()
    return true

func _orders(mode: String) -> Dictionary:
    var posture: String = POSTURES[posture_select.selected] if posture_select.selected >= 0 else "equilibrada"
    var result: Dictionary = {"skills_mode": mode, "posture": posture}
    if mode == "manual" and hero_select.selected >= 0:
        result["activate_hero_id"] = str(hero_select.get_item_metadata(hero_select.selected))
    if target_select.selected >= 0:
        result["focus_enemy_id"] = str(target_select.get_item_metadata(target_select.selected))
    return result

func take_turn(mode: String = "auto") -> bool:
    if animating or str(battle_state.get("status", "")) != "active":
        return false
    if not ["none", "auto", "manual"].has(mode):
        return false
    var candidate: Dictionary = ENGINE.advance_round(battle_state, _orders(mode))
    if not bool(candidate.get("ok", false)):
        return false
    battle_state = candidate
    var events: Array = battle_state["events"]
    playback_queue = events.slice(seen_event_count, events.size())
    seen_event_count = events.size()
    animating = not playback_queue.is_empty()
    playback_seconds = 0.0
    _set_commands_enabled(false)
    _refresh()
    return true

func _set_commands_enabled(enabled: bool) -> void:
    if attack_button == null:
        return
    attack_button.disabled = not enabled
    auto_button.disabled = not enabled
    skill_button.disabled = not enabled

func _refresh() -> void:
    if status_label == null:
        return
    if not bool(battle_state.get("ok", false)):
        return
    var status: String = str(battle_state["status"])
    var result_text := "EM COMBATE"
    if status == "resolved":
        match str(battle_state.get("winner", "")):
            "heroes":
                result_text = "VITÓRIA DOS HERÓIS"
            "enemies":
                result_text = "DERROTA DOS HERÓIS"
            _:
                result_text = "EMPATE — LIMITE DE 8 RODADAS"
    status_label.text = "RODADA %d/8   •   %s   •   Seed %d" % [int(battle_state["round"]), result_text, int(battle_state["seed"])]
    var hero_lines: Array[String] = []
    var enemy_lines: Array[String] = []
    for hero in battle_state["heroes"]:
        hero_lines.append("%s %d/%d PV" % [str(hero["name"]), int(hero["hp"]), int(hero["max_hp"])])
    for enemy in battle_state["enemies"]:
        enemy_lines.append("%s %d/%d PV" % [str(enemy["name"]), int(enemy["hp"]), int(enemy["max_hp"])])
    heroes_label.text = "  •  ".join(hero_lines)
    enemies_label.text = "  •  ".join(enemy_lines)
    if not animating:
        _set_commands_enabled(status == "active")
        for party in [battle_state["heroes"], battle_state["enemies"]]:
            for actor in party:
                var id: String = str(actor["id"])
                if actor_nodes.has(id):
                    var avatar: Node3D = actor_nodes[id]
                    avatar.visible = int(actor["hp"]) > 0
        var previous_target: String = ""
        if target_select.selected >= 0 and target_select.item_count > 0:
            previous_target = str(target_select.get_item_metadata(target_select.selected))
        target_select.clear()
        for enemy in battle_state["enemies"]:
            if int(enemy["hp"]) <= 0:
                continue
            target_select.add_item(str(enemy["name"]))
            target_select.set_item_metadata(target_select.item_count - 1, str(enemy["id"]))
            if previous_target == str(enemy["id"]):
                target_select.select(target_select.item_count - 1)
        if target_select.item_count > 0 and target_select.selected < 0:
            target_select.select(0)

func _process(delta: float) -> void:
    if not animating:
        return
    playback_seconds += delta
    if playback_seconds < 0.11:
        return
    playback_seconds = 0.0
    if playback_queue.is_empty():
        animating = false
        _refresh()
        return
    var event: Dictionary = playback_queue.pop_front()
    _replay_event(event)
    if playback_queue.is_empty():
        # Último evento deve concluir antes de liberar novos comandos.
        playback_seconds = -0.15

func _effect_at(id: String, color: Color) -> void:
    if not actor_nodes.has(id):
        return
    var avatar: Node3D = actor_nodes[id]
    var sphere := SphereMesh.new()
    sphere.radius = 0.38
    sphere.height = 0.65
    var flash := _mesh(world_root, sphere, avatar.position + Vector3(0, 0.9, 0), color)
    var tween := create_tween()
    flash.scale = Vector3(0.12, 0.12, 0.12)
    tween.tween_property(flash, "scale", Vector3(1.25, 1.25, 1.25), 0.20)
    tween.tween_callback(flash.queue_free)

func _attack_projectile(event: Dictionary) -> void:
    var actor_id: String = str(event.get("actor_id", ""))
    var target_id: String = str(event.get("target_id", ""))
    if not actor_nodes.has(actor_id) or not actor_nodes.has(target_id):
        return
    var attacker: Node3D = actor_nodes[actor_id]
    var target: Node3D = actor_nodes[target_id]
    var orb := SphereMesh.new()
    orb.radius = 0.12
    orb.height = 0.24
    var node := _mesh(world_root, orb, attacker.position + Vector3(0, 1.05, 0), Color("#ffce80"))
    var tween := create_tween()
    tween.tween_property(node, "position", target.position + Vector3(0, 0.9, 0), 0.22)
    tween.tween_callback(node.queue_free)

func _replay_event(event: Dictionary) -> void:
    var kind: String = str(event.get("type", ""))
    match kind:
        "attack_started":
            _attack_projectile(event)
        "damage_applied":
            _effect_at(str(event.get("target_id", "")), Color("#dc523f"))
            event_label.append_text("Rodada %d: %s causou %d dano em %s.\n" % [
                int(event.get("round", 0)), str(event.get("actor_id", "")),
                int(event.get("amount", 0)), str(event.get("target_id", ""))])
        "skill_triggered":
            _effect_at(str(event.get("actor_id", "")), Color("#83c5f6"))
            event_label.append_text("HABILIDADE: %s\n" % str(event.get("skill", "")))
        "healed":
            _effect_at(str(event.get("target_id", "")), Color("#80b980"))
            event_label.append_text("CURA: %s recuperou %d PV.\n" % [
                str(event.get("target_id", "")), int(event.get("amount", 0))])
        "shield_blocked":
            _effect_at(str(event.get("target_id", "")), Color("#90aadd"))
        "battle_resolved":
            event_label.append_text("Combate encerrado: %s. Sem recompensas.\n" % str(event.get("winner", "")))
