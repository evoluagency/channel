# Exportação Android — EVOLU Channel

## Requisitos
- Godot Engine 4.7.2 Standard instalado no PC.
- Templates de exportação da **mesma versão** do Godot.
- Android SDK e Java SDK configurados no editor; a documentação recomenda JDK 17, embora versões superiores possam funcionar.
- Configuração de exportação presente em `export_presets.cfg` para `arm64-v8a` e `ink.evolu.channel`.

## Primeiro protótipo para testes
1. Abra `project.godot` no Godot e execute F5.
2. Corrija erros de importação/GDScript, caso existam, antes de exportar.
3. Vá a **Projeto > Exportar** e selecione **Android**.
4. Instale os templates e indique caminhos de Android SDK/Java SDK nas preferências do editor.
5. Exporte como **debug APK** para `dist/Channel-Valdora-alpha.apk`.
6. Instale manualmente no telefone e permita instalação da origem escolhida, seguindo os avisos do Android.

**Atenção:** para distribuição pública com futuras atualizações sem desinstalar, crie uma chave de assinatura de release segura no seu computador e **guarde-a**. Não distribua permanentemente um APK assinado com chaves temporárias/de debug. O ID de pacote é `ink.evolu.channel`.

## Compilação em linha de comando (apenas após configurar o ambiente)
```
godot --headless --path . --editor --quit
godot --headless --path . --export-debug Android dist/Channel-Valdora-alpha.apk
```

Para Google Play, use Android App Bundle (`.aab`) assinado, conforme a documentação atual. Para download em `channel.evolu.ink`, distribua um APK de release devidamente assinado, acompanhado de tamanho, versão e SHA-256.

Referências:
- https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html
- https://developer.android.com/games/engines/godot/godot-export