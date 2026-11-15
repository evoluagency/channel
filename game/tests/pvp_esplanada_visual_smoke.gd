extends SceneTree
## Homologação local da Esplanada. Sem deploy, sem APK e sem GitHub Actions.
## Godot: godot --headless --path game --script res://tests/pvp_esplanada_visual_smoke.gd
## Capturas: xvfb-run -a godot --path game --rendering-driver opengl3 \
##   --script res://tests/pvp_esplanada_visual_smoke.gd -- --capturas=/CAMINHO
##
## Compara a contagem de colisores entre modo físico original e modo visual
## e verifica limites amplos de complexidade no cenário-piloto.

const ARENA := preload("res://scripts/pvp/pvp_arena.gd")
var falhas: Array[String] = []

func _ok(condicao: bool, descricao: String) -> void:
	if not condicao:
		falhas.append(descricao)
		print("FALHOU: ", descricao)

func _contar_colisores(n: Node) -> int:
	var total := 1 if n is CollisionShape3D or n is CollisionPolygon3D else 0
	for child in n.get_children():
		total += _contar_colisores(child)
	return total

func _initialize() -> void:
	_executar.call_deferred()

func _executar() -> void:
	root.size = Vector2i(1280, 720)
	var saida := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capturas="):
			saida = arg.trim_prefix("--capturas=")
	if not saida.is_empty():
		DirAccess.make_dir_recursive_absolute(saida)

	_ok(ARENA.lista().size() == 5, "Os cinco mapas originais devem existir")
	ARENA.mapa_escolhido = "esplanada"
	ARENA.visual = false
	var base = load("res://scenes/pvp/ArenaPvP.tscn").instantiate()
	root.add_child(base)
	for i in 3:
		await process_frame
	var colisores_base := _contar_colisores(base)
	_ok(colisores_base > 0, "A arena original precisa ter colisores")
	base.queue_free()
	for i in 3:
		await process_frame

	ARENA.visual = true
	var piloto = load("res://scenes/pvp/ArenaPvP.tscn").instantiate()
	root.add_child(piloto)
	for i in 5:
		await process_frame
	var colisores_piloto := _contar_colisores(piloto)
	var elementos := int(piloto.get_meta("esplanada_elementos_visuais", 0))
	var tris := int(piloto.get_meta("esplanada_triangulos_cenario", 0))
	var materiais := int(piloto.chamadas_cenario)
	_ok(colisores_piloto == colisores_base,
		"Sem alteração de colisão: original=%d piloto=%d" % [colisores_base, colisores_piloto])
	_ok(elementos > 100, "A Esplanada deve carregar a nova camada visual")
	_ok(tris > 0 and tris <= 250000, "Triângulos de cenário dentro de 250 mil")
	_ok(materiais > 0 and materiais <= 80, "Máximo de 80 superfícies de material")
	_ok(piloto.hud != null and piloto.jogador != null, "HUD e jogador mantidos")
	_ok(piloto.mapa.get("id", "") == "esplanada", "Mapa-piloto correto")
	print("ESPLANADA_METRICAS colisores=%d elementos=%d triangulos=%d materiais=%d" % [
		colisores_piloto, elementos, tris, materiais
	])

	if not saida.is_empty():
		piloto.hud.visible = false
		var j = piloto.jogador
		for nome in ["spawn", "objetivo_a", "objetivo_b"]:
			j.global_position = piloto.centro_de("T") if nome == "spawn" else piloto.centro_de("A" if nome == "objetivo_a" else "B")
			j.olhar_para(piloto.centro_de("D"))
			j.camera.make_current()
			for i in 7:
				await process_frame
			await RenderingServer.frame_post_draw
			var imagem = root.get_texture().get_image()
			_ok(imagem.save_png("%s/esplanada_%s.png" % [saida, nome]) == OK,
				"Captura visual: " + nome)
	print("ESPLANADA_VISUAL_SMOKE %s (%d falhas)" % [
		"PASSOU" if falhas.is_empty() else "FALHOU", falhas.size()
	])
	quit(0 if falhas.is_empty() else 1)
