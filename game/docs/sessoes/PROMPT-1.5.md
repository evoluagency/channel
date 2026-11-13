# Valdora 1.5 (Economia v0.3: regiões, impostos, comércio, banco e centro tecnológico)

Responda em português do Brasil, de forma direta. Branch de partida: `claude/zealous-tesla-kfhwld`. Leia antes de agir: `game/docs/ESTADO_DO_PROJETO.md`, `game/docs/sessoes/HANDOFF-1.4.md` (inclusive o adendo), `game/docs/JOGABILIDADE_ECONOMIA_v0.1.md` e `game/docs/SOCIEDADE_ECONOMIA_v0.1.md`, seções 10 a 12.

## Contexto

- **Aprovado na 1.4:** curvas v0.2 (`game/data/mundo_componentes_v0.2.json`; 15 min/dia chega ao nível 20 no dia 29 e ao 30 no dia 62; o passe do pagante médio chega ao 30 no dia 30). Também aprovados: Prefeitura, moeda do sistema com banco em cada cidade, ajuda do movimento e presidente que só nomeia governadores.
- **Decisões novas do dono:**
  - Banco é prédio próprio.
  - Impostos estadual e federal só na venda, definidos por governador e presidente.
  - O sistema mede a capacidade de pagamento das cidades e avisa, sem impedir.
  - O caos permite derrubar o presidente.
  - Comércio entre estados e cidades, com margem de lucro de quem vende.
  - O servidor não reinicia: depois da temporada vem a disputa entre países, com troca de tecnologias e migração paga.
  - Siglas e números de movimento livres.
- **Recomendações à espera do OK do dono** (seção 12 de `SOCIEDADE_ECONOMIA`):
  - Banco sem cobrança.
  - Fila extra de obra e de pesquisa no passe.
  - Centro tecnológico como 15º prédio.
  - Especialização +30%/−20% com limite de 2 prédios por recurso fraco.
  - Bônus de recém-chegado.
  - Migração entre países com teto do que se leva.

## Objetivo

1. **Pedir o OK do dono** nas recomendações acima antes de fechar números (só o que bloquear).
2. **Simulação v0.3** (`tools/mundo/simular_economia.py`):
   - Especialização das regiões e comércio entre estados com margem do vendedor (0 a 15%).
   - Impostos estadual e federal no lugar da taxa fixa de 5%.
   - Tesouro com obras públicas (dreno) e teto.
   - Faixas de capacidade de pagamento (verde, amarela, vermelha) e o efeito no ritmo.
   - Centro tecnológico (pesquisa) e bônus de recém-chegado.
   - Mostrar: comércio entre 20% e 35% da produção, regiões a ±3%, moeda estável e metas de ritmo mantidas.
3. **Produção extra do passe:** não pode ser vendida (coerência com "nada pago é transferível").
4. **Regras numéricas** da disputa entre servidores (proposta inicial) e da migração entre países.
5. **Dados e testes:**
   - Regerar `mundo_componentes` (v0.3, com o Centro tecnológico se aprovado).
   - Atualizar `game/tests/test_economia_mundo.py`.
   - Registrar em `ESTADO_DO_PROJETO.md`; escrever `HANDOFF-1.5.md`.
   - A sessão seguinte é a 1.6 (Cidade 3D): `PROMPT-1.6.md` já está escrito; ajustar se algo mudar.

## Regras

- Único gasto pago: assinatura Claude. Sem push na `main`, deploy, publicação de OTA ou workflow sem OK explícito do dono.
- Não alterar o jogo instalado (Valdora 0.4.1 e OTA rev 10). Backend e regras antes de visual.
- Não refazer etapas aprovadas; conferir o registro antes. Poupar contexto.

## Modelo

**Opus** para toda a sessão: são regras de economia e de poder com efeito umas nas outras. O Sonnet só se a sessão terminar com tarefa mecânica (regerar tabelas e textos).
