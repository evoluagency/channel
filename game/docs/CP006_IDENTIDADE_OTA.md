# CP006 — Identidade Valdora e ativação OTA na sessão atual

**Base:** Android 0.4.0-alpha CP004 + módulo Minha Cidade CP005, ambos homologados pelo usuário.

## Implementação

- Nome exibido no Android: Valdora. Pacote permanente: ink.evolu.valdora.
- Ícone Valdora próprio de 192px e camadas adaptativas de 432px. Splash padrão Godot desativado, fundo azul-marinho e menu principal Valdora em Godot.
- Tela principal com caminhos para Minha Cidade, Exploração 3D, Heróis e Combate; a tela inicial não altera nem substitui os saves existentes.
- Versão Android 0.4.1-alpha, versionCode 103, com a mesma assinatura permanente e atualização obrigatória por cima de 102.
- Gerenciador OTA consulta automaticamente ao abrir, verifica SHA-256 e assinatura RSA e pode montar um ZIP compatível durante a sessão.
- Pacotes ZIP precisam conter SOMENTE arquivos dentro de valdora_modules/<id>/ e extensões permitidas. Um módulo atualizado substitui apenas seu namespace, não sobrescreve o core.
- Ao reabrir a cena de módulo, ResourceLoader usa CACHE_MODE_REPLACE_DEEP para evitar dados antigos em cache.
- Uma cena que já esteja aberta não será recriada durante a interação do usuário; feche e reabra somente o painel, não o app.
- A base PCK com mesmo ID NÃO é sobreposta ao vivo por falta de inspeção segura de caminhos; PCK novo é montado sem replace_files.
- CP005 Minha Cidade e seu save local user://valdora_city_cp005_v1.json permanecem intactos.

## Condições de conclusão

1. Validar importação Godot e testes da build de release, incluindo cp006_live_smoke.gd.
2. Conferir APK assinado com package ink.evolu.valdora, code 103 e fingerprint anterior.
3. Atualizar o aplicativo Android **sem desinstalar**.
4. Validar ícone na área de apps, inicialização Valdora e acesso à cidade.
5. Publicar novo módulo ZIP de versão superior em fase posterior e validar abertura no mesmo processo sem reiniciar; não alterar arquivos já publicados sem incrementar versão/revisão.

Nenhum backend de multiplayer, custo novo, deploy da Vercel ou alteração de saldos será realizado neste checkpoint.
