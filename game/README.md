# Valdora — Alpha 0.2.1

> **Nota de 11/11/2026.** Este README descreve a Alpha 0.2.1. A versão atual no código é a 0.4.1-alpha (code 103), com pacote `ink.evolu.valdora`. Veja `docs/ESTADO_DO_PROJETO.md`.

**Valdora** é um RPG 3D independente para Android, desenvolvido por **EVOLU Channel**. O nome interno do projeto Godot permanece legado exclusivamente para preservar a pasta de salvamento; o APK e o HUD exibem Valdora.

Esta Alpha mantém Valdora, praça, NPCs, economia local, controles móveis, nascimento na praça e autodiagnóstico. A atualização 0.2 acrescenta **checagem automática de conteúdo declarativo** (textos), via Vercel, com conferência SHA-256 e persistência local. Não requer Supabase nem conexão permanente para jogar.

## Testar no celular

1. Extraia esta pasta e importe `project.godot` no Godot Editor 4.7.2 Android.
2. Execute ▶ e confirme `AUTO TESTE: 9/9` e os controles.
3. Toque **ATUALIZAR** perto do canto superior direito e confira a mensagem no jogo/console (`VALDORA_UPDATE`).
4. Abra o jogo sem internet para verificar que não há bloqueio e o conteúdo instalado permanece disponível.
5. Exporte `dist/Valdora-Alpha-0.2.apk` como Debug no editor. As permissões Android incluem INTERNET.
6. Para atualizar o APK existente **sem desinstalar**, mantenha `ink.evolu.channel` e assine com a mesma chave usada na versão anterior. Atualizações de APK não são silenciosas.

## Arquitetura e documentação

- Jogo: `scripts/main.gd`, `scenes/Main.tscn`.
- Atualizador JSON (sem execução de código remoto): `scripts/content_updater.gd`.
- Manifesto de versão publicado no site do estúdio: `site_updates/manifest.json` (fonte do site é `site/updates/manifest.json` no GitHub).
- Conteúdo de teste: `site_updates/content/valdora-1.json`.
- [Explicação técnica e dois jogadores de teste](docs/ATUALIZACOES_E_DOIS_TESTADORES.md).
- [Instruções anteriores de exportação](docs/EXPORTAR_ANDROID.md).

**Estado:** código preparado e testes estruturais executados localmente. A atualização via HTTPS no Android e o novo APK ainda precisam de teste real e validação de disponibilidade pública no domínio. Multiplayer simultâneo e atualização de mapas via `.pck` não implementados.

## Diagnostico de rede (Alpha 0.2.1)
A falha capturada no Android anterior nao distinguia o status da requisicao.
Agora o jogo exibe a causa e registra `[VALDORA_UPDATE] stage=manifesto result=N http=N reason=...` na Saida.
Isso nao altera o dominio remoto nem corrige automaticamente problemas DNS/HTTP; permite identifica-los antes de outra distribuicao.
O cliente continua compativel com o manifesto de conteudo `required_client_version: 0.2.0` (versao do protocolo de conteudo, nao do APK).

Teste adicional sem instalar APK: abra `https://channel.evolu.ink/updates/manifest.json` no navegador do proprio aparelho.
Se aparecer JSON, o servidor responde no navegador; se 404, login ou pagina HTML, anote essa resposta.
Nao desinstale a Alpha anterior; ao exportar um novo APK mantenha `ink.evolu.channel` e a assinatura digital original.