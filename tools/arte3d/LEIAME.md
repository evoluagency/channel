# arte3d — gerador das construções do MUNDO (sessão 1.2)

Projeto Godot só de arte, separado do jogo (`game/` não é tocado). Cada construção é uma
receita em GDScript que monta peças de baixo polígono do `kit.gd` (caixas chanfradas,
cilindros, janelas, bandeira, antena, drone, painel solar, veículo, pessoa, selo de nível).
Nenhum modelo externo: forma, cor e faixa são parâmetros, e a mesma receita vira o modelo
da cidade 3D na sessão 1.5.

- `kit.gd`: paleta, cores de aliança, materiais e peças.
- `construcoes/<nome>.gd`: `construir(kit, pai, faixa) -> altura do topo`, faixas 1 a 6.
- `render.gd`: luz, câmera ortográfica isométrica (33° / 45°) e PNG por trabalho.
- `folha.py`: monta a folha das seis faixas e a do detalhe da faixa 6 com as alianças.
- Fonte Montserrat (OFL, licença ao lado).

## Gerar

Atalho: `GODOT=/caminho/do/godot tools/arte3d/gerar.sh alojamento "Alojamento"`.

```bash
G=/caminho/Godot_v4.7.2-stable_linux.x86_64
cd tools/arte3d && $G --headless --editor --path . --quit   # 1ª vez: importa a fonte
J="1:azul:folha,2:azul:folha,3:azul:folha,4:azul:folha,5:azul:folha,6:azul:folha,6:azul:detalhe"
for a in azul vermelha verde roxa amarela; do J="$J,3:$a:alianca,6:$a:alianca"; done
xvfb-run -a -s "-screen 0 1600x1600x24" $G --path . --rendering-driver opengl3 -- \
  --construcao=prefeitura --saida=/tmp/qg --trabalhos=$J
python3 folha.py /tmp/qg prefeitura "Prefeitura" ../../game/docs/imagens/componentes
```

Renderizador: GL Compatibility, o mesmo do jogo no celular (sem SSAO e sem reflexo rico;
por isso o ouro é "pintado", não metálico). Cerca de 15 s para os 17 PNG de uma construção.

## Cidade 3D (sessão 1.6, M8)

Projeto de teste da cidade em retrato, no mesmo projeto de arte (o jogo instalado não é tocado).

- `fusao.gd`: funde as peças de uma construção e faixa numa malha (até 5 superfícies) e gera o LOD 1.
- `cidade.gd` + `cidade.tscn`: grade de 80 lotes (8 × 10), câmera ortográfica com arrastar e pinça
  nos limites da seção 3.1 de `DESENHO_MUNDO_v0.1.md`, LOD por zoom, selos em 2D e medição.
- `selos_cidade.gd`: selos de nível desenhados numa malha 2D só.
- `smoke_cidade.gd`: smoke (90 combinações, LOD, câmera); grava `contagens_construcoes.json`.

```bash
G=/caminho/Godot_v4.7.2-stable_linux.x86_64
cd tools/arte3d
# abrir a cidade (mouse: arrastar e roda; celular: dedo e pinça)
$G --path . --rendering-driver opengl3 res://cidade.tscn -- --cenario=cheia
# medir e gravar contagens (cenários: cheia, n30, misto; opções --sombra=0, --sem_fusao)
xvfb-run -a -s "-screen 0 1600x1600x24" $G --path . --rendering-driver opengl3 res://cidade.tscn -- \
  --cenario=cheia --medir=../../game/docs/logs/cidade3d --quadros=60
# smoke
xvfb-run -a -s "-screen 0 1600x1600x24" $G --path . --rendering-driver opengl3 -s smoke_cidade.gd -- \
  --saida=../../game/docs/logs/cidade3d
python3 -I ../../game/tests/test_cidade3d.py
```

Sem placa de vídeo (xvfb) o Godot desenha por software (llvmpipe): as contagens valem, o tempo de
quadro não representa o celular.
