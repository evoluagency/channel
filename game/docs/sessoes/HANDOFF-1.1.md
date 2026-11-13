# Valdora 1.1 — Passagem de bastão

Sessão: "Valdora 1.1 (Telas do jogo na direção visual)", 13/11/2026.
Branch: `claude/zealous-tesla-kfhwld`. Registro único: `game/docs/ESTADO_DO_PROJETO.md`. Próxima sessão: **1.2**.

## Decisão do dono (13/11/2026)

O CP012 (governança regional) será **`city-12`**. Nada é publicado agora: a Cidade visual evolui em versões intermediárias (`city-10`, `city-11`) até chegar a `city-12`. O número `city-10` fica livre para a Cidade visual; ela continua **sem assinatura e sem publicação**.

## Feito

1. **Módulo Cidade na direção visual v1** (`game/modules/city/city.gd`, regras da v9 intactas):
   - Barra superior de 60 px fixos (`clip_contents`, rótulos de uma linha com reticências, nome da cidade no título e quatro pílulas de recurso: madeira, pedra, alimentos, população). Corrige o defeito da coluna de letras.
   - Removido o texto "CIDADE · v8" do mapa e a versão do título do painel lateral.
   - Cores, raios (painel 18, botão 10), molduras (ouro 2 px só no painel em foco), alvos de 48/56 px, letra mínima 14. Fundo noite com montanhas violeta; terrenos mantidos legíveis.
   - Cinzel (títulos) e Montserrat (resto) carregados dos TTF dentro do módulo (`valdora_modules/city/fonts/`) com as licenças OFL. Sem as fontes, cai na fonte padrão.
   - Sem mudança de regra, de caminho de save (`user://valdora_city_cp005_v1.json`) nem de esquema; sem dependência do núcleo (APK 0.4.1 serve).
2. **Tema do núcleo**: `game/scripts/ui/valdora_tema.gd` (arquivo novo, não usado por nenhuma tela). Lista das mudanças de camadas e HUD pronta em `game/docs/MUDANCAS_NUCLEO_CP013.md`. `main.gd` intocado.
3. **Montador do ZIP sem assinatura**: `python3 tools/build_city_zip.py --version N [--out PASTA]` (padrão `dist/ota-trabalho/`, ignorado pelo git). Determinístico: `city-10.zip` com 383.057 bytes, SHA-256 `b6a097907956c1febe44bcb2b936b860164886263c1e0a9a8fe9a024eee80284` para o estado desta sessão.
4. **Smoke novo** `game/tests/city_visual_smoke.gd` (monta o ZIP sem assinatura em `tests/fixtures/city_visual_trabalho.zip`, entra no `--all`): barra de 60 px em 1280×720, 960×540 e 1600×720, rótulos em linha única, ausência de texto de versão, fontes e licenças no módulo, sem dependência do núcleo, alvos de 48 px, letra mínima 14, regras e custos iguais à v9, save válido.
5. `game/tools_validate.py`: a regra "nenhuma fonte no projeto" virou "fonte só com licença OFL na mesma pasta".

## Verificação (Godot 4.7.2 oficial, liberado pelo dono em 13/11/2026)

- `tools/run_valdora_tests.sh --all`: **18 passaram, 1 falhou**. A falha é o `remote_update_smoke` (sem rede até channel.evolu.ink, como já registrado). `city_visual_smoke`, `cp011_city_v9_smoke`, `cp005`, `cp007` e `city_name_layout` passaram.
- Captura real em 1280×720 (Xvfb + OpenGL): `game/docs/logs/cidade_visual_1280x720.png`. Barra de 60 px com título e quatro pílulas legíveis; sem texto de versão no mapa. Um defeito achado na captura (pílula cortando o valor, faixa verde-escura sob o mapa) foi corrigido antes do commit.
- Não conferido: aparelho físico (só o dono) e a janela de nomear cidade e o painel do Conselho em captura.

## Assinar no computador do dono (só quando a versão estiver validada)

A chave privada OTA nunca sai do computador do dono nem entra no repositório. O `ota_manifest.py` aceita um módulo por id: a versão anterior precisa sair da pasta antes.

```bash
git checkout claude/zealous-tesla-kfhwld && git pull
python3 tools/build_city_zip.py --version 10            # gera dist/ota-trabalho/city-10.zip
mkdir -p ~/valdora-ota-guardado && mv site/updates/v2/modules/city-9.zip ~/valdora-ota-guardado/
cp dist/ota-trabalho/city-10.zip site/updates/v2/modules/
python3 tools/ota_manifest.py --revision 11 --min-client-code 102 \
  --key-file /CAMINHO/DA/CHAVE/valdora_ota_privada.pem --write
python3 tools/ota_manifest.py --verify-existing         # confere com a chave pública
```

Observações:
- A revisão do manifesto sobe de 10 para 11. O cliente rejeita módulo de versão menor: nunca reutilize um número já assinado.
- `--verify-existing` deve imprimir `PASS: 3 OTA modules verified`.
- Publicar (push na `main` por uma branch `publicar/...`, 1 deploy) só com o OK explícito do dono. Ao chegar a `city-12`, repetir com `--version 12` e a revisão seguinte.
- Os smokes antigos (CP008 a CP011) estão presos às revisões anteriores do manifesto; após assinar, o `cp011_city_v9_smoke` deixa de passar por desenho, como já acontece com os históricos.

## Pendências

- Capturas do Conselho e da janela de nome; homologar no aparelho depois da assinatura.
- O dono não tem os pacotes do CP012 e do CP013: o desenvolvimento cabe a nós. Próximas sessões: construir o CP012 (`city-12`, governança regional) sobre a Cidade visual e o CP013 (HUD, aplicando `MUDANCAS_NUCLEO_CP013.md`).
- Decidir se o APK passa a levar as fontes em `res://fonts/` (item 8 da lista do CP013).
- "OK, subir site" do site novo continua pendente (sessão 1.0); o dono aprova se ficar como a imagem de referência.
