# Valdora — Canal Android permanente
Situação: preparado para migração única, sem publicação de APK nesta etapa.

## Decisões irrevogáveis após a migração
- Identificador Android permanente: `ink.evolu.valdora`.
- Nome visível: **Valdora**.
- Assinar **todos os próximos APKs** com a mesma chave PKCS12, alias `valdora-release`.
- `version/code` deve crescer monotonamente: 100 → 101 → 102; `version/name` também.
- Compilar com Godot 4.7.2 enquanto esse motor for a referência da série.
- **Não gerar chaves aleatórias em workflows de release**.
- Preservar `user://channel_save.json` para economia; os heróis ficam em `user://valdora_hero_roster_v1.json`.
- Não usar alteração de app ID para simular versões. Não remover dados ou desinstalar o app durante atualizações.

## Etapa humana obrigatória (uma única vez)
A chave privada foi gerada e foi feito backup na pasta privada do Google Drive
`Channel/Seguranca - Assinatura Android/VALDORA_RELEASE_ANDROID.p12`.
O arquivo não é compartilhado publicamente. O backup não fica no GitHub.

Configurar na conta proprietária de `evoluagency/channel`, via
**Settings → Secrets and variables → Actions → New repository secret**:

1. `VALDORA_ANDROID_KEYSTORE_B64`: copie integralmente o texto do arquivo
   **VALDORA_GITHUB_KEYSTORE_BASE64_PRIVADO.txt** disponibilizado em privado.
2. `VALDORA_ANDROID_KEYSTORE_PASSWORD`: copie o valor fornecido no documento
   privado **VALDORA_CREDENCIAL_ASSINATURA_PRIVADA.txt**.

**Jamais colocar esses valores em commits, mensagens, documentação pública, Issues, PRs, logs ou no site.**
Guarde também a senha em gerenciador de senhas seguro. Sem o arquivo e a senha, não será possível
garantir futuras atualizações fora dos mecanismos formais de rotação da loja.

## Publicação controlada
- Workflow GitHub Actions **Valdora - Android release permanente**;
  `workflow_dispatch` manual, sem gatilho de push.
- Código compilado exclusivamente da branch `release/valdora-android`.
- Verificar testes estáticos e runtime antes de obter o Android SDK.
- Exportar usando `--export-release` e secrets, nunca certificado temporário.
- Conferir `aapt` (identificador e versionCode) e `apksigner` (SHA-256 do certificado)
  comparando o fingerprint registrado.
- Publicar o único artefato `Valdora.apk` com SHA256.txt e validade limitada.
- Não distribuir se identidade, assinatura, versão ou testes divergirem.
- O APK só é considerado homologado após instalar, executar 17/17 e confirmar reinício no Android.

## Migração (única)
Os APKs originais possuem os seguintes identificadores e certificados:
- `ink.evolu.channel` — origem anterior; assinatura do aparelho/editor não disponível.
- `ink.evolu.channel.cp001` — certificado temporário CP001.
- `ink.evolu.channel.cp002` — certificado temporário CP002.

O novo `ink.evolu.valdora` será instalado uma vez. O Android **não**
transfere automaticamente os dados privados entre aplicativos de identificadores diferentes.
Por enquanto **mantenha os anteriores instalados até confirmar a nova versão**.
Depois de validar, remova somente os protótipos sem progresso necessário.

## Atualizações de conteúdo x binário
- JSON de diálogos remoto: existente via HTTPS + SHA-256 + cache.
- Modelos 3D, mapas e código GDScript: ainda precisam de novo APK.
- Atualizador de heróis e regras remotas: futuro, exigirá novo contrato validado,
  versionamento, limites, hashes e rollback. Não está implementado nesta etapa.
- Android não concede instalação silenciosa comum por link: novas versões exigem
  confirmação de instalação ou canal gerenciado/loja apropriada.
- Supabase não é necessário para este processo.

## Controle de custos
- O novo workflow é **somente manual**; não executa a cada commit.
- Não aciona Vercel intencionalmente; o site e seus endpoints permanecem inalterados.
- Publicação e retenção de artefatos podem ter quotas e limites de serviço.
