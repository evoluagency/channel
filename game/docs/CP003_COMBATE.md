# Valdora — CP003-A/B | Motor de combate PvE offline

Estado: núcleo CP003-A/B **testado**, CP003-C integrado em **arena 3D de demonstração** na branch de desenvolvimento. O APK homologado v0.3.3-alpha será disponibilizado por atualização assinada do aplicativo já instalado.

## Fonte de verdade
- GDD Mestre **v0.4.1**, §§6.2–6.3, 7, 8.1–8.11 e 15.3–15.4.
- Catálogo **CP002-A** e formação CP002-B: Pietro, Henzo, Giulia e Arthur.
- O GDD define **Regente + até 4 heróis** para expedição PvE; o Regente ainda não é ator simulado. A formação CP002 tem 5 posições genéricas, mas o motor PvE admite no máximo **4 heróis** efetivamente alocados. Não converter a quinta posição em herói adicional nem confundir com contingentes da batalha territorial.

## Contrato da simulação
Arquivo: `res://scripts/combat/pve_engine.gd`.

- `begin_battle(catalog, roster, enemy_specs, seed, posture)`: valida entradas, retorna estado inicial sem alterar o save.
- `advance_round(state, orders)`: retorna **cópia** do estado, resolve uma rodada e emite eventos.
- `simulate(catalog, roster, enemy_specs, seed, orders)`: executa até vitória, derrota ou limite de 8 rodadas.
- `result_digest(state)`: SHA-256 do resultado e dos eventos para comparação de replays. Não é assinatura de segurança.
- `damage_amount(...)`: segue fórmula GDD: ataque × coeficiente × 100/(100+defesa) × terreno × unidade × crítico × fortificação, com arredondamento por `roundi` e dano mínimo 1.

### Contrato de entrada
Um inimigo é declarado com ID único, nome, linha `front/back`, `hp`, `attack`, `defense`, `initiative`, `attack_type` (`physical/magical`). Máximo de seis NPCs neste motor, limite experimental, **não** escala aprovada de exército.

Ordens por rodada:
- `posture`: `equilibrada`, `cautelosa`, `agressiva`.
- `skills_mode`: `auto`, `manual` ou `none`. Em manual, `activate_hero_id` libera a ativa de um herói por rodada; os outros atacam normalmente.
- `focus_enemy_id`: prioriza o inimigo informado **somente** se estiver exposto pela linha de frente.

### Regras e limites
- 8 rodadas lógicas; ordem por iniciativa decrescente, empates por ID estável; seed da batalha registrada. RNG Lehmer próprio; o mesmo estado/seed/versão reproduz os mesmos eventos.
- Linha de frente protege retaguarda; só permite atingir alvos de trás após esgotar os da frente.
- Posturas são **propostas de balanceamento**: agressiva +10% dano causado e recebido; cautelosa −10% causado e recebido; equilibrada neutra. Não são parâmetros já homologados no produto.
- Crítico base conforme atributos do catálogo, multiplicador 1,50; modificador de terreno limitado a 0,90–1,10, tipo a 0,90–1,15 e fortificação a no máximo 20%. O modelo de relações entre unidades e terrenos ainda não foi integrado à arena; atualmente os modificadores aplicados pela simulação padrão são neutros.
- Pietro: aplica 15% de redução à vanguarda **na próxima rodada**; passiva de 5% no primeiro ataque físico recebido.
- Henzo: marca alvo por até a rodada seguinte, consumida no próximo ataque aliado (+10%); reconhecimento passivo contextual fora do combate.
- Giulia: recupera 12% dos PV máximos de um aliado vivo mais ferido, limitado aos PV faltantes, sem ressuscitar. Passiva de coleta fora do combate.
- Arthur: ativa bônus de 1,20× no **próximo ataque** e fica exposto a +5% dano recebido até o fim da rodada seguinte; abaixo de metade dos PV recebe +5% ataque físico passivo.
- Custos de Foco e recargas são lidos do catálogo CP002-A, não de valores duplicados.
- Habilidades supremas continuam bloqueadas por domínio III.
- Ao finalizar em 8 rodadas sem aniquilação há `draw` **provisório**, sem mecanismo de desempate por objetivo até existir contrato de missões.
- No modo solo o cliente resolve; **nada é autoritativo para PvP ou economia compartilhada**.

### Eventos emitidos
`battle_started`, `round_started`, `attack_started`, `damage_applied`, `shield_blocked`, `focus_spent`, `skill_triggered`, `healed`, `round_ended`, `battle_resolved`.

Cada evento tem `round`; os eventos de ataque e habilidade têm IDs de ator e/ou alvo. O renderizador poderá consumir essa sequência sem recalcular o resultado.

## O que esta etapa NÃO faz
- Não gera APK nem modifica a assinatura permanente, o pacote `ink.evolu.valdora` ou o versionCode 100.
- Não altera o save `user://channel_save.json`, nem `user://valdora_hero_roster_v1.json`.
- Não distribui moedas, experiência, drops, saúde persistente ou recursos de vitória (campo `reward_issued=false`).
- A branch CP003-C implementa arena 3D e HUD tática com avatares 3D simplificados, projéteis e pulsos visuais por evento, mas **não** modelos finais, rigging, animação esquelética, pathfinding ou medição de FPS.
- Não implementa multiplayer, entidades autoritativas, Supabase, Intelligence ou lógica executável por atualização remota.

## Homologação técnica
Executar com Godot **4.7.2**:
`godot --headless --editor --path game --quit`
`godot --headless --path game --script res://tests/combat_smoke.gd`

Uma workflow leve CP003 executa também os testes CP001/CP002 e o smoke da cena. Não baixa Android SDK nem gera APK. Após homologação, o plano é CP003-C (adaptador de eventos para arena isolada e UI de decisões). Só então consolidar uma nova atualização **sobre o mesmo aplicativo**, com mesma chave e versionCode > 100.

## CP003-C — Integração visual em Godot

**Arquivos:** `res://scripts/combat/arena_panel.gd`, `res://scripts/main.gd`, `res://tests/smoke.gd`.
A nova interface abre pelo botão **COMBATE** na HUD e é um `SubViewport` com `World3D` próprio (separado do mundo explorável). O deslocamento do personagem fica suspenso enquanto a interface está visível.

### Jornada interativa de teste
1. Abrir **COMBATE**; arena provisória mostra os quatro heróis e dois inimigos com modelos low-poly de referência.
2. Selecionar postura (equilibrada / cautelosa / agressiva), herói e foco de alvo.
3. Usar **ATAQUE BÁSICO**, **SEMIAUTOMÁTICO** ou **ATIVAR HABILIDADE**; cada comando resolve uma rodada no motor CP003.
4. A tela apresenta PV, número de rodadas, histórico textual e pulsos/projéteis associados a eventos do motor; nova ordem fica bloqueada até concluir a reprodução.
5. A batalha termina em vitória, derrota ou empate por 8 rodadas. **REINICIAR** cria um encontro novo com seed registrada.
6. **FECHAR** retorna ao cenário anterior; moedas, banco, poções e formação persistente permanecem intactos.

Os avatares são **protótipos 3D estilizados e simplificados**. Não representam modelos finais nem retratos oficiais de Pietro, Henzo, Giulia ou Arthur. A formação CP002-A, inclusive os valores de habilidades e os atributos, continua sendo a fonte de verdade. Não há dependência de recursos remotos nem instalação de efeitos visuais externos.

### Salvaguardas
- Não há escrita de saves, distribuição de recompensas ou mudanças de estado fora do painel.
- A arena consome somente cópias de catálogo e formação no início do encontro; fechar e reabrir não transfere PV/lesões para o mundo.
- Aplicativo Android permanece `ink.evolu.valdora` com assinatura permanente. Próxima versão, quando aprovada, terá código superior a 100 e será **atualização sobre o mesmo app**, não novo pacote.
- Testes CP001/002/003 e testes de abertura, pausa, turno, replay e fechamento da cena.
- O demo CP003-C não substitui a futura arena PvE definitiva ou o combate territorial em larga escala.
