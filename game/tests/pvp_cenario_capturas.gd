extends SceneTree
## Capturas do cenário das arenas (não é teste): vista aérea e 3 vistas em primeira pessoa.
##   xvfb-run -a godot --path game --rendering-driver opengl3 -s tests/pvp_cenario_capturas.gd -- --saida=PASTA [--mapa=id]

const ARENA := preload("res://scripts/pvp/pvp_arena.gd")

func _livre_perto(cena, x: int, y: int) -> Vector3:
	for r in 6:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if cena.letra(x + dx, y + dy) in [".", "1", "2", "3"]:
					return cena.celula_mundo(x + dx, y + dy)
	return cena.celula_mundo(x, y)

func _initialize() -> void:
	_rodar.call_deferred()

func _rodar() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var p := a.trim_prefix("--").split("=", true, 1)
		args[p[0]] = p[1] if p.size() > 1 else ""
	root.size = Vector2i(1280, 720)
	var saida: String = args.get("saida", "user://capturas")
	DirAccess.make_dir_recursive_absolute(saida)
	var ids := []
	for m in ARENA.lista():
		if args.get("mapa", "") in ["", m.id]:
			ids.append(m.id)
	for id in ids:
		ARENA.mapa_escolhido = id
		var cena = load("res://scenes/pvp/ArenaPvP.tscn").instantiate()
		root.add_child(cena)
		for i in 4:
			await process_frame
		cena.hud.visible = false
		var j = cena.jogador
		var vistas := [
			["pe_base", cena.centro_de("T") + Vector3(0, 0.05, 0), cena.centro_de("D")],
			["pe_A", cena.centro_de("A") + Vector3(0, 0.05, 6), cena.centro_de("A") + Vector3(0, 0, -20)],
			["pe_meio", _livre_perto(cena, 12, 17), _livre_perto(cena, 12, 6)],
		]
		for v in vistas:
			j.global_position = v[1]
			j.olhar_para(v[2])
			j.camera.make_current()
			for i in 8:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/%s_%s.png" % [saida, id, v[0]])
		# vista aérea
		var cam := Camera3D.new()
		cena.add_child(cam)
		cam.fov = 50
		cam.far = 600
		cam.position = Vector3(-55, 70, 85)
		cam.look_at(Vector3(0, 0, 5))
		cam.make_current()
		for i in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/%s_aerea.png" % [saida, id])
		print("CAPTURAS %s ok (%d malhas de cenário, %d triângulos)" % [id, cena.chamadas_cenario, cena.get_meta("cenario_triangulos", 0)])
		cena.queue_free()
		await process_frame
	quit()
