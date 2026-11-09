# Valdora CP009 — Cidade viva (módulo v7)

**Entrega:** expansão OTA `city-7.zip`, manifest `revision=8`, sem novo APK.

## Sistemas construídos

- Produção local: serraria +8 madeira, pedreira +5 pedra e fazenda +10 alimentos por nível e por ciclo de 10 minutos.
- Coleta explícita e transacional com persistência atômica do timestamp e saldos; nunca credita ao desenhar a cena.
- Retomada offline limitada a 48 ciclos (8 horas), sem acumulação infinita. Mudança de nível ou construção de indústria reinicia o ciclo, impedindo ganhos retroativos a uma ampliação.
- Campo de alimentos adicionado de forma retrocompatível, sem custo nem consumo nesta versão; não integra ainda mercado ou população efetiva.
- Moradores cosméticos transitam entre casas e locais produtivos (até 12 objetos por quadro), com cores profissionais; comportamento visual, **não** agentes autônomos com tarefas persistentes.
- Detalhes ambientais desenhados com primitivas leves (mercado, fazenda, oficina, poço, quartel e praça); revisão de conteúdo exibida na cena como Cidade v7.
- Não altera `channel_save.json`, `valdora_hero_roster_v1.json` nem `package id` Android. Todos os saves da cidade permanecem em `user://valdora_city_cp005_v1.json`.

## Restrições e segurança

- Tempo baseado no relógio local do aparelho: adequado à fase solo e **não confiável como autoridade de competição online**. Multijogador exigirá relógio/estado de servidor e regras de migração.
- Nenhum recebimento automático ao entrar no jogo; coleta voluntária do jogador, com limite de recursos 999.999.
- Conteúdo ZIP assinado usando chave OTA existente, caminhos limitados a `valdora_modules/city/`.
- Não promover a versão sem suíte Godot, integridade ZIP, assinatura RSA e validação do manifesto.
- Android 0.4.0 pode exigir reabertura para carregar novos módulos; Android 0.4.1 suporta ativação ao vivo de ZIPs compatíveis. O número 0.4.0 no menu antigo é fixo do aplicativo e não equivale à versão do módulo.

## Aceite

- Godot headless carrega `city-7.zip` e completa a suíte CP009.
- Regressões de CP001–CP008 continuam aprovadas.
- Vercel produção retorna manifesto revisão 8 e ZIP city-7 HTTP 200.
- Performance mobile física permanece para validação quando o usuário decidir testar a versão consolidada.
