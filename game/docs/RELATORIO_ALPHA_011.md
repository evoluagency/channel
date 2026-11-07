# EVOLU Channel — Valdora Alpha 0.1.1 — relatório de execução

**Data:** 07/11/2026
**Repositório:** `evoluagency/channel`, branch `feat/godot-valdora-alpha01`
**Escopo:** primeiro jogo independente Android em Godot 4.7.2, **não** o Add-on Minecraft.

## Evidência objetiva

- Arquivos da cena 3D e scripts presentes e empacotados no projeto.
- [x] `tools_validate.py`: 11 verificações da estrutura do código aprovadas.
- [x] `tests/test_static_contract.py`: 11 verificações estáticas específicas de spawn, abertura física dos edifícios, controles e exportação aprovadas.
- [x] `ZIP`: integridade verificada e manifesto na raiz (`project.godot`).
- [ ] Godot 4.7.2 executado neste ambiente: **não** — executável ausente. As tentativas de obter a distribuição oficial foram bloqueadas por indisponibilidade de rede; não foi possível executar a cena aqui.
- [ ] `tests/smoke.gd` executado no Godot real: **pendente**.
- [ ] APK Android compilado e assinado: **pendente**.
- [ ] Android Samsung/Xiaomi testado: **pendente**.

## Correções em relação à Alpha 0.1

1. Fachadas do banco, ferraria e guilda deixam de ser paredes contínuas; aberturas de 2,7 m x 3,6 m com colisão são passáveis. Fundação/soleira niveladas com o terreno.
2. Adicionado botão **AUTO TESTE** na compilação de depuração; nove verificações dentro do motor do jogo e relatório no console.
3. Adicionado `tests/smoke.gd` para testar instância de cena, spawn e diálogos de NPC no motor real, sem alterar saldos.
4. Exportação Android para `arm64-v8a` e `armeabi-v7a`; pacote único `ink.evolu.channel` versão `0.1.1`, código `2`.
5. Guia para execução e exportação usando **Godot Editor Android 4.7.2**, apoiado na documentação oficial.

## Próxima barreira de validação

Abrir a Alpha 0.1.1 no Godot 4.7.2, inspecionar o log de parser/execução, tocar em **AUTO TESTE** e exportar o APK de depuração. Se o teste rodar sem erros, validar o APK em Samsung e Xiaomi antes de distribuí-lo no site.

Sem deploy Vercel, escrita Supabase, GitHub Actions ou criação de infraestrutura paga.