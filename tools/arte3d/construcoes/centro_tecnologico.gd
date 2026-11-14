extends RefCounted
## Centro tecnológico (15º prédio, sessão 1.6). Assinatura: branco, grafite e verde-circuito;
## telas e anéis de pesquisa. A aliança aparece em bandeira, faixa, telhado e neon.
## Frente = +Z, lado visível = +X.

const LOTE := 5.4
const GRAFITE := Color("2d3442")
const CIRCUITO := Color("4fe08a")

func construir(k, pai: Node3D, faixa: int) -> float:
	match faixa:
		1: return _f1(k, pai)
		2: return _f2(k, pai)
		3: return _f3(k, pai)
		4: return _f4(k, pai)
		5: return _f5(k, pai)
		_: return _f6(k, pai)

## Tela vertical virada para +Z (ou +X com lado=true) com linhas de código acesas.
func _tela(k, pai: Node3D, pos: Vector3, larg: float, alt: float, cor: Color, lado := false, semente := 3) -> void:
	var t := Vector3(0.05, alt, larg) if lado else Vector3(larg, alt, 0.05)
	k.caixa(pai, pos, t, k.mat(Color("141a24"), 0.4), 0.02)
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var linhas := int(alt / 0.14) - 1
	for i in linhas:
		var w := larg * rng.randf_range(0.3, 0.8)
		var y := pos.y + 0.1 + i * 0.14
		var off := (larg - w) * 0.5 - larg * 0.08
		if lado:
			k.caixa(pai, Vector3(pos.x + 0.03, y, pos.z - off), Vector3(0.02, 0.05, w), k.luz(cor, 1.0), 0.0)
		else:
			k.caixa(pai, Vector3(pos.x - off, y, pos.z + 0.03), Vector3(w, 0.05, 0.02), k.luz(cor, 1.0), 0.0)

## Rack de servidores com luzes na frente (+Z).
func _rack(k, pai: Node3D, pos: Vector3, alt := 1.0) -> void:
	k.caixa(pai, pos, Vector3(0.5, alt, 0.45), k.mat(GRAFITE, 0.45), 0.03)
	for i in int(alt / 0.16):
		k.caixa(pai, pos + Vector3(-0.1, 0.1 + i * 0.16, 0.23), Vector3(0.18, 0.04, 0.02), k.luz(CIRCUITO if i % 3 else k.PALETA["neon"], 1.0), 0.0)

# ---- faixa 1: contêiner com antena e bancada
func _f1(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("terra", 0.95))
	k.conteiner(pai, Vector3(-0.5, 0.05, -0.6), 0, Color("e9edf2"), true)
	k.caixa(pai, Vector3(-0.5, 0.95, -0.6), Vector3(2.45, 0.1, 1.05), k.alianca(), 0.03)
	# antena treliçada com parabólica pequena
	var an := Vector3(-1.4, 1.05, -0.9)
	k.antena(pai, an, 1.6, Color("ff3b30"))
	var prato = k.grupo(pai, an + Vector3(0.0, 1.0, 0.1))
	prato.rotation_degrees.x = 60
	k.cilindro(prato, Vector3.ZERO, 0.32, 0.03, k.p("branco", 0.5), 16)
	# bancada externa com notebook e tela
	k.caixa(pai, Vector3(1.2, 0.05, 0.9), Vector3(1.6, 0.75, 0.7), k.p("madeira"), 0.03)
	k.caixa(pai, Vector3(0.9, 0.8, 0.95), Vector3(0.45, 0.03, 0.32), k.mat(GRAFITE, 0.4), 0.01)
	var tampa = k.grupo(pai, Vector3(0.9, 0.82, 0.8))
	tampa.rotation_degrees.x = -15
	k.caixa(tampa, Vector3.ZERO, Vector3(0.45, 0.3, 0.02), k.luz(k.PALETA["neon"], 0.9), 0.01)
	_tela(k, pai, Vector3(1.55, 0.8, 0.75), 0.6, 0.45, CIRCUITO)
	# gerador e cabos
	k.caixa(pai, Vector3(1.6, 0.05, -1.3), Vector3(0.8, 0.55, 0.55), k.mat(Color("ff8a2a"), 0.6), 0.05)
	k.caixa(pai, Vector3(0.7, 0.05, -1.3), Vector3(1.0, 0.04, 0.06), k.p("aco_escuro"), 0.0)
	k.bandeira(pai, Vector3(-2.15, 0.05, 1.9), 2.4, k.cor_alianca)
	k.pessoa(pai, Vector3(1.2, 0.05, 1.6), Color("f4f6fa"))
	k.caixa(pai, Vector3(-2.0, 0.05, -2.0), Vector3(0.5, 0.5, 0.5), k.p("madeira"), 0.04)
	return 2.9

# ---- faixa 2: laboratório pré-fabricado com painel solar
func _f2(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var b := Vector3(-0.3, 0.05, -0.3)
	var t := Vector3(3.6, 1.9, 2.6)
	k.caixa(pai, b, t, k.p("painel", 0.55), 0.08)
	for i in 7:
		k.caixa(pai, Vector3(b.x - 1.35 + i * 0.45, b.y, b.z + 1.31), Vector3(0.04, 1.9, 0.02), k.p("concreto_escuro"), 0.0)
	k.caixa(pai, b + Vector3(0, 0.0, 0), Vector3(3.66, 0.3, 2.66), k.mat(GRAFITE, 0.6), 0.04)
	k.caixa(pai, b + Vector3(0, 1.75, 0), Vector3(3.7, 0.18, 2.7), k.alianca(), 0.04)
	var jan = k.vidro(Color("8fd8ff"), 0.4)
	k.janelas(pai, b + Vector3(0, 0, 1.3), Vector3.BACK, 3.0, b.y + 0.45, 1, 1.1, 4, jan, k.mat(CIRCUITO, 0.5), Vector2(0.5, 0.75))
	k.janelas(pai, b + Vector3(1.8, 0, 0), Vector3.RIGHT, 2.0, b.y + 0.45, 1, 1.1, 2, jan, k.mat(CIRCUITO, 0.5), Vector2(0.6, 0.75))
	# painéis solares no telhado
	for i in 3:
		k.painel_solar(pai, b + Vector3(-1.1 + i * 1.05, 1.95, -0.3), 0, 0.85)
	k.antena(pai, b + Vector3(1.5, 1.95, 0.9), 1.2)
	# tanque de nitrogênio e bancada externa
	k.cilindro(pai, Vector3(1.95, 0.05, 1.6), 0.28, 1.1, k.p("branco", 0.4), 14)
	k.cone(pai, Vector3(1.95, 1.15, 1.6), 0.28, 0.2, k.p("branco", 0.4), 14)
	k.caixa(pai, Vector3(1.95, 0.6, 1.89), Vector3(0.3, 0.12, 0.02), k.alianca(), 0.0)
	k.caixa(pai, Vector3(-1.3, 0.05, 1.7), Vector3(1.2, 0.7, 0.5), k.p("aco"), 0.03)
	_tela(k, pai, Vector3(-1.3, 0.75, 1.75), 0.7, 0.5, k.PALETA["neon"])
	k.bandeira(pai, Vector3(-2.25, 0.05, -1.9), 2.4, k.cor_alianca)
	k.pessoa(pai, Vector3(0.4, 0.05, 1.9), Color("f4f6fa"))
	k.pessoa(pai, Vector3(-0.3, 0.05, 2.1), k.cor_alianca)
	return 3.4

# ---- faixa 3: instituto de concreto com cúpula de observação
func _f3(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var b := Vector3(-0.3, 0.05, -0.3)
	k.caixa(pai, b, Vector3(4.0, 2.4, 3.2), k.p("concreto", 0.8), 0.1)
	# faixas de janelas horizontais
	for a in 2:
		var y := b.y + 0.4 + a * 1.0
		k.caixa(pai, Vector3(b.x, y, b.z + 1.6), Vector3(3.5, 0.55, 0.06), k.vidro(Color("4aa8e6"), 0.55), 0.01)
		k.caixa(pai, Vector3(b.x + 2.0, y, b.z), Vector3(0.06, 0.55, 2.7), k.vidro(Color("4aa8e6"), 0.55), 0.01)
	k.caixa(pai, b + Vector3(0, 2.3, 0), Vector3(4.1, 0.16, 3.3), k.alianca(), 0.04)
	k.caixa(pai, b + Vector3(0, 2.0, 1.62), Vector3(4.02, 0.08, 0.04), k.luz(CIRCUITO, 1.0), 0.0)
	# entrada com marquise
	k.caixa(pai, Vector3(b.x + 1.1, 0.05, b.z + 1.62), Vector3(0.9, 1.0, 0.06), k.vidro(Color("5fb8f0"), 0.5), 0.02)
	k.caixa(pai, Vector3(b.x + 1.1, 1.15, b.z + 1.9), Vector3(1.4, 0.08, 0.6), k.mat(GRAFITE, 0.5), 0.03)
	# observatório: tambor e cúpula com fresta
	var c := b + Vector3(-0.6, 2.46, -0.3)
	k.cilindro(pai, c, 1.15, 0.6, k.p("painel", 0.5), 20)
	k.cupula(pai, c + Vector3(0, 0.6, 0), 1.1, k.p("branco", 0.35), k.p("aco", 0.4, 0.5), 6)
	var fr = k.grupo(pai, c + Vector3(0, 0.6, 0), -35)
	k.caixa(fr, Vector3(0, 0.15, 0.7), Vector3(0.32, 0.9, 0.5), k.mat(GRAFITE, 0.4), 0.02)
	var tel = k.grupo(pai, c + Vector3(0, 1.05, 0), -35)
	tel.rotation_degrees.x = 40
	k.cilindro(tel, Vector3(0, 0, 0), 0.12, 0.9, k.p("aco", 0.4, 0.6), 10)
	# antenas e painéis no telhado livre
	k.antena(pai, b + Vector3(1.4, 2.46, -1.2), 1.3)
	k.painel_solar(pai, b + Vector3(1.2, 2.46, 0.4), 0, 0.8)
	k.poste(pai, Vector3(-2.2, 0.05, 2.1), 1.4)
	k.bandeira(pai, Vector3(-2.2, 0.05, -2.0), 2.8, k.cor_alianca)
	k.veiculo(pai, Vector3(2.2, 0.08, 1.9), 90, Color("f4f6fa"))
	k.pessoa(pai, Vector3(0.2, 0.05, 1.95), Color("f4f6fa"))
	k.pessoa(pai, Vector3(-0.6, 0.05, 2.2), k.cor_alianca)
	return c.y + 1.9

# ---- faixa 4: torre de vidro com laboratórios aparentes
func _f4(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var pod := Vector3(-0.2, 0.05, -0.2)
	k.caixa(pai, pod, Vector3(4.2, 0.8, 3.8), k.mat(GRAFITE, 0.5), 0.08)
	k.caixa(pai, pod + Vector3(0, 0.8, 0), Vector3(4.3, 0.1, 3.9), k.luz(CIRCUITO, 1.0), 0.02)
	var t0 := pod + Vector3(-0.2, 0.9, -0.2)
	var tam := Vector3(2.9, 5.0, 2.7)
	# andares de laboratório: laje branca, vidro claro e bancadas acesas aparentes
	for a in 5:
		var y := t0.y + a * 1.0
		k.caixa(pai, Vector3(t0.x, y, t0.z), Vector3(tam.x, 0.12, tam.z), k.p("painel", 0.45), 0.02)
		k.caixa(pai, Vector3(t0.x, y + 0.12, t0.z), Vector3(tam.x - 0.4, 0.88, tam.z - 0.4), k.vidro(Color("2b6fae"), 0.6), 0.02)
		for i in 3:
			# bancada com tela acesa à vista, entre o vidro e a borda da laje
			k.caixa(pai, Vector3(t0.x - 0.8 + i * 0.8, y + 0.12, t0.z + tam.z * 0.5 - 0.12), Vector3(0.5, 0.3, 0.16), k.p("branco", 0.5), 0.02)
			k.caixa(pai, Vector3(t0.x - 0.8 + i * 0.8, y + 0.45, t0.z + tam.z * 0.5 - 0.16), Vector3(0.4, 0.24, 0.03), k.luz(CIRCUITO if (a + i) % 2 else k.PALETA["neon"], 1.0), 0.0)
		k.caixa(pai, Vector3(t0.x + tam.x * 0.5 - 0.12, y + 0.12, t0.z), Vector3(0.16, 0.3, 1.6), k.p("branco", 0.5), 0.02)
		k.caixa(pai, Vector3(t0.x + tam.x * 0.5 - 0.16, y + 0.45, t0.z), Vector3(0.03, 0.24, 1.2), k.luz(CIRCUITO, 1.0), 0.0)
	# montantes de aço nas duas faces visíveis
	var aco = k.mat(Color("dfe7f2"), 0.3, 0.8)
	for i in 5:
		k.caixa(pai, Vector3(t0.x - tam.x * 0.5 + i * tam.x / 4.0, t0.y, t0.z + tam.z * 0.5), Vector3(0.06, tam.y, 0.06), aco, 0.0)
		k.caixa(pai, Vector3(t0.x + tam.x * 0.5, t0.y, t0.z - tam.z * 0.5 + i * tam.z / 4.0), Vector3(0.06, tam.y, 0.06), aco, 0.0)
	var top := t0.y + tam.y
	k.caixa(pai, Vector3(t0.x, top, t0.z), Vector3(tam.x + 0.12, 0.3, tam.z + 0.12), k.alianca(0.4), 0.05)
	# telhado: antena alta e caixas de ventilação
	k.antena(pai, Vector3(t0.x - 0.8, top + 0.3, t0.z - 0.7), 1.8)
	k.caixa(pai, Vector3(t0.x + 0.6, top + 0.3, t0.z - 0.4), Vector3(0.8, 0.5, 0.8), k.p("aco"), 0.04)
	k.cilindro(pai, Vector3(t0.x + 0.6, top + 0.8, t0.z - 0.4), 0.3, 0.03, k.p("aco_escuro"), 14)
	k.bandeira(pai, Vector3(1.95, 0.05, 1.95), 2.6, k.cor_alianca)
	k.pessoa(pai, Vector3(-0.4, 0.05, 2.15), Color("f4f6fa"))
	k.pessoa(pai, Vector3(0.4, 0.05, 2.25), k.cor_alianca)
	k.arvore(pai, Vector3(-2.2, 0.05, 2.0), 0.8)
	return top + 1.0

# ---- faixa 5: campus com servidores, drones e telas holográficas
func _f5(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	k.caixa(pai, Vector3(0, 0.05, 0), Vector3(4.4, 0.4, 4.2), k.p("painel", 0.5), 0.08)
	k.caixa(pai, Vector3(0, 0.37, 0), Vector3(4.45, 0.06, 4.25), k.luz(CIRCUITO, 1.0), 0.02)
	var y := 0.45
	# prédio principal em L: bloco alto e ala baixa de servidores
	k.caixa(pai, Vector3(-0.9, y, -0.8), Vector3(2.2, 4.4, 2.0), k.p("branco", 0.5), 0.08)
	for a in 5:
		k.caixa(pai, Vector3(-0.9, y + 0.35 + a * 0.85, 0.22), Vector3(1.9, 0.4, 0.05), k.vidro(Color("4aa8e6"), 0.6), 0.01)
		k.caixa(pai, Vector3(0.22, y + 0.35 + a * 0.85, -0.8), Vector3(0.05, 0.4, 1.7), k.vidro(Color("4aa8e6"), 0.6), 0.01)
	k.caixa(pai, Vector3(-0.9, y + 4.4, -0.8), Vector3(2.3, 0.22, 2.1), k.alianca(0.4), 0.04)
	# ala de servidores com racks à vista pela fachada de vidro
	var al := Vector3(1.0, y, 0.0)
	k.caixa(pai, al, Vector3(1.6, 1.3, 3.0), k.mat(GRAFITE, 0.5), 0.06)
	for i in 4:
		_rack(k, pai, Vector3(1.0 + 0.82, y + 0.1, -1.1 + i * 0.7) + Vector3(-0.3, 0, 0), 1.0)
	k.caixa(pai, al + Vector3(0, 1.3, 0), Vector3(1.7, 0.08, 3.1), k.luz(k.PALETA["neon"], 1.0), 0.02)
	for i in 3:
		k.caixa(pai, al + Vector3(0, 1.38, -0.9 + i * 0.9), Vector3(1.0, 0.3, 0.5), k.p("aco"), 0.03)
	# telas holográficas na frente (mistura normal, sem estourar)
	var holo = k.feixe(Color("3ef2ff"), 0.35, 1.0, false)
	for i in 2:
		var hp := Vector3(-1.6 + i * 1.1, y + 0.9, 1.55)
		k.caixa(pai, hp, Vector3(0.9, 0.6, 0.02), holo, 0.0)
		k.cilindro(pai, Vector3(hp.x, y, hp.z), 0.06, 0.9, k.mat(GRAFITE, 0.4), 8)
		for j in 3:
			k.caixa(pai, hp + Vector3(-0.25 + j * 0.25, 0.12, 0.02), Vector3(0.12, 0.15 + j * 0.12, 0.01), k.luz(CIRCUITO, 1.0), 0.0)
	# parabólica e drones
	var pr = k.grupo(pai, Vector3(-0.9, y + 4.62, -0.8), 35)
	var inc = k.grupo(pr, Vector3(0, 0.3, 0))
	inc.rotation_degrees.x = 50
	k.cilindro(pr, Vector3.ZERO, 0.1, 0.35, k.p("aco", 0.4, 0.6), 8)
	k.cilindro(inc, Vector3.ZERO, 0.6, 0.04, k.p("branco", 0.4), 20)
	k.toro(inc, Vector3(0, 0.03, 0), 0.62, 0.035, k.alianca())
	k.drone(pai, Vector3(1.8, 3.0, 1.6), Color("f4f6fa"))
	k.drone(pai, Vector3(-2.0, 5.2, 1.0), k.cor_alianca)
	k.drone(pai, Vector3(1.5, 4.4, -1.7), Color("f4f6fa"))
	k.pessoa(pai, Vector3(0.3, y, 1.9), Color("f4f6fa"))
	k.pessoa(pai, Vector3(-0.3, y, 2.1), k.cor_alianca)
	return y + 5.6

# ---- faixa 6: centro de elite com anel de pesquisa iluminado
func _f6(k, pai: Node3D) -> float:
	k.base_elite(pai, LOTE)
	k.caixa(pai, Vector3(0, 0.05, 0), Vector3(4.0, 0.4, 4.0), k.mat(Color("f3f0ea"), 0.3), 0.08)
	k.caixa(pai, Vector3(0, 0.45, 0), Vector3(4.06, 0.06, 4.06), k.ouro(), 0.02)
	var y := 0.51
	# torre de núcleo em três volumes que giram 15° cada (silhueta de "hélice")
	var blocos := [Vector3(2.4, 2.2, 2.4), Vector3(2.0, 2.0, 2.0), Vector3(1.6, 1.8, 1.6)]
	var vid = k.vidro(Color("234a8f"), 0.85)
	for i in blocos.size():
		var t: Vector3 = blocos[i]
		var g = k.grupo(pai, Vector3(0, y, 0), i * 15.0)
		k.caixa(g, Vector3.ZERO, t, vid, 0.05)
		k.luzes_fachada(g, Vector3(0, 0, t.z * 0.5), Vector3.BACK, t.x - 0.4, 0.1, t.y - 0.2, Vector2(0.3, 0.42), CIRCUITO, 0.4, 51 + i)
		k.luzes_fachada(g, Vector3(t.x * 0.5, 0, 0), Vector3.RIGHT, t.z - 0.4, 0.1, t.y - 0.2, Vector2(0.3, 0.42), CIRCUITO, 0.4, 61 + i)
		for sx in [-1, 1]:
			for sz in [-1, 1]:
				k.caixa(g, Vector3(sx * t.x * 0.5, 0, sz * t.z * 0.5), Vector3(0.08, t.y, 0.08), k.luz(k.cor_alianca, 0.9), 0.02)
		y += t.y
		k.caixa(pai, Vector3(0, y - 0.04, 0), Vector3(t.x * 0.9, 0.16, t.z * 0.9), k.ouro(), 0.04)
	# anel de pesquisa: toro largo inclinado em volta da torre, com suportes dourados
	var anel = k.grupo(pai, Vector3(0, 3.4, 0))
	anel.rotation_degrees = Vector3(14, 0, -10)
	k.toro(anel, Vector3.ZERO, 2.1, 0.1, k.p("branco", 0.3))
	k.toro(anel, Vector3.ZERO, 2.1, 0.045, k.luz(k.cor_alianca, 1.0))
	k.toro(anel, Vector3(0, 0.12, 0), 2.1, 0.03, k.luz(CIRCUITO, 1.0))
	for i in 4:
		var a := i * TAU / 4 + PI / 4
		var s = k.grupo(anel, Vector3(cos(a), 0, sin(a)) * 1.05, -rad_to_deg(a))
		k.caixa(s, Vector3(0, -0.04, 0), Vector3(2.0, 0.08, 0.08), k.ouro(), 0.02)
	# topo: esfera de dados e feixe
	k.cilindro(pai, Vector3(0, y, 0), 0.5, 0.25, k.alianca(0.4), 8)
	k.esfera(pai, Vector3(0, y + 0.75, 0), 0.5, k.feixe(k.PALETA["neon"], 0.3, 1.0, false))
	k.esfera(pai, Vector3(0, y + 0.75, 0), 0.22, k.luz(Color("ffffff"), 4.0))
	k.toro(pai, Vector3(0, y + 0.75, 0), 0.62, 0.03, k.ouro())
	k.cilindro(pai, Vector3(0, y + 1.25, 0), 0.12, 5.0, k.feixe(CIRCUITO, 0.18, 1.0), 12, 0.3)
	# holograma de circuito ao lado
	var h = k.grupo(pai, Vector3(1.8, 1.4, 1.8), 45)
	k.caixa(h, Vector3.ZERO, Vector3(1.0, 0.7, 0.02), k.feixe(CIRCUITO, 0.3, 1.0, false), 0.0)
	for j in 4:
		k.caixa(h, Vector3(-0.3 + j * 0.2, 0.1, 0.02), Vector3(0.08, 0.2 + j * 0.1, 0.01), k.luz(k.PALETA["neon"], 1.0), 0.0)
	k.cilindro(pai, Vector3(1.8, 0.45, 1.8), 0.18, 0.12, k.ouro(), 12)
	k.cilindro(pai, Vector3(1.8, 0.57, 1.8), 0.08, 0.8, k.mat(GRAFITE, 0.4), 8)
	k.bandeira(pai, Vector3(-1.85, 0.51, 1.85), 2.2, k.cor_alianca)
	k.pessoa(pai, Vector3(-0.6, 0.51, 1.9), Color("f4f6fa"))
	k.pessoa(pai, Vector3(0.5, 0.51, 1.95), k.cor_alianca)
	return y + 2.0
