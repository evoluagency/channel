#!/usr/bin/env python3
"""Create Valdora v2 manifests offline. Does NOT deploy or run GitHub Actions."""
from pathlib import Path
from hashlib import sha256
import argparse
import base64
import json
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
UPDATES = ROOT / "site" / "updates" / "v2"
MODULES = UPDATES / "modules"
ORIGIN = "https://channel.evolu.ink/updates/v2/modules/"

def create(revision: int, minimum_client: int, private_key: Path | None) -> dict:
    if revision < 1 or minimum_client < 102:
        raise ValueError("revision positive and minimum_client>=102 required")
    entries = []
    seen = set()
    total = 0
    for file in sorted(MODULES.iterdir()):
        if not file.is_file() or file.suffix not in {".json", ".pck", ".zip"}:
            continue
        match = re.fullmatch(r"([a-z0-9_-]{3,40})-([1-9][0-9]*)\.(json|pck|zip)",file.name)
        if not match:
            raise ValueError(f"invalid module file name: {file.name}")
        identifier, version, ext = match.groups()
        if identifier in seen:
            raise ValueError(f"duplicate id; retain only latest version per manifest: {identifier}")
        seen.add(identifier)
        data = file.read_bytes()
        total += len(data)
        if not data or len(data) > 100*1024*1024 or total > 200*1024*1024:
            raise ValueError("size budget exceeded")
        entry = {
            "id":identifier, "version":int(version),
            "kind":"data" if ext == "json" else ext,
            "url":ORIGIN+file.name, "bytes":len(data),
            "sha256":sha256(data).hexdigest()
        }
        if ext == "json":
            d = json.loads(data)
            allowed = {"message", "open_heroes", "open_combat", "economy"}
            if d.get("schema_version") != 1 or d.get("module_id") != identifier:
                raise ValueError("JSON schema/id mismatch")
            if len(d.get("actions",[])) > 12 or any(a.get("command") not in allowed for a in d["actions"]):
                raise ValueError("unsupported action")
        else:
            if private_key is None or not private_key.is_file():
                raise ValueError("PCK requires a local, non-repository RSA private key")
            signature = subprocess.run(
                ["openssl", "dgst", "-sha256", "-sign", str(private_key), str(file)],
                capture_output=True, check=True
            ).stdout
            entry["signature_b64"] = base64.b64encode(signature).decode("ascii")
            entry["entry"] = f"res://valdora_modules/{identifier}/entry.tscn"
        entries.append(entry)
    if not entries or len(entries)>24:
        raise ValueError("manifest must contain 1..24 modules")
    return {
        "schema_version":2, "game":"Valdora", "studio":"EVOLU Channel",
        "channel":"alpha", "revision":revision,
        "min_client_code":minimum_client, "modules":entries
    }

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--revision",type=int,required=True)
    ap.add_argument("--min-client-code",type=int,default=102)
    ap.add_argument("--key-file",type=Path)
    ap.add_argument("--write",action="store_true",help="Write staged site manifest; never deploy")
    args=ap.parse_args()
    result=create(args.revision,args.min_client_code,args.key_file)
    content=json.dumps(result,ensure_ascii=False,indent=2)+"\n"
    if args.write:
        final=UPDATES/"manifest.json"
        temporary=final.with_suffix(".json.tmp")
        temporary.write_text(content,encoding="utf-8")
        temporary.replace(final)
        print(f"staged {final} modules={len(result['modules'])} revision={args.revision}")
    else:
        print(content)

if __name__=="__main__":
    main()
