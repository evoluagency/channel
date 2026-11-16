extends CharacterBody3D
## Bot do Valdora PvP (sessão 1.8): herói KayKit com marcador de paintball. Anda pela grade
## do mapa (busca em largura nas células livres), procura o adversário mais perto com linha
## de visão, para, mira e dispara bolas de tinta com um pouco de imprecisão. Morre ao zerar a
## vida (o escudo cai primeiro) e renasce na base do time depois de alguns segundos.

const HEROI := preload("res://scripts/pvp/visual/heroi_visual.gd")

const VELOCIDADE := 3.9
const GRAVIDADE := 14.0
const ALCANCE := 34.0
const CADENCIA := 0.26
const DANO := 9.0
const IMPRECISAO := 0.045        # radianos
const RENASCER := 5.0
const VIDA := 100.0
const ESCUDO := 50.0

var arena                        # pvp_arena.gd
var time := 1                    # 0: time do jogador; 1: adversário
var heroi_id := "cole"
var aparencia := "mare_alta"
var nome := ""
var vida := VIDA
var escudo := ESCUDO
var morto := false
var abates := 0
var visual: Node3D
var alvo: Node3D
var _caminho: Array = []         # posições no mundo
var _pensar := 0.0
var _tiro := 0.0
var _morto_t := 0.0
var _yaw := 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 2
	var cs := CollisionShape3D.new()
	var f := CapsuleShape3D.new()
	f.radius = 0.35
	f.height = 1.8
	cs.shape = f
	cs.position.y = 0.9
	add_child(cs)
	visual = HEROI.new()
	add_child(visual)
	visual.montar(heroi_id, aparencia)
	if nome == "":
		nome = String(visual.heroi.get("nome", heroi_id))
	_rng.seed = hash(nome + str(time))
	_pensar = _rng.randf() * 0.3

func olho() -> Vector3:
	return global_position + Vector3(0, 1.45, 0)

func peito() -> Vector3:
	return global_position + Vector3(0, 1.1, 0)

func _physics_process(dt: float) -> void:
	if morto:
		_morto_t -= dt
		if _morto_t <= 0.0:
			renascer()
		return
	if not is_on_floor():
		velocity.y -= GRAVIDADE * dt
	else:
		velocity.y = -0.5
	_pensar -= dt
	if _pensar <= 0.0:
		_pensar = 0.3
		alvo = _procurar_alvo()
		if alvo == null and _caminho.is_empty():
			_caminho = arena.caminho(global_position, _objetivo())
	_tiro -= dt
	var mov := Vector3.ZERO
	if alvo != null and is_instance_valid(alvo) and not alvo.morto:
		var d: Vector3 = alvo.peito() - olho()
		_virar_para(d, dt * 9.0)
		if _tiro <= 0.0 and absf(angle_difference(_yaw, atan2(-d.x, -d.z))) < 0.25:
			_tiro = CADENCIA + _rng.randf() * 0.12
			_atirar(d)
		visual.animar("2H_Ranged_Shooting")
	else:
		alvo = null
		while not _caminho.is_empty() and Vector2(_caminho[0].x - global_position.x, _caminho[0].z - global_position.z).length() < 0.6:
			_caminho.pop_front()
		if not _caminho.is_empty():
			mov = (_caminho[0] - global_position)
			mov.y = 0
			mov = mov.normalized()
			_virar_para(mov, dt * 8.0)
			visual.animar("Running_A")
		else:
			visual.animar("2H_Ranged_Aiming")
	velocity.x = mov.x * VELOCIDADE
	velocity.z = mov.z * VELOCIDADE
	move_and_slide()

func _virar_para(d: Vector3, peso: float) -> void:
	if Vector2(d.x, d.z).length() < 0.01:
		return
	_yaw = lerp_angle(_yaw, atan2(-d.x, -d.z), clampf(peso, 0.0, 1.0))
	rotation.y = _yaw

func _objetivo() -> Vector3:
	var alvos: Array = ["A", "B", "D" if time == 0 else "T"]
	return arena.celula_aleatoria(alvos[_rng.randi() % alvos.size()], _rng)

func _procurar_alvo() -> Node3D:
	var melhor: Node3D = null
	var dist := ALCANCE
	var espaco := get_world_3d().direct_space_state
	for c in arena.combatentes:
		if c == self or not is_instance_valid(c) or c.time == time or c.morto:
			continue
		var dd: float = c.global_position.distance_to(global_position)
		if dd >= dist:
			continue
		var q := PhysicsRayQueryParameters3D.create(olho(), c.peito(), 1)
		if espaco.intersect_ray(q).is_empty():
			melhor = c
			dist = dd
	return melhor

func _atirar(d: Vector3) -> void:
	var dir := d.normalized()
	var lado := dir.cross(Vector3.UP).normalized()
	dir = dir.rotated(Vector3.UP, _rng.randf_range(-IMPRECISAO, IMPRECISAO))
	dir = dir.rotated(lado, _rng.randf_range(-IMPRECISAO, IMPRECISAO) * 0.6)
	var boca := olho() + Vector3(0, -0.25, 0) + dir * 0.7
	arena.tinta.disparar(boca, dir, arena.cor_time(time), self, DANO)

func registrar_acerto() -> void:
	pass

func levar_tinta(dano: float, _cor: Color, autor: Node, _ponto: Vector3, _normal: Vector3) -> void:
	if morto:
		return
	var resto := dano
	if escudo > 0.0:
		var tira := minf(escudo, resto)
		escudo -= tira
		resto -= tira
	vida -= resto
	if is_instance_valid(autor) and autor != self and (alvo == null) and autor.get("time") != time:
		alvo = autor
	if vida <= 0.0:
		morrer(autor)

func morrer(autor: Node) -> void:
	morto = true
	vida = 0.0
	_morto_t = RENASCER
	collision_layer = 0
	velocity = Vector3.ZERO
	visual.animar("Death_A", 0.05)
	arena.registrar_abate(autor, self)

func renascer() -> void:
	morto = false
	vida = VIDA
	escudo = ESCUDO
	alvo = null
	_caminho.clear()
	collision_layer = 2
	global_position = arena.celula_aleatoria("T" if time == 0 else "D", _rng) + Vector3(0, 0.1, 0)
	visual.animar("2H_Ranged_Aiming", 0.0)
	for c in get_children():
		if c is MeshInstance3D:
			c.queue_free()   # manchas de tinta da vida anterior
