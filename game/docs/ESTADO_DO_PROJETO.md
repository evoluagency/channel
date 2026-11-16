# Valdora — Estado do projeto

Registro único do que está pronto, publicado e pendente. Atualizado em **16/11/2026** (sessão 1.8, PvP). Quando outro documento contradiz este, vale este até o outro ser corrigido. Atualize este arquivo ao fechar cada marco, e só ele.

Plano de continuidade (lacunas e fases): https://claude.ai/artifact/8PDe8WWqE8aftgsBwSU1rU

## 1. Versões

| Item | Valor | Como foi conferido |
|---|---|---|
| Código na `release/valdora-android` (`8a29073`) | 0.4.1-alpha, versionCode 103 | `export_presets.cfg`, `version.txt`, `update_contract.gd` |
| Pacote Android | `ink.evolu.valdora` | `export_presets.cfg` |
| Motor | Godot 4.7.2, GL Compatibility | `project.godot`, workflow `cp004-ota` |
| APKs recebidos do dono | 0.3.3 e 0.4.0-alpha (code 102) | os dois com o mesmo certificado do arquivo de credencial |
| APK 0.4.1 (code 103) | gerado e instalado por cima da 0.4.0 em 13/11/2026; homologado com defeitos visuais (ver abaixo) | workflow `valdora-android-release`, execução 43429562665 a partir da release `8a29073`; artefato 14039765549 expira em 20/11/2026 |

### Build do APK 0.4.1 (13/11/2026)

- Disparado manualmente na branch `release/valdora-android`. A cópia do workflow na `main` ainda exige versionCode 100 e não deve ser usada.
- Passaram: segredos, certificado permanente (SHA-256 `C5:95:06…`), testes estáticos, import, 8 smokes Godot (inclusive o OTA remoto contra a produção na revisão 10), exportação, `aapt` (`ink.evolu.valdora`, code 103, 0.4.1-alpha) e `apksigner` com o mesmo certificado. APK com 52.677.239 bytes; o SHA-256 está no `SHA256.txt` do artefato.
- Aviso na exportação: a cópia `game/modules/city/valdora_modules/city/entry.tscn` aponta para um script que só existe dentro do ZIP OTA. O APK sai assinado e o jogo usa o módulo do ZIP, mas é a lacuna P1 das duas cópias do módulo Cidade.
- Continuam dentro do APK: botão AUTO TESTE e a pasta de testes (lacuna P1 de release).
- Instalação: por cima da 0.4.0, sem desinstalar. `retain_data_on_uninstall=false`, então desinstalar apaga os saves.

### Homologação em aparelho da 0.4.1 com OTA revisão 10 (13/11/2026)

Prints do dono. Funciona: instalação por cima sem perder dados (moedas, poções, formação e nome da cidade preservados), tela de marca nova, "conteúdo v10" recebido, Cidade v9 abre em MINHA CIDADE com o painel Territórios, Heróis e Arena abrem.

Defeitos encontrados:

| Defeito | Onde | Correção sai por |
|---|---|---|
| Barra superior da Cidade: o rótulo de recursos fica numa coluna de letras, a barra estica até o meio da tela e escurece o mapa; o nome da cidade aparece no meio da tela | `city.gd`, `_create_ui`: `resource_label` com quebra de linha dentro de um `HBoxContainer` sem largura mínima | OTA (módulo da Cidade visual, sem assinatura ainda) |
| Texto "CIDADE · v8" desenhado no mapa da v9 | `city.gd`, `draw_string` | OTA (módulo da Cidade visual) |
| Botões do topo (MÓDULOS e outros) desenhados por cima dos painéis de Heróis e Arena | `main.gd`: botões adicionados à mesma camada depois dos painéis | APK |
| Mensagem de status do topo passa por baixo dos botões | `main.gd` | APK |

### Direção visual e site novo (13/11/2026)

- Guia em `docs/DIRECAO_VISUAL.md` (texto) e `docs/direcao-visual/guia-visual.html` (ilustrado).
- Site refeito com cinco páginas na branch `claude/zealous-tesla-kfhwld`, sobre o `site/` da `main`. **Não publicado**: publicar exige "OK, subir" e gera 1 deploy.
- Telas do jogo: Cidade pelo OTA; demais telas no APK junto com o CP013.

### Cidade na direção visual (sessão 1.1, 13/11/2026)

- Decisão do dono: o CP012 será `city-12`; nada é publicado agora e a Cidade visual evolui em versões intermediárias até lá. `city-10` e `city-11` ficam livres para o visual.
- `game/modules/city/city.gd` reescrito visualmente (barra de 60 px fixos, pílulas de recurso, sem "CIDADE · v8", Cinzel e Montserrat dentro do módulo, cores e raios do guia), regras e save da v9 intactos. Fontes e licenças OFL em `game/modules/city/fontes/`.
- Tema do núcleo em `game/scripts/ui/valdora_tema.gd` (não usado ainda); lista de mudanças de camadas e HUD em `game/docs/MUDANCAS_NUCLEO_CP013.md`. `main.gd` intocado.
- `tools/build_city_zip.py` monta o ZIP sem assinatura (determinístico, `dist/ota-trabalho/`). Assinatura: só no computador do dono, passo a passo em `game/docs/sessoes/HANDOFF-1.1.md`.
- Verificado com Godot 4.7.2 oficial: `--all` com 18 passando e só o `remote_update_smoke` falhando (sem rede). Captura em `game/docs/logs/cidade_visual_1280x720.png`. Falta homologar no aparelho depois da assinatura.
- O dono não tem os pacotes do CP012 nem do CP013; o desenvolvimento deles é nosso, em sessões próprias.
- Os defeitos 1 e 2 da tabela acima (barra e texto da v8) têm correção pronta e não homologada; os 3 e 4 seguem para o APK com o CP013.

### Mudança de rumo: jogo moderno (13/11/2026)

- Decisão do dono: o jogo passa a um cenário moderno (sem zumbis), com mapa-múndi real, divisões de estado reais, país/estado por jogador, alianças e guerra por território. Reskin do mesmo jogo, nome novo (provisório "MUNDO"). Piloto: Brasil, 27 estados.
- Desenho completo em `game/docs/DESENHO_MUNDO_v0.1.md` (decisões, perfis dos 27 estados, alianças, marcos M0 a M7, o que reaproveitar do Valdora). Prévia visual privada: https://claude.ai/artifact/7ZdEi4EiADxRTxHEQLhfGe
- Pendentes do dono: direção visual (A, B ou C), nome, atribuição do estado, territórios disputados, pacote do app novo, nomes dos heróis.
- Componentes, níveis 1 a 30 e aparência por faixa: `game/docs/COMPONENTES_NIVEIS_v0.1.md` (13 construções, heróis, tropas, estado, alianças, chat, animações). Números são proposta de balanceamento.
- O CP012 (`city-12`) deixa de ser pacote externo; o conteúdo é reescrito nos marcos M4 a M6. Nada do Valdora em produção muda; o site novo segue sem publicar.

### Visual individual dos componentes (sessão 1.2, 13/11/2026)

- Método: 3D de baixo polígono **modelado por código no Godot 4.7.2** (GL Compatibility, o renderizador do celular), sem modelos externos. Gerador separado do jogo em `tools/arte3d/` (kit de peças, uma receita por construção, `gerar.sh`, `folha.py`, `catalogo.py`). O jogo instalado e o OTA não foram tocados.
- As 13 construções nas seis faixas estão prontas, cada uma com uma folha das faixas e o detalhe da faixa 6 em cinco cores de aliança, em `game/docs/imagens/componentes/`. Há também o catálogo `catalogo_13_construcoes.png`.
- **Aprovado pelo dono em 13/11/2026:** as 13 construções nas seis faixas (Quartel-general, Alojamento e Estufa uma a uma; as outras 10 em avaliação conjunta) e o guia de arte.
- Guia consolidado: `game/docs/GUIA_DE_ARTE_v0.1.md` (paleta, formas, luz, selo, aliança, animações propostas, desempenho, lista para artista).
- Desempenho medido: de 24 a 210 peças e de 2 mil a 38 mil triângulos por construção. É preciso fundir as malhas antes da cidade 3D (sessão 1.5).
- Motor: o dono perguntou sobre Unity e Three.js. A recomendação registrada é **seguir no Godot** (pipeline, OTA e testes prontos; a diferença para o nível comercial é de arte, não de motor). A decisão final é do dono.
- Números e fórmulas de `mundo_componentes_v0.1.json` sem mudança; `test_componentes_mundo.py` 12/12.
- Marcos M8 a M13 registrados em `DESENHO_MUNDO_v0.1.md`: desempenho da cidade 3D, OTA só de conteúdo (regra do Google), servidor no Supabase gratuito, preparação e publicação na Play Store (taxa única de US$ 25 só com OK do dono).

### Brasil em dados: marcos M1 e M2 (sessão 1.3, 13/11/2026)

- **M1 pronto:** `tools/mundo/gerar_pais.py` (Python puro) gera `game/data/mundo/BR.json` do Natural Earth 1:10m (domínio público; commit e SHA-256 fixos em `tools/mundo/FONTE.md`; fonte bruta de 40 MB não versionada). 241 KB, 15.131 vértices, 27 estados com área, centroide, ponto do rótulo, litoral, fronteira externa e vizinhos. Simplificação por arco (divisas idênticas dos dois lados), tolerância proporcional ao tamanho do estado (0,001 × raiz da área, 30 a 2.500 m, para o zoom do modo retrato), sem cruzamentos. Determinístico.
- **M2 fechado (aprovado pelo dono em 13/11/2026):** perfis com peso, 2.000 vagas de base repartidas entre os 26 estados (SE 50 a AM 103; DF é a capital federal, sem bases), capitais estaduais, bônus por região. Primeira versão: `game/data/mundo/BR_perfis.json` (região, área IBGE e calculada, lotes, biomas, vocação, recursos fortes). Fórmula de lotes mantida; BA 106 e PE 81 corrigidos pela fórmula; MT com Amazônia dominante (proposta).
- Simulação das compensações (`tools/mundo/simular_lotes.py`): sem compensação o AM fica 3 vezes mais forte que o DF; com produção e poder por prédio × `(80/lotes)^0,75`, nenhum estado passa de ±21% da mediana. Transporte e tempo de obra por tamanho pioram o equilíbrio. Proposta e tabela dos 27 em `game/docs/MUNDO_BRASIL_DADOS_v0.1.md`, com 6 decisões do dono.
- Folha de conferência: `game/docs/imagens/mundo/BR_conferencia.png`.
- **Decisão do dono (13/11/2026): jogo em modo retrato**, com arrastar e pinça para zoom, zoom de afastar limitado para o próprio estado continuar legível, botão para ver o país inteiro e toque num estado para ver as bases dos outros jogadores. Regras em `DESENHO_MUNDO_v0.1.md`, seção 3.1.
- **Decisão do dono (13/11/2026): servidor = país; estado = terreno com muitos jogadores; DF é a capital**, disputada em guerra; quem a controla elege o presidente do servidor. Servidores de outros países e regiões em atualizações futuras. Proposta em `DESENHO_MUNDO_v0.1.md`, seção 4.1: base de tamanho igual para todos (80 lotes), 2.000 bases por servidor Brasil repartidas pelo peso de cada estado, DF sem bases. A coluna "lotes" de `BR_perfis.json` passa a ser esse peso; o arquivo muda quando o dono confirmar os números.
- **Decisão do dono (13/11/2026): sociedade e economia.** Servidores com nome de país, movimentos (até 100 membros) que tomam o estado por voto ou guerra civil, recursos fortes por região, migração, comércio entre jogadores e o jogo como banco (colchão ou banco, taxas, empréstimos). Registro e propostas em `game/docs/SOCIEDADE_ECONOMIA_v0.1.md`; números ficam para a sessão 1.4.
- **Ritmo da temporada (decisão do dono):** 30 dias; governo por volta do dia 15 e presidência por volta do dia 30; sem pagar, nível 20 em 30 dias; pagando, nível 30 na metade do tempo. A 1.4 reajusta as curvas.
- Testes: `game/tests/test_mundo_brasil.py` 25/25 (entra no `tools/run_valdora_tests.sh`, também no `--py`). Nada do jogo instalado mudou.

### Jogabilidade e economia da Fase A (sessão 1.4, 13/11/2026)

- **Aprovado pelo dono:** curvas v0.2. Quem joga 15 min por dia chega ao nível 20 no dia 29 e ao 30 no dia 62; 30 min, 26 e 56; o **pagante médio** (passe da temporada: obras 60% mais rápidas, produção +75%, uma fila a mais) chega ao 30 no dia 30. Salto do início rápido suavizado: a obra dobra a cada nível do 9 ao 13 (4 h a 2,7 dias) e fica em cerca de 3,8 dias do 15 ao 30.
- **Decisões do dono:** Prefeitura no lugar do Quartel-general (o nível dela é o nível da cidade); moeda do próprio sistema com banco em cada cidade (proposto como 14º prédio); árvore de desbloqueio em que um prédio depende do outro; a economia gira em torno da produção; sigla do movimento de até 4 letras e número de 10 a 99; ajuda entre cidades do movimento com métrica; o presidente só nomeia governadores para os cargos do país e tem 4 secretários; governadores podem ser oposição.
- Simulação `tools/mundo/simular_economia.py` (5 regiões × 4 perfis, determinística): fontes e drenos de moeda andam juntos (20 a 28% da produção por semana), moeda guardada abaixo de 0,6 dia de produção, preço preso na faixa de ±15% pela âncora do sistema; regiões a ±1% em poder e produção.
- Dados: `game/data/mundo_componentes_v0.2.json` (14 prédios, gerado por `tools/mundo/gerar_componentes_v02.py`). A v0.1 continua no repositório para a arte e o teste antigo.
- Regras em `game/docs/JOGABILIDADE_ECONOMIA_v0.1.md`: progressão, desbloqueio, economia, banco, empréstimo, ajuda, passe, poder (eleição, guerra civil, governador, Conselho dos governadores, presidência), ciclo diário, NPC e chat. As seções 4 a 12 são proposta sobre as decisões do dono.
- Decisões finais da sessão: impostos estadual e federal só na venda, com aviso de capacidade de pagamento; comércio entre estados com margem de lucro; Banco como prédio próprio; servidor sem reinício, com disputa entre países e migração paga; siglas livres (`SOCIEDADE_ECONOMIA_v0.1.md`, seções 11 e 12). Próxima sessão: 1.5, economia v0.3; Cidade 3D na 1.6.
- Testes: `game/tests/test_economia_mundo.py` 22/22, no `tools/run_valdora_tests.sh` (o `--py` passa 8/8). Nada do jogo instalado mudou.

### Economia v0.3 (sessão 1.5, 13/11/2026)

- **Aprovado pelo dono:**
  - as 6 recomendações da seção 12 de `SOCIEDADE_ECONOMIA_v0.1.md`;
  - Nordeste forte em alimentos e materiais;
  - fraco em −20%;
  - impostos estadual e federal de 0 a 30%, com faixas verde até 20%, amarela até 40% e vermelha acima;
  - recém-chegado com obras 50% mais rápidas.
- **Simulação v0.3:**
  - Mercado entre jogadores com margem, impostos só na venda, tesouro com obras públicas (bônus até 3% + 3%), Centro tecnológico com 5 linhas de pesquisa e produção do passe não vendável.
  - Resultados: 15 min/dia chega ao nível 20 no dia 29,6 e ao 30 no 63,6; o pagante, ao 30 no dia 31.
  - Regiões a ±2%; comércio entre jogadores de 18% da produção (abaixo da meta de 20%, aceito); moeda guardada abaixo de 0,5 dia.
- **Dados:** `game/data/mundo_componentes_v0.3.json` (15 prédios, com pesquisa, regiões, mercado, impostos, tesouro, passe, recém-chegado, migração e disputa entre países), gerado por `tools/mundo/gerar_componentes_v03.py`. As curvas da v0.2 continuam iguais (o teste confere).
- **Sem dinheiro real por enquanto** (decisão do dono); a cobrança será definida no M13.
  - Migração a partir do dia 60, com reserva de 25% do valor da cidade (4 a 7 dias de produção).
  - Venda da cidade só em moeda do jogo.
  - Disputa entre países nos dias 1 a 15 de cada temporada a partir da 2ª.
- **Regras:** `game/docs/ECONOMIA_v0.3.md`. Os detalhes da disputa entre países (grupos, pontos, prêmios, tratados) são proposta a confirmar.
- **Testes:** `game/tests/test_economia_mundo.py` 37/37; o `--py` passa 8/8. Nada do jogo instalado mudou.

### Valdora PvP: paintball, heróis KayKit, bots 5 × 5 e interface da arte (sessão 1.8, 16/11/2026)

- **Paintball** (decisão do dono): todas as armas disparam tinta.
  - `pvp/pvp_tinta.gd`: bolas com trajetória e gravidade, respingos procedurais na parede e no chão (`visual/tinta_respingo.gdshader`, até 180, os mais antigos são reciclados) e mancha que acompanha o corpo atingido; bolas e respingos em dois MultiMesh (duas chamadas de desenho);
  - cor de tinta por time: verde-azulado claro (seu time) e magenta (adversário). No GL Compatibility a cor da instância vai por `INSTANCE_CUSTOM` (pelo `COLOR` saía preta).
- **30 aparências do marcador** (`data/pvp/aparencias.json`, nomes próprios) num shader só, `visual/pintura_marcador.gdshader`: camuflagem, respingos, chamas, raio, listras, digital, colmeia, tigre, metal gravado, gelo, floral, neon, galáxia e folhagem, mais emblemas (coração, estrela, caveira, X, coroa). Sem textura pintada.
- **Armas em primeira pessoa** (`visual/marcador.gd`, baixo polígono por código): marcador de assalto com funil (hopper), pistola de tinta e granada de tinta, com a aparência escolhida e braços (manga verde-azulada, punho laranja, luva preta). Coice, balanço ao andar e recuo perto da parede. Granada: arco, estouro com 16 respingos em volta e dano em área com linha de visão.
- **11 heróis** (`data/pvp/herois.json`; Nilo é o Brasil):
  - corpo KayKit Adventurers 1.0 (CC0; LICENSE conferido e versionado em `assets/pvp/personagens/`), baixado do repositório oficial do autor no GitHub;
  - GLB podados por `tools/pvp/podar_glb.py`: sem armas medievais, 16 de 76 animações, de 3,5 MB para cerca de 870 KB cada (5 corpos, 4,3 MB);
  - textura de cada herói gerada por `tools/pvp/recolorir_herois.py` (roupa e tom de pele por faixa da paleta, 120 KB no total);
  - 4.148 triângulos e 6 malhas por herói (Knight); retratos renderizados uma vez num SubViewport (`visual/retratos.gd`).
- **Bots** (`pvp/pvp_bot.gd`): 4 aliados e 5 adversários, caminho pela grade (busca em largura), alvo mais perto com linha de visão, imprecisão, morte com animação e volta em 5 s. Partida de 3 minutos; o time que pintar mais vence. Jogador com vida 100 e escudo 50 e volta em 4 s.
- **HUD da partida** (`pvp/pvp_hud.gd`): placar com os retratos dos dois times e o tempo, "CONFRONTO 5 × 5", minimapa com o nome do mapa e os aliados, abates recentes, vida e escudo, 3 espaços de arma (toque para trocar), munição, joystick com setas, botões redondos e tiro laranja com aro; marcador de acerto, borda de dano, aviso de queda, pausa e tela de fim.
- **Menus** (`ui/pvp/pvp_menu.gd`):
  - topo com logo, moeda e atalhos (loja, clã, chat, ajustes);
  - barra inferior BASE, HERÓIS, ARSENAL e MISSÕES;
  - painéis navy translúcidos de cantos grandes e botão JOGAR laranja com brilho;
  - vitrine 3D (`ui/pvp/pvp_vitrine.gd`) com pedestal e anel aceso;
  - Heróis com lista de retratos, ficha e SELECIONAR;
  - Arsenal com o marcador no pedestal, as 30 aparências e EQUIPAR;
  - herói e aparência salvos em `user://pvp_perfil.cfg`.
- **Ficaram aquém da arte:** os heróis KayKit são "chibi", e a arte tem proporção heroica. Faltam o rosto detalhado e os acessórios (cocar, turbante, óculos de Nilo). Os atributos da ficha (mobilidade, ataque, defesa) só aparecem na tela: ainda não mudam a partida.
- **Capturas:** `imagens/pvp_1.8/`.
- **Testes:** 26 de 26 em `run_valdora_tests.sh`, com o novo `test_pvp_paintball.py`. O `pvp_arena_smoke` passou a provar a bola de tinta e o respingo nos 5 mapas, e mais 9 bots com herói e marcador, bots andando e atirando, pistola e granada.
- **APK 0.6.0-pvp (código 109) publicado em 16/11/2026:**
  - gerado pelo workflow `valdora-android-release`, execução 43862833591, do commit `f6dfc8a`;
  - release `valdora-0.6.0-pvp` com 55.149.890 bytes (1,8 MB a mais que a 0.5.4, por causa dos heróis) e SHA-256 `4a5244f1…5583c9e`;
  - o link fixo `releases/latest/download/Valdora.apk` foi baixado e conferido: tamanho e SHA-256 batem com o `versao.json`;
  - falta a homologação no aparelho: FPS, toque e leitura do HUD.

### Valdora PvP: gráfico da arte conceitual e APK 0.5.4 (sessão 1.7, 16/11/2026)

- **Alvo visual:** as 6 telas de referência do dono (Base, Heróis, Arsenal, Equipamento e duas de partida) em `imagens/referencia_1.7/`. Capturas da sessão (antes, luz, detalhe, menu) em `imagens/pvp_1.7/`.
- **Luz e cor dos 5 mapas:**
  - céu estilizado com nuvens de desenho animado e halo dourado (`visual/ceu.gdshader`);
  - sol baixo dourado; ambiente por cor quente, para a sombra não ficar azul;
  - tonemap filmic, brilho leve nas lanternas e neblina de profundidade;
  - paletas regionais mais saturadas e contorno de luz (rim) no shader das superfícies.
- **Detalhe dos cenários:**
  - kit `visual/ornamentos.gd`: arcadas, cornijas, balaustradas, cúpulas verde-azuladas com nervuras e pináculo dourados, estandartes com ponta e V dourado, lampiões acesos, jardineiras com flores, trepadeiras e árvores em vários volumes;
  - marcos: Cristo no Corcovado e Theatro Municipal no Porto; cúpulas na igreja e Elevador Lacerda na Ladeira; Theatro e torre com cúpula na Estação; Ver-o-Peso e mata viva no limite da Represa.
- **Orçamento medido** (Godot 4.7.2, GL Compatibility), dentro do limite de 80 malhas e 250 mil triângulos por arena:

  | Mapa | Malhas | Triângulos |
  |---|---|---|
  | Esplanada | 51 | 132 mil |
  | Porto | 40 | 83 mil |
  | Ladeira | 45 | 172 mil |
  | Estação | 38 | 129 mil |
  | Represa | 41 | 105 mil |

  Colisão intacta: o smoke da Esplanada compara os colisores (62) com o mapa original.
- **Menus:** o fundo virou a praça do Valdora em 3D (`visual/praca_valdora.gd`, 23 malhas e 23 mil triângulos), com chafariz, prédio de cúpula e arco, estandartes, arcada com trepadeiras e café. A praça para de renderizar quando o fundo some.
- **Personagens:** o acabamento de desenho animado dos heróis não sai por código. Levantamento em `PVP_PERSONAGENS_CC0.md`; recomendação: KayKit (CC0) recolorido para a partida e imagem para 3D local (TripoSR ou TRELLIS) para os heróis de vitrine.
- **Defeitos de processo corrigidos:**
  - `godot_checar_scripts.sh` dava "0 erros" quando o Godot não era encontrado; agora sai com código 2;
  - o smoke do menu passava com o fundo sem compilar; agora confere a praça montada;
  - o prazo dos smokes subiu para 300 s, porque a arena leva cerca de 3 minutos numa máquina lenta.
- **Testes:** 25 de 25 em `run_valdora_tests.sh`, com os 3 testes visuais PvP incluídos, entre eles o novo `test_pvp_arte_conceitual.py`.
- **APK 0.5.4-pvp (código 108) publicado em 16/11/2026:**
  - gerado pelo workflow `valdora-android-release`, execução 43842883778, do commit `ab288a5`;
  - pré-versão `valdora-0.5.4-pvp`, com 53.341.674 bytes e SHA-256 `38f01538…ea32706a`;
  - o link fixo `releases/latest/download/Valdora.apk` foi baixado e conferido (tamanho e SHA-256 batem com o `versao.json`);
  - o app instalado (107) avisa e se atualiza;
  - falta a homologação no aparelho: visual e FPS com glow e praça 3D.

### Revisão do trabalho do ChatGPT (sessão 1.6, 15/11/2026)

- **Revisados os 36 commits do ChatGPT** (`d503fd6`..`8a0b66c`):
  - download automático do APK pelo gerenciador de downloads do Android, com tamanho e SHA-256 conferidos e instalação com a confirmação do Android (permissão `REQUEST_INSTALL_PACKAGES`);
  - opções de vídeo (MSAA, resolução, sombras e FPS);
  - acabamento piloto da Esplanada;
  - testes novos.
- **Defeitos encontrados e corrigidos:**
  - dois erros de sintaxe GDScript: em `pvp_menu.gd` (a tela inicial do app) e em `esplanada_acabamento.gd` (que derrubava o cenário de todos os mapas). O app abriria sem menu. Os smokes travavam (o do menu) ou falhavam (o das arenas), e o workflow de APK pararia neles. O ChatGPT não rodou o Godot.
  - não havia alternativa se o download nativo falhasse. Agora aparece "Baixar pelo navegador".
- **Prevenção:** `tools/godot_checar_scripts.sh` confere a sintaxe de todos os scripts PvP e entra no `run_valdora_tests.sh` e no workflow de release.
- **Testes:** 22 de 22, mais o `pvp_esplanada_visual_smoke`.
- **Atenção:**
  - o download automático usa dados móveis (`setAllowedOverMetered`);
  - a permissão `REQUEST_INSTALL_PACKAGES` exige justificativa na Play Store (M13);
  - a ponte Android (JavaClassWrapper) só se prova no aparelho.

### Valdora PvP: cenários regionais e APK 0.5.1 (sessão 1.6, 15/11/2026)

- Os 5 mapas ganharam o ambiente da região, com texturas procedurais, prédios locais, adereços e paisagem de fundo. A colisão continua a da grade. Detalhes em `PVP_v0.1.md`.
- **Versão 0.5.1-pvp (código 105).** O link direto do APK fica na pré-versão do GitHub, porque o artefato do Actions não baixa sem login. Repositório público: o link também é público.
- Testes: 21 de 21.

### Valdora PvP: arenas 3D e APK 0.5.0 (sessão 1.6, 15/11/2026)

- **O dono encerrou o jogo de estratégia** (MUNDO, cidades e alianças). O foco é 100% o PvP; as seções sobre o MUNDO abaixo ficam só como histórico.
- **Arenas 3D jogáveis** nos 5 mapas: delimitações tiradas das grades, primeira pessoa e controles de toque. O app agora abre no menu PvP.
- **Versão 0.5.0-pvp (versionCode 104):** atualização por cima da 0.4.1, com o mesmo pacote e o mesmo certificado. O APK é gerado pelo workflow `valdora-android-release`, com OK do dono dado em 15/11/2026.
- **APK 0.5.0-pvp gerado em 15/11/2026.**
  - Execução 43729674199 do workflow, com fonte `claude/zealous-tesla-kfhwld` e commit `39fc8c0`.
  - Passaram os testes estáticos e os 10 smokes Godot, inclusive os 2 do PvP e o OTA remoto.
  - Exportação: `aapt` confirma `ink.evolu.valdora`, versionCode 104 e 0.5.0-pvp. O `apksigner` confirma o certificado permanente `C5:95:06…`.
  - APK com 53.241.308 bytes. Artefato 14167872881, que expira em 22/11/2026.
  - Na exportação apareceu o aviso antigo de `valdora_modules/city/city.gd` (a cópia do módulo Cidade). Ele não afeta o PvP.
  - Falta homologar no aparelho.
- O workflow de release ganhou a entrada `fonte`, que por padrão continua sendo `release/valdora-android`.
- Testes locais: 21 de 21. Detalhes em `PVP_v0.1.md`.

### Valdora PvP: menus e mapas (sessão 1.6, 15/11/2026)

- **Mudança de rumo do dono:**
  - versão **PvP** do Valdora;
  - jogabilidade e estrutura de menus de tiro competitivo mobile (referência: Standoff 2);
  - acabamento de estratégia mobile (referência: Last War), com identidade própria.
- **Feito:** layout das 10 telas de menu, só com espaços reservados, e 5 mapas do modo Desarmar com regras de equilíbrio testadas.
- O cenário de Brasília está sendo construído pelo Codex.
- Registro completo em `PVP_v0.1.md`.
- Nada publicado; a `Main.tscn` e o jogo instalado não mudaram.
- Testes: `pvp_menu_smoke` passou (10 telas); `test_mapas_pvp` 67/67; `--py` 10/10.

### Cidade 3D, M8 (sessão 1.6, 14/11/2026)

- **Feito no projeto de arte e teste `tools/arte3d/`**, separado do jogo; o jogo instalado e o OTA não mudaram.
  - Fusão de malhas: até 4 superfícies por construção e faixa, idêntica às folhas pixel a pixel.
  - LOD por zoom.
  - Cidade de 80 lotes em retrato, com arrastar e pinça nos limites da seção 3.1.
  - Selos em 2D.
  - Painel de medição para o aparelho.
- **Contagens medidas** (Godot 4.7.2 oficial, GL Compatibility), cidade cheia no nível 30 com sombra: de 59 a 166 chamadas de desenho e de 227 a 360 mil triângulos. Sem a fusão seriam de 3.107 a 13.266 chamadas. Tabelas em `sessoes/HANDOFF-1.6.md`; dados em `logs/cidade3d/`.
- **O tempo de quadro local não vale:** a máquina de teste desenha por software. **Os 30 FPS em Samsung e Xiaomi ainda não foram medidos.** O roteiro está em `ROTEIRO_APARELHO_M8.md`, e o APK de teste (pacote separado `ink.evolu.mundo.teste3d`) depende do OK do dono.
- **Arte:**
  - Banco da cidade e Centro tecnológico nas seis faixas, à espera da avaliação do dono.
  - Prefeitura no lugar do Quartel-general (receita e letreiro).
  - Catálogo `catalogo_15_construcoes.png`.
- **Testes:**
  - `smoke_cidade.gd` passou;
  - `test_cidade3d.py` entrou no `--py`;
  - componentes 12/12 e economia 37/37.

## 2. O que está onde

| Conteúdo | `main` (site) | `release/valdora-android` | Produção em 11/11 |
|---|---|---|---|
| Manifesto OTA | revisão 10 (city-9) | revisão 10 (city-9, CP011) | **revisão 10 (city-9)**, deploy de 12/11 |

- Em 12/11/2026, com "OK, subir" do dono, a `main` avançou em fast-forward de `6f397f5` para `18317b3` (branch `publicar/ota-rev10`): manifesto revisão 10, `city-9.zip` e `vercel.json` que limita o deploy automático à `main`. Gerou 1 deploy de produção na Vercel. A revisão 9 nunca chegou à produção; saltou da 8 para a 10.
- Falta confirmar no celular que a Cidade v9 chega pelo OTA (homologação do dono).
- **CP012** (governança regional, será `city-12`) e **CP013** (HUD 3D) existem só no computador do dono. O CP013 muda o núcleo e exige APK novo.

## 3. Branches

- `main`: site, Vercel e OTA. Não tem `project.godot`.
- `release/valdora-android`: jogo completo.
- 22 branches `feat/` e `fix/` de checkpoints (CP001–CP011 e correções): históricas, não recebem push.
- Trabalho novo nasce no computador e só sobe em marco fechado.

## 4. Como a atualização chega ao celular

- **Módulos** (Cidade, guia, mensagens): ao abrir o app com internet, ele lê o manifesto OTA, baixa o que mudou, confere SHA-256 e assinatura RSA-3072 e ativa. Se algo falhar, mantém a versão anterior.
- **Núcleo** (HUD, mundo, combate, heróis, economia): só muda com APK novo instalado por cima, com o mesmo certificado e versionCode maior.
- Os módulos não vão dentro do APK. Vêm do servidor na primeira abertura.
- Fluxo completo em aparelho físico: não provado além do que o CP006 registra como homologado pelo dono.

## 5. Automação e custo

Workflows da `release` (a `main` só tem `valdora-android-release`):

| Workflow | Disparo |
|---|---|
| `valdora-android-release` | manual (`workflow_dispatch`) |
| `valdora-cp004-ota` | manual; roda 5 dos 15 smokes Godot (core, hero, combat, update, cp011) |
| `valdora-cp001`, `cp002`, `cp003-combat`, `cp003c-arena` | push só nas branches históricas respectivas, ou manual |

- O repositório é público: runners padrão do GitHub Actions não consomem franquia. Levantamento de 11/11 (execuções de 08 e 09/11, em UTC): 38 execuções, 19 falharam, cerca de 42 min no total.
- **Vercel Hobby: 100 deploys por dia, por equipe.** Nos 40 deploys mais recentes do projeto `channel`, feitos em 2h51 na noite de 08/11, 36 eram previews de branches e 22 foram cancelados. A equipe tem outros 5 projetos que dividem a mesma cota.
- `git.deploymentEnabled` em `site/vercel.json` está na `main` desde 12/11: só a `main` gera deploy. A `release` ainda não tem esse arquivo; a branch `docs/fase0-base-de-verdade` traz a versão mínima para ela.
- OTA revisão 10 publicada em 12/11 (ver seção 2). O cliente não aceita voltar a uma versão de módulo menor: correção é sempre uma versão nova.
- Segredos: `VALDORA_ANDROID_KEYSTORE_B64` e `VALDORA_ANDROID_KEYSTORE_PASSWORD` no GitHub Secrets; chave privada OTA em pasta restrita do Drive. Nenhum deles entra no repositório, nos ZIPs ou na Vercel.

## 6. Testes

- `game/tests`: 16 smokes Godot (o `city_visual_smoke` entra no `--all`; ainda não executado) e 7 testes Python (`componentes`, `mundo_brasil`, `economia_mundo` e `cidade3d` são do jogo novo). Fora do jogo: `tools/arte3d/smoke_cidade.gd` (precisa de renderizador; ver `tools/arte3d/LEIAME.md`).
- Comando único: `tools/run_valdora_tests.sh`. Sem opção, roda Python mais os 8 testes Godot que os workflows rodam hoje. Com `--py`, só Python. Com `--all`, inclui os 4 smokes extras que devem passar hoje. Com `--historico`, inclui também CP008, CP009 e CP010, que estão presos às revisões 7, 8 e 9 do manifesto e falham por desenho contra o manifesto atual. O script copia o manifesto e os ZIPs de `site/updates/v2/` para `game/tests/fixtures/` antes dos smokes, como o workflow `cp004-ota`; sem essa cópia 10 smokes falhavam (defeito corrigido em 12/11).
- Godot esperado: 4.7.2 (Linux x86_64, zip com SHA-256 `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`).
- **Primeira execução real dos smokes: 12/11/2026**, Godot 4.7.2 oficial com o hash conferido, código do jogo igual ao da release `8a29073`. Log em `game/docs/logs/smokes_2026-11-12.log`.

| Grupo | Resultado em 12/11 |
|---|---|
| Python (5 verificações) | passou |
| 8 smokes do CI: core 12/12, heróis 13/13, combate 42/42, cena 22/22 e 25/25, OTA 15/15, PCK 6/6, CP006 8/8, CP011 44/44 | passou |
| Extras: CP005 11/11, CP007 22/22, layout de nome 14/14 | passou |
| `remote_update_smoke` | não conclusivo: exige rede até channel.evolu.ink, bloqueada na máquina de teste |
| Históricos CP008, CP009, CP010 | falham só nas checagens de revisão do manifesto (CP010: 45 de 48, as 3 que faltam são `manifest_9`, `module_8`, `signed`) |

- Portão G1 da Fase 1: aberto. Falta só rodar `remote_update_smoke` numa máquina com acesso ao domínio e registrar aqui.

## 7. Documentos que contradiziam o estado real

Corrigidos em 11/11/2026 com nota datada no topo, sem reescrever o histórico:

- `CP004_OTA_MODULAR.md`: falava em fase de construção e em APK 0.4.0 não homologado.
- `RELEASE_ANDROID_PERMANENTE.md`: descrevia a 0.4.0 e um gatilho de push em `build.request` que não existe mais; o workflow só roda manualmente.
- `ARQUITETURA.md`: dizia "sem Actions/jobs", pacote `ink.evolu.channel`, sem combate e sem validação de atualização.
- `README.md` da raiz: dizia "sem GitHub Actions"; vale só para o addon Minecraft.
- `game/README.md`: descreve a Alpha 0.2.1.

Ainda abertos: o `GDD Mestre v0.4.1` não está no repositório, e os documentos `docs/` da raiz são da era Minecraft, não do jogo atual.

## 8. Pendências que dependem do dono

1. Entregar o GDD Mestre v0.4.1, se existir; senão, redesenhar.
2. Entregar os pacotes completos do CP012 e do CP013.
3. Responder as decisões 1 a 4 do plano de continuidade.
4. ~~Instalar e homologar o APK 0.4.1~~ feito em 13/11/2026, com os defeitos listados na seção 1.
5. ~~Primeira execução real dos smokes~~ feita em 12/11/2026 (seção 6). Resta rodar `remote_update_smoke` numa máquina com acesso a channel.evolu.ink.

## 9. Decisões vigentes

O dono delegou as decisões em 11/11/2026. Ele pode reverter qualquer uma.

- **PvP é paintball (decisão do dono, 16/11/2026):** todas as armas disparam tinta, com respingo colorido no cenário e no adversário. Referências: `PVP_REFERENCIAS_1.8.md`.
- **Heróis (decisão do dono, 16/11/2026):** o 11º herói da referência (macacão preto e amarelo, óculos na testa) é o representante do Brasil.
- GDD: reconstruído a partir do código e dos CP, marcado como reconstruído. A cópia do dono prevalece se aparecer.
- `release/valdora-android` é o tronco do jogo. A `main` fica só com site e OTA até a G2.
- Testes locais e gratuitos. Workflow manual do GitHub só em marco fechado.
- Meta de 30 FPS estáveis em Samsung e Xiaomi, medida na Fase 4.
- Primeiro laço da Fase 3: combate que dá moedas e experiência aos heróis.
- Online fora até a G3.
- A versão do app nunca cai abaixo do code 103. "Valdora 0.1" é só o nome do ciclo de trabalho iniciado em 11/11/2026.

## 10. Como retomar

1. Esta branch (`docs/fase0-base-de-verdade`, base: release `8a29073`) tem o registro, o script de testes e o `site/vercel.json` mínimo; a branch `claude/zealous-tesla-kfhwld` a continua com a correção do script e o log de 12/11. A branch `publicar/ota-rev10` (base: `main` `6f397f5`) tem o `vercel.json` completo e a publicação da revisão 10. Nenhuma das duas foi integrada à release ou à `main`.
2. `tools/run_valdora_tests.sh --all` já rodou com o Godot 4.7.2 em 12/11 (seção 6). Repetir a cada marco; no computador do dono, rodar também o `remote_update_smoke`.
3. Revisão 10 publicada em 12/11 (`main` = `18317b3`). Próxima publicação segue o mesmo rito: branch `publicar/...` a partir da `main`, conferir fast-forward e assinatura, "OK, subir" do dono, 1 deploy.
4. Fase 2 quando chegarem os pacotes completos do CP012 e do CP013.
5. Regras de custo: o único gasto pago é a assinatura Claude; franquias só com aviso e estimativa; a Vercel Hobby aceita 100 deploys por dia por equipe; o cliente rejeita módulo de versão menor, então correção de OTA é sempre versão nova; segredos nunca entram no repositório, em ZIP, na Vercel ou em documento.
