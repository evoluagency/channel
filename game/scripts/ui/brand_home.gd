extends Control
## CP006: menu principal em estilo Valdora, sem modificar saves.
signal city_requested()
signal explore_requested()
signal heroes_requested()
signal combat_requested()

var city_button: Button
var status_label: Label

func _style(background: String, edge: String) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = Color(background)
    s.border_color = Color(edge)
    s.set_border_width_all(2)
    s.set_corner_radius_all(13)
    s.content_margin_left = 18
    s.content_margin_right = 18
    s.content_margin_top = 12
    s.content_margin_bottom = 12
    return s

func _label(value: String, font_size: int, color: String) -> Label:
    var l := Label.new()
    l.text = value
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", Color(color))
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return l

func _button(value: String, method: Callable) -> Button:
    var b := Button.new()
    b.text = value
    b.custom_minimum_size = Vector2(360, 60)
    b.add_theme_font_size_override("font_size", 22)
    b.add_theme_color_override("font_color", Color("#f9dfa1"))
    b.add_theme_stylebox_override("normal", _style("#0e2d4b", "#b89a58"))
    b.add_theme_stylebox_override("hover", _style("#194b6a", "#e7bc68"))
    b.add_theme_stylebox_override("pressed", _style("#235673", "#e7bc68"))
    b.pressed.connect(method)
    return b

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    var background := ColorRect.new()
    background.color = Color("#071d36")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)
    var middle := CenterContainer.new()
    middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(middle)
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _style("#092239f5", "#bd9958"))
    panel.custom_minimum_size = Vector2(460, 0)
    middle.add_child(panel)
    var list := VBoxContainer.new()
    list.add_theme_constant_override("separation", 10)
    panel.add_child(list)
    var img := TextureRect.new()
    img.texture = load("res://assets/branding/valdora_192.png")
    img.custom_minimum_size = Vector2(110, 110)
    img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    list.add_child(img)
    list.add_child(_label("VALDORA", 46, "#f9d780"))
    list.add_child(_label("CONSTRUA  ·  GOVERNE  ·  EXPANDA", 16, "#b5d2e2"))
    list.add_child(HSeparator.new())
    city_button = _button("MINHA CIDADE", _city)
    city_button.disabled = true
    list.add_child(city_button)
    list.add_child(_button("EXPLORAÇÃO 3D", _explore))
    list.add_child(_button("HERÓIS", _heroes))
    list.add_child(_button("COMBATE", _combat))
    list.add_child(HSeparator.new())
    status_label = _label("Verificando atualizações...", 14, "#b5d2e2")
    list.add_child(status_label)
    list.add_child(_label("EVOLU CHANNEL  ·  ALPHA 0.4.1", 12, "#9db5c5"))

func _city() -> void:
    city_requested.emit()

func _explore() -> void:
    explore_requested.emit()

func _heroes() -> void:
    heroes_requested.emit()

func _combat() -> void:
    combat_requested.emit()

func set_status(value: String) -> void:
    if status_label != null:
        status_label.text = value

func set_city_available(enabled: bool) -> void:
    if city_button != null:
        city_button.disabled = not enabled
        city_button.text = "MINHA CIDADE" if enabled else "CIDADE  ·  AGUARDANDO"
