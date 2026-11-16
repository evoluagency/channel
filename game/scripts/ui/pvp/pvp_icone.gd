extends Control
## Ícones vetoriais simples, desenhados por código (sem imagem externa).
## tipo: jogar, arma, moedas, carrinho, escudo, engrenagem, chat, lupa, mais, pessoa,
##       recarregar, correr, agachar, tiro, pausa, trofeu, presente, passe, faca, granada, mapa
## Sessão 1.8: base, herois, arsenal, missoes, bola (tiro de tinta), vida, marcador, pistola,
##       cadeado, moeda_v (moeda do Valdora)

const T := preload("res://scripts/ui/pvp/pvp_tema.gd")

var tipo := "jogar"
var cor := T.TEXTO

func _init(t := "jogar", c := T.TEXTO, tam := 40) -> void:
	tipo = t
	cor = c
	custom_minimum_size = Vector2(tam, tam)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _p(x: float, y: float) -> Vector2:
	# coordenadas de 0 a 1 dentro do quadrado centralizado
	var l := minf(size.x, size.y)
	var o := (size - Vector2(l, l)) * 0.5
	return o + Vector2(x, y) * l

func _poli(pts: Array, c := cor) -> void:
	var v := PackedVector2Array()
	for q in pts:
		v.append(_p(q[0], q[1]))
	draw_colored_polygon(v, c)

func _l() -> float:
	return minf(size.x, size.y)

func _draw() -> void:
	if minf(size.x, size.y) < 4.0:
		return
	var l := _l()
	match tipo:
		"jogar":
			_poli([[0.28, 0.18], [0.82, 0.5], [0.28, 0.82]])
		"arma":
			_poli([[0.08, 0.36], [0.86, 0.36], [0.92, 0.42], [0.92, 0.5], [0.46, 0.5], [0.4, 0.82], [0.24, 0.82], [0.3, 0.5], [0.08, 0.5]])
		"faca":
			_poli([[0.12, 0.62], [0.7, 0.3], [0.9, 0.24], [0.78, 0.4], [0.24, 0.72]])
			_poli([[0.12, 0.62], [0.24, 0.72], [0.16, 0.86], [0.04, 0.76]])
		"granada":
			draw_circle(_p(0.5, 0.6), l * 0.28, cor)
			_poli([[0.4, 0.2], [0.6, 0.2], [0.62, 0.34], [0.38, 0.34]])
		"moedas":
			for i in 3:
				var y := 0.72 - i * 0.18
				draw_rect(Rect2(_p(0.2, y - 0.08), Vector2(0.6, 0.12) * l), cor)
				_elipse(_p(0.5, y - 0.08), Vector2(0.3, 0.07) * l, cor.lightened(0.25))
		"carrinho":
			_poli([[0.27, 0.3], [0.9, 0.3], [0.82, 0.6], [0.33, 0.6]])
			draw_polyline(PackedVector2Array([_p(0.06, 0.2), _p(0.22, 0.2), _p(0.33, 0.64)]), cor, l * 0.07, true)
			draw_circle(_p(0.36, 0.76), l * 0.07, cor)
			draw_circle(_p(0.76, 0.76), l * 0.07, cor)
		"escudo":
			_poli([[0.5, 0.1], [0.86, 0.22], [0.82, 0.56], [0.5, 0.9], [0.18, 0.56], [0.14, 0.22]])
		"engrenagem":
			for i in 8:
				var a := i * TAU / 8
				var c := _p(0.5, 0.5) + Vector2(cos(a), sin(a)) * l * 0.34
				draw_circle(c, l * 0.09, cor)
			draw_circle(_p(0.5, 0.5), l * 0.32, cor)
			draw_circle(_p(0.5, 0.5), l * 0.13, T.PAINEL)
		"chat":
			draw_rect(Rect2(_p(0.1, 0.18), Vector2(0.8, 0.5) * l), cor)
			_poli([[0.24, 0.66], [0.44, 0.66], [0.24, 0.84]])
			for x in [0.32, 0.5, 0.68]:
				draw_circle(_p(x, 0.43), l * 0.055, T.PAINEL)
		"lupa":
			draw_arc(_p(0.42, 0.42), l * 0.24, 0, TAU, 24, cor, l * 0.08, true)
			draw_line(_p(0.6, 0.6), _p(0.86, 0.86), cor, l * 0.1, true)
		"mais":
			draw_rect(Rect2(_p(0.42, 0.16), Vector2(0.16, 0.68) * l), cor)
			draw_rect(Rect2(_p(0.16, 0.42), Vector2(0.68, 0.16) * l), cor)
		"pessoa":
			draw_circle(_p(0.5, 0.3), l * 0.17, cor)
			_poli([[0.18, 0.88], [0.24, 0.58], [0.5, 0.5], [0.76, 0.58], [0.82, 0.88]])
		"recarregar":
			draw_arc(_p(0.5, 0.5), l * 0.3, 0.3, TAU - 0.6, 24, cor, l * 0.09, true)
			_poli([[0.78, 0.28], [0.92, 0.46], [0.66, 0.46]])
		"correr":
			draw_circle(_p(0.62, 0.18), l * 0.09, cor)
			draw_line(_p(0.56, 0.32), _p(0.44, 0.58), cor, l * 0.1, true)
			draw_line(_p(0.44, 0.58), _p(0.62, 0.86), cor, l * 0.09, true)
			draw_line(_p(0.44, 0.58), _p(0.22, 0.78), cor, l * 0.09, true)
			draw_line(_p(0.52, 0.4), _p(0.78, 0.5), cor, l * 0.08, true)
			draw_line(_p(0.52, 0.4), _p(0.28, 0.42), cor, l * 0.08, true)
		"agachar":
			draw_circle(_p(0.58, 0.28), l * 0.09, cor)
			draw_line(_p(0.54, 0.4), _p(0.42, 0.6), cor, l * 0.1, true)
			draw_line(_p(0.42, 0.6), _p(0.66, 0.66), cor, l * 0.09, true)
			draw_line(_p(0.66, 0.66), _p(0.62, 0.86), cor, l * 0.09, true)
			draw_line(_p(0.48, 0.46), _p(0.86, 0.44), cor, l * 0.07, true)
		"tiro":
			_poli([[0.2, 0.62], [0.62, 0.2], [0.82, 0.18], [0.8, 0.38], [0.38, 0.8]])
			_poli([[0.12, 0.7], [0.3, 0.88], [0.22, 0.92], [0.08, 0.78]])
		"pausa":
			draw_rect(Rect2(_p(0.26, 0.2), Vector2(0.16, 0.6) * l), cor)
			draw_rect(Rect2(_p(0.58, 0.2), Vector2(0.16, 0.6) * l), cor)
		"trofeu":
			_poli([[0.26, 0.16], [0.74, 0.16], [0.68, 0.46], [0.5, 0.58], [0.32, 0.46]])
			draw_rect(Rect2(_p(0.44, 0.56), Vector2(0.12, 0.18) * l), cor)
			draw_rect(Rect2(_p(0.3, 0.74), Vector2(0.4, 0.1) * l), cor)
		"presente":
			draw_rect(Rect2(_p(0.16, 0.4), Vector2(0.68, 0.46) * l), cor)
			draw_rect(Rect2(_p(0.12, 0.3), Vector2(0.76, 0.14) * l), cor.lightened(0.2))
			draw_rect(Rect2(_p(0.45, 0.3), Vector2(0.1, 0.56) * l), T.LARANJA)
		"passe":
			_poli([[0.14, 0.24], [0.86, 0.24], [0.86, 0.42], [0.78, 0.5], [0.86, 0.58], [0.86, 0.76], [0.14, 0.76], [0.14, 0.58], [0.22, 0.5], [0.14, 0.42]])
		"mapa":
			_poli([[0.12, 0.22], [0.38, 0.14], [0.62, 0.24], [0.88, 0.16], [0.88, 0.78], [0.62, 0.86], [0.38, 0.76], [0.12, 0.84]])
		"lideres":
			draw_rect(Rect2(_p(0.12, 0.5), Vector2(0.22, 0.36) * l), cor)
			draw_rect(Rect2(_p(0.39, 0.3), Vector2(0.22, 0.56) * l), cor)
			draw_rect(Rect2(_p(0.66, 0.6), Vector2(0.22, 0.26) * l), cor)
		"voltar":
			_poli([[0.16, 0.5], [0.52, 0.18], [0.52, 0.38], [0.86, 0.38], [0.86, 0.62], [0.52, 0.62], [0.52, 0.82]])
		"base":
			_elipse(_p(0.5, 0.36), Vector2(0.22, 0.17) * l, cor)
			draw_rect(Rect2(_p(0.26, 0.36), Vector2(0.48, 0.06) * l), cor)
			for x in [0.22, 0.38, 0.54, 0.7]:
				draw_rect(Rect2(_p(x, 0.46), Vector2(0.08, 0.3) * l), cor)
			draw_rect(Rect2(_p(0.14, 0.78), Vector2(0.72, 0.08) * l), cor)
			draw_rect(Rect2(_p(0.48, 0.12), Vector2(0.04, 0.08) * l), cor)
		"herois":
			draw_circle(_p(0.36, 0.34), l * 0.14, Color(cor, 0.7))
			_poli([[0.12, 0.84], [0.16, 0.6], [0.36, 0.52], [0.56, 0.6], [0.6, 0.84]], Color(cor, 0.7))
			draw_circle(_p(0.6, 0.32), l * 0.16, cor)
			_poli([[0.34, 0.88], [0.38, 0.6], [0.6, 0.5], [0.82, 0.6], [0.86, 0.88]])
		"arsenal", "marcador":
			_poli([[0.06, 0.48], [0.6, 0.44], [0.62, 0.38], [0.92, 0.38], [0.94, 0.56], [0.7, 0.58], [0.66, 0.64], [0.54, 0.64], [0.5, 0.84], [0.38, 0.84], [0.4, 0.6], [0.06, 0.58]])
			_elipse(_p(0.58, 0.28), Vector2(0.16, 0.1) * l, cor)
			draw_rect(Rect2(_p(0.54, 0.32), Vector2(0.06, 0.08) * l), cor)
		"missoes":
			draw_rect(Rect2(_p(0.2, 0.18), Vector2(0.6, 0.72) * l), cor)
			draw_rect(Rect2(_p(0.36, 0.1), Vector2(0.28, 0.14) * l), cor.lightened(0.2))
			for y in [0.38, 0.56, 0.74]:
				draw_polyline(PackedVector2Array([_p(0.28, y), _p(0.33, y + 0.05), _p(0.42, y - 0.05)]), T.PAINEL, l * 0.05, true)
				draw_rect(Rect2(_p(0.48, y - 0.02), Vector2(0.24, 0.05) * l), T.PAINEL)
		"bola":
			for i in 3:
				var y := 0.36 + i * 0.14
				draw_line(_p(0.08 + i * 0.04, y), _p(0.42, y), Color(cor, 0.75), l * 0.06, true)
			draw_circle(_p(0.64, 0.5), l * 0.24, cor)
			draw_circle(_p(0.58, 0.42), l * 0.07, Color(1, 1, 1, 0.55))
		"vida":
			draw_rect(Rect2(_p(0.38, 0.12), Vector2(0.24, 0.76) * l), cor)
			draw_rect(Rect2(_p(0.12, 0.38), Vector2(0.76, 0.24) * l), cor)
		"pistola":
			_poli([[0.1, 0.3], [0.86, 0.3], [0.88, 0.48], [0.5, 0.48], [0.46, 0.82], [0.26, 0.82], [0.3, 0.48], [0.1, 0.48]])
		"cadeado":
			draw_arc(_p(0.5, 0.42), l * 0.18, PI, TAU, 16, cor, l * 0.08, true)
			draw_rect(Rect2(_p(0.24, 0.42), Vector2(0.52, 0.42) * l), cor)
		"moeda_v":
			draw_circle(_p(0.5, 0.5), l * 0.46, cor.darkened(0.25))
			draw_circle(_p(0.5, 0.5), l * 0.38, cor)
			_poli([[0.28, 0.3], [0.42, 0.3], [0.5, 0.56], [0.58, 0.3], [0.72, 0.3], [0.56, 0.74], [0.44, 0.74]], cor.darkened(0.45))
		_:
			draw_circle(_p(0.5, 0.5), l * 0.3, cor)

func _elipse(c: Vector2, r: Vector2, co: Color) -> void:
	var v := PackedVector2Array()
	for i in 20:
		var a := i * TAU / 20
		v.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	draw_colored_polygon(v, co)
