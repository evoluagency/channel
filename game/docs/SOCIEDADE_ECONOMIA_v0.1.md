# Mundo — Sociedade, poder e economia (v0.1)

Escrito em 13/11/2026 (sessão 1.3), a partir das decisões do dono. **Propostas aprovadas pelo dono em 13/11/2026** (termo "movimento", taxas, colchão, regiões, migração, investimento, ciclo); os números seguem como ponto de partida para a sessão 1.4 balancear. Complementa `DESENHO_MUNDO_v0.1.md` (decisão 10 e seção 4.1). **O que está marcado como decisão veio do dono; o resto é proposta**, com números de partida para a sessão 1.4 balancear. Nada implementado.

## 1. Decisões do dono (13/11/2026)

1. **Servidores com nome de país** (Brasil 1, Brasil 2...); regiões do mundo em atualizações futuras.
2. **Movimentos** no lugar de alianças: grupos de jogadores que disputam o governo do estado. Até **100 membros**; o líder decide quem entra e quem sai.
3. **Duas formas de tomar o poder:** pacífica (votação ou outro critério) ou à força (unidades e guerra civil). O caminho depende de como os jogadores se organizam.
4. **Regiões do Brasil** (Norte, Nordeste, Centro-Oeste, Sudeste, Sul) fortes em **2 ou 3 recursos**. O jogador escolhe o estado pelo que lhe interessa.
5. **Migração livre** entre estados.
6. **Comércio entre jogadores** do que produzem (por exemplo, vender energia para financiar obras).
7. **O jogo é o banco:** controla o dinheiro que entra e sai, com taxa de entrada e de saída. Dinheiro no **colchão** (sem taxa, mais exposto) ou **aplicado no banco** (protegido). O banco **empresta** a quem cumpre critérios de saúde fiscal.
8. **Obra mais rápida com mais investimento**, e o investimento depende do quanto se produz: economia girando como na vida real.

## 2. Nome dos servidores

Usar o nome do país é prática comum em jogos e, em princípio, não há impedimento: nome de país não é marca de ninguém. Cuidados propostos:

- **Símbolos oficiais fora:** no Brasil, bandeira, hino, armas e selo nacionais têm uso regulado (Lei 5.700/1971). Proposta: nome do país sim; bandeira e brasão oficiais não. Usar ícone próprio do jogo (silhueta do país e cor).
- **Nada de política real:** bloquear nomes de partidos, siglas e políticos reais em movimentos, bases e chat (lista de bloqueio e moderação no M10).
- **Territórios disputados** seguem como zona neutra (proposta já registrada; falta o OK).
- Antes da loja (M11), uma conferência jurídica simples sobre nomes e símbolos. Não é parecer jurídico; é a recomendação de conferir.

## 3. Movimentos e poder

**Nome:** proposta **"movimento"**. "Partido" lembra demais a política real e atrai nomes reais; "movimento" cabe tanto na via pacífica quanto na tomada à força.

| Regra | Proposta |
|---|---|
| Tamanho | Até 100 membros; o líder define a vaga máxima abaixo disso |
| Cargos | Líder, vice-líderes (até 4), membros. O líder aceita, recusa e expulsa |
| Onde atua | Um movimento tem sede num estado; membros podem morar em estados vizinhos |
| Um por jogador | O jogador está em um movimento por vez; sair tem espera de 24 h |

**Tomar o governo do estado**, em ciclos (proposta: semanais):

- **Via pacífica (eleição):** os moradores do estado votam num movimento candidato. Para concorrer, o movimento precisa de um mínimo de membros morando no estado e de "apoio" acumulado (missões e obras públicas no estado). Voto de 1 por morador ativo.
- **Via da força (guerra civil):** um movimento declara insurreição e ataca a **capital estadual** numa janela marcada. Quem controlar a capital no fim da janela governa até o próximo ciclo. Custo alto (unidades perdidas, produção do estado cai durante a guerra) para a força não ser sempre o caminho mais fácil.
- O **governador** (líder do movimento no poder) define uma taxa estadual pequena sobre o comércio do estado, dentro de uma faixa fixa, e escolhe o bônus do estado entre opções.
- **Presidência:** os governadores e seus movimentos disputam o **DF** (capital federal), também pelas duas vias: votação entre governadores ou tomada da capital em guerra. O presidente define cargos e uma política do servidor por ciclo.

Proteções: jogador novo não pode ser atacado nos primeiros dias; quem não está em guerra não perde a base (perde recurso e território, nunca a cidade).

## 4. Regiões e recursos

Proposta: cada região soma **+20%** de bônus de produção, dividido em 2 ou 3 recursos, para nenhuma região ser a melhor. A vocação do estado (tecnologia fictícia, +5 a 10%) continua por estado.

| Região | Recursos fortes | Ideia |
|---|---|---|
| Norte | metal +10%, energia +10% | mineração e hidrelétricas |
| Nordeste | energia +10%, alimentos +10% | eólica, solar e fruticultura |
| Centro-Oeste | alimentos +10%, metal +10% | grãos e mineração |
| Sudeste | materiais +10%, metal +5%, energia +5% | indústria |
| Sul | alimentos +7%, materiais +7%, energia +6% | agroindústria e Itaipu |

Materiais ficam fortes só em duas regiões, o que cria comércio. Isso substitui os "dois recursos fortes por estado" propostos antes; `BR_perfis.json` muda quando o dono aprovar.

## 5. Migração

- Livre, com espera entre mudanças (proposta: 7 dias) e custo em moedas que cresce com o nível do QG.
- Não pode migrar em guerra, com empréstimo em atraso ou ocupando cargo (governador, presidente).
- A base muda inteira de lugar; o jogador perde o vínculo de voto no estado antigo até o próximo ciclo.

## 6. Economia e banco

**Moeda.** Uma moeda do jogo (nome a definir) ganha só jogando. **Não pode ser comprada com dinheiro real nem sacada.** Se um dia houver moeda premium na loja, ela não pode ser transferida entre jogadores. Isso evita comércio de dinheiro real, fraude e problema com as regras da loja e de jogos de azar.

**Comércio.** Mercado do estado e do servidor com ordens de compra e venda (energia, alimentos, materiais, metal). Preço livre dentro de uma faixa em torno do preço de referência, para evitar manipulação. Cada venda paga uma **taxa do banco** (proposta: 5%) e a taxa estadual do governador (0 a 3%). As taxas tiram moeda de circulação e seguram a inflação.

**Colchão ou banco.**

| | Colchão | Banco |
|---|---|---|
| Taxa | nenhuma | entrada 2%, saída 2% (proposta) |
| Proteção | um ataque vencido leva parte (proposta: até 20%) | protegido |
| Rendimento | nenhum | pequeno (proposta: 1% por semana, com teto) |

**Empréstimo.** O banco empresta conforme uma **nota fiscal** do jogador (0 a 1.000), calculada de: produção crescendo, impostos e taxas pagos, empréstimos anteriores quitados em dia, obras concluídas. Limite e juros saem da nota. Atraso: a produção fica parcialmente retida até quitar, e a nota cai. Sem perda da base.

**Investimento e tempo de obra.** Cada obra tem um tempo-base; o jogador pode investir moeda para acelerar, com custo crescente e redução máxima (proposta: até 50% do tempo). Quem produz e vende mais tem mais para investir. A sessão 1.4 fecha os números com uma simulação dos fluxos (produção, venda, taxas, juros) para a moeda não perder valor.

## 7. Fase A (offline)

Tudo isso existe primeiro contra o jogo: movimentos NPC, eleições e guerras civis NPC, mercado com compradores e vendedores NPC e banco local. Regras determinísticas (mesma seed, mesmo resultado). O mercado entre jogadores reais, o voto e o banco compartilhado exigem o servidor (M10).

## 8. Ritmo da temporada (decisão do dono, 13/11/2026)

- Temporada de **30 dias**: governo do estado por volta do dia 15, presidência por volta do dia 30.
- Sem pagar: **nível 20 em 30 dias**, nível 30 em cerca de 60.
- Pagando: **nível 30 na metade do tempo** (cerca de 30 dias). Se preciso, mais níveis.
- Como o ciclo de governo é semanal (seção 3), a temporada tem cerca de 4 ciclos estaduais; a disputa da presidência fica na última semana.
- As curvas de tempo atuais (`COMPONENTES_NIVEIS_v0.1.md`) levam o QG ao nível 30 em cerca de 4 dias de obra; a sessão 1.4 reajusta tempo, custo e produção para essas metas.

## 9. Aprovado

Termo "movimento"; taxas (banco 2% + 2%, mercado 5%, estadual 0 a 3%); 20% do colchão em ataque; tabela das regiões (já em `BR_perfis.json`); migração com espera de 7 dias; redução máxima de 50% por investimento; ciclo semanal. Aprovados como ponto de partida em 13/11/2026.

## 10. Decisões do dono (13/11/2026, sessão 1.4) e propostas sobre elas

**Decisões:**
1. **A moeda é do próprio sistema.** Não existe um "banco do jogo" como personagem: a moeda está embutida no sistema, e **cada cidade tem o seu próprio banco**. Substitui o "o jogo é o banco" da seção 1, item 7.
2. **Não usar "QG".** O jogador é o **comandante e líder da própria cidade**; ele constrói uma cidade e vai subindo de cargo.
3. **Carreira por cargos:** líder da cidade → cargos no movimento → governador → presidente.
4. **O governador governa com companheiros** escolhidos dentro do próprio movimento.
5. **Movimentos têm representantes** que ajudam a comandar, e têm **nome, sigla e número**, como um partido.

**Propostas (aguardando OK):**

| Tema | Proposta |
|---|---|
| Prédio principal | **Prefeitura** no lugar do Quartel-general; o nível da Prefeitura é o **nível da cidade**. Mesma arte aprovada |
| Banco da cidade | Prédio próprio (o 14º), níveis 1 a 30. Moeda guardada nele fica protegida até a capacidade do nível; o que passa disso fica no cofre exposto (20% num ataque vencido). Taxas de 2% na entrada e na saída, rendimento de 1%/semana com teto e empréstimo pela nota fiscal: tudo regra do sistema, sem saldo central |
| Mercado | O sistema compra e vende nas pontas da faixa de ±15% (âncora da simulação). Números da simulação não mudam |
| Movimento: identidade | Nome (3 a 30 letras), sigla (2 a 6 letras) e número de 2 dígitos (10 a 99), único no servidor, escolhido na fundação |
| Movimento: cargos | Líder; **representantes**: 1 a cada 10 membros, até 10 (com 100 membros). Aceitam e expulsam membros, convocam defesa e votam as decisões do movimento com o líder |
| Governo do estado | O governador nomeia até 4 **secretários** entre os representantes (Economia, Defesa, Obras, Comunicação), cada um com um bônus pequeno para o estado |
| Presidência | O presidente nomeia ministros entre os governadores e representantes do próprio movimento |
| Política real | Bloquear nomes e siglas de partidos reais. Os números de 2 dígitos coincidem com os de partidos reais (por exemplo 13, 22, 45): decisão do dono se ficam liberados ou se ficam fora |

**Respostas do dono (13/11/2026, mesma sessão):** aprovou o ritmo e as curvas; a meta do pagante vale para o **pagante médio**; suavizar o salto do tempo de obra; **Prefeitura** e nível da cidade; níveis da Prefeitura liberam recursos aos poucos, um dependendo do outro; a economia gira em torno da produção; **sigla de até 4 letras** e número de 10 a 99; cidades do mesmo movimento se ajudam, com métrica; **o presidente só nomeia governadores** para os cargos do país e tem **4 secretários** próprios; governadores podem ser oposição e o presidente precisa de aliados. Regras numéricas em `JOGABILIDADE_ECONOMIA_v0.1.md` (seções 4 a 9), que valem sobre a tabela acima onde diferirem (por exemplo, secretários do governador e ministros do presidente).

## 11. Decisões do dono sobre impostos e comércio (13/11/2026, sessão 1.4)

1. **Imposto estadual** (definido pelo governador) e **imposto federal** (definido pelo presidente).
2. **O sistema mede a capacidade de pagamento das cidades** e define um limite de referência. Passar do limite **não é impedido**: gera **aviso** ao governante e às cidades, com os impactos (ritmo menor).
3. Diante do risco de caos, os governadores podem **derrubar o presidente**, com nova eleição ou guerra civil.
4. Cada região tem mais de alguns recursos. As sobras são **vendidas entre estados e entre cidades** (trocas diretas também).
5. **Precificação com margem de lucro** para quem vende. **O imposto incide só na venda** e é abatido de quem vende.

Medida rápida na simulação atual, com o imposto só na venda (sem a taxa de 5% do sistema): imposto de 10% atrasa o nível 30 do jogador de 15 min em 0,4 dia; imposto de 40%, em 1,6 dia (6% da produção). Hoje as vendas são só cerca de 15% da produção, então o imposto sobre venda quase não pesa no ritmo. Ver a crítica registrada no `HANDOFF-1.4.md` e a decisão pendente sobre especialização das regiões.

## 12. Decisões do dono (13/11/2026, fim da sessão 1.4) e recomendações

**Decisões:**
1. **Banco é prédio próprio** (o 14º).
2. **O servidor não reinicia no fim da temporada.** Começa a **disputa entre servidores (países)**: tecnologias podem ser trocadas entre países e cidades podem migrar de um país para outro, **pagando por isso**. As regras da disputa entre servidores ainda não estão definidas.
3. **Siglas e números livres:** não bloquear partidos reais; fica a critério dos jogadores. A moderação do M10 continua valendo para ofensa e fraude.
4. Especialização das regiões: o dono pediu sugestão (abaixo).

**Recomendações (a confirmar na sessão 1.5):**

| Tema | Recomendação | Por quê |
|---|---|---|
| Banco pago? | **Não.** O banco é construído com recursos, como os outros prédios, e todos têm acesso a ele | Proteger a moeda e tomar empréstimo é o centro da economia; cobrar por isso torna o jogo de pagar para ganhar e liga dinheiro real à moeda, que não pode ser comprada |
| O que cobrar (modelo do gênero) | **Fila extra de obra** e **fila extra de pesquisa**, dentro do passe da temporada | É conveniência e velocidade: o pagante vai mais rápido, mas nenhuma regra fica fechada para quem não paga |
| Centro tecnológico | **Sim, como 15º prédio:** árvore de pesquisa (produção, obras, defesa, economia e comércio) com 1 fila grátis e a 2ª no passe | Dá destino de longo prazo depois do nível 30 e é a base das **tecnologias trocadas entre países** da disputa entre servidores |
| Especialização das regiões | **+30% em 2 recursos e −20% nos outros 2**, mais **limite de 2 prédios por recurso fraco** | Teste rápido: só os ±% não criam comércio, porque a cidade constrói mais prédios do recurso que falta (compras ficam abaixo de 1% da produção). O limite de prédios obriga a comprar de outro estado, e aí o imposto sobre a venda passa a pesar |
| Atribuição | Norte: metal e energia fortes; Nordeste: energia e alimentos; Centro-Oeste: alimentos e metal; Sudeste: materiais e metal; Sul: alimentos e materiais. Fracos: os outros dois | Com +30%/−20%, a produção das regiões ficou entre 0,98 e 1,02 da média e o nível 30 entre os dias 62,9 e 63,2 |
| Servidor que não reinicia | Bônus de recém-chegado: obras mais rápidas para quem está abaixo da cidade mediana do servidor | Quem chega na temporada 2 alcança os outros |
| Migração entre países | Item de transferência pago, com requisitos (sem cargo, sem dívida e sem guerra); a moeda e os recursos levados têm teto | Impede levar uma economia inteira de um país para outro |
