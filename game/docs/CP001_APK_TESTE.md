# Valdora — CP001 APK Android isolado (Alpha 0.3)
Estado: teste em ambiente separado, sem substituir a Alpha 0.2.1.

- Aplicativo original preservado: `ink.evolu.channel`.
- APK de teste: `ink.evolu.channel.cp001` (nome exibido Valdora CP001).
- Não compartilhar ou migrar saves: cada identificador Android tem seus próprios dados.
- Sistema de atualização e URL da Vercel mantidos sem alteração.
- Economia, salvamento e mapeamento de teclado extraídos para scripts/core.
- AUTO TESTE deve exibir 12/12: 9 diagnósticos anteriores + 3 do módulo econômico.
- Teste automatizado Godot core_smoke usa somente arquivo temporário.
- Nenhum serviço Supabase, política de servidor, multiplayer ou nova era foi implementado.

## Validação
`python3 game/tests/test_static_contract.py`
`python3 game/tools_validate.py`
`godot --headless --path game --script res://tests/core_smoke.gd`
`godot --headless --path game --script res://tests/smoke.gd`

O processo de exportação remota usa uma chave de DEBUG descartável e não é uma assinatura
de produção. Por isso esta variante não substitui a instalação existente e não deverá ser
utilizada para futuras atualizações obrigatórias do jogo.
