# Mundo — Jogabilidade e economia da Fase A (v0.1, proposta)

Sessão 1.4, 13/11/2026. **Proposta aguardando o OK do dono**: só os números de ritmo e economia estão aqui; ciclo diário, poder, NPC e chat entram depois do OK. Nada implementado; o jogo instalado (0.4.1, OTA rev 10) não muda. Gerado por `tools/mundo/simular_economia.py` (determinístico, roda em cerca de 2 s; `--calibrar-tempo` refaz a busca das curvas em cerca de 20 s).

## 1. Metas (decisão do dono, `SOCIEDADE_ECONOMIA_v0.1.md`, seção 8)

Temporada de 30 dias; governo por volta do dia 15 e presidência por volta do dia 30. Sem pagar: QG 20 em 30 dias e QG 30 em cerca de 60. Pagando: QG 30 na metade do tempo. A meta foi calibrada no jogador de **15 min por dia**; 5 e 30 min ficam um pouco atrás e à frente.

## 2. Regras propostas (substituem as fórmulas de `COMPONENTES_NIVEIS_v0.1.md`, seção 1)

| Regra | Antes (v0.1) | Proposta (v0.2) |
|---|---|---|
| Tempo do QG | 60 s × 1,28^(n−1): QG 30 em cerca de 4 dias de obra | Níveis 1 a 10 rápidos (1 min a 6 h; QG 10 em 2 a 4 dias de jogo). Do 11 em diante: 6 h + 76 h × (1 − e^−(n−10)/2): 1,5 d no 11, 2,3 d no 12, 3,2 d no 15 e cerca de 3,4 d do 18 ao 30 |
| Tempo dos outros prédios | 30 s × fator × 1,28^(n−1) | fração do tempo do QG no mesmo nível: Base militar 30%, Alojamento 10%, prédios de produção 3%; 20% da segunda fila fica para os secundários (Radar, Entreposto, Via, Parque, Água, Heliponto) |
| Pré-requisito do QG | só o nível | QG n exige a Usina principal e (do 11 em diante) a Base militar no nível n−1 |
| Custo | materiais × 1,25^(n−1), metal a partir do 5 | QG(n) = 0,30 × produção de referência por hora no QG n × tempo-base em horas; Base militar 40%, Alojamento 10%, produção 4% do custo do QG do mesmo nível |
| Receita do custo | materiais (+ metal do 5) | níveis 1 a 4: materiais 70%, alimentos 30%; 5 a 9: materiais 45%, metal 30%, alimentos 25%; 10 em diante: materiais 30%, metal 25%, energia 25%, alimentos 20% |
| Produção | base × 1,12^(n−1) | igual, com valor de 60 moedas/h no nível 1 (alimentos 60, materiais 60, metal 40, energia 30); offline até 8 h |
| Prédios de produção por tipo | 4 a 20 Estufas | 2 + QG/10 (2 no QG 1, 5 no QG 30) |
| Filas de obra | 2 (suposição) | 2; obra de até 5 min termina na hora |
| Preço de referência | — | alimentos 1, materiais 1, metal 1,5, energia 2 moedas |
| Aceleração por investimento | até 50% | 1 h poupada custa 1 h de produção de referência do QG atual até 25% do tempo; o dobro de 25% a 50% |
| Pagante | — | itens pagos cortam 67% de cada obra e pacotes cobrem falta de recurso; nada transferível |
| Tropas | — | 15% do valor produzido vira tropa (alimentos e metal) |

## 3. Moeda (fontes e drenos)

| Fonte | Proposta | Dreno | Proposta |
|---|---|---|---|
| Missões diárias | 5, 8 e 11% da produção diária de referência (5, 15 e 30 min) | Aceleração de obra | preço da seção 2 |
| Baú por login | 1% (até 3 por dia) | Taxa do mercado | 5% do valor vendido |
| Venda de recursos | Fase A: o banco compra até 20% do valor produzido por sessão, no preço do mercado | Taxa estadual | 0 a 3% (NPC usa 1,5%) |
| Rendimento do banco | 1%/semana até 7 dias de produção | Banco | 2% na entrada e 2% na saída |
| Empréstimo | limite de 2 dias de produção × nota/1.000; prazo 7 dias | Juros | 5%, 3% e 2% por semana com nota 500, 700 e 900 |
| | | Colchão | um ataque vencido por semana leva 20% |
| | | Migração | meio dia de produção |
| | | Obras públicas | moeda parada acima de 1 dia de produção vira apoio ao movimento no estado |

**Mercado com âncora:** preço livre dentro de ±15% da referência; fora da faixa o banco do jogo compra ou vende. Isso prende o valor da moeda aos recursos: ela não pode perder mais de 15% de poder de compra. E o preço da aceleração é fixado em horas de produção do nível, então a moeda também vale o mesmo em tempo.

## 4. Resultados da simulação (60 a 70 dias, 5 regiões × 4 perfis, pesos pelas vagas)

### 1. Dia em que cada perfil chega ao nível do QG (média das regiões)

| Perfil | QG 10 | QG 15 | QG 20 | QG 25 | QG 30 | QG no dia 15 | QG no dia 30 | QG no dia 60 | Corte médio por investimento |
|---|---|---|---|---|---|---|---|---|---|
| 5 min/dia | 4,1 | 18,7 | 37,1 | 56,0 | — | 13,0 | 17,6 | 25,4 | 17% |
| 15 min/dia | 2,5 | 14,9 | 30,1 | 45,7 | 62,9 | 14,0 | 19,0 | 28,8 | 23% |
| 30 min/dia | 1,6 | 13,1 | 27,3 | 41,8 | 57,7 | 15,0 | 20,0 | 30,0 | 28% |
| pagante (15 min) | 1,4 | 7,3 | 14,3 | 22,3 | 30,1 | 20,0 | 29,2 | 30,0 | 12% |

### 2. Curvas propostas (QG; os outros prédios usam fatores)

| Nível | Tempo-base do QG | Custo do QG (valor em moedas) | Produção de referência/h | Preço de 1 h de aceleração |
|---|---|---|---|---|
| 2 | 1 min | 1 | 244 | 244 |
| 5 | 13 min | 17 | 257 | 257 |
| 8 | 2,0 h | 506 | 844 | 844 |
| 10 | 6,0 h | 2.111 | 1.173 | 1.173 |
| 12 | 2,3 d | 28.066 | 1.731 | 1.731 |
| 15 | 3,2 d | 46.438 | 2.043 | 2.043 |
| 18 | 3,4 d | 59.759 | 2.471 | 2.471 |
| 20 | 3,4 d | 68.727 | 2.811 | 2.811 |
| 22 | 3,4 d | 89.147 | 3.632 | 3.632 |
| 25 | 3,4 d | 108.914 | 4.430 | 4.430 |
| 28 | 3,4 d | 133.795 | 5.439 | 5.439 |
| 30 | 3,4 d | 168.679 | 6.857 | 6.857 |

### 3. Moeda por dia, média ponderada de todos os jogadores, por semana (em % da produção)

| Fluxo | sem 1 | sem 2 | sem 3 | sem 4 | sem 5 | sem 6 | sem 7 | sem 8 | sem 9 | sem 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| fonte: missões diárias | 7,3 | 8,4 | 8,2 | 8,1 | 7,9 | 7,8 | 7,5 | 7,1 | 6,7 | 5,7 |
| fonte: baús | 2,7 | 2,9 | 2,9 | 2,9 | 2,8 | 2,7 | 2,6 | 2,5 | 2,3 | 2,0 |
| fonte: vendas (líquidas) | 15,0 | 14,7 | 16,2 | 16,1 | 16,3 | 17,2 | 16,9 | 17,6 | 18,2 | 18,2 |
| fonte: rendimento do banco | 0,0 | 0,1 | 0,1 | 0,1 | 0,1 | 0,1 | 0,1 | 0,1 | 0,1 | 0,1 |
| fonte: empréstimos concedidos | 9,2 | 4,1 | 0,0 | 0,0 | 0,0 | 0,0 | 0,0 | 0,0 | 0,0 | 0,0 |
| dreno: aceleração de obra | -19,0 | -24,2 | -24,0 | -25,8 | -22,8 | -22,6 | -20,7 | -19,9 | -14,0 | -3,0 |
| dreno: compras no mercado | 0,0 | -0,0 | -0,0 | -0,3 | -0,4 | -0,8 | -1,4 | -2,0 | -2,4 | -0,5 |
| dreno: taxa do mercado (5%) | -0,8 | -0,8 | -0,9 | -0,9 | -0,9 | -0,9 | -0,9 | -0,9 | -1,0 | -1,0 |
| dreno: taxa estadual (1,5%) | -0,2 | -0,2 | -0,3 | -0,3 | -0,3 | -0,3 | -0,3 | -0,3 | -0,3 | -0,3 |
| dreno: taxa do banco (2%) | -0,1 | -0,1 | -0,0 | -0,0 | -0,0 | -0,0 | -0,0 | -0,0 | -0,0 | -0,0 |
| dreno: empréstimos pagos (com juros) | -8,7 | -2,9 | -1,6 | 0,0 | 0,0 | 0,0 | 0,0 | 0,0 | 0,0 | 0,0 |
| dreno: colchão saqueado | -0,0 | 0,0 | -0,0 | -0,0 | -0,4 | -0,3 | -0,3 | -0,5 | -1,0 | -1,8 |
| dreno: migração | 0,0 | 0,0 | -0,0 | 0,0 | 0,0 | 0,0 | 0,0 | 0,0 | 0,0 | 0,0 |
| dreno: obras públicas (apoio) | 0,0 | 0,0 | 0,0 | 0,0 | -0,4 | -3,1 | -3,2 | -3,2 | -6,0 | -16,3 |
| **total de fontes** | 34,2 | 30,1 | 27,4 | 27,2 | 27,1 | 27,8 | 27,0 | 27,2 | 27,3 | 25,9 |
| **total de drenos** | -28,9 | -28,3 | -26,8 | -27,2 | -25,2 | -28,0 | -26,9 | -26,9 | -24,8 | -22,8 |
| produção média por jogador/dia (moedas) | 25.258 | 39.939 | 47.710 | 56.432 | 71.539 | 88.295 | 105.795 | 127.624 | 160.113 | 207.905 |

### 4. Moeda guardada por jogador em dias de produção (M/Y) e âncora do mercado

| Dia | M/Y médio | Índice de preços (ref = 1,00) | Emissão líquida da âncora (% do valor vendido) |
|---|---|---|---|
| 1 | 0,05 | 0,922 | 100,0 |
| 7 | 0,22 | 0,850 | 100,0 |
| 14 | 0,26 | 0,850 | 100,0 |
| 21 | 0,40 | 0,850 | 100,0 |
| 30 | 0,38 | 0,850 | 100,0 |
| 45 | 0,44 | 0,850 | 98,2 |
| 60 | 0,53 | 0,891 | 83,9 |

### 5. Regiões: jogador de 15 min (relativo à média das regiões)

| Região | QG dia 15 | QG dia 30 | Poder dia 30 | Produção/h dia 30 | Moeda acumulada no dia 30 (líquida) |
|---|---|---|---|---|---|
| Norte | 14 | 19 | 1,000 | 0,997 | 29.747 |
| Nordeste | 14 | 19 | 1,000 | 0,997 | 29.747 |
| Centro-Oeste | 14 | 19 | 1,000 | 0,997 | 29.747 |
| Sudeste | 14 | 19 | 1,001 | 1,006 | 29.747 |
| Sul | 14 | 19 | 1,000 | 1,003 | 29.747 |

**Pior caso de preço** (bônus da região em % da produção total, com produção igual nos 4 recursos):

| Cenário | Norte | Nordeste | Centro-Oeste | Sudeste | Sul | maior − menor |
|---|---|---|---|---|---|---|
| preços de referência | 5,00% | 5,00% | 5,00% | 5,00% | 5,00% | 0,00 p.p. |
| materiais e metal no teto, alimentos e energia no piso | 5,00% | 4,25% | 5,00% | 5,38% | 4,78% | 1,12 p.p. |
| alimentos e energia no teto, materiais e metal no piso | 5,00% | 5,75% | 5,00% | 4,62% | 5,22% | 1,12 p.p. |

### 6. Pagante (média): o que compra em 30 dias

- Horas de aceleração paga: 2.023 h; recursos comprados: 620.297 moedas de valor.
- Sessões em que faltou recurso para iniciar obra: p5 41, p15 19, p30 59, pag 0

## 5. Leitura

- **Ritmo:** 15 min/dia chega ao QG 15 no dia 15 (governo), ao 20 no dia 30 e ao 30 no dia 63. 30 min/dia: 20 no dia 27 e 30 no dia 58. 5 min/dia: 20 no dia 37. Pagante: 20 no dia 14 e 30 no dia 30.
- **Moeda:** depois da primeira semana (empréstimos iniciais), fontes e drenos ficam entre 23 e 30% da produção e andam juntos, e a moeda guardada fica entre 0,2 e 0,5 dia de produção do dia 7 ao 60: não acumula, então não pressiona preço. O preço fica no piso da faixa (recurso sobrando, moeda escassa): a moeda **ganha** valor, não perde. Na Fase A quem compra é o banco do jogo; online (M10) os jogadores compram uns dos outros e o banco só age nas pontas da faixa.
- **Regiões:** com o mesmo perfil de jogo, poder e produção no dia 30 ficam a menos de 1% entre as cinco. No pior caso de preço (online), a diferença do bônus fica em 1,1 ponto percentual da produção.
- **Pagante:** para dobrar o ritmo compra cerca de 2.000 h de aceleração e 620 mil moedas de recurso em 30 dias (cerca de 67 h por dia). É ritmo de grande pagante; um pagante moderado (corte de 33%, cerca de 490 h no mês) chega ao QG 22 no dia 30. A loja (M13) define os preços.
- **Degrau no QG 11:** a obra salta de 6 h (QG 10) para 1,5 dia. É o fim do início rápido; se ficar brusco no teste, suavizar entre o 9 e o 12.
