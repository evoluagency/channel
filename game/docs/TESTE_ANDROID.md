# EVOLU Channel — execução real no Android (Alpha 0.1.2)

**Objetivo:** executar o motor Godot e exportar um APK **real**, sem Minecraft e sem serviços pagos. O código ainda não foi executado no Godot nesta sessão; nenhum APK foi gerado/homologado.

## O que está preparado

- `project.godot`: abre a cena `scenes/Main.tscn` no renderizador Compatibility.
- `export_presets.cfg`: exportação Android para arm64-v8a **e** armeabi-v7a (amplia a compatibilidade), ID `ink.evolu.channel`, versão 0.1.1 (código 2).
- `scripts/main.gd`: Valdora com entrada no setor da praça, NPCs e economia local. Fachadas com passagens físicas abertas, sem colisão fictícia nas portas.
- Botão **AUTO TESTE**: na versão Alpha, inclusive no editor Android, verifica nascimento dentro do reino, personagem, câmera, quatro NPCs, comerciante, banqueiro, saldos, interface e gravação local (9 verificações). Registra `CHANNEL_DIAGNOSTIC` no console.
- `tests/smoke.gd`: teste automatizado que instancia a cena no próprio Godot, verifica diálogos sem transações e retorna código de saída 0/1. Não altera saldos do jogador.

## Caminho sem computador: Godot Editor Android

1. Instale a versão 4.7.2 do [Godot Editor para Android](https://godotengine.org/download/android/) ou sua página oficial na Google Play.
2. Descompacte `EVOLU_Channel_Valdora_Godot_Alpha011.zip` na pasta Downloads (precisa conter `project.godot` na raiz da pasta extraída).
3. No Godot Android, permita acesso aos arquivos e **Importar** → localize `project.godot`.
4. Execute o projeto. Se aparecer erro de código no painel inferior, registre o texto exato do erro e a linha; não considere o build aprovado.
5. Se o jogo iniciar, toque **AUTO TESTE** e verifique se aparece `VALDORA: 9/9 testes OK`.
6. Movimente o personagem até os NPCs; teste compra de poção, depósito e saque; feche o jogo, abra novamente e confirme os saldos.
7. No editor, **Projeto → Exportar → Android**, instale os templates correspondentes se solicitados e exporte **Debug APK**. A documentação 4.7 não exige Android SDK/JDK separados ao exportar dentro do editor Android. Se houver limitação específica do aparelho, use um computador com Godot e Android SDK.
8. Instale o APK exportado como um aplicativo separado do Godot Editor. Teste o mesmo APK em Samsung e Xiaomi.

**Atenção:** o editor Godot para Android está em *early access*; a interface é pouco otimizada para telefones. Exporte primeiro uma compilação de depuração. Não publique um APK de produção assinado com chave de teste nem compartilhe keystores privados.

## Caminho por computador / terminal

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --export-debug Android dist/Channel-Valdora-alpha.apk
```

Para exportar em Linux/Windows/macOS, é necessário instalar os templates da versão 4.7.2 e preparar as ferramentas Android conforme a [documentação oficial](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html).

## Critérios mínimos de aceite

| Caso | Evidência requerida |
|---|---|
| Inicialização | Cena sem erros de parser e sem exceções na inicialização |
| Nascimento | Personagem visível na praça, sem colisão inicial |
| Controles | Movimentação joystick e interação por toque |
| Arquitetura | Portas do banco/guilda permitem entrar fisicamente |
| NPCs | Mercadora, banqueiro, ferreiro e guarda visíveis |
| Economia | Compra, depósito e saque sem valores negativos |
| Persistência | Saldo salvo após fechar e reabrir |
| Compatibilidade | APK executado em Samsung e Xiaomi reais |

## Limites de compatibilidade

Habilitar arm32 e arm64 aumenta a cobertura de dispositivos, mas **não significa compatibilidade com todos os Androids**; GPU, versão Android, memória e drivers também importam. A incompatibilidade de abertura de arquivos `.mcaddon` no Xiaomi deixa de ser relevante para um jogo independente, mas precisamos testar o APK próprio.

## Fontes oficiais

- [Godot 4.7: editor para Android](https://docs.godotengine.org/en/4.7/tutorials/editor/using_the_android_editor.html)
- [Godot 4.7: exportando para Android](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html)