# Valdora CP011 — Expansão regional e primeiro estado (offline)

**Base:** CP010 Cidade v8, GDD Mestre v0.4.1 e hierarquia cidade → estado → país. Distribuição prevista: OTA `city-9.zip`, manifesto revisão 10. O servidor público ainda distribui a revisão 8 devido à cota de Vercel.

## Novos sistemas

- **Mapa regional** com cinco cidades: a cidade do jogador + quatro cidades NPC (Valeverde, Pedralta, Ribeirinha, Montesol).
- **Expedição e descoberta** após contato com Valeverde, construção de mercado e primeira caravana. Expedições registradas, custo limitado e sem duplicação.
- **Tratados municipais** individuais: assentamentos não podem aderir duas vezes; exigências de comércio, serviços e recursos. O custo é debitado em salvamento atômico antes de confirmar.
- **Fundação do primeiro estado:** somente com as cinco cidades representadas, quatro tratados, mercado, defesa e cobertura de serviços de pelo menos 50%. Estado local denominado `Estado de <nome da cidade>`. Governador: jogador. Sem governar contas de outros jogadores.
- **Três missões** adicionais: cartografia, conselho de prefeitos e primeiro estado. Recompensas únicas.
- **Cidades NPC** são agentes de regra fixa no mesmo save, não servidores físicos nem multiplayer.

## Compatibilidade e segurança

- Continua usando `user://valdora_city_cp005_v1.json` e `schema_version=1`. Campos opcionais: `regional_discoveries`, `regional_pacts`, `state_founded`, `state_name`.
- Migração conservadora de `npc_discovered=true` para Valeverde; não apaga moedas/heróis/saves anteriores.
- Validação de lista de cidades autorizadas, IDs únicos, pactos como subconjunto das descobertas, e estado formado apenas com quatro tratados.
- Economia e missões **offline** continuam manipuláveis pelo relógio e arquivos locais. Nunca sincronizar saldo local diretamente para PvP competitivo; multiplayer exige backend autoritativo.
- Nenhum recurso de Vercel/Supabase adicional, nenhum APK, sem publicação de ZIP não homologado.

## Critérios

1. Assinatura RSA-3072 verificada com a chave pública CP004.
2. Testes Godot de compatibilidade, transições, economia, pactos, eleições não simuladas, persistência e fraude básica.
3. Publicação em produção somente depois que a Vercel liberar implantação de produção; verificar `https://channel.evolu.ink/updates/v2/manifest.json` e ZIP HTTP 200.
4. Homologação visual/Android a cargo do usuário depois da consolidação, conforme orientação atual.
