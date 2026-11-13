extends RefCounted
## Via: liga os prédios. É um trecho de lote atravessado pela rua (eixo X) e, a partir
## da faixa 3, um cruzamento. A aliança aparece nas placas, na ciclovia e no neon. Frente = +Z.

const LOTE := 5.4

func construir(k, pai: Node3D, faixa: int) -> float:
	match faixa:
		1: return _f1(k, pai)
		2: return _f2(k, pai)
		3: return _f3(k, pai)
		4: return _f4(k, pai)
		5: return _f5(k, pai)
		_: return _f6(k, pai)

func _placa(k, pai: Node3D, pos: Vector3, cor: Color) -> void:
	k.cilindro(pai, pos, 0.03, 0.9, k.p("aco", 0.4, 0.5), 6)
	var p = k.cilindro(pai, Vector3.ZERO, 0.18, 0.03, k.mat(cor, 0.5), 16)
	p.rotation_degrees.x = 90
	p.position = pos + Vector3(0, 0.95, 0.03)
	k.cilindro(pai, Vector3.ZERO, 0.13, 0.035, k.p("branco", 0.5), 16).position = pos + Vector3(0, 0.95, 0.03)

func _faixas(k, pai: Node3D, y: float, larg: float, mat, cruz := false) -> void:
	for i in 7:
		var x := -2.4 + i * 0.8
		if cruz and absf(x) < larg * 0.6:
			continue
		k.caixa(pai, Vector3(x, y, 0), Vector3(0.45, 0.012, 0.08), mat, 0.0)
	if cruz:
		for i in 7:
			var z := -2.4 + i * 0.8
			if absf(z) < larg * 0.6:
				continue
			k.caixa(pai, Vector3(0, y, z), Vector3(0.08, 0.012, 0.45), mat, 0.0)

func _faixa_pedestre(k, pai: Node3D, centro: Vector3, ao_longo_x: bool, larg: float) -> void:
	for i in 6:
		var o := (i - 2.5) * (larg / 6.0)
		var pos := centro + (Vector3(o, 0, 0) if not ao_longo_x else Vector3(0, 0, o))
		var t := Vector3(0.14, 0.012, 0.6) if not ao_longo_x else Vector3(0.6, 0.012, 0.14)
		k.caixa(pai, pos, t, k.p("branco", 0.6), 0.0)

func _calcadas(k, pai: Node3D, larg: float, cruz: bool, cor: Color, meio_fio := Color("d8d2c6")) -> void:
	var h := LOTE * 0.5
	var q := (h - larg * 0.5)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var pos := Vector3(sx * (larg * 0.5 + q * 0.5), 0.05, sz * (larg * 0.5 + q * 0.5))
			if not cruz:
				pos.x = sx * h * 0.5
			var t := Vector3(q if cruz else h, 0.12, q)
			k.caixa(pai, pos, t, k.mat(cor, 0.85), 0.03)

func _bicicleta(k, pai: Node3D, pos: Vector3, rot: float, cor: Color) -> void:
	var g = k.grupo(pai, pos, rot)
	for x in [-0.18, 0.18]:
		var r = k.toro(g, Vector3(x, 0.14, 0), 0.12, 0.015, k.p("aco_escuro"))
		r.rotation_degrees.x = 90
	k.caixa(g, Vector3(0, 0.2, 0), Vector3(0.36, 0.03, 0.03), k.mat(cor, 0.5), 0.0)
	k.pessoa(g, Vector3(0, 0.18, 0), cor, 0.7)

# ---- faixa 1: terra batida
func _f1(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("grama", 0.9))
	pai = k.grupo(pai, Vector3(0, 0.05, 0))
	k.caixa(pai, Vector3(0, 0.06, 0), Vector3(LOTE - 0.1, 0.03, 1.5), k.p("terra", 0.95), 0.0)
	for z in [-0.35, 0.35]:
		k.caixa(pai, Vector3(0, 0.09, z), Vector3(LOTE - 0.2, 0.01, 0.18), k.mat(Color("a8804f"), 0.95), 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	for i in 10:
		k.esfera(pai, Vector3(rng.randf_range(-2.5, 2.5), 0.1, rng.randf_range(-0.9, 0.9) + (1.2 if i % 2 else -1.2)), rng.randf_range(0.06, 0.12), k.mat(Color("9a958e"), 0.9), 0.6)
	var pl = k.grupo(pai, Vector3(-1.6, 0.05, 1.2), 0)
	k.caixa(pl, Vector3.ZERO, Vector3(0.08, 1.0, 0.08), k.p("madeira"), 0.01)
	k.caixa(pl, Vector3(0.25, 0.75, 0), Vector3(0.6, 0.22, 0.04), k.p("madeira"), 0.01)
	k.caixa(pl, Vector3(0.25, 0.8, 0.025), Vector3(0.45, 0.06, 0.01), k.alianca(), 0.0)
	k.arvore(pai, Vector3(1.8, 0.05, -1.8))
	k.arvore(pai, Vector3(-2.0, 0.05, -1.6), 0.8)
	k.veiculo(pai, Vector3(0.6, 0.09, 0.3), 0, Color("6e8d52"))
	return 1.2

# ---- faixa 2: asfalto simples
func _f2(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("grama", 0.9))
	pai = k.grupo(pai, Vector3(0, 0.05, 0))
	k.caixa(pai, Vector3(0, 0.06, 0), Vector3(LOTE - 0.1, 0.03, 1.6), k.p("asfalto", 0.85), 0.0)
	for z in [-0.85, 0.85]:
		k.caixa(pai, Vector3(0, 0.05, z), Vector3(LOTE - 0.1, 0.08, 0.1), k.p("concreto"), 0.01)
	_placa(k, pai, Vector3(-1.8, 0.05, 1.2), Color("ff4a3d"))
	k.arvore(pai, Vector3(1.6, 0.05, 1.8))
	k.arvore(pai, Vector3(-1.2, 0.05, -1.8))
	k.veiculo(pai, Vector3(-0.6, 0.09, -0.4), 0, Color("ffffff"))
	k.veiculo(pai, Vector3(1.2, 0.09, 0.4), 180, Color("e8833a"))
	return 1.2

# ---- faixa 3: asfalto com faixas e postes (cruzamento)
func _f3(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("concreto", 0.85))
	pai = k.grupo(pai, Vector3(0, 0.05, 0))
	var larg := 1.8
	k.caixa(pai, Vector3(0, 0.06, 0), Vector3(LOTE - 0.1, 0.03, larg), k.p("asfalto", 0.85), 0.0)
	k.caixa(pai, Vector3(0, 0.061, 0), Vector3(larg, 0.03, LOTE - 0.1), k.p("asfalto", 0.85), 0.0)
	_calcadas(k, pai, larg, true, Color("ddd5c6"))
	_faixas(k, pai, 0.09, larg, k.p("branco", 0.6), true)
	_faixa_pedestre(k, pai, Vector3(0, 0.09, 1.2), false, larg - 0.2)
	_faixa_pedestre(k, pai, Vector3(1.2, 0.09, 0), true, larg - 0.2)
	for q in [Vector3(-1.1, 0.17, -1.1), Vector3(1.1, 0.17, 1.1)]:
		k.poste(pai, q, 1.5)
	var sem := Vector3(1.1, 0.17, -1.1)
	k.cilindro(pai, sem, 0.04, 1.2, k.p("aco_escuro"), 6)
	k.caixa(pai, sem + Vector3(0, 1.1, 0), Vector3(0.14, 0.4, 0.14), k.p("aco_escuro"), 0.02)
	for i in 3:
		k.esfera(pai, sem + Vector3(0, 1.4 - i * 0.12, 0.08), 0.04, k.luz([Color("ff4a3d"), Color("ffb400"), Color("3ddc6a")][i], 1.0 if i == 2 else 0.2))
	_placa(k, pai, Vector3(-1.1, 0.17, 1.1), k.cor_alianca)
	k.veiculo(pai, Vector3(-1.5, 0.09, 0.4), 180, Color("ffffff"))
	k.veiculo(pai, Vector3(0.4, 0.09, -1.6), 90, Color("e8833a"))
	k.pessoa(pai, Vector3(-1.8, 0.17, -1.6), Color("2d3a4f"))
	return 1.6

# ---- faixa 4: via larga com ciclovia
func _f4(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("concreto", 0.85))
	pai = k.grupo(pai, Vector3(0, 0.05, 0))
	var larg := 2.2
	k.caixa(pai, Vector3(0, 0.06, -0.2), Vector3(LOTE - 0.1, 0.03, larg), k.p("asfalto", 0.85), 0.0)
	k.caixa(pai, Vector3(0, 0.07, -0.2), Vector3(LOTE - 0.1, 0.012, 0.1), k.p("amarelo", 0.6), 0.0)
	for z in [-0.75, 0.35]:
		for i in 7:
			k.caixa(pai, Vector3(-2.4 + i * 0.8, 0.075, z), Vector3(0.45, 0.012, 0.07), k.p("branco", 0.6), 0.0)
	# ciclovia na cor da aliança com canteiro de árvores
	k.caixa(pai, Vector3(0, 0.05, 1.3), Vector3(LOTE - 0.1, 0.08, 0.6), k.mat(k.cor_alianca.lerp(Color.WHITE, 0.15), 0.7), 0.0)
	for i in 4:
		k.caixa(pai, Vector3(-2.0 + i * 1.3, 0.135, 1.3), Vector3(0.25, 0.01, 0.25), k.p("branco", 0.6), 0.0)
	k.caixa(pai, Vector3(0, 0.05, 0.98), Vector3(LOTE - 0.1, 0.14, 0.12), k.p("concreto"), 0.02)
	for x in [-2.0, -0.6, 0.8, 2.2]:
		k.caixa(pai, Vector3(x, 0.05, 1.85), Vector3(0.5, 0.15, 0.4), k.p("grama", 0.9), 0.03)
		k.arvore(pai, Vector3(x, 0.2, 1.85), 0.75)
	k.caixa(pai, Vector3(0, 0.05, -1.95), Vector3(LOTE - 0.1, 0.12, 0.9), k.p("calcada"), 0.02)
	for x in [-1.8, 0.6]:
		k.poste(pai, Vector3(x, 0.17, -1.6), 1.6)
	_bicicleta(k, pai, Vector3(-0.8, 0.13, 1.3), 0, Color("e8833a"))
	_bicicleta(k, pai, Vector3(1.2, 0.13, 1.3), 180, Color("2f9e6a"))
	k.veiculo(pai, Vector3(-1.2, 0.09, -0.75), 0, Color("ffffff"))
	k.veiculo(pai, Vector3(1.0, 0.09, 0.35), 180, Color("d94a4a"), "caminhao")
	k.banco(pai, Vector3(-0.2, 0.17, -2.1), 0)
	return 1.6

# ---- faixa 5: via com postes inteligentes
func _f5(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("concreto", 0.85))
	pai = k.grupo(pai, Vector3(0, 0.05, 0))
	var larg := 2.0
	k.caixa(pai, Vector3(0, 0.06, 0), Vector3(LOTE - 0.1, 0.03, larg), k.mat(Color("3a3f4c"), 0.6), 0.0)
	k.caixa(pai, Vector3(0, 0.061, 0), Vector3(larg, 0.03, LOTE - 0.1), k.mat(Color("3a3f4c"), 0.6), 0.0)
	_calcadas(k, pai, larg, true, Color("eef1f5"))
	_faixas(k, pai, 0.09, larg, k.p("branco", 0.6), true)
	_faixa_pedestre(k, pai, Vector3(0, 0.09, 1.3), false, larg - 0.2)
	for q in [Vector3(-1.2, 0.17, -1.2), Vector3(1.2, 0.17, 1.2), Vector3(1.2, 0.17, -1.2), Vector3(-1.2, 0.17, 1.2)]:
		k.poste(pai, q, 1.7, Color("dff8ff"), true)
		k.cilindro(pai, q + Vector3(0, 1.75, 0), 0.06, 0.06, k.p("branco", 0.4), 10)
	# painel de informação e carregador de carro elétrico
	var pn := Vector3(-1.9, 0.17, -1.9)
	k.caixa(pai, pn, Vector3(0.1, 0.9, 0.6), k.mat(Color("20242c"), 0.4), 0.03)
	k.caixa(pai, pn + Vector3(0.06, 0.25, 0), Vector3(0.01, 0.55, 0.5), k.luz(k.cor_alianca, 0.8), 0.0)
	var ev := Vector3(1.9, 0.17, 1.9)
	k.caixa(pai, ev, Vector3(0.25, 0.7, 0.2), k.p("branco", 0.4), 0.04)
	k.caixa(pai, ev + Vector3(0, 0.45, 0.101), Vector3(0.15, 0.12, 0.01), k.luz(Color("3ddc6a"), 1.2), 0.0)
	k.veiculo(pai, Vector3(-1.6, 0.09, 0.45), 180, Color("f4f6fa"))
	k.veiculo(pai, Vector3(-0.45, 0.09, -1.7), 90, k.cor_alianca)
	k.drone(pai, Vector3(0.6, 2.0, 0.8), Color("f4f6fa"))
	k.pessoa(pai, Vector3(1.8, 0.17, -1.6), Color("2d3a4f"))
	return 2.2

# ---- faixa 6: via com faixas luminosas
func _f6(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.mat(k.cor_alianca.darkened(0.55), 0.35, 0.2))
	pai = k.grupo(pai, Vector3(0, 0.05, 0))
	var larg := 2.0
	var piso = k.mat(Color("1c2236"), 0.3, 0.3)
	k.caixa(pai, Vector3(0, 0.06, 0), Vector3(LOTE - 0.1, 0.03, larg), piso, 0.0)
	k.caixa(pai, Vector3(0, 0.061, 0), Vector3(larg, 0.03, LOTE - 0.1), piso, 0.0)
	_calcadas(k, pai, larg, true, Color("f3f0ea"))
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var c := Vector3(sx * (larg * 0.5 + 0.92), 0.17, sz * (larg * 0.5 + 0.92))
			k.caixa(pai, c, Vector3(1.6, 0.03, 1.6), k.ouro(), 0.0)
			k.caixa(pai, c + Vector3(0, 0.03, 0), Vector3(1.5, 0.02, 1.5), k.mat(Color("f3f0ea"), 0.3), 0.0)
			k.cilindro(pai, c, 0.06, 1.8, k.ouro(), 8)
			k.esfera(pai, c + Vector3(0, 1.85, 0), 0.12, k.luz(k.PALETA["neon"], 1.5))
	# faixas luminosas: bordas na cor da aliança e eixo ciano
	for z in [-larg * 0.5 + 0.06, larg * 0.5 - 0.06]:
		k.caixa(pai, Vector3(0, 0.08, z), Vector3(LOTE - 0.1, 0.02, 0.06), k.luz(k.cor_alianca, 1.1), 0.0)
		k.caixa(pai, Vector3(z, 0.08, 0), Vector3(0.06, 0.02, LOTE - 0.1), k.luz(k.cor_alianca, 1.1), 0.0)
	_faixas(k, pai, 0.08, larg, k.luz(k.PALETA["neon"], 1.2), true)
	k.cilindro(pai, Vector3(0, 0.08, 0), 0.6, 0.02, k.feixe(k.PALETA["neon"], 0.5, 1.4), 32)
	# carros flutuantes
	for v in [[Vector3(-1.5, 0.35, 0.45), 180.0], [Vector3(0.45, 0.35, -1.5), 90.0]]:
		k.veiculo(pai, v[0], v[1], Color("f4f6fa"))
		k.cilindro(pai, v[0] - Vector3(0, 0.22, 0), 0.45, 0.02, k.feixe(k.cor_alianca, 0.5, 1.5), 20)
	k.pessoa(pai, Vector3(1.8, 0.2, 1.6), k.cor_alianca)
	return 2.3
