# Mundo — Jogabilidade e economia da Fase A (v0.1)

Sessão 1.4, 13/11/2026. **Ritmo, curvas e meta do pagante aprovados pelo dono em 13/11/2026**; as regras das seções 4 a 12 são proposta sobre as decisões dele (marcadas como decisão quando vieram do dono). Nada implementado; o jogo instalado (0.4.1, OTA rev 10) não muda.

Ferramentas: `tools/mundo/simular_economia.py` (simulação determinística, cerca de 2 s; `--calibrar-tempo` refaz a busca das curvas), `tools/mundo/gerar_componentes_v02.py` (gera `game/data/mundo_componentes_v0.2.json`) e `game/tests/test_economia_mundo.py` (22 verificações, no `tools/run_valdora_tests.sh`).

## 1. Decisões do dono nesta sessão

1. Ritmo aprovado: temporada de 30 dias; sem pagar, nível 20 em cerca de 30 dias e 30 em cerca de 60; **a meta do pagante vale para o pagante médio** (nível 30 em cerca de 30 dias).
2. Suavizar o salto do tempo de obra no fim do início rápido.
3. **Sem "QG":** o jogador é o comandante e líder da própria cidade; o prédio principal é a **Prefeitura**, e o nível dela é o nível da cidade.
4. **A moeda é do próprio sistema**; cada cidade tem o seu banco.
5. Os níveis da Prefeitura liberam recursos e prédios aos poucos, **uma coisa dependendo da outra** (seção 4).
6. **A economia gira em torno da produção.**
7. Movimento: **sigla de até 4 letras** e **número de 10 a 99**.
8. **As cidades do mesmo movimento podem se ajudar** para crescer mais rápido, com uma métrica (seção 7).
9. **O presidente só nomeia governadores** para os cargos que decidem sobre o país, e tem **4 secretários** para o próprio objetivo. Governadores podem ser oposição; o presidente precisa juntar governadores aliados para governar (seção 9).

## 2. Ritmo (simulação: 5 regiões × 4 perfis, pesos pelas vagas, 66 dias)


| Perfil | nível 10 | nível 15 | nível 20 | nível 25 | nível 30 | nível no dia 15 | nível no dia 30 | nível no dia 60 | Corte médio por investimento |
|---|---|---|---|---|---|---|---|---|---|
| 5 min/dia | 2,5 | 16,3 | 35,3 | 55,0 | — | 14,0 | 18,0 | 26,0 | 13% |
| 15 min/dia | 1,8 | 13,3 | 29,3 | 45,6 | 62,4 | 15,0 | 20,0 | 29,0 | 19% |
| 30 min/dia | 1,2 | 12,2 | 26,3 | 41,0 | 56,1 | 16,0 | 21,0 | 30,0 | 25% |
| pagante médio (passe, 15 min) | 1,4 | 6,9 | 14,7 | 21,8 | 29,6 | 19,6 | 29,8 | 30,0 | 28% |

Leitura: 15 min por dia chega ao nível 15 no dia 13 (governo por volta do dia 15), ao 20 no dia 29 e ao 30 no dia 62. O passe da temporada (pagante médio, seção 8) chega ao 30 no dia 30. Sem movimento (sem ajuda), leva cerca de 10% mais tempo: 15 min chega ao 20 no dia 32 e ao 30 no dia 69; o passe, ao 30 no dia 32.

## 3. Regras de progressão (`mundo_componentes_v0.2.json`; substituem a seção 1 de `COMPONENTES_NIVEIS_v0.1.md`)

| Nível | 2 | 5 | 8 | 9 | 10 | 11 | 12 | 13 | 15 | 20 | 25 | 30 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Obra da Prefeitura | 1 min | 13 min | 2,0 h | 4,0 h | 8,0 h | 16,0 h | 1,3 d | 2,7 d | 3,7 d | 3,8 d | 3,8 d | 3,8 d |
| Custo da Prefeitura (valor em moedas) | 30 | 30 | 689 | 1.509 | 3.300 | 7.221 | 15.800 | 34.571 | 57.682 | 92.974 | 146.029 | 228.880 |
| Obra de um prédio de produção | 0 min | 0 min | 4 min | 7 min | 14 min | 29 min | 58 min | 1,9 h | 2,7 h | 2,8 h | 2,8 h | 2,8 h |
| Obra da Base militar | 0 min | 4 min | 36 min | 1,2 h | 2,4 h | 4,8 h | 9,6 h | 19,2 h | 1,1 d | 1,1 d | 1,1 d | 1,1 d |
| Produção de referência por hora | 240 | 240 | 1.149 | 1.257 | 1.375 | 1.504 | 1.646 | 1.801 | 2.155 | 3.377 | 5.292 | 8.293 |
| Banco: moeda protegida | 2.880 | 2.880 | 13.788 | 15.084 | 16.502 | 18.053 | 19.750 | 21.607 | 25.860 | 40.524 | 63.504 | 99.515 |

| Regra | Valor |
|---|---|
| Tempo da Prefeitura | níveis 2 a 8 rápidos (1 min a 2 h); do 9 em diante o tempo dobra a cada nível (4 h, 8 h, 16 h, 32 h) até encostar no teto: 92 h × (1 − e^−(n−8)/2), cerca de 3,8 dias do 15 ao 30 |
| Tempo dos outros prédios | fração do tempo da Prefeitura no mesmo nível: Base militar 30%, Alojamento e Banco 10%, secundários (Radar, Entreposto, Parque, Água, Heliponto) 5%, produção 3%, Via 1% |
| Custo | Prefeitura: 0,30 × produção de referência por hora × horas de obra (cerca de 30% do que a cidade produz durante a obra). Outros: Base militar 40%, Alojamento e Banco 10%, secundários 5%, produção 4%, Via 1% do custo da Prefeitura do mesmo nível. Piso de 10 moedas de valor |
| Receita do custo | níveis 1 a 4: materiais 70%, alimentos 30%; 5 a 9: materiais 45%, metal 30%, alimentos 25%; 10 a 30: materiais 35%, metal 25%, energia 20%, alimentos 20% |
| Produção | 60 moedas de valor por hora no nível 1 (alimentos 60, materiais 60, metal 40, energia 30 unidades), × 1,12 por nível; offline até 8 h |
| Preço de referência | alimentos 1, materiais 1, metal 1,5, energia 2 moedas |
| Produção de referência | 240 moedas/h até o nível 6; 560 × 1,094^n depois. Base dos preços em moeda (aceleração, banco, empréstimo, migração, missões) |
| Prédios de produção por tipo | 2 + nível/10 (2 no início, 5 no nível 30) |
| Filas de obra | 2 (3 com o passe); obra de até 5 min termina na hora |
| Pré-requisito | Prefeitura n exige a Usina principal no n−1 e, do 11 em diante, a Base militar no n−1; nenhum prédio passa do nível da Prefeitura |
| Tropas | cerca de 15% do valor produzido vira tropa (alimentos e metal) |
| Manutenção | prédio acima do nível 10 consome 0,4 de energia por hora por nível acima do 10 |

## 4. Árvore de desbloqueio e lista de prioridades (decisão 5)

Cada nível da Prefeitura libera algo, e cada prédio novo exige outro num nível mínimo. A **missão-guia** mostra sempre o próximo item da lista; é também a ordem que a simulação segue.

| Prefeitura | Libera | Exige | O que muda no jogo |
|---|---|---|---|
| 1 | Prefeitura, Alojamento, Estufa, Usina, Via | — | alimentos e materiais |
| 2 | Mineradora | Usina 2 | metal |
| 3 | Central de energia; Banco da cidade | Mineradora 2; Usina 3 | energia; moeda protegida, mercado do estado |
| 4 | Parque | Alojamento 3 | bem-estar |
| 5 | Estação de água; entrar em movimento | Estufa 4 | metal entra no custo das obras; ajuda do movimento |
| 6 | Entreposto logístico | Banco 3 | mercado do país (outros estados) |
| 8 | Radar e antena | Central 6 | visão e defesa |
| 10 | Base militar; fundar movimento | Radar 2 | tropas; energia entra no custo |
| 11 | — | Base militar 10 | a Prefeitura passa a exigir a Base militar |
| 12 | Heliponto; ser representante | Base militar 2 | marchas e guerra |
| 15 | candidatar o movimento ao governo | líder com Prefeitura 15 | eleição e guerra civil |

**Lista de prioridades sugerida (missão-guia):** 1) pré-requisito da próxima Prefeitura; 2) a Prefeitura; 3) prédio de produção novo quando liberado; 4) o prédio de produção mais baixo, preferindo o recurso que falta para a próxima Prefeitura; 5) Alojamento; 6) secundários.

## 5. Economia (decisões 4 e 6)

**A economia gira em torno da produção.** Toda moeda nasce da produção ou de jogar (missões); todo preço em moeda é medido em horas de produção do nível.

**Banco da cidade (prédio próprio, o 14º; arte pendente).** A moeda é do sistema e fica no banco de cada cidade, protegida até 12 h de produção de referência do nível do banco; o que passa disso fica no **cofre**, e um ataque vencido leva 20% do cofre. Entrada 2% e saída 2%; rendimento de 1% por semana sobre até 7 dias de produção. Taxas e rendimento são regra do sistema; não existe saldo central.

**Mercado.** Ordens de compra e venda no estado e no país (Entreposto). Preço livre dentro de ±15% do preço de referência; nas pontas, o sistema compra e vende (âncora). Taxa de 5% sobre a venda e taxa estadual de 0 a 3% (o governador escolhe; NPC usa 1,5%). Na Fase A o sistema compra até 20% do valor produzido por sessão.

**Empréstimo.** Pela nota fiscal (0 a 1.000; começa em 500): limite de 2 dias de produção × nota/1.000, prazo de 7 dias, juros de 5%, 3% e 2% por semana com nota 500, 700 e 900. Abaixo de 500, negado. Atraso: metade da moeda que entra vai para a dívida e a nota cai 100.

**Aceleração por investimento.** 1 h poupada custa 1 h de produção de referência do nível até 25% do tempo da obra, e o dobro de 25% a 50% (teto aprovado). Corte médio na simulação: 13% (5 min), 19% (15 min), 25% (30 min).

**Outros drenos.** Migração: meio dia de produção. Obras públicas: moeda que sobra depois do nível 30 vai para obras do estado e vira apoio ao movimento (seção 9).

### Moeda por semana (% da produção)


| Fluxo | sem 1 | sem 2 | sem 3 | sem 4 | sem 5 | sem 6 | sem 7 | sem 8 | sem 9 | sem 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| fonte: missões diárias | 7,5 | 7,2 | 7,4 | 7,6 | 7,1 | 6,7 | 6,6 | 6,5 | 6,3 | 5,9 |
| fonte: baús | 2,7 | 2,5 | 2,6 | 2,7 | 2,5 | 2,3 | 2,3 | 2,3 | 2,2 | 2,1 |
| fonte: vendas (líquidas) | 12,7 | 12,4 | 11,6 | 12,3 | 14,4 | 15,1 | 14,1 | 13,4 | 13,9 | 17,5 |
| fonte: rendimento do banco | 0,0 | 0,0 | 0,0 | 0,1 | 0,1 | 0,1 | 0,1 | 0,1 | 0,1 | 0,1 |
| fonte: empréstimos concedidos | 10,0 | 3,6 | 3,6 | 4,5 | 4,3 | 1,7 | 0,0 | 0,0 | 0,0 | 0,0 |
| dreno: aceleração de obra | -22,3 | -20,2 | -19,3 | -20,8 | -19,6 | -16,3 | -15,0 | -14,8 | -7,5 | -1,5 |
| dreno: compras no mercado | -0,1 | -0,0 | 0,0 | -0,0 | -0,1 | -0,0 | -0,0 | -0,1 | -0,1 | -0,1 |
| dreno: taxa do mercado (5%) | -0,7 | -0,7 | -0,6 | -0,7 | -0,8 | -0,8 | -0,8 | -0,7 | -0,7 | -0,9 |
| dreno: taxa estadual (1,5%) | -0,2 | -0,2 | -0,2 | -0,2 | -0,2 | -0,2 | -0,2 | -0,2 | -0,2 | -0,3 |
| dreno: taxa do banco (2%) | -0,1 | -0,1 | -0,0 | -0,0 | -0,0 | -0,0 | -0,0 | -0,0 | -0,0 | -0,0 |
| dreno: empréstimos pagos (com juros) | -7,1 | -2,6 | -3,8 | -4,9 | -3,8 | -2,2 | -1,1 | 0,0 | 0,0 | 0,0 |
| dreno: colchão saqueado | -0,1 | 0,0 | 0,0 | -0,0 | -0,4 | -0,3 | -0,3 | -0,3 | -0,9 | 0,0 |
| dreno: migração | 0,0 | 0,0 | 0,0 | 0,0 | 0,0 | 0,0 | 0,0 | 0,0 | 0,0 | 0,0 |
| dreno: obras públicas (apoio) | 0,0 | 0,0 | 0,0 | 0,0 | -2,4 | -5,6 | -5,9 | -5,9 | -10,1 | -11,3 |
| **total de fontes** | 32,9 | 25,8 | 25,3 | 27,1 | 28,4 | 25,8 | 23,1 | 22,2 | 22,5 | 25,6 |
| **total de drenos** | -30,6 | -23,8 | -23,9 | -26,6 | -27,3 | -25,5 | -23,2 | -22,1 | -19,6 | -14,2 |
| produção média por jogador/dia (moedas) | 31.262 | 48.910 | 58.898 | 72.010 | 93.988 | 119.469 | 144.471 | 174.449 | 212.520 | 244.956 |

### Moeda guardada e preços

| Dia | M/Y médio | Índice de preços (ref = 1,00) | Emissão líquida da âncora (% do valor vendido) |
|---|---|---|---|
| 1 | 0,02 | 0,850 | 100,0 |
| 7 | -0,01 | 0,917 | 95,1 |
| 14 | 0,08 | 0,850 | 100,0 |
| 21 | 0,19 | 0,850 | 100,0 |
| 30 | 0,30 | 0,850 | 100,0 |
| 45 | 0,36 | 0,850 | 100,0 |
| 60 | 0,52 | 0,850 | 99,8 |

Leitura: fontes e drenos andam juntos (entre 20 e 28% da produção nas semanas 2 a 9; a semana 10 tem só 3 dias e muita gente já no nível 30); a moeda guardada fica abaixo de 0,6 dia de produção até o dia 60; o preço fica no piso da faixa, ou seja, sobra recurso e a moeda **ganha** valor. A âncora (o sistema comprando nas pontas) faz quase todo o papel de comprador na Fase A; online, os jogadores compram uns dos outros. O preço da aceleração é fixo em horas de produção, então a moeda também vale o mesmo em tempo.

## 6. Regiões


| Região | Prefeitura 20 (dia) | Prefeitura 30 (dia) | Poder | Produção/h | Moeda guardada |
|---|---|---|---|---|---|
| Norte | 29,3 | 62,4 | 1,000 | 0,998 | 1,00 |
| Nordeste | 29,3 | 62,2 | 0,996 | 0,988 | 0,98 |
| Centro-Oeste | 29,3 | 62,7 | 0,998 | 1,000 | 1,02 |
| Sudeste | 29,3 | 62,4 | 1,002 | 1,008 | 1,00 |
| Sul | 29,3 | 62,2 | 1,004 | 1,005 | 1,00 |

**Pior caso de preço** (bônus da região em % da produção total, com produção igual nos 4 recursos):

| Cenário | Norte | Nordeste | Centro-Oeste | Sudeste | Sul | maior − menor |
|---|---|---|---|---|---|---|
| preços de referência | 5,00% | 5,00% | 5,00% | 5,00% | 5,00% | 0,00 p.p. |
| materiais e metal no teto, alimentos e energia no piso | 5,00% | 4,25% | 5,00% | 5,38% | 4,78% | 1,12 p.p. |
| alimentos e energia no teto, materiais e metal no piso | 5,00% | 5,75% | 5,00% | 4,62% | 5,22% | 1,12 p.p. |

Com o mesmo perfil de jogo, as cinco regiões chegam aos níveis 20 e 30 com menos de meio dia de diferença, e poder e produção ficam a ±1%. No pior caso de preço online, a diferença do bônus regional fica em 1,1 ponto percentual da produção.

## 7. Ajuda entre cidades do movimento (decisão 8)

| Regra | Proposta |
|---|---|
| Pedir ajuda | toda obra pode pedir ajuda ao movimento uma vez |
| Efeito | cada ajuda corta 1% do tempo-base da obra (mínimo 1 min); até 20 ajudas por obra (−20%) |
| Quem ajuda | cada membro ajuda uma vez por obra; até 50 ajudas por dia |
| Recompensa de quem ajuda | 1 **ponto de cooperação** por ajuda; pontos abrem o baú de cooperação (recursos) e somam apoio do movimento no estado |
| Doação de recursos | entre membros com 3 dias ou mais no movimento, até 10% da produção diária de quem doa; taxa de 5% (dreno) |
| **Métrica: índice de cooperação** | ajudas dadas por membro ativo por dia (meta: 10 ajudas por obra recebida). Aparece no perfil do movimento e no ranking do estado |

A simulação supõe 10 ajudas por obra: poupa de 230 a 430 h por jogador em 66 dias e entra na meta de ritmo.

## 8. Pagante médio: passe da temporada (decisão 1)

O pagante médio compra **um passe por temporada**: obras 60% mais rápidas, produção +75% e uma fila a mais. Na simulação, chega ao nível 30 no dia 30 (metade dos 62 dias de quem joga 15 min). Equivale a cerca de 2.250 h de aceleração. Nada é transferível, e a moeda não se compra com dinheiro real. Preço e loja: M13.

## 9. Poder: carreira, movimentos, governo e presidência (decisões 3, 7 e 9)

**Carreira do comandante:** líder da cidade → membro de movimento (Prefeitura 5) → representante (12) → líder de movimento (fundar: 10) → governador → presidente.

**Movimento.** Nome (3 a 30 letras), **sigla de até 4 letras**, **número de 10 a 99** único no servidor, escolhido na fundação. Até 100 membros. **Representantes:** 1 a cada 10 membros (até 10); aceitam e expulsam membros, convocam defesa e votam as decisões do movimento com o líder. Nomes e siglas de partidos reais são bloqueados.

**Governo do estado (ciclo semanal; temporada com 4 ciclos).**

| Etapa | Regra |
|---|---|
| Dias 1 a 14 | governo NPC |
| Candidatura | movimento com sede no estado, pelo menos 10 membros morando nele, líder com Prefeitura 15 e apoio mínimo (pontos de cooperação, obras públicas e missões do estado) |
| Via pacífica | eleição no fim de cada semana (dias 14, 21 e 28, às 20 h). Votam os moradores ativos (entraram nos últimos 3 dias e moram no estado há 3 dias ou mais), 1 voto cada. Maioria simples; empate vai para o maior apoio |
| Via da força | o movimento declara guerra civil com 24 h de aviso; janela de 2 h na capital estadual; vence quem controlar a capital no fim. Exige 20 membros no estado; o estado produz 20% menos por 24 h; espera de 7 dias para declarar de novo |
| Governador | o líder do movimento vencedor, até o próximo ciclo. Escolhe a taxa estadual (0 a 3%), um bônus do estado (produção +3% de um recurso, obras −3% ou defesa +5%) e nomeia até **4 secretários** entre os representantes (Economia, Obras, Defesa, Comunicação), cada um com +1% no bônus da área |

**Presidência (decisão 9).**

| Etapa | Regra |
|---|---|
| Quem disputa | só governadores |
| Via pacífica | no dia 28, o **Conselho dos governadores** (até 26 votos) elege o presidente por maioria (14 votos); sem maioria, segundo turno entre os dois mais votados no dia 29 |
| Via da força | movimentos de governadores podem tomar o DF numa janela no dia 30; quem controlar o DF no fim tira o presidente eleito |
| Mandato | até a presidência da temporada seguinte |
| Ministros | o presidente nomeia **somente governadores** para os 4 ministérios que decidem sobre o país (Economia, Infraestrutura, Defesa, Comércio) |
| Secretários | **4 secretários** do próprio movimento trabalham no objetivo do presidente (preparam propostas e missões nacionais), sem voto no Conselho |
| Decisões do país | uma política por ciclo (por exemplo, taxa nacional de 0 a 2% no mercado, obras −5% num setor, evento de defesa). Precisa de maioria do Conselho (14 votos). Governadores podem ser oposição; o presidente precisa juntar aliados |
| Destituição | dois terços do Conselho (18 votos) tiram o presidente; o Conselho elege outro em 24 h |

Proteções: jogador novo não pode ser atacado nos primeiros 3 dias; quem perde guerra perde recurso do cofre e território, nunca a cidade; migração proibida em guerra, com empréstimo atrasado ou em cargo.

## 10. Ciclo diário

| Tempo por dia | O que faz | Resultado na simulação |
|---|---|---|
| 5 min (2 entradas) | coleta, inicia obras, 3 missões rápidas, baú de entrada | nível 20 no dia 35 |
| 15 min (3 entradas) | o anterior + mercado, pedir e dar ajudas, 5 missões, banco | nível 20 no dia 29 |
| 30 min (5 entradas) | o anterior + combate contra NPC, missões do estado, eleições, guerra | nível 20 no dia 26 |

- Produção offline acumula até 8 h: quem entra 3 vezes por dia perde pouco, quem entra 2 vezes perde parte da noite.
- **Missões diárias:** 5 por dia; recompensa total de 8% da produção diária de referência em moeda (5% para quem faz 3; 11% com combate).
- **Baús:** um por entrada (até 3 por dia), 1% em moeda mais recursos; baú de cooperação pelos pontos de ajuda.

## 11. NPC na Fase A (determinístico: mesma semente, mesmo resultado)

- **Cidades NPC** ocupam as vagas de cada estado (`vagas_base` de `BR_perfis.json`), com a mesma mistura de perfis da simulação (30% de 5 min, 45% de 15 min, 20% de 30 min, 5% com passe) e crescem pelas mesmas regras. Semente = servidor + UF.
- **Movimentos NPC:** 3 a 5 por estado, com nome, sigla e número sorteados de listas fictícias; aceitam o jogador e dão as 10 ajudas por obra da meta.
- **Mercado:** o sistema e os NPC são a contraparte, dentro da faixa de ±15%.
- **Governo e presidência:** governadores NPC até o dia 14; depois as eleições contam votos NPC pelo peso dos moradores de cada movimento. Um movimento NPC declara guerra civil se tiver 20% mais poder que o governo. O Conselho NPC vota conforme a aliança do governador com o candidato.
- **Ataques:** um ataque NPC por semana contra o cofre (20% em caso de derrota).

## 12. Chat

| Canal | Fase A (offline) | Online (M10) |
|---|---|---|
| Sistema | eventos reais da simulação ("Movimento 27 venceu em Goiás") | igual |
| Movimento | mensagens NPC de modelo (pedido de ajuda, convocação) | chat do movimento |
| Estado | mensagens NPC (eleição, mercado) | chat do estado |
| País | anúncios do presidente e do Conselho | chat do país |
| Privado | — | entre membros do mesmo movimento |

Moderação (M10): filtro de palavras e de nomes políticos reais, uma mensagem a cada 5 s, silenciar, bloquear e denunciar; o líder do movimento e o governador moderam os próprios canais. Tradução automática fica fora do piloto Brasil.

## 13. Pendências

- Arte do Banco da cidade (14º prédio): nas seis faixas, com o kit da sessão 1.2.
- Renomear "Quartel-general" para "Prefeitura" nos documentos e na arte aprovados (texto e selo; o modelo 3D serve).
- Preço do passe e loja: M13.
