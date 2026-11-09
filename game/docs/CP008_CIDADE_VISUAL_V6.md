# Valdora — CP008, Cidade v6: identidade territorial interativa

## Escopo entregue

- Mantém o mapa isométrico de 12 x 10 lotes, edição, zoom, pan, nomeação responsiva, upgrades e todos os saves existentes.
- 3 estilos persistentes por cidade (Azul Real, Terracota, Bosque) controlados pelo botão ESTILO. Campo opcional visual_style; schema_version continua 1.
- Construções adicionais: jardim, praça, poço, quartel e mercado; sem aumentar o saldo inicial ou habilitar produção automática.
- Edifícios redesenhados por componentes geométricos leves (prefeitura/fortaleza, casa, fazenda, serraria, pedreira, torre, quartel e mercado), com telhados, bandeiras, portas, janelas e props.
- Estradas com tratamento de conexão entre lotes contíguos; paisagismo de árvores, rochas, plantações e água.
- Até 6 habitantes cosméticos com animação discreta; movimento não representa população real nem consumo.
- Grade alternável e visão crepúsculo; renderização limitada à cadência anterior de aproximadamente 4 FPS em Godot, sem shaders ou texturas grandes.
- Painel mostra classificação da cidade e revisão visual v6 para diferenciar a versão do módulo da versão APK 0.4.x.

## Limites
A arte é 2.5D procedural para Android e não implica cenários 3D detalhados nem a habilitação de multiplayer, economia online, NPCs com IA ou servidores dedicados. Os habitantes são visuais; ganhos e produção continuam não simulados. Atualização online requer o aplicativo base 0.4.0+; para módulos carregados na sessão, a base 0.4.1 possui hot-mount com proteção de namespace.

## Segurança e persistência
- Pacote ZIP city-6.zip versionado e imutável, SHA-256 e assinatura RSA-3072 compatíveis com o CP004.
- `user://valdora_city_cp005_v1.json` preservado com armazenamento atômico e backup; saves legados sem visual_style são aceitos.
- Não modifica os saldos, os heróis, a arena, configurações do Android, assinatura APK ou o projeto EVOLU Intelligence.

## Gate de publicação
Validar contrato SHA/RSA em CI,  teste Godot com carga da cena v6, regressões CP001–CP007, depois integrar ao release e publicar os dois arquivos estáticos no `main` da Vercel. Restaurar Action para manual-only. O usuário optou por testar no Android somente após a conclusão do pacote visual.
