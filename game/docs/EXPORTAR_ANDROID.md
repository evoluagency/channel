# EVOLU Channel — Exportação Android, Alpha 0.1.1

Esta é uma aplicação **Godot independente**. Ela não depende do Minecraft.

## A. Exportar pelo Godot Editor no Android (sem PC)

1. Instale o **Godot Editor 4.7.2 para Android** (editor oficial, ainda em early access): https://godotengine.org/download/android/
2. Descompacte o projeto ZIP. Importe o `project.godot` no editor; permita acesso aos arquivos conforme solicitado.
3. Execute a cena usando ▶ e confirme que Valdora abre sem erros. Toque **AUTO TESTE**; resultado esperado: `VALDORA: 9/9 testes OK`.
4. Acesse **Projeto → Exportar**, escolha o preset **Android** do projeto, instale os templates oficiais 4.7.2 se o editor solicitar, selecione **Debug** e salve o APK.
5. Instale o APK em outro celular e teste como um aplicativo independente.

**Godot 4.7:** o editor Android pode exportar o jogo sem instalar separadamente Java SDK/Android SDK. Para exportação com Gradle, siga os passos adicionais da documentação oficial. Não confunda o APK do *Godot Editor* com o APK do *EVOLU Channel*.

Referência: https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html

## B. Exportar pelo Godot no computador (Windows/Linux/macOS)

- Instale **Godot Engine 4.7.2 Standard** e seus templates de exportação correspondentes.
- Configure OpenJDK 17 e Android SDK nas preferências do editor. A documentação oficial especifica versões dos componentes Android; siga-a em vez de instalar SDKs arbitrários.
- Abra `project.godot` e execute a cena. Após corrigir erros de importação/GDScript, verifique o teste automatizado no motor.
- Exporte o preset Android como APK de depuração em `dist/Channel-Valdora-alpha.apk`.

Com ambiente preparado, comandos:

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --export-debug Android dist/Channel-Valdora-alpha.apk
```

## Assinatura e distribuição

- ID do aplicativo: `ink.evolu.channel`.
- Versão do projeto: 0.1.1, código Android: 2.
- Arquiteturas selecionadas para exportação: arm64-v8a e armeabi-v7a. Isso amplia a cobertura, sem garantir compatibilidade universal.
- APK de depuração serve para testes, **não** para distribuição pública permanente.
- APK de produção exige assinatura de release com chave privada mantida pelo proprietário fora do GitHub. Para atualização sem desinstalação, devem ser preservados o identificador e a chave de assinatura.
- Para Play Store, a publicação inicial de novos apps deve seguir a exigência de AAB.
- Não publicar um arquivo `.zip` renomeado para `.apk` e não afirmar que houve teste Android antes da instalação em dispositivos reais.

Referência: https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html