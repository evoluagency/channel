extends RefCounted
## Quartel-general: receita das seis faixas visuais.
## Lado visível pela câmera: faces +X e +Z (frente = +Z).

const LOTE := 5.4

func construir(k, pai: Node3D, faixa: int) -> float:
	match faixa:
		1: return _f1(k, pai)
		2: return _f2(k, pai)
		3: return _f3(k, pai)
		4: return _f4(k, pai)
		5: return _f5(k, pai)
		_: return _f6(k, pai)

# ---- faixa 1: Acampamento (contêineres, lona, bandeira e antena simples)
func _conteiner(k, pai: Node3D, pos: Vector3, rot: float, cor: Color, porta := false) -> void:
	var g = k.grupo(pai, pos, rot)
	var m = k.mat(cor, 0.85)
	var friso = k.mat(cor.darkened(0.18), 0.85)
	k.caixa(g, Vector3.ZERO, Vector3(2.4, 1.0, 1.0), m, 0.05)
	for i in 11:
		var x := -1.0 + i * 0.2
		for z in [-0.51, 0.51]:
			k.caixa(g, Vector3(x, 0.08, z), Vector3(0.07, 0.84, 0.03), friso, 0.01)
	for z in [-0.25, 0.25]:
		k.caixa(g, Vector3(1.21, 0.08, z), Vector3(0.03, 0.84, 0.42), friso, 0.01)
	if porta:
		k.caixa(g, Vector3(0.3, 0.02, 0.53), Vector3(0.5, 0.8, 0.04), k.mat(Color("3b3f48"), 0.7), 0.02)
		k.caixa(g, Vector3(-0.5, 0.45, 0.53), Vector3(0.55, 0.3, 0.04), k.vidro(Color("9fe0ff"), 0.3), 0.02)

func _f1(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("terra", 0.95))
	_conteiner(k, pai, Vector3(-0.3, 0.05, -0.6), 0, k.PALETA["conteiner_a"])
	_conteiner(k, pai, Vector3(-0.3, 0.05, 0.55), 0, k.PALETA["conteiner_b"], true)
	_conteiner(k, pai, Vector3(-0.3, 1.05, 0.0), 90, k.PALETA["conteiner_c"])
	# lona sobre estacas
	for z in [-0.9, 0.9]:
		k.cilindro(pai, Vector3(1.75, 0.05, z), 0.05, 1.25, k.p("madeira"), 6)
	var lona = k.grupo(pai, Vector3(1.35, 1.2, 0))
	lona.rotation_degrees.z = -14
	k.caixa(lona, Vector3.ZERO, Vector3(1.1, 0.05, 2.1), k.p("lona", 0.9), 0.02)
	k.caixa(pai, Vector3(1.3, 0.05, 0.2), Vector3(0.7, 0.4, 0.5), k.p("madeira"), 0.03)
	# sacos de areia em arco
	for i in 7:
		var a := deg_to_rad(-20 + i * 16)
		var pos := Vector3(cos(a), 0, sin(a)) * 2.15 + Vector3(-0.2, 0.05, 0.2)
		var s = k.caixa(pai, pos, Vector3(0.5, 0.24, 0.3), k.p("saco", 0.95), 0.1)
		s.rotation.y = -a + PI / 2
	for i in 5:
		var a := deg_to_rad(-12 + i * 18)
		var pos := Vector3(cos(a), 0, sin(a)) * 2.15 + Vector3(-0.2, 0.29, 0.2)
		var s = k.caixa(pai, pos, Vector3(0.5, 0.24, 0.3), k.p("saco", 0.95), 0.1)
		s.rotation.y = -a + PI / 2
	# caixotes e tambor
	k.caixa(pai, Vector3(-2.0, 0.05, 1.7), Vector3(0.5, 0.5, 0.5), k.p("madeira"), 0.04)
	k.caixa(pai, Vector3(-1.45, 0.05, 1.85), Vector3(0.4, 0.4, 0.4), k.p("madeira"), 0.04)
	k.cilindro(pai, Vector3(-2.05, 0.05, 1.1), 0.2, 0.55, k.mat(Color("c0392b"), 0.6), 12)
	# bandeira e antena simples
	k.bandeira(pai, Vector3(1.9, 0.05, -1.9), 2.6, k.cor_alianca)
	k.antena(pai, Vector3(-0.3, 2.05, 0.9), 1.1)
	# chaminé com fumaça leve
	k.cilindro(pai, Vector3(-0.8, 2.05, -0.8), 0.07, 0.5, k.p("aco_escuro"), 8)
	for i in 3:
		k.esfera(pai, Vector3(-0.8 + i * 0.08, 2.75 + i * 0.28, -0.8 - i * 0.05), 0.13 + i * 0.05, k.mat(Color("e8edf2"), 1.0, 0.0, 0.0, 0.55 - i * 0.15))
	k.pessoa(pai, Vector3(1.2, 0.05, 1.3), Color("6e8d52"))
	return 3.4

# ---- faixa 2: Pré-fabricado de 2 andares com faixa da aliança
func _f2(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var corpo := Vector3(3.6, 2.0, 2.6)
	var base := Vector3(-0.2, 0.05, -0.3)
	k.caixa(pai, base, corpo, k.p("painel", 0.6), 0.08)
	# juntas dos painéis
	for i in 7:
		var x := base.x - 1.8 + 0.45 + i * 0.45
		k.caixa(pai, Vector3(x, base.y, base.z + 1.31), Vector3(0.04, 2.0, 0.02), k.p("concreto_escuro"), 0.0)
	# faixa da aliança entre os andares e no topo
	k.caixa(pai, base + Vector3(0, 0.92, 0), Vector3(3.7, 0.2, 2.7), k.alianca(), 0.04)
	k.caixa(pai, base + Vector3(0, 1.94, 0), Vector3(3.72, 0.16, 2.72), k.alianca(), 0.04)
	k.caixa(pai, base + Vector3(0, 2.0, 0), Vector3(3.5, 0.14, 2.5), k.p("concreto", 0.8), 0.04)
	var jan = k.vidro(Color("8fd8ff"), 0.4)
	var mold = k.p("aco_escuro", 0.5)
	k.janelas(pai, base + Vector3(0, 0, 1.3), Vector3.BACK, 3.2, base.y + 0.05, 2, 1.0, 5, jan, mold)
	k.janelas(pai, base + Vector3(1.8, 0, 0), Vector3.RIGHT, 2.2, base.y + 0.05, 2, 1.0, 3, jan, mold)
	# porta e marquise
	k.caixa(pai, base + Vector3(0, 0, 1.33), Vector3(0.8, 0.85, 0.06), k.vidro(Color("5fb8f0"), 0.5), 0.02)
	k.caixa(pai, base + Vector3(0, 0.95, 1.6), Vector3(1.4, 0.08, 0.6), k.alianca(), 0.03)
	# telhado: ar-condicionado, caixa d'água, antena com luz piscante
	k.caixa(pai, base + Vector3(-1.0, 2.16, -0.4), Vector3(0.6, 0.35, 0.5), k.p("aco"), 0.04)
	k.cilindro(pai, base + Vector3(-1.0, 2.52, -0.4), 0.16, 0.02, k.p("aco_escuro"), 12)
	k.caixa(pai, base + Vector3(-0.2, 2.16, -0.6), Vector3(0.6, 0.35, 0.5), k.p("aco"), 0.04)
	k.cilindro(pai, base + Vector3(1.1, 2.16, -0.5), 0.35, 0.6, k.p("branco", 0.5), 14)
	k.antena(pai, base + Vector3(1.3, 2.16, 0.7), 1.2)
	k.bandeira(pai, Vector3(-1.4, 0.05, 2.0), 2.4, k.cor_alianca)
	# pátio
	k.veiculo(pai, Vector3(1.9, 0.08, 0.2), 90, Color("6e8d52"))
	k.pessoa(pai, Vector3(0.6, 0.05, 1.9), k.cor_alianca)
	k.pessoa(pai, Vector3(-0.7, 0.05, 1.8), Color("e8833a"))
	k.arvore(pai, Vector3(-2.2, 0.05, 0.9), 1.0)
	k.arvore(pai, Vector3(-2.2, 0.05, -2.0), 0.9)
	return 3.9

# ---- faixa 3: Torre de concreto, heliponto no teto e letreiro luminoso
func _f3(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	k.caixa(pai, Vector3(1.4, 0.06, 0.8), Vector3(1.4, 0.03, 3.4), k.p("asfalto", 0.9), 0.0)
	var pod := Vector3(-0.3, 0.05, -0.3)
	k.caixa(pai, pod, Vector3(4.0, 1.1, 3.4), k.p("concreto_escuro", 0.85), 0.08)
	# portões de garagem
	for z in [-0.8, 0.4]:
		k.caixa(pai, pod + Vector3(2.0, 0.0, z), Vector3(0.06, 0.8, 0.9), k.p("aco"), 0.02)
		for y in 4:
			k.caixa(pai, pod + Vector3(2.03, 0.1 + y * 0.18, z), Vector3(0.03, 0.04, 0.86), k.p("aco_escuro"), 0.0)
	k.caixa(pai, pod + Vector3(0, 1.02, 0), Vector3(4.1, 0.14, 3.5), k.alianca(), 0.04)
	k.caixa(pai, pod + Vector3(0, 1.1, 0), Vector3(3.85, 0.1, 3.25), k.p("concreto", 0.85), 0.03)
	# torre
	var t0 := pod + Vector3(-0.3, 1.22, -0.2)
	var tam := Vector3(2.9, 3.6, 2.6)
	k.caixa(pai, t0, tam, k.p("concreto", 0.8), 0.1)
	for a in 4:
		var y := t0.y + 0.25 + a * 0.85
		k.caixa(pai, Vector3(t0.x, y, t0.z + 1.3), Vector3(2.5, 0.5, 0.06), k.vidro(Color("4aa8e6"), 0.55), 0.01)
		k.caixa(pai, Vector3(t0.x + 1.45, y, t0.z), Vector3(0.06, 0.5, 2.2), k.vidro(Color("4aa8e6"), 0.55), 0.01)
	for i in 5:
		k.caixa(pai, Vector3(t0.x - 1.2 + i * 0.6, t0.y, t0.z + 1.34), Vector3(0.12, 3.6, 0.1), k.p("concreto", 0.8), 0.02)
	# letreiro luminoso
	k.caixa(pai, Vector3(t0.x, t0.y + 3.0, t0.z + 1.36), Vector3(1.5, 0.48, 0.1), k.p("aco_escuro"), 0.03)
	k.caixa(pai, Vector3(t0.x, t0.y + 3.05, t0.z + 1.42), Vector3(1.36, 0.38, 0.03), k.luz(k.cor_alianca, 2.2), 0.0)
	var l := Label3D.new()
	l.text = "QG"; l.font = k.fonte; l.font_size = 96; l.pixel_size = 0.004
	l.modulate = Color.WHITE; l.outline_size = 0; l.shaded = false
	l.position = Vector3(t0.x, t0.y + 3.24, t0.z + 1.45)
	pai.add_child(l)
	# heliponto
	var top := t0.y + tam.y
	k.caixa(pai, Vector3(t0.x, top, t0.z), Vector3(3.0, 0.1, 2.7), k.p("concreto_escuro"), 0.03)
	k.cilindro(pai, Vector3(t0.x, top + 0.1, t0.z), 1.15, 0.08, k.p("asfalto", 0.8), 24)
	k.toro(pai, Vector3(t0.x, top + 0.19, t0.z), 0.95, 0.04, k.p("amarelo", 0.5))
	k.caixa(pai, Vector3(t0.x - 0.25, top + 0.18, t0.z), Vector3(0.1, 0.02, 0.8), k.p("branco"), 0.0)
	k.caixa(pai, Vector3(t0.x + 0.25, top + 0.18, t0.z), Vector3(0.1, 0.02, 0.8), k.p("branco"), 0.0)
	k.caixa(pai, Vector3(t0.x, top + 0.18, t0.z), Vector3(0.5, 0.02, 0.1), k.p("branco"), 0.0)
	for i in 8:
		var a := i * TAU / 8
		k.esfera(pai, Vector3(t0.x + cos(a) * 1.12, top + 0.2, t0.z + sin(a) * 1.12), 0.05, k.luz(Color("7dff7a"), 4.0))
	k.antena(pai, Vector3(t0.x - 1.3, top + 0.1, t0.z - 1.15), 1.3)
	k.antena(pai, Vector3(t0.x + 1.3, top + 0.1, t0.z - 1.15), 0.9)
	k.bandeira(pai, Vector3(0.6, 1.17, 1.25), 1.6, k.cor_alianca)
	k.veiculo(pai, Vector3(1.45, 0.08, 1.4), 180, Color("3d4f6b"), "caminhao")
	k.pessoa(pai, Vector3(-1.0, 0.05, 2.0), k.cor_alianca)
	k.pessoa(pai, Vector3(0.4, 0.05, 2.1), Color("2d3a4f"))
	k.arvore(pai, Vector3(-2.2, 0.05, 2.0))
	return top + 0.6

# ---- faixa 4: Torre de vidro e aço, fachada espelhada e jardim no teto
func _f4(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var pod := Vector3(-0.2, 0.05, -0.3)
	k.caixa(pai, pod, Vector3(4.2, 0.9, 3.6), k.p("concreto", 0.7), 0.08)
	k.caixa(pai, pod + Vector3(0, 0.0, 1.81), Vector3(2.4, 0.75, 0.05), k.vidro(Color("8fdcff"), 0.5), 0.01)
	k.caixa(pai, pod + Vector3(0, 0.9, 0), Vector3(4.3, 0.1, 3.7), k.p("aco", 0.35, 0.7), 0.03)
	var t0 := pod + Vector3(-0.2, 1.0, -0.2)
	var tam := Vector3(2.9, 5.2, 2.6)
	k.caixa(pai, t0, tam, k.vidro(Color("5cc4ff"), 0.75), 0.04)
	var aco = k.mat(Color("dfe7f2"), 0.3, 0.8)
	for i in 7:
		k.caixa(pai, Vector3(t0.x - 1.45 + i * (2.9 / 6.0), t0.y, t0.z + 1.31), Vector3(0.07, tam.y, 0.05), aco, 0.0)
	for i in 6:
		k.caixa(pai, Vector3(t0.x + 1.46, t0.y, t0.z - 1.3 + i * (2.6 / 5.0)), Vector3(0.05, tam.y, 0.07), aco, 0.0)
	for a in 7:
		k.caixa(pai, t0 + Vector3(0, a * 0.866, 0), Vector3(2.98, 0.07, 2.68), aco, 0.0)
	# coroa da aliança e jardim no teto
	var top := t0.y + tam.y
	k.caixa(pai, Vector3(t0.x, top - 0.05, t0.z), Vector3(3.05, 0.35, 2.75), k.alianca(0.4), 0.05)
	k.caixa(pai, Vector3(t0.x, top + 0.3, t0.z), Vector3(2.6, 0.15, 2.3), k.p("grama", 0.9), 0.04)
	for pos in [Vector3(-0.8, 0, -0.6), Vector3(0.7, 0, -0.7), Vector3(-0.6, 0, 0.7), Vector3(0.8, 0, 0.6)]:
		k.arvore(pai, Vector3(t0.x, top + 0.45, t0.z) + pos, 0.75)
	k.caixa(pai, Vector3(t0.x + 0.1, top + 0.45, t0.z), Vector3(0.7, 0.12, 0.25), k.p("madeira"), 0.03)
	# praça
	k.bandeira(pai, Vector3(1.9, 0.05, 1.9), 2.6, k.cor_alianca)
	k.bandeira(pai, Vector3(-2.3, 0.05, 1.9), 2.6, k.cor_alianca)
	for x in [-1.6, 1.2]:
		k.caixa(pai, Vector3(x, 0.05, 2.15), Vector3(0.9, 0.3, 0.5), k.p("concreto_escuro"), 0.06)
		k.arvore(pai, Vector3(x, 0.35, 2.15), 0.7)
	k.pessoa(pai, Vector3(0.0, 0.05, 2.0), Color("2d3a4f"))
	k.pessoa(pai, Vector3(0.45, 0.05, 2.25), k.cor_alianca)
	k.veiculo(pai, Vector3(2.15, 0.08, -0.3), 90, Color("f4f6fa"))
	return top + 1.3

# ---- faixa 5: Complexo com anel de painéis solares e parabólica giratória
func _f5(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var c := Vector3(-0.15, 0.05, -0.15)
	k.cilindro(pai, c, 2.35, 0.7, k.p("painel", 0.5), 8)
	k.cilindro(pai, c + Vector3(0, 0.55, 0), 2.37, 0.08, k.luz(k.PALETA["neon"], 2.5), 8)
	k.cilindro(pai, c + Vector3(0, 0.7, 0), 2.3, 0.06, k.alianca(), 8)
	for i in 12:
		var a := i * TAU / 12 + PI / 12
		var pos := c + Vector3(cos(a), 0, sin(a)) * 1.85 + Vector3(0, 0.76, 0)
		k.painel_solar(pai, pos, -rad_to_deg(a) - 90, 0.62)
	# torre octogonal: núcleo de vidro e lajes brancas
	var base_t := c + Vector3(0, 0.76, 0)
	var alt := 5.6
	k.cilindro(pai, base_t, 1.1, alt, k.vidro(Color("5cc4ff"), 0.7), 8)
	for a in 7:
		k.cilindro(pai, base_t + Vector3(0, a * 0.9 - 0.04, 0), 1.2, 0.14, k.p("painel", 0.45), 8)
	# tubos brilhantes
	for i in 3:
		var a := i * TAU / 3 + 0.4
		var pos := base_t + Vector3(cos(a), 0, sin(a)) * 1.24
		k.cilindro(pai, pos, 0.06, alt, k.luz(k.PALETA["neon"], 3.0), 8)
	# topo: parabólica
	var top := base_t.y + alt
	k.cilindro(pai, Vector3(c.x, top, c.z), 0.85, 0.3, k.alianca(0.4), 8)
	var prato_g = k.grupo(pai, Vector3(c.x, top + 0.3, c.z), 35)
	k.cilindro(prato_g, Vector3.ZERO, 0.12, 0.45, k.p("aco", 0.4, 0.6), 8)
	var inclina = k.grupo(prato_g, Vector3(0, 0.55, 0))
	inclina.rotation_degrees.x = 55
	k.cilindro(inclina, Vector3(0, 0.0, 0), 0.16, 0.3, k.p("aco", 0.45), 24, 0.75)
	k.cilindro(inclina, Vector3(0, 0.29, 0), 0.68, 0.03, k.mat(Color("5d6b82"), 0.5), 24)
	k.toro(inclina, Vector3(0, 0.3, 0), 0.74, 0.04, k.alianca())
	k.cilindro(inclina, Vector3(0, 0.1, 0), 0.03, 0.75, k.p("aco_escuro"), 6)
	k.esfera(inclina, Vector3(0, 0.88, 0), 0.08, k.luz(k.PALETA["neon"], 4.0))
	# baterias
	for pos in [Vector3(-2.05, 0.05, 2.05), Vector3(2.05, 0.05, -2.05)]:
		k.caixa(pai, pos, Vector3(0.7, 0.75, 0.7), k.mat(Color("ff8a2a"), 0.5), 0.08)
		k.caixa(pai, pos + Vector3(0, 0.3, 0), Vector3(0.74, 0.1, 0.74), k.luz(k.PALETA["neon"], 1.8), 0.03)
	# drones
	k.drone(pai, Vector3(1.8, 3.4, 1.4), Color("f4f6fa"))
	k.drone(pai, Vector3(-1.9, 4.6, 1.0), k.cor_alianca)
	k.drone(pai, Vector3(1.3, 6.2, -1.6), Color("f4f6fa"))
	k.pessoa(pai, Vector3(1.6, 0.05, 2.2), Color("2d3a4f"))
	k.pessoa(pai, Vector3(-1.8, 0.05, 2.2), k.cor_alianca)
	return top + 1.9

# ---- faixa 6: Arranha-céu de elite, feixe de luz no topo e brilho dourado
func _f6(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.mat(k.cor_alianca.darkened(0.55), 0.35, 0.2))
	k.toro(pai, Vector3(0, 0.16, 0), 2.45, 0.05, k.ouro())
	# campo de energia na base
	k.toro(pai, Vector3(0, 0.12, 0), 2.75, 0.06, k.luz(k.PALETA["neon"], 3.5))
	k.cilindro(pai, Vector3(0, 0.1, 0), 2.75, 0.45, k.feixe(k.PALETA["neon"], 0.12, 1.0), 48)
	k.caixa(pai, Vector3(0, 0.05, 0), Vector3(4.0, 0.4, 4.0), k.mat(Color("f3f0ea"), 0.3), 0.08)
	k.caixa(pai, Vector3(0, 0.45, 0), Vector3(4.06, 0.06, 4.06), k.ouro(), 0.02)
	var y := 0.51
	var blocos := [Vector3(3.0, 3.1, 3.0), Vector3(2.4, 2.4, 2.4), Vector3(1.8, 1.9, 1.8)]
	var vid = k.vidro(Color("234a8f"), 0.85)
	for i in blocos.size():
		var t: Vector3 = blocos[i]
		k.caixa(pai, Vector3(0, y, 0), t, vid, 0.05)
		# janelas acesas nas duas faces visíveis
		k.luzes_fachada(pai, Vector3(0, 0, t.z * 0.5), Vector3.BACK, t.x - 0.4, y + 0.1, y + t.y - 0.2, Vector2(0.3, 0.42), Color("ffd98a"), 0.45, 11 + i)
		k.luzes_fachada(pai, Vector3(t.x * 0.5, 0, 0), Vector3.RIGHT, t.z - 0.4, y + 0.1, y + t.y - 0.2, Vector2(0.3, 0.42), Color("ffd98a"), 0.45, 21 + i)
		# neon nas quinas (cor da aliança)
		for sx in [-1, 1]:
			for sz in [-1, 1]:
				k.caixa(pai, Vector3(sx * t.x * 0.5, y, sz * t.z * 0.5), Vector3(0.09, t.y, 0.09), k.luz(k.cor_alianca, 0.9), 0.02)
		y += t.y
		# friso dourado em cada recuo
		k.caixa(pai, Vector3(0, y - 0.04, 0), Vector3(t.x + 0.16, 0.2, t.z + 0.16), k.ouro(), 0.04)
	# coroa, agulha e feixe
	k.cilindro(pai, Vector3(0, y + 0.16, 0), 0.6, 0.35, k.alianca(0.4), 8)
	k.cone(pai, Vector3(0, y + 0.5, 0), 0.4, 1.5, k.ouro(), 8)
	k.esfera(pai, Vector3(0, y + 2.05, 0), 0.14, k.luz(Color("ffffff"), 6.0))
	k.cilindro(pai, Vector3(0, y + 2.1, 0), 0.2, 7.0, k.feixe(Color("9ff4ff"), 0.1, 1.0), 16, 0.45)
	k.cilindro(pai, Vector3(0, y + 2.1, 0), 0.07, 7.0, k.feixe(Color("ffffff"), 0.2, 1.2), 12, 0.15)
	# holograma: anel flutuando e emblema
	k.toro(pai, Vector3(0, 4.6, 0), 2.05, 0.05, k.feixe(k.PALETA["neon"], 0.7, 2.0))
	k.toro(pai, Vector3(0, 4.75, 0), 1.95, 0.02, k.feixe(k.PALETA["neon"], 0.5, 2.0))
	var holo = k.grupo(pai, Vector3(2.15, 1.6, 2.15), 45)
	var hex := CylinderMesh.new()
	hex.top_radius = 0.45; hex.bottom_radius = 0.45; hex.height = 0.02; hex.radial_segments = 6
	var mh := MeshInstance3D.new()
	mh.mesh = hex; mh.material_override = k.feixe(k.cor_alianca, 0.55, 2.2)
	mh.rotation_degrees = Vector3(90, 0, 0)
	holo.add_child(mh)
	k.cilindro(pai, Vector3(2.15, 0.45, 2.15), 0.18, 0.12, k.ouro(), 12)
	k.cilindro(pai, Vector3(2.15, 0.57, 2.15), 0.12, 0.7, k.feixe(k.cor_alianca, 0.25, 1.5), 12, 0.42)
	k.bandeira(pai, Vector3(-1.8, 0.51, 1.8), 2.2, k.cor_alianca)
	k.pessoa(pai, Vector3(0.6, 0.51, 1.75), Color("1d2a44"))
	k.pessoa(pai, Vector3(-0.4, 0.51, 1.8), k.cor_alianca)
	return y + 2.9
