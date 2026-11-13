extends RefCounted
## Tema visual do núcleo: direção visual v1 (docs/DIRECAO_VISUAL.md).
## Arquivo novo, ainda NÃO usado por nenhuma tela. Será aplicado junto com o CP013 (APK novo).
## O módulo Cidade tem uma cópia própria das constantes porque não pode depender do núcleo.
class_name ValdoraTema

const NOITE := Color("#0a0f22")
const NOITE_2 := Color("#10183a")
const NOITE_3 := Color("#19234d")
const VIOLETA := Color("#6a3fd4")
const VIOLETA_CLARO := Color("#8b5cf0")
const VIOLETA_ESCURO := Color("#3a1f87")
const VIOLETA_LUZ := Color("#b892ff")
const OURO := Color("#e2b865")
const OURO_CLARO := Color("#f5dc9c")
const OURO_ESCURO := Color("#9c7a3a")
const PEDRA := Color("#ece6da")
const TEXTO := Color("#e4e1ee")
const TEXTO_2 := Color("#a9a7c2")
const CAMPO := Color("#2f9e4f")
const ALERTA := Color("#f0a33c")
const ERRO := Color("#e35d6a")
const FORCAS := {
    "ferro": Color("#a7b1c2"),
    "nevoa": Color("#7cc3d1"),
    "aurora": Color("#f2a7c8"),
    "brasa": Color("#ff8a4c"),
}

# Camadas (CanvasLayer.layer): mundo na 0; HUD 1; painéis 2; avisos e confirmações 3.
const CAMADA_HUD := 1
const CAMADA_PAINEIS := 2
const CAMADA_AVISOS := 3

const BARRA_ALTURA := 60
const ALVO_MIN := 48
const ALVO_PRINCIPAL := 56
const RAIO_PAINEL := 18
const RAIO_BOTAO := 10
const ESCURECER_MUNDO := 0.72 # opacidade de NOITE sobre o mundo com painel aberto

# Letra a 1280x720.
const FONTE_TITULO_MIN := 28
const FONTE_TITULO_MAX := 40
const FONTE_CORPO := 16
const FONTE_MIN := 14

const FONTE_TITULO_PATH := "res://fonts/Cinzel.ttf"
const FONTE_CORPO_PATH := "res://fonts/Montserrat.ttf"

static func painel(foco := false) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = Color(NOITE_2, 0.94)
    s.border_color = OURO if foco else Color(VIOLETA_LUZ, 0.24)
    s.set_border_width_all(2 if foco else 1)
    s.set_corner_radius_all(RAIO_PAINEL)
    s.set_content_margin_all(20)
    return s

static func botao_principal() -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = VIOLETA
    s.border_color = OURO
    s.set_border_width_all(2)
    s.set_corner_radius_all(12)
    s.content_margin_left = 32
    s.content_margin_right = 32
    return s

static func botao_secundario(ativo := false) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = NOITE_3 if ativo else NOITE_2
    s.border_color = OURO if ativo else Color(OURO, 0.35)
    s.set_border_width_all(2 if ativo else 1)
    s.set_corner_radius_all(RAIO_BOTAO)
    s.content_margin_left = 14
    s.content_margin_right = 14
    return s

static func cor_forca(forca: String) -> Color:
    return FORCAS.get(forca, TEXTO_2)
