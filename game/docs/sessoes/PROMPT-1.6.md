# Valdora 1.6 (Cidade 3D, M8)

Responda em português do Brasil, de forma direta. Branch de partida: `claude/zealous-tesla-kfhwld`. Leia antes de agir: `game/docs/ESTADO_DO_PROJETO.md`, `game/docs/sessoes/HANDOFF-1.5.md`, `game/docs/GUIA_DE_ARTE_v0.1.md`, `game/docs/DESENHO_MUNDO_v0.1.md` (seção 3.1 e marco M8), `game/docs/JOGABILIDADE_ECONOMIA_v0.1.md` (seções 3 e 4) e `tools/arte3d/`.

## Contexto

- **Jogo:** moderno, de base e estratégia, com mapa real; nome provisório "MUNDO". Piloto Brasil, Fase A offline, **modo retrato**.
- **Arte e curvas aprovadas:** as 13 construções nas seis faixas, modeladas por código no Godot 4.7.2 (`tools/arte3d/`). Também aprovadas as curvas v0.2 (`game/data/mundo_componentes_v0.2.json`).
- **Mudanças da 1.4:** o Quartel-general virou **Prefeitura** e entrou o **Banco da cidade** (14º prédio, arte pendente).
- **Desempenho medido na 1.2:** de 24 a 210 peças e de 2 mil a 38 mil triângulos por construção. Falta fundir malhas.

## Objetivo (M8)

1. **Cidade 3D em retrato, num projeto de teste separado do jogo instalado:** grade da base de 80 lotes com prédios nas seis faixas, câmera com arrastar e pinça nos limites da seção 3.1.
2. **Malhas fundidas por material e nível de detalhe**, com contagem de chamadas de desenho e triângulos por cena (cidade cheia no nível 30).
3. **Arte do Banco da cidade** nas seis faixas (mesmo kit e guia), se o dono confirmar o 14º prédio. Troca do selo e do texto de Quartel-general para Prefeitura.
4. **Medição:**
   - Local: tempo de quadro no Godot oficial em GL Compatibility.
   - No aparelho: roteiro para o dono medir 30 FPS em Samsung e Xiaomi. Não gerar APK sem OK.
5. **Testes e registro:**
   - Smoke Godot da cena; teste Python das contagens.
   - Atualizar `ESTADO_DO_PROJETO.md`, escrever `HANDOFF-1.6.md` e `PROMPT-1.7.md`.

## Regras

- Único gasto pago: assinatura Claude. Sem push na `main`, deploy, publicação de OTA, APK ou workflow sem OK explícito do dono.
- Não alterar o jogo instalado (Valdora 0.4.1 e OTA rev 10). Chaves privadas nunca no repositório.
- Não refazer etapas aprovadas; conferir o registro antes. Poupar contexto.
- Pendências do dono (nome, cor final, atribuição do estado, territórios disputados, pacote do app, nomes dos heróis, Banco como prédio): perguntar só o que bloquear.

## Modelo

Opus para a arquitetura de desempenho (fusão, nível de detalhe, câmera). Sonnet pode gerar folhas, contagens e testes depois que o método estiver fechado.
