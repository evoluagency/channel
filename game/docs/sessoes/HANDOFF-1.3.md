# Valdora 1.3 — Passagem de bastão

Sessão: "Valdora 1.3 (Mapa do Brasil e estados em dados)", 13/11/2026.
Branch: `claude/zealous-tesla-kfhwld`. Registro único: `game/docs/ESTADO_DO_PROJETO.md`. Próxima sessão prevista: **1.4 (Jogabilidade, ciclo diário e chat)**.

## Feito

1. **M1:** `tools/mundo/gerar_pais.py` gera `game/data/mundo/BR.json` (formato `mundo-pais/1`, 241 KB) do Natural Earth 1:10m. Escolhida a 1:10m em vez da 1:50m (litoral e divisas mais finos, mundo todo, vértices idênticos nas divisas). Simplificação por arco com tolerância proporcional ao tamanho do estado (0,001 × raiz da área, ajustada ao modo retrato com zoom) e refino automático contra cruzamentos.
2. **M2 (aguarda decisões do dono):** `tools/mundo/gerar_perfis.py` gera `game/data/mundo/BR_perfis.json` (`mundo-perfis/1`).
3. **Simulação** das compensações de tamanho: `tools/mundo/simular_lotes.py`.
4. **Folha de conferência:** `game/docs/imagens/mundo/BR_conferencia.png` (enviada ao dono antes de fechar os perfis).
5. **Testes:** `game/tests/test_mundo_brasil.py` 23/23, no `tools/run_valdora_tests.sh`.
6. Documento da sessão: `game/docs/MUNDO_BRASIL_DADOS_v0.1.md` (formato, tolerância, simulação, tabela dos 27, decisões). Tabela do desenho atualizada (BA 106, PE 81, MT com Amazônia dominante).

## Decisão do dono recebida nesta sessão

Jogo em **modo retrato**, com arrastar, pinça, zoom de afastar limitado, botão do país e toque num estado para ver as bases dos outros jogadores (`DESENHO_MUNDO_v0.1.md`, seção 3.1). Também decidido: **servidor = país, estado com muitos jogadores, DF como capital** disputada pela presidência (`DESENHO_MUNDO_v0.1.md`, decisão 10 e seção 4.1). Propostas pendentes: base de 80 lotes igual para todos, 2.000 bases por servidor, DF sem bases. Depois do OK, `gerar_perfis.py` ganha o campo de vagas e o teste correspondente (trabalho para o Sonnet).

## Decisões do dono abertas nesta sessão

Seção 7 do `MUNDO_BRASIL_DADOS_v0.1.md`: (1) compensação só por densidade, `(80/lotes)^0,75` na produção e no poder; (2) dois recursos fortes por estado, +5% cada; (3) MT com Amazônia dominante; (4) aceitar a área menor do Acre na geometria; (5) DF sem divisa com MG; (6) ilhas oceânicas fora do piloto. E o OK da folha de conferência.

## Verificação

- `python3 -I game/tests/test_mundo_brasil.py`: 23/23, inclusive regenerar duas vezes e comparar o SHA-256 com o arquivo versionado (a fonte precisa estar em `tools/mundo/.cache/`; sem ela essa checagem aparece como PULADA).
- `tools/run_valdora_tests.sh --py`: 7/7. Smokes Godot não rodados: o jogo não mudou.
- Nada publicado: sem push na `main`, deploy, OTA ou workflow.

## Pendências e riscos

- Limitações da fonte (Acre −6,4% de área, lagoas do RS fora, Noronha atribuída ao RN): registradas em `tools/mundo/FONTE.md`; lotes usam a área oficial.
- O modelo de simulação é só de tempo (recursos não travam). Refazer quando houver economia completa (M4 a M6).
- Pendências do dono, inalteradas: nome do jogo, cor final, atribuição do estado, territórios disputados, pacote do app, nomes dos heróis.

## Retomar

```bash
git checkout claude/zealous-tesla-kfhwld && git pull
python3 -I tools/mundo/gerar_pais.py        # baixa a fonte (40 MB) uma vez e confere o SHA-256
python3 -I tools/mundo/gerar_perfis.py
python3 -I game/tests/test_mundo_brasil.py
python3 -I tools/mundo/simular_lotes.py      # tabelas da simulação
```

Modelo: formato e tolerância fechados. Ajustes de perfis e regerar arquivos podem ficar com o Sonnet; mudar a fórmula de lotes ou as compensações pede o Opus.
