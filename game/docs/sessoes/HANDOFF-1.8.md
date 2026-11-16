# HANDOFF 1.8 — Valdora PvP: paintball, heróis, bots e interface da arte (16/11/2026)

Branch `claude/zealous-tesla-kfhwld`. Registro oficial: `game/docs/ESTADO_DO_PROJETO.md`, seção da sessão 1.8.

## O que foi feito

1. **Paintball:**
   - tinta: `scripts/pvp/pvp_tinta.gd`;
   - respingo: `visual/tinta_respingo.gdshader`;
   - aparências do marcador: `visual/pintura_marcador.gdshader` e `data/pvp/aparencias.json`;
   - armas: `visual/marcador.gd` (marcador, pistola e granada).
2. **Jogador** (`pvp_jogador.gd`):
   - três armas (teclas 1 a 3 ou toque nos espaços do HUD);
   - vida e escudo, queda e volta;
   - arma em primeira pessoa com braços.
3. **Heróis:**
   - 11 em `data/pvp/herois.json`, sobre o KayKit (CC0) em `assets/pvp/personagens/`;
   - visual: `visual/heroi_visual.gd`;
   - retratos: `visual/retratos.gd`;
   - ferramentas: `tools/pvp/podar_glb.py` e `tools/pvp/recolorir_herois.py`.
4. **Bots:** `pvp_bot.gd`. A arena (`pvp_arena.gd`) ganhou `combatentes`, `placar`, `caminho()`, `celula_aleatoria()`, `registrar_abate()` e o tempo de partida.
5. **Interface:**
   - HUD novo: `pvp_hud.gd`;
   - menus reestruturados: `ui/pvp/pvp_menu.gd`;
   - vitrine 3D: `ui/pvp/pvp_vitrine.gd`;
   - tema: `T.vidro()` em `pvp_tema.gd`;
   - ícones novos: `pvp_icone.gd`.
6. **Versão:** 0.6.0-pvp, código 109, nos 7 pontos de versão.

## Como conferir

```sh
GODOT=/caminho/godot tools/run_valdora_tests.sh          # 26 testes
xvfb-run -a $GODOT --path game --rendering-driver opengl3 -s tests/pvp_menu_smoke.gd -- --capturas=PASTA
xvfb-run -a $GODOT --path game --rendering-driver opengl3 -s tests/pvp_arena_smoke.gd -- --capturas=PASTA   # inclui arena_bots.png
python3 -I tools/pvp/recolorir_herois.py                 # regenera as texturas dos heróis após mudar herois.json
```

## O que falta ou ficou aquém da arte

- **Heróis:**
  - os corpos KayKit são "chibi"; a arte tem proporção heroica e rosto detalhado;
  - acessórios de origem (cocar, turbante, lenço, óculos do Nilo) não foram modelados;
  - antes de publicar, rever os trajes de origem com cuidado (ver `PVP_REFERENCIAS_1.8.md`).
  - Caminho para chegar à arte: imagem para 3D local (TripoSR ou TRELLIS) no computador do dono, ou acessórios modelados presos aos ossos (`BoneAttachment3D` em `head`).
- **Armas:**
  - feitas 3 das 30: 01 marcador, 06 pistola e 14 granada de tinta;
  - faltam as outras 27 (ordem em `PVP_REFERENCIAS_1.8.md`);
  - o marcador por código é aceitável, mas ainda não tem o acabamento da arte.
- **Atributos dos heróis:** só aparecem na ficha; ainda não mudam a partida.
- **Bots:**
  - não usam cobertura nem agacham;
  - miram no peito com imprecisão fixa.
- **Modo:** o confronto 5 × 5 não tem rodadas nem bomba. A tela Missões ainda é a seleção de modos da 1.6.
- **FPS no aparelho:** não medido. Pontos novos a observar:
  - 10 personagens com esqueleto;
  - a vitrine 3D sobre a praça 3D do menu;
  - os retratos renderizados na entrada.
  Primeiros cortes se pesar: MSAA da vitrine, sombra do sol da vitrine e número de bots.

## Pegadinhas

- **Corpos na física:** desligar `process_mode` de um bot tira o corpo da física, e a tinta passa por ele. Para congelar um bot num teste, use `set_physics_process(false)`.
- **Cor da instância:** no GL Compatibility, a cor da instância do MultiMesh não chega pelo `COLOR` (sai preta). Use `INSTANCE_CUSTOM`.
- **Camadas de colisão:** bots e jogador ficam na camada 2. O smoke de colisão da grade consulta só a camada 1, e o `ARENA.com_bots = false` desliga os bots nos testes de mapa.
- **Retratos sem renderizador:** o headless não gera retratos (o HUD mostra a inicial).
- **KayKit e rede:** o itch.io e as páginas do GitHub fora do repositório respondem 403 nesta rede. O `git clone` do repositório público funciona.
- **Arquivos que não vão no commit:** `tools/pvp/__pycache__/*.pyc` continua versionado por engano.
