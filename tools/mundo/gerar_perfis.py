#!/usr/bin/env python3
"""Gera game/data/mundo/BR_perfis.json: perfis dos 27 estados do piloto Brasil.

Lê a geometria de game/data/mundo/BR.json (área calculada, litoral, vizinhos) e
junta os dados de desenho abaixo: região, área oficial aproximada (IBGE),
biomas, vocação fictícia, bônus da região, capital e vagas de base. O peso sai
da fórmula da seção 4 de DESENHO_MUNDO_v0.1.md (antes "lotes"), sobre a área
oficial, e reparte as vagas de base do servidor (seção 4.1).

Python puro; mesma entrada, mesmo arquivo.

Uso: python3 -I tools/mundo/gerar_perfis.py [--pais game/data/mundo/BR.json] [--saida ...]
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.dirname(os.path.dirname(AQUI))
FORMATO = "mundo-perfis/1"

# Fórmula dos lotes (DESENHO_MUNDO_v0.1.md, seção 4). A referência 5760 km² é o DF.
LOTES_MIN, LOTES_MAX = 40, 120
LOTES_BASE_KM2 = 5760.0
LOTES_FATOR = 32.9


def lotes(area_km2: float) -> int:
    v = LOTES_MIN + LOTES_FATOR * math.log10(area_km2 / LOTES_BASE_KM2)
    return int(math.floor(max(LOTES_MIN, min(LOTES_MAX, v)) + 0.5))


# Área territorial oficial aproximada (IBGE, 2022), km², arredondada a 0,1.
AREA_IBGE = {
    "AC": 164173.4, "AL": 27830.7, "AP": 142470.8, "AM": 1559255.9, "BA": 564760.4,
    "CE": 148894.4, "DF": 5760.8, "ES": 46074.4, "GO": 340242.9, "MA": 329651.5,
    "MT": 903208.4, "MS": 357142.1, "MG": 586514.0, "PA": 1245870.7, "PB": 56467.2,
    "PR": 199299.0, "PE": 98067.9, "PI": 251755.5, "RJ": 43750.4, "RN": 52809.6,
    "RS": 281707.2, "RO": 237754.2, "RR": 223644.5, "SC": 95730.7, "SP": 248219.5,
    "SE": 21938.2, "TO": 277423.6,
}

REGIAO = {
    **dict.fromkeys(["AC", "AP", "AM", "PA", "RO", "RR", "TO"], "Norte"),
    **dict.fromkeys(["AL", "BA", "CE", "MA", "PB", "PE", "PI", "RN", "SE"], "Nordeste"),
    **dict.fromkeys(["DF", "GO", "MT", "MS"], "Centro-Oeste"),
    **dict.fromkeys(["ES", "MG", "RJ", "SP"], "Sudeste"),
    **dict.fromkeys(["PR", "RS", "SC"], "Sul"),
}

# Biomas em ordem de participação na área (o primeiro é o dominante) e vocação
# fictícia, da tabela da seção 5 do desenho. Mudança: MT passa a ter a Amazônia
# como dominante (cerca de 54% da área, contra 40% de Cerrado).
DESENHO = {
    "AC": (["Amazônia"], "Bioeconomia"),
    "AL": (["Mata Atlântica", "Caatinga"], "Bioenergia"),
    "AP": (["Amazônia"], "Energia hídrica e porto"),
    "AM": (["Amazônia"], "Eletrônica (polo industrial)"),
    "BA": (["Caatinga", "Cerrado", "Mata Atlântica"], "Petroquímica e renováveis"),
    "CE": (["Caatinga"], "Energia eólica e porto"),
    "DF": (["Cerrado"], "Administração e dados"),
    "ES": (["Mata Atlântica"], "Portos e minério"),
    "GO": (["Cerrado"], "Agroindústria"),
    "MA": (["Cerrado", "Amazônia"], "Logística portuária"),
    "MT": (["Amazônia", "Cerrado", "Pantanal"], "Grãos em escala"),
    "MS": (["Cerrado", "Pantanal"], "Pecuária e celulose"),
    "MG": (["Cerrado", "Mata Atlântica"], "Mineração e metalurgia"),
    "PA": (["Amazônia"], "Mineração"),
    "PB": (["Caatinga"], "Tecnologia e solar"),
    "PR": (["Mata Atlântica"], "Agroindústria e automotivo"),
    "PE": (["Caatinga", "Mata Atlântica"], "Saúde e software"),
    "PI": (["Caatinga", "Cerrado"], "Eólica e solar"),
    "RJ": (["Mata Atlântica"], "Petróleo offshore e pesquisa"),
    "RN": (["Caatinga"], "Eólica e sal"),
    "RS": (["Pampa", "Mata Atlântica"], "Máquinas e pecuária"),
    "RO": (["Amazônia"], "Hidrelétrica e agro"),
    "RR": (["Amazônia"], "Fronteira e logística"),
    "SC": (["Mata Atlântica"], "Têxtil, naval e software"),
    "SP": (["Mata Atlântica", "Cerrado"], "Indústria e finanças"),
    "SE": (["Caatinga", "Mata Atlântica"], "Petróleo e gás"),
    "TO": (["Cerrado"], "Agro e logística"),
}

# Bônus de produção por região (SOCIEDADE_ECONOMIA_v0.1.md, seção 4; aprovado em
# 13/11/2026): cada região soma +20%, em 2 ou 3 recursos.
BONUS_REGIAO = {
    "Norte": {"metal": 10, "energia": 10},
    "Nordeste": {"energia": 10, "alimentos": 10},
    "Centro-Oeste": {"alimentos": 10, "metal": 10},
    "Sudeste": {"materiais": 10, "metal": 5, "energia": 5},
    "Sul": {"alimentos": 7, "materiais": 7, "energia": 6},
}

# Servidor (DESENHO_MUNDO_v0.1.md, seção 4.1; aprovado em 13/11/2026): bases de
# tamanho igual, vagas repartidas pelo peso (fórmula de lotes) entre os 26 estados;
# o DF é a capital federal, sem bases de jogador.
BASE_LOTES = 80
VAGAS_SERVIDOR = 2000
CAPITAL_FEDERAL = "DF"

# Capitais estaduais (ponto de disputa do governo), lon/lat com 2 casas.
CAPITAIS = {
    "AC": ("Rio Branco", -67.81, -9.97), "AL": ("Maceió", -35.74, -9.67),
    "AP": ("Macapá", -51.07, 0.03), "AM": ("Manaus", -60.02, -3.12),
    "BA": ("Salvador", -38.50, -12.97), "CE": ("Fortaleza", -38.54, -3.73),
    "DF": ("Brasília", -47.88, -15.79), "ES": ("Vitória", -40.31, -20.32),
    "GO": ("Goiânia", -49.25, -16.68), "MA": ("São Luís", -44.30, -2.53),
    "MT": ("Cuiabá", -56.10, -15.60), "MS": ("Campo Grande", -54.62, -20.47),
    "MG": ("Belo Horizonte", -43.94, -19.92), "PA": ("Belém", -48.50, -1.46),
    "PB": ("João Pessoa", -34.86, -7.12), "PR": ("Curitiba", -49.27, -25.43),
    "PE": ("Recife", -34.88, -8.05), "PI": ("Teresina", -42.80, -5.09),
    "RJ": ("Rio de Janeiro", -43.21, -22.91), "RN": ("Natal", -35.21, -5.79),
    "RS": ("Porto Alegre", -51.23, -30.03), "RO": ("Porto Velho", -63.90, -8.76),
    "RR": ("Boa Vista", -60.67, 2.82), "SC": ("Florianópolis", -48.55, -27.60),
    "SP": ("São Paulo", -46.63, -23.55), "SE": ("Aracaju", -37.07, -10.91),
    "TO": ("Palmas", -48.33, -10.18),
}


def repartir(pesos: dict, total: int) -> dict:
    """Maiores restos: soma exata, empate decidido pela sigla."""
    soma = sum(pesos.values())
    cota = {u: total * p / soma for u, p in pesos.items()}
    v = {u: int(math.floor(c)) for u, c in cota.items()}
    resto = total - sum(v.values())
    for u in sorted(pesos, key=lambda u: (-(cota[u] - v[u]), u))[:resto]:
        v[u] += 1
    return v


def gerar(pais: dict) -> dict:
    pesos = {e["uf"]: lotes(AREA_IBGE[e["uf"]]) for e in pais["estados"]}
    vagas = repartir({u: p for u, p in pesos.items() if u != CAPITAL_FEDERAL}, VAGAS_SERVIDOR)
    estados = []
    for e in pais["estados"]:
        uf = e["uf"]
        biomas, vocacao = DESENHO[uf]
        of = AREA_IBGE[uf]
        cap = CAPITAIS[uf]
        estados.append({
            "uf": uf,
            "nome": e["nome"],
            "regiao": REGIAO[uf],
            "area_oficial_km2": round(of),
            "area_calculada_km2": e["area_km2"],
            "diferenca_area_pct": round(100 * (e["area_km2"] / of - 1), 1),
            "peso": pesos[uf],
            "vagas_base": vagas.get(uf, 0),
            "capital_federal": uf == CAPITAL_FEDERAL,
            "capital": {"nome": cap[0], "lon": cap[1], "lat": cap[2]},
            "bioma_dominante": biomas[0],
            "biomas": biomas,
            "litoral": e["litoral"],
            "litoral_km": e["litoral_km"],
            "vizinhos": e["vizinhos"],
            "vocacao": vocacao,
            "bonus_regiao_pct": BONUS_REGIAO[REGIAO[uf]],
        })
    return {
        "formato": FORMATO,
        "pais": pais["pais"],
        "status": "aprovado pelo dono em 13/11/2026 (sessão 1.3); números de balanceamento revisáveis",
        "fontes": {
            "geometria": "game/data/mundo/BR.json (Natural Earth 1:10m, domínio público)",
            "area_oficial": "IBGE, áreas territoriais 2022, aproximadas a 1 km²",
        },
        "regras": {
            "peso": f"round(clamp({LOTES_MIN} + {LOTES_FATOR} x log10(area_oficial_km2 / {LOTES_BASE_KM2:g}), {LOTES_MIN}, {LOTES_MAX}))",
            "vagas_base": f"{VAGAS_SERVIDOR} bases por servidor, repartidas pelo peso entre os estados (maiores restos); {CAPITAL_FEDERAL} é a capital federal, sem bases",
            "base_lotes": BASE_LOTES,
            "bonus_regiao": "+20% de produção por região, em 2 ou 3 recursos",
            "vocacao": "bônus de 5 a 10% na tecnologia de assinatura (DESENHO_MUNDO_v0.1.md, seção 4)",
        },
        "estados": estados,
    }


def serializar(doc: dict) -> str:
    def c(v):
        return json.dumps(v, ensure_ascii=False, separators=(",", ":"), sort_keys=True)
    cab = {k: v for k, v in doc.items() if k != "estados"}
    linhas = [c(cab)[:-1] + ',"estados":[']
    linhas += [c(e) + ("," if i < len(doc["estados"]) - 1 else "") for i, e in enumerate(doc["estados"])]
    linhas.append("]}")
    return "\n".join(linhas) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--pais", default=os.path.join(RAIZ, "game", "data", "mundo", "BR.json"))
    ap.add_argument("--saida", default=os.path.join(RAIZ, "game", "data", "mundo", "BR_perfis.json"))
    a = ap.parse_args()
    with open(a.pais, encoding="utf-8") as f:
        pais = json.load(f)
    texto = serializar(gerar(pais))
    with open(a.saida, "w", encoding="utf-8", newline="\n") as f:
        f.write(texto)
    print(f"{a.saida}: {len(texto.encode())} bytes, sha256 {hashlib.sha256(texto.encode()).hexdigest()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
