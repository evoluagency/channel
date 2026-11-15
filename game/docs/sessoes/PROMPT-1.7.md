# Valdora 1.7 (PvP: gráfico da arte conceitual em todo o jogo)

Responda em português do Brasil, de forma direta. Branch: `claude/zealous-tesla-kfhwld`; desenvolva e faça push nela.

Leia antes de agir, nesta ordem:

- `game/docs/ESTADO_DO_PROJETO.md`: as três primeiras seções da 1.6.
- `game/docs/PVP_v0.1.md`.
- `game/docs/PVP_QUALIDADE_VISUAL.md`: diagnóstico feito pelo ChatGPT.
- Código:
  - `game/scripts/pvp/visual/` (`cenario.gd`, `construtor.gd`, `superficie.gdshader`, `agua.gdshader`, `esplanada_acabamento.gd` e `qualidade_video.gd`);
  - `game/scripts/pvp/` (arena, jogador, interface da partida e atualizador);
  - `game/scripts/ui/pvp/` (menus).

## Contexto

- **Foco 100% no PvP.** É um jogo de tiro 5 × 5 em primeira pessoa no celular, com estrutura de menus de tiro competitivo mobile (referência: Standoff 2) e acabamento estilizado de jogo mobile premium (referência: Last War e a arte conceitual do dono).
- **O jogo de estratégia (MUNDO, cidades, alianças) foi encerrado pelo dono.** Não retomar.
- **Feito na 1.6:**
  - menus em 10 telas;
  - 5 mapas do modo Desarmar, com equilíbrio testado (`game/data/pvp/mapas_v0.1.json`);
  - arenas 3D jogáveis, com cenários regionais e lojas: Brasília, Rio, Salvador, São Paulo e Pará;
  - atualização automática do APK.
- **Publicado:** APK 0.5.3-pvp (versionCode 107), que o dono instala pelo link fixo `https://github.com/evoluagency/channel/releases/latest/download/Valdora.apk`.
- **Como gerar um APK novo:**
  1. Suba o versionCode em `export_presets.cfg`, `release-control/version.txt`, `update_contract.gd` (`CLIENT_CODE`), nos 3 testes estáticos (`version/code=`) e no workflow (`versionCode=`).
  2. Dispare o workflow `valdora-android-release.yml` na branch com `fonte=claude/zealous-tesla-kfhwld` e `publicar_link=true`.
  3. O app instalado avisa e se atualiza sozinho.
- **O ChatGPT também mexe nesta branch.** Antes de trabalhar: `git pull` e `GODOT=... tools/run_valdora_tests.sh` (hoje 22 de 22). Na 1.6 ele deixou 2 erros de sintaxe; `tools/godot_checar_scripts.sh` pega isso.

## Objetivo

O dono quer o gráfico da arte conceitual dele em toda a atmosfera do jogo. Referência: telas "Heróis" e "Base" do Valdora, com praça de pedra creme, cúpulas verde-azuladas, arcos, estandartes verde-azulados com o V dourado, flores e trepadeiras, luz dourada de fim de tarde, cores saturadas e acabamento de desenho animado 3D. O ambiente de cada mapa continua refletindo a região real.

1. **Luz e cor de todos os mapas:**
   - sol dourado, sombra quente (não azul), verdes saturados, leve brilho nas luzes e neblina de profundidade;
   - conferir sempre por capturas em `tests/pvp_cenario_capturas.gd` (com `xvfb-run` e `--rendering-driver opengl3`).
2. **Detalhe nos cenários:**
   - arcos, cúpulas trabalhadas, ornamentos e cornijas;
   - floreiras com flores, trepadeiras nas paredes e vegetação mais cheia (copas em vários volumes);
   - marcos de cada cidade mais reconhecíveis.
   - Manter a colisão da grade e o orçamento do celular: até cerca de 80 malhas e 250 mil triângulos por arena.
3. **Menus com cenário 3D ao fundo** (praça do Valdora), no lugar das silhuetas planas.
4. **Personagens:**
   - o acabamento de desenho animado dos heróis não sai por código;
   - levantar modelos 3D gratuitos com licença livre (CC0) compatíveis, ou o caminho de imagem para 3D por IA;
   - não propor gasto.
5. **Registro e entrega:**
   - testes;
   - APK novo com o link fixo;
   - atualizar `ESTADO_DO_PROJETO.md`, escrever `HANDOFF-1.7.md` e `PROMPT-1.8.md`.

## Regras

- Único gasto pago: assinatura Claude.
- Sem push na `main` e sem deploy na Vercel.
- O dono autorizou gerar APK pelo workflow e publicar o link.
- Chaves privadas nunca no repositório. Não copiar arte, personagens nem nomes de outros jogos.
- Poupar contexto. Perguntar só o que bloquear.

## Modelo

- Opus para a direção de arte e a luz.
- Sonnet para adereços repetitivos, capturas e testes.
