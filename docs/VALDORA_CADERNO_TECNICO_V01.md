# EVOLU CHANNEL | VALDORA
## Caderno técnico executivo de construção — V-01 / Revisão 1

**Estado:** especificação de implementação aprovada para início do *vertical slice* arquitetônico. Documento normativo para o primeiro núcleo de Valdora. Os elementos descritos como **futuro** não são apresentados como funcionalidades concluídas.

**Destinação:** GitHub `evoluagency/channel` (código e arquivos de fonte, sem Actions, workflows, jobs, migrations ou cron); Minecraft Bedrock para execução local; Vercel somente para site público de download manual; Google Drive para cópias de versões. **Sem custos incrementais contratados.**

**Idioma/identidade:** PT-BR, marca de texto `EVOLU CHANNEL` com Montserrat; nenhum símbolo novo de logomarca. A coroa, escudo e emblemas usados *dentro do reino* são heráldica ficcional, **não** substituem a marca EVOLU. A arte da capa define clima e materiais, não a renderização final garantida do Minecraft. A referência de fantasia medieval é temática; não reproduzir personagens, nomes, narrativas, uniformes ou brasões de terceiros.

---

## 1. Objetivo, princípios e escopo de entrega

Valdora é o primeiro país do universo Channel. Sua capital serve de entrada para o RPG, ponto de apoio econômico e introdução às futuras guildas/classes. A **V-01** deve produzir um setor compacto e caminhável que seja reconhecível visualmente, possa ser instalado em Minecraft Bedrock Mobile e permaneça independente de qualquer backend.

### 1.1 Escopo do primeiro setor

| Área | Identidade | Produto construído na fase V-01A | Função jogável prevista |
|---|---|---|---|
| Praça Central | Ponto de chegada e memória do reino | piso, caminhos, fonte, estátua, iluminação e jardins | orientação, chegada, início de missão |
| Mercado Real | Núcleo econômico | fachada/interior do banco, ferraria, bancas e vias | mercador, ferreiro, banqueiro; compras/vendas |
| Quartel e Guilda | Progressão e treinamento | salão, arsenal cênico, pátio e alvos | exposição de classes e missões futuras |
| Portão do Castelo | Fronteira monumental | muralhas, passagem, guaritas, torres e bandeiras | conexão para castelo e expansão |
| Rede viária | Continuidade do percurso | conexões sinalizadas entre os quatro módulos | navegação acessível entre edifícios |

**V-01A (começo da construção):** construir arquivos estruturais reais `.mcstructure` de cada setor, um instalador/importador em pacote de comportamento e um roteiro de implantação em mundo de teste. Os elementos **NPCs customizados, missão programada, classes e mundo `.mcworld` pronto para importação** permanecem em etapas subsequentes, após testes no jogo.

### 1.2 Fora do escopo inicial

Reprodução exata dos gráficos da capa, substituição de todos os blocos por malhas orgânicas, criação de servidor hospedado, comércio com dinheiro real, diplomacia e guerras, importação automática sem consentimento, criação de NPCs com IA externa, sincronização de banco com Supabase/Vercel, loja oficial Minecraft Marketplace.

---

## 2. Território, coordenadas e implantação

### 2.1 Sistema de referência

- **Área-base:** 96 blocos em X por 96 blocos em Z, setor local `[0..95] × [0..95]`, altura de fundação local `Y=0`.
- **Norte:** direção `-Z`. **Leste:** `+X`. Construções posicionadas na dimensão **Overworld**.
- **Origem absoluta:** configurável no mundo de teste. A tabela adota `P=(X0, Y0, Z0)` como canto noroeste do setor. No exemplo operacional do guia: `P=(0,64,0)`; posicionamento em outros mundos soma os deslocamentos a P.
- **Y0:** nível da camada de fundação. Caminhada principal a `Y0+1`; o jogador fica em `Y0+2` quando sobre piso completo. Essa fundação foi projetada para **mundo plano controlado**, não para ser inserida automaticamente sobre terrenos irregulares.
- **Implantação somente mediante ação manual do operador**, após backup e escolha de um mundo descartável. Não gerar estruturas no `playerSpawn` e não substituir silenciosamente blocos existentes.

### 2.2 Implantação geométrica vinculante

| Módulo | ID de estrutura | X local | Z local | Dimensões X×Y×Z | Limites |
|---|---|---:|---:|---|---|
| Portão do Castelo | `channel:valdora/portao` | 31 | 2 | 33×20×19 | X31–63, Z2–20 |
| Praça Central | `channel:valdora/praca` | 32 | 32 | 31×12×31 | X32–62, Z32–62 |
| Mercado Real | `channel:valdora/mercado` | 65 | 35 | 30×13×25 | X65–94, Z35–59 |
| Quartel e Guilda | `channel:valdora/guilda` | 1 | 35 | 30×15×25 | X1–30, Z35–59 |
| Vias (quadrantes) | `channel:valdora/via_nw` etc. | 0 / 48 | 0 / 48 | 48×3×48 | quatro quadrantes 48×48 |

**Relação com edificações:** os quatro quadrantes da malha viária são máscaras de posicionamento: somente as posições expressamente desenhadas recebem blocos; as demais são *structure void* (`-1`) e não alteram o local. Aplicar vias **antes** dos edifícios para evitar sobreposição de caminhos nas fachadas. A geometria dos edifícios terá prioridade na interseção.

### 2.3 Planta urbana funcional

```text
                            NORTE  (-Z)
            +---------------------------------------+
            |      MURALHAS / PORTÃO REAL            |
            |              [31,2]                  |
            |                  ||                   |
            |                  ||                   |
 OESTE      | GUILDA ===== PRAÇA CENTRAL ==== MERCADO|  LESTE
 (-X)       |[1,35]      [32,32]       [65,35]     |  (+X)
            |                  ||                   |
            |                  ||                   |
            |             ESTRADA SUL              |
            +---------------------------------------+
                           SUL  (+Z)
```

Reserva de expansão fora do setor: castelo ao norte, distrito arcano a oeste, artesãos/comércio a leste, estradas para aldeias e fronteiras ao sul. **Não** assumir que o país inteiro cabe nos 96×96 blocos; este é o setor de homologação da capital.

---

## 3. Manual arquitetônico e paleta

### 3.1 Direção de arte

Fantasia medieval de aventura, materiais luminosos, muralhas claras e contraste entre madeira escura, telhados aconchegantes e roxo heráldico. A imagem de referência é arte conceitual inspiradora; não exigir que o jogo replique iluminação, montanhas ou polígonos de renderização da capa.

### 3.2 Materiais prioritários (blocos vanilla)

| Grupo | Blocos candidatos | Aplicação |
|---|---|---|
| Pedra estrutural | `stone_bricks`, `polished_diorite`, `polished_andesite`, `chiseled_stone_bricks` | muralhas, coluna, fundações e caminhos |
| Variação histórica | `mossy_stone_bricks`, `cracked_stone_bricks`, `cobblestone` | desgaste discreto, pisos e bordas |
| Madeira | `dark_oak_planks`, `spruce_planks`, `oak_planks` | estruturas, telhados em degraus, bancadas |
| Heráldica | `purple_wool`, `purple_concrete`, `yellow_wool`, `gold_block` | bandeiras, escudo estilizado e detalhes |
| Luz e vidros | `glowstone`, `glass`, `blue_stained_glass`, `sea_lantern` | iluminação e fonte simulada |
| Paisagismo | `grass_block`, `oak_leaves`, `moss_block` | canteiros, copas e jardins |
| Comércio | `bookshelf`, `crafting_table`, `furnace`, `anvil` | interiores funcionais/decorativos |

**Regra:** dar preferência a blocos vanilla amplamente suportados. Blocos com estados direcionais deverão ter permutações explicitamente verificadas antes do aceite. A primeira construção pode usar telhados em degraus de blocos inteiros para reduzir incompatibilidade entre versões.

### 3.3 Qualidade e desempenho mobile

- Silhueta distintiva de cada edifício a 20–30 blocos; referências visuais por cor e altura.
- Circulação principal com pelo menos **3 blocos de largura**, com ar livre acima (mínimo 3 blocos de altura).
- Evitar excesso de entidades, partículas contínuas, loops a cada tick, iluminação dinâmica simulada e centenas de block entities.
- Preferir sinalização sem texto como elemento físico na etapa V-01A; textos/localização por UI ou painel quando implementados.
- Construir em módulos pequenos e independentes; a composição final não deve provocar alterações fora de X0..X0+95 e Z0..Z0+95.

---

## 4. Fichas construtivas dos ambientes

### 4.1 Praça Central — `channel:valdora/praca`

**Implantação:** X32–62, Z32–62. **Altura:** 12 blocos. **Piso:** plataforma de pedra clara com centro marcado, base na camada Y0, circulação Y0+1.

**Elementos obrigatórios:**

1. Átrio aberto com pavimento de pedra e desenho de orientação nos quatro eixos.
2. Fonte monumental de aproximadamente 9×9 blocos, com bordo de pedra, água cenográfica em blocos azulados e luz discreta. Se água real for introduzida, ensaiar fluxo e isolamento antes da publicação.
3. Monumento de um guardião com escudo **original**, construído em blocos; não usar personagens licenciados.
4. Quatro canteiros com área verde, árvores baixas/copa contida e assentos.
5. Quatro postes ou pilares de iluminação, protegidos contra colisões.
6. Entradas livres nos quatro lados para mercado, guilda, castelo e estrada sul.

**Interior:** não se aplica; é espaço público aberto. **Interações V-01C/D:** marcador de chegada, mural de missões e início do “Juramento de Valdora”. **Aceite arquitetônico:** circulação sem obstáculos; monumento e fonte reconhecíveis; sem spawn dentro de água/parede; iluminação noturna suficiente.

### 4.2 Mercado Real — `channel:valdora/mercado`

**Implantação:** X65–94, Z35–59. **Altura:** 13. **Linguagem:** térreo comercial com stone/wood, telhados escuros e acentos roxos.

**Programa e interiores:**

- **Banco de Valdora:** edifício de 11×10 blocos aproximados; piso de pedra, balcão, área reservada e cofre cenográfico. O saldo real será gerido pelas propriedades dinâmicas do jogador, não por itens guardados em baús públicos.
- **Ferraria:** edifício de 11×10 aproximados; forno, bancada e bigorna; vitrine de equipamentos. Não espalhar fogo real que possa incendiar estruturas.
- **Bancas gerais:** três bancas com coberturas roxas e amarelas, expositores de produtos, circulação central livre.
- **Armazém de apoio:** canto de estocagem cenográfico e rota de serviço sem interferir na praça.

**NPCs V-01C:** banqueiro, ferreiro e mercador geral em posições estáveis, registrados por identificador/tag para evitar duplicações ao recarregar o mundo. **Economia:** o código do protótipo atual dispõe de carteira digital, moedas físicas e banco, mas a loja existente opera **somente saldo digital**. Pagamento misto em NPCs será implementado e testado em etapa específica, sem antecipar que já funciona.

**Aceite:** três postos claramente distinguíveis, acesso pelo oeste, passagem interna sem colisão, nenhum baú com moeda infinita e nenhuma entidade duplicada em reinícios.

### 4.3 Quartel e Guilda — `channel:valdora/guilda`

**Implantação:** X1–30, Z35–59. **Altura:** 15. **Linguagem:** muralha baixa, madeira escura, banners heráldicos e área de treino.

**Programa e interiores:**

- **Salão dos aventureiros:** recepção, mesa de missões, livros cenográficos e bancos.
- **Arsenal:** decoração com forja leve/armaduras em suportes futuros; não dar itens de alto valor gratuitamente.
- **Campo de arquearia:** ao menos três alvos estáticos, faixa de disparo delimitada, barreira posterior e circulação independente.
- **Pátio de treino:** espaço para espadas e escudos, sem mobs hostis na área inicial.
- **Dormitório simplificado:** nicho reservado para ampliação; não requer camas interativas na primeira construção.

**Classes futuras:** caçador, escudeiro, arqueiro, explorador, minerador, bruxo e mago. Cada classe terá equipamento, progressão, habilidades, saldo de energia e persistência definidos em documento separado antes de executar. **Nenhuma escolha de classe funcional na V-01A.**

**Aceite:** entrada lateral conectada à praça; alvos/arsenal distinguíveis; área de treino sem criação automática de mobs; boa navegação em toque.

### 4.4 Portão do Castelo — `channel:valdora/portao`

**Implantação:** X31–63, Z2–20. **Altura:** 20. **Linguagem:** pedras claras, torres simétricas, banners roxos, detalhes dourados.

**Programa:**

- **Dois torreões** com parapeitos e base maciça; nenhum acesso ao alto é obrigatório na V-01A.
- **Passagem central** com vão livre de pelo menos 5 blocos de largura e 5 de altura, atravessando a muralha.
- **Muralhas e ameias** em ambos os lados, sem escadas abertas perigosas para novos jogadores.
- **Guaritas** para personagens futuros e painel de orientações do reino.
- **Estandartes** de Valdora; heráldica original, distinta da marca EVOLU.

**Interação futura:** controle narrativo de acesso ao castelo, não bloqueio técnico irreversível. **Aceite:** passagem desobstruída e legível, perspectiva monumental a partir da praça, ausência de queda acidental por ponto de spawn.

### 4.5 Rede de vias

- Eixo norte-sul: ligação Portão → Praça → Estrada Sul, em X46–49 aproximadamente.
- Eixo oeste-leste: Guilda → Praça → Mercado, em Z46–49 aproximadamente.
- Materiais: polido, pedra e bordas discretas, com 4 blocos de largura preferencial nos eixos.
- As vias externas aos módulos são máscaras `.mcstructure` separadas em quatro quadrantes de 48×48. **Não** projetar vias destrutivas através de construções previamente existentes.

---

## 5. Personagens, economia e estado do jogo

### 5.1 Modelo de NPCs

| NPC (nome proposto) | Local | Função pretendida | Estado V-01A |
|---|---|---|---|
| Orin, o Mercador | Banca central do Mercado | vender básicos e comprar recursos | cenário reservado; entidade não criada |
| Dália, a Ferreira | Ferraria | equipamentos, futura manutenção | cenário reservado; entidade não criada |
| Soren, o Banqueiro | Banco | depósitos, saques, câmbio físico/digital | cenário reservado; entidade não criada |
| Capitã Miren | Quartel | introdução a classes e treinamento | futuro |
| Vigia do Portão | Portão do Castelo | informação e passagem narrativa | futuro |

### 5.2 Princípios econômicos para a fase interativa

- A moeda de conta é única na V-01 (sem câmbio entre países). Saldo digital em carteira, saldo bancário e itens físicos separados.
- Os IDs técnicos da base inicial (`erpg:*`) permanecem por compatibilidade, apesar de os textos exibirem somente “Channel”. Não reinicializar saldos existentes ao instalar os novos cenários.
- Operações `comprar`, `vender`, `depositar`, `sacar`, `transferir` devem validar saldo, inventário, limites e resultado no mesmo contexto de execução; testar falhas intermediárias e ações repetidas.
- A V-01A **não altera a economia**. A fase V-01C será um incremento de NPCs com menus por toque e integração às mesmas regras. O código legado exige auditoria de transações e recuperação parcial antes de ser declarado seguro para economia competitiva.
- Nenhuma transação com Minecoins/dinheiro real.

### 5.3 Multiplayer e segurança de execução

O mundo é hospedado pelo jogador no próprio Minecraft Mobile; amigos conectam via multiplayer Bedrock. Uma economia gerenciada no cliente proprietário não possui resistência a jogadores com permissões criativas/administrativas. Testes de ausência de duplicação são necessários antes de afirmar robustez.

---

## 6. Narrativa original — “O Juramento de Valdora”

**Premissa:** Valdora nasceu em um entroncamento de rotas comerciais entre montanhas, minas e campos férteis. As guildas sustentam uma paz frágil. Um viajante recém-chegado recebe um convite para conhecer a capital e provar que pode contribuir com a comunidade.

**Sequência da missão inicial (V-01D):**

1. Chegada à Praça Central; o jogador encontra o Marco do Guardião.
2. Orientação até o Banco Real e conversa com Soren.
3. Deslocamento até uma banca do Mercado e primeira negociação válida.
4. Retorno à Praça e registro de conclusão única (propriedade persistente específica).
5. Recompensa simbólica definida após balanceamento, sem possibilidade de repetição por relog, transferência ou spam.

Sem combate obrigatório na área de spawn. As futuras facções e guerras serão optativas e terão consequências delimitadas. Não usar nomes ou enredos de séries existentes.

---

## 7. Especificação de engenharia, empacotamento e versão

**Formato:** cada estrutura é NBT Bedrock sem compressão, little-endian, `format_version=1`, paleta de blocos, camadas de índices e dimensões. Arquivo no pacote de comportamento em `structures/channel/valdora/*.mcstructure`; IDs `channel:valdora/<nome>`. O projeto mantém gerador Python local (não executado por GitHub Actions). A estrutura deve ser validada por parser independente no build local.

**Versão de produto:** nome para usuários `Channel`; comportamento e recursos existentes seguem com os UUIDs originais para não invalidar mundos. Número da versão deve subir em cada nova distribuição. A V-01A será entregue como incremento de desenvolvimento, não como publicação aprovada para Marketplace.

**Instalação:** o arquivo `.mcaddon` contém os `.mcpack` de comportamento e recurso. O instalador de estruturas deve ser controlado por operação manual no jogo, preferencialmente em mundo plano **descartável com cheats**. Não alterar mundos preexistentes automaticamente. Os limites e coordenadas devem ser visíveis para o operador.

**Mundo `.mcworld`:** somente gerar quando o setor for validado na edição Bedrock real. Um `.mcaddon` com estruturas não é, por si só, um mundo montado. Não prometer importação automática nem atualização de um mundo anterior quando o usuário fizer download de um novo mundo.

### 7.1 Portas de entrega

| Marco | Saída concreta | Portão de aprovação |
|---|---|---|
| V-01A | caderno técnico + 4 estruturas de edifício + máscaras viárias + Add-on experimental | NBT e assets conferidos; sem verificação no Minecraft real |
| V-01B | mundo de teste construído, walkthrough, colisão, luz, capturas reais | entra em Android, circula e reconhece ambientes |
| V-01C | 3 NPCs e menus integrados | transações de 2 jogadores, falhas e retomadas |
| V-01D | missão introdutória única, progresso persistente | recompensa não duplicável |
| V-01E | documentação final, performance, regressões, backup | pronto para distribuição ampliada |

### 7.2 Critérios de qualidade mínimos

1. Quatro módulos posicionados sem sobreposição; vias contínuas; área total dentro do setor.
2. Estruturas lidas pelo Bedrock sem avisos fatais; blocos legíveis e não substituídos inesperadamente.
3. Spawn seguro, circulação mínima de 3 blocos nos eixos, passagem do portão de 5×5.
4. Construção manual e reversibilidade via backup do mundo.
5. Economia legada não quebrada pelo novo pacote e saldos existentes mantidos.
6. Celular Android de teste: verificação de importação, ativação, gameplay e retomada.
7. Não mencionar no site NPCs, classes ou história como recursos atuais enquanto não estiverem concluídos.
8. Não gerar cobranças, deploy de aplicação, Actions, workflows, jobs, migrations ou uso de banco externo.

### 7.3 Riscos e mitigação

| Risco | Mitigação |
|---|---|
| Conteúdo exportado visualmente divergente da capa | usar concept art como alvo de clima, mostrar capturas reais após homologação |
| Mundo de usuário sobrescrito | instalação sob comando/manual, backup, mundo plano descartável |
| Incompatibilidade NBT/estado de bloco | parser independente e teste no Bedrock Mobile antes de release estável |
| Módulos em terreno desnivelado | primeiro setor restrito a mundo plano controlado; adaptação de relevo posterior |
| Economia duplicada em multiplayer | manter NPCs bloqueados até teste transacional |
| Atualização perder itens/saldo | preservar UUIDs e IDs internos; backup e teste de upgrade |
| Arquivo Android reconhecido como `.bin` | nome `.mcaddon`, URL direta e cabeçalhos HTTP; teste em aparelhos reais |
| Custo operacional imprevisto | sem integração externa, sem runner Actions, sem servidor novo |

---

## 8. Checklist de vistoria V-01A/V-01B

- [ ] Build local gera `portao.mcstructure`, `praca.mcstructure`, `mercado.mcstructure`, `guilda.mcstructure` e 4 máscaras de vias.
- [ ] NBT válido, listas de índices dimensionadas corretamente, IDs com namespace.
- [ ] Arquivo instalável `.mcaddon` contém os pacotes corretos e passou por inspeção de ZIP.
- [ ] Minecraft Mobile reconhece e importa o arquivo sem `.bin`.
- [ ] Mundo de teste com backup e cheats; `structure load` funciona nos 8 IDs.
- [ ] Caminho da praça para mercado, quartel e portão é transitável.
- [ ] Avaliar dia/noite, interiores, colisões e textura de coberturas.
- [ ] Registrar coordenadas reais, screenshots e problemas encontrados.
- [ ] Revisar acessibilidade de navegação e desempenho no aparelho.

**Registro de estado:** somente marcar os itens verificados por execução real. Testes sintáticos, de NBT ou ZIP não substituem homologação no jogo.