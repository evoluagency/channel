# Valdora 1.2 (Visual individual dos componentes)

Responda em português do Brasil, de forma direta. Branch de partida: `claude/zealous-tesla-kfhwld`. Leia antes de agir: `game/docs/ESTADO_DO_PROJETO.md`, `game/docs/sessoes/HANDOFF-1.1.md`, `game/docs/DESENHO_MUNDO_v0.1.md`, `game/docs/COMPONENTES_NIVEIS_v0.1.md`, `game/data/mundo_componentes_v0.1.json` e `docs/DIRECAO_VISUAL.md` (a direção antiga fica só como referência).

## Contexto (decidido pelo dono em 13/11/2026)

- O jogo passa a um cenário moderno, sem zumbis: base e estratégia com mapa-múndi real, estados reais por jogador, alianças e guerra por território. Reskin do mesmo jogo; nome provisório "MUNDO"; o prefixo "Valdora" segue só nos títulos de sessão.
- Piloto Brasil (27 estados), Fase A offline antes de qualquer servidor.
- **Aprovados:** o documento de componentes (13 construções com níveis 1 a 30 e seis faixas visuais), a Central de energia como recurso novo e o ritmo de semanas até o nível 30.
- O dono quer **gráfico 3D estilizado de cores vivas, com animações que prendam a atenção, no nível comercial das referências que enviou** (Last War e jogos parecidos). As referências guiam o estilo; **não se copia arte, personagem, nome nem logotipo**.
- O dono pediu **imagens primeiro, movimento depois**.

## Objetivo

Criar o visual individual de cada componente, uma construção por vez, em todas as faixas de nível, e fechar um guia de arte consolidado.

## Trabalho

1. **Método.** Definir uma forma única e reaproveitável de gerar cada construção por faixa (3D de baixo polígono em Godot, modelado por código ou por kits CC0), com cor, silhueta, iluminação e detalhes de nível parametrizados. Comparar com os protótipos já feitos em `game/docs/imagens/` (cena 3D com modelos CC0 da Kenney, licença CC0) e escolher o que sustenta as seis faixas.
2. **Uma construção de cada vez**, na ordem: Quartel-general, Alojamento, Estufa, Usina, Mineradora, Central de energia, Radar, Base militar, Entreposto, Via, Parque, Estação de água, Heliponto. Para cada uma: folha com as seis faixas (níveis 1, 6, 11, 16, 21 e 26) e a faixa 6 em detalhe, renderizada de verdade no Godot, mais as variações de cor de aliança.
3. **Aprovação por construção.** Mostrar a folha ao dono e só seguir após o OK, para não gastar com o que será refeito.
4. **Guia de arte consolidado** (`game/docs/GUIA_DE_ARTE_v0.1.md`): paleta viva, formas, iluminação, selo de nível, animações de construir e melhorar, e a lista do que ainda precisa de artista (heróis com rosto expressivo).
5. **Atualizar** `ESTADO_DO_PROJETO.md` e escrever `game/docs/sessoes/HANDOFF-1.2.md`.

## Regras

- Único gasto pago: assinatura Claude. Nada de serviço pago novo. Kits de arte só se a licença for CC0 ou equivalente, com a licença guardada ao lado do arquivo.
- Não alterar o jogo instalado (Valdora 0.4.1 e OTA rev 10). Nada de push na `main`, deploy, publicação de OTA ou workflow sem OK explícito do dono.
- Chaves privadas nunca entram no repositório.
- Godot 4.7.2 oficial (`cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`). O dono liberou a execução. Renderização com `xvfb-run` e `--rendering-driver opengl3`; ver `HANDOFF-1.1.md` para o resultado.
- Poupar contexto: renderizar folhas de contato em vez de dezenas de imagens soltas, e olhar uma imagem de cada vez.
- Dizer com franqueza o que não alcança nível comercial. O que exigir arte profissional (rosto de herói, personagem animado) vai para a lista do guia, sem proposta de gasto.
- Fechar as fórmulas e os números em `game/data/mundo_componentes_v0.1.json`; qualquer mudança passa por `game/tests/test_componentes_mundo.py`.

## Pendências do dono

Nome do jogo (Terravia, Atlaris, Nexora, Vantara, Orbena ou Kardia), direção de cor final, atribuição do estado, territórios disputados como zona neutra, pacote do app e nomes dos heróis. Perguntar só o que bloquear o trabalho.

## Próximas sessões previstas

Títulos no padrão "Valdora N.N (tema)": 1.3 (Mapa do Brasil e estados em dados), 1.4 (Jogabilidade, ciclo diário e chat), 1.5 (Cidade 3D no Godot com os componentes).

## Modelo

Opus: o trabalho é de decisão de direção visual e de método. Avisar o dono quando a parte mecânica (renderizar as folhas já definidas) puder passar para Sonnet.
