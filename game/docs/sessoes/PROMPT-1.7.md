# Valdora 1.7 (Mapa do Brasil em retrato, M3)

Responda em português do Brasil, de forma direta. Branch de partida: `claude/zealous-tesla-kfhwld`. Leia antes de agir: `game/docs/ESTADO_DO_PROJETO.md`, `game/docs/sessoes/HANDOFF-1.6.md`, `game/docs/DESENHO_MUNDO_v0.1.md` (seções 3, 3.1 e 4.1; marcos M3 e M8), `game/docs/MUNDO_BRASIL_DADOS_v0.1.md` e `game/docs/ROTEIRO_APARELHO_M8.md`.

## Contexto

- **Jogo:** moderno, de base e estratégia, com mapa real; nome provisório "MUNDO". Piloto Brasil, Fase A offline, **modo retrato**.
- **Aprovado:** as 13 construções nas seis faixas, as curvas v0.2 e a economia v0.3 (`game/data/mundo_componentes_v0.3.json`, 15 prédios).
- **Feito na 1.6 (M8, falta o aparelho):**
  - Cidade 3D de 80 lotes em retrato em `tools/arte3d/cidade.tscn`, com arrastar e pinça nos limites.
  - Fusão de malhas, LOD e selos 2D.
  - Banco da cidade e Centro tecnológico nas seis faixas.
  - Prefeitura no lugar do Quartel-general.
  - Contagens em `game/docs/logs/cidade3d/`.
- **Pendente do dono:**
  - Avaliar a arte do Banco e do Centro tecnológico.
  - Dar o OK (ou não) para o APK de teste da cidade e medir com o roteiro.

## Objetivo

0. **Se o dono mandou as medições do aparelho:** registrar no `ESTADO_DO_PROJETO.md` e aplicar os cortes da seção 4 do roteiro, se preciso. Se mandou ajustes de arte do Banco ou do Centro tecnológico, fazer antes do resto.
1. **M3: tela do mapa do Brasil em retrato**, num projeto ou cena de teste separado do jogo instalado:
   - contornos de `game/data/mundo/BR.json`;
   - arrastar e pinça com os limites da seção 3.1 (estado com pelo menos 60% da largura, até duas larguras de tela, caixa do estado mais meia tela);
   - botão do país e botão de voltar ao próprio estado;
   - toque num estado (áreas de toque maiores para DF, SE e AL).
   - Reaproveitar a câmera de `tools/arte3d/cidade.gd`, com o mesmo controle de toque.
2. **Smoke Godot e captura de tela** em 1080 × 2340 (proporção). Teste Python, se houver dado novo.
3. **Registro:** atualizar `ESTADO_DO_PROJETO.md`, escrever `HANDOFF-1.7.md` e `PROMPT-1.8.md`.

## Regras

- Único gasto pago: assinatura Claude.
- Sem push na `main`, deploy, OTA, APK ou workflow sem OK explícito do dono.
- Não alterar o jogo instalado (Valdora 0.4.1 e OTA rev 10). Chaves privadas nunca no repositório.
- Não refazer etapas aprovadas; conferir o registro antes. Poupar contexto.
- Pendências do dono (nome, cor final, atribuição do estado, territórios disputados, pacote do app, nomes dos heróis): perguntar só o que bloquear. A atribuição do estado afeta o M4, não o M3.

## Modelo

- Opus: desenho da câmera e da seleção por toque.
- Sonnet: depois do método fechado, capturas, testes e registro.
