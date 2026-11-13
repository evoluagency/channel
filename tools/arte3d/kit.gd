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

func feixe(cor: Color, alfa := 0.35, energia := 3.0) -> StandardMaterial3D:
	var chave := "feixe|%s|%.2f|%.2f" % [cor.to_html(), alfa, energia]
	if _mats.has(chave):
		return _mats[chave]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(cor * energia, alfa)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
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
