extends Control
## Fundo dos menus: a praça do Valdora em 3D (arte conceitual do dono), renderizada num
## SubViewport atrás da interface, com vinheta suave para os textos continuarem legíveis.
## A praça é montada por código (scripts/pvp/visual/praca_valdora.gd), sem imagem externa.

const PRACA := preload("res://scripts/pvp/visual/praca_valdora.gd")

var tom := "menu"   # menu | partida (mantido por compatibilidade com o menu)
var praca: Node3D
var _vp: SubViewport

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var caixa := SubViewportContainer.new()
	caixa.name = "Praca3D"
	caixa.stretch = true
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(caixa)
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.msaa_3d = Viewport.MSAA_2X
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var video = get_node_or_null("/root/ValdoraVideo")
	if video != null:
		_vp.scaling_3d_scale = float(video.escala_3d)
		if str(video.qualidade) == "Baixa":
			_vp.msaa_3d = Viewport.MSAA_DISABLED
	caixa.add_child(_vp)
	praca = PRACA.new()
	praca.name = "PracaValdora"
	_vp.add_child(praca)
	if video != null and not video.sombras:
		for n in praca.get_children():
			if n is DirectionalLight3D:
				n.shadow_enabled = false
	# vinheta: escurece de leve as bordas de cima e de baixo, onde ficam as barras
	var vinheta := TextureRect.new()
	vinheta.name = "Vinheta"
	vinheta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vinheta.set_anchors_preset(Control.PRESET_FULL_RECT)
	vinheta.stretch_mode = TextureRect.STRETCH_SCALE
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.16, 0.62, 1.0])
	g.colors = PackedColorArray([Color(0.04, 0.08, 0.13, 0.42), Color(0.04, 0.08, 0.13, 0.0), Color(0.04, 0.08, 0.13, 0.0), Color(0.04, 0.08, 0.13, 0.5)])
	var tx := GradientTexture2D.new()
	tx.gradient = g
	tx.fill_from = Vector2(0, 0)
	tx.fill_to = Vector2(0, 1)
	tx.width = 4
	tx.height = 128
	vinheta.texture = tx
	add_child(vinheta)

## Pausa a praça quando o fundo não está visível (economiza bateria na partida).
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and _vp != null:
		_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if is_visible_in_tree() else SubViewport.UPDATE_DISABLED
		if praca != null:
			praca.process_mode = Node.PROCESS_MODE_INHERIT if is_visible_in_tree() else Node.PROCESS_MODE_DISABLED
