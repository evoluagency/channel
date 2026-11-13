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
