extends RefCounted
## Radar e antena: visão do mapa e defesa passiva. Silhueta vertical e fina, branco e
## cinza com vermelho de sinalização; a varredura aparece como luz ciano. Frente = +Z.

const LOTE := 5.4

func construir(k, pai: Node3D, faixa: int) -> float:
	match faixa:
		1: return _f1(k, pai)
		2: return _f2(k, pai)
		3: return _f3(k, pai)
		4: return _f4(k, pai)
		5: return _f5(k, pai)
		_: return _f6(k, pai)

func _trelica(k, pai: Node3D, pos: Vector3, h: float, base: float, topo: float, cor: Material, faixas_vermelhas := false) -> void:
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var g = k.grupo(pai, pos + Vector3(sx, 0, sz) * base * 0.5)
			var inc := atan2((base - topo) * 0.5, h)
			g.rotation.x = -sz * inc
			g.rotation.z = sx * inc
			k.caixa(g, Vector3.ZERO, Vector3(0.07, h / cos(inc), 0.07), cor, 0.0)
	var n := int(h / 0.45)
	for i in n:
		var y := 0.3 + i * 0.45
		var l := lerpf(base, topo, y / h)
		var m = k.p("vermelho", 0.5) if faixas_vermelhas and (i / 2) % 2 == 1 else cor
		k.caixa(pai, pos + Vector3(0, y, 0), Vector3(l, 0.04, l), m, 0.0)
		k.caixa(pai, pos + Vector3(0, y, l * 0.5), Vector3(l, 0.03, 0.03), m, 0.0)
	k.caixa(pai, pos + Vector3(0, h, 0), Vector3(topo + 0.2, 0.1, topo + 0.2), cor, 0.02)

func _parabolica(k, pai: Node3D, pos: Vector3, rot_y: float, inclina: float, r: float) -> Node3D:
	var g = k.grupo(pai, pos, rot_y)
	k.cilindro(g, Vector3.ZERO, 0.06, 0.25, k.p("aco_escuro"), 8)
	var i = k.grupo(g, Vector3(0, 0.25, 0))
	i.rotation_degrees.x = inclina
	k.cilindro(i, Vector3.ZERO, r * 0.2, r * 0.35, k.p("branco", 0.45), 20, r)
	k.cilindro(i, Vector3(0, r * 0.34, 0), r * 0.92, 0.02, k.mat(Color("c7d2e2"), 0.5), 20)
	k.cilindro(i, Vector3(0, 0.05, 0), 0.02, r * 0.9, k.p("aco_escuro"), 6)
	k.esfera(i, Vector3(0, r * 0.95, 0), 0.05, k.luz(Color("ff3b30"), 1.5))
	return i

func _cone_luz(k, pai: Node3D, origem: Vector3, alvo: Vector3, raio_fim: float, cor: Color, alfa := 0.3) -> void:
	var meio := (origem + alvo) * 0.5
	var f = k.grupo(pai, meio)
	f.look_at_from_position(meio, alvo, Vector3.UP)
	var m = k.cilindro(f, Vector3.ZERO, 0.05, origem.distance_to(alvo), k.feixe(cor, alfa, 1.4), 16, raio_fim)
	m.rotation_degrees.x = -90
	m.position = Vector3.ZERO

# ---- faixa 1: mastro com antena e refletor
func _f1(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("terra", 0.95))
	var m := Vector3(-0.3, 0.05, -0.3)
	k.cilindro(pai, m, 0.1, 3.0, k.p("madeira"), 8)
	for s in [Vector3(1, 0, 0), Vector3(-0.5, 0, 0.87), Vector3(-0.5, 0, -0.87)]:
		var a := m + Vector3(0, 2.6, 0)
		var c: Vector3 = m + s * 1.6
		var meio := (a + c) * 0.5
		var f = k.grupo(pai, meio)
		f.look_at_from_position(meio, c, Vector3.UP)
		var cabo = k.cilindro(f, Vector3.ZERO, 0.01, a.distance_to(c), k.p("aco_escuro"), 4)
		cabo.rotation_degrees.x = 90
		cabo.position = Vector3.ZERO
		k.caixa(pai, c, Vector3(0.12, 0.08, 0.12), k.p("concreto_escuro"), 0.02)
	k.antena(pai, m + Vector3(0, 3.0, 0), 0.9)
	for i in 3:
		k.caixa(pai, m + Vector3(0, 2.3 + i * 0.15, 0), Vector3(0.5 - i * 0.1, 0.025, 0.025), k.p("aco", 0.4, 0.6), 0.0)
	# refletor apontado para a frente
	var r = k.grupo(pai, m + Vector3(0, 1.9, 0.12), 0)
	r.rotation_degrees.x = 20
	k.cilindro(r, Vector3.ZERO, 0.14, 0.25, k.p("aco_escuro"), 12).rotation_degrees.x = 90
	k.cilindro(r, Vector3(0, -0.12, 0.13), 0.12, 0.02, k.luz(Color("fff3c4"), 1.8), 12).rotation_degrees.x = 90
	_cone_luz(k, pai, m + Vector3(0, 1.9, 0.3), Vector3(0.6, 0.06, 2.3), 0.7, Color("fff3c4"), 0.18)
	# guarita de sacos de areia
	for i in 6:
		var a := deg_to_rad(-30 + i * 24)
		var q := Vector3(cos(a), 0, sin(a)) * 1.0 + Vector3(-1.2, 0.05, 1.2)
		var s = k.caixa(pai, q, Vector3(0.45, 0.22, 0.28), k.p("saco", 0.95), 0.1)
		s.rotation.y = -a + PI / 2
	k.caixa(pai, Vector3(1.4, 0.05, -1.4), Vector3(0.9, 0.8, 0.8), k.p("madeira"), 0.04)
	k.caixa(pai, Vector3(1.4, 0.85, -1.4), Vector3(1.0, 0.08, 0.9), k.alianca(), 0.02)
	k.pessoa(pai, Vector3(-1.2, 0.05, 1.2), k.cor_alianca)
	return 4.2

# ---- faixa 2: torre de aço com antena parabólica
func _f2(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var c := Vector3(-0.4, 0.05, -0.4)
	k.caixa(pai, c, Vector3(1.6, 0.25, 1.6), k.p("concreto", 0.8), 0.04)
	_trelica(k, pai, c + Vector3(0, 0.25, 0), 3.4, 1.2, 0.5, k.p("aco", 0.45, 0.5), true)
	_parabolica(k, pai, c + Vector3(0, 3.75, 0), 40, 50, 0.8)
	k.antena(pai, c + Vector3(0.2, 3.75, -0.2), 0.8)
	k.caixa(pai, Vector3(1.3, 0.05, 1.2), Vector3(1.2, 0.9, 0.9), k.p("painel", 0.6), 0.05)
	k.caixa(pai, Vector3(1.3, 0.95, 1.2), Vector3(1.25, 0.08, 0.95), k.alianca(), 0.02)
	k.caixa(pai, Vector3(1.3, 0.4, 1.66), Vector3(0.5, 0.3, 0.02), k.vidro(Color("8fd8ff"), 0.4), 0.0)
	k.pessoa(pai, Vector3(0.3, 0.05, 1.9), k.cor_alianca)
	k.arvore(pai, Vector3(-2.0, 0.05, 1.8))
	return 5.0

# ---- faixa 3: radar giratório com cúpula
func _f3(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var b := Vector3(-0.3, 0.05, -0.3)
	k.caixa(pai, b, Vector3(2.4, 1.4, 2.4), k.p("concreto", 0.8), 0.08)
	k.caixa(pai, b + Vector3(0, 1.4, 0), Vector3(2.5, 0.14, 2.5), k.alianca(), 0.03)
	k.janelas(pai, b + Vector3(0, 0, 1.2), Vector3.BACK, 2.0, b.y + 0.3, 1, 0.9, 3, k.vidro(Color("6fd0ff"), 0.5), k.p("branco"))
	k.cilindro(pai, b + Vector3(0, 1.54, 0), 0.5, 1.0, k.p("concreto", 0.8), 12)
	k.esfera(pai, b + Vector3(0, 3.1, 0), 0.85, k.p("branco", 0.4))
	k.toro(pai, b + Vector3(0, 2.6, 0), 0.75, 0.05, k.alianca())
	# antena de barra giratória ao lado da cúpula
	var g = k.grupo(pai, b + Vector3(1.0, 1.54, 1.0), 25)
	k.cilindro(g, Vector3.ZERO, 0.08, 0.6, k.p("aco_escuro"), 8)
	k.caixa(g, Vector3(0, 0.6, 0), Vector3(1.4, 0.35, 0.08), k.mat(Color("dfe7f2"), 0.4, 0.4), 0.02)
	for i in 6:
		k.caixa(g, Vector3(-0.55 + i * 0.22, 0.65, 0.05), Vector3(0.12, 0.25, 0.02), k.mat(Color("4d586b"), 0.5), 0.0)
	k.antena(pai, b + Vector3(-1.0, 1.54, -1.0), 1.0)
	_parabolica(k, pai, b + Vector3(-1.0, 1.54, 0.8), 200, 45, 0.4)
	k.veiculo(pai, Vector3(1.8, 0.08, 1.9), 90, Color("3d4f6b"))
	k.pessoa(pai, Vector3(0.2, 0.05, 1.9), k.cor_alianca)
	return 4.4

# ---- faixa 4: torre com três antenas e luz de varredura
func _f4(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var c := Vector3(-0.3, 0.05, -0.3)
	k.caixa(pai, c, Vector3(2.0, 0.8, 2.0), k.p("painel", 0.5), 0.06)
	k.caixa(pai, c + Vector3(0, 0.8, 0), Vector3(2.06, 0.1, 2.06), k.alianca(), 0.02)
	k.cilindro(pai, c + Vector3(0, 0.9, 0), 0.45, 4.2, k.p("branco", 0.45), 12, 0.32)
	for a in 3:
		k.cilindro(pai, c + Vector3(0, 1.6 + a * 1.2, 0), 0.47 - a * 0.04, 0.12, k.p("vermelho", 0.55), 12)
	var top := c + Vector3(0, 5.1, 0)
	k.cilindro(pai, top, 0.8, 0.5, k.vidro(Color("6fd0ff"), 0.6), 12)
	k.cilindro(pai, top + Vector3(0, 0.5, 0), 0.85, 0.12, k.p("branco", 0.45), 12)
	for i in 3:
		var a := i * TAU / 3
		k.antena(pai, top + Vector3(cos(a) * 0.5, 0.62, sin(a) * 0.5), 1.0 + i * 0.3)
	# luz de varredura
	k.esfera(pai, top + Vector3(0.5, 0.25, 0.5), 0.14, k.luz(Color("bff8ff"), 2.0))
	_cone_luz(k, pai, top + Vector3(0.5, 0.25, 0.5), Vector3(2.3, 0.1, 2.0), 0.9, Color("bff8ff"), 0.22)
	_parabolica(k, pai, c + Vector3(0.7, 0.9, 0.7), 30, 50, 0.35)
	k.veiculo(pai, Vector3(1.8, 0.08, 1.4), 90, Color("3d4f6b"))
	k.pessoa(pai, Vector3(-1.4, 0.05, 1.9), k.cor_alianca)
	return 7.1

# ---- faixa 5: rede de antenas com feixe visível
func _f5(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var pos := [Vector3(-1.3, 0.05, -1.3), Vector3(1.3, 0.05, -1.3), Vector3(-1.3, 0.05, 1.3), Vector3(1.0, 0.05, 1.0)]
	for i in 4:
		var q: Vector3 = pos[i]
		k.cilindro(pai, q, 0.35, 0.5, k.p("concreto", 0.7), 12)
		k.cilindro(pai, q + Vector3(0, 0.5, 0), 0.37, 0.06, k.luz(k.PALETA["neon"], 1.2), 12)
		var d = _parabolica(k, pai, q + Vector3(0, 0.5, 0), 45, 25, 0.75)
		var orig := q + Vector3(0, 1.4, 0)
		_cone_luz(k, pai, orig, orig + Vector3(-0.6, 3.2, -0.6), 0.25, k.PALETA["neon"], 0.3)
	# central de controle no meio
	var c := Vector3(-0.15, 0.05, -0.15)
	k.cilindro(pai, c, 0.8, 1.6, k.p("painel", 0.45), 8)
	k.cilindro(pai, c + Vector3(0, 0.9, 0), 0.82, 0.3, k.vidro(Color("6fd0ff"), 0.6), 8)
	k.cilindro(pai, c + Vector3(0, 1.6, 0), 0.9, 0.12, k.alianca(), 8)
	k.cilindro(pai, c + Vector3(0, 1.72, 0), 0.08, 1.8, k.p("aco", 0.4, 0.5), 8)
	k.esfera(pai, c + Vector3(0, 3.6, 0), 0.18, k.luz(k.PALETA["neon"], 1.6))
	for y in [2.2, 2.8]:
		k.toro(pai, c + Vector3(0, y, 0), 0.4, 0.03, k.feixe(k.PALETA["neon"], 0.7, 1.8))
	k.drone(pai, Vector3(1.9, 2.6, -0.2), k.cor_alianca)
	k.pessoa(pai, Vector3(0.3, 0.05, 2.1), k.cor_alianca)
	return 4.4

# ---- faixa 6: torre de elite com holograma de varredura
func _f6(k, pai: Node3D) -> float:
	k.base_elite(pai, LOTE)
	k.cilindro(pai, Vector3(0, 0.05, 0), 2.0, 0.45, k.mat(Color("f3f0ea"), 0.3), 6)
	k.cilindro(pai, Vector3(0, 0.5, 0), 2.04, 0.06, k.ouro(), 6)
	var c := Vector3(0, 0.56, 0)
	k.cilindro(pai, c, 0.75, 4.6, k.mat(Color("23305a"), 0.35, 0.3), 6, 0.45)
	for i in 6:
		var a := i * TAU / 6 + PI / 6
		var g = k.grupo(pai, c + Vector3(cos(a) * 0.62, 0, sin(a) * 0.62))
		g.rotation.x = -sin(a) * 0.065
		g.rotation.z = cos(a) * 0.065
		k.caixa(g, Vector3.ZERO, Vector3(0.08, 4.6, 0.08), k.luz(k.cor_alianca, 0.9), 0.0)
	for y in [1.5, 3.0]:
		k.cilindro(pai, c + Vector3(0, y, 0), 0.75 - y * 0.06, 0.15, k.ouro(), 6)
	var top := c + Vector3(0, 4.6, 0)
	k.cilindro(pai, top, 0.9, 0.3, k.ouro(), 6)
	k.esfera(pai, top + Vector3(0, 0.7, 0), 0.5, k.mat(Color("f4f6fa"), 0.3))
	k.toro(pai, top + Vector3(0, 0.7, 0), 0.55, 0.05, k.alianca())
	k.cone(pai, top + Vector3(0, 1.15, 0), 0.08, 0.8, k.ouro(), 8)
	# disco holográfico de varredura com fatia acesa e alvos
	var d := top + Vector3(0, -1.6, 0)
	k.cilindro(pai, d, 2.3, 0.02, k.feixe(Color("1fb8d8"), 0.25, 1.0, false), 48)
	for r in [0.9, 1.6, 2.3]:
		k.toro(pai, d + Vector3(0, 0.02, 0), r, 0.025, k.feixe(Color("0fd0f0"), 0.8, 1.0, false))
	for i in 8:
		var a0 := deg_to_rad(20 + i * 6)
		var s = k.grupo(pai, d + Vector3(0, 0.03, 0), rad_to_deg(-a0))
		k.caixa(s, Vector3(1.15, 0, 0), Vector3(2.3, 0.01, 0.12 + i * 0.02), k.feixe(Color("2ee86a"), 0.12 + i * 0.05, 1.0, false), 0.0)
	for q in [Vector3(1.3, 0, 1.0), Vector3(-1.5, 0, 0.6), Vector3(0.4, 0, -1.8)]:
		k.esfera(pai, d + q + Vector3(0, 0.05, 0), 0.08, k.luz(Color("ff4a3d"), 1.8))
	k.pessoa(pai, Vector3(-1.4, 0.5, 1.6), k.cor_alianca)
	return 7.0
