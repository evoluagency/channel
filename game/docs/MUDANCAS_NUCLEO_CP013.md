# Mudanças de camadas e HUD preparadas para o CP013

Preparado em 13/11/2026 (sessão Valdora 1.1). **Nada disso foi aplicado.** O `main.gd` não foi tocado, porque o CP013 confere o hash dele. Esta lista entra junto com o CP013, num APK novo (versionCode maior que 103, mesmo certificado). Regras de origem: `docs/DIRECAO_VISUAL.md`, seção "Jogo (Godot)". Constantes prontas em `game/scripts/ui/valdora_tema.gd`.

| # | Defeito ou regra | Mudança no núcleo | Onde olhar |
|---|---|---|---|
| 1 | Botões do topo (MÓDULOS e outros) desenhados por cima dos painéis de Heróis e Arena | Botões do HUD numa `CanvasLayer` de camada 1; painéis na camada 2. Hoje estão na mesma camada e os botões entram depois dos painéis | `scripts/main.gd` (criação do HUD e abertura de painéis); `scripts/ui/hero_panel.gd` |
| 2 | Painel aberto deve ocultar os botões do HUD e escurecer o mundo | Ao abrir painel: `hud_layer.visible = false` e `ColorRect` NOITE a 72% entre mundo e painel; ao fechar, desfazer | `main.gd` |
| 3 | Mensagem de status passa por baixo dos botões | Mensagem numa `CanvasLayer` de camada 3, centralizada no rodapé, com margem inferior que não colide com botões | `main.gd` |
| 4 | Barra superior com altura fixa de 60 px, sem quebra | Mesmo padrão do módulo Cidade: `custom_minimum_size.y = 60`, `clip_contents`, rótulos com `autowrap_mode = OFF` e `OVERRUN_TRIM_ELLIPSIS` | `main.gd`, `brand_home.gd` |
| 5 | Rótulos em linha sem quebra automática dentro de `HBoxContainer` | Auditar todo `Label` com autowrap em `HBoxContainer`; desligar o autowrap ou dar largura mínima | `scripts/` inteiro |
| 6 | Alvo de toque mínimo de 48 px; botão principal de 56 px | Revisar `custom_minimum_size` dos botões do HUD, de Heróis e de Arena | `main.gd`, `hero_panel.gd` |
| 7 | Letra: título 28 a 40, corpo 16 a 18, mínimo 14 | Trocar os tamanhos soltos por `ValdoraTema.FONTE_*` | todas as telas |
| 8 | Tipografia Cinzel (títulos) e Montserrat (resto) | Copiar os TTF e as licenças OFL para `game/fonts/` (hoje estão em `game/modules/city/fontes/`), definir tema padrão com Montserrat; títulos com Cinzel | `project.godot` (tema padrão), telas |
| 9 | Cores, raios e molduras | Substituir `StyleBoxFlat` ad hoc por `ValdoraTema.painel()`, `botao_principal()`, `botao_secundario()`. Um painel em foco por tela (moldura dourada) | todas as telas |
| 10 | AUTO TESTE fora da versão de jogador | Esconder o botão fora de build de debug (`OS.is_debug_build()`) e excluir `tests/` da exportação | `main.gd`, `export_presets.cfg` |
| 11 | Cor por força nos cartões de herói | `ValdoraTema.cor_forca()` nos cartões e barras de atributo | `hero_panel.gd` |

Ordem sugerida: 1 a 3 (corrigem os defeitos vistos no aparelho), depois 4 a 7, depois 8 a 11. Cada passo precisa passar `tools/run_valdora_tests.sh --all` antes de ir ao APK.
