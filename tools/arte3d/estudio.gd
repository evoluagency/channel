extends Node3D
## Estúdio (sessão 1.6, prova de direção visual). Renderiza uma construção com o renderizador
## completo do Godot (Forward+): oclusão de ambiente, luz indireta, reflexo, brilho e textura de
## desgaste, e com a paleta trocada para tons terrosos e contidos. As receitas não mudam.
## Uso:
##   godot --path tools/arte3d --rendering-method forward_plus res://estudio.tscn -- \
##     --construcao=banco --faixas=4,6 --saida=PASTA
## Pré-renderizado no PC, o resultado vira imagem 2D no jogo (o celular não precisa desse renderizador).

const KIT := preload("res://kit.gd")

## Paleta nova: cor do kit (hex) -> [cor nova, rugosidade, metal]. O que não está aqui perde
## 25% de saturação. Metais e ouro passam a refletir de verdade.
const TROCA := {
	"7ed957": ["8c9a58", 0.95, 0.0],   # grama -> oliva
	"4fb83f": ["66733f", 0.95, 0.0],   # laje -> oliva escuro
	"c99b62": ["b38f63", 0.95, 0.0],   # terra
	"ddd5c6": ["c8bda9", 0.85, 0.0],   # calçada -> pedra quente
	"4a4f5c": ["45474c", 0.9, 0.0],    # asfalto
	"e8e1d4": ["dcd2bf", 0.8, 0.0],    # concreto
	"b9b0a2": ["9b9284", 0.85, 0.0],   # concreto escuro
	"f4f6fa": ["e4e0d6", 0.6, 0.0],    # painel
	"8d9bb0": ["a3abb5", 0.35, 0.85],  # aço
	"4d586b": ["50565f", 0.4, 0.8],    # aço escuro
	"dfe7f2": ["c9d1da", 0.25, 0.9],   # montantes
	"f0a81c": ["d8a24a", 0.28, 0.95],  # ouro
	"ffc21a": ["e2ac3c", 0.5, 0.0],    # amarelo
	"1f63e8": ["3e6fb0", 0.55, 0.0],   # aliança azul -> azul-ardósia
	"6fd0ff": ["86c6de", 0.05, 0.6],   # vidro
	"f3ede1": ["e8dcc4", 0.45, 0.0],   # mármore
	"f3f0ea": ["e2dccf", 0.45, 0.0],
	"ffffff": ["eeeae2", 0.6, 0.0],
}

var args := {}
var _ruido: NoiseTexture2D
var _ruido_r: NoiseTexture2D
var _cache := {}

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var par := a.trim_prefix("--").split("=", true, 1)
		args[par[0]] = par[1] if par.size() > 1 else ""
	_ruido = _textura(0.9, 0.6)
	_ruido_r = _textura(0.5, 1.0)
	var c: String = args.get("construcao", "banco")
	var saida: String = args.get("saida", "user://estudio")
	DirAccess.make_dir_recursive_absolute(saida)
	var receita = load("res://construcoes/%s.gd" % c).new()
	for f in String(args.get("faixas", "4")).split(","):
		await _render(receita, c, int(f), "%s/%s_f%s_estudio.png" % [saida, c, f])
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

## Troca o material do kit pela versão do estúdio.
func _material(m: Material) -> Material:
	if not (m is StandardMaterial3D):
		return m
	if _cache.has(m):
		return _cache[m]
	var s := m as StandardMaterial3D
	var n := s.duplicate() as StandardMaterial3D
	var hexa := s.albedo_color.to_html(false)
	if s.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED or s.emission_enabled:
		# hologramas e luzes: mantêm a cor; o brilho (glow) do estúdio faz o resto
		pass
	elif TROCA.has(hexa):
		var t: Array = TROCA[hexa]
		n.albedo_color = Color(t[0], s.albedo_color.a)
		n.roughness = t[1]
		n.metallic = t[2]
	else:
		var c := s.albedo_color
		n.albedo_color = Color.from_hsv(c.h, c.s * 0.75, c.v * 0.96, c.a)
	if not n.emission_enabled and n.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED:
		# desgaste: ruído suave na cor e na rugosidade, projetado nas três direções
		n.albedo_texture = _ruido
		n.roughness_texture = _ruido_r
		n.uv1_triplanar = true
		n.uv1_world_triplanar = true
		n.uv1_scale = Vector3.ONE * 0.35
		if n.metallic > 0.5:
			n.clearcoat_enabled = false
			n.metallic_specular = 0.6
		n.rim_enabled = true
		n.rim = 0.25
		n.rim_tint = 0.6
	_cache[m] = n
	return n

func _aplicar(no: Node) -> void:
	if no is MeshInstance3D:
		if no.material_override:
			no.material_override = _material(no.material_override)
	for f in no.get_children():
		_aplicar(f)

func _render(receita, c: String, faixa: int, arquivo: String) -> void:
	get_window().size = Vector2i(900, 900)
	var raiz := Node3D.new()
	add_child(raiz)
	_cena(raiz)
	var k = KIT.new(args.get("alianca", "azul"))
	var obra := Node3D.new()
	raiz.add_child(obra)
	receita.construir(k, obra, faixa)
	_aplicar(obra)
	for i in 30:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(arquivo)
	print("salvo ", arquivo)
	raiz.queue_free()
	await get_tree().process_frame

func _cena(raiz: Node3D) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("9fa8ad")
	var ceu := Sky.new()
	var mc := ProceduralSkyMaterial.new()
	mc.sky_top_color = Color("6f9fd0")
	mc.sky_horizon_color = Color("d9e2e8")
	mc.ground_horizon_color = Color("c9c0ae")
	mc.ground_bottom_color = Color("8a7d66")
	mc.sun_angle_max = 30.0
	ceu.sky_material = mc
	env.sky = ceu
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.45
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.85
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 3.5
	env.ssao_power = 1.6
	env.ssil_enabled = true
	env.ssil_intensity = 0.8
	env.ssr_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 1.3
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.15
	env.adjustment_saturation = 1.15
	var we := WorldEnvironment.new()
	we.environment = env
	raiz.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.light_color = Color("ffe9c9")
	sol.light_energy = 2.6
	sol.rotation_degrees = Vector3(-52, -25, 0)
	sol.shadow_enabled = true
	sol.light_angular_distance = 1.5
	sol.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sol.directional_shadow_max_distance = 60.0
	raiz.add_child(sol)
	var contra := DirectionalLight3D.new()
	contra.light_color = Color("cfe0ff")
	contra.light_energy = 0.45
	contra.rotation_degrees = Vector3(-20, 150, 0)
	raiz.add_child(contra)
	var sonda := ReflectionProbe.new()
	sonda.size = Vector3(14, 16, 14)
	sonda.position = Vector3(0, 6, 0)
	sonda.update_mode = ReflectionProbe.UPDATE_ALWAYS
	raiz.add_child(sonda)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.rotation_degrees = Vector3(-33, 45, 0)
	cam.size = 15.8
	cam.position = Vector3(0, 4.9, 0) + cam.basis.z * 40.0
	cam.far = 200.0
	raiz.add_child(cam)
	cam.make_current()
