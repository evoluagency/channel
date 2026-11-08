# Valdora — Release 0.4.0-alpha (CP004)
O protocolo CP004 foi validado em Godot headless: contrato, assinatura de ZIP, carregamento de cena, economia/heróis/combate e smoke de UI. O novo APK ainda requer confirmação em Android físico.

- Identidade permanente: `ink.evolu.valdora`; code `102` / name `0.4.0-alpha`.
- Assinatura Android: a MESMA chave privada de release utilizada em 0.3.3, referenciada somente por GitHub Secrets. NÃO reutilizar a chave OTA para assinar APKs.
- Assinatura OTA: RSA-3072 pública em `updates/trust/valdora_ota.pub`, privada em pasta restrita Drive/Channel, nunca GitHub.
- A Vercel distribui `/updates/v2/manifest.json`, e um catálogo com guia declarativo + ZIP assinado.
- No Android, instalar uma vez **sobre** 0.3.3, sem desinstalar. Conferir economia, heróis, arena, novo botão MÓDULOS e atualização OTA.
- Versões posteriores de dados e expansões compatíveis devem dispensar APK, mas atualização nativa Android continua exigindo instalação confirmada.
- Workflow release inicialmente disponível por `workflow_dispatch` e gatilho de push restrito a `game/release-control/build.request`. Esse gatilho só existe para disparo controlado único do CP004; removê-lo depois da exportação.
- Salvamentos: `user://channel_save.json` e `user://valdora_hero_roster_v1.json`. A versão nova não deve migrar/destruir dados.
- O certificado Android deve bater com o fingerprint esperado no workflow; `apksigner` e `aapt` validam assinatura e versionCode.
