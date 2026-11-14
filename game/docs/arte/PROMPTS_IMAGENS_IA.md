# Prompts para gerar imagens (MUNDO, nome provisório)

Sessão 1.6, 14/11/2026. Use num gerador de imagens por IA. Os prompts estão em inglês porque a maioria dos geradores responde melhor assim; a explicação está em português.

**Antes de gerar, confira:**

- **Uso comercial.** A licença do gerador precisa permitir uso comercial. Leia os termos e anote, para cada imagem, o gerador e a data.
- **Nada de Last War.** Não escreva "Last War", nomes de personagens dele nem "in the style of" outro jogo. O pedido é de **acabamento parecido** (3D estilizado, mobile, premium) com identidade própria. Imagem que lembre demais um personagem ou prédio existente vai para o lixo.
- **Paleta ainda não escolhida.** Os prompts usam a **paleta A**. Para B ou C, troque só a linha `PALETTE`.

---

## 1. Bloco de estilo (cole no começo de todos os prompts)

```
STYLE: premium mobile strategy game art, stylized 3D render, clean hand-painted textures,
soft global illumination, soft ambient occlusion in corners, warm sunlight from the upper left,
gentle rim light, slightly chunky proportions, rounded bevelled edges, high detail but readable
at small size, no text, no logos, no watermark.
PALETTE: slate blue-grey roofs (#4A5D75), copper-orange accents (#D27A35), warm off-white
walls (#E6DCCB), beige concrete (#C3B9A6), olive green (#7F8F4C), brushed steel, small gold details.
```

Paletas alternativas (troque a linha `PALETTE`):

- **B:** `petrol teal roofs (#1F6A72), brick red accents (#C4573E), cream walls (#ECE2CF), beige concrete, sage green, brushed steel, small gold details.`
- **C:** `graphite roofs (#3A3F48), bright orange accents (#EF8A2A), light grey-beige walls (#E9E3D7), concrete, olive green, brushed steel, small gold details.`

## 2. Prédios (vista isométrica, para a cidade)

Formato: **1024 × 1024, fundo transparente** (ou branco liso, que eu recorto). Câmera isométrica a 45°, vista de cima a cerca de 35°. O prédio fica centralizado sobre uma placa de chão quadrada.

```
[STYLE + PALETTE]
SUBJECT: isometric game building, 45 degree isometric view from above, single building centered
on a square concrete base tile, transparent background.
BUILDING: <descrição abaixo>
```

Trocar `<descrição>` conforme o prédio. Cada prédio tem 6 faixas; comece pela faixa 4 de cada um, para fixar o estilo:

| Prédio | Faixa 4 (descrição em inglês) |
|---|---|
| Prefeitura | `modern city hall, 6-storey tower of glass and steel with slate roof trim, wide entrance with columns, flagpole, small helipad on the roof, plaza with planters` |
| Banco da cidade | `city bank, marble podium with gold columns, dark glass tower, large round vault door visible at the entrance, gold coin emblem on the roof` |
| Centro tecnológico | `research center, glass tower with visible laboratories, rooftop antenna and satellite dish, server cabinets with glowing lights, small hologram screen` |
| Alojamento | `military residential barracks, three-storey building with balconies, copper awnings, laundry lines, small courtyard` |
| Estufa | `hydroponic greenhouse, steel frame and glass panels, rows of green crops inside, water tanks, irrigation pipes` |
| Usina de materiais | `construction materials plant, brick building with conveyor belt, stacks of lumber and steel beams, small crane, chimney with light smoke` |
| Mineradora | `metal mine, open pit with ore carts on rails, drill tower, heavy excavator, piles of ore` |
| Central de energia | `power station, solar panels, two wind turbines, transformer yard with glowing cyan cables` |
| Radar e antena | `radar station, rotating radar dish on a tower, satellite antennas, control bunker` |
| Base militar | `military base, armored vehicles in a garage, training yard, watchtower, sandbags` |
| Entreposto logístico | `logistics depot, stacked shipping containers, forklift, loading dock with trucks` |
| Parque | `city park, fountain, trees, benches, flower beds, paved paths` |
| Estação de água | `water treatment station, round water tower, clarifier tanks, pipes and pumps` |
| Heliponto | `helipad with a parked transport helicopter, landing lights, small control tower, fuel tanks` |
| Via | `road tile with crosswalk, street lamps, small traffic island` |

Para as outras faixas, troque a descrição pela da faixa, em `game/data/mundo_componentes_v0.3.json` (campo `visual_faixas`). Os nomes das faixas são: 1 acampamento, 2 pré-fabricado, 3 concreto, 4 vidro e aço, 5 tecnológico, 6 elite (dourado e neon).

## 3. Cenário da base (fundo do jogo, retrato)

Formato: **1080 × 2340** (retrato).

```
[STYLE + PALETTE]
SUBJECT: top-down isometric view of an empty military-civil base area for a mobile strategy game,
portrait composition, large beige concrete yard with painted lines, chain-link fence with copper
trim around the yard, railway crossing diagonally in the background, olive grass fields with
dirt patches, scattered trees and rocks around the edges, a few storage tanks along the fence,
no buildings inside the yard, no people, no text.
```

## 4. Heróis (retrato de cartão)

Formato: **1024 × 1024**, fundo liso numa cor só (ele é trocado pela cor da raridade no jogo). Personagens **originais**, com nomes provisórios (os nomes finais estão pendentes com o dono).

```
[STYLE]
SUBJECT: original character portrait for a mobile strategy game hero card, stylized semi-realistic
3D cartoon style, expressive face, confident pose, from the waist up, three-quarter view,
plain flat background, no text, no logos.
CHARACTER: <descrição abaixo>
```

| Provisório | CHARACTER |
|---|---|
| Engenheira | `brazilian woman in her 30s, short curly dark hair, safety goggles on forehead, orange work jacket with tool belt, holding a tablet, smart and determined` |
| Comandante | `veteran male commander in his 50s, grey beard, slate-blue officer coat with copper insignia, binoculars around the neck, calm and strong` |
| Piloto | `young female helicopter pilot, ponytail, aviator headset, olive flight suit with patches, cheerful grin` |
| Atirador | `male sniper, lean, camouflage hood, scarf over the neck, long rifle on the back, serious eyes` |
| Médica | `female field medic, braided hair, white and teal uniform with medical cross armband, first-aid bag, kind expression` |
| Mecânico | `big friendly male mechanic, shaved head, thick mustache, oil-stained overalls, giant wrench on the shoulder` |

Regras de identidade dos heróis: diversidade brasileira (tons de pele, cabelos, idades), roupas modernas e funcionais. Nada de uniforme real de forças armadas, polícia ou bandeiras.

## 5. Ícones da interface

Formato: **512 × 512**, fundo transparente.

```
[STYLE + PALETTE]
SUBJECT: glossy mobile game icon, single object centered, soft shadow underneath, transparent
background, no text.
OBJECT: <objeto>
```

Objetos: `stack of steel ingots` (metal), `basket of fresh vegetables` (alimentos), `pile of bricks and planks` (materiais), `glowing battery cell` (energia), `gold coin with a star` (moeda), `hammer and wrench crossed` (obras), `research flask with gears` (pesquisa), `shield with a star` (aliança).

## 6. Como me entregar

1. Salvar em PNG, com o nome no padrão `predio_banco_f4.png`, `heroi_engenheira.png`, `icone_metal.png` ou `cenario_base.png`.
2. Anotar o gerador e a data de cada imagem (licença).
3. Mandar aqui na conversa, ou colocar em `game/assets/arte_ia/` na branch de trabalho. Eu integro no jogo, recorto o fundo e ajusto o tamanho e a escala.
