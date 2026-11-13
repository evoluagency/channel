# Valdora 1.4 (Jogabilidade, ciclo diário e chat)

Responda em português do Brasil, de forma direta. Branch de partida: `claude/zealous-tesla-kfhwld`. Leia antes de agir: `game/docs/ESTADO_DO_PROJETO.md`, `game/docs/sessoes/HANDOFF-1.3.md`, `game/docs/DESENHO_MUNDO_v0.1.md`, `game/docs/COMPONENTES_NIVEIS_v0.1.md` (seções 1, 2, 7 e 9 do chat) e `game/docs/MUNDO_BRASIL_DADOS_v0.1.md` (seções 5 a 7).

## Contexto

- Jogo moderno de base e estratégia com mapa real; nome provisório "MUNDO". Piloto Brasil, Fase A offline.
- **Modo retrato** (decisão do dono): arrastar, pinça, zoom de afastar limitado, botão do país e toque num estado para ver as bases dos outros jogadores (`DESENHO_MUNDO_v0.1.md`, seção 3.1). Todo ciclo e toda tela pensados para uma mão, em retrato.
- **Servidor = país, estado com muitos jogadores, DF como capital** e presidência por guerra (`DESENHO_MUNDO_v0.1.md`, decisão 10 e seção 4.1). Na Fase A, as outras bases e alianças são NPC.
- Aprovados: desenho do mundo v0.1, 13 construções com níveis 1 a 30, visual e guia de arte, marcos M8 a M13. M1 pronto na 1.3; M2 gerado e dependente das decisões da seção 7 do `MUNDO_BRASIL_DADOS_v0.1.md` (conferir no registro o que o dono decidiu).

## Objetivo

Desenhar, em documento e dados (sem tela nova e sem mudar o jogo instalado), a jogabilidade da Fase A:

1. **Ciclo diário:** o que o jogador faz em 5, 15 e 30 minutos por dia; produção offline (até 8 h), filas de obra (quantas obras simultâneas; a simulação da 1.3 supôs 2), missões diárias e baús.
2. **Economia:** fluxo dos quatro recursos e das moedas por dia, por nível do QG, com as compensações de tamanho decididas; refazer `tools/mundo/simular_lotes.py` com os recursos travando as obras.
3. **NPC:** bases e alianças NPC morando nos estados, governos estaduais e disputa da capital federal contra NPC; como crescem, comerciam e reagem (determinístico, mesma seed).
4. **Chat:** canais (aliança, estado, global, sistema), o que existe offline na Fase A (mensagens de sistema e NPC) e o que fica para o servidor (M10), com moderação.
5. **Testes Python** dos números novos e entrada no `tools/run_valdora_tests.sh`.
6. Atualizar `ESTADO_DO_PROJETO.md`, escrever `HANDOFF-1.4.md` e `PROMPT-1.5.md` (Cidade 3D, M8).

## Regras

- Único gasto pago: assinatura Claude. Sem push na `main`, deploy, publicação de OTA ou workflow sem OK explícito do dono.
- Não alterar o jogo instalado (Valdora 0.4.1 e OTA rev 10). Chaves privadas nunca no repositório.
- Não refazer etapas aprovadas; conferir o registro antes. Poupar contexto.
- Pendências do dono (nome, cor final, atribuição do estado, territórios disputados, pacote do app, nomes dos heróis): perguntar só o que bloquear.

## Modelo

Opus para as regras de economia e o ciclo diário. Sonnet pode escrever os testes e regerar tabelas depois que as regras estiverem fechadas.
