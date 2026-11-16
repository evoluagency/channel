extends Control
## Menus do Valdora PvP. Sessão 1.8: estrutura da arte conceitual do dono, com logo e moedas
## no topo, barra inferior BASE, HERÓIS, ARSENAL e MISSÕES, painéis navy translúcidos de
## cantos grandes e a vitrine 3D (herói ou marcador no pedestal) sobre a praça do Valdora.
## Nenhum item, arma ou produto real: os cartões são marcadores com a cor da raridade.
## Cena de prévia: res://scenes/pvp/MenuPvP.tscn (o jogo instalado não usa esta cena).

const T := preload("res://scripts/ui/pvp/pvp_tema.gd")
const ICONE := preload("res://scripts/ui/pvp/pvp_icone.gd")
const FUNDO := preload("res://scripts/ui/pvp/pvp_fundo.gd")
const ARENA := preload("res://scripts/pvp/pvp_arena.gd")
const CENA_ARENA := "res://scenes/pvp/ArenaPvP.tscn"
const ATUALIZADOR := preload("res://scripts/pvp/pvp_atualizador.gd")
const VITRINE := preload("res://scripts/ui/pvp/pvp_vitrine.gd")
const HEROI := preload("res://scripts/pvp/visual/heroi_visual.gd")
const MARCADOR := preload("res://scripts/pvp/visual/marcador.gd")
const RETRATOS := preload("res://scripts/pvp/visual/retratos.gd")
const PERFIL := "user://pvp_perfil.cfg"
var aviso_atualizacao: Control
var atualizador: Node

## Barra de baixo: [id da tela, ícone, rótulo]
const ABAS := [
	["inicio", "base", "Base"],
	["herois", "herois", "Heróis"],
	["arsenal", "arsenal", "Arsenal"],
	["modos", "missoes", "Missões"],
]
## Atalhos do topo, ao lado das moedas: [ícone, tela, dica]
const ATALHOS := [["moedas", "loja", "Loja"], ["escudo", "cla", "Clã"], ["chat", "chat", "Chat"], ["engrenagem", "ajustes", "Ajustes"]]
const TELAS := ["inicio", "herois", "arsenal", "modos", "inventario", "loja", "mercado", "cla", "ajustes", "chat", "carregando"]
## Atributos por função (só exibição nesta versão: o paintball ainda não diferencia heróis).
const ATRIBUTOS := {"Batedor": [0.9, 0.6, 0.45], "Assalto": [0.65, 0.75, 0.6], "Precisão": [0.5, 0.92, 0.4],
	"Suporte": [0.6, 0.5, 0.78], "Tático": [0.6, 0.66, 0.66], "Explosivos": [0.55, 0.86, 0.5], "Pesado": [0.35, 0.8, 0.92],
	"Corpo a corpo": [0.86, 0.72, 0.5], "Reconhecimento": [0.82, 0.55, 0.5], "Rastreadora": [0.86, 0.6, 0.5]}

var tela := ""
var fundo: Control
var lateral: HBoxContainer      # barra de baixo
var topo_abas: HBoxContainer
var topo_moedas: HBoxContainer
var corpo: Control
var moldura: Control      # topo e barra de baixo (somem no carregamento)
var heroi_visto := ""
var aparencia_vista := ""
var _botoes_lateral := {}
var aba_atual := {}       # tela -> índice da aba

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo = FUNDO.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	_carregar_perfil()
	_moldura()
	abrir("inicio")
	atualizador = ATUALIZADOR.new()
	add_child(atualizador)
	atualizador.nova_versao.connect(mostrar_atualizacao)
	atualizador.iniciar()

## Tela de atualização automática: progresso, integridade e instalação pelo Android.
func mostrar_atualizacao(d: Dictionary) -> void:
	if aviso_atualizacao != null:
		return
	var escuro := ColorRect.new()
	escuro.color = Color(0, 0, 0, 0.70)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(escuro)
	aviso_atualizacao = escuro
	var caixa := _painel(Color(T.PAINEL, 0.99))
	caixa.set_anchors_preset(Control.PRESET_CENTER)
	caixa.custom_minimum_size = Vector2(560, 0)
	caixa.position = Vector2(-280, -165)
	escuro.add_child(caixa)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 14)
	caixa.add_child(coluna)
	coluna.add_child(_titulo("Nova versão disponível", 30))
	var descricao := _rotulo("Valdora %s está disponível. O download começa automaticamente. Depois, confirme a instalação no Android." % str(d.get("version_name", "")), 18, T.TEXTO, 600)
	descricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	descricao.custom_minimum_size = Vector2(510, 0)
	coluna.add_child(descricao)
	var estado := _rotulo("Preparando download...", 18, T.TEXTO, 700)
	coluna.add_child(estado)
	var barra := ProgressBar.new()
	barra.custom_minimum_size = Vector2(500, 24)
	barra.min_value = 0
	barra.max_value = 100
	barra.value = 0
	coluna.add_child(barra)
	var botoes := HBoxContainer.new()
	botoes.add_theme_constant_override("separation", 12)
	coluna.add_child(botoes)
	var depois := _botao("Depois", "escuro", 18, 56)
	depois.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	depois.pressed.connect(func():
		aviso_atualizacao.queue_free()
		aviso_atualizacao = null)
	botoes.add_child(depois)
	var instalar := _botao("Instalar atualização", "laranja", 18, 56)
	instalar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	instalar.disabled = true
	botoes.add_child(instalar)
	instalar.pressed.connect(func():
		if instalar.has_meta("navegador"):
			# alternativa: baixar pelo navegador; o Android pede para instalar ao abrir o arquivo
			OS.shell_open(str(d.get("apk", "")))
			return
		var retorno: String = atualizador.solicitar_instalacao()
		if retorno == "permissao":
			estado.text = "Autorize a instalação no Android e toque novamente em Instalar."
		elif retorno != "":
			estado.text = retorno)
	atualizador.download_progresso.connect(func(pct: int):
		if is_instance_valid(barra):
			barra.value = pct
			estado.text = "Baixando atualização... %d%%" % pct if pct < 100 else "Verificando APK...")
	atualizador.download_pronto.connect(func():
		if is_instance_valid(instalar):
			instalar.disabled = false
			estado.text = "APK validado. Toque em Instalar atualização.")
	atualizador.download_erro.connect(func(mensagem: String):
		if is_instance_valid(estado):
			estado.text = mensagem + " Use o botão para baixar pelo navegador."
		if is_instance_valid(instalar):
			instalar.set_meta("navegador", true)
			instalar.text = "BAIXAR PELO NAVEGADOR"
			instalar.disabled = false)

# ---------------------------------------------------------------- estrutura

func _moldura() -> void:
	moldura = Control.new()
	moldura.set_anchors_preset(Control.PRESET_FULL_RECT)
	moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(moldura)
	# topo: título da tela (ou logo) à esquerda; moedas e atalhos à direita
	var topo := HBoxContainer.new()
	topo.anchor_right = 1.0
	topo.offset_left = 16
	topo.offset_right = -16
	topo.offset_top = 10
	topo.offset_bottom = 70
	topo.add_theme_constant_override("separation", 10)
	topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moldura.add_child(topo)
	topo_abas = HBoxContainer.new()
	topo_abas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo_abas.add_theme_constant_override("separation", 8)
	topo.add_child(topo_abas)
	topo_moedas = HBoxContainer.new()
	topo_moedas.add_theme_constant_override("separation", 8)
	topo.add_child(topo_moedas)
	topo_moedas.add_child(_moeda("V", "1 250", T.OURO))
	for at in ATALHOS:
		topo_moedas.add_child(_botao_icone(at[0], at[1], at[2]))
	# barra de baixo: as quatro áreas do jogo
	var bb := PanelContainer.new()
	var sb := T.vidro(26)
	sb.content_margin_left = 8; sb.content_margin_right = 8; sb.content_margin_top = 6; sb.content_margin_bottom = 6
	bb.add_theme_stylebox_override("panel", sb)
	bb.anchor_top = 1.0; bb.anchor_bottom = 1.0; bb.anchor_right = 1.0
	bb.offset_left = 36; bb.offset_right = -36; bb.offset_top = -84; bb.offset_bottom = -10
	moldura.add_child(bb)
	lateral = HBoxContainer.new()
	lateral.add_theme_constant_override("separation", 6)
	bb.add_child(lateral)
	for item in ABAS:
		var b := _botao_lateral(item[0], item[1], item[2])
		lateral.add_child(b)
		_botoes_lateral[item[0]] = b
	# corpo
	corpo = Control.new()
	corpo.set_anchors_preset(Control.PRESET_FULL_RECT)
	corpo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(corpo)

func _botao_icone(icone: String, destino: String, dica: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(56, 56)
	b.tooltip_text = dica
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", T.vidro(16))
	b.add_theme_stylebox_override("hover", T.vidro(16, Color(T.PAINEL_3, 0.85)))
	b.add_theme_stylebox_override("pressed", T.vidro(16, Color(T.TEAL_ESCURO, 0.9)))
	var ic = ICONE.new(icone, T.CREME, 30)
	ic.position = Vector2(13, 13)
	b.add_child(ic)
	b.pressed.connect(abrir.bind(destino))
	return b

func _logo() -> Control:
	var p := PanelContainer.new()
	var s := T.vidro(28)
	s.content_margin_left = 12; s.content_margin_right = 22; s.content_margin_top = 2; s.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", s)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	p.add_child(h)
	var v := _rotulo("V", 40, T.LARANJA, 900, true)
	v.add_theme_color_override("font_outline_color", T.LARANJA_ESCURO)
	v.add_theme_constant_override("outline_size", 6)
	h.add_child(v)
	var n := _titulo("Valdora", 34)
	n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(n)
	return p

func _cabecalho(titulo: String, volta := "inicio") -> void:
	var b := _voltar()
	b.pressed.disconnect(abrir.bind("inicio"))
	b.pressed.connect(abrir.bind(volta))
	topo_abas.add_child(b)
	var p := PanelContainer.new()
	var s := T.vidro(26)
	s.content_margin_left = 22; s.content_margin_right = 26
	p.add_theme_stylebox_override("panel", s)
	var t := _titulo(titulo, 32)
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(t)
	topo_abas.add_child(p)

# ---------------------------------------------------------------- perfil (herói e aparência escolhidos)

func _carregar_perfil() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PERFIL) == OK:
		ARENA.heroi_jogador = String(cfg.get_value("pvp", "heroi", ARENA.heroi_jogador))
		ARENA.aparencia_jogador = String(cfg.get_value("pvp", "aparencia", ARENA.aparencia_jogador))
	heroi_visto = ARENA.heroi_jogador
	aparencia_vista = ARENA.aparencia_jogador

func _salvar_perfil() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("pvp", "heroi", ARENA.heroi_jogador)
	cfg.set_value("pvp", "aparencia", ARENA.aparencia_jogador)
	cfg.save(PERFIL)

func abrir(id: String) -> void:
	tela = id
	for c in corpo.get_children():
		c.queue_free()
	for c in topo_abas.get_children():
		c.queue_free()
	var cheia := id == "carregando"
	moldura.visible = not cheia
	fundo.tom = "menu"
	fundo.queue_redraw()
	for k in _botoes_lateral:
		_marcar_lateral(_botoes_lateral[k], k == id or (k == "arsenal" and id in ["inventario", "mercado", "loja"]))
	var area := Control.new()
	area.set_anchors_preset(Control.PRESET_FULL_RECT)
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not cheia:
		area.offset_left = 16
		area.offset_top = 80
		area.offset_right = -16
		area.offset_bottom = -96
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

func _painel(cor := T.VIDRO, raio := 22, borda := 2) -> PanelContainer:
	var p := PanelContainer.new()
	var s := T.caixa(cor, raio, borda, T.BORDA_VIDRO, 6)
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
	var sn := T.caixa_botao(cores[0], cores[1], 20)
	var sh := T.caixa_botao(cores[2], cores[1], 20)
	if tipo == "laranja":
		for st in [sn, sh]:
			st.shadow_color = Color(T.LARANJA_CLARO, 0.45)
			st.shadow_size = 10
			st.shadow_offset = Vector2.ZERO
			st.border_width_top = 2
	b.add_theme_stylebox_override("normal", sn)
	b.add_theme_stylebox_override("hover", sh)
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
	b.custom_minimum_size = Vector2(0, 60)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.tooltip_text = texto
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(abrir.bind(id))
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 12)
	b.add_child(h)
	var ic = ICONE.new(icone, T.CREME, 38)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var l := _rotulo(texto.to_upper(), 24, T.CREME, 900, true)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(l)
	b.set_meta("icone", ic)
	b.set_meta("rotulo", l)
	return b

func _marcar_lateral(b: Button, ativo: bool) -> void:
	var s := StyleBoxFlat.new()
	s.set_corner_radius_all(20)
	s.anti_aliasing = true
	if ativo:
		s.bg_color = Color(T.TEAL, 0.34)
		s.set_border_width_all(3)
		s.border_color = T.TEAL_CLARO
		s.shadow_color = Color(T.TEAL_CLARO, 0.35)
		s.shadow_size = 8
	else:
		s.bg_color = Color(0, 0, 0, 0)
	b.add_theme_stylebox_override("normal", s)
	b.add_theme_stylebox_override("hover", s if ativo else T.caixa(Color(1, 1, 1, 0.06), 20))
	b.add_theme_stylebox_override("pressed", s)
	var c := Color.WHITE if ativo else T.CREME
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
	if simbolo == "V":
		var mv = ICONE.new("moeda_v", cor, 40)
		h.add_child(mv)
		var vv := _rotulo(valor, 24, T.TEXTO, 900)
		vv.custom_minimum_size = Vector2(80, 0)
		vv.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(vv)
		s.bg_color = T.VIDRO
		s.border_color = T.BORDA_VIDRO
		s.set_corner_radius_all(26)
		s.content_margin_left = 8; s.content_margin_right = 14
		return p
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
	topo_abas.add_child(_logo())
	var h = HEROI.dados(ARENA.heroi_jogador)
	# herói escolhido na vitrine, à esquerda
	var vit = VITRINE.new()
	vit.anchor_right = 0.5
	vit.anchor_bottom = 1.0
	a.add_child(vit)
	vit.mostrar_heroi(String(h.id), ARENA.aparencia_jogador)
	var pn := _painel(T.VIDRO, 22)
	pn.anchor_top = 1.0; pn.anchor_bottom = 1.0
	pn.offset_left = 8; pn.offset_top = -92; pn.offset_bottom = -6
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 0)
	pn.add_child(pv)
	pv.add_child(_titulo(String(h.nome), 32))
	pv.add_child(_rotulo("%s · %s" % [h.funcao, h.origem], 17, T.CREME, 700))
	a.add_child(pn)
	# próxima missão, à direita
	var pm := _painel(T.VIDRO, 26, 3)
	pm.anchor_left = 1.0; pm.anchor_right = 1.0
	pm.offset_left = -420; pm.offset_right = -4; pm.offset_top = 0
	a.add_child(pm)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pm.add_child(v)
	var t := _titulo("Próxima missão", 26)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	v.add_child(_miniatura_mapa(ARENA.mapa_escolhido, Vector2(0, 150)))
	var nm := _rotulo("Confronto 5 × 5", 30, T.CREME, 900)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nm)
	var trocar := _botao("Mapa: " + _nome_mapa(), "teal", 18, 50)
	trocar.pressed.connect(func():
		var l := ARENA.lista()
		var i := 0
		for k in l.size():
			if l[k].id == ARENA.mapa_escolhido:
				i = k
		ARENA.mapa_escolhido = l[(i + 1) % l.size()].id
		abrir("inicio"))
	v.add_child(trocar)
	var jogar := _botao("Jogar", "laranja", 44, 86)
	var ji = ICONE.new("jogar", Color.WHITE, 40)
	ji.position = Vector2(64, 20)
	jogar.add_child(ji)
	jogar.pressed.connect(abrir.bind("carregando"))
	v.add_child(jogar)

## Planta do mapa em miniatura, nas cores do Valdora (sem arte externa).
func _miniatura_mapa(id: String, tam: Vector2) -> Control:
	var dados := ARENA.carregar(id)
	var c := Control.new()
	c.custom_minimum_size = tam
	c.draw.connect(func():
		var g: Array = dados.get("grade", [])
		if g.is_empty():
			return
		var s := c.size
		c.draw_rect(Rect2(Vector2.ZERO, s), Color("2f6f6a"))
		var lg := String(g[0]).length()
		var e := minf(s.x / lg, s.y / g.size())
		var o := (s - Vector2(lg, g.size()) * e) * 0.5
		var cores := {"#": Color("e8dcc0"), "c": Color("c48a4e"), "A": Color("d9534a"), "B": Color("3f6fc9"), "T": T.TEAL_CLARO, "D": T.LARANJA}
		for y in g.size():
			for x in lg:
				var ch: String = String(g[y])[x]
				var cor: Color = cores.get(ch, Color("b9ab8f"))
				c.draw_rect(Rect2(o + Vector2(x, y) * e, Vector2(e, e) + Vector2(0.5, 0.5)), cor)
		c.draw_rect(Rect2(Vector2.ZERO, s), Color(1, 1, 1, 0.35), false, 3.0))
	c.resized.connect(c.queue_redraw)
	return c

# ---------------------------------------------------------------- heróis

func _tela_herois(a: Control) -> void:
	_cabecalho("Heróis")
	if heroi_visto == "":
		heroi_visto = ARENA.heroi_jogador
	var h = HEROI.dados(heroi_visto)
	# lista à esquerda (retratos renderizados uma vez)
	var lista := VBoxContainer.new()
	lista.add_theme_constant_override("separation", 8)
	var ids := []
	for d in HEROI.herois():
		ids.append(d.id)
		lista.add_child(_cartao_heroi(d))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.anchor_bottom = 1.0
	sc.offset_right = 168
	sc.add_child(lista)
	a.add_child(sc)
	RETRATOS.pedir(self, ids)
	# vitrine no centro
	var vit = VITRINE.new()
	vit.anchor_left = 0.0; vit.anchor_right = 1.0; vit.anchor_bottom = 1.0
	vit.offset_left = 170; vit.offset_right = -430
	a.add_child(vit)
	vit.mostrar_heroi(heroi_visto, ARENA.aparencia_jogador)
	# ficha à direita
	var pf := _painel(T.VIDRO, 26, 3)
	pf.anchor_left = 1.0; pf.anchor_right = 1.0; pf.anchor_bottom = 1.0
	pf.offset_left = -420; pf.offset_right = -4
	a.add_child(pf)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pf.add_child(v)
	v.add_child(_titulo(String(h.nome), 46))
	var fl := _rotulo("  %s  " % String(h.funcao).to_upper(), 18, T.CREME, 900, true)
	fl.add_theme_stylebox_override("normal", T.caixa(Color(T.TEAL, 0.35), 14, 2, T.TEAL_CLARO))
	fl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(fl)
	v.add_child(_rotulo("Origem: %s" % h.origem, 16, T.TEXTO_2, 700))
	var fr := _rotulo("“%s”" % h.frase, 17, T.CREME, 600, true)
	fr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(fr)
	var at: Array = ATRIBUTOS.get(String(h.funcao), [0.6, 0.6, 0.6])
	for i in 3:
		v.add_child(_barra(["Mobilidade", "Ataque", "Defesa"][i], at[i], T.TEAL_CLARO))
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(esp)
	var escolhido := heroi_visto == ARENA.heroi_jogador
	var sel := _botao("Selecionado" if escolhido else "Selecionar", "teal" if escolhido else "laranja", 30, 72)
	sel.pressed.connect(func():
		ARENA.heroi_jogador = heroi_visto
		_salvar_perfil()
		abrir("herois"))
	v.add_child(sel)

func _cartao_heroi(d: Dictionary) -> Control:
	var ativo: bool = d.id == heroi_visto
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(150, 128)
	p.add_theme_stylebox_override("panel", T.caixa(Color(T.PAINEL_2, 0.9), 18, 4 if ativo else 2, T.TEAL_CLARO if ativo else T.BORDA_VIDRO, 6))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var tr := TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.texture = RETRATOS.textura(d.id)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(tr)
	var faixa := _rotulo(String(d.nome).to_upper(), 18, T.CREME, 900, true)
	faixa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	faixa.size_flags_vertical = Control.SIZE_SHRINK_END
	faixa.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	faixa.add_theme_constant_override("outline_size", 6)
	p.add_child(faixa)
	if tr.texture == null:
		var g = RETRATOS.pedir(self, [d.id])
		g.pronto.connect(func(id):
			if id == d.id and is_instance_valid(tr):
				tr.texture = RETRATOS.textura(id))
	p.gui_input.connect(func(ev):
		if (ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed) or (ev is InputEventScreenTouch and not ev.pressed):
			heroi_visto = d.id
			abrir("herois"))
	return p

func _barra(nome: String, valor: float, cor: Color) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.add_child(_rotulo(nome.to_upper(), 15, T.CREME, 800))
	var b := ProgressBar.new()
	b.value = valor * 100.0
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, 14)
	b.add_theme_stylebox_override("background", T.caixa(Color(0, 0, 0, 0.35), 7))
	b.add_theme_stylebox_override("fill", T.caixa(cor, 7))
	v.add_child(b)
	return v

# ---------------------------------------------------------------- arsenal

func _tela_arsenal(a: Control) -> void:
	_cabecalho("Arsenal")
	if aparencia_vista == "":
		aparencia_vista = ARENA.aparencia_jogador
	var ap := MARCADOR.aparencia(aparencia_vista)
	# marcador no pedestal, no alto à esquerda
	var vit = VITRINE.new(T.OURO)
	vit.anchor_right = 1.0; vit.anchor_bottom = 0.62
	vit.offset_right = -430
	a.add_child(vit)
	vit.mostrar_marcador(aparencia_vista)
	# as 30 aparências embaixo, com miniatura renderizada uma vez
	var g := _grade(6, 8)
	var ids := []
	for d in MARCADOR.aparencias():
		ids.append("m:" + String(d.id))
		g.add_child(_cartao_aparencia(d))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.anchor_top = 0.62; sc.anchor_right = 1.0; sc.anchor_bottom = 1.0
	sc.offset_right = -430; sc.offset_top = 4
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(g)
	a.add_child(sc)
	RETRATOS.pedir(self, ids)
	# ficha à direita
	var pf := _painel(T.VIDRO, 26, 3)
	pf.anchor_left = 1.0; pf.anchor_right = 1.0; pf.anchor_bottom = 1.0
	pf.offset_left = -420; pf.offset_right = -4
	a.add_child(pf)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pf.add_child(v)
	var nome := _titulo(String(ap.nome), 36)
	nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(nome)
	var cor_r: Color = T.RARIDADE.get(String(ap.raridade), T.RARIDADE.comum)
	var rl := _rotulo("  %s  " % {"comum": "COMUM", "incomum": "INCOMUM", "raro": "RARO", "epico": "ÉPICO", "lendario": "LENDÁRIO"}.get(String(ap.raridade), ""), 16, Color.WHITE, 900, true)
	rl.add_theme_stylebox_override("normal", T.caixa(cor_r, 12))
	rl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(rl)
	v.add_child(_rotulo("Marcador de assalto · arma principal", 16, T.TEXTO_2, 700))
	for i in 3:
		v.add_child(_barra(["Poder", "Cadência", "Controle"][i], [0.55, 0.82, 0.7][i], T.LARANJA_CLARO))
	v.add_child(_rotulo("Tinta: %d de dano · %d por pente" % [25, 24], 15, T.TEXTO_2, 600))
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(esp)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	v.add_child(h)
	for at in [["Inventário", "inventario"], ["Mercado", "mercado"]]:
		var b := _botao(at[0], "escuro", 16, 50)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(abrir.bind(at[1]))
		h.add_child(b)
	var equipada := aparencia_vista == ARENA.aparencia_jogador
	var eq := _botao("Equipada" if equipada else "Equipar", "teal" if equipada else "laranja", 30, 72)
	eq.pressed.connect(func():
		ARENA.aparencia_jogador = aparencia_vista
		_salvar_perfil()
		abrir("arsenal"))
	v.add_child(eq)

func _cartao_aparencia(d: Dictionary) -> Control:
	var ativo: bool = d.id == aparencia_vista
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(0, 86)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cor_r: Color = T.RARIDADE.get(String(d.raridade), T.RARIDADE.comum)
	p.add_theme_stylebox_override("panel", T.caixa(Color(T.PAINEL_2, 0.9), 14, 3 if ativo else 2, T.TEAL_CLARO if ativo else Color(cor_r, 0.8)))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.tooltip_text = String(d.nome)
	var tr := TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture = RETRATOS.textura("m:" + String(d.id))
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(tr)
	if tr.texture == null:
		var g = RETRATOS.pedir(self, ["m:" + String(d.id)])
		g.pronto.connect(func(id):
			if id == "m:" + String(d.id) and is_instance_valid(tr):
				tr.texture = RETRATOS.textura(id))
	p.gui_input.connect(func(ev):
		if (ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed) or (ev is InputEventScreenTouch and not ev.pressed):
			aparencia_vista = d.id
			abrir("arsenal"))
	return p

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
	mh.add_child(_rotulo("MAPA", 15, T.TEXTO_2, 800))
	var trocar := _botao(_nome_mapa(), "escuro", 17, 52)
	trocar.custom_minimum_size.x = 220
	trocar.pressed.connect(func():
		var l := ARENA.lista()
		var i := 0
		for k in l.size():
			if l[k].id == ARENA.mapa_escolhido:
				i = k
		ARENA.mapa_escolhido = l[(i + 1) % l.size()].id
		abrir("modos"))
	mh.add_child(trocar)
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
		var video = get_node_or_null("/root/ValdoraVideo") if ativa == 1 else null
		var selecionada: String = video.valor_de(str(l[0])) if video != null else ""
		for i in opc.size():
			var ativa_opcao: bool = selecionada == str(opc[i]) if video != null else i == opc.size() - 1
			var b := _botao(opc[i], "teal" if ativa_opcao else "escuro", 16, 50)
			b.custom_minimum_size.x = 200 if opc.size() <= 2 else 150
			if video != null:
				b.pressed.connect(_selecionar_video.bind(str(l[0]), str(opc[i])))
			lh.add_child(b)
		lista.add_child(p)
	var sc := _rolagem(lista)
	sc.set_anchors_preset(Control.PRESET_TOP_LEFT)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sc)
	var bb := HBoxContainer.new()
	v.add_child(bb)
	var redefinir := _botao("Redefinir ao padrão", "escuro", 16, 50)
	if ativa == 1:
		redefinir.pressed.connect(_restaurar_video)
	bb.add_child(redefinir)
	var e := Control.new()
	e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bb.add_child(e)
	var ap := _botao("Aplicar", "laranja", 18, 50)
	ap.custom_minimum_size.x = 220
	if ativa == 1:
		ap.pressed.connect(_aplicar_video)
	bb.add_child(ap)

## Configurações reais: o usuário não precisa reiniciar para ajustar a nitidez.
func _selecionar_video(categoria: String, valor: String) -> void:
	var video = get_node_or_null("/root/ValdoraVideo")
	if video == null:
		return
	video.definir(categoria, valor)
	abrir("ajustes")

func _restaurar_video() -> void:
	var video = get_node_or_null("/root/ValdoraVideo")
	if video == null:
		return
	video.restaurar()
	abrir("ajustes")

func _aplicar_video() -> void:
	var video = get_node_or_null("/root/ValdoraVideo")
	if video == null:
		return
	video.aplicar()
	abrir("ajustes")

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
	var dl := _rotulo("   Dica: o escudo absorve a tinta antes da vida. Use as coberturas para recarregar.", 18, T.TEXTO, 600)
	dl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dica.add_child(dl)
	# planta do mapa escolhido
	var dados := ARENA.carregar(ARENA.mapa_escolhido)
	var mapa := _painel(Color(T.PAINEL_2, 0.9))
	mapa.position = Vector2(150, 90)
	mapa.size = Vector2(380, 500)
	a.add_child(mapa)
	var planta := Control.new()
	planta.custom_minimum_size = Vector2(24 * 14, 32 * 14)
	planta.draw.connect(func():
		var cores := {"#": Color(T.TEXTO_2, 0.6), "c": Color(T.TEXTO_2, 0.3), "A": Color("d9534a"), "B": Color("3f6fc9"),
			"T": Color("3f8f5a"), "D": Color("b0603a"), "1": T.OURO, "2": T.OURO, "3": T.OURO}
		var g: Array = dados.get("grade", [])
		for y in g.size():
			for x in String(g[y]).length():
				var ch: String = String(g[y])[x]
				if cores.has(ch):
					planta.draw_rect(Rect2(x * 14, y * 14, 14, 14), cores[ch]))
	var mc := CenterContainer.new()
	mapa.add_child(mc)
	mc.add_child(planta)
	var info := VBoxContainer.new()
	info.position = Vector2(620, 130)
	info.custom_minimum_size = Vector2(600, 0)
	info.add_theme_constant_override("separation", 10)
	a.add_child(info)
	info.add_child(_titulo(dados.get("nome", ""), 64))
	info.add_child(_rotulo(dados.get("cidade", ""), 22, T.TEXTO_2, 700))
	info.add_child(_rotulo("Confronto 5 × 5 · paintball", 26, T.LARANJA_CLARO, 800, true))
	var d := _rotulo("Dois times de cinco, três minutos. Cada adversário pintado vale um ponto; quem pintar mais vence.\n%s." % _maiuscula(String(dados.get("tema", ""))), 20, T.TEXTO, 600)
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
	var ir := _botao("Entrar", "laranja", 26, 64)
	ir.anchor_left = 1.0; ir.anchor_right = 1.0; ir.anchor_top = 1.0; ir.anchor_bottom = 1.0
	ir.offset_left = -300; ir.offset_right = -40; ir.offset_top = -190; ir.offset_bottom = -126
	ir.pressed.connect(func(): get_tree().change_scene_to_file(CENA_ARENA))
	var volta := _voltar()
	volta.anchor_left = 1.0; volta.anchor_right = 1.0
	volta.offset_left = -80; volta.offset_right = -24; volta.offset_top = 84; volta.offset_bottom = 136
	a.add_child(volta)
	a.add_child(ir)

func _nome_mapa() -> String:
	for m in ARENA.lista():
		if m.id == ARENA.mapa_escolhido:
			return "%s" % m.nome
	return "?"

func _maiuscula(t: String) -> String:
	return t.substr(0, 1).to_upper() + t.substr(1) if t != "" else t
