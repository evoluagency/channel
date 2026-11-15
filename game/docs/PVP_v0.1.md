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

## Próximos passos (propostos)

1. O dono avalia os menus e os mapas.
2. Ligar a cena PvP ao início do app, atrás de um botão. Isso exige APK novo e OK do dono.
3. Montar os mapas em 3D a partir da grade (bloqueio cinza), para testar a movimentação.
4. Arte de cada arena, junto com o trabalho do Codex em Brasília.
5. Pendências que mudam o projeto:
   - o PvP online pede servidor de partida em tempo real, o que ainda não existe;
   - o Supabase gratuito não serve para tiro em tempo real; é preciso decidir a arquitetura antes de gastar;
   - o futuro do "MUNDO" (estratégia) ao lado do PvP: o que continua e o que pausa.
