extends RefCounted
## Parque: bem-estar. Verde, flores de cores vivas e água; a aliança aparece em toldos,
## bandeirolas e luzes. Frente = +Z.

const LOTE := 5.4
const FLORES := [Color("ff5d8f"), Color("ffd23f"), Color("ff8a2a"), Color("b06bff"), Color("ffffff")]

func construir(k, pai: Node3D, faixa: int) -> float:
	var y := 0.0
	match faixa:
		1: y = _f1(k, pai)
		2: y = _f2(k, pai)
		3: y = _f3(k, pai)
		4: y = _f4(k, pai)
		5: y = _f5(k, pai)
		_: y = _f6(k, pai)
	return y

func _canteiro(k, pai: Node3D, pos: Vector3, t: Vector2, semente: int) -> void:
	k.caixa(pai, pos, Vector3(t.x, 0.18, t.y), k.p("tijolo", 0.85), 0.04)
	k.caixa(pai, pos + Vector3(0, 0.18, 0), Vector3(t.x - 0.1, 0.03, t.y - 0.1), k.p("terra", 0.95), 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	for i in int(t.x * t.y * 10):
		var q := pos + Vector3(rng.randf_range(-t.x * 0.4, t.x * 0.4), 0.22, rng.randf_range(-t.y * 0.4, t.y * 0.4))
		k.esfera(pai, q, 0.07, k.p("folha", 0.85), 0.8)
		k.esfera(pai, q + Vector3(0, 0.07, 0), 0.045, k.mat(FLORES[rng.randi() % FLORES.size()], 0.6))

func _lago(k, pai: Node3D, pos: Vector3, raio: float, brilho := false) -> void:
	k.cilindro(pai, pos, raio + 0.12, 0.08, k.p("concreto", 0.8), 24)
	k.cilindro(pai, pos + Vector3(0, 0.02, 0), raio, 0.08, k.luz(Color("37b6f0"), 0.4) if brilho else k.mat(Color("37b6f0"), 0.08, 0.3), 24)

func _chafariz(k, pai: Node3D, pos: Vector3, raio: float, cor_agua: Color, jatos := 1, luz_agua := false) -> void:
	k.cilindro(pai, pos, raio, 0.3, k.p("concreto", 0.7), 20)
	k.cilindro(pai, pos + Vector3(0, 0.22, 0), raio - 0.1, 0.1, k.mat(cor_agua, 0.05, 0.3), 20)
	k.cilindro(pai, pos + Vector3(0, 0.3, 0), 0.12, 0.6, k.p("concreto", 0.7), 10)
	k.cilindro(pai, pos + Vector3(0, 0.85, 0), raio * 0.45, 0.1, k.p("concreto", 0.7), 16)
	var agua = k.feixe(cor_agua, 0.55, 1.4, false) if not luz_agua else k.feixe(cor_agua, 0.6, 1.6)
	k.cilindro(pai, pos + Vector3(0, 0.95, 0), 0.06, 0.9, agua, 8, 0.02)
	k.esfera(pai, pos + Vector3(0, 1.85, 0), 0.1, agua)
	for i in jatos:
		var a: float = i * TAU / max(jatos, 1)
		var q := pos + Vector3(cos(a), 0, sin(a)) * raio * 0.7
		k.cilindro(pai, q + Vector3(0, 0.3, 0), 0.04, 0.5 + (i % 2) * 0.3, agua, 6, 0.015)

# ---- faixa 1: canteiro com bancos
func _f1(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("grama", 0.9))
	k.caixa(pai, Vector3(0, 0.1, 0), Vector3(LOTE - 0.4, 0.02, 0.8), k.p("terra", 0.95), 0.0)
	_canteiro(k, pai, Vector3(-1.2, 0.1, -1.3), Vector2(1.8, 1.0), 1)
	_canteiro(k, pai, Vector3(1.2, 0.1, 1.3), Vector2(1.8, 1.0), 2)
	k.banco(pai, Vector3(1.0, 0.1, -0.6), 180)
	k.banco(pai, Vector3(-1.0, 0.1, 0.6), 0)
	k.arvore(pai, Vector3(2.0, 0.1, -1.7), 0.9)
	k.cilindro(pai, Vector3(-2.1, 0.1, 1.6), 0.15, 0.4, k.p("aco_escuro"), 8)
	k.pessoa(pai, Vector3(-0.5, 0.1, 0.9), k.cor_alianca)
	return 1.4

# ---- faixa 2: praça com árvores
func _f2(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("grama", 0.9))
	k.caixa(pai, Vector3(0, 0.1, 0), Vector3(3.6, 0.02, 3.6), k.p("calcada", 0.85), 0.0)
	for i in 4:
		var g = k.grupo(pai, Vector3.ZERO, i * 90)
		k.caixa(g, Vector3(0, 0.12, 1.2), Vector3(0.9, 0.02, 2.4), k.mat(Color("cbbfa8"), 0.85), 0.0)
		k.arvore(g, Vector3(1.4, 0.1, 1.4), 1.3)
		k.banco(g, Vector3(0.6, 0.1, 1.0), 180)
	# monumento simples
	k.caixa(pai, Vector3(0, 0.1, 0), Vector3(0.7, 0.4, 0.7), k.p("concreto", 0.7), 0.05)
	k.cilindro(pai, Vector3(0, 0.5, 0), 0.12, 1.0, k.p("concreto", 0.7), 8)
	k.esfera(pai, Vector3(0, 1.6, 0), 0.22, k.alianca())
	for i in 6:
		var a := i * TAU / 6
		k.cilindro(pai, Vector3(cos(a) * 2.4, 0.1, sin(a) * 2.4), 0.03, 0.9, k.p("aco_escuro"), 6)
	k.pessoa(pai, Vector3(0.8, 0.1, 0.4), k.cor_alianca)
	k.pessoa(pai, Vector3(-0.6, 0.1, 0.9), Color("ff5d8f"))
	return 2.2

# ---- faixa 3: parque com lago
func _f3(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("grama", 0.9))
	_lago(k, pai, Vector3(-0.4, 0.1, -0.3), 1.4)
	# ponte de madeira
	var p = k.grupo(pai, Vector3(-0.4, 0.2, -0.3), 45)
	k.caixa(p, Vector3.ZERO, Vector3(3.4, 0.08, 0.5), k.p("madeira"), 0.02)
	for x in [-1.5, -0.5, 0.5, 1.5]:
		for z in [-0.24, 0.24]:
			k.caixa(p, Vector3(x, 0.08, z), Vector3(0.05, 0.3, 0.05), k.p("madeira"), 0.0)
	for z in [-0.24, 0.24]:
		k.caixa(p, Vector3(0, 0.36, z), Vector3(3.2, 0.04, 0.04), k.p("madeira"), 0.0)
	# patos e vitórias-régias
	for d in [Vector3(-1.1, 0.22, 0.2), Vector3(0.3, 0.22, -0.9)]:
		k.esfera(pai, d, 0.1, k.p("branco", 0.6))
		k.esfera(pai, d + Vector3(0.08, 0.08, 0), 0.06, k.p("branco", 0.6))
		k.esfera(pai, d + Vector3(0.14, 0.08, 0), 0.025, k.p("amarelo", 0.6))
	for v in [Vector3(-0.9, 0.2, -0.9), Vector3(0.1, 0.2, 0.4)]:
		k.cilindro(pai, v, 0.15, 0.01, k.p("folha", 0.8), 10)
	for q in [Vector3(1.9, 0.1, 1.8), Vector3(-2.1, 0.1, 1.9), Vector3(2.0, 0.1, -1.9), Vector3(1.7, 0.1, 0.6)]:
		k.arvore(pai, q, 1.2)
	k.banco(pai, Vector3(0.9, 0.1, 1.6), 180)
	_canteiro(k, pai, Vector3(-1.9, 0.1, -2.0), Vector2(1.0, 0.7), 3)
	k.pessoa(pai, Vector3(0.4, 0.1, 1.9), k.cor_alianca)
	return 2.0

# ---- faixa 4: parque com quiosque e playground
func _f4(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("grama", 0.9))
	# quiosque
	var q := Vector3(-1.3, 0.1, -1.2)
	k.cilindro(pai, q, 0.9, 0.12, k.p("concreto", 0.7), 8)
	for i in 6:
		var a := i * TAU / 6
		k.cilindro(pai, q + Vector3(cos(a) * 0.75, 0.12, sin(a) * 0.75), 0.04, 1.0, k.p("branco", 0.5), 6)
	k.cilindro(pai, q + Vector3(0, 1.12, 0), 1.0, 0.45, k.alianca(), 8, 0.1)
	k.caixa(pai, q + Vector3(0, 0.12, 0), Vector3(0.7, 0.5, 0.5), k.p("madeira"), 0.03)
	k.caixa(pai, q + Vector3(0, 0.62, 0), Vector3(0.7, 0.04, 0.5), k.p("branco"), 0.0)
	# playground em piso emborrachado
	var pg := Vector3(0.9, 0.1, 0.7)
	k.caixa(pai, pg, Vector3(2.4, 0.03, 2.2), k.mat(Color("ff7a59"), 0.9), 0.02)
	k.caixa(pai, pg + Vector3(-0.5, 0.03, -0.4), Vector3(0.7, 0.9, 0.7), k.mat(Color("3c78c8"), 0.5), 0.06)
	k.caixa(pai, pg + Vector3(-0.5, 0.93, -0.4), Vector3(0.8, 0.08, 0.8), k.p("amarelo", 0.5), 0.02)
	k.cone(pai, pg + Vector3(-0.5, 1.0, -0.4), 0.55, 0.5, k.p("vermelho", 0.5), 4)
	var esc = k.grupo(pai, pg + Vector3(0.25, 0.5, -0.4))
	esc.rotation_degrees.z = 35
	k.caixa(esc, Vector3(0, -0.04, 0), Vector3(1.1, 0.06, 0.4), k.p("amarelo", 0.4), 0.02)
	# balanço
	var b := pg + Vector3(0.0, 0.03, 0.6)
	for x in [-0.6, 0.6]:
		k.caixa(pai, b + Vector3(x, 0, 0), Vector3(0.06, 1.0, 0.06), k.p("aco", 0.4, 0.4), 0.0)
	k.caixa(pai, b + Vector3(0, 1.0, 0), Vector3(1.3, 0.06, 0.06), k.p("aco", 0.4, 0.4), 0.0)
	for x in [-0.25, 0.25]:
		k.caixa(pai, b + Vector3(x, 0.35, 0), Vector3(0.015, 0.65, 0.015), k.p("aco_escuro"), 0.0)
		k.caixa(pai, b + Vector3(x, 0.3, 0), Vector3(0.25, 0.04, 0.15), k.p("vermelho", 0.5), 0.0)
	for t in [Vector3(-2.0, 0.1, 1.6), Vector3(2.1, 0.1, -1.8), Vector3(0.4, 0.1, -2.1)]:
		k.arvore(pai, t, 1.1)
	k.banco(pai, Vector3(-1.2, 0.1, 0.4), 0)
	k.pessoa(pai, Vector3(1.0, 0.13, 1.6), k.cor_alianca, 0.75)
	k.pessoa(pai, Vector3(-0.6, 0.1, -0.2), Color("ff5d8f"))
	return 2.0

# ---- faixa 5: jardim com chafariz
func _f5(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("grama", 0.9))
	k.caixa(pai, Vector3(0, 0.1, 0), Vector3(LOTE - 0.3, 0.02, 0.8), k.p("calcada", 0.85), 0.0)
	k.caixa(pai, Vector3(0, 0.1, 0), Vector3(0.8, 0.02, LOTE - 0.3), k.p("calcada", 0.85), 0.0)
	k.cilindro(pai, Vector3(0, 0.1, 0), 1.3, 0.03, k.p("calcada", 0.85), 24)
	_chafariz(k, pai, Vector3(0, 0.1, 0), 1.0, Color("6fd8ff"), 6)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var c := Vector3(sx * 1.75, 0.1, sz * 1.75)
			k.caixa(pai, c + Vector3(-sx * 0.2, 0, 0), Vector3(1.2, 0.4, 0.25), k.p("folha", 0.85), 0.1)
			k.caixa(pai, c + Vector3(0, 0, -sz * 0.2), Vector3(0.25, 0.4, 1.2), k.p("folha", 0.85), 0.1)
			_canteiro(k, pai, c + Vector3(sx * 0.15, 0, sz * 0.15), Vector2(0.8, 0.8), 5 + int(sx + sz * 2))
			k.cone(pai, c + Vector3(sx * 0.6, 0.0, sz * 0.6), 0.25, 1.1, k.p("folha", 0.85), 8)
	for q in [Vector3(1.0, 0.1, 1.55), Vector3(-1.0, 0.1, -1.55)]:
		k.poste(pai, q, 1.4)
	k.drone(pai, Vector3(1.8, 2.2, -0.6), Color("f4f6fa"))
	k.pessoa(pai, Vector3(0.6, 0.1, 1.7), k.cor_alianca)
	k.pessoa(pai, Vector3(-0.3, 0.1, 2.0), Color("b06bff"))
	return 2.6

# ---- faixa 6: parque com luz e fontes animadas
func _f6(k, pai: Node3D) -> float:
	k.base_elite(pai, LOTE)
	k.cilindro(pai, Vector3(0, 0.05, 0), 2.3, 0.3, k.mat(Color("f3f0ea"), 0.3), 32)
	k.cilindro(pai, Vector3(0, 0.35, 0), 2.33, 0.05, k.ouro(), 32)
	k.cilindro(pai, Vector3(0, 0.4, 0), 1.6, 0.06, k.luz(Color("37b6f0"), 0.5), 32)
	_chafariz(k, pai, Vector3(0, 0.4, 0), 0.8, Color("8ff4ff"), 8, true)
	# jatos dançantes em anel, com cores alternadas
	for i in 10:
		var a := i * TAU / 10
		var q := Vector3(cos(a), 0, sin(a)) * 1.35 + Vector3(0, 0.45, 0)
		var cor: Color = k.cor_alianca.lightened(0.2) if i % 2 == 0 else Color("ff6bd8")
		k.cilindro(pai, q, 0.05, 0.6 + (i % 3) * 0.45, k.feixe(cor, 0.65, 1.6), 6, 0.02)
	# arcos dourados com luzes
	for i in 4:
		k.arco(pai, Vector3(0, 0.4, 0), 2.05, 45 + i * 90, 0.06, k.ouro(), 6)
	for i in 12:
		var a := i * TAU / 12
		k.esfera(pai, Vector3(cos(a) * 2.05, 0.42, sin(a) * 2.05), 0.06, k.luz(Color("fff1a8"), 1.6))
	for q in [Vector3(-1.75, 0.4, 1.0), Vector3(1.0, 0.4, -1.75), Vector3(-1.4, 0.4, -1.4)]:
		k.cilindro(pai, q, 0.25, 0.3, k.ouro(), 10)
		k.arvore(pai, q + Vector3(0, 0.3, 0), 0.8)
		k.esfera(pai, q + Vector3(0, 1.3, 0), 0.12, k.luz(Color("c6ff6a"), 1.0))
	k.pessoa(pai, Vector3(1.4, 0.4, 1.2), k.cor_alianca)
	k.pessoa(pai, Vector3(0.9, 0.4, 1.7), Color("ff5d8f"))
	return 3.0
