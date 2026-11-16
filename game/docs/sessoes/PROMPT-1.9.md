# Valdora 1.9 (PvP: homologação no aparelho, mais armas e acabamento dos heróis)

Responda em português do Brasil, de forma direta. Branch: `claude/zealous-tesla-kfhwld`; desenvolva e faça push nela.

Leia antes de agir:

- `game/docs/ESTADO_DO_PROJETO.md`: seção da sessão 1.8;
- `game/docs/sessoes/HANDOFF-1.8.md`;
- `game/docs/PVP_REFERENCIAS_1.8.md` e as imagens de `game/docs/imagens/referencia_1.8/`;
- as capturas atuais em `game/docs/imagens/pvp_1.8/`.

## Contexto

- **Foco 100% no PvP:** paintball 5 × 5 em primeira pessoa no celular.
- **Feito na 1.8:**
  - tinta com respingo, 30 aparências do marcador, marcador, pistola e granada de tinta;
  - 11 heróis KayKit (CC0) recoloridos, com 9 bots;
  - HUD e menus no estilo da arte;
  - APK 0.6.0-pvp (código 109).
- **O ChatGPT também mexe nesta branch:**
  - antes de começar: `git pull` e `GODOT=... tools/run_valdora_tests.sh` (hoje 26 de 26);
  - Godot 4.7.2 oficial: zip SHA-256 `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`;
  - capturas: `xvfb-run` com `--rendering-driver opengl3`.

## Objetivo

1. **Homologação no aparelho** com o dono: FPS na partida e nos menus, toque nos espaços de arma, leitura do HUD e cores de tinta. Corrigir o que ele apontar primeiro.
2. **Armas, por grupos** (ordem em `PVP_REFERENCIAS_1.8.md`), cada uma com tinta e respingo próprios:
   - marcadores 02 a 05, 07 e 08;
   - arremesso: 09 a 13;
   - granadas e armadilhas: 15 a 18 (fumaça colorida, flash, adesiva, mina).
3. **Atributos dos heróis valendo na partida** (velocidade, dano, vida e escudo por função), com equilíbrio simples.
4. **Bots melhores:** usar coberturas (`c`), agachar e espalhar entre A e B.
5. **Heróis mais perto da arte:** acessórios presos aos ossos (óculos do Nilo, cachecol, coletes), sem copiar personagens de outros jogos. Rever os trajes de origem com cuidado.
6. **Registro e entrega:**
   - testes;
   - APK novo pelo workflow (`fonte=claude/zealous-tesla-kfhwld`, `publicar_link=true`); subir o versionCode nos 7 pontos listados no PROMPT-1.7;
   - atualizar o ESTADO e escrever `HANDOFF-1.9.md` e `PROMPT-1.10.md`.

## Regras

- Único gasto pago: assinatura Claude.
- Sem push na `main` e sem deploy na Vercel.
- O dono autorizou gerar o APK pelo workflow e publicar o link.
- Não copiar arte, personagens nem nomes de outros jogos.
- Poupar contexto. Perguntar só o que bloquear.

## Modelo

- Opus para o equilíbrio das armas e a direção de arte.
- Sonnet para criar armas em série, gerar capturas e rodar testes.
