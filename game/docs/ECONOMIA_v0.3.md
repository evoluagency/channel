# Mundo — Economia v0.3 (sessão 1.5, 13/11/2026)

Substitui, onde diferir, as seções 5 e 6 de `JOGABILIDADE_ECONOMIA_v0.1.md` e a seção 12 de `SOCIEDADE_ECONOMIA_v0.1.md`. As curvas da v0.2 (tempo, custo e produção) não mudaram. Dados: `game/data/mundo_componentes_v0.3.json`, gerado por `tools/mundo/gerar_componentes_v03.py`. Simulação: `python3 -I tools/mundo/simular_economia.py --cenarios`. Teste: `game/tests/test_economia_mundo.py`.

## 1. Decisões do dono nesta sessão

As 6 recomendações da seção 12 de `SOCIEDADE_ECONOMIA` foram aprovadas:

1. Banco sem cobrança.
2. Fila extra de obra e de pesquisa no passe.
3. Centro tecnológico como 15º prédio.
4. Especialização +30%/−20% com limite de 2 prédios por recurso fraco.
5. Bônus de recém-chegado.
6. Migração entre países com teto.

Também foram aprovados, depois das tabelas:

1. **Nordeste forte em alimentos e materiais.** Na atribuição da seção 12, Norte e Nordeste (61% das vagas, nenhum forte em materiais) chegavam ao nível 30 cerca de 3 dias depois das outras regiões.
2. **Fraco continua em −20%.** O comércio entre jogadores fica em 18%; −30% levaria a cerca de 20%.
3. **Faixas de imposto:** verde até 20% somados, amarela até 40%, vermelha acima disso. O estadual e o federal vão de 0 a 30% cada.
4. **Recém-chegado:** obras 50% mais rápidas.

## 2. Regras

| Tema | Regra |
|---|---|
| Regiões | +30% nos 2 recursos fortes e −20% nos 2 fracos; no máximo 2 prédios de cada recurso fraco. As vagas que o fraco perde vão para os fortes, então o total de prédios é o mesmo (na Prefeitura 30: 8 de cada forte e 2 de cada fraco) |
| Fortes | Norte: metal e energia · Nordeste: alimentos e materiais · Centro-Oeste: alimentos e metal · Sudeste: materiais e metal · Sul: alimentos e materiais |
| Mercado | Quem vende oferece a sobra pelo preço de referência + margem (0 a 15%; NPC usa 10%). Quem compra leva das ofertas de todo o país, pro rata, lote mais antigo primeiro. Faltando oferta, o sistema vende no teto (+15%). A oferta com 24 h ou mais o sistema compra no piso (−15%), até 20% da produção diária do vendedor (+1 ponto por nível de pesquisa em Comércio) |
| Impostos | Só na venda (a jogadores e ao sistema), abatidos de quem vende. Estadual: governador, 0 a 30%. Federal: presidente com o Conselho, 0 a 30%. NPC: 5% + 5%. Substituem a taxa de 5% do sistema e as taxas de 0 a 3% e de 0 a 2% da seção 9 |
| Capacidade de pagamento | O sistema mede a carga de cada cidade (impostos pagos ÷ produção, 7 dias) e mostra a faixa. **Verde:** imposto somado até 20%. **Amarela:** até 40%. **Vermelha:** acima de 40%. Não impede nada: avisa o governante e as cidades, com o atraso estimado no ritmo (seção 4) |
| Caos | Estado em vermelha por 7 dias seguidos: o movimento pode declarar guerra civil sem a espera de 7 dias. Um terço ou mais dos estados em vermelha por 7 dias: a destituição do presidente passa a exigir maioria simples do Conselho (14 votos) em vez de dois terços (18) |
| Tesouro | Estadual e federal. Gastam por dia 1/7 do saldo em obras públicas (dreno de moeda), e tudo o que passar do teto (7 dias de arrecadação média). As obras dão bônus de produção = 0,5 × gasto em obras (7 dias) ÷ produção (7 dias), até 3% do estado e 3% do país |
| Centro tecnológico | 15º prédio; abre na Prefeitura 10 com Entreposto 4; tempo e custo de 10% da Prefeitura. Cada 3 níveis do Centro liberam 1 nível em cada linha. Linhas: Produção (+1%/nível), Obras (−1% no tempo/nível), Economia (+5% na proteção do Banco e −0,1 ponto nos juros), Comércio (+1 ponto na cota de venda ao sistema e +1 oferta), Defesa (+2%). Nível k: 15% do tempo e do custo da Prefeitura no nível 3k (no mínimo 10). 10 níveis por linha na temporada; 11 a 20 (tecnologias avançadas, 1 a 2 dias cada) depois da Prefeitura 30 |
| Passe | Obras 60% mais rápidas, produção +75%, +1 fila de obra e +1 de pesquisa. **A produção a mais do passe fica marcada**: só paga obras e pesquisa do próprio jogador; não entra em venda, doação nem migração |
| Banco | Sem cobrança de acesso: construído com recursos, como os outros prédios. Taxas de 2% na entrada e na saída, rendimento e empréstimo como na v0.2 |
| Recém-chegado | Obras 50% mais rápidas enquanto a Prefeitura estiver 3 ou mais níveis abaixo da mediana do servidor. Não vale para cidade migrada. Corte somado (passe, recém-chegado, pesquisa) com teto de 80% |

## 3. Migração entre países e disputa entre servidores

**Migração (forma aprovada; números propostos):**

| Regra | Proposta |
|---|---|
| Item | Item de transferência da loja (preço no M13); 1 por cidade por temporada, só na semana 1 |
| Requisitos | Sem cargo, sem dívida no banco, sem guerra em andamento, cidade com 14 dias ou mais; a cidade sai do movimento |
| O que leva | Prédios, níveis e pesquisa; moeda até 2 dias de produção de referência; cada recurso até 1 dia |
| Excedente | O que passa do teto fica no tesouro do estado de origem |
| Teto do destino | O país recebe até 5% da sua população por temporada, respeitando as vagas de cada estado |

**Disputa entre países (proposta inicial, a confirmar):**

| Regra | Proposta |
|---|---|
| Início | Depois da temporada 1; o servidor não reinicia |
| Calendário de cada temporada | Dias 1 a 21: política interna. Dias 22 a 28: disputa. Dias 29 e 30: resultado e tratados |
| Grupos | 4 países por grupo, pela soma do poder das 200 maiores cidades |
| Pontos | Missões nacionais 40%, território de fronteira 40%, tecnologia 20% |
| Território | Zonas neutras entre os países do grupo; 3 janelas de 2 h na semana da disputa; só cidades com Prefeitura 15 ou mais |
| Prêmio | Produção do país inteiro na temporada seguinte: +5% para o 1º, +3% para o 2º, +1% para o 3º |
| Perdas | Nunca cidade nem nível; só recursos do cofre, como na guerra civil |
| Tecnologia nacional | Linha com nível 11 ou mais pesquisado por 20% ou mais das cidades do país |
| Tratado | O presidente propõe e o Conselho aprova (14 votos). Cada país cede uma linha; quem recebe pesquisa aquela linha 50% mais rápido por 1 temporada (não recebe níveis prontos). Até 2 tratados por país por temporada |

## 4. Simulação v0.3 (5 regiões × 4 perfis, 66 dias, determinística)

### 4.1 Dia em que cada perfil chega ao nível da Prefeitura (média das regiões)

| Perfil | nível 10 | nível 15 | nível 20 | nível 25 | nível 30 | nível no dia 15 | nível no dia 30 | nível no dia 60 | Corte médio por investimento |
|---|---|---|---|---|---|---|---|---|---|
| 5 min/dia | 2,5 | 16,5 | 35,8 | 55,4 | — | 14,0 | 18,0 | 26,0 | 8% |
| 15 min/dia | 1,8 | 13,4 | 29,6 | 46,0 | 63,6 | 15,0 | 19,8 | 28,4 | 17% |
| 30 min/dia | 1,5 | 12,3 | 28,2 | 43,8 | 58,7 | 15,2 | 20,0 | 29,6 | 32% |
| pagante médio (passe, 15 min) | 1,4 | 7,2 | 15,0 | 23,2 | 31,0 | 19,4 | 29,0 | 30,0 | 24% |

### 4.2 Curvas da Prefeitura (as mesmas da v0.2; os outros prédios usam frações)

| Nível | Tempo-base da obra | Custo (valor em moedas) | Produção de referência/h | Preço de 1 h de aceleração |
|---|---|---|---|---|
| 2 | 1 min | 1 | 240 | 240 |
| 5 | 13 min | 16 | 240 | 240 |
| 8 | 2,0 h | 689 | 1.149 | 1.149 |
| 10 | 8,0 h | 3.300 | 1.375 | 1.375 |
| 12 | 1,3 d | 15.800 | 1.646 | 1.646 |
| 15 | 3,7 d | 57.682 | 2.155 | 2.155 |
| 18 | 3,8 d | 77.352 | 2.822 | 2.822 |
| 20 | 3,8 d | 92.975 | 3.377 | 3.377 |
| 22 | 3,8 d | 111.450 | 4.042 | 4.042 |
| 25 | 3,8 d | 146.030 | 5.292 | 5.292 |
| 28 | 3,8 d | 191.233 | 6.929 | 6.929 |
| 30 | 3,8 d | 228.881 | 8.293 | 8.293 |

### 4.3 Moeda por semana, média ponderada de todos os jogadores (em % da produção)

| Fluxo | sem 1 | sem 2 | sem 3 | sem 4 | sem 5 | sem 6 | sem 7 | sem 8 | sem 9 | sem 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| fonte: missões diárias | 7,5 | 6,8 | 6,7 | 6,7 | 6,2 | 5,9 | 5,7 | 5,6 | 5,5 | 5,1 |
| fonte: baús | 2,7 | 2,4 | 2,4 | 2,4 | 2,2 | 2,1 | 2,0 | 2,0 | 1,9 | 1,8 |
| fonte: vendas ao sistema (piso) | 10,5 | 14,7 | 15,6 | 15,0 | 17,8 | 23,8 | 23,8 | 23,6 | 24,3 | 26,5 |
| fonte: rendimento do banco | 0,0 | 0,0 | 0,0 | 0,1 | 0,1 | 0,0 | 0,0 | 0,0 | 0,0 | 0,0 |
| fonte: empréstimos concedidos | 14,7 | 8,0 | 12,1 | 7,5 | 11,1 | 10,2 | 6,3 | 10,8 | 5,5 | 0,0 |
| dreno: aceleração de obra | -14,1 | -16,4 | -20,7 | -16,5 | -15,8 | -16,5 | -11,5 | -14,9 | -6,5 | -2,0 |
| dreno: compras ao sistema (teto) | -0,1 | -0,0 | -0,0 | 0,0 | 0,0 | 0,0 | 0,0 | 0,0 | 0,0 | 0,0 |
| dreno: imposto estadual (vai ao tesouro) | -1,0 | -1,6 | -1,8 | -1,7 | -1,8 | -2,1 | -2,1 | -2,2 | -2,0 | -1,8 |
| dreno: imposto federal (vai ao tesouro) | -1,0 | -1,6 | -1,8 | -1,7 | -1,8 | -2,1 | -2,1 | -2,2 | -2,0 | -1,8 |
| dreno: taxa do banco (2%) | -0,1 | -0,1 | -0,0 | -0,0 | -0,0 | -0,0 | -0,0 | -0,0 | -0,0 | -0,0 |
| dreno: empréstimos pagos (com juros) | -13,5 | -6,8 | -10,6 | -9,2 | -11,5 | -8,4 | -8,2 | -8,5 | -8,0 | 0,0 |
| dreno: cofre saqueado | -0,5 | -0,8 | -0,5 | -0,5 | -0,8 | -0,9 | -0,9 | -1,0 | -1,2 | 0,0 |
| dreno: migração | 0,0 | 0,0 | -0,7 | 0,0 | 0,0 | 0,0 | 0,0 | 0,0 | 0,0 | 0,0 |
| dreno: obras públicas dos jogadores (apoio) | 0,0 | 0,0 | 0,0 | 0,0 | -2,9 | -10,5 | -11,1 | -12,0 | -15,0 | -15,2 |
| **total de fontes** | 35,4 | 31,9 | 36,9 | 31,7 | 37,4 | 42,0 | 37,8 | 42,0 | 37,2 | 33,4 |
| **total de drenos** | -30,3 | -27,2 | -36,2 | -29,5 | -34,6 | -40,4 | -35,9 | -40,7 | -34,8 | -20,8 |
| comércio entre jogadores (transferência, fora dos totais) | 10,2 | 17,6 | 20,4 | 18,6 | 17,9 | 18,1 | 17,6 | 19,5 | 16,5 | 9,6 |
| produção média por jogador/dia (moedas) | 30.965 | 51.399 | 64.053 | 78.878 | 104.481 | 132.809 | 162.595 | 197.281 | 238.870 | 280.700 |

### 4.4 Moeda guardada (M/Y), mercado e tesouros

| Dia | M/Y médio | Comércio entre jogadores (% da produção do dia) | Sistema comprou no piso | Sistema vendeu no teto | Impostos | Saldo dos tesouros (dias de arrecadação) | Bônus das obras públicas (estado + país) |
|---|---|---|---|---|---|---|---|
| 7 | 0,13 | 4,9% | 14,3% | 0,0% | 1,9% | 3,3 | +0,39% |
| 14 | 0,27 | 28,6% | 21,4% | 0,0% | 5,0% | 2,8 | +0,89% |
| 21 | 0,16 | 43,9% | 12,5% | 0,0% | 5,6% | 3,2 | +1,28% |
| 30 | 0,23 | 28,8% | 15,5% | 0,0% | 4,4% | 4,1 | +1,45% |
| 45 | 0,49 | 22,6% | 22,0% | 0,0% | 4,5% | 4,7 | +1,66% |
| 60 | 0,49 | 6,8% | 26,9% | 0,0% | 3,4% | 6,3 | +1,82% |

### 4.5 Regiões: jogador de 15 min (dias 1 a 60, relativo à média das regiões)

| Região | Fortes (+30%) | Fracos (−20%, até 2 prédios) | Prefeitura 20 (dia) | Prefeitura 30 (dia) | Poder | Produção/h | Compras (% da produção) | Vendas a jogadores | Vendas ao sistema |
|---|---|---|---|---|---|---|---|---|---|
| Norte | metal, energia | alimentos, materiais | 29,9 | 63,3 | 1,001 | 0,980 | 21,3% | 16,2% | 16,8% |
| Nordeste | alimentos, materiais | metal, energia | 29,3 | 64,2 | 0,991 | 0,998 | 23,4% | 10,1% | 23,6% |
| Centro-Oeste | alimentos, metal | materiais, energia | 30,0 | 64,0 | 0,999 | 0,988 | 17,9% | 15,4% | 12,8% |
| Sudeste | materiais, metal | alimentos, energia | 29,3 | 63,3 | 1,004 | 1,016 | 20,4% | 11,0% | 20,8% |
| Sul | alimentos, materiais | metal, energia | 29,3 | 63,3 | 1,004 | 1,018 | 23,4% | 10,8% | 23,5% |

### 4.6 Centro tecnológico: níveis de pesquisa (média das regiões)

| Perfil | Centro no dia 30 | Centro no dia 60 | producao (dia 60) | obras (dia 60) | economia (dia 60) | comercio (dia 60) | defesa (dia 60) |
|---|---|---|---|---|---|---|---|
| 5 min/dia | 16,8 | 24,0 | 4,6 | 4,4 | 4,2 | 4,2 | 4,2 |
| 15 min/dia | 18,0 | 27,0 | 5,8 | 5,4 | 5,0 | 5,0 | 5,0 |
| 30 min/dia | 19,0 | 28,6 | 4,2 | 4,2 | 3,8 | 3,4 | 3,4 |
| pagante médio (passe, 15 min) | 27,8 | 29,0 | 4,6 | 4,4 | 4,0 | 4,0 | 3,8 |

### 4.7 Pagante médio e ajuda do movimento

- Passe da temporada: obras 60% mais rápidas, produção +75%, +1 fila de obra e +1 de pesquisa. Equivale a 2.288 h de aceleração. A produção a mais do passe fica marcada e só paga obras e pesquisa do próprio jogador: nunca entra numa venda.
- Ajuda do movimento (10 ajudas por obra, 1% cada): 5 min/dia 243 h, 15 min/dia 288 h, 30 min/dia 330 h, pagante médio (passe, 15 min) 440 h poupadas.
- Sessões em que faltou recurso para iniciar obra: p5 2, p15 0, p30 55, pag 41

**Resumo:** comércio entre jogadores 17,9% da produção; vendas ao sistema 21,0%; impostos 3,9% (carga do jogador de 15 min: 3,3% da produção); regiões: produção 3,9% e poder 1,3% entre a maior e a menor, nível 30 com 0,9 dia de diferença; moeda guardada até 0,49 dia de produção.

### 4.8 Impostos: faixas de capacidade de pagamento (imposto somado, metade estadual e metade federal; margem de 10%)

| Imposto somado | Nível 30, 15 min (dia) | Atraso | Nível 30, pagante | Comércio entre jogadores | Carga do jogador de 15 min (% da produção) | Bônus das obras públicas | Faixa |
|---|---|---|---|---|---|---|---|
| 0% | 63,3 | 0,0 | 30,3 | 18,6% | 0,0% | +0,00% | verde |
| 10% | 63,6 | 0,4 | 31,0 | 17,9% | 3,3% | +1,82% | verde |
| 20% | 64,3 | 1,0 | 31,6 | 17,5% | 6,7% | +3,61% | verde |
| 30% | 65,5 | 2,2 | 32,4 | 16,5% | 10,1% | +5,42% | amarela |
| 40% | 66,9 | 3,7 | 33,8 | 14,9% | 14,2% | +6,00% | amarela |
| 50% | 69,1 | 5,8 | 35,5 | 14,0% | 17,7% | +6,00% | vermelha |
| 60% | 72,2 | 8,9 | 37,5 | 12,8% | 21,1% | +6,00% | vermelha |

### 4.9 Margem de quem vende

| Margem | Nível 30, 15 min (dia) | Comércio entre jogadores | Vendas ao sistema | Produção: maior/menor região | Nível 30: diferença entre regiões (dias) |
|---|---|---|---|---|---|
| 0% | 63,6 | 16,3% | 21,2% | 1,049 | 1,1 |
| 5% | 63,6 | 17,1% | 21,1% | 1,042 | 1,1 |
| 10% | 63,6 | 17,9% | 21,0% | 1,039 | 0,9 |
| 15% | 63,7 | 18,8% | 21,1% | 1,051 | 1,1 |

### 4.10 Bônus de recém-chegado (cidade nova num servidor com mediana na Prefeitura 30; vale até a Prefeitura 27)

| Corte de tempo | Perfil | nível 15 | nível 20 | nível 25 | nível 27 | nível 30 |
|---|---|---|---|---|---|---|
| 0% | 15 min/dia | 13,9 | 30,6 | 48,5 | 55,6 | 67,4 |
| 0% | pagante médio (passe, 15 min) | 7,2 | 15,4 | 24,7 | 28,7 | 34,5 |
| 30% | 15 min/dia | 12,2 | 26,5 | 41,7 | 47,9 | 58,7 |
| 30% | pagante médio (passe, 15 min) | 6,4 | 14,1 | 22,1 | 25,8 | 31,9 |
| 50% | 15 min/dia | 10,1 | 22,2 | 35,8 | 41,8 | 53,2 |
| 50% | pagante médio (passe, 15 min) | 6,2 | 13,2 | 20,8 | 24,4 | 30,1 |

## 5. Leitura e limites

- **Ritmo mantido:**
  - 15 min/dia: nível 20 no dia 29,6 e nível 30 no 63,6 (v0.2: 29,3 e 62,4).
  - Pagante médio: nível 30 no dia 31,0.
  - A pesquisa custa recurso e atrasa cerca de 1 dia; a especialização, com o mercado, quase não atrasa.
- **Regiões:** produção e poder a ±2% da média; o nível 30 com menos de 1 dia de diferença entre regiões.
- **Comércio entre jogadores:** 18% da produção (17% a 21% por semana da 2ª à 9ª), abaixo da meta de 20%. A outra parte da sobra (21%) o sistema compra no piso, como na Fase A. Online, os jogadores devem absorver parte disso. Testado e não adotado:
  - limite de 1 prédio fraco: comércio de 21% a 31%, mas duas regiões não chegam ao nível 30;
  - fraco em −30%: cerca de 20%, com o ritmo mantido.
- **Moeda estável:** a moeda guardada fica abaixo de 0,5 dia de produção. O sistema quase não vende no teto, porque as ofertas de jogadores bastam.
- **Imposto:** pesa pouco no ritmo porque volta como obra pública: o NPC (10%) atrasa 0,4 dia; 40% atrasa 3,7 dias.
- **Passe:** a 2ª fila de pesquisa quase não acelera o pagante, porque falta recurso, não fila.
- **Limite do modelo:**
  - O vendedor não muda a margem conforme a procura; o preço de cada recurso é fixo na margem escolhida.
  - O recém-chegado é simulado num mercado maduro em que o sistema compra a sobra no piso, uma visão conservadora.
