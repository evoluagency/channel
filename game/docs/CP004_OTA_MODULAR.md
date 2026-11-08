# Valdora — CP004 | OTA modular (fase de construção)

Branch de implementação: \`feat/valdora-cp004-ota-foundation\`. **Não publicar APK, deploy ou workflow sem homologação.**

## O que muda

- A Alpha 0.4.0 (Android versionCode 102, ainda não distribuída) inclui dois autoloads:
  1. \`ValdoraPacks\`, carregado primeiro, valida hash e assinatura de PCK e monta no arranque com \`replace_files=false\`.
  2. \`ValdoraUpdater\`, consulta a Vercel na inicialização e também por botão; baixa sequencialmente para armazenamento privado e ativa somente depois da verificação completa.
- \`ATUALIZAR\` consulta tanto o protocolo legado de diálogos v1 quanto o catálogo de módulos v2.
- O novo botão \`MÓDULOS\` exibe ações declarativas recebidas remotamente.
- Arquivos são versionados em \`user://valdora_updates/files/\`. Metadados ativos e anteriores são separados.
- Falha de rede, download parcial, hash incorreto ou pacote não confiável não remove o conteúdo anterior.
- Pacotes PCK só são aceitos com assinatura RSA/SHA-256 e chave pública fixa incorporada ao aplicativo. **Sem chave pública válida, ficam bloqueados por padrão.**
- Novo conteúdo PCK montado antes da cena principal pode adicionar cenas em \`res://valdora_modules/<id>/entry.tscn\`, sem sobrescrever recursos originais.
- Dados JSON não podem executar scripts arbitrários, mudar saldos ou emitir recompensas. Comandos disponíveis: \`message\`, \`open_heroes\`, \`open_combat\`, \`economy\`.

## Atualização versus instalação Android

A versão instalada 0.3.3 **não consegue se autoalterar para executar CP004**. Há **uma migração de aplicativo-base** (código 101 para 102) a homologar usando a assinatura Android permanente e sem desinstalação. Após a migração, *módulos compatíveis* não exigem novos APKs. Mudanças em permissões, bibliotecas nativas, versão do motor e outras capacidades não previstas podem exigir APK futuro e confirmação da instalação pelo Android.

A Vercel entrega apenas arquivos estáticos públicos. Os arquivos v2 deste branch ainda não estão em produção. O protocolo v1 permanece inalterado.

## Contrato de publicação v2

GET \`https://channel.evolu.ink/updates/v2/manifest.json\` (sem redirects), JSON com:
- \`schema_version: 2\`, \`game: "Valdora"\`, \`channel: "alpha"\`, \`revision\` crescente e \`min_client_code\`.
- \`modules[]\` com ID estável, versão, kind \`data|pck\`, URL HTTPS exata no domínio, bytes e SHA-256.
- PCK requer \`entry: res://valdora_modules/<id>/entry.tscn\` e \`signature_b64\` calculada com RSA/SHA-256 sobre os **bytes exatos do PCK**. A implementação do cliente usa \`Crypto.verify(HASH_SHA256, digest, signature, public_key)\`.
- Data JSON possui \`schema_version:1\`, \`module_id\`, \`title\` e lista de \`actions[]\` com \`id\`, \`label\`, \`command\` e \`text\` (somente para \`message\`).
- Cada recurso PCK novo precisa ser preparado com Godot compatível e referenciar apenas arquivos de seu namespace. A assinatura comprova origem, mas não substitui revisão de código, QA de assets e política de segurança.

**ATENÇÃO — chave de publicação:** antes de habilitar PCK, gerar uma chave RSA exclusiva para OTA, armazenar a privada fora do GitHub e da Vercel e incluir somente a pública em \`game/updates/trust/valdora_ota.pub\`. A chave de assinatura Android do APK não deve ser reutilizada. A implementação permanece com PCK *fail closed* até esse processo, evitando ativação de código remoto não autenticado. Manifests JSON são entregues por HTTPS; dados continuam restritos a comandos conhecidos.

## Requisitos de homologação antes da distribuição

1. Import Godot + testes core, heróis, combate e cena (CP001/002/003/004).
2. Verificar \`MÓDULOS\`, fluxo v2, download e atualização imediata de JSON.
3. Rodar testes negativos: 404, offline, HTTPS redirecionado, SHA divergente, truncamento, path traversal, alteração de versão, ausência de chave, assinatura adulterada, falta de espaço, reinício durante o download e rollback.
4. Gerar PCK mínimo, assiná-lo, confirmar adição de cena sem substituir \`res://scripts\` original.
5. Instalar APK 0.4.0 **sobre** 0.3.3 com a mesma assinatura; repetir diagnóstico, salvar dados, reiniciar e verificar compatibilidade.
6. Medir uso de armazenamento, tráfego e tempo de descarga em celulares-alvo.
7. Ajustar workflow release para code 102 e **remover gatilho push**, mantendo workflow_dispatch manual; evitar Actions e Vercel automáticos durante desenvolvimento.
8. Publicar somente após aceite explícito da Alpha pelo responsável.

## Limites deliberados

- Sem atualização silenciosa do Android APK.
- Sem executar código GDScript cru de JSON, URLs arbitrárias ou scripts provenientes de fonte sem assinatura.
- Sem Supabase, Intelligence, login, monetização ou multiplayer nesta etapa.
- Sem carregar patches de core como \`res://scripts/main.gd\`: o mecanismo PCK usa \`replace_files=false\`, e novos sistemas entram como módulos isolados.
- O carregador PCK é fase de plataforma, ainda **não homologado em Godot nem Android**; dependente de chave de assinatura, testes de integridade e protótipo de PCK real.

## Pendências de release (não mascarar como concluído)

- Nenhum APK 0.4.0 foi compilado/instalado ou homologado nesta branch.
- A chave pública OTA ainda precisa ser provisionada em `game/updates/trust/valdora_ota.pub`, com a privada protegida fora do repositório; PCK permanece bloqueado.
- O site v2 existe no Git, mas ainda não está distribuído pelo domínio de produção; portanto, o atualizador retorna modo offline/indisponível até a publicação.
- Godot headless e Android físico não foram executados neste trabalho; os arquivos de teste e workflow apenas preparam a validação.
- Antes do merge de release: atualizar `release-control/version.txt`, preflight para code 102, tornar workflow release somente manual e validar patch assinado com rollback.

## Segurança do workflow de release

O workflow Android nesta branch passa a ser exclusivamente `workflow_dispatch`, não mais `push`, e exigirá `version_code=102` no arquivo `game/release-control/version.txt`. Esse arquivo **permanece com 101 nesta branch**, intencionalmente: o build de release fica bloqueado até validação final e autorização da migração para 0.4.0. O workflow CP004 de testes também é exclusivamente manual.

## Assinatura OTA — material preparado em 08/11/2026

A chave pública RSA-3072 para OTA foi gerada independentemente da assinatura Android, com fingerprint SHA-256 (DER/SPKI) `d88fb6ad0d4787a3820c13238fc86ef3f2bdfffed833492cc47ce6f83b4007ef`. A privada foi depositada na pasta de acesso restrito `Google Drive/Channel/Seguranca - Assinatura Android/VALDORA_OTA_RSA3072_PRIVATE.pem`; **nunca** deve ser adicionada ao GitHub ou aos arquivos públicos da Vercel. Recomenda-se migração futura para cofre/KMS.

O tipo `zip` do Godot é aceito como resource pack, além do `pck`. O primeiro pacote `welcome-1.zip` foi criado sem scripts e assinado com a chave OTA. A assinatura RSA/PKCS#1 v1.5 + SHA-256 foi validada com OpenSSL localmente. Ainda requer prova de montagem no Godot e Android. Publicar `manifest.json` v2 e módulos apenas após teste do pipeline.
