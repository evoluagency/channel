extends SceneTree
## Smoke dos menus do Valdora PvP: abre as 10 telas, confere que montam sem erro, que todo
## botão tem ao menos 48 px de altura e que nada fica fora da tela de 1280 x 720.
## Com renderizador e --capturas=PASTA, salva um PNG por tela.
##   godot --headless --path game -s tests/pvp_menu_smoke.gd
##   xvfb-run -a godot --path game --rendering-driver opengl3 -s tests/pvp_menu_smoke.gd -- --capturas=PASTA

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
	var menu = load("res://scenes/pvp/MenuPvP.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	var pasta: String = args.get("capturas", "")
	if pasta != "":
		DirAccess.make_dir_recursive_absolute(pasta)
	for t in menu.TELAS:
		menu.abrir(t)
		for i in 4:
			await process_frame
		var botoes := 0
		for b in _todos(menu, []):
			if b is Button and b.is_visible_in_tree():
				botoes += 1
				_ok(b.size.y >= 47.5, "%s: botão '%s' com %.0f px" % [t, b.text, b.size.y])
				var r: Rect2 = b.get_global_rect()
				_ok(r.position.x >= -1 and r.end.x <= 1281 and r.position.y >= -1 and r.end.y <= 721,
					"%s: botão '%s' fora da tela %s" % [t, b.text, r])
		_ok(botoes > 0, "%s tem botões" % t)
		print("TELA %s ok (%d botões)" % [t, botoes])
		if pasta != "":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/pvp_%s.png" % [pasta, t])
	print("PVP_MENU %s (%d falhas)" % ["PASSOU" if falhas.is_empty() else "FALHOU", falhas.size()])
	quit(0 if falhas.is_empty() else 1)

func _todos(n: Node, acc: Array) -> Array:
	acc.append(n)
	for c in n.get_children():
		_todos(c, acc)
	return acc
