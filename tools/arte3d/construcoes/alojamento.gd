extends RefCounted
## Alojamento: moradia das tropas e dos trabalhadores. Paleta quente (creme, coral,
## terracota) para não repetir o azul do Quartel-general; a aliança aparece em toldos,
## varandas e neon. Frente = +Z, lado visível = +X.

const LOTE := 5.4

func construir(k, pai: Node3D, faixa: int) -> float:
	match faixa:
		1: return _f1(k, pai)
		2: return _f2(k, pai)
		3: return _f3(k, pai)
		4: return _f4(k, pai)
		5: return _f5(k, pai)
		_: return _f6(k, pai)

func _varal(k, pai: Node3D, a: Vector3, b: Vector3) -> void:
	k.cilindro(pai, a, 0.03, 1.2, k.p("madeira"), 6)
	k.cilindro(pai, b, 0.03, 1.2, k.p("madeira"), 6)
	var cores := [k.PALETA["coral"], Color.WHITE, k.cor_alianca, k.PALETA["amarelo"]]
	for i in 4:
		var t := (i + 0.5) / 4.0
		k.caixa(pai, a.lerp(b, t) + Vector3(0, 0.82, 0), Vector3(0.22, 0.3, 0.02) if absf(b.x - a.x) > absf(b.z - a.z) else Vector3(0.02, 0.3, 0.22), k.mat(cores[i], 0.9), 0.0)

# ---- faixa 1: módulos de contêiner com janelas e toldo
func _f1(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("terra", 0.95))
	k.conteiner(pai, Vector3(-0.4, 0.05, -0.7), 0, k.PALETA["creme"].darkened(0.08))
	k.conteiner(pai, Vector3(-0.4, 0.05, 0.6), 0, k.PALETA["menta"].darkened(0.15), true)
	k.conteiner(pai, Vector3(-0.4, 1.05, -0.7), 0, k.PALETA["coral"].darkened(0.1))
	# janelas recortadas no contêiner de cima e do lado
	for x in [-1.1, -0.4, 0.3]:
		k.caixa(pai, Vector3(x, 1.4, -0.17), Vector3(0.4, 0.35, 0.04), k.vidro(Color("9fe0ff"), 0.3), 0.02)
	k.caixa(pai, Vector3(0.83, 0.4, 0.6), Vector3(0.04, 0.4, 0.5), k.vidro(Color("9fe0ff"), 0.3), 0.02)
	# toldos listrados
	k.toldo(pai, Vector3(-0.4, 1.0, 1.12), Vector3.BACK, 2.2, 0.7)
	k.toldo(pai, Vector3(0.84, 1.9, -0.7), Vector3.RIGHT, 0.9, 0.5, 4)
	# escada de acesso ao de cima
	for i in 5:
		k.caixa(pai, Vector3(1.15, 0.05 + i * 0.2, -0.2 - i * 0.22), Vector3(0.5, 0.08, 0.26), k.p("aco"), 0.01)
	# pátio: varal, banco, vasos, fogueira apagada
	_varal(k, pai, Vector3(1.4, 0.05, 0.2), Vector3(1.4, 0.05, 1.8))
	k.caixa(pai, Vector3(-0.6, 0.05, 2.0), Vector3(0.9, 0.2, 0.3), k.p("madeira"), 0.03)
	for x in [-2.1, -1.6]:
		k.cilindro(pai, Vector3(x, 0.05, 1.9), 0.18, 0.25, k.p("terracota", 0.8), 10)
		k.esfera(pai, Vector3(x, 0.4, 1.9), 0.2, k.p("folha", 0.85))
	k.caixa(pai, Vector3(-2.0, 0.05, -1.9), Vector3(0.5, 0.5, 0.5), k.p("madeira"), 0.04)
	k.pessoa(pai, Vector3(0.6, 0.05, 1.8), k.PALETA["coral"])
	k.pessoa(pai, Vector3(-0.2, 0.25, 2.0), Color("6e8d52"))
	return 2.6

# ---- faixa 2: bloco pré-fabricado de 3 andares com varandas coloridas
func _f2(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var b := Vector3(-0.3, 0.05, -0.4)
	var t := Vector3(3.4, 2.7, 2.2)
	k.caixa(pai, b, t, k.p("creme", 0.75), 0.08)
	k.caixa(pai, b + Vector3(0, t.y, 0), Vector3(3.55, 0.14, 2.35), k.p("terracota", 0.7), 0.04)
	var jan = k.vidro(Color("8fd8ff"), 0.4)
	var mold = k.p("branco", 0.6)
	k.janelas(pai, b + Vector3(0, 0, 1.1), Vector3.BACK, 3.0, b.y + 0.05, 3, 0.9, 3, jan, mold, Vector2(0.5, 0.5))
	k.janelas(pai, b + Vector3(1.7, 0, 0), Vector3.RIGHT, 1.8, b.y + 0.05, 3, 0.9, 2, jan, mold)
	# varandas coloridas (a do meio na cor da aliança)
	var cores := [k.PALETA["coral"], k.cor_alianca, k.PALETA["amarelo"]]
	for a in range(1, 3):
		for c in 3:
			var x := b.x - 1.0 + c * 1.0
			var y := b.y + a * 0.9
			var cor: Color = cores[(a + c) % 3]
			k.caixa(pai, Vector3(x, y, b.z + 1.1), Vector3(0.85, 0.08, 0.45), k.p("concreto"), 0.02)
			k.caixa(pai, Vector3(x, y + 0.08, b.z + 1.31), Vector3(0.85, 0.3, 0.04), k.mat(cor, 0.6), 0.01)
	# porta e marquise
	k.caixa(pai, b + Vector3(0, 0, 1.12), Vector3(0.6, 0.75, 0.05), k.mat(Color("7a4a2a"), 0.7), 0.02)
	k.toldo(pai, b + Vector3(0, 0.85, 1.12), Vector3.BACK, 1.0, 0.5, 4)
	# escada externa no lado
	k.caixa(pai, b + Vector3(2.0, 0, -0.5), Vector3(0.6, 2.7, 0.9), k.p("aco", 0.5), 0.04)
	for i in 3:
		k.caixa(pai, b + Vector3(2.31, 0.3 + i * 0.9, -0.5), Vector3(0.03, 0.4, 0.8), k.p("aco_escuro"), 0.0)
	# telhado: caixa d'água e antena com luz
	k.cilindro(pai, b + Vector3(-1.0, t.y + 0.14, -0.3), 0.32, 0.5, k.p("branco", 0.5), 14)
	k.antena(pai, b + Vector3(1.2, t.y + 0.14, -0.6), 0.9)
	_varal(k, pai, Vector3(-2.2, 0.05, 0.6), Vector3(-2.2, 0.05, 2.0))
	k.arvore(pai, Vector3(1.9, 0.05, 1.9))
	k.pessoa(pai, Vector3(0.6, 0.05, 1.6), k.cor_alianca)
	k.pessoa(pai, Vector3(-1.0, 0.05, 1.9), k.PALETA["coral"])
	return t.y + 1.2

# ---- faixa 3: prédio de concreto com garagem e antena de TV
func _f3(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	k.caixa(pai, Vector3(1.55, 0.06, 0.2), Vector3(1.1, 0.03, 4.2), k.p("asfalto", 0.9), 0.0)
	var b := Vector3(-0.5, 0.05, -0.4)
	var t := Vector3(3.2, 4.4, 2.6)
	# térreo de garagem em concreto escuro, andares em tijolo com faixas de concreto
	k.caixa(pai, b, Vector3(t.x, 1.0, t.z), k.p("concreto_escuro", 0.85), 0.08)
	k.caixa(pai, b + Vector3(0, 1.0, 0), Vector3(t.x, t.y - 1.0, t.z), k.p("tijolo", 0.85), 0.08)
	for a in 4:
		k.caixa(pai, b + Vector3(0, 1.0 + a * 0.85, 0), Vector3(t.x + 0.06, 0.1, t.z + 0.06), k.p("concreto"), 0.02)
	k.caixa(pai, b + Vector3(0, t.y - 0.1, 0), Vector3(t.x + 0.12, 0.3, t.z + 0.12), k.alianca(), 0.04)
	k.caixa(pai, b + Vector3(0, t.y, 0), Vector3(t.x - 0.1, 0.22, t.z - 0.1), k.p("concreto"), 0.03)
	var jan = k.vidro(Color("8fd8ff"), 0.45)
	var mold = k.p("branco", 0.6)
	k.janelas(pai, b + Vector3(0, 0, t.z * 0.5), Vector3.BACK, 2.8, b.y + 1.1, 4, 0.85, 4, jan, mold, Vector2(0.4, 0.45))
	k.janelas(pai, b + Vector3(t.x * 0.5, 0, 0), Vector3.RIGHT, 2.2, b.y + 1.1, 4, 0.85, 3, jan, mold, Vector2(0.4, 0.45))
	# portões de garagem no lado da rua
	for z in [-0.7, 0.4]:
		k.caixa(pai, b + Vector3(t.x * 0.5, 0.0, z), Vector3(0.06, 0.75, 0.85), k.p("aco"), 0.02)
		for y in 4:
			k.caixa(pai, b + Vector3(t.x * 0.5 + 0.03, 0.08 + y * 0.17, z), Vector3(0.03, 0.04, 0.8), k.p("aco_escuro"), 0.0)
	# entrada com toldo da aliança e letreiro
	k.caixa(pai, b + Vector3(-0.6, 0, t.z * 0.5), Vector3(0.7, 0.8, 0.06), k.vidro(Color("5fb8f0"), 0.5), 0.02)
	k.toldo(pai, b + Vector3(-0.6, 0.92, t.z * 0.5), Vector3.BACK, 1.3, 0.6, 5)
	# antena de TV espinha de peixe e parabólicas
	var ant := b + Vector3(0.8, t.y + 0.16, -0.6)
	k.cilindro(pai, ant, 0.03, 1.4, k.p("aco", 0.4, 0.6), 6)
	for i in 4:
		k.caixa(pai, ant + Vector3(0, 0.9 + i * 0.13, 0), Vector3(0.5 - i * 0.08, 0.025, 0.025), k.p("aco", 0.4, 0.6), 0.0)
	for pos in [Vector3(-1.1, 0, -0.7), Vector3(-0.4, 0, 0.6)]:
		var g = k.grupo(pai, b + Vector3(0, t.y + 0.16, 0) + pos, 30)
		var inc = k.grupo(g, Vector3(0, 0.25, 0))
		inc.rotation_degrees.x = 50
		k.cilindro(inc, Vector3.ZERO, 0.05, 0.12, k.p("branco", 0.5), 16, 0.3)
		k.cilindro(g, Vector3.ZERO, 0.03, 0.25, k.p("aco_escuro"), 6)
	k.cilindro(pai, b + Vector3(-1.0, t.y + 0.16, -0.6), 0.3, 0.5, k.p("branco", 0.5), 14)
	k.veiculo(pai, Vector3(1.6, 0.08, 1.5), 180, k.PALETA["coral"])
	k.arvore(pai, Vector3(-2.2, 0.05, 2.0))
	k.arvore(pai, Vector3(-2.2, 0.05, 1.1), 0.8)
	k.pessoa(pai, Vector3(0.3, 0.05, 1.9), k.cor_alianca)
	k.pessoa(pai, Vector3(-0.8, 0.05, 2.1), Color("2d3a4f"))
	return t.y + 1.6

# ---- faixa 4: residencial de vidro com jardim no terraço
func _f4(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var b := Vector3(-0.3, 0.05, -0.3)
	var t := Vector3(3.4, 5.0, 2.8)
	var aco = k.mat(Color("f2f4f7"), 0.35, 0.3)
	k.caixa(pai, b, t, k.vidro(Color("7fd8ff"), 0.7), 0.04)
	# lajes brancas com varandas de vidro e painéis de destaque
	for a in 6:
		var y := b.y + a * 0.9
		k.caixa(pai, Vector3(b.x, y - 0.06, b.z + 0.2), Vector3(t.x + 0.2, 0.12, t.z + 0.5), aco, 0.03)
		if a > 0 and a < 6:
			k.caixa(pai, Vector3(b.x, y + 0.06, b.z + t.z * 0.5 + 0.43), Vector3(t.x + 0.2, 0.32, 0.03), k.vidro(Color("bfefff"), 0.3), 0.0)
	for a in range(1, 6):
		var x := b.x + (-1.0 if a % 2 == 0 else 0.9)
		k.caixa(pai, Vector3(x, b.y + a * 0.9 - 0.9 + 0.06, b.z + t.z * 0.5 + 0.02), Vector3(0.7, 0.78, 0.05), k.mat(k.cor_alianca, 0.5) if a % 2 == 1 else k.p("coral", 0.6), 0.02)
	for i in 5:
		k.caixa(pai, Vector3(b.x + t.x * 0.5 + 0.02, b.y, b.z - 1.2 + i * 0.6), Vector3(0.05, t.y, 0.06), aco, 0.0)
	# terraço com jardim, pérgola e piscina pequena
	var top := b.y + t.y
	k.caixa(pai, Vector3(b.x, top - 0.06, b.z + 0.2), Vector3(t.x + 0.2, 0.18, t.z + 0.5), aco, 0.03)
	k.caixa(pai, Vector3(b.x - 0.6, top + 0.12, b.z), Vector3(2.0, 0.14, 2.4), k.p("grama", 0.9), 0.04)
	for pos in [Vector3(-1.3, 0, -0.8), Vector3(-1.3, 0, 0.6), Vector3(0.0, 0, -0.9)]:
		k.arvore(pai, Vector3(b.x, top + 0.26, b.z) + pos, 0.7)
	k.caixa(pai, Vector3(b.x + 1.0, top + 0.12, b.z + 0.4), Vector3(1.0, 0.1, 1.2), k.p("agua", 0.1, 0.2), 0.02)
	for x in [0.55, 1.45]:
		for z in [-0.7, 0.0]:
			k.cilindro(pai, Vector3(b.x + x, top + 0.12, b.z + z), 0.03, 0.7, k.p("madeira"), 6)
	k.caixa(pai, Vector3(b.x + 1.0, top + 0.82, b.z - 0.35), Vector3(1.1, 0.06, 0.9), k.mat(k.cor_alianca, 0.6), 0.02)
	# praça
	for x in [-1.8, 1.4]:
		k.caixa(pai, Vector3(x, 0.05, 2.2), Vector3(0.9, 0.3, 0.45), k.p("concreto_escuro"), 0.06)
		k.arvore(pai, Vector3(x, 0.35, 2.2), 0.7)
	k.pessoa(pai, Vector3(-0.3, 0.05, 2.1), k.cor_alianca)
	k.pessoa(pai, Vector3(0.3, 0.05, 2.3), k.PALETA["coral"])
	k.veiculo(pai, Vector3(2.15, 0.08, -0.4), 90, Color("ffffff"))
	return top + 1.3

# ---- faixa 5: torre residencial com painéis solares e elevador visível
func _f5(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var b := Vector3(-0.4, 0.05, -0.4)
	var t := Vector3(2.8, 6.6, 2.6)
	k.caixa(pai, b, t, k.p("painel", 0.5), 0.1)
	var jan = k.vidro(Color("6fd0ff"), 0.6)
	for a in 7:
		var y := b.y + 0.2 + a * 0.92
		k.caixa(pai, Vector3(b.x, y, b.z + t.z * 0.5 + 0.01), Vector3(t.x - 0.4, 0.55, 0.05), jan, 0.01)
		k.caixa(pai, Vector3(b.x + t.x * 0.5 + 0.01, y, b.z - 0.2), Vector3(0.05, 0.55, t.z - 0.8), jan, 0.01)
		k.caixa(pai, Vector3(b.x, y + 0.6, b.z + t.z * 0.5 + 0.03), Vector3(t.x - 0.3, 0.06, 0.04), k.luz(k.PALETA["neon"], 1.2), 0.0)
	# painéis solares na fachada lateral (brises) e no telhado
	for a in 6:
		var pl = k.grupo(pai, Vector3(b.x + t.x * 0.5 + 0.12, b.y + 0.85 + a * 0.92, b.z - 0.2))
		pl.rotation_degrees.z = -35
		k.caixa(pl, Vector3.ZERO, Vector3(0.35, 0.03, t.z - 0.8), k.mat(k.PALETA["solar"], 0.15, 0.4), 0.0)
	var top := b.y + t.y
	k.caixa(pai, Vector3(b.x, top, b.z), Vector3(t.x + 0.1, 0.15, t.z + 0.1), k.alianca(), 0.04)
	for i in 2:
		for j in 2:
			k.painel_solar(pai, Vector3(b.x - 0.6 + i * 1.1, top + 0.15, b.z - 0.5 + j * 1.0), 0, 0.9)
	# elevador de vidro externo, cabine acesa
	var e := Vector3(b.x - 0.6, b.y, b.z + t.z * 0.5 + 0.4)
	k.caixa(pai, e, Vector3(0.7, t.y + 0.5, 0.7), k.mat(Color("bfefff"), 0.05, 0.3, 0.0, 0.35), 0.03)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			k.caixa(pai, e + Vector3(sx * 0.33, 0, sz * 0.33), Vector3(0.05, t.y + 0.5, 0.05), k.p("aco", 0.4, 0.5), 0.0)
	k.caixa(pai, e + Vector3(0, 3.7, 0), Vector3(0.55, 0.7, 0.55), k.luz(k.PALETA["amarelo"], 1.0), 0.04)
	k.caixa(pai, e + Vector3(0, t.y + 0.5, 0), Vector3(0.8, 0.2, 0.8), k.alianca(), 0.03)
	# chão: baterias e drone de entrega
	k.caixa(pai, Vector3(1.9, 0.05, 1.9), Vector3(0.7, 0.7, 0.7), k.mat(Color("ff8a2a"), 0.5), 0.08)
	k.caixa(pai, Vector3(1.9, 0.35, 1.9), Vector3(0.74, 0.1, 0.74), k.luz(k.PALETA["neon"], 1.8), 0.03)
	k.drone(pai, Vector3(1.6, 4.4, 1.2), k.cor_alianca)
	k.drone(pai, Vector3(-2.0, 2.8, 1.6), Color("f4f6fa"))
	k.arvore(pai, Vector3(-2.2, 0.05, 2.1))
	k.pessoa(pai, Vector3(0.6, 0.05, 2.0), k.cor_alianca)
	k.pessoa(pai, Vector3(1.0, 0.05, 2.3), k.PALETA["coral"])
	return top + 1.4

# ---- faixa 6: torre de luxo com iluminação neon por andar
func _f6(k, pai: Node3D) -> float:
	k.base_elite(pai, LOTE)
	k.caixa(pai, Vector3(0, 0.05, 0), Vector3(3.8, 0.4, 3.8), k.mat(Color("f3f0ea"), 0.3), 0.08)
	k.caixa(pai, Vector3(0, 0.45, 0), Vector3(3.86, 0.06, 3.86), k.ouro(), 0.02)
	var y0 := 0.51
	var andares := 9
	var h := 0.85
	var vid = k.vidro(Color("2a3f7a"), 0.85)
	k.cilindro(pai, Vector3(0, y0, 0), 1.25, andares * h, vid, 8)
	# varanda contínua por andar com neon na cor da aliança
	for a in andares:
		var y := y0 + a * h
		var r := 1.55 - (0.15 if a % 3 == 2 else 0.0)
		k.cilindro(pai, Vector3(0, y + h - 0.1, 0), r, 0.1, k.mat(Color("f3f0ea"), 0.3), 8)
		k.cilindro(pai, Vector3(0, y + h - 0.24, 0), r + 0.05, 0.13, k.luz(k.cor_alianca, 1.1), 8)
		k.luzes_fachada(pai, Vector3(0, 0, 1.15), Vector3.BACK, 1.6, y + 0.1, y + h - 0.2, Vector2(0.32, 0.6), Color("ffd98a"), 0.5, 40 + a)
		k.luzes_fachada(pai, Vector3(1.15, 0, 0), Vector3.RIGHT, 1.6, y + 0.1, y + h - 0.2, Vector2(0.32, 0.6), Color("ffd98a"), 0.5, 60 + a)
	var top := y0 + andares * h
	# coroa dourada com piscina de borda infinita
	k.cilindro(pai, Vector3(0, top, 0), 1.6, 0.25, k.ouro(), 8)
	k.cilindro(pai, Vector3(0, top + 0.25, 0), 1.1, 0.06, k.luz(k.PALETA["agua"], 0.8), 8)
	k.cilindro(pai, Vector3(0, top + 0.25, 0), 0.25, 0.9, k.ouro(), 8, 0.1)
	k.esfera(pai, Vector3(0, top + 1.2, 0), 0.12, k.luz(k.cor_alianca, 1.5))
	# holograma de boas-vindas
	var holo = k.grupo(pai, Vector3(2.1, 1.5, 2.1), 45)
	var hex := CylinderMesh.new()
	hex.top_radius = 0.42; hex.bottom_radius = 0.42; hex.height = 0.02; hex.radial_segments = 6
	var mh := MeshInstance3D.new()
	mh.mesh = hex; mh.material_override = k.feixe(k.cor_alianca, 0.55, 2.2)
	mh.rotation_degrees = Vector3(90, 0, 0)
	holo.add_child(mh)
	k.cilindro(pai, Vector3(2.1, 0.45, 2.1), 0.18, 0.12, k.ouro(), 12)
	k.cilindro(pai, Vector3(2.1, 0.57, 2.1), 0.12, 0.6, k.feixe(k.cor_alianca, 0.25, 1.5), 12, 0.4)
	for pos in [Vector3(-1.6, 0.51, 1.6), Vector3(1.6, 0.51, -1.6), Vector3(-1.6, 0.51, -1.6)]:
		k.cilindro(pai, pos, 0.2, 0.25, k.ouro(), 10)
		k.arvore(pai, pos + Vector3(0, 0.25, 0), 0.6)
	k.pessoa(pai, Vector3(0.5, 0.51, 1.7), Color("1d2a44"))
	k.pessoa(pai, Vector3(-0.3, 0.51, 1.8), k.cor_alianca)
	return top + 1.5
