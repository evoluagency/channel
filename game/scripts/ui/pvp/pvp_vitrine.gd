extends SubViewportContainer
## Vitrine 3D dos menus do Valdora PvP (sessão 1.8): pedestal de pedra com anel verde-azulado
## aceso, como na arte das telas Heróis e Arsenal, e em cima um herói KayKit ou o marcador de
## paintball girando devagar. Fundo transparente: a praça 3D do menu aparece atrás.
## Arrastar gira o modelo. mostrar_heroi(id, aparência) e mostrar_marcador(aparência).

const HEROI := preload("res://scripts/pvp/visual/heroi_visual.gd")
const MARCADOR := preload("res://scripts/pvp/visual/marcador.gd")
const T := preload("res://scripts/ui/pvp/pvp_tema.gd")

var vp: SubViewport
var palco: Node3D
var modelo: Node3D
var camera: Camera3D
var anel_cor := T.TEAL_CLARO
var girar := true
var _giro := 0.0
var _arrastando := false

func _init(cor_anel := T.TEAL_CLARO) -> void:
	anel_cor = cor_anel

func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var mundo := Node3D.new()
	vp.add_child(mundo)
	camera = Camera3D.new()
	camera.fov = 32
	mundo.add_child(camera)
	_enquadrar(false)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-38, 28, 0)
	sol.light_color = Color("fff0d6")
	sol.light_energy = 0.9
	sol.shadow_enabled = true
	mundo.add_child(sol)
	var contra := DirectionalLight3D.new()
	contra.rotation_degrees = Vector3(-20, 200, 0)
	contra.light_color = Color("9fe8ff")
	contra.light_energy = 0.45
	mundo.add_child(contra)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c9d6ea")
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.5
	var we := WorldEnvironment.new()
	we.environment = env
	mundo.add_child(we)
	_pedestal(mundo)
	palco = Node3D.new()
	palco.position.y = 0.32
	mundo.add_child(palco)

func _enquadrar(arma: bool) -> void:
	if arma:
		camera.position = Vector3(0, 1.55, 4.2)
		camera.look_at(Vector3(0, 0.75, 0))
	else:
		camera.position = Vector3(0, 1.45, 5.4)
		camera.look_at(Vector3(0, 1.05, 0))

func _pedestal(mundo: Node3D) -> void:
	var pedra := StandardMaterial3D.new()
	pedra.albedo_color = Color("a89a80")
	pedra.roughness = 0.9
	var topo := StandardMaterial3D.new()
	topo.albedo_color = Color("2c3646")
	topo.roughness = 0.6
	var luz := StandardMaterial3D.new()
	luz.albedo_color = anel_cor
	luz.emission_enabled = true
	luz.emission = anel_cor
	luz.emission_energy_multiplier = 1.0
	for p in [[1.25, 1.32, 0.2, 0.1, pedra], [1.05, 1.1, 0.12, 0.26, topo]]:
		var mi := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = p[0]; c.bottom_radius = p[1]; c.height = p[2]; c.radial_segments = 40; c.rings = 1
		mi.mesh = c
		mi.material_override = p[4]
		mi.position.y = p[3]
		mundo.add_child(mi)
	# anel aceso, como na arte
	var arco := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.9
	t.outer_radius = 0.96
	t.rings = 40
	t.ring_segments = 6
	arco.mesh = t
	arco.material_override = luz
	arco.position.y = 0.325
	arco.scale = Vector3(1, 0.4, 1)
	mundo.add_child(arco)
	# V dourado no chão do pedestal
	var v := MeshInstance3D.new()
	var vm := PrismMesh.new()
	vm.size = Vector3(0.5, 0.36, 0.02)
	v.mesh = vm
	var ouro := StandardMaterial3D.new()
	ouro.albedo_color = T.OURO
	ouro.metallic = 0.6
	ouro.roughness = 0.35
	v.material_override = ouro
	v.rotation_degrees = Vector3(-90, 0, 180)
	v.position = Vector3(0, 0.33, 0.62)
	mundo.add_child(v)

func mostrar_heroi(id: String, aparencia := MARCADOR.PADRAO) -> void:
	_limpar()
	_enquadrar(false)
	var h = HEROI.new()
	palco.add_child(h)
	h.montar(id, aparencia)
	h.rotation.y = PI
	h.animar("2H_Melee_Idle", 0.0)
	modelo = h

func mostrar_marcador(aparencia: String) -> void:
	_limpar()
	_enquadrar(true)
	var m := MARCADOR.novo(aparencia)
	m.scale = Vector3.ONE * 2.3
	var piv := Node3D.new()
	piv.add_child(m)
	# de lado, com o centro da arma sobre o eixo do pedestal
	m.rotation_degrees = Vector3(0, -90, 0)
	m.position = Vector3(-0.5, 0.62, 0)
	palco.add_child(piv)
	modelo = piv

func _limpar() -> void:
	for c in palco.get_children():
		c.queue_free()
	modelo = null

func _process(dt: float) -> void:
	if modelo == null:
		return
	if girar and not _arrastando:
		_giro += dt * 0.35
	palco.rotation.y = _giro

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		_arrastando = ev.pressed
	elif ev is InputEventScreenTouch:
		_arrastando = ev.pressed
	elif ev is InputEventMouseMotion and _arrastando:
		_giro += ev.relative.x * 0.01
	elif ev is InputEventScreenDrag:
		_giro += ev.relative.x * 0.01

## Para de renderizar quando a vitrine some.
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and vp != null:
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if is_visible_in_tree() else SubViewport.UPDATE_DISABLED
