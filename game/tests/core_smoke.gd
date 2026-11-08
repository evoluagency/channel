extends SceneTree
## Testes do núcleo sem acessar o progresso do app.
const ECONOMY = preload("res://scripts/core/economy.gd")
const SAVE_STORE = preload("res://scripts/core/save_store.gd")
const INPUT_ACTIONS = preload("res://scripts/core/input_actions.gd")
const TEST_PATH := "user://valdora_cp001_core_smoke.tmp"

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var checks := {}
    var buy: Dictionary = ECONOMY.transact("buy_potion", 30, 0, 0)
    checks["compra"] = buy["accepted"] and buy["coins"] == 20 and buy["potions"] == 1
    var denied: Dictionary = ECONOMY.transact("buy_potion", 9, 0, 0)
    checks["compra_insuficiente"] = not denied["accepted"] and denied["coins"] == 9
    var deposit: Dictionary = ECONOMY.transact("deposit", 20, 0, 1)
    checks["deposito"] = deposit["accepted"] and deposit["coins"] == 15 and deposit["bank_coins"] == 5
    var withdraw: Dictionary = ECONOMY.transact("withdraw", 15, 5, 1)
    checks["saque"] = withdraw["accepted"] and withdraw["coins"] == 20 and withdraw["bank_coins"] == 0
    var invalid: Dictionary = ECONOMY.transact("deposit", -1, 0, 0)
    checks["saldo_negativo_bloqueado"] = not invalid["accepted"]
    var unknown: Dictionary = ECONOMY.transact("unknown", 20, 0, 1)
    checks["acao_desconhecida"] = not unknown["accepted"] and unknown["coins"] == 20
    checks["salvamento"] = SAVE_STORE.save_game(TEST_PATH, 20, 5, 1)
    var saved: Dictionary = SAVE_STORE.load_game(TEST_PATH, 30)
    checks["leitura_legado"] = saved["coins"] == 20 and saved["bank_coins"] == 5 and saved["potions"] == 1
    var raw = JSON.parse_string(FileAccess.get_file_as_string(TEST_PATH))
    checks["schema_v1"] = raw is Dictionary and raw.get("version") == 1
    checks["salvamento_negativo_bloqueado"] = not SAVE_STORE.save_game(TEST_PATH, -1, 0, 0)
    var retained: Dictionary = SAVE_STORE.load_game(TEST_PATH, 30)
    checks["negativa_nao_sobrescreve"] = retained["coins"] == 20
    DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
    INPUT_ACTIONS.configure()
    checks["entrada_teclado"] = InputMap.has_action("channel_interact")
    var passed := 0
    for key in checks.keys():
        if checks[key]:
            passed += 1
    var ok := passed == checks.size()
    print("[VALDORA_CP001_CORE] ", JSON.stringify({"ok":ok,"passed":passed,"total":checks.size(),"checks":checks}))
    quit(0 if ok else 1)
