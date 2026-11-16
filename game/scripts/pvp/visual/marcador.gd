extends RefCounted
## Marcador de paintball do Valdora (sessão 1.8): corpo de fuzil de assalto com funil de tinta
## (hopper) em cima, montado por código em baixo polígono. Três superfícies: 0 pintura
## (aparência da loja), 1 peças pretas, 2 funil. O cano aponta para -Z; a origem fica no punho.
## Uso: MARCADOR.novo("labareda") devolve um MeshInstance3D pronto.

const PINTURA := preload("res://scripts/pvp/visual/pintura_marcador.gdshader")
const DADOS := "res://data/pvp/aparencias.json"
const PADRAO := "mare_alta"

static var _malha: ArrayMesh
static var _malha_pistola: ArrayMesh
static var _malha_granada: ArrayMesh
static var _aparencias: Array = []
static var _mats := {}
static var _preto: StandardMaterial3D

static func aparencias() -> Array:
	if _aparencias.is_empty():
		var f := FileAccess.open(DADOS, FileAccess.READ)
		if f != null:
			_aparencias = JSON.parse_string(f.get_as_text()).get("aparencias", [])
	return _aparencias

static func aparencia(id: String) -> Dictionary:
	for a in aparencias():
		if a.id == id:
			return a
	return aparencias()[0] if not aparencias().is_empty() else {}

static func novo(id := PADRAO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Marcador"
	mi.mesh = malha()
	aplicar(mi, id)
	return mi

## Pistola de tinta (arma 06) e granada de tinta (arma 14), com a mesma pintura.
static func nova_pistola(id := PADRAO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Pistola"
	mi.mesh = malha_pistola()
	aplicar(mi, id)
	return mi

static func nova_granada(id := PADRAO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Granada"
	mi.mesh = malha_granada()
	aplicar(mi, id)
	return mi

static func aplicar(mi: MeshInstance3D, id: String) -> void:
	var ap := aparencia(id)
	mi.set_surface_override_material(0, _material(ap, false))
	mi.set_surface_override_material(1, _material_preto())
	mi.set_surface_override_material(2, _material(ap, true))
	mi.set_meta("aparencia", ap.get("id", id))

static func _material_preto() -> StandardMaterial3D:
	if _preto == null:
		_preto = StandardMaterial3D.new()
		_preto.albedo_color = Color("1f2227")
		_preto.roughness = 0.5
		_preto.metallic = 0.2
	return _preto

static func _material(ap: Dictionary, funil: bool) -> ShaderMaterial:
	var k := "%s|%s" % [ap.get("id", ""), funil]
	if _mats.has(k):
		return _mats[k]
	var m := ShaderMaterial.new()
	m.shader = PINTURA
	var c1 := Color(ap.get("c1", "#3060d0"))
	var c2 := Color(ap.get("c2", ap.get("c1", "#3060d0")))
	var c3 := Color(ap.get("c3", ap.get("c2", ap.get("c1", "#3060d0"))))
	if funil:
		var ch := Color(ap.get("hopper", "#20242c"))
		var tipo := int(ap.get("tipo", 0))
		m.set_shader_parameter("tipo", 0 if tipo in [0, 9] else 2)
		m.set_shader_parameter("c1", ch)
		m.set_shader_parameter("c2", c2 if ch != c2 else c1)
		m.set_shader_parameter("c3", c1 if ch != c1 else c3)
		m.set_shader_parameter("escala", 1.5)
		m.set_shader_parameter("hopper", 1.0)
		m.set_shader_parameter("metal", float(ap.get("metal", 0.0)) * 0.5)
	else:
		m.set_shader_parameter("tipo", int(ap.get("tipo", 0)))
		m.set_shader_parameter("c1", c1)
		m.set_shader_parameter("c2", c2)
		m.set_shader_parameter("c3", c3)
		m.set_shader_parameter("escala", float(ap.get("escala", 1.0)))
		m.set_shader_parameter("emblema", int(ap.get("emblema", 0)))
		m.set_shader_parameter("cor_emblema", Color(ap.get("cor_emblema", "#ffffff")))
		m.set_shader_parameter("metal", float(ap.get("metal", 0.0)))
		m.set_shader_parameter("neon", float(ap.get("neon", 0.0)))
	_mats[k] = m
	return m

# ---------------------------------------------------------------- geometria

static func malha() -> ArrayMesh:
	if _malha != null:
		return _malha
	var partes := [SurfaceTool.new(), SurfaceTool.new(), SurfaceTool.new()]
	for st in partes:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var X := Basis(Vector3.RIGHT, PI * 0.5)   # cilindro deitado ao longo de Z
	# 0: corpo pintado
	_caixa(partes[0], Vector3(0.06, 0.085, 0.30), Vector3(0, 0, -0.10))          # receptor
	_caixa(partes[0], Vector3(0.058, 0.07, 0.20), Vector3(0, -0.004, -0.34))     # guarda-mão
	_caixa(partes[0], Vector3(0.046, 0.09, 0.06), Vector3(0, -0.085, -0.17), Basis(Vector3.RIGHT, -0.12))  # pente de ar
	_caixa(partes[0], Vector3(0.05, 0.085, 0.15), Vector3(0, -0.012, 0.14))      # coronha
	# 1: peças pretas
	_caixa(partes[1], Vector3(0.032, 0.016, 0.28), Vector3(0, 0.05, -0.12))      # trilho
	for i in 3:
		_caixa(partes[1], Vector3(0.062, 0.014, 0.035), Vector3(0, 0.0, -0.29 - i * 0.05))  # respiros do guarda-mão
	_cilindro(partes[1], 0.016, 0.24, Vector3(0, 0.004, -0.55), X)               # cano
	_cilindro(partes[1], 0.023, 0.05, Vector3(0, 0.004, -0.66), X)               # boca
	_caixa(partes[1], Vector3(0.04, 0.11, 0.05), Vector3(0, -0.085, 0.01), Basis(Vector3.RIGHT, -0.28))   # punho
	_caixa(partes[1], Vector3(0.012, 0.012, 0.075), Vector3(0, -0.058, -0.06))  # guarda-mato
	_caixa(partes[1], Vector3(0.056, 0.105, 0.026), Vector3(0, -0.02, 0.225))    # soleira
	_cilindro(partes[1], 0.014, 0.08, Vector3(0, 0.01, 0.04), X)                 # tubo da coronha
	_cilindro(partes[1], 0.02, 0.05, Vector3(0, 0.078, -0.07))                   # pescoço do funil
	_caixa(partes[1], Vector3(0.032, 0.036, 0.05), Vector3(0, 0.075, 0.07))      # mira
	_caixa(partes[1], Vector3(0.008, 0.03, 0.02), Vector3(0, 0.07, -0.42))       # alça da frente
	# 2: funil de tinta (hopper)
	_esfera(partes[2], Vector3(0.078, 0.062, 0.135), Vector3(0, 0.135, -0.07))
	_caixa(partes[2], Vector3(0.05, 0.012, 0.09), Vector3(0, 0.196, -0.07))      # tampa
	_malha = ArrayMesh.new()
	for st in partes:
		st.commit(_malha)
	return _malha

static func malha_pistola() -> ArrayMesh:
	if _malha_pistola != null:
		return _malha_pistola
	var partes := [SurfaceTool.new(), SurfaceTool.new(), SurfaceTool.new()]
	for st in partes:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var X := Basis(Vector3.RIGHT, PI * 0.5)
	_caixa(partes[0], Vector3(0.045, 0.06, 0.22), Vector3(0, 0.02, -0.08))          # ferrolho pintado
	_caixa(partes[1], Vector3(0.04, 0.12, 0.05), Vector3(0, -0.06, 0.0), Basis(Vector3.RIGHT, -0.22))  # punho
	_caixa(partes[1], Vector3(0.01, 0.01, 0.06), Vector3(0, -0.025, -0.06))         # guarda-mato
	_cilindro(partes[1], 0.013, 0.07, Vector3(0, 0.025, -0.22), X)                  # cano
	_caixa(partes[1], Vector3(0.012, 0.016, 0.02), Vector3(0, 0.058, -0.17))        # alça
	_cilindro(partes[2], 0.022, 0.09, Vector3(0, -0.035, 0.07), Basis(Vector3.RIGHT, 0.9))  # cilindro de ar
	_malha_pistola = ArrayMesh.new()
	for st in partes:
		st.commit(_malha_pistola)
	return _malha_pistola

static func malha_granada() -> ArrayMesh:
	if _malha_granada != null:
		return _malha_granada
	var partes := [SurfaceTool.new(), SurfaceTool.new(), SurfaceTool.new()]
	for st in partes:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_esfera(partes[0], Vector3(0.05, 0.06, 0.05), Vector3.ZERO)                     # corpo de tinta
	_cilindro(partes[1], 0.018, 0.03, Vector3(0, 0.068, 0))                         # bocal
	_caixa(partes[1], Vector3(0.012, 0.05, 0.02), Vector3(0.028, 0.06, 0), Basis(Vector3.BACK, -0.4))  # alavanca
	_esfera(partes[2], Vector3(0.012, 0.012, 0.012), Vector3(-0.022, 0.085, 0))     # pino
	_malha_granada = ArrayMesh.new()
	for st in partes:
		st.commit(_malha_granada)
	return _malha_granada

static func _anexar(st: SurfaceTool, m: PrimitiveMesh, t: Transform3D) -> void:
	st.append_from(m, 0, t)

static func _caixa(st: SurfaceTool, tam: Vector3, pos: Vector3, b := Basis.IDENTITY) -> void:
	var m := BoxMesh.new()
	m.size = tam
	_anexar(st, m, Transform3D(b, pos))

static func _cilindro(st: SurfaceTool, r: float, comp: float, pos: Vector3, b := Basis.IDENTITY) -> void:
	var m := CylinderMesh.new()
	m.top_radius = r; m.bottom_radius = r; m.height = comp
	m.radial_segments = 10; m.rings = 1
	_anexar(st, m, Transform3D(b, pos))

static func _esfera(st: SurfaceTool, raio: Vector3, pos: Vector3) -> void:
	var m := SphereMesh.new()
	m.radius = 1.0; m.height = 2.0
	m.radial_segments = 14; m.rings = 8
	_anexar(st, m, Transform3D(Basis.from_scale(raio), pos))
