extends Node3D
## Praça do Valdora em 3D para o fundo dos menus (arte conceitual do dono): calçamento de
## pedra creme, chafariz com flores, prédio com arco de entrada e cúpula verde-azulada,
## estandartes com o V dourado, arcada com balaustrada e trepadeiras, café de toldo vermelho,
## árvores cheias e a cidade de cúpulas ao fundo. Câmera parada com leve balanço.
## Tudo por código, juntado por material (poucas chamadas de desenho no celular).

const CONSTRUTOR := preload("res://scripts/pvp/visual/construtor.gd")
const ORN := preload("res://scripts/pvp/visual/ornamentos.gd")
const CEU := preload("res://scripts/pvp/visual/ceu.gdshader")

var camera: Camera3D
var _t := 0.0
var _base_cam := Vector3(0.6, 1.75, 15.5)
var malhas := 0
var triangulos := 0

func _ready() -> void:
	var c = CONSTRUTOR.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1707
	var o = ORN.new()
	o.preparar(c, rng)
	_materiais(c)
	_montar(c, o, rng)
	triangulos = c.triangulos()
	malhas = c.montar(self)
	_luz()
	camera = Camera3D.new()
	camera.fov = 58.0
	camera.far = 400.0
	add_child(camera)
	_posicionar(0.0)

func _process(delta: float) -> void:
	_t += delta
	_posicionar(_t)

func _posicionar(t: float) -> void:
	if camera == null:
		return
	var balanco := sin(t * 0.12) * 1.6
	camera.position = _base_cam + Vector3(balanco, sin(t * 0.21) * 0.06, 0)
	camera.look_at(Vector3(balanco * 0.35, 3.4, -4.0))

func _materiais(c) -> void:
	c.sup("piso", 0, Color("d8c3ae"), Color("b39a86"), 0.8, 0.12)
	c.sup("piso_borda", 3, Color("e6d6bd"), Color("cdb99c"), 0.7, 0.1)
	c.sup("pedra", 2, Color("f1e3c8"), Color("d9c6a5"), 1.0, 0.2, 0.8)
	c.sup("friso", 2, Color("f6ecd8"), Color("e2d3b6"), 2.0, 0.1)
	c.sup("telha", 11, Color("c8643a"), Color("94442a"), 1.2, 0.2)
	c.liso("ferro", Color("2f3336"), 0.5, 0.6)
	c.liso("tronco", Color("6e4b30"), 0.9)
	c.liso("creme", Color("f6ead2"), 0.7)
	c.liso("vidro", Color("1f6f78"), 0.1, 0.5)
	c.liso("madeira", Color("8a5a34"), 0.7)
	c.liso("toldo", Color("d9453c"), 0.7)
	c.liso("toldo_claro", Color("f7eee0"), 0.7)
	c.liso("vitrine", Color("ffd79a"), 0.3, 0.0, 1.3)
	c.agua("agua", Color("6fd6dc"), Color("1d8aa0"))
	c.sup("grama", 6, Color("7ab848"), Color("579a36"), 1.0, 0.1)

func _montar(c, o, rng: RandomNumberGenerator) -> void:
	# chão
	c.plano(Vector3(0, 0, 0), Vector2(90, 90), "piso")
	# chafariz em três níveis
	var f := Vector3(0, 0, -2.0)
	c.cilindro(f, 4.2, 0.55, "pedra", 18)
	c.cilindro(f + Vector3(0, 0.55, 0), 4.45, 0.16, "friso", 18)
	c.plano(f + Vector3(0, 0.5, 0), Vector2(6.2, 6.2), "agua")
	o.floreira(f + Vector3(0, 0, 4.9), Vector2(5.6, 0.9), 0.0, 0.55, "pedra")
	for s in [-1, 1]:
		o.floreira(f + Vector3(s * 4.4, 0, 2.6), Vector2(0.9, 2.6), s * 0.5, 0.55, "pedra")
	c.cilindro(f, 0.55, 2.2, "pedra", 10, 0.4)
	c.cilindro(f + Vector3(0, 2.2, 0), 2.0, 0.3, "pedra", 14, 1.6)
	c.plano(f + Vector3(0, 2.46, 0), Vector2(2.4, 2.4), "agua")
	c.cilindro(f + Vector3(0, 2.5, 0), 0.3, 1.2, "pedra", 8, 0.22)
	c.cilindro(f + Vector3(0, 3.7, 0), 0.9, 0.22, "pedra", 12, 0.7)
	c.cilindro(f + Vector3(0, 3.9, 0), 0.14, 1.0, "orn_ouro", 6, 0.06)
	o.estandarte(f + Vector3(0, 0.9, 0.05), Vector3(0, 0, 1), 4.0, 1.0)
	# prédio principal: corpo creme, arco de entrada, colunas, cúpula verde-azulada
	var b := Vector3(-1.5, 0, -16.0)
	c.caixa(b, Vector3(18, 9.5, 8), "pedra")
	o.cornija(b, 18, 8, 9.5, "friso")
	o.balaustrada(b + Vector3(0, 0, 0), 17.6, 7.6, 9.5, "friso")
	c.caixa(b + Vector3(0, 0, 4.0), Vector3(19, 0.6, 1.6), "friso")                       # escadaria
	c.caixa(b + Vector3(0, 0, 4.6), Vector3(17, 0.3, 1.0), "friso")
	c.caixa(b + Vector3(0, 0.6, 4.05), Vector3(3.2, 4.2, 0.1), "ferro")
	c.caixa(b + Vector3(0, 0.6, 4.1), Vector3(2.6, 3.6, 0.06), "vidro")
	c.arco(b + Vector3(0, 4.8, 4.25), 1.7, 2.3, 0.5, "friso", 0.0, 9)
	c.meio_disco(b + Vector3(0, 4.8, 4.04), 1.7, "vidro", 0.0, 9)
	for s in [-1, 1]:
		for k in 2:
			var px: float = s * (3.2 + k * 2.2)
			c.cilindro(b + Vector3(px, 0.6, 4.4), 0.38, 6.6, "pedra", 10)
			c.caixa(b + Vector3(px, 7.2, 4.4), Vector3(1.0, 0.4, 1.0), "friso")
		o.estandarte(b + Vector3(s * 4.3, 2.6, 4.75), Vector3(0, 0, 1), 4.2, 1.15)
		for k in 2:
			var jx: float = s * (6.8 + k * 1.9)
			c.caixa(b + Vector3(jx, 2.0, 4.02), Vector3(1.3, 2.6, 0.1), "vidro")
			c.arco(b + Vector3(jx, 4.6, 4.1), 0.65, 0.9, 0.2, "friso", 0.0, 6)
			o.lampiao(b + Vector3(s * 2.2, 0.6, 4.9) if k == 0 else b + Vector3(s * 9.6, 0, 5.4))
	c.caixa(b + Vector3(0, 8.2, 4.05), Vector3(4.8, 1.6, 0.12), "orn_estandarte")
	o.estandarte(b + Vector3(0, 7.1, 4.12), Vector3(0, 0, 1), 1.6, 0.9)
	o.cupula(b + Vector3(0, 9.5, -0.5), 4.4, 1.6, "friso")
	# arcada à direita com balaustrada e trepadeiras (como a ponte da arte)
	var ar := Vector3(13.5, 0, -9.0)
	var rot := -PI * 0.5 + 0.35
	var fora := Vector3(sin(rot), 0, cos(rot))
	var ao := Vector3(fora.z, 0, -fora.x)
	c.caixa(ar - fora * 1.5, Vector3(16, 6.4, 3.0), "pedra", rot)
	o.arcada(ar, fora, ao, 15.0, 6.0, "friso")
	for k in 3:
		o.trepadeira(ar + fora * 0.2 + ao * (-5.0 + k * 5.0) + Vector3(0, 6.2, 0), fora, ao, rng.randf_range(2.0, 3.6), 2.6)
	for k in 10:
		c.cilindro(ar - fora * 0.1 + ao * (-7.0 + k * 1.55) + Vector3(0, 6.4, 0), 0.1, 0.8, "friso", 5, 0.07)
	c.caixa(ar - fora * 0.1 + Vector3(0, 7.2, 0), Vector3(16, 0.18, 0.4), "friso", rot)
	o.estandarte(ar + fora * 0.5 + ao * -2.5 + Vector3(0, 1.6, 0), fora, 4.2, 1.0)
	o.estandarte(ar + fora * 0.5 + ao * 2.5 + Vector3(0, 1.6, 0), fora, 4.2, 1.0)
	# café de toldo vermelho à direita, mais perto
	var cf := Vector3(11.5, 0, 3.0)
	var rc := -PI * 0.5
	c.caixa(cf + Vector3(3.0, 0, 0), Vector3(6, 7.5, 9), "pedra", rc)
	c.caixa(cf + Vector3(0.02, 0.4, 0), Vector3(7.6, 2.8, 0.1), "vitrine", rc)
	for i in 7:
		c.caixa(cf + Vector3(-0.3 - i * 0.26, 3.6 - i * 0.12, 0), Vector3(8.4, 0.06, 0.3), "toldo" if i % 2 == 0 else "toldo_claro", rc)
	c.caixa(cf + Vector3(-0.05, 4.1, 0), Vector3(5.4, 1.0, 0.12), "toldo", rc)
	for k in 2:
		var m := cf + Vector3(-2.6, 0, -2.0 + k * 4.0)
		c.cilindro(m, 0.05, 0.75, "ferro", 6)
		c.cilindro(m + Vector3(0, 0.75, 0), 0.45, 0.05, "creme", 10)
		for q in [-0.7, 0.7]:
			c.caixa(m + Vector3(0, 0, q), Vector3(0.42, 0.5, 0.42), "madeira")
	o.trepadeira(cf + Vector3(-0.1, 7.3, 3.6), Vector3(-1, 0, 0), Vector3(0, 0, 1), 2.6, 2.0)
	# lado esquerdo: casario creme com telhado, árvores e floreiras
	for k in 3:
		var p := Vector3(-14.5, 0, -6.0 + k * 7.5)
		var hh := 7.0 + k * 0.8
		c.caixa(p, Vector3(6, hh, 7), "pedra")
		c.telhado(p + Vector3(0, hh, 0), Vector3(6, 0, 7), 1.6, "telha", 0.4)
		for j in 2:
			c.caixa(p + Vector3(3.02, 1.2 + j * 3.0, 0), Vector3(0.1, 1.8, 1.3), "vidro")
		o.trepadeira(p + Vector3(3.15, hh - 0.2, rng.randf_range(-2, 2)), Vector3(1, 0, 0), Vector3(0, 0, 1), hh * 0.5, 2.2)
	for p in [Vector3(-9.0, 0, -9.0), Vector3(-10.0, 0, 6.5), Vector3(7.5, 0, -11.5), Vector3(-6.5, 0, 12.0)]:
		o.arvore(p, rng.randf_range(1.05, 1.3))
	o.floreira(Vector3(-6.0, 0, 9.5), Vector2(3.6, 1.2), 0.3, 0.7, "pedra")
	o.floreira(Vector3(6.5, 0, 9.0), Vector2(3.0, 1.2), -0.4, 0.7, "pedra")
	o.lampiao(Vector3(-5.0, 0, 3.5))
	o.lampiao(Vector3(5.5, 0, 5.0))
	# cidade de cúpulas no morro ao fundo
	for i in 26:
		var p := Vector3(rng.randf_range(-60, 60), rng.randf_range(2.0, 9.0), rng.randf_range(-70, -38))
		if absf(p.x) < 14 and p.z > -48:
			continue
		var t := Vector3(rng.randf_range(5, 9), rng.randf_range(8, 18), rng.randf_range(5, 9))
		c.caixa(p - Vector3(0, p.y, 0), Vector3(t.x, t.y + p.y, t.z), "pedra")
		if i % 3 == 0:
			o.cupula(p + Vector3(0, t.y, 0), t.x * 0.4, 0.8, "friso")
		elif i % 3 == 1:
			c.caixa(p + Vector3(0, t.y, 0), Vector3(2.0, 5.0, 2.0), "pedra")
			c.cilindro(p + Vector3(0, t.y + 5.0, 0), 1.4, 2.6, "orn_cupula", 4, 0.0)
		else:
			c.telhado(p + Vector3(0, t.y, 0), Vector3(t.x, 0, t.z), 1.8, "telha", 0.3)
	for i in 18:
		var p := Vector3(rng.randf_range(-55, 55), 0, rng.randf_range(-45, -26))
		if absf(p.x) > 12:
			o.arvore(p, rng.randf_range(1.4, 2.0))

func _luz() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var ceu := Sky.new()
	var mc := ShaderMaterial.new()
	mc.shader = CEU
	mc.set_shader_parameter("topo", Color("2a7fdc"))
	mc.set_shader_parameter("horizonte", Color("f8e3bf"))
	mc.set_shader_parameter("cor_sol", Color("ffd49a"))
	mc.set_shader_parameter("nuvens", 0.55)
	mc.set_shader_parameter("semente", 11.0)
	ceu.sky_material = mc
	ceu.radiance_size = Sky.RADIANCE_SIZE_32
	env.sky = ceu
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dab69a")
	env.ambient_light_energy = 0.46
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.fog_enabled = true
	env.fog_light_color = Color("f2dcbd")
	env.fog_density = 0.0035
	env.fog_sky_affect = 0.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.18
	env.adjustment_contrast = 1.08
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.light_color = Color("ffd39a")
	sol.light_energy = 1.45
	sol.rotation_degrees = Vector3(-30, -35, 0)
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 45.0
	sol.shadow_blur = 1.6
	sol.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_AND_SKY
	add_child(sol)
	var pre := DirectionalLight3D.new()
	pre.light_color = Color("ffc9a0")
	pre.light_energy = 0.22
	pre.rotation_degrees = Vector3(-20, 135, 0)
	pre.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	add_child(pre)
