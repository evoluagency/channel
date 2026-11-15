extends Control
## Menus do Valdora PvP (sessão 1.6): só o layout, com espaços reservados.
## Estrutura: barra lateral de ícones à esquerda, abas no topo, moedas à direita e conteúdo.
## Nenhum item, arma ou produto real: os cartões são marcadores com a cor da raridade.
## Cena de prévia: res://scenes/pvp/MenuPvP.tscn (o jogo instalado não usa esta cena).

const T := preload("res://scripts/ui/pvp/pvp_tema.gd")
const ICONE := preload("res://scripts/ui/pvp/pvp_icone.gd")
const FUNDO := preload("res://scripts/ui/pvp/pvp_fundo.gd")

## Barra lateral: [id da tela, ícone, rótulo]
const LATERAL := [
	["inicio", "jogar", "Jogar"],
	["inventario", "arma", "Inventário"],
	["loja", "moedas", "Loja"],
	["mercado", "carrinho", "Mercado"],
	["cla", "escudo", "Clã"],
	["ajustes", "engrenagem", "Ajustes"],
	["chat", "chat", "Chat"],
]
const TELAS := ["inicio", "modos", "inventario", "loja", "mercado", "cla", "ajustes", "chat", "carregando", "partida"]

var tela := ""
var fundo: Control
var lateral: VBoxContainer
var topo_abas: HBoxContainer
var topo_moedas: HBoxContainer
var corpo: Control
var moldura: Control      # lateral + topo (some na partida e no carregamento)
var _botoes_lateral := {}
var aba_atual := {}       # tela -> índice da aba

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo = FUNDO.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	_moldura()
	abrir("inicio")

# ---------------------------------------------------------------- estrutura

func _moldura() -> void:
	moldura = Control.new()
	moldura.set_anchors_preset(Control.PRESET_FULL_RECT)
	moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(moldura)
	# barra lateral
	var bl := PanelContainer.new()
	bl.add_theme_stylebox_override("panel", T.caixa(Color(T.NOITE, 0.94), 0))
	bl.anchor_bottom = 1.0
	bl.offset_right = 96
	moldura.add_child(bl)
	lateral = VBoxContainer.new()
	lateral.add_theme_constant_override("separation", 0)
	bl.add_child(lateral)
	var marca := _rotulo("V", 34, T.LARANJA, 900, true)
	marca.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marca.custom_minimum_size = Vector2(96, 64)
	marca.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lateral.add_child(marca)
	for item in LATERAL:
		var b := _botao_lateral(item[0], item[1], item[2])
		lateral.add_child(b)
		_botoes_lateral[item[0]] = b
	# topo: abas da tela e moedas
	var topo := HBoxContainer.new()
	topo.anchor_right = 1.0
	topo.offset_left = 112
	topo.offset_right = -16
	topo.offset_top = 10
	topo.offset_bottom = 66
	topo.add_theme_constant_override("separation", 8)
	moldura.add_child(topo)
	topo_abas = HBoxContainer.new()
	topo_abas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo_abas.add_theme_constant_override("separation", 6)
	topo.add_child(topo_abas)
	topo_moedas = HBoxContainer.new()
	topo_moedas.add_theme_constant_override("separation", 10)
	topo.add_child(topo_moedas)
	topo_moedas.add_child(_moeda("C", "0", T.TEAL))
	topo_moedas.add_child(_moeda("G", "0", T.OURO))
	# corpo
	corpo = Control.new()
	corpo.set_anchors_preset(Control.PRESET_FULL_RECT)
	corpo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(corpo)

func abrir(id: String) -> void:
	tela = id
	for c in corpo.get_children():
		c.queue_free()
	for c in topo_abas.get_children():
		c.queue_free()
	var cheia := id in ["carregando", "partida"]
	moldura.visible = not cheia
	fundo.tom = "partida" if id == "partida" else "menu"
	fundo.queue_redraw()
	for k in _botoes_lateral:
		_marcar_lateral(_botoes_lateral[k], k == id or (k == "inicio" and id == "modos"))
	var area := Control.new()
	area.set_anchors_preset(Control.PRESET_FULL_RECT)
	if not cheia:
		area.offset_left = 112
		area.offset_top = 78
		area.offset_right = -16
		area.offset_bottom = -16
	corpo.add_child(area)
	call("_tela_" + id, area)

# ---------------------------------------------------------------- peças

func _rotulo(texto: String, tam := 18, cor := T.TEXTO, peso := 700, italico := false) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_override("font", T.fonte(peso, italico))
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	return l

func _titulo(texto: String, tam := 28) -> Label:
	var l := _rotulo(texto.to_upper(), tam, T.CREME, 900, true)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.45))
	l.add_theme_constant_override("outline_size", 6)
	return l

func _painel(cor := Color(T.PAINEL, 0.92), raio := T.RAIO, borda := 2) -> PanelContainer:
	var p := PanelContainer.new()
	var s := T.caixa(cor, raio, borda, T.BORDA, 6)
	s.content_margin_left = 12; s.content_margin_right = 12
	s.content_margin_top = 10; s.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", s)
	return p

## tipo: laranja (principal), teal (secundário), escuro (neutro)
func _botao(texto: String, tipo := "laranja", tam := 22, altura := 56) -> Button:
	var b := Button.new()
	b.text = texto.to_upper()
	b.custom_minimum_size = Vector2(0, maxf(altura, T.ALVO_MIN))
	var cores: Array = {"laranja": [T.LARANJA, T.LARANJA_ESCURO, T.LARANJA_CLARO],
		"teal": [T.TEAL_ESCURO.lightened(0.08), Color("#0d5357"), T.TEAL],
		"escuro": [T.PAINEL_3, Color("#1a2a3c"), T.PAINEL_3.lightened(0.12)]}[tipo]
	b.add_theme_stylebox_override("normal", T.caixa_botao(cores[0], cores[1]))
	b.add_theme_stylebox_override("hover", T.caixa_botao(cores[2], cores[1]))
	b.add_theme_stylebox_override("pressed", T.caixa_botao(cores[1].lightened(0.15), cores[1], T.RAIO_BOTAO, true))
	b.add_theme_stylebox_override("focus", T.caixa(Color(0, 0, 0, 0), T.RAIO_BOTAO, 2, T.TEAL_CLARO))
	b.add_theme_font_override("font", T.fonte(900, true))
	b.add_theme_font_size_override("font_size", tam)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, Color.WHITE)
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.35))
	b.add_theme_constant_override("outline_size", 4)
	return b

func _botao_lateral(id: String, icone: String, texto: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(96, 86)
	b.tooltip_text = texto
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(abrir.bind(id))
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 2)
	b.add_child(v)
	var ic = ICONE.new(icone, T.TEXTO_2, 34)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	var l := _rotulo(texto, 12, T.TEXTO_2, 700)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(l)
	b.set_meta("icone", ic)
	b.set_meta("rotulo", l)
	return b

func _marcar_lateral(b: Button, ativo: bool) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(T.TEAL, 0.16) if ativo else Color(0, 0, 0, 0)
	s.border_width_left = 5 if ativo else 0
	s.border_color = T.TEAL
	b.add_theme_stylebox_override("normal", s)
	b.add_theme_stylebox_override("hover", T.caixa(Color(1, 1, 1, 0.06), 0))
	b.add_theme_stylebox_override("pressed", s)
	var c := T.TEAL_CLARO if ativo else T.TEXTO_2
	b.get_meta("icone").cor = c
	b.get_meta("icone").queue_redraw()
	b.get_meta("rotulo").add_theme_color_override("font_color", c)

## Abas do topo da tela. Devolve o índice ativo.
func _abas(nomes: Array, alvo: HBoxContainer = null) -> int:
	var caixa: HBoxContainer = topo_abas if alvo == null else alvo
	var ativa: int = aba_atual.get(tela + str(alvo != null), 0)
	for i in nomes.size():
		var b := Button.new()
		b.text = String(nomes[i]).to_upper()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(150, 52)
		var s := StyleBoxFlat.new()
		s.bg_color = Color(T.PAINEL_2, 0.95) if i == ativa else Color(T.PAINEL, 0.55)
		s.set_corner_radius_all(12)
		s.border_width_bottom = 4 if i == ativa else 0
		s.border_color = T.TEAL
		s.content_margin_left = 16; s.content_margin_right = 16
		b.add_theme_stylebox_override("normal", s)
		b.add_theme_stylebox_override("hover", s)
		b.add_theme_stylebox_override("pressed", s)
		b.add_theme_font_override("font", T.fonte(900, true))
		b.add_theme_font_size_override("font_size", 20 if alvo == null else 16)
		var c := T.CREME if i == ativa else T.TEXTO_2
		for k in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(k, c)
		var chave := tela + str(alvo != null)
		b.pressed.connect(func():
			aba_atual[chave] = i
			abrir(tela))
		caixa.add_child(b)
	return ativa

func _moeda(simbolo: String, valor: String, cor: Color) -> Control:
	var p := PanelContainer.new()
	var s := T.caixa(Color(T.NOITE, 0.85), 22, 2, cor.darkened(0.2))
	s.content_margin_left = 6; s.content_margin_right = 6
	s.content_margin_top = 4; s.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", s)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	p.add_child(h)
	var m := Label.new()
	m.text = simbolo
	m.custom_minimum_size = Vector2(36, 36)
	m.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	m.add_theme_font_override("font", T.fonte(900))
	m.add_theme_font_size_override("font_size", 18)
	m.add_theme_color_override("font_color", T.NOITE)
	var ms := T.caixa(cor, 18)
	m.add_theme_stylebox_override("normal", ms)
	h.add_child(m)
	var v := _rotulo(valor, 22, T.TEXTO, 800)
	v.custom_minimum_size = Vector2(70, 0)
	v.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(v)
	var mais := Button.new()
	mais.custom_minimum_size = Vector2(40, 40)
	mais.add_theme_stylebox_override("normal", T.caixa(cor.darkened(0.15), 12))
	mais.add_theme_stylebox_override("hover", T.caixa(cor, 12))
	mais.add_theme_stylebox_override("pressed", T.caixa(cor.darkened(0.3), 12))
	var ic = ICONE.new("mais", Color.WHITE, 22)
	ic.position = Vector2(9, 9)
	ic.size = Vector2(22, 22)
	mais.add_child(ic)
	h.add_child(mais)
	return p

## Cartão de item vazio: área do desenho com o ícone apagado e faixa de raridade embaixo.
func _cartao(nome: String, raridade := "comum", icone := "arma", rodape := "", preco := "") -> PanelContainer:
	var p := PanelContainer.new()
	var s := T.caixa(Color(T.PAINEL_2, 0.92), 12, 2, T.BORDA)
	p.add_theme_stylebox_override("panel", s)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	var area := CenterContainer.new()
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area.custom_minimum_size = Vector2(0, 80)
	v.add_child(area)
	area.add_child(ICONE.new(icone, Color(T.TEXTO_2, 0.35), 64))
	var faixa := PanelContainer.new()
	var fs := T.caixa(T.RARIDADE.get(raridade, T.RARIDADE.comum), 0)
	fs.corner_radius_bottom_left = 10; fs.corner_radius_bottom_right = 10
	fs.content_margin_left = 10; fs.content_margin_right = 10
	fs.content_margin_top = 4; fs.content_margin_bottom = 4
	faixa.add_theme_stylebox_override("panel", fs)
	v.add_child(faixa)
	var fv := VBoxContainer.new()
	fv.add_theme_constant_override("separation", 0)
	faixa.add_child(fv)
	fv.add_child(_rotulo(nome, 15, Color.WHITE, 800))
	if rodape != "" or preco != "":
		var h := HBoxContainer.new()
		fv.add_child(h)
		var r := _rotulo(rodape, 12, Color(1, 1, 1, 0.75), 600)
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(r)
		h.add_child(_rotulo(preco, 15, T.CREME, 900))
	return p

func _grade(colunas: int, sep := 12) -> GridContainer:
	var g := GridContainer.new()
	g.columns = colunas
	g.add_theme_constant_override("h_separation", sep)
	g.add_theme_constant_override("v_separation", sep)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return g

func _rolagem(filho: Control) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	filho.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(filho)
	return sc

func _avatar(iniciais: String, cor := T.TEAL, tam := 52) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(tam, tam)
	p.add_theme_stylebox_override("panel", T.caixa(cor.darkened(0.35), 10, 3, cor))
	var l := _rotulo(iniciais, int(tam * 0.36), T.CREME, 900, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p

func _linha_sep() -> HSeparator:
	var s := HSeparator.new()
	var st := StyleBoxLine.new()
	st.color = Color(T.BORDA, 0.6)
	st.thickness = 1
	s.add_theme_stylebox_override("separator", st)
	return s

# ---------------------------------------------------------------- telas

func _tela_inicio(a: Control) -> void:
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.add_theme_constant_override("separation", 16)
	a.add_child(h)
	# coluna da esquerda: perfil e amigos
	var esq := VBoxContainer.new()
	esq.custom_minimum_size = Vector2(320, 0)
	esq.add_theme_constant_override("separation", 10)
	h.add_child(esq)
	var perfil := _painel()
	esq.add_child(perfil)
	var ph := HBoxContainer.new()
	ph.add_theme_constant_override("separation", 12)
	perfil.add_child(ph)
	ph.add_child(_avatar("JG", T.LARANJA, 64))
	var pv := VBoxContainer.new()
	pv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ph.add_child(pv)
	pv.add_child(_rotulo("Jogador", 20, T.CREME, 900, true))
	var nh := HBoxContainer.new()
	pv.add_child(nh)
	var nivel := _rotulo(" 1 ", 15, T.NOITE, 900)
	nivel.add_theme_stylebox_override("normal", T.caixa(T.OURO, 8))
	nh.add_child(nivel)
	nh.add_child(_rotulo("  0 / 1.000 XP", 13, T.TEXTO_2, 600))
	var xp := ProgressBar.new()
	xp.custom_minimum_size = Vector2(0, 10)
	xp.value = 30
	xp.show_percentage = false
	xp.add_theme_stylebox_override("background", T.caixa(T.NOITE, 5))
	xp.add_theme_stylebox_override("fill", T.caixa(T.TEAL, 5))
	pv.add_child(xp)
	var amigos := _painel()
	amigos.size_flags_vertical = Control.SIZE_EXPAND_FILL
	esq.add_child(amigos)
	var av := VBoxContainer.new()
	av.add_theme_constant_override("separation", 6)
	amigos.add_child(av)
	var ah := HBoxContainer.new()
	av.add_child(ah)
	ah.add_child(ICONE.new("pessoa", T.TEXTO_2, 26))
	ah.add_child(_rotulo("  Amigos", 17, T.TEXTO, 700))
	av.add_child(_linha_sep())
	for i in 4:
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 10)
		linha.add_child(_avatar("?", T.PAINEL_3.lightened(0.2), 40))
		var lv := VBoxContainer.new()
		lv.add_theme_constant_override("separation", 0)
		lv.add_child(_rotulo("Amigo %d" % (i + 1), 15, T.TEXTO, 700))
		lv.add_child(_rotulo("Online" if i == 0 else "Offline", 12, T.VERDE if i == 0 else T.TEXTO_2, 600))
		linha.add_child(lv)
		av.add_child(linha)
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	av.add_child(esp)
	av.add_child(_botao("Encontrar amigos", "escuro", 16, 48))
	# centro: agente sobre o pedestal (espaço do modelo 3D)
	var centro := Control.new()
	centro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(centro)
	var ag := _agente()
	ag.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.add_child(ag)
	var lid := _botao("", "escuro", 14, 52)
	lid.custom_minimum_size = Vector2(64, 56)
	lid.anchor_top = 1.0; lid.anchor_bottom = 1.0
	lid.offset_top = -60; lid.offset_bottom = -4; lid.offset_right = 64
	var li = ICONE.new("lideres", T.CREME, 30)
	li.position = Vector2(17, 10)
	lid.add_child(li)
	centro.add_child(lid)
	# direita: evento, atalhos e jogar
	var dir := VBoxContainer.new()
	dir.custom_minimum_size = Vector2(330, 0)
	dir.add_theme_constant_override("separation", 10)
	h.add_child(dir)
	dir.add_child(_banner("Evento da temporada", "Arte do evento", T.LARANJA))
	var atalhos := HBoxContainer.new()
	atalhos.add_theme_constant_override("separation", 10)
	dir.add_child(atalhos)
	for at in [["presente", "Eventos"], ["passe", "Passe"]]:
		var b := _botao("", "escuro", 14, 92)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var bv := VBoxContainer.new()
		bv.set_anchors_preset(Control.PRESET_FULL_RECT)
		bv.alignment = BoxContainer.ALIGNMENT_CENTER
		bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic = ICONE.new(at[0], T.LARANJA_CLARO, 36)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		bv.add_child(ic)
		var l := _rotulo(at[1].to_upper(), 15, T.CREME, 900, true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bv.add_child(l)
		b.add_child(bv)
		atalhos.add_child(b)
	dir.add_child(_banner("Missão do dia", "Arte da missão", T.TEAL))
	var esp2 := Control.new()
	esp2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dir.add_child(esp2)
	var modo := _botao("Selecionar modo de jogo", "teal", 17, 52)
	modo.pressed.connect(abrir.bind("modos"))
	dir.add_child(modo)
	var jogar := _botao("Jogar", "laranja", 40, 84)
	jogar.pressed.connect(abrir.bind("carregando"))
	dir.add_child(jogar)

## Banner de evento: painel com degradê e texto; a arte entra depois.
func _banner(titulo: String, marcador: String, cor: Color) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(0, 118)
	var s := T.caixa(cor.darkened(0.45), T.RAIO, 2, cor)
	p.add_theme_stylebox_override("panel", s)
	var m := MarginContainer.new()
	for k in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		m.add_theme_constant_override(k, 12)
	p.add_child(m)
	var v := VBoxContainer.new()
	m.add_child(v)
	var mk := _rotulo("[ %s ]" % marcador, 12, Color(1, 1, 1, 0.45), 600)
	v.add_child(mk)
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(esp)
	v.add_child(_titulo(titulo, 22))
	return p

## Silhueta do agente sobre o pedestal (marcador do modelo 3D do personagem).
func _agente() -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var s := c.size
		var base := Vector2(s.x * 0.5, s.y * 0.86)
		# pedestal
		for i in 3:
			var r := Vector2(s.x * (0.36 - i * 0.04), s.y * (0.07 - i * 0.008))
			var cor: Color = [Color(T.PAINEL_3, 0.9), Color(T.TEAL, 0.5), Color(T.PAINEL_2, 0.95)][i]
			var v := PackedVector2Array()
			for k in 32:
				var ang := k * TAU / 32
				v.append(base + Vector2(cos(ang) * r.x, sin(ang) * r.y - i * 6))
			c.draw_colored_polygon(v, cor)
		# silhueta
		var h := s.y * 0.66
		var cor_s := Color(T.CREME, 0.12)
		c.draw_circle(base + Vector2(0, -h * 0.9), h * 0.075, cor_s)
		c.draw_colored_polygon(PackedVector2Array([
			base + Vector2(-h * 0.17, -h * 0.8), base + Vector2(h * 0.17, -h * 0.8),
			base + Vector2(h * 0.2, -h * 0.45), base + Vector2(h * 0.13, -h * 0.42),
			base + Vector2(h * 0.12, -0.0), base + Vector2(h * 0.02, -0.0),
			base + Vector2(0, -h * 0.38), base + Vector2(-h * 0.02, -0.0),
			base + Vector2(-h * 0.12, -0.0), base + Vector2(-h * 0.13, -h * 0.42),
			base + Vector2(-h * 0.2, -h * 0.45)]), cor_s)
		var f := T.fonte(700)
		var txt := "MODELO DO AGENTE"
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		c.draw_string(f, base + Vector2(-w * 0.5, -h * 0.5), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(T.TEXTO_2, 0.6)))
	c.resized.connect(c.queue_redraw)
	return c

func _tela_modos(a: Control) -> void:
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.add_theme_constant_override("separation", 14)
	a.add_child(h)
	topo_abas.add_child(_voltar())
	topo_abas.add_child(_titulo("Selecionar modo de jogo", 26))
	# categorias à esquerda
	var cat := VBoxContainer.new()
	cat.custom_minimum_size = Vector2(150, 0)
	h.add_child(cat)
	var ativa: int = aba_atual.get("modos_cat", 0)
	for i in 2:
		var b := _botao(["Principal", "Outro"][i], "teal" if i == ativa else "escuro", 17, 56)
		b.pressed.connect(func():
			aba_atual["modos_cat"] = i
			abrir("modos"))
		cat.add_child(b)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 12)
	h.add_child(v)
	var cartoes := HBoxContainer.new()
	cartoes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cartoes.add_theme_constant_override("separation", 12)
	v.add_child(cartoes)
	if ativa == 0:
		var esq := VBoxContainer.new()
		esq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		esq.size_flags_stretch_ratio = 3.0
		esq.add_theme_constant_override("separation", 12)
		cartoes.add_child(esq)
		var cima := HBoxContainer.new()
		cima.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cima.add_theme_constant_override("separation", 12)
		esq.add_child(cima)
		cima.add_child(_modo("Mata-mata em equipe", "arma", T.TEAL, true))
		cima.add_child(_modo("Desarmar", "granada", T.LARANJA))
		var baixo := HBoxContainer.new()
		baixo.size_flags_vertical = Control.SIZE_EXPAND_FILL
		baixo.size_flags_stretch_ratio = 1.4
		baixo.add_theme_constant_override("separation", 12)
		esq.add_child(baixo)
		for m in ["Competitivo", "Aliados", "Duelo"]:
			baixo.add_child(_modo(m, "escudo", T.OURO, false, "Calibração  0/10"))
		cartoes.add_child(_modo("Duelo 2 x 2", "arma", T.TEAL_ESCURO))
		cartoes.add_child(_modo("Modo especial", "presente", T.VERMELHO))
	else:
		cartoes.add_child(_modo("Treinamento", "pessoa", T.LARANJA))
		cartoes.add_child(_modo("Torneio", "trofeu", T.OURO))
		var vazio := Control.new()
		vazio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cartoes.add_child(vazio)
	# barra de baixo
	var bb := HBoxContainer.new()
	bb.add_theme_constant_override("separation", 12)
	v.add_child(bb)
	var pub := _painel()
	bb.add_child(pub)
	var ph := HBoxContainer.new()
	ph.add_theme_constant_override("separation", 14)
	pub.add_child(ph)
	ph.add_child(_rotulo("Partida pública", 17, T.TEXTO, 700))
	var ch := CheckButton.new()
	ch.button_pressed = true
	ch.custom_minimum_size = Vector2(64, 48)
	ph.add_child(ch)
	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bb.add_child(esp)
	var mapas := _painel()
	bb.add_child(mapas)
	var mh := HBoxContainer.new()
	mh.add_theme_constant_override("separation", 24)
	mapas.add_child(mh)
	mh.add_child(_rotulo("MAPAS", 15, T.TEXTO_2, 800))
	mh.add_child(_rotulo("Aleatório (1)", 17, T.TEXTO, 700))
	var sel := _botao("Selecionar modo", "laranja", 20, 56)
	sel.custom_minimum_size.x = 280
	sel.pressed.connect(abrir.bind("inicio"))
	bb.add_child(sel)

func _modo(nome: String, icone: String, cor: Color, selecionado := false, extra := "") -> Control:
	var b := Button.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	var s := T.caixa(cor.darkened(0.62), 14, 4 if selecionado else 2, T.CREME if selecionado else cor.darkened(0.25))
	b.add_theme_stylebox_override("normal", s)
	var sh := s.duplicate() as StyleBoxFlat
	sh.bg_color = cor.darkened(0.5)
	b.add_theme_stylebox_override("hover", sh)
	b.add_theme_stylebox_override("pressed", sh)
	var ic = ICONE.new(icone, Color(cor, 0.4), 90)
	ic.set_anchors_preset(Control.PRESET_FULL_RECT)
	ic.offset_bottom = -40
	b.add_child(ic)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 12; v.offset_right = -12; v.offset_top = 8; v.offset_bottom = -10
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	if extra != "":
		v.add_child(_rotulo(extra, 13, T.TEXTO_2, 700))
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	esp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(esp)
	var t := _titulo(nome, 19)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	return b

func _voltar() -> Button:
	var b := _botao("", "escuro", 14, 52)
	b.custom_minimum_size = Vector2(56, 52)
	var ic = ICONE.new("voltar", T.CREME, 28)
	ic.position = Vector2(14, 10)
	b.add_child(ic)
	b.pressed.connect(abrir.bind("inicio"))
	return b

func _tela_inventario(a: Control) -> void:
	topo_abas.add_child(_titulo("Inventário", 28))
	var esp := Control.new()
	esp.custom_minimum_size = Vector2(24, 0)
	topo_abas.add_child(esp)
	topo_abas.add_child(_botao("Equipamento do agente", "escuro", 15, 50))
	var g := _grade(5)
	var rar := ["epico", "raro", "incomum", "raro", "raro", "incomum", "incomum", "comum", "lendario", "raro",
		"comum", "incomum", "epico", "comum", "raro"]
	var ic := ["passe", "passe", "passe", "arma", "arma", "arma", "arma", "arma", "faca", "arma", "arma", "arma", "granada", "arma", "arma"]
	for i in rar.size():
		var c := _cartao("Item %02d" % (i + 1), rar[i], ic[i])
		c.custom_minimum_size = Vector2(0, 170)
		g.add_child(c)
	a.add_child(_rolagem(g))

func _tela_loja(a: Control) -> void:
	var ativa := _abas(["Loja", "Ouro"])
	var g := _grade(4, 14)
	var n := 8 if ativa == 0 else 4
	for i in n:
		var caixa := i < 4
		var c := _cartao("Caixa %d" % (i + 1) if caixa else "Caixote %d" % (i - 3), "lendario" if caixa else "incomum",
			"presente", "", ("G 100" if caixa else "C 100") if ativa == 0 else "G %d" % [100, 500, 1200, 2500][i])
		c.custom_minimum_size = Vector2(0, 230)
		g.add_child(c)
	a.add_child(_rolagem(g))

func _tela_mercado(a: Control) -> void:
	_abas(["Mercado", "Minhas solicitações", "Histórico"])
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.add_theme_constant_override("separation", 14)
	a.add_child(h)
	var filtro := _painel()
	filtro.custom_minimum_size = Vector2(250, 0)
	h.add_child(filtro)
	var fv := VBoxContainer.new()
	fv.add_theme_constant_override("separation", 8)
	filtro.add_child(fv)
	fv.add_child(_rotulo("Classificar por:", 17, T.TEXTO, 700))
	for f in ["Raridade", "Preço", "Filtro"]:
		var b := _botao(f, "escuro", 15, 50)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		fv.add_child(b)
	var g := _grade(4)
	var rar := ["raro", "raro", "raro", "raro", "epico", "epico", "raro", "comum", "raro", "incomum", "epico", "epico"]
	for i in rar.size():
		var c := _cartao("Item %02d" % (i + 1), rar[i], "arma" if i > 3 else "trofeu", "0 unid.", "G 0,00")
		c.custom_minimum_size = Vector2(0, 175)
		g.add_child(c)
	var sc := _rolagem(g)
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.set_anchors_preset(Control.PRESET_TOP_LEFT)
	h.add_child(sc)

func _tela_cla(a: Control) -> void:
	_abas(["Encontrar clã", "Solicitações"])
	topo_abas.add_child(_botao("Criar clã", "laranja", 17, 50))
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 8)
	a.add_child(v)
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 8)
	v.add_child(cab)
	var busca := LineEdit.new()
	busca.placeholder_text = "Nome ou identificação do clã"
	busca.custom_minimum_size = Vector2(380, 52)
	busca.add_theme_stylebox_override("normal", T.caixa(T.NOITE, 12, 2, T.BORDA))
	busca.add_theme_font_override("font", T.fonte(600))
	busca.add_theme_font_size_override("font_size", 16)
	cab.add_child(busca)
	var lupa := _botao("", "teal", 14, 52)
	lupa.custom_minimum_size = Vector2(56, 52)
	var li = ICONE.new("lupa", Color.WHITE, 26)
	li.position = Vector2(15, 11)
	lupa.add_child(li)
	cab.add_child(lupa)
	var e := Control.new()
	e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(e)
	cab.add_child(_rotulo("Membros", 16, T.TEXTO_2, 700))
	var e2 := Control.new()
	e2.custom_minimum_size = Vector2(250, 0)
	cab.add_child(e2)
	cab.add_child(_rotulo("Ações   ", 16, T.TEXTO_2, 700))
	var lista := VBoxContainer.new()
	lista.add_theme_constant_override("separation", 8)
	for i in 6:
		var p := _painel(Color(T.PAINEL, 0.9), 12, 1)
		var lh := HBoxContainer.new()
		lh.add_theme_constant_override("separation", 14)
		p.add_child(lh)
		var em := PanelContainer.new()
		em.custom_minimum_size = Vector2(60, 60)
		em.add_theme_stylebox_override("panel", T.caixa(T.NOITE, 10))
		var ei = ICONE.new("escudo", Color(T.TEXTO_2, 0.5), 40)
		ei.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		em.add_child(ei)
		lh.add_child(em)
		var nv := VBoxContainer.new()
		nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nv.add_child(_rotulo("[TAG%d]" % (i + 1), 13, T.TEXTO_2, 600))
		nv.add_child(_rotulo("Nome do clã %d" % (i + 1), 18, T.TEXTO, 700))
		lh.add_child(nv)
		var mb := _rotulo("%d / 10" % (i + 1), 24, T.CREME, 800)
		mb.custom_minimum_size = Vector2(160, 0)
		lh.add_child(mb)
		var env := _botao("Enviar solicitação", "teal", 15, 50)
		env.custom_minimum_size.x = 260
		lh.add_child(env)
		lista.add_child(p)
	var sc := _rolagem(lista)
	sc.set_anchors_preset(Control.PRESET_TOP_LEFT)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sc)

func _tela_ajustes(a: Control) -> void:
	var ativa := _abas(["Jogo", "Vídeo", "Controles", "Som"])
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 8)
	a.add_child(v)
	var sub := HBoxContainer.new()
	sub.add_theme_constant_override("separation", 6)
	v.add_child(sub)
	var linhas: Array = []
	match ativa:
		0:
			_abas(["Geral", "Privacidade", "Autorização"], sub)
			linhas = [["Região (Automático)", ["Selecionar"]], ["Idioma (Idioma do sistema)", ["Selecionar"]],
				["Informações legais", ["Abrir"]], ["Visualizar braços e armas", ["Padrão", "Clássico"]],
				["Visibilidade do HUD", ["Visível", "Só abates", "Invisível"]]]
		1:
			linhas = [["Qualidade gráfica", ["Baixa", "Média", "Alta"]], ["Limite de quadros", ["30", "60", "90"]],
				["Sombras", ["Desligadas", "Ligadas"]], ["Resolução 3D", ["75%", "100%"]]]
		2:
			linhas = [["Sensibilidade da mira", ["−", "+"]], ["Disparo automático", ["Desligado", "Ligado"]],
				["Editar posição dos botões", ["Abrir"]]]
		_:
			linhas = [["Volume geral", ["−", "+"]], ["Música", ["Desligada", "Ligada"]], ["Voz da equipe", ["Desligada", "Ligada"]]]
	var lista := VBoxContainer.new()
	lista.add_theme_constant_override("separation", 6)
	for l in linhas:
		var p := _painel(Color(T.PAINEL, 0.85), 12, 1)
		var lh := HBoxContainer.new()
		lh.add_theme_constant_override("separation", 10)
		p.add_child(lh)
		var r := _rotulo(l[0], 19, T.TEXTO, 600)
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lh.add_child(r)
		var opc: Array = l[1]
		for i in opc.size():
			var b := _botao(opc[i], "teal" if i == opc.size() - 1 else "escuro", 16, 50)
			b.custom_minimum_size.x = 200 if opc.size() <= 2 else 150
			lh.add_child(b)
		lista.add_child(p)
	var sc := _rolagem(lista)
	sc.set_anchors_preset(Control.PRESET_TOP_LEFT)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sc)
	var bb := HBoxContainer.new()
	v.add_child(bb)
	bb.add_child(_botao("Redefinir ao padrão", "escuro", 16, 50))
	var e := Control.new()
	e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bb.add_child(e)
	var ap := _botao("Aplicar", "laranja", 18, 50)
	ap.custom_minimum_size.x = 220
	bb.add_child(ap)

func _tela_chat(a: Control) -> void:
	_abas(["Amigos", "Sistema"])
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.add_theme_constant_override("separation", 14)
	a.add_child(h)
	var lista := _painel()
	lista.custom_minimum_size = Vector2(440, 0)
	h.add_child(lista)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 8)
	lista.add_child(lv)
	for i in 2:
		var lh := HBoxContainer.new()
		lh.add_theme_constant_override("separation", 12)
		lh.add_child(_avatar("?", T.PAINEL_3.lightened(0.2), 60))
		var mv := VBoxContainer.new()
		mv.add_theme_constant_override("separation", 0)
		mv.add_child(_rotulo("00/00/0000", 13, T.TEXTO_2, 600))
		mv.add_child(_rotulo("Amigo %d" % (i + 1), 17, T.TEXTO, 800))
		mv.add_child(_rotulo("Última mensagem…", 14, T.TEXTO_2, 600))
		lh.add_child(mv)
		lv.add_child(lh)
		lv.add_child(_linha_sep())
	var vazio := _painel(Color(T.PAINEL, 0.6))
	vazio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(vazio)
	var cv := VBoxContainer.new()
	cv.alignment = BoxContainer.ALIGNMENT_CENTER
	cv.add_theme_constant_override("separation", 14)
	vazio.add_child(cv)
	var ic = ICONE.new("chat", Color(T.TEXTO_2, 0.5), 110)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cv.add_child(ic)
	var t := _rotulo("Escolha uma conversa\nou comece uma nova", 20, T.TEXTO, 700)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cv.add_child(t)
	var nb := _botao("Nova conversa", "laranja", 18, 54)
	nb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	nb.custom_minimum_size.x = 300
	cv.add_child(nb)
	var aviso := _rotulo("Nunca compartilhe senha, dados pessoais ou de pagamento. Quem pedir isso pode ser bloqueado.", 13, T.TEXTO_2, 600)
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.custom_minimum_size = Vector2(500, 0)
	aviso.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cv.add_child(aviso)

func _tela_carregando(a: Control) -> void:
	var p := ColorRect.new()
	p.color = Color(T.NOITE, 0.55)
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	a.add_child(p)
	var dica := PanelContainer.new()
	dica.add_theme_stylebox_override("panel", T.caixa(Color(T.NOITE, 0.9), 0))
	dica.anchor_right = 1.0
	dica.offset_bottom = 64
	a.add_child(dica)
	var dl := _rotulo("   Dica: caixas raras têm mais chance de visuais especiais do que caixotes.", 18, T.TEXTO, 600)
	dl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dica.add_child(dl)
	# minimapa (marcador)
	var mapa := _painel(Color(T.PAINEL_2, 0.9))
	mapa.position = Vector2(70, 110)
	mapa.size = Vector2(470, 470)
	a.add_child(mapa)
	var mc := CenterContainer.new()
	mapa.add_child(mc)
	var mv := VBoxContainer.new()
	mc.add_child(mv)
	var mi = ICONE.new("mapa", Color(T.TEXTO_2, 0.4), 160)
	mi.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mv.add_child(mi)
	var ml := _rotulo("MINIMAPA", 16, T.TEXTO_2, 800)
	ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mv.add_child(ml)
	var info := VBoxContainer.new()
	info.position = Vector2(620, 130)
	info.custom_minimum_size = Vector2(600, 0)
	info.add_theme_constant_override("separation", 10)
	a.add_child(info)
	info.add_child(_titulo("Brasília", 64))
	info.add_child(_rotulo("Desarmar", 26, T.LARANJA_CLARO, 800, true))
	var d := _rotulo("Ataque e defesa em equipes de cinco. Plante ou desarme o dispositivo para vencer a rodada.", 20, T.TEXTO, 600)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(600, 0)
	info.add_child(d)
	var barra := ProgressBar.new()
	barra.value = 42
	barra.show_percentage = false
	barra.custom_minimum_size = Vector2(0, 16)
	barra.add_theme_stylebox_override("background", T.caixa(T.NOITE, 8))
	barra.add_theme_stylebox_override("fill", T.caixa(T.LARANJA, 8))
	barra.anchor_left = 0.48; barra.anchor_right = 0.96
	barra.anchor_top = 1.0; barra.anchor_bottom = 1.0
	barra.offset_top = -60; barra.offset_bottom = -44
	a.add_child(barra)
	var cl := _rotulo("Carregando recursos do jogo…", 18, T.TEXTO, 600)
	cl.anchor_left = 0.48; cl.anchor_top = 1.0; cl.anchor_bottom = 1.0
	cl.offset_top = -94
	a.add_child(cl)
	var ir := _botao("Entrar (prévia)", "teal", 15, 48)
	ir.anchor_left = 1.0; ir.anchor_right = 1.0
	ir.offset_left = -220; ir.offset_right = -24; ir.offset_top = 84; ir.offset_bottom = 132
	ir.pressed.connect(abrir.bind("partida"))
	a.add_child(ir)

## Interface da partida (só o layout; sem jogabilidade).
func _tela_partida(a: Control) -> void:
	# placar no topo
	var placar := HBoxContainer.new()
	placar.anchor_left = 0.5; placar.anchor_right = 0.5
	placar.offset_left = -330; placar.offset_right = 330; placar.offset_top = 10
	placar.add_theme_constant_override("separation", 6)
	a.add_child(placar)
	for i in 5:
		placar.add_child(_avatar("", T.TEAL, 44))
	var pt := _rotulo(" 0 ", 34, T.TEAL_CLARO, 900, true)
	placar.add_child(pt)
	var tempo := _rotulo(" 01:55 ", 22, T.TEXTO, 800)
	tempo.add_theme_stylebox_override("normal", T.caixa(Color(T.NOITE, 0.8), 10))
	tempo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placar.add_child(tempo)
	placar.add_child(_rotulo(" 0 ", 34, T.VERMELHO, 900, true))
	for i in 5:
		placar.add_child(_avatar("", T.VERMELHO, 44))
	var aq := _rotulo("  AQUECIMENTO 00:53  ", 18, T.TEXTO, 800)
	aq.add_theme_stylebox_override("normal", T.caixa(Color(T.NOITE, 0.7), 10))
	aq.anchor_left = 0.5; aq.anchor_right = 0.5
	aq.offset_left = -120; aq.offset_right = 120; aq.offset_top = 64
	aq.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	a.add_child(aq)
	# minimapa
	var mm := _painel(Color(T.NOITE, 0.7))
	mm.position = Vector2(16, 16)
	mm.size = Vector2(180, 180)
	a.add_child(mm)
	var mmi = ICONE.new("mapa", Color(T.TEXTO_2, 0.4), 120)
	mm.add_child(mmi)
	# pausa e ajustes
	for i in 2:
		var b := _botao("", "escuro", 14, 52)
		b.anchor_left = 1.0; b.anchor_right = 1.0
		b.offset_left = -76 - i * 66; b.offset_right = -20 - i * 66
		b.offset_top = 16; b.offset_bottom = 68
		var ic = ICONE.new(["pausa", "engrenagem"][i], T.CREME, 30)
		ic.position = Vector2(13, 10)
		b.add_child(ic)
		if i == 0:
			b.pressed.connect(abrir.bind("inicio"))
		a.add_child(b)
	# mira
	var mira := Control.new()
	mira.set_anchors_preset(Control.PRESET_CENTER)
	mira.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mira.draw.connect(func():
		for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			mira.draw_line(d * 6, d * 18, T.TEAL_CLARO, 3.0, true))
	a.add_child(mira)
	# controle de movimento
	var joy := Control.new()
	joy.anchor_top = 1.0; joy.anchor_bottom = 1.0
	joy.offset_left = 40; joy.offset_top = -250; joy.offset_right = 250; joy.offset_bottom = -40
	joy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joy.draw.connect(func():
		var c := joy.size * 0.5
		joy.draw_circle(c, joy.size.x * 0.5, Color(T.NOITE, 0.35))
		joy.draw_arc(c, joy.size.x * 0.5 - 2, 0, TAU, 48, Color(T.CREME, 0.35), 3.0, true)
		joy.draw_circle(c, joy.size.x * 0.2, Color(T.CREME, 0.55)))
	a.add_child(joy)
	# vida, colete, armas e munição
	var base := HBoxContainer.new()
	base.anchor_left = 0.5; base.anchor_right = 0.5; base.anchor_top = 1.0; base.anchor_bottom = 1.0
	base.offset_left = -330; base.offset_right = 160; base.offset_top = -84; base.offset_bottom = -20
	base.add_theme_constant_override("separation", 10)
	a.add_child(base)
	var vida := _painel(Color(T.NOITE, 0.75))
	base.add_child(vida)
	var vh := HBoxContainer.new()
	vida.add_child(vh)
	vh.add_child(_rotulo("+ 100", 24, T.VERDE, 900))
	vh.add_child(_rotulo("   ◆ 50", 24, T.TEAL_CLARO, 900))
	for i in 3:
		var s := _painel(Color(T.NOITE, 0.75) if i else Color(T.LARANJA, 0.35), 12, 2)
		s.custom_minimum_size = Vector2(96, 0)
		var si = ICONE.new(["arma", "arma", "granada"][i], T.CREME, 34)
		si.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		s.add_child(si)
		base.add_child(s)
	var mun := _rotulo("  24 / 90  ", 26, T.CREME, 900)
	mun.add_theme_stylebox_override("normal", T.caixa(Color(T.NOITE, 0.75), 12))
	mun.anchor_left = 1.0; mun.anchor_right = 1.0; mun.anchor_top = 1.0; mun.anchor_bottom = 1.0
	mun.offset_left = -440; mun.offset_right = -280; mun.offset_top = -300; mun.offset_bottom = -252
	mun.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mun.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	a.add_child(mun)
	# botões de ação
	var acoes := [["tiro", 150, Vector2(-190, -200), T.LARANJA], ["recarregar", 84, Vector2(-330, -150), T.PAINEL_3],
		["correr", 84, Vector2(-290, -260), T.PAINEL_3], ["agachar", 84, Vector2(-120, -310), T.PAINEL_3]]
	for ac in acoes:
		var b := Button.new()
		var d: float = ac[1]
		b.anchor_left = 1.0; b.anchor_right = 1.0; b.anchor_top = 1.0; b.anchor_bottom = 1.0
		b.offset_left = ac[2].x; b.offset_top = ac[2].y
		b.offset_right = ac[2].x + d; b.offset_bottom = ac[2].y + d
		var cor: Color = ac[3]
		var s := T.caixa(Color(cor, 0.85), int(d / 2), 4, Color(T.CREME, 0.6))
		b.add_theme_stylebox_override("normal", s)
		b.add_theme_stylebox_override("hover", s)
		b.add_theme_stylebox_override("pressed", T.caixa(cor.darkened(0.2), int(d / 2), 4, T.CREME))
		var ic = ICONE.new(ac[0], Color.WHITE, int(d * 0.5))
		ic.position = Vector2(d * 0.25, d * 0.25)
		b.add_child(ic)
		a.add_child(b)
