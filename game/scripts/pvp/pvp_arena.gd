extends Node3D
## Arena 3D do Valdora PvP, montada a partir da grade do mapa (game/data/pvp/mapas_v0.1.json).
## Cada célula tem 3 m. As paredes (#) viram blocos com colisão, juntados em retângulos;
## as coberturas (c) viram caixotes e contêineres; bases e pontos A e B são pintados no chão.
## Os limites do mapa são as paredes da borda, mais uma cerca invisível alta em volta.

const T := preload("res://scripts/ui/pvp/pvp_tema.gd")
const JOGADOR := preload("res://scripts/pvp/pvp_jogador.gd")
const HUD := preload("res://scripts/pvp/pvp_hud.gd")
const DADOS := "res://data/pvp/mapas_v0.1.json"
const CENARIO := preload("res://scripts/pvp/visual/cenario.gd")
const TINTA := preload("res://scripts/pvp/pvp_tinta.gd")
const BOT := preload("res://scripts/pvp/pvp_bot.gd")
const HEROI := preload("res://scripts/pvp/visual/heroi_visual.gd")
## Cores de tinta dos times (sessão 1.8): verde-azulado claro para o seu, magenta para o adversário.
const CORES_TIME := [Color("#21e0d0"), Color("#ff3d9a")]
const DURACAO := 180.0

const CELULA := 3.0
const ALTURA_PAREDE := 4.2
const ALTURA_BORDA := 6.0
const COBERTURA := 2.6          # lado do caixote (deixa 0,4 m: o jogador, com 0,7 m, não passa)
const ALTURA_CAIXOTE := 1.15
const ALTURA_CONTEINER := 2.4

static var mapa_escolhido := "esplanada"
## false: arena em blocos simples (teste de espaço); true: cenário da região (cenario.gd).
static var visual := true
## Confronto 5 x 5 com bots (4 aliados e 5 adversários). Os smokes de colisão desligam.
static var com_bots := true
static var heroi_jogador := "nilo"
static var aparencia_jogador := "mare_alta"
var tinta: Node3D
var combatentes: Array = []
var placar := [0, 0]
var abates_recentes: Array = []   # [{autor, vitima, time, t}]
var tempo := DURACAO
var encerrada := false
var _livres := {}                 # Vector2i -> true
var chamadas_cenario := 0

var mapa: Dictionary = {}
var grade: Array = []
var largura := 0
var altura := 0
var jogador: CharacterBody3D
var hud: CanvasLayer
var paredes := 0               # blocos de parede depois de juntar
var _mats := {}

func _ready() -> void:
	mapa = carregar(mapa_escolhido)
	grade = mapa.get("grade", [])
	altura = grade.size()
	largura = String(grade[0]).length() if altura > 0 else 0
	if not visual:
		_ambiente()
	_chao()
	_paredes()
	_coberturas()
	_marcas()
	_cerca()
	if visual:
		chamadas_cenario = CENARIO.new().montar(self)
	tinta = TINTA.new()
	add_child(tinta)
	jogador = JOGADOR.new()
	jogador.arena = self
	jogador.heroi_id = heroi_jogador
	jogador.aparencia = aparencia_jogador
	add_child(jogador)
	jogador.global_position = centro_de("T") + Vector3(0, 1.0, 0)
	jogador.olhar_para(centro_de("D"))
	combatentes.append(jogador)
	if com_bots:
		_bots()
	hud = HUD.new()
	hud.arena = self
	add_child(hud)

func _bots() -> void:
	var ids: Array = []
	for h in HEROI.herois():
		if h.id != heroi_jogador:
			ids.append(h.id)
	var aps: Array = []
	for a in preload("res://scripts/pvp/visual/marcador.gd").aparencias():
		aps.append(a.id)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(mapa_escolhido)
	for i in 9:
		var b := BOT.new()
		b.arena = self
		b.time = 0 if i < 4 else 1
		b.heroi_id = ids[i % ids.size()]
		b.aparencia = aps[(i * 7 + 3) % aps.size()]
		add_child(b)
		b.global_position = celula_aleatoria("T" if b.time == 0 else "D", rng) + Vector3(0, 0.1, 0)
		combatentes.append(b)

func _process(dt: float) -> void:
	if encerrada or not com_bots:
		return
	tempo = maxf(0.0, tempo - dt)
	if tempo <= 0.0:
		encerrada = true

func cor_time(t: int) -> Color:
	return CORES_TIME[clampi(t, 0, 1)]

func registrar_abate(autor: Node, vitima: Node) -> void:
	if is_instance_valid(autor) and autor.get("time") != null and autor != vitima:
		placar[int(autor.time)] += 1
		autor.abates += 1
	abates_recentes.push_front({"autor": String(autor.nome) if is_instance_valid(autor) else "?",
		"vitima": String(vitima.nome), "time": int(autor.time) if is_instance_valid(autor) else -1, "t": Time.get_ticks_msec()})
	if abates_recentes.size() > 4:
		abates_recentes.pop_back()

func livre(c: Vector2i) -> bool:
	return not letra(c.x, c.y) in ["#", "c"]

## Centro de uma célula sorteada com a letra pedida (base, ponto A ou B).
func celula_aleatoria(ch: String, rng: RandomNumberGenerator) -> Vector3:
	var lista := []
	for y in altura:
		for x in largura:
			if letra(x, y) == ch:
				lista.append(Vector2i(x, y))
	if lista.is_empty():
		return centro_de(ch)
	var c: Vector2i = lista[(rng.randi() if rng != null else randi()) % lista.size()]
	return celula_mundo(c.x, c.y)

## Caminho pela grade (busca em largura, 8 vizinhos sem cortar quina). Devolve pontos no mundo.
func caminho(de: Vector3, para: Vector3) -> Array:
	var a := mundo_celula(de)
	var b := mundo_celula(para)
	if not livre(b):
		return []
	var veio := {a: a}
	var fila := [a]
	var i := 0
	var achou := false
	while i < fila.size():
		var c: Vector2i = fila[i]
		i += 1
		if c == b:
			achou = true
			break
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]:
			var n: Vector2i = c + d
			if veio.has(n) or not livre(n):
				continue
			if d.x != 0 and d.y != 0 and (not livre(Vector2i(c.x + d.x, c.y)) or not livre(Vector2i(c.x, c.y + d.y))):
				continue
			veio[n] = c
			fila.append(n)
	if not achou:
		return []
	var pts := []
	var c2 := b
	while c2 != a:
		pts.push_front(celula_mundo(c2.x, c2.y))
		c2 = veio[c2]
	return pts

static func carregar(id: String) -> Dictionary:
	var f := FileAccess.open(DADOS, FileAccess.READ)
	if f == null:
		push_error("mapas não encontrados: " + DADOS)
		return {}
	var dados = JSON.parse_string(f.get_as_text())
	for m in dados.get("mapas", []):
		if m.get("id", "") == id:
			return m
	return dados.get("mapas", [{}])[0]

static func lista() -> Array:
	var f := FileAccess.open(DADOS, FileAccess.READ)
	if f == null:
		return []
	var dados = JSON.parse_string(f.get_as_text())
	var r := []
	for m in dados.get("mapas", []):
		r.append({"id": m.id, "nome": m.nome, "cidade": m.cidade, "tema": m.tema})
	return r

## Centro da célula (coluna, linha) no mundo. Linha 0 (defesa) fica no -Z.
func celula_mundo(x: int, y: int) -> Vector3:
	return Vector3((x + 0.5) * CELULA - largura * CELULA * 0.5, 0, (y + 0.5) * CELULA - altura * CELULA * 0.5)

func mundo_celula(p: Vector3) -> Vector2i:
	return Vector2i(int(floor((p.x + largura * CELULA * 0.5) / CELULA)), int(floor((p.z + altura * CELULA * 0.5) / CELULA)))

func letra(x: int, y: int) -> String:
	if y < 0 or y >= altura or x < 0 or x >= largura:
		return "#"
	return String(grade[y])[x]

func centro_de(ch: String) -> Vector3:
	var soma := Vector3.ZERO
	var n := 0
	for y in altura:
		for x in largura:
			if letra(x, y) == ch:
				soma += celula_mundo(x, y)
				n += 1
	return soma / maxf(n, 1)

# ---------------------------------------------------------------- materiais e peças

func _mat(cor: Color, rug := 0.85, ruido := true) -> StandardMaterial3D:
	var k := "%s|%s" % [cor.to_html(), ruido]
	if _mats.has(k):
		return _mats[k]
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = rug
	m.metallic_specular = 0.15
	if ruido:
		var n := FastNoiseLite.new()
		n.frequency = 0.05
		var t := NoiseTexture2D.new()
		t.width = 128; t.height = 128; t.seamless = true; t.noise = n
		var g := Gradient.new()
		g.set_color(0, Color(0.86, 0.86, 0.86))
		g.set_color(1, Color(1, 1, 1))
		t.color_ramp = g
		m.albedo_texture = t
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3.ONE * 0.25
	_mats[k] = m
	return m

## Bloco com colisão. pos = centro da base.
func bloco(pos: Vector3, tam: Vector3, mat: Material, colide := true, nome := "") -> Node3D:
	var corpo: Node3D = StaticBody3D.new() if colide else Node3D.new()
	if nome != "":
		corpo.name = nome
	corpo.position = pos + Vector3(0, tam.y * 0.5, 0)
	if visual and not colide:
		corpo.free()   # no modo visual o que se vê vem do cenário
		return null
	if not visual:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = tam
		mi.mesh = bm
		mi.material_override = mat
		corpo.add_child(mi)
	if colide:
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = tam
		cs.shape = sh
		corpo.add_child(cs)
	add_child(corpo)
	return corpo

# ---------------------------------------------------------------- montagem

func _ambiente() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var ceu := Sky.new()
	var mc := ProceduralSkyMaterial.new()
	mc.sky_top_color = Color("4f8fd6")
	mc.sky_horizon_color = Color("cfe3f0")
	mc.ground_horizon_color = Color("cfe3f0")
	mc.ground_bottom_color = Color("8a8070")
	ceu.sky_material = mc
	env.sky = ceu
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.3
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 0.9
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.1
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.light_color = Color("fff0d8")
	sol.light_energy = 0.95
	sol.rotation_degrees = Vector3(-55, -35, 0)
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 60.0
	add_child(sol)

func _chao() -> void:
	var w := largura * CELULA
	var h := altura * CELULA
	bloco(Vector3(0, -0.5, 0), Vector3(w + 6, 0.5, h + 6), _mat(Color("b9ab8f")), true, "Chao")

func _paredes() -> void:
	# junta células de parede em retângulos (menos nós e menos colisões)
	var usado := {}
	var borda_mat := _mat(Color("9c8c6e"))
	var parede_mat := _mat(Color("d6c7a6"))
	var friso := _mat(T.TEAL, 0.6, false)
	for y in altura:
		for x in largura:
			if letra(x, y) != "#" or usado.has(Vector2i(x, y)):
				continue
			var w := 1
			while x + w < largura and letra(x + w, y) == "#" and not usado.has(Vector2i(x + w, y)):
				w += 1
			var h := 1
			var cabe := true
			while cabe and y + h < altura:
				for i in w:
					if letra(x + i, y + h) != "#" or usado.has(Vector2i(x + i, y + h)):
						cabe = false
						break
				if cabe:
					h += 1
			for j in h:
				for i in w:
					usado[Vector2i(x + i, y + j)] = true
			var borda := x == 0 or y == 0 or x + w == largura or y + h == altura
			var a := ALTURA_BORDA if borda else ALTURA_PAREDE
			var c0 := celula_mundo(x, y) - Vector3(CELULA * 0.5, 0, CELULA * 0.5)
			var tam := Vector3(w * CELULA, a, h * CELULA)
			bloco(c0 + Vector3(tam.x * 0.5, 0, tam.z * 0.5), tam, borda_mat if borda else parede_mat, true, "Parede%d" % paredes)
			if not borda:
				bloco(c0 + Vector3(tam.x * 0.5, a, tam.z * 0.5), Vector3(tam.x + 0.1, 0.18, tam.z + 0.1), friso, false)
				bloco(c0 + Vector3(tam.x * 0.5, 0, tam.z * 0.5), Vector3(tam.x + 0.06, 0.6, tam.z + 0.06), _mat(Color("8c7c62")), false)
			paredes += 1

## Cobertura alta (contêiner, quiosque) ou baixa (caixote, floreira): regra fixa pela posição.
func cobertura_alta(x: int, y: int) -> bool:
	return (x * 7 + y * 3) % 3 == 0

func _coberturas() -> void:
	var caixote := _mat(Color("c48a4e"))
	var conteiner := [_mat(Color("3f7f86")), _mat(Color("d2763a")), _mat(Color("5d6b7d"))]
	var n := 0
	for y in altura:
		for x in largura:
			if letra(x, y) != "c":
				continue
			var p := celula_mundo(x, y)
			if cobertura_alta(x, y):
				bloco(p, Vector3(COBERTURA, ALTURA_CONTEINER, COBERTURA), conteiner[n % 3], true, "Cobertura%d" % n)
			else:
				bloco(p, Vector3(COBERTURA, ALTURA_CAIXOTE, COBERTURA), caixote, true, "Cobertura%d" % n)
				bloco(p + Vector3(0, ALTURA_CAIXOTE, 0), Vector3(COBERTURA * 0.55, 0.05, COBERTURA * 0.55), _mat(Color("9a6a39"), 0.9, false), false)
			n += 1

func _marcas() -> void:
	var cores := {"T": Color("3f8f5a"), "D": Color("b0603a"), "A": Color("d9534a"), "B": Color("3f6fc9")}
	for ch in cores:
		var m := _mat(Color(cores[ch], 0.55), 0.9, false)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		for y in altura:
			for x in largura:
				if letra(x, y) == ch:
					bloco(celula_mundo(x, y) + Vector3(0, 0.005, 0), Vector3(CELULA, 0.02, CELULA), m, false)
		if ch in ["A", "B"]:
			var l := Label3D.new()
			l.text = ch
			l.font_size = 512
			l.pixel_size = 0.01
			l.modulate = Color(cores[ch], 0.75)
			l.outline_size = 0
			l.rotation_degrees = Vector3(-90, 0, 0)
			l.position = centro_de(ch) + Vector3(0, 0.05, 0)
			l.double_sided = true
			add_child(l)
	# portas das rotas: faixa amarela no chão
	var faixa := _mat(Color("ffc21a"), 0.7, false)
	for y in altura:
		for x in largura:
			if letra(x, y) in ["1", "2", "3"]:
				bloco(celula_mundo(x, y) + Vector3(0, 0.01, 0), Vector3(CELULA, 0.02, 0.3), faixa, false)

func _cerca() -> void:
	# limite invisível: ninguém sai do mapa, nem pulando de cima de nada
	var w := largura * CELULA
	var h := altura * CELULA
	var alto := 30.0
	for lado in [[Vector3(0, 0, -h * 0.5 - 0.5), Vector3(w + 2, alto, 1)], [Vector3(0, 0, h * 0.5 + 0.5), Vector3(w + 2, alto, 1)],
			[Vector3(-w * 0.5 - 0.5, 0, 0), Vector3(1, alto, h + 2)], [Vector3(w * 0.5 + 0.5, 0, 0), Vector3(1, alto, h + 2)]]:
		var c := StaticBody3D.new()
		c.name = "Limite"
		c.position = lado[0] + Vector3(0, alto * 0.5, 0)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = lado[1]
		cs.shape = sh
		c.add_child(cs)
		add_child(c)
