# EVOLU Channel — Valdora | Alpha 0.1.2 (Godot)

Protótipo independente de RPG 3D medieval para Android. **Não é mais um Add-on de Minecraft.**

## O que já está no projeto
- Primeiro setor cenográfico de Valdora: praça e fonte, portão do castelo, mercado, banco, ferraria, quartel, árvores, vias e rio.
- Personagem com escudo e câmera em terceira pessoa.
- Controle de movimento via WASD/setas ou joystick virtual Android.
- Interação com mercador e banqueiro, moedas e salvamento local.
- HUD em português e entrada na praça.

## O que ainda não está concluído
- APK compilado, testes em dispositivo, gameplay homologado, renderização na qualidade da concept art, quests, multiplayer, serviços online.

## Para executar
1. Instale o [Godot Engine 4.7.2 Standard](https://godotengine.org/download/archive/4.7.2-stable/).
2. Importe a pasta do projeto no Godot (arquivo `project.godot`).
3. Pressione **F6/F5** para testar a cena inicial.
4. Para Android, instale SDK, templates de exportação da mesma versão do Godot e configure a assinatura. Consulte `docs/EXPORTAR_ANDROID.md`.

## Controles
- PC: **WASD ou setas** para mover; **E** para interagir; **Esc** para fechar o diálogo.
- Celular: arraste o círculo na esquerda; toque **INTERAGIR** perto de um NPC.
- O jogo nasce sempre na praça de Valdora, sem Minecraft.

## Segurança de distribuição
Nunca publique keystore, senhas ou chaves de assinatura no GitHub público. Um novo APK instalado por atualização precisa manter identificador e assinatura. O arquivo `.apk` não pode ser produzido pela mera compactação dos arquivos deste projeto.


## Validação no próprio Android (Godot 4.7.2)

A Godot disponibiliza um **editor para Android** que pode executar este projeto e exportar um APK de teste sem instalar separadamente Android SDK/JDK. Ele é um **aplicativo de desenvolvimento**, não o jogo Channel. Fonte oficial: https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html

1. Instale o [Godot Editor Android 4.7.2](https://godotengine.org/download/android/), da fonte oficial.
2. Extraia este ZIP em uma pasta do armazenamento do celular (por exemplo `Downloads/Channel-Valdora/`). Não abra o ZIP como um projeto sem extraí-lo.
3. No Godot Editor Android, **Importar projeto** → selecione `project.godot`.
4. Execute a cena Valdora (`▶`). Ao aparecer o personagem perto da praça, toque **AUTO TESTE** (exibido nesta versão Alpha também no editor Android). A mensagem deve indicar **9/9 testes OK**.
5. Caminhe até a mercadora e o banqueiro, use **INTERAGIR** e valide diálogos, movimentação e salvamento. Confira a guia `docs/TESTE_ANDROID.md`.
6. Para gerar `Channel-Valdora-alpha.apk`, escolha **Projeto → Exportar → Android** e selecione **Exportar com depuração**. Se o editor solicitar templates, instale os da mesma versão; não use chaves de assinatura públicas.

**Não é um APK pré-compilado.** Não classificamos a versão como homologada até executar o jogo e verificar a exportação em Samsung/Xiaomi.