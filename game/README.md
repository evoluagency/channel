# EVOLU Channel — Valdora | Alpha 0.1 (Godot)

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