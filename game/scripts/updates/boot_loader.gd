extends Node
## Autoload PRIMEIRO no projeto: monta somente packs com hash e assinatura válidos,
## antes de qualquer preload de cenas dinâmicas. Nunca substitui arquivos do jogo-base.
const CONTRACT = preload("res://scripts/updates/update_contract.gd")
var loaded: Dictionary = {}
var load_errors: Array[String] = []

func _init() -> void:
    var state := CONTRACT.read_json(CONTRACT.ACTIVE)
    if not CONTRACT.valid_state(state):
        state = CONTRACT.read_json(CONTRACT.PREVIOUS)
    if not CONTRACT.valid_state(state):
        return
    for module in state.get("modules", []):
        if str(module.get("kind", "")) != "pck" and str(module.get("kind", "")) != "zip":
            continue
        var id := str(module["id"])
        var path := CONTRACT.file_path(module)
        if not CONTRACT.verify_file(module, path):
            load_errors.append(id + ": assinatura ou integridade inválida")
            continue
        if not ProjectSettings.load_resource_pack(ProjectSettings.globalize_path(path), false):
            load_errors.append(id + ": não foi possível carregar pacote")
            continue
        loaded[id] = str(module["entry"])

func is_loaded(id: String) -> bool:
    return loaded.has(id)

func get_entry(id: String) -> String:
    return str(loaded.get(id, ""))
