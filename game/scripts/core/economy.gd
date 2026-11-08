extends RefCounted
## Regras determinísticas da economia local. Não acessa rede nem disco.
const POTION_PRICE := 10
const BANK_STEP := 5

static func transact(action: String, coins: int, bank_coins: int, potions: int) -> Dictionary:
    var result := {
        "accepted": false,
        "message": "",
        "coins": coins,
        "bank_coins": bank_coins,
        "potions": potions
    }
    if coins < 0 or bank_coins < 0 or potions < 0:
        result["message"] = "Saldo invalido; transacao cancelada."
        return result
    match action:
        "buy_potion":
            if coins >= POTION_PRICE:
                result["coins"] = coins - POTION_PRICE
                result["potions"] = potions + 1
                result["accepted"] = true
                result["message"] = "Poção comprada! Ela foi salva no seu inventário."
            else:
                result["message"] = "Você precisa de 10 moedas para comprar uma poção."
        "deposit":
            if coins >= BANK_STEP:
                result["coins"] = coins - BANK_STEP
                result["bank_coins"] = bank_coins + BANK_STEP
                result["accepted"] = true
                result["message"] = "5 moedas depositadas no Banco Real."
            else:
                result["message"] = "Saldo insuficiente para o depósito."
        "withdraw":
            if bank_coins >= BANK_STEP:
                result["bank_coins"] = bank_coins - BANK_STEP
                result["coins"] = coins + BANK_STEP
                result["accepted"] = true
                result["message"] = "5 moedas sacadas do Banco Real."
            else:
                result["message"] = "Saldo bancário insuficiente."
    return result
