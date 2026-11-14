extends Node3D
## Prova de direção visual (sessão 1.6): um bairro da base em retrato, com cenário (terreno,
## pátio de concreto, cerca, vias, árvores, névoa) e render de estúdio (Forward+).
## Paletas próprias, sem as cores da bandeira. As receitas não mudam: a paleta troca as cores.
## Uso:
##   godot --path tools/arte3d --rendering-method forward_plus res://bairro.tscn -- --paleta=A --saida=PASTA

const KIT := preload("res://kit.gd")

## Cada paleta: papel -> cor. "teto" é a cor de identidade (substitui o azul da aliança nas
## faixas, telhados e toldos); "acento" substitui o amarelo; "verde" as plantas.
const PALETAS := {
	"A": {"nome": "Ardósia e cobre", "teto": "4a5d75", "acento": "d27a35", "verde": "7f8f4c", "parede": "e6dccb",
		"patio": "c3b9a6", "terreno": "6f7c43", "terra": "a5835c", "vidro": "86b5c4", "neon": "5fd3e6"},
	"B": {"nome": "Petróleo e tijolo", "teto": "1f6a72", "acento": "c4573e", "verde": "6f8a52", "parede": "ece2cf",
		"patio": "c9bda6", "terreno": "6c7d48", "terra": "a98a61", "vidro": "7fbcc0", "neon": "58e0c8"},
	"C": {"nome": "Grafite e laranja", "teto": "3a3f48", "acento": "ef8a2a", "verde": "84914d", "parede": "e9e3d7",
		"patio": "bdb6a8", "terreno": "727f45", "terra": "a7865e", "vidro": "8ab4cc", "neon": "ffb347"},
}

var args := {}
var pal := {}
var _cache := {}
var _ruido: NoiseTexture2D
var _ruido_r: NoiseTexture2D

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var par := a.trim_prefix("--").split("=", true, 1)
		args[par[0]] = par[1] if par.size() > 1 else ""
	pal = PALETAS[args.get("paleta", "A")]
	_ruido = _textura(0.9, 0.6)
	_ruido_r = _textura(0.5, 1.0)
	get_window().size = Vector2i(int(args.get("largura", "720")), int(args.get("altura", "1560")))
	_cena()
	_montar()
	for i in 40:
		await RenderingServer.frame_post_draw
	var saida: String = args.get("saida", "user://bairro")
	DirAccess.make_dir_recursive_absolute(saida)
	var arq := "%s/bairro_%s.png" % [saida, args.get("paleta", "A")]
	get_viewport().get_texture().get_image().save_png(arq)
	print("salvo ", arq)
	get_tree().quit()

func _textura(contraste: float, escala: float) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = 0.02 * escala
	n.fractal_octaves = 5
	var t := NoiseTexture2D.new()
	t.width = 512; t.height = 512
	t.seamless = true
	t.noise = n
	var g := Gradient.new()
	g.set_color(0, Color(1.0 - 0.22 * contraste, 1.0 - 0.22 * contraste, 1.0 - 0.24 * contraste))
	g.set_color(1, Color(1, 1, 1))
	t.color_ramp = g
	return t

# ---------------------------------------------------------------- paleta

## Papel de cada cor do kit na paleta nova: [papel ou hex, rugosidade, metal].
func _troca(hexa: String, s: StandardMaterial3D) -> Array:
	var aliancas := ["1f63e8", "f0453a", "22b860", "8e4dff", "ffb400"]
	if hexa in aliancas:
		return [pal.teto, 0.55, 0.0]
	match hexa:
		"7ed957", "4fb83f":            # grama e laje do lote: viram pátio de concreto
			return [pal.patio, 0.9, 0.0]
		"ddd5c6": return [pal.patio, 0.85, 0.0]
		"c99b62": return [pal.terra, 0.95, 0.0]
		"4a4f5c": return ["45474c", 0.9, 0.0]
		"e8e1d4", "f4f6fa", "ffffff", "f3ede1", "f3f0ea", "f5e6c8": return [pal.parede, 0.7, 0.0]
		"b9b0a2": return ["9b9284", 0.85, 0.0]
		"8d9bb0", "dfe7f2": return ["a3abb5", 0.35, 0.85]
		"4d586b": return ["50565f", 0.4, 0.8]
		"f0a81c": return ["d8a24a", 0.28, 0.95]
		"ffc21a", "ff8a2a": return [pal.acento, 0.55, 0.0]
		"3fc75a", "8be36b", "6f9a52": return [pal.verde, 0.9, 0.0]
		"6fd0ff", "8fd8ff", "5cc4ff", "4aa8e6", "8fdcff", "5fb8f0": return [pal.vidro, 0.05, 0.6]
		"1f8a5b", "146246", "3fb98a", "2f9a78": return [pal.teto, 0.5, 0.0]   # verde-cédula do Banco
		"2b6fae", "234a8f": return ["2c3e55", 0.08, 0.6]
	var c := s.albedo_color
	return [Color.from_hsv(c.h, c.s * 0.65, c.v * 0.95).to_html(false), s.roughness, s.metallic]

func _material(m: Material) -> Material:
	if not (m is StandardMaterial3D):
		return m
	if _cache.has(m):
		return _cache[m]
	var s := m as StandardMaterial3D
	var n := s.duplicate() as StandardMaterial3D
	var hexa := s.albedo_color.to_html(false)
	if s.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED or s.emission_enabled:
		var c := Color(pal.neon)
		if s.emission_enabled:
			n.emission = c if hexa in ["3ef2ff", "1f63e8"] else s.emission
			n.albedo_color = Color(n.emission, s.albedo_color.a)
		elif hexa.begins_with("3e") or hexa.begins_with("1f") or hexa.begins_with("0f") or hexa.begins_with("9f"):
			n.albedo_color = Color(c * 1.4, s.albedo_color.a)
	else:
		var t := _troca(hexa, s)
		n.albedo_color = Color(Color(t[0]), s.albedo_color.a)
		n.roughness = t[1]
		n.metallic = t[2]
		n.albedo_texture = _ruido
		n.roughness_texture = _ruido_r
		n.uv1_triplanar = true
		n.uv1_world_triplanar = true
		n.uv1_scale = Vector3.ONE * 0.35
		n.rim_enabled = true
		n.rim = 0.2
		n.rim_tint = 0.6
	_cache[m] = n
	return n

func _aplicar(no: Node) -> void:
	if no is MeshInstance3D and no.material_override:
		no.material_override = _material(no.material_override)
	for f in no.get_children():
		_aplicar(f)

# ---------------------------------------------------------------- bairro

## 4 colunas x 6 linhas de lotes; via na coluna 1 e na linha 3.
const LAYOUT := [
	["radar|3", "via|3", "usina|3", "usina|3"],
	["alojamento|3", "via|3", "prefeitura|4", "estufa|3"],
	["alojamento|3", "via|3", "banco|4", "mineradora|3"],
	["via|3", "via|3", "via|3", "via|3"],
	["parque|3", "via|3", "centro_tecnologico|4", "central_energia|3"],
	["base_militar|3", "via|3", "entreposto|3", "estacao_agua|3"],
]
const PASSO := 6.0

func _montar() -> void:
	var k = KIT.new("azul")
	var obra := Node3D.new()
	add_child(obra)
	var receitas := {}
	var nl := LAYOUT.size()
	var nc: int = LAYOUT[0].size()
	for l in nl:
		for c in nc:
			var p: PackedStringArray = LAYOUT[l][c].split("|")
			if not receitas.has(p[0]):
				receitas[p[0]] = load("res://construcoes/%s.gd" % p[0]).new()
			var g := Node3D.new()
			g.position = Vector3((c - (nc - 1) * 0.5) * PASSO, 0, (l - (nl - 1) * 0.5) * PASSO)
			obra.add_child(g)
			receitas[p[0]].construir(k, g, int(p[1]))
	# pátio de concreto sob a base, borda e cerca
	var lx := nc * PASSO + 2.0
	var lz := nl * PASSO + 2.0
	k.caixa(obra, Vector3(0, -0.62, 0), Vector3(lx, 0.3, lz), k.p("calcada"), 0.15)
	_cerca(k, obra, lx * 0.5 + 0.4, lz * 0.5 + 0.4)
	# tanques e contêineres encostados na cerca (vida de base)
	for i in 4:
		var z := -lz * 0.5 + 3.0 + i * 1.3
		k.cilindro(obra, Vector3(lx * 0.5 + 1.6, -0.45, z), 0.55, 1.5, k.p("concreto_escuro"), 16)
	for i in 3:
		k.conteiner(obra, Vector3(-lx * 0.5 - 1.8, -0.45, lz * 0.5 - 4.0 - i * 1.3), 90, [Color("b0603a"), Color("6f7a52"), Color("4f6a86")][i])
	# trilhos ao fundo, cruzando o terreno
	_trilhos(k, obra, Vector3(lx * 0.5 + 6.0, -0.55, 0))
	_aplicar(obra)
	# terreno de fora, árvores e pedras (já na paleta)
	_terreno()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var folha := _mat_cor(pal.verde, 0.9)
	var folha2 := _mat_cor(Color(pal.verde).darkened(0.18).to_html(false), 0.9)
	var tronco := _mat_cor("7a5a3c", 0.9)
	for i in 70:
		var p := Vector3(rng.randf_range(-40, 40), -0.6, rng.randf_range(-45, 45))
		if absf(p.x) < lx * 0.5 + 3.5 and absf(p.z) < lz * 0.5 + 3.5:
			continue
		if absf(p.x - (lx * 0.5 + 6.0)) < 2.5:
			continue
		_arvore(p, rng.randf_range(1.0, 1.8), folha if i % 3 else folha2, tronco)
	for i in 25:
		var p := Vector3(rng.randf_range(-40, 40), -0.6, rng.randf_range(-45, 45))
		if absf(p.x) < lx * 0.5 + 3.0 and absf(p.z) < lz * 0.5 + 3.0:
			continue
		var r := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = rng.randf_range(0.3, 0.8); sm.height = sm.radius * 1.1
		sm.radial_segments = 7; sm.rings = 4
		r.mesh = sm
		r.position = p
		r.material_override = _mat_cor("8d877c", 0.95)
		add_child(r)

func _mat_cor(hexa: String, rug: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hexa)
	m.roughness = rug
	m.albedo_texture = _ruido
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * 0.2
	return m

func _arvore(p: Vector3, e: float, folha: Material, tronco: Material) -> void:
	var t := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.08 * e; cm.bottom_radius = 0.12 * e; cm.height = 0.8 * e; cm.radial_segments = 6
	t.mesh = cm; t.position = p + Vector3(0, 0.4 * e, 0); t.material_override = tronco
	add_child(t)
	for j in 3:
		var f := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = (0.6 - j * 0.12) * e; sm.height = sm.radius * 1.7
		sm.radial_segments = 9; sm.rings = 5
		f.mesh = sm
		f.position = p + Vector3((j - 1) * 0.18 * e, (0.95 + j * 0.45) * e, (1 - j) * 0.1 * e)
		f.material_override = folha
		add_child(f)

func _cerca(k, pai: Node3D, hx: float, hz: float) -> void:
	var poste = k.p("aco_escuro", 0.5, 0.6)
	var tela = k.mat(Color("6d7480"), 0.6, 0.4, 0.0, 0.55)
	var lados := [[Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz)], [Vector3(hx, 0, -hz), Vector3(hx, 0, hz)],
		[Vector3(hx, 0, hz), Vector3(-hx, 0, hz)], [Vector3(-hx, 0, hz), Vector3(-hx, 0, -hz)]]
	for ld in lados:
		var a: Vector3 = ld[0]
		var b: Vector3 = ld[1]
		var n := int(a.distance_to(b) / 2.0)
		for i in n + 1:
			var p := a.lerp(b, float(i) / n) + Vector3(0, -0.5, 0)
			k.cilindro(pai, p, 0.06, 1.3, poste, 6)
		var meio := (a + b) * 0.5 + Vector3(0, -0.5, 0)
		var comp := a.distance_to(b)
		var t := Vector3(comp, 1.0, 0.03) if absf(a.z - b.z) < 0.01 else Vector3(0.03, 1.0, comp)
		k.caixa(pai, meio + Vector3(0, 0.15, 0), t, tela, 0.0)
		var tt := Vector3(comp, 0.06, 0.06) if absf(a.z - b.z) < 0.01 else Vector3(0.06, 0.06, comp)
		k.caixa(pai, meio + Vector3(0, 1.2, 0), tt, poste, 0.01)
		k.caixa(pai, meio + Vector3(0, 0.1, 0), tt + Vector3(0, 0.2, 0), k.mat(Color(pal.acento), 0.7), 0.01)

func _trilhos(k, pai: Node3D, c: Vector3) -> void:
	k.caixa(pai, c + Vector3(0, -0.1, 0), Vector3(3.2, 0.25, 90), k.mat(Color("8a7f6e"), 0.95), 0.1)
	for i in 120:
		k.caixa(pai, c + Vector3(0, 0.05, -45 + i * 0.75), Vector3(2.2, 0.1, 0.25), k.p("madeira", 0.9), 0.02)
	for x in [-0.7, 0.7]:
		k.caixa(pai, c + Vector3(x, 0.15, 0), Vector3(0.1, 0.12, 90), k.p("aco", 0.35, 0.8), 0.0)

func _terreno() -> void:
	var m := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(300, 300)
	m.mesh = pm
	m.position.y = -0.62
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(pal.terreno)
	var n := FastNoiseLite.new()
	n.frequency = 0.03
	n.fractal_octaves = 4
	var t := NoiseTexture2D.new()
	t.width = 1024; t.height = 1024; t.seamless = true; t.noise = n
	var g := Gradient.new()
	g.set_color(0, Color(pal.terra).lightened(0.1))
	g.add_point(0.45, Color(1, 1, 1))
	g.set_color(1, Color(1, 1, 1).darkened(0.12))
	t.color_ramp = g
	mt.albedo_texture = t
	mt.uv1_scale = Vector3(6, 6, 6)
	mt.roughness = 0.95
	m.material_override = mt
	add_child(m)

func _cena() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("b9c3b2")
	var ceu := Sky.new()
	var mc := ProceduralSkyMaterial.new()
	mc.sky_top_color = Color("7aa6cf")
	mc.sky_horizon_color = Color("dfe6dd")
	mc.ground_horizon_color = Color("c9c3ae")
	mc.ground_bottom_color = Color("8a8a66")
	ceu.sky_material = mc
	env.sky = ceu
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.9
	env.ssao_enabled = true
	env.ssao_radius = 1.4
	env.ssao_intensity = 3.0
	env.ssao_power = 1.6
	env.ssil_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_hdr_threshold = 1.3
	env.fog_enabled = false
	env.fog_light_color = Color("cfd6c4")
	env.fog_density = 0.006
	env.fog_sky_affect = 0.0
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.12
	env.adjustment_saturation = 1.12
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.light_color = Color("ffe6c4")
	sol.light_energy = 2.6
	sol.rotation_degrees = Vector3(-50, -30, 0)
	sol.shadow_enabled = true
	sol.light_angular_distance = 1.5
	sol.directional_shadow_max_distance = 140.0
	add_child(sol)
	var contra := DirectionalLight3D.new()
	contra.light_color = Color("cfe0ff")
	contra.light_energy = 0.4
	contra.rotation_degrees = Vector3(-20, 150, 0)
	add_child(contra)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.rotation_degrees = Vector3(-38, 45, 0)
	cam.size = float(args.get("zoom", "24"))
	cam.position = Vector3(1.5, 0, 1.5) + cam.basis.z * 80.0
	cam.far = 300.0
	add_child(cam)
	cam.make_current()
