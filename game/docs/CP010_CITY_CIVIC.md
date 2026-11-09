# Valdora CP010 — Cidade v8: administração, missões e vizinhança

Base: Cidade v7 / OTA revisão 8, Android 0.4.0/0.4.1, GDD Mestre v0.4.1 e hierarquia cidade → estado → país.

## Entrega

- Governo local: painel **GOVERNO · MISSÕES · REGIÃO**, com serviços, cobertura, defesa e abastecimento.
- Missões urbanas com sete objetivos fixos e recompensas únicas, registradas no save transacional antes de informar conclusão. Não permitem resgate duplo.
- Abastecimento: a produção das fazendas permanece igual; ao coletar, cada casa produz demanda por alimentos. Uma unidade residencial de seis habitantes consome 2 alimentos por ciclo de dez minutos. A coleta mantém o limite de 48 ciclos (oito horas), persiste o saldo bruto, desconta consumo sem negativo e registra carência sem demolir casas.
- Região: mapa ilustrado e primeira cidade vizinha **Valeverde**, administrada por NPC (determinística e offline). Desbloqueia após fundação e uma casa.
- Comércio: com mercado construído, oferece troca madeira→alimentos e alimentos→pedra, com cooldown local de 15 minutos, relação e histórico salvos.
- Proteção: nomes de países, servidores, economia do jogador original, heróis, combate e rota de distribuição não são alterados. Sem conexão online compartilhada, sem eleições/multiplayer, sem custos de infraestrutura.

## Compatibilidade

- Mesmo arquivo `user://valdora_city_cp005_v1.json`, schema 1, nome e layouts preservados.
- Campos opcionais: `claimed_missions`, `npc_discovered`, `npc_trades`, `npc_relation`, `last_trade_unix`, `food_shortage_cycles`; migração não destrutiva, verificador recusa valores fora de limites.
- Recursos `madeira`, `pedra` e `alimentos` continuam isolados da economia CP001; o novo uso de alimentos é econômico e local, não afeta a carteira anterior.
- APK-base não recompilado. Módulo ZIP versionado e assinado com chave OTA já existente; manifesto v2 revision 9.
- O usuário fará homologação visual/Android apenas após consolidarmos as próximas funcionalidades. Godot headless valida agora a lógica e persistência.

## Risco conhecido

- Relógio é o horário local do dispositivo. O limite de produção e o cooldown não equivalem a garantias anti-fraude; ao implementar multiplayer será necessário serviço autoritativo e separação rigorosa do saldo offline.
- Cidade Valeverde é simulação NPC local. Não representa um segundo usuário ou servidor real.
