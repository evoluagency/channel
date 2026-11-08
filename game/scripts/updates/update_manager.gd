extends Node
## CP004: atualização HTTP sequencial, cache offline e ativação transacional.
## Nunca baixa APK, executa GDScript remoto cru ou desinstala conteúdo.
signal status_changed(message: String)
signal modules_changed()
signal download_progress(done: int, total: int)

const CONTRACT = preload("res://scripts/updates/update_contract.gd")
const MANIFEST := CONTRACT.ORIGIN + "manifest.json"
var request_node: HTTPRequest
var phase := "idle"
var state: Dictionary = {}
var pending: Dictionary = {}
var index := 0
var staging_path := ""
var actions: Array[Dictionary] = []

func _ready() -> void:
    if not CONTRACT.ensure_dirs():
        status_changed.emit("Sem armazenamento disponível para atualizações.")
        return
    state = CONTRACT.read_json(CONTRACT.ACTIVE)
    if not CONTRACT.valid_state(state):
        state = CONTRACT.read_json(CONTRACT.PREVIOUS)
    if not CONTRACT.valid_state(state):
        state = {}
    _load_actions()
    request_node = HTTPRequest.new()
    request_node.max_redirects = 0
    request_node.accept_gzip = false
    request_node.use_threads = true
    request_node.timeout = 20.0
    add_child(request_node)
    request_node.request_completed.connect(_completed)
    call_deferred("check_for_updates")

func is_busy() -> bool:
    return phase != "idle"

func get_actions() -> Array[Dictionary]:
    return actions.duplicate(true)

func get_revision() -> int:
    return int(state.get("revision", 0))

func check_for_updates() -> void:
    if request_node == null or is_busy():
        return
    phase = "manifest"
    request_node.download_file = ""
    request_node.body_size_limit = CONTRACT.MAX_MANIFEST
    request_node.timeout = 15.0
    var err := request_node.request(MANIFEST, PackedStringArray(["Accept: application/json", "Cache-Control: no-cache"]))
    if err != OK:
        _finish("Valdora continua disponível offline.")

func _completed(result: int, status: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if phase == "manifest":
        _manifest_finished(result, status, body)
    elif phase == "file":
        _file_finished(result, status)
    else:
        _finish("Resposta de atualização fora de sequência.")

func _manifest_finished(result: int, status: int, body: PackedByteArray) -> void:
    if result != HTTPRequest.RESULT_SUCCESS or status != 200:
        # v2 ainda não publicado (404) ou aparelho offline: não bloquear o jogo.
        _finish("Conteúdo local disponível; catálogo remoto indisponível.")
        return
    if body.is_empty() or body.size() > CONTRACT.MAX_MANIFEST:
        _finish("Manifesto de atualização excedeu o limite.")
        return
    var parsed = JSON.parse_string(body.get_string_from_utf8())
    if typeof(parsed) != TYPE_DICTIONARY:
        _finish("Manifesto de atualização inválido.")
        return
    var m: Dictionary = parsed
    var problem: String = CONTRACT.validate_manifest(m)
    if not problem.is_empty():
        _finish("Atualização rejeitada: " + problem)
        return
    if int(m["revision"]) <= get_revision():
        _finish("Valdora atualizado: conteúdo v%d." % get_revision())
        return
    # Impede regressão silenciosa de um módulo mesmo com revisão global maior.
    for next_mod in m["modules"]:
        for active_mod in state.get("modules", []):
            if str(next_mod["id"]) == str(active_mod["id"]) and int(next_mod["version"]) < int(active_mod["version"]):
                _finish("Atualização rejeitada: versão anterior de módulo.")
                return
    pending = m
    index = 0
    _next_file()

func _next_file() -> void:
    var modules: Array = pending["modules"]
    while index < modules.size():
        var mod: Dictionary = modules[index]
        var target := CONTRACT.file_path(mod)
        if CONTRACT.verify_file(mod, target):
            index += 1
            continue
        staging_path = target + ".part"
        if FileAccess.file_exists(staging_path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(staging_path))
        request_node.download_file = staging_path
        request_node.body_size_limit = int(mod["bytes"]) + 1
        request_node.timeout = 90.0
        phase = "file"
        download_progress.emit(index, modules.size())
        var err := request_node.request(str(mod["url"]), PackedStringArray(["Accept-Encoding: identity"]))
        if err != OK:
            _finish("Download indisponível; módulos anteriores preservados.")
        return
    _activate()

func _file_finished(result: int, status: int) -> void:
    if result != HTTPRequest.RESULT_SUCCESS or status != 200:
        _remove_staging()
        _finish("Download interrompido; nenhum módulo novo foi ativado.")
        return
    var mod: Dictionary = pending["modules"][index]
    if not CONTRACT.verify_file(mod, staging_path):
        _remove_staging()
        _finish("Módulo rejeitado: integridade ou assinatura inválida.")
        return
    if str(mod["kind"]) == "data":
        var data := CONTRACT.read_json(staging_path)
        if not CONTRACT.validate_data(data, str(mod["id"])):
            _remove_staging()
            _finish("Módulo rejeitado: comandos fora do contrato.")
            return
    var target := CONTRACT.file_path(mod)
    if DirAccess.rename_absolute(ProjectSettings.globalize_path(staging_path), ProjectSettings.globalize_path(target)) != OK:
        _remove_staging()
        _finish("Falha de gravação; versão anterior preservada.")
        return
    staging_path = ""
    index += 1
    _next_file()

func _activate() -> void:
    if not CONTRACT.valid_state(pending):
        _finish("Falha na validação final; versão anterior preservada.")
        return
    if not state.is_empty():
        if not CONTRACT.write_json_atomic(CONTRACT.PREVIOUS, state):
            _finish("Não foi possível criar ponto de recuperação.")
            return
    if not CONTRACT.write_json_atomic(CONTRACT.ACTIVE, pending):
        _finish("Não foi possível ativar a atualização.")
        return
    state = pending.duplicate(true)
    pending = {}
    _load_actions()
    _cleanup_old_files()
    var needs_restart := false
    for mod in state["modules"]:
        if str(mod["kind"]) == "pck" and not ValdoraPacks.is_loaded(str(mod["id"])):
            needs_restart = true
    if needs_restart:
        _finish("Atualização instalada. Reinicie o Valdora para ativar novas cenas.")
    else:
        _finish("Atualização instalada e comandos disponíveis no jogo.")

func _load_actions() -> void:
    actions.clear()
    if state.is_empty():
        modules_changed.emit()
        return
    for mod in state.get("modules", []):
        var id := str(mod["id"])
        if str(mod["kind"]) == "data":
            var data := CONTRACT.read_json(CONTRACT.file_path(mod))
            if not CONTRACT.validate_data(data, id):
                continue
            for source in data["actions"]:
                var action: Dictionary = source.duplicate(true)
                action["module_id"] = id
                action["module_title"] = str(data["title"])
                actions.append(action)
        elif str(mod["kind"]) == "pck" and ValdoraPacks.is_loaded(id):
            actions.append({"id": id, "label": str(mod.get("label", id)), "command": "open_scene", "module_id": id, "scene_path": str(mod["entry"]), "module_title": "Expansão Valdora"})
    modules_changed.emit()

func _cleanup_old_files() -> void:
    # Conserva somente os dois estados recuperáveis; limpa versões obsoletas.
    var keep: Dictionary = {}
    for data in [CONTRACT.read_json(CONTRACT.ACTIVE), CONTRACT.read_json(CONTRACT.PREVIOUS)]:
        if not CONTRACT.valid_state(data):
            continue
        for mod in data.get("modules", []):
            keep[CONTRACT.file_path(mod).get_file()] = true
    var folder := DirAccess.open(CONTRACT.FILES)
    if folder == null:
        return
    for name in folder.get_files():
        if keep.has(name):
            continue
        # Não remove outros arquivos de usuário que não sejam pacotes do nosso protocolo.
        if name.ends_with(".part") or name.ends_with(".pck") or name.ends_with(".json"):
            var stem := name.get_basename()
            var cut := stem.rfind("-")
            if cut > 0 and CONTRACT.valid_id(stem.substr(0, cut)) and stem.substr(cut + 1).is_valid_int():
                DirAccess.remove_absolute(ProjectSettings.globalize_path(CONTRACT.FILES + name))

func _remove_staging() -> void:
    if not staging_path.is_empty() and FileAccess.file_exists(staging_path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(staging_path))
    staging_path = ""

func _finish(message: String) -> void:
    phase = "idle"
    request_node.download_file = ""
    pending = {}
    _remove_staging()
    status_changed.emit(message)
