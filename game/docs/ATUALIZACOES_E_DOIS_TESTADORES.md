# VALDORA — Alpha 0.2 | Distribuição, atualizações e testes com dois aparelhos

## Identidade
- **Valdora** é o jogo; **EVOLU Channel** é o estúdio publicador.
- Mantemos temporariamente o identificador técnico Android `ink.evolu.channel` para possibilitar atualizar a instalação Alpha existente, desde que **a chave de assinatura APK continue a mesma**.
- O salvamento legado `user://channel_save.json` e o **nome interno antigo** de `project.godot` são preservados, pois o nome do projeto participa da resolução da pasta `user://`. O **nome visível no APK** e no HUD é Valdora.
- Alterar o identificador Android para `ink.evolu.valdora` posteriormente **criaria outro app**, exigindo migração de dados e nova instalação. Adiar decisão até o fim da Alpha.

## Tecnologia
- Motor: Godot 4.7.2, renderizador Compatibility.
- Vercel: projeto existente `channel` e domínio `channel.evolu.ink`; hospeda manifesto e conteúdos JSON estáticos (sem funções, cron, Actions ou novas despesas).
- Supabase: **não conectado ao jogo nesta fase**. EVOLU possui 2 projetos ativos no Free (Training e Intelligence); não misturar dados de jogo aos projetos existentes nem provisionar terceiro que exija cobrança.

## Atualizações automáticas na 0.2

1. Ao abrir, o jogo lê seu último conteúdo verificado do armazenamento local (`user://`), sem apagar progresso.
2. O cliente consulta `https://channel.evolu.ink/updates/manifest.json` por HTTPS.
3. Confere `game=Valdora`, schema, compatibilidade da versão e origem fixa do arquivo.
4. Se há versão nova, baixa **somente um JSON declarativo** de até 256 KiB e compara SHA-256.
5. Confere que existem apenas chaves autorizadas e textos curtos; grava cópia local e o indicador de versão; aplica os textos sem reinstalar APK.
6. Offline ou em falha de rede/integridade, prossegue com os conteúdos instalados e mantém o salvamento.

O botão **ATUALIZAR** permite consultar manualmente. A verificação inicial ocorre uma vez por abertura, não é um processo contínuo, não usa serviços de background.

**Limites**: conteúdo JSON inclui somente mensagens de NPC e boas-vindas. Novos modelos 3D, mapas e sons exigirão um sistema de pacotes `.pck` com validação de assinatura criptográfica e regras de compatibilidade. Correções no código principal, motor nativo e permissões Android **continuam exigindo atualização do APK** — instalação assistida ou pela loja, não silenciosa. O hash protege a integridade contra corrupção, mas não substitui uma assinatura criptográfica do publicador.

## Segundo testador
1. Exportar uma vez `Valdora-Alpha-0.2.apk` no Godot Android com as mesmas configurações e chave de assinatura.
2. Instalar o mesmo APK em um segundo aparelho Android.
3. Ambos testam localmente, com saldos e progressos independentes. A conexão a Vercel consulta as mesmas atualizações.
4. Testar offline, rede lenta, versão já atualizada e JSON inválido (rollback local).
5. **Multiplayer simultâneo ainda não está incluído.** Para personagens interagirem no mesmo mapa, haverá nova fase com autenticação, sincronização de estados e autoridade do servidor; Supabase Realtime pode ajudar em presença/lobby, não substitui sozinho um servidor de jogo autoritativo.

## Validação requerida
- Abrir a Alpha 0.2 no editor Godot 4.7.2 e testar o autodiagnóstico 9/9.
- Confirmar APK com nome visível **Valdora**, sem mexer na assinatura, com `INTERNET` habilitada.
- Confirmar no dispositivo rede online que o manifesto foi lido e o texto recebido.
- Desligar a internet e reiniciar; confirmar que último conteúdo persiste e banco/moedas funcionam.
- Confirmar que APK atualizado instala **sobre** o anterior mantendo os saldos; falha de assinatura deve ser tratada antes de distribuir para o segundo usuário.
- Verificar público acesso TLS e resposta 200 do manifesto no domínio em produção. **Ainda não comprovado** nesta entrega.

## Não implementar sem decisão adicional
- Transferir ou criar projeto Supabase, banco, SQL, RLS, realtime multiplayer.
- Deploy de produção do jogo, mudar domínio principal do estúdio, habilitar Actions ou workflows pagos.
- Instalação silenciosa de APK ou código executável remoto sem controle de assinatura.