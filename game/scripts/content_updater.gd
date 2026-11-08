extends Node
## Valdora Alpha 0.2 — atualizador de conteúdo exclusivamente declarativo.
## Nenhum script, APK, executável ou pacote PCK é baixado nesta fase.
## HTTPS obrigatório; somente um domínio e caminho fixos; SHA-256 conferido.

signal status_changed(message: String)
signal content_changed(payload: Dictionary)

const MANIFEST_URL := "https://channel.evolu.ink/updates/manifest.json"
const CONTENT_PREFIX := "https://channel.evolu.ink/updates/content/"
const CLIENT_VERSION := "0.2.0"
const STATE_PATH := "user://valdora_content_state.json"
const MAX_MANIFEST_BYTES := 32768
const MAX_CONTENT_BYTES := 262144
const ALLOWED_KEYS := ["welcome", "merchant", "bank", "blacksmith", "guard"]

var installed_version: int = 0
var current_texts: Dictionary = {}
var pending_manifest: Dictionary = {}
var pending_hash: String = ""
var checking: bool = false
var manifest_http: HTTPRequest
var content_http: HTTPRequest

func _ready() -> void:
    manifest_http = HTTPRequest.new()
    manifest_http.timeout = 12.0
    manifest_http.max_redirects = 0
    manifest_http.body_size_limit = MAX_MANIFEST_BYTES
    add_child(manifest_http)
    manifest_http.request_completed.connect(_on_manifest_completed)

    content_http = HTTPRequest.new()
    content_http.timeout = 20.0
    content_http.max_redirects = 0
    content_http.body_size_limit = MAX_CONTENT_BYTES
    add_child(content_http)
    content_http.request_completed.connect(_on_content_completed)
    _load_cached_content()

func check_for_updates() -> void:
    if checking:
        status_changed.emit("Verificação já em andamento")
        return
    checking = true
    var error := manifest_http.request(MANIFEST_URL, PackedStringArray(["Accept: application/json", "Cache-Control: no-cache"]))
    if error != OK:
        _finish("Sem conexão com o serviço de atualizações; jogo offline disponível")

func text_for(key: String, fallback: String) -> String:
    if current_texts.has(key):
        return str(current_texts[key])
    return fallback

func _finish(message: String) -> void:
    checking = false
    status_changed.emit(message)

func _on_manifest_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
        _finish("Sem acesso às atualizações; conteúdo local preservado")
        return
    if body.size() == 0 or body.size() > MAX_MANIFEST_BYTES:
        _finish("Manifesto de atualização inválido")
        return
    var parsed = JSON.parse_string(body.get_string_from_utf8())
    if typeof(parsed) != TYPE_DICTIONARY:
        _finish("Manifesto não é um objeto JSON")
        return
    var manifest: Dictionary = parsed
    if manifest.get("schema_version") != 1 or manifest.get("game") != "Valdora" or manifest.get("channel") != "alpha":
        _finish("Manifesto não pertence a Valdora Alpha")
        return
    if str(manifest.get("required_client_version", "")) != CLIENT_VERSION:
        _finish("Há uma versão nova do aplicativo; atualização APK necessária")
        return
    var latest := int(manifest.get("content_version", -1))
    if latest < 0:
        _finish("Número de versão do conteúdo inválido")
        return
    if latest <= installed_version:
        _finish("Valdora: conteúdo atualizado (v%d)" % installed_version)
        return
    var content = manifest.get("content", null)
    if typeof(content) != TYPE_DICTIONARY:
        _finish("Conteúdo do manifesto inválido")
        return
    var url := str(content.get("url", ""))
    var hash_hex := str(content.get("sha256", "")).to_lower()
    if not url.begins_with(CONTENT_PREFIX) or not url.ends_with(".json") or url.contains("..") or url.contains("\\") or url.contains("?") or url.contains("#"):
        _finish("Origem do conteúdo não autorizada")
        return
    if not _is_sha256(hash_hex):
        _finish("Assinatura de integridade ausente")
        return
    pending_manifest = manifest
    pending_hash = hash_hex
    var error := content_http.request(url, PackedStringArray(["Accept: application/json"]))
    if error != OK:
        _finish("Download não iniciado; conteúdo local preservado")

func _on_content_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
        _finish("Falha no download; conteúdo local preservado")
        return
    if body.size() == 0 or body.size() > MAX_CONTENT_BYTES or _sha256(body) != pending_hash:
        _finish("Arquivo não passou na verificação SHA-256")
        return
    var data = JSON.parse_string(body.get_string_from_utf8())
    if typeof(data) != TYPE_DICTIONARY:
        _finish("Pacote de conteúdo inválido")
        return
    var target_version := int(pending_manifest.get("content_version", -1))
    var payload: Dictionary = data
    if not _valid_payload(payload, target_version):
        _finish("Dados fora do contrato de conteúdo")
        return
    var path := _version_path(target_version)
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        _finish("Sem permissão de gravação local; progresso preservado")
        return
    file.store_buffer(body)
    file.close()
    if _sha256(FileAccess.get_file_as_bytes(path)) != pending_hash:
        _finish("Falha ao conferir arquivo salvo")
        return
    var state_file := FileAccess.open(STATE_PATH, FileAccess.WRITE)
    if state_file == null:
        _finish("Falha ao salvar versão do conteúdo")
        return
    state_file.store_string(JSON.stringify({"version": target_version, "sha256": pending_hash}))
    state_file.close()
    installed_version = target_version
    current_texts = payload["strings"]
    content_changed.emit(payload)
    _finish("Valdora: conteúdo v%d instalado automaticamente" % target_version)

func _load_cached_content() -> void:
    if not FileAccess.file_exists(STATE_PATH):
        return
    var state = JSON.parse_string(FileAccess.get_file_as_string(STATE_PATH))
    if typeof(state) != TYPE_DICTIONARY:
        return
    var version := int(state.get("version", -1))
    var expected_hash := str(state.get("sha256", "")).to_lower()
    if version < 1 or not _is_sha256(expected_hash):
        return
    var path := _version_path(version)
    if not FileAccess.file_exists(path):
        return
    var body := FileAccess.get_file_as_bytes(path)
    if body.is_empty() or body.size() > MAX_CONTENT_BYTES or _sha256(body) != expected_hash:
        return
    var data = JSON.parse_string(body.get_string_from_utf8())
    if typeof(data) != TYPE_DICTIONARY:
        return
    var payload: Dictionary = data
    if _valid_payload(payload, version):
        installed_version = version
        current_texts = payload["strings"]

func _valid_payload(payload: Dictionary, expected_version: int) -> bool:
    if payload.get("schema_version") != 1 or payload.get("content_version") != expected_version:
        return false
    var texts = payload.get("strings", null)
    if typeof(texts) != TYPE_DICTIONARY:
        return false
    for key in texts.keys():
        if not ALLOWED_KEYS.has(str(key)) or typeof(texts[key]) != TYPE_STRING or str(texts[key]).length() > 300:
            return false
    return true

func _version_path(version: int) -> String:
    return "user://valdora_content_v%d.json" % version

func _is_sha256(value: String) -> bool:
    if value.length() != 64:
        return false
    for letter in value:
        if not "0123456789abcdef".contains(letter):
            return false
    return true

func _sha256(bytes: PackedByteArray) -> String:
    var context := HashingContext.new()
    if context.start(HashingContext.HASH_SHA256) != OK:
        return ""
    if context.update(bytes) != OK:
        return ""
    return context.finish().hex_encode()