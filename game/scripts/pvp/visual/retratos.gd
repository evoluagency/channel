extends Node
## Retratos dos heróis (sessão 1.8): o rosto de cada herói é renderizado uma vez num
## SubViewport pequeno e guardado como textura, para o placar da partida e os cartões
## dos menus. Sem renderizador (smoke headless), não gera nada e quem usa mostra a inicial.
## Uso: RETRATOS.pedir(self, ["nilo", "mei"]).pronto.connect(...). Com "m:<aparência>",
## gera a miniatura do marcador com aquela pintura (cartões do Arsenal).

const HEROI := preload("res://scripts/pvp/visual/heroi_visual.gd")
const MARCADOR := preload("res://scripts/pvp/visual/marcador.gd")
const LADO := 128

static var cache := {}            # id -> Texture2D
static var _gerador: Node

signal pronto(id: String)

static func textura(id: String) -> Texture2D:
	return cache.get(id, null)

## Cria (uma vez) o gerador como filho de quem pediu e enfileira os heróis que faltam.
static func pedir(dono: Node, ids: Array) -> Node:
	if not is_instance_valid(_gerador):
		_gerador = load("res://scripts/pvp/visual/retratos.gd").new()
		_gerador.name = "Retratos"
		dono.add_child(_gerador)
	_gerador.enfileirar(ids)
	return _gerador

var _fila: Array = []
var _rodando := false

func enfileirar(ids: Array) -> void:
	for id in ids:
		if not cache.has(id) and not _fila.has(id):
			_fila.append(id)
	if not _rodando and not _fila.is_empty():
		_gerar()

func _gerar() -> void:
	if DisplayServer.get_name() == "headless":
		_fila.clear()
		return
	_rodando = true
	var vp := SubViewport.new()
	vp.size = Vector2i(LADO, LADO)
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var mundo := Node3D.new()
	vp.add_child(mundo)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.42, 2.1)
	cam.fov = 30
	mundo.add_child(cam)
	cam.look_at(Vector3(0, 1.3, 0))
	cam.current = true
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-30, 35, 0)
	sol.light_color = Color("fff1d8")
	mundo.add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c8d4e6")
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = env
	mundo.add_child(we)
	while not _fila.is_empty():
		var id: String = _fila.pop_front()
		var h: Node3D
		if id.begins_with("m:"):
			h = MARCADOR.novo(id.substr(2))
			h.position = Vector3(-0.26, 1.24, 0)
			h.rotation_degrees = Vector3(0, -90, 0)
			h.scale = Vector3.ONE * 1.05
			mundo.add_child(h)
		else:
			h = HEROI.new()
			mundo.add_child(h)
			h.montar(id, "", false)
			h.rotation.y = PI + 0.35
			h.animar("Idle", 0.0)
		for i in 3:
			await RenderingServer.frame_post_draw
		var im := vp.get_texture().get_image()
		if im != null and not im.is_empty():
			cache[id] = ImageTexture.create_from_image(im)
			pronto.emit(id)
		h.queue_free()
	vp.queue_free()
	_rodando = false
