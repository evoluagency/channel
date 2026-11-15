extends CharacterBody3D
## Jogador em primeira pessoa do Valdora PvP.
## Celular: joystick na metade esquerda (aparece onde o dedo toca), arrastar na metade direita
## para mirar; pular, agachar, atirar e recarregar pelos botões da interface.
## PC: W A S D, mouse (clique para prender), espaço pula, Ctrl agacha, clique esquerdo atira, R recarrega.

const VELOCIDADE := 5.0
const VELOCIDADE_AGACHADO := 2.4
const PULO := 4.6
const GRAVIDADE := 14.0
const ALTURA := 1.8
const ALTURA_AGACHADO := 1.2
const RAIO := 0.35
const OLHOS := 1.62
const SENSIBILIDADE_TOQUE := 0.22   # graus por pixel
const SENSIBILIDADE_MOUSE := 0.12

var camera: Camera3D
var forma: CapsuleShape3D
var mover := Vector2.ZERO       # vindo do joystick (-1..1)
var agachado := false
var pedir_pulo := false
var municao := 24
var reserva := 90
var acertos := 0
var _pitch := 0.0
var _yaw := 0.0

signal atirou(acertou: bool, ponto: Vector3)

func _ready() -> void:
	name = "Jogador"
	forma = CapsuleShape3D.new()
	forma.radius = RAIO
	forma.height = ALTURA
	var cs := CollisionShape3D.new()
	cs.shape = forma
	cs.position.y = ALTURA * 0.5
	add_child(cs)
	camera = Camera3D.new()
	camera.position.y = OLHOS
	camera.fov = 75.0
	camera.near = 0.05
	add_child(camera)
	camera.make_current()
	floor_max_angle = deg_to_rad(46)
	_teclas()

func _teclas() -> void:
	var mapa := {"pvp_frente": [KEY_W, KEY_UP], "pvp_tras": [KEY_S, KEY_DOWN], "pvp_esq": [KEY_A, KEY_LEFT],
		"pvp_dir": [KEY_D, KEY_RIGHT], "pvp_pulo": [KEY_SPACE], "pvp_agachar": [KEY_CTRL, KEY_C], "pvp_recarregar": [KEY_R]}
	for a in mapa:
		if InputMap.has_action(a):
			continue
		InputMap.add_action(a)
		for k in mapa[a]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(a, e)

func olhar_para(alvo: Vector3) -> void:
	var d := alvo - global_position
	_yaw = atan2(-d.x, -d.z)
	_pitch = 0.0
	_aplicar_olhar()

func girar(dx_pixels: float, dy_pixels: float, sens := SENSIBILIDADE_TOQUE) -> void:
	_yaw -= deg_to_rad(dx_pixels * sens)
	_pitch = clampf(_pitch - deg_to_rad(dy_pixels * sens), deg_to_rad(-80), deg_to_rad(80))
	_aplicar_olhar()

func _aplicar_olhar() -> void:
	rotation.y = _yaw
	camera.rotation.x = _pitch

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		girar(ev.relative.x, ev.relative.y, SENSIBILIDADE_MOUSE)
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and not DisplayServer.is_touchscreen_available():
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			atirar()
	elif ev.is_action_pressed("pvp_recarregar"):
		recarregar()
	elif ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func alternar_agachar() -> void:
	if agachado:
		# só levanta se houver espaço acima
		var q := PhysicsShapeQueryParameters3D.new()
		var s := CapsuleShape3D.new()
		s.radius = RAIO * 0.9
		s.height = ALTURA
		q.shape = s
		q.transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0, ALTURA * 0.5 + 0.05, 0))
		q.exclude = [get_rid()]
		if not get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty():
			return
	agachado = not agachado
	forma.height = ALTURA_AGACHADO if agachado else ALTURA
	get_child(0).position.y = forma.height * 0.5

func pular() -> void:
	pedir_pulo = true

func atirar() -> void:
	if municao <= 0:
		return
	municao -= 1
	var origem := camera.global_position
	var fim := origem - camera.global_transform.basis.z * 120.0
	var q := PhysicsRayQueryParameters3D.create(origem, fim)
	q.exclude = [get_rid()]
	var r := get_world_3d().direct_space_state.intersect_ray(q)
	if r.is_empty():
		atirou.emit(false, fim)
		return
	acertos += 1
	_marca(r.position, r.normal)
	atirou.emit(true, r.position)

func recarregar() -> void:
	var falta := 24 - municao
	var pega := mini(falta, reserva)
	municao += pega
	reserva -= pega

func _marca(p: Vector3, n: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var m := SphereMesh.new()
	m.radius = 0.06; m.height = 0.12; m.radial_segments = 6; m.rings = 3
	mi.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("2b2b2b")
	mi.material_override = mat
	get_parent().add_child(mi)
	mi.global_position = p + n * 0.01
	get_tree().create_timer(6.0).timeout.connect(mi.queue_free)

func _physics_process(dt: float) -> void:
	var entrada := mover
	var teclado := Input.get_vector("pvp_esq", "pvp_dir", "pvp_frente", "pvp_tras")
	if teclado.length() > 0.01:
		entrada = teclado
	if Input.is_action_just_pressed("pvp_pulo"):
		pedir_pulo = true
	if Input.is_action_just_pressed("pvp_agachar"):
		alternar_agachar()
	var dir := (transform.basis * Vector3(entrada.x, 0, entrada.y))
	dir.y = 0
	if dir.length() > 1.0:
		dir = dir.normalized()
	var v := VELOCIDADE_AGACHADO if agachado else VELOCIDADE
	velocity.x = dir.x * v
	velocity.z = dir.z * v
	if is_on_floor():
		if pedir_pulo and not agachado:
			velocity.y = PULO
	else:
		velocity.y -= GRAVIDADE * dt
	pedir_pulo = false
	move_and_slide()
	camera.position.y = lerpf(camera.position.y, (OLHOS if not agachado else OLHOS - 0.55), minf(1.0, dt * 12.0))
