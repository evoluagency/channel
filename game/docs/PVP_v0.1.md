# Valdora PvP — v0.1 (15/11/2026)

## Decisão do dono (15/11/2026)

- Nova versão do jogo, chamada **PvP**, dentro do próprio Valdora (o APK que existe).
- **Jogabilidade, modos e estrutura de menus** baseados em jogos de tiro competitivo mobile (referência: Standoff 2).
- **Acabamento visual** no nível de jogos de estratégia mobile (referência: Last War), com **identidade própria do Valdora**. A arte conceitual do dono define a paleta: azul-noite, verde-azulado, laranja e creme, praças com cúpulas.
- **Primeira etapa:** layout dos menus. Sem produtos, armas ou itens reais: só espaços reservados.
- O cenário de Brasília está sendo construído à parte, pelo Codex.
- O jogo instalado (0.4.1, OTA rev 10) não mudou. Nada foi publicado.

## Menus (layout v0.1)

| Item | Onde fica |
|---|---|
| Cena de prévia | `game/scenes/pvp/MenuPvP.tscn`. A `Main.tscn` não foi alterada |
| Código | `game/scripts/ui/pvp/`: `pvp_tema.gd` (cores, fontes e caixas), `pvp_menu.gd` (telas), `pvp_icone.gd` (ícones vetoriais próprios), `pvp_fundo.gd` (céu e silhueta de cidade com cúpulas) |
| Fonte | Montserrat (OFL), em `game/assets/fontes/` |
| Capturas | `game/docs/imagens/pvp/` |
| Smoke | `game/tests/pvp_menu_smoke.gd`, incluído no `tools/run_valdora_tests.sh --all`. Confere as 10 telas, botões com pelo menos 48 px e nada fora da tela de 1280 × 720 |

Estrutura: barra lateral de ícones (Jogar, Inventário, Loja, Mercado, Clã, Ajustes, Chat), abas no topo e moedas à direita (C de créditos, G de ouro, com o botão "+").

As 10 telas:

| Tela | O que tem |
|---|---|
| Início | perfil com nível e XP, amigos, pedestal do agente, evento, atalhos de Eventos e Passe, missão do dia, "Selecionar modo de jogo" e "Jogar" |
| Modos | categorias Principal e Outro; cartões Mata-mata em equipe, Desarmar, Competitivo, Aliados, Duelo, Duelo 2 × 2 e Modo especial; partida pública; mapas |
| Inventário | grade de itens com faixa de raridade e acesso ao equipamento do agente |
| Loja | abas Loja e Ouro; caixas e caixotes com preço |
| Mercado | abas Mercado, Minhas solicitações e Histórico; filtros; grade com quantidade e preço |
| Clã | busca, lista com membros e "Enviar solicitação", "Criar clã" |
| Ajustes | abas Jogo, Vídeo, Controles e Som; subabas; opções em botões segmentados; "Redefinir" e "Aplicar" |
| Chat | Amigos e Sistema, lista de conversas, tela vazia com "Nova conversa" e aviso de segurança |
| Carregamento | minimapa, nome do mapa, modo, descrição e barra de progresso |
| Partida | placar 5 × 5, tempo, minimapa, mira, controle de movimento, vida e colete, armas, munição, tiro, recarregar, pular e agachar (só o layout) |

Raridades: comum (cinza), incomum (azul-claro), raro (azul), épico (roxo) e lendário (laranja).

## Mapas (modo Desarmar, v0.1)

Cada mapa é uma grade de 24 × 32 células de 3 m (72 × 96 m), feita a partir da planta de referência do dono:
- base 1 (ataque) embaixo e base 2 (defesa) em cima;
- três rotas (esquerda, meio e direita);
- dois pontos de plantio, A e B.

| Item | Onde fica |
|---|---|
| Fonte dos mapas | `tools/pvp/mapas.py`, que gera `game/data/pvp/mapas_v0.1.json` e as plantas em `game/docs/imagens/pvp/mapas/` |
| Teste | `game/tests/test_mapas_pvp.py` (no `--py`) |

| Mapa | Tema | Ataque até A / B | Defesa até A / B | Rotação A-B |
|---|---|---|---|---|
| Esplanada (Brasília) | praça cívica: galeria, pátio e jardim (a planta do dono) | 17 / 16 s | 4 / 4 s | 8 s |
| Porto (Rio de Janeiro) | armazém (A), contêineres no meio, cais aberto (B) | 13 / 14 s | 5 / 5 s | 8 s |
| Ladeira (Salvador) | igreja no alto (A), mercado (B), escadaria e becos | 15 / 14 s | 4 / 4 s | 8 s |
| Estação (São Paulo) | bilheteria (B), plataforma (A), trilhos e passarelas | 17 / 18 s | 4 / 4 s | 8 s |
| Represa (Pará) | turbinas (A), vila (B), rio com três pontes | 16 / 12 s | 5 / 4 s | 7 s |

Regras de equilíbrio conferidas em todos os mapas:
- as três portas são o único caminho entre as metades, e cada rota sozinha liga as bases;
- o ataque chega a cada ponto em 12 a 26 s e a defesa em 3 a 11 s, sempre ao menos 5 s antes;
- A e B ficam a pelo menos 30 m um do outro;
- a defesa troca de ponto em até 16 s.

Velocidade de corrida usada: 5 m/s.

## Arenas 3D e APK 0.5.0 (15/11/2026, mesma sessão)

**Decisões do dono:**
- foco 100% no PvP;
- o jogo de estratégia (MUNDO, cidades 3D e alianças) foi encerrado;
- o APK novo é uma **atualização do Valdora instalado**: mesmo pacote `ink.evolu.valdora`, mesmo certificado e versionCode maior.

**Arenas** (`game/scripts/pvp/pvp_arena.gd`, cena `game/scenes/pvp/ArenaPvP.tscn`):
- Montadas direto da grade de `mapas_v0.1.json`, com célula de 3 m.
- Paredes com colisão, juntadas em retângulos de 27 a 41 blocos por mapa. Têm 4,2 m de altura; as da borda, 6 m.
- Cerca invisível de 30 m em volta: ninguém sai do mapa.
- Coberturas: caixotes de 1,15 m e contêineres de 2,4 m.
- Bases e pontos A e B pintados no chão, com letra grande; portas das rotas em faixa amarela.
- Visual de blocos (fase de teste), na paleta do Valdora.

**Jogador em primeira pessoa** (`pvp_jogador.gd`):
- corre a 5 m/s; agachado, a 2,4 m/s;
- pula, mira e atira por raio (marca o impacto), com recarga de 24 + 90.

**Interface da partida** (`pvp_hud.gd`):
- joystick na metade esquerda, mira arrastando na metade direita;
- tiro (contínuo segurando), recarga, pulo e agachar, com vários dedos ao mesmo tempo;
- minimapa com o jogador, tempo e munição;
- pausa, que volta ao menu.

**Fluxo:**
1. O app abre direto no menu PvP (`run/main_scene`).
2. Jogar leva ao carregamento, com a planta do mapa escolhido.
3. Entrar abre a arena.
4. O mapa se troca em Selecionar modo → Mapa.

**Testes:**
- `pvp_arena_smoke`: cada célula de parede e de cobertura das 5 grades tem colisão, e cada célula de chão está livre; o jogador pousa na base de ataque e, correndo 4 s em 8 direções, não entra em parede nem sai do mapa; tiro e recarga.
- `tools/run_valdora_tests.sh`: 21 de 21.

**Versão:**
- 0.5.0-pvp, versionCode 104, nos arquivos `export_presets.cfg`, `release-control/version.txt`, `update_contract.gd` (CLIENT_CODE) e no workflow de release.
- Os smokes PvP entram no workflow.
- O manifesto OTA aceita cliente a partir do 102.
- A pasta `docs/` sai do APK.

O código do jogo antigo continua no repositório, sem uso, porque os testes do sistema de atualização dependem dele. Remover fica para depois do APK homologado.

## Cenários regionais e APK 0.5.1 (15/11/2026)

O dono pediu o acabamento da arte conceitual, com o ambiente de cada região. Regras da rodada ficam para depois.

**Feito em `game/scripts/pvp/visual/`:**
- **Texturas procedurais** (`superficie.gdshader`), sem imagem externa: paralelepípedo, pedra portuguesa em ondas, tijolo, reboco, concreto, madeira, metal ondulado, grama, azulejo, asfalto, terra e telha. Têm sujeira perto do chão e sombra falsa nas paredes.
- **Água animada** (`agua.gdshader`).
- **Construtor** (`construtor.gd`): junta a geometria por material e fica com 21 a 32 malhas por arena (chamadas de desenho).
- **Cenário** (`cenario.gd`): as paredes da grade viram prédios da região; a colisão é a mesma da grade.

| Mapa | Ambiente |
|---|---|
| Esplanada | Brasília modernista: prédios brancos com janelas em faixa e brises, placas de concreto, ipês amarelos e rosa, terra vermelha do cerrado. Ao fundo: torres gêmeas, cúpula, cúpula invertida, catedral de pilares e ministérios |
| Porto | armazéns de tijolo com portões de carga e telhado de zinco, pedra portuguesa em ondas, contêineres, guindastes, baía e morros |
| Ladeira | casario colonial colorido com cantaria branca, venezianas, sacadas e telhado de telha, igreja com torres de azulejo, paralelepípedo, barracas, palmeiras e mar ao fundo |
| Estação | tijolo aparente com cantaria clara, trilhos com dormentes, bancas, torre do relógio e prédios altos ao fundo |
| Represa | casas de madeira coloridas sobre palafitas, assoalho de tábuas, rio com três pontes, mata fechada no limite, barragem ao fundo |

- Em todos os mapas: estandartes verde-azulados com o V dourado (identidade Valdora), postes, árvores junto às paredes sem fechar passagem, bordas pintadas nas bases e nos pontos A e B, e luz quente.
- Capturas: `game/docs/imagens/pvp/cenarios/` (vista aérea e três vistas em primeira pessoa por mapa).
- `--rendering-method` não muda: tudo roda no GL Compatibility do celular.
- **Limite:** o nível da arte conceitual (pintura digital) não sai inteiro de geometria feita por código. A distância está em detalhe de modelagem (ornamentos, arcos, vegetação densa) e em texturas pintadas. Os próximos passos de arte são modelos dedicados por marco e mais adereços.
- **APK 0.5.1-pvp (versionCode 105):** atualização por cima da 0.5.0. O link direto fica na pré-versão `valdora-0.5.1-pvp` do GitHub.

## Estabelecimentos e APK 0.5.2 (15/11/2026)

- Até 14 lojas por mapa no térreo dos prédios, espalhadas a pelo menos 9 m uma da outra e só onde a calçada em frente é livre.
- Cada loja tem moldura, vitrine iluminada, porta de vidro, toldo listrado e letreiro com o nome.
- Na calçada, encostados na parede: mesas e cadeiras de café, banca de frutas ou de peixe, expositor de revistas ou caixas.
- Nomes por região:
  - Brasília: Café Cerrado, Livraria, Padaria, Farmácia, Restaurante Ipê, Banca;
  - Rio: Botequim, Peixaria, Armazém 7, Café do Cais, Estiva, Sucos;
  - Salvador: Acarajé, Sorveteria, Artesanato, Padaria, Capoeira, Café Baiano;
  - São Paulo: Pastelaria, Lanchonete, Banca, Farmácia, Bilheteria, Café da Estação;
  - Pará: Açaí, Mercado do Peixe, Farinha, Café, Mercearia, Tacacá.
- APK 0.5.2-pvp (versionCode 106). Testes: 21 de 21.

## Próximos passos (propostos)

1. O dono avalia os menus e os mapas.
2. Homologar o APK 0.5.0 no aparelho.
3. Inimigos de treino e regras da rodada (plantar e desarmar).
4. Arte de cada arena, junto com o trabalho do Codex em Brasília.
5. Pendências que mudam o projeto:
   - o PvP online pede servidor de partida em tempo real, o que ainda não existe;
   - o Supabase gratuito não serve para tiro em tempo real; é preciso decidir a arquitetura antes de gastar;
   - o futuro do "MUNDO" (estratégia) ao lado do PvP: o que continua e o que pausa.
