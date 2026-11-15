extends Node
## Configuração gráfica independente dos mapas e da lógica de combate.
## Compatibilidade GLES3: 3D nativo, MSAA e filtros com perfis persistentes.
## Mantém escolha manual para aparelhos com diferentes capacidades de GPU.

const SALVO := "user://valdora_video.cfg"

var qualidade := "Média"
var fps := 60
var sombras := true
var escala_3d := 1.0

func _ready() -> void:
	_carregar()
	aplicar()

func _carregar() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SALVO) != OK:
		return
	var q := str(cfg.get_value("video", "qualidade", "Média"))
	qualidade = q if q in ["Baixa", "Média", "Alta"] else "Média"
	fps = int(cfg.get_value("video", "fps", 60))
	if fps not in [30, 60, 90]:
		fps = 60
	sombras = bool(cfg.get_value("video", "sombras", true))
	escala_3d = float(cfg.get_value("video", "escala_3d", 1.0))
	if escala_3d != 0.75 and escala_3d != 1.0:
		escala_3d = 1.0

func _salvar() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("video", "qualidade", qualidade)
	cfg.set_value("video", "fps", fps)
	cfg.set_value("video", "sombras", sombras)
	cfg.set_value("video", "escala_3d", escala_3d)
	cfg.save(SALVO)

func valor_de(categoria: String) -> String:
	match categoria:
		"Qualidade gráfica": return qualidade
		"Limite de quadros": return str(fps)
		"Sombras": return "Ligadas" if sombras else "Desligadas"
		"Resolução 3D": return "100%" if escala_3d == 1.0 else "75%"
	return ""

func definir(categoria: String, valor: String) -> void:
	match categoria:
		"Qualidade gráfica":
			if valor in ["Baixa", "Média", "Alta"]:
				qualidade = valor
		"Limite de quadros":
			if valor in ["30", "60", "90"]:
				fps = int(valor)
		"Sombras":
			if valor in ["Ligadas", "Desligadas"]:
				sombras = valor == "Ligadas"
		"Resolução 3D":
			if valor == "75%" or valor == "100%":
				escala_3d = 0.75 if valor == "75%" else 1.0
	_salvar()
	aplicar()

func restaurar() -> void:
	qualidade = "Média"
	fps = 60
	sombras = true
	escala_3d = 1.0
	_salvar()
	aplicar()

func aplicar() -> void:
	var vp := get_tree().root
	# MSAA 3D suaviza as arestas. 4x somente no perfil Alta;
	# o perfil Médio é o padrão compatível com celulares intermediários.
	match qualidade:
		"Baixa":
			vp.msaa_3d = Viewport.MSAA_DISABLED
			vp.anisotropic_filtering_level = Viewport.ANISOTROPY_2X
		"Média":
			vp.msaa_3d = Viewport.MSAA_2X
			vp.anisotropic_filtering_level = Viewport.ANISOTROPY_4X
		"Alta":
			vp.msaa_3d = Viewport.MSAA_4X
			vp.anisotropic_filtering_level = Viewport.ANISOTROPY_8X
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = escala_3d
	Engine.max_fps = fps
	# Atualiza também a arena já aberta, sem mudar colisão ou objetos.
	for luz in get_tree().get_nodes_in_group("valdora_sombras"):
		if luz is DirectionalLight3D:
			luz.shadow_enabled = sombras
