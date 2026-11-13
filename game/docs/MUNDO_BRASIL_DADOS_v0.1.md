# Mundo — Brasil em dados (v0.1)

Sessão 1.3, 13/11/2026. Marcos **M1** (Brasil gerado do dado aberto) e **M2** (perfis dos 27 estados e fórmula de lotes) do `DESENHO_MUNDO_v0.1.md`. Trabalho só de dados: nada muda no jogo instalado.

## 1. Arquivos

| Arquivo | O que é |
|---|---|
| `tools/mundo/gerar_pais.py` | Gera `game/data/mundo/BR.json` da fonte (Python puro). Baixa a fonte do commit fixo e confere o SHA-256. |
| `tools/mundo/gerar_perfis.py` | Gera `game/data/mundo/BR_perfis.json` (região, área IBGE, lotes, biomas, vocação, recursos). |
| `tools/mundo/folha_conferencia.py` | Folha `game/docs/imagens/mundo/BR_conferencia.png` (precisa do Pillow, só para a imagem). |
| `tools/mundo/simular_lotes.py` | Simulação das compensações de tamanho (seção 5). |
| `tools/mundo/FONTE.md` | Licença, origem, SHA-256 e limitações da fonte. |
| `game/tests/test_mundo_brasil.py` | 23 checagens; entra no `tools/run_valdora_tests.sh` (também no `--py`). |

Regerar tudo: `python3 -I tools/mundo/gerar_pais.py && python3 -I tools/mundo/gerar_perfis.py && python3 -I tools/mundo/folha_conferencia.py`.

## 2. Fonte

Natural Earth, Admin 1, escala **1:10m**, domínio público, commit `ca96624` do `nvkelso/natural-earth-vector`. A 1:50m também traz as 27 unidades, mas a 1:10m foi escolhida porque tem 5 a 10 vezes mais pontos no litoral e nas divisas (importa quando um estado pequeno ocupa a tela), cobre o mundo todo (serve para os próximos países e para separar fronteira internacional de litoral) e tem os vértices idênticos dos dois lados de cada divisa. A fonte bruta (40 MB) não é versionada. Detalhes em `tools/mundo/FONTE.md`.

## 3. Formato do arquivo (`mundo-pais/1`)

Um JSON por país, compacto, chaves ordenadas, um estado por linha (diferenças legíveis no git). Cabeçalho com a fonte (commit, SHA-256, licença) e os parâmetros da geração. Para cada estado:

| Campo | Conteúdo |
|---|---|
| `uf`, `nome` | Sigla e nome |
| `area_km2` | Área da geometria final, projeção Albers de área igual (WGS 84) |
| `centroide` | Centro de área [lon, lat] |
| `rotulo` | Ponto interno mais longe da borda, para escrever o nome |
| `caixa` | [lon mín, lat mín, lon máx, lat máx] em inteiros de 0,0001 grau |
| `litoral`, `litoral_km` | Tem mar? Extensão aproximada do litoral na geometria final |
| `fronteira_exterior_km` | Fronteira com outros países |
| `vizinhos`, `divisas_km` | Estados com divisa e a extensão de cada divisa |
| `poligonos` | Lista de anéis externos; cada anel é `[lon, lat, lon, lat, ...]` em inteiros de 0,0001 grau (cerca de 11 m), anti-horário, sem repetir o primeiro ponto. Nenhum estado tem buraco. |

Escolhas: anéis prontos por estado (o jogo não precisa montar arcos); inteiros em vez de decimais (arquivo menor e sem diferença de arredondamento entre máquinas); lon/lat sem projeção (a tela escolhe a projeção de desenho). Os perfis ficam em arquivo separado (`mundo-perfis/1`), porque mudam por balanceamento e a geometria não.

## 4. Simplificação

- **Por arco, não por estado.** Os contornos são quebrados em arcos (divisa entre dois estados, fronteira com outro país, litoral) e cada arco é simplificado uma vez. Os dois lados de uma divisa ficam idênticos: sem buraco nem sobreposição entre vizinhos.
- **Tolerância proporcional ao tamanho.** Douglas-Peucker em metros, `0,001 × raiz(área do estado)`, entre 30 e 2.500 m. O jogo é em retrato (1.080 px de largura) e o mapa aceita zoom até o estado ocupar duas larguras de tela; nesse zoom máximo o erro fica em cerca de 2 px: DF 76 m, SE 147 m, SP 499 m, AM 1.252 m. Mais perto que isso, o limite é a própria fonte (o DF já usa 76 dos 86 pontos dela). Uma divisa usa a menor tolerância dos dois lados. (Primeira escolha da sessão: 0,002, para o estado ocupar uma largura de tela; refeita depois da decisão do modo retrato com zoom.)
- **Sem cruzamentos.** Se dois arcos passam a se cruzar, a tolerância deles cai à metade até não sobrar nenhum (4 arcos refeitos, de 108).
- **Ilhas com menos de 100 km² saem** (15 polígonos): Fernando de Noronha (que a fonte atribui ao RN), São Pedro e São Paulo, Trindade e Martim Vaz, e ilhas costeiras pequenas (entre elas São Vicente, SP, e Itamaracá, PE). Ficam, por exemplo, Marajó, São Luís, Florianópolis e Ilhabela.
- **Resultado:** 241 KB e 15.131 vértices (meta: até 1 MB). Área de cada estado a menos de 0,3% da fonte sem simplificar. Testadas também tolerâncias fixas (500 m: 221 KB; 1.500 m: 113 KB; 4.000 m: 58 KB): com valor fixo de 1.500 m o DF ficava com 14 vértices.

## 5. Lotes e compensações de tamanho

**Fórmula mantida:** `round(clamp(40 + 32,9 × log10(área IBGE / 5760), 40, 120))`, sempre sobre a área oficial. Faixa de 40 (DF) a 120 (AM), monotônica pela área. Distribuição: 1 estado com 40, 6 entre 59 e 73, 15 entre 80 e 99, 5 entre 106 e 120. Dois valores da tabela do desenho estavam arredondados para baixo e foram corrigidos pela própria fórmula: **BA 105 → 106** e **PE 80 → 81**.

**Simulação** (`simular_lotes.py`): 2 obras simultâneas, tempos e produção das fórmulas dos componentes, prédios liberados pela tabela do QG (15% a 95% dos lotes), nenhum prédio acima do QG; recursos não travam (a pergunta é só o efeito do tamanho). Valores relativos à mediana dos 27 (1,00 = mediana).

- **Sem compensação, o Amazonas fica claramente melhor:** 1,8 vez a produção do DF na primeira semana e 3 vezes depois de 6 meses. Os lotes viram teto de capacidade.
- **Busca em grade** de três compensações (produção por lote `(80/L)^γ`, transporte `1 − τ(√(L/40) − 1)`, tempo de obra `(L/80)^β`), escolhendo a que dá a menor diferença maior/menor em 3, 7, 30, 90 e 180 dias. **Melhor: γ = 0,75, τ = 0, β = 0** (diferença máxima 1,32). Transporte e tempo de obra mais lentos para estado grande **pioram** o equilíbrio neste modelo: o estado pequeno já sai na frente no começo, e esses dois só aumentam a vantagem dele.
- **Com a densidade (γ = 0,75) aplicada à produção e ao poder:** nenhum estado passa de ±21% da mediana em momento algum. Estados pequenos lideram o primeiro mês, os grandes depois de três meses. O caso de borda é o **DF**: +21% na primeira semana e −19% depois de 90 dias, quando os 38 prédios dele já estão no nível 30.
- **Nenhum ajuste na fórmula de lotes.** A diferença final entre o maior e o menor é `(120/40)^0,25 = 1,32`; subir o piso para 50 lotes só traria o DF de 0,81 para 0,85 da mediana.

| UF | Área IBGE (km²) | Lotes | Sem comp.: produção dia 7 | Sem comp.: dia 180 | Com: produção dia 7 | dia 30 | dia 90 | dia 180 | Com: poder dia 7 | poder dia 180 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| DF | 5.761 | 40 | 0,64 | 0,44 | 1,20 | 1,20 | 0,84 | 0,82 | 1,07 | 0,82 |
| SE | 21.938 | 59 | 0,79 | 0,64 | 1,10 | 1,10 | 0,93 | 0,90 | 1,03 | 0,90 |
| AL | 27.831 | 63 | 0,82 | 0,68 | 1,09 | 1,09 | 0,93 | 0,90 | 1,03 | 0,90 |
| RJ | 43.750 | 69 | 0,86 | 0,75 | 1,07 | 1,06 | 0,96 | 0,93 | 1,03 | 0,93 |
| ES | 46.074 | 70 | 0,87 | 0,76 | 1,06 | 1,06 | 0,96 | 0,93 | 1,03 | 0,93 |
| RN | 52.810 | 72 | 0,88 | 0,78 | 1,06 | 1,06 | 0,97 | 0,94 | 1,02 | 0,94 |
| PB | 56.467 | 73 | 0,89 | 0,79 | 1,05 | 1,05 | 0,97 | 0,94 | 1,02 | 0,94 |
| SC | 95.731 | 80 | 0,93 | 0,87 | 1,03 | 1,03 | 1,00 | 0,97 | 1,01 | 0,97 |
| PE | 98.068 | 81 | 0,94 | 0,87 | 1,03 | 1,03 | 0,99 | 0,96 | 1,01 | 0,96 |
| AP | 142.471 | 86 | 0,97 | 0,93 | 1,02 | 1,02 | 1,01 | 0,98 | 1,01 | 0,98 |
| CE | 148.894 | 86 | 0,97 | 0,93 | 1,02 | 1,02 | 1,01 | 0,98 | 1,01 | 0,98 |
| AC | 164.173 | 88 | 0,98 | 0,95 | 1,01 | 1,01 | 1,02 | 0,99 | 1,00 | 0,99 |
| PR | 199.299 | 91 | 1,00 | 0,99 | 1,01 | 1,00 | 1,02 | 1,00 | 1,01 | 1,00 |
| RR | 223.644 | 92 | 1,00 | 1,00 | 1,00 | 1,00 | 1,02 | 1,00 | 1,00 | 1,00 |
| RO | 237.754 | 93 | 1,01 | 1,01 | 1,00 | 0,99 | 1,02 | 1,00 | 1,00 | 1,00 |
| SP | 248.220 | 94 | 1,01 | 1,02 | 1,00 | 0,99 | 1,01 | 1,01 | 1,00 | 1,01 |
| PI | 251.756 | 94 | 1,01 | 1,02 | 1,00 | 0,99 | 1,01 | 1,01 | 1,00 | 1,01 |
| TO | 277.424 | 95 | 1,02 | 1,03 | 1,00 | 0,99 | 1,01 | 1,01 | 1,00 | 1,01 |
| RS | 281.707 | 96 | 1,02 | 1,05 | 0,99 | 0,99 | 1,01 | 1,01 | 0,99 | 1,01 |
| MA | 329.652 | 98 | 1,04 | 1,07 | 0,99 | 0,99 | 1,01 | 1,02 | 1,00 | 1,02 |
| GO | 340.243 | 98 | 1,04 | 1,07 | 0,99 | 0,99 | 1,01 | 1,02 | 1,00 | 1,02 |
| MS | 357.142 | 99 | 1,05 | 1,08 | 0,99 | 0,98 | 1,00 | 1,02 | 1,00 | 1,02 |
| BA | 564.760 | 106 | 1,08 | 1,15 | 0,97 | 0,97 | 0,98 | 1,03 | 0,98 | 1,03 |
| MG | 586.514 | 106 | 1,08 | 1,15 | 0,97 | 0,97 | 0,98 | 1,03 | 0,98 | 1,03 |
| MT | 903.208 | 112 | 1,11 | 1,22 | 0,96 | 0,96 | 0,98 | 1,05 | 0,98 | 1,05 |
| PA | 1.245.871 | 117 | 1,13 | 1,28 | 0,94 | 0,94 | 0,96 | 1,07 | 0,97 | 1,07 |
| AM | 1.559.256 | 120 | 1,15 | 1,31 | 0,94 | 0,94 | 0,95 | 1,07 | 0,97 | 1,07 |
| **maior/menor** | | | 1,80 | 3,00 | 1,27 | 1,27 | 1,21 | 1,32 | 1,10 | 1,32 |

Colunas "Com": produção por lote `(80/L)^0,75`, sem compensação de transporte e de tempo. "Poder" é o poder dos prédios multiplicado pelo mesmo fator.

## 6. Perfis (`BR_perfis.json`)

Para cada estado: sigla, nome, região, área oficial (IBGE 2022) e calculada com a diferença em %, lotes, bioma dominante e lista de biomas (por participação na área), litoral, vizinhos, vocação fictícia e dois recursos fortes. Bioma e vocação seguem a tabela do desenho, com uma mudança: **MT passa a ter a Amazônia como bioma dominante** (cerca de 54% da área, contra 40% de Cerrado). Recursos fortes são proposta nova: dois por estado entre alimentos, materiais, metal e energia (+5% de produção cada), ligados à vocação; distribuição 14, 15, 11 e 14.

Diferenças de área acima de 1,5%, todas da fonte: **AC −6,4%** (divisa AC–AM com o traçado antigo; exceção registrada no teste, limite de 7%), **RS −3,3%** (lagoas dos Patos e Mirim fora do polígono), **AP −2,4%** (ilhas e estuário). O total do país fica 0,45% abaixo do oficial.

## 7. Decisões do dono

| # | Decisão | Proposta |
|---|---|---|
| 1 | Compensação de tamanho | Só densidade: produção e poder por prédio × `(80/lotes)^0,75`. Transporte e tempo de obra sem penalidade por tamanho (pioram o equilíbrio). |
| 2 | Recursos fortes | Dois por estado, +5% cada (tabela em `gerar_perfis.py`). |
| 3 | MT com Amazônia dominante | Corrige o dado; não muda vocação. |
| 4 | Acre com área menor na geometria | Aceitar a fonte (lotes usam a área oficial). Corrigir a divisa AC–AM exigiria outra fonte aberta (IBGE), em outra sessão. |
| 5 | DF sem divisa com MG | Aceitar a fonte. |
| 6 | Ilhas oceânicas fora do mapa | Fernando de Noronha e Trindade fora do piloto; podem voltar como zona especial. |

Continuam pendentes, sem mudança: nome do jogo, cor final, atribuição do estado, territórios disputados, pacote do app, nomes dos heróis.
