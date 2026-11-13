# Valdora — Estado do projeto

Registro único do que está pronto, publicado e pendente. Atualizado em **13/11/2026**. Quando outro documento contradiz este, vale este até o outro ser corrigido. Atualize este arquivo ao fechar cada marco, e só ele.

Plano de continuidade (lacunas e fases): https://claude.ai/artifact/8PDe8WWqE8aftgsBwSU1rU

## 1. Versões

| Item | Valor | Como foi conferido |
|---|---|---|
| Código na `release/valdora-android` (`8a29073`) | 0.4.1-alpha, versionCode 103 | `export_presets.cfg`, `version.txt`, `update_contract.gd` |
| Pacote Android | `ink.evolu.valdora` | `export_presets.cfg` |
| Motor | Godot 4.7.2, GL Compatibility | `project.godot`, workflow `cp004-ota` |
| APKs recebidos do dono | 0.3.3 e 0.4.0-alpha (code 102) | os dois com o mesmo certificado do arquivo de credencial |
| APK 0.4.1 (code 103) | gerado e instalado por cima da 0.4.0 em 13/11/2026; homologado com defeitos visuais (ver abaixo) | workflow `valdora-android-release`, execução 43429562665 a partir da release `8a29073`; artefato 14039765549 expira em 20/11/2026 |

### Build do APK 0.4.1 (13/11/2026)

- Disparado manualmente na branch `release/valdora-android`. A cópia do workflow na `main` ainda exige versionCode 100 e não deve ser usada.
- Passaram: segredos, certificado permanente (SHA-256 `C5:95:06…`), testes estáticos, import, 8 smokes Godot (inclusive o OTA remoto contra a produção na revisão 10), exportação, `aapt` (`ink.evolu.valdora`, code 103, 0.4.1-alpha) e `apksigner` com o mesmo certificado. APK com 52.677.239 bytes; o SHA-256 está no `SHA256.txt` do artefato.
- Aviso na exportação: a cópia `game/modules/city/valdora_modules/city/entry.tscn` aponta para um script que só existe dentro do ZIP OTA. O APK sai assinado e o jogo usa o módulo do ZIP, mas é a lacuna P1 das duas cópias do módulo Cidade.
- Continuam dentro do APK: botão AUTO TESTE e a pasta de testes (lacuna P1 de release).
- Instalação: por cima da 0.4.0, sem desinstalar. `retain_data_on_uninstall=false`, então desinstalar apaga os saves.

### Homologação em aparelho da 0.4.1 com OTA revisão 10 (13/11/2026)

Prints do dono. Funciona: instalação por cima sem perder dados (moedas, poções, formação e nome da cidade preservados), tela de marca nova, "conteúdo v10" recebido, Cidade v9 abre em MINHA CIDADE com o painel Territórios, Heróis e Arena abrem.

Defeitos encontrados:

| Defeito | Onde | Correção sai por |
|---|---|---|
| Barra superior da Cidade: o rótulo de recursos fica numa coluna de letras, a barra estica até o meio da tela e escurece o mapa; o nome da cidade aparece no meio da tela | `city.gd`, `_create_ui`: `resource_label` com quebra de linha dentro de um `HBoxContainer` sem largura mínima | OTA (módulo da Cidade visual, sem assinatura ainda) |
| Texto "CIDADE · v8" desenhado no mapa da v9 | `city.gd`, `draw_string` | OTA (módulo da Cidade visual) |
| Botões do topo (MÓDULOS e outros) desenhados por cima dos painéis de Heróis e Arena | `main.gd`: botões adicionados à mesma camada depois dos painéis | APK |
| Mensagem de status do topo passa por baixo dos botões | `main.gd` | APK |

### Direção visual e site novo (13/11/2026)

- Guia em `docs/DIRECAO_VISUAL.md` (texto) e `docs/direcao-visual/guia-visual.html` (ilustrado).
- Site refeito com cinco páginas na branch `claude/zealous-tesla-kfhwld`, sobre o `site/` da `main`. **Não publicado**: publicar exige "OK, subir" e gera 1 deploy.
- Telas do jogo: Cidade pelo OTA; demais telas no APK junto com o CP013.

### Cidade na direção visual (sessão 1.1, 13/11/2026)

- Decisão do dono: o CP012 será `city-12`; nada é publicado agora e a Cidade visual evolui em versões intermediárias até lá. `city-10` e `city-11` ficam livres para o visual.
- `game/modules/city/city.gd` reescrito visualmente (barra de 60 px fixos, pílulas de recurso, sem "CIDADE · v8", Cinzel e Montserrat dentro do módulo, cores e raios do guia), regras e save da v9 intactos. Fontes e licenças OFL em `game/modules/city/fontes/`.
- Tema do núcleo em `game/scripts/ui/valdora_tema.gd` (não usado ainda); lista de mudanças de camadas e HUD em `game/docs/MUDANCAS_NUCLEO_CP013.md`. `main.gd` intocado.
- `tools/build_city_zip.py` monta o ZIP sem assinatura (determinístico, `dist/ota-trabalho/`). Assinatura: só no computador do dono, passo a passo em `game/docs/sessoes/HANDOFF-1.1.md`.
- Verificado com Godot 4.7.2 oficial: `--all` com 18 passando e só o `remote_update_smoke` falhando (sem rede). Captura em `game/docs/logs/cidade_visual_1280x720.png`. Falta homologar no aparelho depois da assinatura.
- O dono não tem os pacotes do CP012 nem do CP013; o desenvolvimento deles é nosso, em sessões próprias.
- Os defeitos 1 e 2 da tabela acima (barra e texto da v8) têm correção pronta e não homologada; os 3 e 4 seguem para o APK com o CP013.

### Mudança de rumo: jogo moderno (13/11/2026)

- Decisão do dono: o jogo passa a um cenário moderno (sem zumbis), com mapa-múndi real, divisões de estado reais, país/estado por jogador, alianças e guerra por território. Reskin do mesmo jogo, nome novo (provisório "MUNDO"). Piloto: Brasil, 27 estados.
- Desenho completo em `game/docs/DESENHO_MUNDO_v0.1.md` (decisões, perfis dos 27 estados, alianças, marcos M0 a M7, o que reaproveitar do Valdora). Prévia visual privada: https://claude.ai/artifact/7ZdEi4EiADxRTxHEQLhfGe
- Pendentes do dono: direção visual (A, B ou C), nome, atribuição do estado, territórios disputados, pacote do app novo, nomes dos heróis.
- Componentes, níveis 1 a 30 e aparência por faixa: `game/docs/COMPONENTES_NIVEIS_v0.1.md` (13 construções, heróis, tropas, estado, alianças, chat, animações). Números são proposta de balanceamento.
- O CP012 (`city-12`) deixa de ser pacote externo; o conteúdo é reescrito nos marcos M4 a M6. Nada do Valdora em produção muda; o site novo segue sem publicar.

## 2. O que está onde

| Conteúdo | `main` (site) | `release/valdora-android` | Produção em 11/11 |
|---|---|---|---|
| Manifesto OTA | revisão 10 (city-9) | revisão 10 (city-9, CP011) | **revisão 10 (city-9)**, deploy de 12/11 |

- Em 12/11/2026, com "OK, subir" do dono, a `main` avançou em fast-forward de `6f397f5` para `18317b3` (branch `publicar/ota-rev10`): manifesto revisão 10, `city-9.zip` e `vercel.json` que limita o deploy automático à `main`. Gerou 1 deploy de produção na Vercel. A revisão 9 nunca chegou à produção; saltou da 8 para a 10.
- Falta confirmar no celular que a Cidade v9 chega pelo OTA (homologação do dono).
- **CP012** (governança regional, será `city-12`) e **CP013** (HUD 3D) existem só no computador do dono. O CP013 muda o núcleo e exige APK novo.

## 3. Branches

- `main`: site, Vercel e OTA. Não tem `project.godot`.
- `release/valdora-android`: jogo completo.
- 22 branches `feat/` e `fix/` de checkpoints (CP001–CP011 e correções): históricas, não recebem push.
- Trabalho novo nasce no computador e só sobe em marco fechado.

## 4. Como a atualização chega ao celular

- **Módulos** (Cidade, guia, mensagens): ao abrir o app com internet, ele lê o manifesto OTA, baixa o que mudou, confere SHA-256 e assinatura RSA-3072 e ativa. Se algo falhar, mantém a versão anterior.
- **Núcleo** (HUD, mundo, combate, heróis, economia): só muda com APK novo instalado por cima, com o mesmo certificado e versionCode maior.
- Os módulos não vão dentro do APK. Vêm do servidor na primeira abertura.
- Fluxo completo em aparelho físico: não provado além do que o CP006 registra como homologado pelo dono.

## 5. Automação e custo

Workflows da `release` (a `main` só tem `valdora-android-release`):

| Workflow | Disparo |
|---|---|
| `valdora-android-release` | manual (`workflow_dispatch`) |
| `valdora-cp004-ota` | manual; roda 5 dos 15 smokes Godot (core, hero, combat, update, cp011) |
| `valdora-cp001`, `cp002`, `cp003-combat`, `cp003c-arena` | push só nas branches históricas respectivas, ou manual |

- O repositório é público: runners padrão do GitHub Actions não consomem franquia. Levantamento de 11/11 (execuções de 08 e 09/11, em UTC): 38 execuções, 19 falharam, cerca de 42 min no total.
- **Vercel Hobby: 100 deploys por dia, por equipe.** Nos 40 deploys mais recentes do projeto `channel`, feitos em 2h51 na noite de 08/11, 36 eram previews de branches e 22 foram cancelados. A equipe tem outros 5 projetos que dividem a mesma cota.
- `git.deploymentEnabled` em `site/vercel.json` está na `main` desde 12/11: só a `main` gera deploy. A `release` ainda não tem esse arquivo; a branch `docs/fase0-base-de-verdade` traz a versão mínima para ela.
- OTA revisão 10 publicada em 12/11 (ver seção 2). O cliente não aceita voltar a uma versão de módulo menor: correção é sempre uma versão nova.
- Segredos: `VALDORA_ANDROID_KEYSTORE_B64` e `VALDORA_ANDROID_KEYSTORE_PASSWORD` no GitHub Secrets; chave privada OTA em pasta restrita do Drive. Nenhum deles entra no repositório, nos ZIPs ou na Vercel.

## 6. Testes

- `game/tests`: 16 smokes Godot (o `city_visual_smoke` entra no `--all`; ainda não executado) e 3 testes Python.
- Comando único: `tools/run_valdora_tests.sh`. Sem opção, roda Python mais os 8 testes Godot que os workflows rodam hoje. Com `--py`, só Python. Com `--all`, inclui os 4 smokes extras que devem passar hoje. Com `--historico`, inclui também CP008, CP009 e CP010, que estão presos às revisões 7, 8 e 9 do manifesto e falham por desenho contra o manifesto atual. O script copia o manifesto e os ZIPs de `site/updates/v2/` para `game/tests/fixtures/` antes dos smokes, como o workflow `cp004-ota`; sem essa cópia 10 smokes falhavam (defeito corrigido em 12/11).
- Godot esperado: 4.7.2 (Linux x86_64, zip com SHA-256 `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`).
- **Primeira execução real dos smokes: 12/11/2026**, Godot 4.7.2 oficial com o hash conferido, código do jogo igual ao da release `8a29073`. Log em `game/docs/logs/smokes_2026-11-12.log`.

| Grupo | Resultado em 12/11 |
|---|---|
| Python (5 verificações) | passou |
| 8 smokes do CI: core 12/12, heróis 13/13, combate 42/42, cena 22/22 e 25/25, OTA 15/15, PCK 6/6, CP006 8/8, CP011 44/44 | passou |
| Extras: CP005 11/11, CP007 22/22, layout de nome 14/14 | passou |
| `remote_update_smoke` | não conclusivo: exige rede até channel.evolu.ink, bloqueada na máquina de teste |
| Históricos CP008, CP009, CP010 | falham só nas checagens de revisão do manifesto (CP010: 45 de 48, as 3 que faltam são `manifest_9`, `module_8`, `signed`) |

- Portão G1 da Fase 1: aberto. Falta só rodar `remote_update_smoke` numa máquina com acesso ao domínio e registrar aqui.

## 7. Documentos que contradiziam o estado real

Corrigidos em 11/11/2026 com nota datada no topo, sem reescrever o histórico:

- `CP004_OTA_MODULAR.md`: falava em fase de construção e em APK 0.4.0 não homologado.
- `RELEASE_ANDROID_PERMANENTE.md`: descrevia a 0.4.0 e um gatilho de push em `build.request` que não existe mais; o workflow só roda manualmente.
- `ARQUITETURA.md`: dizia "sem Actions/jobs", pacote `ink.evolu.channel`, sem combate e sem validação de atualização.
- `README.md` da raiz: dizia "sem GitHub Actions"; vale só para o addon Minecraft.
- `game/README.md`: descreve a Alpha 0.2.1.

Ainda abertos: o `GDD Mestre v0.4.1` não está no repositório, e os documentos `docs/` da raiz são da era Minecraft, não do jogo atual.

## 8. Pendências que dependem do dono

1. Entregar o GDD Mestre v0.4.1, se existir; senão, redesenhar.
2. Entregar os pacotes completos do CP012 e do CP013.
3. Responder as decisões 1 a 4 do plano de continuidade.
4. ~~Instalar e homologar o APK 0.4.1~~ feito em 13/11/2026, com os defeitos listados na seção 1.
5. ~~Primeira execução real dos smokes~~ feita em 12/11/2026 (seção 6). Resta rodar `remote_update_smoke` numa máquina com acesso a channel.evolu.ink.

## 9. Decisões vigentes

O dono delegou as decisões em 11/11/2026. Ele pode reverter qualquer uma.

- GDD: reconstruído a partir do código e dos CP, marcado como reconstruído. A cópia do dono prevalece se aparecer.
- `release/valdora-android` é o tronco do jogo. A `main` fica só com site e OTA até a G2.
- Testes locais e gratuitos. Workflow manual do GitHub só em marco fechado.
- Meta de 30 FPS estáveis em Samsung e Xiaomi, medida na Fase 4.
- Primeiro laço da Fase 3: combate que dá moedas e experiência aos heróis.
- Online fora até a G3.
- A versão do app nunca cai abaixo do code 103. "Valdora 0.1" é só o nome do ciclo de trabalho iniciado em 11/11/2026.

## 10. Como retomar

1. Esta branch (`docs/fase0-base-de-verdade`, base: release `8a29073`) tem o registro, o script de testes e o `site/vercel.json` mínimo; a branch `claude/zealous-tesla-kfhwld` a continua com a correção do script e o log de 12/11. A branch `publicar/ota-rev10` (base: `main` `6f397f5`) tem o `vercel.json` completo e a publicação da revisão 10. Nenhuma das duas foi integrada à release ou à `main`.
2. `tools/run_valdora_tests.sh --all` já rodou com o Godot 4.7.2 em 12/11 (seção 6). Repetir a cada marco; no computador do dono, rodar também o `remote_update_smoke`.
3. Revisão 10 publicada em 12/11 (`main` = `18317b3`). Próxima publicação segue o mesmo rito: branch `publicar/...` a partir da `main`, conferir fast-forward e assinatura, "OK, subir" do dono, 1 deploy.
4. Fase 2 quando chegarem os pacotes completos do CP012 e do CP013.
5. Regras de custo: o único gasto pago é a assinatura Claude; franquias só com aviso e estimativa; a Vercel Hobby aceita 100 deploys por dia por equipe; o cliente rejeita módulo de versão menor, então correção de OTA é sempre versão nova; segredos nunca entram no repositório, em ZIP, na Vercel ou em documento.
