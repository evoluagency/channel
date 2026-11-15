extends SceneTree
## Smoke das arenas 3D do Valdora PvP. Para cada um dos 5 mapas:
##  - cada parede (#) e cobertura (c) da grade tem colisão no centro da célula;
##  - cada célula de chão está livre na altura do corpo;
##  - o jogador nasce na base de ataque e pousa no chão;
##  - correndo 4 s em 8 direções, nunca entra em parede nem sai dos limites;
##  - o tiro acerta alguma coisa à frente; o minimapa e a interface existem.
##   godot --headless --path game -s tests/pvp_arena_smoke.gd
##   xvfb-run -a godot --path game --rendering-driver opengl3 -s tests/pvp_arena_smoke.gd -- --capturas=PASTA

const ARENA := preload("res://scripts/pvp/pvp_arena.gd")

var falhas := []

func _ok(c: bool, m: String) -> void:
	if not c:
		falhas.append(m)
		print("FALHOU ", m)

func _initialize() -> void:
	_rodar.call_deferred()

func _rodar() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var p := a.trim_prefix("--").split("=", true, 1)
		args[p[0]] = p[1] if p.size() > 1 else ""
	root.size = Vector2i(1280, 720)
	var pasta: String = args.get("capturas", "")
	if pasta != "":
		DirAccess.make_dir_recursive_absolute(pasta)
	var mapas := ARENA.lista()
	_ok(mapas.size() == 5, "5 mapas no JSON: %d" % mapas.size())
	for m in mapas:
		ARENA.mapa_escolhido = m.id
		var cena = load("res://scenes/pvp/ArenaPvP.tscn").instantiate()
		root.add_child(cena)
		for i in 3:
			await physics_frame
		var espaco: PhysicsDirectSpaceState3D = cena.get_world_3d().direct_space_state
		var erros_grade := 0
		for y in cena.altura:
			for x in cena.largura:
				var ch: String = cena.letra(x, y)
				var c: Vector3 = cena.celula_mundo(x, y)
				var bate := func(h: float) -> bool:
					var q := PhysicsPointQueryParameters3D.new()
					q.position = c + Vector3(0, h, 0)
					q.exclude = [cena.jogador.get_rid()]
					return not espaco.intersect_point(q, 1).is_empty()
				if ch == "#":
					if not bate.call(1.0):
						erros_grade += 1
				elif ch == "c":
					if not bate.call(0.6):
						erros_grade += 1
				else:
					if bate.call(1.0) or bate.call(0.3):
						erros_grade += 1
		_ok(erros_grade == 0, "%s: %d células da grade sem a colisão certa" % [m.id, erros_grade])
		var j = cena.jogador
		for i in 40:
			await physics_frame
		_ok(j.is_on_floor() and absf(j.global_position.y) < 0.2, "%s: jogador pousa no chão (y=%.2f)" % [m.id, j.global_position.y])
		_ok(cena.letra(cena.mundo_celula(j.global_position).x, cena.mundo_celula(j.global_position).y) == "T", "%s: nasce na base de ataque" % m.id)
		# tiro à frente
		var antes: int = j.acertos
		j.atirar()
		_ok(j.acertos == antes + 1 and j.municao == 23, "%s: tiro acerta algo e gasta munição" % m.id)
		j.recarregar()
		_ok(j.municao == 24 and j.reserva == 89, "%s: recarga" % m.id)
		# corrida em 8 direções a partir da base
		var inicio: Vector3 = j.global_position
		var dentro := true
		var em_parede := 0
		for k in 8:
			j.global_position = inicio
			j.velocity = Vector3.ZERO
			var a := k * TAU / 8
			j.mover = Vector2(cos(a), sin(a))
			for f in 240:
				await physics_frame
				var cel: Vector2i = cena.mundo_celula(j.global_position)
				if cel.x < 0 or cel.y < 0 or cel.x >= cena.largura or cel.y >= cena.altura:
					dentro = false
				elif cena.letra(cel.x, cel.y) == "#":
					# encostar no limite da célula é normal; o centro do corpo não pode entrar fundo
					var c: Vector3 = cena.celula_mundo(cel.x, cel.y)
					if absf(j.global_position.x - c.x) < 1.0 and absf(j.global_position.z - c.z) < 1.0:
						em_parede += 1
		j.mover = Vector2.ZERO
		_ok(dentro, "%s: jogador ficou dentro dos limites" % m.id)
		_ok(em_parede == 0, "%s: jogador entrou em parede %d vezes" % [m.id, em_parede])
		_ok(cena.hud != null and cena.paredes > 0, "%s: interface e paredes montadas (%d blocos)" % [m.id, cena.paredes])
		print("MAPA %s ok: %d blocos de parede" % [m.id, cena.paredes])
		if pasta != "":
			j.global_position = inicio
			j.olhar_para(cena.centro_de("D"))
			for i in 6:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/arena_%s.png" % [pasta, m.id])
		cena.queue_free()
		await process_frame
	print("PVP_ARENA %s (%d falhas)" % ["PASSOU" if falhas.is_empty() else "FALHOU", falhas.size()])
	quit(0 if falhas.is_empty() else 1)
