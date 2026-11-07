extends Node3D
## EVOLU Channel — Valdora, primeira fatia vertical.
## Protótipo com geometria 3D original, sem Minecraft e sem rede.

const SAVE_PATH := "user://channel_save.json"
const INITIAL_GOLD := 30
const WALK_SPEED := 7.5
const WORLD_SIZE := 96.0
const START_POS := Vector3(0, 0.2, 15)

var coins: int = INITIAL_GOLD
var bank_coins: int = 0
var potions: int = 0
var player: CharacterBody3D
var player_model: Node3D
var camera: Camera3D
var balance_label: Label
var message_label: Label
var action_button: Button
var dialogue_layer: PanelContainer
var joystick_base: Panel
var joystick_dot: Panel
var joystick_touch_id: int = -1
var joystick_start := Vector2.ZERO
var mobile_axis := Vector2.ZERO
var game_paused_for_dialogue := false
var npcs: Array[Dictionary] = []
var clock: float = 0.0

func _ready() -> void:
    _setup_input()
    _load_save()
    _build_environment()
    _build_terrain()
    _build_valdora()
    _build_player()
    _build_ui()
    _update_hud()
    _notify("Bem-vindo a Valdora. Conheça o Mercado Real!")

func _setup_input() -> void:
    var mapping := {
        "channel_left": [KEY_A, KEY_LEFT],
        "channel_right": [KEY_D, KEY_RIGHT],
        "channel_forward": [KEY_W, KEY_UP],
        "channel_back": [KEY_S, KEY_DOWN],
        "channel_interact": [KEY_E]
    }
    for action in mapping.keys():
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        for key_code in mapping[action]:
            var key := InputEventKey.new()
            key.physical_keycode = key_code
            InputMap.action_add_event(action, key)

func _mat(color_hex: String, rough: float = 1.0) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(color_hex)
    material.roughness = rough
    return material

func _box(name: String, pos: Vector3, size: Vector3, color_hex: String, solid: bool = false) -> Node3D:
    var root: Node3D
    if solid:
        var body := StaticBody3D.new()
        var collider := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collider.shape = shape
        body.add_child(collider)
        root = body
    else:
        root = Node3D.new()
    root.name = name
    root.position = pos
    var visual := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    visual.mesh = mesh
    visual.material_override = _mat(color_hex)
    root.add_child(visual)
    add_child(root)
    return root

func _cylinder(name: String, pos: Vector3, radius: float, height: float, color_hex: String, top_radius: float = -1.0) -> Node3D:
    var holder := Node3D.new()
    holder.name = name
    holder.position = pos
    var mesh := CylinderMesh.new()
    mesh.bottom_radius = radius
    mesh.top_radius = radius if top_radius < 0.0 else top_radius
    mesh.height = height
    mesh.radial_segments = 8
    var visual := MeshInstance3D.new()
    visual.mesh = mesh
    visual.material_override = _mat(color_hex)
    holder.add_child(visual)
    add_child(holder)
    return holder

func _build_environment() -> void:
    var world_environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#93acc5")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#d2c8b9")
    env.ambient_light_energy = 0.7
    world_environment.environment = env
    add_child(world_environment)

    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-38, -34, 0)
    light.light_color = Color("#fff0d7")
    light.light_energy = 1.5
    light.shadow_enabled = false # prioriza aparelhos modestos
    add_child(light)

func _build_terrain() -> void:
    _box("Terreno verde", Vector3(0, -0.55, 0), Vector3(WORLD_SIZE, 1.1, WORLD_SIZE), "#608264", true)
    _box("Rua norte-sul", Vector3(0, 0.025, -6), Vector3(8, 0.08, 84), "#b7aa91")
    _box("Rua leste-oeste", Vector3(0, 0.026, 2), Vector3(83, 0.08, 8), "#b7aa91")
    _box("Rua secundária mercado", Vector3(24, 0.03, -6), Vector3(5, 0.08, 36), "#b8ad9a")
    _box("Riacho leste", Vector3(44, 0.035, 0), Vector3(7, 0.07, 92), "#397e9e")
    _box("Ponte de madeira", Vector3(44, 0.16, 2), Vector3(9, 0.35, 7), "#886643", true)
    for i in range(-4, 5):
        _box("Pedra da via norte %d" % i, Vector3(-3.7, 0.085, float(i) * 9), Vector3(0.45, 0.1, 3), "#d5c8ad")
        _box("Pedra da via sul %d" % i, Vector3(3.7, 0.085, float(i) * 9), Vector3(0.45, 0.1, 3), "#d5c8ad")

    for x in [-38.0, -32.0, -22.0, 18.0, 38.0]:
        for z in [-37.0, -25.0, 19.0, 30.0]:
            if x > 16.0 and z < 20.0:
                continue
            _tree(Vector3(x, 0, z))
    for i in range(18):
        var ax := -41.0 + float((i * 13) % 78)
        var az := -43.0 + float((i * 19) % 80)
        if absf(ax) > 9.0 and absf(az) > 10.0:
            _box("Arbusto %d" % i, Vector3(ax, 0.6, az), Vector3(1.3, 1.2, 1.4), "#426a48")

func _tree(pos: Vector3) -> void:
    _cylinder("Tronco", pos + Vector3(0, 2.1, 0), 0.36, 4.2, "#695138")
    _cylinder("Copa base", pos + Vector3(0, 5.1, 0), 2.4, 3.3, "#4c7045", 0.9)
    _cylinder("Copa topo", pos + Vector3(0, 7.0, 0), 1.5, 2.2, "#46663f", 0.0)

func _building(name: String, pos: Vector3, width: float, depth: float, wall: String, roof: String) -> void:
    # A fundacao fica nivelada ao solo: CharacterBody3D nao possui degrau automatico.
    _box(name + " fundacao", pos + Vector3(0, -0.18, 0), Vector3(width, 0.36, depth), "#7b7066", true)
    # Fachada com vao real e livre (2.7 x 3.6 metros). Uma fachada unica
    # com colisao bloquearia todas as portas apesar da aparencia do modelo.
    var doorway_width := 2.7
    var doorway_height := 3.6
    var side_width := (width - doorway_width) / 2.0
    var front := -depth / 2.0
    for side in [-1.0, 1.0]:
        var offset_x: float = float(side) * (doorway_width / 2.0 + side_width / 2.0)
        _box(name + " fachada lateral", pos + Vector3(offset_x, 3.0, front), Vector3(side_width, 5.4, 0.65), wall, true)
    var lintel_height := 5.4 - doorway_height
    _box(name + " verga", pos + Vector3(0, doorway_height + lintel_height / 2.0 + 0.3, front), Vector3(doorway_width, lintel_height, 0.65), wall, true)
    _box(name + " fundo", pos + Vector3(0, 3.0, depth / 2.0), Vector3(width, 5.4, 0.65), wall, true)
    _box(name + " parede esq", pos + Vector3(-width / 2.0, 3.0, 0), Vector3(0.65, 5.4, depth), wall, true)
    _box(name + " parede dir", pos + Vector3(width / 2.0, 3.0, 0), Vector3(0.65, 5.4, depth), wall, true)
    _box(name + " telhado", pos + Vector3(0, 6.1, 0), Vector3(width + 1.0, 1.1, depth + 1.0), roof)
    _box(name + " placa", pos + Vector3(0, 4.6, front - 0.55), Vector3(width * 0.45, 0.75, 0.25), "#80629b")
    # A passagem central permanece aberta, sem malha/collider de porta ficticia.
    _box(name + " soleira", pos + Vector3(0, -0.06, front - 0.25), Vector3(doorway_width, 0.12, 1.0), "#bca888")
    for side in [-1.0, 1.0]:
        _box(name + " janela", pos + Vector3(side * width * 0.28, 3.1, -depth / 2.0 - 0.58), Vector3(1.5, 1.7, 0.3), "#99b7bd")

func _stall(name: String, pos: Vector3, roof_color: String) -> void:
    _box(name + " tablado", pos + Vector3(0, 0.35, 0), Vector3(4.8, 0.7, 4.5), "#8b6546")
    for x in [-2.0, 2.0]:
        for z in [-1.8, 1.8]:
            _box(name + " poste", pos + Vector3(x, 2.4, z), Vector3(0.3, 4.2, 0.3), "#614632")
    _box(name + " toldo", pos + Vector3(0, 4.8, 0), Vector3(5.4, 0.55, 5.0), roof_color)
    _box(name + " balao", pos + Vector3(0, 1.1, -1.9), Vector3(3.7, 0.7, 0.45), "#d2b176")

func _tower(pos: Vector3) -> void:
    _cylinder("Torre de Valdora", pos + Vector3(0, 7.8, 0), 4.7, 15.6, "#b5a995")
    _cylinder("Cobertura da torre", pos + Vector3(0, 17.5, 0), 5.7, 5.1, "#624a6e", 0.0)
    _box("Estandarte da torre", pos + Vector3(0, 14.6, -4.85), Vector3(1.2, 3.2, 0.18), "#77528d")

func _build_valdora() -> void:
    # Praça central. O ponto de nascimento está no caminho, ao sul da fonte.
    _box("Placa da praça", Vector3(0, 0.14, -5), Vector3(24, 0.25, 24), "#c3b69d")
    _box("Passarela de entrada", Vector3(0, 0.15, 9), Vector3(6, 0.25, 11), "#b8a88e")
    _cylinder("Fonte base", Vector3(0, 0.68, -9), 4.7, 1.35, "#a6a5a3")
    _cylinder("Água da fonte", Vector3(0, 1.39, -9), 3.85, 0.12, "#5399b4")
    _cylinder("Coluna da fonte", Vector3(0, 2.25, -9), 0.77, 2.6, "#c9c1b1")
    _cylinder("Topo da fonte", Vector3(0, 3.95, -9), 1.3, 0.75, "#e0cb9f")
    for x in [-10.5, 10.5]:
        for z in [-20.0, 2.0]:
            _box("Canteiro", Vector3(x, 0.35, z), Vector3(4.3, 0.7, 4.3), "#657a52")
            _cylinder("Flor amarela", Vector3(x, 0.95, z), 0.25, 0.6, "#dec47e")

    # Castelo ao norte: portão em arco simplificado, torres e muralhas.
    _box("Muralha oeste", Vector3(-24, 6.0, -40), Vector3(29, 12, 3.8), "#b5a58f", true)
    _box("Muralha leste", Vector3(24, 6.0, -40), Vector3(29, 12, 3.8), "#b5a58f", true)
    _box("Lintel do portão", Vector3(0, 10.4, -40), Vector3(20, 4, 4), "#c0b39a", true)
    _box("Ponte do castelo", Vector3(0, 0.12, -40), Vector3(10, 0.24, 12), "#c3ac82")
    _tower(Vector3(-10, 0, -40))
    _tower(Vector3(10, 0, -40))
    _box("Estandarte real", Vector3(0, 13.3, -37.9), Vector3(2.0, 4.7, 0.25), "#76539c")
    _box("Portal interior", Vector3(0, 0.8, -46), Vector3(25, 1.5, 4), "#8b857e")

    # Guilda/quartel a oeste.
    _building("Guilda de Valdora", Vector3(-26, 0, -9), 13, 12, "#b9ae98", "#705569")
    _box("Pátio da guilda", Vector3(-26, 0.09, 9), Vector3(20, 0.18, 18), "#ad9c84")
    for x in [-33.0, -26.0, -19.0]:
        _box("Alvo de treino", Vector3(x, 2.0, 17), Vector3(2.7, 2.7, 0.6), "#cfbf93")
        _box("Centro do alvo", Vector3(x, 2.0, 16.59), Vector3(0.9, 0.9, 0.23), "#935b63")

    # Comércio a leste. Construções cenográficas, transações simplificadas nos NPCs.
    _building("Banco Real", Vector3(27, 0, 13), 13.5, 11.0, "#c7b6a4", "#6b526c")
    _building("Oficina do Ferreiro", Vector3(27, 0, -20), 13.5, 10.0, "#ab9f8d", "#7f6157")
    _stall("Banca de especiarias", Vector3(17, 0, -6), "#875477")
    _stall("Banca de suprimentos", Vector3(32, 0, -6), "#bb8c5a")
    _box("Bigorna", Vector3(33.6, 1.2, -12.9), Vector3(2.2, 2.4, 1.2), "#43484c")
    _box("Forno", Vector3(35.5, 1.6, -18.6), Vector3(2.3, 3.2, 2.5), "#58443c")
    _box("Braseiro", Vector3(35.5, 3.27, -18.6), Vector3(1.4, 0.3, 1.6), "#e9ab53")

    _npc("Elena · Mercadora", Vector3(19, 0, -1), "#9a6882", "merchant")
    _npc("Dorian · Banqueiro", Vector3(27, 0, 4), "#7e6897", "bank")
    _npc("Bram · Ferreiro", Vector3(32, 0, -13), "#886756", "blacksmith")
    _npc("Sargento Orlan", Vector3(-20, 0, 9), "#5c7483", "guard")

    # Luminárias simples sem efeitos caros.
    for pos in [Vector3(-5, 0, 14), Vector3(5, 0, 14), Vector3(-5, 0, -26), Vector3(5, 0, -26), Vector3(14, 0, 5), Vector3(-14, 0, 5)]:
        _box("Poste de luz", pos + Vector3(0, 2.7, 0), Vector3(0.28, 5.4, 0.28), "#54463f")
        _box("Lanterna dourada", pos + Vector3(0, 5.5, 0), Vector3(0.9, 1.0, 0.9), "#efca80")

func _npc(label: String, pos: Vector3, robe: String, kind: String) -> void:
    var npc := Node3D.new()
    npc.name = label
    npc.position = pos
    add_child(npc)
    _box(label + " corpo", pos + Vector3(0, 1.15, 0), Vector3(1.05, 1.8, 0.7), robe)
    _box(label + " cabeça", pos + Vector3(0, 2.6, 0), Vector3(0.75, 0.82, 0.75), "#d0a682")
    _box(label + " cabelo", pos + Vector3(0, 3.0, 0), Vector3(0.84, 0.26, 0.83), "#483d36")
    _box(label + " base", pos + Vector3(0, 0.14, 0), Vector3(2.2, 0.28, 2.2), "#b6a889")
    npcs.append({"label": label, "position": pos, "kind": kind})

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Aventureiro"
    player.position = START_POS
    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.42
    capsule.height = 2.4
    collider.position = Vector3(0, 1.2, 0)
    collider.shape = capsule
    player.add_child(collider)
    add_child(player)
    player_model = Node3D.new()
    player_model.position = Vector3(0, 1.1, 0)
    player.add_child(player_model)
    _player_box("Peitoral", Vector3(0, 0, 0), Vector3(0.85, 1.15, 0.55), "#53657a")
    _player_box("Cabeça", Vector3(0, 0.91, 0), Vector3(0.65, 0.7, 0.65), "#d4b18d")
    _player_box("Elmo", Vector3(0, 1.23, 0), Vector3(0.77, 0.19, 0.73), "#59667d")
    _player_box("Perna esquerda", Vector3(-0.22, -0.87, 0), Vector3(0.3, 0.65, 0.36), "#434b54")
    _player_box("Perna direita", Vector3(0.22, -0.87, 0), Vector3(0.3, 0.65, 0.36), "#434b54")
    _player_box("Escudo", Vector3(-0.68, 0.12, -0.08), Vector3(0.22, 1.25, 0.93), "#8f718f")
    _player_box("Brasão", Vector3(-0.82, 0.10, -0.10), Vector3(0.06, 0.55, 0.42), "#d2b171")
    camera = Camera3D.new()
    camera.current = true
    camera.fov = 61
    camera.near = 0.1
    camera.far = 150.0
    add_child(camera)
    _camera_follow(1.0)

func _player_box(name: String, pos: Vector3, size: Vector3, color_hex: String) -> void:
    var mesh := BoxMesh.new()
    mesh.size = size
    var visual := MeshInstance3D.new()
    visual.name = name
    visual.mesh = mesh
    visual.position = pos
    visual.material_override = _mat(color_hex)
    player_model.add_child(visual)

func _camera_follow(weight: float) -> void:
    var target := player.global_position + Vector3(0, 7.9, 12.5)
    camera.global_position = camera.global_position.lerp(target, weight)
    camera.look_at(player.global_position + Vector3(0, 1.5, 0), Vector3.UP)

func _physics_process(delta: float) -> void:
    if player == null:
        return
    clock += delta
    var direction2 := Vector2.ZERO
    if not game_paused_for_dialogue:
        direction2 = Input.get_vector("channel_left", "channel_right", "channel_forward", "channel_back")
        if mobile_axis.length_squared() > 0.02:
            direction2 = mobile_axis
    var direction := Vector3(direction2.x, 0, direction2.y)
    if direction.length_squared() > 1.0:
        direction = direction.normalized()
    player.velocity.x = direction.x * WALK_SPEED
    player.velocity.z = direction.z * WALK_SPEED
    if not player.is_on_floor():
        player.velocity.y -= 23.0 * delta
    else:
        player.velocity.y = -0.05
    player.move_and_slide()
    if direction.length_squared() > 0.02:
        player_model.rotation.y = lerp_angle(player_model.rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 8.0))
    _camera_follow(minf(1.0, delta * 5.0))
    _update_nearby_message()
    if Input.is_action_just_pressed("channel_interact"):
        _interact()
    if Input.is_key_pressed(KEY_ESCAPE) and game_paused_for_dialogue:
        _close_dialogue()

func _make_panel(color_hex: String, radius: int = 14) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(color_hex)
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.content_margin_left = 10.0
    style.content_margin_right = 10.0
    style.content_margin_top = 9.0
    style.content_margin_bottom = 9.0
    return style

func _build_ui() -> void:
    var viewport_size := get_viewport().get_visible_rect().size
    var layer := CanvasLayer.new()
    layer.name = "Interface"
    add_child(layer)

    var brand := Label.new()
    brand.name = "Marca"
    brand.text = "EVOLU  CHANNEL       |       REINO DE VALDORA"
    brand.position = Vector2(24, 18)
    brand.add_theme_font_size_override("font_size", 24)
    brand.add_theme_color_override("font_color", Color("#fff3dd"))
    layer.add_child(brand)

    balance_label = Label.new()
    balance_label.position = Vector2(24, 55)
    balance_label.add_theme_font_size_override("font_size", 18)
    balance_label.add_theme_color_override("font_color", Color("#eed39d"))
    layer.add_child(balance_label)

    message_label = Label.new()
    message_label.name = "Objetivo"
    message_label.position = Vector2(24, 93)
    message_label.custom_minimum_size = Vector2(650, 0)
    message_label.add_theme_font_size_override("font_size", 17)
    message_label.add_theme_color_override("font_color", Color("#fff5d8"))
    layer.add_child(message_label)

    joystick_start = Vector2(115, viewport_size.y - 112)
    joystick_base = Panel.new()
    joystick_base.name = "Controle de movimento"
    joystick_base.position = joystick_start - Vector2(70, 70)
    joystick_base.size = Vector2(140, 140)
    joystick_base.add_theme_stylebox_override("panel", _make_panel("#29364e99", 70))
    joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(joystick_base)

    joystick_dot = Panel.new()
    joystick_dot.position = Vector2(45, 45)
    joystick_dot.size = Vector2(50, 50)
    joystick_dot.add_theme_stylebox_override("panel", _make_panel("#c8a86fcc", 25))
    joystick_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
    joystick_base.add_child(joystick_dot)

    action_button = Button.new()
    action_button.name = "Interagir"
    action_button.text = "INTERAGIR"
    action_button.position = Vector2(viewport_size.x - 204, viewport_size.y - 146)
    action_button.size = Vector2(174, 88)
    action_button.add_theme_font_size_override("font_size", 19)
    action_button.add_theme_stylebox_override("normal", _make_panel("#76549dcc"))
    action_button.add_theme_stylebox_override("hover", _make_panel("#8b65accd"))
    action_button.add_theme_stylebox_override("pressed", _make_panel("#5d4482dd"))
    action_button.pressed.connect(_interact)
    layer.add_child(action_button)

    var help := Label.new()
    help.position = Vector2(viewport_size.x - 480, 18)
    help.text = "WASD / setas  •  E para conversar"
    help.add_theme_font_size_override("font_size", 16)
    help.add_theme_color_override("font_color", Color("#eee6dc"))
    layer.add_child(help)

    # Visivel apenas em versoes de desenvolvimento: diagnostico executado
    # no proprio motor Godot, sem servidor nem dados da conta do jogador.
    if OS.is_debug_build():
        var diagnostic_button := Button.new()
        diagnostic_button.name = "Auto teste Valdora"
        diagnostic_button.text = "AUTO TESTE"
        diagnostic_button.position = Vector2(viewport_size.x - 205, 78)
        diagnostic_button.size = Vector2(175, 49)
        diagnostic_button.add_theme_font_size_override("font_size", 17)
        diagnostic_button.pressed.connect(_run_diagnostics)
        layer.add_child(diagnostic_button)

    dialogue_layer = PanelContainer.new()
    dialogue_layer.name = "Dialogo"
    dialogue_layer.position = Vector2(viewport_size.x * 0.28, viewport_size.y * 0.53)
    dialogue_layer.size = Vector2(viewport_size.x * 0.44, viewport_size.y * 0.34)
    dialogue_layer.add_theme_stylebox_override("panel", _make_panel("#181d30f5", 16))
    dialogue_layer.visible = false
    layer.add_child(dialogue_layer)

func _run_diagnostics() -> void:
    var results: Dictionary = {}
    results["spawn_no_reino"] = absf(START_POS.x) <= WORLD_SIZE / 2.0 and absf(START_POS.z) <= WORLD_SIZE / 2.0
    results["jogador"] = player != null and is_instance_valid(player)
    results["camera"] = camera != null and is_instance_valid(camera) and camera.current
    results["quatro_npcs"] = npcs.size() == 4
    results["mercador"] = npcs.any(func(npc: Dictionary): return npc.get("kind") == "merchant")
    results["banqueiro"] = npcs.any(func(npc: Dictionary): return npc.get("kind") == "bank")
    results["economia_valida"] = coins >= 0 and bank_coins >= 0 and potions >= 0
    results["interface"] = action_button != null and joystick_base != null and balance_label != null
    # Testa gravacao no sandbox local sem tocar no progresso da pessoa.
    var path := "user://channel_diagnostic.tmp"
    var file := FileAccess.open(path, FileAccess.WRITE)
    var writable := file != null
    if writable:
        file.store_string("VALDORA_TESTE")
        file.close()
        var readback := FileAccess.get_file_as_string(path)
        writable = readback == "VALDORA_TESTE"
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    results["armazenamento_local"] = writable
    var passed := 0
    for check in results.keys():
        if results[check]:
            passed += 1
    var success := passed == results.size()
    var summary := "VALDORA: %d/%d testes OK" % [passed, results.size()]
    if not success:
        summary = "VALDORA: %d/%d testes, verifique console" % [passed, results.size()]
    _notify(summary)
    print("[CHANNEL_DIAGNOSTIC] ", JSON.stringify({"success": success, "summary": summary, "checks": results}))

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed and joystick_touch_id == -1 and touch.position.x < get_viewport().get_visible_rect().size.x * 0.42 and touch.position.y > get_viewport().get_visible_rect().size.y * 0.50:
            joystick_touch_id = touch.index
            _update_joystick(touch.position)
        elif not touch.pressed and touch.index == joystick_touch_id:
            joystick_touch_id = -1
            mobile_axis = Vector2.ZERO
            _update_joystick(joystick_start)
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if drag.index == joystick_touch_id:
            _update_joystick(drag.position)

func _update_joystick(touch_position: Vector2) -> void:
    var relative := (touch_position - joystick_start).limit_length(60.0)
    mobile_axis = relative / 60.0
    if joystick_dot != null:
        joystick_dot.position = Vector2(45, 45) + relative

func _nearest_npc() -> Dictionary:
    if player == null:
        return {}
    var best: Dictionary = {}
    var dist := 4.7
    for npc in npcs:
        var distance := player.global_position.distance_to(npc["position"] + Vector3(0, 1.0, 0))
        if distance < dist:
            dist = distance
            best = npc
    return best

func _update_nearby_message() -> void:
    if game_paused_for_dialogue:
        return
    var npc := _nearest_npc()
    if npc.is_empty():
        action_button.text = "EXPLORAR"
    else:
        action_button.text = "CONVERSAR"

func _interact() -> void:
    if game_paused_for_dialogue:
        return
    var npc := _nearest_npc()
    if npc.is_empty():
        _notify("Explore Valdora e aproxime-se de um comerciante.")
        return
    match npc["kind"]:
        "merchant":
            _dialogue(npc["label"], "Bem-vindo ao Mercado Real. Uma poção custa 10 moedas.", [
                {"name":"Comprar poção · 10 moedas", "code":"buy_potion"},
                {"name":"Voltar", "code":"close"}])
        "bank":
            _dialogue(npc["label"], "O banco guarda suas moedas. Depósito e saque: 5 moedas por operação.", [
                {"name":"Depositar 5 moedas", "code":"deposit"},
                {"name":"Sacar 5 moedas", "code":"withdraw"},
                {"name":"Voltar", "code":"close"}])
        "blacksmith":
            _dialogue(npc["label"], "As forjas de Valdora estão abertas. Equipamentos especiais chegarão em versões futuras.", [{"name":"Entendido", "code":"close"}])
        "guard":
            _dialogue(npc["label"], "Bem-vindo, aventureiro. A Guilda ainda prepara as primeiras expedições.", [{"name":"Entendido", "code":"close"}])

func _dialogue(title: String, description: String, choices: Array) -> void:
    for child in dialogue_layer.get_children():
        dialogue_layer.remove_child(child)
        child.queue_free()
    var wrapper := VBoxContainer.new()
    wrapper.add_theme_constant_override("separation", 10)
    var title_label := Label.new()
    title_label.text = title
    title_label.add_theme_font_size_override("font_size", 23)
    title_label.add_theme_color_override("font_color", Color("#e0bb84"))
    wrapper.add_child(title_label)
    var line := Label.new()
    line.text = description
    line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    line.custom_minimum_size.y = 60
    line.add_theme_font_size_override("font_size", 17)
    wrapper.add_child(line)
    for choice in choices:
        var option := Button.new()
        option.text = choice["name"]
        option.custom_minimum_size.y = 42
        option.pressed.connect(_dialog_action.bind(choice["code"]))
        wrapper.add_child(option)
    dialogue_layer.add_child(wrapper)
    dialogue_layer.visible = true
    game_paused_for_dialogue = true
    mobile_axis = Vector2.ZERO

func _dialog_action(code: String) -> void:
    match code:
        "buy_potion":
            if coins >= 10:
                coins -= 10
                potions += 1
                _save_game()
                _notify("Poção comprada! Ela foi salva no seu inventário.")
            else:
                _notify("Você precisa de 10 moedas para comprar uma poção.")
        "deposit":
            if coins >= 5:
                coins -= 5
                bank_coins += 5
                _save_game()
                _notify("5 moedas depositadas no Banco Real.")
            else:
                _notify("Saldo insuficiente para o depósito.")
        "withdraw":
            if bank_coins >= 5:
                bank_coins -= 5
                coins += 5
                _save_game()
                _notify("5 moedas sacadas do Banco Real.")
            else:
                _notify("Saldo bancário insuficiente.")
    _update_hud()
    _close_dialogue()

func _close_dialogue() -> void:
    dialogue_layer.visible = false
    game_paused_for_dialogue = false

func _notify(message: String) -> void:
    if message_label != null:
        message_label.text = message

func _update_hud() -> void:
    if balance_label != null:
        balance_label.text = "Moedas: %d     Banco: %d     Poções: %d" % [coins, bank_coins, potions]

func _save_game() -> void:
    var save_data := {"version": 1, "coins": coins, "bank_coins": bank_coins, "potions": potions}
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(save_data))
        file.flush()

func _load_save() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary:
        return
    coins = maxi(0, int(parsed.get("coins", INITIAL_GOLD)))
    bank_coins = maxi(0, int(parsed.get("bank_coins", 0)))
    potions = maxi(0, int(parsed.get("potions", 0)))