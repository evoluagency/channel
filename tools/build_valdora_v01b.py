#!/usr/bin/env python3
"""Empacotador manual EVOLU Channel (sem builds hospedados ou automacoes)."""
from __future__ import annotations
import hashlib, io, json, zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'addon'
DIST = ROOT / 'dist'
DIST.mkdir(parents=True, exist_ok=True)
OUT = DIST / 'Channel.mcaddon'

def pack(folder: Path) -> bytes:
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for path in sorted(folder.rglob('*')):
            if path.is_file():
                z.write(path, path.relative_to(folder).as_posix())
    data = buffer.getvalue()
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        if z.testzip() is not None:
            raise RuntimeError('Erro de integridade ZIP no pacote')
        manifest = json.loads(z.read('manifest.json'))
        if manifest['header']['version'] != [1, 3, 0]:
            raise RuntimeError('Versao inesperada: ' + folder.name)
    return data

packs = {'Channel_BP.mcpack': pack(SOURCE/'Channel_BP'), 'Channel_RP.mcpack': pack(SOURCE/'Channel_RP')}
with zipfile.ZipFile(OUT, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    for name,data in packs.items():
        z.writestr(name,data)
with zipfile.ZipFile(OUT) as z:
    assert z.testzip() is None
    assert set(z.namelist()) == set(packs)
    with zipfile.ZipFile(io.BytesIO(z.read('Channel_BP.mcpack'))) as p:
        assert len([name for name in p.namelist() if name.endswith('.mcstructure')]) == 8
print(f'{OUT}: {OUT.stat().st_size} bytes; sha256={hashlib.sha256(OUT.read_bytes()).hexdigest()}')
