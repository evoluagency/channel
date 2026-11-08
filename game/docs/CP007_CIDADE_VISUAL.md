# Valdora — CP007: evolução visual da cidade (módulo OTA)

## Escopo concluído na proposta de módulo
- Conteúdo Cidade v4, sem novo APK; arquivo de atualização `site/updates/v2/modules/city-4.zip`, manifesto rev. 5 (client mínimo 102).
- Interface azul-marinho/dourada; painel de territórios com nome, estruturas e níveis do lote selecionado; barra de construção com rolagem horizontal; indicação explícita de **CIDADE v4** (versão de conteúdo, não versão do aplicativo).
- Novo modo **INSPECIONAR** não consome recursos nem altera o save.
- Objetivos de progresso derivados do estado salvo: nomeação → fundação → casa → fazenda → serraria → pedreira → torre.
- População visualmente estimada a partir das casas, sem criar recursos econômicos, recompensas ou NPCs reais.
- Cenário isométrico gerado por primitivas leves: relevo em camadas, água com animação discreta, rochas, árvores adicionais, lavouras, detalhes específicos de prédios e bandeiras.
- A escrita continua em `user://valdora_city_cp005_v1.json` com schema 1 e mesmos custos, mapa, construções e regras.

## Limites e conformidade
- A versão 0.4.0 mostrada pelo HUD legado é texto do APK Android anterior e não é alterada por módulos online.
- Clientes com APK 0.4.0 baixam ZIPs automaticamente, mas podem precisar reiniciar para ativar cena atualizada. A base 0.4.1 acrescenta hot activation. O ideal é instalar 0.4.1 **por cima** para manter saves.
- CP007 não contém IA, multiplayer, política, estados, países, monetização ou mudanças de backend.
- O render segue 2.5D estilizado de baixo custo, não uma réplica 3D fotorealista da imagem de referência; desempenho físico Android ainda requer homologação.

## Critérios de aceite
1. Pacote zip assinado RSA-3072 validado com chave pública e SHA-256; nenhum arquivo fora de `valdora_modules/city/`.
2. Godot carrega a cena e smoke `cp007_city_visual_smoke.gd` passa, incluindo modo inspeção, população derivada, objetivos e preservação de schema.
3. Outras suítes CP001–CP006 preservadas e workflow retorna ao modo manual após one-shot.
4. Publicação do manifesto na Vercel e respostas HTTP 200 verificadas.
5. Aprovação visual e fluidez no Android pelo usuário antes de considerar o próximo checkpoint fechado.
