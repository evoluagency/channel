# Valdora 1.3 (Mapa do Brasil e estados em dados)

Responda em português do Brasil, de forma direta. Branch de partida: `claude/zealous-tesla-kfhwld`. Leia antes de agir: `game/docs/ESTADO_DO_PROJETO.md`, `game/docs/sessoes/HANDOFF-1.2.md`, `game/docs/DESENHO_MUNDO_v0.1.md` (seções 3, 4, 8 e a tabela dos 27 estados), `game/docs/COMPONENTES_NIVEIS_v0.1.md` e `game/data/mundo_componentes_v0.1.json`.

## Contexto (decidido pelo dono até 13/11/2026)

- Jogo moderno de base e estratégia com mapa real; nome provisório "MUNDO"; o prefixo "Valdora" segue só nos títulos de sessão. Piloto Brasil (27 estados), Fase A offline antes de qualquer servidor.
- **Aprovados:** desenho do mundo (v0.1), 13 construções com níveis 1 a 30, Central de energia, ritmo de semanas até o nível 30, visual das 13 construções em seis faixas e o `GUIA_DE_ARTE_v0.1.md`, e os marcos M8 a M13 (desempenho, OTA só de conteúdo, Supabase, Play Store).
- Recomendação registrada: seguir no Godot 4.7.2.

## Objetivo

Fechar os marcos **M1** (Brasil gerado a partir do dado aberto) e **M2** (perfis dos 27 estados e fórmula de lotes), com testes. É trabalho de dados: nenhuma tela nova e nenhuma mudança no jogo instalado.

## Trabalho

1. **Fonte.** Natural Earth, divisões administrativas nível 1, domínio público. Usar a base 1:50m (que já traz o Brasil com 27 unidades) e conferir se a 1:10m vale a pena para o contorno do litoral. Baixar só pelo GitHub (`nvkelso/natural-earth-vector`), guardar ao lado a nota de licença e o SHA-256 do arquivo de origem, e não versionar a fonte bruta se for grande (só o script que baixa e confere).
2. **Script** `tools/mundo/gerar_pais.py` (Python puro, sem dependência paga; bibliotecas abertas só se necessário, com versão fixa). Ele:
   - lê o GeoJSON;
   - simplifica os contornos (Douglas-Peucker), com a tolerância documentada;
   - calcula a área (km², projeção de área igual), o centroide, o litoral (sim/não e extensão aproximada) e os vizinhos (fronteira compartilhada);
   - grava `game/data/mundo/BR.json` compacto e determinístico (mesma entrada, mesmo arquivo).
3. **Perfis dos 27 estados** em `game/data/mundo/BR_perfis.json`: sigla, nome, região, área oficial aproximada (IBGE) ao lado da calculada, lotes pela fórmula da seção 4, bioma dominante, vocação fictícia e recursos. Bioma e vocação seguem a tabela já proposta no desenho; o que mudar vai para a lista de decisões do dono.
4. **Fórmula de lotes** (`round(clamp(40 + 32.9 × log10(área/5760), 40, 120))`): conferir faixa, ordem e distribuição; simular as compensações de tamanho da seção 4 (produção por lote, transporte, tempo de obra) com uma tabela dos 27 e dizer se algum estado fica claramente melhor. Ajuste só com justificativa numérica.
5. **Testes** `game/tests/test_mundo_brasil.py` (entra no `tools/run_valdora_tests.sh`):
   - 27 unidades com siglas únicas;
   - área calculada dentro de ±5% da oficial;
   - vizinhos simétricos e conhecidos (por exemplo DF só com GO; SP com MG, RJ, PR e MS);
   - litoral correto (17 estados costeiros);
   - lotes entre 40 e 120 e monotônicos pela área;
   - nenhum campo faltando;
   - tamanho do arquivo dentro da meta (até 1 MB);
   - determinismo (gerar duas vezes dá o mesmo SHA-256).
6. **Imagem de conferência** (uma folha só): contornos simplificados dos 27 estados com sigla e número de lotes, gerada pelo script ou pelo Godot, para o dono comparar com o mapa real.
7. **Atualizar** `ESTADO_DO_PROJETO.md` (M1 e M2), a tabela de estados do desenho se algo mudar, e escrever `game/docs/sessoes/HANDOFF-1.3.md` e o `PROMPT-1.4.md`.

## Regras

- Único gasto pago: assinatura Claude. Dados só de fonte aberta (domínio público ou licença equivalente), com a licença guardada ao lado.
- Não alterar o jogo instalado (Valdora 0.4.1 e OTA rev 10). Nada de push na `main`, deploy, publicação de OTA ou workflow sem OK explícito do dono.
- Chaves privadas nunca entram no repositório.
- Godot 4.7.2 oficial (`cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`), se precisar renderizar; `xvfb-run` com `--rendering-driver opengl3`.
- Não refazer etapas aprovadas; conferir o registro antes.
- Poupar contexto: olhar uma imagem de cada vez e preferir folhas de contato.
- Territórios disputados e atribuição do estado continuam pendências do dono: não decidir por ele; registrar a proposta.

## Pendências do dono (perguntar só o que bloquear)

Nome do jogo (Terravia, Atlaris, Nexora, Vantara, Orbena ou Kardia), direção de cor final, atribuição do estado (escolha livre recomendada), territórios disputados como zona neutra, pacote do app, nomes dos heróis.

## Próximas sessões previstas

1.4 (Jogabilidade, ciclo diário e chat), 1.5 (Cidade 3D no Godot com os componentes e fusão de malhas, marco M8), depois M3 (tela do mapa).

## Modelo

Opus para decidir a forma do arquivo de dados, a tolerância de simplificação e qualquer ajuste da fórmula. Sonnet pode gerar os arquivos e escrever os testes depois que o formato estiver fechado; avisar o dono quando valer trocar.
