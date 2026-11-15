extends Node
## Aviso de atualização do app (Valdora PvP).
## Ao abrir o menu, consulta o versao.json publicado junto com cada APK na versão mais recente
## do GitHub. Se houver versionCode maior que o deste app, avisa; o botão "Atualizar agora"
## baixa o APK novo pelo navegador e o Android abre o instalador (a confirmação final é do
## jogador: fora da Play Store o Android não instala app sem confirmação).
## Só aceita APK das versões publicadas deste repositório.

const CONTRATO := preload("res://scripts/updates/update_contract.gd")
const URL_VERSAO := "https://github.com/evoluagency/channel/releases/latest/download/versao.json"
const PREFIXO_APK := "https://github.com/evoluagency/channel/releases/download/"

signal nova_versao(dados: Dictionary)

static var verificado := false

## Consulta uma vez por abertura do app. No PC (testes) só consulta se pedido.
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
		if resultado != HTTPRequest.RESULT_SUCCESS or codigo != 200:
			return   # sem internet ou sem versão publicada: segue em silêncio
		var d = JSON.parse_string(corpo.get_string_from_utf8())
		if typeof(d) == TYPE_DICTIONARY and avaliar(d):
			nova_versao.emit(d))
	if http.request(URL_VERSAO) != OK:
		http.queue_free()

## Verdadeiro quando o arquivo é do Valdora, tem versão maior e o APK vem deste repositório.
static func avaliar(d: Dictionary) -> bool:
	if str(d.get("jogo", "")) != "Valdora":
		return false
	var codigo := int(d.get("version_code", 0))
	var apk := str(d.get("apk", ""))
	return codigo > CONTRATO.CLIENT_CODE and apk.begins_with(PREFIXO_APK) and apk.ends_with(".apk")
