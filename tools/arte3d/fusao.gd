extends RefCounted
## Fusão das peças de uma construção numa malha só (sessão 1.6, M8).
##
## Cada material do kit vira atributo de vértice, e não superfície própria:
##   COLOR = cor (sRGB, como no kit; alfa = transparência)
##   UV    = (rugosidade, metal)
##   UV2   = (energia de emissão, multiplicador da cor dos feixes)
## Sobram no máximo cinco superfícies por construção, uma por tipo de mistura:
##   opaco · translucido (vidro e fumaça) · feixe (sem luz, mistura normal) · aditivo · sem_sombra
## O nível de detalhe 1 tira as peças marcadas pelo kit (pessoas, drones, veículos, bancos,
## plantas), as peças com menos de MIUDA unidades no maior lado e as tiras finas (frisos,
## juntas) com menos de FINA na medida do meio. Pode vir de uma segunda montagem com o kit em
## modo "longe" (menos segmentos).
## Nós que não são malha (o letreiro Label3D) voltam em "extras", com o transform relativo.

const MIUDA := 0.3
const FINA := 0.09
const GRUPOS := ["opaco", "translucido", "feixe", "aditivo"]

## No GL Compatibility a cor de vértice já chega como o albedo do StandardMaterial3D:
## conferido pixel a pixel contra as folhas (diferença média 0,0). Por isso lin() é identidade.
const _LIN := """
vec3 lin(vec3 c) {
	return c;
}
"""

const SHADERS := {
	"opaco": "shader_type spatial;\nrender_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;\n%s\nvoid fragment() {\n\tvec3 a = lin(COLOR.rgb);\n\tALBEDO = a;\n\tROUGHNESS = UV.x;\n\tMETALLIC = UV.y;\n\tSPECULAR = 0.5;\n\tEMISSION = a * UV2.x;\n}\n",
	"translucido": "shader_type spatial;\nrender_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;\n%s\nvoid fragment() {\n\tvec3 a = lin(COLOR.rgb);\n\tALBEDO = a;\n\tROUGHNESS = UV.x;\n\tMETALLIC = UV.y;\n\tSPECULAR = 0.5;\n\tEMISSION = a * UV2.x;\n\tALPHA = COLOR.a;\n}\n",
	"feixe": "shader_type spatial;\nrender_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;\n%s\nvoid fragment() {\n\tALBEDO = lin(COLOR.rgb * UV2.y);\n\tALPHA = COLOR.a;\n}\n",
	"aditivo": "shader_type spatial;\nrender_mode blend_add, depth_draw_opaque, cull_disabled, unshaded;\n%s\nvoid fragment() {\n\tALBEDO = lin(COLOR.rgb * UV2.y);\n\tALPHA = COLOR.a;\n}\n",
}

static var _materiais := {}

## Material compartilhado de um grupo (um por grupo em toda a cidade).
static func material(grupo: String) -> ShaderMaterial:
	var g := "opaco" if grupo == "sem_sombra" else grupo
	if not _materiais.has(g):
		var sh := Shader.new()
		sh.code = SHADERS[g] % _LIN
		var m := ShaderMaterial.new()
		m.shader = sh
		if g != "opaco":
			m.render_priority = 0
		_materiais[g] = m
	return _materiais[g]

## Classifica um material do kit e devolve [grupo, cor, uv, uv2] ou [] se não souber.
static func _atributos(m: Material, sombra: bool) -> Array:
	if not (m is StandardMaterial3D):
		return []
	var s := m as StandardMaterial3D
	var c := s.albedo_color
	var mult := maxf(1.0, maxf(c.r, maxf(c.g, c.b)))
	var cor := Color(c.r / mult, c.g / mult, c.b / mult, c.a)
	var energia := s.emission_energy_multiplier if s.emission_enabled else 0.0
	var grupo := "opaco"
	if s.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		if s.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
			grupo = "aditivo" if s.blend_mode == BaseMaterial3D.BLEND_MODE_ADD else "feixe"
		else:
			grupo = "translucido"
	elif not sombra:
		grupo = "sem_sombra"
	return [grupo, cor, Vector2(s.roughness, s.metallic), Vector2(energia, mult)]

## Transform da peça relativo à raiz, sem depender de a cena estar na árvore.
static func _relativo(no: Node3D, raiz: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = no
	while n != null and n != raiz:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t

## Funde a construção montada sob `raiz`. Devolve:
## { "lod0": ArrayMesh, "lod1": ArrayMesh, "grupos0": [nomes das superfícies], "grupos1": [...],
##   "extras": [[Node, Transform3D]], "pecas": int, "pecas_detalhe": int, "avisos": [] }
static func fundir(raiz: Node3D, raiz_longe: Node3D = null) -> Dictionary:
	var acc := [{}, {}]  # por LOD: grupo -> {v, n, c, uv, uv2, i}
	var r := {"extras": [], "pecas": 0, "pecas_detalhe": 0, "avisos": []}
	if raiz_longe == null:
		_visitar(raiz, raiz, acc, r, [0, 1])
	else:
		_visitar(raiz, raiz, acc, r, [0])
		var r1 := {"extras": [], "pecas": 0, "pecas_detalhe": 0, "avisos": []}
		_visitar(raiz_longe, raiz_longe, acc, r1, [1])
		r.pecas_detalhe = r1.pecas_detalhe
	for lod in 2:
		var malha := ArrayMesh.new()
		var nomes := []
		for g in GRUPOS + ["sem_sombra"]:
			if not acc[lod].has(g):
				continue
			var d: Dictionary = acc[lod][g]
			var arr := []
			arr.resize(Mesh.ARRAY_MAX)
			arr[Mesh.ARRAY_VERTEX] = d.v
			arr[Mesh.ARRAY_NORMAL] = d.n
			arr[Mesh.ARRAY_COLOR] = d.c
			arr[Mesh.ARRAY_TEX_UV] = d.uv
			arr[Mesh.ARRAY_TEX_UV2] = d.uv2
			arr[Mesh.ARRAY_INDEX] = d.i
			malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			malha.surface_set_material(malha.get_surface_count() - 1, material(g))
			malha.surface_set_name(malha.get_surface_count() - 1, g)
			nomes.append(g)
		r["lod%d" % lod] = malha
		r["grupos%d" % lod] = nomes
	return r

static func _visitar(no: Node, raiz: Node3D, acc: Array, r: Dictionary, lods: Array) -> void:
	for filho in no.get_children():
		if filho is MeshInstance3D and filho.mesh != null:
			_juntar(filho, raiz, acc, r, lods)
		elif filho is Label3D or filho is Sprite3D:
			r.extras.append([filho, _relativo(filho, raiz)])
		elif filho is VisualInstance3D and not (filho is MeshInstance3D):
			r.avisos.append("nó não fundido: %s" % filho.get_class())
		_visitar(filho, raiz, acc, r, lods)

static func _juntar(mi: MeshInstance3D, raiz: Node3D, acc: Array, r: Dictionary, lods: Array) -> void:
	if not mi.visible:
		return
	var xf := _relativo(mi, raiz)
	var nb := xf.basis.inverse().transposed()
	var sombra := mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var aabb := xf * mi.mesh.get_aabb()
	var t := [aabb.size.x, aabb.size.y, aabb.size.z]
	t.sort()
	var miuda: bool = mi.has_meta("detalhe") or t[2] < MIUDA or t[1] < FINA
	r.pecas += 1
	if miuda:
		r.pecas_detalhe += 1
	for s in mi.mesh.get_surface_count():
		var m: Material = mi.material_override if mi.material_override else mi.get_active_material(s)
		var at := _atributos(m, sombra)
		if at.is_empty():
			r.avisos.append("material não suportado em %s" % mi.name)
			continue
		var a := mi.mesh.surface_get_arrays(s)
		var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var ns = a[Mesh.ARRAY_NORMAL]
		var idx = a[Mesh.ARRAY_INDEX]
		for lod in lods:
			if lod == 1 and miuda:
				continue
			var d: Dictionary = acc[lod].get(at[0], {})
			if d.is_empty():
				d = {"v": PackedVector3Array(), "n": PackedVector3Array(), "c": PackedColorArray(),
					"uv": PackedVector2Array(), "uv2": PackedVector2Array(), "i": PackedInt32Array()}
				acc[lod][at[0]] = d
			var base: int = d.v.size()
			for k in vs.size():
				d.v.append(xf * vs[k])
				d.n.append((nb * ns[k]).normalized() if ns else Vector3.UP)
				d.c.append(at[1])
				d.uv.append(at[2])
				d.uv2.append(at[3])
			if idx:
				for k in idx.size():
					d.i.append(base + idx[k])
			else:
				for k in vs.size():
					d.i.append(base + k)

## Triângulos de uma malha.
static func triangulos(m: Mesh) -> int:
	var t := 0
	for s in m.get_surface_count():
		var a := m.surface_get_arrays(s)
		var idx = a[Mesh.ARRAY_INDEX]
		t += (idx.size() if idx else a[Mesh.ARRAY_VERTEX].size()) / 3
	return t
