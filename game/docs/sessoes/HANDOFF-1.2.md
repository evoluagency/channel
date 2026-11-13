# Valdora 1.2 — Passagem de bastão

Sessão: "Valdora 1.2 (Visual individual dos componentes)", 13/11/2026.
Branch: `claude/zealous-tesla-kfhwld`. Registro único: `game/docs/ESTADO_DO_PROJETO.md`. Próxima sessão prevista: **1.3 (Mapa do Brasil e estados em dados)**.

## Feito

1. **Método de geração** (`tools/arte3d/`, projeto Godot separado do jogo):
   - `kit.gd`: paleta, cores de aliança, materiais e cerca de 35 peças (caixa chanfrada, túnel, cúpula, arco, contêiner, toldo, helicóptero, guindaste, turbina, selo de nível etc.).
   - `construcoes/<nome>.gd`: uma receita por construção, `construir(kit, pai, faixa) -> altura do topo`.
   - `render.gd`: luz, câmera isométrica ortográfica e PNG por trabalho (`faixa:aliança:enquadramento`). Com `--contar`, informa peças e triângulos. Encerra com erro se a receita não carregar.
   - `gerar.sh`: as 17 imagens e as duas folhas de uma construção (cerca de 15 s).
   - `folha.py` e `catalogo.py`: montagem das folhas.
   - Fonte Montserrat com a licença OFL ao lado.
2. **13 construções × 6 faixas** em `game/docs/imagens/componentes/`: `<nome>_folha_faixas.png`, `<nome>_faixa6_detalhe_aliancas.png` e `catalogo_13_construcoes.png`.
3. **Guia de arte**: `game/docs/GUIA_DE_ARTE_v0.1.md`.
4. Registro atualizado (`ESTADO_DO_PROJETO.md`, seção "Visual individual dos componentes").

## Aprovações

- Quartel-general, Alojamento e Estufa: aprovados pelo dono, um por vez.
- Usina, Mineradora, Central de energia, Radar e antena, Base militar, Entreposto, Via, Parque, Estação de água e Heliponto: feitos em sequência a pedido do dono e **aprovados na avaliação final** (13/11/2026), junto com o guia de arte.
- Marcos M8 a M13 (desempenho, OTA só de conteúdo, Supabase, loja) registrados em `DESENHO_MUNDO_v0.1.md` a pedido do dono.

## Verificação

- Godot 4.7.2 oficial baixado de novo nesta máquina, SHA-256 `cadd3204…5e4` conferido; renderização com `xvfb-run` e `--rendering-driver opengl3`.
- `python3 game/tests/test_componentes_mundo.py`: 12/12. `python3 game/tools_validate.py`: OK. O `--all` dos smokes não foi rodado, porque o jogo não mudou.
- A reorganização do kit depois do QG aprovado foi conferida pixel a pixel (folha idêntica).

## Pendências e riscos

- **Desempenho**: até 210 peças e 38 mil triângulos por construção. É preciso fundir as malhas por material e reduzir as esferas antes da cidade 3D (sessão 1.5); detalhes no guia, seção 8.
- **Nível comercial**: o que falta está no guia, seções 9 e 10 (texturas, personagens, efeitos, heróis com rosto). Sem proposta de gasto.
- **Motor**: o dono perguntou sobre Unity e Three.js. A recomendação é seguir no Godot; a decisão é dele.
- **Pendências do dono**, inalteradas: nome do jogo, direção de cor final, atribuição do estado, territórios disputados, pacote do app, nomes dos heróis.
- Nada foi publicado: sem push na `main`, deploy, OTA ou workflow.

## Retomar

```bash
git checkout claude/zealous-tesla-kfhwld && git pull
curl -L -o godot.zip https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
sha256sum godot.zip   # cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4
unzip godot.zip && export GODOT=$PWD/Godot_v4.7.2-stable_linux.x86_64
tools/arte3d/gerar.sh usina "Usina de materiais" /tmp/arte/usi
```

Modelo: o método e o estilo estão fechados. Ajustes pontuais nas receitas e novas gerações podem ficar com o Sonnet. Mudanças de direção visual e a fusão de malhas da sessão 1.5 pedem o Opus.
