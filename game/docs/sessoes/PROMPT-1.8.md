# Valdora 1.8 (PvP: interface e personagens no estilo da arte conceitual)

Responda em português do Brasil, de forma direta. Branch: `claude/zealous-tesla-kfhwld`; desenvolva e faça push nela.

Leia antes de agir:

- `game/docs/ESTADO_DO_PROJETO.md`: seção da sessão 1.7;
- `game/docs/sessoes/HANDOFF-1.7.md`;
- `game/docs/PVP_PERSONAGENS_CC0.md`;
- referências do dono: `game/docs/imagens/referencia_1.7/` (base, heróis, arsenal, equipamento, partida_5x5, partida_terceira);
- capturas atuais: `game/docs/imagens/pvp_1.7/`.

## Contexto

- **Foco 100% no PvP** (tiro 5 × 5 em primeira pessoa no celular). O jogo de estratégia foi encerrado; não retomar.
- **Feito na 1.7:**
  - luz dourada, céu com nuvens e cores saturadas nos 5 mapas;
  - kit de ornamentos (arcos, cúpulas, estandartes com V, flores, trepadeiras) e marcos regionais;
  - praça do Valdora em 3D atrás dos menus;
  - APK 0.5.4-pvp (código 108).
- **O ChatGPT também mexe nesta branch:**
  - antes de começar: `git pull` e `GODOT=... tools/run_valdora_tests.sh` (hoje 25 de 25);
  - Godot 4.7.2 oficial: zip SHA-256 `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`;
  - capturas: `xvfb-run` com `--rendering-driver opengl3`.

## Objetivo

1. **Interface no estilo da arte:**
   - painéis navy translúcidos com borda clara e cantos grandes;
   - botão JOGAR laranja com brilho e ícone;
   - barra inferior BASE, HERÓIS, ARSENAL e MISSÕES;
   - moedas no topo, como nas referências.
   - A praça 3D precisa aparecer atrás.
   - Na partida, o HUD também segue a arte: retratos dos times no placar, vida e escudo embaixo, joystick e botões redondos.
2. **Personagens:**
   - baixar o KayKit Adventurers e o Character Animations (CC0) e conferir o LICENSE do download;
   - recolorir na paleta do Valdora e usar como jogador e bots, com animações de andar, correr e atirar;
   - medir malhas e triângulos.
3. **Arma em primeira pessoa** no estilo da arte (creme, verde-azulado e laranja), por código ou CC0 (Kenney Blaster Kit).
4. **Vitrine do herói** nas telas Heróis e Arsenal: pedestal com anel verde-azulado, como na arte.
5. **Registro e entrega:**
   - testes;
   - APK novo pelo workflow (`fonte=claude/zealous-tesla-kfhwld`, `publicar_link=true`; subir o versionCode nos 7 pontos listados no PROMPT-1.7);
   - atualizar o ESTADO, escrever `HANDOFF-1.8.md` e `PROMPT-1.9.md`.

## Regras

- Único gasto pago: assinatura Claude.
- Sem push na `main` e sem deploy na Vercel.
- O dono autorizou gerar APK pelo workflow e publicar o link.
- Não copiar arte, personagens nem nomes de outros jogos.
- Poupar contexto. Perguntar só o que bloquear.

## Modelo

- Opus para a direção de arte da interface e a integração dos personagens.
- Sonnet para recolorir, gerar capturas e rodar testes.
