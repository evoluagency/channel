extends Node2D
## Selos de nível da cidade, desenhados em 2D por cima da cena.
## Hexágono azul-noite com borda branca (faixas 1 a 5) ou dourado (faixa 6), número e pontos.
## Todos os hexágonos e pontos vão numa malha 2D só (uma chamada de desenho); os números usam
## a mesma fonte e o renderizador junta em lote.

var cidade
var _malha := ArrayMesh.new()

func _draw() -> void:
	if cidade == null:
		return
	var cam: Camera3D = cidade.cam
	var vp := get_viewport_rect().size
	var lote_px: float = cidade.LARGURA_LOTE_TELA / cidade.largura * vp.x
	if lote_px < 45.0:
		return   # de longe os selos viram ruído: somem
	var r := clampf(lote_px * 0.11, 9.0, 22.0)
	var fonte: Font = cidade.kit.fonte
	var v := PackedVector2Array()
	var c := PackedColorArray()
	var textos := []
	for l in cidade.lotes:
		if l.nivel <= 0 or l.id == "via":
			continue
		var p: Vector2 = cam.unproject_position(l.pos + Vector3(0, l.topo + 0.7, 0))
		if p.x < -r or p.y < -r or p.x > vp.x + r or p.y > vp.y + r:
			continue
		var dourado: bool = l.nivel > 25
		_poligono(v, c, p, r + 2.0, 6, Color("fff3c4") if dourado else Color.WHITE, PI / 6.0)
		_poligono(v, c, p, r, 6, Color("f0a81c") if dourado else Color("1d2a44"), PI / 6.0)
		if r >= 11.0:
			var pontos: int = (l.nivel - 1) % 5 + 1
			for i in pontos:
				_poligono(v, c, p + Vector2((i - (pontos - 1) * 0.5) * r * 0.22, r * 0.62), r * 0.07, 6, Color.WHITE, 0.0)
			textos.append([p, str(l.nivel)])
	_malha.clear_surfaces()
	if v.size() > 0:
		var a := []
		a.resize(Mesh.ARRAY_MAX)
		a[Mesh.ARRAY_VERTEX] = v
		a[Mesh.ARRAY_COLOR] = c
		_malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
		draw_mesh(_malha, null)
	var tam := int(r * 0.95)
	for t in textos:
		var w := fonte.get_string_size(t[1], HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		draw_string(fonte, t[0] + Vector2(-w * 0.5, tam * 0.3), t[1], HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Color.WHITE)

func _poligono(v: PackedVector2Array, c: PackedColorArray, centro: Vector2, r: float, lados: int, cor: Color, giro: float) -> void:
	for i in lados:
		var a0 := giro + i * TAU / lados
		var a1 := giro + (i + 1) * TAU / lados
		v.append(centro)
		v.append(centro + Vector2(cos(a0), sin(a0)) * r)
		v.append(centro + Vector2(cos(a1), sin(a1)) * r)
		for k in 3:
			c.append(cor)
