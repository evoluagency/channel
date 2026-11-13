# Valdora 1.0 — Passagem de bastão

Sessão: "Valdora 1.0 (Estado do jogo, OTA rev 10, APK 0.4.1 e direção visual)", 12 e 13/11/2026.
Branch de trabalho: `claude/zealous-tesla-kfhwld`. Registro único do projeto: `game/docs/ESTADO_DO_PROJETO.md`.

## Feito e verificado

1. **Primeira execução real dos smokes Godot** (Godot 4.7.2 oficial, hash conferido). 17 passaram; `remote_update_smoke` depende de rede até channel.evolu.ink. Log em `game/docs/logs/smokes_2026-11-12.log`.
2. **Script de testes corrigido**: `tools/run_valdora_tests.sh` copia manifesto e ZIPs para `game/tests/fixtures/`. Modos `--py`, padrão, `--all`, `--historico`.
3. **OTA revisão 10 publicada** com OK do dono: `main` em `18317b3`, 1 deploy, manifesto e `city-9.zip` conferidos em produção.
4. **APK 0.4.1 (code 103)** gerado pelo workflow manual na `release/valdora-android` (execução 43429562665), mesmo certificado. Instalado pelo dono por cima da 0.4.0 sem perda de dados.
5. **Homologação em aparelho** com quatro defeitos visuais registrados (seção 1 do registro).
6. **Direção visual v1**: `docs/DIRECAO_VISUAL.md` e `docs/direcao-visual/guia-visual.html`. Prévia privada: https://claude.ai/artifact/DF4Z4hh8tZe5br9AUFMLNX
7. **Site novo** com cinco páginas (Início, Universo, Classes, Reinos, Download), gerado por `tools/gerar_site.py` a partir de `tools/site_paginas/`. **Não publicado.**

## Pendente com o dono

- "OK, subir site" para publicar o site novo (1 deploy na Vercel).
- Revisar os textos de lore propostos (forças e era dos clãs) na página Universo.
- Pacotes completos do CP012 (Cidade v10, governança regional) e do CP013 (HUD 3D), que estão só no computador dele.
- Assinar módulos OTA no computador dele: a chave privada OTA fica no Drive e nunca entra no repositório.

## Atenção

- A minha branch nasceu da `docs/fase0-base-de-verdade` (base: release `8a29073`) e recebeu o `site/` da `main`. Não mesclar na `main` inteira: publicar o site copiando só `site/` numa branch `publicar/...` a partir da `main`.
- O CP013 aplica mudanças no `scripts/main.gd` conferindo o hash do arquivo. Não alterar o `main.gd` antes de integrar o CP013.
- O número `city-10` está reservado pelo CP012. Ver a primeira decisão do PROMPT-1.1.
