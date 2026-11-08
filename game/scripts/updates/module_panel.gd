extends PanelContainer
## Painel genérico para comandos declarativos. Nunca avalia código de JSON.
signal command_requested(action: Dictionary)
signal close_requested()

var saved_actions: Array[Dictionary] = []
var button_list: VBoxContainer
var status_label: Label

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    custom_minimum_size = Vector2(580, 450)
    size = custom_minimum_size
    position = Vector2(350, 135)
    var outer := MarginContainer.new()
    outer.add_theme_constant_override("margin_left", 20)
    outer.add_theme_constant_override("margin_right", 20)
    outer.add_theme_constant_override("margin_top", 16)
    outer.add_theme_constant_override("margin_bottom", 16)
    add_child(outer)
    var vertical := VBoxContainer.new()
    outer.add_child(vertical)
    var header := HBoxContainer.new()
    vertical.add_child(header)
    var heading := Label.new()
    heading.text = "MÓDULOS · VALDORA"
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    heading.add_theme_font_size_override("font_size", 23)
    header.add_child(heading)
    var close := Button.new()
    close.text = "FECHAR"
    close.pressed.connect(func(): close_requested.emit())
    header.add_child(close)
    status_label = Label.new()
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    vertical.add_child(status_label)
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(510, 360)
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vertical.add_child(scroll)
    button_list = VBoxContainer.new()
    button_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(button_list)
    _rebuild()

func set_actions(next_actions: Array[Dictionary]) -> void:
    saved_actions = next_actions.duplicate(true)
    if button_list != null:
        _rebuild()

func _rebuild() -> void:
    for child in button_list.get_children():
        button_list.remove_child(child)
        child.queue_free()
    if saved_actions.is_empty():
        status_label.text = "Nenhum módulo adicional instalado. Toque em ATUALIZAR para consultar novos conteúdos."
        return
    status_label.text = "%d comando(s) adicional(is) disponíveis." % saved_actions.size()
    for action in saved_actions:
        var button := Button.new()
        button.text = str(action.get("label", "Comando"))
        button.custom_minimum_size = Vector2(490, 48)
        button.pressed.connect(Callable(self, "_select_action").bind(action.duplicate(true)))
        button_list.add_child(button)

func _select_action(action: Dictionary) -> void:
    command_requested.emit(action)
