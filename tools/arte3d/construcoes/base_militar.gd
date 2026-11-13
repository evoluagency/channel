extends RefCounted
## Base militar: treina e abriga tropas e heróis. Verde-oliva e cáqui com a bandeira e as
## faixas da aliança bem visíveis. Frente = +Z.

const LOTE := 5.4
const OLIVA := Color("5f7a3a")
const CAQUI := Color("c2b280")

func construir(k, pai: Node3D, faixa: int) -> float:
	match faixa:
		1: return _f1(k, pai)
		2: return _f2(k, pai)
		3: return _f3(k, pai)
		4: return _f4(k, pai)
		5: return _f5(k, pai)
		_: return _f6(k, pai)

func _soldados(k, pai: Node3D, pos: Vector3, linhas: int, colunas: int, cor: Color) -> void:
	for l in linhas:
		for c in colunas:
			k.pessoa(pai, pos + Vector3(c * 0.3, 0, l * 0.32), cor, 0.85)

func _sacos(k, pai: Node3D, pos: Vector3, rot: float, n: int, camadas := 2) -> void:
	var g = k.grupo(pai, pos, rot)
	for c in camadas:
		for i in n - c:
			k.caixa(g, Vector3((i - (n - c - 1) * 0.5) * 0.42, c * 0.22, 0), Vector3(0.42, 0.22, 0.28), k.p("saco", 0.95), 0.1)

func _hangar(k, pai: Node3D, pos: Vector3, rot: float, comp: float, raio: float, cor: Color) -> void:
	var g = k.grupo(pai, pos, rot)
	k.tunel(g, Vector3.ZERO, raio, comp, k.mat(cor, 0.6, 0.2), k.mat(cor.darkened(0.25), 0.6), 9, 5)
	k.caixa(g, Vector3(comp * 0.5 + 0.02, 0, 0), Vector3(0.04, raio * 0.85, raio * 1.4), k.mat(Color("3b3f48"), 0.6), 0.0)
	k.caixa(g, Vector3(comp * 0.5 + 0.04, raio * 0.75, 0), Vector3(0.04, 0.16, raio * 1.6), k.alianca(), 0.0)

# ---- faixa 1: tendas militares e jipe
func _f1(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("terra", 0.95))
	k.tenda(pai, Vector3(-1.2, 0.05, -1.0), 0, OLIVA, 1.8, 1.4)
	k.tenda(pai, Vector3(0.9, 0.05, -1.3), 90, OLIVA.darkened(0.08), 1.6, 1.2)
	k.tenda(pai, Vector3(-1.4, 0.05, 0.8), 0, CAQUI.darkened(0.1), 1.4, 1.1)
	k.veiculo(pai, Vector3(1.0, 0.08, 0.6), -30, OLIVA)
	_sacos(k, pai, Vector3(0.6, 0.05, 1.9), 0, 4)
	for i in 3:
		k.caixa(pai, Vector3(1.9, 0.05 + i * 0.32, -0.2), Vector3(0.45, 0.3, 0.4), k.mat(Color("6d6a3a"), 0.8), 0.03)
	k.bandeira(pai, Vector3(-0.2, 0.05, 0.2), 2.4, k.cor_alianca)
	k.cilindro(pai, Vector3(0.0, 0.05, 1.0), 0.25, 0.06, k.p("concreto_escuro"), 10)
	k.esfera(pai, Vector3(0.0, 0.16, 1.0), 0.12, k.luz(Color("ff9a3a"), 1.4))
	_soldados(k, pai, Vector3(-1.0, 0.05, 1.7), 1, 3, OLIVA.darkened(0.1))
	return 2.9

# ---- faixa 2: galpão de treino com sacos de areia
func _f2(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("terra", 0.95))
	var c := Vector3(-0.9, 0.05, -0.9)
	for x in [-1.1, 0.0, 1.1]:
		for z in [-0.7, 0.7]:
			k.caixa(pai, c + Vector3(x, 0, z), Vector3(0.12, 1.5, 0.12), k.p("aco"), 0.02)
	var tel = k.grupo(pai, c + Vector3(0, 1.55, 0))
	tel.rotation_degrees.x = -6
	k.caixa(tel, Vector3.ZERO, Vector3(2.6, 0.08, 1.8), k.mat(OLIVA, 0.7), 0.02)
	k.caixa(tel, Vector3(0, -0.02, 0.85), Vector3(2.62, 0.14, 0.1), k.alianca(), 0.0)
	# bonecos de treino e alvos
	for i in 3:
		var q := c + Vector3(-0.8 + i * 0.8, 0, 0)
		k.cilindro(pai, q, 0.05, 0.6, k.p("madeira"), 6)
		k.cilindro(pai, q + Vector3(0, 0.55, 0), 0.18, 0.45, k.p("saco", 0.9), 10)
	var alvo = k.grupo(pai, Vector3(1.9, 0.05, -1.6), -45)
	k.caixa(alvo, Vector3.ZERO, Vector3(0.06, 0.5, 0.06), k.p("madeira"), 0.0)
	for r in [[0.4, Color.WHITE], [0.28, Color("ff4a3d")], [0.15, Color.WHITE], [0.06, Color("ff4a3d")]]:
		var d = k.cilindro(alvo, Vector3.ZERO, r[0], 0.03 + (0.4 - r[0]) * 0.1, k.mat(r[1], 0.6), 20)
		d.rotation_degrees.x = 90
		d.position = Vector3(0, 0.85, 0.05 + (0.4 - r[0]) * 0.05)
	# pista de obstáculos: barras e muro de sacos
	for i in 3:
		k.caixa(pai, Vector3(-1.6 + i * 0.6, 0.05, 1.1), Vector3(0.06, 0.6, 0.06), k.p("aco"), 0.0)
		k.caixa(pai, Vector3(-1.6 + i * 0.6, 0.65, 1.3), Vector3(0.06, 0.06, 0.5), k.p("aco"), 0.0)
		k.caixa(pai, Vector3(-1.6 + i * 0.6, 0.05, 1.5), Vector3(0.06, 0.6, 0.06), k.p("aco"), 0.0)
	_sacos(k, pai, Vector3(0.9, 0.05, 0.8), 0, 5, 3)
	_sacos(k, pai, Vector3(1.8, 0.05, 0.1), 90, 3, 2)
	k.bandeira(pai, Vector3(-2.2, 0.05, 2.0), 2.4, k.cor_alianca)
	_soldados(k, pai, Vector3(0.2, 0.05, 1.6), 2, 4, OLIVA.darkened(0.1))
	return 2.9

# ---- faixa 3: quartel de concreto com garagem de veículos
func _f3(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("concreto_escuro", 0.9))
	var b := Vector3(-0.6, 0.05, -0.8)
	var t := Vector3(3.6, 1.9, 2.0)
	k.caixa(pai, b, t, k.mat(CAQUI, 0.85), 0.08)
	k.caixa(pai, b + Vector3(0, t.y, 0), Vector3(t.x + 0.12, 0.18, t.z + 0.12), k.mat(OLIVA, 0.7), 0.04)
	k.caixa(pai, b + Vector3(0, t.y - 0.25, 0), Vector3(t.x + 0.08, 0.16, t.z + 0.08), k.alianca(), 0.02)
	for i in 3:
		var x := b.x - 1.1 + i * 1.1
		k.caixa(pai, Vector3(x, b.y, b.z + 1.01), Vector3(0.9, 1.1, 0.05), k.p("aco"), 0.02)
		for y in 5:
			k.caixa(pai, Vector3(x, b.y + 0.1 + y * 0.2, b.z + 1.04), Vector3(0.86, 0.04, 0.03), k.p("aco_escuro"), 0.0)
	k.janelas(pai, b + Vector3(0, 0, t.z * 0.5), Vector3.BACK, 3.2, b.y + 1.2, 1, 0.6, 6, k.vidro(Color("8fd8ff"), 0.4), null, Vector2(0.3, 0.3))
	k.janelas(pai, b + Vector3(t.x * 0.5, 0, 0), Vector3.RIGHT, 1.6, b.y + 0.3, 2, 0.75, 2, k.vidro(Color("8fd8ff"), 0.4), null, Vector2(0.4, 0.4))
	k.antena(pai, b + Vector3(1.4, t.y + 0.18, -0.6), 1.0)
	# brasão (estrela) na fachada lateral
	k.cilindro(pai, b + Vector3(t.x * 0.5 + 0.02, 1.0, 0.5), 0.3, 0.04, k.alianca(), 5).rotation_degrees.z = 90
	k.blindado(pai, Vector3(-1.1, 0.05, 1.0), 0, OLIVA, false)
	k.veiculo(pai, Vector3(0.6, 0.08, 1.2), 0, OLIVA, "caminhao")
	k.bandeira(pai, Vector3(1.9, 0.05, 1.8), 2.6, k.cor_alianca)
	k.bandeira(pai, Vector3(1.9, 0.05, 0.9), 2.6, k.cor_alianca)
	_soldados(k, pai, Vector3(-1.9, 0.05, 1.9), 1, 4, OLIVA.darkened(0.1))
	return 3.2

# ---- faixa 4: base com torre de controle e hangar
func _f4(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("concreto_escuro", 0.9))
	k.caixa(pai, Vector3(0.6, 0.06, 1.2), Vector3(3.8, 0.02, 1.4), k.p("asfalto", 0.85), 0.0)
	for i in 6:
		k.caixa(pai, Vector3(-1.0 + i * 0.6, 0.08, 1.2), Vector3(0.3, 0.01, 0.06), k.p("amarelo", 0.6), 0.0)
	_hangar(k, pai, Vector3(-0.3, 0.05, -1.0), 0, 3.4, 1.25, Color("6f7f5a"))
	var tw := Vector3(1.8, 0.05, -1.7)
	k.caixa(pai, tw, Vector3(0.7, 3.4, 0.7), k.p("concreto", 0.8), 0.06)
	k.caixa(pai, tw + Vector3(0, 3.4, 0), Vector3(1.2, 0.6, 1.2), k.vidro(Color("6fd0ff"), 0.6), 0.06)
	k.caixa(pai, tw + Vector3(0, 4.0, 0), Vector3(1.3, 0.12, 1.3), k.alianca(), 0.03)
	k.antena(pai, tw + Vector3(0.3, 4.12, 0.3), 0.9)
	k.esfera(pai, tw + Vector3(-0.3, 4.3, -0.3), 0.18, k.p("branco", 0.4))
	k.helicoptero(pai, Vector3(0.0, 0.08, 1.2), 0, OLIVA)
	k.blindado(pai, Vector3(-1.8, 0.05, 1.9), 0, OLIVA)
	k.bandeira(pai, Vector3(2.2, 0.05, 0.4), 2.6, k.cor_alianca)
	_soldados(k, pai, Vector3(1.3, 0.05, 1.9), 1, 3, OLIVA.darkened(0.1))
	return 4.9

# ---- faixa 5: complexo com tanques e hangar duplo
func _f5(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("concreto_escuro", 0.9))
	_hangar(k, pai, Vector3(-0.3, 0.05, -1.5), 0, 3.6, 1.0, Color("5a6b46"))
	_hangar(k, pai, Vector3(-0.3, 0.05, -0.1), 0, 3.6, 1.0, Color("5a6b46"))
	k.caixa(pai, Vector3(-0.3, 1.05, -0.8), Vector3(3.6, 0.06, 0.4), k.luz(k.PALETA["neon"], 1.0), 0.0)
	k.blindado(pai, Vector3(-1.4, 0.05, 1.5), 15, Color("5a6b3a"))
	k.blindado(pai, Vector3(0.2, 0.05, 1.7), 15, Color("5a6b3a"))
	k.drone(pai, Vector3(1.6, 2.6, 1.2), k.cor_alianca)
	k.drone(pai, Vector3(-1.8, 2.9, 0.6), Color("4d586b"))
	var tw := Vector3(1.9, 0.05, 0.9)
	k.cilindro(pai, tw, 0.35, 2.4, k.p("painel", 0.45), 10)
	k.esfera(pai, tw + Vector3(0, 2.7, 0), 0.45, k.p("branco", 0.4))
	k.toro(pai, tw + Vector3(0, 2.35, 0), 0.38, 0.05, k.alianca())
	k.bandeira(pai, Vector3(1.9, 0.05, 2.0), 2.8, k.cor_alianca)
	_soldados(k, pai, Vector3(1.0, 0.05, 1.6), 2, 2, Color("3f4f2a"))
	return 3.6

# ---- faixa 6: fortaleza tecnológica com campo de energia e bandeira da aliança
func _f6(k, pai: Node3D) -> float:
	k.base_elite(pai, LOTE)
	var muro = k.mat(Color("2a3350"), 0.4)
	for lado in 4:
		var g = k.grupo(pai, Vector3.ZERO, lado * 90)
		k.caixa(g, Vector3(0, 0.05, 2.0), Vector3(3.6, 0.9, 0.35), muro, 0.06)
		k.caixa(g, Vector3(0, 0.95, 2.0), Vector3(3.64, 0.08, 0.4), k.ouro(), 0.02)
		k.caixa(g, Vector3(0, 0.5, 2.18), Vector3(3.0, 0.08, 0.02), k.luz(k.cor_alianca, 1.0), 0.0)
		var tor := Vector3(2.0, 0.05, 2.0)
		k.cilindro(g, tor, 0.42, 1.5, muro, 8)
		k.cilindro(g, tor + Vector3(0, 1.5, 0), 0.48, 0.12, k.ouro(), 8)
		k.esfera(g, tor + Vector3(0, 1.75, 0), 0.14, k.luz(k.PALETA["neon"], 1.5))
	# núcleo: quartel-forte com hangar no centro
	k.caixa(pai, Vector3(-0.2, 0.05, -0.3), Vector3(2.4, 1.5, 2.0), k.mat(Color("3a4a6a"), 0.4, 0.3), 0.1)
	k.caixa(pai, Vector3(-0.2, 1.55, -0.3), Vector3(2.5, 0.12, 2.1), k.ouro(), 0.03)
	k.caixa(pai, Vector3(-0.2, 0.3, 0.71), Vector3(1.6, 0.9, 0.04), k.luz(k.cor_alianca, 0.7), 0.0)
	k.blindado(pai, Vector3(0.9, 0.05, 1.2), 30, Color("2a3350"))
	# grande bandeira da aliança
	k.bandeira(pai, Vector3(-0.2, 1.67, -0.3), 3.2, k.cor_alianca, Color("ffd24a"))
	# campo de energia em cúpula
	var m := SphereMesh.new()
	m.radius = 2.7; m.height = 2.7 * 1.3; m.is_hemisphere = true; m.radial_segments = 40; m.rings = 14
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = k.feixe(k.cor_alianca.lerp(Color("3ef2ff"), 0.4), 0.16, 1.0, false)
	mi.position = Vector3(0, 0.05, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pai.add_child(mi)
	k.toro(pai, Vector3(0, 1.4, 0), 2.45, 0.03, k.feixe(k.PALETA["neon"], 0.7, 1.6))
	return 5.0
