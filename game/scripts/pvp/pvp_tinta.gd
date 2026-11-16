extends Node3D
## Tinta do paintball do Valdora PvP (sessão 1.8): bolas de tinta com trajetória e respingos
## coloridos onde batem. Tudo em dois MultiMesh (bolas e respingos): duas chamadas de
## desenho, qualquer que seja o tiroteio. Respingos no cenário ficam até serem reciclados
## (os mais antigos saem primeiro); no adversário, a mancha vai junto com o corpo.
##
## disparar(origem, direção, cor, autor, dano) lança uma bola. Quando ela bate num corpo
## com levar_tinta(dano, cor, autor, ponto, normal), o corpo recebe o dano.

const RESPINGO := preload("res://scripts/pvp/visual/tinta_respingo.gdshader")
const MAX_BOLAS := 64
const MAX_RESPINGOS := 180
const VELOCIDADE := 62.0
const GRAVIDADE := 5.0
const ALCANCE := 3.0            # segundos de voo antes de sumir
const CAMADAS := 1 | 2          # cenário e personagens

var bolas: MultiMeshInstance3D
var respingos: MultiMeshInstance3D
var _voando := []               # [{p, v, cor, autor, dano, t}]
var _proximo := 0
var total_respingos := 0
var total_acertos_corpo := 0
var _mat_corpo := {}

func _ready() -> void:
	name = "Tinta"
	var mb := MultiMesh.new()
	mb.transform_format = MultiMesh.TRANSFORM_3D
	mb.use_colors = true
	mb.instance_count = MAX_BOLAS
	mb.visible_instance_count = 0
	var esf := SphereMesh.new()
	esf.radius = 0.055; esf.height = 0.11; esf.radial_segments = 8; esf.rings = 4
	var mbm := StandardMaterial3D.new()
	mbm.vertex_color_use_as_albedo = true
	mbm.roughness = 0.25
	mbm.emission_enabled = true
	mbm.emission = Color(0.25, 0.25, 0.25)
	esf.material = mbm
	mb.mesh = esf
	bolas = MultiMeshInstance3D.new()
	bolas.name = "Bolas"
	bolas.multimesh = mb
	bolas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(bolas)
	var mr := MultiMesh.new()
	mr.transform_format = MultiMesh.TRANSFORM_3D
	mr.use_colors = true
	mr.use_custom_data = true
	mr.instance_count = MAX_RESPINGOS
	mr.visible_instance_count = 0
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	var sm := ShaderMaterial.new()
	sm.shader = RESPINGO
	q.material = sm
	mr.mesh = q
	respingos = MultiMeshInstance3D.new()
	respingos.name = "Respingos"
	respingos.multimesh = mr
	respingos.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(respingos)

func disparar(origem: Vector3, direcao: Vector3, cor: Color, autor: Node, dano := 20.0, velocidade := VELOCIDADE) -> void:
	if _voando.size() >= MAX_BOLAS:
		_voando.pop_front()
	_voando.append({"p": origem, "v": direcao.normalized() * velocidade, "cor": cor, "autor": autor, "dano": dano, "t": 0.0})

func _physics_process(dt: float) -> void:
	if _voando.is_empty():
		bolas.multimesh.visible_instance_count = 0
		return
	var espaco := get_world_3d().direct_space_state
	var vivos := []
	for b in _voando:
		var v: Vector3 = b.v
		v.y -= GRAVIDADE * dt
		var nova: Vector3 = b.p + v * dt
		var q := PhysicsRayQueryParameters3D.create(b.p, nova, CAMADAS)
		var autor = b.autor
		if is_instance_valid(autor) and autor is CollisionObject3D:
			q.exclude = [autor.get_rid()]
		var r := espaco.intersect_ray(q)
		if not r.is_empty():
			_bater(b, r)
			continue
		b.p = nova
		b.v = v
		b.t += dt
		if b.t < ALCANCE:
			vivos.append(b)
	_voando = vivos
	var mm := bolas.multimesh
	mm.visible_instance_count = vivos.size()
	for i in vivos.size():
		var d: Vector3 = vivos[i].v.normalized()
		var bs := Basis.looking_at(d, Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT).scaled(Vector3(1, 1, 1.6))
		mm.set_instance_transform(i, Transform3D(bs, vivos[i].p))
		mm.set_instance_color(i, vivos[i].cor)

func _bater(b: Dictionary, r: Dictionary) -> void:
	var alvo = r.collider
	var autor = b.autor
	if is_instance_valid(autor) and autor.has_method("registrar_acerto"):
		autor.registrar_acerto()
	if alvo != null and alvo.has_method("levar_tinta"):
		total_acertos_corpo += 1
		if is_instance_valid(autor) and autor.has_method("registrar_acerto_corpo") and alvo.get("time") != autor.get("time"):
			autor.registrar_acerto_corpo()
		alvo.levar_tinta(b.dano, b.cor, autor, r.position, r.normal)
		manchar_corpo(alvo, r.position, r.normal, b.cor)
	else:
		respingo(r.position, r.normal, b.cor)

## Respingo no cenário, alinhado à superfície.
func respingo(ponto: Vector3, normal: Vector3, cor: Color, tamanho := -1.0) -> void:
	var mm := respingos.multimesh
	var i := _proximo
	_proximo = (_proximo + 1) % MAX_RESPINGOS
	mm.visible_instance_count = mini(MAX_RESPINGOS, maxi(mm.visible_instance_count, i + 1))
	var n := normal.normalized()
	var cima := Vector3.UP if absf(n.y) < 0.9 else Vector3.FORWARD
	var x := cima.cross(n).normalized()
	var y := n.cross(x)
	var giro := randf() * TAU
	var bs := Basis(x, y, n) * Basis(Vector3.BACK, giro)
	var s := tamanho if tamanho > 0 else randf_range(0.6, 0.95)
	# deslocamento mínimo e crescente: respingos sobrepostos não piscam entre si
	var p := ponto + n * (0.012 + float(i % 12) * 0.0008)
	mm.set_instance_transform(i, Transform3D(bs.scaled(Vector3(s, s, 1)), p))
	mm.set_instance_color(i, cor)
	mm.set_instance_custom_data(i, Color(randf(), 0, 0, 0))
	total_respingos += 1

## Mancha que acompanha o corpo atingido (some depois de alguns segundos).
func manchar_corpo(corpo: Node3D, ponto: Vector3, normal: Vector3, cor: Color) -> void:
	if corpo.name == "Jogador":
		return   # o jogador não vê o próprio corpo; a interface mostra o dano
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	var s := randf_range(0.22, 0.34)
	q.size = Vector2(s, s)
	mi.mesh = q
	mi.material_override = _material_corpo(cor)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	corpo.add_child(mi)
	var n := normal.normalized()
	mi.global_position = ponto + n * 0.02
	var cima := Vector3.UP if absf(n.y) < 0.9 else Vector3.FORWARD
	mi.global_basis = Basis.looking_at(-n, cima)
	get_tree().create_timer(5.0).timeout.connect(mi.queue_free)

func _material_corpo(cor: Color) -> StandardMaterial3D:
	var k := cor.to_html()
	if not _mat_corpo.has(k):
		var m := StandardMaterial3D.new()
		m.albedo_color = cor
		m.albedo_texture = _textura_mancha()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.5
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.roughness = 0.3
		_mat_corpo[k] = m
	return _mat_corpo[k]

static var _tex_mancha: ImageTexture
## Mancha em textura pequena (64 px), gerada uma vez: formato de respingo com pingos.
static func _textura_mancha() -> ImageTexture:
	if _tex_mancha != null:
		return _tex_mancha
	var im := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var pontas := []
	for i in 6:
		pontas.append([rng.randf() * TAU, rng.randf_range(0.6, 0.85)])
	for y in 64:
		for x in 64:
			var p := Vector2(x, y) / 32.0 - Vector2.ONE
			var a := atan2(p.y, p.x)
			var dentro := p.length() < 0.5 + 0.08 * sin(a * 5.0) + 0.05 * sin(a * 9.0 + 1.0)
			for pt in pontas:
				var d := Vector2(cos(pt[0]), sin(pt[0]))
				var t := clampf(p.dot(d), 0.0, pt[1])
				if p.distance_to(d * t) < 0.1 * (1.0 - t / pt[1]) + 0.03:
					dentro = true
			im.set_pixel(x, y, Color(1, 1, 1, 1.0 if dentro else 0.0))
	_tex_mancha = ImageTexture.create_from_image(im)
	return _tex_mancha
