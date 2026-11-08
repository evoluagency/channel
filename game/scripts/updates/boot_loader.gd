extends Node
## CP006: assinatura e namespace obrigatórios para pacotes ZIP ativados ao vivo.
const CONTRACT = preload("res://scripts/updates/update_contract.gd")
var loaded: Dictionary = {}
var hashes: Dictionary = {}
var load_errors: Array[String] = []

func _init() -> void:
    var state := CONTRACT.read_json(CONTRACT.ACTIVE)
    if not CONTRACT.valid_state(state):
        state = CONTRACT.read_json(CONTRACT.PREVIOUS)
    if not CONTRACT.valid_state(state):
        return
    for module in state.get("modules", []):
        if str(module.get("kind", "")) not in ["zip", "pck"]:
            continue
        if not mount_verified(module, CONTRACT.file_path(module)):
            load_errors.append(str(module.get("id", "?")) + ": pacote rejeitado")

func _zip_namespace_ok(path: String, id: String, entry: String) -> bool:
    var reader := ZIPReader.new()
    if reader.open(ProjectSettings.globalize_path(path)) != OK:
        return false
    var files := reader.get_files()
    var prefix := "valdora_modules/" + id + "/"
    var expected := entry.trim_prefix("res://")
    var found := false
    var valid := not files.is_empty() and files.size() <= 600
    var visited := {}
    for raw in files:
        var filename := str(raw).trim_prefix("res://")
        if not filename.begins_with(prefix) or filename.contains("..") or filename.contains("\\") or filename.begins_with("/"):
            valid = false
            break
        if filename.ends_with("/"):
            continue
        if visited.has(filename):
            valid = false
            break
        visited[filename] = true
        if filename.get_extension().to_lower() not in ["tscn", "gd", "tres", "png", "jpg", "webp", "ogg", "wav", "glb", "res", "json", "svg"]:
            valid = false
            break
        if filename == expected:
            found = true
    reader.close()
    return valid and found

func mount_verified(module: Dictionary, path: String) -> bool:
    var id := str(module.get("id", ""))
    var kind := str(module.get("kind", ""))
    var digest := str(module.get("sha256", ""))
    if kind not in ["zip", "pck"] or not CONTRACT.verify_file(module, path):
        return false
    if loaded.has(id) and hashes.get(id, "") == digest:
        return true
    var replace_existing := loaded.has(id)
    if kind == "zip" and not _zip_namespace_ok(path, id, str(module.get("entry", ""))):
        return false
    # Sem parser de PCK para inspecionar caminhos, não substituir PCK existente ao vivo.
    if kind == "pck" and replace_existing:
        return false
    if not ProjectSettings.load_resource_pack(ProjectSettings.globalize_path(path), replace_existing):
        return false
    loaded[id] = str(module.get("entry", ""))
    hashes[id] = digest
    return true

func is_loaded(id: String) -> bool:
    return loaded.has(id)

func get_entry(id: String) -> String:
    return str(loaded.get(id, ""))
