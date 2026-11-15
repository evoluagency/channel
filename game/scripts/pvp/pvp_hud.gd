extends CanvasLayer
## Interface da partida do Valdora PvP: joystick (metade esquerda), mira por arrasto (metade
## direita), botões de tiro, recarga, pulo e agachar (vários dedos ao mesmo tempo), minimapa,
## tempo, munição e pausa (volta ao menu).

const T := preload("res://scripts/ui/pvp/pvp_tema.gd")
const ICONE := preload("res://scripts/ui/pvp/pvp_icone.gd")
const MENU := "res://scenes/pvp/MenuPvP.tscn"

var arena                      # pvp_arena.gd
var _joy_id := -1
var _joy_origem := Vector2.ZERO
var _joy_pos := Vector2.ZERO
var _olhar_id := -1
var _botoes := []              # [{centro, raio, acao, visual}]
var _tempo := 115.0
var _rotulo_tempo: Label
var _rotulo_municao: Label
var _desenho: Control
var _minimapa: Control
var _tiro_seguido := false
var _cadencia := 0.0

const RAIO_JOY := 90.0

func _ready() -> void:
	layer = 5
	_desenho = Control.new()
	_desenho.set_anchors_preset(Control.PRESET_FULL_RECT)
	_desenho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desenho.draw.connect(_desenhar)
	add_child(_desenho)
	# topo: tempo e placar
	_rotulo_tempo = _rotulo("01:55", 26)
	_rotulo_tempo.add_theme_stylebox_override("normal", _caixa(Color(T.NOITE, 0.75), 10))
	_rotulo_tempo.anchor_left = 0.5; _rotulo_tempo.anchor_right = 0.5
	_rotulo_tempo.offset_left = -60; _rotulo_tempo.offset_right = 60; _rotulo_tempo.offset_top = 12
	_rotulo_tempo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_rotulo_tempo)
	var placar := _rotulo("0   ·   0", 20)
	placar.anchor_left = 0.5; placar.anchor_right = 0.5
	placar.offset_left = -60; placar.offset_right = 60; placar.offset_top = 52
	placar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(placar)
	var nome := _rotulo("%s · Desarmar" % arena.mapa.get("nome", ""), 16)
	nome.position = Vector2(16, 214)
	add_child(nome)
	# minimapa
	_minimapa = Control.new()
	_minimapa.position = Vector2(16, 16)
	_minimapa.size = Vector2(arena.largura, arena.altura) * 6.0
	_minimapa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_minimapa.draw.connect(_desenhar_minimapa)
	add_child(_minimapa)
	# munição
	_rotulo_municao = _rotulo("24 / 90", 28)
	_rotulo_municao.add_theme_stylebox_override("normal", _caixa(Color(T.NOITE, 0.75), 12))
	_rotulo_municao.anchor_left = 1.0; _rotulo_municao.anchor_right = 1.0
	_rotulo_municao.anchor_top = 1.0; _rotulo_municao.anchor_bottom = 1.0
	_rotulo_municao.offset_left = -470; _rotulo_municao.offset_right = -320
	_rotulo_municao.offset_top = -290; _rotulo_municao.offset_bottom = -244
	_rotulo_municao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_rotulo_municao)
	# pausa (volta ao menu)
	var pausa := Button.new()
	pausa.anchor_left = 1.0; pausa.anchor_right = 1.0
	pausa.offset_left = -76; pausa.offset_right = -20; pausa.offset_top = 16; pausa.offset_bottom = 72
	pausa.add_theme_stylebox_override("normal", _caixa(T.PAINEL_3, 14))
	pausa.add_theme_stylebox_override("hover", _caixa(T.PAINEL_3.lightened(0.1), 14))
	pausa.add_theme_stylebox_override("pressed", _caixa(T.PAINEL, 14))
	var pi = ICONE.new("pausa", T.CREME, 30)
	pi.position = Vector2(13, 13)
	pausa.add_child(pi)
	pausa.pressed.connect(sair)
	add_child(pausa)
	# botões de ação (posição a partir do canto inferior direito)
	_botao("tiro", Vector2(-120, -130), 72, T.LARANJA)
	_botao("recarregar", Vector2(-275, -90), 44, T.PAINEL_3)
	_botao("pulo", Vector2(-250, -215), 44, T.PAINEL_3)
	_botao("agachar", Vector2(-110, -290), 44, T.PAINEL_3)
	get_viewport().size_changed.connect(_reposicionar)
	_reposicionar()

func _rotulo(txt: String, tam: int) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", T.fonte(900, true))
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", T.CREME)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _caixa(cor: Color, raio: int) -> StyleBoxFlat:
	var s := T.caixa(cor, raio)
	s.content_margin_left = 10; s.content_margin_right = 10
	s.content_margin_top = 4; s.content_margin_bottom = 4
	return s

func _botao(acao: String, canto: Vector2, raio: float, cor: Color) -> void:
	var tipo: String = {"tiro": "tiro", "recarregar": "recarregar", "pulo": "correr", "agachar": "agachar"}[acao]
	var ic = ICONE.new(tipo, Color.WHITE, int(raio))
	add_child(ic)
	_botoes.append({"canto": canto, "raio": raio, "acao": acao, "cor": cor, "icone": ic, "centro": Vector2.ZERO, "dedo": -1})

func _reposicionar() -> void:
	var tam := get_viewport().get_visible_rect().size
	for b in _botoes:
		b.centro = tam + b.canto
		b.icone.position = b.centro - Vector2(b.raio, b.raio) * 0.5
	_desenho.queue_redraw()

# ---------------------------------------------------------------- toque

func _botao_em(p: Vector2):
	for b in _botoes:
		if p.distance_to(b.centro) <= b.raio + 10:
			return b
	return null

func _input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		var tam := get_viewport().get_visible_rect().size
		if ev.pressed:
			var b = _botao_em(ev.position)
			if b != null:
				b.dedo = ev.index
				_acao(b.acao, true)
			elif ev.position.y < 90 or (ev.position.x < 200 and ev.position.y < 240):
				return   # topo e minimapa ficam livres para os botões
			elif ev.position.x < tam.x * 0.45 and _joy_id < 0:
				_joy_id = ev.index
				_joy_origem = ev.position
				_joy_pos = ev.position
			elif _olhar_id < 0:
				_olhar_id = ev.index
		else:
			for b in _botoes:
				if b.dedo == ev.index:
					b.dedo = -1
					_acao(b.acao, false)
			if ev.index == _joy_id:
				_joy_id = -1
				arena.jogador.mover = Vector2.ZERO
			if ev.index == _olhar_id:
				_olhar_id = -1
		_desenho.queue_redraw()
	elif ev is InputEventScreenDrag:
		if ev.index == _joy_id:
			_joy_pos = ev.position
			var d: Vector2 = (_joy_pos - _joy_origem) / RAIO_JOY
			if d.length() > 1.0:
				d = d.normalized()
			arena.jogador.mover = d
			_desenho.queue_redraw()
		elif ev.index == _olhar_id:
			arena.jogador.girar(ev.relative.x, ev.relative.y)

func _acao(acao: String, apertou: bool) -> void:
	var j = arena.jogador
	match acao:
		"tiro":
			_tiro_seguido = apertou
			if apertou:
				j.atirar()
				_cadencia = 0.0
		"recarregar":
			if apertou:
				j.recarregar()
		"pulo":
			if apertou:
				j.pular()
		"agachar":
			if apertou:
				j.alternar_agachar()

func sair() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MENU)

# ---------------------------------------------------------------- quadro a quadro

func _process(dt: float) -> void:
	_tempo = maxf(0.0, _tempo - dt)
	_rotulo_tempo.text = "%02d:%02d" % [int(_tempo) / 60, int(_tempo) % 60]
	var j = arena.jogador
	if _tiro_seguido:
		_cadencia += dt
		if _cadencia >= 0.12:
			_cadencia = 0.0
			j.atirar()
	_rotulo_municao.text = "%d / %d" % [j.municao, j.reserva]
	_minimapa.queue_redraw()

func _desenhar() -> void:
	var tam := _desenho.size
	# mira
	var c := tam * 0.5
	for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		_desenho.draw_line(c + d * 6, c + d * 18, T.TEAL_CLARO, 3.0, true)
	# joystick
	var base := _joy_origem if _joy_id >= 0 else Vector2(150, tam.y - 150)
	var ponto := _joy_pos if _joy_id >= 0 else base
	_desenho.draw_circle(base, RAIO_JOY, Color(T.NOITE, 0.35))
	_desenho.draw_arc(base, RAIO_JOY, 0, TAU, 48, Color(T.CREME, 0.35), 3.0, true)
	var lim := ponto - base
	if lim.length() > RAIO_JOY:
		lim = lim.normalized() * RAIO_JOY
	_desenho.draw_circle(base + lim, 36, Color(T.CREME, 0.6))
	# botões
	for b in _botoes:
		var cor: Color = b.cor
		_desenho.draw_circle(b.centro, b.raio, Color(cor, 0.9 if b.dedo >= 0 else 0.75))
		_desenho.draw_arc(b.centro, b.raio, 0, TAU, 48, Color(T.CREME, 0.6), 3.0, true)

func _desenhar_minimapa() -> void:
	var m := _minimapa
	var e := 6.0
	m.draw_rect(Rect2(Vector2.ZERO, m.size), Color(T.NOITE, 0.7))
	var cores := {"#": Color(T.TEXTO_2, 0.55), "c": Color(T.TEXTO_2, 0.3), "A": Color("d9534a"), "B": Color("3f6fc9"),
		"T": Color("3f8f5a"), "D": Color("b0603a")}
	for y in arena.altura:
		var linha: String = arena.grade[y]
		for x in arena.largura:
			var ch := linha[x]
			if cores.has(ch):
				m.draw_rect(Rect2(Vector2(x, y) * e, Vector2(e, e)), cores[ch])
	var j = arena.jogador
	var p := Vector2((j.global_position.x / arena.CELULA + arena.largura * 0.5) * e, (j.global_position.z / arena.CELULA + arena.altura * 0.5) * e)
	var f := -Vector2(sin(j.rotation.y), cos(j.rotation.y))
	var lado := Vector2(-f.y, f.x)
	m.draw_colored_polygon(PackedVector2Array([p + f * 9, p - f * 5 + lado * 5, p - f * 5 - lado * 5]), T.TEAL_CLARO)
