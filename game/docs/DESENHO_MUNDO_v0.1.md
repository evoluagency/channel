# Desenho do jogo moderno — Mundo v0.1 (piloto Brasil)

Escrito em 13/11/2026 (sessão 1.1, continuação). Nome do jogo: **provisório "MUNDO"** (o dono escolherá entre Terravia, Atlaris, Nexora, Vantara, Orbena e Kardia; disponibilidade como marca ainda não verificada). O Valdora vira o jogo de origem de onde se reaproveita código, não o produto.

Este documento é proposta. Valores numéricos são ponto de partida de balanceamento, não homologados. Nada daqui foi implementado.

## 1. Decisões

**Aprovadas pelo dono (13/11/2026)**

1. Reskin do mesmo jogo, no cenário moderno. Sem zumbis; ameaça humana: facções rivais e mercenários.
2. Só o **mapa-múndi** e as **divisões de estado** são reais. Todo o resto (tecnologias, facções, história, nomes de unidades) é fictício.
3. Seis ambientes, um por continente (América do Norte, América do Sul, Europa, Ásia, África, Oceania). Dentro de cada ambiente, uma variação por país. Antártida: região neutra.
4. Alianças em níveis (tratado, bloco, assembleia). As guerras acontecem entre alianças, por território.
5. Terra fixa por jogador, no mapa-múndi.
6. **Brasil como piloto**, com os 27 estados; um estado por jogador, cada um com tamanho e perfil próprios.
7. Reaproveitar do Valdora só o que for reutilizável (seção 9).
8. Fase A offline e local antes de qualquer servidor; online fica na G3.
9. **Modo retrato** (13/11/2026, sessão 1.3): o jogo inteiro roda com o celular em pé. Navegação na seção 3.1.
10. **Servidor = país; estado = terreno com muitos jogadores** (13/11/2026, sessão 1.3). Cada estado é habitado por vários jogadores, cada um com a sua base. O **Distrito Federal é a capital**: os jogadores dos estados se organizam e disputam a capital em guerra; quem a controla torna-se o **presidente do servidor**. Primeiro objetivo: um servidor Brasil com milhares de jogadores. Servidores de outros países e de regiões (América do Sul, Central, do Norte etc.) ficam para atualizações futuras. Regras propostas na seção 4.1; substitui a ideia de "um estado por jogador" das seções 4 e 5.
11. **Sociedade e economia** (13/11/2026, sessão 1.3): servidores com nome de país; **movimentos** de até 100 membros disputam o governo do estado por via pacífica ou guerra civil; regiões fortes em 2 ou 3 recursos; migração livre; comércio entre jogadores; o jogo é o banco (colchão ou banco, taxas, empréstimo por saúde fiscal); obra acelera com investimento. Detalhes e propostas em `SOCIEDADE_ECONOMIA_v0.1.md`; os movimentos substituem as alianças da seção 6 no nível do estado.
12. **Ritmo da temporada** (13/11/2026, sessão 1.3): temporada de **30 dias**. Cerca do dia 15, um movimento toma o governo do estado; cerca do dia 30, a presidência. Quem não paga chega ao **nível 20 em 30 dias** (e ao 30 em cerca de 60); **quem paga chega ao nível 30 na metade do tempo**, ou seja, em cerca de 30 dias. Se for preciso, aumentar o número de níveis. Compras com dinheiro real só pelo sistema do Google (M13); o que se compra acelera o próprio jogador e nunca é transferível para outro (`SOCIEDADE_ECONOMIA_v0.1.md`, seção 6).

**Pendentes (nenhum bloqueia o documento, mas bloqueiam a arte e o nome)**

- Direção visual: A (Concreto e Sinalização), B (Neon Tático) ou C (Horizonte Aberto). Prévia: https://claude.ai/artifact/7ZdEi4EiADxRTxHEQLhfGe
- Nome do jogo (dois finalistas).
- Como o jogador recebe o estado: escolha livre, sorteio ou ordem de chegada (seção 5).
- Territórios disputados como zona neutra (proposta da seção 3; falta o OK).
- Se o app novo mantém o pacote `ink.evolu.valdora` ou terá pacote próprio (seção 9).

## 2. Visão em uma página

Um jogo de base e estratégia em mundo compartilhado. O jogador governa um **estado** de um país real do mapa, cresce sua economia com a tecnologia do ambiente, firma alianças e disputa território. Os heróis e o combate vêm do Valdora, reinterpretados como equipes modernas.

Hierarquia: **Mundo → Continente (ambiente) → País → Estado (território do jogador) → Lotes (onde se constrói)**.

## 3. Mapa e dados

- **Fonte:** Natural Earth, divisões administrativas nível 1, domínio público. Conferido em 13/11/2026: a base de escala 1:50 milhões, baixada de `github.com/nvkelso/natural-earth-vector`, traz o Brasil com 27 unidades corretas; essa versão cobre só 9 países. A versão 1:10 milhões da mesma fonte cobre o mundo; **ainda não foi baixada nem conferida**.
- **Processamento (offline, no repositório):** script Python lê o GeoJSON, simplifica os contornos (Douglas-Peucker), calcula área, centroide, litoral e vizinhos, e grava um arquivo compacto por país em `game/data/mundo/`. O jogo lê esse arquivo; não lê a fonte.
- **Tamanho:** meta de até 1 MB por país grande após simplificar. Conferir no marco M1.
- **Territórios disputados** (por exemplo Taiwan, Crimeia, Caxemira): aparecem como **zona neutra**, como a Antártida, sem escolher lado. Proposta; precisa do OK do dono.
- **Antártida:** nenhuma unidade pertence a jogador. Zonas de recurso e evento disputadas por todos. Não entra no piloto.
- **Resolução:** a tela mostra o estado do jogador em detalhe e os vizinhos simplificados. O mapa-múndi completo é só navegação.

### 3.1 Tela e navegação (decisão do dono, 13/11/2026)

O jogo é em **retrato**. Referência de tela: 1080 × 2340 px (proporção 9:19,5; telas mais curtas só mostram menos na altura).

- **O conteúdo não precisa caber na tela.** O jogador arrasta com um dedo em qualquer direção para ver o resto e usa dois dedos (pinça) para aproximar e afastar.
- **Afastar tem limite.** O zoom de afastar para quando o próprio estado ainda é legível: proposta, o estado nunca fica com menos de 60% da largura da tela. Assim ele nunca vira um ponto minúsculo.
- **Aproximar tem limite.** No mapa, até o estado ocupar duas larguras de tela; o arquivo `BR.json` foi simplificado para esse zoom (erro de cerca de 2 px). Mais perto que isso é a vista dos lotes e prédios (M4).
- **Arrastar tem limite.** Até a caixa do próprio estado mais meia tela de folga, para ver as divisas e os vizinhos sem se perder.
- **Botão do país.** Um botão mostra o Brasil inteiro (vista macro). Em retrato, o Brasil cabe na largura e ocupa cerca de metade da altura; nessa vista também há arrastar e pinça, limitados ao país. Outro botão volta ao próprio estado.
- **Toque num estado** (na vista do país) abre aquele estado e mostra as bases dos outros jogadores que estão nele.
- Pontos de toque com pelo menos 48 dp; estados pequenos (DF, SE, AL) recebem uma área de toque maior que o desenho.

**Respondida em 13/11/2026 (decisão 10):** vários jogadores por estado; ver a seção 4.1. Texto original da pergunta: "as bases dos outros jogadores" dentro de um estado indica que **um estado terá vários jogadores**. O desenho atual (seção 5) prevê um estado por jogador, com 40 a 120 lotes só dele. Com 27 estados, isso limita o Brasil a 27 jogadores por mundo. É preciso decidir entre (a) um jogador por estado, em vários mundos paralelos de 27; ou (b) vários jogadores por estado, cada um com sua base, e o estado como região disputada. A escolha muda o sentido dos lotes e o M4.

## 4. O jogador e o estado

Cada estado vira um território com **lotes** (a grade isométrica da Cidade atual, mas com formato e tamanho do estado).

**Tamanho (lotes).** A área real é comprimida em escala logarítmica, para o estado grande não dominar:

`lotes = round(clamp(40 + 32.9 × log10(área_km² / 5760), 40, 120))`

Com isso o Distrito Federal tem 40 lotes e o Amazonas 120, em vez de 260 vezes de diferença. (Proposta; testar no M2.)

**Compensação.** Tamanho não é poder:

| Característica | Estado grande | Estado pequeno |
|---|---|---|
| Lotes | Mais | Menos |
| Custo de transporte entre lotes | Maior (cresce com a distância) | Menor |
| Produção por lote | Menor (recursos espalhados) | Maior (bônus de densidade) |
| Tempo de obras | Mais lento | Mais rápido |

**Perfil (gerado dos dados reais).** Cada estado recebe: bioma dominante, litoral (sim/não e extensão), vizinhos, vocação (uma tecnologia de assinatura fictícia ligada ao que o estado é conhecido por produzir) e um conjunto de recursos. O perfil define o mapa de terreno, os recursos disponíveis e a estrutura exclusiva.

**Bônus de vocação:** pequeno (cerca de 5 a 10%). Nenhum estado é "o melhor". A estrutura exclusiva só funciona em quem a construiu; o produto dela pode ser comerciado.

### 4.1 Servidor, estados habitados e presidência (proposta sobre a decisão 10)

**Hierarquia nova:** Servidor (país) → Estado (terreno compartilhado) → Base do jogador (lotes) → Prédios.

**Base do jogador.** Todas as bases têm o **mesmo tamanho** (proposta: 80 lotes, liberados pela tabela do QG, de 15% a 95%). Assim nenhum jogador nasce mais forte pelo estado onde mora, e a compensação por densidade estudada na sessão 1.3 deixa de ser necessária. O estado dá identidade: bioma, vocação, recursos fortes (+5%) e vizinhos.

**Quantos jogadores.** O servidor tem uma capacidade total de bases, repartida entre os estados pela fórmula de tamanho da seção 4 (o antigo número de "lotes" do estado vira o **peso** dele). Proposta: **2.000 bases por servidor Brasil** para começar. Com esse total, o menor estado habitado (SE) recebe 50 vagas e o maior (AM) 101. Quando o servidor enche, abre-se um novo servidor Brasil (Brasil 1, Brasil 2...), o padrão do gênero. O número é um parâmetro: subir para 5.000 só muda a escala (SE 124, AM 252). A conta de custo e capacidade do servidor online (M10) decide o teto real.

**Distrito Federal.** Proposta: o DF **não recebe bases de jogador**; é a zona da capital, neutra no começo da temporada e disputada. As vagas dele são redistribuídas entre os 26 estados habitados.

**Caminho até a presidência (proposta):**
1. O jogador escolhe o estado onde vai morar (atribuição: decisão pendente, seção 5) e entra numa aliança.
2. Cada estado tem a sua **capital estadual** (posição real da capital no mapa) como ponto de disputa. A aliança que a controla governa o estado: título de governador para o líder e um bônus pequeno para o estado.
3. Em janelas marcadas da temporada, as alianças disputam a **capital federal (DF)** em guerra. Quem a controla ao fim da janela faz o **presidente do servidor**.
4. O presidente distribui cargos (ministérios com bônus pequenos para o servidor ou para alianças) até a próxima disputa.
5. Mais tarde: guerra entre servidores (países) e entre regiões, em atualizações futuras.

**Fase A (offline):** o jogador mora num estado com bases NPC ao redor; governos estaduais e a presidência são disputados contra alianças NPC, com regras determinísticas.

**Aprovado pelo dono em 13/11/2026:** base de 80 lotes igual para todos, 2.000 bases por servidor Brasil, DF sem bases. Vagas por estado em `game/data/mundo/BR_perfis.json` (SE 50 a AM 103). Cargos do presidente: sessão 1.4.

## 5. Piloto Brasil: os 27 estados

> Pela decisão 10, a coluna "Lotes" passa a ser o **peso** do estado na repartição das vagas de base do servidor (seção 4.1), e não o tamanho da base de um jogador.

Lotes pela fórmula acima, com as áreas oficiais aproximadas (IBGE). Conferido na sessão 1.3 (`MUNDO_BRASIL_DADOS_v0.1.md`): BA e PE corrigidos pela fórmula (105 → 106 e 80 → 81) e MT com a Amazônia como bioma dominante (proposta). Dados finais em `game/data/mundo/BR_perfis.json`. Bioma e vocação são **proposta** para revisão; vocações são fictícias e só inspiradas no perfil econômico geral.

| UF | Estado | Lotes | Bioma | Vocação (proposta) |
|---|---|---|---|---|
| AC | Acre | 88 | Amazônia | Bioeconomia |
| AL | Alagoas | 63 | Mata Atlântica | Bioenergia |
| AP | Amapá | 86 | Amazônia | Energia hídrica e porto |
| AM | Amazonas | 120 | Amazônia | Eletrônica (polo industrial) |
| BA | Bahia | 106 | Caatinga, Cerrado, Mata Atlântica | Petroquímica e renováveis |
| CE | Ceará | 86 | Caatinga | Energia eólica e porto |
| DF | Distrito Federal | 40 | Cerrado | Administração e dados |
| ES | Espírito Santo | 70 | Mata Atlântica | Portos e minério |
| GO | Goiás | 98 | Cerrado | Agroindústria |
| MA | Maranhão | 98 | Cerrado, Amazônia | Logística portuária |
| MT | Mato Grosso | 112 | Amazônia, Cerrado, Pantanal | Grãos em escala |
| MS | Mato Grosso do Sul | 99 | Cerrado, Pantanal | Pecuária e celulose |
| MG | Minas Gerais | 106 | Cerrado, Mata Atlântica | Mineração e metalurgia |
| PA | Pará | 117 | Amazônia | Mineração |
| PB | Paraíba | 73 | Caatinga | Tecnologia e solar |
| PR | Paraná | 91 | Mata Atlântica | Agroindústria e automotivo |
| PE | Pernambuco | 81 | Caatinga, Mata Atlântica | Saúde e software |
| PI | Piauí | 94 | Caatinga, Cerrado | Eólica e solar |
| RJ | Rio de Janeiro | 69 | Mata Atlântica | Petróleo offshore e pesquisa |
| RN | Rio Grande do Norte | 72 | Caatinga | Eólica e sal |
| RS | Rio Grande do Sul | 96 | Pampa | Máquinas e pecuária |
| RO | Rondônia | 93 | Amazônia | Hidrelétrica e agro |
| RR | Roraima | 92 | Amazônia | Fronteira e logística |
| SC | Santa Catarina | 80 | Mata Atlântica | Têxtil, naval e software |
| SP | São Paulo | 94 | Mata Atlântica, Cerrado | Indústria e finanças |
| SE | Sergipe | 59 | Caatinga, Mata Atlântica | Petróleo e gás |
| TO | Tocantins | 95 | Cerrado | Agro e logística |

**Atribuição ao jogador (decisão pendente).** Opções:
1. **Escolha livre**, por ordem de chegada. Simples; gera disputa pelos estados "bons".
2. **Sorteio.** Justo no início; pode desagradar.
3. **Leilão** com moeda do jogo. Interessante; mais complexo.

Recomendação: escolha livre, com o perfil do estado visível antes de confirmar, e trocar só com custo.

**Sem jogador no estado:** controlado pelo jogo (NPC). O mapa não tem buracos. Se houver mais jogadores que estados num país, o estado passa a ter vários lotes de cidade e a governança do estado vai para quem tiver mais influência; no piloto isso fica fora.

## 6. Alianças e guerra

| Nível | Inspirado em | Regra |
|---|---|---|
| Tratado | acordos bilaterais | Dois membros, um tema (comércio, defesa, tecnologia). Troca de produtos e rotas mais baratas. Obrigações e cota de entrega. |
| Bloco | blocos econômicos | 3 a 6 membros, vários países. Projeto conjunto com custo dividido e bônus para todos. Quem não cumpre perde reputação. |
| Assembleia | organização global | Todos os países. Propõe e vota resoluções (embargo, ajuda, regras de disputa). Voto pesa por influência. |

Nomes das organizações são fictícios; nenhuma sigla ou marca real.

**Guerra.**
- Entre **alianças**, por controle de região e postos avançados. Não é o país A contra o país B.
- Perde-se território e recurso, não a base: a cidade do jogador nunca é apagada.
- Proteção de novato e janelas de ataque. Jogador offline não é atacado fora da janela.
- Facções rivais e mercenários são NPC que disputam regiões neutras e vendem serviço a qualquer lado.

Na Fase A tudo é resolvido no aparelho, com regras determinísticas (mesma seed, mesmo resultado), reaproveitando o motor do Valdora.

## 7. Fases

**Fase A: offline e local (primeira entrega).**
Mapa do Brasil, escolha do estado, perfis, cidade em lotes do formato do estado, produção, os outros 26 estados NPC, tratado e um bloco simples, guerra contra NPC. Tudo local, testável e sem custo. Critério de pronto: homologada pelo dono em aparelho.

**Fase B: online (G3).**
Servidor decide os resultados; jogadores reais no lugar dos NPC; temporadas (novo mundo quando um país enche). Exige servidor e moderação. Custo: a decisão é do dono; o plano gratuito do Supabase só serve para protótipo. Nada pago sem pedido dele.

## 8. Ordem de construção do piloto

| Marco | Entrega | Como se verifica |
|---|---|---|
| M0 | Este documento aprovado; direção visual e nome escolhidos | OK do dono |
| M1 | ✅ (1.3) Script que gera o Brasil a partir do dado aberto, arquivo em `game/data/mundo/` | Teste Python: 27 unidades, área e vizinhos corretos; tamanho do arquivo |
| M2 | Perfis dos 27 estados e fórmula de lotes | Teste: faixa 40 a 120, ordem por área, nenhum estado com campo faltando |
| M3 | Tela do mapa do Brasil em Godot, em retrato (contornos, arrastar, pinça com limites, botão do país, toque para selecionar; seção 3.1) | Smoke Godot + captura de tela |
| M4 | Escolha do estado e Cidade nos lotes com o formato do estado | Smoke; save compatível e versionado |
| M5 | NPC, tratado e bloco | Smoke determinístico |
| M6 | Guerra por região contra NPC | Smoke determinístico |
| M7 | Homologação em aparelho | Dono |

### Depois da Fase A: online e loja (registrado em 13/11/2026)

| Marco | Entrega | Como se verifica |
|---|---|---|
| M8 | Desempenho da cidade 3D: malhas fundidas por material, nível de detalhe, 30 FPS em Samsung e Xiaomi | Medição em aparelho; contagem de chamadas de desenho |
| M9 | OTA só de conteúdo (imagens, textos, balanceamento, eventos); lógica do jogo dentro do app, para cumprir a regra do Google contra baixar código executável | Smoke: módulo OTA sem script; app atualiza conteúdo |
| M10 | Servidor online no Supabase (plano gratuito, protótipo): login, saves, alianças, chat em tempo real e funções que validam ataques e compras no servidor | Testes de API; nenhum resultado decidido pelo celular |
| M11 | Preparação da loja: nome e pacote definitivos do app (permanentes na Play Store), política de privacidade no site, formulário de segurança de dados, classificação etária, exportação em AAB, Play App Signing com a chave atual | Lista conferida; AAB assinado gerado localmente |
| M12 | Conta no Google Play Console (taxa única de US$ 25; só com OK do dono). Conta pessoal: teste fechado com 12 testadores por 14 dias seguidos; conta de organização: número D-U-N-S | OK do dono; conta verificada |
| M13 | Faixas de teste da loja: interna, fechada e produção, com revisão do Google em cada envio. Compras dentro do app só pelo sistema de pagamento do Google (15% até US$ 1 milhão por ano), se houver loja no jogo | App aprovado em produção |

Arquitetura alvo: a Play Store só distribui o app; o app conversa por HTTPS com a Vercel (atualizações de conteúdo) e com o Supabase (dados e regras online). AWS ou servidor próprio só se a escala exigir e houver receita.

CP012 (governança regional) e CP013 (HUD) deixam de ser pacotes do computador do dono: seu conteúdo é reescrito nos marcos M4 a M6 e na lista `MUDANCAS_NUCLEO_CP013.md`.

## 9. O que reaproveitar do Valdora

Inventário feito em 13/11/2026 sobre `game/`.

| Parte | Decisão | Motivo e ajuste |
|---|---|---|
| `scripts/updates/*`, `tools/ota_manifest.py`, `updates/trust`, workflows de build e testes | **Reaproveitar sem mudança** | Infraestrutura independente do tema: manifesto, assinatura RSA, SHA-256, rejeição de versão menor. Mudar só o domínio/pacote, se o app novo tiver identidade própria (pendente). |
| `scripts/core/save_store.gd`, padrão de save com validação e backup (`city.gd`) | **Reaproveitar** | Mecânica de persistência segura. Esquema novo, compatível com versão. |
| `scripts/combat/pve_engine.gd` (determinístico, seed, rodadas) | **Reaproveitar** | Base do combate e da guerra da Fase A. Trocar nomes de itens e ações medievais. |
| `scripts/heroes/hero_system.gd`, catálogo, formação, atributos | **Adaptar** | Mecânica e atributos ficam. Forças viram Indústria, Informação, Energia e Defesa; classes medievais (guardião, patrulheiro, clérigo, berserker) são renomeadas; descrições e aparências reescritas. |
| `scripts/core/economy.gd` | **Adaptar** | Regras determinísticas ficam; a poção é item medieval e sai. |
| `modules/city/city.gd` (1.760 linhas) | **Adaptar o esqueleto** | Mantém grade isométrica, produção offline, missões, coleta, tratados e estado NPC (CP011). Trocar desenhos e textos pelo cenário moderno; a malha vira o formato do estado; entram perfil e vocação. |
| `scripts/ui/valdora_tema.gd`, estilos do módulo da Cidade | **Adaptar** | Estrutura de constantes e estilos fica; cores seguem a direção escolhida (A, B ou C). |
| Montserrat (fonte) | **Reaproveitar** | Boa legibilidade; licença OFL já no repositório. |
| Cinzel (fonte) | **Provavelmente trocar** | Serifada de título clássico/romano; combina com medieval, não com cenário moderno. |
| Testes, `tools/run_valdora_tests.sh`, `tools_validate.py`, `tools/build_city_zip.py` | **Reaproveitar** | Renomear para o novo jogo. |
| `tools/gerar_site.py` e as cinco páginas | **Reaproveitar o gerador; refazer o conteúdo** | O site fala de Valdora, clãs e forças medievais. |
| Direção visual v1 (violeta e ouro, brasão) | **Manter só se escolher a opção B**; caso contrário, nova direção | Brasão e logotipo VALDORA saem em qualquer caso. |
| Lore (forças, clãs, Valdora), nomes de heróis, `brand_home`, ícone | **Descartar ou reescrever** | Conteúdo do universo antigo. Nomes dos heróis só se o dono quiser manter. |
| OTA rev 10 e `city-9.zip` em produção | **Manter como estão** | O app instalado depende deles. Nada muda sem o dono. |

## 10. Riscos

- **Territórios e fronteiras:** política e loja. Mitigação: base neutra, disputados como zona neutra, guerra entre alianças.
- **Estados pequenos e grandes:** desequilíbrio. Mitigação: compressão logarítmica e compensações; testar com simulação no M2.
- **Servidor:** custo e manutenção. Mitigação: Fase A offline; custo só com decisão do dono.
- **Volume de dados:** 27 estados é viável; cobrir o mundo todo exige geração automática e revisão por prioridade.
- **Escopo:** mundo, alianças e guerra são grandes. Mitigação: marcos pequenos, cada um verificável.
- **Dois jogos no mesmo repositório:** o APK instalado é Valdora. O jogo novo precisa de decisão sobre pacote, certificado e histórico de versão antes de qualquer build.

## 11. Perguntas abertas

1. Direção visual: A, B ou C.
2. Nome do jogo (dois finalistas).
3. Atribuição do estado: escolha livre (recomendada), sorteio ou leilão.
4. Territórios disputados como zona neutra: sim ou não.
5. Pacote do app novo: mesmo `ink.evolu.valdora` (atualiza o Valdora) ou pacote novo (app separado).
6. Nomes dos heróis: manter Pietro, Henzo, Giulia e Arthur ou renomear.
