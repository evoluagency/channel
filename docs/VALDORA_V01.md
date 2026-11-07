# CHANNEL — VALDORA | Marco V-01 — Construção do primeiro setor
Estado: especificação técnica de implementação; não está implantado no jogo.

## Direção artística
Fantasia medieval original; referência visual: capa do usuário com herói portando escudo, castelo de pedra clara, telhados quentes, banners roxos, montanhas, rio e cascata. A capa é concept art, não captura do gameplay. Geometria do terreno Minecraft Bedrock permanece em blocos. Personagens/NPCs poderão receber geometria customizada, dentro dos limites da engine e do celular.

## Arquitetura sem serviços pagos
- Código e arquivos versionados manualmente no GitHub público `evoluagency/channel`; não criar workflows, Actions, crons, migrations ou jobs.
- Site mínimo publicado manualmente na Vercel pelo proprietário (se autorizado), apontando para `Channel.mcaddon` e, futuramente, `Channel-Valdora.mcworld`.
- Lógica do mundo funciona integralmente offline no Minecraft Bedrock Mobile; sem Supabase/Vercel em tempo de jogo.
- Preservar os UUIDs dos pacotes e os IDs `erpg:*` já presentes na versão inicial até uma migração segura ser implementada.

## Distribuição (dois artefatos)
1. `Channel.mcaddon` — comportamento, recursos, NPCs, economia, classes e regras.
2. `Channel-Valdora.mcworld` — mundo base construído, terreno, construções e pontos de interesse.
Criar backup antes de importar novas versões. Importação de um novo `.mcworld` não deve ser descrita como atualização automática de um mundo antigo.

## Núcleo V-01 — 96x96 blocos (dimensões de planejamento)
Áreas: praça de chegada, mercado, quartel inicial e portão do castelo. Reserva de expansão ao norte (castelo), leste (bairro comercial), oeste (bairro arcano), sul (estrada e fronteira).

### Layout modular
- Centro: praça e marco de spawn. Área livre e acessível, ponto de referência visível.
- Leste: mercado com 3 postos de NPCs: ferreiro, mercador geral, banqueiro.
- Oeste: quartel com placa da guilda; seleção de classe fica bloqueada como futura função até implementação real.
- Norte: portão do castelo, muralha e ligação futura.
- Sul: via de entrada, paisagismo e ponto inicial da primeira missão.
Cada construção deve ser modelada em módulos `.mcstructure` e testada em mundo descartável.
Manter distâncias de navegação curtas para celulares e boa iluminação.

## Vertical slice — interações essenciais
- Jogador aparece na praça com guia de acesso ao mercado.
- Interage com 3 NPCs reais, com menus adaptados para toque.
- Usa carteira digital e moedas físicas no comércio, sem criar valor duplicado.
- Pode vender um item, comprar um item e consultar banco.
- Teste com 2 jogadores conectados ao mundo; nenhum saldo ou item pode duplicar em transações concorrentes.
- Uma tarefa inicial original, 'O Juramento de Valdora': conhecer praça, visitar banqueiro e concluir primeira negociação. Recompensa limitada e aplicada uma única vez por jogador.

## Ordem de implementação e portas de aprovação
V-01A: definir a planta, origens de coordenadas, paleta e exportar praça/portão como estruturas reutilizáveis.
V-01B: instanciar mundo `.mcworld` de teste, identificar spawn, terreno, colisões e iluminação.
V-01C: criar entidades dos três NPCs e interações com a economia existente.
V-01D: adicionar a missão introdutória e impedir recebimento repetido de recompensas.
V-01E: executar testes em Android com 1 e 2 jogadores e registrar capturas reais, desempenho e resultados.
V-01F: publicar manualmente novo `.mcaddon` e `.mcworld` após validação.

## Critérios de aceite
- World load estável na versão Bedrock alvo; nenhum experimento obrigatório não autorizado.
- Mundo criado apresenta construções posicionadas e spawn seguro.
- Comércios são operados por toque em NPC, com limites de inventário e saldo.
- Persistência após sair/reentrar; sem duplicação por relog ou spam de interação.
- Primeiro jogador consegue concluir a missão uma vez.
- Arquivos corretamente nomeados e abertos em Android: `.mcaddon` e `.mcworld`.
- O site distingue recursos disponíveis de recursos planejados.

## História original (base preliminar)
Valdora é um reino comercial de fronteira, surgido sobre antigas rotas de minério e travessias. Conflitos entre guildas e territórios vizinhos serão introduzidos apenas quando houver mecânicas de reputação e diplomacia. Sem usar nomes, personagens, insígnias ou tramas de obras protegidas.

## Decisões abertas, sem bloquear V-01A
Mapa fixo inicial em mundo novo; explorar geração procedural apenas depois de validar o núcleo.
`channel.evolu.ink` será configurado pelo proprietário na Vercel. Não alterar DNS ou fazer deploy neste marco.
