extends RefCounted
## Kit de peças 3D de baixo polígono, todas geradas por código.
## Uma construção é uma receita que chama estas funções; cor, faixa e aliança
## entram como parâmetro. Nada de modelo externo: o kit é a fonte da verdade.

const PALETA := {
	# base e terreno
	"grama": Color("7ed957"), "grama_escura": Color("4fb83f"),
	"terra": Color("c99b62"), "calcada": Color("ddd5c6"), "asfalto": Color("4a4f5c"),
	# materiais de obra
	"concreto": Color("e8e1d4"), "concreto_escuro": Color("b9b0a2"),
	"painel": Color("f4f6fa"), "aco": Color("8d9bb0"), "aco_escuro": Color("4d586b"),
	"madeira": Color("b07a45"), "lona": Color("6f9a52"), "saco": Color("c4a46a"),
	"vidro": Color("6fd0ff"), "vidro_escuro": Color("2b6fae"),
	"conteiner_a": Color("d9773a"), "conteiner_b": Color("6e8d52"), "conteiner_c": Color("4f7fae"),
	"amarelo": Color("ffc21a"), "vermelho": Color("ff4a3d"), "branco": Color("ffffff"),
	"ouro": Color("f0a81c"), "neon": Color("3ef2ff"), "neon_rosa": Color("ff4fd8"),
	"solar": Color("1f3f8f"), "folha": Color("3fc75a"), "folha_clara": Color("8be36b"),
	"pele": Color("f1c27d"),
	"creme": Color("f5e6c8"), "coral": Color("ff7a59"), "terracota": Color("d9643a"),
	"tijolo": Color("c25a43"), "menta": Color("7fd6b5"), "agua": Color("37d3f0"),
}

const ALIANCAS := {
	"azul": Color("1f63e8"), "vermelha": Color("f0453a"), "verde": Color("22b860"),
	"roxa": Color("8e4dff"), "amarela": Color("ffb400"),
}

var cor_alianca: Color = ALIANCAS["azul"]
var _mats := {}
var _malhas := {}
var fonte: Font

func _init(alianca := "azul") -> void:
	cor_alianca = ALIANCAS.get(alianca, ALIANCAS["azul"])
	var fv := FontVariation.new()
	fv.base_font = load("res://fontes/Montserrat.ttf")
	var ts := TextServerManager.get_primary_interface()
	fv.variation_opentype = {ts.name_to_tag("weight"): 800}
	fonte = fv

# ---------------------------------------------------------------- materiais

func mat(cor: Color, rugosidade := 0.75, metal := 0.0, emissao := 0.0, alfa := 1.0) -> StandardMaterial3D:
	var chave := "%s|%.2f|%.2f|%.2f|%.2f" % [cor.to_html(), rugosidade, metal, emissao, alfa]
	if _mats.has(chave):
		return _mats[chave]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(cor, alfa)
	m.roughness = rugosidade
	m.metallic = metal
	m.metallic_specular = 0.5
	if emissao > 0.0:
		m.emission_enabled = true
		m.emission = cor
		m.emission_energy_multiplier = emissao
	if alfa < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mats[chave] = m
	return m

func p(nome: String, rugosidade := 0.75, metal := 0.0) -> StandardMaterial3D:
	return mat(PALETA[nome], rugosidade, metal)

func alianca(rugosidade := 0.55) -> StandardMaterial3D:
	return mat(cor_alianca, rugosidade)

func luz(cor: Color, energia := 1.6) -> StandardMaterial3D:
	return mat(cor, 0.4, 0.0, energia)

func vidro(cor := Color("6fd0ff"), reflexo := 0.65) -> StandardMaterial3D:
	return mat(cor, 0.06, reflexo)

func ouro() -> StandardMaterial3D:
	# o renderizador de compatibilidade não tem reflexo rico: ouro "pintado", não metálico
	return mat(PALETA["ouro"], 0.3, 0.3, 0.05)

func feixe(cor: Color, alfa := 0.35, energia := 3.0, aditivo := true) -> StandardMaterial3D:
	var chave := "feixe|%s|%.2f|%.2f|%s" % [cor.to_html(), alfa, energia, aditivo]
	if _mats.has(chave):
		return _mats[chave]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(cor * energia, alfa)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if aditivo:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	_mats[chave] = m
	return m

# ---------------------------------------------------------------- malhas

## Caixa com quinas chanfradas (o "bisel" é o que dá cara de brinquedo).
func malha_caixa(t: Vector3, bisel: float) -> ArrayMesh:
	var chave := "cx|%s|%.3f" % [t, bisel]
	if _malhas.has(chave):
		return _malhas[chave]
	var h := t * 0.5
	var b: float = minf(bisel, minf(h.x, minf(h.y, h.z)) * 0.95)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var P := func(eixo: int, s: Vector3) -> Vector3:
		var v := Vector3()
		for i in 3:
			v[i] = s[i] * (h[i] if i == eixo else h[i] - b)
		return v
	var tri := func(a: Vector3, bb: Vector3, c: Vector3) -> void:
		var n := (bb - a).cross(c - a).normalized()
		var centro := (a + bb + c) / 3.0
		if n.dot(centro) > 0.0:
			# Godot trata como frente o sentido horário: inverte a ordem
			st.set_normal(n); st.add_vertex(a)
			st.set_normal(n); st.add_vertex(c)
			st.set_normal(n); st.add_vertex(bb)
		else:
			n = -n
			st.set_normal(n); st.add_vertex(a)
			st.set_normal(n); st.add_vertex(bb)
			st.set_normal(n); st.add_vertex(c)
	var quad := func(a: Vector3, bb: Vector3, c: Vector3, d: Vector3) -> void:
		tri.call(a, bb, c)
		tri.call(a, c, d)
	var sinais := [-1.0, 1.0]
	# faces
	for e in 3:
		var u := (e + 1) % 3
		var w := (e + 2) % 3
		for se in sinais:
			var pts := []
			for su_sw in [[-1, -1], [1, -1], [1, 1], [-1, 1]]:
				var s := Vector3()
				s[e] = se; s[u] = su_sw[0]; s[w] = su_sw[1]
				pts.append(P.call(e, s))
			quad.call(pts[0], pts[1], pts[2], pts[3])
	if b > 0.0005:
		# arestas
		for e in 3:
			for c in range(e + 1, 3):
				var o := 3 - e - c
				for se in sinais:
					for sc in sinais:
						var s1 := Vector3(); s1[e] = se; s1[c] = sc; s1[o] = -1
						var s2 := Vector3(); s2[e] = se; s2[c] = sc; s2[o] = 1
						quad.call(P.call(e, s1), P.call(e, s2), P.call(c, s2), P.call(c, s1))
		# cantos
		for sx in sinais:
			for sy in sinais:
				for sz in sinais:
					var s := Vector3(sx, sy, sz)
					tri.call(P.call(0, s), P.call(1, s), P.call(2, s))
	var m := st.commit()
	_malhas[chave] = m
	return m

# ---------------------------------------------------------------- peças

func _no(malha: Mesh, material: Material, pos: Vector3, pai: Node3D, sombra := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.material_override = material
	mi.position = pos
	if not sombra:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pai.add_child(mi)
	return mi

## Caixa apoiada pela base: pos é o centro do chão da peça.
func caixa(pai: Node3D, pos: Vector3, t: Vector3, material: Material, bisel := 0.06) -> MeshInstance3D:
	return _no(malha_caixa(t, bisel), material, pos + Vector3(0, t.y * 0.5, 0), pai)

func cilindro(pai: Node3D, pos: Vector3, raio: float, altura: float, material: Material, lados := 16, raio_topo := -1.0) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.bottom_radius = raio
	m.top_radius = raio if raio_topo < 0.0 else raio_topo
	m.height = altura
	m.radial_segments = lados
	m.rings = 1
	return _no(m, material, pos + Vector3(0, altura * 0.5, 0), pai)

func esfera(pai: Node3D, pos: Vector3, raio: float, material: Material, achatar := 1.0) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = raio
	m.height = raio * 2.0 * achatar
	m.radial_segments = 16
	m.rings = 8
	return _no(m, material, pos, pai)

func cone(pai: Node3D, pos: Vector3, raio: float, altura: float, material: Material, lados := 8) -> MeshInstance3D:
	return cilindro(pai, pos, raio, altura, material, lados, 0.0)

func toro(pai: Node3D, pos: Vector3, raio: float, espessura: float, material: Material) -> MeshInstance3D:
	var m := TorusMesh.new()
	m.inner_radius = raio - espessura
	m.outer_radius = raio + espessura
	m.rings = 32
	m.ring_segments = 8
	return _no(m, material, pos, pai)

func grupo(pai: Node3D, pos := Vector3.ZERO, rot_y_graus := 0.0) -> Node3D:
	var g := Node3D.new()
	g.position = pos
	g.rotation_degrees.y = rot_y_graus
	pai.add_child(g)
	return g

## Janelas numa face vertical. normal: Vector3.FORWARD/BACK/LEFT/RIGHT;
## centro: centro da face; largura útil e altura da faixa de janelas.
func janelas(pai: Node3D, centro: Vector3, normal: Vector3, largura: float, y0: float, andares: int, altura_andar: float, colunas: int, material: Material, moldura: Material = null, jan := Vector2(0.42, 0.5)) -> void:
	var lado := Vector3.UP.cross(normal).normalized()
	for a in andares:
		for c in colunas:
			var f := (c + 0.5) / colunas - 0.5
			var pos := centro + lado * f * largura + normal * 0.02
			pos.y = y0 + a * altura_andar + (altura_andar - jan.y) * 0.5
			var t := Vector3(jan.x, jan.y, 0.06)
			if absf(normal.x) > 0.5:
				t = Vector3(0.06, jan.y, jan.x)
			if moldura:
				caixa(pai, pos - Vector3(0, 0.05, 0), t + Vector3(0.1, 0.1, 0.0) if absf(normal.z) > 0.5 else t + Vector3(0.0, 0.1, 0.1), moldura, 0.02)
				pos += normal * 0.02
			caixa(pai, pos, t, material, 0.02)

## Lote: placa de chão arredondada com borda de grama, onde a construção assenta.
func lote(pai: Node3D, tamanho: float, piso: Material, borda := "grama") -> void:
	caixa(pai, Vector3(0, -0.45, 0), Vector3(tamanho + 0.5, 0.45, tamanho + 0.5), p("grama_escura"), 0.18)
	caixa(pai, Vector3(0, -0.05, 0), Vector3(tamanho + 0.3, 0.12, tamanho + 0.3), p(borda), 0.08)
	caixa(pai, Vector3(0, 0.0, 0), Vector3(tamanho - 0.2, 0.1, tamanho - 0.2), piso, 0.05)

func arvore(pai: Node3D, pos: Vector3, escala := 1.0) -> void:
	cilindro(pai, pos, 0.07 * escala, 0.35 * escala, p("madeira"), 6)
	esfera(pai, pos + Vector3(0, 0.55 * escala, 0), 0.32 * escala, p("folha", 0.85))
	esfera(pai, pos + Vector3(0.12, 0.78, 0.05) * escala, 0.2 * escala, p("folha_clara", 0.85))

func pessoa(pai: Node3D, pos: Vector3, cor: Color, escala := 1.0) -> void:
	cilindro(pai, pos, 0.11 * escala, 0.3 * escala, mat(cor, 0.6), 10, 0.08 * escala)
	esfera(pai, pos + Vector3(0, 0.42 * escala, 0), 0.1 * escala, p("pele", 0.6))
	esfera(pai, pos + Vector3(0, 0.47 * escala, 0), 0.105 * escala, mat(cor.darkened(0.3), 0.6), 0.55)

func bandeira(pai: Node3D, pos: Vector3, altura: float, cor: Color, segunda: Color = Color("ffffff")) -> void:
	cilindro(pai, pos, 0.04, altura, p("aco", 0.4, 0.6), 8)
	esfera(pai, pos + Vector3(0, altura + 0.04, 0), 0.06, ouro())
	var b := grupo(pai, pos + Vector3(0, altura - 0.55, 0))
	caixa(b, Vector3(0.38, 0, 0), Vector3(0.72, 0.5, 0.03), mat(cor, 0.7), 0.01)
	caixa(b, Vector3(0.38, 0.17, 0.0), Vector3(0.72, 0.16, 0.04), mat(segunda, 0.7), 0.01)

func antena(pai: Node3D, pos: Vector3, altura: float, luz_cor := Color("ff3b30")) -> void:
	cilindro(pai, pos, 0.035, altura, p("aco", 0.4, 0.6), 6)
	cilindro(pai, pos + Vector3(0, altura * 0.6, 0), 0.12, 0.02, p("aco_escuro", 0.4, 0.6), 8)
	esfera(pai, pos + Vector3(0, altura + 0.05, 0), 0.07, luz(luz_cor, 2.0))

func drone(pai: Node3D, pos: Vector3, cor: Color) -> void:
	var g := grupo(pai, pos)
	caixa(g, Vector3.ZERO, Vector3(0.32, 0.1, 0.32), mat(cor, 0.4), 0.04)
	for d in [Vector3(1, 0, 1), Vector3(-1, 0, 1), Vector3(1, 0, -1), Vector3(-1, 0, -1)]:
		cilindro(g, d * 0.22 + Vector3(0, 0.08, 0), 0.12, 0.015, mat(Color("20242c"), 0.4, 0.0, 0.0, 0.7), 12)
	esfera(g, Vector3(0, -0.03, 0.17), 0.04, luz(PALETA["neon"], 5.0))

func painel_solar(pai: Node3D, pos: Vector3, rot_y: float, largura := 0.9) -> void:
	var g := grupo(pai, pos, rot_y)
	cilindro(g, Vector3.ZERO, 0.04, 0.35, p("aco", 0.5, 0.5), 6)
	var pl := grupo(g, Vector3(0, 0.38, 0))
	pl.rotation_degrees.x = -28
	caixa(pl, Vector3.ZERO, Vector3(largura, 0.05, 0.6), p("aco"), 0.015)
	caixa(pl, Vector3(0, 0.03, 0), Vector3(largura - 0.08, 0.03, 0.52), mat(PALETA["solar"], 0.15, 0.4), 0.01)

## Selo de nível: hexágono com o número e de 1 a 5 pontos; dourado na faixa 6.
func selo(pai: Node3D, pos: Vector3, nivel: int, pontos: int, dourado: bool, camera_basis: Basis) -> void:
	var g := Node3D.new()
	g.position = pos
	g.basis = camera_basis
	pai.add_child(g)
	var hex := CylinderMesh.new()
	hex.top_radius = 0.62; hex.bottom_radius = 0.62; hex.height = 0.16; hex.radial_segments = 6; hex.rings = 1
	var borda := CylinderMesh.new()
	borda.top_radius = 0.72; borda.bottom_radius = 0.72; borda.height = 0.12; borda.radial_segments = 6; borda.rings = 1
	var m_fundo := ouro() if dourado else mat(Color("1d2a44"), 0.5)
	var m_borda := mat(Color("fff3c4"), 0.3, 0.6) if dourado else mat(Color("ffffff"), 0.5)
	for par in [[borda, m_borda, -0.02], [hex, m_fundo, 0.0]]:
		var mi := MeshInstance3D.new()
		mi.mesh = par[0]
		mi.material_override = par[1]
		mi.rotation_degrees = Vector3(90, 0, 30)
		mi.position.z = par[2]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.add_child(mi)
	var l := Label3D.new()
	l.text = str(nivel)
	l.font = fonte
	l.font_size = 120
	l.pixel_size = 0.0045
	l.outline_size = 10
	l.modulate = Color.WHITE
	l.outline_modulate = Color("7a4a00") if dourado else Color("0b1324")
	l.no_depth_test = true
	l.render_priority = 10
	l.position = Vector3(0, 0.06, 0.12)
	l.shaded = false
	g.add_child(l)
	for i in pontos:
		var x := (i - (pontos - 1) * 0.5) * 0.17
		var d := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.055; s.height = 0.11; s.radial_segments = 10; s.rings = 5
		d.mesh = s
		d.material_override = luz(Color("fff1a8") if dourado else Color("7fe3ff"), 2.5)
		d.position = Vector3(x, -0.36, 0.1)
		d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.add_child(d)

func veiculo(pai: Node3D, pos: Vector3, rot_y: float, cor: Color, tipo := "jipe") -> void:
	var g := grupo(pai, pos, rot_y)
	var comp := 1.1 if tipo == "jipe" else 1.6
	caixa(g, Vector3(0, 0.12, 0), Vector3(comp, 0.32, 0.6), mat(cor, 0.45), 0.08)
	if tipo == "jipe":
		caixa(g, Vector3(-0.1, 0.44, 0), Vector3(0.55, 0.26, 0.54), mat(cor, 0.45), 0.06)
		caixa(g, Vector3(0.18, 0.46, 0), Vector3(0.03, 0.2, 0.46), vidro(), 0.01)
	else:
		caixa(g, Vector3(0.5, 0.44, 0), Vector3(0.5, 0.36, 0.58), mat(cor, 0.45), 0.06)
		caixa(g, Vector3(0.76, 0.5, 0), Vector3(0.03, 0.22, 0.48), vidro(), 0.01)
		caixa(g, Vector3(-0.3, 0.44, 0), Vector3(0.95, 0.4, 0.6), p("aco"), 0.04)
	for x in [-comp * 0.32, comp * 0.32]:
		for z in [-0.3, 0.3]:
			var r := cilindro(g, Vector3.ZERO, 0.14, 0.12, mat(Color("23262d"), 0.8), 12)
			r.rotation_degrees.x = 90
			r.position = Vector3(x, 0.14, z)

## Grade de janelas acesas (pontos de luz) numa face, para torres.
func luzes_fachada(pai: Node3D, centro: Vector3, normal: Vector3, largura: float, y0: float, y1: float, passo: Vector2, cor: Color, chance := 0.55, semente := 7) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var lado := Vector3.UP.cross(normal).normalized()
	var cols := int(largura / passo.x)
	var y := y0 + passo.y * 0.5
	while y < y1:
		for c in cols:
			if rng.randf() < chance:
				var f := (c + 0.5) / cols - 0.5
				var pos := centro + lado * f * largura + normal * 0.03
				pos.y = y
				var t := Vector3(passo.x * 0.55, passo.y * 0.4, 0.02)
				if absf(normal.x) > 0.5:
					t = Vector3(0.02, passo.y * 0.4, passo.x * 0.55)
				caixa(pai, pos, t, luz(cor, 1.6), 0.0)
		y += passo.y

# ---------------------------------------------------------------- conjuntos

func conteiner(pai: Node3D, pos: Vector3, rot: float, cor: Color, porta := false) -> void:
	var g := grupo(pai, pos, rot)
	var m := mat(cor, 0.85)
	var friso := mat(cor.darkened(0.18), 0.85)
	caixa(g, Vector3.ZERO, Vector3(2.4, 1.0, 1.0), m, 0.05)
	for i in 11:
		var x := -1.0 + i * 0.2
		for z in [-0.51, 0.51]:
			caixa(g, Vector3(x, 0.08, z), Vector3(0.07, 0.84, 0.03), friso, 0.01)
	for z in [-0.25, 0.25]:
		caixa(g, Vector3(1.21, 0.08, z), Vector3(0.03, 0.84, 0.42), friso, 0.01)
	if porta:
		caixa(g, Vector3(0.3, 0.02, 0.53), Vector3(0.5, 0.8, 0.04), mat(Color("3b3f48"), 0.7), 0.02)
		caixa(g, Vector3(-0.5, 0.45, 0.53), Vector3(0.55, 0.3, 0.04), vidro(Color("9fe0ff"), 0.3), 0.02)

## Base comum da faixa 6 (Elite): piso na cor da aliança, friso dourado e campo de energia.
func base_elite(pai: Node3D, tamanho: float) -> void:
	lote(pai, tamanho, mat(cor_alianca.darkened(0.55), 0.35, 0.2))
	toro(pai, Vector3(0, 0.16, 0), 2.45, 0.05, ouro())
	toro(pai, Vector3(0, 0.12, 0), 2.75, 0.06, luz(PALETA["neon"], 3.5))
	cilindro(pai, Vector3(0, 0.1, 0), 2.75, 0.45, feixe(PALETA["neon"], 0.12, 1.0), 48)

## Toldo listrado (aliança e branco). pos = meio da borda presa à parede; normal = para onde avança.
func toldo(pai: Node3D, pos: Vector3, normal: Vector3, largura: float, fundo := 0.6, listras := 6) -> void:
	var g := grupo(pai, pos, rad_to_deg(atan2(normal.x, normal.z)))
	var inc := grupo(g, Vector3.ZERO)
	inc.rotation_degrees.x = 22
	for i in listras:
		var x := (i + 0.5) / listras * largura - largura * 0.5
		caixa(inc, Vector3(x, 0, fundo * 0.5), Vector3(largura / listras, 0.04, fundo), alianca(0.7) if i % 2 == 0 else p("branco", 0.7), 0.0)

## Fileira de plantas a partir de pos, na direção dir. tipo: alface, tomate, broto, luminosa.
func fileira(pai: Node3D, pos: Vector3, dir: Vector3, n: int, passo: float, tipo := "alface", escala := 1.0) -> void:
	for i in n:
		var q := pos + dir * (i * passo)
		match tipo:
			"tomate":
				cilindro(pai, q, 0.015 * escala, 0.45 * escala, p("madeira"), 4)
				esfera(pai, q + Vector3(0, 0.3, 0) * escala, 0.16 * escala, p("folha", 0.85))
				esfera(pai, q + Vector3(0.08, 0.28, 0.08) * escala, 0.05 * escala, p("vermelho", 0.5))
				esfera(pai, q + Vector3(-0.07, 0.36, 0.04) * escala, 0.045 * escala, p("vermelho", 0.5))
			"broto":
				esfera(pai, q + Vector3(0, 0.05, 0) * escala, 0.07 * escala, p("folha_clara", 0.8), 0.7)
			"luminosa":
				esfera(pai, q + Vector3(0, 0.12, 0) * escala, 0.13 * escala, luz(Color("6dff9e"), 0.9), 0.8)
				esfera(pai, q + Vector3(0.06, 0.2, 0) * escala, 0.07 * escala, luz(Color("c6ff6a"), 1.1))
			_:
				esfera(pai, q + Vector3(0, 0.07, 0) * escala, 0.12 * escala, p("folha_clara", 0.85), 0.75)
				esfera(pai, q + Vector3(0, 0.1, 0) * escala, 0.07 * escala, p("folha", 0.85))

## Túnel de meio cilindro ao longo de X (estufa de plástico): segmentos planos e arcos.
func tunel(pai: Node3D, pos: Vector3, raio: float, comp: float, pele: Material, arco_m: Material, segmentos := 7, arcos := 5) -> void:
	for s in segmentos:
		var a0 := PI * s / segmentos
		var a1 := PI * (s + 1) / segmentos
		var p0 := Vector3(0, sin(a0), cos(a0)) * raio
		var p1 := Vector3(0, sin(a1), cos(a1)) * raio
		var g := grupo(pai, pos + (p0 + p1) * 0.5)
		g.rotation.x = -(a0 + a1) * 0.5 + PI * 0.5
		_no(malha_caixa(Vector3(comp, 0.02, p0.distance_to(p1) + 0.01), 0.0), pele, Vector3.ZERO, g, false)
	for i in arcos:
		var x := -comp * 0.5 + comp * i / (arcos - 1)
		arco(pai, pos + Vector3(x, 0, 0), raio + 0.02, 90.0, 0.05, arco_m)

## Cúpula (meia esfera) de vidro com nervuras.
func cupula(pai: Node3D, pos: Vector3, raio: float, pele: Material, nervura: Material, nervuras := 8) -> void:
	var m := SphereMesh.new()
	m.radius = raio; m.height = raio; m.is_hemisphere = true; m.radial_segments = 32; m.rings = 12
	_no(m, pele, pos, pai, false)
	for i in nervuras:
		arco(pai, pos, raio + 0.02, 180.0 * i / nervuras, 0.06, nervura, 12)
	for h in [0.35, 0.7]:
		toro(pai, pos + Vector3(0, raio * h, 0), raio * sqrt(1.0 - h * h), 0.03, nervura)

## Meio arco vertical (semicírculo acima do chão), girado rot_y graus em torno de Y.
func arco(pai: Node3D, centro: Vector3, raio: float, rot_y: float, espessura: float, material: Material, segmentos := 9) -> void:
	var g := grupo(pai, centro, rot_y)
	for s in segmentos:
		var a0 := PI * s / segmentos
		var a1 := PI * (s + 1) / segmentos
		var p0 := Vector3(cos(a0), sin(a0), 0) * raio
		var p1 := Vector3(cos(a1), sin(a1), 0) * raio
		var h := grupo(g, (p0 + p1) * 0.5)
		h.rotation.z = (a0 + a1) * 0.5 - PI * 0.5
		_no(malha_caixa(Vector3(p0.distance_to(p1) + 0.02, espessura, espessura), 0.0), material, Vector3.ZERO, h)

func helicoptero(pai: Node3D, pos: Vector3, rot_y: float, cor: Color) -> void:
	var g := grupo(pai, pos, rot_y)
	caixa(g, Vector3(0, 0.12, 0), Vector3(1.1, 0.5, 0.55), mat(cor, 0.45), 0.2)
	caixa(g, Vector3(0.35, 0.25, 0), Vector3(0.36, 0.3, 0.5), vidro(Color("8fdcff"), 0.5), 0.12)
	caixa(g, Vector3(-0.95, 0.32, 0), Vector3(0.9, 0.12, 0.12), mat(cor, 0.45), 0.04)
	caixa(g, Vector3(-1.35, 0.32, 0), Vector3(0.12, 0.4, 0.04), mat(cor.darkened(0.2), 0.45), 0.02)
	for z in [-0.3, 0.3]:
		caixa(g, Vector3(0, 0, z), Vector3(1.0, 0.04, 0.05), p("aco_escuro"), 0.01)
	cilindro(g, Vector3(0, 0.62, 0), 0.05, 0.12, p("aco_escuro"), 8)
	for a in [0, 90]:
		var h := grupo(g, Vector3(0, 0.75, 0), a + 20)
		caixa(h, Vector3.ZERO, Vector3(2.0, 0.025, 0.1), p("aco_escuro", 0.5), 0.0)

func guindaste(pai: Node3D, pos: Vector3, rot_y: float, altura: float, braco: float, cor: Color) -> void:
	var g := grupo(pai, pos, rot_y)
	caixa(g, Vector3.ZERO, Vector3(0.6, 0.15, 0.6), p("concreto_escuro"), 0.03)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			caixa(g, Vector3(sx * 0.12, 0.15, sz * 0.12), Vector3(0.05, altura, 0.05), mat(cor, 0.5), 0.0)
	for i in int(altura / 0.4):
		caixa(g, Vector3(0, 0.3 + i * 0.4, 0), Vector3(0.3, 0.03, 0.3), mat(cor, 0.5), 0.0)
	caixa(g, Vector3(0, altura + 0.15, 0), Vector3(0.4, 0.3, 0.4), mat(cor, 0.5), 0.04)
	caixa(g, Vector3(braco * 0.5 - 0.5, altura + 0.45, 0), Vector3(braco, 0.12, 0.14), mat(cor, 0.5), 0.02)
	caixa(g, Vector3(-0.7, altura + 0.3, 0), Vector3(0.4, 0.3, 0.3), p("concreto_escuro"), 0.03)
	caixa(g, Vector3(braco - 0.8, altura - 0.6, 0), Vector3(0.015, 1.05, 0.015), p("aco_escuro"), 0.0)
	caixa(g, Vector3(braco - 0.8, altura - 0.75, 0), Vector3(0.1, 0.12, 0.1), p("amarelo", 0.5), 0.02)

func poste(pai: Node3D, pos: Vector3, altura := 1.3, cor_luz := Color("fff1b0"), inteligente := false) -> void:
	cilindro(pai, pos, 0.035, altura, p("aco_escuro", 0.5), 8)
	caixa(pai, pos + Vector3(0.12, altura, 0), Vector3(0.32, 0.06, 0.1), p("aco_escuro", 0.5), 0.02)
	caixa(pai, pos + Vector3(0.2, altura - 0.03, 0), Vector3(0.14, 0.03, 0.08), luz(cor_luz, 1.5), 0.0)
	if inteligente:
		caixa(pai, pos + Vector3(0, altura * 0.55, 0), Vector3(0.1, 0.25, 0.1), mat(Color("20242c"), 0.4), 0.02)
		caixa(pai, pos + Vector3(0, altura * 0.55 + 0.04, 0.051), Vector3(0.07, 0.15, 0.01), luz(PALETA["neon"], 1.2), 0.0)

func banco(pai: Node3D, pos: Vector3, rot_y := 0.0) -> void:
	var g := grupo(pai, pos, rot_y)
	caixa(g, Vector3(0, 0.15, 0), Vector3(0.6, 0.05, 0.2), p("madeira"), 0.01)
	caixa(g, Vector3(0, 0.2, -0.09), Vector3(0.6, 0.18, 0.04), p("madeira"), 0.01)
	for x in [-0.25, 0.25]:
		caixa(g, Vector3(x, 0, 0), Vector3(0.04, 0.15, 0.18), p("aco_escuro"), 0.0)

func turbina(pai: Node3D, pos: Vector3, altura: float, rot_y := 30.0, cor := Color("f4f6fa")) -> void:
	cilindro(pai, pos, 0.09, altura, mat(cor, 0.4), 10, 0.05)
	var g := grupo(pai, pos + Vector3(0, altura, 0), rot_y)
	caixa(g, Vector3(0, -0.07, -0.08), Vector3(0.16, 0.16, 0.36), mat(cor, 0.4), 0.05)
	var r := grupo(g, Vector3(0, 0, 0.13))
	esfera(r, Vector3.ZERO, 0.08, mat(cor, 0.4))
	for i in 3:
		var pa := Node3D.new()
		pa.rotation.z = i * TAU / 3 + 0.4
		r.add_child(pa)
		caixa(pa, Vector3(0, 0.05, 0), Vector3(0.09, altura * 0.42, 0.03), mat(cor, 0.4), 0.02)

func tenda(pai: Node3D, pos: Vector3, rot_y: float, cor: Color, comp := 1.4, larg := 1.1) -> void:
	var g := grupo(pai, pos, rot_y)
	var h := larg * 0.55
	for s in [-1, 1]:
		var lado := grupo(g, Vector3(0, h * 0.5, s * larg * 0.25))
		lado.rotation.x = -s * atan2(larg * 0.5, h)
		caixa(lado, Vector3(0, -sqrt(h * h + larg * larg * 0.25) * 0.5, 0), Vector3(comp, sqrt(h * h + larg * larg * 0.25), 0.03), mat(cor, 0.9), 0.0)
	caixa(g, Vector3(comp * 0.5, 0, 0), Vector3(0.02, h * 0.8, larg * 0.4), mat(cor.darkened(0.35), 0.9), 0.0)

func blindado(pai: Node3D, pos: Vector3, rot_y: float, cor: Color, canhao := true) -> void:
	var g := grupo(pai, pos, rot_y)
	for z in [-0.32, 0.32]:
		caixa(g, Vector3(0, 0, z), Vector3(1.3, 0.25, 0.22), p("aco_escuro", 0.8), 0.08)
	caixa(g, Vector3(0, 0.2, 0), Vector3(1.2, 0.25, 0.8), mat(cor, 0.6), 0.06)
	if canhao:
		caixa(g, Vector3(-0.1, 0.45, 0), Vector3(0.6, 0.22, 0.55), mat(cor.darkened(0.1), 0.6), 0.08)
		cilindro(g, Vector3(0.5, 0.17, 0), 0.04, 0.75, p("aco_escuro"), 8).rotation_degrees.z = -90
