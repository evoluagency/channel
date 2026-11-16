# Valdora PvP: referências do dono para heróis e armas (16/11/2026)

As imagens estão em `imagens/referencia_1.8/`. Este arquivo registra o que elas pedem e o caminho de produção de cada parte. Junto com `referencia_1.7/` (telas do jogo), é o alvo visual do jogo.

## 1. Heróis (`herois_corpo.jpg`, `herois_retratos.jpg`)

São 11 heróis de corpo inteiro e 10 retratos, num estilo de desenho animado 3D. Os traços em comum:

- proporção heroica;
- colete tático com bolsos;
- joelheiras e coturnos;
- luvas;
- emblema da origem no ombro.

| # | Origem sugerida pela arte | Traço marcante |
|---|---|---|
| 1 | Estados Unidos | camisa azul-marinho, fuzil, fone |
| 2 | China | traje vermelho com dragão dourado, coque com hashi |
| 3 | Arábia | lenço vermelho e branco, uniforme cáqui |
| 4 | África | tranças com anéis dourados, colares, regata verde |
| 5 | Índia | turbante azul, cachecol amarelo, emblema da roda |
| 6 | México | vestido bordado com flores, flor no cabelo |
| 7 | Rússia | gorro de pele com estrela, camuflagem de inverno |
| 8 | Japão | armadura vermelha de samurai, katana |
| 9 | Europa | aviadora com óculos, jaqueta de pele, emblema da UE |
| 10 | Povo indígena | cocar de penas, pintura no rosto, colar de dentes |
| 11 | Brasil (a confirmar) | macacão preto e amarelo, óculos na testa |

Antes de publicar, rever com cuidado os trajes étnicos e religiosos:

- cocar indígena;
- turbante sikh;
- lenço árabe.

Esses trajes costumam gerar reclamações de estereótipo nas lojas e nas redes. Recomendo tratar cada um como homenagem, com nome próprio, história e consulta, e não como "fantasia".

## 2. Armas (`armas_30.jpg`): tema **paintball**

São 30 armas que disparam tinta, com respingos coloridos. Os nomes vêm da arte:

| Grupo | Itens |
|---|---|
| Marcadores | 01 assalto, 02 precisão, 03 submetralhadora, 04 escopeta, 05 pesado (LMG), 06 pistola, 07 pistolas duplas, 08 revólver |
| Arremesso e projétil | 09 balestra, 10 arco, 11 lançador (RPG), 12 lançador de granadas, 13 minigun |
| Granadas e armadilhas | 14 tinta, 15 fumaça colorida, 16 luz (flash), 17 adesiva, 18 mina |
| Corpo a corpo e defesa | 19 escudo tático, 20 taco, 21 marreta, 22 faca, 23 machete, 24 machado |
| Especiais | 25 estrela, 26 bumerangue, 27 dardos, 28 drone de pintura, 29 torreta sentinela, 30 lança-tinta (área) |

## 3. Aparências do marcador (`marcador_aparencias_30.jpg`)

São 30 pinturas do mesmo marcador de assalto: camuflagens, chamas, raio, caveira, coração, estrela, dourado real, ghillie, entre outras. Todas têm o funil de tinta (hopper) em cima.

## 4. O que isso muda no jogo

- **Tiro vira paintball:** projétil de tinta com respingo colorido na parede, no chão e no adversário, em vez de bala. Fica mais leve para classificação etária e combina com o visual de desenho animado.
- **Arma em primeira pessoa:** passa a ser o marcador com hopper. O código atual monta a arma com caixas e ainda não segue esta arte.
- **Loja e inventário:** as 30 aparências viram itens cosméticos. O padrão de pintura pode ser procedural, com um shader de tinta e respingos por cor, sem 30 texturas pintadas.

## 5. Caminho de produção

| Parte | Por código no Godot | Precisa de modelo 3D |
|---|---|---|
| Respingos de tinta no cenário e no adversário | sim (decal ou malha simples com shader) | não |
| Pinturas do marcador (as 30 aparências) | sim (shader com camuflagem, respingo, faixas, gradiente e cores por aparência) | não |
| Marcador e pistola de vitrine | aceitável em baixo polígono | melhor com modelo |
| Armas de corpo a corpo, granadas, drone, torreta | aceitável em baixo polígono | melhor com modelo |
| 11 heróis | não (o acabamento da arte não sai por código) | sim: imagem para 3D local, ou base CC0 adaptada (ver `PVP_PERSONAGENS_CC0.md`) |

Ordem recomendada:

1. Paintball na jogabilidade: projétil e respingo.
2. Shader de pintura com as 30 aparências.
3. Marcador em primeira pessoa no novo estilo.
4. Interface da arte.
5. Heróis, numa sessão própria, com a geração de imagem para 3D rodando no computador do dono.
