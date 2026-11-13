# Valdora — Direção visual v1

Criada em 13/11/2026 a partir da arte-chave ("Valdora · Primeiro reino de Channel") e do primeiro site do Channel. Vale para o site e para o jogo. A versão ilustrada, com amostras e quadros das telas, está em `docs/direcao-visual/guia-visual.html`. O arquivo de estilo do site é `site/assets/valdora.css` e usa os mesmos nomes de token.

## Essência

- Fantasia medieval de blocos e polígonos simples, em luz de crepúsculo: céu violeta, pedra clara, lanternas quentes.
- Fundo sempre escuro. Violeta é a cor de agir. Ouro só no destaque: moldura do título, ação principal, item em foco.
- Cada herói usa a cor da sua força.
- O jogo Valdora não usa nomes, logos ou ícones do Minecraft. O add-on Channel para Minecraft é um produto separado.

## Cores

| Token | Valor | Uso |
|---|---|---|
| noite | `#0a0f22` | fundo |
| noite-2 | `#10183a` | painéis |
| noite-3 | `#19234d` | painel em foco, toque |
| violeta | `#6a3fd4` (degradê `#8b5cf0` → `#3a1f87`) | ação principal |
| violeta-luz | `#b892ff` | ativo, contornos frios (24% de opacidade) |
| ouro | `#e2b865` (degradê `#f5dc9c` → `#9c7a3a`) | molduras, ícones, rótulos |
| pedra | `#ece6da` | títulos |
| texto | `#e4e1ee` | corpo |
| texto-2 | `#a9a7c2` | apoio |
| campo | `#2f9e4f` | confirmar, instalar, pronto |
| alerta | `#f0a33c` | em andamento |
| erro | `#e35d6a` | falha |
| ferro / névoa / aurora / brasa | `#a7b1c2` / `#7cc3d1` / `#f2a7c8` / `#ff8a4c` | Pietro / Henzo / Giulia / Arthur |

## Tipografia

- **Cinzel** (600 a 800): títulos, logotipo VALDORA, nomes de herói e de cidade.
- **Montserrat** (400 a 700): texto, botões, números, rótulos.
- Ambas com licença OFL. No jogo, entram como TTF dentro do projeto.
- Rótulos em caixa alta com espaçamento de 0,2 a 0,3 em. Números com algarismos tabulares.

## Componentes

| Peça | Regra |
|---|---|
| Botão real | Violeta em degradê, moldura dourada de 2 px, pontas cortadas, altura mínima 56 px. Um por tela. |
| Botão secundário | Noite com contorno dourado fraco, raio 10, altura mínima 48 px. |
| Painel | Noite-2, contorno violeta-luz a 24%, raio 18. Em foco: moldura dourada de 2 px, um por tela. |
| Selo hexagonal | Hexágono de borda dourada com ícone de traço dourado e rótulo abaixo. |
| Estado | Pílula com contorno e ponto: verde pronto, âmbar em andamento, violeta planejado. |
| Passos | Círculos numerados violeta, só quando a ordem importa. |
| Aviso | Contorno violeta forte com sombra, título com ícone de alerta. |
| Cartão de herói | Fundo tingido pela cor da força, emblema hexagonal, barras de atributo na cor da força. |

## Imagem e ícones

- A arte-chave é concept art, não captura do jogo. Texto sobre ela sempre com camada escura.
- A arte original tem o título impresso. As versões em `site/assets/valdora-arte-*.jpg` têm essa área escurecida. A versão de redes sociais (`valdora-social.jpg`) mantém o título.
- Ícones de traço de 1,8 px em grade de 24 px, cantos redondos, cor do texto ou ouro. Sem emoji. Biblioteca em `site/assets/icones.svg`.
- Brasão: coroa violeta de três pontas com losango dourado, em `site/assets/brasao.svg`.

## Texto

- Português do Brasil, frases curtas, verbos de ação.
- Todo recurso anunciado diz se está no jogo, em desenvolvimento ou planejado.
- Aviso de risco diz o que se perde e como evitar.

## Site

- Cinco páginas: Início, Universo, Classes, Reinos, Download. Fontes em `tools/site_paginas/`, geradas com `python3 tools/gerar_site.py`, que aplica topo, rodapé e ícones iguais em todas.
- A página Classes usa os valores do catálogo `game/data/valdora_heroes_v0.1.json`. Se o catálogo mudar, a página precisa ser atualizada.
- O APK continua sem link público. O add-on Minecraft aparece na página Download como experimental.
- A antiga `/valdora/` redireciona para a página inicial.

## Jogo (Godot)

| Regra | Valor |
|---|---|
| Camadas | Mundo; HUD na camada 1; painéis na 2; avisos e confirmações na 3 |
| Painel aberto | Oculta os botões do HUD e escurece o mundo com noite a 72% |
| Barra superior | Altura fixa de 60 px, sem quebra de linha |
| Rótulos em linha | Sem quebra automática dentro de `HBoxContainer`, ou com largura mínima |
| Toque | Alvo mínimo de 48 px; botão principal 56 px |
| Letra a 1280×720 | Título 28 a 40; corpo 16 a 18; mínimo 14 |
| Mensagens | Aviso centralizado no rodapé, nunca embaixo dos botões |
| AUTO TESTE | Fora da versão de jogador |

Constantes propostas para `res://scripts/ui/valdora_tema.gd`: ver o bloco de código no guia ilustrado.

Onde cada tela muda:

- **Minha cidade** (`modules/city/city.gd`): pelo OTA, como módulo `city-10` assinado com a chave OTA.
- **Tela de marca, exploração, Heróis, Arena, Módulos** (`scripts/main.gd`, `scripts/ui/`): exigem APK novo. Devem entrar junto com o CP013, que já reescreve o HUD e aplica mudanças no `main.gd` conferindo o hash do arquivo. Alterar o `main.gd` antes quebraria esse script.
