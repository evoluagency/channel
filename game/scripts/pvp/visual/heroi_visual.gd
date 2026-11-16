extends Node3D
## Visual de um herói do Valdora PvP (sessão 1.8): corpo KayKit Adventurers (CC0) com a
## textura recolorida do herói (tools/pvp/recolorir_herois.py), o marcador de paintball na
## mão direita e as animações de parado, andar, correr, mirar, atirar, levar tiro e cair.
## Os 11 heróis estão em data/pvp/herois.json.

const MARCADOR := preload("res://scripts/pvp/visual/marcador.gd")
const DADOS := "res://data/pvp/herois.json"
const PASTA := "res://assets/pvp/personagens/"
const EM_LOOP := ["Idle", "2H_Melee_Idle", "2H_Ranged_Aiming", "2H_Ranged_Shooting", "Walking_A",
	"Walking_Backwards", "Running_A", "Running_Strafe_Left", "Running_Strafe_Right", "Jump_Idle"]
## Altura do KayKit em metros (medida); a escala deixa o herói com ALTURA m.
const ALTURA_KAYKIT := 2.31
const ALTURA := 1.8

static var _herois: Array = []
static var _mats := {}

var heroi: Dictionary = {}
var anim: AnimationPlayer
var esqueleto: Skeleton3D
var marcador: MeshInstance3D
var malhas := 0
var triangulos := 0
var _atual := ""

static func herois() -> Array:
	if _herois.is_empty():
		var f := FileAccess.open(DADOS, FileAccess.READ)
		if f != null:
			_herois = JSON.parse_string(f.get_as_text()).get("herois", [])
	return _herois

static func dados(id: String) -> Dictionary:
	for h in herois():
		if h.id == id:
			return h
	return herois()[0]

func montar(id: String, aparencia := MARCADOR.PADRAO, com_marcador := true) -> Node3D:
	heroi = dados(id)
	name = "Heroi_" + String(heroi.id)
	var cena: PackedScene = load(PASTA + String(heroi.base) + ".glb")
	var corpo := cena.instantiate()
	var esc := ALTURA / ALTURA_KAYKIT
	corpo.scale = Vector3.ONE * esc
	corpo.rotation.y = PI          # o KayKit olha para +Z; no Godot a frente é -Z
	add_child(corpo)
	anim = corpo.find_child("AnimationPlayer", true, false)
	esqueleto = corpo.find_child("Skeleton3D", true, false)
	var mat := _material(String(heroi.id))
	for mi in corpo.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		mi.material_override = mat
		malhas += 1
		for s in mi.mesh.get_surface_count():
			var arr: Array = mi.mesh.surface_get_arrays(s)
			var idx = arr[Mesh.ARRAY_INDEX]
			triangulos += (idx.size() if idx != null else arr[Mesh.ARRAY_VERTEX].size()) / 3
	if anim != null:
		for nome in EM_LOOP:
			if anim.has_animation(nome):
				anim.get_animation(nome).loop_mode = Animation.LOOP_LINEAR
	if com_marcador and esqueleto != null:
		var mao := BoneAttachment3D.new()
		mao.bone_name = "handslot.r"
		esqueleto.add_child(mao)
		marcador = MARCADOR.novo(aparencia)
		# na mão do KayKit: cano para a frente do corpo, funil para cima
		marcador.rotation_degrees = Vector3(0, -90, 0)
		marcador.position = Vector3(0, 0.0, 0)
		marcador.scale = Vector3.ONE / esc * 1.25
		mao.add_child(marcador)
	animar("2H_Ranged_Aiming" if com_marcador else "Idle")
	return self

func animar(nome: String, mistura := 0.18) -> void:
	if anim == null or nome == _atual or not anim.has_animation(nome):
		return
	_atual = nome
	anim.play(nome, mistura)

func _material(id: String) -> StandardMaterial3D:
	if _mats.has(id):
		return _mats[id]
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(PASTA + "herois/%s.png" % id)
	m.roughness = 0.75
	m.metallic_specular = 0.3
	m.rim_enabled = true
	m.rim = 0.25
	m.rim_tint = 0.6
	_mats[id] = m
	return m
