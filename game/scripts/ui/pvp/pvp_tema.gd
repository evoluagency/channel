extends RefCounted
## Tema dos menus do Valdora PvP (sessão 1.6, 15/11/2026).
## Estrutura de menus inspirada em jogos de tiro competitivo (barra lateral, abas no topo,
## moedas à direita); acabamento de jogo de estratégia mobile: painéis azul-noite arredondados,
## verde-azulado de destaque, botão principal laranja em relevo e texto creme.
## Identidade própria do Valdora: nada de nomes, ícones ou artes de outros jogos.

const NOITE := Color("#13202f")
const PAINEL := Color("#1c2c40")
const PAINEL_2 := Color("#24384f")
const PAINEL_3 := Color("#2e4762")
const BORDA := Color("#3d5a78")
const TEAL := Color("#22b3ad")
const TEAL_CLARO := Color("#5fe0d8")
const TEAL_ESCURO := Color("#147a7b")
const LARANJA := Color("#f7891f")
const LARANJA_CLARO := Color("#ffae4a")
const LARANJA_ESCURO := Color("#b8520d")
const CREME := Color("#f4e9d4")
const TEXTO := Color("#eef3f7")
const TEXTO_2 := Color("#9fb3c6")
const OURO := Color("#e9b13c")
const VERDE := Color("#3fbf5f")
const VERMELHO := Color("#e2534a")
## Sessão 1.8: painéis de vidro navy translúcido com borda clara, como na arte conceitual.
const VIDRO := Color(0.075, 0.125, 0.21, 0.8)
const BORDA_VIDRO := Color(1, 1, 1, 0.26)

## Raridade dos itens (faixa de baixo dos cartões).
const RARIDADE := {
	"comum": Color("#7b8a9c"),
	"incomum": Color("#2a9fc4"),
	"raro": Color("#3b67d6"),
	"epico": Color("#8b47d9"),
	"lendario": Color("#e8981c"),
}

const RAIO := 16
const RAIO_BOTAO := 14
const ALVO_MIN := 48

static var _fontes := {}

## Montserrat com peso e inclinação (títulos em itálico grosso, como na arte).
static func fonte(peso := 700, italico := false) -> Font:
	var chave := "%d|%s" % [peso, italico]
	if _fontes.has(chave):
		return _fontes[chave]
	var fv := FontVariation.new()
	fv.base_font = load("res://assets/fontes/Montserrat.ttf")
	var ts := TextServerManager.get_primary_interface()
	fv.variation_opentype = {ts.name_to_tag("weight"): peso}
	if italico:
		fv.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.18, 1), Vector2.ZERO)
	_fontes[chave] = fv
	return fv

static func caixa(cor: Color, raio := RAIO, borda := 0, cor_borda := BORDA, sombra := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = cor
	s.set_corner_radius_all(raio)
	if borda > 0:
		s.set_border_width_all(borda)
		s.border_color = cor_borda
	if sombra > 0:
		s.shadow_size = sombra
		s.shadow_color = Color(0, 0, 0, 0.35)
		s.shadow_offset = Vector2(0, 3)
	s.anti_aliasing = true
	return s

## Botão em relevo: cor de cima, borda grossa embaixo mais escura.
static func caixa_botao(cor: Color, escura: Color, raio := RAIO_BOTAO, apertado := false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = cor
	s.set_corner_radius_all(raio)
	s.border_color = escura
	s.border_width_bottom = 2 if apertado else 6
	s.border_width_top = 4 if apertado else 0
	s.border_blend = false
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 6
	s.content_margin_bottom = 8
	s.shadow_size = 0 if apertado else 4
	s.shadow_color = Color(0, 0, 0, 0.3)
	s.shadow_offset = Vector2(0, 3)
	s.anti_aliasing = true
	return s

## Painel de vidro navy com borda clara e cantos grandes (arte conceitual).
static func vidro(raio := 22, cor := VIDRO) -> StyleBoxFlat:
	var s := caixa(cor, raio, 2, BORDA_VIDRO)
	s.shadow_size = 6
	s.shadow_color = Color(0, 0, 0, 0.25)
	s.shadow_offset = Vector2(0, 3)
	return s
