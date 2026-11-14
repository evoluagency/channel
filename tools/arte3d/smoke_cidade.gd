extends SceneTree
## Smoke da cidade 3D (sessão 1.6). Precisa de renderizador (as malhas do kit vivem na GPU):
##   xvfb-run -a godot --path tools/arte3d --rendering-driver opengl3 -s smoke_cidade.gd -- [--saida=PASTA]
## 1. Monta e funde as 15 construções nas 6 faixas; confere avisos, superfícies e LOD.
## 2. Abre a cidade cheia, confere os 80 lotes, o LOD por zoom e os limites da câmera.
## Grava PASTA/contagens_construcoes.json e sai com 0 (passou) ou 1 (falhou).

const KIT := preload("res://kit.gd")
const FUSAO := preload("res://fusao.gd")
const CIDADE := preload("res://cidade.gd")

var falhas := []

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		falhas.append(msg)
		print("FALHOU ", msg)

func _initialize() -> void:
	_rodar.call_deferred()

func _rodar() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var par := a.trim_prefix("--").split("=", true, 1)
		args[par[0]] = par[1] if par.size() > 1 else ""
	var saida: String = args.get("saida", "")
	# ---- 1. construções
	var kit = KIT.new("azul")
	kit.modo_cidade = true
	var linhas := {}
	for id in CIDADE.RECEITAS:
		var nome: String = CIDADE.RECEITAS[id]
		var s = load("res://construcoes/%s.gd" % nome)
		_ok(s != null and s.can_instantiate(), "receita %s carrega" % nome)
		if s == null:
			continue
		var r = s.new()
		for faixa in range(1, 7):
			var a := Node3D.new()
			var orig := [0, 0]
			kit.modo_cidade = false
			var b0 := Node3D.new()
			r.construir(kit, b0, faixa)
			_contar(b0, orig)
			b0.free()
			kit.modo_cidade = true
			var topo: float = r.construir(kit, a, faixa)
			var b := Node3D.new()
			kit.longe = true
			r.construir(kit, b, faixa)
			kit.longe = false
			var f: Dictionary = FUSAO.fundir(a, b)
			var chave := "%s|%d" % [id, faixa]
			var t0 := FUSAO.triangulos(f.lod0)
			var t1 := FUSAO.triangulos(f.lod1)
			linhas[chave] = {"receita": nome, "faixa": faixa, "pecas": orig[0], "triangulos_folha": orig[1],
				"superficies_lod0": f.lod0.get_surface_count(), "superficies_lod1": f.lod1.get_surface_count(),
				"grupos_lod0": f.grupos0, "triangulos_lod0": t0, "triangulos_lod1": t1,
				"extras": f.extras.size(), "topo": topo, "avisos": f.avisos}
			_ok(f.avisos.is_empty(), "%s sem avisos: %s" % [chave, f.avisos])
			_ok(f.lod0.get_surface_count() >= 1 and f.lod0.get_surface_count() <= 5, "%s superfícies 1..5" % chave)
			_ok(t1 <= t0, "%s LOD1 não passa do LOD0" % chave)
			_ok(t0 <= orig[1], "%s modo cidade não passa da folha" % chave)
			_ok(topo > 0.5 and topo < 15.0, "%s topo plausível (%.1f)" % [chave, topo])
			a.free()
			b.free()
	_ok(linhas.size() == 90, "90 combinações (15 x 6): %d" % linhas.size())
	# ---- 2. cidade
	var c = CIDADE.new()
	c.args = {"cenario": "cheia", "quadros": "3"}
	root.add_child(c)
	for i in 5:
		await process_frame
	_ok(c.lotes.size() == 80, "80 lotes: %d" % c.lotes.size())
	var lz: Vector2 = c.limites_zoom()
	c.largura = 0.1
	c._aplicar_camera()
	_ok(is_equal_approx(c.largura, lz.x), "zoom de aproximar para no limite")
	_ok(c._lod_atual == 0, "de perto usa LOD 0")
	c.largura = 1.0e6
	c._aplicar_camera()
	_ok(is_equal_approx(c.largura, lz.y), "zoom de afastar para no limite")
	_ok(c._lod_atual == 1, "de longe usa LOD 1")
	var base: Rect2 = c.caixa_base()
	_ok(base.size.x / lz.y >= 0.6 - 0.001, "de longe a base ocupa ao menos 60% da largura")
	c.pan = Vector2(1.0e5, -1.0e5)
	c._aplicar_camera()
	_ok(c.pan.x <= base.end.x + 0.001 and c.pan.y >= base.position.y - 0.001, "arrastar para na caixa da base")
	# arrastar com um dedo e pinça com dois (eventos de toque)
	c.largura = 20.0
	c.pan = Vector2.ZERO
	c._aplicar_camera()
	var t := InputEventScreenTouch.new()
	t.index = 0; t.pressed = true; t.position = Vector2(200, 500)
	c._unhandled_input(t)
	var d := InputEventScreenDrag.new()
	d.index = 0; d.position = Vector2(150, 500); d.relative = Vector2(-50, 0)
	c._unhandled_input(d)
	_ok(c.pan.x > 0.0, "arrastar move a câmera")
	var t2 := InputEventScreenTouch.new()
	t2.index = 1; t2.pressed = true; t2.position = Vector2(350, 500)
	c._unhandled_input(t2)
	var antes: float = c.largura
	var d2 := InputEventScreenDrag.new()
	d2.index = 1; d2.position = Vector2(500, 500); d2.relative = Vector2(150, 0)
	c._unhandled_input(d2)
	_ok(c.largura < antes, "abrir a pinça aproxima")
	await process_frame
	await RenderingServer.frame_post_draw
	var chamadas := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	_ok(chamadas > 0 and chamadas <= 200, "chamadas de desenho no quadro: %d" % chamadas)
	# botão "Medir" do painel (o que o dono usa no aparelho): mede sem sair e mostra na tela
	_ok(c.hud != null and c.hud.visible, "painel de medição aparece")
	await c._medir(false)
	_ok(c._resultado.contains("perto") and c._resultado.contains("longe") and c.hud.visible, "Medir mostra o resultado na tela")
	if saida != "":
		DirAccess.make_dir_recursive_absolute(saida)
		var f := FileAccess.open(saida + "/contagens_construcoes.json", FileAccess.WRITE)
		f.store_string(JSON.stringify(linhas, "  ", true))
		f.close()
	print("SMOKE_CIDADE %s (%d falhas)" % ["PASSOU" if falhas.is_empty() else "FALHOU", falhas.size()])
	quit(0 if falhas.is_empty() else 1)

func _contar(no: Node, n: Array) -> void:
	if no is MeshInstance3D and no.mesh:
		n[0] += 1
		n[1] += FUSAO.triangulos(no.mesh)
	for ch in no.get_children():
		_contar(ch, n)
