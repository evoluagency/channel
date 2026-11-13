#!/usr/bin/env python3
"""Gera as páginas estáticas de site/ a partir de tools/site_paginas/*.html.

Cada fonte tem uma primeira linha de metadados em JSON dentro de um comentário:
  <!-- {"titulo": "...", "descricao": "...", "menu": "inicio"} -->
O resto do arquivo é o conteúdo do <main>. Topo, rodapé e <head> saem daqui,
para que todas as páginas fiquem iguais. Não há build na Vercel: o resultado
gerado é versionado em site/. Uso: python3 tools/gerar_site.py
"""
from pathlib import Path
import json
import re

RAIZ = Path(__file__).resolve().parents[1]
FONTES = RAIZ / "tools" / "site_paginas"
SAIDA = RAIZ / "site"
DOMINIO = "https://channel.evolu.ink"

MENU = [
    ("inicio", "index.html", "Início", "inicio"),
    ("universo", "universo.html", "Universo", "universo"),
    ("classes", "classes.html", "Classes", "classes"),
    ("reinos", "reinos.html", "Reinos", "reinos"),
    ("download", "download.html", "Download", "baixar"),
]

LOGO = (
    '<svg viewBox="0 0 40 40" aria-hidden="true"><rect x="2.5" y="2.5" width="35" height="35" rx="7" '
    'fill="none" stroke="#ece6da" stroke-width="3"/><path d="M13 11.5h15M13 20h11M13 28.5h15M13 11.5v17" '
    'fill="none" stroke="#ece6da" stroke-width="4"/></svg>'
)

CABECA = """<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<meta name="theme-color" content="#0a0f22">
<title>{titulo}</title>
<meta name="description" content="{descricao}">
<meta property="og:title" content="{titulo}">
<meta property="og:description" content="{descricao}">
<meta property="og:image" content="{dominio}/assets/valdora-social.jpg">
<meta property="og:type" content="website">
<link rel="icon" href="assets/brasao.svg" type="image/svg+xml">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@600;700;800&family=Montserrat:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="assets/valdora.css">
</head>
<body>
"""


def topo(atual: str) -> str:
    itens = []
    for chave, href, nome, icone in MENU:
        marca = ' aria-current="page"' if chave == atual else ""
        itens.append(
            f'<a href="{href}"{marca}><svg class="icone" aria-hidden="true"><use href="assets/icones.svg#{icone}"/></svg>{nome}</a>'
        )
    return (
        '<header class="topo faixa"><div class="coluna">'
        f'<a class="marca" href="index.html" aria-label="EVOLU Channel, início">{LOGO}<span><b>EVOLU</b><small>CHANNEL</small></span></a>'
        f'<nav class="menu" aria-label="Principal">{"".join(itens)}</nav>'
        "</div></header>\n"
    )


RODAPE = """<footer class="rodape faixa"><div class="coluna">
<a class="marca" href="index.html" aria-label="EVOLU Channel, início">{logo}<span><b>EVOLU</b><small>CHANNEL</small></span></a>
<p>Valdora é um jogo independente do estúdio EVOLU Channel, em Alpha fechada para Android.</p>
<nav aria-label="Rodapé"><a href="universo.html">Universo</a><a href="classes.html">Classes</a><a href="reinos.html">Reinos</a><a href="download.html">Download</a><a href="https://github.com/evoluagency/channel" target="_blank" rel="noopener noreferrer">Código do projeto</a></nav>
</div></footer>
</body>
</html>
"""


def gerar() -> list[str]:
    feitas = []
    for fonte in sorted(FONTES.glob("*.html")):
        texto = fonte.read_text(encoding="utf-8")
        primeira, _, corpo = texto.partition("\n")
        meta = re.fullmatch(r"<!--\s*(\{.*\})\s*-->", primeira.strip())
        if not meta:
            raise SystemExit(f"{fonte.name}: primeira linha precisa ser o comentário JSON de metadados")
        dados = json.loads(meta.group(1))
        html = (
            CABECA.format(titulo=dados["titulo"], descricao=dados["descricao"], dominio=DOMINIO)
            + topo(dados["menu"])
            + "<main>\n" + corpo.strip() + "\n</main>\n"
            + RODAPE.format(logo=LOGO)
        )
        # Ícones embutidos: <use> de arquivo externo falha em file:// e em alguns visualizadores.
        sprite = (SAIDA / "assets" / "icones.svg").read_text(encoding="utf-8")
        sprite = sprite.replace('<svg xmlns="http://www.w3.org/2000/svg">', '<svg xmlns="http://www.w3.org/2000/svg" style="display:none" aria-hidden="true">', 1)
        html = html.replace("<body>\n", "<body>\n" + sprite.strip() + "\n", 1).replace('href="assets/icones.svg#', 'href="#')
        destino = SAIDA / fonte.name
        destino.write_text(html, encoding="utf-8")
        feitas.append(destino.relative_to(RAIZ).as_posix())
    return feitas


if __name__ == "__main__":
    for caminho in gerar():
        print("gerado:", caminho)
