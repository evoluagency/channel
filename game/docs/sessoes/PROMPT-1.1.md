# Valdora 1.1 (Telas do jogo na direção visual)

Responda em português do Brasil, de forma direta. Leia antes de agir: `game/docs/ESTADO_DO_PROJETO.md`, `game/docs/sessoes/HANDOFF-1.0.md` e `docs/DIRECAO_VISUAL.md`.

## Objetivo

Levar a direção visual v1, já aplicada ao site, para as telas do jogo Godot, e corrigir os quatro defeitos visuais vistos no aparelho em 13/11.

## Decisão que vem primeiro (perguntar ao dono)

O número `city-10` está reservado pelo CP012 (governança regional), que está só no computador do dono. Pergunte:

1. Ele envia agora o pacote completo do CP012? Então a Cidade visual entra por cima do CP012 e sai como `city-10`.
2. Ou a Cidade visual sai antes, como `city-10`, e o CP012 passa a `city-11`?

Enquanto ele não responder, prepare o trabalho sem número de versão e sem assinatura.

## Trabalho

1. **Módulo Cidade** (`game/modules/city/city.gd`, cópia que gera o ZIP):
   - Barra superior de altura fixa de 60 px com nome da cidade e recursos em pílulas, sem quebra de linha. Causa do defeito: `resource_label` com quebra automática dentro de um `HBoxContainer`.
   - Remover o texto "CIDADE · v8" desenhado no mapa.
   - Cores, raios, molduras e tamanhos de letra da direção visual; Cinzel nos títulos e Montserrat no resto, com os TTF e a licença OFL dentro do próprio módulo.
   - Sem mudar regras de jogo, caminho ou esquema do save. O módulo deve continuar sem depender do núcleo, porque o APK instalado é o 0.4.1.
   - Smoke novo da versão visual e todos os smokes atuais passando com `tools/run_valdora_tests.sh --all`.
2. **Tema do núcleo**: criar `game/scripts/ui/valdora_tema.gd` com as constantes da direção visual (arquivo novo; não toca no `main.gd`). Preparar, sem aplicar, a lista de mudanças de camadas e de HUD para entrar junto com o CP013.
3. **ZIP sem assinatura** em pasta de trabalho, mais as instruções exatas para o dono assinar no computador dele com `tools/ota_manifest.py --key-file` e conferir com `--verify-existing`.
4. Atualizar `game/docs/ESTADO_DO_PROJETO.md` e escrever `game/docs/sessoes/HANDOFF-1.1.md`.

## Regras

- Único gasto pago: assinatura Claude. Nada de serviço pago novo.
- Nada de push na `main`, deploy, publicação de OTA ou workflow sem OK explícito do dono. A Vercel publica a partir da `main`; cada push nela é 1 deploy.
- Validação local primeiro. Godot 4.7.2 oficial: baixar o zip Linux x86_64 e conferir o SHA-256 `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4` antes de usar.
- Chaves privadas (APK e OTA) nunca entram no repositório, em ZIP, na Vercel ou em documento.
- O cliente recusa módulo de versão menor: correção é sempre versão nova.
- Não alterar `game/scripts/main.gd` antes de integrar o CP013.
- Títulos de sessão seguem o padrão "Valdora N.N (tema)". A próxima é a 1.2.
