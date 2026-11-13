extends RefCounted
## Usina de materiais: produz materiais de construção. Paleta industrial (laranja de
## segurança, aço, tijolo); aliança em faixas, portões e no guindaste. Frente = +Z.

const LOTE := 5.4

func construir(k, pai: Node3D, faixa: int) -> float:
	match faixa:
		1: return _f1(k, pai)
		2: return _f2(k, pai)
		3: return _f3(k, pai)
		4: return _f4(k, pai)
		5: return _f5(k, pai)
		_: return _f6(k, pai)

func _toras(k, pai: Node3D, pos: Vector3, n: int) -> void:
	var base := int((sqrt(8.0 * n + 1.0) - 1.0) / 2.0)
	for linha in base:
		var nesta := base - linha
		for i in nesta:
			var c := pos + Vector3((i - (nesta - 1) * 0.5) * 0.33, linha * 0.29, 0)
			var t = k.cilindro(pai, Vector3.ZERO, 0.16, 1.3, k.p("madeira", 0.9), 10)
			t.rotation_degrees.x = 90
			t.position = c + Vector3(0, 0.16, 0)
			var d = k.cilindro(pai, Vector3.ZERO, 0.13, 0.02, k.mat(Color("e8c08a"), 0.9), 10)
			d.rotation_degrees.x = 90
			d.position = c + Vector3(0, 0.16, 0.65)

func _tabuas(k, pai: Node3D, pos: Vector3, camadas: int) -> void:
	for c in camadas:
		for i in 4:
			k.caixa(pai, pos + Vector3((i - 1.5) * 0.17, c * 0.08, 0), Vector3(0.15, 0.07, 1.0), k.mat(Color("d9a86a"), 0.9), 0.01)

func _caixote(k, pai: Node3D, pos: Vector3, cor: Color) -> void:
	k.caixa(pai, pos, Vector3(0.32, 0.26, 0.32), k.mat(cor, 0.6), 0.03)

func _esteira(k, pai: Node3D, a: Vector3, comp: float, carga: Color, n := 4, luz_cor: Color = Color(0, 0, 0, 0)) -> void:
	k.caixa(pai, a, Vector3(comp, 0.12, 0.45), k.p("aco_escuro", 0.6), 0.03)
	k.caixa(pai, a + Vector3(0, 0.12, 0), Vector3(comp - 0.05, 0.03, 0.38), k.mat(Color("2b2f3a"), 0.8), 0.0)
	if luz_cor.a > 0:
		k.caixa(pai, a + Vector3(0, 0.05, 0.23), Vector3(comp, 0.03, 0.02), k.luz(luz_cor, 1.2), 0.0)
	for x in [-comp * 0.45, comp * 0.45]:
		k.caixa(pai, a + Vector3(x, -0.4, 0), Vector3(0.06, 0.4, 0.4), k.p("aco"), 0.0)
	for i in n:
		_caixote(k, pai, a + Vector3(-comp * 0.4 + i * comp * 0.8 / max(n - 1, 1), 0.15, 0), carga)

func _braco(k, pai: Node3D, pos: Vector3, rot: float) -> void:
	var g = k.grupo(pai, pos, rot)
	var lar = k.mat(Color("ff8a2a"), 0.45)
	k.cilindro(g, Vector3.ZERO, 0.2, 0.15, k.p("aco_escuro"), 12)
	k.cilindro(g, Vector3(0, 0.15, 0), 0.12, 0.2, lar, 12)
	var s1 = k.grupo(g, Vector3(0, 0.35, 0))
	s1.rotation_degrees.z = -35
	k.caixa(s1, Vector3(0, 0, 0), Vector3(0.14, 0.75, 0.14), lar, 0.05)
	var s2 = k.grupo(s1, Vector3(0, 0.75, 0))
	s2.rotation_degrees.z = 100
	k.esfera(s2, Vector3.ZERO, 0.1, k.p("aco_escuro"))
	k.caixa(s2, Vector3(0, 0, 0), Vector3(0.11, 0.6, 0.11), lar, 0.04)
	k.caixa(s2, Vector3(0, 0.6, 0), Vector3(0.18, 0.08, 0.12), k.p("aco_escuro"), 0.02)

# ---- faixa 1: galpão com serra e pilhas de madeira
func _f1(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("terra", 0.95))
	var c := Vector3(-0.4, 0.05, -0.4)
	for x in [-1.3, 1.3]:
		for z in [-0.9, 0.9]:
			k.caixa(pai, c + Vector3(x, 0, z), Vector3(0.14, 1.5, 0.14), k.p("madeira"), 0.02)
	var tel = k.grupo(pai, c + Vector3(0, 1.62, 0))
	tel.rotation_degrees.x = 8
	k.caixa(tel, Vector3.ZERO, Vector3(3.0, 0.08, 2.2), k.mat(Color("8a9aa8"), 0.6, 0.3), 0.02)
	for i in 8:
		k.caixa(tel, Vector3(-1.4 + i * 0.4, 0.08, 0), Vector3(0.05, 0.03, 2.2), k.mat(Color("6f7f8c"), 0.6, 0.3), 0.0)
	# serra circular sobre bancada
	k.caixa(pai, c + Vector3(0, 0, 0), Vector3(1.4, 0.55, 0.6), k.p("madeira"), 0.03)
	var s = k.cilindro(pai, Vector3.ZERO, 0.32, 0.03, k.p("aco", 0.3, 0.8), 20)
	s.rotation_degrees.x = 90
	s.position = c + Vector3(0.1, 0.6, 0)
	k.caixa(pai, c + Vector3(-0.35, 0.55, 0), Vector3(0.5, 0.08, 0.18), k.mat(Color("d9a86a"), 0.9), 0.01)
	_toras(k, pai, Vector3(1.8, 0.05, -1.4), 6)
	_tabuas(k, pai, Vector3(1.9, 0.05, 1.0), 4)
	_tabuas(k, pai, Vector3(-2.0, 0.05, 1.1), 2)
	k.caixa(pai, Vector3(-0.2, 0.05, 1.7), Vector3(0.9, 0.3, 0.5), k.mat(Color("8a5a35"), 0.9), 0.02)
	for i in 4:
		k.esfera(pai, Vector3(-0.5 + i * 0.2, 0.37, 1.7), 0.09, k.mat(Color("e8c08a"), 0.95), 0.5)
	k.pessoa(pai, Vector3(0.6, 0.05, 0.6), k.cor_alianca)
	k.pessoa(pai, Vector3(1.2, 0.05, 1.7), Color("ff8a2a"))
	return 2.2

# ---- faixa 2: fábrica com chaminé e esteira
func _f2(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var b := Vector3(-0.6, 0.05, -0.5)
	var t := Vector3(3.0, 1.8, 2.4)
	k.caixa(pai, b, t, k.p("tijolo", 0.85), 0.06)
	# telhado em dente de serra
	for i in 3:
		var g = k.grupo(pai, b + Vector3(-1.0 + i * 1.0, t.y, 0))
		k.caixa(g, Vector3(0, 0, 0), Vector3(1.0, 0.1, t.z), k.p("aco", 0.5, 0.3), 0.02)
		var inc = k.grupo(g, Vector3(0.0, 0.08, 0))
		inc.rotation_degrees.z = 28
		k.caixa(inc, Vector3(0.05, 0, 0), Vector3(1.05, 0.05, t.z), k.p("aco", 0.5, 0.3), 0.0)
		k.caixa(g, Vector3(0.45, 0.08, 0), Vector3(0.04, 0.48, t.z - 0.1), k.vidro(Color("8fd8ff"), 0.4), 0.0)
	k.caixa(pai, b + Vector3(0, t.y - 0.35, 0), Vector3(t.x + 0.06, 0.2, t.z + 0.06), k.alianca(), 0.02)
	k.janelas(pai, b + Vector3(0, 0, t.z * 0.5), Vector3.BACK, 2.6, b.y + 0.4, 1, 0.9, 4, k.vidro(Color("8fd8ff"), 0.4), k.p("concreto"), Vector2(0.45, 0.6))
	k.caixa(pai, b + Vector3(t.x * 0.5, 0, 0.3), Vector3(0.06, 1.0, 1.0), k.alianca(), 0.02)
	# chaminé com fumaça
	var ch := b + Vector3(-1.1, 0, -0.8)
	k.cilindro(pai, ch, 0.28, 3.3, k.p("tijolo", 0.85), 12, 0.22)
	k.cilindro(pai, ch + Vector3(0, 2.6, 0), 0.25, 0.2, k.p("branco"), 12)
	for i in 4:
		k.esfera(pai, ch + Vector3(0.15 * i, 3.6 + i * 0.35, 0.1 * i), 0.22 + i * 0.08, k.mat(Color("d8dde3"), 1.0, 0.0, 0.0, 0.7 - i * 0.12))
	# esteira saindo pelo lado
	_esteira(k, pai, Vector3(1.6, 0.5, 0.0) + Vector3(0, 0, -0.2), 1.6, Color("d9a86a"), 3)
	_tabuas(k, pai, Vector3(1.9, 0.05, 1.6), 3)
	_toras(k, pai, Vector3(-1.8, 0.05, 1.7), 3)
	k.veiculo(pai, Vector3(0.4, 0.08, 1.7), 0, Color("ff8a2a"), "caminhao")
	k.pessoa(pai, Vector3(-0.6, 0.05, 1.0), k.cor_alianca)
	return 3.6

# ---- faixa 3: linha de montagem coberta e guindaste móvel (pórtico)
func _f3(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var b := Vector3(-0.3, 0.05, -1.0)
	var t := Vector3(4.2, 1.9, 1.9)
	k.caixa(pai, b + Vector3(0, 0, -t.z * 0.5 + 0.08), Vector3(t.x, t.y, 0.16), k.p("concreto", 0.8), 0.03)
	for x in [-2.0, -1.0, 0.0, 1.0, 2.0]:
		k.caixa(pai, b + Vector3(x, 0, t.z * 0.5 - 0.1), Vector3(0.16, t.y, 0.16), k.p("concreto_escuro"), 0.02)
	k.caixa(pai, b + Vector3(0, t.y, 0), Vector3(t.x + 0.2, 0.18, t.z + 0.3), k.p("concreto", 0.8), 0.04)
	k.caixa(pai, b + Vector3(0, t.y - 0.05, t.z * 0.5 + 0.12), Vector3(t.x + 0.22, 0.22, 0.06), k.alianca(), 0.02)
	for i in 3:
		k.caixa(pai, b + Vector3(-1.2 + i * 1.2, t.y + 0.18, 0), Vector3(0.7, 0.25, 1.2), k.vidro(Color("8fd8ff"), 0.4), 0.04)
	_esteira(k, pai, b + Vector3(0, 0.45, 0.1), 3.8, Color("ff8a2a"), 6, Color("ffb400"))
	for x in [-1.3, 0.2, 1.4]:
		k.pessoa(pai, b + Vector3(x, 0.0, -0.45), Color("ffb400"))
	# pórtico no pátio
	var p0 := Vector3(-0.3, 0.05, 1.2)
	for x in [-1.9, 1.9]:
		k.caixa(pai, p0 + Vector3(x, 0, 0), Vector3(0.18, 2.2, 0.3), k.alianca(0.5), 0.03)
		k.caixa(pai, p0 + Vector3(x, 0, 0), Vector3(0.3, 0.12, 0.9), k.p("aco_escuro"), 0.03)
	k.caixa(pai, p0 + Vector3(0, 2.2, 0), Vector3(4.1, 0.25, 0.32), k.alianca(0.5), 0.03)
	k.caixa(pai, p0 + Vector3(0.6, 1.95, 0), Vector3(0.35, 0.25, 0.4), k.p("amarelo", 0.5), 0.03)
	k.caixa(pai, p0 + Vector3(0.6, 1.2, 0), Vector3(0.02, 0.75, 0.02), k.p("aco_escuro"), 0.0)
	_tabuas(k, pai, p0 + Vector3(0.6, 0.85, 0), 2)
	_tabuas(k, pai, p0 + Vector3(-1.1, 0.0, 0.2), 4)
	_toras(k, pai, Vector3(1.9, 0.05, 2.1), 3)
	k.veiculo(pai, Vector3(-1.9, 0.08, 2.05), 0, Color("ff8a2a"), "caminhao")
	return 3.3

# ---- faixa 4: fábrica automatizada com braços robóticos
func _f4(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var b := Vector3(-0.3, 0.05, -0.4)
	var t := Vector3(4.0, 2.3, 3.0)
	k.caixa(pai, b, Vector3(t.x, 0.15, t.z), k.mat(Color("cfd6df"), 0.4), 0.03)
	k.caixa(pai, b + Vector3(0, 0, -t.z * 0.5 + 0.1), Vector3(t.x, t.y, 0.2), k.p("painel", 0.5), 0.04)
	k.caixa(pai, b + Vector3(-t.x * 0.5 + 0.1, 0, 0), Vector3(0.2, t.y, t.z), k.p("painel", 0.5), 0.04)
	k.caixa(pai, b + Vector3(0, 0, t.z * 0.5), Vector3(t.x, t.y, 0.03), k.mat(Color("cfefff"), 0.05, 0.2, 0.0, 0.2), 0.0)
	k.caixa(pai, b + Vector3(t.x * 0.5, 0, 0), Vector3(0.03, t.y, t.z), k.mat(Color("cfefff"), 0.05, 0.2, 0.0, 0.2), 0.0)
	for i in 6:
		k.caixa(pai, b + Vector3(-t.x * 0.5 + i * t.x / 5.0, 0, t.z * 0.5), Vector3(0.07, t.y, 0.07), k.p("aco", 0.4, 0.5), 0.0)
	k.caixa(pai, b + Vector3(0, t.y, 0), Vector3(t.x + 0.12, 0.16, t.z + 0.12), k.p("painel", 0.5), 0.04)
	k.caixa(pai, b + Vector3(0, t.y - 0.1, 0), Vector3(t.x + 0.16, 0.12, t.z + 0.16), k.alianca(), 0.02)
	for i in 2:
		for j in 3:
			k.painel_solar(pai, b + Vector3(-1.2 + j * 1.2, t.y + 0.16, -0.6 + i * 1.1), 0, 0.95)
	_esteira(k, pai, b + Vector3(0.2, 0.55, 0.3), 3.2, Color("4f7fae"), 5, Color("3ef2ff"))
	for x in [-1.0, 0.4, 1.6]:
		_braco(k, pai, b + Vector3(x, 0.15, -0.45), 90)
	k.veiculo(pai, Vector3(2.15, 0.08, 1.9), 90, Color("ffffff"), "caminhao")
	k.pessoa(pai, Vector3(0.2, 0.05, 2.0), k.cor_alianca)
	_caixote(k, pai, Vector3(-1.9, 0.05, 1.9), Color("4f7fae"))
	_caixote(k, pai, Vector3(-1.5, 0.05, 1.95), Color("4f7fae"))
	return t.y + 1.0

# ---- faixa 5: complexo com tubulações brilhantes e fumaça branca
func _f5(k, pai: Node3D) -> float:
	k.lote(pai, LOTE, k.p("calcada", 0.9))
	var b := Vector3(-0.8, 0.05, -0.6)
	var t := Vector3(2.6, 3.0, 2.6)
	k.caixa(pai, b, t, k.p("painel", 0.45), 0.1)
	for a in 3:
		k.caixa(pai, b + Vector3(0, 0.3 + a * 0.95, t.z * 0.5), Vector3(t.x - 0.3, 0.45, 0.04), k.vidro(Color("6fd0ff"), 0.6), 0.01)
	k.caixa(pai, b + Vector3(0, t.y, 0), Vector3(t.x + 0.1, 0.18, t.z + 0.1), k.alianca(), 0.04)
	# tanques e torres de resfriamento
	for pos in [Vector3(1.4, 0.05, -1.3), Vector3(1.4, 0.05, 0.1)]:
		k.cilindro(pai, pos, 0.55, 2.2, k.p("branco", 0.4), 16)
		k.cilindro(pai, pos + Vector3(0, 2.2, 0), 0.57, 0.1, k.alianca(), 16)
		k.cilindro(pai, pos + Vector3(0, 0.8, 0), 0.57, 0.08, k.luz(k.PALETA["neon"], 1.2), 16)
	var torre := Vector3(-1.9, 0.05, 1.6)
	k.cilindro(pai, torre, 0.6, 1.4, k.p("concreto", 0.7), 16, 0.45)
	for i in 4:
		k.esfera(pai, torre + Vector3(0.1 * i, 1.7 + i * 0.4, -0.1 * i), 0.4 + i * 0.1, k.mat(Color("ffffff"), 1.0, 0.0, 0.0, 0.75 - i * 0.15))
	# tubulações brilhantes ligando prédio e tanques
	var neon = k.luz(k.PALETA["neon"], 1.3)
	for y in [0.6, 1.4, 2.1]:
		k.caixa(pai, Vector3(0.6, y, -1.3), Vector3(1.2, 0.1, 0.1), neon, 0.02)
		k.caixa(pai, Vector3(0.6, y - 0.2, 0.1), Vector3(1.2, 0.1, 0.1), neon, 0.02)
	k.caixa(pai, Vector3(1.4, 2.4, -0.6), Vector3(0.1, 0.1, 1.4), neon, 0.02)
	k.caixa(pai, Vector3(0.2, 0.15, 1.2), Vector3(0.1, 0.1, 1.6), neon, 0.02)
	_esteira(k, pai, Vector3(0.5, 0.45, 1.9), 2.6, Color("ff8a2a"), 4, Color("3ef2ff"))
	k.drone(pai, Vector3(1.8, 3.3, 1.5), k.cor_alianca)
	k.pessoa(pai, Vector3(-0.6, 0.05, 1.3), k.cor_alianca)
	return t.y + 1.3

# ---- faixa 6: mega-fábrica com faíscas e esteiras flutuantes
func _f6(k, pai: Node3D) -> float:
	k.base_elite(pai, LOTE)
	k.caixa(pai, Vector3(0, 0.05, 0), Vector3(4.0, 0.4, 4.0), k.mat(Color("f3f0ea"), 0.3), 0.08)
	k.caixa(pai, Vector3(0, 0.45, 0), Vector3(4.06, 0.06, 4.06), k.ouro(), 0.02)
	var b := Vector3(-0.5, 0.51, -0.5)
	var t := Vector3(2.8, 3.2, 2.8)
	k.caixa(pai, b, t, k.mat(Color("23305a"), 0.35, 0.3), 0.12)
	for a in 3:
		k.caixa(pai, b + Vector3(0, 0.35 + a * 1.0, t.z * 0.5), Vector3(t.x - 0.4, 0.5, 0.04), k.luz(Color("ff9a3a"), 0.9), 0.01)
		k.caixa(pai, b + Vector3(t.x * 0.5, 0.35 + a * 1.0, 0), Vector3(0.04, 0.5, t.z - 0.4), k.luz(Color("ff9a3a"), 0.9), 0.01)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			k.caixa(pai, b + Vector3(sx * t.x * 0.5, 0, sz * t.z * 0.5), Vector3(0.1, t.y, 0.1), k.luz(k.cor_alianca, 0.9), 0.02)
	k.caixa(pai, b + Vector3(0, t.y - 0.04, 0), Vector3(t.x + 0.16, 0.12, t.z + 0.16), k.mat(Color("2a3350"), 0.4), 0.03)
	for s in [-1, 1]:
		k.caixa(pai, b + Vector3(0, t.y - 0.06, s * (t.z * 0.5 + 0.06)), Vector3(t.x + 0.2, 0.2, 0.08), k.ouro(), 0.02)
		k.caixa(pai, b + Vector3(s * (t.x * 0.5 + 0.06), t.y - 0.06, 0), Vector3(0.08, 0.2, t.z + 0.2), k.ouro(), 0.02)
	# chaminés douradas com chama
	for x in [-0.7, 0.5]:
		k.cilindro(pai, b + Vector3(x, t.y, -0.6), 0.22, 1.1, k.ouro(), 12)
		k.esfera(pai, b + Vector3(x, t.y + 1.25, -0.6), 0.2, k.luz(Color("ff7a1a"), 1.6))
	# esteiras flutuantes (faixas de luz) com caixotes pairando
	for e in [[Vector3(1.6, 1.6, -0.5), 90.0], [Vector3(-0.5, 2.4, 1.6), 0.0], [Vector3(1.6, 3.2, 1.6), 45.0]]:
		var g = k.grupo(pai, e[0], e[1])
		k.caixa(g, Vector3.ZERO, Vector3(2.2, 0.04, 0.4), k.feixe(k.PALETA["neon"], 0.5, 1.5), 0.0)
		for i in 3:
			_caixote(k, g, Vector3(-0.7 + i * 0.7, 0.12, 0), [k.cor_alianca, Color("ff8a2a"), Color("f4f6fa")][i])
	# faíscas
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 22:
		var q := b + Vector3(t.x * 0.5 + rng.randf_range(0.0, 0.6), rng.randf_range(0.3, 1.4), t.z * 0.5 + rng.randf_range(0.0, 0.6))
		k.esfera(pai, q, rng.randf_range(0.03, 0.06), k.luz(Color("ffd24a"), 2.0))
	k.cilindro(pai, Vector3(2.15, 0.45, 2.15), 0.18, 0.12, k.ouro(), 12)
	k.cilindro(pai, Vector3(2.15, 0.57, 2.15), 0.12, 0.6, k.feixe(k.cor_alianca, 0.25, 1.5), 12, 0.4)
	k.pessoa(pai, Vector3(-1.4, 0.51, 1.7), k.cor_alianca)
	return t.y + 2.6
