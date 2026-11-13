extends RefCounted
## Estufa hidropônica: produz alimentos. Verde domina; a aliança vai nas estruturas
## (arcos, caixilhos, faixas). Frente = +Z, lado visível = +X.

const LOTE := 5.4

func construir(k, pai: Node3D, faixa: int) -> float:
	match faixa:
		1: return _f1(k, pai)
		2: return _f2(k, pai)
		3: return _f3(k, pai)
		4: return _f4(k, pai)
		5: return _f5(k, pai)
		_: return _f6(k, pai)

func _plastico(k) -> Material:
	return k.mat(Color("eef8ff"), 0.2, 0.0, 0.0, 0.45)

func _canteiro(k, pai: Node3D, pos: Vector3, comp: float, tipo: String, linhas := 2) -> void:
	k.caixa(pai, pos, Vector3(comp, 0.12, 0.25 * linhas + 0.1), k.p("terra", 0.95), 0.03)
	for l in linhas:
		k.fileira(pai, pos + Vector3(-comp * 0.5 + 0.2, 0.12, (l - (linhas - 1) * 0.5) * 0.25), Vector3.RIGHT, int((comp - 0.2) / 0.3), 0.3, tipo, 0.9)

# ---- faixa 1: estufa de plástico com fileiras de verduras
func _f1(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("terra", 0.95))
	var c := Vector3(-0.3, 0.05, -0.5)
	_canteiro(k, pai, c + Vector3(0, 0, -0.45), 3.2, "alface")
	_canteiro(k, pai, c + Vector3(0, 0, 0.45), 3.2, "tomate")
	k.tunel(pai, c, 1.25, 3.4, _plastico(k), k.p("branco", 0.5), 8, 5)
	# porta de lona na ponta
	k.caixa(pai, c + Vector3(1.72, 0, 0), Vector3(0.04, 0.95, 0.6), k.p("lona", 0.9), 0.01)
	# canteiros ao ar livre, regador, caixa de colheita
	_canteiro(k, pai, Vector3(-0.3, 0.05, 1.55), 3.4, "broto", 2)
	k.caixa(pai, Vector3(1.9, 0.05, 1.2), Vector3(0.5, 0.3, 0.4), k.p("madeira"), 0.03)
	k.fileira(pai, Vector3(1.75, 0.35, 1.2), Vector3.RIGHT, 2, 0.25, "alface", 0.8)
	k.cilindro(pai, Vector3(2.1, 0.05, -1.7), 0.35, 0.8, k.mat(Color("4f7fae"), 0.6), 14)
	k.cilindro(pai, Vector3(2.1, 0.85, -1.7), 0.37, 0.06, k.alianca(), 14)
	k.pessoa(pai, Vector3(1.6, 0.05, 2.1), k.PALETA["lona"])
	return 2.0

# ---- faixa 2: estufa de vidro com irrigação aparente
func _f2(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var c := Vector3(-0.3, 0.05, -0.3)
	var t := Vector3(3.6, 1.5, 2.6)
	var vid = k.mat(Color("d8f4ff"), 0.08, 0.2, 0.0, 0.35)
	var arm = k.p("branco", 0.5)
	k.caixa(pai, c, Vector3(t.x + 0.1, 0.45, t.z + 0.1), k.p("concreto"), 0.04)
	k.caixa(pai, c + Vector3(0, 0.38, 0), Vector3(t.x + 0.14, 0.1, t.z + 0.14), k.alianca(), 0.03)
	_canteiro(k, pai, c + Vector3(0, 0.45, -0.6), 3.2, "tomate")
	_canteiro(k, pai, c + Vector3(0, 0.45, 0.6), 3.2, "alface")
	k.caixa(pai, c + Vector3(0, 0.25, 0), Vector3(t.x, t.y, t.z), vid, 0.0)
	# telhado de duas águas
	for s in [-1, 1]:
		var g = k.grupo(pai, c + Vector3(0, 0.25 + t.y, s * t.z * 0.25))
		g.rotation_degrees.x = s * 32
		k.caixa(g, Vector3(0, -0.02, 0), Vector3(t.x, 0.03, t.z * 0.58), vid, 0.0)
		k.caixa(g, Vector3(0, -0.04, s * t.z * 0.29), Vector3(t.x + 0.06, 0.08, 0.08), k.alianca(), 0.0)
		for i in 7:
			k.caixa(g, Vector3(-t.x * 0.5 + i * t.x / 6.0, 0.0, 0), Vector3(0.05, 0.05, t.z * 0.58), arm, 0.0)
	k.caixa(pai, c + Vector3(0, 0.25 + t.y + 0.38, 0), Vector3(t.x + 0.1, 0.1, 0.1), k.alianca(), 0.0)
	# caixilhos verticais
	for i in 7:
		var x := c.x - t.x * 0.5 + i * t.x / 6.0
		for z in [-t.z * 0.5, t.z * 0.5]:
			k.caixa(pai, Vector3(x, c.y + 0.25, c.z + z), Vector3(0.05, t.y, 0.05), arm, 0.0)
	for i in 5:
		var z := c.z - t.z * 0.5 + i * t.z / 4.0
		k.caixa(pai, Vector3(c.x + t.x * 0.5, c.y + 0.25, z), Vector3(0.05, t.y, 0.05), arm, 0.0)
	# irrigação: cano azul aparente com aspersores e caixa d'água
	k.caixa(pai, c + Vector3(0, 0.25 + t.y - 0.15, 0), Vector3(t.x - 0.2, 0.06, 0.06), k.mat(Color("2f8ad6"), 0.4), 0.0)
	for i in 5:
		k.esfera(pai, c + Vector3(-1.4 + i * 0.7, 0.25 + t.y - 0.2, 0), 0.05, k.p("aco", 0.4, 0.6))
	var tq := Vector3(2.0, 0.05, -1.8)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			k.caixa(pai, tq + Vector3(sx * 0.25, 0, sz * 0.25), Vector3(0.06, 0.9, 0.06), k.p("aco"), 0.0)
	k.cilindro(pai, tq + Vector3(0, 0.9, 0), 0.42, 0.6, k.mat(Color("2f8ad6"), 0.4), 14)
	k.caixa(pai, Vector3(1.75, 0.05, -1.0), Vector3(0.06, 0.06, 0.9), k.mat(Color("2f8ad6"), 0.4), 0.0)
	# porta e caixas de colheita
	k.caixa(pai, c + Vector3(t.x * 0.5 + 0.02, 0.25, 0.6), Vector3(0.04, 1.1, 0.6), k.vidro(Color("9fe0ff"), 0.3), 0.01)
	for i in 3:
		k.caixa(pai, Vector3(1.9, 0.05 + i * 0.3, 1.3), Vector3(0.55, 0.28, 0.4), k.mat(Color("ff8a2a"), 0.6), 0.03)
	k.fileira(pai, Vector3(1.72, 0.95, 1.3), Vector3.RIGHT, 2, 0.3, "tomate", 0.6)
	k.pessoa(pai, Vector3(0.8, 0.05, 1.9), k.cor_alianca)
	k.pessoa(pai, Vector3(-1.2, 0.05, 2.0), k.PALETA["lona"])
	return 2.9

# ---- faixa 3: galpão com bandejas empilhadas e luz roxa
func _f3(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var c := Vector3(-0.4, 0.05, -0.4)
	var t := Vector3(3.6, 2.2, 2.8)
	# paredes de trás e esquerda, telhado curvo; frente aberta em vidro para mostrar o interior
	k.caixa(pai, c + Vector3(0, 0, -t.z * 0.5 + 0.08), Vector3(t.x, t.y, 0.16), k.mat(Color("3a2a5c"), 0.7), 0.03)
	k.caixa(pai, c + Vector3(-t.x * 0.5 + 0.08, 0, 0), Vector3(0.16, t.y, t.z), k.mat(Color("3a2a5c"), 0.7), 0.03)
	k.caixa(pai, c, Vector3(t.x, 0.1, t.z), k.mat(Color("2b2f3a"), 0.6), 0.02)
	var roxo := Color("a13dff")
	for fil in 3:
		var z := c.z - 0.85 + fil * 0.85
		for n in 4:
			var y := c.y + 0.1 + n * 0.5
			k.caixa(pai, Vector3(c.x + 0.1, y + 0.3, z), Vector3(3.0, 0.05, 0.45), k.mat(Color("4b3f6b"), 0.5), 0.01)
			k.fileira(pai, Vector3(c.x - 1.25, y + 0.35, z), Vector3.RIGHT, 9, 0.33, "broto", 1.1)
			k.caixa(pai, Vector3(c.x + 0.1, y + 0.7, z), Vector3(2.9, 0.04, 0.36), k.luz(roxo, 1.0), 0.0)
		for x in [-1.4, 1.6]:
			k.caixa(pai, Vector3(c.x + x, c.y + 0.1, z), Vector3(0.05, 2.05, 0.05), k.p("aco"), 0.0)
	k.caixa(pai, c + Vector3(0.0, 0.0, t.z * 0.5), Vector3(t.x, t.y, 0.03), k.feixe(roxo, 0.3, 0.6), 0.0)
	k.caixa(pai, c + Vector3(t.x * 0.5, 0.0, 0.0), Vector3(0.03, t.y, t.z), k.feixe(roxo, 0.3, 0.6), 0.0)
	for z in [-t.z * 0.5, t.z * 0.5]:
		k.caixa(pai, c + Vector3(t.x * 0.5 - 0.05, 0, z), Vector3(0.1, t.y, 0.1), k.p("aco_escuro"), 0.02)
	# telhado com faixa da aliança e exaustores
	k.caixa(pai, c + Vector3(0, t.y, 0), Vector3(t.x + 0.2, 0.14, t.z + 0.2), k.alianca(), 0.04)
	k.caixa(pai, c + Vector3(0, t.y + 0.14, 0), Vector3(t.x - 0.1, 0.1, t.z - 0.1), k.p("aco", 0.6), 0.03)
	for x in [-1.0, 0.0, 1.0]:
		k.cilindro(pai, c + Vector3(x, t.y + 0.24, -0.6), 0.2, 0.3, k.p("aco", 0.4, 0.5), 12)
		k.cilindro(pai, c + Vector3(x, t.y + 0.54, -0.6), 0.24, 0.06, k.p("aco_escuro"), 12)
	# doca e caminhão de alimentos
	k.caixa(pai, Vector3(1.7, 0.05, 1.5), Vector3(1.0, 0.03, 1.6), k.p("asfalto", 0.9), 0.0)
	k.veiculo(pai, Vector3(1.75, 0.08, 1.4), 180, Color("ffffff"), "caminhao")
	for i in 2:
		k.caixa(pai, Vector3(0.4 + i * 0.55, 0.05, 1.7), Vector3(0.45, 0.3, 0.35), k.mat(Color("ff8a2a"), 0.6), 0.03)
	k.pessoa(pai, Vector3(-0.6, 0.05, 1.9), k.cor_alianca)
	k.arvore(pai, Vector3(-2.2, 0.05, 1.9))
	return t.y + 1.0

# ---- faixa 4: estufa vertical de 3 andares, folhagem brilhante
func _f4(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var c := Vector3(-0.3, 0.05, -0.3)
	var t := Vector3(3.0, 1.35, 2.6)
	var vid = k.mat(Color("d8f4ff"), 0.06, 0.25, 0.0, 0.3)
	var aco = k.mat(Color("eef3f8"), 0.3, 0.4)
	for a in 3:
		var y := c.y + a * t.y
		k.caixa(pai, Vector3(c.x, y, c.z), Vector3(t.x + 0.3, 0.12, t.z + 0.3), aco, 0.03)
		k.caixa(pai, Vector3(c.x, y + 0.04, c.z + t.z * 0.5 + 0.15), Vector3(t.x + 0.32, 0.08, 0.04), k.alianca(), 0.0)
		for fil in 3:
			var z := c.z - 0.85 + fil * 0.85
			k.caixa(pai, Vector3(c.x, y + 0.12, z), Vector3(2.7, 0.18, 0.4), k.p("terra", 0.9), 0.02)
			for i in 8:
				var q := Vector3(c.x - 1.2 + i * 0.34, y + 0.3, z)
				k.esfera(pai, q, 0.17, k.mat(Color("49e26a"), 0.6, 0.0, 0.25), 0.85)
				k.esfera(pai, q + Vector3(0.05, 0.12, 0.03), 0.09, k.mat(Color("b5ff6a"), 0.6, 0.0, 0.35))
		k.caixa(pai, Vector3(c.x, y + 0.12, c.z), t + Vector3(0, -0.12, 0), vid, 0.0)
	var top := c.y + 3 * t.y
	k.caixa(pai, Vector3(c.x, top, c.z), Vector3(t.x + 0.3, 0.14, t.z + 0.3), aco, 0.03)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			k.caixa(pai, Vector3(c.x + sx * t.x * 0.5, c.y, c.z + sz * t.z * 0.5), Vector3(0.12, top - c.y, 0.12), aco, 0.02)
	# topo: turbina de ventilação, caixa d'água e painel
	k.cilindro(pai, Vector3(c.x + 0.8, top + 0.14, c.z - 0.5), 0.4, 0.6, k.mat(Color("2f8ad6"), 0.4), 14)
	k.painel_solar(pai, Vector3(c.x - 0.6, top + 0.14, c.z), 0, 1.2)
	k.caixa(pai, Vector3(1.9, 0.05, 1.6), Vector3(0.6, 0.3, 0.45), k.mat(Color("ff8a2a"), 0.6), 0.03)
	k.fileira(pai, Vector3(1.7, 0.35, 1.6), Vector3.RIGHT, 2, 0.3, "tomate", 0.6)
	k.veiculo(pai, Vector3(2.1, 0.08, -0.3), 90, Color("7ed957"))
	k.pessoa(pai, Vector3(0.4, 0.05, 2.0), k.cor_alianca)
	k.pessoa(pai, Vector3(-1.0, 0.05, 2.1), Color("ffffff"))
	k.arvore(pai, Vector3(-2.2, 0.05, 2.0), 0.9)
	return top + 1.1

# ---- faixa 5: fazenda vertical com drones colhendo
func _f5(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var c := Vector3(-0.3, 0.05, -0.3)
	var andares := 6
	var h := 1.0
	var aco = k.mat(Color("f4f6fa"), 0.35, 0.3)
	k.cilindro(pai, c, 0.7, andares * h, k.mat(Color("2b3a55"), 0.4), 8)
	for a in andares:
		var y := c.y + a * h
		var r := 1.75 if a % 2 == 0 else 1.55
		var rot := a * 22.5
		var g = k.grupo(pai, c + Vector3(0, y - c.y, 0), rot)
		k.cilindro(g, Vector3.ZERO, r, 0.12, aco, 8)
		k.cilindro(g, Vector3(0, 0.12, 0), r - 0.1, 0.1, k.p("terra", 0.9), 8)
		for i in 12:
			var ang := i * TAU / 12
			var q := Vector3(cos(ang), 0, sin(ang)) * (r - 0.4) + Vector3(0, 0.3, 0)
			k.esfera(g, q, 0.2, k.mat(Color("49e26a"), 0.6, 0.0, 0.2), 0.85)
			if i % 3 == 0:
				k.esfera(g, q + Vector3(0, 0.15, 0), 0.07, k.p("vermelho", 0.5))
		k.cilindro(g, Vector3(0, 0.02, 0), r + 0.03, 0.05, k.luz(k.cor_alianca, 1.0), 8)
		k.cilindro(g, Vector3(0, 0.25, 0), 0.75, 0.6, k.vidro(Color("6fd0ff"), 0.6), 8)
	var top := c.y + andares * h
	k.cilindro(pai, Vector3(c.x, top, c.z), 1.3, 0.15, aco, 8)
	k.cilindro(pai, Vector3(c.x, top + 0.15, c.z), 0.6, 0.5, k.mat(Color("2f8ad6"), 0.4), 12)
	k.esfera(pai, Vector3(c.x, top + 0.75, c.z), 0.12, k.luz(k.PALETA["neon"], 2.0))
	# drones colhendo, com cesto
	for d in [[Vector3(1.9, 2.3, 1.0), k.cor_alianca], [Vector3(-1.9, 3.6, 1.4), Color("f4f6fa")], [Vector3(1.4, 5.1, -1.7), Color("f4f6fa")], [Vector3(0.9, 1.4, 2.0), Color("f4f6fa")]]:
		k.drone(pai, d[0], d[1])
		k.caixa(pai, d[0] - Vector3(0, 0.3, 0), Vector3(0.22, 0.16, 0.22), k.mat(Color("ff8a2a"), 0.6), 0.03)
		k.fileira(pai, d[0] - Vector3(0, 0.16, 0), Vector3.RIGHT, 1, 0.1, "tomate", 0.35)
	# base: estação de carga e caixotes
	k.caixa(pai, Vector3(1.9, 0.05, 1.9), Vector3(0.8, 0.12, 0.8), k.p("aco_escuro"), 0.03)
	k.cilindro(pai, Vector3(1.9, 0.17, 1.9), 0.3, 0.02, k.luz(k.PALETA["neon"], 1.5), 16)
	for i in 3:
		k.caixa(pai, Vector3(-2.0, 0.05 + i * 0.3, 1.8), Vector3(0.55, 0.28, 0.4), k.mat(Color("ff8a2a"), 0.6), 0.03)
	k.pessoa(pai, Vector3(0.2, 0.05, 2.2), k.cor_alianca)
	return top + 1.3

# ---- faixa 6: biodomo de vidro curvo, folhas luminosas e vapor
func _f6(k, pai: Node3D) -> float:
	k.base_elite(pai, LOTE)
	k.cilindro(pai, Vector3(0, 0.05, 0), 2.35, 0.45, k.mat(Color("f3f0ea"), 0.3), 32)
	k.cilindro(pai, Vector3(0, 0.5, 0), 2.38, 0.06, k.ouro(), 32)
	var base := Vector3(0, 0.56, 0)
	# jardim interno: terra, árvores e folhas luminosas
	k.cilindro(pai, base, 2.15, 0.08, k.p("grama", 0.9), 32)
	k.arvore(pai, base + Vector3(-0.5, 0.08, -0.4), 2.4)
	k.arvore(pai, base + Vector3(0.7, 0.08, 0.3), 1.6)
	for i in 14:
		var a := i * TAU / 14
		var r := 1.5 + 0.25 * (i % 2)
		k.fileira(pai, base + Vector3(cos(a) * r, 0.08, sin(a) * r), Vector3.RIGHT, 1, 0.1, "luminosa", 1.6)
	# lago com água luminosa
	k.cilindro(pai, base + Vector3(0.3, 0.08, 1.0), 0.6, 0.03, k.luz(k.PALETA["agua"], 0.7), 20)
	# cúpula com nervuras douradas e topo na cor da aliança
	k.cupula(pai, base, 2.2, k.mat(Color("cfefff"), 0.04, 0.2, 0.0, 0.22), k.ouro(), 8)
	k.cilindro(pai, base + Vector3(0, 2.15, 0), 0.4, 0.2, k.alianca(0.4), 12)
	k.esfera(pai, base + Vector3(0, 2.45, 0), 0.14, k.luz(k.cor_alianca, 1.4))
	# vapor saindo do topo
	for i in 4:
		k.esfera(pai, base + Vector3(0.1 * i, 2.75 + i * 0.32, -0.05 * i), 0.18 + i * 0.07, k.mat(Color("ffffff"), 1.0, 0.0, 0.0, 0.5 - i * 0.1))
	# anel de holograma com folha
	k.toro(pai, base + Vector3(0, 1.5, 0), 2.45, 0.03, k.feixe(k.PALETA["neon"], 0.6, 2.0))
	k.cilindro(pai, Vector3(2.15, 0.45, 2.15), 0.18, 0.12, k.ouro(), 12)
	k.cilindro(pai, Vector3(2.15, 0.57, 2.15), 0.12, 0.6, k.feixe(k.cor_alianca, 0.25, 1.5), 12, 0.4)
	k.esfera(pai, Vector3(2.15, 1.45, 2.15), 0.22, k.feixe(Color("6dff9e"), 0.6, 2.0), 0.5)
	k.pessoa(pai, Vector3(-0.8, 0.5, 2.25), k.cor_alianca)
	return 4.5
