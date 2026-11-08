# VALDORA — CP005: Cidade individual e territórios (primeira entrega)

**Base:** GDD mestre v0.4.1; imagem de referência de mapa estilizado mobile aprovada pelo usuário.
**Situação:** módulo para homologação, independente do aplicativo-base Android 0.4.0.

## Entrega

- Novo pacote ZIP Godot carregável pelo CP004: `res://valdora_modules/city/entry.tscn`.
- Mapa isométrico 2.5D de 12 × 10 lotes, renderizado com primitivas leves em vez de textura cinematográfica estática.
- Camadas territoriais visuais: centro urbano, campos férteis, bosque de madeira, pedreira/mina, rio/doca, ruínas, vila artesã e área de vigilância.
- Jogador define o **nome da sua cidade** (Valdora permanece o nome do mundo).
- Fundação inicial e cinco edifícios colocáveis: casa, fazenda, serraria, pedreira e torre; seleção de lotes e validação territorial.
- Recursos experimentais independentes (madeira/pedra), consumo validado e proibição de duplicidade de construção.
- Pan por arrasto e zoom com botões, rolagem e gesto de ampliação.
- Save próprio versionado `user://valdora_city_cp005_v1.json` com verificação, escrita temporária e backup, sem escrever em `channel_save.json` nem no roster CP002.
- Interface responsiva no layout paisagem 1280 × 720 do app, aberta pelo botão **MÓDULOS** após download e reinício.

## Limites explícitos

Não é ainda um mundo 3D definitivo: é uma fatia jogável isométrica com geometria simples gerada por código. Não integra a economia legado, não simula produção contínua, não gera população real, não executa missões, não cria estados/países e não habilita multiplayer. Escolha de cidade não implica reserva de nome global. A imagem aprovada orienta forma, leitura e cores; novos modelos 3D finais serão objeto de expansão.

## Publicação segura

O ZIP é assinado com a **chave OTA RSA-3072 existente** (nunca a chave Android). A atualização incrementa a revisão do manifesto v2 sem alterar módulos já ativos nem o aplicativo-base. O aplicativo baixa os arquivos e indica que novas cenas precisam de reinício. A cena aparece como **Minha cidade · CP005** no painel MÓDULOS. O rollback de módulo preserva o save dedicado.

## Critérios de homologação

1. `Godot 4.7.2` carrega e instancia o pacote ZIP, executa o teste `game/tests/cp005_city_smoke.gd` sem erros.
2. Manifesto, tamanho, SHA-256 e assinatura RSA conferem com chave pública fixada no APK.
3. No Android físico: nome da cidade, fundação, construção, recursos, pan, zoom e save após fechar/abrir.
4. Módulo antigo e saldos/heróis/combate anteriores não sofrem alteração.
5. Medir FPS, RAM e legibilidade no aparelho antes de tratar esta visualização como identidade final 3D.

**Fora de escopo:** APK novo, novos serviços Vercel, Supabase, multiplayer, automações recorrentes e disparo automático de Actions.