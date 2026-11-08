# CP006 Cidade v2 — personalização e continuidade OTA

O modelo leve de cidade aprovado no CP005 recebeu:
- Estrada construível de 5 unidades de madeira, com representação visual de via.
- Modo MOVER: seleciona edifício e lote de destino compatível, sem consumir recursos.
- Modo MELHORAR: progressão por níveis 1–3 com custo de madeira/pedra, novo volume e detalhes visuais.
- Limites de relevo mantidos (fazendas em campos, serrarias na floresta, pedreiras em rocha).
- Save user://valdora_city_cp005_v1.json com schema 1, mantendo construções existentes sem o campo level (nível implícito 1).
- Backup e gravação atômica existentes são preservados.
- ZIP assinado RSA-3072, versão city-2.zip e manifesto revision 3; publicação só após teste Godot.

O CP006 não transforma a cidade em 3D fotorrealista: mantém a abordagem 2.5D isométrica compatível com Android. Novos edifícios e layout serão produzidos incrementalmente. Recursos econômicos do módulo permanecem separados do saldo CP001.
