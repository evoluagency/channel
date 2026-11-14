#!/usr/bin/env python3
"""Simula ritmo da temporada e economia do mundo (v0.3, sessão 1.5).

Pergunta: com as curvas aprovadas na v0.2 (tempo, custo, produção), as metas de ritmo se mantêm
depois de especializar as regiões, abrir o comércio entre estados, trocar a taxa fixa por impostos
estadual e federal, criar o tesouro, o Centro tecnológico e o bônus de recém-chegado? O comércio
fica entre 20% e 35% da produção? A moeda guarda o valor? Alguma região fica claramente melhor?

Modelo (determinístico, sem sorteio):
- População: 5 regiões x 4 perfis (5, 15 e 30 min por dia, pagante), pesada pelas vagas de
  BR_perfis.json e pela fatia de cada perfil. Cada agente representa os jogadores do seu par.
  As sessões de todos os agentes correm intercaladas pela hora do dia.
- Produção offline até 8 h; 2 filas de obra (3 com o passe); obra de até 5 min termina na hora.
  Fila A: Prefeitura e pré-requisitos; fila B: o resto pela melhor razão ganho/custo.
- Regiões (v0.3): +30% em 2 recursos fortes e -20% nos 2 fracos; no máximo 2 prédios de cada
  recurso fraco, e as vagas que sobram vão para os recursos fortes (mesmo total de prédios).
- Mercado (v0.3): o vendedor oferece a sobra pelo preço de referência + margem (0 a 15%); quem
  precisa compra das ofertas de todo o país (pro rata). Faltando oferta, o sistema vende no teto
  (+15%); no fim do dia o sistema compra o que sobrou no piso (-15%), até 20% da produção do dia.
  Impostos estadual e federal só na venda, abatidos de quem vende, vão para os tesouros.
- Tesouro (v0.3): gasta 1/7 do saldo por dia em obras públicas (dreno) e tudo o que passa do teto
  (7 dias de arrecadação). As obras dão bônus de produção ao estado (federal: ao país), até 3%.
- Centro tecnológico (v0.3): 15º prédio; pesquisa em 5 linhas (produção, obras, defesa, economia,
  comércio), 1 fila grátis e a 2ª no passe.
- Passe: obras mais rápidas, produção a mais, +1 fila de obra e +1 de pesquisa. A produção a mais
  do passe só serve para as obras do próprio jogador: não entra na venda.
- Moeda: missões, baús e vendas ao sistema (fontes); aceleração, compras ao sistema, impostos,
  taxa do banco, juros, migração e perdas do cofre (drenos). Comércio entre jogadores é transferência.

Uso: python3 -I tools/mundo/simular_economia.py [--dias 66] [--json SAIDA] [--cenarios]
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
T_QG_ANCORAS = [(2, 1 / 60), (4, 6 / 60), (6, 0.5), (8, 2.0)]
T_MAX, T_K = 92.0, 2.0  # horas; achados por calibrar_tempo() (--calibrar-tempo refaz a busca)
FATOR_TEMPO = {"hq": 1.0, "bas": 0.3, "alo": 0.1, "prod": 0.03, "tec": 0.10}
FATOR_CUSTO = {"hq": 1.0, "bas": 0.4, "alo": 0.1, "prod": 0.04, "tec": 0.10}
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
PASSE_CORTE = 0.60  # passe da temporada (pagante médio): obras mais rápidas
PASSE_PROD = 0.75   # passe: produção a mais
PASSE_FILA = 1      # passe: uma fila de obra a mais
AJUDAS_POR_OBRA = 10  # ajudas médias recebidas do movimento por obra
AJUDA_CORTE = 0.01    # cada ajuda corta 1% do tempo-base (mínimo 1 min)
AJUDA_MAX = 20
# v0.3: impostos só na venda, abatidos de quem vende (substituem a taxa de 5% do sistema)
IMPOSTO = {"estadual": 0.05, "federal": 0.05}  # governador e presidente NPC; cada um de 0 a 30% (aprovado na 1.5)
MARGEM = 0.10           # margem de quem vende sobre o preço de referência (0 a 15%)
TESOURO_GASTO_DIA = 1 / 7   # fração do saldo gasta por dia em obras públicas
TESOURO_TETO_DIAS = 7       # teto do saldo: 7 dias de arrecadação média
OBRA_PUB_EFICIENCIA = 0.5   # bônus de produção = 0,5 x gasto em obras (7 dias) / produção (7 dias)
OBRA_PUB_BONUS_MAX = 0.03
# v0.3: especialização das regiões
FORTE, FRACO, LIMITE_FRACO = 0.30, -0.20, 2
FORTES = {"Norte": ("metal", "energia"), "Nordeste": ("alimentos", "materiais"),
          "Centro-Oeste": ("alimentos", "metal"), "Sudeste": ("materiais", "metal"),
          "Sul": ("alimentos", "materiais")}
ESPECIALIZAR = True
TROPAS_COMPRAM = True
# v0.3: Centro tecnológico (15º prédio) e pesquisa
TEC_DESBLOQUEIO = 10        # nível da Prefeitura
LINHAS = ("producao", "obras", "economia", "comercio", "defesa")  # ordem de prioridade do NPC
PESQ_NIVEIS = 10            # níveis por linha na temporada (11 a 20 depois da Prefeitura 30)
PESQ_FRACAO = 0.15          # tempo e custo do nível k = 15% da obra da Prefeitura no nível 3k
PESQ_EFEITO = 0.01          # produção +1% e obras -1% por nível
PESQUISA = True
PASSE_FILA_PESQ = 1
# v0.3: bônus de recém-chegado (obras mais rápidas abaixo da mediana do servidor)
RECEM_CORTE = 0.50
RECEM_MARGEM_NIVEIS = 3     # vale enquanto a Prefeitura estiver 3 ou mais níveis abaixo da mediana
CORTE_MAX = 0.80            # corte de tempo somado (passe, recém-chegado) nunca passa disso
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
NOME_PERFIL = {"p5": "5 min/dia", "p15": "15 min/dia", "p30": "30 min/dia", "pag": "pagante médio (passe, 15 min)"}
REGIOES_V02 = {  # bônus da v0.2 (%), só para comparação (ESPECIALIZAR = False)
    "Norte": {"metal": 10, "energia": 10},
    "Nordeste": {"energia": 10, "alimentos": 10},
    "Centro-Oeste": {"alimentos": 10, "metal": 10},
    "Sudeste": {"materiais": 10, "metal": 5, "energia": 5},
    "Sul": {"alimentos": 7, "materiais": 7, "energia": 6},
}
REGIOES = list(FORTES)


def bonus_regiao(rg: str) -> dict:
    if not ESPECIALIZAR:
        return {r: REGIOES_V02[rg].get(r, 0) / 100 for r in RES}
    return {r: FORTE if r in FORTES[rg] else FRACO for r in RES}


def t_qg_h(n: int) -> float:
    """Tempo-base da obra da Prefeitura (horas). Até o nível 8: âncoras (início rápido).
    Do 9 em diante: o menor entre dobrar a cada nível (2 h no 8) e a curva que satura em T_MAX,
    o que suaviza o fim do início rápido (decisão do dono, sessão 1.4)."""
    if n <= 1:
        return 0.0
    if n <= 8:
        for (a, ta), (b, tb) in zip(T_QG_ANCORAS, T_QG_ANCORAS[1:]):
            if a <= n <= b:
                return math.exp(math.log(ta) + (math.log(tb) - math.log(ta)) * (n - a) / (b - a))
    t8 = T_QG_ANCORAS[-1][1]
    return min(t8 * 2 ** (n - 8), T_MAX * (1 - math.exp(-(n - 8) / T_K)))


def max_prod(q: int) -> int:
    return 2 + q // 10


def max_alo(q: int) -> int:
    return 1 + q // 8


def receita(n: int) -> dict:
    if n < 5:
        return {"materiais": 0.7, "alimentos": 0.3}
    if n < 10:
        return {"materiais": 0.45, "metal": 0.30, "alimentos": 0.25}
    return {"materiais": 0.35, "metal": 0.25, "energia": 0.20, "alimentos": 0.20}


# Produção de referência por hora no nível n da Prefeitura (valor em moedas): 240 até o 6; 560 x 1,094^n depois.
# calibrar() mede de novo, só para diagnóstico.
YREF = [240.0 if n < 7 else 560.0 * 1.094 ** n for n in range(32)]  # ajuste da calibração da sessão 1.4


def custo(tipo: str, n: int) -> dict:
    """Custo em unidades de cada recurso para levar um prédio do tipo ao nível n."""
    v = ALFA_CUSTO * YREF[n] * max(t_qg_h(n), 1 / 60) * FATOR_CUSTO[tipo]
    if n == 1:
        v = max(v, 30.0)
    return {r: v * f / PRECO_REF[r] for r, f in receita(n).items()}


def tempo_h(tipo: str, n: int) -> float:
    return t_qg_h(n) * FATOR_TEMPO[tipo] if n > 1 else (30 / 3600 if tipo != "hq" else 0)


def custo_pesq(k: int) -> dict:
    """Custo do nível k de uma linha: 15% da obra da Prefeitura no nível 3k (no mínimo a 10, onde o Centro abre)."""
    return {r: v * PESQ_FRACAO for r, v in custo("hq", min(30, max(TEC_DESBLOQUEIO, 3 * k))).items()}


def tempo_pesq_h(k: int) -> float:
    return t_qg_h(min(30, max(TEC_DESBLOQUEIO, 3 * k))) * PESQ_FRACAO


# ---------------------------------------------------------------- mercado e tesouros
class Mercado:
    """Ofertas de todo o país, pro rata; o sistema vende no teto e compra no piso (âncora).

    Unidades em `oferta` são do par inteiro (unidades por jogador x peso do agente)."""

    def __init__(self, fixo: bool = False):
        self.fixo = fixo  # mercado maduro (recém-chegado): sempre há oferta de jogador
        self.oferta = {r: {} for r in RES}
        self.tes_est, self.tes_fed = {}, 0.0
        self.novo_dia()

    def novo_dia(self):
        self.d = {"jog": 0.0, "sis_vende": 0.0, "sis_compra": 0.0, "imp_est": {}, "imp_fed": 0.0,
                  "jog_r": {r: 0.0 for r in RES}}

    @staticmethod
    def preco_jog(r):
        return PRECO_REF[r] * (1 + MARGEM)

    @staticmethod
    def teto(r):
        return PRECO_REF[r] * (1 + FAIXA_PRECO)

    @staticmethod
    def piso(r):
        return PRECO_REF[r] * (1 - FAIXA_PRECO)

    def ofertar(self, ag, r, q, agora):
        if q <= 0:
            return
        if self.fixo:  # mercado maduro, visão conservadora: o sistema compra no piso, até a cota
            u = min(q, max(0.0, ag.cota_sis) / self.piso(r))
            if u > 0:
                self._vender(ag, r, u * ag.peso, self.piso(r), "venda_sistema")
                ag.cota_sis -= u * self.piso(r)
            ag.estoque[r] += q - u
            return
        self.oferta[r].setdefault(ag, []).append([agora, q * ag.peso])

    def disponivel(self, r) -> float:
        return sum(u for lotes in self.oferta[r].values() for _, u in lotes)

    def _vender(self, s, r, u_tot, preco, chave):
        """Paga o vendedor s por u_tot unidades (do par) ao preço dado; imposto abatido dele."""
        q = u_tot / s.peso
        bruto = q * preco
        ie, ifd = bruto * IMPOSTO["estadual"], bruto * IMPOSTO["federal"]
        s.colchao += bruto - ie - ifd
        s.f(chave, bruto)
        s.f("imposto_estadual", -ie)
        s.f("imposto_federal", -ifd)
        s.imp_pago += ie + ifd
        self.d["imp_est"][s.regiao] = self.d["imp_est"].get(s.regiao, 0.0) + ie * s.peso
        self.d["imp_fed"] += ifd * s.peso

    def comprar(self, ag, r, q, so_jogadores=False) -> float:
        """Compra q unidades (por jogador) para o agente; devolve o valor pago.
        Pro rata entre os vendedores, lote mais antigo primeiro; o que faltar o sistema vende no teto."""
        if q <= 0:
            return 0.0
        tot = q * ag.peso
        if self.fixo:
            take = tot
        else:
            disp = self.disponivel(r)
            take = min(tot, disp)
            if take > 0:
                frac = take / disp
                for s, lotes in self.oferta[r].items():
                    x = sum(u for _, u in lotes) * frac
                    if x <= 0:
                        continue
                    self._vender(s, r, x, self.preco_jog(r), "venda_jogadores")
                    while x > 1e-12 and lotes:
                        y = min(x, lotes[0][1])
                        lotes[0][1] -= y
                        x -= y
                        if lotes[0][1] <= 1e-12:
                            lotes.pop(0)
        resto = 0.0 if so_jogadores else tot - take
        v_jog = take / ag.peso * self.preco_jog(r)
        v_sis = resto / ag.peso * self.teto(r)
        ag.estoque[r] += (take + resto) / ag.peso
        ag.f("compra_jogadores", -v_jog)
        ag.f("compra_sistema", -v_sis)
        self.d["jog"] += take * self.preco_jog(r)
        self.d["jog_r"][r] += take * self.preco_jog(r)
        self.d["sis_vende"] += resto * self.teto(r)
        return v_jog + v_sis

    def fechar_dia(self, agora):
        """O sistema compra no piso as ofertas com 24 h ou mais, até a cota do vendedor; o resto fica."""
        for r in RES:
            for s, lotes in self.oferta[r].items():
                for lote in lotes:
                    if lote[0] > agora - 24 or s.cota_sis <= 0:
                        continue
                    q = min(lote[1], s.cota_sis / self.piso(r) * s.peso)
                    self._vender(s, r, q, self.piso(r), "venda_sistema")
                    s.cota_sis -= q / s.peso * self.piso(r)
                    self.d["sis_compra"] += q * self.piso(r)
                    lote[1] -= q
                self.oferta[r][s] = [l for l in lotes if l[1] > 1e-9]


# ---------------------------------------------------------------- agente
class Agente:
    def __init__(self, regiao: str, perfil: str, peso: float, recem_mediana=None):
        self.regiao, self.perfil, self.peso = regiao, perfil, peso
        self.bonus = bonus_regiao(regiao)
        self.fracos = tuple(r for r in RES if self.bonus[r] < 0) if ESPECIALIZAR else ()
        self.sessoes = PERFIS[perfil]["sessoes"]
        self.qg = 1
        self.prod = {"alimentos": [1], "materiais": [1], "metal": [], "energia": []}
        self.bas = 0
        self.tec = 0
        self.alo = [1]
        self.estoque = {r: 300.0 for r in RES}
        self.vinc = {r: 0.0 for r in RES}  # parte do estoque que veio do passe (não se vende)
        self.colchao = 0.0
        self.banco = 0.0
        self.divida = 0.0
        self.divida_venc = None
        self.nota = 500
        self.ocupado = []  # [fim_h, tipo, chave, base_h, poupado_h]
        self.pesq = {l: 0 for l in LINHAS}
        self.pesq_ocup = []  # [fim_h, linha]
        self.dia_pesq = {}
        self.ultimo = 0.0
        self.tropas = 0.0
        self.dia_qg = {1: 0.0}
        self.fluxo = {}
        self.espera_recurso = 0.0
        self.pago_h = 0.0
        self.pago_rec = 0.0
        self.apoio = 0.0
        self.ajuda_h = 0.0
        self.recem_h = 0.0
        self.imp_pago = 0.0
        self.reserva = 0.0
        self.cota_sis = 0.0
        self.pub_bonus = 0.0
        self.vendido_passe = 0.0
        self.recem_mediana = recem_mediana
        self.filas = FILAS + (PASSE_FILA if perfil == "pag" else 0)
        self.filas_pesq = 1 + (PASSE_FILA_PESQ if perfil == "pag" else 0)
        self.prod_extra = PASSE_PROD if perfil == "pag" else 0.0
        self.corte_soma = self.corte_base = 0.0
        self.hist = []

    # ---- utilidades
    def f(self, chave, v):
        self.fluxo[chave] = self.fluxo.get(chave, 0.0) + v

    def mult_prod(self, r) -> float:
        return 1 + self.bonus[r] + self.prod_extra + self.pub_bonus + PESQ_EFEITO * self.pesq["producao"]

    def taxa_prod(self) -> dict:
        return {r: sum(PROD_BASE[r] * CRESC_PROD ** (n - 1) for n in self.prod[r]) * self.mult_prod(r) for r in RES}

    def max_tipo(self, r: str, q: int) -> int:
        m = max_prod(q)
        if not ESPECIALIZAR:
            return m
        if r in self.fracos:
            return min(m, LIMITE_FRACO)
        return m + max(0, m - LIMITE_FRACO)

    def gastar(self, r, x):
        self.estoque[r] -= x
        self.vinc[r] = max(0.0, min(self.vinc[r] - x, self.estoque[r]))

    def manut(self) -> float:
        niveis = [self.qg, self.bas, self.tec] + self.alo + [n for r in RES for n in self.prod[r]]
        return sum(MANUT_ENERGIA * (n - 10) for n in niveis if n > 10)

    def valor(self, d: dict, preco) -> float:
        return sum(d.get(r, 0) * preco[r] for r in RES)

    def ref_h(self) -> float:
        return YREF[self.qg]

    def poder(self) -> float:
        niveis = [self.qg, self.bas, self.tec] + self.alo + [n for r in RES for n in self.prod[r]]
        return sum(40 * n ** 1.55 for n in niveis if n > 0) + self.tropas / 20

    def recem_ativo(self) -> bool:
        return self.recem_mediana is not None and self.qg <= self.recem_mediana - RECEM_MARGEM_NIVEIS

    # ---- obra
    def em_obra(self, tipo, chave=None):
        return any(o[1] == tipo and o[2] == chave for o in self.ocupado)

    def concluir(self, o, agora):
        _, tipo, chave, _, _ = o
        if tipo == "hq":
            self.corte_soma += o[4]
            self.corte_base += o[3]
            self.qg += 1
            self.dia_qg[self.qg] = agora / 24
        elif tipo == "bas":
            self.bas += 1
        elif tipo == "tec":
            self.tec += 1
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

    def candidatos(self, fila_a: bool):
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
            if q >= DESBLOQ_PROD[r] and len(self.prod[r]) < self.max_tipo(r, q) and not self.em_obra("prod", (r, len(self.prod[r]))):
                out.append(("prod", (r, len(self.prod[r])), 1))
        if len(self.alo) < max_alo(q) and not self.em_obra("alo", len(self.alo)):
            out.append(("alo", len(self.alo), 1))
        if PESQUISA and q >= TEC_DESBLOQUEIO and self.tec < q - 1 and not self.em_obra("tec"):
            out.append(("tec", None, self.tec + 1))
        melh = []
        prox = custo("hq", min(q + 1, 30))
        # com especialização, o recurso fraco se compra: subir o prédio forte rende mais (1,3 x 0,8)
        falta = {r: 3.0 if self.estoque[r] < 1.5 * prox.get(r, 0) and r not in self.fracos else 1.0 for r in RES}
        for r in RES:
            for i, n in enumerate(self.prod[r]):
                if n < q and not self.em_obra("prod", (r, i)):
                    ganho = PROD_BASE[r] * PRECO_REF[r] * CRESC_PROD ** (n - 1) * 0.12 * (1 + self.bonus[r]) * falta[r]
                    c = self.valor(custo("prod", n + 1), PRECO_REF)
                    melh.append((-ganho / c, r, i, n))
        melh.sort()
        out += [("prod", (r, i), n + 1) for _, r, i, n in melh]
        for i, n in enumerate(self.alo):
            if n < q - 3 and not self.em_obra("alo", i):
                out.append(("alo", i, n + 1))
        return out

    def comprar_falta(self, c: dict, mercado) -> bool:
        falta = {r: max(0.0, c.get(r, 0) - self.estoque[r]) for r in RES}
        est = sum(falta[r] * Mercado.teto(r) for r in RES)
        if est <= 0:
            return True
        if est > self.colchao:
            return False
        for r in RES:
            if falta[r] > 0:
                self.colchao -= mercado.comprar(self, r, falta[r])
        return True

    def comprar_adiantado(self, mercado):
        """Compra das ofertas de jogadores o que vai faltar na próxima obra da Prefeitura."""
        c = custo("hq", min(self.qg + 1, 30))
        for r in self.fracos:
            falta = c.get(r, 0) - self.estoque[r]
            if falta <= 0:
                continue
            q = min(falta, max(0.0, self.colchao) / Mercado.preco_jog(r))
            if not mercado.fixo:
                q = min(q, mercado.disponivel(r) / self.peso)
            if q > 0:
                self.colchao -= mercado.comprar(self, r, q, so_jogadores=True)

    def _iniciar(self, tipo, chave, n, agora, mercado) -> bool:
        c = custo(tipo, n)
        if not self.comprar_falta(c, mercado):
            return False
        for r in RES:
            self.gastar(r, c.get(r, 0))
        base = tempo_h(tipo, n)
        if tipo != "hq":
            base /= (1 - SECUNDARIOS)
        aj = min(AJUDAS_POR_OBRA, AJUDA_MAX)
        corte_aj = min(base * 0.95, max(aj * AJUDA_CORTE * base, aj / 60))
        self.ajuda_h += corte_aj
        base -= corte_aj
        mult = 1 - PESQ_EFEITO * self.pesq["obras"]
        if self.perfil == "pag":
            mult *= 1 - PASSE_CORTE
        if self.recem_ativo():
            mult *= 1 - RECEM_CORTE
            self.recem_h += base * RECEM_CORTE
        mult = max(mult, 1 - CORTE_MAX)
        if self.perfil == "pag":
            self.pago_h += base * PASSE_CORTE
        base *= mult
        fim = agora + (0 if base * 3600 <= GRATIS_S else base)
        self.ocupado.append([fim, tipo, chave, base, 0.0])
        return True

    def iniciar_obras(self, agora, mercado):
        # fila A: Prefeitura ou o pré-requisito dela; espera o recurso em vez de fazer outra coisa
        if len(self.ocupado) < self.filas and not any(o[1] == "hq" for o in self.ocupado):
            ca = self.candidatos(True)
            if ca:
                if not self._iniciar(*ca[0], agora, mercado):
                    self.espera_recurso += 1
        while len(self.ocupado) < self.filas:
            cb = self.candidatos(False)
            if not any(self._iniciar(*c, agora, mercado) for c in cb[:4]):
                break

    def prox_custos(self) -> dict:
        prox_c = {r: 0.0 for r in RES}
        q1 = min(self.qg + 1, 30)
        for tipo, chave, n in ([("hq", None, q1)] + self.candidatos(False)[:3]):
            for r, v in custo(tipo, n).items():
                prox_c[r] += v
        return prox_c

    def calc_reserva(self):
        """Moeda guardada para comprar o que falta da próxima obra da Prefeitura."""
        c = custo("hq", min(self.qg + 1, 30))
        self.reserva = sum(max(0.0, c.get(r, 0) - self.estoque[r]) * Mercado.teto(r) for r in RES)

    def pesquisar(self, agora):
        if not PESQUISA:
            return
        self.pesq_ocup.sort()
        while self.pesq_ocup and self.pesq_ocup[0][0] <= agora + 1e-9:
            _, l = self.pesq_ocup.pop(0)
            self.pesq[l] += 1
            self.dia_pesq[(l, self.pesq[l])] = agora / 24
        prox = custo("hq", min(self.qg + 1, 30))
        while len(self.pesq_ocup) < self.filas_pesq:
            em = {o[1] for o in self.pesq_ocup}
            cand = [l for l in LINHAS if l not in em and self.pesq[l] < min(PESQ_NIVEIS, self.tec // 3)]
            if not cand:
                return
            l = min(cand, key=lambda x: (self.pesq[x], LINHAS.index(x)))
            c = custo_pesq(self.pesq[l] + 1)
            # pesquisa só usa o que sobra depois de garantir a próxima obra da Prefeitura
            if any(self.estoque[r] - c.get(r, 0) < prox.get(r, 0) for r in RES):
                return
            for r in RES:
                self.gastar(r, c.get(r, 0))
            self.pesq_ocup.append([agora + tempo_pesq_h(self.pesq[l] + 1), l])

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
                disp = self.colchao - self.reserva
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

    def sessao(self, agora, dur_h, mercado, primeira_do_dia, dia):
        # 1. produção desde a última coleta (até 8 h) e manutenção
        dt = min(agora - self.ultimo, OFFLINE_H)
        tx = self.taxa_prod()
        for r in RES:
            self.estoque[r] += tx[r] * dt
            self.vinc[r] += tx[r] * dt * self.prod_extra / self.mult_prod(r)
        self.gastar("energia", self.manut() * dt)
        vprod = self.valor({r: tx[r] * dt for r in RES}, PRECO_REF)
        self.f("producao_valor", vprod)
        self.ultimo = agora
        # 2. tropas
        orc = TROPAS * vprod
        if TROPAS_COMPRAM:  # o recurso fraco das tropas vem das ofertas de jogadores, se houver moeda livre
            for r in ("alimentos", "metal"):
                if r in self.fracos and (r == "alimentos" or self.qg >= 5):
                    q = orc * 0.5 / PRECO_REF[r] - self.estoque[r]
                    if not mercado.fixo:
                        q = min(q, mercado.disponivel(r) / self.peso)
                    q = min(q, max(0.0, self.colchao - self.reserva) / Mercado.preco_jog(r))
                    if q > 0:
                        self.colchao -= mercado.comprar(self, r, q, so_jogadores=True)
        a = min(self.estoque["alimentos"], orc * 0.5 / PRECO_REF["alimentos"])
        m = min(self.estoque["metal"], orc * 0.5 / PRECO_REF["metal"]) if self.qg >= 5 else 0
        self.gastar("alimentos", max(0.0, a))
        self.gastar("metal", max(0.0, m))
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
            self.calc_reserva()  # antes do vencimento, paga sem tocar a reserva da próxima obra
            pag = min(self.divida, self.colchao if dia >= self.divida_venc - 1 else max(0.0, self.colchao - self.reserva))
            self.colchao -= pag
            self.f("emprestimo_pagamento", -pag)
            self.divida -= pag
            if self.divida <= 1e-6:
                self.divida = 0.0
                self.nota = min(1000, self.nota + 50 if dia <= self.divida_venc else self.nota)
            elif dia > self.divida_venc:
                self.nota = max(0, self.nota - 100)
        # 5. obras e pesquisa: concluir e iniciar (dentro da sessão as obras curtas encadeiam)
        fim_sessao = agora + dur_h
        t = agora
        self.calc_reserva()
        while True:
            self.ocupado.sort()
            while self.ocupado and self.ocupado[0][0] <= t + 1e-9:
                o = self.ocupado.pop(0)
                self.concluir(o, o[0])
            self.iniciar_obras(t, mercado)
            self.pesquisar(t)
            self.calc_reserva()
            self.investir(t)
            self.ocupado.sort()
            prox = [o[0] for o in self.ocupado if o[0] <= fim_sessao]
            if not prox:
                break
            t = max(t, min(prox))
        # 6. oferta da sobra (acima de 1,5 vez as próximas obras); a parte do passe não entra
        prox_c = self.prox_custos()
        for r in RES:
            sobra = self.estoque[r] - self.vinc[r] - 1.5 * prox_c[r]
            if sobra > 0:
                self.estoque[r] -= sobra
                mercado.ofertar(self, r, sobra, agora)
        self.comprar_adiantado(mercado)
        self.calc_reserva()
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


def simular(dias=60, regioes=None, ags=None, fixo=False):
    """Roda a temporada. `ags` permite simular agentes avulsos (recém-chegado) num mercado fixo."""
    vag = carregar_regioes()
    regioes = regioes or list(REGIOES)
    if ags is None:
        ags = [Agente(rg, p, vag[rg] * PERFIS[p]["fatia"]) for rg in regioes for p in PERFIS]
    m = Mercado(fixo)
    eventos = sorted((h, i, k, mi) for i, a in enumerate(ags) for k, (h, mi) in enumerate(a.sessoes))
    hist = []
    arrec_est = {rg: [] for rg in REGIOES}
    arrec_fed = []
    obras_est = {rg: [] for rg in REGIOES}
    obras_fed = []
    prod_est = {rg: [] for rg in REGIOES}
    for dia in range(dias):
        m.novo_dia()
        for a in ags:
            a.logins_hoje = 0
            a.fluxo = {}
            a.imp_pago = 0.0
            a.cota_sis = (VENDA_COTA + 0.01 * a.pesq["comercio"]) * 24 * a.valor(a.taxa_prod(), PRECO_REF)
        for h, i, k, mi in eventos:
            ags[i].sessao(dia * 24 + h, mi / 60, m, k == 0, dia)
        m.fechar_dia(dia * 24 + 24)
        # tesouros: arrecadação do dia, gasto em obras públicas (1/7 do saldo + o que passa do teto)
        tes = {}
        if not fixo:
            for rg in REGIOES:
                prod_est[rg].append(sum(a.peso * a.fluxo.get("producao_valor", 0) for a in ags if a.regiao == rg))
            for rg in REGIOES:
                arr = m.d["imp_est"].get(rg, 0.0)
                arrec_est[rg].append(arr)
                saldo = m.tes_est.get(rg, 0.0) + arr
                gasto = saldo * TESOURO_GASTO_DIA
                saldo -= gasto
                teto = TESOURO_TETO_DIAS * sum(arrec_est[rg][-7:]) / len(arrec_est[rg][-7:])
                if saldo > teto:
                    gasto += saldo - teto
                    saldo = teto
                m.tes_est[rg] = saldo
                obras_est[rg].append(gasto)
            arrec_fed.append(m.d["imp_fed"])
            saldo = m.tes_fed + m.d["imp_fed"]
            gasto = saldo * TESOURO_GASTO_DIA
            saldo -= gasto
            teto = TESOURO_TETO_DIAS * sum(arrec_fed[-7:]) / len(arrec_fed[-7:])
            if saldo > teto:
                gasto += saldo - teto
                saldo = teto
            m.tes_fed = saldo
            obras_fed.append(gasto)
            ptot = sum(sum(prod_est[rg][-7:]) for rg in REGIOES) or 1
            b_fed = min(OBRA_PUB_BONUS_MAX, OBRA_PUB_EFICIENCIA * sum(obras_fed[-7:]) / ptot)
            b_est = {rg: min(OBRA_PUB_BONUS_MAX, OBRA_PUB_EFICIENCIA * sum(obras_est[rg][-7:]) / (sum(prod_est[rg][-7:]) or 1))
                     for rg in REGIOES}
            for a in ags:
                a.pub_bonus = b_est[a.regiao] + b_fed
            tes = {"saldo_est": sum(m.tes_est.values()), "saldo_fed": m.tes_fed,
                   "obras_est": sum(obras_est[rg][-1] for rg in REGIOES), "obras_fed": obras_fed[-1],
                   "b_est": b_est, "b_fed": b_fed}
        for a in ags:
            # rendimento do banco (diário, 1%/semana, com teto) e ataque ao cofre
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
            a.hist.append({"dia": dia + 1, "qg": a.qg, "moeda": a.colchao + a.banco - a.divida,
                           "prod_h": a.valor(a.taxa_prod(), PRECO_REF), "poder": a.poder(), "tec": a.tec,
                           "imp_pago": a.imp_pago, **a.fluxo})
        hist.append({"dia": dia + 1, "jog": m.d["jog"], "jog_r": dict(m.d["jog_r"]), "sis_vende": m.d["sis_vende"],
                     "sis_compra": m.d["sis_compra"], "imp_est": sum(m.d["imp_est"].values()), "imp_fed": m.d["imp_fed"],
                     "prod": sum(a.peso * a.fluxo.get("producao_valor", 0) for a in ags), **tes})
    return ags, hist


# Meta do jogador de 15 min por dia, sem pagar: dia em que chega ao nível.
META_P15 = {2: 0.02, 4: 0.05, 6: 0.15, 8: 0.5, 10: 1.5, 12: 5.0, 14: 12.0, 16: 18.0, 20: 30.0, 25: 45.0, 30: 60.0}


def calibrar_tempo():
    """Busca T_MAX e T_K para o jogador de 15 min chegar ao QG 20 no dia 30 e ao 30 no dia 60."""
    global T_MAX, T_K
    melhor = None
    for tk in (1.5, 2.0, 3.0, 4.0):
        for tmax in range(76, 133, 4):
            T_MAX, T_K = float(tmax), tk
            ags, _ = simular(dias=80, regioes=["Sudeste"])
            a = next(x for x in ags if x.perfil == "p15")
            d20, d30 = a.dia_qg.get(20, 99), a.dia_qg.get(30, 99)
            erro = (d20 - META_P15[20]) ** 2 + ((d30 - META_P15[30]) / 2) ** 2
            if melhor is None or erro < melhor[0]:
                melhor = (erro, tmax, tk, d20, d30)
    _, T_MAX, T_K = melhor[0], float(melhor[1]), melhor[2]
    return melhor


def calibrar_passe():
    """Busca o corte de tempo do passe para o pagante médio chegar à Prefeitura 30 no dia 30."""
    global PASSE_CORTE
    melhor = None
    for c in (0.30, 0.35, 0.40, 0.45, 0.50, 0.55, 0.60):
        PASSE_CORTE = c
        ags, _ = simular(dias=50, regioes=["Sudeste"])
        d30 = next(x for x in ags if x.perfil == "pag").dia_qg.get(30, 99)
        if melhor is None or abs(d30 - 30) < melhor[0]:
            melhor = (abs(d30 - 30), c, d30)
    PASSE_CORTE = melhor[1]
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


FLUXOS = ["missoes", "baus", "venda_sistema", "rendimento_banco", "emprestimo_saldo",
          "investimento", "compra_sistema", "imposto_estadual", "imposto_federal", "taxa_banco",
          "emprestimo_pagamento", "perda_colchao", "migracao", "obras_publicas"]
ROTULOS = {"missoes": "fonte: missões diárias", "baus": "fonte: baús", "venda_sistema": "fonte: vendas ao sistema (piso)",
           "rendimento_banco": "fonte: rendimento do banco", "emprestimo_saldo": "fonte: empréstimos concedidos",
           "investimento": "dreno: aceleração de obra", "compra_sistema": "dreno: compras ao sistema (teto)",
           "imposto_estadual": "dreno: imposto estadual (vai ao tesouro)", "imposto_federal": "dreno: imposto federal (vai ao tesouro)",
           "taxa_banco": "dreno: taxa do banco (2%)", "emprestimo_pagamento": "dreno: empréstimos pagos (com juros)",
           "perda_colchao": "dreno: cofre saqueado", "migracao": "dreno: migração",
           "obras_publicas": "dreno: obras públicas dos jogadores (apoio)"}


def dia_medio(ags, perfil, n):
    g = [a for a in ags if a.perfil == perfil]
    return sum(a.dia_qg.get(n, 99) for a in g) / len(g)


def resumo(ags, hist, ate=60):
    """Números-chave usados no relatório, nos cenários e no teste."""
    P = sum(h["prod"] for h in hist[:ate]) or 1
    g = [a for a in ags if a.perfil == "p15"]
    pr = [sum(x["prod_h"] for x in a.hist[:ate]) for a in g]
    po = [sum(x["poder"] for x in a.hist[:ate]) for a in g]
    my = []
    for d in range(13, min(ate, len(hist))):
        m = sum(a.peso * a.hist[d]["moeda"] for a in ags)
        y = sum(a.peso * a.hist[d]["prod_h"] * 24 for a in ags)
        my.append(m / y)
    carga = sum(a.peso * x["imp_pago"] for a in g for x in a.hist[:ate]) / (sum(a.peso * x.get("producao_valor", 0) for a in g for x in a.hist[:ate]) or 1)
    return {
        "dia": {pf: {n: dia_medio(ags, pf, n) for n in (10, 15, 20, 25, 30)} for pf in PERFIS},
        "comercio": sum(h["jog"] for h in hist[:ate]) / P,
        "venda_sistema": sum(h["sis_compra"] for h in hist[:ate]) / P,
        "compra_sistema": sum(h["sis_vende"] for h in hist[:ate]) / P,
        "impostos": sum(h["imp_est"] + h["imp_fed"] for h in hist[:ate]) / P,
        "carga_p15": carga,
        "reg_prod": max(pr) / min(pr), "reg_poder": max(po) / min(po),
        "reg_d30": max(a.dia_qg.get(30, 99) for a in g) - min(a.dia_qg.get(30, 99) for a in g),
        "my_max": max(my) if my else 0.0,
        "bonus_pub": (hist[ate - 1].get("b_fed", 0) + sum(hist[ate - 1].get("b_est", {}).values()) / len(REGIOES)) if hist else 0,
    }


def relatorio(ags, hist, dias, md=True):
    out = []
    p = out.append
    R = resumo(ags, hist, min(60, dias))
    # 1. ritmo
    p("## 1. Dia em que cada perfil chega ao nível da Prefeitura (média das regiões)\n")
    p("| Perfil | nível 10 | nível 15 | nível 20 | nível 25 | nível 30 | nível no dia 15 | nível no dia 30 | nível no dia 60 | Corte médio por investimento |")
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
    # 2. curvas (iguais à v0.2)
    p("\n## 2. Curvas da Prefeitura (as mesmas da v0.2; os outros prédios usam frações)\n")
    p("| Nível | Tempo-base da obra | Custo (valor em moedas) | Produção de referência/h | Preço de 1 h de aceleração |")
    p("|---|---|---|---|---|")
    for n in (2, 5, 8, 10, 12, 15, 18, 20, 22, 25, 28, 30):
        t = t_qg_h(n)
        ts = f"{br(t * 60)} min" if t < 1 else (f"{br(t, 1)} h" if t < 24 else f"{br(t / 24, 1)} d")
        p(f"| {n} | {ts} | {br(sum(v * PRECO_REF[r] for r, v in custo('hq', n).items()))} | {br(YREF[n])} | {br(KAPPA * YREF[n])} |")
    # 3. moeda por semana
    p("\n## 3. Moeda por semana, média ponderada de todos os jogadores (em % da produção)\n")
    sem = list(range(0, dias, 7))
    p("| Fluxo | " + " | ".join(f"sem {i // 7 + 1}" for i in sem) + " |")
    p("|---|" + "---|" * len(sem))

    def soma(k, rng):
        return sum(a.peso * a.hist[d].get(k, 0) for a in ags for d in rng)

    for k in FLUXOS:
        linha = []
        for i in sem:
            rng = range(i, min(i + 7, dias))
            linha.append(br(100 * soma(k, rng) / soma("producao_valor", rng), 1))
        p(f"| {ROTULOS[k]} | " + " | ".join(linha) + " |")
    for nome, pos in (("total de fontes", True), ("total de drenos", False)):
        linha = []
        for i in sem:
            rng = range(i, min(i + 7, dias))
            v = sum(a.peso * x for a in ags for d in rng for c, x in a.hist[d].items() if c in FLUXOS and (x > 0) == pos)
            linha.append(br(100 * v / soma("producao_valor", rng), 1))
        p(f"| **{nome}** | " + " | ".join(linha) + " |")
    linha = []
    for i in sem:
        rng = range(i, min(i + 7, dias))
        linha.append(br(100 * sum(hist[d]["jog"] for d in rng) / sum(hist[d]["prod"] for d in rng), 1))
    p("| comércio entre jogadores (transferência, fora dos totais) | " + " | ".join(linha) + " |")
    tot_peso = sum(a.peso for a in ags)
    p("| produção média por jogador/dia (moedas) | " + " | ".join(
        br(soma("producao_valor", range(i, min(i + 7, dias))) / tot_peso / len(range(i, min(i + 7, dias)))) for i in sem) + " |")
    # 4. moeda guardada, mercado e tesouros
    p("\n## 4. Moeda guardada (M/Y), mercado e tesouros\n")
    p("| Dia | M/Y médio | Comércio entre jogadores (% da produção do dia) | Sistema comprou no piso | Sistema vendeu no teto | Impostos | Saldo dos tesouros (dias de arrecadação) | Bônus das obras públicas (estado + país) |")
    p("|---|---|---|---|---|---|---|---|")
    for d in (7, 14, 21, 30, 45, 60):
        if d > dias:
            continue
        h = hist[d - 1]
        m = sum(a.peso * a.hist[d - 1]["moeda"] for a in ags)
        y = sum(a.peso * a.hist[d - 1]["prod_h"] * 24 for a in ags)
        arr = h["imp_est"] + h["imp_fed"]
        bon = h["b_fed"] + sum(h["b_est"].values()) / len(REGIOES)
        p(f"| {d} | {br(m / y, 2)} | {br(100 * h['jog'] / h['prod'], 1)}% | {br(100 * h['sis_compra'] / h['prod'], 1)}% | "
          f"{br(100 * h['sis_vende'] / h['prod'], 1)}% | {br(100 * arr / h['prod'], 1)}% | "
          f"{br((h['saldo_est'] + h['saldo_fed']) / max(arr, 1e-9), 1)} | +{br(100 * bon, 2)}% |")
    # 5. regiões
    p("\n## 5. Regiões: jogador de 15 min (dias 1 a 60, relativo à média das regiões)\n")
    p("| Região | Fortes (+30%) | Fracos (−20%, até 2 prédios) | Prefeitura 20 (dia) | Prefeitura 30 (dia) | Poder | Produção/h | Compras (% da produção) | Vendas a jogadores | Vendas ao sistema |")
    p("|---|---|---|---|---|---|---|---|---|---|")
    g = [a for a in ags if a.perfil == "p15"]
    jan = range(0, min(60, dias))
    med = {k: sum(a.hist[d][k] for a in g for d in jan) / len(g) for k in ("poder", "prod_h")}
    for a in g:
        rel = {k: sum(a.hist[d][k] for d in jan) / med[k] for k in med}
        P = sum(a.hist[d].get("producao_valor", 0) for d in jan)
        c = -sum(a.hist[d].get("compra_jogadores", 0) + a.hist[d].get("compra_sistema", 0) for d in jan)
        vj = sum(a.hist[d].get("venda_jogadores", 0) for d in jan)
        vs = sum(a.hist[d].get("venda_sistema", 0) for d in jan)
        fr = [r for r in RES if r in a.fracos]
        p(f"| {a.regiao} | {', '.join(FORTES[a.regiao])} | {', '.join(fr)} | {br(a.dia_qg.get(20, 99), 1)} | {br(a.dia_qg.get(30, 99), 1)} | "
          f"{br(rel['poder'], 3)} | {br(rel['prod_h'], 3)} | {br(100 * c / P, 1)}% | {br(100 * vj / P, 1)}% | {br(100 * vs / P, 1)}% |")
    # 6. pesquisa
    p("\n## 6. Centro tecnológico: níveis de pesquisa (média das regiões)\n")
    p("| Perfil | Centro no dia 30 | Centro no dia 60 | " + " | ".join(f"{l} (dia 60)" for l in LINHAS) + " |")
    p("|---|---|---|" + "---|" * len(LINHAS))
    for pf in PERFIS:
        gp = [a for a in ags if a.perfil == pf]

        def niv(l, d):
            return sum(sum(1 for (ll, k), t in a.dia_pesq.items() if ll == l and t <= d) for a in gp) / len(gp)
        p(f"| {NOME_PERFIL[pf]} | {br(sum(a.hist[min(30, dias) - 1]['tec'] for a in gp) / len(gp), 1)} | "
          f"{br(sum(a.hist[min(60, dias) - 1]['tec'] for a in gp) / len(gp), 1)} | " + " | ".join(br(niv(l, 60), 1) for l in LINHAS) + " |")
    # 7. passe e ajuda
    pg = [a for a in ags if a.perfil == "pag"]
    p("\n## 7. Pagante médio e ajuda do movimento\n")
    p(f"- Passe da temporada: obras {br(100 * PASSE_CORTE)}% mais rápidas, produção +{br(100 * PASSE_PROD)}%, "
      f"+{PASSE_FILA} fila de obra e +{PASSE_FILA_PESQ} de pesquisa. Equivale a {br(sum(a.pago_h for a in pg) / len(pg))} h de aceleração. "
      "A produção a mais do passe fica marcada e só paga obras e pesquisa do próprio jogador: nunca entra numa venda.")
    p(f"- Ajuda do movimento ({AJUDAS_POR_OBRA} ajudas por obra, {br(100 * AJUDA_CORTE)}% cada): "
      + ", ".join(f"{NOME_PERFIL[pf]} {br(sum(a.ajuda_h for a in ags if a.perfil == pf) / 5)} h" for pf in PERFIS) + " poupadas.")
    esp = {pf: sum(a.espera_recurso for a in ags if a.perfil == pf) / 5 for pf in PERFIS}
    p("- Sessões em que faltou recurso para iniciar obra: " + ", ".join(f"{k} {br(v)}" for k, v in esp.items()))
    p(f"\n**Resumo:** comércio entre jogadores {br(100 * R['comercio'], 1)}% da produção; vendas ao sistema {br(100 * R['venda_sistema'], 1)}%; "
      f"impostos {br(100 * R['impostos'], 1)}% (carga do jogador de 15 min: {br(100 * R['carga_p15'], 1)}% da produção); "
      f"regiões: produção {br(100 * (R['reg_prod'] - 1), 1)}% e poder {br(100 * (R['reg_poder'] - 1), 1)}% entre a maior e a menor, "
      f"nível 30 com {br(R['reg_d30'], 1)} dia de diferença; moeda guardada até {br(R['my_max'], 2)} dia de produção.")
    return "\n".join(out)


# ---------------------------------------------------------------- cenários
def _rodar(dias=85, **par):
    g = globals()
    velho = {k: g[k] for k in par}
    g.update(par)
    try:
        ags, hist = simular(dias)
        return resumo(ags, hist)
    finally:
        g.update(velho)


def cenario_impostos(totais=(0.0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60)):
    """Imposto somado (metade estadual, metade federal): atraso do nível 30 e carga na produção."""
    base = None
    linhas = []
    for t in totais:
        r = _rodar(IMPOSTO={"estadual": t / 2, "federal": t / 2})
        if base is None:
            base = r["dia"]["p15"][30]
        linhas.append((t, r["dia"]["p15"][30], r["dia"]["p15"][30] - base, r["dia"]["pag"][30], r["comercio"], r["carga_p15"], r["bonus_pub"]))
    return linhas


def cenario_margem(margens=(0.0, 0.05, 0.10, 0.15)):
    return [(m, _rodar(MARGEM=m)) for m in margens]


def recem_chegado(cortes=(0.0, 0.30, 0.50), perfis=("p15", "pag"), mediana=30, dias=75):
    """Cidade nova num servidor maduro (mediana na Prefeitura 30), mercado com oferta sempre disponível."""
    global RECEM_CORTE
    velho = RECEM_CORTE
    out = []
    try:
        for c in cortes:
            RECEM_CORTE = c
            for pf in perfis:
                ags = [Agente(rg, pf, 1.0, recem_mediana=mediana) for rg in REGIOES]
                simular(dias, ags=ags, fixo=True)
                out.append((c, pf, {n: sum(a.dia_qg.get(n, 99) for a in ags) / len(ags) for n in (15, 20, 25, 27, 30)}))
    finally:
        RECEM_CORTE = velho
    return out


def relatorio_cenarios() -> str:
    out = []
    p = out.append
    p("## 8. Impostos: faixas de capacidade de pagamento (imposto somado, metade estadual e metade federal; margem de 10%)\n")
    p("| Imposto somado | Nível 30, 15 min (dia) | Atraso | Nível 30, pagante | Comércio entre jogadores | Carga do jogador de 15 min (% da produção) | Bônus das obras públicas | Faixa |")
    p("|---|---|---|---|---|---|---|---|")
    for t, d, atr, dp, com, carga, bon in cenario_impostos():
        fx = faixa_imposto(t)
        p(f"| {br(100 * t)}% | {br(d, 1)} | {br(atr, 1)} | {br(dp, 1)} | {br(100 * com, 1)}% | {br(100 * carga, 1)}% | +{br(100 * bon, 2)}% | {fx} |")
    p("\n## 9. Margem de quem vende\n")
    p("| Margem | Nível 30, 15 min (dia) | Comércio entre jogadores | Vendas ao sistema | Produção: maior/menor região | Nível 30: diferença entre regiões (dias) |")
    p("|---|---|---|---|---|---|")
    for m, r in cenario_margem():
        p(f"| {br(100 * m)}% | {br(r['dia']['p15'][30], 1)} | {br(100 * r['comercio'], 1)}% | {br(100 * r['venda_sistema'], 1)}% | "
          f"{br(r['reg_prod'], 3)} | {br(r['reg_d30'], 1)} |")
    p("\n## 10. Bônus de recém-chegado (cidade nova num servidor com mediana na Prefeitura 30; vale até a Prefeitura 27)\n")
    p("| Corte de tempo | Perfil | nível 15 | nível 20 | nível 25 | nível 27 | nível 30 |")
    p("|---|---|---|---|---|---|---|")
    for c, pf, d in recem_chegado():
        p(f"| {br(100 * c)}% | {NOME_PERFIL[pf]} | " + " | ".join("—" if d[n] >= 99 else br(d[n], 1) for n in (15, 20, 25, 27, 30)) + " |")
    return "\n".join(out)


# Faixas de capacidade de pagamento (imposto somado sobre a venda). Fechadas pelo cenário de impostos.
FAIXAS_IMPOSTO = ((0.20, "verde"), (0.40, "amarela"), (1.01, "vermelha"))


def faixa_imposto(t: float) -> str:
    return next(n for lim, n in FAIXAS_IMPOSTO if t <= lim + 1e-9)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dias", type=int, default=66)
    ap.add_argument("--cenarios", action="store_true", help="impostos, margem e recém-chegado (cerca de 15 s)")
    ap.add_argument("--json")
    ap.add_argument("--calibrar-tempo", action="store_true", help="refaz a busca de T_MAX e T_K (cerca de 20 s)")
    a = ap.parse_args()
    if a.calibrar_tempo:
        print("calibrar_tempo:", calibrar_tempo())
        print("calibrar_passe:", calibrar_passe())
    ags, hist = simular(a.dias)
    print(relatorio(ags, hist, a.dias))
    if a.cenarios:
        print()
        print(relatorio_cenarios())
    if a.json:
        with open(a.json, "w", encoding="utf-8") as fh:
            json.dump({"yref": YREF, "dia_qg": {f"{x.regiao}/{x.perfil}": x.dia_qg for x in ags}}, fh,
                      ensure_ascii=False, indent=1)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
