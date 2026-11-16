extends CanvasLayer
## Interface da partida do Valdora PvP (sessão 1.8, no estilo da arte conceitual):
## placar com os retratos dos dois times e o tempo no topo, "CONFRONTO 5 × 5", minimapa com
## o nome do mapa, abates recentes à direita, vida e escudo embaixo, espaços de arma,
## munição, joystick com setas e botões redondos (tiro de tinta laranja com aro).
## Toque: joystick na metade esquerda (aparece onde o dedo toca), mira por arrasto na direita,
## botões com vários dedos ao mesmo tempo. Pausa congela a partida.

const T := preload("res://scripts/ui/pvp/pvp_tema.gd")
const ICONE := preload("res://scripts/ui/pvp/pvp_icone.gd")
const RETRATOS := preload("res://scripts/pvp/visual/retratos.gd")
const MENU := "res://scenes/pvp/MenuPvP.tscn"

var arena                      # pvp_arena.gd
var _joy_id := -1
var _joy_origem := Vector2.ZERO
var _joy_pos := Vector2.ZERO
var _olhar_id := -1
var _botoes := []              # [{canto, raio, acao, cor, icone, centro, dedo}]
var _rotulo_tempo: Label
var _rotulo_municao: Label
var _rotulo_vida: Label
var _rotulo_escudo: Label
var _placar: Array = []        # 2 Labels
var _retratos: Array = [[], []]
var _feed: VBoxContainer
var _aviso: Label
var _fim: Control
var _pausa: Control
var _desenho: Control
var _minimapa: Control
var _tiro_seguido := false
var _cadencia := 0.0
var _acerto_t := 0.0
var _dano_t := 0.0
var _acertos_vistos := 0
var _autor_queda := ""
var _feed_visto := -1
var _slots: Array = []          # painéis das 3 armas
var _arma_vista := -1

const RAIO_JOY := 84.0
const NAVY := Color(0.07, 0.12, 0.2, 0.72)

func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	_desenho = Control.new()
	_desenho.set_anchors_preset(Control.PRESET_FULL_RECT)
	_desenho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desenho.draw.connect(_desenhar)
	add_child(_desenho)
	_topo()
	_minimapa_montar()
	_canto_direito()
	_base()
	_botao("tiro", Vector2(-104, -128), 66, T.LARANJA)
	_botao("recarregar", Vector2(-232, -176), 40, NAVY)
	_botao("pulo", Vector2(-226, -72), 40, NAVY)
	_botao("agachar", Vector2(-322, -72), 40, NAVY)
	_aviso = _rotulo("", 30)
	_aviso.set_anchors_preset(Control.PRESET_CENTER)
	_aviso.offset_left = -360; _aviso.offset_right = 360; _aviso.offset_top = 60; _aviso.offset_bottom = 150
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_aviso.visible = false
	add_child(_aviso)
	get_viewport().size_changed.connect(_reposicionar)
	_reposicionar()
	arena.jogador.caiu.connect(func(autor): _autor_queda = String(autor.nome) if is_instance_valid(autor) else "")
	arena.jogador.ferido.connect(func(_d): _dano_t = 0.45)
	var ids := []
	for c in arena.combatentes:
		ids.append(c.heroi_id)
	var g = RETRATOS.pedir(self, ids)
	g.pronto.connect(_retrato_pronto)

# ---------------------------------------------------------------- peças

func _rotulo(txt: String, tam: int, cor := T.CREME) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", T.fonte(900, true))
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _caixa(cor: Color, raio: int, borda := 2, cor_borda := Color(1, 1, 1, 0.22)) -> StyleBoxFlat:
	var s := T.caixa(cor, raio, borda, cor_borda)
	s.content_margin_left = 10; s.content_margin_right = 10
	s.content_margin_top = 4; s.content_margin_bottom = 4
	return s

func _painel(cor := NAVY, raio := 14, borda := 2, cor_borda := Color(1, 1, 1, 0.22)) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _caixa(cor, raio, borda, cor_borda))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p

func _topo() -> void:
	var h := HBoxContainer.new()
	h.anchor_left = 0.5; h.anchor_right = 0.5
	h.offset_top = 10
	h.add_theme_constant_override("separation", 6)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(h)
	for lado in 2:
		var cor_time: Color = T.TEAL_CLARO if lado == 0 else T.VERMELHO
		var p := _painel(NAVY, 14, 2, Color(cor_time, 0.55))
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 4)
		linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(linha)
		var num := _rotulo("0", 34, cor_time)
		num.custom_minimum_size = Vector2(46, 0)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_placar.append(num)
		var lista := []
		for c in arena.combatentes:
			if c.time == lado:
				lista.append(c)
		var caixas := []
		for c in lista:
			caixas.append(_retrato(c, cor_time))
		if lado == 0:
			for r in caixas: linha.add_child(r)
			linha.add_child(num)
		else:
			linha.add_child(num)
			for r in caixas: linha.add_child(r)
		h.add_child(p)
		if lado == 0:
			_rotulo_tempo = _rotulo("03:00", 26)
			var pt := _painel(Color(0.05, 0.09, 0.15, 0.85), 14)
			_rotulo_tempo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			pt.add_child(_rotulo_tempo)
			h.add_child(pt)
	h.resized.connect(func(): h.offset_left = -h.size.x * 0.5; h.offset_right = h.size.x * 0.5)
	var modo := _painel(NAVY, 14)
	modo.anchor_left = 0.5; modo.anchor_right = 0.5
	modo.offset_top = 70
	var ml := _rotulo("CONFRONTO 5 × 5", 16)
	modo.add_child(ml)
	add_child(modo)
	modo.resized.connect(func(): modo.offset_left = -modo.size.x * 0.5; modo.offset_right = modo.size.x * 0.5)

func _retrato(c: Node, cor_time: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(44, 44)
	var s := T.caixa(Color(cor_time.darkened(0.55), 0.9), 10, 2, cor_time)
	p.add_theme_stylebox_override("panel", s)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tr := TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.texture = RETRATOS.textura(c.heroi_id)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(tr)
	var l := _rotulo(String(c.nome).substr(0, 1), 18)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.visible = tr.texture == null
	p.add_child(l)
	p.set_meta("combatente", c)
	p.set_meta("textura", tr)
	p.set_meta("inicial", l)
	_retratos[c.time].append(p)
	return p

func _retrato_pronto(id: String) -> void:
	for lado in _retratos:
		for p in lado:
			if p.get_meta("combatente").heroi_id == id:
				p.get_meta("textura").texture = RETRATOS.textura(id)
				p.get_meta("inicial").visible = false

func _minimapa_montar() -> void:
	_minimapa = Control.new()
	_minimapa.position = Vector2(14, 12)
	var e := 168.0 / maxf(arena.largura, arena.altura)
	_minimapa.size = Vector2(arena.largura, arena.altura) * e
	_minimapa.set_meta("escala", e)
	_minimapa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_minimapa.clip_contents = true
	_minimapa.draw.connect(_desenhar_minimapa)
	add_child(_minimapa)
	var nome := _painel(Color(0.05, 0.09, 0.15, 0.85), 12)
	nome.position = Vector2(14 + _minimapa.size.x * 0.5 - 60, 16 + _minimapa.size.y)
	nome.custom_minimum_size = Vector2(120, 0)
	var l := _rotulo(String(arena.mapa.get("nome", "")).to_upper(), 14)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.add_child(l)
	add_child(nome)

func _canto_direito() -> void:
	var pausa := Button.new()
	pausa.anchor_left = 1.0; pausa.anchor_right = 1.0
	pausa.offset_left = -70; pausa.offset_right = -14; pausa.offset_top = 12; pausa.offset_bottom = 68
	pausa.focus_mode = Control.FOCUS_NONE
	for k in ["normal", "hover", "pressed"]:
		pausa.add_theme_stylebox_override(k, _caixa(Color(0.05, 0.09, 0.15, 0.85) if k != "pressed" else T.PAINEL, 14, 2, Color(1, 1, 1, 0.3)))
	var pi = ICONE.new("pausa", T.CREME, 30)
	pi.position = Vector2(13, 13)
	pausa.add_child(pi)
	pausa.pressed.connect(_alternar_pausa)
	add_child(pausa)
	_feed = VBoxContainer.new()
	_feed.anchor_left = 1.0; _feed.anchor_right = 1.0
	_feed.offset_left = -330; _feed.offset_right = -14; _feed.offset_top = 80
	_feed.alignment = BoxContainer.ALIGNMENT_BEGIN
	_feed.add_theme_constant_override("separation", 6)
	_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_feed)

func _base() -> void:
	# vida e escudo
	var pv := _painel(NAVY, 16)
	pv.anchor_top = 1.0; pv.anchor_bottom = 1.0
	pv.offset_left = 258; pv.offset_top = -74; pv.offset_bottom = -18
	var hv := HBoxContainer.new()
	hv.add_theme_constant_override("separation", 8)
	hv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pv.add_child(hv)
	hv.add_child(ICONE.new("vida", T.VERDE, 30))
	_rotulo_vida = _rotulo("100", 28)
	hv.add_child(_rotulo_vida)
	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(2, 30)
	sep.color = Color(1, 1, 1, 0.3)
	hv.add_child(sep)
	hv.add_child(ICONE.new("escudo", T.TEAL_CLARO, 30))
	_rotulo_escudo = _rotulo("50", 28)
	hv.add_child(_rotulo_escudo)
	for c in hv.get_children():
		if c is Label: c.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(pv)
	# espaços de arma: marcador, pistola e granada de tinta (toque para trocar)
	var hs := HBoxContainer.new()
	hs.anchor_top = 1.0; hs.anchor_bottom = 1.0
	hs.offset_left = 500; hs.offset_top = -74; hs.offset_bottom = -18
	hs.add_theme_constant_override("separation", 6)
	hs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hs)
	for i in 3:
		var p := _painel(Color(0.05, 0.09, 0.15, 0.8), 12, 2)
		p.custom_minimum_size = Vector2(110 if i < 2 else 74, 56)
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		var ic = ICONE.new(["marcador", "pistola", "granada"][i], T.CREME, 40)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		p.add_child(ic)
		p.set_meta("icone", ic)
		p.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and not DisplayServer.is_touchscreen_available():
				arena.jogador.trocar_arma(i))
		hs.add_child(p)
		_slots.append(p)
	# munição
	var pm := _painel(NAVY, 18)
	pm.anchor_left = 1.0; pm.anchor_right = 1.0; pm.anchor_top = 1.0; pm.anchor_bottom = 1.0
	pm.offset_left = -258; pm.offset_right = -96; pm.offset_top = -262; pm.offset_bottom = -216
	var hm := HBoxContainer.new()
	hm.add_theme_constant_override("separation", 8)
	hm.alignment = BoxContainer.ALIGNMENT_CENTER
	hm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pm.add_child(hm)
	hm.add_child(ICONE.new("bola", T.CREME, 28))
	_rotulo_municao = _rotulo("24 / 90", 26)
	_rotulo_municao.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hm.add_child(_rotulo_municao)
	add_child(pm)

func _botao(acao: String, canto: Vector2, raio: float, cor: Color) -> void:
	var tipo: String = {"tiro": "bola", "recarregar": "recarregar", "pulo": "correr", "agachar": "agachar"}[acao]
	var ic = ICONE.new(tipo, Color.WHITE, int(raio * 1.05))
	add_child(ic)
	_botoes.append({"canto": canto, "raio": raio, "acao": acao, "cor": cor, "icone": ic, "centro": Vector2.ZERO, "dedo": -1})

func _reposicionar() -> void:
	var tam := get_viewport().get_visible_rect().size
	for b in _botoes:
		b.centro = tam + b.canto
		b.icone.position = b.centro - Vector2(b.raio, b.raio) * 0.525
	_desenho.queue_redraw()

# ---------------------------------------------------------------- toque

func _botao_em(p: Vector2):
	for b in _botoes:
		if p.distance_to(b.centro) <= b.raio + 10:
			return b
	return null

func _input(ev: InputEvent) -> void:
	if get_tree().paused or arena.encerrada:
		return
	if ev is InputEventScreenTouch:
		var tam := get_viewport().get_visible_rect().size
		if ev.pressed:
			var b = _botao_em(ev.position)
			for k in _slots.size():
				if _slots[k].get_global_rect().has_point(ev.position):
					arena.jogador.trocar_arma(k)
					return
			if b != null:
				b.dedo = ev.index
				_acao(b.acao, true)
			elif ev.position.y < 110 or (ev.position.x < 200 and ev.position.y < 240) or (ev.position.x > tam.x - 90 and ev.position.y < 80):
				return   # topo, minimapa e pausa ficam livres
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
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MENU)

func _alternar_pausa() -> void:
	if arena.encerrada:
		return
	if _pausa != null:
		_pausa.queue_free()
		_pausa = null
		get_tree().paused = false
		return
	get_tree().paused = true
	_pausa = _janela("PAUSA", "A partida está parada.", [["CONTINUAR", "teal", _alternar_pausa], ["SAIR DA PARTIDA", "laranja", sair]])

func _janela(titulo: String, texto: String, botoes: Array) -> Control:
	var fundo := ColorRect.new()
	fundo.color = Color(0.02, 0.04, 0.08, 0.55)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	var p := _painel(Color(0.07, 0.12, 0.2, 0.92), 26, 3, Color(1, 1, 1, 0.3))
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.offset_left = -230; p.offset_right = 230; p.offset_top = -150; p.offset_bottom = 150
	fundo.add_child(p)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	var t := _rotulo(titulo, 40, T.CREME)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var tx := _rotulo(texto, 18, T.TEXTO_2)
	tx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(tx)
	for b in botoes:
		var bt := Button.new()
		bt.text = b[0]
		bt.custom_minimum_size = Vector2(0, 56)
		var cores: Array = [T.LARANJA, T.LARANJA_ESCURO] if b[1] == "laranja" else [T.TEAL_ESCURO.lightened(0.08), Color("#0d5357")]
		bt.add_theme_stylebox_override("normal", T.caixa_botao(cores[0], cores[1], 18))
		bt.add_theme_stylebox_override("hover", T.caixa_botao(cores[0].lightened(0.1), cores[1], 18))
		bt.add_theme_stylebox_override("pressed", T.caixa_botao(cores[1], cores[1], 18, true))
		bt.add_theme_font_override("font", T.fonte(900, true))
		bt.add_theme_font_size_override("font_size", 22)
		bt.pressed.connect(b[2])
		v.add_child(bt)
	return fundo

func _mostrar_fim() -> void:
	var p: Array = arena.placar
	var titulo := "VITÓRIA" if p[0] > p[1] else ("DERROTA" if p[0] < p[1] else "EMPATE")
	var j = arena.jogador
	_fim = _janela(titulo, "Placar %d × %d · seus abates: %d" % [p[0], p[1], j.abates], [["VOLTAR À BASE", "laranja", sair]])

# ---------------------------------------------------------------- quadro a quadro

func _process(dt: float) -> void:
	if get_tree().paused:
		return
	var t: float = arena.tempo
	_rotulo_tempo.text = "%02d:%02d" % [int(t) / 60, int(t) % 60]
	_placar[0].text = str(arena.placar[0])
	_placar[1].text = str(arena.placar[1])
	var j = arena.jogador
	if _tiro_seguido and j.automatica():
		_cadencia += dt
		if _cadencia >= j.cadencia():
			_cadencia = 0.0
			j.atirar()
	_rotulo_municao.text = ("%d" % j.municao) if j.arma_atual == 2 else ("%d / %d" % [j.municao, j.reserva])
	if j.arma_atual != _arma_vista:
		_arma_vista = j.arma_atual
		for k in _slots.size():
			var ativo: bool = k == j.arma_atual
			_slots[k].add_theme_stylebox_override("panel", _caixa(Color(0.05, 0.09, 0.15, 0.85 if ativo else 0.7), 12, 3 if ativo else 2, T.OURO if ativo else Color(1, 1, 1, 0.2)))
			_slots[k].get_meta("icone").cor = T.CREME if ativo else Color(T.CREME, 0.5)
			_slots[k].get_meta("icone").queue_redraw()
	_rotulo_vida.text = str(int(ceil(j.vida)))
	_rotulo_escudo.text = str(int(ceil(j.escudo)))
	if j.acertos_corpo != _acertos_vistos:
		_acertos_vistos = j.acertos_corpo
		_acerto_t = 0.18
	_acerto_t = maxf(0.0, _acerto_t - dt)
	_dano_t = maxf(0.0, _dano_t - dt)
	for lado in _retratos:
		for r in lado:
			r.modulate = Color(0.45, 0.45, 0.5, 0.8) if r.get_meta("combatente").morto else Color.WHITE
	if j.morto:
		_aviso.visible = true
		_aviso.text = "PINTADO POR %s\nvolta em %d" % [_autor_queda.to_upper(), int(ceil(j._morto_t))]
	else:
		_aviso.visible = false
	_atualizar_feed()
	if arena.encerrada and _fim == null:
		_tiro_seguido = false
		j.mover = Vector2.ZERO
		_mostrar_fim()
	_minimapa.queue_redraw()
	_desenho.queue_redraw()

func _atualizar_feed() -> void:
	var lista: Array = arena.abates_recentes
	var chave := lista.size() if lista.is_empty() else int(lista[0].t)
	var agora := Time.get_ticks_msec()
	if chave != _feed_visto:
		_feed_visto = chave
		for c in _feed.get_children():
			c.queue_free()
		for a in lista.slice(0, 3):
			var p := _painel(Color(0.05, 0.09, 0.15, 0.78), 12)
			p.size_flags_horizontal = Control.SIZE_SHRINK_END
			p.set_meta("t", int(a.t))
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 8)
			h.mouse_filter = Control.MOUSE_FILTER_IGNORE
			p.add_child(h)
			var ca: Color = T.TEAL_CLARO if a.time == 0 else T.VERMELHO
			var cv: Color = T.VERMELHO if a.time == 0 else T.TEAL_CLARO
			h.add_child(_rotulo(a.autor, 17, ca))
			h.add_child(ICONE.new("marcador", T.CREME, 26))
			h.add_child(_rotulo(a.vitima, 17, cv))
			_feed.add_child(p)
	for c in _feed.get_children():
		c.visible = agora - int(c.get_meta("t")) < 6000

func _desenhar() -> void:
	var tam := _desenho.size
	var c := tam * 0.5
	# dano: borda vermelha
	if _dano_t > 0.0:
		var a := _dano_t / 0.45 * 0.45
		for i in 6:
			var w := 14.0 * (6 - i)
			_desenho.draw_rect(Rect2(Vector2.ZERO, tam), Color(0.85, 0.1, 0.15, a / 6.0), false, w)
	# mira (abre e fica branca quando a tinta acerta alguém)
	var abre := 4.0 if _acerto_t > 0.0 else 0.0
	var cor_mira := Color.WHITE if _acerto_t > 0.0 else Color(T.CREME, 0.95)
	for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		_desenho.draw_line(c + d * (7 + abre), c + d * (19 + abre), Color(0, 0, 0, 0.45), 5.0, true)
		_desenho.draw_line(c + d * (7 + abre), c + d * (19 + abre), cor_mira, 2.5, true)
	if _acerto_t > 0.0:
		for d in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			_desenho.draw_line(c + d * 9, c + d * 16, T.LARANJA_CLARO, 3.0, true)
	# joystick com setas
	var base := _joy_origem if _joy_id >= 0 else Vector2(132, tam.y - 138)
	var ponto := _joy_pos if _joy_id >= 0 else base
	_desenho.draw_circle(base, RAIO_JOY, Color(0.07, 0.12, 0.2, 0.45))
	_desenho.draw_arc(base, RAIO_JOY, 0, TAU, 56, Color(1, 1, 1, 0.35), 3.0, true)
	for k in 4:
		var ang := k * PI * 0.5
		var dir := Vector2(cos(ang), sin(ang))
		var lado := Vector2(-dir.y, dir.x)
		var p0 := base + dir * (RAIO_JOY - 12)
		_desenho.draw_colored_polygon(PackedVector2Array([p0, p0 - dir * 13 + lado * 10, p0 - dir * 13 - lado * 10]), Color(1, 1, 1, 0.45))
	var lim := ponto - base
	if lim.length() > RAIO_JOY:
		lim = lim.normalized() * RAIO_JOY
	_desenho.draw_circle(base + lim + Vector2(0, 3), 36, Color(0, 0, 0, 0.25))
	_desenho.draw_circle(base + lim, 36, Color("e7ebef"))
	_desenho.draw_circle(base + lim + Vector2(-6, -8), 22, Color(1, 1, 1, 0.55))
	# botões redondos
	for b in _botoes:
		var cor: Color = b.cor
		var apertado: bool = b.dedo >= 0
		if b.acao == "tiro":
			_desenho.draw_circle(b.centro, b.raio + 9, Color(T.LARANJA_CLARO, 0.35 if apertado else 0.22))
			_desenho.draw_circle(b.centro, b.raio, cor.lightened(0.1) if apertado else cor)
			_desenho.draw_circle(b.centro + Vector2(0, -b.raio * 0.25), b.raio * 0.7, Color(1, 1, 1, 0.12))
			_desenho.draw_arc(b.centro, b.raio, 0, TAU, 64, T.LARANJA_CLARO.lightened(0.3), 4.0, true)
		else:
			_desenho.draw_circle(b.centro, b.raio, Color(cor, 0.92 if apertado else 0.72))
			_desenho.draw_arc(b.centro, b.raio, 0, TAU, 48, Color(1, 1, 1, 0.55), 3.0, true)

func _desenhar_minimapa() -> void:
	var m := _minimapa
	var e: float = m.get_meta("escala")
	m.draw_rect(Rect2(Vector2.ZERO, m.size), Color(0.07, 0.12, 0.2, 0.75))
	var cores := {"#": Color(0.75, 0.78, 0.82, 0.85), "c": Color(0.6, 0.64, 0.7, 0.6), "A": Color("d9534a"), "B": Color("3f6fc9"),
		"T": Color(T.TEAL, 0.8), "D": Color(T.VERMELHO, 0.6)}
	for y in arena.altura:
		var linha: String = arena.grade[y]
		for x in arena.largura:
			var ch := linha[x]
			if cores.has(ch):
				m.draw_rect(Rect2(Vector2(x, y) * e, Vector2(e, e)), cores[ch])
	var para_mapa := func(p: Vector3) -> Vector2:
		return Vector2((p.x / arena.CELULA + arena.largura * 0.5) * e, (p.z / arena.CELULA + arena.altura * 0.5) * e)
	for c in arena.combatentes:
		if c == arena.jogador or c.morto or c.time != 0:
			continue
		m.draw_circle(para_mapa.call(c.global_position), 4.0, T.TEAL_CLARO)
	var j = arena.jogador
	var p: Vector2 = para_mapa.call(j.global_position)
	var f := -Vector2(sin(j.rotation.y), cos(j.rotation.y))
	var lado := Vector2(-f.y, f.x)
	m.draw_colored_polygon(PackedVector2Array([p + f * 10, p - f * 6 + lado * 6, p - f * 6 - lado * 6]), T.TEAL_CLARO)
	m.draw_rect(Rect2(Vector2.ZERO, m.size), Color(1, 1, 1, 0.4), false, 2.0)
