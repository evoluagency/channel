# EVOLU Channel — Valdora Alpha 0.1.2 — correção do diagnóstico no Android

## Evidência recebida

O usuário executou a cena do Channel no editor Godot Android 4.7.2 e apresentou captura da praça de Valdora, personagem, fonte, estruturas, interface e controle de toque renderizados. Isso comprova **inicialização visual da cena** no aparelho, mas não comprova ainda gameplay ou persistência.

## Problema

Na 0.1.1 o botão de diagnóstico era instanciado apenas se `OS.is_debug_build()` retornasse verdadeiro. A captura mostrava `EXPLORAR` mas não `AUTO TESTE`. O editor Android pode executar a cena em uma configuração que não satisfaça essa condição.

## Correção

- Adicionar `const ALPHA_DIAGNOSTICS_ENABLED := true` no script principal.
- Exibir botão `AUTO TESTE` independentemente de `OS.is_debug_build()` durante a fase Alpha.
- Atualizar preset Android para 0.1.2, código 3.
- Os nove testes não executam compras, não mexem nos saldos e usam somente arquivo temporário para testar leitura/escrita.

## Validação

Revisão estática local concluída. Ainda é necessário importar a Alpha 0.1.2 no Godot Android, pressionar Play e registrar o resultado real do botão `AUTO TESTE` e dos testes de gameplay. Não foi gerado APK nesta revisão.

## Limite

**Desativar o diagnóstico na versão de produção.** Não afirmar que houve 9/9 até recebimento do resultado de execução no aparelho.
