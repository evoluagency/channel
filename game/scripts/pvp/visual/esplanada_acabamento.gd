extends RefCounted
## Esplanada: camada artística original inspirada no modernismo de Brasília.
## Somente malhas visuais, SEM nós físicos, alterações da grade ou colisões.
## Os materiais são unificados pelo construtor, preservando draw calls no mobile.

var arena
var c
var nivel := 1
var elementos := 0
var fachadas := 0
var coberturas := 0

func preparar(a, construtor) -> void:
	arena = a
	c = construtor
	var video = a.get_node_or_null("/root/ValdoraVideo")
	if video != null:
		match str(video.qualidade):
			"Baixa": nivel = 0
			"Alta": nivel = 2
			_: nivel = 1
	_materiais()

func _materiais() -> void:
	c.sup("esp_piso", 0, Color("d7d5ca"), Color("b9b6aa"), 0.68, 0.08, 0.88)
	c.sup("esp_piso_claro", 3, Color("e5e1d5"), Color("d3cec0"), 0.55, 0.06, 0.86)
	c.sup("esp_pedra", 3, Color("f0ece2"), Color("dad7ca"), 0.42, 0.09, 0.75)
	c.sup("esp_concreto", 3, Color("b8bdbb"), Color("989d9c"), 0.65, 0.14, 0.78)
	c.liso("esp_vidro", Color("5b91a7"), 0.19, 0.22)
	c.liso("esp_vidro_escuro", Color("2d576e"), 0.26, 0.12)
	c.liso("esp_brise", Color("e5e5d9"), 0.62, 0.04)
	c.liso("esp_metal", Color("596d76"), 0.42, 0.34)
	c.liso("esp_detalhe", Color("bba982"), 0.72)
	c.liso("esp_terra", Color("766653"), 0.92)
	c.sup("esp_folhagem", 6, Color("4f8e54"), Color("2f6845"), 1.6, 0.08)
	c.sup("esp_flor", 6, Color("d98d68"), Color("ae594b"), 1.4, 0.05)
	c.agua("esp_espelho", Color("78c6c8"), Color("397589"))

func _caixa(pos: Vector3, tamanho: Vector3, material: String, rot := 0.0) -> void:
	c.caixa(pos, tamanho, material, rot)
	elementos += 1

func _esfera(pos: Vector3, raio: Vector3, material: String, segmentos := 8, aneis := 5) -> void:
	c.esfera(pos, raio, material, segmentos, aneis)
	elementos += 1

## Paginação visual do chão. Não cobre marcações A, B, rotas ou spawn.
## O traçado lógico das 5 arenas permanece idêntico.
func pisos() -> void:
	for y in arena.altura:
		for x in arena.largura:
			if arena.letra(x, y) != ".":
				continue
			var p: Vector3 = arena.celula_mundo(x, y)
			var alternado := (x + y) % 6 == 0
			var chave := "esp_piso_claro" if alternado else "esp_piso"
			c.plano(p + Vector3(0, 0.006, 0), Vector2(2.94, 2.94), chave)
			elementos += 1
			# Juntas discretas, ritmadas, sem decalque de alta frequência.
			if (x * 3 + y) % 9 == 0:
				c.plano(p + Vector3(0, 0.009, 0), Vector2(2.60, 0.035), "esp_detalhe")
				elementos += 1

## Conjunto de brises, fachadas envidraçadas e marquises.
## Chamado exclusivamente sobre retângulos de parede '#', acima da altura
## de circulação; nenhuma peça altera os limites de passagem dos jogadores.
func fachada(centro: Vector3, sx: float, sz: float, altura: float, faces: Array, borda: bool) -> void:
	if borda or sx * sz < 12.0:
		return
	var num_fachadas := 0
	for lado in faces:
		var fora: Vector3 = {
			"n": Vector3(0, 0, -1), "s": Vector3(0, 0, 1),
			"o": Vector3(-1, 0, 0), "l": Vector3(1, 0, 0)
		}[lado]
		var ao: Vector3 = Vector3(1, 0, 0) if lado in ["n", "s"] else Vector3(0, 0, 1)
		var comp: float = sx if lado in ["n", "s"] else sz
		var prof: float = sz if lado in ["n", "s"] else sx
		if comp < 5.0:
			continue
		var rot := atan2(fora.x, fora.z)
		var face: Vector3 = centro + fora * (prof * 0.5)
		var faixa_h: float = maxf(1.0, altura - 3.85)
		# Caixa de vidro mais profunda que a fachada-base da arena.
		_caixa(face + fora * 0.14 + Vector3(0, 3.15, 0),
			Vector3(comp - 0.65, faixa_h, 0.06), "esp_vidro_escuro", rot)
		_caixa(face + fora * 0.18 + Vector3(0, 3.18, 0),
			Vector3(comp - 1.0, 0.12, 0.14), "esp_metal", rot)
		# Marquise em concreto claro, apoiada em parede já não atravessável.
		_caixa(face + fora * 0.22 + Vector3(0, 2.75, 0),
			Vector3(comp - 0.40, 0.19, 0.76), "esp_pedra", rot)
		var divisoes: int = maxi(2, mini(14, int(comp / 2.15)))
		var visiveis: int = divisoes if nivel >= 1 else maxi(2, int(float(divisoes) / 2.0))
		for j in visiveis:
			var q: float = (float(j) + 0.5) / float(visiveis) - 0.5
			var pos: Vector3 = face + ao * q * (comp - 0.85)
			_caixa(pos + fora * 0.35 + Vector3(0, 3.16, 0),
				Vector3(0.12, faixa_h + 0.18, 0.58), "esp_brise", rot)
			if nivel == 2:
				_caixa(pos + fora * 0.37 + Vector3(0, altura - 0.5, 0),
					Vector3(0.12, 0.10, 0.6), "esp_metal", rot)
		# Peitoris e sombra de borda: distinção entre volumes.
		_caixa(face + fora * 0.28 + Vector3(0, altura - 0.55, 0),
			Vector3(comp - 0.35, 0.18, 0.42), "esp_concreto", rot)
		num_fachadas += 1
	# Elementos discretos na cobertura; apenas se ao menos uma face foi exposta.
	if num_fachadas > 0:
		_caixa(centro + Vector3(0, altura + 0.47, 0),
			Vector3(sx + 0.15, 0.10, sz + 0.15), "esp_pedra")
		if nivel >= 1 and sx >= 6.0 and sz >= 5.0:
			_caixa(centro + Vector3(0, altura + 0.57, 0),
				Vector3(sx * 0.45, 0.34, sz * 0.35), "esp_metal")
		fachadas += num_fachadas

## Floreiras e quiosques com volumes secundários: todo detalhe se apoia
## em células 'c', que JÁ possuíam colisão e cobertura definida no mapa.
func mobiliario() -> void:
	for y in arena.altura:
		for x in arena.largura:
			if arena.letra(x, y) != "c":
				continue
			var p: Vector3 = arena.celula_mundo(x, y)
			if arena.cobertura_alta(x, y):
				# Quiosque: sobrecobertura, painéis e moldura metálica.
				_caixa(p + Vector3(0, 2.39, 0), Vector3(2.84, 0.14, 2.84), "esp_pedra")
				_caixa(p + Vector3(0, 2.56, 0), Vector3(2.60, 0.08, 2.60), "esp_metal")
				for s in [-1, 1]:
					_caixa(p + Vector3(s * 1.14, 1.0, 1.20),
						Vector3(0.07, 1.48, 0.06), "esp_brise")
					_caixa(p + Vector3(s * 1.14, 1.0, -1.20),
						Vector3(0.07, 1.48, 0.06), "esp_brise")
				if nivel >= 1:
					for s in [-1, 1]:
						_caixa(p + Vector3(s * 1.2, 1.15, 0),
							Vector3(0.05, 0.88, 1.95), "esp_vidro")
			else:
				# Canteiro volumétrico: borda, camada de terra e folhagem irregular.
				_caixa(p + Vector3(0, 0.96, 0), Vector3(2.70, 0.15, 2.70), "esp_pedra")
				_caixa(p + Vector3(0, 1.10, 0), Vector3(2.40, 0.05, 2.40), "esp_terra")
				if nivel >= 1:
					for k in 4:
						var ang: float = float(k) * TAU / 4.0 + 0.45
						var origem := p + Vector3(cos(ang) * 0.72, 1.34 + float(k % 2) * 0.20, sin(ang) * 0.72)
						_esfera(origem, Vector3(0.56, 0.43, 0.62),
							"esp_flor" if (x + y + k) % 7 == 0 else "esp_folhagem",
							8 if nivel == 2 else 6, 5 if nivel == 2 else 4)
			coberturas += 1

## Paisagem de contemplação do lado de fora do limite jogável.
## Não acrescentar água/árvores como obstáculos em rotas ou pontos de bomba.
func entorno() -> void:
	var w: float = float(arena.largura) * arena.CELULA
	var h: float = float(arena.altura) * arena.CELULA
	var z: float = -h * 0.5 - 18.0
	# Espelho d'água com guias finas e dois platôs laterais externos.
	c.plano(Vector3(0, 0.08, z), Vector2(26.0, 8.0), "esp_espelho")
	elementos += 1
	for lateral in [-1, 1]:
		_caixa(Vector3(0, 0, z + lateral * 4.0),
			Vector3(26.5, 0.20, 0.25), "esp_pedra")
		_caixa(Vector3(lateral * 12.8, 0, z),
			Vector3(0.25, 0.20, 8.0), "esp_pedra")
	# Colunata modernista autoral com curvas reais; situada após a
	# lâmina d'água e fora da grade jogável, sem colisão ou bloqueio de rota.
	var z_colunas: float = -h * 0.5 - 30.0
	var qtd_colunas: int = 7 if nivel == 0 else 9
	for k in qtd_colunas:
		var t: float = float(k) / float(qtd_colunas - 1)
		var x: float = lerpf(-27.0, 27.0, t)
		var desvio := Vector3((t - 0.5) * 2.2, 0, -1.15)
		c.coluna_curva(Vector3(x, 0, z_colunas), 14.0, desvio,
			0.75, 0.95, "esp_pedra", 6 if nivel == 0 else 10)
		elementos += 1
	_caixa(Vector3(0, 13.90, z_colunas - 1.15),
		Vector3(58.5, 0.40, 3.3), "esp_pedra")
	_caixa(Vector3(0, 13.60, z_colunas - 1.15),
		Vector3(55.0, 0.12, 3.1), "esp_metal")
	# Árvores do cerrado com copas segmentadas, fora dos muros.
	for lado in [-1, 1]:
		for k in 6:
			var tx: float = float(lado) * (w * 0.5 + 9.0 + float(k % 2) * 3.2)
			var tz: float = -h * 0.5 + 3.0 + float(k) * 14.5
			_arvore_cerrado(Vector3(tx, 0, tz), k, lado)
	# Torres ao fundo: caixilhos verticais e marquise de coroamento;
	# são detalhes do skyline preexistente, não novos prédios.
	var torre_z: float = -h * 0.5 - 55.0
	for s in [-1, 1]:
		for faixa in 5:
			var cx: float = float(s) * 4.0 - 2.35 + float(faixa) * 1.16
			_caixa(Vector3(cx, 1.5, torre_z + 2.12),
				Vector3(0.09, 31.0, 0.12), "esp_brise")
		_caixa(Vector3(float(s) * 4.0, 34.0, torre_z),
			Vector3(6.45, 0.28, 4.35), "esp_pedra")

func _arvore_cerrado(p: Vector3, indice: int, lado: int) -> void:
	var escala: float = 1.0 + 0.14 * float(indice % 3)
	c.cilindro(p, 0.17 * escala, 2.9 * escala, "esp_terra", 8, 0.11 * escala)
	elementos += 1
	var copa := p + Vector3(0, 3.5 * escala, 0)
	var j := 1 if nivel == 0 else 3
	for k in j:
		var off: float = (float(k) - float(j - 1) * 0.5) * 0.72 * escala
		_esfera(copa + Vector3(off, 0.18 * float(k % 2), float(lado) * off * 0.35),
			Vector3(1.65, 1.05, 1.5) * escala,
			"esp_folhagem", 8 if nivel == 0 else 10, 5 if nivel == 0 else 7)
