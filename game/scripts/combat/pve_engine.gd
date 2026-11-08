extends RefCounted
## CP003-A/B — motor PvE offline determinístico, sem cena, rede ou escrita em disco.
## Contrato GDD v0.4.1: até 4 heróis, 8 rodadas, seed, eventos e dano por defesa.
## Valores de posturas e heurísticas são propostas de balanceamento, não homologação.
const HERO_SYSTEM := preload("res://scripts/heroes/hero_system.gd")
const RULE_VERSION := 1
const MAX_ROUNDS := 8
const MAX_HEROES := 4
const MAX_ENEMIES := 6
const VALID_POSTURES := ["equilibrada", "cautelosa", "agressiva"]
const RNG_MODULUS := 2147483647
const RNG_MULTIPLIER := 48271

static func damage_amount(attack: int, defense: int, coefficient: float = 1.0, terrain: float = 1.0, unit: float = 1.0, critical: bool = false, fortification: float = 0.0) -> int:
    # Ordem: ATQ × skill × mitigação DEF × terreno × unidade × crítico × fortificação.
    var amount := float(maxi(0, attack)) * clampf(coefficient, 0.1, 3.0)
    amount *= 100.0 / (100.0 + float(maxi(0, defense)))
    amount *= clampf(terrain, 0.9, 1.1)
    amount *= clampf(unit, 0.9, 1.15)
    if critical:
        amount *= 1.5
    amount *= 1.0 - clampf(fortification, 0.0, 0.2)
    return maxi(1, roundi(amount))

static func _error(reason: String) -> Dictionary:
    return {"ok": false, "error": reason, "rule_version": RULE_VERSION}

static func _normalized_seed(seed: int) -> int:
    return posmod(seed, RNG_MODULUS - 1) + 1

static func _roll(state: Dictionary) -> float:
    var next_seed: int = (int(state["rng_state"]) * RNG_MULTIPLIER) % RNG_MODULUS
    state["rng_state"] = next_seed
    return float(next_seed) / float(RNG_MODULUS)

static func _event(state: Dictionary, event_type: String, data: Dictionary = {}) -> void:
    var payload: Dictionary = {"type": event_type, "round": int(state["round"])}
    payload.merge(data)
    var events: Array = state["events"]
    events.append(payload)

static func _hero_actor(hero: Dictionary, slot: String) -> Dictionary:
    var stats: Dictionary = HERO_SYSTEM.derived_stats(hero)
    var abilities: Dictionary = hero.get("skills", {})
    var active: Dictionary = abilities.get("active_1", {})
    return {
        "id": str(hero["hero_id"]), "name": str(hero["display_name"]), "side": "heroes",
        "line": "front" if slot.begins_with("vanguarda") else "back",
        "slot": slot, "class": str(hero["class"]),
        "hp": int(stats["HP"]), "max_hp": int(stats["HP"]),
        "focus": int(stats["focus"]), "max_focus": int(stats["focus"]),
        "attack_physical": int(stats["physical_attack"]), "attack_magic": int(stats["magic_attack"]),
        "defense_physical": int(stats["physical_defense"]), "defense_magic": int(stats["magic_defense"]),
        "initiative": int(stats["initiative"]), "crit_percent": float(stats["critical_percent"]),
        "next_skill_round": 1, "skill_uses": 0,
        "skill_focus_cost": int(active.get("focus_cost_proposed", 0)),
        "skill_cooldown": int(active.get("cooldown_rounds_proposed", 0)),
        "shield_round": 0,
        "empowered": false, "vulnerable_until": 0, "first_hit_used": false,
        "mark_until": 0, "mark_consumed": false, "attack_type": "magical" if str(hero["class"]) == "clerigo" else "physical"
    }

static func _enemy_actor(spec: Dictionary) -> Dictionary:
    var max_hp: int = int(spec["hp"])
    return {
        "id": str(spec["id"]), "name": str(spec["name"]), "side": "enemies",
        "line": str(spec["line"]), "slot": "", "class": "npc",
        "hp": max_hp, "max_hp": max_hp, "focus": 0, "max_focus": 0,
        "attack_physical": int(spec["attack"]), "attack_magic": int(spec["attack"]),
        "defense_physical": int(spec["defense"]), "defense_magic": int(spec["defense"]),
        "initiative": int(spec["initiative"]), "crit_percent": 5.0,
        "next_skill_round": MAX_ROUNDS + 1, "skill_uses": 0, "shield_round": 0,
        "empowered": false, "vulnerable_until": 0, "first_hit_used": false,
        "mark_until": 0, "mark_consumed": false, "attack_type": str(spec["attack_type"])
    }

static func _enemy_is_valid(spec: Variant) -> bool:
    if not spec is Dictionary:
        return false
    var e: Dictionary = spec
    if not e.has_all(["id", "name", "line", "hp", "attack", "defense", "initiative", "attack_type"]):
        return false
    if str(e["id"]).is_empty() or str(e["name"]).is_empty():
        return false
    if not ["front", "back"].has(str(e["line"])):
        return false
    if not ["physical", "magical"].has(str(e["attack_type"])):
        return false
    return int(e["hp"]) >= 1 and int(e["hp"]) <= 5000 and int(e["attack"]) >= 1 and int(e["attack"]) <= 500 and int(e["defense"]) >= 0 and int(e["defense"]) <= 500 and int(e["initiative"]) >= 1 and int(e["initiative"]) <= 200

static func begin_battle(catalog: Dictionary, roster: Dictionary, enemy_specs: Array, seed: int, posture: String = "equilibrada") -> Dictionary:
    if not HERO_SYSTEM.catalog_is_valid(catalog) or not HERO_SYSTEM.roster_is_valid(roster, catalog):
        return _error("catalogo_ou_formacao_invalida")
    if not VALID_POSTURES.has(posture):
        return _error("postura_invalida")
    if enemy_specs.is_empty() or enemy_specs.size() > MAX_ENEMIES:
        return _error("quantidade_inimigos_invalida")
    # Custos e recargas vêm das fichas CP002-A, não são duplicados no código.
    for hero in catalog.get("heroes", []):
        var active: Dictionary = hero.get("skills", {}).get("active_1", {})
        if int(active.get("focus_cost_proposed", 0)) < 1 or int(active.get("focus_cost_proposed", 0)) > 100:
            return _error("custo_de_habilidade_invalido")
        if int(active.get("cooldown_rounds_proposed", 0)) < 1 or int(active.get("cooldown_rounds_proposed", 0)) > MAX_ROUNDS:
            return _error("recarga_de_habilidade_invalida")
    var enemies: Array = []
    var unique_enemy_ids: Dictionary = {}
    for spec in enemy_specs:
        if not _enemy_is_valid(spec):
            return _error("especificacao_inimigo_invalida")
        var enemy_id: String = str(spec["id"])
        if unique_enemy_ids.has(enemy_id) or HERO_SYSTEM.hero_by_id(catalog, enemy_id).size() > 0:
            return _error("id_inimigo_duplicado")
        unique_enemy_ids[enemy_id] = true
        enemies.append(_enemy_actor(spec))
    var heroes: Array = []
    var formation: Dictionary = roster["formation"]
    for slot in HERO_SYSTEM.SLOTS:
        var hero_id: String = str(formation.get(slot, ""))
        if hero_id.is_empty():
            continue
        var hero: Dictionary = HERO_SYSTEM.hero_by_id(catalog, hero_id)
        heroes.append(_hero_actor(hero, slot))
    if heroes.is_empty() or heroes.size() > MAX_HEROES:
        return _error("expedicao_pve_exige_de_1_a_4_herois")
    var normalized_seed: int = _normalized_seed(seed)
    var state: Dictionary = {
        "ok": true, "rule_version": RULE_VERSION, "kind": "pve_offline",
        "status": "active", "winner": "", "round": 0, "max_rounds": MAX_ROUNDS,
        "seed": normalized_seed, "rng_state": normalized_seed, "posture": posture,
        "heroes": heroes, "enemies": enemies, "events": [], "damage_heroes": 0,
        "damage_enemies": 0, "skills_used": 0, "reward_issued": false
    }
    _event(state, "battle_started", {"seed": normalized_seed, "heroes": heroes.size(), "enemies": enemies.size(), "posture": posture})
    return state

static func _is_alive(actors: Array) -> bool:
    for actor in actors:
        if int(actor["hp"]) > 0:
            return true
    return false

static func _winner(state: Dictionary) -> String:
    var alive_heroes: bool = _is_alive(state["heroes"])
    var alive_enemies: bool = _is_alive(state["enemies"])
    if not alive_heroes:
        return "enemies"
    if not alive_enemies:
        return "heroes"
    if int(state["round"]) >= MAX_ROUNDS:
        return "draw"
    return ""

static func _finish_if_needed(state: Dictionary) -> void:
    var result: String = _winner(state)
    if result.is_empty():
        return
    state["winner"] = result
    state["status"] = "resolved"
    _event(state, "battle_resolved", {
        "winner": result, "rounds": state["round"],
        "damage_heroes": state["damage_heroes"], "damage_enemies": state["damage_enemies"],
        "skills_used": state["skills_used"], "reward_issued": false
    })

static func _turn_order(state: Dictionary) -> Array:
    var actions: Array = []
    for side in ["heroes", "enemies"]:
        var party: Array = state[side]
        for i in range(party.size()):
            var unit: Dictionary = party[i]
            if int(unit["hp"]) > 0:
                actions.append({"side": side, "index": i, "initiative": int(unit["initiative"]), "key": str(unit["id"])})
    actions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        if int(a["initiative"]) == int(b["initiative"]):
            return str(a["key"]) < str(b["key"])
        return int(a["initiative"]) > int(b["initiative"])
    )
    return actions

static func _find_target(party: Array, round_number: int, forced_id: String = "", favor_marked: bool = false) -> int:
    var viable: Array[int] = []
    var front_exists := false
    for i in range(party.size()):
        if int(party[i]["hp"]) > 0 and str(party[i]["line"]) == "front":
            front_exists = true
    for i in range(party.size()):
        var target: Dictionary = party[i]
        if int(target["hp"]) <= 0:
            continue
        if front_exists and str(target["line"]) != "front":
            continue
        viable.append(i)
    for i in viable:
        if str(party[i]["id"]) == forced_id:
            return i
    if favor_marked:
        for i in viable:
            if int(party[i]["mark_until"]) >= round_number:
                return i
    # Critério fixo: menor percentual de PV; empate pelo slot/ordem de entrada.
    var index := -1
    for i in viable:
        if index < 0:
            index = i
        else:
            var unit: Dictionary = party[i]
            var choice: Dictionary = party[index]
            if int(unit["hp"]) * int(choice["max_hp"]) < int(choice["hp"]) * int(unit["max_hp"]):
                index = i
    return index

static func _heal_target(party: Array) -> int:
    var best := -1
    for i in range(party.size()):
        var unit: Dictionary = party[i]
        if int(unit["hp"]) <= 0 or int(unit["hp"]) >= int(unit["max_hp"]):
            continue
        if best < 0:
            best = i
        else:
            var chosen: Dictionary = party[best]
            if int(unit["hp"]) * int(chosen["max_hp"]) < int(chosen["hp"]) * int(unit["max_hp"]):
                best = i
    return best

static func _try_skill(state: Dictionary, actor: Dictionary, mode: String, forced_skill_id: String) -> bool:
    if str(actor["side"]) != "heroes":
        return false
    var hero_id: String = str(actor["id"])
    var cost: int = int(actor["skill_focus_cost"])
    var cooldown: int = int(actor["skill_cooldown"])
    var action := ""
    match hero_id:
        "hero_pietro_001":
            action = "muralha"
        "hero_henzo_002":
            action = "trilha"
        "hero_giulia_003":
            action = "alento"
        "hero_arthur_004":
            action = "impeto"
        _:
            return false
    if int(actor["focus"]) < cost or int(state["round"]) < int(actor["next_skill_round"]):
        return false
    if mode == "manual" and forced_skill_id != hero_id:
        return false
    var rounds: int = int(state["round"])
    var targets: Array = state["enemies"]
    var allies: Array = state["heroes"]
    var target_index := -1
    var healed := 0
    if action == "muralha":
        if rounds >= MAX_ROUNDS:
            return false
        var protected := 0
        for ally in allies:
            if int(ally["hp"]) > 0 and str(ally["line"]) == "front":
                protected += 1
        if protected == 0:
            return false
    elif action == "trilha":
        target_index = _find_target(targets, rounds)
        if target_index < 0 or int(targets[target_index]["mark_until"]) >= rounds:
            return false
        if rounds >= MAX_ROUNDS:
            return false
    elif action == "alento":
        target_index = _heal_target(allies)
        if target_index < 0:
            return false
        var patient: Dictionary = allies[target_index]
        healed = mini(int(patient["max_hp"]) - int(patient["hp"]), roundi(float(patient["max_hp"]) * 0.12))
        if mode == "auto" and healed < roundi(float(patient["max_hp"]) * 0.1):
            return false
    elif action == "impeto":
        if bool(actor["empowered"]) or rounds >= MAX_ROUNDS:
            return false
    actor["focus"] = int(actor["focus"]) - cost
    actor["next_skill_round"] = rounds + cooldown
    actor["skill_uses"] = int(actor["skill_uses"]) + 1
    state["skills_used"] = int(state["skills_used"]) + 1
    _event(state, "focus_spent", {"actor_id": hero_id, "amount": cost, "remaining": actor["focus"]})
    match action:
        "muralha":
            for ally in allies:
                if int(ally["hp"]) > 0 and str(ally["line"]) == "front":
                    ally["shield_round"] = rounds + 1
            _event(state, "skill_triggered", {"actor_id": hero_id, "skill": "Muralha do Primeiro Povo", "shield_next_round": rounds + 1})
        "trilha":
            var prey: Dictionary = targets[target_index]
            prey["mark_until"] = rounds + 1
            _event(state, "skill_triggered", {"actor_id": hero_id, "skill": "Trilha Oculta", "target_id": prey["id"], "mark_until": prey["mark_until"]})
        "alento":
            var patient: Dictionary = allies[target_index]
            patient["hp"] = mini(int(patient["max_hp"]), int(patient["hp"]) + healed)
            _event(state, "skill_triggered", {"actor_id": hero_id, "skill": "Alento da Aurora", "target_id": patient["id"]})
            _event(state, "healed", {"actor_id": hero_id, "target_id": patient["id"], "amount": healed, "target_hp": patient["hp"]})
        "impeto":
            actor["empowered"] = true
            _event(state, "skill_triggered", {"actor_id": hero_id, "skill": "Ímpeto da Chama"})
    return true

static func _basic_attack(state: Dictionary, actor: Dictionary, target: Dictionary) -> void:
    var physical: bool = str(actor["attack_type"]) == "physical"
    var attack: int = int(actor["attack_physical"]) if physical else int(actor["attack_magic"])
    var defense: int = int(target["defense_physical"]) if physical else int(target["defense_magic"])
    var round_number: int = int(state["round"])
    var coefficient := 1.0
    var hero_side: bool = str(actor["side"]) == "heroes"
    if hero_side and str(actor["id"]) == "hero_arthur_004":
        if bool(actor["empowered"]):
            coefficient *= 1.20
            actor["empowered"] = false
            actor["vulnerable_until"] = round_number + 1
        if int(actor["hp"]) * 2 < int(actor["max_hp"]):
            coefficient *= 1.05
    if hero_side and int(target["mark_until"]) >= round_number:
        coefficient *= 1.10
        target["mark_until"] = 0
        target["mark_consumed"] = true
    if str(state["posture"]) == "agressiva":
        coefficient *= 1.10 if hero_side else 1.0
    elif str(state["posture"]) == "cautelosa":
        coefficient *= 0.90 if hero_side else 1.0
    var is_critical: bool = _roll(state) < float(actor["crit_percent"]) / 100.0
    var amount: int = damage_amount(attack, defense, coefficient, 1.0, 1.0, is_critical)
    if not hero_side:
        if str(state["posture"]) == "agressiva":
            amount = maxi(1, roundi(float(amount) * 1.10))
        elif str(state["posture"]) == "cautelosa":
            amount = maxi(1, roundi(float(amount) * 0.90))
    var mitigated := 0
    if int(target["shield_round"]) == round_number:
        var reduction: int = roundi(float(amount) * 0.15)
        amount = maxi(1, amount - reduction)
        mitigated += reduction
    if not hero_side and str(target["id"]) == "hero_pietro_001" and physical and not bool(target["first_hit_used"]):
        target["first_hit_used"] = true
        var reduction: int = roundi(float(amount) * 0.05)
        amount = maxi(1, amount - reduction)
        mitigated += reduction
    if int(target["vulnerable_until"]) >= round_number and str(target["id"]) == "hero_arthur_004":
        amount = maxi(1, roundi(float(amount) * 1.05))
    var applied: int = mini(int(target["hp"]), amount)
    _event(state, "attack_started", {"actor_id": actor["id"], "target_id": target["id"], "attack_type": actor["attack_type"]})
    if mitigated > 0:
        _event(state, "shield_blocked", {"target_id": target["id"], "amount": mitigated})
    target["hp"] = int(target["hp"]) - applied
    if hero_side:
        state["damage_heroes"] = int(state["damage_heroes"]) + applied
    else:
        state["damage_enemies"] = int(state["damage_enemies"]) + applied
    _event(state, "damage_applied", {"actor_id": actor["id"], "target_id": target["id"], "amount": applied, "critical": is_critical, "target_hp": target["hp"]})

static func advance_round(previous: Dictionary, orders: Dictionary = {}) -> Dictionary:
    if not bool(previous.get("ok", false)) or str(previous.get("status", "")) != "active":
        return _error("combate_nao_ativo")
    var state: Dictionary = previous.duplicate(true)
    var mode: String = str(orders.get("skills_mode", "auto"))
    if not ["auto", "manual", "none"].has(mode):
        return _error("modo_habilidade_invalido")
    var posture: String = str(orders.get("posture", state["posture"]))
    if not VALID_POSTURES.has(posture):
        return _error("postura_invalida")
    state["posture"] = posture
    state["round"] = int(state["round"]) + 1
    var round_number: int = int(state["round"])
    _event(state, "round_started", {"posture": posture})
    var order: Array = _turn_order(state)
    for action in order:
        var side: String = str(action["side"])
        var party: Array = state[side]
        var unit: Dictionary = party[int(action["index"])]
        if int(unit["hp"]) <= 0:
            continue
        var opponent_side: String = "enemies" if side == "heroes" else "heroes"
        var opponents: Array = state[opponent_side]
        if not _is_alive(opponents):
            break
        if mode != "none" and _try_skill(state, unit, mode, str(orders.get("activate_hero_id", ""))):
            continue
        var forced_id: String = str(orders.get("focus_enemy_id", "")) if side == "heroes" else ""
        var target_index: int = _find_target(opponents, round_number, forced_id, side == "heroes")
        if target_index < 0:
            break
        _basic_attack(state, unit, opponents[target_index])
    for enemy in state["enemies"]:
        if int(enemy["mark_until"]) <= round_number:
            enemy["mark_until"] = 0
    _event(state, "round_ended", {"heroes_alive": _is_alive(state["heroes"]), "enemies_alive": _is_alive(state["enemies"])})
    _finish_if_needed(state)
    return state

static func simulate(catalog: Dictionary, roster: Dictionary, enemy_specs: Array, seed: int, orders: Dictionary = {}) -> Dictionary:
    var state: Dictionary = begin_battle(catalog, roster, enemy_specs, seed, str(orders.get("posture", "equilibrada")))
    if not bool(state.get("ok", false)):
        return state
    while str(state["status"]) == "active":
        state = advance_round(state, orders)
        if not bool(state.get("ok", false)):
            return state
    return state

static func result_digest(state: Dictionary) -> String:
    if not bool(state.get("ok", false)) or str(state.get("status", "")) != "resolved":
        return ""
    return JSON.stringify({
        "rules": RULE_VERSION, "seed": state["seed"], "winner": state["winner"],
        "events": state["events"], "heroes": state["heroes"], "enemies": state["enemies"]
    }).sha256_text()
