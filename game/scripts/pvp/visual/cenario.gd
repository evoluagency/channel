extends RefCounted
## Cenário visual de cada arena do Valdora PvP, montado sobre a grade do mapa.
## A colisão continua a da grade (pvp_arena.gd); aqui só entra o que se vê:
## prédios da região no lugar das paredes, chão, coberturas temáticas, adereços junto às
## paredes (sem bloquear passagem) e a paisagem de fundo com marcos da cidade.
## Referência de acabamento: arte conceitual do dono (estilizado, quente, detalhado).

const CONSTRUTOR := preload("res://scripts/pvp/visual/construtor.gd")
const ACABAMENTO_ESPLANADA := preload("res://scripts/pvp/visual/esplanada_acabamento.gd")
const T := preload("res://scripts/ui/pvp/pvp_tema.gd")
const CEU := preload("res://scripts/pvp/visual/ceu.gdshader")

## Estabelecimentos por região: [nome no letreiro, tipo da calçada, cor do toldo e do letreiro].
const LOJAS := {
	"esplanada": [["CAFÉ CERRADO", "cafe", "teal"], ["LIVRARIA", "revistas", "azul"], ["PADARIA", "cafe", "laranja"],
		["FARMÁCIA", "nada", "verde"], ["RESTAURANTE IPÊ", "cafe", "amarelo"], ["BANCA", "revistas", "vermelho"]],
	"porto": [["BOTEQUIM", "cafe", "verde"], ["PEIXARIA", "peixe", "azul"], ["ARMAZÉM 7", "caixas", "amarelo"],
		["CAFÉ DO CAIS", "cafe", "vermelho"], ["ESTIVA", "caixas", "laranja"], ["SUCOS", "frutas", "teal"]],
	"ladeira": [["ACARAJÉ", "frutas", "laranja"], ["SORVETERIA", "cafe", "teal"], ["ARTESANATO", "revistas", "vermelho"],
		["PADARIA", "cafe", "amarelo"], ["CAPOEIRA", "nada", "verde"], ["CAFÉ BAIANO", "cafe", "azul"]],
	"estacao": [["PASTELARIA", "cafe", "amarelo"], ["LANCHONETE", "cafe", "vermelho"], ["BANCA", "revistas", "verde"],
		["FARMÁCIA", "nada", "teal"], ["BILHETERIA", "nada", "azul"], ["CAFÉ DA ESTAÇÃO", "cafe", "laranja"]],
	"represa": [["AÇAÍ", "frutas", "vermelho"], ["MERCADO DO PEIXE", "peixe", "azul"], ["FARINHA", "caixas", "amarelo"],
		["CAFÉ", "cafe", "verde"], ["MERCEARIA", "caixas", "laranja"], ["TACACÁ", "frutas", "teal"]],
}
const MAX_LOJAS := 14

var _vagas = []          # [ponto na face, fora, ao longo]

var a                 # pvp_arena.gd
var c                 # construtor
var acabamento = null # visual premium exclusivo da Esplanada; nunca altera colisões
var tema = {}
var rng = RandomNumberGenerator.new()
var C := 3.0

## Paletas e regras por região.
const TEMAS := {
	"esplanada": {
		"ceu": ["2a7fdc", "f6e1bd"], "sol": ["ffd49a", 1.45, -33.0, -40.0], "neblina": "efd9bb", "ambiente": "d8b496", "nuvens": 0.55,
		"chao": [0, "c9b3a0", "a38a78", 1.0], "chao_fora": [6, "86b84a", "5f9238", 0.35],
		"paredes": ["f2e5cb"], "socle": "c9b28f", "janela": "1f7f86", "estilo": "moderno",
		"altura": [5.0, 9.0], "arvore": ["5fae3c", "f2b33a", "e46a9e"], "baixo": "floreira", "alto": "quiosque",
	},
	"porto": {
		"ceu": ["2f85d6", "f8e4c2"], "sol": ["ffd09a", 1.45, -30.0, -55.0], "neblina": "f0dcc2", "ambiente": "dbb49a", "nuvens": 0.6,
		"chao": [9, "f1e6d2", "4f5358", 0.55], "chao_fora": [8, "7a736b", "5c5650", 1.0],
		"paredes": ["b9573a", "c86a40", "9c4a30"], "socle": "7b6e60", "janela": "1f5f66", "estilo": "armazem",
		"altura": [5.5, 8.0], "arvore": ["52a83a", "3f8f34"], "baixo": "caixotes", "alto": "conteiner",
	},
	"ladeira": {
		"ceu": ["2a82e0", "fbe3bd"], "sol": ["ffcf92", 1.5, -29.0, -30.0], "neblina": "f4dcc0", "ambiente": "e0b898", "nuvens": 0.45,
		"chao": [0, "c4ad9a", "9a8472", 1.0], "chao_fora": [0, "c4ad9a", "9a8472", 1.0],
		"paredes": ["f6c232", "2f8fd8", "ec6a92", "4fb868", "f58a36", "f6e8cc", "9a6cd0"], "socle": "eadcc2",
		"janela": "234a5a", "estilo": "colonial", "altura": [6.0, 9.5], "arvore": ["46a83f", "6cbf45"], "baixo": "carrinho", "alto": "barraca",
	},
	"estacao": {
		"ceu": ["3a86d2", "f4dfc0"], "sol": ["ffcc90", 1.4, -31.0, -65.0], "neblina": "eed8bf", "ambiente": "d6b096", "nuvens": 0.65,
		"chao": [0, "c4ae9b", "9c8573", 1.0], "chao_fora": [8, "6e6862", "54504b", 1.2],
		"paredes": ["bd5a3c", "ad4d32"], "socle": "eadcc2", "janela": "22505c", "estilo": "tijolo",
		"altura": [6.5, 10.0], "arvore": ["4f9a3a", "68b444"], "baixo": "banco", "alto": "banca",
	},
	"represa": {
		"ceu": ["2a86d0", "f4e6c4"], "sol": ["ffd8a0", 1.4, -34.0, -20.0], "neblina": "dfe2c4", "ambiente": "cdb592", "nuvens": 0.6, "densidade": 0.0032,
		"chao": [4, "b9864f", "8a6038", 1.0], "chao_fora": [6, "52a23a", "36782a", 0.6],
		"paredes": ["2f8fc8", "4fb06a", "e0583f", "f2c44a", "f6efe0"], "socle": "7a6244", "janela": "22444a",
		"estilo": "palafita", "altura": [4.6, 6.5], "arvore": ["2f9a3a", "4fb04a", "79c24a"], "baixo": "cestos", "alto": "barraco",
	},
}

func montar(arena) -> int:
	a = arena
	C = a.CELULA
	tema = TEMAS.get(a.mapa.get("id", ""), TEMAS["esplanada"])
	rng.seed = hash(a.mapa.get("id", ""))
	c = CONSTRUTOR.new()
	_materiais()
	if a.mapa.get("id", "") == "esplanada":
		acabamento = ACABAMENTO_ESPLANADA.new()
		acabamento.preparar(a, c)
	_chao()
	if acabamento != null:
		acabamento.pisos()
	_predios()
	_coberturas()
	if acabamento != null:
		acabamento.mobiliario()
	_marcas()
	_lojas()
	_adereços()
	_trilhos()
	_fundo()
	if acabamento != null:
		acabamento.entorno()
	_luz()
	if acabamento != null:
		# Metadados apenas para auditoria gráfica, sem custo de rede ou física.
		a.set_meta("esplanada_elementos_visuais", acabamento.elementos)
		a.set_meta("esplanada_triangulos_cenario", c.triangulos())
	return c.montar(a)

# ---------------------------------------------------------------- materiais

func _materiais() -> void:
	var ch: Array = tema.chao
	c.sup("chao", ch[0], Color(ch[1]), Color(ch[2]), ch[3], 0.25)
	var cf: Array = tema.chao_fora
	c.sup("chao_fora", cf[0], Color(cf[1]), Color(cf[2]), cf[3], 0.2)
	var i = 0
	for cor in tema.paredes:
		var tipo = 2
		match tema.estilo:
			"armazem", "tijolo": tipo = 1
			"moderno": tipo = 3
			"palafita": tipo = 4
		c.sup("parede%d" % i, tipo, Color(cor), Color(cor).darkened(0.18), 1.0 if tipo != 3 else 0.6, 0.4)
		i += 1
	c.sup("socle", 2, Color(tema.socle), Color(tema.socle).darkened(0.2), 1.0, 0.5)
	c.sup("friso", 2, Color("f4efe4"), Color("dcd5c6"), 2.0, 0.2)
	c.sup("telha", 11, Color("c2643a"), Color("8e4128"), 1.2, 0.2)
	c.sup("zinco", 5, Color("8e979e"), Color("6b737a"), 1.0, 0.3, 0.45, 0.5)
	c.sup("madeira", 4, Color("9a6a3d"), Color("6e4826"), 1.2, 0.3)
	c.sup("madeira_clara", 4, Color("c79a64"), Color("a27645"), 1.2, 0.2)
	c.sup("concreto", 3, Color("c9c4b8"), Color("a9a398"), 0.6, 0.4)
	c.sup("pedra", 0, Color("b9b1a2"), Color("958d7e"), 1.6, 0.3)
	c.sup("grama", 6, Color("6aa84a"), Color("4c8a34"), 1.0, 0.1)
	c.sup("terra", 10, Color("b4643c"), Color("8f4a2c"), 0.5, 0.2)
	c.sup("metal", 5, Color("3f7f86"), Color("2f6268"), 1.4, 0.25, 0.5, 0.4)
	c.sup("azulejo", 7, Color("f4f1ea"), Color("2f5fa8"), 2.5, 0.1, 0.3)
	c.liso("vidro", Color(tema.janela), 0.08, 0.5)
	c.liso("vidro_claro", Color("8fc8d8"), 0.06, 0.6)
	c.liso("caixilho", Color("f6f2ea"), 0.6)
	c.liso("escuro", Color("2b2e33"), 0.7)
	c.liso("ferro", Color("33373d"), 0.5, 0.6)
	c.liso("ouro", Color("e2b13c"), 0.35, 0.6)
	c.liso("teal", Color("1f9a96"), 0.6)
	c.liso("creme", Color("f4e9d4"), 0.7)
	c.liso("laranja", Color("f08a2a"), 0.6)
	c.liso("vermelho", Color("c8473a"), 0.6)
	c.liso("azul", Color("2f6fb8"), 0.6)
	c.liso("luz", Color("ffe2a0"), 0.4, 0.0, 1.4)
	c.liso("tronco", Color("6a4a30"), 0.9)
	var arv: Array = tema.arvore
	for k in arv.size():
		c.sup("folha%d" % k, 6, Color(arv[k]), Color(arv[k]).darkened(0.3), 2.5, 0.0, 0.9)
	c.agua("agua", Color("3fc0c8"), Color("146a86"))
	c.liso("verde", Color("3f9a52"), 0.6)
	c.liso("amarelo", Color("f2b632"), 0.6)
	c.liso("vitrine", Color("ffd9a0"), 0.3, 0.0, 0.55)

# ---------------------------------------------------------------- chão

func _chao() -> void:
	var w: float = a.largura * C
	var h: float = a.altura * C
	c.plano(Vector3(0, 0.002, 0), Vector2(w, h), "chao")
	# terreno de fora (até o horizonte)
	for lado in [[Vector3(0, -0.02, -h * 0.5 - 60), Vector2(w + 240, 120)], [Vector3(0, -0.02, h * 0.5 + 60), Vector2(w + 240, 120)],
			[Vector3(-w * 0.5 - 60, -0.02, 0), Vector2(120, h)], [Vector3(w * 0.5 + 60, -0.02, 0), Vector2(120, h)]]:
		c.plano(lado[0], lado[1], "chao_fora")

# ---------------------------------------------------------------- prédios

## Retângulos de parede iguais aos da colisão (mesmo algoritmo guloso).
func _retangulos() -> Array:
	var usado = {}
	var r = []
	for y in a.altura:
		for x in a.largura:
			if a.letra(x, y) != "#" or usado.has(Vector2i(x, y)):
				continue
			var w = 1
			while x + w < a.largura and a.letra(x + w, y) == "#" and not usado.has(Vector2i(x + w, y)):
				w += 1
			var h = 1
			var cabe = true
			while cabe and y + h < a.altura:
				for i in w:
					if a.letra(x + i, y + h) != "#" or usado.has(Vector2i(x + i, y + h)):
						cabe = false
						break
				if cabe:
					h += 1
			for j in h:
				for i in w:
					usado[Vector2i(x + i, y + j)] = true
			r.append(Rect2i(x, y, w, h))
	return r

## Lado do retângulo que dá para chão livre: quantas células de fora são livres.
func _face_livre(r: Rect2i, lado: String) -> bool:
	var livres = 0
	match lado:
		"n":
			for i in r.size.x:
				livres += int(_livre(r.position.x + i, r.position.y - 1))
		"s":
			for i in r.size.x:
				livres += int(_livre(r.position.x + i, r.end.y))
		"o":
			for j in r.size.y:
				livres += int(_livre(r.position.x - 1, r.position.y + j))
		"l":
			for j in r.size.y:
				livres += int(_livre(r.end.x, r.position.y + j))
	return livres > 0

func _livre(x: int, y: int) -> bool:
	var ch: String = a.letra(x, y)
	return ch != "#" and not (x < 0 or y < 0 or x >= a.largura or y >= a.altura)

func _predios() -> void:
	var rio_represa = a.mapa.get("id", "") == "represa"
	for r in _retangulos():
		var x0: float = r.position.x * C - a.largura * C * 0.5
		var z0: float = r.position.y * C - a.altura * C * 0.5
		var sx = r.size.x * C
		var sz = r.size.y * C
		var centro = Vector3(x0 + sx * 0.5, 0, z0 + sz * 0.5)
		var borda: bool = r.position.x == 0 or r.position.y == 0 or r.end.x == a.largura or r.end.y == a.altura
		# rio da Represa: as linhas 13 a 15 são água com mureta
		if rio_represa and r.position.y >= 13 and r.end.y <= 16:
			_rio(centro, sx, sz)
			continue
		var faixa: Array = tema.altura
		var alt = rng.randf_range(faixa[0], faixa[1]) + (2.5 if borda else 0.0)
		alt = maxf(alt, 4.4)
		var cor = "parede%d" % rng.randi_range(0, tema.paredes.size() - 1)
		var faces = []
		for lado in ["n", "s", "o", "l"]:
			if _face_livre(r, lado):
				faces.append(lado)
		match tema.estilo:
			"moderno": _moderno(centro, sx, sz, alt, cor, faces)
			"armazem": _armazem(centro, sx, sz, alt, cor, faces)
			"colonial": _colonial(r, centro, sx, sz, alt, faces)
			"tijolo": _estacao(centro, sx, sz, alt, cor, faces)
			"palafita": _palafita(centro, sx, sz, alt, cor, faces)
		# Segunda pele arquitetônica: somente malha visual, fora da grade de colisão.
		if acabamento != null:
			acabamento.fachada(centro, sx, sz, alt, faces, borda)
		# vagas de loja no térreo (só onde a calçada em frente é livre)
		if rio_represa and (_na_borda(centro, sx, sz) or sx * sz >= 120.0):
			continue
		for lado in faces:
			for v in _ao_longo(centro, sx, sz, lado, 5.0, 1.0):
				var cel = a.mundo_celula(v[0] + v[1] * 1.6)
				if a.letra(cel.x, cel.y) in [".", "1", "2", "3", "A", "B"]:
					_vagas.append(v)

## Pontos ao longo de uma face, com o vetor para fora. passo = distância entre janelas.
func _ao_longo(centro: Vector3, sx: float, sz: float, lado: String, passo: float, margem := 1.2) -> Array:
	var pts = []
	var comp = sx if lado in ["n", "s"] else sz
	var n = maxi(1, int((comp - margem * 2.0) / passo))
	var fora = {"n": Vector3(0, 0, -1), "s": Vector3(0, 0, 1), "o": Vector3(-1, 0, 0), "l": Vector3(1, 0, 0)}[lado]
	var ao = Vector3(1, 0, 0) if lado in ["n", "s"] else Vector3(0, 0, 1)
	var face = centro + fora * ((sz if lado in ["n", "s"] else sx) * 0.5)
	for i in n:
		var t = (i + 0.5) / n - 0.5
		pts.append([face + ao * t * (comp - margem * 2.0), fora, ao])
	return pts

## Janela na face: base = ponto na parede (y = peitoril), fora = normal.
func _janela(base: Vector3, fora: Vector3, ao: Vector3, larg: float, alt: float, vidro := "vidro", moldura := "caixilho", venezianas := "") -> void:
	var rot = atan2(fora.x, fora.z)
	c.caixa(base + fora * 0.04, Vector3(larg + 0.24, alt + 0.24, 0.1), moldura, rot)
	c.caixa(base + fora * 0.08 + Vector3(0, 0.12, 0), Vector3(larg, alt, 0.06), vidro, rot)
	c.caixa(base + fora * 0.12 + Vector3(0, 0.12 + alt * 0.025, 0), Vector3(0.05, alt * 0.95, 0.04), moldura, rot)
	c.caixa(base + fora * 0.12 - Vector3(0, 0.08, 0), Vector3(larg + 0.4, 0.1, 0.22), moldura, rot)   # peitoril
	if venezianas != "":
		for s in [-1, 1]:
			c.caixa(base + fora * 0.1 + ao * s * (larg * 0.5 + 0.33), Vector3(0.6, alt + 0.1, 0.06), venezianas, rot)

func _corpo(centro: Vector3, sx: float, sz: float, alt: float, cor: String) -> void:
	c.caixa(centro, Vector3(sx, alt, sz), cor)
	c.caixa(centro, Vector3(sx + 0.12, 0.9, sz + 0.12), "socle")

# -- Brasília: modernismo branco, janelas em faixa e brises
func _moderno(centro: Vector3, sx: float, sz: float, alt: float, cor: String, faces: Array) -> void:
	_corpo(centro, sx, sz, alt, cor)
	var andares = int((alt - 1.2) / 3.0)
	for lado in faces:
		var fora = {"n": Vector3(0, 0, -1), "s": Vector3(0, 0, 1), "o": Vector3(-1, 0, 0), "l": Vector3(1, 0, 0)}[lado]
		var comp = sx if lado in ["n", "s"] else sz
		var prof = sz if lado in ["n", "s"] else sx
		var rot = atan2(fora.x, fora.z)
		for k in andares:
			var y = 1.5 + k * 3.0
			c.caixa(centro + fora * (prof * 0.5 + 0.03) + Vector3(0, y, 0), Vector3(comp - 0.8, 1.4, 0.08), "vidro", rot)
		for p in _ao_longo(centro, sx, sz, lado, 1.6, 0.6):
			c.caixa(p[0] + p[1] * 0.25 + Vector3(0, 1.0, 0), Vector3(0.12, alt - 1.6, 0.5), "friso", rot)
	c.caixa(centro + Vector3(0, alt, 0), Vector3(sx + 0.3, 0.45, sz + 0.3), "friso")
	if rng.randf() < 0.35:
		# letreiro com faixa verde-azulada (identidade Valdora)
		c.caixa(centro + Vector3(0, alt - 1.0, 0), Vector3(sx + 0.16, 0.35, sz + 0.16), "teal")

# -- Rio: armazéns de tijolo do porto, janelas em arco e telhado de zinco
func _armazem(centro: Vector3, sx: float, sz: float, alt: float, cor: String, faces: Array) -> void:
	_corpo(centro, sx, sz, alt, cor)
	c.caixa(centro + Vector3(0, alt - 0.6, 0), Vector3(sx + 0.2, 0.3, sz + 0.2), "friso")
	for lado in faces:
		var i = 0
		for p in _ao_longo(centro, sx, sz, lado, 2.6):
			if i % 3 == 1 and alt > 5.0:
				# portão de carga
				var rot = atan2(p[1].x, p[1].z)
				c.caixa(p[0] + p[1] * 0.05, Vector3(2.0, 3.0, 0.1), "metal", rot)
				c.caixa(p[0] + p[1] * 0.06 + Vector3(0, 3.0, 0), Vector3(2.3, 0.25, 0.14), "friso", rot)
			else:
				_janela(p[0] + Vector3(0, 1.4, 0), p[1], p[2], 1.0, 1.5, "vidro", "friso")
			_janela(p[0] + Vector3(0, alt - 2.6, 0), p[1], p[2], 0.9, 1.1, "vidro", "friso")
			i += 1
	c.telhado(centro + Vector3(0, alt, 0), Vector3(sx, 0, sz), 1.2, "zinco", 0.3)

# -- Salvador: casario colorido com cantaria branca, venezianas e telhado de telha
func _colonial(r: Rect2i, centro: Vector3, sx: float, sz: float, alt: float, faces: Array) -> void:
	# casas estreitas lado a lado ao longo do maior eixo
	var largo = sx >= sz
	var comp = sx if largo else sz
	var n = maxi(1, int(round(comp / 4.5)))
	var passo = comp / n
	for k in n:
		var off = (k + 0.5) * passo - comp * 0.5
		var cc = centro + (Vector3(off, 0, 0) if largo else Vector3(0, 0, off))
		var w = passo if largo else sx
		var d = sz if largo else passo
		var h = alt + rng.randf_range(-1.2, 1.2)
		var cor = "parede%d" % rng.randi_range(0, tema.paredes.size() - 1)
		_corpo(cc, w, d, h, cor)
		for q in [Vector3(-1, 0, -1), Vector3(1, 0, -1), Vector3(-1, 0, 1), Vector3(1, 0, 1)]:
			c.caixa(cc + Vector3(q.x * w * 0.5, 0, q.z * d * 0.5), Vector3(0.35, h, 0.35), "friso")   # cunhais
		c.caixa(cc + Vector3(0, h - 0.4, 0), Vector3(w + 0.3, 0.4, d + 0.3), "friso")                   # cornija
		var venez = ["azul", "teal", "vermelho"][rng.randi_range(0, 2)]
		for lado in faces:
			for p in _ao_longo(cc, w, d, lado, 2.1, 0.9):
				var andares = int((h - 1.0) / 3.0)
				for f in andares:
					var y = 1.1 + f * 3.0
					if f == 0 and rng.randf() < 0.3:
						var rot = atan2(p[1].x, p[1].z)
						c.caixa(p[0] + p[1] * 0.05, Vector3(1.2, 2.4, 0.1), "madeira", rot)   # porta
						c.caixa(p[0] + p[1] * 0.06 + Vector3(0, 2.4, 0), Vector3(1.5, 0.3, 0.14), "friso", rot)
					else:
						_janela(p[0] + Vector3(0, y, 0), p[1], p[2], 0.95, 1.7, "vidro", "friso", venez)
					if f >= 1 and rng.randf() < 0.25:
						var rot2 = atan2(p[1].x, p[1].z)
						c.caixa(p[0] + p[1] * 0.45 + Vector3(0, y - 0.25, 0), Vector3(1.6, 0.12, 0.8), "friso", rot2)  # sacada
						c.caixa(p[0] + p[1] * 0.82 + Vector3(0, y - 0.13, 0), Vector3(1.6, 0.8, 0.05), "ferro", rot2)
		c.telhado(cc + Vector3(0, h, 0), Vector3(w, 0, d), 1.6, "telha", 0.4)
	# igreja barroca no lugar do maior bloco da área da Igreja
	if r.size.x * r.size.y >= 6 and centro.z < 0:
		_igreja(centro + Vector3(0, 0, 0), sx, sz, alt)

func _igreja(centro: Vector3, sx: float, sz: float, alt: float) -> void:
	var h = alt + 5.0
	c.caixa(centro, Vector3(sx * 0.9, h, sz * 0.9), "parede5")
	c.caixa(centro + Vector3(0, h, 0), Vector3(sx * 0.95, 0.5, sz * 0.95), "friso")
	for s in [-1, 1]:
		var t = centro + Vector3(s * sx * 0.32, 0, 0)
		c.caixa(t, Vector3(2.4, h + 5.0, 2.4), "friso")
		c.caixa(t + Vector3(0, h + 5.0, 0), Vector3(2.0, 1.4, 2.0), "azulejo")
		c.cilindro(t + Vector3(0, h + 6.4, 0), 1.0, 2.0, "azulejo", 8, 0.0)
		c.caixa(t + Vector3(0, h + 3.2, 1.21), Vector3(0.9, 1.6, 0.1), "escuro")
	c.telhado(centro + Vector3(0, h + 0.5, 0), Vector3(sx * 0.6, 0, sz * 0.8), 2.4, "telha", 0.2)

# -- São Paulo: tijolo aparente com cantaria clara (estação ferroviária antiga)
func _estacao(centro: Vector3, sx: float, sz: float, alt: float, cor: String, faces: Array) -> void:
	_corpo(centro, sx, sz, alt, cor)
	var andares = int((alt - 1.0) / 3.4)
	for k in andares + 1:
		c.caixa(centro + Vector3(0, 0.9 + k * 3.4, 0), Vector3(sx + 0.16, 0.22, sz + 0.16), "friso")
	for lado in faces:
		for p in _ao_longo(centro, sx, sz, lado, 2.4):
			for k in andares:
				_janela(p[0] + Vector3(0, 1.4 + k * 3.4, 0), p[1], p[2], 1.0, 2.0, "vidro", "friso")
				c.caixa(p[0] + p[1] * 0.08 + Vector3(0, 3.55 + k * 3.4, 0), Vector3(1.4, 0.25, 0.14), "friso", atan2(p[1].x, p[1].z))
	c.caixa(centro + Vector3(0, alt, 0), Vector3(sx + 0.4, 0.5, sz + 0.4), "friso")
	for x in [-1, 1]:
		for z in [-1, 1]:
			c.caixa(centro + Vector3(x * sx * 0.5, alt + 0.5, z * sz * 0.5), Vector3(0.6, 0.9, 0.6), "friso")

# -- Pará: casas de madeira coloridas sobre palafitas, telhado de zinco
func _palafita(centro: Vector3, sx: float, sz: float, alt: float, cor: String, faces: Array) -> void:
	var grande = sx * sz >= 120.0 and absf(centro.z) < 20.0
	if _na_borda(centro, sx, sz):
		_mata(centro, sx, sz, alt)
		return
	if not grande and sx * sz > 40.0:
		# bloco comprido: várias casas
		var largo = sx >= sz
		var comp = sx if largo else sz
		var n = maxi(1, int(round(comp / 6.0)))
		var passo = comp / n
		for k in n:
			var off = (k + 0.5) * passo - comp * 0.5
			var cc = centro + (Vector3(off, 0, 0) if largo else Vector3(0, 0, off))
			_palafita(cc, (passo - 0.4) if largo else sx, sz if largo else (passo - 0.4), alt + rng.randf_range(-0.5, 0.8), "parede%d" % rng.randi_range(0, tema.paredes.size() - 1), faces)
		return
	if grande:
		# estrutura de concreto da usina
		c.caixa(centro, Vector3(sx, alt + 2.0, sz), "concreto")
		for lado in faces:
			for p in _ao_longo(centro, sx, sz, lado, 3.0, 0.8):
				c.caixa(p[0] + p[1] * 0.05 + Vector3(0, 0.5, 0), Vector3(0.6, alt + 1.0, 0.1), "socle", atan2(p[1].x, p[1].z))
		c.caixa(centro + Vector3(0, alt + 2.0, 0), Vector3(sx + 0.3, 0.4, sz + 0.3), "friso")
		c.caixa(centro + Vector3(0, alt + 2.4, 0), Vector3(sx * 0.4, 1.6, sz * 0.4), "metal")
		return
	c.caixa(centro, Vector3(sx, 0.9, sz), "madeira")                       # assoalho elevado
	for x in [-1, 1]:
		for z in [-1, 1]:
			c.cilindro(centro + Vector3(x * (sx * 0.5 - 0.2), 0, z * (sz * 0.5 - 0.2)), 0.16, 1.0, "tronco", 6)
	var corpo = centro + Vector3(0, 0.9, 0)
	c.caixa(corpo, Vector3(sx - 0.2, alt - 0.9, sz - 0.2), cor)
	for lado in faces:
		for p in _ao_longo(corpo, sx - 0.2, sz - 0.2, lado, 2.4, 1.0):
			_janela(p[0] + Vector3(0, 1.0, 0), p[1], p[2], 1.0, 1.1, "escuro", "creme", "madeira_clara")
	c.telhado(centro + Vector3(0, alt, 0), Vector3(sx, 0, sz), 1.4, "zinco", 0.6)

func _na_borda(centro: Vector3, sx: float, sz: float) -> bool:
	var w = a.largura * C * 0.5
	var h = a.altura * C * 0.5
	return absf(centro.x) + sx * 0.5 >= w - 0.1 or absf(centro.z) + sz * 0.5 >= h - 0.1

## Mata fechada no limite do mapa (Represa): barranco de terra e árvores altas.
func _mata(centro: Vector3, sx: float, sz: float, alt: float) -> void:
	c.caixa(centro, Vector3(sx, alt, sz), "folha0")
	var n = int(sx * sz / 9.0)
	for i in n:
		var p = centro + Vector3(rng.randf_range(-sx, sx) * 0.5, alt - 1.0, rng.randf_range(-sz, sz) * 0.5)
		c.esfera(p + Vector3(0, 1.5, 0), Vector3(2.2, 1.8, 2.2) * rng.randf_range(0.8, 1.4), "folha%d" % rng.randi_range(0, tema.arvore.size() - 1), 7, 4)

func _rio(centro: Vector3, sx: float, sz: float) -> void:
	c.plano(centro + Vector3(0, 0.06, 0), Vector2(sx, sz), "agua")
	for s in [-1, 1]:
		c.caixa(centro + Vector3(0, 0, s * (sz * 0.5 - 0.1)), Vector3(sx, 0.5, 0.2), "concreto")

# ---------------------------------------------------------------- coberturas

func _coberturas() -> void:
	for y in a.altura:
		for x in a.largura:
			if a.letra(x, y) != "c":
				continue
			var p: Vector3 = a.celula_mundo(x, y)
			var alta: bool = a.cobertura_alta(x, y)
			var rot = rng.randf_range(-0.12, 0.12)
			var t: float = a.COBERTURA
			if alta:
				match tema.alto:
					"quiosque":
						c.caixa(p, Vector3(t, 0.4, t), "concreto", rot)
						c.caixa(p + Vector3(0, 0.4, 0), Vector3(t - 0.3, 1.6, t - 0.3), "vidro_claro", rot)
						c.caixa(p + Vector3(0, 2.0, 0), Vector3(t + 0.2, 0.4, t + 0.2), "friso", rot)
					"conteiner":
						var cor = ["metal", "laranja", "vermelho", "azul"][rng.randi_range(0, 3)]
						c.caixa(p, Vector3(t, a.ALTURA_CONTEINER, t), "metal" if cor == "metal" else cor, rot)
						c.caixa(p + Vector3(0, a.ALTURA_CONTEINER - 0.15, 0), Vector3(t + 0.05, 0.15, t + 0.05), "ferro", rot)
					"barraca":
						c.caixa(p, Vector3(t, 1.0, t), "madeira", rot)
						for q in [Vector3(-1, 0, -1), Vector3(1, 0, -1), Vector3(-1, 0, 1), Vector3(1, 0, 1)]:
							c.cilindro(p + q * (t * 0.45), 0.06, 2.4, "ferro", 5)
						c.telhado(p + Vector3(0, 2.4, 0), Vector3(t, 0, t), 0.5, ["laranja", "teal", "vermelho"][rng.randi_range(0, 2)], 0.3)
					"banca":
						c.caixa(p, Vector3(t, 2.2, t), "teal", rot)
						c.caixa(p + Vector3(0, 2.2, 0), Vector3(t + 0.3, 0.25, t + 0.3), "creme", rot)
						c.caixa(p + Vector3(0, 0.9, t * 0.5), Vector3(t - 0.6, 0.9, 0.1), "vidro_claro", rot)
					_:
						c.caixa(p, Vector3(t, 2.3, t), "madeira", rot)
						c.telhado(p + Vector3(0, 2.3, 0), Vector3(t, 0, t), 0.5, "zinco", 0.2)
			else:
				match tema.baixo:
					"floreira":
						c.caixa(p, Vector3(t, 0.9, t), "concreto", rot)
						c.caixa(p + Vector3(0, 0.9, 0), Vector3(t - 0.3, 0.12, t - 0.3), "grama", rot)
						_arvore(p + Vector3(0, 0.9, 0), 0.8)
					"caixotes":
						c.caixa(p, Vector3(t, a.ALTURA_CAIXOTE, t), "madeira_clara", rot)
						c.caixa(p + Vector3(0.3, a.ALTURA_CAIXOTE, -0.3), Vector3(1.1, 0.8, 1.1), "madeira", rot + 0.3)
					"carrinho":
						c.caixa(p + Vector3(0, 0.3, 0), Vector3(t, 0.85, t * 0.8), "madeira_clara", rot)
						for s in [-1, 1]:
							c.cilindro(p + Vector3(s * t * 0.42, 0, t * 0.45), 0.34, 0.12, "escuro", 8)
						c.caixa(p + Vector3(0, 1.15, 0), Vector3(t - 0.4, 0.25, t * 0.6), "laranja", rot)
					"banco":
						c.caixa(p, Vector3(t, 1.0, t * 0.7), "madeira", rot)
						c.caixa(p + Vector3(0, 1.0, -t * 0.3), Vector3(t, 0.5, 0.15), "ferro", rot)
					_:
						c.caixa(p, Vector3(t, 0.7, t), "madeira", rot)
						for k in 3:
							c.cilindro(p + Vector3(-0.7 + k * 0.7, 0.7, 0), 0.32, 0.5, "madeira_clara", 8)

# ---------------------------------------------------------------- marcas de jogo no chão

func _marcas() -> void:
	c.liso("base_t", Color("3f8f5a"), 0.8, 0.0, 0.0, 0.55)
	c.liso("base_d", Color("b0603a"), 0.8, 0.0, 0.0, 0.55)
	c.liso("ponto_a", Color("d9534a"), 0.8, 0.0, 0.0, 0.5)
	c.liso("ponto_b", Color("3f6fc9"), 0.8, 0.0, 0.0, 0.5)
	c.liso("faixa", Color("ffc21a"), 0.7)
	var chaves = {"T": "base_t", "D": "base_d", "A": "ponto_a", "B": "ponto_b"}
	for y in a.altura:
		for x in a.largura:
			var ch: String = a.letra(x, y)
			var p: Vector3 = a.celula_mundo(x, y)
			if chaves.has(ch):
				# só a borda da área, como pintura no chão
				for d in [[Vector2i(0, -1), Vector3(0, 0, -1)], [Vector2i(0, 1), Vector3(0, 0, 1)], [Vector2i(-1, 0), Vector3(-1, 0, 0)], [Vector2i(1, 0), Vector3(1, 0, 0)]]:
					if a.letra(x + d[0].x, y + d[0].y) != ch:
						var tam = Vector2(C, 0.25) if d[1].x == 0 else Vector2(0.25, C)
						c.plano(p + d[1] * (C * 0.5 - 0.15) + Vector3(0, 0.012, 0), tam, chaves[ch])
			elif ch in ["1", "2", "3"]:
				c.plano(p + Vector3(0, 0.01, 0), Vector2(C, 0.25), "faixa")

# ---------------------------------------------------------------- adereços (sem colisão)

func _adereços() -> void:
	# junto às paredes, em células livres: poste, bandeira da equipe ou árvore (não fecham passagem)
	var k = 0
	for y in a.altura:
		for x in a.largura:
			if not _livre(x, y) or a.letra(x, y) in ["T", "D", "A", "B", "1", "2", "3", "c"]:
				continue
			var parede = Vector3.ZERO
			for d in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
				if a.letra(x + d.x, y + d.y) == "#":
					parede = Vector3(d.x, 0, d.y)
					break
			if parede == Vector3.ZERO:
				continue
			k += 1
			var p: Vector3 = a.celula_mundo(x, y) + parede * (C * 0.5 - 0.35)
			match k % 7:
				0, 4:
					_poste(p)
				2:
					_bandeira(p, parede)
				5:
					if tema.estilo != "armazem":
						_arvore(p - parede * 0.3, 1.0)
				_:
					pass

# ---------------------------------------------------------------- estabelecimentos

func _lojas() -> void:
	var lista: Array = LOJAS.get(a.mapa.get("id", ""), LOJAS["esplanada"])
	# espalha as lojas pelo mapa: sorteia vagas e não deixa duas lojas a menos de 9 m
	var escolhidas = []
	var ordem = range(_vagas.size())
	for i in ordem.size():
		var j = rng.randi_range(i, ordem.size() - 1)
		var t = ordem[i]; ordem[i] = ordem[j]; ordem[j] = t
	for i in ordem:
		if escolhidas.size() >= MAX_LOJAS:
			break
		var v = _vagas[i]
		var perto = false
		for e in escolhidas:
			if (e[0] as Vector3).distance_to(v[0]) < 9.0:
				perto = true
				break
		if not perto:
			escolhidas.append(v)
	for k in escolhidas.size():
		var v = escolhidas[k]
		var loja: Array = lista[k % lista.size()]
		_loja(v[0], v[1], v[2], loja[0], loja[1], loja[2])

## Fachada de loja no térreo: moldura, vitrine iluminada, porta, toldo listrado, letreiro e calçada.
func _loja(p: Vector3, fora: Vector3, ao: Vector3, nome: String, tipo: String, cor: String) -> void:
	var rot = atan2(fora.x, fora.z)
	var L := 3.6
	var up = Vector3.UP
	var moldura = "madeira" if tema.estilo in ["colonial", "palafita"] else "ferro"
	c.caixa(p + fora * 0.08, Vector3(L, 3.1, 0.16), moldura, rot)
	c.caixa(p + fora * 0.17 - ao * 0.45 + up * 0.55, Vector3(L - 1.6, 1.8, 0.04), "vitrine", rot)
	c.caixa(p + fora * 0.17 + ao * (L * 0.5 - 0.65), Vector3(0.95, 2.35, 0.04), "vidro", rot)
	for i in 5:
		var faixa = cor if i % 2 == 0 else "creme"
		c.caixa(p + fora * (0.3 + i * 0.24) + up * (2.9 - i * 0.11), Vector3(L + 0.2, 0.06, 0.26), faixa, rot)
	c.caixa(p + fora * 0.2 + up * 3.15, Vector3(L, 0.7, 0.1), cor, rot)
	var l = Label3D.new()
	l.text = nome
	l.font = T.fonte(900, false)
	# Mais amostras na fonte do letreiro, sem ampliar o tamanho em metros.
	l.font_size = 96 if nome.length() <= 10 else 69
	l.pixel_size = 0.004
	l.modulate = Color("fff6e6")
	l.outline_size = 10
	l.outline_modulate = Color(0, 0, 0, 0.45)
	l.position = p + fora * 0.27 + up * 3.5
	l.rotation.y = rot
	l.shaded = false
	a.add_child(l)
	# calçada da loja (encostada na parede, abaixo de 1 m: não atrapalha a passagem)
	var calc = p + fora * 0.9
	match tipo:
		"cafe":
			for s_ in [-1, 1]:
				var m = calc + ao * s_ * 1.0
				c.cilindro(m, 0.05, 0.75, "ferro", 6)
				c.cilindro(m + up * 0.75, 0.38, 0.04, "creme", 10)
				for q in [-0.5, 0.5]:
					c.caixa(m + ao * q, Vector3(0.36, 0.45, 0.36), "madeira", rot)
					c.caixa(m + ao * q * 1.25 + up * 0.45, Vector3(0.06, 0.45, 0.36), "madeira", rot)
		"frutas", "peixe":
			c.caixa(calc, Vector3(1.6, 0.75, 0.8), "madeira_clara", rot)
			var cores = ["laranja", "vermelho", "amarelo", "verde"] if tipo == "frutas" else ["creme", "azul", "creme", "teal"]
			for i in 6:
				var f = calc + ao * (-0.6 + (i % 3) * 0.6) + fora * (-0.18 + (i / 3) * 0.36) + up * 0.85
				c.esfera(f, Vector3(0.16, 0.12, 0.16), cores[i % 4], 6, 4)
		"revistas":
			c.caixa(calc - fora * 0.3, Vector3(1.4, 1.3, 0.35), "madeira", rot)
			for i in 6:
				c.caixa(calc - fora * 0.1 + ao * (-0.5 + (i % 3) * 0.5) + up * (0.35 + (i / 3) * 0.45), Vector3(0.38, 0.32, 0.03), ["vermelho", "azul", "amarelo"][i % 3], rot)
		"caixas":
			for i in 3:
				c.caixa(calc + ao * (-0.7 + i * 0.7), Vector3(0.6, 0.5 + (i % 2) * 0.3, 0.6), "madeira_clara", rot + 0.1 * i)

func _trilhos() -> void:
	if a.mapa.get("id", "") != "estacao":
		return
	for y in [7, 10]:
		var z = a.celula_mundo(0, y).z
		var w = a.largura * C - 6.0
		for k in int(w / 0.8):
			c.caixa(Vector3(-w * 0.5 + k * 0.8, 0.0, z), Vector3(0.25, 0.08, 2.0), "madeira")
		for s_ in [-0.72, 0.72]:
			c.caixa(Vector3(0, 0.08, z + s_), Vector3(w, 0.1, 0.1), "ferro")

func _poste(p: Vector3) -> void:
	c.cilindro(p, 0.08, 3.4, "ferro", 6)
	c.caixa(p + Vector3(0, 3.4, 0), Vector3(0.35, 0.45, 0.35), "ferro")
	c.caixa(p + Vector3(0, 3.45, 0), Vector3(0.25, 0.3, 0.25), "luz")

## Estandarte verde-azulado com o emblema em V (identidade Valdora).
func _bandeira(p: Vector3, parede: Vector3) -> void:
	var rot = atan2(-parede.x, -parede.z)
	c.caixa(p + Vector3(0, 3.8, 0), Vector3(1.0, 0.08, 0.08), "ouro", rot)
	c.caixa(p + Vector3(0, 2.0, 0), Vector3(0.85, 1.8, 0.04), "teal", rot)
	c.caixa(p - parede * 0.03 + Vector3(0, 2.5, 0), Vector3(0.45, 0.45, 0.04), "ouro", rot + PI * 0.25)
	c.caixa(p + Vector3(0, 1.85, 0), Vector3(0.85, 0.2, 0.05), "ouro", rot)

func _arvore(p: Vector3, e: float) -> void:
	var folha = "folha%d" % rng.randi_range(0, tema.arvore.size() - 1)
	if tema.estilo in ["colonial", "palafita"] and rng.randf() < 0.5:
		# palmeira
		c.cilindro(p, 0.14 * e, 5.0 * e, "tronco", 6, 0.1 * e)
		for i in 7:
			var ang = TAU * i / 7
			var d = Vector3(cos(ang), 0, sin(ang))
			c.caixa(p + Vector3(0, 5.0 * e, 0) + d * 0.9 * e, Vector3(1.9 * e, 0.08, 0.5 * e), folha, -ang)
		return
	c.cilindro(p, 0.13 * e, 2.4 * e, "tronco", 6, 0.08 * e)
	c.esfera(p + Vector3(0, 3.0 * e, 0), Vector3(1.3, 1.0, 1.3) * e, folha, 8, 5)
	c.esfera(p + Vector3(0.5, 3.6 * e, 0.3) * Vector3(e, 1, e), Vector3(0.9, 0.75, 0.9) * e, folha, 7, 4)

# ---------------------------------------------------------------- paisagem de fundo

func _fundo() -> void:
	var w: float = a.largura * C
	var h: float = a.altura * C
	match a.mapa.get("id", ""):
		"esplanada":
			# duas torres gêmeas, cúpula e cúpula invertida, catedral de pilares curvos, ministérios
			var z = -h * 0.5 - 45.0
			for s in [-1, 1]:
				c.caixa(Vector3(s * 4.0, 0, z - 10), Vector3(6.0, 34.0, 4.0), "parede0")
				for k in 10:
					c.caixa(Vector3(s * 4.0, 2.0 + k * 3.2, z - 7.95), Vector3(5.4, 1.2, 0.1), "vidro")
			c.caixa(Vector3(0, 0, z + 2), Vector3(70.0, 5.0, 14.0), "parede0")
			c.esfera(Vector3(-20, 5.0, z + 2), Vector3(7.0, 5.0, 7.0), "parede0", 14, 8, true)
			c.cilindro(Vector3(20, 5.0, z + 2), 3.0, 4.0, "parede0", 14, 9.0)
			for i in 12:
				var ang = TAU * i / 12
				c.cilindro(Vector3(-55 + cos(ang) * 6, 0, z + 20 + sin(ang) * 6), 0.6, 18.0, "parede0", 6, 0.25)
			for s in [-1, 1]:
				for k in 5:
					c.caixa(Vector3(s * (w * 0.5 + 20), 0, -h * 0.5 + k * 20), Vector3(12, 14, 8), "parede0")
			for i in 40:
				var p = Vector3(rng.randf_range(-w, w), 0, rng.randf_range(-h, h))
				if absf(p.x) > w * 0.5 + 6 or absf(p.z) > h * 0.5 + 6:
					_arvore(p, rng.randf_range(1.2, 1.8))
		"porto":
			c.plano(Vector3(w * 0.5 + 70, 0.05, 0), Vector2(120, h + 260), "agua")
			for s in [-1, 1]:
				c.esfera(Vector3(w * 0.5 + 110, -10, s * 40 - 20), Vector3(22, 48, 18), "pedra", 10, 6, true)
			c.esfera(Vector3(w * 0.5 + 90, -6, 90), Vector3(14, 30, 12), "folha0", 10, 6, true)
			c.esfera(Vector3(-w * 0.5 - 70, -10, -60), Vector3(40, 60, 30), "folha0", 10, 6, true)
			for k in 4:
				_guindaste(Vector3(w * 0.5 + 8, 0, -h * 0.5 + 15 + k * 22))
		"ladeira":
			c.plano(Vector3(0, 0.05, -h * 0.5 - 90), Vector2(w + 400, 120), "agua")
			for i in 30:
				var p = Vector3(rng.randf_range(-w * 0.5 - 50, w * 0.5 + 50), 0, rng.randf_range(h * 0.5 + 8, h * 0.5 + 50))
				var cor = "parede%d" % rng.randi_range(0, tema.paredes.size() - 1)
				c.caixa(p, Vector3(5, 7, 6), cor)
				c.telhado(p + Vector3(0, 7, 0), Vector3(5, 0, 6), 1.5, "telha", 0.3)
			c.caixa(Vector3(w * 0.5 + 25, 0, -h * 0.5 - 20), Vector3(8, 32, 8), "parede5")
		"estacao":
			# torre do relógio de tijolo e prédios altos ao fundo
			var t = Vector3(0, 0, -h * 0.5 - 18)
			c.caixa(t, Vector3(7, 30, 7), "parede0")
			c.caixa(t + Vector3(0, 30, 0), Vector3(8, 1, 8), "friso")
			c.cilindro(t + Vector3(0, 22, 3.6), 2.2, 0.2, "creme", 16)
			c.cilindro(t + Vector3(0, 31, 0), 3.5, 5.0, "zinco", 4, 0.0)
			for i in 26:
				var p = Vector3(rng.randf_range(-w - 40, w + 40), 0, rng.randf_range(-h - 40, -h * 0.5 - 30))
				var alt = rng.randf_range(20, 55)
				c.caixa(p, Vector3(rng.randf_range(10, 18), alt, rng.randf_range(10, 18)), ["concreto", "parede0", "socle"][i % 3])
		"represa":
			for i in 90:
				var p = Vector3(rng.randf_range(-w - 30, w + 30), 0, rng.randf_range(-h - 30, h + 30))
				if absf(p.x) > w * 0.5 + 4 or absf(p.z) > h * 0.5 + 4:
					_arvore(p, rng.randf_range(1.6, 2.6))
			c.caixa(Vector3(0, 0, -h * 0.5 - 30), Vector3(w + 60, 22, 10), "concreto")
			for k in 8:
				c.caixa(Vector3(-w * 0.5 + k * 12, 2, -h * 0.5 - 24.9), Vector3(6, 16, 0.2), "agua")

func _guindaste(p: Vector3) -> void:
	for x in [-1, 1]:
		for z in [-1, 1]:
			c.cilindro(p + Vector3(x * 2.5, 0, z * 2.5), 0.25, 14.0, "laranja", 6)
	c.caixa(p + Vector3(0, 14, 0), Vector3(6, 3, 6), "laranja")
	c.caixa(p + Vector3(9, 16, 0), Vector3(26, 1.2, 1.4), "laranja")
	c.caixa(p + Vector3(-5, 16, 0), Vector3(6, 1.6, 2.0), "ferro")

# ---------------------------------------------------------------- luz e céu

func _luz() -> void:
	# Direção de arte (arte conceitual do dono): fim de tarde dourado, sombra quente,
	# cores saturadas, brilho leve nas luzes e neblina de profundidade.
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var ceu = Sky.new()
	var mc = ShaderMaterial.new()
	mc.shader = CEU
	mc.set_shader_parameter("topo", Color(tema.ceu[0]))
	mc.set_shader_parameter("horizonte", Color(tema.ceu[1]))
	mc.set_shader_parameter("chao", Color(tema.neblina).darkened(0.3))
	mc.set_shader_parameter("cor_sol", Color(tema.sol[0]))
	mc.set_shader_parameter("nuvens", tema.get("nuvens", 0.5))
	mc.set_shader_parameter("semente", float(absi(hash(a.mapa.get("id", ""))) % 97))
	ceu.sky_material = mc
	ceu.radiance_size = Sky.RADIANCE_SIZE_64
	env.sky = ceu
	# ambiente por cor (não pelo céu azul): a sombra fica quente, como na arte
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(tema.get("ambiente", "d9b89c"))
	env.ambient_light_energy = 0.44
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.98
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_strength = 1.0
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.05
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.fog_enabled = true
	env.fog_light_color = Color(tema.neblina)
	env.fog_light_energy = 1.0
	env.fog_sun_scatter = 0.25
	env.fog_density = tema.get("densidade", 0.0026)
	env.fog_sky_affect = 0.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.16
	env.adjustment_contrast = 1.1
	env.adjustment_brightness = 1.0
	var we = WorldEnvironment.new()
	we.environment = env
	a.add_child(we)
	var s: Array = tema.sol
	var sol = DirectionalLight3D.new()
	sol.light_color = Color(s[0])
	sol.light_energy = s[1]
	sol.rotation_degrees = Vector3(s[2], s[3], 0)
	sol.shadow_enabled = true
	sol.add_to_group("valdora_sombras")
	var video = a.get_node_or_null("/root/ValdoraVideo")
	if video != null:
		sol.shadow_enabled = video.sombras
	sol.directional_shadow_max_distance = 70.0
	sol.shadow_blur = 1.6
	sol.shadow_opacity = 0.95
	sol.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_AND_SKY
	a.add_child(sol)
	# contraluz quente e fraco do lado oposto: dá volume sem esfriar a sombra
	var pre = DirectionalLight3D.new()
	pre.light_color = Color("ffc9a0")
	pre.light_energy = 0.22
	pre.rotation_degrees = Vector3(-20, s[3] + 170.0, 0)
	pre.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	a.add_child(pre)
