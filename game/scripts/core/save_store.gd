extends RefCounted
## Preserva schema legado version=1 e user://channel_save.json.
static func load_game(path: String, initial_gold: int) -> Dictionary:
    var defaults := {"coins": initial_gold, "bank_coins": 0, "potions": 0}
    if not FileAccess.file_exists(path):
        return defaults
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return defaults
    var parsed = JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary:
        return defaults
    return {
        "coins": maxi(0, int(parsed.get("coins", initial_gold))),
        "bank_coins": maxi(0, int(parsed.get("bank_coins", 0))),
        "potions": maxi(0, int(parsed.get("potions", 0)))
    }

static func save_game(path: String, coins: int, bank_coins: int, potions: int) -> bool:
    if coins < 0 or bank_coins < 0 or potions < 0:
        return false
    var save_data := {"version": 1, "coins": coins, "bank_coins": bank_coins, "potions": potions}
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(save_data))
    file.flush()
    file.close()
    return true
