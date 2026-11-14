extends Node3D
## Renderiza construções em PNG. Uso:
##   godot --path tools/arte3d --rendering-driver opengl3 -- \
##     --construcao=prefeitura --saida=PASTA --trabalhos=1:azul:folha,6:azul:detalhe
## Cada trabalho é faixa:aliança:enquadramento (folha = escala comum; detalhe = mais perto).

const KIT := preload("res://kit.gd")
const FUSAO := preload("res://fusao.gd")

var args := {}

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var par := a.trim_prefix("--").split("=", true, 1)
		args[par[0]] = par[1] if par.size() > 1 else ""
	var construcao: String = args.get("construcao", "prefeitura")
	var saida: String = args.get("saida", "user://")
	var script = load("res://construcoes/%s.gd" % construcao)
	if script == null or not script.can_instantiate():
		push_error("receita inválida: " + construcao)
		get_tree().quit(1)
		return
	var receita = script.new()
	DirAccess.make_dir_recursive_absolute(saida)
	for t in String(args.get("trabalhos", "1:azul:folha")).split(","):
		var p := t.split(":")
		var faixa := int(p[0])
		var cor := p[1]
		var enq := p[2] if p.size() > 2 else "folha"
		await _renderizar(receita, faixa, cor, enq, "%s/%s_f%d_%s_%s.png" % [saida, construcao, faixa, cor, enq])
	get_tree().quit()

func _renderizar(receita, faixa: int, cor: String, enq: String, arquivo: String) -> void:
	var tam := 1400 if enq == "detalhe" else 900
	get_window().size = Vector2i(tam, tam)
	var raiz := Node3D.new()
	add_child(raiz)
	_cena(raiz, enq)
	var k = KIT.new(cor)
	var cam: Camera3D = raiz.get_node("Camera")
	k.modo_cidade = args.has("cidade")
	var obra := Node3D.new()
	raiz.add_child(obra)
	var topo: float = receita.construir(k, obra, faixa)
	if args.has("contar"):
		var n := [0, 0]
		_contar(obra, n)
		print("CONTAGEM %s f%d malhas=%d triangulos=%d" % [args.get("construcao"), faixa, n[0], n[1]])
	if args.has("fundir"):
		# --fundir=0 ou 1: troca as peças pela malha fundida do LOD pedido (conferência)
		var f: Dictionary = FUSAO.fundir(obra)
		var mi := MeshInstance3D.new()
		mi.mesh = f["lod%d" % int(args.get("fundir", "0"))]
		raiz.add_child(mi)
		for e in f.extras:
			e[0].get_parent().remove_child(e[0])
			e[0].transform = e[1]
			raiz.add_child(e[0])
		obra.queue_free()
		print("FUNDIDA %s f%d superficies=%d triangulos=%d avisos=%s" % [args.get("construcao"), faixa, mi.mesh.get_surface_count(), FUSAO.triangulos(mi.mesh), f.avisos])
	var nivel := 1 + (faixa - 1) * 5
	if enq != "alianca":
		k.selo(raiz, Vector3(0, topo + 0.7, 0), nivel, 1, faixa == 6, cam.global_transform.basis)
	for i in 8:
		await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(arquivo)
	print("salvo ", arquivo)
	raiz.queue_free()
	await get_tree().process_frame

func _cena(raiz: Node3D, enq: String) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("d6e8f5")
	var ceu := Sky.new()
	var mc := ProceduralSkyMaterial.new()
	mc.sky_top_color = Color("4a9dff")
	mc.sky_horizon_color = Color("cfe9ff")
	mc.ground_horizon_color = Color("cfe9ff")
	mc.ground_bottom_color = Color("7fb26a")
	ceu.sky_material = mc
	env.sky = ceu
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.4
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	env.tonemap_white = 4.0
	env.glow_enabled = (args.get("glow","0") == "1")
	env.glow_intensity = 0.7
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.1
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.2
	env.adjustment_contrast = 1.08
	var we := WorldEnvironment.new()
	we.environment = env
	raiz.add_child(we)

	var sol := DirectionalLight3D.new()
	sol.light_color = Color("fff0d8")
	sol.light_energy = 1.0
	sol.rotation_degrees = Vector3(-50, -18, 0)
	sol.shadow_enabled = true
	sol.shadow_blur = 1.5
	sol.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sol.directional_shadow_max_distance = 60.0
	raiz.add_child(sol)
	var preenche := DirectionalLight3D.new()
	preenche.light_color = Color("bcd7ff")
	preenche.light_energy = 0.3
	preenche.rotation_degrees = Vector3(-25, 120, 0)
	raiz.add_child(preenche)

	var cam := Camera3D.new()
	cam.name = "Camera"
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.rotation_degrees = Vector3(-33, 45, 0)
	var alvo := Vector3(0, 4.9, 0)
	cam.size = 15.8
	if enq == "detalhe":
		alvo = Vector3(0, 4.6, 0)
		cam.size = 13.0
	elif enq == "alianca":
		alvo = Vector3(0, 4.0, 0)
		cam.size = 14.0
	cam.position = alvo + cam.basis.z * 40.0
	cam.far = 200.0
	raiz.add_child(cam)
	cam.make_current()

func _contar(no: Node, n: Array) -> void:
	if no is MeshInstance3D and no.mesh:
		n[0] += 1
		for s in no.mesh.get_surface_count():
			var a = no.mesh.surface_get_arrays(s)
			var idx = a[Mesh.ARRAY_INDEX]
			n[1] += (idx.size() if idx else a[Mesh.ARRAY_VERTEX].size()) / 3
	for c in no.get_children():
		_contar(c, n)
