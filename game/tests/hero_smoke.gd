extends SceneTree
## CP002-B: valida regras e persistência em arquivo de teste, nunca no save real.
const HERO_SYSTEM := preload("res://scripts/heroes/hero_system.gd")
const TEST_PATH := "user://valdora_cp002_roster_smoke.tmp"

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var checks: Dictionary = {}
    var catalog: Dictionary = HERO_SYSTEM.load_catalog()
    checks["catalogo"] = HERO_SYSTEM.catalog_is_valid(catalog)
    var names: Array = []
    for hero in catalog.get("heroes", []):
        names.append(hero.get("display_name",""))
    checks["quatro_nomes"] = names == ["Pietro", "Henzo", "Giulia", "Arthur"]
    checks["atributos_pietro"] = HERO_SYSTEM.derived_stats(HERO_SYSTEM.hero_by_id(catalog, "hero_pietro_001")).get("HP", 0) == 268
    checks["atributos_giulia"] = HERO_SYSTEM.derived_stats(HERO_SYSTEM.hero_by_id(catalog, "hero_giulia_003")).get("focus", 0) == 102
    var original: Dictionary = HERO_SYSTEM.default_roster()
    checks["formacao_padrao"] = HERO_SYSTEM.roster_is_valid(original, catalog)
    var rejected: Dictionary = HERO_SYSTEM.assign(original, catalog, "vanguarda_2", "hero_giulia_003")
    checks["posicao_invalida"] = not bool(rejected.get("ok", true))
    var moved: Dictionary = HERO_SYSTEM.assign(original, catalog, "vanguarda_2", "hero_pietro_001")
    var slots: Dictionary = moved.get("state", {}).get("formation", {})
    checks["sem_duplicacao"] = bool(moved.get("ok", false)) and str(slots.get("vanguarda_1", "")) == "" and str(slots.get("vanguarda_2", "")) == "hero_pietro_001"
    var removed: Dictionary = HERO_SYSTEM.remove_selected(moved.get("state", {}), catalog)
    checks["remocao"] = str(removed.get("formation", {}).get("vanguarda_2", "?")) == ""
    checks["persistencia_escrita"] = HERO_SYSTEM.save_roster(TEST_PATH, original, catalog)
    var restored: Dictionary = HERO_SYSTEM.load_roster(catalog, TEST_PATH)
    checks["persistencia_leitura"] = restored == original
    var invalid_state: Dictionary = original.duplicate(true)
    invalid_state["formation"]["vanguarda_1"] = "hero_giulia_003"
    checks["gravar_invalido_bloqueado"] = not HERO_SYSTEM.save_roster(TEST_PATH, invalid_state, catalog)
    checks["estado_preservado"] = HERO_SYSTEM.load_roster(catalog, TEST_PATH) == original
    var corrupted: Dictionary = original.duplicate(true)
    corrupted["formation"]["retaguarda_1"] = "hero_pietro_001"
    checks["normalizar_posicoes"] = str(HERO_SYSTEM.normalize_roster(corrupted, catalog).get("formation", {}).get("retaguarda_1", "?")) == ""
    DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
    var passed := 0
    for name in checks:
        if checks[name]:
            passed += 1
    var ok := passed == checks.size()
    print("[VALDORA_CP002_HEROES] ", JSON.stringify({"ok":ok,"passed":passed,"total":checks.size(),"checks":checks}))
    quit(0 if ok else 1)
