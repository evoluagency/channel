# Valdora — Alpha 0.2.0

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