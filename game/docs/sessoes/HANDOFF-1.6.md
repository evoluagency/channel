# Handoff 1.6 — Cidade 3D, M8 (14/11/2026)

Branch: `claude/zealous-tesla-kfhwld`. Nada publicado: sem push na `main`, deploy, OTA, APK ou workflow. O jogo instalado (Valdora 0.4.1, OTA rev 10) não mudou. Tudo novo está em `tools/arte3d/` (projeto de arte e teste, separado do jogo).

## Feito

### 1. Fusão de malhas e nível de detalhe (`tools/arte3d/fusao.gd`)

- Cada construção e faixa vira **uma malha com até 5 superfícies**, uma por tipo de mistura: opaco, translúcido, feixe, aditivo e sem sombra. Na prática ficam de 1 a 4.
- O material do kit vira atributo de vértice: cor, rugosidade, metal e emissão. Assim, 4 shaders servem à cidade inteira.
- Conferido **pixel a pixel** contra as folhas aprovadas: diferença média de 0,00 a 0,02 em 255. No GL Compatibility a cor de vértice já chega igual ao albedo do material, sem conversão.
- **Modo cidade do kit** (desligado por padrão, então as folhas não mudam; conferido na Usina):
  - esferas 10×5;
  - cilindros até 16 lados;
  - toros 20×6.
- **LOD 1** (de longe) sai de uma segunda montagem com esferas 6×3 e cilindros até 8 lados. Ficam de fora:
  - pessoas, drones, veículos, bancos e plantas miúdas (marcados no kit);
  - peças com menos de 0,3 no maior lado;
  - tiras com menos de 0,09 na medida do meio.
- As 90 combinações (15 × 6): **7.529 peças → 150 superfícies** (até 4 por construção). Por construção, o LOD 0 tem de 1,5 mil a 20,5 mil triângulos.

### 2. Cidade em retrato (`tools/arte3d/cidade.tscn`)

- Grade de **80 lotes** (8 × 10), com as vias em cruz (17 lotes).
- Uma `MultiMesh` por construção e faixa. O LOD 0 fica em blocos de 2×2 lotes, para a câmera recortar o que não aparece; de perto, a sombra vem da malha leve do LOD 1.
- **Câmera ortográfica** (33°/45°), com a seção 3.1 adaptada à base:
  - arrastar com um dedo ou com o mouse, até a caixa da base mais meia tela;
  - pinça ou roda do mouse;
  - afastar até a base ocupar 60% da largura;
  - aproximar até um lote ocupar 85% da largura;
  - LOD 1 quando a largura visível passa de 24 unidades (cerca de 3 lotes).
- **Selos de nível em 2D**, numa malha só: custam 2 chamadas em vez de 70 a 290. Somem quando o lote fica com menos de 45 px.
- **Painel para o aparelho:** FPS, milissegundos, chamadas, triângulos e LOD; botões Cenário, Sombra e Medir.
- No celular, o projeto abre direto na cidade (`run/main_scene.mobile`) em retrato, com mapa de sombra de 2048 e MSAA 2×.

### 3. Arte

- **Banco da cidade** (`construcoes/banco.gd`). Assinatura: creme-mármore, verde-cédula e dourado. As faixas:
  1. contêiner com cofre e placa;
  2. agência com caixa eletrônico;
  3. agência de colunas com frontão;
  4. torre de vidro verde com letreiro "BANCO";
  5. duas torres com painéis de cotação e drones com malotes;
  6. rotunda com cúpula dourada e cofre iluminado na cor da aliança.
- **Centro tecnológico** (`construcoes/centro_tecnologico.gd`). Assinatura: branco, grafite e verde-circuito. As faixas:
  1. contêiner com antena e bancada;
  2. laboratório com painéis solares;
  3. instituto com observatório;
  4. torre com laboratórios aparentes;
  5. campus com racks, telas holográficas e drones;
  6. torre em hélice com anel de pesquisa iluminado.
- **Prefeitura:** a receita foi renomeada (`quartel_general.gd` → `prefeitura.gd`) e o letreiro da faixa 3 passou de "QG" para "PREFEITURA".
- Folhas em `game/docs/imagens/componentes/`:
  - novas: `banco_*`, `centro_tecnologico_*` e `prefeitura_*` (as do QG saíram);
  - catálogo: `catalogo_15_construcoes.png`.
- `GUIA_DE_ARTE_v0.1.md`: assinaturas novas e seção 8.1.

### 4. Medição local (Godot 4.7.2 oficial, GL Compatibility, janela 540 × 1170, 60 quadros)

Cidade **cheia** no nível 30 (80 lotes ocupados), com sombra:

| Zoom (largura visível) | LOD | Chamadas | Triângulos |
|---|---|---|---|
| perto (9,8) | 0 | 110 | 227 mil |
| padrão (20) | 0 | 166 | 360 mil |
| médio (30) | 1 | 61 | 299 mil |
| longe (127, base inteira) | 1 | 59 | 298 mil |

| Cenário | Chamadas (faixa) | Triângulos (faixa) |
|---|---|---|
| `n30` (só o que a regra permite: 33 prédios, 17 vias e 30 lotes vazios) | 61 a 121 | 176 a 234 mil |
| `misto` (faixas sorteadas, 53 malhas diferentes) | 103 a 150 | 230 a 349 mil |
| `cheia` sem sombra | 42 a 109 | 145 a 239 mil |
| `cheia` **sem fusão** (peças soltas, como as folhas) | **3.107 a 13.266** | 304 mil a 1,3 milhão |

- Montar e fundir a cidade leva cerca de 0,4 s (1,1 s no `misto`). Não foi preciso exportar `.glb`.
- **O tempo de quadro daqui não vale para o celular.** A máquina não tem placa de vídeo, e o Godot desenha por software (llvmpipe): de 100 a 330 ms por quadro. Os números estão nos JSON, mas o que decide são as contagens e a medição no aparelho.
- Arquivos: `game/docs/logs/cidade3d/contagens_*.json`, `contagens_construcoes.json` e capturas `cidade_*.png`.

### 5. Testes

- `tools/arte3d/smoke_cidade.gd` passou. Ele confere:
  - as 90 combinações sem aviso, com até 5 superfícies e LOD 1 ≤ LOD 0 ≤ folha;
  - os 80 lotes;
  - o LOD por zoom;
  - os limites de zoom e de arrasto;
  - arrastar e pinça por eventos de toque;
  - menos de 200 chamadas;
  - o botão Medir.
- `game/tests/test_cidade3d.py`: 463/463 (entra no `tools/run_valdora_tests.sh --py`, agora com 9/9). Ele confere:
  - os 15 ids do JSON v0.3 com receita e folha;
  - a Prefeitura renomeada;
  - os 90 itens fundidos;
  - a composição do `n30` pela regra (5 por tipo de produção, 4 Alojamentos, 1 de cada único);
  - o orçamento de 200 chamadas e 400 mil triângulos nos três cenários com sombra;
  - a fusão cortando as chamadas em 10 vezes ou mais.
- Também passaram `test_componentes_mundo` 12/12 e `test_economia_mundo` 37/37.

## Pendências

- **Do dono:**
  1. Avaliar a arte do Banco e do Centro tecnológico (folhas e catálogo).
  2. Dar o OK para o APK de teste da cidade (`ROTEIRO_APARELHO_M8.md`). O recomendado é gerar no próprio computador, sem custo, com pacote separado `ink.evolu.mundo.teste3d`.
  3. Medir no Samsung e no Xiaomi. O M8 só fecha com essa medição.
- **Técnicas:**
  - A sombra dobra as chamadas. Se o aparelho não segurar 30 FPS, a ordem de cortes está no roteiro, seção 4.
  - Transparências dentro de uma mesma malha não são ordenadas entre si; não houve defeito visível.
  - Animações (seção 7 do guia) ainda não existem. Peças animadas vão precisar ficar fora da fusão, como nó próprio.
- **Antigas do dono:** nome do jogo, cor final, atribuição do estado, territórios disputados, pacote do app, nomes dos heróis e detalhes da disputa entre países.

## Retomar

```bash
git checkout claude/zealous-tesla-kfhwld && git pull
G=/caminho/Godot_v4.7.2-stable_linux.x86_64   # zip SHA-256 cadd3204…
cd tools/arte3d && $G --headless --editor --path . --quit
$G --path . --rendering-driver opengl3 res://cidade.tscn -- --cenario=cheia          # abrir
xvfb-run -a -s "-screen 0 1600x1600x24" $G --path . --rendering-driver opengl3 -s smoke_cidade.gd -- --saida=../../game/docs/logs/cidade3d
python3 -I ../../game/tests/test_cidade3d.py
```

Próxima sessão: `PROMPT-1.7.md` (mapa do Brasil em retrato, M3, mais os resultados do aparelho, se chegarem).

Modelo: Opus para a câmera e a seleção por toque do M3. Sonnet basta para registrar as medições do aparelho e regerar as folhas.
