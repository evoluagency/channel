extends RefCounted
## Central de energia: gera energia. Paleta de branco, azul-solar e amarelo elétrico;
## a energia aparece como luz ciano. A fonte muda por país; aqui, solar e eólica.

const LOTE := 5.4

func construir(k, pai: Node3D, faixa: int) -> float:
	match faixa:
		1: return _f1(k, pai)
		2: return _f2(k, pai)
		3: return _f3(k, pai)
		4: return _f4(k, pai)
		5: return _f5(k, pai)
		_: return _f6(k, pai)

func _gerador(k, pai: Node3D, pos: Vector3) -> void:
	k.caixa(pai, pos, Vector3(1.0, 0.6, 0.6), k.mat(Color("3f8f4a"), 0.6), 0.06)
	k.caixa(pai, pos + Vector3(0, 0.6, 0), Vector3(1.04, 0.06, 0.64), k.alianca(), 0.02)
	for i in 4:
		k.caixa(pai, pos + Vector3(-0.3 + i * 0.2, 0.15, 0.31), Vector3(0.1, 0.35, 0.02), k.mat(Color("2c6b35"), 0.6), 0.0)
	k.cilindro(pai, pos + Vector3(0.35, 0.6, -0.15), 0.05, 0.4, k.p("aco_escuro"), 8)
	for i in 3:
		k.esfera(pai, pos + Vector3(0.35 + i * 0.05, 1.1 + i * 0.2, -0.15), 0.08 + i * 0.04, k.mat(Color("6b6f78"), 1.0, 0.0, 0.0, 0.6 - i * 0.15))

func _fileira_solar(k, pai: Node3D, pos: Vector3, n: int) -> void:
	for i in n:
		k.painel_solar(pai, pos + Vector3(i * 0.95, 0, 0), 0, 0.9)

func _torre_tx(k, pai: Node3D, pos: Vector3, h: float) -> void:
	var cor = k.p("aco", 0.45, 0.5)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var g = k.grupo(pai, pos + Vector3(sx * 0.35, 0, sz * 0.35))
			g.rotation_degrees.x = -sz * 4
			g.rotation_degrees.z = sx * 4
			k.caixa(g, Vector3.ZERO, Vector3(0.06, h, 0.06), cor, 0.0)
	for i in int(h / 0.5):
		var y := 0.4 + i * 0.5
		var l := 0.7 - (y / h) * 0.55
		k.caixa(pai, pos + Vector3(0, y, 0), Vector3(l, 0.04, l), cor, 0.0)
	for y in [h * 0.7, h * 0.9]:
		k.caixa(pai, pos + Vector3(0, y, 0), Vector3(0.08, 0.06, 1.6 - (y / h) * 0.4), cor, 0.0)
		for z in [-0.6, 0.6]:
			k.cilindro(pai, pos + Vector3(0, y - 0.18, z * (1.0 - y / h * 0.3)), 0.04, 0.18, k.mat(Color("7fb8e6"), 0.3), 8)

func _raio(k, pai: Node3D, a: Vector3, b: Vector3, semente: int, cor: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var anterior := a
	for i in range(1, 6):
		var q := a.lerp(b, i / 5.0)
		if i < 5:
			q += Vector3(rng.randf_range(-0.15, 0.15), rng.randf_range(-0.1, 0.1), rng.randf_range(-0.15, 0.15))
		var meio := (anterior + q) * 0.5
		var f = k.grupo(pai, meio)
		f.look_at_from_position(meio, q, Vector3.UP if absf((q - anterior).normalized().y) < 0.95 else Vector3.RIGHT)
		var m = k.cilindro(f, Vector3.ZERO, 0.025, anterior.distance_to(q), k.feixe(cor, 0.9, 2.5), 5)
		m.rotation_degrees.x = 90
		m.position = Vector3.ZERO
		anterior = q

# ---- faixa 1: poucos painéis solares e um gerador a diesel
func _f1(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("terra", 0.95))
	_fileira_solar(k, pai, Vector3(-1.6, 0.05, -1.3), 3)
	k.painel_solar(pai, Vector3(-1.6, 0.05, -0.1), 0, 0.9)
	_gerador(k, pai, Vector3(0.9, 0.05, 0.2))
	for i in 3:
		k.cilindro(pai, Vector3(1.7 + (i % 2) * 0.3, 0.05, 1.4 + i * 0.3), 0.17, 0.5, k.mat(Color("c0392b"), 0.6), 12)
	k.caixa(pai, Vector3(0.0, 0.06, 0.0), Vector3(1.6, 0.03, 0.05), k.mat(Color("20242c"), 0.7), 0.0)
	k.caixa(pai, Vector3(-0.6, 0.05, 1.4), Vector3(0.7, 0.9, 0.5), k.p("painel"), 0.04)
	k.caixa(pai, Vector3(-0.6, 0.55, 1.66), Vector3(0.4, 0.25, 0.02), k.luz(Color("7dff7a"), 0.8), 0.0)
	k.bandeira(pai, Vector3(-2.1, 0.05, 1.9), 1.7, k.cor_alianca)
	k.pessoa(pai, Vector3(0.3, 0.05, 1.6), k.cor_alianca)
	return 2.2

# ---- faixa 2: fileira de painéis e uma turbina pequena
func _f2(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	_fileira_solar(k, pai, Vector3(-2.0, 0.05, -1.6), 4)
	_fileira_solar(k, pai, Vector3(-2.0, 0.05, -0.5), 4)
	k.turbina(pai, Vector3(1.7, 0.05, -1.5), 2.8, 40)
	k.caixa(pai, Vector3(1.5, 0.05, 1.0), Vector3(1.0, 0.9, 0.8), k.p("painel", 0.6), 0.05)
	k.caixa(pai, Vector3(1.5, 0.95, 1.0), Vector3(1.05, 0.08, 0.85), k.alianca(), 0.02)
	k.caixa(pai, Vector3(1.5, 0.35, 1.41), Vector3(0.4, 0.5, 0.02), k.p("amarelo", 0.5), 0.0)
	k.antena(pai, Vector3(1.2, 1.03, 0.8), 0.6)
	_gerador(k, pai, Vector3(-1.4, 0.05, 1.4))
	k.pessoa(pai, Vector3(0.2, 0.05, 1.6), k.cor_alianca)
	return 3.4

# ---- faixa 3: parque com turbina grande e subestação
func _f3(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("grama", 0.9))
	k.turbina(pai, Vector3(-1.2, 0.05, -1.2), 4.6, 40)
	k.turbina(pai, Vector3(1.6, 0.05, -1.9), 2.6, 40)
	# subestação cercada
	var s := Vector3(0.9, 0.05, 0.8)
	k.caixa(pai, s, Vector3(2.4, 0.08, 2.0), k.mat(Color("b9b0a2"), 0.9), 0.0)
	for i in 3:
		var q := s + Vector3(-0.7 + i * 0.7, 0.08, -0.3)
		k.caixa(pai, q, Vector3(0.45, 0.55, 0.45), k.mat(Color("8d9bb0"), 0.5, 0.3), 0.04)
		for j in 3:
			k.cilindro(pai, q + Vector3(-0.12 + j * 0.12, 0.55, 0), 0.04, 0.3, k.mat(Color("7fb8e6"), 0.3), 8)
	k.caixa(pai, s + Vector3(0, 0.08, 0.5), Vector3(1.6, 0.7, 0.5), k.p("painel", 0.6), 0.04)
	k.caixa(pai, s + Vector3(0, 0.78, 0.5), Vector3(1.65, 0.08, 0.55), k.alianca(), 0.02)
	k.caixa(pai, s + Vector3(0.4, 0.25, 0.76), Vector3(0.25, 0.25, 0.02), k.p("amarelo", 0.5), 0.0)
	for lado in [[Vector3(0, 0, -1.0), Vector3(2.4, 0.5, 0.03)], [Vector3(0, 0, 1.0), Vector3(2.4, 0.5, 0.03)], [Vector3(-1.2, 0, 0), Vector3(0.03, 0.5, 2.0)], [Vector3(1.2, 0, 0), Vector3(0.03, 0.5, 2.0)]]:
		k.caixa(pai, s + lado[0], lado[1], k.mat(Color("c8d0da"), 0.4, 0.4, 0.0, 0.45), 0.0)
	_fileira_solar(k, pai, Vector3(-2.1, 0.05, 1.2), 2)
	k.pessoa(pai, Vector3(-0.6, 0.05, 2.1), k.cor_alianca)
	return 5.6

# ---- faixa 4: usina com torre de transmissão e linhas
func _f4(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var b := Vector3(-0.8, 0.05, 0.2)
	var t := Vector3(2.4, 2.0, 2.4)
	k.caixa(pai, b, t, k.p("painel", 0.5), 0.08)
	for a in 2:
		k.caixa(pai, b + Vector3(0, 0.4 + a * 0.8, t.z * 0.5), Vector3(t.x - 0.4, 0.4, 0.04), k.vidro(Color("6fd0ff"), 0.6), 0.01)
	k.caixa(pai, b + Vector3(0, t.y, 0), Vector3(t.x + 0.1, 0.15, t.z + 0.1), k.alianca(), 0.03)
	k.cilindro(pai, b + Vector3(-0.6, t.y + 0.15, -0.6), 0.25, 1.6, k.p("branco", 0.5), 12)
	k.cilindro(pai, b + Vector3(-0.6, t.y + 1.45, -0.6), 0.27, 0.15, k.alianca(), 12)
	k.cilindro(pai, b + Vector3(0.4, t.y + 0.15, -0.6), 0.25, 1.2, k.p("branco", 0.5), 12)
	k.cilindro(pai, b + Vector3(0.4, t.y + 1.05, -0.6), 0.27, 0.15, k.p("vermelho", 0.6), 12)
	var tx := Vector3(1.6, 0.05, -1.5)
	_torre_tx(k, pai, tx, 4.0)
	# linhas de transmissão saindo do prédio e da torre
	for z in [-0.55, 0.55]:
		var a := b + Vector3(t.x * 0.5, t.y - 0.2, z * 0.6)
		var c := tx + Vector3(0, 4.0 * 0.7 - 0.18, z * 0.75)
		var meio := (a + c) * 0.5
		var f = k.grupo(pai, meio)
		f.look_at_from_position(meio, c, Vector3.UP)
		var m = k.cilindro(f, Vector3.ZERO, 0.012, a.distance_to(c), k.mat(Color("20242c"), 0.6), 4)
		m.rotation_degrees.x = 90
		m.position = Vector3.ZERO
		var d := c + Vector3(1.4, -0.6, 0.0)
		var meio2 := (c + d) * 0.5
		var f2 = k.grupo(pai, meio2)
		f2.look_at_from_position(meio2, d, Vector3.UP)
		var m2 = k.cilindro(f2, Vector3.ZERO, 0.012, c.distance_to(d), k.mat(Color("20242c"), 0.6), 4)
		m2.rotation_degrees.x = 90
		m2.position = Vector3.ZERO
	_fileira_solar(k, pai, Vector3(-2.1, 0.05, -1.9), 3)
	k.veiculo(pai, Vector3(1.6, 0.08, 1.6), 90, Color("ffb400"))
	k.pessoa(pai, Vector3(-0.3, 0.05, 1.0), k.cor_alianca)
	return 4.9

# ---- faixa 5: complexo com baterias gigantes e raios azuis
func _f5(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var azul := Color("4fc8ff")
	for i in 3:
		var q := Vector3(-1.7 + i * 1.15, 0.05, -1.6)
		k.caixa(pai, q, Vector3(0.95, 2.0, 1.3), k.p("painel", 0.45), 0.1)
		for n in 4:
			k.caixa(pai, q + Vector3(0, 0.25 + n * 0.42, 0.66), Vector3(0.6, 0.22, 0.02), k.luz(azul if n < 3 - (i % 2) else Color("40465a"), 1.0), 0.0)
		k.caixa(pai, q + Vector3(0, 2.0, 0), Vector3(0.6, 0.12, 0.4), k.alianca(), 0.03)
	# bobina com raios
	var bob := Vector3(0.9, 0.05, 0.9)
	k.cilindro(pai, bob, 0.5, 0.4, k.p("aco_escuro"), 12)
	k.cilindro(pai, bob + Vector3(0, 0.4, 0), 0.22, 2.0, k.mat(Color("b87333"), 0.35, 0.7), 16)
	for i in 8:
		k.toro(pai, bob + Vector3(0, 0.6 + i * 0.22, 0), 0.24, 0.025, k.mat(Color("d48a45"), 0.3, 0.7))
	var topo := bob + Vector3(0, 2.6, 0)
	k.toro(pai, topo, 0.5, 0.17, k.p("aco", 0.25, 0.8))
	k.esfera(pai, topo, 0.25, k.luz(azul, 1.2))
	_raio(k, pai, topo + Vector3(0.4, 0, 0), Vector3(1.9, 1.0, 1.9), 3, azul)
	_raio(k, pai, topo + Vector3(-0.4, 0, 0), Vector3(-0.6, 1.4, -0.4), 7, azul)
	_raio(k, pai, topo + Vector3(0, 0.1, 0.4), topo + Vector3(0.3, 1.0, 0.9), 11, Color("c9f1ff"))
	k.caixa(pai, Vector3(1.9, 0.05, 1.9), Vector3(0.5, 0.95, 0.5), k.p("aco"), 0.04)
	k.cilindro(pai, Vector3(-1.6, 0.05, 1.2), 0.5, 1.2, k.p("branco", 0.45), 16)
	k.cilindro(pai, Vector3(-1.6, 0.6, 1.2), 0.52, 0.12, k.luz(azul, 1.0), 16)
	k.drone(pai, Vector3(-0.4, 3.1, 1.6), k.cor_alianca)
	k.pessoa(pai, Vector3(-0.3, 0.05, 2.1), k.cor_alianca)
	return 3.6

# ---- faixa 6: reator de energia com anel luminoso girando
func _f6(k, pai: Node3D) -> float:
	k.base_elite(pai, LOTE)
	k.cilindro(pai, Vector3(0, 0.05, 0), 2.1, 0.5, k.mat(Color("f3f0ea"), 0.3), 16)
	k.cilindro(pai, Vector3(0, 0.55, 0), 2.14, 0.06, k.ouro(), 16)
	var c := Vector3(0, 0.61, 0)
	k.cilindro(pai, c, 1.2, 0.4, k.mat(Color("2a3350"), 0.4), 16)
	for i in 6:
		var a := i * TAU / 6
		k.caixa(pai, c + Vector3(cos(a), 0, sin(a)) * 1.25, Vector3(0.25, 2.6, 0.25), k.ouro(), 0.05)
	k.cilindro(pai, c + Vector3(0, 0.4, 0), 0.75, 2.4, k.mat(Color("bff4ff"), 0.05, 0.2, 0.0, 0.3), 24)
	k.esfera(pai, c + Vector3(0, 1.6, 0), 0.55, k.luz(Color("6ff7ff"), 1.4))
	k.esfera(pai, c + Vector3(0, 1.6, 0), 0.8, k.feixe(k.PALETA["neon"], 0.35, 1.2))
	k.cilindro(pai, c + Vector3(0, 2.8, 0), 1.3, 0.25, k.mat(Color("2a3350"), 0.4), 16)
	k.cilindro(pai, c + Vector3(0, 3.05, 0), 0.5, 0.3, k.alianca(0.4), 12)
	k.cone(pai, c + Vector3(0, 3.35, 0), 0.3, 0.8, k.ouro(), 12)
	# anéis luminosos inclinados (giram na animação)
	var a1 = k.grupo(pai, c + Vector3(0, 1.6, 0))
	a1.rotation_degrees = Vector3(70, 0, 20)
	k.toro(a1, Vector3.ZERO, 1.7, 0.06, k.luz(k.cor_alianca, 1.2))
	var a2 = k.grupo(pai, c + Vector3(0, 1.6, 0))
	a2.rotation_degrees = Vector3(-60, 0, -35)
	k.toro(a2, Vector3.ZERO, 1.55, 0.05, k.luz(k.PALETA["neon"], 1.4))
	k.toro(pai, c + Vector3(0, 1.6, 0), 1.9, 0.04, k.feixe(k.PALETA["neon"], 0.6, 1.6))
	k.pessoa(pai, Vector3(-1.5, 0.55, 1.6), k.cor_alianca)
	k.pessoa(pai, Vector3(1.4, 0.55, 1.7), Color("1d2a44"))
	return 4.9
