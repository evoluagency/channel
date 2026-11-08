extends SceneTree
## CP004: consulta HTTPS real sem instalar módulos, alterar progressão ou criar novos APKs.
const CONTRACT = preload("res://scripts/updates/update_contract.gd")
var http: HTTPRequest

func _initialize() -> void:
    call_deferred("_run")

func _http_download(url: String, limit: int) -> PackedByteArray:
    http.download_file = ""
    http.body_size_limit = limit
    var error := http.request(url, PackedStringArray(["Cache-Control: no-cache", "Accept-Encoding: identity"]))
    if error != OK:
        printerr("[VALDORA_OTA_REMOTE] não iniciou download: ", error)
        return PackedByteArray()
    var response: Array = await http.request_completed
    if int(response[0]) != HTTPRequest.RESULT_SUCCESS or int(response[1]) != 200:
        printerr("[VALDORA_OTA_REMOTE] falha HTTP: ", response[0], " / ", response[1])
        return PackedByteArray()
    return response[3]

func _run() -> void:
    http = HTTPRequest.new()
    http.max_redirects = 0
    http.timeout = 20.0
    http.accept_gzip = false
    root.add_child(http)

    var source: PackedByteArray = await _http_download(CONTRACT.ORIGIN + "manifest.json", CONTRACT.MAX_MANIFEST)
    var manifest = JSON.parse_string(source.get_string_from_utf8())
    var passed: int = 0
    var total: int = 3
    var manifest_ok: bool = typeof(manifest) == TYPE_DICTIONARY and CONTRACT.validate_manifest(manifest).is_empty()
    if manifest_ok:
        passed += 1
    if not manifest_ok:
        printerr("[VALDORA_OTA_REMOTE] manifesto incorreto")
        quit(1)
        return
    var modules: Array = manifest["modules"]
    var content_ok := true
    var rsa_ok := true
    for entry in modules:
        var mod: Dictionary = entry
        var bytes: PackedByteArray = await _http_download(str(mod["url"]), int(mod["bytes"]) + 1)
        var hasher := HashingContext.new()
        hasher.start(HashingContext.HASH_SHA256)
        hasher.update(bytes)
        var digest := hasher.finish()
        if bytes.size() != int(mod["bytes"]) or digest.hex_encode() != str(mod["sha256"]):
            content_ok = false
            break
        if str(mod["kind"]) == "zip" or str(mod["kind"]) == "pck":
            var pub := CryptoKey.new()
            if pub.load(CONTRACT.PUBLIC_KEY, true) != OK:
                rsa_ok = false
                break
            if not Crypto.new().verify(HashingContext.HASH_SHA256, digest,
                    Marshalls.base64_to_raw(str(mod["signature_b64"])), pub):
                rsa_ok = false
                break
    if content_ok:
        passed += 1
    if rsa_ok:
        passed += 1
    var ok := passed == total
    print("[VALDORA_OTA_REMOTE] ", JSON.stringify({"ok": ok, "passed": passed, "total": total,
        "manifest": manifest_ok, "download_integrity": content_ok, "rsa": rsa_ok}))
    quit(0 if ok else 1)
