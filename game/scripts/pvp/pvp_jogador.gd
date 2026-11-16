extends CharacterBody3D
## Jogador em primeira pessoa do Valdora PvP.
## Celular: joystick na metade esquerda (aparece onde o dedo toca), arrastar na metade direita
## para mirar; pular, agachar, atirar e recarregar pelos botões da interface.
## PC: W A S D, mouse (clique para prender), espaço pula, Ctrl agacha, clique esquerdo atira, R recarrega.
## Sessão 1.8: paintball. O tiro é uma bola de tinta (pvp_tinta.gd) que sai da boca do
## marcador em direção ao ponto da mira; o marcador com funil aparece em primeira pessoa.

const MARCADOR := preload("res://scripts/pvp/visual/marcador.gd")
const T := preload("res://scripts/ui/pvp/pvp_tema.gd")

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
var disparos := 0
var time := 0
var nome := "Você"
var heroi_id := "nilo"
var aparencia := MARCADOR.PADRAO
var vida := 100.0
var escudo := 50.0
var morto := false
var abates := 0
var arena                       # pvp_arena.gd (opcional: sem ela o tiro é só visual)
var arma: Node3D                # marcador e braços em primeira pessoa
var marcador: MeshInstance3D
var _coice := 0.0
var _balanco := 0.0
var _morto_t := 0.0
const DANO := 25.0
const RENASCER := 4.0
var _pitch := 0.0
var _yaw := 0.0

signal atirou(acertou: bool, ponto: Vector3)
signal ferido(dano: float)
signal caiu(autor: Node)

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
	collision_layer = 2
	collision_mask = 1 | 2
	_teclas()
	_montar_arma()

## Marcador com funil e braços (manga verde-azulada, punho laranja, luva preta), presos à câmera.
func _montar_arma() -> void:
	arma = Node3D.new()
	arma.name = "ArmaPrimeiraPessoa"
	camera.add_child(arma)
	arma.position = Vector3(0.2, -0.2, -0.42)
	arma.rotation_degrees = Vector3(1.5, 5.0, 0)
	marcador = MARCADOR.novo(aparencia)
	marcador.scale = Vector3.ONE * 0.52
	marcador.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arma.add_child(marcador)
	var manga := StandardMaterial3D.new()
	manga.albedo_color = T.TEAL_ESCURO
	manga.roughness = 0.8
	var punho := StandardMaterial3D.new()
	punho.albedo_color = T.LARANJA
	var luva := StandardMaterial3D.new()
	luva.albedo_color = Color("22252b")
	luva.roughness = 0.6
	# braço direito: segura o punho e vem de baixo à direita
	_braco(Vector3(0.0, -0.08, 0.01), Vector3(0.06, -0.22, 0.4), manga, punho, luva)
	# braço esquerdo: segura o guarda-mão e vem da esquerda
	_braco(Vector3(-0.012, -0.045, -0.3), Vector3(-0.3, -0.24, 0.16), manga, punho, luva)

func _braco(mao: Vector3, ombro: Vector3, manga: Material, punho: Material, luva: Material) -> void:
	var s := 0.52
	var m := mao * s
	var o := ombro
	var meio := (m + o) * 0.5
	var comp := m.distance_to(o)
	var b := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.028; c.bottom_radius = 0.036; c.height = comp; c.radial_segments = 10; c.rings = 1
	b.mesh = c
	b.material_override = manga
	arma.add_child(b)
	b.position = meio
	b.basis = Basis.looking_at(m - o, Vector3.UP) * Basis(Vector3.RIGHT, -PI * 0.5)
	b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var p := MeshInstance3D.new()
	var pc := CylinderMesh.new()
	pc.top_radius = 0.033; pc.bottom_radius = 0.033; pc.height = 0.035; pc.radial_segments = 10; pc.rings = 1
	p.mesh = pc
	p.material_override = punho
	arma.add_child(p)
	p.position = m + (o - m).normalized() * 0.06
	p.basis = b.basis
	var l := MeshInstance3D.new()
	var lb := BoxMesh.new()
	lb.size = Vector3(0.05, 0.045, 0.065)
	l.mesh = lb
	l.material_override = luva
	arma.add_child(l)
	l.position = m
	l.basis = Basis.looking_at(m - o, Vector3.UP)
	for n in [p, l]:
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func trocar_aparencia(id: String) -> void:
	aparencia = id
	if marcador != null:
		MARCADOR.aplicar(marcador, id)

func olho() -> Vector3:
	return camera.global_position

func peito() -> Vector3:
	return global_position + Vector3(0, 1.1, 0)

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
	if municao <= 0 or morto:
		return
	municao -= 1
	disparos += 1
	_coice = 1.0
	var origem := camera.global_position
	var fim := origem - camera.global_transform.basis.z * 120.0
	var q := PhysicsRayQueryParameters3D.create(origem, fim, 1 | 2)
	q.exclude = [get_rid()]
	var r := get_world_3d().direct_space_state.intersect_ray(q)
	var ponto: Vector3 = fim if r.is_empty() else r.position
	if arena != null and arena.tinta != null:
		# a bola sai da boca do marcador e vai para o ponto da mira
		var boca := marcador.global_transform * Vector3(0, 0.004, -0.69)
		if origem.distance_to(ponto) < 1.2:
			boca = origem
		arena.tinta.disparar(boca, ponto - boca, arena.cor_time(time), self, DANO)
	else:
		if not r.is_empty():
			registrar_acerto()
	atirou.emit(not r.is_empty(), ponto)

func registrar_acerto() -> void:
	acertos += 1

var acertos_corpo := 0
func registrar_acerto_corpo() -> void:
	acertos_corpo += 1

func levar_tinta(dano: float, _cor: Color, autor: Node, _ponto: Vector3, _normal: Vector3) -> void:
	if morto:
		return
	var resto := dano
	if escudo > 0.0:
		var tira := minf(escudo, resto)
		escudo -= tira
		resto -= tira
	vida -= resto
	ferido.emit(dano)
	if vida <= 0.0:
		vida = 0.0
		morto = true
		_morto_t = RENASCER
		mover = Vector2.ZERO
		caiu.emit(autor)
		if arena != null:
			arena.registrar_abate(autor, self)

func renascer() -> void:
	morto = false
	vida = 100.0
	escudo = 50.0
	municao = 24
	reserva = maxi(reserva, 90)
	if arena != null:
		global_position = arena.celula_aleatoria("T", null) + Vector3(0, 0.1, 0)
		olhar_para(arena.centro_de("D"))

func recarregar() -> void:
	var falta := 24 - municao
	var pega := mini(falta, reserva)
	municao += pega
	reserva -= pega

func _physics_process(dt: float) -> void:
	if morto:
		_morto_t -= dt
		velocity = Vector3(0, velocity.y - GRAVIDADE * dt, 0) if not is_on_floor() else Vector3.ZERO
		move_and_slide()
		if _morto_t <= 0.0:
			renascer()
		return
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
	_animar_arma(dt, Vector2(velocity.x, velocity.z).length())

## Coice do tiro, balanço ao andar e recuo perto da parede (a arma não atravessa o cenário).
func _animar_arma(dt: float, rapidez: float) -> void:
	if arma == null:
		return
	_coice = maxf(0.0, _coice - dt * 9.0)
	_balanco += dt * rapidez * 1.9
	var anda := minf(1.0, rapidez / VELOCIDADE)
	var recuo := 0.0
	var q := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_transform.basis.z * 0.95, 1)
	var r := get_world_3d().direct_space_state.intersect_ray(q)
	if not r.is_empty():
		recuo = clampf(0.95 - camera.global_position.distance_to(r.position), 0.0, 0.5)
	var alvo := Vector3(0.2 + sin(_balanco) * 0.012 * anda, -0.2 - absf(cos(_balanco)) * 0.01 * anda - recuo * 0.25, -0.42 + _coice * 0.03 + recuo * 0.5)
	arma.position = arma.position.lerp(alvo, minf(1.0, dt * 18.0))
	arma.rotation_degrees.x = 1.5 + _coice * 4.0 + recuo * 30.0
	arma.rotation_degrees.y = 5.0
