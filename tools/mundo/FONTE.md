# Fonte dos contornos

- **Dado:** Natural Earth, *Admin 1 – States, Provinces*, escala 1:10m (versão GeoJSON).
- **Licença:** domínio público. Termos: https://www.naturalearthdata.com/about/terms-of-use/ ("All versions of Natural Earth raster + vector map data found on this website are in the public domain. You may use the maps in any manner, including modifying the content and design, electronic dissemination, and offset printing."). Crédito sugerido, não obrigatório: "Made with Natural Earth".
- **Origem:** `github.com/nvkelso/natural-earth-vector`, commit `ca96624a56bd078437bca8184e78163e5039ad19`, arquivo `geojson/ne_10m_admin_1_states_provinces.geojson`.
- **SHA-256:** `22d0e3ad85eb3e27f17cabf8ba2d50e554fbc27a87796ff891d958185da62fb5` (40.726.851 bytes).
- **Não versionado:** o arquivo bruto fica em `tools/mundo/.cache/` (ignorado pelo git). `gerar_pais.py` baixa do commit fixo e confere o SHA-256 antes de usar.

## Por que 1:10m e não 1:50m

Conferido em 13/11/2026. As duas trazem o Brasil com as 27 unidades e as mesmas siglas. A 1:10m:

- tem o litoral e as divisas com 5 a 10 vezes mais pontos (o DF passa de 17 para 86), o que importa quando um estado pequeno ocupa a tela inteira;
- cobre o mundo todo (a 1:50m só 9 países), então serve para os próximos países e para separar fronteira internacional de litoral;
- tem vértices idênticos dos dois lados de cada divisa, o que permite simplificar cada divisa uma vez só.

A diferença de área entre as duas é pequena (até 0,5% por estado). O arquivo final não depende do tamanho da fonte, só da tolerância.

## Limitações conhecidas da fonte

- **Acre:** a divisa AC–AM segue o traçado antigo; o Acre sai cerca de 6% menor que a área oficial do IBGE (e o Amazonas, cerca de 0,5% maior). Os lotes usam a área oficial, então o jogo não é afetado.
- **Rio Grande do Sul:** as lagoas dos Patos e Mirim ficam fora do polígono (cerca de 3% da área oficial). As margens das lagoas contam como litoral.
- **DF e MG:** no IBGE o DF tem uma divisa curta com Minas Gerais; na fonte os dois só se tocam em um ponto. O arquivo registra o DF com um único vizinho (GO).
- **Fernando de Noronha** aparece na fonte como parte do RN (é de PE). Sai do arquivo junto com as outras ilhas com menos de 100 km².
