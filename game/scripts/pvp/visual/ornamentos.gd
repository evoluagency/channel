extends RefCounted
## Kit de ornamentos do Valdora PvP (arte conceitual do dono): arcos, cúpulas verde-azuladas,
## estandartes com o V dourado, floreiras com flores, trepadeiras, copas em vários volumes e
## lampiões. Só malha visual, juntada por material no construtor; nunca cria colisão.
## Usado pelos cinco mapas; cada região escolhe onde e quanto usar.

var c          # construtor
var rng: RandomNumberGenerator
var baixa := false   # perfil de vídeo Baixa: menos flores e folhas

func preparar(construtor, gerador: RandomNumberGenerator, qualidade_baixa := false) -> void:
	c = construtor
	rng = gerador
	baixa = qualidade_baixa
	c.sup("orn_folha", 6, Color("3f9a36"), Color("2a6e2a"), 2.2, 0.0, 0.9)
	c.sup("orn_folha_clara", 6, Color("7cc043"), Color("4f9a34"), 2.2, 0.0, 0.9)
	c.sup("orn_cupula", 2, Color("1f9a92"), Color("167873"), 1.4, 0.05, 0.45, 0.15)
	c.sup("orn_pedra", 2, Color("efe1c6"), Color("d8c6a6"), 1.0, 0.25, 0.8)
	c.liso("orn_flor_branca", Color("fbf6ea"), 0.8)
	c.liso("orn_flor_rosa", Color("f07aa6"), 0.8)
	c.liso("orn_flor_amarela", Color("ffc93a"), 0.8)
	c.liso("orn_estandarte", Color("15867f"), 0.75)
	c.liso("orn_ouro", Color("f0b93a"), 0.3, 0.7)
	c.liso("orn_sombra", Color("2a201b"), 0.95)
	c.liso("orn_lanterna", Color("ffd27a"), 0.4, 0.0, 2.2)

# ---------------------------------------------------------------- arquitetura

## Arcada na face de um prédio: n arcos com pilastras e fundo escuro (falso vão).
## p0 = ponto da face no chão, fora = normal, ao = direção ao longo da face.
func arcada(p0: Vector3, fora: Vector3, ao: Vector3, comp: float, alt: float, pedra := "orn_pedra") -> void:
	var rot := atan2(fora.x, fora.z)
	var n := maxi(1, int(comp / 3.2))
	var passo := comp / n
	var r := passo * 0.36
	var imposta := alt - r - 0.3
	for i in n:
		var centro := p0 + ao * ((i + 0.5) * passo - comp * 0.5)
		c.caixa(centro + fora * 0.05, Vector3(r * 2.0, imposta, 0.04), "orn_sombra", rot)
		c.meio_disco(centro + fora * 0.075 + Vector3(0, imposta, 0), r, "orn_sombra", rot, 6)
		c.arco(centro + fora * 0.16 + Vector3(0, imposta, 0), r, r + 0.32, 0.3, pedra, rot, 7)
		c.caixa(centro + fora * 0.18 + Vector3(0, imposta + r + 0.12, 0), Vector3(0.34, 0.42, 0.34), pedra, rot)  # aduela-chave
		for s in [-1, 1]:
			c.caixa(centro + ao * s * (r + 0.16) + fora * 0.16, Vector3(0.36, imposta, 0.32), pedra, rot)
	c.caixa(p0 + fora * 0.2 + Vector3(0, alt - 0.1, 0), Vector3(comp, 0.28, 0.4), pedra, rot)            # friso sobre a arcada

## Cornija com dentículos na borda do telhado.
func cornija(centro: Vector3, sx: float, sz: float, alt: float, pedra := "orn_pedra") -> void:
	c.caixa(centro + Vector3(0, alt - 0.35, 0), Vector3(sx + 0.3, 0.2, sz + 0.3), pedra)
	c.caixa(centro + Vector3(0, alt - 0.15, 0), Vector3(sx + 0.55, 0.3, sz + 0.55), pedra)

## Balaustrada sobre a cobertura (poucos balaústres por metro, cabe no celular).
func balaustrada(centro: Vector3, sx: float, sz: float, alt: float, pedra := "orn_pedra") -> void:
	for lado in [[Vector3(0, 0, -sz * 0.5), Vector3(1, 0, 0), sx], [Vector3(0, 0, sz * 0.5), Vector3(1, 0, 0), sx],
			[Vector3(-sx * 0.5, 0, 0), Vector3(0, 0, 1), sz], [Vector3(sx * 0.5, 0, 0), Vector3(0, 0, 1), sz]]:
		var base: Vector3 = centro + lado[0] + Vector3(0, alt, 0)
		var comp: float = lado[2]
		var n := int(comp / 0.7)
		for i in n:
			c.cilindro(base + lado[1] * ((i + 0.5) * comp / n - comp * 0.5), 0.09, 0.7, pedra, 5, 0.06)
		var rot := 0.0 if lado[1].x > 0.5 else PI * 0.5
		c.caixa(base + Vector3(0, 0.7, 0), Vector3(comp + 0.2, 0.14, 0.3), pedra, rot)

## Cúpula verde-azulada sobre tambor, com nervuras douradas e pináculo.
func cupula(base: Vector3, raio: float, tambor := 1.0, pedra := "orn_pedra") -> void:
	c.cilindro(base, raio * 1.05, tambor, pedra, 12)
	c.cilindro(base + Vector3(0, tambor, 0), raio * 1.12, 0.18, pedra, 12)
	c.esfera(base + Vector3(0, tambor + 0.18, 0), Vector3(raio, raio * 1.1, raio), "orn_cupula", 12, 8, true)
	for i in 6:
		var ang := TAU * i / 6.0
		c.caixa(base + Vector3(cos(ang), 0, sin(ang)) * raio * 0.72 + Vector3(0, tambor + 0.18 + raio * 0.55, 0), Vector3(0.08, raio * 0.6, 0.08), "orn_ouro", -ang)
	var topo := base + Vector3(0, tambor + 0.18 + raio * 1.1, 0)
	c.cilindro(topo, raio * 0.12, raio * 0.35, "orn_ouro", 6)
	c.esfera(topo + Vector3(0, raio * 0.42, 0), Vector3.ONE * raio * 0.13, "orn_ouro", 6, 4)

# ---------------------------------------------------------------- identidade Valdora

## Estandarte verde-azulado com ponta em V e emblema dourado. p = pé, fora = para onde olha.
func estandarte(p: Vector3, fora: Vector3, alt := 3.9, larg := 0.95) -> void:
	var rot := atan2(fora.x, fora.z)
	var ao := Vector3(fora.z, 0, -fora.x)
	var topo := p + Vector3(0, alt, 0)
	c.caixa(topo + fora * 0.02, Vector3(larg + 0.3, 0.07, 0.07), "orn_ouro", rot)
	for s in [-1, 1]:
		c.esfera(topo + ao * s * (larg * 0.5 + 0.16) + Vector3(0, 0.03, 0), Vector3.ONE * 0.07, "orn_ouro", 5, 3)
	var corpo := larg * 1.7
	c.caixa(topo + Vector3(0, -corpo - 0.04, 0), Vector3(larg, corpo, 0.04), "orn_estandarte", rot)
	# ponta em V: duas abas inclinadas
	for s in [-1, 1]:
		c.caixa(topo + ao * s * larg * 0.25 + Vector3(0, -corpo - 0.32, 0), Vector3(larg * 0.5, 0.42, 0.035), "orn_estandarte", rot)
	c.caixa(topo + fora * 0.03 + Vector3(0, -corpo - 0.06, 0), Vector3(larg, 0.06, 0.04), "orn_ouro", rot)
	# emblema: V de duas hastes douradas
	var e := topo + fora * 0.035 + Vector3(0, -corpo * 0.52, 0)
	for s in [-1, 1]:
		var b := Basis(Vector3.UP, rot) * Basis(Vector3(0, 0, 1), -s * 0.42)
		var t := Transform3D(b, e + ao * s * larg * 0.13)
		_caixa_t(t, Vector3(0.11, larg * 0.55, 0.03), "orn_ouro")

func _caixa_t(t: Transform3D, tam: Vector3, chave: String) -> void:
	# caixa inclinada: usa a base do construtor girando os cantos à mão
	var h := tam * 0.5
	var p := func(x: float, y: float, z: float) -> Vector3: return t * Vector3(x * h.x, y * h.y, z * h.z)
	var st: SurfaceTool = c._s(chave)
	c._quad(st, p.call(-1, -1, 1), p.call(1, -1, 1), p.call(1, 1, 1), p.call(-1, 1, 1))
	c._quad(st, p.call(1, -1, -1), p.call(-1, -1, -1), p.call(-1, 1, -1), p.call(1, 1, -1))

## Lampião de ferro com lanterna acesa (brilha com o glow).
func lampiao(p: Vector3, alt := 3.4) -> void:
	c.cilindro(p, 0.16, 0.35, "ferro", 6, 0.1)
	c.cilindro(p + Vector3(0, 0.35, 0), 0.07, alt - 0.35, "ferro", 6, 0.05)
	c.caixa(p + Vector3(0, alt, 0), Vector3(0.36, 0.05, 0.36), "ferro")
	c.caixa(p + Vector3(0, alt + 0.05, 0), Vector3(0.26, 0.42, 0.26), "orn_lanterna")
	c.cilindro(p + Vector3(0, alt + 0.47, 0), 0.26, 0.22, "ferro", 4, 0.02)

# ---------------------------------------------------------------- vegetação

## Tufo de flores sobre uma superfície (centro, raio). Flores = pequenos octaedros.
func flores(centro: Vector3, raio: float, n := 8, cores := ["orn_flor_branca", "orn_flor_branca", "orn_flor_rosa", "orn_flor_amarela"]) -> void:
	if baixa:
		n = maxi(2, n / 2)
	for i in n:
		var ang := rng.randf() * TAU
		var d := sqrt(rng.randf()) * raio
		var f := centro + Vector3(cos(ang) * d, rng.randf_range(0.0, 0.12), sin(ang) * d)
		c.esfera(f, Vector3(0.13, 0.08, 0.13), cores[rng.randi_range(0, cores.size() - 1)], 4, 2)

## Moita arredondada em dois tons, com flores por cima.
func moita(centro: Vector3, raio: float, com_flores := true) -> void:
	c.esfera(centro, Vector3(raio, raio * 0.7, raio), "orn_folha", 7, 4)
	c.esfera(centro + Vector3(raio * 0.35, raio * 0.25, -raio * 0.2), Vector3(raio, raio * 0.6, raio) * 0.7, "orn_folha_clara", 6, 4)
	if com_flores:
		flores(centro + Vector3(0, raio * 0.55, 0), raio * 0.8, int(4 + raio * 6))

## Floreira de pedra creme com borda, terra coberta de folhas e flores.
func floreira(p: Vector3, tam: Vector2, rot := 0.0, alt := 0.75, pedra := "orn_pedra") -> void:
	c.caixa(p, Vector3(tam.x, alt, tam.y), pedra, rot)
	c.caixa(p + Vector3(0, alt, 0), Vector3(tam.x + 0.16, 0.1, tam.y + 0.16), pedra, rot)
	var bs := Basis(Vector3.UP, rot)
	var n := maxi(1, int(maxf(tam.x, tam.y) / 1.1))
	for i in n:
		var t := (i + 0.5) / n - 0.5
		var off := bs * (Vector3(t * tam.x, 0, 0) if tam.x >= tam.y else Vector3(0, 0, t * tam.y))
		moita(p + off + Vector3(0, alt + 0.2, 0), minf(tam.x, tam.y) * 0.5)

## Trepadeira pendurada da cornija e descendo pela parede: massa contínua de folhas
## achatadas contra a face, mais larga no alto, com cachos soltos e algumas flores.
func trepadeira(topo: Vector3, fora: Vector3, ao: Vector3, queda: float, largura := 1.6) -> void:
	var passo := 0.55
	var linhas := int(queda / passo) + 1
	for k in linhas:
		var v := k * passo
		var frac := v / queda
		var larg_k := largura * (1.0 - frac * 0.7) * rng.randf_range(0.8, 1.1)
		var n := maxi(1, int(larg_k / 0.5)) if not baixa else maxi(1, int(larg_k / 0.8))
		var desvio := sin(k * 1.3 + rng.randf() * 2.0) * 0.25
		for i in n:
			var u := ((i + 0.5) / n - 0.5) * larg_k + desvio
			var p := topo + ao * u - Vector3(0, v, 0) + fora * 0.16
			var s := rng.randf_range(0.36, 0.5) * (1.0 - frac * 0.3)
			c.esfera(p, Vector3(s, s * 0.85, s * 0.45), "orn_folha" if (i + k) % 3 != 0 else "orn_folha_clara", 6, 4)
	# cachos que pendem mais
	for i in 2:
		var u := rng.randf_range(-0.4, 0.4) * largura
		c.esfera(topo + ao * u - Vector3(0, queda + 0.3, 0) + fora * 0.16, Vector3(0.28, 0.4, 0.22), "orn_folha", 6, 4)
	if rng.randf() < 0.7:
		flores(topo - Vector3(0, queda * 0.25, 0) + fora * 0.38, largura * 0.35, 4)

## Árvore de copa cheia em vários volumes (cartoon), em dois verdes.
func arvore(p: Vector3, e := 1.0, folha := "orn_folha") -> void:
	c.cilindro(p, 0.2 * e, 2.6 * e, "tronco", 7, 0.12 * e)
	for g in [[Vector3(0.0, 1.9, 0.0), 0.32, Vector3(0.0, 1.0, 0.0)], [Vector3(0.6, 1.8, 0.2), 0.12, Vector3(0.55, 0.6, 0.2)]]:
		c.cilindro(p + g[0] * e - Vector3(0, 0.6 * e, 0), g[1] * e * 0.5, 1.0 * e, "tronco", 5, 0.04 * e)
	var copas := [
		[Vector3(0, 3.6, 0), 1.6], [Vector3(1.0, 3.2, 0.4), 1.1], [Vector3(-0.9, 3.3, -0.3), 1.15],
		[Vector3(0.2, 4.4, -0.5), 1.05], [Vector3(-0.3, 3.0, 0.9), 0.95],
	]
	if baixa:
		copas = copas.slice(0, 3)
	for k in copas.size():
		var q: Array = copas[k]
		var chave := folha if k % 2 == 0 else "orn_folha_clara"
		c.esfera(p + (q[0] as Vector3) * e, Vector3(1.0, 0.82, 1.0) * float(q[1]) * e, chave, 8, 5)
