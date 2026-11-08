# Valdora Alpha 0.2.1 — diagnostico de atualizacao Android

## Evidencia real
Captura do Godot Android 4.7.2 mostrou tres ocorrencias de `[VALDORA_UPDATE] Sem acesso às atualizações; conteúdo local preservado`.
A resposta original englobava todos os erros de rede e respostas nao-200; nao era possivel inferir a causa exata.

## Correcao
- Exibir em HUD o resultado da verificacao, inclusive falhas.
- Registrar no console a etapa, resultado Godot (DNS, TLS, timeout, conexao) e HTTP (3xx, 401/403, 404 etc).
- Permanecem URL HTTPS fixa, sem redirecionamentos, SHA-256, validacao de schema, cache offline e salvamento local.
- Versao Android 0.2.1-alpha codigo 5, mesmo identificador `ink.evolu.channel`.

## Homologacao
Testes estaticos e integridade do ZIP executados localmente; nao houve execucao real desta revisao no motor Android.
Para aprovar: abrir o manifesto no navegador do aparelho, rodar 0.2.1 no Godot, coletar linha com `stage=manifesto result=... http=...`, corrigir a origem conforme o codigo, baixar conteudo v1 e comprovar leitura offline.

**Atencao**: corrigir o cliente requer exportar novo APK nesta fase. Atualizacoes futuras apenas de conteudo declarativo poderao ocorrer sem reinstalar.