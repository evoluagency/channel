# HANDOFF 1.7 — Valdora PvP: gráfico da arte conceitual (16/11/2026)

Branch `claude/zealous-tesla-kfhwld`. Registro oficial: `game/docs/ESTADO_DO_PROJETO.md`, seção da sessão 1.7.

## O que foi feito

1. **Luz e cor dos 5 mapas** (`scripts/pvp/visual/cenario.gd`, `_luz()` e `TEMAS`):
   - céu `ceu.gdshader`: gradiente, halo do sol e nuvens;
   - sol dourado a cerca de 30°;
   - ambiente por cor quente (`AMBIENT_SOURCE_COLOR`) e contraluz quente fraco;
   - filmic, brilho (glow) e neblina 0,0026;
   - saturação 1,16;
   - rim no `superficie.gdshader`.
2. **Detalhe** (`scripts/pvp/visual/ornamentos.gd`):
   - o kit inteiro é malha visual juntada por material, sem colisão nem nós próprios;
   - `cenario.gd::_ornar` põe arcadas (até 6 por mapa, só em face ≥ 6 m, mais nas bordas), trepadeiras e jardineiras acima de 2,2 m;
   - lampiões, estandartes e árvores substituem os antigos;
   - os marcos regionais estão em `_fundo()`.
3. **Menu**: `scripts/ui/pvp/pvp_fundo.gd` mostra a praça `scripts/pvp/visual/praca_valdora.gd` num SubViewport (MSAA 2×; sem MSAA no Baixa; respeita escala e sombras de Ajustes > Vídeo).
4. **Personagens**: `game/docs/PVP_PERSONAGENS_CC0.md`.
5. **Versão** 0.5.4-pvp, código 108. APK pelo workflow: ver o ESTADO.

## Medidas

Até 51 malhas e 172 mil triângulos por arena; praça do menu com 23 malhas e 23 mil triângulos. As capturas imprimem malhas e triângulos:

```sh
xvfb-run -a godot --path game --rendering-driver opengl3 -s tests/pvp_cenario_capturas.gd -- --saida=PASTA [--mapa=id]
xvfb-run -a godot --path game --rendering-driver opengl3 -s tests/pvp_menu_smoke.gd -- --capturas=PASTA
```

## O que falta ou ficou aquém da arte

- **Personagens** (a maior diferença para a arte): o jogador e os bots continuam sendo cápsulas e formas por código. Caminho em `PVP_PERSONAGENS_CC0.md`.
- **Arma em primeira pessoa** no estilo da arte (creme, verde-azulado e laranja): não feita.
- **Interface:** as telas continuam com o layout da 1.6 (painéis escuros opacos). A arte usa painéis navy translúcidos, cantos grandes e botões laranja com brilho. É a próxima frente, porque a praça 3D já aparece atrás.
- **Esplanada:** é o mapa mais distante da arte, porque o modernismo de Brasília é branco e reto. Recebeu arcadas, trepadeiras e cores quentes, sem perder a região.
- **Água do chafariz** sem jato animado; flores são octaedros pequenos (barato no celular).
- **FPS no aparelho:** não medido. Pontos a observar: o glow e a praça 3D atrás do menu. Se o celular sofrer, os primeiros cortes são `glow_enabled` e o MSAA do fundo.

## Pegadinhas

- `godot_checar_scripts.sh` precisa de `GODOT=` apontando para o binário; sem ele agora sai com código 2. Antes dava falso "0 erros".
- No GDScript tipado, `var x := s * ...` com `s` vindo de um `for` sobre lista literal não compila. Use `var x: float = ...`.
- `tools/pvp/__pycache__/*.pyc` está versionado por engano e muda quando se roda o teste de mapas. Não fazer commit dele.
