# Channel / Valdora — V-01A: entrega técnica da primeira construção

**Status:** 8 estruturas Bedrock geradas, empacotadas e validadas localmente. **Não homologadas no Minecraft Mobile**.

## Entregue

- `portao.mcstructure`: fachada e torreões do portão do castelo, 33 × 20 × 19 blocos.
- `praca.mcstructure`: praça, fonte decorativa sem água corrente, monumento do guardião, árvores e iluminação, 31 × 12 × 31.
- `mercado.mcstructure`: banco, ferraria, três bancas e iluminação, 30 × 13 × 25.
- `guilda.mcstructure`: salão da guilda, campo de treino e alvos, 30 × 15 × 25.
- `via_nw`, `via_ne`, `via_sw`, `via_se`: máscaras estruturais de vias; só os blocos dos caminhos são alterados.
- `Channel_Valdora_V01A.mcaddon`: instala estruturas e mantém a economia e os itens da versão anterior.
- `/function valdora/construir` para a implantação pelo canto noroeste conforme caderno técnico.
- `/function valdora/construir_centro` para operador ao centro da área, diminuindo distância das estruturas no celular.

## Instalação

Em **mundo plano novo e descartável**, habilite cheats, importe o `.mcaddon`, ative o pacote e fique no **centro de uma área livre 96 × 96**. Execute `/function valdora/construir_centro` uma vez. A região afetada se estende 48 blocos para cada direção, aproximadamente. Como a implantação altera blocos, **não execute em mundos importantes**.

Alternativa fiel ao caderno: pare no canto noroeste e digite `/function valdora/construir`.

O construtor **não** cria um `.mcworld` independente. Uma importação isolada do Add-on não cria a capital automaticamente. Os NPCs customizados, as missões e as classes não estão incluídos.

## Validações executadas

- NBT Bedrock descomprimido, little-endian, decodificado por verificador independente.
- Tamanho de `block_indices` (2 camadas) consistente com dimensões e paleta, todas as estruturas dentro da área 96 × 96.
- Rota de caminhada conectada entre portão, praça, guilda, mercado, banco e ferraria, avaliada sobre blocos de caminhada.
- ZIP externo `.mcaddon` e internos `.mcpack` íntegros; versões de BP/RP `1.2.0` consistentes.
- Sem alteração de UUIDs e IDs técnicos da economia.
- Sintaxe do JavaScript validada com Node; 11 testes simulados anteriores aprovados.

## Pendências para V-01B

1. Importar o pacote num Minecraft Bedrock real e verificar mensagens de log e disponibilidade do comando.
2. Construir na área de teste e registrar capturas reais diurnas/noturnas, colisões e posição do personagem.
3. Verificar materiais e estados dos blocos (especialmente as folhas persistentes e a versão da paleta NBT).
4. Ajustar conforme os problemas observados e só então produzir `.mcworld` homologado.
5. Integrar NPCs e regras comerciais na V-01C, separadamente.

**Segurança de versão:** manter o pacote V1.1 anterior disponível. A V-01A é uma compilação experimental, não substitui o download estável no site até conclusão da homologação.

**Infraestrutura:** nenhum GitHub Action, workflow, cron, job, migration, Supabase, Vercel ou hospedagem externa foi criado por esta implementação.