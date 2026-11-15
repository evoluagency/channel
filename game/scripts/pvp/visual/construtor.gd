extends RefCounted
## Junta a geometria do cenário por material: cada material vira uma malha só (poucas chamadas
## de desenho no celular). Caixas, cilindros, prismas (telhado) e planos, com rotação em Y.

const SUP := preload("res://scripts/pvp/visual/superficie.gdshader")
const AGUA := preload("res://scripts/pvp/visual/agua.gdshader")

var _st := {}        # chave -> SurfaceTool
var _mat := {}       # chave -> Material
var _tri := 0

## Material procedural (ver superficie.gdshader para os tipos).
func sup(chave: String, tipo: int, a: Color, b: Color, escala := 1.0, sujeira := 0.35, rug := 0.85, metal := 0.0) -> String:
	if not _mat.has(chave):
		var m := ShaderMaterial.new()
		m.shader = SUP
		m.set_shader_parameter("tipo", tipo)
		m.set_shader_parameter("cor_a", a)
		m.set_shader_parameter("cor_b", b)
		m.set_shader_parameter("escala", escala)
		m.set_shader_parameter("sujeira", sujeira)
		m.set_shader_parameter("rugosidade", rug)
		m.set_shader_parameter("metal", metal)
		_mat[chave] = m
	return chave

## Material liso (vidro, pintura, luz).
func liso(chave: String, cor: Color, rug := 0.6, metal := 0.0, luz := 0.0, alfa := 1.0) -> String:
	if not _mat.has(chave):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(cor, alfa)
		m.roughness = rug
		m.metallic = metal
		if luz > 0.0:
			m.emission_enabled = true
			m.emission = cor
			m.emission_energy_multiplier = luz
		if alfa < 1.0:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mat[chave] = m
	return chave

func agua(chave: String, rasa: Color, funda: Color) -> String:
	if not _mat.has(chave):
		var m := ShaderMaterial.new()
		m.shader = AGUA
		m.set_shader_parameter("cor_rasa", rasa)
		m.set_shader_parameter("cor_funda", funda)
		_mat[chave] = m
	return chave

func _s(chave: String) -> SurfaceTool:
	if not _st.has(chave):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_st[chave] = st
	return _st[chave]

func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var n := (b - a).cross(c - a).normalized()
	for v in [a, c, b, a, d, c]:
		st.set_normal(n)
		st.add_vertex(v)
	_tri += 2

## Caixa apoiada pela base. base = centro do chão da caixa; rot = giro em Y (radianos).
## sem_base: não gera a face de baixo (ninguém vê).
func caixa(base: Vector3, t: Vector3, chave: String, rot := 0.0, sem_base := true) -> void:
	var st := _s(chave)
	var h := t * 0.5
	var bs := Basis(Vector3.UP, rot)
	var c := base + Vector3(0, h.y, 0)
	var p := func(x: float, y: float, z: float) -> Vector3:
		return c + bs * Vector3(x * h.x, y * h.y, z * h.z)
	# topo
	_quad(st, p.call(-1, 1, -1), p.call(1, 1, -1), p.call(1, 1, 1), p.call(-1, 1, 1))
	if not sem_base:
		_quad(st, p.call(-1, -1, 1), p.call(1, -1, 1), p.call(1, -1, -1), p.call(-1, -1, -1))
	# lados
	_quad(st, p.call(-1, -1, 1), p.call(1, -1, 1), p.call(1, 1, 1), p.call(-1, 1, 1))      # +Z
	_quad(st, p.call(1, -1, -1), p.call(-1, -1, -1), p.call(-1, 1, -1), p.call(1, 1, -1))  # -Z
	_quad(st, p.call(1, -1, 1), p.call(1, -1, -1), p.call(1, 1, -1), p.call(1, 1, 1))      # +X
	_quad(st, p.call(-1, -1, -1), p.call(-1, -1, 1), p.call(-1, 1, 1), p.call(-1, 1, -1))  # -X

func cilindro(base: Vector3, raio: float, altura: float, chave: String, lados := 10, raio_topo := -1.0) -> void:
	var st := _s(chave)
	var rt := raio if raio_topo < 0.0 else raio_topo
	for i in lados:
		var a0 := TAU * i / lados
		var a1 := TAU * (i + 1) / lados
		var b0 := base + Vector3(cos(a0) * raio, 0, sin(a0) * raio)
		var b1 := base + Vector3(cos(a1) * raio, 0, sin(a1) * raio)
		var t0 := base + Vector3(cos(a0) * rt, altura, sin(a0) * rt)
		var t1 := base + Vector3(cos(a1) * rt, altura, sin(a1) * rt)
		_quad(st, b1, b0, t0, t1)
		if rt > 0.001:
			var topo := base + Vector3(0, altura, 0)
			for v in [topo, t1, t0]:
				st.set_normal(Vector3.UP)
				st.add_vertex(v)
			_tri += 1

## Esfera achatada simples (copa de árvore, cúpula).
func esfera(centro: Vector3, raio: Vector3, chave: String, seg := 8, aneis := 5, meia := false) -> void:
	var st := _s(chave)
	var a_max := aneis / 2 if meia else aneis
	for r in a_max:
		var f0 := PI * r / aneis
		var f1 := PI * (r + 1) / aneis
		for s in seg:
			var t0 := TAU * s / seg
			var t1 := TAU * (s + 1) / seg
			var v := func(f: float, t: float) -> Vector3:
				return centro + Vector3(sin(f) * cos(t) * raio.x, cos(f) * raio.y, sin(f) * sin(t) * raio.z)
			_quad(st, v.call(f0, t0), v.call(f0, t1), v.call(f1, t1), v.call(f1, t0))

## Telhado de duas águas sobre um retângulo (cumeeira no eixo maior).
func telhado(base: Vector3, t: Vector3, altura: float, chave: String, beiral := 0.35) -> void:
	var st := _s(chave)
	var hx := t.x * 0.5 + beiral
	var hz := t.z * 0.5 + beiral
	var y := base.y
	if t.x >= t.z:
		var a := base + Vector3(-hx, 0, -hz); var b := base + Vector3(hx, 0, -hz)
		var c := base + Vector3(hx, 0, hz); var d := base + Vector3(-hx, 0, hz)
		var e := base + Vector3(-hx, altura, 0); var f := base + Vector3(hx, altura, 0)
		_quad(st, a, b, f, e)
		_quad(st, c, d, e, f)
		for tri in [[d, a, e], [b, c, f]]:
			var n: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0]).normalized()
			for v in tri:
				st.set_normal(n)
				st.add_vertex(v)
	else:
		var a := base + Vector3(-hx, 0, -hz); var b := base + Vector3(hx, 0, -hz)
		var c := base + Vector3(hx, 0, hz); var d := base + Vector3(-hx, 0, hz)
		var e := base + Vector3(0, altura, -hz); var f := base + Vector3(0, altura, hz)
		_quad(st, b, c, f, e)
		_quad(st, d, a, e, f)
		for tri in [[a, b, e], [c, d, f]]:
			var n: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0]).normalized()
			for v in tri:
				st.set_normal(n)
				st.add_vertex(v)
	_tri += 6

## Plano horizontal (água, marcações no chão).
func plano(centro: Vector3, t: Vector2, chave: String) -> void:
	var st := _s(chave)
	var h := t * 0.5
	_quad(st, centro + Vector3(-h.x, 0, h.y), centro + Vector3(h.x, 0, h.y), centro + Vector3(h.x, 0, -h.y), centro + Vector3(-h.x, 0, -h.y))

## Cria um MeshInstance3D por material e devolve quantos foram (= chamadas de desenho).
func montar(pai: Node3D, sombra := true) -> int:
	var n := 0
	for chave in _st:
		var st: SurfaceTool = _st[chave]
		var mi := MeshInstance3D.new()
		mi.name = "Cenario_" + chave
		mi.mesh = st.commit()
		mi.material_override = _mat.get(chave)
		if not sombra or chave.begins_with("agua") or chave.begins_with("luz"):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pai.add_child(mi)
		n += 1
	_st.clear()
	return n

func triangulos() -> int:
	return _tri
