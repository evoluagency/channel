# Valdora — CP002-B · integração dos heróis

Estado: teste funcional do catálogo CP002-A no Godot 4.7.2 e no aplicativo Android isolado.

## Escopo entregue
- Leitura do catálogo original CP002-A (`res://data/valdora_heroes_v0.1.json`).
- Validação de identidade, classe, força, seis atributos e distribuição inicial.
- Fichas de Pietro, Henzo, Giulia e Arthur com aparência, lore e habilidades.
- Interface HERÓIS (aberta a partir da HUD), seleção, 2 espaços de vanguarda e 3 de retaguarda.
- Formação alterável sem duplicação de um mesmo herói e com respeito à posição permitida.
- Persistência dedicada em `user://valdora_hero_roster_v1.json`, não modifica `channel_save.json`.
- Prévia da Temporada 1; desbloqueios cronológicos, níveis, recrutamento real e combate não ativados.
- Botão AUTO TESTE com 17 verificações (12 do CP001 + 5 de heróis).
- Teste automatizado de domínio dos heróis + smoke de cena no Godot.

## Limitações do build
- Não substitui o APK CP001 e não carrega o progresso dele.
- Pacote isolado: `ink.evolu.channel.cp002`. Assinatura debug descartável; não é canal de distribuição final.
- Modelos visuais 3D e combate ainda não foram implementados. O cenário medieval é ambiente técnico provisório.
- Atualizações remotas continuam limitadas a textos JSON do esquema anterior; fichas de heróis neste build são empacotadas no APK.
- Nenhuma integração Supabase ou Intelligence foi adicionada.

## Teste manual Android
1. Instale Valdora CP002 sem remover as versões anteriores.
2. Abra o jogo, toque AUTO TESTE e confira 17/17.
3. Toque HERÓIS; veja os quatro nomes e abra cada ficha.
4. Selecione um herói e escolha um espaço compatível na formação.
5. Tente colocar Giulia na frente (deve recusar); altere a formação e feche.
6. Reinicie o aplicativo e confira se seleção e formação persistiram.
7. Verifique que movimentação, compras, banco e o botão ATUALIZAR seguem funcionais.
