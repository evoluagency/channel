extends Node
## Verificação no início do jogo e download automático usando o Android DownloadManager.
## O consentimento para instalar continua sendo exigido pelo Android.

const CONTRATO := preload("res://scripts/updates/update_contract.gd")
const PONTE := preload("res://scripts/pvp/pvp_android_download.gd")
const URL_VERSAO := "https://github.com/evoluagency/channel/releases/latest/download/versao.json"
const PREFIXO_APK := "https://github.com/evoluagency/channel/releases/download/"
const ESTADO := "user://pvp_apk_download.json"
const MAX_APK := 209715200

signal nova_versao(dados: Dictionary)
signal download_progresso(porcentagem: int)
signal download_pronto()
signal download_erro(mensagem: String)

static var verificado := false
var _ponte
var _dados: Dictionary = {}
var _id := -1
var _arquivo := ""
var _tempo := 0.0
var _intervalo := 0.0
var _ultimo_pct := -1
var _pronto := false

func _ready() -> void:
	set_process(false)

static func avaliar(d: Dictionary) -> bool:
	if str(d.get("jogo", "")) != "Valdora":
		return false
	if typeof(d.get("version_code")) != TYPE_INT and typeof(d.get("version_code")) != TYPE_FLOAT:
		return false
	if int(d.get("version_code", 0)) <= CONTRATO.CLIENT_CODE:
		return false
	if typeof(d.get("bytes")) != TYPE_INT and typeof(d.get("bytes")) != TYPE_FLOAT:
		return false
	if int(d.get("bytes", 0)) < 1000000 or int(d.get("bytes", 0)) > MAX_APK:
		return false
	if not CONTRATO.valid_sha(str(d.get("sha256", ""))):
		return false
	var nome := str(d.get("version_name", ""))
	var apk := str(d.get("apk", ""))
	return nome.length() >= 5 and apk.begins_with(PREFIXO_APK + "valdora-" + nome + "/") and apk.ends_with(".apk")

func iniciar(forcar := false) -> void:
	if verificado and not forcar:
		return
	if not forcar and not OS.has_feature("android"):
		return
	verificado = true
	var http := HTTPRequest.new()
	http.timeout = 10.0
	http.max_redirects = 8
	add_child(http)
	http.request_completed.connect(func(resultado: int, codigo: int, _h, corpo: PackedByteArray):
		http.queue_free()
		if resultado != HTTPRequest.RESULT_SUCCESS or codigo != 200 or corpo.size() > 16384:
			return
		var d = JSON.parse_string(corpo.get_string_from_utf8())
		if typeof(d) == TYPE_DICTIONARY and avaliar(d):
			nova_versao.emit(d)
			iniciar_download(d))
	if http.request(URL_VERSAO) != OK:
		http.queue_free()

func iniciar_download(d: Dictionary) -> void:
	if not OS.has_feature("android") or not avaliar(d):
		return
	_dados = d
	_pronto = false
	_ponte = PONTE.new()
	if not _ponte.preparar():
		download_erro.emit("Gerenciador de downloads Android não disponível.")
		return
	var salvo := _ler_estado()
	if salvo.get("version_code") == d.get("version_code") and salvo.get("sha256") == d.get("sha256"):
		_id = int(salvo.get("id", -1))
		_arquivo = str(salvo.get("arquivo", ""))
	else:
		_id = -1
		_arquivo = ""
	if _id <= 0 or _arquivo == "" or not _arquivo.begins_with(_ponte.caminho("Valdora-")):
		var nome := "Valdora-%d-%s-%d.apk" % [int(d["version_code"]), str(d["sha256"]).substr(0, 10), int(Time.get_unix_time_from_system())]
		_arquivo = _ponte.caminho(nome)
		if _arquivo == "":
			download_erro.emit("Não foi possível criar a pasta de atualização.")
			return
		_id = _ponte.baixar(str(d["apk"]), nome)
		if _id <= 0:
			download_erro.emit("O Android não iniciou o download automático.")
			return
		_salvar_estado({"version_code": d["version_code"], "sha256": d["sha256"], "id": _id, "arquivo": _arquivo})
	_tempo = 0.0
	_intervalo = 0.0
	_ultimo_pct = -1
	download_progresso.emit(0)
	set_process(true)
	_verificar_download()

func _process(delta: float) -> void:
	if _dados.is_empty() or _pronto or _id <= 0 or _ponte == null:
		return
	_tempo += delta
	_intervalo += delta
	if _intervalo >= 1.0:
		_intervalo = 0.0
		_verificar_download()
	if _tempo > 1800.0:
		set_process(false)
		download_erro.emit("Download interrompido ou muito lento. Abra novamente o Valdora para retomar.")

## O Android mantém seu próprio registro e a contagem de bytes até a conclusão.
## Nunca habilitar instalação enquanto o DownloadManager não informar sucesso.
func _verificar_download() -> void:
	var info: Dictionary = _ponte.progresso(_id)
	var status := int(info.get("status", -1))
	if status == 1 or status == 2 or status == 4:
		var esperado := int(_dados.get("bytes", 0))
		var baixado := int(info.get("baixado", 0))
		if esperado > 0 and baixado >= 0 and baixado <= esperado:
			var pct := mini(99, int(float(baixado) * 100.0 / float(esperado)))
			if pct != _ultimo_pct:
				_ultimo_pct = pct
				download_progresso.emit(pct)
		return
	if status == 8:
		_verificar_arquivo()
		return
	set_process(false)
	# Registro perdido ou falha definitiva: permitir que uma nova abertura faça
	# novo download em vez de reaproveitar indefinidamente uma tarefa quebrada.
	_salvar_estado({})
	if status == 16:
		download_erro.emit("O Android não conseguiu baixar a atualização. Verifique a rede e reabra o jogo.")
	else:
		download_erro.emit("Download não encontrado no Android. Abra o jogo novamente para tentar.")

func _verificar_arquivo() -> void:
	if not FileAccess.file_exists(_arquivo):
		return
	var f := FileAccess.open(_arquivo, FileAccess.READ)
	if f == null:
		return
	var tamanho := f.get_length()
	f.close()
	var esperado := int(_dados["bytes"])
	if tamanho > esperado:
		set_process(false)
		download_erro.emit("APK maior que o publicado. Download rejeitado.")
		return
	var pct := mini(99, int(float(tamanho) * 100.0 / float(esperado)))
	if pct != _ultimo_pct:
		_ultimo_pct = pct
		download_progresso.emit(pct)
	if tamanho != esperado:
		return
	if CONTRATO.file_digest(_arquivo).hex_encode() != str(_dados["sha256"]):
		set_process(false)
		download_erro.emit("Integridade SHA-256 incorreta. Instalação bloqueada.")
		return
	_pronto = true
	set_process(false)
	download_progresso.emit(100)
	download_pronto.emit()

func solicitar_instalacao() -> String:
	if not _pronto or _ponte == null or _id <= 0:
		return "O APK ainda não foi validado."
	if not FileAccess.file_exists(_arquivo):
		return "O APK baixado não foi encontrado."
	if CONTRATO.file_digest(_arquivo).hex_encode() != str(_dados["sha256"]):
		return "O APK foi alterado. Instalação bloqueada."
	return _ponte.instalar(_id)

func _ler_estado() -> Dictionary:
	if not FileAccess.file_exists(ESTADO):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(ESTADO))
	return d if typeof(d) == TYPE_DICTIONARY else {}

func _salvar_estado(d: Dictionary) -> void:
	var f := FileAccess.open(ESTADO, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d))
		f.close()
