extends RefCounted
## Heliponto: chegada e saída de reforços e heróis. O círculo com "H" é a marca de todas
## as faixas; a aliança pinta o anel do pouso. Frente = +Z.

const LOTE := 5.4

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

func _pad(k, pai: Node3D, pos: Vector3, r: float, fundo: Material, letra: Material, anel: Material, luzes := 0, luz_cor := Color("7dff7a")) -> void:
	k.cilindro(pai, pos, r, 0.04, fundo, 32)
	k.toro(pai, pos + Vector3(0, 0.05, 0), r * 0.85, r * 0.05, anel)
	var e := r * 0.42
	k.caixa(pai, pos + Vector3(-e * 0.45, 0.04, 0), Vector3(e * 0.22, 0.015, e * 1.4), letra, 0.0)
	k.caixa(pai, pos + Vector3(e * 0.45, 0.04, 0), Vector3(e * 0.22, 0.015, e * 1.4), letra, 0.0)
	k.caixa(pai, pos + Vector3(0, 0.04, 0), Vector3(e * 0.9, 0.015, e * 0.22), letra, 0.0)
	for i in luzes:
		var a := i * TAU / luzes
		k.esfera(pai, pos + Vector3(cos(a) * (r - 0.06), 0.06, sin(a) * (r - 0.06)), 0.05, k.luz(luz_cor, 1.4))

func _biruta(k, pai: Node3D, pos: Vector3) -> void:
	k.cilindro(pai, pos, 0.03, 1.4, k.p("aco", 0.4, 0.5), 6)
	var g = k.grupo(pai, pos + Vector3(0, 1.35, 0), 30)
	g.rotation_degrees.z = -10
	for i in 4:
		var r := 0.12 - i * 0.02
		var c = k.cilindro(g, Vector3.ZERO, r, 0.16, k.mat(Color("ff7a1a") if i % 2 == 0 else Color.WHITE, 0.7), 10, r - 0.02)
		c.rotation_degrees.z = -90
		c.position = Vector3(0.1 + i * 0.16, 0, 0)

func _jato(k, pai: Node3D, pos: Vector3, rot: float, cor: Color) -> void:
	var g = k.grupo(pai, pos, rot)
	var m = k.mat(cor, 0.35, 0.3)
	k.caixa(g, Vector3(0, 0.25, 0), Vector3(1.9, 0.32, 0.42), m, 0.14)
	k.cone(g, Vector3(0, 0, 0), 0.2, 0.5, m, 10).rotation_degrees.z = -90
	g.get_child(g.get_child_count() - 1).position = Vector3(1.2, 0.41, 0)
	k.caixa(g, Vector3(0.45, 0.42, 0), Vector3(0.55, 0.18, 0.3), k.vidro(Color("4fb0ff"), 0.6), 0.08)
	k.caixa(g, Vector3(-0.2, 0.3, 0), Vector3(0.7, 0.05, 2.0), m, 0.02)
	for z in [-0.75, 0.75]:
		k.cilindro(g, Vector3(-0.2, 0.18, z), 0.14, 0.3, k.p("aco_escuro"), 12)
		k.cilindro(g, Vector3(-0.2, 0.12, z), 0.1, 0.06, k.luz(Color("ff9a3a"), 1.4), 12)
	for s in [-1, 1]:
		var t = k.grupo(g, Vector3(-0.85, 0.4, s * 0.18))
		t.rotation_degrees.x = s * 25
		k.caixa(t, Vector3.ZERO, Vector3(0.3, 0.45, 0.04), m, 0.02)
	k.caixa(g, Vector3(-0.2, 0.31, 0), Vector3(0.12, 0.02, 1.6), k.alianca(), 0.0)
	for x in [0.6, -0.5]:
		k.caixa(g, Vector3(x, 0, 0), Vector3(0.05, 0.12, 0.05), k.p("aco_escuro"), 0.0)

# ---- faixa 1: círculo pintado no chão
func _f1(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("grama", 0.9))
	_pad(k, pai, Vector3(-0.2, 0.1, -0.2), 1.7, k.p("terra", 0.95), k.p("branco", 0.7), k.alianca(0.7))
	for i in 6:
		var a := i * TAU / 6
		k.cone(pai, Vector3(cos(a) * 2.2 - 0.2, 0.1, sin(a) * 2.2 - 0.2), 0.08, 0.22, k.mat(Color("ff7a1a"), 0.6), 8)
	for i in 3:
		k.cilindro(pai, Vector3(1.9 + (i % 2) * 0.3, 0.1, 1.5 + i * 0.25), 0.15, 0.45, k.mat(Color("c0392b"), 0.6), 12)
	k.bandeira(pai, Vector3(-2.2, 0.1, 1.9), 1.6, k.cor_alianca)
	k.pessoa(pai, Vector3(1.4, 0.1, 2.0), k.cor_alianca)
	return 1.2

# ---- faixa 2: plataforma com biruta
func _f2(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("grama", 0.9))
	var c := Vector3(-0.3, 0.1, -0.3)
	k.caixa(pai, c, Vector3(3.8, 0.25, 3.8), k.p("concreto", 0.85), 0.06)
	_pad(k, pai, c + Vector3(0, 0.25, 0), 1.6, k.p("asfalto", 0.85), k.p("branco", 0.6), k.p("amarelo", 0.6))
	k.toro(pai, c + Vector3(0, 0.26, 0), 1.75, 0.04, k.alianca())
	_biruta(k, pai, Vector3(1.9, 0.1, 1.9))
	k.caixa(pai, Vector3(-1.9, 0.1, 2.0), Vector3(0.8, 0.6, 0.5), k.p("painel", 0.6), 0.04)
	k.caixa(pai, Vector3(-1.9, 0.7, 2.0), Vector3(0.85, 0.06, 0.55), k.alianca(), 0.02)
	k.pessoa(pai, Vector3(0.9, 0.1, 2.1), k.cor_alianca)
	return 1.6

# ---- faixa 3: heliponto com luzes de pista
func _f3(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("concreto_escuro", 0.9))
	var c := Vector3(-0.4, 0.1, -0.4)
	k.caixa(pai, c, Vector3(3.6, 0.3, 3.6), k.p("concreto", 0.85), 0.06)
	_pad(k, pai, c + Vector3(0, 0.3, 0), 1.55, k.p("asfalto", 0.85), k.p("branco", 0.6), k.alianca(0.6), 16)
	for i in 5:
		k.esfera(pai, Vector3(-2.2 + i * 0.5, 0.15, 1.9), 0.05, k.luz(Color("4fb0ff"), 1.4))
	k.caixa(pai, Vector3(1.9, 0.1, 1.0), Vector3(0.8, 1.0, 1.6), k.p("aco", 0.5, 0.3), 0.06)
	k.caixa(pai, Vector3(2.31, 0.1, 1.0), Vector3(0.02, 0.8, 1.2), k.p("aco_escuro"), 0.0)
	k.caixa(pai, Vector3(1.9, 1.1, 1.0), Vector3(0.85, 0.08, 1.65), k.alianca(), 0.02)
	_biruta(k, pai, Vector3(-2.2, 0.1, -2.2))
	k.helicoptero(pai, c + Vector3(0, 0.34, 0), 30, Color("e8eef5"))
	k.pessoa(pai, Vector3(1.2, 0.1, 2.1), k.cor_alianca)
	return 1.9

# ---- faixa 4: plataforma elevada com helicóptero
func _f4(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("concreto", 0.85))
	var c := Vector3(-0.3, 0.1, -0.3)
	var h := 1.8
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			k.cilindro(pai, c + Vector3(sx * 1.1, 0, sz * 1.1), 0.18, h, k.p("concreto", 0.8), 10)
	k.cilindro(pai, c + Vector3(0, h, 0), 2.0, 0.22, k.p("aco", 0.5, 0.3), 8)
	_pad(k, pai, c + Vector3(0, h + 0.22, 0), 1.85, k.p("asfalto", 0.8), k.p("branco", 0.6), k.alianca(0.6), 16)
	for i in 16:
		var a := i * TAU / 16
		k.caixa(pai, c + Vector3(cos(a) * 2.0, h + 0.22, sin(a) * 2.0), Vector3(0.04, 0.25, 0.04), k.p("aco", 0.4, 0.5), 0.0)
	k.helicoptero(pai, c + Vector3(0, h + 0.26, 0), 20, Color("d94a4a"))
	# escada até a plataforma
	for i in 8:
		k.caixa(pai, Vector3(1.6, 0.1 + i * 0.22, 1.9 - i * 0.18), Vector3(0.5, 0.06, 0.2), k.p("aco", 0.5, 0.3), 0.0)
	k.caixa(pai, Vector3(-1.9, 0.1, 1.9), Vector3(0.9, 0.9, 0.7), k.p("painel", 0.6), 0.04)
	k.caixa(pai, Vector3(-1.9, 1.0, 1.9), Vector3(0.95, 0.08, 0.75), k.alianca(), 0.02)
	_biruta(k, pai, Vector3(-2.2, 0.1, -2.2))
	k.pessoa(pai, Vector3(0.6, 0.1, 2.0), k.cor_alianca)
	return h + 1.6

# ---- faixa 5: heliponto duplo com torre
func _f5(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("concreto", 0.85))
	for q in [Vector3(-1.2, 0.1, -1.2), Vector3(1.0, 0.1, 1.0)]:
		k.caixa(pai, q, Vector3(2.3, 0.35, 2.3), k.p("painel", 0.5), 0.06)
		k.caixa(pai, q + Vector3(0, 0.25, 0), Vector3(2.36, 0.06, 2.36), k.luz(k.PALETA["neon"], 1.0), 0.0)
		_pad(k, pai, q + Vector3(0, 0.35, 0), 1.0, k.p("asfalto", 0.8), k.p("branco", 0.6), k.alianca(0.6), 12, Color("4fb0ff"))
	k.helicoptero(pai, Vector3(-1.2, 0.48, -1.2), -20, Color("f4f6fa"))
	var t := Vector3(1.6, 0.1, -1.6)
	k.cilindro(pai, t, 0.4, 3.0, k.p("painel", 0.45), 10)
	k.cilindro(pai, t + Vector3(0, 3.0, 0), 0.7, 0.55, k.vidro(Color("6fd0ff"), 0.6), 10)
	k.cilindro(pai, t + Vector3(0, 3.55, 0), 0.75, 0.12, k.alianca(), 10)
	k.antena(pai, t + Vector3(0, 3.67, 0), 0.7)
	k.drone(pai, Vector3(1.0, 1.6, 1.0), k.cor_alianca)
	k.pessoa(pai, Vector3(-1.6, 0.1, 1.6), k.cor_alianca)
	return 4.8

# ---- faixa 6: plataforma tecnológica com holograma e jato estacionado
func _f6(k, pai: Node3D) -> float:
	k.base_elite(pai, LOTE)
	k.cilindro(pai, Vector3(0, 0.05, 0), 2.3, 0.5, k.mat(Color("f3f0ea"), 0.3), 8)
	k.cilindro(pai, Vector3(0, 0.55, 0), 2.34, 0.06, k.ouro(), 8)
	_pad(k, pai, Vector3(0, 0.6, 0), 2.0, k.mat(Color("1c2236"), 0.3, 0.3), k.luz(k.PALETA["neon"], 1.0), k.luz(k.cor_alianca, 1.0), 24, Color("fff1a8"))
	_jato(k, pai, Vector3(0.1, 0.65, 0.1), 40, Color("f4f6fa"))
	# holograma do "H" girando sobre a plataforma
	var hg = k.grupo(pai, Vector3(0, 2.4, 0), 45)
	var hm = k.feixe(Color("1fb8d8"), 0.55, 1.0, false)
	k.caixa(hg, Vector3(-0.3, -0.4, 0), Vector3(0.15, 0.8, 0.03), hm, 0.0)
	k.caixa(hg, Vector3(0.3, -0.4, 0), Vector3(0.15, 0.8, 0.03), hm, 0.0)
	k.caixa(hg, Vector3(0, -0.07, 0), Vector3(0.6, 0.14, 0.03), hm, 0.0)
	k.toro(pai, Vector3(0, 2.4, 0), 0.75, 0.02, k.feixe(Color("0fd0f0"), 0.9, 1.0, false))
	k.cilindro(pai, Vector3(0, 0.62, 0), 0.9, 1.4, k.feixe(Color("1fb8d8"), 0.08, 1.0, false), 24, 0.75)
	for q in [Vector3(2.0, 0.55, 0.9), Vector3(-0.9, 0.55, 2.0)]:
		k.cilindro(pai, q, 0.12, 1.0, k.ouro(), 8)
		k.esfera(pai, q + Vector3(0, 1.1, 0), 0.1, k.luz(k.PALETA["neon"], 1.5))
	k.pessoa(pai, Vector3(-1.4, 0.6, 1.4), k.cor_alianca)
	return 3.5
