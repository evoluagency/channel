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
  --construcao=quartel_general --saida=/tmp/qg --trabalhos=$J
python3 folha.py /tmp/qg quartel_general "Quartel-general" ../../game/docs/imagens/componentes
```

Renderizador: GL Compatibility, o mesmo do jogo no celular (sem SSAO e sem reflexo rico;
por isso o ouro é "pintado", não metálico). Cerca de 15 s para os 17 PNG de uma construção.
