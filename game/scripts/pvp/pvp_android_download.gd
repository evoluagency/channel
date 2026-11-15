extends RefCounted
## Integração com o DownloadManager e instalador do Android (Godot 4.7).
## Nenhuma instalação silenciosa; a autorização permanece com o sistema.

var java
var activity
var context
var manager

func preparar() -> bool:
	if not OS.has_feature("android"):
		return false
	if not Engine.has_singleton("AndroidRuntime") or not Engine.has_singleton("JavaClassWrapper"):
		return false
	var runtime = Engine.get_singleton("AndroidRuntime")
	java = Engine.get_singleton("JavaClassWrapper")
	activity = runtime.getActivity()
	context = runtime.getApplicationContext()
	if activity == null or context == null:
		return false
	manager = context.getSystemService("download")
	return manager != null and java.get_exception() == null

func caminho(nome: String) -> String:
	var pasta = context.getExternalFilesDir("Download")
	if pasta == null or java.get_exception() != null:
		return ""
	return str(pasta.getAbsolutePath()).path_join(nome)

func baixar(url: String, nome: String) -> int:
	var uri_class = java.wrap("android.net.Uri")
	var request_class = java.wrap("android.app.DownloadManager$Request")
	var pedido = request_class.Request(uri_class.parse(url))
	pedido.setTitle("Valdora — atualização")
	pedido.setDescription("Download de nova versão do jogo")
	pedido.setMimeType("application/vnd.android.package-archive")
	pedido.setAllowedOverMetered(true)
	pedido.setAllowedOverRoaming(false)
	pedido.setNotificationVisibility(request_class.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
	pedido.setDestinationInExternalFilesDir(context, "Download", nome)
	if java.get_exception() != null:
		return -1
	var identificador = manager.enqueue(pedido)
	if java.get_exception() != null:
		return -1
	return int(identificador)

## "" = instalador aberto; "permissao" = usuário precisa autorizar origem.
func instalar(identificador: int) -> String:
	if identificador <= 0 or manager == null:
		return "O download não está disponível."
	var uri = manager.getUriForDownloadedFile(identificador)
	if uri == null or java.get_exception() != null:
		return "O Android ainda não disponibilizou o APK."
	var intent_class = java.wrap("android.content.Intent")
	var versao = java.wrap("android.os.Build$VERSION")
	if int(versao.SDK_INT) >= 26 and not activity.getPackageManager().canRequestPackageInstalls():
		var settings = java.wrap("android.provider.Settings")
		var uri_class = java.wrap("android.net.Uri")
		var tela = intent_class.Intent(settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
		tela.setData(uri_class.parse("package:" + str(activity.getPackageName())))
		activity.startActivity(tela)
		return "permissao" if java.get_exception() == null else "Abra as configurações para autorizar a instalação."
	var abrir = intent_class.Intent(intent_class.ACTION_VIEW)
	abrir.setDataAndType(uri, "application/vnd.android.package-archive")
	abrir.addFlags(intent_class.FLAG_GRANT_READ_URI_PERMISSION)
	activity.startActivity(abrir)
	return "" if java.get_exception() == null else "O Android não conseguiu abrir o instalador."
