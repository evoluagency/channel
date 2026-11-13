#!/usr/bin/env python3
"""Monta o ZIP do módulo Cidade SEM assinar, numa pasta de trabalho.

Uso: python3 tools/build_city_zip.py --version 10 [--out PASTA]
Saída: PASTA/city-<versão>.zip e PASTA/city-<versão>.zip.sha256 (padrão: dist/ota-trabalho/).
Não toca em site/updates/v2/, não assina, não publica. A assinatura é feita pelo dono,
no computador dele, com tools/ota_manifest.py --key-file (ver HANDOFF-1.1).
O ZIP é determinístico: mesma entrada, mesmo SHA-256.
"""
import argparse
import hashlib
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CITY = ROOT / "game" / "modules" / "city"
ENTRY = CITY / "valdora_modules" / "city" / "entry.tscn"
FILES = [  # (origem, caminho dentro do ZIP)
    (ENTRY, "valdora_modules/city/entry.tscn"),
    (CITY / "city.gd", "valdora_modules/city/city.gd"),
    (CITY / "fontes" / "Cinzel.ttf", "valdora_modules/city/fonts/Cinzel.ttf"),
    (CITY / "fontes" / "Montserrat.ttf", "valdora_modules/city/fonts/Montserrat.ttf"),
    (CITY / "fontes" / "OFL-Cinzel.txt", "valdora_modules/city/fonts/OFL-Cinzel.txt"),
    (CITY / "fontes" / "OFL-Montserrat.txt", "valdora_modules/city/fonts/OFL-Montserrat.txt"),
]

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--version", type=int, required=True)
    ap.add_argument("--out", type=Path, default=ROOT / "dist" / "ota-trabalho")
    a = ap.parse_args()
    if a.version < 1:
        raise SystemExit("versão deve ser positiva")
    a.out.mkdir(parents=True, exist_ok=True)
    target = a.out / f"city-{a.version}.zip"
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for src, name in FILES:
            info = zipfile.ZipInfo(name, date_time=(2026, 11, 13, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            z.writestr(info, src.read_bytes())
    digest = hashlib.sha256(target.read_bytes()).hexdigest()
    (a.out / f"{target.name}.sha256").write_text(f"{digest}  {target.name}\n")
    print(f"{target}  {target.stat().st_size} bytes  sha256 {digest}")

if __name__ == "__main__":
    main()
