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

def verify_existing() -> None:
    """Read-only verification of all published module files and signatures."""
    manifest = json.loads((UPDATES / "manifest.json").read_text(encoding="utf-8"))
    key = ROOT / "game" / "updates" / "trust" / "valdora_ota.pub"
    assert manifest["game"] == "Valdora" and manifest["schema_version"] == 2
    assert key.is_file(), "OTA public key is missing"
    seen = set()
    for module in manifest["modules"]:
        mid = module["id"]
        assert mid not in seen, "duplicate module"
        seen.add(mid)
        ext = "json" if module["kind"] == "data" else module["kind"]
        expected = MODULES / f"{mid}-{module['version']}.{ext}"
        assert expected.is_file(), "missing module: " + expected.name
        data = expected.read_bytes()
        assert len(data) == module["bytes"], "wrong size: " + mid
        assert sha256(data).hexdigest() == module["sha256"], "wrong digest: " + mid
        assert module["url"] == ORIGIN + expected.name, "unexpected URL"
        if module["kind"] in {"pck", "zip"}:
            assert module["entry"] == f"res://valdora_modules/{mid}/entry.tscn"
            raw_signature = base64.b64decode(module["signature_b64"], validate=True)
            with tempfile.TemporaryDirectory() as work:
                signature_file = Path(work) / "signature.bin"
                signature_file.write_bytes(raw_signature)
                result = subprocess.run(
                    ["openssl", "dgst", "-sha256", "-verify", str(key),
                     "-signature", str(signature_file), str(expected)],
                    capture_output=True, text=True, check=False
                )
                assert result.returncode == 0 and "Verified OK" in result.stdout,                     "RSA signature verification failed: " + mid
        elif module["kind"] == "data":
            payload = json.loads(data)
            assert payload["module_id"] == mid and payload["schema_version"] == 1
        else:
            raise ValueError("Unknown kind: " + str(module["kind"]))
    print(f"PASS: {len(manifest['modules'])} OTA modules verified using public key only")


def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--revision",type=int)
    ap.add_argument("--min-client-code",type=int,default=102)
    ap.add_argument("--key-file",type=Path)
    ap.add_argument("--write",action="store_true",help="Write staged site manifest; never deploy")
    ap.add_argument("--verify-existing",action="store_true")
    args=ap.parse_args()
    if args.verify_existing:
        verify_existing()
        return
    if args.revision is None:
        ap.error("--revision is required for manifest generation")
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
