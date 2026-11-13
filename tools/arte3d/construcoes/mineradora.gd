extends RefCounted
## Mineradora: extrai metal. Paleta de terra, rocha cinza e amarelo de máquina pesada;
## o minério de metal tem brilho azul-aço e, no topo, cristal. Frente = +Z.

const LOTE := 5.4

func construir(k, pai: Node3D, faixa: int) -> float:
	match faixa:
		1: return _f1(k, pai)
		2: return _f2(k, pai)
		3: return _f3(k, pai)
		4: return _f4(k, pai)
		5: return _f5(k, pai)
		_: return _f6(k, pai)

func _rocha(k, pai: Node3D, pos: Vector3, r: float, cor := Color("8e8a86")) -> void:
	var m := SphereMesh.new()
	m.radius = r; m.height = r * 1.4; m.radial_segments = 6; m.rings = 3
	var mi := MeshInstance3D.new()
	mi.mesh = m; mi.material_override = k.mat(cor, 0.9)
	mi.position = pos + Vector3(0, r * 0.5, 0)
	mi.rotation_degrees.y = pos.x * 57.0
	pai.add_child(mi)

func _minerio(k, pai: Node3D, pos: Vector3, tamanho: float, brilho := false) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(pos.x * 100 + pos.z * 7)
	_rocha(k, pai, pos, tamanho, Color("6f6a66"))
	for i in 9:
		var a := rng.randf() * TAU
		var d := rng.randf_range(0.2, 0.8) * tamanho
		var q := pos + Vector3(cos(a) * d, tamanho * 0.3 * (1.0 - d / tamanho), sin(a) * d)
		var cor := Color("9fb4cc") if i % 3 else Color("7c8a9c")
		_rocha(k, pai, q, rng.randf_range(0.12, 0.22) * (1.0 + tamanho * 0.3), cor)
	if brilho:
		for i in 5:
			var a := rng.randf() * TAU
			k.esfera(pai, pos + Vector3(cos(a) * tamanho * 0.5, tamanho * 0.55, sin(a) * tamanho * 0.5), 0.07, k.luz(Color("7fe3ff"), 1.4))

func _trilho(k, pai: Node3D, a: Vector3, comp: float) -> void:
	for i in int(comp / 0.3):
		k.caixa(pai, a + Vector3(i * 0.3, 0, 0), Vector3(0.08, 0.04, 0.5), k.p("madeira"), 0.0)
	for z in [-0.17, 0.17]:
		k.caixa(pai, a + Vector3(comp * 0.5 - 0.15, 0.04, z), Vector3(comp, 0.04, 0.04), k.p("aco", 0.4, 0.6), 0.0)

func _vagonete(k, pai: Node3D, pos: Vector3, cheio := true) -> void:
	k.caixa(pai, pos + Vector3(0, 0.1, 0), Vector3(0.6, 0.35, 0.42), k.mat(Color("6d4c35"), 0.7), 0.04)
	k.caixa(pai, pos + Vector3(0, 0.42, 0), Vector3(0.64, 0.05, 0.46), k.p("aco_escuro"), 0.01)
	for x in [-0.2, 0.2]:
		for z in [-0.2, 0.2]:
			var r = k.cilindro(pai, Vector3.ZERO, 0.09, 0.05, k.p("aco_escuro"), 10)
			r.rotation_degrees.x = 90
			r.position = pos + Vector3(x, 0.1, z)
	if cheio:
		for i in 3:
			_rocha(k, pai, pos + Vector3(-0.15 + i * 0.15, 0.4, 0), 0.12, Color("9fb4cc"))

func _escavadeira(k, pai: Node3D, pos: Vector3, rot: float, escala := 1.0) -> void:
	var g = k.grupo(pai, pos, rot)
	g.scale = Vector3.ONE * escala
	var am = k.mat(Color("ffb400"), 0.5)
	for z in [-0.3, 0.3]:
		k.caixa(g, Vector3(0, 0, z), Vector3(1.0, 0.22, 0.2), k.p("aco_escuro", 0.8), 0.07)
	k.caixa(g, Vector3(-0.1, 0.22, 0), Vector3(0.8, 0.3, 0.6), am, 0.06)
	k.caixa(g, Vector3(0.12, 0.52, 0.12), Vector3(0.32, 0.36, 0.3), am, 0.05)
	k.caixa(g, Vector3(0.29, 0.6, 0.12), Vector3(0.02, 0.22, 0.24), k.vidro(Color("8fdcff"), 0.4), 0.0)
	var b1 = k.grupo(g, Vector3(0.25, 0.45, -0.12))
	b1.rotation_degrees.z = -50
	k.caixa(b1, Vector3.ZERO, Vector3(0.12, 0.9, 0.12), am, 0.03)
	var b2 = k.grupo(b1, Vector3(0, 0.9, 0))
	b2.rotation_degrees.z = 120
	k.caixa(b2, Vector3.ZERO, Vector3(0.1, 0.7, 0.1), am, 0.03)
	k.caixa(b2, Vector3(0, 0.62, 0), Vector3(0.28, 0.22, 0.3), k.p("aco_escuro"), 0.04)

func _basculante(k, pai: Node3D, pos: Vector3, rot: float, escala := 1.0) -> void:
	var g = k.grupo(pai, pos, rot)
	g.scale = Vector3.ONE * escala
	var am = k.mat(Color("ffb400"), 0.5)
	k.caixa(g, Vector3(0, 0.25, 0), Vector3(1.4, 0.15, 0.7), k.p("aco_escuro"), 0.03)
	k.caixa(g, Vector3(0.5, 0.4, 0), Vector3(0.4, 0.45, 0.68), am, 0.06)
	k.caixa(g, Vector3(0.71, 0.55, 0), Vector3(0.02, 0.22, 0.5), k.vidro(Color("8fdcff"), 0.4), 0.0)
	k.caixa(g, Vector3(-0.25, 0.4, 0), Vector3(0.95, 0.4, 0.72), am, 0.04)
	for i in 3:
		_rocha(k, g, Vector3(-0.45 + i * 0.22, 0.72, 0), 0.15, Color("9fb4cc"))
	for x in [-0.45, 0.5]:
		for z in [-0.35, 0.35]:
			var r = k.cilindro(g, Vector3.ZERO, 0.22, 0.16, k.mat(Color("23262d"), 0.8), 12)
			r.rotation_degrees.x = 90
			r.position = Vector3(x, 0.22, z)

# ---- faixa 1: poço aberto com carrinho e pá
func _f1(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("terra", 0.95))
	var po := Vector3(-0.6, 0.05, -0.6)
	k.cilindro(pai, po, 0.75, 0.03, k.mat(Color("1d1712"), 1.0), 16)
	for i in 10:
		var a := i * TAU / 10
		_rocha(k, pai, po + Vector3(cos(a), 0, sin(a)) * 0.95, 0.22, Color("a07850"))
	# cavalete com roldana sobre o poço
	for s in [-1, 1]:
		var g = k.grupo(pai, po + Vector3(s * 0.55, 0, 0))
		g.rotation_degrees.z = -s * 14
		k.caixa(g, Vector3.ZERO, Vector3(0.1, 1.7, 0.1), k.p("madeira"), 0.02)
	k.caixa(pai, po + Vector3(0, 1.62, 0), Vector3(1.0, 0.1, 0.1), k.p("madeira"), 0.02)
	var rd = k.cilindro(pai, Vector3.ZERO, 0.14, 0.05, k.p("aco_escuro"), 12)
	rd.rotation_degrees.x = 90
	rd.position = po + Vector3(0, 1.5, 0)
	k.caixa(pai, po + Vector3(0, 0.55, 0), Vector3(0.015, 0.95, 0.015), k.p("aco_escuro"), 0.0)
	k.caixa(pai, po + Vector3(0, 0.4, 0), Vector3(0.25, 0.2, 0.25), k.p("madeira"), 0.02)
	_trilho(k, pai, Vector3(0.4, 0.05, -0.6), 2.1)
	_vagonete(k, pai, Vector3(1.4, 0.1, -0.6))
	_minerio(k, pai, Vector3(1.4, 0.05, 1.2), 0.6)
	# pá e picareta encostadas
	var pa = k.grupo(pai, Vector3(-1.6, 0.05, 1.2))
	pa.rotation_degrees.z = 20
	k.caixa(pa, Vector3.ZERO, Vector3(0.05, 1.0, 0.05), k.p("madeira"), 0.01)
	k.caixa(pa, Vector3(0, -0.05, 0), Vector3(0.22, 0.28, 0.03), k.p("aco", 0.4, 0.6), 0.01)
	k.caixa(pai, Vector3(-2.0, 0.05, -1.9), Vector3(0.6, 0.5, 0.5), k.p("madeira"), 0.04)
	k.bandeira(pai, Vector3(-2.1, 0.05, 0.4), 1.8, k.cor_alianca)
	k.pessoa(pai, Vector3(-0.4, 0.05, 1.0), Color("ffb400"))
	k.pessoa(pai, Vector3(0.6, 0.05, 0.4), k.cor_alianca)
	return 2.4

# ---- faixa 2: escavadeira e pilha de minério
func _f2(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("terra", 0.95))
	_minerio(k, pai, Vector3(-0.9, 0.05, -0.9), 1.1)
	_minerio(k, pai, Vector3(0.5, 0.05, -1.5), 0.7)
	_escavadeira(k, pai, Vector3(0.6, 0.05, 0.1), 160, 1.4)
	# casinha de apoio e balança
	var c := Vector3(-1.7, 0.05, 1.2)
	k.caixa(pai, c, Vector3(1.2, 0.9, 0.9), k.p("painel", 0.6), 0.05)
	k.caixa(pai, c + Vector3(0, 0.9, 0), Vector3(1.3, 0.1, 1.0), k.alianca(), 0.03)
	k.caixa(pai, c + Vector3(0.2, 0.35, 0.46), Vector3(0.45, 0.3, 0.04), k.vidro(Color("8fd8ff"), 0.4), 0.02)
	k.antena(pai, c + Vector3(-0.4, 1.0, -0.2), 0.7)
	k.caixa(pai, Vector3(1.2, 0.05, 1.7), Vector3(1.6, 0.06, 0.9), k.p("aco_escuro", 0.6), 0.02)
	for i in 4:
		k.caixa(pai, Vector3(0.6 + i * 0.4, 0.05, 2.25), Vector3(0.2, 0.25, 0.2), k.mat(Color("ff8a2a") if i % 2 == 0 else Color("ffffff"), 0.6), 0.04)
	k.pessoa(pai, Vector3(-0.6, 0.05, 1.7), Color("ffb400"))
	return 2.6

# ---- faixa 3: cavas em degraus com caminhões
func _f3(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("terra", 0.95))
	# borda alta e degraus descendo até o fundo, de fora para dentro
	var cores := [Color("c99b62"), Color("b5864f"), Color("a0723f"), Color("8a5f33")]
	var tam := [5.0, 4.0, 3.0, 2.0]
	var alt := [0.9, 0.62, 0.34, 0.08]
	for i in 4:
		var s: float = tam[i]
		var h: float = alt[i]
		var w := 0.5
		for lado in 4:
			var g = k.grupo(pai, Vector3(-0.1, 0.05, -0.1), lado * 90)
			k.caixa(g, Vector3(0, 0, s * 0.5 - w * 0.5), Vector3(s, h, w), k.mat(cores[i], 0.95), 0.04)
	k.caixa(pai, Vector3(-0.1, 0.05, -0.1), Vector3(1.6, 0.04, 1.6), k.mat(Color("6f4a2a"), 0.95), 0.0)
	_minerio(k, pai, Vector3(-0.3, 0.09, -0.3), 0.45, true)
	_escavadeira(k, pai, Vector3(0.35, 0.09, 0.2), 200, 0.8)
	_basculante(k, pai, Vector3(-1.4, 0.39, 1.3), 0, 0.75)
	_basculante(k, pai, Vector3(1.3, 0.95, -1.9), 90, 0.75)
	k.caixa(pai, Vector3(1.9, 0.95, 1.9), Vector3(0.8, 0.6, 0.6), k.p("painel", 0.6), 0.04)
	k.caixa(pai, Vector3(1.9, 1.55, 1.9), Vector3(0.9, 0.08, 0.7), k.alianca(), 0.02)
	k.bandeira(pai, Vector3(-2.2, 0.95, -2.2), 1.6, k.cor_alianca)
	k.pessoa(pai, Vector3(1.4, 0.95, 2.0), Color("ffb400"))
	return 2.6

# ---- faixa 4: torre de perfuração com guindaste duplo
func _f4(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("concreto_escuro", 0.9))
	var c := Vector3(-0.5, 0.05, -0.5)
	k.caixa(pai, c, Vector3(2.0, 0.4, 2.0), k.p("concreto", 0.8), 0.05)
	var aco = k.alianca(0.5)
	var h := 5.0
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var g = k.grupo(pai, c + Vector3(sx * 0.7, 0.4, sz * 0.7))
			g.rotation_degrees.x = -sz * 6
			g.rotation_degrees.z = sx * 6
			k.caixa(g, Vector3.ZERO, Vector3(0.1, h, 0.1), aco, 0.02)
	for i in 8:
		var y := 0.4 + 0.3 + i * 0.6
		var lado := 1.4 - (y / h) * 1.0
		k.caixa(pai, c + Vector3(0, y, 0), Vector3(lado, 0.06, lado), k.p("branco", 0.5), 0.0)
	k.caixa(pai, c + Vector3(0, 0.4 + h, 0), Vector3(0.6, 0.35, 0.6), k.p("branco", 0.5), 0.04)
	k.antena(pai, c + Vector3(0, 0.75 + h, 0), 0.6)
	k.cilindro(pai, c + Vector3(0, 0.4, 0), 0.12, 2.2, k.p("aco", 0.3, 0.7), 10)
	k.caixa(pai, c + Vector3(1.2, 0.4, 0.2), Vector3(0.8, 0.7, 1.2), k.p("painel", 0.5), 0.04)
	k.caixa(pai, c + Vector3(1.2, 1.1, 0.2), Vector3(0.85, 0.08, 1.25), k.alianca(), 0.02)
	k.guindaste(pai, Vector3(1.6, 0.05, -1.8), -60, 3.0, 2.6, Color("ffb400"))
	k.guindaste(pai, Vector3(-2.0, 0.05, 1.6), 30, 2.4, 2.2, Color("ffb400"))
	for i in 3:
		k.cilindro(pai, Vector3(0.6 + i * 0.5, 0.05, 1.9), 0.2, 0.9, k.p("aco", 0.4, 0.5), 12).rotation_degrees.x = 0
	_minerio(k, pai, Vector3(1.8, 0.05, 0.7), 0.5, true)
	k.pessoa(pai, Vector3(0.2, 0.05, 1.3), Color("ffb400"))
	k.pessoa(pai, Vector3(-0.6, 0.05, 1.6), k.cor_alianca)
	return h + 1.5

# ---- faixa 5: escavadeira gigante e esteira de minério brilhante
func _f5(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("terra", 0.95))
	_minerio(k, pai, Vector3(-1.4, 0.05, -1.4), 1.2, true)
	# escavadeira de roda de caçambas
	var g = k.grupo(pai, Vector3(0.6, 0.05, -0.1), 0)
	var am = k.mat(Color("ffb400"), 0.5)
	for z in [-0.5, 0.5]:
		k.caixa(g, Vector3(0.3, 0, z), Vector3(1.6, 0.35, 0.35), k.p("aco_escuro", 0.8), 0.08)
	k.caixa(g, Vector3(0.3, 0.35, 0), Vector3(1.4, 0.7, 1.1), am, 0.08)
	k.caixa(g, Vector3(0.5, 1.05, 0), Vector3(0.6, 0.5, 0.6), am, 0.06)
	k.caixa(g, Vector3(0.81, 1.15, 0), Vector3(0.02, 0.3, 0.45), k.vidro(Color("8fdcff"), 0.4), 0.0)
	k.caixa(g, Vector3(0.3, 1.05, 0), Vector3(1.4, 0.12, 1.15), k.alianca(), 0.02)
	var lanca = k.grupo(g, Vector3(-0.2, 1.1, 0))
	lanca.rotation_degrees.z = 62
	k.caixa(lanca, Vector3.ZERO, Vector3(0.25, 2.0, 0.25), am, 0.04)
	var roda = k.grupo(lanca, Vector3(0, 2.1, 0))
	k.toro(roda, Vector3.ZERO, 0.7, 0.08, am).rotation_degrees.x = 90
	for i in 8:
		var a := i * TAU / 8
		var cc = k.grupo(roda, Vector3(cos(a) * 0.75, sin(a) * 0.75, 0))
		cc.rotation.z = a
		k.caixa(cc, Vector3.ZERO, Vector3(0.28, 0.2, 0.3), k.p("aco_escuro"), 0.03)
	# esteira de minério brilhante saindo para o pátio
	var e := Vector3(1.0, 0.75, 1.4)
	k.caixa(pai, e, Vector3(3.2, 0.12, 0.45), k.p("aco_escuro", 0.6), 0.03)
	k.caixa(pai, e + Vector3(0, 0.12, 0), Vector3(3.15, 0.03, 0.38), k.luz(Color("3ec8ff"), 0.8), 0.0)
	for x in [-1.4, 0.0, 1.4]:
		k.caixa(pai, e + Vector3(x, -0.7, 0), Vector3(0.08, 0.7, 0.35), k.p("aco"), 0.0)
	for i in 6:
		k.esfera(pai, e + Vector3(-1.3 + i * 0.5, 0.25, 0), 0.12, k.luz(Color("9fe8ff"), 1.0), 0.7)
	_minerio(k, pai, Vector3(2.0, 0.05, -0.2), 0.6, true)
	k.drone(pai, Vector3(-1.0, 2.8, 1.2), k.cor_alianca)
	k.pessoa(pai, Vector3(-1.6, 0.05, 1.8), Color("ffb400"))
	return 3.6

# ---- faixa 6: mina de cristal com lasers e vagonetes flutuantes
func _f6(k, pai: Node3D) -> float:
	k.base_elite(pai, LOTE)
	k.cilindro(pai, Vector3(0, 0.05, 0), 2.2, 0.4, k.mat(Color("3a2f55"), 0.6), 8)
	k.cilindro(pai, Vector3(0, 0.45, 0), 2.24, 0.06, k.ouro(), 8)
	# aglomerado de cristais
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var cores := [Color("b06bff"), Color("4fe3ff"), k.cor_alianca.lightened(0.2)]
	for i in 11:
		var a := rng.randf() * TAU
		var d := rng.randf_range(0.0, 0.9) if i > 0 else 0.0
		var h := rng.randf_range(1.2, 2.6) if i > 0 else 3.4
		var g = k.grupo(pai, Vector3(cos(a) * d - 0.2, 0.5, sin(a) * d - 0.2), rng.randf() * 60)
		g.rotation_degrees.x = rng.randf_range(-18, 18) if i > 0 else 0
		g.rotation_degrees.z = rng.randf_range(-18, 18) if i > 0 else 0
		var cor: Color = cores[i % 3]
		var r := 0.32 if i > 0 else 0.5
		k.cilindro(g, Vector3.ZERO, r, h * 0.8, k.mat(cor, 0.15, 0.2, 0.6), 6)
		k.cone(g, Vector3(0, h * 0.8, 0), r, h * 0.25, k.mat(cor.lightened(0.2), 0.15, 0.2, 0.8), 6)
	# emissores de laser dourados com feixes até o cristal
	for pos in [Vector3(1.9, 0.5, -1.4), Vector3(-1.5, 0.5, 1.9), Vector3(1.8, 0.5, 1.6)]:
		k.cilindro(pai, pos, 0.18, 0.6, k.ouro(), 8)
		k.esfera(pai, pos + Vector3(0, 0.7, 0), 0.12, k.luz(Color("ff4fd8"), 1.4))
		var alvo := Vector3(-0.2, 1.8, -0.2)
		var ini: Vector3 = pos + Vector3(0, 0.7, 0)
		var f = k.grupo(pai, (ini + alvo) * 0.5)
		f.look_at_from_position((ini + alvo) * 0.5, alvo, Vector3.UP)
		var m = k.cilindro(f, Vector3.ZERO, 0.03, ini.distance_to(alvo), k.feixe(Color("ff4fd8"), 0.8, 2.0), 6)
		m.rotation_degrees.x = 90
		m.position = Vector3.ZERO
	# vagonetes flutuantes com aro de energia
	for v in [Vector3(1.5, 2.0, 0.4), Vector3(-1.6, 2.6, -0.6), Vector3(0.4, 3.4, 1.5)]:
		_vagonete(k, pai, v)
		k.toro(pai, v - Vector3(0, 0.05, 0), 0.4, 0.03, k.feixe(k.PALETA["neon"], 0.7, 2.0))
	k.pessoa(pai, Vector3(-0.6, 0.5, 2.2), k.cor_alianca)
	return 4.6
