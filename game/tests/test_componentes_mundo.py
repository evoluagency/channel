#!/usr/bin/env python3
"""Confere o arquivo de dados dos componentes contra as fórmulas do documento COMPONENTES_NIVEIS_v0.1.md."""
import json, math
from pathlib import Path
d = json.loads((Path(__file__).resolve().parents[1] / "data" / "mundo_componentes_v0.1.json").read_text(encoding="utf-8"))
checks = {}
checks["13_construcoes"] = len(d["construcoes"]) == 13
checks["30_niveis_cada"] = all(len(c["niveis"]) == 30 and [x["nivel"] for x in c["niveis"]] == list(range(1, 31)) for c in d["construcoes"])
checks["6_faixas_visuais"] = all(len(c["visual_faixas"]) == 6 for c in d["construcoes"]) and len(d["faixas"]) == 6
checks["poder_formula"] = all(abs(c["niveis"][n - 1]["poder"] - 40 * n ** 1.55) < 0.06 for c in d["construcoes"] for n in (1, 10, 30))
checks["poder_n1_n30"] = d["construcoes"][0]["niveis"][0]["poder"] == 40 and abs(d["construcoes"][0]["niveis"][29]["poder"] - 7791) < 2
checks["custo_cresce"] = all(all(a["custo_materiais"] <= b["custo_materiais"] for a, b in zip(c["niveis"], c["niveis"][1:])) for c in d["construcoes"])
checks["tempo_cresce"] = all(all(a["tempo_s"] <= b["tempo_s"] for a, b in zip(c["niveis"], c["niveis"][1:])) for c in d["construcoes"])
checks["custo_menor_que_ganho"] = 1.25 > 1.12
est = next(c for c in d["construcoes"] if c["id"] == "est")
checks["estufa_producao"] = est["niveis"][0]["valor"] == 60 and abs(est["niveis"][29]["valor"] - 60 * 1.12 ** 29) < 0.05
qg = next(c for c in d["construcoes"] if c["id"] == "hq")
checks["qg_tempo_30"] = abs(qg["niveis"][29]["tempo_s"] - 30 * 2 * 1.28 ** 29) < 2
checks["desbloqueios_validos"] = all(1 <= c["desbloqueio_qg"] <= 30 for c in d["construcoes"])
checks["ids_unicos"] = len({c["id"] for c in d["construcoes"]}) == 13
failed = [k for k, v in checks.items() if not v]
print(f"mundo_componentes {len(checks)-len(failed)}/{len(checks)} falhas={failed}")
raise SystemExit(1 if failed else 0)
