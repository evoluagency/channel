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


---

## Eixo 2 — Esplanada como mapa-piloto de direção de arte (15/11/2026)

**Decisão de arquitetura:** preservar o mapa PvP, a física, as rotas A/B e o motor
que já funcionam no Android. Criar uma segunda camada exclusivamente visual,
carregada **apenas** quando `mapa.id == "esplanada"`.

### Peças implementadas
- **Pavimentação:** padrão de ladrilhos claros, alternância sutil de placas e
  juntas com baixa frequência, sem ocultar marcas de objetivos/rotas.
- **Fachadas:** janelas mais profundas, brises ritmados, marquises, coroamento
  e volumetria nas laterais dos edifícios; só sobre footprint de paredes `#`.
- **Coberturas e floreiras:** molduras de quiosques, vidraças e vegetação
  volumétrica adicional; toda a base já possui cobertura `c` e colisão.
- **Entorno externo:** espelho d'água, guias de pedra, árvores de cerrado em
  camadas e acabamento das torres distantes, todos fora da área de combate.
- **Colunata escultórica:** primitiva procedural de pilares genuinamente curvos
  (`construtor.gd::coluna_curva`), com teto e profundidade no entorno externo,
  sem colisores ou importação de modelos protegidos.
- **Atmosfera:** iluminação ambiente e neblina calibradas apenas na Esplanada
  para reduzir saturação excessiva e melhorar separação entre planos.
- **Qualidade móvel:** geometria unificada por material pelo construtor,
  nível de detalhes menor na configuração Baixa e maior na Alta.

As proporções e a linguagem de concreto, brises e espelho d'água foram usadas
como referências *arquitetônicas*, sem copiar fotografias, modelos ou materiais
de terceiros. A identidade visual e a composição de jogo continuam próprias.

### Arquivos e integração
- `game/scripts/pvp/visual/esplanada_acabamento.gd` — camada visual modular;
- `game/scripts/pvp/visual/cenario.gd` — gancho exclusivo da Esplanada;
- `game/tests/test_pvp_esplanada_visual.py` — regressão estática;
- `.github/workflows/valdora-android-release.yml` — inclui a regressão
  no workflow de release **manual**, sem execução automática.

### Homologação ainda necessária
1. Executar a regressão local, seguida do Godot em modo de testes.
2. Gerar as quatro capturas da Esplanada pelo script
   `game/tests/pvp_cenario_capturas.gd -- --saida=PASTA --mapa=esplanada`.
3. Conferir próxima à câmera o contorno de marquises, brises e vegetação;
   conferir se nenhum detalhe mascara A/B, rotas ou linhas de tiro.
4. Medir FPS e estabilidade em Android de entrada e intermediário nos
   perfis Baixa, Média e Alta; comparar com o mapa original.
5. Verificar que as outras quatro arenas não receberam geometria nova.

**Limite do escopo:** é um avanço concreto na direção de arte, mas ainda não
representa fidelidade idêntica à de Last War. Modelos 3D autorais, animações,
VFX e tratamento de personagem continuam sendo etapas distintas. Não gerar
release nem acionar workflows antes de homologar os ajustes visualmente.
