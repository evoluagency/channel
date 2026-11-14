# Handoff 1.5 — Economia v0.3 (13/11/2026)

Branch: `claude/zealous-tesla-kfhwld`. Nada publicado: sem push na `main`, deploy, OTA ou workflow. O jogo instalado (Valdora 0.4.1, OTA rev 10) não mudou.

## Decisões do dono

- Aprovadas as 6 recomendações da seção 12 de `SOCIEDADE_ECONOMIA_v0.1.md`:
  - banco sem cobrança;
  - fila extra de obra e de pesquisa no passe;
  - Centro tecnológico como 15º prédio;
  - especialização +30%/−20% com limite de 2 prédios por recurso fraco;
  - bônus de recém-chegado;
  - migração com teto.
- Depois das tabelas:
  - Nordeste forte em **alimentos e materiais**;
  - fraco continua em −20%;
  - impostos de 0 a 30% cada, com faixas verde até 20%, amarela até 40% e vermelha acima;
  - recém-chegado com obras 50% mais rápidas.
- Registro: `SOCIEDADE_ECONOMIA_v0.1.md`, seção 13.

## Feito

- **`tools/mundo/simular_economia.py` v0.3.** As sessões dos agentes correm intercaladas pela hora. O que entrou:
  - regiões especializadas;
  - mercado entre jogadores pro rata, com margem (as ofertas ficam 24 h antes de o sistema comprar no piso);
  - impostos estadual e federal só na venda;
  - tesouros com obras públicas e teto;
  - Centro tecnológico e pesquisa;
  - produção do passe marcada como não vendável;
  - reserva de moeda para comprar o recurso fraco;
  - bônus de recém-chegado;
  - cenários (`--cenarios`): impostos, margem e recém-chegado.

  As curvas são as da v0.2.
- **`tools/mundo/gerar_componentes_v03.py`** gera `game/data/mundo_componentes_v0.3.json`, com 15 prédios. Contém o Centro tecnológico (abre na Prefeitura 10 com Entreposto 4) e as seções de pesquisa, regiões, mercado, impostos, tesouro, passe, recém-chegado, migração e disputa entre países. A v0.2 continua no repositório, sem mudança.
- **`game/docs/ECONOMIA_v0.3.md`:** regras, migração, proposta da disputa entre países, todas as tabelas da simulação e a leitura.
- **`game/tests/test_economia_mundo.py`:** 35/35. Inclui:
  - os geradores v0.2 e v0.3 são determinísticos e as curvas da v0.2 ficaram iguais;
  - regiões a ±3%;
  - comércio entre 15% e 35%;
  - moeda estável;
  - faixas de imposto;
  - produção do passe não vendida;
  - recém-chegado.
- `tools/run_valdora_tests.sh --py`: 8/8. Os smokes do Godot não rodaram, porque o jogo não mudou.
- `ESTADO_DO_PROJETO.md` atualizado; `PROMPT-1.6.md` ajustado (Centro tecnológico como 15º prédio, com arte pendente).

## Resultados principais

| Medida | v0.3 | Meta |
|---|---|---|
| 15 min/dia: nível 20 / nível 30 | dia 29,6 / 63,6 | perto de 30 / 60 (faixa do teste: 27 a 32 / 55 a 65) |
| Pagante médio: nível 30 | dia 31,0 | metade do tempo |
| Regiões: produção e poder | ±2%; nível 30 com menos de 1 dia de diferença | ±3% |
| Comércio entre jogadores | 18% da produção | 20 a 35% (aceito abaixo) |
| Moeda guardada | abaixo de 0,5 dia de produção | abaixo de 1 dia |
| Imposto NPC (10%) | atrasa 0,4 dia; carga de 3,3% | — |

## Achados

- Sem limite de vagas, a especialização não cria comércio. Com o limite, o NPC precisava preferir subir o prédio forte e comprar o fraco; com a heurística antiga, as regiões travavam.
- O peso das vagas decide a atribuição: Norte e Nordeste têm 61% da população e precisam de oferta de materiais.
- Um `set` de textos tornava a simulação não determinística (aleatorização do hash). Corrigido com uma tupla na ordem de `RES`.
- A 2ª fila de pesquisa do passe quase não acelera: o pagante fica sem recurso antes de ficar sem fila.

## Pendências

- **Confirmar com o dono:** os números da migração e a proposta da disputa entre países (`ECONOMIA_v0.3.md`, seção 3); o preço do item de migração e do passe ficam para o M13.
- **Arte:** Banco e Centro tecnológico nas seis faixas, na sessão 1.6.
- **Limites do modelo:** a margem do vendedor é fixa (não reage à procura); o mercado online só se mede no M10.
- **Pendências antigas do dono:** nome do jogo, cor final, atribuição do estado, territórios disputados, pacote do app, nomes dos heróis.

## Retomar

```bash
git checkout claude/zealous-tesla-kfhwld && git pull
python3 -I tools/mundo/simular_economia.py --cenarios   # tabelas (cerca de 15 s)
python3 -I tools/mundo/gerar_componentes_v03.py          # regera o JSON v0.3
python3 -I game/tests/test_economia_mundo.py
tools/run_valdora_tests.sh --py
```

Próxima sessão: `PROMPT-1.6.md` (Cidade 3D, M8).

Modelo:
- Opus para a arquitetura de desempenho.
- Regerar as tabelas da economia pode ficar com o Sonnet.
- Mudar metas, regiões ou regras de poder pede o Opus.
