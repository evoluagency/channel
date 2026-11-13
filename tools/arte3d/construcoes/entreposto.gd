extends RefCounted
## Entreposto logístico: comércio e transporte. Contêineres coloridos são a marca;
## a aliança aparece nas docas, nas faixas e no contêiner de destaque. Frente = +Z.

const LOTE := 5.4
const CORES := [Color("e8833a"), Color("2f9e6a"), Color("d94a4a"), Color("3c78c8"), Color("f2c230"), Color("8e5ad6")]

func construir(k, pai: Node3D, faixa: int) -> float:
	match faixa:
		1: return _f1(k, pai)
		2: return _f2(k, pai)
		3: return _f3(k, pai)
		4: return _f4(k, pai)
		5: return _f5(k, pai)
		_: return _f6(k, pai)

func _cont(k, pai: Node3D, pos: Vector3, rot: float, cor: Color, escala := 0.7) -> void:
	var g = k.grupo(pai, pos, rot)
	g.scale = Vector3.ONE * escala
	k.conteiner(g, Vector3.ZERO, 0, cor)

func _palete(k, pai: Node3D, pos: Vector3, cor: Color) -> void:
	k.caixa(pai, pos, Vector3(0.5, 0.08, 0.5), k.p("madeira"), 0.01)
	k.caixa(pai, pos + Vector3(0, 0.08, 0), Vector3(0.44, 0.34, 0.44), k.mat(cor, 0.75), 0.03)
	k.caixa(pai, pos + Vector3(0, 0.3, 0.221), Vector3(0.12, 0.06, 0.01), k.p("branco"), 0.0)

func _empilhadeira(k, pai: Node3D, pos: Vector3, rot: float) -> void:
	var g = k.grupo(pai, pos, rot)
	var am = k.mat(Color("ffb400"), 0.5)
	k.caixa(g, Vector3(0, 0.1, 0), Vector3(0.6, 0.3, 0.4), am, 0.05)
	k.caixa(g, Vector3(-0.15, 0.4, 0), Vector3(0.3, 0.05, 0.38), k.p("aco_escuro"), 0.01)
	for z in [-0.17, 0.17]:
		k.caixa(g, Vector3(0.05, 0.4, z), Vector3(0.04, 0.45, 0.04), k.p("aco_escuro"), 0.0)
	for z in [-0.12, 0.12]:
		k.caixa(g, Vector3(0.45, 0.12, z), Vector3(0.35, 0.03, 0.06), k.p("aco_escuro"), 0.0)
	k.caixa(g, Vector3(0.32, 0.1, 0), Vector3(0.05, 0.75, 0.32), k.p("aco_escuro"), 0.0)
	for x in [-0.2, 0.2]:
		for z in [-0.2, 0.2]:
			var r = k.cilindro(g, Vector3.ZERO, 0.08, 0.06, k.mat(Color("23262d"), 0.8), 10)
			r.rotation_degrees.x = 90
			r.position = Vector3(x, 0.08, z)
	k.pessoa(g, Vector3(-0.1, 0.25, 0), Color("ff8a2a"), 0.7)

func _galpao(k, pai: Node3D, b: Vector3, t: Vector3, docas: int, cor_corpo: Color) -> void:
	k.caixa(pai, b, t, k.mat(cor_corpo, 0.7), 0.06)
	var tel = k.grupo(pai, b + Vector3(0, t.y, 0))
	for s in [-1, 1]:
		var g = k.grupo(tel, Vector3(0, 0, s * t.z * 0.25))
		g.rotation_degrees.x = s * 12
		k.caixa(g, Vector3.ZERO, Vector3(t.x + 0.15, 0.08, t.z * 0.55), k.p("aco", 0.5, 0.3), 0.02)
	k.caixa(pai, b + Vector3(0, t.y - 0.2, 0), Vector3(t.x + 0.06, 0.16, t.z + 0.06), k.alianca(), 0.02)
	k.caixa(pai, b + Vector3(0, 0, t.z * 0.5 + 0.3), Vector3(t.x, 0.35, 0.6), k.p("concreto_escuro"), 0.03)
	for i in docas:
		var x := b.x + (i - (docas - 1) * 0.5) * (t.x / docas)
		k.caixa(pai, Vector3(x, b.y + 0.35, b.z + t.z * 0.5 + 0.01), Vector3(t.x / docas - 0.35, t.y * 0.55, 0.04), k.p("aco"), 0.02)
		for y in 4:
			k.caixa(pai, Vector3(x, b.y + 0.42 + y * t.y * 0.13, b.z + t.z * 0.5 + 0.04), Vector3(t.x / docas - 0.4, 0.03, 0.02), k.p("aco_escuro"), 0.0)
		k.caixa(pai, Vector3(x, b.y + 0.35 + t.y * 0.57, b.z + t.z * 0.5 + 0.2), Vector3(t.x / docas - 0.2, 0.06, 0.4), k.alianca(), 0.01)
		k.caixa(pai, Vector3(x - (t.x / docas) * 0.42, b.y + 0.35, b.z + t.z * 0.5 + 0.62), Vector3(0.05, 0.3, 0.05), k.p("amarelo"), 0.0)

# ---- faixa 1: barraca com caixas e carrinho
func _f1(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("terra", 0.95))
	var c := Vector3(-0.5, 0.05, -0.5)
	for x in [-1.0, 1.0]:
		for z in [-0.6, 0.6]:
			k.caixa(pai, c + Vector3(x, 0, z), Vector3(0.08, 1.3, 0.08), k.p("madeira"), 0.01)
	k.toldo(pai, c + Vector3(0, 1.45, -0.7), Vector3.BACK, 2.3, 1.5, 8)
	k.caixa(pai, c + Vector3(0, 0, 0.35), Vector3(2.0, 0.7, 0.5), k.p("madeira"), 0.03)
	for i in 4:
		k.caixa(pai, c + Vector3(-0.75 + i * 0.5, 0.7, 0.35), Vector3(0.4, 0.15, 0.35), k.mat(CORES[i], 0.7), 0.02)
	for i in 5:
		k.caixa(pai, c + Vector3(-0.8 + (i % 3) * 0.55, (i / 3) * 0.42, -0.4), Vector3(0.45, 0.4, 0.45), k.p("madeira"), 0.03)
	# carrinho de mão com caixas
	var g = k.grupo(pai, Vector3(1.4, 0.05, 1.1), -30)
	k.caixa(g, Vector3(0, 0.2, 0), Vector3(0.9, 0.08, 0.6), k.p("madeira"), 0.02)
	var r = k.cilindro(g, Vector3.ZERO, 0.2, 0.06, k.p("aco_escuro"), 12)
	r.rotation_degrees.x = 90
	r.position = Vector3(0.0, 0.2, 0.33)
	var r2 = k.cilindro(g, Vector3.ZERO, 0.2, 0.06, k.p("aco_escuro"), 12)
	r2.rotation_degrees.x = 90
	r2.position = Vector3(0.0, 0.2, -0.33)
	k.caixa(g, Vector3(-0.65, 0.25, 0.2), Vector3(0.6, 0.04, 0.04), k.p("madeira"), 0.0)
	k.caixa(g, Vector3(-0.65, 0.25, -0.2), Vector3(0.6, 0.04, 0.04), k.p("madeira"), 0.0)
	k.caixa(g, Vector3(0.1, 0.28, 0), Vector3(0.4, 0.35, 0.4), k.mat(CORES[1], 0.7), 0.03)
	_palete(k, pai, Vector3(-1.8, 0.05, 1.5), CORES[0])
	k.bandeira(pai, Vector3(1.9, 0.05, -1.8), 2.0, k.cor_alianca)
	k.pessoa(pai, Vector3(-0.4, 0.05, 0.9), k.cor_alianca)
	k.pessoa(pai, Vector3(0.6, 0.05, 1.7), CORES[4])
	return 2.4

# ---- faixa 2: armazém com duas docas
func _f2(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	k.caixa(pai, Vector3(-0.3, 0.06, 1.6), Vector3(4.6, 0.02, 1.6), k.p("asfalto", 0.85), 0.0)
	_galpao(k, pai, Vector3(-0.3, 0.05, -1.0), Vector3(3.6, 1.8, 2.2), 2, Color("e6dfd2"))
	k.veiculo(pai, Vector3(-1.1, 0.08, 1.4), 90, Color("ffffff"), "caminhao")
	_palete(k, pai, Vector3(0.6, 0.05, 1.3), CORES[0])
	_palete(k, pai, Vector3(1.2, 0.05, 1.4), CORES[3])
	k.pessoa(pai, Vector3(0.9, 0.05, 2.0), k.cor_alianca)
	k.arvore(pai, Vector3(2.1, 0.05, -1.9))
	return 3.0

# ---- faixa 3: galpão com empilhadeiras e caminhão
func _f3(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	k.caixa(pai, Vector3(-0.3, 0.06, 1.55), Vector3(4.6, 0.02, 1.7), k.p("asfalto", 0.85), 0.0)
	_galpao(k, pai, Vector3(-0.3, 0.05, -1.1), Vector3(4.2, 2.2, 2.2), 3, Color("b9c4d0"))
	k.janelas(pai, Vector3(-0.3, 0.05, -1.1) + Vector3(2.1, 0, 0), Vector3.RIGHT, 1.8, 0.05 + 1.3, 1, 0.6, 3, k.vidro(Color("8fd8ff"), 0.4), null, Vector2(0.4, 0.35))
	k.veiculo(pai, Vector3(-1.5, 0.08, 1.4), 90, k.cor_alianca, "caminhao")
	_empilhadeira(k, pai, Vector3(0.3, 0.05, 1.5), 180)
	_empilhadeira(k, pai, Vector3(1.4, 0.05, 1.1), 120)
	for i in 4:
		_palete(k, pai, Vector3(1.0 + (i % 2) * 0.6, 0.05 + (i / 2) * 0.42, 2.05), CORES[i])
	k.pessoa(pai, Vector3(-0.5, 0.05, 2.1), k.cor_alianca)
	return 3.4

# ---- faixa 4: terminal com contêineres coloridos
func _f4(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("asfalto", 0.85))
	for i in 5:
		k.caixa(pai, Vector3(-2.2 + i * 1.1, 0.06, 0.4), Vector3(0.5, 0.01, 0.06), k.p("amarelo", 0.6), 0.0)
	var i := 0
	for x in [-1.4, 0.4]:
		for z in [-1.7, -0.9]:
			for a in 3:
				var cor: Color = k.cor_alianca if (x > 0 and z > -1.0 and a == 2) else CORES[(i + a * 2) % CORES.size()]
				_cont(k, pai, Vector3(x, 0.05 + a * 0.7, z), 0, cor)
			i += 1
	# portaria com cancela
	var p := Vector3(1.7, 0.05, 1.4)
	k.caixa(pai, p, Vector3(0.8, 0.9, 0.8), k.p("painel", 0.6), 0.05)
	k.caixa(pai, p + Vector3(0, 0.9, 0), Vector3(1.0, 0.08, 1.0), k.alianca(), 0.02)
	k.caixa(pai, p + Vector3(0.0, 0.35, 0.41), Vector3(0.5, 0.3, 0.02), k.vidro(Color("8fd8ff"), 0.4), 0.0)
	k.caixa(pai, p + Vector3(-1.0, 0.45, 0.5), Vector3(1.4, 0.06, 0.06), k.p("vermelho", 0.6), 0.0)
	k.veiculo(pai, Vector3(-0.4, 0.08, 1.2), 90, Color("ffffff"), "caminhao")
	_cont(k, pai, Vector3(-0.7, 0.62, 1.2), 0, CORES[4], 0.4)
	_empilhadeira(k, pai, Vector3(-1.9, 0.05, 1.7), 30)
	k.pessoa(pai, Vector3(0.9, 0.05, 2.0), k.cor_alianca)
	return 3.0

# ---- faixa 5: porto seco com guindaste móvel e drones
func _f5(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("asfalto", 0.85))
	var i := 0
	for x in [-1.6, 0.1]:
		for z in [-1.8, -1.05, -0.3]:
			for a in 2 + (i % 2):
				_cont(k, pai, Vector3(x, 0.05 + a * 0.7, z), 0, CORES[(i * 2 + a) % CORES.size()])
			i += 1
	# pórtico sobre trilhos com contêiner suspenso
	var p := Vector3(-0.75, 0.05, -1.05)
	for x in [-1.85, 1.85]:
		for z in [-1.0, 1.0]:
			k.caixa(pai, p + Vector3(x, 0, z), Vector3(0.18, 3.0, 0.18), k.alianca(0.5), 0.03)
		k.caixa(pai, p + Vector3(x, 0, 0), Vector3(0.3, 0.15, 2.3), k.p("aco_escuro"), 0.02)
	for z in [-1.0, 1.0]:
		k.caixa(pai, p + Vector3(0, 3.0, z), Vector3(4.0, 0.22, 0.2), k.alianca(0.5), 0.03)
	k.caixa(pai, p + Vector3(0.4, 2.8, 0), Vector3(0.5, 0.3, 2.2), k.p("amarelo", 0.5), 0.03)
	_cont(k, pai, p + Vector3(0.4, 1.9, 0), 90, k.cor_alianca)
	for z in [-0.4, 0.4]:
		k.caixa(pai, p + Vector3(0.4, 2.6, z), Vector3(0.02, 0.2, 0.02), k.p("aco_escuro"), 0.0)
	# drones de entrega
	for d in [Vector3(1.6, 2.4, 1.2), Vector3(1.9, 3.3, -0.4), Vector3(0.5, 2.0, 1.8)]:
		k.drone(pai, d, Color("f4f6fa"))
		k.caixa(pai, d - Vector3(0, 0.3, 0), Vector3(0.25, 0.2, 0.25), k.mat(CORES[0], 0.7), 0.03)
	k.veiculo(pai, Vector3(-1.2, 0.08, 1.6), 90, Color("ffffff"), "caminhao")
	k.caixa(pai, Vector3(1.8, 0.05, 1.8), Vector3(0.8, 0.12, 0.8), k.p("aco_escuro"), 0.03)
	k.cilindro(pai, Vector3(1.8, 0.17, 1.8), 0.3, 0.02, k.luz(k.PALETA["neon"], 1.5), 16)
	k.pessoa(pai, Vector3(0.6, 0.05, 2.2), k.cor_alianca)
	return 3.9

# ---- faixa 6: hub global com esteiras luminosas e contêineres flutuantes
func _f6(k, pai: Node3D) -> float:
	k.base_elite(pai, LOTE)
	k.caixa(pai, Vector3(0, 0.05, 0), Vector3(4.0, 0.4, 4.0), k.mat(Color("f3f0ea"), 0.3), 0.08)
	k.caixa(pai, Vector3(0, 0.45, 0), Vector3(4.06, 0.06, 4.06), k.ouro(), 0.02)
	# terminal central em degraus
	var b := Vector3(-0.4, 0.51, -0.4)
	k.caixa(pai, b, Vector3(2.4, 1.2, 2.4), k.mat(Color("23305a"), 0.35, 0.3), 0.1)
	k.caixa(pai, b + Vector3(0, 1.2, 0), Vector3(2.5, 0.12, 2.5), k.ouro(), 0.03)
	k.caixa(pai, b + Vector3(0, 1.32, 0), Vector3(1.6, 0.9, 1.6), k.mat(Color("23305a"), 0.35, 0.3), 0.08)
	k.caixa(pai, b + Vector3(0, 0.3, 1.21), Vector3(1.8, 0.5, 0.03), k.luz(k.cor_alianca, 0.8), 0.0)
	k.caixa(pai, b + Vector3(1.21, 0.3, 0), Vector3(0.03, 0.5, 1.8), k.luz(k.cor_alianca, 0.8), 0.0)
	# globo holográfico
	var gc := b + Vector3(0, 3.0, 0)
	k.cilindro(pai, b + Vector3(0, 2.22, 0), 0.3, 0.2, k.ouro(), 12)
	k.esfera(pai, gc, 0.65, k.feixe(Color("1fb8d8"), 0.35, 1.0, false))
	for a in [0, 60, 120]:
		var g = k.grupo(pai, gc, a)
		var t = k.toro(g, Vector3.ZERO, 0.66, 0.015, k.feixe(Color("0fd0f0"), 0.9, 1.0, false))
		t.rotation_degrees.x = 90
	for y in [-0.35, 0.0, 0.35]:
		k.toro(pai, gc + Vector3(0, y, 0), sqrt(0.66 * 0.66 - y * y), 0.015, k.feixe(Color("0fd0f0"), 0.9, 1.0, false))
	k.toro(pai, gc, 1.0, 0.03, k.luz(k.cor_alianca, 1.0)).rotation_degrees.z = 20
	# esteiras luminosas saindo do terminal
	for e in [[Vector3(1.6, 0.51, -0.4), 90.0], [Vector3(-0.4, 0.51, 1.6), 0.0]]:
		var g = k.grupo(pai, e[0], e[1])
		k.caixa(g, Vector3(0, 0.2, 0), Vector3(1.8, 0.1, 0.5), k.p("aco_escuro"), 0.02)
		k.caixa(g, Vector3(0, 0.3, 0), Vector3(1.8, 0.03, 0.42), k.luz(k.PALETA["neon"], 1.0), 0.0)
		for i in 2:
			_cont(k, g, Vector3(-0.4 + i * 0.8, 0.33, 0), 0, CORES[i * 3], 0.3)
	# contêineres flutuantes com aro de energia
	for f in [[Vector3(1.7, 2.4, 1.5), CORES[0]], [Vector3(-1.8, 2.9, 1.0), k.cor_alianca], [Vector3(1.6, 3.6, -1.5), CORES[4]]]:
		_cont(k, pai, f[0], 30, f[1], 0.45)
		k.toro(pai, f[0] - Vector3(0, 0.15, 0), 0.65, 0.025, k.feixe(k.PALETA["neon"], 0.7, 1.8))
	k.pessoa(pai, Vector3(1.4, 0.51, 1.6), k.cor_alianca)
	return 4.6
