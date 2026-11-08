extends RefCounted
## CP002-B: catálogo imutável, cálculos derivados e formação local independente.
## A prévia não concede desbloqueios reais nem altera o save econômico do CP001.

const CATALOG_PATH := "res://data/valdora_heroes_v0.1.json"
const SAVE_PATH := "user://valdora_hero_roster_v1.json"
const SLOTS := ["vanguarda_1", "vanguarda_2", "retaguarda_1", "retaguarda_2", "retaguarda_3"]
const ATTRS := ["VIG", "FOR", "TEC", "INT", "ESP", "AGI"]
const EXPECTED_IDS := ["hero_pietro_001", "hero_henzo_002", "hero_giulia_003", "hero_arthur_004"]

static func hero_by_id(catalog: Dictionary, hero_id: String) -> Dictionary:
    var heroes: Array = catalog.get("heroes", [])
    for hero in heroes:
        if hero is Dictionary and str(hero.get("hero_id", "")) == hero_id:
            return hero
    return {}

static func catalog_is_valid(catalog: Dictionary) -> bool:
    if str(catalog.get("schema", "")) != "valdora.hero_catalog.v0.1":
        return false
    if int(catalog.get("catalog_version", 0)) != 1:
        return false
    if int(catalog.get("season_1_days", 0)) != 60:
        return false
    var heroes: Array = catalog.get("heroes", [])
    if heroes.size() != 4:
        return false
    var seen: Array = []
    for hero in heroes:
        if not hero is Dictionary:
            return false
        var hero_id: String = str(hero.get("hero_id", ""))
        if not EXPECTED_IDS.has(hero_id) or seen.has(hero_id):
            return false
        seen.append(hero_id)
        var attributes: Dictionary = hero.get("attributes_level1", {})
        if attributes.size() != ATTRS.size():
            return false
        var total := 0
        for attribute in ATTRS:
            if not attributes.has(attribute):
                return false
            var value: int = int(attributes.get(attribute, -1))
            if value < 10 or value > 16:
                return false
            total += value
        if total != 66:
            return false
        if not ["vanguarda", "retaguarda"].has(str(hero.get("formation_position", ""))):
            return false
        if not hero.has("skills") or not hero.has("appearance"):
            return false
        if str(hero.get("display_name", "")).is_empty():
            return false
    return true

static func load_catalog() -> Dictionary:
    if not FileAccess.file_exists(CATALOG_PATH):
        return {}
    var content: String = FileAccess.get_file_as_string(CATALOG_PATH)
    var parsed: Variant = JSON.parse_string(content)
    if not parsed is Dictionary:
        return {}
    var catalog: Dictionary = parsed
    return catalog if catalog_is_valid(catalog) else {}

static func derived_stats(hero: Dictionary, level: int = 1) -> Dictionary:
    var a: Dictionary = hero.get("attributes_level1", {})
    if a.is_empty() or level < 1:
        return {}
    var vigor: int = int(a.get("VIG", 0))
    var strength: int = int(a.get("FOR", 0))
    var technique: int = int(a.get("TEC", 0))
    var intellect: int = int(a.get("INT", 0))
    var spirit: int = int(a.get("ESP", 0))
    var agility: int = int(a.get("AGI", 0))
    return {
        "HP": 100 + 12 * vigor + 8 * (level - 1),
        "focus": 50 + 4 * spirit + 2 * (level - 1),
        "physical_attack": 20 + 3 * strength + technique,
        "magic_attack": 20 + 3 * intellect + spirit,
        "physical_defense": 10 + 2 * vigor,
        "magic_defense": 10 + 2 * spirit,
        "initiative": 10 + agility,
        "critical_percent": minf(20.0, maxf(5.0, 5.0 + 0.15 * float(agility - 10)))
    }

static func empty_formation() -> Dictionary:
    var formation: Dictionary = {}
    for slot in SLOTS:
        formation[slot] = ""
    return formation

static func default_roster() -> Dictionary:
    var formation: Dictionary = empty_formation()
    formation["vanguarda_1"] = "hero_pietro_001"
    formation["vanguarda_2"] = "hero_arthur_004"
    formation["retaguarda_1"] = "hero_henzo_002"
    formation["retaguarda_2"] = "hero_giulia_003"
    return {"version": 1, "selected_hero_id": "hero_pietro_001", "formation": formation}

static func slot_accepts(slot: String, hero: Dictionary) -> bool:
    if not SLOTS.has(slot) or hero.is_empty():
        return false
    var position: String = "vanguarda" if slot.begins_with("vanguarda") else "retaguarda"
    return str(hero.get("formation_position", "")) == position

static func normalize_roster(candidate: Variant, catalog: Dictionary) -> Dictionary:
    var result: Dictionary = default_roster()
    if not catalog_is_valid(catalog):
        return result
    if not candidate is Dictionary:
        return result
    var source: Dictionary = candidate
    if int(source.get("version", -1)) != 1:
        return result
    var selected: String = str(source.get("selected_hero_id", ""))
    result["selected_hero_id"] = selected if not hero_by_id(catalog, selected).is_empty() else "hero_pietro_001"
    var saved_formation: Variant = source.get("formation", {})
    if not saved_formation is Dictionary:
        return result
    var formation: Dictionary = empty_formation()
    var seen: Array = []
    for slot in SLOTS:
        var hero_id: String = str(saved_formation.get(slot, ""))
        if hero_id.is_empty():
            continue
        var hero: Dictionary = hero_by_id(catalog, hero_id)
        if slot_accepts(slot, hero) and not seen.has(hero_id):
            formation[slot] = hero_id
            seen.append(hero_id)
    result["formation"] = formation
    return result

static func roster_is_valid(candidate: Variant, catalog: Dictionary) -> bool:
    if not candidate is Dictionary or not catalog_is_valid(catalog):
        return false
    var state: Dictionary = candidate
    if int(state.get("version", 0)) != 1:
        return false
    if hero_by_id(catalog, str(state.get("selected_hero_id", ""))).is_empty():
        return false
    var formation: Variant = state.get("formation", {})
    if not formation is Dictionary or formation.size() != SLOTS.size():
        return false
    var seen: Array = []
    for slot in SLOTS:
        if not formation.has(slot):
            return false
        var hero_id: String = str(formation.get(slot, ""))
        if hero_id.is_empty():
            continue
        if seen.has(hero_id) or not slot_accepts(slot, hero_by_id(catalog, hero_id)):
            return false
        seen.append(hero_id)
    return true

static func assign(state: Dictionary, catalog: Dictionary, slot: String, hero_id: String) -> Dictionary:
    var hero: Dictionary = hero_by_id(catalog, hero_id)
    if not slot_accepts(slot, hero):
        return {"ok": false, "state": state, "message": "Este herói não ocupa essa linha de combate."}
    var next_state: Dictionary = normalize_roster(state, catalog)
    var formation: Dictionary = next_state.get("formation", {})
    for other_slot in SLOTS:
        if str(formation.get(other_slot, "")) == hero_id:
            formation[other_slot] = ""
    formation[slot] = hero_id
    next_state["formation"] = formation
    next_state["selected_hero_id"] = hero_id
    return {"ok": true, "state": next_state, "message": "Herói colocado na formação."}

static func remove_selected(state: Dictionary, catalog: Dictionary) -> Dictionary:
    var next_state: Dictionary = normalize_roster(state, catalog)
    var selected: String = str(next_state.get("selected_hero_id", ""))
    var formation: Dictionary = next_state.get("formation", {})
    for slot in SLOTS:
        if str(formation.get(slot, "")) == selected:
            formation[slot] = ""
    next_state["formation"] = formation
    return next_state

static func load_roster(catalog: Dictionary, path: String = SAVE_PATH) -> Dictionary:
    if not FileAccess.file_exists(path):
        return default_roster()
    var raw: String = FileAccess.get_file_as_string(path)
    var parsed: Variant = JSON.parse_string(raw)
    if parsed == null:
        return default_roster()
    return normalize_roster(parsed, catalog)

static func save_roster(path: String, roster: Dictionary, catalog: Dictionary) -> bool:
    if not roster_is_valid(roster, catalog):
        return false
    var temp: String = path + ".tmp"
    var file: FileAccess = FileAccess.open(temp, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(roster))
    file.flush()
    file.close()
    var temp_absolute: String = ProjectSettings.globalize_path(temp)
    var path_absolute: String = ProjectSettings.globalize_path(path)
    var renamed: Error = DirAccess.rename_absolute(temp_absolute, path_absolute)
    if renamed != OK:
        DirAccess.remove_absolute(temp_absolute)
        return false
    return true
