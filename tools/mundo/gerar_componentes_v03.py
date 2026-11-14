#!/usr/bin/env python3
"""Gera game/data/mundo_componentes_v0.3.json (sessão 1.5).

Parte da v0.2 (curvas aprovadas, sem mudança) e acrescenta o que o dono aprovou na 1.5:
Centro tecnológico (15º prédio) com a árvore de pesquisa, especialização das regiões,
mercado com margem, impostos estadual e federal com faixas de capacidade de pagamento,
tesouro, passe, bônus de recém-chegado, migração entre países e a proposta da disputa
entre servidores. Os números vêm de tools/mundo/simular_economia.py. Determinístico.

Uso: python3 -I tools/mundo/gerar_componentes_v03.py [--saida CAMINHO]
"""
from __future__ import annotations

import argparse
import copy
import json
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.dirname(os.path.dirname(AQUI))
sys.path.insert(0, AQUI)
import gerar_componentes_v02 as g2  # noqa: E402
import simular_economia as se  # noqa: E402

SAIDA = os.path.join(RAIZ, "game", "data", "mundo_componentes_v0.3.json")

TEC = {
    "id": "tec", "nome": "Centro tecnológico", "origem_valdora": "—", "tipo": "tec", "base": 0,
    "unidade": "níveis de pesquisa liberados",
    "funcao": "Pesquisa em cinco linhas (produção, obras, economia, comércio e defesa). Base das tecnologias trocadas entre países.",
    "beneficio": "Cada 3 níveis do Centro liberam 1 nível em cada linha (até 10 na temporada; 11 a 20 depois da Prefeitura 30). 1 fila de pesquisa grátis; a 2ª vem no passe.",
    "visual_faixas": ["Contêiner com antena e bancada", "Laboratório pré-fabricado com painel solar",
                      "Instituto de concreto com cúpula de observação", "Torre de vidro com laboratórios aparentes",
                      "Campus com servidores, drones e telas holográficas", "Centro de elite com anel de pesquisa iluminado"],
}
FRACAO_TEC = (0.10, 0.10)
DESBLOQUEIO_TEC = (se.TEC_DESBLOQUEIO, ("ent", 4))

LINHAS = {
    "producao": {"nome": "Produção", "efeito_por_nivel": "+1% na produção de todos os recursos"},
    "obras": {"nome": "Obras", "efeito_por_nivel": "−1% no tempo de toda obra"},
    "economia": {"nome": "Economia", "efeito_por_nivel": "+5% na capacidade protegida do Banco e −0,1 ponto nos juros do empréstimo"},
    "comercio": {"nome": "Comércio", "efeito_por_nivel": "+1 ponto na cota de venda ao sistema e +1 oferta simultânea no mercado"},
    "defesa": {"nome": "Defesa", "efeito_por_nivel": "+2% na defesa da cidade e do cofre"},
}


def r1(x: float) -> float:
    return round(x, 1) if x < 100 else float(round(x))


def predio_tec() -> dict:
    c = copy.deepcopy(TEC)
    ft, fc = FRACAO_TEC
    nv, req = DESBLOQUEIO_TEC
    c.update(fracao_tempo=ft, fracao_custo=fc, desbloqueio_prefeitura=nv, requisito={"id": req[0], "nivel": req[1]})
    niveis = []
    for n in range(1, 31):
        base = se.custo("hq", n)
        vb = sum(v * fc * se.PRECO_REF[r] for r, v in base.items())
        k = max(1.0, 10.0 / vb) if vb > 0 else 1.0
        custo = {r: r1(v * fc * k) for r, v in base.items()}
        niveis.append({"nivel": n, "poder": round(40 * n ** 1.55, 1), "custo": custo,
                       "custo_valor": r1(sum(custo[r] * se.PRECO_REF[r] for r in custo)),
                       "tempo_s": int(round(se.tempo_h("hq", n) * ft * 3600)), "valor": n // 3})
    for a, b in zip(niveis, niveis[1:]):
        if b["custo_valor"] < a["custo_valor"]:
            b["custo"], b["custo_valor"] = dict(a["custo"]), a["custo_valor"]
    c["niveis"] = niveis
    return c


def pesquisa() -> dict:
    niveis = []
    for k in range(1, se.PESQ_NIVEIS + 1):
        c = {r: r1(v) for r, v in se.custo_pesq(k).items()}
        niveis.append({"nivel": k, "centro_minimo": 3 * k, "custo": c,
                       "custo_valor": r1(sum(c[r] * se.PRECO_REF[r] for r in c)),
                       "tempo_s": int(round(se.tempo_pesq_h(k) * 3600))})
    return {"linhas": LINHAS, "niveis_temporada": se.PESQ_NIVEIS,
            "regra": "nível k de uma linha: 15% do tempo e do custo da obra da Prefeitura no nível 3k (no mínimo 10); exige Centro no nível 3k",
            "filas": {"gratis": 1, "passe": se.PASSE_FILA_PESQ},
            "depois_da_prefeitura_30": "níveis 11 a 20 de cada linha (tecnologias avançadas): 1 a 2 dias cada; são as tecnologias trocáveis entre países",
            "niveis": niveis}


def gerar() -> dict:
    d = g2.gerar()
    d["schema"] = "mundo.componentes.v0.3"
    d["status"] = "curvas da v0.2 sem mudança; economia v0.3 aprovada pelo dono em 13/11/2026 (sessão 1.5); arte do Banco e do Centro pendente"
    d["construcoes"].append(predio_tec())
    d["pesquisa"] = pesquisa()
    d["regioes"] = {
        "forte": se.FORTE, "fraco": se.FRACO, "limite_predios_fraco": se.LIMITE_FRACO,
        "vagas_do_fraco": "as vagas de prédio que o recurso fraco perde vão para os recursos fortes (mesmo total de prédios)",
        "fortes": {rg: list(v) for rg, v in se.FORTES.items()},
    }
    d["mercado"] = {
        "margem_vendedor": [0.0, 0.15], "margem_npc": se.MARGEM,
        "faixa_preco": se.FAIXA_PRECO, "ancora": "o sistema vende no teto (+15%) quando falta oferta e compra no piso (−15%) a oferta com 24 h ou mais, até 20% da produção diária do vendedor",
        "compra": "pro rata entre as ofertas de todo o país, lote mais antigo primeiro",
    }
    d["impostos"] = {
        "base": "só na venda (a jogadores e ao sistema), abatido de quem vende",
        "estadual": {"define": "governador", "faixa": [0.0, 0.30], "npc": se.IMPOSTO["estadual"]},
        "federal": {"define": "presidente com o Conselho", "faixa": [0.0, 0.30], "npc": se.IMPOSTO["federal"]},
        "faixas_capacidade": [{"faixa": n, "imposto_somado_ate": lim if lim <= 1 else None} for lim, n in se.FAIXAS_IMPOSTO],
        "aviso": "o sistema mede a carga de cada cidade (impostos pagos ÷ produção, 7 dias) e avisa governante e cidades ao entrar na amarela e na vermelha; não impede",
    }
    d["tesouro"] = {"gasto_diario": round(se.TESOURO_GASTO_DIA, 4), "teto_dias_arrecadacao": se.TESOURO_TETO_DIAS,
                    "obras_publicas": "bônus de produção = 0,5 × gasto em obras (7 dias) ÷ produção (7 dias), até 3% do estado e 3% do país"}
    d["passe"] = {"corte_obras": se.PASSE_CORTE, "producao_extra": se.PASSE_PROD, "fila_obra_extra": se.PASSE_FILA,
                  "fila_pesquisa_extra": se.PASSE_FILA_PESQ,
                  "producao_extra_vendavel": False, "regra": "a produção a mais do passe só paga obras e pesquisa do próprio jogador; não se vende, não se doa"}
    d["recem_chegado"] = {"corte_obras": se.RECEM_CORTE, "vale_ate": "Prefeitura 3 ou mais níveis abaixo da mediana do servidor",
                          "corte_maximo_somado": se.CORTE_MAX}
    d["valor_cidade"] = "soma do custo, a preço de referência, de todos os prédios e níveis de pesquisa da cidade"
    d["migracao_paises"] = {
        "status": "aprovada pelo dono na sessão 1.5; sem dinheiro real",
        "abre": f"dia {se.DIA_ABRE_MIGRACAO} (15 dias depois do fim da primeira disputa entre países); depois, fora da janela da disputa",
        "frequencia": "1 migração por cidade por temporada",
        "requisitos": ["sem cargo", "sem dívida no banco", "sem guerra em andamento", "cidade com 14 dias ou mais", "sai do movimento"],
        "reserva_minima": {"fracao_valor_cidade": se.RESERVA_MIGRACAO, "onde": "conta de migração no Banco, protegida de saque",
                           "destino": "gasta na mudança: vai para o tesouro federal do país de destino (taxa de entrada)"},
        "leva": {"predios_e_pesquisa": True, "moeda_teto_dias_producao": 2, "recursos_teto_dias_producao": 1},
        "excedente": "o que passa do teto fica no tesouro do estado de origem",
        "teto_destino": "o país de destino recebe até 5% da sua população por temporada, respeitando as vagas de cada estado",
        "recem_chegado": "não vale para cidade migrada",
    }
    d["venda_cidade"] = {
        "status": "aprovada pelo dono na sessão 1.5: só em moeda do jogo; dinheiro real proibido",
        "abre": f"dia {se.DIA_ABRE_MIGRACAO}, com a cidade tendo 60 dias ou mais; fora da janela da disputa",
        "requisitos_vendedor": ["sem cargo", "sem dívida no banco", "sem guerra em andamento"],
        "cartorio": "anúncio público por 72 h antes de fechar (tempo para o dono perceber roubo de conta)",
        "comprador": "conta sem cidade naquele país; assume a cidade como está; nunca duas cidades por conta no mesmo país",
        "preco": {"moeda_do_jogo": True, "piso_fracao_valor_cidade": se.VENDA_PISO},
        "taxa": {"fracao": se.VENDA_TAXA, "em": "moeda do jogo, sai da economia"},
        "nao_transfere": "passe e itens comprados ficam com a conta de quem vendeu",
    }
    d["abandono"] = {"protecao_apos_dias_inativo": 14,
                     "libera_apos_dias_inativo": 30,
                     "destino": "moeda e recursos vão metade para o movimento e metade para o tesouro do estado; o lote fica livre para recém-chegado"}
    d["disputa_paises"] = {
        "status": "proposta inicial (sessão 1.5); calendário aprovado pelo dono",
        "inicio": "logo depois da temporada 1; o servidor não reinicia",
        "calendario": {"disputa": "dias 1 a 15 de cada temporada a partir da 2ª (a primeira: dias 31 a 45)",
                       "politica_interna": "dias 16 a 30 de cada temporada",
                       "migracao_e_venda": f"a partir do dia {se.DIA_ABRE_MIGRACAO}, fora da janela da disputa"},
        "grupos": "4 países por grupo, pela soma do poder das 200 maiores cidades",
        "pontos": {"missoes_nacionais": 0.40, "territorio_de_fronteira": 0.40, "tecnologia": 0.20},
        "territorio": "zonas neutras entre os países do grupo; 3 janelas de 2 h por semana da disputa; só cidades com Prefeitura 15 ou mais",
        "premio_temporada_seguinte": {"1": 0.05, "2": 0.03, "3": 0.01, "4": 0.0},
        "perdas": "nunca cidade nem nível; só recursos do cofre, como na guerra civil",
        "tecnologias": {
            "tecnologia_nacional": "linha com nível 11 ou mais pesquisado por 20% ou mais das cidades do país",
            "tratado": "o presidente propõe e o Conselho aprova (14 votos); cada país cede uma linha",
            "efeito": "quem recebe pesquisa aquela linha 50% mais rápido por 1 temporada (não recebe níveis prontos)",
            "limite": "até 2 tratados por país por temporada",
        },
    }
    d["cobranca"] = "sem dinheiro real por enquanto; forma de cobrança a definir (M13). Transações entre jogadores só em moeda do jogo"
    return d


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--saida", default=SAIDA)
    a = ap.parse_args()
    dados = gerar()
    with open(a.saida, "w", encoding="utf-8") as fh:
        json.dump(dados, fh, ensure_ascii=False, indent=1)
        fh.write("\n")
    print(f"{a.saida}: {len(dados['construcoes'])} construções")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
