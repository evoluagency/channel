# Valdora PvP — diagnóstico e evolução gráfica (15/11/2026)

## Base inspecionada

- Cinco arenas PvP construídas sobre `game/data/pvp/mapas_v0.1.json`.
- Cenários regionais e estabelecimentos procedurais em `visual/cenario.gd`, usando malhas unificadas por material (`visual/construtor.gd`).
- Projeto com renderer GL Compatibility, referência de layout 1280×720, stretch `canvas_items`; nenhum MSAA 3D declarado antes deste ajuste.
- A aba **Ajustes > Vídeo** exibia opções sem aplicação real.
- Materiais do chão, concreto, metal e vegetação usam frequências procedurais elevadas, sujeitas a cintilação ao mover a câmera.
- A qualidade artística é estilizada, mas ainda tem geometria e UI majoritariamente desenhadas por código; não se iguala, apenas por resolução, ao acabamento de um jogo comercial como Last War.

## Implementado nesta branch

1. **Resolução 3D nativa:** mantém `canvas_items`, escala 100% por padrão e aspecto expansível para telas Android de proporções diferentes. A base 1280×720 continua sendo somente a referência do layout, não um alvo 3D fixo.
2. **Antisserrilhamento:** MSAA 3D 2× por padrão; 4× ao escolher Alta; desativado em Baixa. GLES3/Compatibility mantido por suporte a aparelhos existentes.
3. **Detalhamento em movimento:** filtro derivativo (`fwidth`) em padrões de ruído de grama, terra, asfalto, concreto e ondulação metálica para atenuar detalhes subpixel.
4. **Nitidez de letreiros:** fonte 3D com atlas interno ampliado e dimensão física preservada.
5. **Vídeo funcional e persistente:** qualidade Baixa/Média/Alta; limite 30/60/90 fps; sombras ligadas/desligadas; resolução 75%/100%. Valores salvos em `user://valdora_video.cfg`, aplicados ao abrir e alteráveis em Ajustes.
6. **Sombreamento:** sombras das luzes direcionais dos cinco cenários passam a respeitar a preferência de vídeo.
7. **Regressão:** criado `game/tests/test_pvp_visual_quality.py`, incluído como validação estática no workflow **manual** de release Android.

## Não alterado

- Geometria de colisão, layout de rotas, regras de equilíbrio, dados dos cinco mapas, nomes ou conteúdo das arenas.
- APK, assinatura, versionCode, OTA de conteúdo, sistema de atualização de APK, branch principal e Vercel.
- Não foram executados builds nem Actions com estes ajustes.

## Protocolo de homologação visual

Usar o APK gerado da branch de desenvolvimento, quando houver autorização de release:
1. Nos cinco mapas, comparar três vistas em primeira pessoa e uma vista aérea por mapa (`game/tests/pvp_cenario_capturas.gd`).
2. Confirmar nitidez de bordas de prédios, fios/grades, placas de loja e padrões no solo durante movimento; observar cintilação.
3. Em dois Androids de hardware diferente, comparar Média/100%/60 com Alta/100%/60 e Baixa/75%/30. Anotar FPS real, fluidez, aquecimento e travamentos.
4. Conferir layout em 16:9 e proporções alongadas, incluindo HUD, mira, joystick e botões de ação; nenhum botão pode sair da tela.
5. Reiniciar o jogo e verificar persistência das configurações de vídeo e os cinco mapas jogáveis.
6. Conferir que atualizações OTA do conteúdo continuam funcionando, sem alterar o pacote Android automaticamente.

## Limites e próximo eixo gráfico

Ajustes de MSAA, escala e shaders aumentam a nitidez técnica e a estabilidade visual, mas **não recriam o padrão artístico, iluminação, personagens, animações e assets 3D** de Last War. Para se aproximar desse acabamento, o próximo eixo deve focar modelos próprios com silhuetas mais refinadas, materiais estilizados consistentes, gradação de cor, animações, VFX e telas do menu — sem copiar recursos protegidos de outro jogo.

A execução do smoke Godot e as medições reais de FPS **ainda são pendentes**; este documento não declara homologação da nova qualidade gráfica.
