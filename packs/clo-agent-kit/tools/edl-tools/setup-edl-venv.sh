#!/usr/bin/env bash
# Create local venv for bkerler/edl (portable kit; clone edl if missing).
set -euo pipefail
TOOL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$TOOL"
if [[ ! -d edl ]]; then
  echo "Cloning bkerler/edl into $TOOL/edl ..."
  git clone --depth 1 https://github.com/bkerler/edl.git
fi
python3 -m venv venv
# shellcheck disable=SC1091
source venv/bin/activate
pip install -U pip wheel
pip install -r edl/requirements.txt
echo "OK: $TOOL/venv — run: source $TOOL/edl-env.sh"
echo "NOTE: fetch firehose — docs/servo-flash-clamp.md §2 / AGENT-HANDOFF.md §4"
