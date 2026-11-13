# Valdora 1.4 — Passagem de bastão

Sessão: "Valdora 1.4 (Jogabilidade, ciclo diário e chat)", 13/11/2026.
Branch: `claude/zealous-tesla-kfhwld`. Registro único: `game/docs/ESTADO_DO_PROJETO.md`. Próxima sessão prevista: **1.5 (Economia v0.3)**, depois **1.6 (Cidade 3D, M8)**.

## Feito

1. **Simulação de ritmo e economia:** `tools/mundo/simular_economia.py`. É determinística, simula 5 regiões × 4 perfis (5, 15 e 30 min por dia e pagante com passe) e roda em cerca de 2 s. `--calibrar-tempo` refaz a busca da curva (cerca de 20 s).
2. **Curvas v0.2 aprovadas:** `game/data/mundo_componentes_v0.2.json`, gerado por `tools/mundo/gerar_componentes_v02.py` (determinístico). Tem 14 prédios: a Prefeitura no lugar do QG e o Banco da cidade como prédio novo.
3. **Documento:** `game/docs/JOGABILIDADE_ECONOMIA_v0.1.md` com progressão, árvore de desbloqueio, economia, banco, empréstimo, ajuda do movimento, passe, poder, ciclo diário, NPC e chat.
4. **Registros:** decisões nos três documentos de desenho (decisão 13 em `DESENHO_MUNDO`, seção 10 em `SOCIEDADE_ECONOMIA`, nota no topo de `COMPONENTES_NIVEIS`).
5. **Testes:** `game/tests/test_economia_mundo.py` 22/22 (dados, metas de ritmo, regiões, moeda, determinismo), no `tools/run_valdora_tests.sh`.

## Decisões do dono nesta sessão

- Ritmo aprovado. A meta "nível 30 em cerca de 30 dias" vale para o **pagante médio**. Salto do início rápido suavizado.
- Sem "QG": o prédio principal é a **Prefeitura**, e o nível dela é o nível da cidade.
- A **moeda é do próprio sistema**, e cada cidade tem o seu banco.
- Desbloqueio progressivo, com um prédio dependendo do outro. A economia gira em torno da produção.
- Movimento com sigla de até 4 letras e número de 10 a 99. Cidades do mesmo movimento se ajudam, com uma métrica.
- O presidente só nomeia governadores para os cargos do país e tem 4 secretários. Governadores podem ser oposição.

## Números principais

| Perfil | Nível 15 | Nível 20 | Nível 30 |
|---|---|---|---|
| 5 min/dia | dia 16 | dia 35 | depois do 66 |
| 15 min/dia | dia 13 | dia 29 | dia 62 |
| 30 min/dia | dia 12 | dia 26 | dia 56 |
| Passe (pagante médio) | dia 7 | dia 15 | dia 30 |

- **Moeda:** fontes e drenos andam juntos e a moeda guardada fica abaixo de 0,6 dia de produção. O preço fica preso na faixa de ±15%.
- **Regiões:** ficam a ±1% em poder e produção.

## Verificação

- `tools/run_valdora_tests.sh --py`: 8/8 (inclui `test_economia_mundo` 22/22 e `test_componentes_mundo` 12/12 na v0.1). Smokes Godot não rodados: o jogo não mudou.
- Nada publicado: sem push na `main`, deploy, OTA ou workflow.

## Pendências e riscos

- **Fica para o dono confirmar ou revisar:** as regras das seções 4 a 12 do documento novo (números de eleição, guerra civil, Conselho, ajuda, NPC, chat). São proposta sobre as decisões dele.
- **Proposto sem resposta:** Banco como 14º prédio (exige arte nas seis faixas). A alternativa é ser função da Prefeitura.
- Renomear "Quartel-general" para "Prefeitura" no texto dos documentos antigos e no selo da arte. O modelo 3D serve.
- **Limite da simulação:** o mercado fica no piso da faixa, porque sobra recurso e na Fase A o sistema é quase o único comprador. O comportamento do mercado entre jogadores reais só se mede no M10.
- **Limite da simulação:** a produção de referência é a fórmula fixa 560 × 1,094^n (n ≥ 7). Recalibrar a curva com `--calibrar-tempo` muda T_MAX e T_K; depois disso, rodar o gerador e o teste de novo.
- **Pendências antigas do dono:** nome do jogo, cor final, atribuição do estado, territórios disputados, pacote do app, nomes dos heróis.

## Retomar

```bash
git checkout claude/zealous-tesla-kfhwld && git pull
python3 -I tools/mundo/simular_economia.py          # tabelas
python3 -I tools/mundo/gerar_componentes_v02.py      # regera o JSON v0.2
python3 -I game/tests/test_economia_mundo.py
tools/run_valdora_tests.sh --py
```

Modelo: as regras de poder e economia estão fechadas na forma. Regerar tabelas e ajustar textos pode ficar com o Sonnet; mudar metas, curvas ou regras de poder pede o Opus.

## Adendo: impostos, comércio e crítica do projeto (13/11/2026)

Decisões do dono sobre impostos e comércio: `SOCIEDADE_ECONOMIA_v0.1.md`, seção 11. Pontos abertos levantados na revisão crítica (para a próxima sessão de regras):

1. **O que acontece no fim da temporada?** A cidade continua, e só a política reinicia? Hoje o nível 30 sem pagar vem no dia 62, ou seja, na segunda temporada.
2. **Regiões fortes e comércio:** com bônus de +10%, toda cidade produz os 4 recursos e o comércio fica pequeno. Imposto sobre venda só pesa se o comércio for grande; para isso a especialização precisa ser mais forte.
3. **Passe e moeda:** produção extra do passe vendida no mercado vira moeda transferível, o que contradiz "nada transferível".
4. **Política e pagamento:** pagantes chegam ao nível 15 no dia 7 e dominam governo e guerra civil.
5. **Política real:** números de 10 a 99 e siglas de 4 letras coincidem com partidos reais (13, 22, 45, PT, PL).
6. **Escopo da Fase A:** a parte social (movimentos, eleição, Conselho, chat) feita com NPC é grande e parcialmente descartável; validar antes uma fatia jogável (cidade, produção, mercado com o sistema e um estado).
7. **Tesouro:** destino do imposto arrecadado (obras com bônus, que funcionam como dreno, e teto de saldo do tesouro).

## Fechamento (13/11/2026)

O dono decidiu: Banco como prédio próprio; servidor sem reinício, com disputa entre países, troca de tecnologias e migração paga; siglas e números livres (o ponto 5 acima deixa de valer). Recomendações registradas em `SOCIEDADE_ECONOMIA_v0.1.md`, seção 12. Próxima sessão: `PROMPT-1.5.md` (economia v0.3, Opus); a Cidade 3D passou para `PROMPT-1.6.md`.
