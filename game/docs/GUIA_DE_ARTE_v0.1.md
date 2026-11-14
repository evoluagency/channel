# MUNDO — Guia de arte (v0.1)

Escrito na sessão 1.2 (13/11/2026). Consolida o visual das 13 construções em seis faixas; a sessão 1.6 acrescentou o Banco da cidade e o Centro tecnológico (15 no total) e trocou o Quartel-general pela Prefeitura. Nome do jogo provisório. As referências comerciais (Last War e parecidos) guiam o nível de acabamento; **nenhuma arte, personagem, nome ou logotipo é copiado**.

Imagens: `game/docs/imagens/componentes/` (uma folha de faixas e uma de detalhe com alianças por construção, mais `catalogo_15_construcoes.png`). Gerador: `tools/arte3d/` (ver `LEIAME.md`).

## 1. Método

- **3D de baixo polígono modelado por código no Godot 4.7.2**, sem modelos externos. Cada construção é uma receita em GDScript (`tools/arte3d/construcoes/<nome>.gd`) montada com as peças do `kit.gd`. A mesma receita serve para a cidade 3D (sessão 1.5).
- **Por que não kits CC0 (Kenney)**: cobrem um estilo e um tamanho fixos, não seis faixas por prédio, e o site deles está bloqueado na rede das sessões. O protótipo antigo (`cidade_cena_viva.png`) continua como referência de clima.
- **Renderizador**: GL Compatibility, o mesmo do celular. O que se vê nas folhas é o que o aparelho consegue mostrar, sem truques de PC.
- **Câmera**: ortográfica, 33° de inclinação e 45° de giro. Faces visíveis: frente (+Z) e lado direito (+X). Tudo o que importa fica nessas faces.

## 2. Formas

- **Lote** de 5,4 × 5,4 unidades com laje verde e piso que muda por faixa: terra (1), calçada (2 a 5), piso na cor da aliança escurecida (6).
- **Bisel** em toda caixa (0,02 a 0,1): quinas chanfradas dão o ar de brinquedo e pegam luz.
- **Silhueta muda a cada faixa**, nunca só a cor. Regra prática: faixa 1 é baixa e espalhada; faixas 3 e 4 ganham altura; a 5 ganha peças técnicas (painéis, drones, tubos); a 6 ganha coroa, dourado e efeito.
- **Altura máxima** perto de 9 unidades (Prefeitura faixa 6) para caber na mesma escala; a cidade usa a mesma escala.
- **Escala humana**: pessoa de cerca de 0,55 unidade; veículo de 1,1 a 1,6.
- **Peças do kit**: caixa chanfrada, cilindro, esfera, cone, toro, arco, túnel, cúpula, janelas, luzes de fachada, contêiner, toldo, bandeira, antena, poste, banco, árvore, pessoa, veículo, helicóptero, blindado, guindaste, turbina, tenda, drone, painel solar, fileira de plantas e selo.

## 3. Paleta

| Uso | Cores (hex) |
|---|---|
| Terreno | grama `7ed957`, laje `4fb83f`, terra `c99b62`, calçada `ddd5c6`, asfalto `4a4f5c` |
| Obra | concreto `e8e1d4` e `b9b0a2`, painel `f4f6fa`, aço `8d9bb0` e `4d586b`, madeira `b07a45` |
| Vidro | claro `6fd0ff`, escuro `2b6fae` (Elite: `234a8f`) |
| Quentes | creme `f5e6c8`, coral `ff7a59`, terracota `d9643a`, tijolo `c25a43`, laranja de segurança `ff8a2a`, amarelo `ffc21a` |
| Efeitos | neon `3ef2ff`, rosa `ff4fd8`, água `37d3f0`, ouro `f0a81c` |

**Cor-assinatura por construção** (para distinguir prédios na cidade cheia):

| Construção | Assinatura |
|---|---|
| Prefeitura | azul e vidro; dourado no topo; letreiro "PREFEITURA" na faixa 3 |
| Alojamento | creme, coral e tijolo |
| Estufa | verde e vidro; roxo na faixa 3 |
| Usina | tijolo, aço e laranja de segurança |
| Mineradora | terra, rocha e amarelo de máquina |
| Central de energia | branco, azul-solar e raio ciano |
| Radar | branco com vermelho de sinalização |
| Base militar | verde-oliva e cáqui |
| Entreposto | contêineres coloridos |
| Via | asfalto e marcação |
| Parque | verde e flores |
| Estação de água | azul-água e branco |
| Heliponto | círculo com "H" |
| Banco da cidade (1.6) | creme-mármore, verde-cédula `1f8a5b` e dourado; moeda e porta de cofre redonda |
| Centro tecnológico (1.6) | branco, grafite `2d3442` e verde-circuito `4fe08a`; telas, racks e anel de pesquisa |

**Cores de aliança**: azul `1f63e8`, vermelha `f0453a`, verde `22b860`, roxa `8e4dff`, amarela `ffb400`. Ver seção 6.

## 4. Luz

- Sol quente (`fff0d8`, energia 1,0) vindo da frente e da esquerda (−50°, −18°): a fachada da frente fica clara e a lateral, sombreada. Sombra suave ligada.
- Luz de preenchimento fria (`bcd7ff`, 0,3), sem sombra. Luz ambiente do céu em 0,4.
- Mapeamento de tons linear, saturação 1,2 e contraste 1,08. Brilho (glow) **desligado**: no renderizador de compatibilidade ele estoura a imagem inteira.
- **Limites do celular, que viram regra:**
  1. Sem reflexo rico. O ouro é "pintado" (cor `f0a81c`, pouco metal), não espelhado.
  2. Emissão acima de cerca de 1,2 perde a cor e vira branco ou ciano. A cor de aliança acesa usa energia de 0,9 a 1,1.
  3. Transparência aditiva estoura sobre fundo claro. Holograma, campo de energia e água usam mistura normal (`feixe(..., aditivo = false)`). O aditivo fica só para feixe de luz e anel fino.

## 5. Selo de nível

- Hexágono acima do prédio, sempre virado para a câmera. Número em Montserrat peso 800, branco com contorno.
- Fundo azul-noite `1d2a44` com borda branca nas faixas 1 a 5; **dourado** na faixa 6.
- Pontos de 1 a 5 embaixo do número (nível dentro da faixa). As folhas mostram o primeiro nível de cada faixa, com um ponto.

## 6. Aliança e Elite

- A cor da aliança aparece **em todas as faixas** num elemento de frente ou de topo: bandeira, faixa entre andares, toldo, platibanda, varanda, portão, anel do heliponto, neon da faixa 6. Regra mínima conferida nas folhas: a aliança precisa ser legível na faixa 3 em miniatura.
- **Base comum da Elite (faixa 6)** em todas as construções: piso na cor da aliança escurecida, friso dourado, anel de neon e parede baixa de energia. Mais coroa ou detalhe dourado, neon da aliança e um holograma ou efeito próprio.

## 7. Animações (proposta para a etapa "movimento depois")

Nada disso está implementado. Durações pensadas para o celular.

| Evento | Animação |
|---|---|
| Construir | Lote com andaime e lona; poeira; o prédio sobe da laje com um salto elástico (0,6 s); selo aparece com "pop". |
| Melhorar dentro da faixa | Pulso de escala (1,0 → 1,06 → 1,0), faíscas, novo ponto do selo acende. |
| Mudar de faixa | Nuvem de poeira cobre o prédio, troca de modelo, salto elástico, brilho varrendo a fachada (1,2 s); na faixa 6, o selo vira dourado com partículas. |
| Coletar produção | Ícone do recurso sobe do prédio e voa até a barra do topo. |

**Movimento contínuo por construção**: fumaça (Usina, gerador), pás das turbinas, parabólica girando (Prefeitura faixa 5, Radar), drones em órbita, varredura do radar, chafarizes, anéis do reator, esteiras, rotor do helicóptero, holograma girando, luzes piscando nas antenas, carros na Via.

**Orçamento**: animação por transformação (girar, mover, escalar) e material (emissão pulsando). Sem esqueleto nem física. Partículas pelo `CPUParticles3D`, com no máximo cerca de 30 por prédio.

## 8. Desempenho (medido em 13/11/2026)

| Medida | Faixa |
|---|---|
| Peças (malhas) por construção | de 24 a 210 |
| Triângulos por construção | de 2 mil a 38 mil |

A Estufa e o Parque são os mais pesados, por causa das plantas feitas com esferas.

- Uma cidade com cerca de 40 prédios daria milhares de chamadas de desenho. **Não serve como está para o celular**; a meta é 30 FPS em Samsung e Xiaomi.
- **Obrigatório na sessão 1.5**:
  1. Fundir as peças de cada construção e faixa numa malha só, com uma superfície por material (meta: 10 a 20 chamadas por prédio).
  2. Esferas de planta com menos segmentos.
  3. Materiais compartilhados entre prédios.
  4. Nível de detalhe: sem pessoas, drones e plantas miúdas quando a câmera se afasta.
  5. Exportar `.glb` por construção e faixa, se for mais simples carregar do que gerar no aparelho.

### 8.1 Cidade 3D (sessão 1.6, M8)

Feito o que a lista acima pedia (itens 1 a 4); o item 5 (`.glb`) não foi preciso: montar e fundir a cidade cheia leva cerca de 0,4 s no PC.

- **Fusão** (`tools/arte3d/fusao.gd`): cada construção e faixa vira uma malha com no máximo 5 superfícies, uma por tipo de mistura (opaco, translúcido, feixe, aditivo e sem sombra). Cor, rugosidade, metal e emissão do material do kit passam para atributos de vértice, lidos por 4 shaders compartilhados pela cidade inteira. Conferido pixel a pixel contra as folhas aprovadas: diferença média de 0,0 a 0,02 em 255.
- **Modo cidade do kit**: esferas 10×5 (16×8 nas folhas), cilindros até 16 lados, toros 20×6. As folhas aprovadas não mudam (o modo vem desligado).
- **Nível de detalhe 1** (de longe): sem pessoas, drones, veículos, bancos, plantas miúdas, peças com menos de 0,3 no maior lado e tiras com menos de 0,09; esferas 6×3, cilindros até 8 lados.
- **Instâncias**: uma `MultiMesh` por construção e faixa; o LOD 0 em blocos de 2×2 lotes, para a câmera recortar de perto; de perto a sombra vem da malha do LOD 1.
- **Selos** em 2D numa malha só, por cima da cena; somem quando o lote fica com menos de 45 px.
- Números e cenários: `HANDOFF-1.6.md` e `game/docs/logs/cidade3d/`.

## 9. O que não chega ao nível comercial

- Materiais lisos, sem textura, sujeira ou desgaste; falta pintura à mão nas fachadas.
- Pessoas são bonecos de cilindro e esfera; veículos são blocos.
- Água, fumaça e hologramas são formas transparentes, não efeitos de partícula ou de shader.
- Plantas e árvores são esferas; falta folhagem estilizada.
- Composição: um prédio sozinho sobre fundo liso parece mais pobre que na cidade cheia, com luz de fim de tarde e movimento.

## 10. Lista para artista profissional (sem proposta de gasto)

1. **Heróis** com rosto expressivo (retrato e modelo 3D), poses e animações.
2. **Tropas e personagens animados** (andar, atacar, comemorar).
3. **Logotipo** do jogo, quando o nome for escolhido, e ícone do app.
4. **Ícones de recursos e da interface** em acabamento premium.
5. **Texturas pintadas à mão** para fachadas, telhados e chão.
6. **Efeitos visuais** de alto nível: explosões, fumaça volumétrica, raios, construção.
7. **Som e música** (fora do escopo de arte visual, mas no mesmo nível de exigência).

## 11. Gerar de novo

```bash
GODOT=/caminho/Godot_v4.7.2-stable_linux.x86_64 tools/arte3d/gerar.sh prefeitura "Prefeitura" /tmp/arte/pref
python3 tools/arte3d/catalogo.py game/docs/imagens/componentes/catalogo_15_construcoes.png /tmp/arte/pref /tmp/arte/...
```

Contar peças e triângulos: acrescente `--contar` aos argumentos do `render.gd` (depois de `--`).
