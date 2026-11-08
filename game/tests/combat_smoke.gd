extends SceneTree
## CP003 — suíte headless. Nenhuma cena 3D, arquivo de save ou SDK Android.
const HERO_SYSTEM := preload("res://scripts/heroes/hero_system.gd")
const COMBAT := preload("res://scripts/combat/pve_engine.gd")

static func enemies(health: int = 250) -> Array:
    return [
        {"id": "enemy_stalker", "name": "Predador da encosta", "line": "front", "hp": health, "attack": 42, "defense": 24, "initiative": 25, "attack_type": "physical"},
        {"id": "enemy_tracker", "name": "Caçador rival", "line": "back", "hp": health, "attack": 36, "defense": 18, "initiative": 18, "attack_type": "physical"}
    ]

static func find_events(state: Dictionary, event_name: String) -> Array:
    var found: Array = []
    for e in state.get("events", []):
        if str(e.get("type", "")) == event_name:
            found.append(e)
    return found

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var checks: Dictionary = {}
    var catalog: Dictionary = HERO_SYSTEM.load_catalog()
    var roster: Dictionary = HERO_SYSTEM.default_roster()
    var input_enemies: Array = enemies()
    var catalog_snapshot: String = JSON.stringify(catalog)
    var roster_snapshot: String = JSON.stringify(roster)
    var enemy_snapshot: String = JSON.stringify(input_enemies)
    var started: Dictionary = COMBAT.begin_battle(catalog, roster, input_enemies, 2026)
    checks["initial_valid"] = bool(started.get("ok", false)) and str(started.get("status", "")) == "active"
    checks["hero_limit_and_formation"] = started.get("heroes", []).size() == 4 and started.get("enemies", []).size() == 2
    checks["initial_round_zero"] = int(started.get("round", -1)) == 0 and started.get("events", []).size() == 1
    checks["initial_hero_stats"] = int(started["heroes"][0]["max_hp"]) == 268 and int(started["heroes"][1]["attack_physical"]) == 72
    checks["formula_gdd_52"] = COMBAT.damage_amount(56, 30, 1.2) == 52
    checks["minimum_damage"] = COMBAT.damage_amount(1, 500) == 1
    checks["terrain_limits"] = COMBAT.damage_amount(100, 0, 1.0, 200.0) == COMBAT.damage_amount(100, 0, 1.0, 1.1)
    checks["unit_limits"] = COMBAT.damage_amount(100, 0, 1.0, 1.0, 10.0) == 115
    checks["fortification_limits"] = COMBAT.damage_amount(100, 0, 1.0, 1.0, 1.0, false, 2.0) == 80
    checks["critical_one_point_five"] = COMBAT.damage_amount(100, 0, 1.0, 1.0, 1.0, true) == 150

    var first: Dictionary = COMBAT.advance_round(started)
    checks["advance_round"] = bool(first.get("ok", false)) and int(first.get("round", 0)) == 1
    checks["no_mutation_previous"] = int(started.get("round", -1)) == 0 and started.get("events", []).size() == 1
    checks["round_has_attack"] = find_events(first, "attack_started").size() > 0 and find_events(first, "damage_applied").size() > 0
    checks["round_has_mark"] = find_events(first, "skill_triggered").any(func(e: Dictionary): return str(e.get("skill", "")) == "Trilha Oculta")
    checks["front_protected_targeting"] = find_events(first, "damage_applied").all(func(e: Dictionary): return str(e.get("target_id", "")) != "enemy_tracker")
    var full: Dictionary = COMBAT.simulate(catalog, roster, input_enemies, 2026)
    var again: Dictionary = COMBAT.simulate(catalog, roster, input_enemies, 2026)
    checks["battle_resolved"] = bool(full.get("ok", false)) and str(full.get("status", "")) == "resolved"
    checks["round_cap"] = int(full.get("round", 0)) >= 1 and int(full.get("round", 9)) <= 8
    checks["deterministic_repeat"] = JSON.stringify(full) == JSON.stringify(again)
    checks["digest_repeat"] = not COMBAT.result_digest(full).is_empty() and COMBAT.result_digest(full) == COMBAT.result_digest(again)
    checks["seed_recorded"] = int(full.get("seed", 0)) > 0 and int(full.get("rule_version", 0)) == 1
    checks["battle_event_ending"] = find_events(full, "battle_resolved").size() == 1
    checks["no_reward_authority"] = not bool(full.get("reward_issued", true)) and not bool(find_events(full, "battle_resolved")[0].get("reward_issued", true))
    checks["source_not_mutated"] = JSON.stringify(catalog) == catalog_snapshot and JSON.stringify(roster) == roster_snapshot and JSON.stringify(input_enemies) == enemy_snapshot
    var bounded := true
    for side in ["heroes", "enemies"]:
        for actor in full[side]:
            bounded = bounded and int(actor["hp"]) >= 0 and int(actor["hp"]) <= int(actor["max_hp"]) and int(actor["focus"]) >= 0
    checks["health_focus_bounded"] = bounded

    var no_skills: Dictionary = COMBAT.simulate(catalog, roster, enemies(1800), 84, {"skills_mode": "none"})
    checks["disabled_skills"] = find_events(no_skills, "skill_triggered").size() == 0
    checks["max_eight_rounds"] = int(no_skills.get("round", -1)) == 8 and str(no_skills.get("winner", "")) == "draw"
    var fast_enemy: Array = [
        {"id":"fragile", "name":"Presa", "line":"front", "hp":1, "attack":1, "defense":0, "initiative":1, "attack_type":"physical"}
    ]
    var short_battle: Dictionary = COMBAT.simulate(catalog, roster, fast_enemy, 123)
    checks["early_victory"] = str(short_battle.get("winner", "")) == "heroes" and int(short_battle.get("round", 9)) == 1

    var manual_henzo: Dictionary = COMBAT.advance_round(COMBAT.begin_battle(catalog, roster, enemies(2000), 17), {"skills_mode":"manual", "activate_hero_id":"hero_henzo_002"})
    checks["henzo_manual_skill"] = find_events(manual_henzo, "skill_triggered").any(func(e: Dictionary): return str(e.get("skill", "")) == "Trilha Oculta")
    checks["henzo_mark_consumed"] = bool(manual_henzo["enemies"][0]["mark_consumed"])
    var manual_arthur: Dictionary = COMBAT.advance_round(COMBAT.begin_battle(catalog, roster, enemies(2000), 19), {"skills_mode":"manual", "activate_hero_id":"hero_arthur_004"})
    checks["arthur_manual_skill"] = find_events(manual_arthur, "skill_triggered").any(func(e: Dictionary): return str(e.get("skill", "")) == "Ímpeto da Chama")
    var arthur_second: Dictionary = COMBAT.advance_round(manual_arthur, {"skills_mode": "none"})
    checks["arthur_next_attack"] = not bool(arthur_second["heroes"][1]["empowered"]) and int(arthur_second["heroes"][1]["vulnerable_until"]) == 3

    var healer_state: Dictionary = COMBAT.begin_battle(catalog, roster, enemies(2000), 99)
    healer_state["heroes"][0]["hp"] = 110
    var healer_result: Dictionary = COMBAT.advance_round(healer_state, {"skills_mode":"manual", "activate_hero_id":"hero_giulia_003"})
    checks["giulia_heals"] = find_events(healer_result, "healed").size() == 1 and int(find_events(healer_result,"healed")[0].get("amount",0)) > 0
    checks["giulia_no_revive"] = true
    for unit in healer_result["heroes"]:
        if int(unit["hp"]) == 0 and str(unit["id"]) == "hero_pietro_001":
            checks["giulia_no_revive"] = false
    var manual_pietro: Dictionary = COMBAT.advance_round(COMBAT.begin_battle(catalog, roster, enemies(2000), 42), {"skills_mode":"manual", "activate_hero_id":"hero_pietro_001"})
    checks["pietro_next_round"] = find_events(manual_pietro, "skill_triggered").any(func(e: Dictionary): return str(e.get("skill", "")) == "Muralha do Primeiro Povo") and int(manual_pietro["heroes"][0]["shield_round"]) == 2
    var pietro_second: Dictionary = COMBAT.advance_round(manual_pietro, {"skills_mode":"none"})
    checks["pietro_blocked"] = find_events(pietro_second, "shield_blocked").size() >= 1
    checks["cooldown_not_ready"] = int(manual_pietro["heroes"][0]["next_skill_round"]) == 4

    var invalid: Array = enemies(200)
    invalid[1]["id"] = invalid[0]["id"]
    checks["invalid_duplicate_enemy"] = not bool(COMBAT.begin_battle(catalog, roster, invalid, 1).get("ok", true))
    checks["invalid_posture"] = not bool(COMBAT.begin_battle(catalog, roster, enemies(), 1, "invencivel").get("ok", true))
    checks["cannot_resume_finished"] = not bool(COMBAT.advance_round(short_battle).get("ok", true))
    var empty_roster: Dictionary = roster.duplicate(true)
    for slot in HERO_SYSTEM.SLOTS:
        empty_roster["formation"][slot] = ""
    checks["empty_roster_rejected"] = not bool(COMBAT.begin_battle(catalog, empty_roster, enemies(), 1).get("ok", true))
    var fake_enemy: Array = enemies()
    fake_enemy[0]["hp"] = -10
    checks["negative_enemy_hp_rejected"] = not bool(COMBAT.begin_battle(catalog, roster, fake_enemy, 1).get("ok", true))
    checks["invalid_orders_rejected"] = not bool(COMBAT.advance_round(started, {"posture":"desconhecida"}).get("ok", true))

    var failures: Array = []
    var passed := 0
    for key in checks.keys():
        if checks[key]:
            passed += 1
        else:
            failures.append(key)
    var ok := passed == checks.size()
    print("[VALDORA_CP003_COMBAT] ", JSON.stringify({"ok":ok,"passed":passed,"total":checks.size(),"failed":failures}))
    quit(0 if ok else 1)
