extends RefCounted
## Estação de água: água e saneamento. Azul-água é a cor da função; branco e concreto na
## estrutura; a aliança vai em faixas e tampas. Frente = +Z.

const LOTE := 5.4
const AGUA := Color("37b6f0")
const CANO := Color("2f7fd6")

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

func _cano(k, pai: Node3D, a: Vector3, b: Vector3, raio := 0.07, m: Material = null) -> void:
	var mat = m if m else k.mat(CANO, 0.35, 0.2)
	var meio := (a + b) * 0.5
	var f = k.grupo(pai, meio)
	var d := (b - a).normalized()
	f.look_at_from_position(meio, b, Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT)
	var c = k.cilindro(f, Vector3.ZERO, raio, a.distance_to(b), mat, 10)
	c.rotation_degrees.x = 90
	c.position = Vector3.ZERO
	k.esfera(pai, a, raio * 1.15, mat)
	k.esfera(pai, b, raio * 1.15, mat)

func _tanque(k, pai: Node3D, pos: Vector3, r: float, h: float, cor := Color("f4f6fa")) -> void:
	k.cilindro(pai, pos, r, h, k.mat(cor, 0.4), 20)
	k.cilindro(pai, pos + Vector3(0, h, 0), r + 0.03, 0.08, k.alianca(), 20)
	k.cilindro(pai, pos + Vector3(0, h + 0.08, 0), r, 0.2, k.mat(cor, 0.4), 20, r * 0.3)
	k.cilindro(pai, pos + Vector3(0, h * 0.45, 0), r + 0.01, 0.06, k.mat(AGUA, 0.3), 20)

func _piscina(k, pai: Node3D, pos: Vector3, t: Vector2, cor := AGUA, brilho := false) -> void:
	k.caixa(pai, pos, Vector3(t.x + 0.2, 0.3, t.y + 0.2), k.p("concreto", 0.8), 0.04)
	k.caixa(pai, pos + Vector3(0, 0.26, 0), Vector3(t.x, 0.05, t.y), k.luz(cor, 0.45) if brilho else k.mat(cor, 0.06, 0.3), 0.0)

# ---- faixa 1: poço com bomba
func _f1(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("grama", 0.9))
	var p := Vector3(-0.6, 0.1, -0.6)
	k.cilindro(pai, p, 0.65, 0.6, k.mat(Color("9a958e"), 0.9), 12)
	k.toro(pai, p + Vector3(0, 0.6, 0), 0.62, 0.08, k.mat(Color("b5b0a8"), 0.9))
	k.toro(pai, p + Vector3(0, 0.25, 0), 0.66, 0.05, k.mat(Color("847f78"), 0.9))
	k.cilindro(pai, p + Vector3(0, 0.55, 0), 0.52, 0.04, k.mat(AGUA, 0.1, 0.3), 12)
	for s in [-1, 1]:
		k.caixa(pai, p + Vector3(s * 0.6, 0.6, 0), Vector3(0.1, 1.0, 0.1), k.p("madeira"), 0.02)
	for s in [-1, 1]:
		var g = k.grupo(pai, p + Vector3(0, 1.65, s * 0.35))
		g.rotation_degrees.x = s * 35
		k.caixa(g, Vector3.ZERO, Vector3(1.5, 0.05, 0.85), k.alianca(0.7), 0.02)
	var rol = k.cilindro(pai, Vector3.ZERO, 0.08, 1.2, k.p("madeira"), 10)
	rol.rotation_degrees.z = 90
	rol.position = p + Vector3(0, 1.3, 0)
	k.caixa(pai, p + Vector3(0, 0.75, 0), Vector3(0.015, 0.55, 0.015), k.p("aco_escuro"), 0.0)
	k.cilindro(pai, p + Vector3(0, 0.62, 0), 0.12, 0.2, k.p("madeira"), 10)
	# bomba manual e baldes
	var b := Vector3(1.0, 0.1, 0.6)
	k.caixa(pai, b, Vector3(0.6, 0.12, 0.6), k.p("concreto", 0.8), 0.03)
	k.cilindro(pai, b + Vector3(0, 0.12, 0), 0.09, 0.8, k.p("aco", 0.4, 0.5), 10)
	var al = k.grupo(pai, b + Vector3(0, 0.85, 0))
	al.rotation_degrees.z = 20
	k.caixa(al, Vector3(-0.25, 0, 0), Vector3(0.55, 0.04, 0.04), k.p("aco", 0.4, 0.5), 0.0)
	k.caixa(pai, b + Vector3(0.12, 0.6, 0), Vector3(0.22, 0.05, 0.05), k.p("aco", 0.4, 0.5), 0.0)
	for q in [b + Vector3(0.25, 0.12, 0.2), Vector3(1.6, 0.1, 1.2)]:
		k.cilindro(pai, q, 0.12, 0.2, k.mat(Color("8d9bb0"), 0.4, 0.4), 10, 0.14)
	k.pessoa(pai, Vector3(0.4, 0.1, 1.2), k.cor_alianca)
	k.arvore(pai, Vector3(-1.9, 0.1, 1.7))
	return 2.3

# ---- faixa 2: caixa-d'água pequena
func _f2(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var t := Vector3(-0.4, 0.1, -0.5)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			k.caixa(pai, t + Vector3(sx * 0.55, 0, sz * 0.55), Vector3(0.1, 1.8, 0.1), k.p("aco", 0.45, 0.5), 0.0)
	for y in [0.6, 1.2]:
		k.caixa(pai, t + Vector3(0, y, 0), Vector3(1.2, 0.05, 1.2), k.p("aco", 0.45, 0.5), 0.0)
	k.caixa(pai, t + Vector3(0, 1.8, 0), Vector3(1.4, 0.08, 1.4), k.p("aco_escuro"), 0.02)
	_tanque(k, pai, t + Vector3(0, 1.88, 0), 0.62, 0.9, Color("4fa3e8"))
	_cano(k, pai, t + Vector3(0.4, 1.9, 0.4), t + Vector3(0.4, 0.05, 0.4))
	_cano(k, pai, t + Vector3(0.4, 0.05, 0.4), Vector3(1.4, 0.15, 1.0))
	var c := Vector3(1.4, 0.1, 1.0)
	k.caixa(pai, c, Vector3(0.9, 0.7, 0.7), k.p("painel", 0.6), 0.04)
	k.caixa(pai, c + Vector3(0, 0.7, 0), Vector3(0.95, 0.06, 0.75), k.alianca(), 0.02)
	k.cilindro(pai, Vector3(-1.9, 0.1, 1.5), 0.12, 0.4, k.p("vermelho", 0.6), 10)
	k.pessoa(pai, Vector3(0.5, 0.1, 1.8), k.cor_alianca)
	k.arvore(pai, Vector3(1.9, 0.1, -1.9))
	return 3.3

# ---- faixa 3: reservatório elevado
func _f3(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var c := Vector3(-0.3, 0.1, -0.3)
	k.cilindro(pai, c, 0.9, 0.3, k.p("concreto", 0.8), 16)
	k.cilindro(pai, c + Vector3(0, 0.3, 0), 0.45, 3.4, k.p("concreto", 0.8), 16, 0.38)
	for i in 4:
		k.cilindro(pai, c + Vector3(0, 0.8 + i * 0.75, 0), 0.47 - i * 0.02, 0.05, k.p("concreto_escuro"), 16)
	var tq := c + Vector3(0, 3.7, 0)
	k.cilindro(pai, tq - Vector3(0, 0.4, 0), 0.4, 0.4, k.p("concreto", 0.8), 16, 1.3)
	k.cilindro(pai, tq, 1.3, 0.9, k.mat(Color("f4f6fa"), 0.4), 20)
	k.cilindro(pai, tq + Vector3(0, 0.35, 0), 1.32, 0.2, k.alianca(), 20)
	k.cilindro(pai, tq + Vector3(0, 0.9, 0), 1.3, 0.35, k.mat(Color("f4f6fa"), 0.4), 20, 0.25)
	k.antena(pai, tq + Vector3(0, 1.25, 0), 0.5)
	_cano(k, pai, c + Vector3(0.5, 0.3, 0.5), Vector3(1.5, 0.2, 1.4))
	var e := Vector3(1.5, 0.1, 1.4)
	k.caixa(pai, e, Vector3(1.0, 0.8, 0.8), k.p("painel", 0.6), 0.04)
	k.caixa(pai, e + Vector3(0, 0.8, 0), Vector3(1.05, 0.06, 0.85), k.alianca(), 0.02)
	k.caixa(pai, e + Vector3(0, 0.3, 0.41), Vector3(0.4, 0.4, 0.02), k.vidro(Color("8fd8ff"), 0.4), 0.0)
	k.arvore(pai, Vector3(-2.0, 0.1, 1.8))
	k.arvore(pai, Vector3(-2.1, 0.1, 0.8), 0.8)
	k.pessoa(pai, Vector3(0.5, 0.1, 2.0), k.cor_alianca)
	return 5.2

# ---- faixa 4: estação com filtros e torre
func _f4(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var b := Vector3(-1.0, 0.1, -1.0)
	k.caixa(pai, b, Vector3(2.0, 1.4, 1.8), k.p("painel", 0.5), 0.06)
	k.caixa(pai, b + Vector3(0, 1.4, 0), Vector3(2.06, 0.1, 1.86), k.alianca(), 0.02)
	k.caixa(pai, b + Vector3(0, 0.5, 0.91), Vector3(1.6, 0.5, 0.03), k.vidro(Color("6fd0ff"), 0.6), 0.0)
	# filtros em fileira
	for i in 3:
		var f := Vector3(1.0 + i * 0.0, 0.1, -1.6 + i * 0.85)
		_tanque(k, pai, f, 0.38, 1.3)
		_cano(k, pai, f + Vector3(-0.4, 0.5, 0), b + Vector3(1.0, 0.5, -0.6 + i * 0.6))
	# torre de captação
	var t := Vector3(-1.6, 0.1, 1.3)
	k.caixa(pai, t, Vector3(0.7, 3.0, 0.7), k.p("concreto", 0.8), 0.05)
	k.caixa(pai, t + Vector3(0, 3.0, 0), Vector3(0.9, 0.5, 0.9), k.mat(Color("4fa3e8"), 0.4), 0.06)
	k.caixa(pai, t + Vector3(0, 3.5, 0), Vector3(0.95, 0.08, 0.95), k.alianca(), 0.02)
	_piscina(k, pai, Vector3(0.4, 0.1, 1.4), Vector2(1.6, 1.0))
	_cano(k, pai, Vector3(-1.2, 0.3, 1.3), Vector3(-0.4, 0.3, 1.4))
	k.pessoa(pai, Vector3(1.6, 0.1, 2.1), k.cor_alianca)
	return 4.4

# ---- faixa 5: estação com tubulações azuis
func _f5(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	_piscina(k, pai, Vector3(-1.2, 0.1, 1.2), Vector2(1.8, 1.6), Color("4fc1e8"))
	_piscina(k, pai, Vector3(1.3, 0.1, 1.5), Vector2(1.6, 1.0), Color("6fd8c8"))
	for i in 2:
		_tanque(k, pai, Vector3(-1.5 + i * 1.3, 0.1, -1.5), 0.55, 2.2)
	var b := Vector3(1.5, 0.1, -1.0)
	k.caixa(pai, b, Vector3(1.4, 2.0, 1.6), k.p("painel", 0.5), 0.06)
	k.caixa(pai, b + Vector3(0, 2.0, 0), Vector3(1.46, 0.1, 1.66), k.alianca(), 0.02)
	for a in 2:
		k.caixa(pai, b + Vector3(0, 0.4 + a * 0.8, 0.81), Vector3(1.0, 0.35, 0.03), k.vidro(Color("6fd0ff"), 0.6), 0.0)
	# malha de tubos azuis com anéis luminosos
	var m = k.mat(CANO, 0.3, 0.3)
	_cano(k, pai, Vector3(-1.5, 1.6, -1.0), Vector3(-1.5, 1.6, 0.6), 0.09, m)
	_cano(k, pai, Vector3(-0.2, 1.4, -1.0), Vector3(-0.2, 1.4, 0.8), 0.09, m)
	_cano(k, pai, Vector3(-1.5, 1.6, 0.6), Vector3(-1.5, 0.45, 0.6), 0.09, m)
	_cano(k, pai, Vector3(-0.2, 1.4, 0.8), Vector3(0.8, 1.4, 0.8), 0.09, m)
	_cano(k, pai, Vector3(0.8, 1.4, 0.8), Vector3(0.8, 0.45, 1.3), 0.09, m)
	_cano(k, pai, Vector3(-0.9, 2.0, -1.5), Vector3(0.8, 2.0, -1.5), 0.09, m)
	_cano(k, pai, Vector3(0.8, 2.0, -1.5), Vector3(0.8, 1.2, -1.0), 0.09, m)
	for q in [Vector3(-1.5, 1.6, -0.2), Vector3(-0.2, 1.4, 0.0), Vector3(0.0, 2.0, -1.5)]:
		var r = k.toro(pai, q, 0.12, 0.03, k.luz(k.PALETA["neon"], 1.2))
		r.rotation_degrees.x = 90 if absf(q.x + 0.2) < 0.1 or absf(q.x + 1.5) < 0.1 else 0
		if absf(q.z + 1.5) < 0.1:
			r.rotation_degrees.z = 90
	k.drone(pai, Vector3(0.4, 2.8, 0.6), Color("f4f6fa"))
	k.pessoa(pai, Vector3(0.1, 0.1, 2.2), k.cor_alianca)
	return 3.6

# ---- faixa 6: estação de dessalinização com cúpula brilhante
func _f6(k, pai: Node3D) -> float:
	k.base_elite(pai, LOTE)
	k.cilindro(pai, Vector3(0, 0.05, 0), 2.3, 0.4, k.mat(Color("f3f0ea"), 0.3), 32)
	k.cilindro(pai, Vector3(0, 0.45, 0), 2.33, 0.05, k.ouro(), 32)
	var c := Vector3(-0.2, 0.5, -0.2)
	k.cilindro(pai, c, 1.5, 0.35, k.mat(Color("23305a"), 0.35, 0.3), 24)
	k.cilindro(pai, c + Vector3(0, 0.3, 0), 1.52, 0.06, k.luz(k.cor_alianca, 1.0), 24)
	# cúpula brilhante com núcleo de água
	var m := SphereMesh.new()
	m.radius = 1.35; m.height = 2.7; m.is_hemisphere = true; m.radial_segments = 32; m.rings = 12
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = k.feixe(Color("38c8ff"), 0.4, 1.0, false)
	mi.position = c + Vector3(0, 0.35, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pai.add_child(mi)
	k.esfera(pai, c + Vector3(0, 0.95, 0), 0.6, k.luz(Color("7fe8ff"), 1.0))
	for i in 6:
		k.arco(pai, c + Vector3(0, 0.35, 0), 1.37, i * 30.0, 0.05, k.ouro(), 10)
	k.cone(pai, c + Vector3(0, 1.65, 0), 0.15, 0.6, k.ouro(), 8)
	k.esfera(pai, c + Vector3(0, 2.3, 0), 0.1, k.luz(k.cor_alianca, 1.4))
	# canais de água luminosa e torres de captação
	for e in [[Vector3(1.55, 0.5, -0.2), 90.0], [Vector3(-0.2, 0.5, 1.55), 0.0]]:
		var g = k.grupo(pai, e[0], e[1])
		k.caixa(g, Vector3.ZERO, Vector3(0.5, 0.12, 1.2), k.ouro(), 0.02)
		k.caixa(g, Vector3(0, 0.1, 0), Vector3(0.35, 0.04, 1.2), k.luz(Color("37b6f0"), 0.8), 0.0)
	for q in [Vector3(1.8, 0.45, 1.8), Vector3(-1.8, 0.45, 1.4), Vector3(1.4, 0.45, -1.8)]:
		k.cilindro(pai, q, 0.22, 1.2, k.mat(Color("f3f0ea"), 0.3), 12)
		k.cilindro(pai, q + Vector3(0, 1.2, 0), 0.26, 0.12, k.ouro(), 12)
		k.esfera(pai, q + Vector3(0, 1.45, 0), 0.12, k.luz(k.PALETA["neon"], 1.4))
	for i in 3:
		k.esfera(pai, c + Vector3(0.1 * i, 2.6 + i * 0.3, 0.05 * i), 0.16 + i * 0.06, k.mat(Color("ffffff"), 1.0, 0.0, 0.0, 0.5 - i * 0.12))
	k.pessoa(pai, Vector3(-0.9, 0.45, 2.0), k.cor_alianca)
	return 3.6
