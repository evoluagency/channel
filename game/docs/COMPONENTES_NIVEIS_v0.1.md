# Jogo moderno — Componentes, níveis 1 a 30 e representação visual (v0.1)
Escrito em 13/11/2026, a pedido do dono: explicar cada componente, seus benefícios, a força do nível 1 ao 30 e a aparência em cada nível. Complementa `DESENHO_MUNDO_v0.1.md`. **É proposta de balanceamento; todos os números são ponto de partida para teste, nada está homologado nem implementado.** Nome do jogo ainda provisório.
## 1. Regras gerais de progressão
- **Nível:** de 1 a 30 em todos os prédios. Nenhum prédio passa do nível do Quartel-general.
- **Poder (força):** cada prédio soma `Poder(n) = 40 × n^1,55`. O poder da base é a soma dos prédios, mais heróis e tropas. É o número exibido no perfil e usado para comparar estados.
- **Custo:** `custo(n) = custo do nível 1 × 1,25^(n−1)`, pago em materiais; a partir do nível 5, mais metal equivalente a 60% do valor.
- **Tempo:** `tempo(n) = 30 s × fator × 1,28^(n−1)`. O fator vale 2 no Quartel-general, 1 na maioria, 0,3 na Via. Pode ser reduzido por aceleração (heróis, base militar, eventos).
- **Produção:** `base × 1,12^(n−1)` por hora, acumulada offline por até 8 horas (regra herdada do Valdora).
- **Retorno decrescente:** o custo cresce mais rápido que o ganho (1,25 contra 1,12), para o final do jogo ficar caro e valioso.
- **Quantidade máxima por tipo:** aumenta com o nível do Quartel-general (por exemplo, 4 Estufas no QG 1 e 20 no QG 30).
### Poder por prédio

| Nível | 1 | 5 | 10 | 15 | 20 | 25 | 30 |
|---|---|---|---|---|---|---|---|
| Poder | 40 | 484,7 | 1.419 | 2.661 | 4.156 | 5.873 | 7.791 |

### Multiplicador de poder do Quartel-general no estado

O poder total exibido é a soma dos prédios, dos heróis e das tropas, multiplicada pelo bônus de vocação do estado (de 5 a 10%, ver `DESENHO_MUNDO_v0.1.md`).
## 2. Recursos

| Recurso | Vem de | Serve para |
|---|---|---|
| Alimentos | Estufa | Manter a população, treinar tropas |
| Materiais | Usina | Toda construção e melhoria |
| Metal | Mineradora | Construção avançada (a partir do nível 5), equipamentos e evolução de tropas |
| Energia | Central de energia | Fábricas funcionarem a 100%; prédios acima do nível 10 consomem energia |
| Moedas | Missões, baús e comércio | Aceleração, itens e compras premium futuras (loja fora desta fase) |
**Regra de energia:** `consumo por prédio = 0,4 × (nível − 10)` para prédios acima do nível 10. Se a energia produzida for menor que o consumo, a produção das fábricas cai 50% até equilibrar.
## 3. Representação visual por faixa de nível
Toda construção tem **seis faixas visuais**. Cada faixa muda silhueta, material, altura, iluminação e animação. Dentro da faixa, cada nível acrescenta um ponto ao selo de nível (de 1 a 5 pontos). Ao subir de faixa, o prédio faz a animação de transformação (poeira, salto elástico e brilho).

| Faixa | Níveis | Nome | Material e visual geral | Animação e efeito |
|---|---|---|---|---|
| 1 | 1 a 5 | Acampamento | Contêineres, lona, madeira, cores sem brilho | Quase nenhuma, só fumaça leve |
| 2 | 6 a 10 | Pré-fabricado | Módulos de metal e plástico, faixa colorida da aliança | Luz piscando, pessoas visíveis |
| 3 | 11 a 15 | Concreto | Concreto e aço, mais altura, garagens e antenas | Veículos entrando e saindo |
| 4 | 16 a 20 | Vidro e aço | Fachada de vidro, reflexo, jardim no teto | Luz de janelas acesa à noite |
| 5 | 21 a 25 | Tecnológico | Painéis solares, drones, antenas e tubulações brilhantes | Drones voando, raios de energia |
| 6 | 26 a 30 | Elite | Destaque dourado, neon e holograma, base com campo de energia | Brilho pulsante, partículas e feixe de luz |

**Cores de aliança e de país:** o telhado ou a faixa lateral usa a cor da aliança. A bandeira fictícia do país aparece no Quartel-general e na Base militar.

**Selo de nível:** hexágono acima do prédio com o número, e de 1 a 5 pontos pequenos. Na faixa 6 o selo é dourado.
## 4. Construções
Cada construção tem função, benefício, valores por nível e descrição visual por faixa. Valores por nível de prédio (custo em materiais; tempo para chegar a esse nível).
### Quartel-general
- **Vem de:** Fundação (Valdora).
- **Função:** Centro de comando. Define o nível máximo de todos os outros prédios.
- **Benefício:** Capacidade de armazém e de população-base; libera novos prédios e o limite de cada tipo.
- **Desbloqueio:** Quartel-general nível 1.
| Nível | 1 | 5 | 10 | 15 | 20 | 25 | 30 |
|---|---|---|---|---|---|---|---|
| Poder | 40 | 484,7 | 1.419 | 2.661 | 4.156 | 5.873 | 7.791 |
| Custo (materiais) | 200 | 488,3 | 1.490 | 4.547 | 14 mil | 42 mil | 129 mil |
| Tempo da obra | 60 s | 3 min | 9 min | 32 min | 1,8 h | 6,2 h | 21,4 h |
| Capacidade de armazém | 2.000 | 3.878 | 8.871 | 20 mil | 46 mil | 106 mil | 243 mil |
| Níveis liberados para os outros prédios | 1 | 5 | 10 | 15 | 20 | 25 | 30 |

| Faixa | Níveis | Aparência |
|---|---|---|
| 1 | 1 a 5 | Contêineres empilhados com bandeira e antena simples |
| 2 | 6 a 10 | Prédio pré-fabricado de 2 andares, faixa colorida da aliança |
| 3 | 11 a 15 | Torre de concreto com heliponto no teto e letreiro luminoso |
| 4 | 16 a 20 | Torre de vidro e aço, fachada espelhada, reflexo do céu |
| 5 | 21 a 25 | Complexo com anel de painéis solares e antena parabólica giratória |
| 6 | 26 a 30 | Arranha-céu de elite com feixe de luz no topo e brilho dourado |

### Alojamento
- **Vem de:** Casa (Valdora).
- **Função:** Moradia das tropas e dos trabalhadores.
- **Benefício:** Aumenta a população, que gera mão de obra e limite de tropas.
- **Desbloqueio:** Quartel-general nível 1.
| Nível | 1 | 5 | 10 | 15 | 20 | 25 | 30 |
|---|---|---|---|---|---|---|---|
| Poder | 40 | 484,7 | 1.419 | 2.661 | 4.156 | 5.873 | 7.791 |
| Custo (materiais) | 40 | 97,7 | 298,0 | 909,5 | 2.776 | 8.470 | 26 mil |
| Tempo da obra | 30 s | 81 s | 5 min | 16 min | 54 min | 3,1 h | 10,7 h |
| Moradores por prédio | 8 | 11,7 | 18,9 | 30,4 | 48,9 | 78,8 | 126,9 |

| Faixa | Níveis | Aparência |
|---|---|---|
| 1 | 1 a 5 | Módulos de contêiner com janelas e toldo |
| 2 | 6 a 10 | Bloco pré-fabricado de 3 andares, varandas coloridas |
| 3 | 11 a 15 | Prédio de concreto com garagem e antena de TV |
| 4 | 16 a 20 | Residencial de vidro com jardim no terraço |
| 5 | 21 a 25 | Torre residencial com painéis solares e elevador visível |
| 6 | 26 a 30 | Torre de luxo com iluminação neon por andar |

### Estufa hidropônica
- **Vem de:** Fazenda (Valdora).
- **Função:** Produz alimentos, necessários para manter a população e treinar tropas.
- **Benefício:** Produção contínua de alimentos, também acumulada offline (até 8 h).
- **Desbloqueio:** Quartel-general nível 1.
| Nível | 1 | 5 | 10 | 15 | 20 | 25 | 30 |
|---|---|---|---|---|---|---|---|
| Poder | 40 | 484,7 | 1.419 | 2.661 | 4.156 | 5.873 | 7.791 |
| Custo (materiais) | 30 | 73,2 | 223,5 | 682,1 | 2.082 | 6.353 | 19 mil |
| Tempo da obra | 30 s | 81 s | 5 min | 16 min | 54 min | 3,1 h | 10,7 h |
| Produção (alimentos/h) | 60 | 94,4 | 166,4 | 293,2 | 516,8 | 910,7 | 1.605 |

| Faixa | Níveis | Aparência |
|---|---|---|
| 1 | 1 a 5 | Estufa de plástico com fileiras de verduras |
| 2 | 6 a 10 | Estufa de vidro com irrigação aparente |
| 3 | 11 a 15 | Galpão com bandejas empilhadas e luz roxa |
| 4 | 16 a 20 | Estufa vertical de 3 andares, folhagem brilhante |
| 5 | 21 a 25 | Fazenda vertical com drones colhendo |
| 6 | 26 a 30 | Biodomo de vidro curvo, folhas luminosas e vapor |

### Usina de materiais
- **Vem de:** Serraria (Valdora).
- **Função:** Produz materiais de construção.
- **Benefício:** Fornece o material de toda obra e melhoria.
- **Desbloqueio:** Quartel-general nível 1.
| Nível | 1 | 5 | 10 | 15 | 20 | 25 | 30 |
|---|---|---|---|---|---|---|---|
| Poder | 40 | 484,7 | 1.419 | 2.661 | 4.156 | 5.873 | 7.791 |
| Custo (materiais) | 40 | 97,7 | 298,0 | 909,5 | 2.776 | 8.470 | 26 mil |
| Tempo da obra | 30 s | 81 s | 5 min | 16 min | 54 min | 3,1 h | 10,7 h |
| Produção (materiais/h) | 60 | 94,4 | 166,4 | 293,2 | 516,8 | 910,7 | 1.605 |

| Faixa | Níveis | Aparência |
|---|---|---|
| 1 | 1 a 5 | Galpão com serra e pilhas de madeira |
| 2 | 6 a 10 | Fábrica com chaminé e esteira |
| 3 | 11 a 15 | Linha de montagem coberta, guindaste móvel |
| 4 | 16 a 20 | Fábrica automatizada com braços robóticos |
| 5 | 21 a 25 | Complexo com tubulações brilhantes e fumaça branca |
| 6 | 26 a 30 | Mega-fábrica com faíscas e esteiras flutuantes |

### Mineradora
- **Vem de:** Pedreira (Valdora).
- **Função:** Extrai metal para construção avançada e equipamentos.
- **Benefício:** Metal é exigido em obras acima do nível 5 e na evolução das tropas.
- **Desbloqueio:** Quartel-general nível 2.
| Nível | 1 | 5 | 10 | 15 | 20 | 25 | 30 |
|---|---|---|---|---|---|---|---|
| Poder | 40 | 484,7 | 1.419 | 2.661 | 4.156 | 5.873 | 7.791 |
| Custo (materiais) | 50 | 122,1 | 372,5 | 1.137 | 3.469 | 11 mil | 32 mil |
| Tempo da obra | 30 s | 81 s | 5 min | 16 min | 54 min | 3,1 h | 10,7 h |
| Produção (metal/h) | 40 | 62,9 | 110,9 | 195,5 | 344,5 | 607,1 | 1.070 |

| Faixa | Níveis | Aparência |
|---|---|---|
| 1 | 1 a 5 | Poço aberto com carrinho e pá |
| 2 | 6 a 10 | Escavadeira e pilha de minério |
| 3 | 11 a 15 | Cavas em degraus com caminhões |
| 4 | 16 a 20 | Torre de perfuração com guindaste duplo |
| 5 | 21 a 25 | Escavadeira gigante e esteira de minério brilhante |
| 6 | 26 a 30 | Mina de cristal com lasers e vagonetes flutuantes |

### Central de energia
- **Vem de:** (novo) (Valdora).
- **Função:** Gera energia. A fonte muda por país: solar, eólica, hídrica ou térmica.
- **Benefício:** Sem energia suficiente, as fábricas ficam 50% mais lentas. Prédios acima do nível 10 consomem energia.
- **Desbloqueio:** Quartel-general nível 3.
| Nível | 1 | 5 | 10 | 15 | 20 | 25 | 30 |
|---|---|---|---|---|---|---|---|
| Poder | 40 | 484,7 | 1.419 | 2.661 | 4.156 | 5.873 | 7.791 |
| Custo (materiais) | 60 | 146,5 | 447,0 | 1.364 | 4.163 | 13 mil | 39 mil |
| Tempo da obra | 30 s | 81 s | 5 min | 16 min | 54 min | 3,1 h | 10,7 h |
| Produção (energia/h) | 30 | 47,2 | 83,2 | 146,6 | 258,4 | 455,4 | 802,5 |

| Faixa | Níveis | Aparência |
|---|---|---|
| 1 | 1 a 5 | Poucos painéis solares e um gerador a diesel |
| 2 | 6 a 10 | Fileira de painéis e uma turbina pequena |
| 3 | 11 a 15 | Parque com turbina grande e subestação |
| 4 | 16 a 20 | Usina com torre de transmissão e linhas |
| 5 | 21 a 25 | Complexo com baterias gigantes e raios azuis |
| 6 | 26 a 30 | Reator de energia com anel luminoso girando |

### Radar e antena
- **Vem de:** Torre (Valdora).
- **Função:** Dá visão do mapa, avisa de ataques e reforça a defesa passiva.
- **Benefício:** Aumenta o alcance de visão (casas do mapa) e a defesa do estado.
- **Desbloqueio:** Quartel-general nível 8.
| Nível | 1 | 5 | 10 | 15 | 20 | 25 | 30 |
|---|---|---|---|---|---|---|---|
| Poder | 40 | 484,7 | 1.419 | 2.661 | 4.156 | 5.873 | 7.791 |
| Custo (materiais) | 80 | 195,3 | 596,0 | 1.819 | 5.551 | 17 mil | 52 mil |
| Tempo da obra | 30 s | 81 s | 5 min | 16 min | 54 min | 3,1 h | 10,7 h |
| Defesa | 20 | 33,8 | 65,0 | 125,2 | 241,1 | 464,2 | 893,9 |
| Alcance de visão (casas) | 3 | 4 | 5 | 6 | 7 | 8 | 9 |

| Faixa | Níveis | Aparência |
|---|---|---|
| 1 | 1 a 5 | Mastro com antena e refletor |
| 2 | 6 a 10 | Torre de aço com antena parabólica |
| 3 | 11 a 15 | Radar giratório com cúpula |
| 4 | 16 a 20 | Torre com três antenas e luz de varredura |
| 5 | 21 a 25 | Rede de antenas com feixe visível |
| 6 | 26 a 30 | Torre de elite com holograma de varredura |

### Base militar
- **Vem de:** Quartel (Valdora).
- **Função:** Treina e abriga tropas e heróis.
- **Benefício:** Aumenta a capacidade de tropas e acelera o treinamento.
- **Desbloqueio:** Quartel-general nível 10.
| Nível | 1 | 5 | 10 | 15 | 20 | 25 | 30 |
|---|---|---|---|---|---|---|---|
| Poder | 40 | 484,7 | 1.419 | 2.661 | 4.156 | 5.873 | 7.791 |
| Custo (materiais) | 120 | 293,0 | 894,1 | 2.728 | 8.327 | 25 mil | 78 mil |
| Tempo da obra | 30 s | 81 s | 5 min | 16 min | 54 min | 3,1 h | 10,7 h |
| Capacidade de tropas | 10 | 16,3 | 30,0 | 55,3 | 102,0 | 187,9 | 346,2 |
| Bônus de treinamento | 1,5% | 7,5% | 15% | 22,5% | 30% | 37,5% | 45% |

| Faixa | Níveis | Aparência |
|---|---|---|
| 1 | 1 a 5 | Tendas militares e jipe |
| 2 | 6 a 10 | Galpão de treino com sacos de areia |
| 3 | 11 a 15 | Quartel de concreto com garagem de veículos |
| 4 | 16 a 20 | Base com torre de controle e hangar |
| 5 | 21 a 25 | Complexo com tanques e hangar duplo |
| 6 | 26 a 30 | Fortaleza tecnológica com campo de energia e bandeira da aliança |

### Entreposto logístico
- **Vem de:** Mercado (Valdora).
- **Função:** Comércio e transporte entre estados e países.
- **Benefício:** Reduz a taxa de comércio e aumenta a carga das rotas.
- **Desbloqueio:** Quartel-general nível 6.
| Nível | 1 | 5 | 10 | 15 | 20 | 25 | 30 |
|---|---|---|---|---|---|---|---|
| Poder | 40 | 484,7 | 1.419 | 2.661 | 4.156 | 5.873 | 7.791 |
| Custo (materiais) | 70 | 170,9 | 521,5 | 1.592 | 4.857 | 15 mil | 45 mil |
| Tempo da obra | 30 s | 81 s | 5 min | 16 min | 54 min | 3,1 h | 10,7 h |
| Carga por rota | 100 | 157,4 | 277,3 | 488,7 | 861,3 | 1.518 | 2.675 |
| Taxa de comércio | 15% | 13,7% | 12,0% | 10,4% | 8,7% | 7,1% | 5,4% |

| Faixa | Níveis | Aparência |
|---|---|---|
| 1 | 1 a 5 | Barraca com caixas e carrinho |
| 2 | 6 a 10 | Armazém com duas docas |
| 3 | 11 a 15 | Galpão com empilhadeiras e caminhão |
| 4 | 16 a 20 | Terminal com contêineres coloridos |
| 5 | 21 a 25 | Porto seco com guindaste móvel e drones |
| 6 | 26 a 30 | Hub global com esteiras luminosas e contêineres flutuantes |

### Via
- **Vem de:** Estrada (Valdora).
- **Função:** Liga os prédios e agiliza o transporte interno.
- **Benefício:** Cada nível aumenta a velocidade de transporte entre prédios.
- **Desbloqueio:** Quartel-general nível 1.
| Nível | 1 | 5 | 10 | 15 | 20 | 25 | 30 |
|---|---|---|---|---|---|---|---|
| Poder | 40 | 484,7 | 1.419 | 2.661 | 4.156 | 5.873 | 7.791 |
| Custo (materiais) | 10 | 24,4 | 74,5 | 227,4 | 693,9 | 2.118 | 6.462 |
| Tempo da obra | 9 s | 24 s | 83 s | 5 min | 16 min | 56 min | 3,2 h |
| Velocidade de transporte | +1% | +5% | +10% | +15% | +20% | +25% | +30% |

| Faixa | Níveis | Aparência |
|---|---|---|
| 1 | 1 a 5 | Terra batida |
| 2 | 6 a 10 | Asfalto simples |
| 3 | 11 a 15 | Asfalto com faixas e postes |
| 4 | 16 a 20 | Via larga com ciclovia |
| 5 | 21 a 25 | Via com postes inteligentes |
| 6 | 26 a 30 | Via com faixas luminosas |

### Parque
- **Vem de:** Jardim (Valdora).
- **Função:** Serviço social: melhora o bem-estar.
- **Benefício:** Aumenta a cobertura de serviços, que reduz o custo de manutenção.
- **Desbloqueio:** Quartel-general nível 4.
| Nível | 1 | 5 | 10 | 15 | 20 | 25 | 30 |
|---|---|---|---|---|---|---|---|
| Poder | 40 | 484,7 | 1.419 | 2.661 | 4.156 | 5.873 | 7.791 |
| Custo (materiais) | 25 | 61,0 | 186,3 | 568,4 | 1.735 | 5.294 | 16 mil |
| Tempo da obra | 15 s | 40 s | 2 min | 8 min | 27 min | 1,6 h | 5,4 h |
| Cobertura de serviços | +0,8% | +4% | +8% | +12% | +16% | +20% | +24% |

| Faixa | Níveis | Aparência |
|---|---|---|
| 1 | 1 a 5 | Canteiro com bancos |
| 2 | 6 a 10 | Praça com árvores |
| 3 | 11 a 15 | Parque com lago |
| 4 | 16 a 20 | Parque com quiosque e playground |
| 5 | 21 a 25 | Jardim com chafariz |
| 6 | 26 a 30 | Parque com luz e fontes animadas |

### Estação de água
- **Vem de:** Poço (Valdora).
- **Função:** Serviço de saúde: fornece água e saneamento.
- **Benefício:** Aumenta a cobertura de serviços e a proteção contra falta de alimentos.
- **Desbloqueio:** Quartel-general nível 5.
| Nível | 1 | 5 | 10 | 15 | 20 | 25 | 30 |
|---|---|---|---|---|---|---|---|
| Poder | 40 | 484,7 | 1.419 | 2.661 | 4.156 | 5.873 | 7.791 |
| Custo (materiais) | 45 | 109,9 | 335,3 | 1.023 | 3.123 | 9.529 | 29 mil |
| Tempo da obra | 24 s | 64 s | 4 min | 13 min | 44 min | 2,5 h | 8,6 h |
| Cobertura de serviços | +0,7% | +3,5% | +7% | +10,5% | +14% | +17,5% | +21% |

| Faixa | Níveis | Aparência |
|---|---|---|
| 1 | 1 a 5 | Poço com bomba |
| 2 | 6 a 10 | Caixa-d’água pequena |
| 3 | 11 a 15 | Reservatório elevado |
| 4 | 16 a 20 | Estação com filtros e torre |
| 5 | 21 a 25 | Estação com tubulações azuis |
| 6 | 26 a 30 | Estação de dessalinização com cúpula brilhante |

### Heliponto
- **Vem de:** Praça (Valdora).
- **Função:** Ponto de chegada e saída de reforços e de heróis.
- **Benefício:** Aumenta a velocidade de marcha e o limite de reforços enviados.
- **Desbloqueio:** Quartel-general nível 12.
| Nível | 1 | 5 | 10 | 15 | 20 | 25 | 30 |
|---|---|---|---|---|---|---|---|
| Poder | 40 | 484,7 | 1.419 | 2.661 | 4.156 | 5.873 | 7.791 |
| Custo (materiais) | 90 | 219,7 | 670,6 | 2.046 | 6.245 | 19 mil | 58 mil |
| Tempo da obra | 30 s | 81 s | 5 min | 16 min | 54 min | 3,1 h | 10,7 h |
| Velocidade de marcha | +1,5% | +7,5% | +15% | +22,5% | +30% | +37,5% | +45% |

| Faixa | Níveis | Aparência |
|---|---|---|
| 1 | 1 a 5 | Círculo pintado no chão |
| 2 | 6 a 10 | Plataforma com biruta |
| 3 | 11 a 15 | Heliponto com luzes de pista |
| 4 | 16 a 20 | Plataforma elevada com helicóptero |
| 5 | 21 a 25 | Heliponto duplo com torre |
| 6 | 26 a 30 | Plataforma tecnológica com holograma e jato estacionado |

## 5. Heróis
Os quatro heróis do Valdora (Pietro, Henzo, Giulia, Arthur) são o ponto de partida; os nomes são decisão pendente do dono. As forças viram Indústria, Informação, Energia e Defesa.

- **Nível 1 a 30** (o atual tem sistema de atributos VIG, FOR, TEC, INT, ESP, AGI com 6 pontos no nível 1; os pontos por nível crescem na mesma escala).
- **Poder do herói:** `60 × n^1,5` (nível 1: 60; nível 10: 1.897; nível 20: 5.367; nível 30: 9.859).
- **Estrelas:** de 1 a 5, a cada patamar de 6 níveis (níveis 6, 12, 18, 24 e 30), com bônus de 10% nos atributos por estrela.
- **Visual por faixa:** níveis 1 a 5 uniforme básico; 6 a 10 colete e capacete com a cor da força; 11 a 15 armadura leve com emblema da aliança; 16 a 20 traje tecnológico com luzes; 21 a 25 traje com aura animada na cor da força; 26 a 30 traje de elite, brilho dourado, capa de energia e pose de vitória.
- **Expressão:** rosto com olhos grandes e expressões (comemorar, atacar, ferido), como pedido pelo dono, a desenhar com artista ou kit de personagem.
## 6. Tropas

Cinco tiers de tropa, treinados na Base militar. O tier depende do nível da Base militar.

| Tier | Base militar | Poder por tropa | Visual |
|---|---|---|---|
| 1 Infantaria | 1 a 6 | 4 | Soldado a pé, capacete simples |
| 2 Veículo leve | 7 a 12 | 12 | Jipe blindado |
| 3 Blindado | 13 a 18 | 32 | Tanque leve |
| 4 Aéreo | 19 a 24 | 80 | Drone de combate ou helicóptero |
| 5 Elite | 25 a 30 | 200 | Robô de combate e jato |
## 7. Estado e território

O estado tem de 40 a 120 lotes (ver o desenho do mundo). **Nível do estado** = nível do Quartel-general. Ele define:

| Nível do QG | 1 | 5 | 10 | 15 | 20 | 25 | 30 |
|---|---|---|---|---|---|---|---|
| Prédios construíveis (por cento dos lotes) | 15% | 30% | 45% | 60% | 75% | 85% | 95% |
| Alianças simultâneas | 1 | 1 | 2 | 2 | 3 | 3 | 4 |
| Casas de visão do mapa | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
## 8. Alianças

| Nível da aliança | Membros máximos | Benefício coletivo |
|---|---|---|
| 1 | 10 | Chat de aliança e bandeira |
| 5 | 30 | +5% de produção para todos |
| 10 | 60 | Projeto conjunto liberado (obra de aliança) |
| 15 | 90 | +10% de produção; território avançado |
| 20 | 120 | Posto avançado e rotas rápidas |
| 25 | 150 | +15% de produção; reforço entre membros |
| 30 | 200 | Selo dourado; direito de propor resolução na assembleia |

O nível da aliança sobe com contribuições de recursos dos membros e vitórias de território.
## 9. Chat

- **Canais:** aliança, estado, global (com tradução automática), e mensagens de sistema ("Mato Grosso foi atacado").
- **Regras:** filtro de palavras, silenciar e denunciar, limite de mensagens por minuto.
- **Online:** exige servidor, então só na Fase B. Na Fase A offline, o chat é simulado com mensagens de sistema e respostas de NPC para testar a interface.
- **Visual:** balão colorido por canal, avatar do herói, selo da aliança.
## 10. Animações obrigatórias de prender atenção

- Construir: prédio nasce com salto elástico e poeira.
- Melhorar: obra com andaime e barra de tempo; ao concluir, brilho e confete na cor da aliança.
- Coletar: bolha de recurso clicável sobre o prédio; ao tocar, moedas voam até o contador.
- Subir de faixa visual: animação de transformação com luz e som.
- Selecionar: anel luminoso pulsando e nome do prédio.
- Ciclo dia e noite: janelas acendem à noite.
- Interface: números sobem com som, botões com mola, vibração leve ao concluir.
## 11. Como validar

A validação do balanceamento é local e gratuita:
- Planilha de simulação (Python) com tempo total, custo total e poder por nível; conferir que nenhum prédio fica 3 vezes mais forte por custo que outro.
- Teste automático no Godot (smoke) para as fórmulas: nível 30 exato, limite de nível pelo QG, energia e custo.
- Homologação em aparelho pelo dono antes de ajustar números.
