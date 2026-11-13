#!/usr/bin/env python3
"""Simula ritmo da temporada e economia da Fase A (sessão 1.4).

Pergunta: com as curvas propostas (tempo, custo, produção), o jogador que não paga chega ao
QG 20 por volta do dia 30 e ao 30 por volta do dia 60, e o pagante ao 30 por volta do dia 30?
A moeda guarda o valor (fontes e drenos equilibrados)? Alguma região fica claramente melhor?

Modelo (determinístico, sem sorteio):
- População: 5 regiões x 4 perfis (5, 15 e 30 min por dia, pagante), pesada pelas vagas de
  BR_perfis.json e pela fatia de cada perfil. Cada agente representa os jogadores do seu par.
- Sessões em horários fixos; produção offline acumula até 8 h; 2 filas de obra; obra de até
  5 min termina na hora. Fila A: QG (e os pré-requisitos dele); fila B: pré-requisitos, novos
  prédios de produção, Alojamento e melhorias pela melhor razão ganho/custo. 20% do tempo da
  fila B vai para os prédios secundários (Radar, Entreposto, Via, Parque, Água, Heliponto).
- Custo de cada obra em quatro recursos (receita por faixa de nível); produção com bônus de
  região; manutenção de energia; tropas consomem alimentos e metal.
- Moeda: missões, baús e combate contra NPC (fontes); vendas no mercado; investimento para
  acelerar obra (até 50%), taxas de mercado, estadual e do banco, juros, migração e perdas do
  colchão (drenos). Mercado com preço livre numa faixa de ±15% do preço de referência; fora
  da faixa o jogo compra ou vende (âncora), o que fecha a moeda contra os recursos.
- Pagante: itens de aceleração pagos cortam 50% de toda obra e pacotes cobrem a falta de
  recurso. Nada disso é transferível.

Uso: python3 -I tools/mundo/simular_economia.py [--md] [--json SAIDA] [--dias 60]
"""
from __future__ import annotations

import argparse
import json
import math
import os

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.dirname(os.path.dirname(AQUI))
PERFIS_BR = os.path.join(RAIZ, "game", "data", "mundo", "BR_perfis.json")

# ---------------------------------------------------------------- parâmetros (proposta 0.2)
RES = ("alimentos", "materiais", "metal", "energia")
PRECO_REF = {"alimentos": 1.0, "materiais": 1.0, "metal": 1.5, "energia": 2.0}
PROD_BASE = {"alimentos": 60.0, "materiais": 60.0, "metal": 40.0, "energia": 30.0}  # 60 moedas/h cada
CRESC_PROD = 1.12
DESBLOQ_PROD = {"alimentos": 1, "materiais": 1, "metal": 2, "energia": 3}
OFFLINE_H = 8.0
FILAS = 2
GRATIS_S = 300  # obra de até 5 min termina na hora

# Tempo-base da obra do QG para chegar ao nível n (horas), âncoras interpoladas em log.
T_QG_ANCORAS = [(2, 1 / 60), (4, 6 / 60), (6, 0.5), (8, 2.0), (10, 6.0)]
T_MAX, T_K = 82.0, 2.0  # horas; achados por calibrar_tempo() (--calibrar-tempo refaz a busca)
FATOR_TEMPO = {"hq": 1.0, "bas": 0.3, "alo": 0.1, "prod": 0.03}
FATOR_CUSTO = {"hq": 1.0, "bas": 0.4, "alo": 0.1, "prod": 0.04}
SECUNDARIOS = 0.20  # fração da fila B
ALFA_CUSTO = 0.30   # custo do QG(n) = ALFA x produção de referência/h no QG n x tempo-base (h)
MANUT_ENERGIA = 0.4  # por prédio e hora, por nível acima do 10 (em unidades de energia)
TROPAS = 0.15        # fração do valor produzido que vai para tropas (alimentos 60%, metal 40%)

# Moeda
MISSOES = {"p5": 0.05, "p15": 0.08, "p30": 0.11, "pag": 0.08}  # x valor diário de referência
BAU_LOGIN = 0.01   # por login, até 3 por dia
KAPPA = 1.0        # moedas por hora poupada = KAPPA x produção de referência/h (até 25% do tempo)
KAPPA_FUNDO = 2.0  # multiplicador de 25% a 50%
INVEST_MAX = 0.5
PAGO_CORTE = 0.67  # itens de aceleração pagos (pagante)
TAXA_MERCADO = 0.05
TAXA_ESTADUAL = 0.015  # governador NPC (faixa 0 a 3%)
BANCO_ENTRADA = BANCO_SAIDA = 0.02
BANCO_REND_SEMANA = 0.01
BANCO_TETO_DIAS = 7.0   # rendimento só até 7 dias de produção de referência
POUPANCA_DIAS = 0.5     # quanto o jogador guarda no banco (dias de produção de referência)
COLCHAO_PERDA = 0.20    # um ataque vencido leva 20% do colchão
ATAQUE_CADA_DIAS = 7    # ataque NPC vencido a cada 7 dias (moeda no colchão)
FAIXA_PRECO = 0.15
ELAST_PRECO = 0.3
VENDA_COTA = 0.20       # Fase A: o banco/NPC compra até 20% do valor produzido por sessão
OBRAS_PUB_LIMIAR = 1.0  # moeda acima de 1 dia de produção sem obra para acelerar vai para obras públicas
MIGRA_DIA, MIGRA_FRACAO, MIGRA_CUSTO_DIAS = 20, 0.10, 0.5
EMPRESTIMO = {"perfil": ("p30",), "limite_dias": 2.0, "prazo": 7,
              "juros_semana": [(900, 0.02), (700, 0.03), (500, 0.05)]}

PERFIS = {  # (hora, minutos) das sessões; fatia dos jogadores
    "p5": {"sessoes": [(8, 2.5), (21, 2.5)], "fatia": 0.30},
    "p15": {"sessoes": [(8, 5), (13, 5), (21, 5)], "fatia": 0.45},
    "p30": {"sessoes": [(8, 6), (11, 6), (14, 6), (18, 6), (22, 6)], "fatia": 0.20},
    "pag": {"sessoes": [(8, 5), (13, 5), (21, 5)], "fatia": 0.05},
}
NOME_PERFIL = {"p5": "5 min/dia", "p15": "15 min/dia", "p30": "30 min/dia", "pag": "pagante (15 min)"}
REGIOES = {
    "Norte": {"metal": 10, "energia": 10},
    "Nordeste": {"energia": 10, "alimentos": 10},
    "Centro-Oeste": {"alimentos": 10, "metal": 10},
    "Sudeste": {"materiais": 10, "metal": 5, "energia": 5},
    "Sul": {"alimentos": 7, "materiais": 7, "energia": 6},
}


def t_qg_h(n: int) -> float:
    """Até o nível 10: âncoras fixas (início rápido). Depois: curva crescente que satura em T_MAX."""
    if n <= 1:
        return 0.0
    if n <= 10:
        for (a, ta), (b, tb) in zip(T_QG_ANCORAS, T_QG_ANCORAS[1:]):
            if a <= n <= b:
                return math.exp(math.log(ta) + (math.log(tb) - math.log(ta)) * (n - a) / (b - a))
    t10 = T_QG_ANCORAS[-1][1]
    return t10 + (T_MAX - t10) * (1 - math.exp(-(n - 10) / T_K))


def max_prod(q: int) -> int:
    return 2 + q // 10


def max_alo(q: int) -> int:
    return 1 + q // 8


def receita(n: int) -> dict:
    if n < 5:
        return {"materiais": 0.7, "alimentos": 0.3}
    if n < 10:
        return {"materiais": 0.45, "metal": 0.30, "alimentos": 0.25}
    return {"materiais": 0.30, "metal": 0.25, "energia": 0.25, "alimentos": 0.20}


# Produção de referência por hora no QG n (valor em moedas). Calibrada por ponto fixo (calibrar()).
YREF = [240.0 * CRESC_PROD ** (n - 1) for n in range(32)]


def custo(tipo: str, n: int) -> dict:
    """Custo em unidades de cada recurso para levar um prédio do tipo ao nível n."""
    v = ALFA_CUSTO * YREF[n] * max(t_qg_h(n), 1 / 60) * FATOR_CUSTO[tipo]
    if n == 1:
        v = max(v, 30.0)
    return {r: v * f / PRECO_REF[r] for r, f in receita(n).items()}


def tempo_h(tipo: str, n: int) -> float:
    return t_qg_h(n) * FATOR_TEMPO[tipo] if n > 1 else (30 / 3600 if tipo != "hq" else 0)


# ---------------------------------------------------------------- agente
class Agente:
    def __init__(self, regiao: str, perfil: str, peso: float):
        self.regiao, self.perfil, self.peso = regiao, perfil, peso
        self.bonus = {r: REGIOES[regiao].get(r, 0) / 100 for r in RES}
        self.sessoes = PERFIS[perfil]["sessoes"]
        self.qg = 1
        self.prod = {"alimentos": [1], "materiais": [1], "metal": [], "energia": []}
        self.bas = 0
        self.alo = [1]
        self.estoque = {r: 300.0 for r in RES}
        self.colchao = 0.0
        self.banco = 0.0
        self.divida = 0.0
        self.divida_venc = None
        self.nota = 500
        self.ocupado = []  # [fim_h, tipo, chave, base_h, poupado_h]
        self.ultimo = 0.0
        self.tropas = 0.0
        self.dia_qg = {1: 0.0}
        self.fluxo = {}
        self.espera_recurso = 0.0
        self.pago_h = 0.0
        self.pago_rec = 0.0
        self.apoio = 0.0
        self.corte_soma = self.corte_base = 0.0

    # ---- utilidades
    def f(self, chave, v):
        self.fluxo[chave] = self.fluxo.get(chave, 0.0) + v

    def taxa_prod(self) -> dict:
        t = {r: sum(PROD_BASE[r] * CRESC_PROD ** (n - 1) for n in self.prod[r]) * (1 + self.bonus[r]) for r in RES}
        return t

    def manut(self) -> float:
        niveis = [self.qg, self.bas] + self.alo + [n for r in RES for n in self.prod[r]]
        return sum(MANUT_ENERGIA * (n - 10) for n in niveis if n > 10)

    def valor(self, d: dict, preco) -> float:
        return sum(d.get(r, 0) * preco[r] for r in RES)

    def ref_h(self) -> float:
        return YREF[self.qg]

    def poder(self) -> float:
        niveis = [self.qg, self.bas] + self.alo + [n for r in RES for n in self.prod[r]]
        return sum(40 * n ** 1.55 for n in niveis if n > 0) + self.tropas / 20

    # ---- obra
    def em_obra(self, tipo, chave=None):
        return any(o[1] == tipo and o[2] == chave for o in self.ocupado)

    def nivel(self, tipo, chave):
        if tipo == "hq":
            return self.qg
        if tipo == "bas":
            return self.bas
        if tipo == "alo":
            return self.alo[chave]
        r, i = chave
        return self.prod[r][i]

    def concluir(self, o, agora):
        _, tipo, chave, _, _ = o
        if tipo == "hq":
            self.corte_soma += o[4]
            self.corte_base += o[3]
            self.qg += 1
            self.dia_qg[self.qg] = agora / 24
        elif tipo == "bas":
            self.bas += 1
        elif tipo == "alo":
            if chave >= len(self.alo):
                self.alo.append(1)
            else:
                self.alo[chave] += 1
        else:
            r, i = chave
            if i >= len(self.prod[r]):
                self.prod[r].append(1)
            else:
                self.prod[r][i] += 1

    def candidatos(self, fila_a: bool, preco):
        """Lista de (tipo, chave, nivel_alvo) em ordem de prioridade."""
        q = self.qg
        out = []
        pre = []
        if q < 30 and not self.em_obra("hq"):
            u0 = self.prod["materiais"][0]
            if u0 < q and not self.em_obra("prod", ("materiais", 0)):
                pre.append(("prod", ("materiais", 0), u0 + 1))
            if q + 1 >= 11 and self.bas < q and not self.em_obra("bas"):
                pre.append(("bas", None, self.bas + 1))
        if fila_a:
            if q < 30 and not self.em_obra("hq") and not pre:
                out.append(("hq", None, q + 1))
            return out + pre
        out += pre
        if q >= 10 and self.bas < q and not self.em_obra("bas") and not pre:
            out.append(("bas", None, self.bas + 1))
        for r in RES:
            if q >= DESBLOQ_PROD[r] and len(self.prod[r]) < max_prod(q) and not self.em_obra("prod", (r, len(self.prod[r]))):
                out.append(("prod", (r, len(self.prod[r])), 1))
        if len(self.alo) < max_alo(q) and not self.em_obra("alo", len(self.alo)):
            out.append(("alo", len(self.alo), 1))
        melh = []
        for r in RES:
            for i, n in enumerate(self.prod[r]):
                if n < q and not self.em_obra("prod", (r, i)):
                    ganho = PROD_BASE[r] * preco[r] * CRESC_PROD ** (n - 1) * 0.12 * (1 + self.bonus[r])
                    c = self.valor(custo("prod", n + 1), PRECO_REF)
                    melh.append((-ganho / c, r, i, n))
        melh.sort()
        out += [("prod", (r, i), n + 1) for _, r, i, n in melh]
        for i, n in enumerate(self.alo):
            if n < q - 3 and not self.em_obra("alo", i):
                out.append(("alo", i, n + 1))
        return out

    def comprar_falta(self, c: dict, preco, mercado) -> bool:
        falta = {r: max(0.0, c.get(r, 0) - self.estoque[r]) for r in RES}
        v = self.valor(falta, preco)
        if v <= 0:
            return True
        if self.perfil == "pag":
            for r in RES:
                self.estoque[r] += falta[r]
            self.pago_rec += v
            return True
        if v * (1 + TAXA_MERCADO) <= self.colchao * 0.6:
            for r in RES:
                if falta[r] > 0:
                    self.estoque[r] += falta[r]
                    mercado["compra"][r] += falta[r] * self.peso
            self.colchao -= v
            self.f("compra_mercado", -v)
            return True
        return False

    def _iniciar(self, tipo, chave, n, agora, preco, mercado) -> bool:
        c = custo(tipo, n)
        if not self.comprar_falta(c, preco, mercado):
            return False
        for r in RES:
            self.estoque[r] -= c.get(r, 0)
        base = tempo_h(tipo, n)
        if tipo != "hq":
            base /= (1 - SECUNDARIOS)
        if self.perfil == "pag":
            self.pago_h += base * PAGO_CORTE
            base *= 1 - PAGO_CORTE
        fim = agora + (0 if base * 3600 <= GRATIS_S else base)
        self.ocupado.append([fim, tipo, chave, base, 0.0])
        return True

    def iniciar_obras(self, agora, preco, mercado):
        # fila A: QG ou o pré-requisito dele; espera o recurso em vez de fazer outra coisa
        if len(self.ocupado) < FILAS and not any(o[1] == "hq" for o in self.ocupado):
            ca = self.candidatos(True, preco)
            if ca:
                if not self._iniciar(*ca[0], agora, preco, mercado):
                    self.espera_recurso += 1
        while len(self.ocupado) < FILAS:
            cb = self.candidatos(False, preco)
            if not any(self._iniciar(*c, agora, preco, mercado) for c in cb[:4]):
                break
            if len(self.ocupado) >= FILAS:
                break

    def investir(self, agora):
        for o in self.ocupado:
            if o[1] != "hq":
                continue
            fim, _, _, base, poup = o
            resta = fim - agora
            limite = INVEST_MAX * base - poup
            h = 0.0
            while limite > 1e-6 and resta > 1e-6:
                k = KAPPA * (1 if poup + h < 0.25 * base else KAPPA_FUNDO) * self.ref_h()
                passo = min(limite, resta, (0.25 * base - poup - h) if poup + h < 0.25 * base else limite)
                passo = max(passo, 1e-6)
                disp = self.colchao - self.divida * 0  # tudo que está no colchão
                if disp <= 0:
                    break
                ph = min(passo, disp / k)
                self.colchao -= ph * k
                self.f("investimento", -ph * k)
                h += ph
                limite -= ph
                resta -= ph
                if ph < passo:
                    break
            o[0] -= h
            o[4] += h

    def sessao(self, agora, dur_h, preco, mercado, primeira_do_dia, dia):
        # 1. produção desde a última coleta (até 8 h) e manutenção
        dt = min(agora - self.ultimo, OFFLINE_H)
        tx = self.taxa_prod()
        bruto = {r: tx[r] * dt for r in RES}
        bruto["energia"] -= self.manut() * dt
        for r in RES:
            self.estoque[r] += bruto[r]
        vprod = self.valor({r: tx[r] * dt for r in RES}, PRECO_REF)
        self.f("producao_valor", vprod)
        self.ultimo = agora
        # 2. tropas
        orc = TROPAS * vprod
        a = min(self.estoque["alimentos"], orc * 0.5 / PRECO_REF["alimentos"])
        m = min(self.estoque["metal"], orc * 0.5 / PRECO_REF["metal"]) if self.qg >= 5 else 0
        self.estoque["alimentos"] -= a
        self.estoque["metal"] -= m
        self.tropas += a * PRECO_REF["alimentos"] + m * PRECO_REF["metal"]
        # 3. moeda: missões e baús
        ref_d = 24 * self.ref_h()
        if primeira_do_dia:
            g = MISSOES[self.perfil] * ref_d
            self.colchao += g
            self.f("missoes", g)
        if self.logins_hoje < 3:
            self.logins_hoje += 1
            g = BAU_LOGIN * ref_d
            self.colchao += g
            self.f("baus", g)
        # 4. empréstimo vencido / quitação
        if self.divida > 0:
            pag = min(self.divida, self.colchao)
            self.colchao -= pag
            self.f("emprestimo_pagamento", -pag)
            self.divida -= pag
            if self.divida <= 1e-6:
                self.divida = 0.0
                self.nota = min(1000, self.nota + 50 if dia <= self.divida_venc else self.nota)
            elif dia > self.divida_venc:
                self.nota = max(0, self.nota - 100)
        # 5. obras: concluir e iniciar (dentro da sessão as obras curtas encadeiam)
        fim_sessao = agora + dur_h
        t = agora
        while True:
            self.ocupado.sort()
            while self.ocupado and self.ocupado[0][0] <= t + 1e-9:
                o = self.ocupado.pop(0)
                self.concluir(o, o[0])
            self.iniciar_obras(t, preco, mercado)
            self.investir(t)
            self.ocupado.sort()
            prox = [o[0] for o in self.ocupado if o[0] <= fim_sessao]
            if not prox:
                break
            t = max(t, min(prox))
        # 6. vender sobra (acima de 2 obras à frente) para financiar investimento
        prox_c = {r: 0.0 for r in RES}
        q1 = min(self.qg + 1, 30)
        for tipo, chave, n in ([("hq", None, q1)] + self.candidatos(False, preco)[:3]):
            for r, v in custo(tipo, n).items():
                prox_c[r] += v
        cota = VENDA_COTA * vprod
        for r in RES:
            sobra = min(self.estoque[r] - 1.5 * prox_c[r], cota / preco[r])
            if sobra > 0:
                cota -= sobra * preco[r]
                bruto_v = sobra * preco[r]
                liq = bruto_v * (1 - TAXA_MERCADO - TAXA_ESTADUAL)
                self.estoque[r] -= sobra
                self.colchao += liq
                mercado["venda"][r] += sobra * self.peso
                self.f("vendas_liquidas", liq)
                self.f("taxa_mercado", -bruto_v * TAXA_MERCADO)
                self.f("taxa_estadual", -bruto_v * TAXA_ESTADUAL)
        self.investir(agora)
        # 7. empréstimo para investir (perfil tomador, nota >= 500, sem dívida)
        if self.perfil in EMPRESTIMO["perfil"] and self.divida == 0 and self.nota >= 500 and self.qg >= 8:
            if any(o[1] == "hq" and o[4] < INVEST_MAX * o[3] - 1e-6 for o in self.ocupado):
                lim = EMPRESTIMO["limite_dias"] * ref_d * self.nota / 1000
                j = next(x for n, x in EMPRESTIMO["juros_semana"] if self.nota >= n)
                self.colchao += lim
                self.divida = lim * (1 + j)
                self.divida_venc = dia + EMPRESTIMO["prazo"]
                self.f("emprestimo_saldo", lim)
                self.investir(agora)
        # 8. sem obra para acelerar: o excesso vai para obras públicas do estado (apoio ao movimento)
        pode = any(o[1] == "hq" and o[4] < INVEST_MAX * o[3] - 1e-6 for o in self.ocupado) or self.qg < 30
        lim_c = OBRAS_PUB_LIMIAR * ref_d
        if self.colchao > lim_c and (not pode or self.qg >= 30):
            d = (self.colchao - lim_c) * 0.5
            self.colchao -= d
            self.apoio += d
            self.f("obras_publicas", -d)
        # 9. poupança no banco
        alvo = POUPANCA_DIAS * ref_d
        if self.banco < alvo and self.colchao > 0 and primeira_do_dia:
            dep = min(self.colchao, alvo - self.banco)
            self.colchao -= dep
            self.banco += dep * (1 - BANCO_ENTRADA)
            self.f("taxa_banco", -dep * BANCO_ENTRADA)


def carregar_regioes():
    try:
        est = json.load(open(PERFIS_BR, encoding="utf-8"))["estados"]
        vag = {}
        for e in est:
            vag[e["regiao"]] = vag.get(e["regiao"], 0) + e["vagas_base"]
        return vag
    except OSError:
        return {r: 400 for r in REGIOES}


def simular(dias=60, regioes=None, fixar_yref=None):
    vag = carregar_regioes()
    regioes = regioes or list(REGIOES)
    ags = [Agente(rg, p, vag[rg] * PERFIS[p]["fatia"]) for rg in regioes for p in PERFIS]
    preco = dict(PRECO_REF)
    hist = []
    for dia in range(dias):
        mercado = {"compra": {r: 0.0 for r in RES}, "venda": {r: 0.0 for r in RES}}
        for a in ags:
            a.logins_hoje = 0
            a.fluxo = {}
            for k, (h, mi) in enumerate(a.sessoes):
                a.sessao(dia * 24 + h, mi / 60, preco, mercado, k == 0, dia)
            # rendimento do banco (diário, 1%/semana, com teto) e ataque ao colchão
            teto = BANCO_TETO_DIAS * 24 * a.ref_h()
            rend = min(a.banco, teto) * BANCO_REND_SEMANA / 7
            a.banco += rend
            a.f("rendimento_banco", rend)
            if dia % ATAQUE_CADA_DIAS == ATAQUE_CADA_DIAS - 1:
                perda = a.colchao * COLCHAO_PERDA
                a.colchao -= perda
                a.f("perda_colchao", -perda)
            if dia == MIGRA_DIA:
                c = MIGRA_CUSTO_DIAS * 24 * a.ref_h() * MIGRA_FRACAO
                c = min(c, a.colchao)
                a.colchao -= c
                a.f("migracao", -c)
            a.hist = getattr(a, "hist", [])
            a.hist.append({"dia": dia + 1, "qg": a.qg, "moeda": a.colchao + a.banco - a.divida,
                           "prod_h": a.valor(a.taxa_prod(), PRECO_REF), "poder": a.poder(), **a.fluxo})
        # preço: desequilíbrio do dia move o preço dentro da faixa; o resto o jogo absorve
        ancora = 0.0
        for r in RES:
            c, v = mercado["compra"][r], mercado["venda"][r]
            novo = preco[r] * ((c + 1) / (v + 1)) ** ELAST_PRECO
            lo, hi = PRECO_REF[r] * (1 - FAIXA_PRECO), PRECO_REF[r] * (1 + FAIXA_PRECO)
            preco[r] = min(hi, max(lo, novo))
            ancora += (v - c) * preco[r]  # >0: o jogo comprou o excesso (emitiu moeda)
        hist.append({"dia": dia + 1, "preco": dict(preco), "ancora": ancora,
                     "compra": mercado["compra"], "venda": mercado["venda"]})
    return ags, hist


# Meta do jogador de 15 min por dia, sem pagar: dia em que chega ao nível.
META_P15 = {2: 0.02, 4: 0.05, 6: 0.15, 8: 0.5, 10: 1.5, 12: 5.0, 14: 12.0, 16: 18.0, 20: 30.0, 25: 45.0, 30: 60.0}


def calibrar_tempo():
    """Busca T_MAX e T_K para o jogador de 15 min chegar ao QG 20 no dia 30 e ao 30 no dia 60."""
    global T_MAX, T_K
    melhor = None
    for tk in (2.0, 3.0, 4.0, 5.0, 6.0):
        for tmax in range(64, 125, 6):
            T_MAX, T_K = float(tmax), tk
            calibrar(2)
            ags, _ = simular(dias=80, regioes=["Sudeste"])
            a = next(x for x in ags if x.perfil == "p15")
            d20, d30 = a.dia_qg.get(20, 99), a.dia_qg.get(30, 99)
            erro = (d20 - META_P15[20]) ** 2 + ((d30 - META_P15[30]) / 2) ** 2
            if melhor is None or erro < melhor[0]:
                melhor = (erro, tmax, tk, d20, d30)
    _, T_MAX, T_K = melhor[0], float(melhor[1]), melhor[2]
    calibrar(3)
    return melhor


def calibrar(iter_=4):
    """Ponto fixo: a produção de referência do QG n é a do jogador de 15 min sem bônus."""
    global YREF
    for _ in range(iter_):
        ags, _ = simular(dias=90, regioes=["Sudeste"])
        a = next(x for x in ags if x.perfil == "p15")
        prod_q = {}
        for h in a.hist:
            prod_q.setdefault(h["qg"], h["prod_h"])
        ult = 240.0
        novo = []
        for n in range(32):
            if n in prod_q:
                ult = prod_q[n] / 1.0
            elif n > max(prod_q):
                ult *= CRESC_PROD
            novo.append(ult)
        YREF = [0.5 * x + 0.5 * y for x, y in zip(YREF, novo)]


def br(x, nd=0):
    s = f"{x:,.{nd}f}".replace(",", "X").replace(".", ",").replace("X", ".")
    return s


def relatorio(ags, hist, dias, md=True):
    out = []
    p = out.append
    vag = carregar_regioes()
    # 1. ritmo
    p("## 1. Dia em que cada perfil chega ao nível do QG (média das regiões)\n")
    p("| Perfil | QG 10 | QG 15 | QG 20 | QG 25 | QG 30 | QG no dia 15 | QG no dia 30 | QG no dia 60 | Corte médio por investimento |")
    p("|---|---|---|---|---|---|---|---|---|---|")
    for pf in PERFIS:
        grupo = [a for a in ags if a.perfil == pf]
        cel = []
        for n in (10, 15, 20, 25, 30):
            ds = [a.dia_qg.get(n) for a in grupo]
            cel.append("—" if None in ds else br(sum(ds) / len(ds), 1))
        for d in (15, 30, 60):
            vals = [a.hist[min(d, dias) - 1]["qg"] for a in grupo]
            cel.append(br(sum(vals) / len(vals), 1))
        cel.append(br(100 * sum(a.corte_soma for a in grupo) / max(1e-9, sum(a.corte_base for a in grupo)), 0) + "%")
        p(f"| {NOME_PERFIL[pf]} | " + " | ".join(cel) + " |")
    # 2. curvas
    p("\n## 2. Curvas propostas (QG; os outros prédios usam fatores)\n")
    p("| Nível | Tempo-base do QG | Custo do QG (valor em moedas) | Produção de referência/h | Preço de 1 h de aceleração |")
    p("|---|---|---|---|---|")
    for n in (2, 5, 8, 10, 12, 15, 18, 20, 22, 25, 28, 30):
        t = t_qg_h(n)
        ts = f"{br(t * 60)} min" if t < 1 else (f"{br(t, 1)} h" if t < 24 else f"{br(t / 24, 1)} d")
        p(f"| {n} | {ts} | {br(sum(v * PRECO_REF[r] for r, v in custo('hq', n).items()))} | {br(YREF[n])} | {br(KAPPA * YREF[n])} |")
    # 3. moeda por semana (jogador de 15 min, média)
    p("\n## 3. Moeda por dia, média ponderada de todos os jogadores, por semana (em % da produção)\n")
    chaves = ["missoes", "baus", "vendas_liquidas", "rendimento_banco", "emprestimo_saldo",
              "investimento", "compra_mercado", "taxa_mercado", "taxa_estadual", "taxa_banco",
              "emprestimo_pagamento", "perda_colchao", "migracao", "obras_publicas"]
    sem = list(range(0, dias, 7))
    p("| Fluxo | " + " | ".join(f"sem {i // 7 + 1}" for i in sem) + " |")
    p("|---|" + "---|" * len(sem))
    tot_peso = sum(a.peso for a in ags)
    rot = {"missoes": "fonte: missões diárias", "baus": "fonte: baús", "vendas_liquidas": "fonte: vendas (líquidas)",
           "rendimento_banco": "fonte: rendimento do banco", "emprestimo_saldo": "fonte: empréstimos concedidos",
           "investimento": "dreno: aceleração de obra", "compra_mercado": "dreno: compras no mercado",
           "taxa_mercado": "dreno: taxa do mercado (5%)", "taxa_estadual": "dreno: taxa estadual (1,5%)",
           "taxa_banco": "dreno: taxa do banco (2%)", "emprestimo_pagamento": "dreno: empréstimos pagos (com juros)",
           "perda_colchao": "dreno: colchão saqueado", "migracao": "dreno: migração",
           "obras_publicas": "dreno: obras públicas (apoio)", "producao_valor": "produção média por jogador/dia (moedas)"}
    for k in chaves + ["_fontes", "_drenos", "producao_valor"]:
        linha = []
        if k in ("_fontes", "_drenos"):
            for i in sem:
                rng = range(i, min(i + 7, dias))
                pv = sum(a.peso * a.hist[d].get("producao_valor", 0) for a in ags for d in rng)
                v = sum(a.peso * x for a in ags for d in rng for c, x in a.hist[d].items()
                        if c in chaves and ((x > 0) == (k == "_fontes")))
                linha.append(br(100 * v / pv, 1))
            p(f"| **{'total de fontes' if k == '_fontes' else 'total de drenos'}** | " + " | ".join(linha) + " |")
            continue
        for i in sem:
            rng = range(i, min(i + 7, dias))
            v = sum(a.peso * a.hist[d].get(k, 0) for a in ags for d in rng)
            pv = sum(a.peso * a.hist[d].get("producao_valor", 0) for a in ags for d in rng)
            linha.append(br(100 * v / pv, 1) if k != "producao_valor" else br(v / tot_peso / len(rng)))
        p(f"| {rot.get(k, k)} | " + " | ".join(linha) + " |")
    # 4. estoque de moeda / produção diária
    p("\n## 4. Moeda guardada por jogador em dias de produção (M/Y) e âncora do mercado\n")
    p("| Dia | M/Y médio | Índice de preços (ref = 1,00) | Emissão líquida da âncora (% do valor vendido) |")
    p("|---|---|---|---|")
    for d in (1, 7, 14, 21, 30, 45, 60):
        if d > dias:
            continue
        m = sum(a.peso * a.hist[d - 1]["moeda"] for a in ags)
        y = sum(a.peso * a.hist[d - 1]["prod_h"] * 24 for a in ags)
        h = hist[d - 1]
        idx = math.exp(sum(math.log(h["preco"][r] / PRECO_REF[r]) for r in RES) / 4)
        vend = sum(h["venda"][r] * h["preco"][r] for r in RES) or 1
        p(f"| {d} | {br(m / y, 2)} | {br(idx, 3)} | {br(100 * h['ancora'] / vend, 1)} |")
    # 5. regiões
    p("\n## 5. Regiões: jogador de 15 min (relativo à média das regiões)\n")
    p("| Região | QG dia 15 | QG dia 30 | Poder dia 30 | Produção/h dia 30 | Moeda acumulada no dia 30 (líquida) |")
    p("|---|---|---|---|---|---|")
    g = [a for a in ags if a.perfil == "p15"]
    med = {k: sum(a.hist[29][k] for a in g) / len(g) for k in ("poder", "prod_h")}
    for a in g:
        p(f"| {a.regiao} | {a.hist[14]['qg']} | {a.hist[29]['qg']} | {br(a.hist[29]['poder'] / med['poder'], 3)} | "
          f"{br(a.hist[29]['prod_h'] / med['prod_h'], 3)} | {br(a.hist[29]['moeda'])} |")
    # 5b. pior caso de preços (online): recursos de construção no teto, os outros no piso
    p("\n**Pior caso de preço** (bônus da região em % da produção total, com produção igual nos 4 recursos):\n")
    cen = {"preços de referência": {r: 1.0 for r in RES},
           "materiais e metal no teto, alimentos e energia no piso": {"materiais": 1 + FAIXA_PRECO, "metal": 1 + FAIXA_PRECO, "alimentos": 1 - FAIXA_PRECO, "energia": 1 - FAIXA_PRECO},
           "alimentos e energia no teto, materiais e metal no piso": {"materiais": 1 - FAIXA_PRECO, "metal": 1 - FAIXA_PRECO, "alimentos": 1 + FAIXA_PRECO, "energia": 1 + FAIXA_PRECO}}
    p("| Cenário | " + " | ".join(REGIOES) + " | maior − menor |")
    p("|---|" + "---|" * (len(REGIOES) + 1))
    for nome, fat in cen.items():
        tot = sum(fat.values())
        v = {rg: 100 * sum(b / 100 * fat[r] for r, b in REGIOES[rg].items()) / tot for rg in REGIOES}
        p(f"| {nome} | " + " | ".join(br(x, 2) + "%" for x in v.values()) + f" | {br(max(v.values()) - min(v.values()), 2)} p.p. |")
    # 6. pagante
    pg = [a for a in ags if a.perfil == "pag"]
    p("\n## 6. Pagante (média): o que compra em 30 dias\n")
    p(f"- Horas de aceleração paga: {br(sum(a.pago_h for a in pg) / len(pg))} h; recursos comprados: "
      f"{br(sum(a.pago_rec for a in pg) / len(pg))} moedas de valor.")
    esp = {pf: sum(a.espera_recurso for a in ags if a.perfil == pf) / 5 for pf in PERFIS}
    p(f"- Sessões em que faltou recurso para iniciar obra: " + ", ".join(f"{k} {br(v)}" for k, v in esp.items()))
    return "\n".join(out)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dias", type=int, default=60)
    ap.add_argument("--json")
    ap.add_argument("--calibrar-tempo", action="store_true", help="refaz a busca de T_MAX e T_K (cerca de 20 s)")
    a = ap.parse_args()
    if a.calibrar_tempo:
        print("calibrar_tempo:", calibrar_tempo())
    calibrar(3)
    ags, hist = simular(a.dias)
    print(relatorio(ags, hist, a.dias))
    if a.json:
        with open(a.json, "w", encoding="utf-8") as fh:
            json.dump({"yref": YREF, "dia_qg": {f"{x.regiao}/{x.perfil}": x.dia_qg for x in ags}}, fh,
                      ensure_ascii=False, indent=1)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
