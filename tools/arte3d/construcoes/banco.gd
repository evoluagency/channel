extends RefCounted
## Banco da cidade (14º prédio, sessão 1.6). Assinatura: creme-mármore, verde-cédula e
## dourado (moeda e cofre). A aliança aparece em bandeira, faixa, toldo e neon.
## Frente = +Z, lado visível = +X.

const LOTE := 5.4
const VERDE := Color("1f8a5b")
const VERDE_ESC := Color("146246")
const MARMORE := Color("f3ede1")

func construir(k, pai: Node3D, faixa: int) -> float:
	match faixa:
		1: return _f1(k, pai)
		2: return _f2(k, pai)
		3: return _f3(k, pai)
		4: return _f4(k, pai)
		5: return _f5(k, pai)
		_: return _f6(k, pai)

## Moeda em pé virada para a frente (+Z): disco dourado com aro e marca.
func _moeda(k, pai: Node3D, pos: Vector3, raio: float, giro_y := 0.0) -> void:
	var g = k.grupo(pai, pos, giro_y)
	var d = k.cilindro(g, Vector3(0, 0, -0.04), raio, 0.08, k.ouro(), 20)
	d.rotation_degrees.x = 90
	d.position = Vector3.ZERO
	var aro = k.toro(g, Vector3.ZERO, raio * 0.82, raio * 0.06, k.mat(Color("ffd36a"), 0.3, 0.3))
	aro.rotation_degrees.x = 90
	k.caixa(g, Vector3(0, -raio * 0.45, 0.05), Vector3(raio * 0.22, raio * 0.9, 0.04), k.mat(Color("c98a10"), 0.4), 0.01)

## Porta de cofre redonda na face +Z (pos = centro da porta).
func _cofre_porta(k, pai: Node3D, pos: Vector3, raio: float, brilho := false) -> void:
	var g = k.grupo(pai, pos)
	var p = k.cilindro(g, Vector3.ZERO, raio, 0.12, k.p("aco", 0.35, 0.7), 20)
	p.rotation_degrees.x = 90
	p.position = Vector3.ZERO
	var aro = k.toro(g, Vector3(0, 0, 0.06), raio * 0.95, raio * 0.07, k.luz(k.cor_alianca, 1.0) if brilho else k.p("aco_escuro", 0.4, 0.6))
	aro.rotation_degrees.x = 90
	# roda de abrir: cubo e três raios
	var cubo = k.cilindro(g, Vector3.ZERO, raio * 0.16, 0.1, k.ouro() if brilho else k.p("aco_escuro"), 10)
	cubo.rotation_degrees.x = 90
	cubo.position = Vector3(0, 0, 0.1)
	for i in 3:
		var r = k.grupo(g, Vector3(0, 0, 0.12))
		r.rotation.z = i * TAU / 3
		k.caixa(r, Vector3(0, -raio * 0.55, 0), Vector3(raio * 0.08, raio * 1.1, 0.04), k.ouro() if brilho else k.p("aco_escuro"), 0.01)

# ---- faixa 1: contêiner com cofre e placa
func _f1(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("terra", 0.95))
	k.conteiner(pai, Vector3(-0.5, 0.05, -0.5), 0, VERDE, true)
	# cofre de aço ao lado, com a porta para a frente
	var cofre := Vector3(1.4, 0.05, 0.2)
	k.caixa(pai, cofre, Vector3(1.0, 1.1, 0.9), k.p("aco_escuro", 0.5, 0.4), 0.08)
	_cofre_porta(k, pai, cofre + Vector3(0, 0.55, 0.47), 0.36)
	# placa sobre dois postes, com a moeda
	for x in [-1.5, 0.5]:
		k.cilindro(pai, Vector3(x, 0.05, 1.05), 0.04, 1.9, k.p("madeira"), 6)
	k.caixa(pai, Vector3(-0.5, 1.45, 1.05), Vector3(2.3, 0.55, 0.08), k.p("creme", 0.8), 0.03)
	k.caixa(pai, Vector3(-0.5, 1.45, 1.1), Vector3(2.1, 0.12, 0.02), k.alianca(), 0.0)
	_moeda(k, pai, Vector3(-1.25, 1.72, 1.14), 0.24)
	# sacos de moeda e caixotes
	for p in [Vector3(1.9, 0.05, 1.3), Vector3(1.5, 0.05, 1.55), Vector3(2.15, 0.05, 1.75)]:
		k.esfera(pai, p + Vector3(0, 0.18, 0), 0.2, k.p("saco", 0.95), 0.9)
		k.esfera(pai, p + Vector3(0, 0.38, 0), 0.06, k.p("saco", 0.95))
	k.caixa(pai, Vector3(-2.1, 0.05, 1.8), Vector3(0.5, 0.5, 0.5), k.p("madeira"), 0.04)
	k.bandeira(pai, Vector3(-2.1, 0.05, -1.9), 2.5, k.cor_alianca)
	k.antena(pai, Vector3(-1.4, 1.05, -0.9), 0.8)
	k.pessoa(pai, Vector3(0.9, 0.05, 1.6), Color("2d3a4f"))
	return 2.6

# ---- faixa 2: agência pré-fabricada com caixa eletrônico
func _f2(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var b := Vector3(-0.3, 0.05, -0.4)
	var t := Vector3(3.6, 1.9, 2.6)
	k.caixa(pai, b, t, k.p("painel", 0.6), 0.08)
	# faixa verde-cédula na base e faixa da aliança no topo
	k.caixa(pai, b, Vector3(3.66, 0.35, 2.66), k.mat(VERDE, 0.6), 0.04)
	k.caixa(pai, b + Vector3(0, 1.78, 0), Vector3(3.7, 0.2, 2.7), k.alianca(), 0.04)
	k.caixa(pai, b + Vector3(0, 1.94, 0), Vector3(3.5, 0.1, 2.5), k.p("concreto", 0.8), 0.03)
	# vitrine e porta
	k.caixa(pai, b + Vector3(-0.6, 0.4, 1.31), Vector3(2.0, 1.1, 0.05), k.vidro(Color("8fdcff"), 0.45), 0.01)
	k.caixa(pai, b + Vector3(1.05, 0.35, 1.31), Vector3(0.75, 1.2, 0.06), k.vidro(Color("5fb8f0"), 0.5), 0.02)
	k.toldo(pai, b + Vector3(-0.6, 1.6, 1.3), Vector3.BACK, 2.1, 0.55)
	k.janelas(pai, b + Vector3(1.8, 0, 0), Vector3.RIGHT, 2.0, b.y + 0.55, 1, 1.1, 3, k.vidro(Color("8fd8ff"), 0.4), k.p("aco_escuro", 0.5))
	# caixa eletrônico encostado na lateral da frente
	var atm := Vector3(1.75, 0.05, 1.4)
	k.caixa(pai, atm, Vector3(0.55, 1.15, 0.45), k.mat(VERDE_ESC, 0.5), 0.05)
	k.caixa(pai, atm + Vector3(0, 0.62, 0.23), Vector3(0.38, 0.28, 0.02), k.luz(k.PALETA["neon"], 1.1), 0.0)
	k.caixa(pai, atm + Vector3(0, 0.38, 0.24), Vector3(0.3, 0.1, 0.04), k.p("aco_escuro"), 0.01)
	k.caixa(pai, atm + Vector3(0, 1.15, 0.0), Vector3(0.65, 0.06, 0.55), k.alianca(), 0.02)
	# moeda no telhado e equipamentos
	_moeda(k, pai, b + Vector3(-0.6, 2.55, 0.6), 0.45)
	k.caixa(pai, b + Vector3(-0.6, 2.04, 0.6), Vector3(0.5, 0.08, 0.3), k.p("aco_escuro"), 0.02)
	k.caixa(pai, b + Vector3(1.0, 2.04, -0.6), Vector3(0.6, 0.35, 0.5), k.p("aco"), 0.04)
	k.bandeira(pai, Vector3(-2.2, 0.05, 1.9), 2.4, k.cor_alianca)
	k.arvore(pai, Vector3(-2.2, 0.05, -1.9), 0.9)
	k.pessoa(pai, Vector3(1.75, 0.05, 2.05), k.cor_alianca)
	k.pessoa(pai, Vector3(1.3, 0.05, 2.35), Color("e8833a"))
	return 3.4

# ---- faixa 3: agência de concreto com colunas
func _f3(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var marmore = k.mat(MARMORE, 0.55)
	# escadaria de três degraus na frente
	for i in 3:
		k.caixa(pai, Vector3(0, 0.05 + i * 0.14, 0.75 - i * 0.22), Vector3(4.2 - i * 0.2, 0.14, 3.8 - i * 0.44), k.p("concreto", 0.8), 0.03)
	var y0 := 0.47
	var corpo := Vector3(0, y0, -0.55)
	k.caixa(pai, corpo, Vector3(3.6, 2.4, 2.3), k.p("concreto", 0.8), 0.08)
	# pórtico: seis colunas e entablamento
	for i in 6:
		var x := -1.6 + i * 0.64
		k.cilindro(pai, Vector3(x, y0, 1.05), 0.16, 2.3, marmore, 12)
		k.caixa(pai, Vector3(x, y0, 1.05), Vector3(0.42, 0.1, 0.42), marmore, 0.02)
		k.caixa(pai, Vector3(x, y0 + 2.2, 1.05), Vector3(0.42, 0.1, 0.42), marmore, 0.02)
	k.caixa(pai, Vector3(0, y0 + 2.3, 0.25), Vector3(3.9, 0.3, 2.0), marmore, 0.05)
	k.caixa(pai, Vector3(0, y0 + 2.42, 0.25), Vector3(3.95, 0.14, 2.05), k.alianca(), 0.03)
	# frontão em degraus com a moeda em relevo
	k.caixa(pai, Vector3(0, y0 + 2.6, 0.5), Vector3(3.4, 0.3, 1.4), marmore, 0.05)
	k.caixa(pai, Vector3(0, y0 + 2.9, 0.6), Vector3(2.2, 0.3, 1.1), marmore, 0.05)
	k.caixa(pai, Vector3(0, y0 + 3.2, 0.7), Vector3(1.0, 0.22, 0.8), marmore, 0.05)
	_moeda(k, pai, Vector3(0, y0 + 2.95, 1.17), 0.3)
	# porta de bronze e janelas altas
	k.caixa(pai, Vector3(0, y0, 0.62), Vector3(0.9, 1.6, 0.06), k.mat(Color("8a5a2b"), 0.5, 0.4), 0.02)
	k.janelas(pai, Vector3(1.8, 0, -0.55), Vector3.RIGHT, 1.9, y0 + 0.3, 2, 1.0, 3, k.vidro(Color("4aa8e6"), 0.55), k.p("concreto_escuro"), Vector2(0.38, 0.7))
	# lateral verde-cédula
	k.caixa(pai, Vector3(0, y0 + 2.4, -0.55), Vector3(3.62, 0.12, 2.32), k.mat(VERDE, 0.6), 0.02)
	k.poste(pai, Vector3(-2.1, 0.05, 2.0), 1.4)
	k.poste(pai, Vector3(2.0, 0.05, 2.0), 1.4)
	k.bandeira(pai, Vector3(-2.2, 0.05, -1.9), 2.8, k.cor_alianca)
	k.veiculo(pai, Vector3(2.15, 0.08, -0.6), 90, Color("2d3a4f"), "caminhao")
	k.pessoa(pai, Vector3(-0.6, 0.47, 1.6), Color("2d3a4f"))
	k.pessoa(pai, Vector3(0.8, 0.05, 2.25), k.cor_alianca)
	return y0 + 3.6

# ---- faixa 4: torre de vidro com letreiro
func _f4(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var pod := Vector3(-0.2, 0.05, -0.2)
	k.caixa(pai, pod, Vector3(4.2, 1.0, 3.8), k.mat(MARMORE, 0.5), 0.08)
	for i in 4:
		k.cilindro(pai, Vector3(-1.5 + i * 1.0, 0.05, 1.75), 0.12, 1.0, k.ouro(), 10)
	k.caixa(pai, pod + Vector3(0, 0, 1.91), Vector3(3.2, 0.85, 0.05), k.vidro(Color("8fdcff"), 0.5), 0.01)
	k.caixa(pai, pod + Vector3(0, 1.0, 0), Vector3(4.3, 0.12, 3.9), k.mat(VERDE, 0.4), 0.03)
	# torre de vidro verde com montantes
	var t0 := pod + Vector3(-0.3, 1.12, -0.3)
	var tam := Vector3(2.7, 5.0, 2.5)
	k.caixa(pai, t0, tam, k.vidro(Color("3fb98a"), 0.75), 0.04)
	var aco = k.mat(Color("dfe7f2"), 0.3, 0.8)
	for i in 6:
		k.caixa(pai, Vector3(t0.x - 1.35 + i * 0.54, t0.y, t0.z + 1.26), Vector3(0.06, tam.y, 0.05), aco, 0.0)
		k.caixa(pai, Vector3(t0.x + 1.36, t0.y, t0.z - 1.25 + i * 0.5), Vector3(0.05, tam.y, 0.06), aco, 0.0)
	for a in 6:
		k.caixa(pai, t0 + Vector3(0, a * 1.0, 0), Vector3(2.78, 0.07, 2.58), aco, 0.0)
	# letreiro no alto da fachada
	var ly := t0.y + tam.y - 0.75
	k.caixa(pai, Vector3(t0.x, ly, t0.z + 1.3), Vector3(2.2, 0.55, 0.1), k.p("aco_escuro"), 0.03)
	k.caixa(pai, Vector3(t0.x, ly + 0.05, t0.z + 1.36), Vector3(2.06, 0.45, 0.03), k.luz(VERDE, 1.1), 0.0)
	var l := Label3D.new()
	l.text = "BANCO"; l.font = k.fonte; l.font_size = 84; l.pixel_size = 0.004
	l.modulate = Color.WHITE; l.outline_size = 0; l.shaded = false
	l.position = Vector3(t0.x, ly + 0.27, t0.z + 1.39)
	pai.add_child(l)
	# coroa da aliança e moeda no topo
	var top := t0.y + tam.y
	k.caixa(pai, Vector3(t0.x, top - 0.05, t0.z), Vector3(2.85, 0.32, 2.65), k.alianca(0.4), 0.05)
	k.caixa(pai, Vector3(t0.x, top + 0.27, t0.z), Vector3(1.4, 0.2, 1.2), k.p("concreto", 0.7), 0.04)
	_moeda(k, pai, Vector3(t0.x, top + 1.05, t0.z), 0.55, 45)
	k.antena(pai, Vector3(t0.x - 1.1, top + 0.27, t0.z - 1.0), 1.1)
	k.bandeira(pai, Vector3(1.95, 0.05, 1.95), 2.6, k.cor_alianca)
	k.bandeira(pai, Vector3(-2.35, 0.05, 1.95), 2.6, k.cor_alianca)
	k.pessoa(pai, Vector3(0.2, 0.05, 2.2), Color("2d3a4f"))
	k.pessoa(pai, Vector3(-0.5, 0.05, 2.3), k.cor_alianca)
	k.veiculo(pai, Vector3(2.2, 0.08, -0.4), 90, Color("f4f6fa"))
	return top + 1.7

# ---- faixa 5: centro financeiro com painéis e drones
func _f5(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	k.caixa(pai, Vector3(0, 0.05, 0), Vector3(4.4, 0.5, 4.2), k.p("painel", 0.5), 0.08)
	k.caixa(pai, Vector3(0, 0.45, 0), Vector3(4.45, 0.08, 4.25), k.luz(k.PALETA["neon"], 1.1), 0.02)
	var y := 0.55
	var torres := [[Vector3(-1.0, y, -0.7), Vector3(1.8, 6.0, 1.8)], [Vector3(1.2, y, 0.3), Vector3(1.5, 4.2, 1.5)]]
	for tr in torres:
		var p: Vector3 = tr[0]
		var t: Vector3 = tr[1]
		k.caixa(pai, p, t, k.vidro(Color("2f9a78"), 0.8), 0.05)
		for a in int(t.y / 0.6):
			k.caixa(pai, p + Vector3(0, a * 0.6, 0), Vector3(t.x + 0.06, 0.06, t.z + 0.06), k.p("painel", 0.45), 0.0)
		k.caixa(pai, p + Vector3(0, t.y, 0), Vector3(t.x + 0.1, 0.22, t.z + 0.1), k.alianca(0.4), 0.04)
	# passarela entre as torres
	k.caixa(pai, Vector3(0.1, y + 3.0, -0.2), Vector3(0.7, 0.45, 0.6), k.vidro(Color("9fe0ff"), 0.4), 0.03)
	# painéis de cotação na frente da torre baixa (barras de gráfico acesas)
	var pn := Vector3(1.2, y + 1.2, 1.07)
	k.caixa(pai, pn, Vector3(1.3, 1.6, 0.06), k.mat(Color("16202e"), 0.4), 0.02)
	var alturas := [0.35, 0.55, 0.45, 0.8, 0.7, 1.1]
	for i in alturas.size():
		var cor: Color = Color("35e07a") if i != 2 else Color("ff5a4a")
		k.caixa(pai, pn + Vector3(-0.5 + i * 0.2, 0.15, 0.04), Vector3(0.12, alturas[i], 0.02), k.luz(cor, 1.0), 0.0)
	var pl := Vector3(-0.1, y + 2.0, -0.7)
	k.caixa(pai, pl, Vector3(0.06, 1.4, 1.4), k.mat(Color("16202e"), 0.4), 0.02)
	k.caixa(pai, pl + Vector3(0.04, 0.15, 0), Vector3(0.02, 1.1, 1.2), k.luz(k.PALETA["neon"], 0.9), 0.0)
	# telhado: painéis solares e moeda
	for i in 2:
		k.painel_solar(pai, Vector3(-1.4 + i * 0.8, y + 6.22, -0.7), 0, 0.6)
	_moeda(k, pai, Vector3(1.2, y + 4.42 + 0.7, 0.3), 0.45, 45)
	# drones levando malotes
	for d in [[Vector3(1.9, 3.6, 1.8), Color("f4f6fa")], [Vector3(-2.0, 5.0, 1.2), k.cor_alianca], [Vector3(2.0, 5.6, -1.6), Color("f4f6fa")]]:
		k.drone(pai, d[0], d[1])
		k.caixa(pai, d[0] + Vector3(0, -0.28, 0), Vector3(0.18, 0.16, 0.14), k.mat(VERDE, 0.6), 0.03)
	k.pessoa(pai, Vector3(-1.6, 0.55, 1.75), Color("2d3a4f"))
	k.pessoa(pai, Vector3(0.0, 0.55, 1.8), k.cor_alianca)
	return y + 6.6

# ---- faixa 6: banco de elite com cúpula dourada e cofre iluminado
func _f6(k, pai: Node3D) -> float:
	k.base_elite(pai, LOTE)
	var marmore = k.mat(MARMORE, 0.35)
	k.caixa(pai, Vector3(0, 0.05, 0), Vector3(4.0, 0.4, 4.0), marmore, 0.08)
	k.caixa(pai, Vector3(0, 0.45, 0), Vector3(4.06, 0.06, 4.06), k.ouro(), 0.02)
	var y := 0.51
	# tambor central de vidro escuro, colunata dourada em volta
	k.cilindro(pai, Vector3(0, y, 0), 1.35, 2.6, k.vidro(Color("234a8f"), 0.85), 12)
	k.luzes_fachada(pai, Vector3(0, 0, 1.25), Vector3.BACK, 1.6, y + 0.3, y + 2.4, Vector2(0.3, 0.42), Color("ffd98a"), 0.5, 41)
	k.luzes_fachada(pai, Vector3(1.25, 0, 0), Vector3.RIGHT, 1.6, y + 0.3, y + 2.4, Vector2(0.3, 0.42), Color("ffd98a"), 0.5, 43)
	for i in 10:
		var a := i * TAU / 10
		k.cilindro(pai, Vector3(cos(a) * 1.7, y, sin(a) * 1.7), 0.11, 2.6, marmore, 10)
		k.caixa(pai, Vector3(cos(a) * 1.7, y + 2.5, sin(a) * 1.7), Vector3(0.28, 0.1, 0.28), k.ouro(), 0.02)
	k.cilindro(pai, Vector3(0, y + 2.6, 0), 1.95, 0.3, marmore, 20)
	k.toro(pai, Vector3(0, y + 2.75, 0), 1.95, 0.06, k.ouro())
	k.cilindro(pai, Vector3(0, y + 2.9, 0), 1.85, 0.08, k.luz(k.cor_alianca, 1.0), 20)
	# cúpula dourada com lanterna
	var yc := y + 2.98
	k.cupula(pai, Vector3(0, yc, 0), 1.55, k.ouro(), k.mat(Color("fff3c4"), 0.3, 0.4), 8)
	k.cilindro(pai, Vector3(0, yc + 1.5, 0), 0.25, 0.4, k.alianca(0.4), 8)
	k.cone(pai, Vector3(0, yc + 1.9, 0), 0.22, 0.6, k.ouro(), 8)
	k.esfera(pai, Vector3(0, yc + 2.6, 0), 0.12, k.luz(Color("ffffff"), 6.0))
	# cofre iluminado na frente: pórtico e porta redonda com aro na cor da aliança
	var cf := Vector3(0, y, 1.85)
	k.caixa(pai, cf + Vector3(0, 0, -0.1), Vector3(1.7, 1.7, 0.3), k.p("aco_escuro", 0.4, 0.6), 0.06)
	_cofre_porta(k, pai, cf + Vector3(0, 0.85, 0.12), 0.62, true)
	k.cilindro(pai, cf + Vector3(0, 0.0, 0.35), 0.75, 0.02, k.feixe(k.cor_alianca, 0.35, 1.2, false), 24)
	# holograma de moedas girando ao lado
	for i in 3:
		_moeda(k, pai, Vector3(1.75 - i * 0.05, y + 0.7 + i * 0.55, 1.75), 0.22, 45 + i * 25)
	k.cilindro(pai, Vector3(1.75, 0.45, 1.75), 0.3, 0.1, k.ouro(), 12)
	k.cilindro(pai, Vector3(1.75, 0.55, 1.75), 0.3, 1.8, k.feixe(k.PALETA["neon"], 0.16, 1.0, false), 12, 0.2)
	k.bandeira(pai, Vector3(-1.85, 0.51, 1.85), 2.2, k.cor_alianca)
	k.pessoa(pai, Vector3(-0.9, 0.51, 1.9), Color("1d2a44"))
	k.pessoa(pai, Vector3(0.95, 0.51, 1.95), k.cor_alianca)
	return yc + 3.0
