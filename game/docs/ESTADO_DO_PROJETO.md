# Valdora — Estado do projeto

Registro único do que está pronto, publicado e pendente. Atualizado em **12/11/2026**. Quando outro documento contradiz este, vale este até o outro ser corrigido. Atualize este arquivo ao fechar cada marco, e só ele.

Plano de continuidade (lacunas e fases): https://claude.ai/artifact/8PDe8WWqE8aftgsBwSU1rU

## 1. Versões

| Item | Valor | Como foi conferido |
|---|---|---|
| Código na `release/valdora-android` (`8a29073`) | 0.4.1-alpha, versionCode 103 | `export_presets.cfg`, `version.txt`, `update_contract.gd` |
| Pacote Android | `ink.evolu.valdora` | `export_presets.cfg` |
| Motor | Godot 4.7.2, GL Compatibility | `project.godot`, workflow `cp004-ota` |
| APKs recebidos do dono | 0.3.3 e 0.4.0-alpha (code 102) | os dois com o mesmo certificado do arquivo de credencial |
| APK 0.4.1 (code 103) | não verificado | `build.request` pede o build; nenhum APK 0.4.1 foi recebido |

## 2. O que está onde

| Conteúdo | `main` (site) | `release/valdora-android` | Produção em 11/11 |
|---|---|---|---|
| Manifesto OTA | revisão 9 (city-8) | revisão 10 (city-9, CP011) | **revisão 8 (city-7)** |

- Produção conferida pelo manifesto aberto no navegador e pelo último deploy de produção da Vercel (`main`, commit `66f8003`).
- A revisão 9 está na `main` (`6f397f5`), mas não tem deploy: não chegou à produção.
- **CP012** (Cidade v10) e **CP013** (HUD 3D) existem só no computador do dono. O CP013 muda o núcleo e exige APK novo.

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
- Correção preparada, ainda não enviada: `git.deploymentEnabled` em `site/vercel.json`, limitando o deploy automático à `main`. A `release` não tinha `site/vercel.json`, então cada push nela gerava preview; ela recebe um arquivo mínimo com a mesma regra.
- Publicação preparada, ainda não enviada: OTA revisão 10 (city-9) na `main`, copiando só o manifesto e o `city-9.zip` da release, junto com o `vercel.json`, num único push (1 deploy). O código do CP011 é idêntico ao do commit `03e7784`, que passou na validação Godot do CI. O cliente não aceita voltar a uma versão de módulo menor: correção é sempre uma versão nova.
- Segredos: `VALDORA_ANDROID_KEYSTORE_B64` e `VALDORA_ANDROID_KEYSTORE_PASSWORD` no GitHub Secrets; chave privada OTA em pasta restrita do Drive. Nenhum deles entra no repositório, nos ZIPs ou na Vercel.

## 6. Testes

- `game/tests`: 15 smokes Godot e 3 testes Python.
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
4. Homologar o APK em aparelho físico.
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
3. A publicação da revisão 10 só acontece com "OK, subir" do dono: `git push origin publicar/ota-rev10:main`, que avança a `main` em fast-forward e gera 1 deploy. Antes, conferir que a `main` continua em `6f397f5`.
4. Fase 2 quando chegarem os pacotes completos do CP012 e do CP013.
5. Regras de custo: o único gasto pago é a assinatura Claude; franquias só com aviso e estimativa; a Vercel Hobby aceita 100 deploys por dia por equipe; o cliente rejeita módulo de versão menor, então correção de OTA é sempre versão nova; segredos nunca entram no repositório, em ZIP, na Vercel ou em documento.
