extends RefCounted
## Configuração de ações para teclado. O joystick móvel segue na cena.
static func configure() -> void:
    var mapping := {
        "channel_left": [KEY_A, KEY_LEFT],
        "channel_right": [KEY_D, KEY_RIGHT],
        "channel_forward": [KEY_W, KEY_UP],
        "channel_back": [KEY_S, KEY_DOWN],
        "channel_interact": [KEY_E]
    }
    for action in mapping.keys():
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        for key_code in mapping[action]:
            var key := InputEventKey.new()
            key.physical_keycode = key_code
            InputMap.action_add_event(action, key)
