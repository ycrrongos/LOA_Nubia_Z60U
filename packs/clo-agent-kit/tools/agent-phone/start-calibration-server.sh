#!/usr/bin/env bash
# Web UI for servo angle calibration (default http://127.0.0.1:8787)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
python3 -m pip install -q -r server/requirements.txt
exec python3 -m uvicorn server.app:app --host 127.0.0.1 --port "${PORT:-8787}"
