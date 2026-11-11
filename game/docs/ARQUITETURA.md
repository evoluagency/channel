# EVOLU Channel — Arquitetura da primeira versão independente

**Estado:** projeto-fonte Godot. Não é APK compilado nem execução verificada em Android.

> **Nota de 11/11/2026.** Este documento descreve a Alpha 0.1. Desde então o jogo ganhou heróis, combate, cidade e OTA v2 com assinatura RSA-3072. O pacote Android atual é `ink.evolu.valdora`, e não `ink.evolu.channel`. Os limites listados abaixo sobre combate e validação de atualizações estão superados. Veja `ESTADO_DO_PROJETO.md`.

## Decisão técnica
- Godot 4.7.x + GDScript + renderizador Compatibility (OpenGL ES 3), sem plugins proprietários.
- Um setor cenográfico de Valdora feito com meshes primitivos 3D, iluminação, ambiente, praça, fonte, castelo, vias, guilda, mercados e rio.
- Câmera em terceira pessoa, personagem, toque (joystick e interagir), teclado para testar em computador.
- Economia inicial local: 30 moedas iniciais; compras de poções; depósito e saque; persistência em `user://channel_save.json`.
- Sem Minecraft, contas online, servidores, telemetria, pagamentos, login ou dependências cloud.
- **Vercel:** site `channel.evolu.ink`, arquivos de atualização e manifesto versionado quando pertinente; não opera a lógica do jogo.
- **Supabase:** reservado para autenticação, conta e sincronização de progresso em futura fase online; não criar projeto ou SQL agora.
- **GitHub:** histórico e desenvolvimento. Os workflows do Valdora rodam só de forma manual (`workflow_dispatch`); os de checkpoints antigos só disparam nas suas branches históricas. Veja `ESTADO_DO_PROJETO.md`.

## Limites da alpha
- Cenário usa geometria básica de protótipo, não os modelos 3D detalhados da arte de capa.
- Sem combate, IA, quests persistentes, NPCs animados ou multiplayer.
- Ainda não possui mecanismo de download remoto de assets ou validação criptográfica para atualizações.
- Não se deve considerar o motor de jogo testado até executar no Godot e em Android físico.
- Para atualizações de APK, preservar `ink.evolu.channel` e a **mesma chave de assinatura segura**, criada pelo proprietário, fora do GitHub.

## Roadmap executável
1. Fazer o jogo carregar sem erros no editor Godot 4.7.2.
2. Validar controles PC e toque; corrigir UI mobile, colisões, spawn e salvamento.
3. Exportar debug APK, instalar em Samsung e Xiaomi; testar desempenho e permissões.
4. Modelar arquiteturas, texturas, personagens, vegetação e assets originais a partir da direção artística de Valdora.
5. Missão inicial `O Juramento de Valdora`, NPCs com diálogos, inventário completo.
6. Camada de atualização remota de conteúdo, com manifesto HTTPS, checksum/assinatura, atomicidade e rollback.
7. Avaliar servidor autoritativo para multiplayer e Supabase para conta/perfil; não usar Postgres como servidor de jogo em tempo real.