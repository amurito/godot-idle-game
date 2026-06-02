#!/usr/bin/env python3
"""
fetch_telemetry.py — Baja los runs de telemetría desde el hub (hyphae-game-hub)
y los escribe como JSON individuales, listos para analyze_telemetry.py.

El receptor vive en el hub Node/Express (server.js -> /api/admin/telemetry/export),
con los datos en Supabase. Este script descarga el dump y lo deja en una carpeta
local que analyze_telemetry.py puede leer sin cambios.

Uso
---
    python tools/fetch_telemetry.py \
        --server https://hyphae-game-hub.onrender.com \
        --token  $TELEMETRY_EXPORT_TOKEN \
        --out    ./telemetry_fetched

    python tools/analyze_telemetry.py ./telemetry_fetched   # runs_dir es posicional

Variables de entorno equivalentes a los flags: TELEMETRY_SERVER, TELEMETRY_EXPORT_TOKEN.
"""

import argparse
import json
import os
import sys
from pathlib import Path
from urllib.request import Request, urlopen


def fetch_ndjson(server: str, token: str):
    url = server.rstrip("/") + "/api/admin/telemetry/export?format=ndjson"
    req = Request(url, headers={"Authorization": f"Bearer {token}"})
    with urlopen(req, timeout=60) as resp:
        for raw_line in resp:
            line = raw_line.decode("utf-8").strip()
            if line:
                yield line


def main() -> int:
    parser = argparse.ArgumentParser(description="Descarga runs de telemetría desde el hub.")
    parser.add_argument("--server", default=os.environ.get("TELEMETRY_SERVER", ""),
                        help="URL base del hub, ej. https://hyphae-game-hub.onrender.com")
    parser.add_argument("--token", default=os.environ.get("TELEMETRY_EXPORT_TOKEN", ""),
                        help="TELEMETRY_EXPORT_TOKEN configurado en el hub")
    parser.add_argument("--out", default="./telemetry_fetched", help="Carpeta de salida")
    args = parser.parse_args()

    if not args.server:
        print("ERROR: falta --server (o env TELEMETRY_SERVER)", file=sys.stderr)
        return 2
    if not args.token:
        print("ERROR: falta --token (o env TELEMETRY_EXPORT_TOKEN)", file=sys.stderr)
        return 2

    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    count = 0
    for line in fetch_ndjson(args.server, args.token):
        try:
            payload = json.loads(line)
        except json.JSONDecodeError:
            print("Aviso: línea inválida, salteada", file=sys.stderr)
            continue

        meta = payload.get("meta", {}) if isinstance(payload.get("meta"), dict) else {}
        stamp = meta.get("timestamp_end") or meta.get("timestamp_start") or count
        sid = str(meta.get("session_id", "anon")).replace("/", "_")[-12:]
        (out_dir / f"run_{stamp}_{sid}.json").write_text(
            json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        count += 1

    print(f"OK: {count} runs escritas en {out_dir.resolve()}")
    print(f"Ahora: python tools/analyze_telemetry.py {out_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
