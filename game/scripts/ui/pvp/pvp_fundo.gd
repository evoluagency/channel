extends Control
## Fundo dos menus: céu azul-noite com luz verde-azulada e a silhueta de uma cidade com
## cúpulas e torres (identidade Valdora), sem imagem externa. Será trocado pela arte final.

const T := preload("res://scripts/ui/pvp/pvp_tema.gd")

var tom := "menu"   # menu | partida

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	var s := size
	var topo := Color("#0f1a28") if tom == "menu" else Color("#7fb3d6")
	var meio := Color("#1d3a4f") if tom == "menu" else Color("#d9e4dc")
	var baixo := Color("#13202f") if tom == "menu" else Color("#c9b99c")
	_faixa(0.0, 0.55, topo, meio)
	_faixa(0.55, 1.0, meio, baixo)
	# brilho verde-azulado atrás da área central
	for i in 6:
		var r := s.y * (0.55 - i * 0.07)
		draw_circle(Vector2(s.x * 0.52, s.y * 0.48), r, Color(T.TEAL, 0.035))
	# silhueta da cidade (duas camadas)
	_cidade(0.74, Color("#1a3245") if tom == "menu" else Color("#a9bcb4"), 11)
	_cidade(0.84, Color("#15283a") if tom == "menu" else Color("#97a99c"), 23)
	# vinheta nas bordas
	draw_rect(Rect2(0, s.y * 0.88, s.x, s.y * 0.12), Color(0, 0, 0, 0.18))

func _faixa(a: float, b: float, c0: Color, c1: Color) -> void:
	var s := size
	var v := PackedVector2Array([Vector2(0, s.y * a), Vector2(s.x, s.y * a), Vector2(s.x, s.y * b), Vector2(0, s.y * b)])
	draw_polygon(v, PackedColorArray([c0, c0, c1, c1]))

func _cidade(base: float, cor: Color, semente: int) -> void:
	var s := size
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var x := -20.0
	var y0 := s.y * base
	while x < s.x + 20:
		var w := rng.randf_range(40, 110)
		var h := rng.randf_range(40, 150) * (s.y / 720.0)
		draw_rect(Rect2(x, y0 - h, w, h + s.y), cor)
		var tipo := rng.randi_range(0, 4)
		if tipo == 0:
			# cúpula
			draw_circle(Vector2(x + w * 0.5, y0 - h), w * 0.42, cor)
			draw_rect(Rect2(x + w * 0.47, y0 - h - w * 0.62, w * 0.06, w * 0.24), cor)
		elif tipo == 1:
			# torre fina
			draw_rect(Rect2(x + w * 0.35, y0 - h - 60, w * 0.3, 60), cor)
			draw_colored_polygon(PackedVector2Array([Vector2(x + w * 0.3, y0 - h - 60), Vector2(x + w * 0.7, y0 - h - 60), Vector2(x + w * 0.5, y0 - h - 95)]), cor)
		x += w + rng.randf_range(-10, 14)
