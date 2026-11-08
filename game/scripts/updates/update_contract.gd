extends RefCounted
## CP004: contrato de atualizações remotas. Somente dados declarativos ou PCK assinado.
const ORIGIN := "https://channel.evolu.ink/updates/v2/"
const ROOT := "user://valdora_updates/"
const FILES := ROOT + "files/"
const ACTIVE := ROOT + "active.json"
const PREVIOUS := ROOT + "previous.json"
const PUBLIC_KEY := "res://updates/trust/valdora_ota.pub"
const MAX_MANIFEST := 65536
const MAX_PACKAGE := 104857600
const MAX_TOTAL := 209715200
const MAX_MODULES := 24
const CLIENT_CODE := 102
const COMMANDS := ["message", "open_heroes", "open_combat", "economy"]

static func valid_id(value: String) -> bool:
    if value.length() < 3 or value.length() > 40:
        return false
    for ch in value:
        if not "abcdefghijklmnopqrstuvwxyz0123456789_-".contains(ch):
            return false
    return true

static func valid_sha(value: String) -> bool:
    if value.length() != 64:
        return false
    for ch in value:
        if not "0123456789abcdef".contains(ch):
            return false
    return true

static func file_path(module: Dictionary) -> String:
    var suffix := ".pck" if str(module.get("kind", "")) == "pck" else ".json"
    return FILES + str(module.get("id", "")) + "-" + str(module.get("version", 0)) + suffix

static func validate_manifest(m: Dictionary) -> String:
    if m.get("schema_version") != 2 or m.get("game") != "Valdora" or m.get("channel") != "alpha":
        return "identidade do manifesto incorreta"
    if typeof(m.get("revision")) != TYPE_FLOAT and typeof(m.get("revision")) != TYPE_INT:
        return "revisão inválida"
    if int(m.get("revision", 0)) < 1:
        return "revisão deve ser positiva"
    if typeof(m.get("min_client_code")) != TYPE_FLOAT and typeof(m.get("min_client_code")) != TYPE_INT:
        return "versão mínima inválida"
    if int(m.get("min_client_code", 0)) > CLIENT_CODE:
        return "esta atualização exige um aplicativo-base mais recente"
    var modules = m.get("modules")
    if typeof(modules) != TYPE_ARRAY or modules.size() > MAX_MODULES:
        return "lista de módulos inválida"
    var seen: Dictionary = {}
    var total: int = 0
    for raw in modules:
        if typeof(raw) != TYPE_DICTIONARY:
            return "entrada de módulo inválida"
        var mod: Dictionary = raw
        var id := str(mod.get("id", ""))
        var kind := str(mod.get("kind", ""))
        var ver = mod.get("version")
        var bytes_count = mod.get("bytes")
        if not valid_id(id) or seen.has(id):
            return "identificador repetido ou inválido"
        seen[id] = true
        if kind != "data" and kind != "pck":
            return "tipo de módulo não autorizado"
        if (typeof(ver) != TYPE_INT and typeof(ver) != TYPE_FLOAT) or int(ver) < 1:
            return "versão de módulo inválida"
        if (typeof(bytes_count) != TYPE_INT and typeof(bytes_count) != TYPE_FLOAT) or int(bytes_count) < 1 or int(bytes_count) > MAX_PACKAGE:
            return "tamanho de módulo inválido"
        total += int(bytes_count)
        if total > MAX_TOTAL:
            return "orçamento de download excedido"
        var suffix := ".pck" if kind == "pck" else ".json"
        var expected := ORIGIN + "modules/" + id + "-" + str(int(ver)) + suffix
        if str(mod.get("url", "")) != expected:
            return "URL fora da origem autorizada"
        if not valid_sha(str(mod.get("sha256", "")).to_lower()):
            return "SHA-256 inválido"
        if kind == "pck":
            var entry := "res://valdora_modules/" + id + "/entry.tscn"
            if str(mod.get("entry", "")) != entry:
                return "cena fora do namespace do módulo"
            var sig := str(mod.get("signature_b64", ""))
            if sig.length() < 300 or Marshalls.base64_to_raw(sig).size() < 256:
                return "assinatura digital ausente"
    return ""

static func validate_data(data: Dictionary, id: String) -> bool:
    if data.get("schema_version") != 1 or data.get("module_id") != id:
        return false
    if typeof(data.get("title")) != TYPE_STRING or str(data.get("title")).length() > 70:
        return false
    var actions = data.get("actions")
    if typeof(actions) != TYPE_ARRAY or actions.size() > 12:
        return false
    for item in actions:
        if typeof(item) != TYPE_DICTIONARY:
            return false
        if not valid_id(str(item.get("id", ""))):
            return false
        if typeof(item.get("label")) != TYPE_STRING or str(item.get("label")).length() > 60:
            return false
        if not COMMANDS.has(str(item.get("command", ""))):
            return false
        if str(item.get("command", "")) == "message":
            if typeof(item.get("text")) != TYPE_STRING or str(item.get("text")).length() > 500:
                return false
    return true

static func file_digest(path: String) -> PackedByteArray:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return PackedByteArray()
    var hash := HashingContext.new()
    if hash.start(HashingContext.HASH_SHA256) != OK:
        file.close()
        return PackedByteArray()
    while file.get_position() < file.get_length():
        var part := file.get_buffer(65536)
        if part.is_empty() or hash.update(part) != OK:
            file.close()
            return PackedByteArray()
    file.close()
    return hash.finish()

static func verify_file(mod: Dictionary, path: String) -> bool:
    if not FileAccess.file_exists(path):
        return false
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        return false
    var size := f.get_length()
    f.close()
    if size != int(mod.get("bytes", -1)) or size > MAX_PACKAGE:
        return false
    var digest := file_digest(path)
    if digest.is_empty() or digest.hex_encode() != str(mod.get("sha256", "")).to_lower():
        return false
    if str(mod.get("kind", "")) == "pck":
        if not FileAccess.file_exists(PUBLIC_KEY):
            return false # fail closed; publisher must provision and protect signing key.
        var key := CryptoKey.new()
        if key.load(PUBLIC_KEY, true) != OK or not key.is_public_only():
            return false
        var signature := Marshalls.base64_to_raw(str(mod.get("signature_b64", "")))
        return Crypto.new().verify(HashingContext.HASH_SHA256, digest, signature, key)
    return true

static func read_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var raw := FileAccess.get_file_as_string(path)
    if raw.length() > MAX_MANIFEST * 2:
        return {}
    var parsed = JSON.parse_string(raw)
    return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

static func valid_state(state: Dictionary) -> bool:
    if state.is_empty() or not validate_manifest(state).is_empty():
        return false
    for item in state["modules"]:
        var mod: Dictionary = item
        if not verify_file(mod, file_path(mod)):
            return false
        if str(mod["kind"]) == "data":
            var parsed := read_json(file_path(mod))
            if not validate_data(parsed, str(mod["id"])):
                return false
    return true

static func ensure_dirs() -> bool:
    return DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FILES)) == OK

static func write_json_atomic(path: String, value: Dictionary) -> bool:
    var temporary := path + ".tmp"
    var file := FileAccess.open(temporary, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(value))
    file.flush()
    file.close()
    return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)) == OK
