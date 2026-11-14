extends Node3D
## Cidade 3D em retrato (sessão 1.6, M8). Projeto de teste, separado do jogo instalado.
##
## Uso (janela 540 x 1170 = metade de 1080 x 2340):
##   godot --path tools/arte3d --rendering-driver opengl3 res://cidade.tscn -- [opções]
## Opções:
##   --cenario=cheia|n30|misto   composição dos 80 lotes (ver _composicao)
##   --sem_fusao                 monta as peças soltas, como nas folhas (comparação)
##   --sombra=0                  desliga a sombra do sol
##   --medir=PASTA               mede três zooms, salva PNG e contagens.json e sai
##   --quadros=N                 quadros por medição (padrão 120)
## Sem --medir a cena fica aberta: arrastar com um dedo (ou mouse), pinça (ou roda) para zoom.

const KIT := preload("res://kit.gd")
const FUSAO := preload("res://fusao.gd")

## Base: 80 lotes, 8 colunas (x) por 10 linhas (z). Passo de 6 unidades (lote 5,4 + borda).
const COLUNAS := 8
const LINHAS := 10
const PASSO := 6.0
const LARGURA_LOTE_TELA := 5.9 * 1.41421356   # lote visto a 45°, em unidades

## Limites da câmera (seção 3.1 adaptada à base).
const BASE_MIN_LARGURA := 0.6    # afastar: a base nunca fica com menos de 60% da largura da tela
const LOTE_MAX_LARGURA := 0.85   # aproximar: um lote ocupa no máximo 85% da largura
var LOD_TAMANHO := 24.0        # acima desta largura visível (unidades) usa o LOD 1
const DISTANCIA := 70.0
## LOD 0 em blocos de BLOCO x BLOCO lotes, para a câmera recortar o que não aparece de perto.
## O LOD 1 (de longe) fica numa MultiMesh só por construção e faixa: tudo aparece.
const BLOCO := 2

## id do JSON v0.3 -> receita
const RECEITAS := {
	"pref": "prefeitura", "alo": "alojamento", "est": "estufa", "usi": "usina",
	"min": "mineradora", "ene": "central_energia", "ban": "banco", "rad": "radar",
	"bas": "base_militar", "ent": "entreposto", "via": "via", "par": "parque",
	"agu": "estacao_agua", "hel": "heliponto", "tec": "centro_tecnologico",
}

var args := {}
var kit
var cam: Camera3D
var sol: DirectionalLight3D
var selos: Node2D
var lotes := []           # [{id, nivel, pos: Vector3, topo}]
var conjuntos := []       # [{lod0: Node3D, lod1: Node3D}] por (receita, faixa)
var _cache := {}          # "receita|faixa" -> resultado da fusão
var _receitas := {}
var largura := 30.0       # largura visível da câmera (unidades)
var pan := Vector2.ZERO   # deslocamento do alvo no plano da câmera (direita, cima)
var _toques := {}
var _lod_atual := -1
var tempo_montagem_ms := 0.0
var info_montagem := {}
var sombra_leve := true
static var proximos := {}   # argumentos para recarregar a cena pelos botões do painel
var hud: CanvasLayer
var hud_texto: Label
var _hud_tempo := 0.0
var _medindo := false

func _ready() -> void:
	if args.is_empty() and not proximos.is_empty():
		args = proximos.duplicate()
	if args.is_empty():   # o smoke pode passar os argumentos antes de entrar na árvore
		for a in OS.get_cmdline_user_args():
			var par := a.trim_prefix("--").split("=", true, 1)
			args[par[0]] = par[1] if par.size() > 1 else ""
	var celular := OS.has_feature("mobile")
	if not celular:
		get_window().size = Vector2i(540, 1170)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	# sombra e MSAA do celular (as folhas de arte usam 8x e mapa de 8192; aqui não)
	RenderingServer.directional_shadow_atlas_set_size(2048 if celular else 4096, true)
	get_viewport().msaa_3d = Viewport.MSAA_2X
	kit = KIT.new("azul")
	kit.modo_cidade = not args.has("sem_fusao")
	sombra_leve = args.get("sombra_leve", "1") != "0"
	LOD_TAMANHO = float(args.get("lod_tamanho", str(LOD_TAMANHO)))
	_cena()
	var t0 := Time.get_ticks_usec()
	_montar(_composicao(args.get("cenario", "cheia")))
	tempo_montagem_ms = (Time.get_ticks_usec() - t0) / 1000.0
	print("MONTAGEM %.0f ms %s" % [tempo_montagem_ms, info_montagem])
	largura = 20.0
	_aplicar_camera()
	if args.has("medir"):
		_medir.call_deferred()
	elif not args.has("sem_painel"):
		_painel()

# ---------------------------------------------------------------- composição

## Devolve 80 entradas [id, nível]. Lote vazio = ["", 0].
## cheia: cidade no nível 30 com todos os lotes ocupados (33 prédios pela regra, 17 vias e
##        30 lotes extras repetindo os 15 prédios: pior caso de triângulos).
## n30:   só o que a regra permite no nível 30 (33 prédios + 17 vias), 30 lotes vazios.
## misto: os 80 lotes com prédios em faixas sorteadas (pior caso de malhas diferentes).
func _composicao(cenario: String) -> Array:
	var grade := []
	grade.resize(COLUNAS * LINHAS)
	var livres := []
	for l in LINHAS:
		for c in COLUNAS:
			var i := l * COLUNAS + c
			if c == 3 or l == 4:
				grade[i] = ["via", 30]
			else:
				livres.append(i)
	var regra := ["pref", "ban", "tec", "bas", "rad", "ent", "par", "agu", "hel"]
	for n in 4:
		regra.append("alo")
	for id in ["est", "usi", "min", "ene"]:
		for n in 5:
			regra.append(id)
	# a Prefeitura no lote livre mais perto do cruzamento das vias
	livres.sort_custom(func(a, b): return _dist_centro(a) < _dist_centro(b))
	var rng := RandomNumberGenerator.new()
	rng.seed = 30
	var todos: Array = RECEITAS.keys()
	for k in livres.size():
		var i: int = livres[k]
		if k < regra.size():
			grade[i] = [regra[k], 30]
		elif cenario == "n30":
			grade[i] = ["", 0]
		else:
			grade[i] = [todos[(k - regra.size()) % todos.size()], 30]
	if cenario == "misto":
		for i in grade.size():
			if grade[i][0] != "":
				grade[i] = [grade[i][0], rng.randi_range(1, 30)]
	return grade

func _dist_centro(i: int) -> float:
	return Vector2(i % COLUNAS - 3, i / COLUNAS - 4).length()

func _pos_lote(i: int) -> Vector3:
	var c := i % COLUNAS
	var l := i / COLUNAS
	return Vector3((c - (COLUNAS - 1) * 0.5) * PASSO, 0, (l - (LINHAS - 1) * 0.5) * PASSO)

# ---------------------------------------------------------------- montagem

func _receita(nome: String):
	if not _receitas.has(nome):
		var s = load("res://construcoes/%s.gd" % nome)
		_receitas[nome] = s.new() if s != null and s.can_instantiate() else null
		if _receitas[nome] == null:
			push_error("receita ausente: " + nome)
	return _receitas[nome]

func _vazio(pai: Node3D) -> float:
	kit.lote(pai, 5.4, kit.p("grama", 0.9))
	return 0.2

## Monta (ou pega do cache) uma construção numa faixa. Devolve {no, topo} ou a fusão.
func _construir(id: String, faixa: int) -> Dictionary:
	var chave := "%s|%d" % [id, faixa]
	if _cache.has(chave):
		return _cache[chave]
	var obra := Node3D.new()
	var topo := 0.2
	if id == "":
		topo = _vazio(obra)
	else:
		topo = _receita(RECEITAS[id]).construir(kit, obra, faixa)
	var r := {"obra": obra, "topo": topo}
	if not args.has("sem_fusao"):
		# LOD 1 sai de uma segunda montagem com menos segmentos
		var longe := Node3D.new()
		kit.longe = true
		if id == "":
			_vazio(longe)
		else:
			_receita(RECEITAS[id]).construir(kit, longe, faixa)
		kit.longe = false
		r.merge(FUSAO.fundir(obra, longe))
		longe.free()
	_cache[chave] = r
	return r

## Separa os lotes em blocos de BLOCO x BLOCO.
func _blocos(idx: Array) -> Dictionary:
	var bl := int(args.get("bloco", str(BLOCO)))
	var blocos := {}
	for i in idx:
		var b: int = (i % COLUNAS) / bl + 100 * ((i / COLUNAS) / bl)
		if not blocos.has(b):
			blocos[b] = []
		blocos[b].append(i)
	return blocos

func _montar(grade: Array) -> void:
	var grupos := {}   # chave -> [índices]
	for i in grade.size():
		var id: String = grade[i][0]
		var nivel: int = grade[i][1]
		var faixa := 1 if nivel <= 0 else (nivel - 1) / 5 + 1
		var chave := "%s|%d" % [id, faixa]
		if not grupos.has(chave):
			grupos[chave] = []
		grupos[chave].append(i)
		lotes.append({"id": id, "nivel": nivel, "pos": _pos_lote(i), "topo": 0.0})
	var pecas := 0
	var tri := [0, 0]
	var contagem := {}
	for g in grade:
		var nome: String = g[0] if g[0] != "" else "vazio"
		contagem[nome] = contagem.get(nome, 0) + 1
	for chave in grupos:
		var p: PackedStringArray = chave.split("|")
		var f := _construir(p[0], int(p[1]))
		var idx: Array = grupos[chave]
		for i in idx:
			lotes[i].topo = f.topo
		if args.has("sem_fusao"):
			for i in idx:
				var copia: Node3D = f.obra.duplicate()
				copia.position = lotes[i].pos
				add_child(copia)
			continue
		pecas += f.pecas * idx.size()
		var par := {}
		for lod in 2:
			var no := Node3D.new()
			no.name = "%s_f%s_lod%d" % [p[0], p[1], lod]
			var blocos := _blocos(idx) if lod == 0 else {0: idx}
			for b in blocos:
				var mm := MultiMesh.new()
				mm.transform_format = MultiMesh.TRANSFORM_3D
				mm.mesh = f["lod%d" % lod]
				mm.instance_count = blocos[b].size()
				for k in blocos[b].size():
					mm.set_instance_transform(k, Transform3D(Basis.IDENTITY, lotes[blocos[b][k]].pos))
				var mmi := MultiMeshInstance3D.new()
				mmi.multimesh = mm
				if lod == 0 and sombra_leve:
					mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				no.add_child(mmi)
			tri[lod] += FUSAO.triangulos(f["lod%d" % lod]) * idx.size()
			for i in idx:
				for e in f.extras:
					var c: Node3D = e[0].duplicate()
					c.transform = Transform3D(e[1].basis, e[1].origin + lotes[i].pos)
					no.add_child(c)
			add_child(no)
			par[lod] = no
		if sombra_leve:
			# de perto, a sombra vem da malha leve (só sombra), nos mesmos blocos do LOD 0
			var blocos := _blocos(idx)
			for b in blocos:
				var mm := MultiMesh.new()
				mm.transform_format = MultiMesh.TRANSFORM_3D
				mm.mesh = f.lod1
				mm.instance_count = blocos[b].size()
				for k in blocos[b].size():
					mm.set_instance_transform(k, Transform3D(Basis.IDENTITY, lotes[blocos[b][k]].pos))
				var so := MultiMeshInstance3D.new()
				so.multimesh = mm
				so.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
				par[0].add_child(so)
		conjuntos.append(par)
	info_montagem = {"construcoes_diferentes": grupos.size(), "pecas_soltas": pecas, "composicao": contagem,
		"triangulos_lod0": tri[0], "triangulos_lod1": tri[1]}
	# selos de nível em 2D (uma camada só, desenhada em lote)
	var camada := CanvasLayer.new()
	add_child(camada)
	selos = Node2D.new()
	selos.set_script(_SELOS)
	selos.set("cidade", self)
	camada.add_child(selos)
	selos.visible = args.get("selos", "1") != "0"
	if args.has("detalhar"):
		for chave in grupos:
			var f: Dictionary = _cache[chave]
			print("PESO %s n=%d lod0=%d lod1=%d sup=%s" % [chave, grupos[chave].size(), FUSAO.triangulos(f.lod0), FUSAO.triangulos(f.lod1), f.grupos0])

# ---------------------------------------------------------------- cena e câmera

func _cena() -> void:
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
	env.tonemap_white = 4.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.2
	env.adjustment_contrast = 1.08
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sol = DirectionalLight3D.new()
	sol.light_color = Color("fff0d8")
	sol.rotation_degrees = Vector3(-50, -18, 0)
	sol.shadow_enabled = args.get("sombra", "1") != "0"
	sol.shadow_blur = 1.5
	sol.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	add_child(sol)
	var preenche := DirectionalLight3D.new()
	preenche.light_color = Color("bcd7ff")
	preenche.light_energy = 0.3
	preenche.rotation_degrees = Vector3(-25, 120, 0)
	add_child(preenche)
	# chão em volta da base
	var chao := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(600, 600)
	chao.mesh = pm
	chao.position.y = -0.46
	chao.material_override = kit.p("grama", 0.95)
	add_child(chao)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.rotation_degrees = Vector3(-33, 45, 0)
	cam.far = DISTANCIA * 3.0
	add_child(cam)
	cam.make_current()

## Caixa da base no plano da câmera: [min, max] em (direita, cima).
func caixa_base() -> Rect2:
	var r := Rect2()
	var primeiro := true
	for c in [0, COLUNAS - 1]:
		for l in [0, LINHAS - 1]:
			for y in [0.0, 9.0]:
				var p := _pos_lote(l * COLUNAS + c) + Vector3(0, y, 0)
				for d in [Vector3(-3, 0, -3), Vector3(3, 0, 3), Vector3(-3, 0, 3), Vector3(3, 0, -3)]:
					var q: Vector3 = p + d
					var v := Vector2(q.dot(cam.basis.x), q.dot(cam.basis.y))
					if primeiro:
						r = Rect2(v, Vector2.ZERO); primeiro = false
					else:
						r = r.expand(v)
	return r

func limites_zoom() -> Vector2:
	var b := caixa_base()
	return Vector2(LARGURA_LOTE_TELA / LOTE_MAX_LARGURA, b.size.x / BASE_MIN_LARGURA)

func _aplicar_camera() -> void:
	var lz := limites_zoom()
	largura = clampf(largura, lz.x, lz.y)
	var vp := get_viewport().get_visible_rect().size
	var altura := largura * vp.y / vp.x
	# arrastar: até a caixa da base mais meia tela de folga
	var b := caixa_base()
	pan.x = clampf(pan.x, b.position.x, b.end.x)
	pan.y = clampf(pan.y, b.position.y, b.end.y)
	cam.size = largura
	cam.position = cam.basis.x * pan.x + cam.basis.y * pan.y + cam.basis.z * DISTANCIA
	if sol.shadow_enabled:
		sol.directional_shadow_max_distance = DISTANCIA + maxf(largura, altura) * 1.2
	var lod := 1 if largura > LOD_TAMANHO else 0
	if lod != _lod_atual:
		_lod_atual = lod
		for par in conjuntos:
			par[0].visible = lod == 0
			par[1].visible = lod == 1
	if selos:
		selos.queue_redraw()

func _unhandled_input(ev: InputEvent) -> void:
	var vp := get_viewport().get_visible_rect().size
	var upp := largura / vp.x   # unidades por pixel
	if ev is InputEventScreenTouch:
		if ev.pressed:
			_toques[ev.index] = ev.position
		else:
			_toques.erase(ev.index)
	elif ev is InputEventScreenDrag:
		if _toques.size() >= 2 and _toques.has(ev.index):
			var ids := _toques.keys()
			var outro: Vector2 = _toques[ids[0] if ids[0] != ev.index else ids[1]]
			var antes: float = (_toques[ev.index] as Vector2).distance_to(outro)
			var depois: float = ev.position.distance_to(outro)
			if depois > 1.0:
				largura *= antes / depois
			pan += Vector2(-ev.relative.x, ev.relative.y) * upp * 0.5
		else:
			pan += Vector2(-ev.relative.x, ev.relative.y) * upp
		_toques[ev.index] = ev.position
		_aplicar_camera()
	elif ev is InputEventMouseMotion and (ev.button_mask & MOUSE_BUTTON_MASK_LEFT):
		pan += Vector2(-ev.relative.x, ev.relative.y) * upp
		_aplicar_camera()
	elif ev is InputEventMouseButton and ev.pressed:
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			largura /= 1.1
			_aplicar_camera()
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			largura *= 1.1
			_aplicar_camera()
	elif ev is InputEventMagnifyGesture:
		largura /= ev.factor
		_aplicar_camera()
	elif ev is InputEventPanGesture:
		pan += Vector2(ev.delta.x, -ev.delta.y) * upp * 8.0
		_aplicar_camera()

# ---------------------------------------------------------------- medição

func _medir(sair := true) -> void:
	_medindo = true
	if hud:
		hud.visible = false
	var saida: String = args.get("medir", "user://medicao")
	if saida == "":
		saida = "user://medicao"
	DirAccess.make_dir_recursive_absolute(saida)
	var quadros := int(args.get("quadros", "120"))
	var vp := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var lz := limites_zoom()
	var res := {"cenario": args.get("cenario", "cheia"), "fusao": not args.has("sem_fusao"),
		"sombra": sol.shadow_enabled, "janela": [get_window().size.x, get_window().size.y],
		"montagem_ms": tempo_montagem_ms, "montagem": info_montagem,
		"zoom_min": lz.x, "zoom_max": lz.y, "lod_tamanho": LOD_TAMANHO,
		"placa_video": RenderingServer.get_video_adapter_name(), "zooms": {}}
	for z in [["perto", lz.x, Vector2(0, 0)], ["padrao", 20.0, Vector2(0, 0)], ["medio", 30.0, Vector2(0, 0)], ["longe", lz.y, Vector2(0, 0)]]:
		largura = z[1]
		pan = z[2]
		_aplicar_camera()
		for i in 10:
			await RenderingServer.frame_post_draw
		var soma := 0.0
		var pior := 0.0
		var cpu := 0.0
		var gpu := 0.0
		var t := Time.get_ticks_usec()
		for i in quadros:
			await RenderingServer.frame_post_draw
			var agora := Time.get_ticks_usec()
			var dt := (agora - t) / 1000.0
			t = agora
			soma += dt
			pior = maxf(pior, dt)
			cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp)
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
		var m := {
			"largura_visivel": largura, "lod": _lod_atual,
			"chamadas_desenho": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			"triangulos": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
			"objetos": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
			"quadro_ms_medio": soma / quadros, "quadro_ms_pior": pior,
			"render_cpu_ms": cpu / quadros, "render_gpu_ms": gpu / quadros,
		}
		res.zooms[z[0]] = m
		print("MEDIDA %s %s" % [z[0], JSON.stringify(m)])
		var suf := ("" if res.fusao else "_sem_fusao") + ("" if res.sombra else "_sem_sombra")
		get_viewport().get_texture().get_image().save_png("%s/cidade_%s%s_%s.png" % [saida, res.cenario, suf, z[0]])
	var nome := "%s/contagens_%s%s%s.json" % [saida, res.cenario, "" if res.fusao else "_sem_fusao", "" if res.sombra else "_sem_sombra"]
	var f := FileAccess.open(nome, FileAccess.WRITE)
	f.store_string(JSON.stringify(res, "  "))
	f.close()
	print("SALVO ", nome)
	_medindo = false
	if sair:
		get_tree().quit()
		return
	hud.visible = true
	var linhas := ["MEDIÇÃO (%s, sombra %s) salva em %s" % [res.cenario, "sim" if res.sombra else "não", ProjectSettings.globalize_path(nome)]]
	for z in res.zooms:
		var m: Dictionary = res.zooms[z]
		linhas.append("%s: %.1f ms (%.0f FPS), pior %.1f ms, %d chamadas, %d mil triângulos" % [z, m.quadro_ms_medio, 1000.0 / maxf(m.quadro_ms_medio, 0.01), m.quadro_ms_pior, m.chamadas_desenho, m.triangulos / 1000])
	_resultado = "\n".join(linhas)
	largura = 20.0
	pan = Vector2.ZERO
	_aplicar_camera()

# ---------------------------------------------------------------- painel (medir no aparelho)

var _resultado := ""

func _painel() -> void:
	hud = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	var fundo := PanelContainer.new()
	fundo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud.add_child(fundo)
	hud_texto = Label.new()
	hud_texto.add_theme_font_size_override("font_size", 14)
	hud_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fundo.add_child(hud_texto)
	var barra := HBoxContainer.new()
	barra.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	barra.offset_top = -64
	barra.alignment = BoxContainer.ALIGNMENT_CENTER
	hud.add_child(barra)
	var cenarios := ["cheia", "n30", "misto"]
	var botoes := [
		["Cenário: " + args.get("cenario", "cheia"), func():
			var i := cenarios.find(args.get("cenario", "cheia"))
			_recarregar({"cenario": cenarios[(i + 1) % cenarios.size()]})],
		["Sombra: " + ("sim" if sol.shadow_enabled else "não"), func():
			_recarregar({"sombra": "1" if args.get("sombra", "1") == "0" else "0"})],
		["Medir", func(): _medir(false)],
	]
	for b in botoes:
		var bt := Button.new()
		bt.text = b[0]
		bt.custom_minimum_size = Vector2(150, 56)   # alvo de toque >= 48 dp
		bt.pressed.connect(b[1])
		barra.add_child(bt)

func _recarregar(mudar: Dictionary) -> void:
	var n := args.duplicate()
	n.merge(mudar, true)
	n.erase("medir")
	proximos = n
	get_tree().reload_current_scene()

func _process(dt: float) -> void:
	if hud_texto == null or _medindo:
		return
	_hud_tempo += dt
	if _hud_tempo < 0.5:
		return
	_hud_tempo = 0.0
	var fps := Engine.get_frames_per_second()
	hud_texto.text = "%d FPS (%.1f ms) · %d chamadas · %d mil triângulos · LOD %d · largura %.0f\n%s" % [
		fps, 1000.0 / maxf(fps, 1.0),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME) / 1000,
		_lod_atual, largura, _resultado]

# ---------------------------------------------------------------- selos

const _SELOS := preload("res://selos_cidade.gd")
