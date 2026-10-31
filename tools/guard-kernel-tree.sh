#!/usr/bin/env bash
# Cerro kernel-tree protection guard.
# Run before ANY Image build / boot image packaging:
#   tools/guard-kernel-tree.sh
# Fails hard on:
#   1. dirty kernel tree — uncommitted local changes. The 2026-10-21 display-stack
#      loss (panel-raydium-rm692h0.c, dsi_host DSC patch, final setup.c) happened
#      exactly because local files lived uncommitted and were wiped by a cleanup.
#   2. config regression vs the known-good kernel config — any symbol built-in (=y)
#      in the good kernel that vanished from the tree config now. This check would
#      have caught the panel driver loss before the first broken boot image.
# On success prints the tree commit sha for the build manifest.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TREE="$PROJECT_DIR/build/linux-7.2"
GOOD_CFG="$PROJECT_DIR/patches/kernel-config-good-20260817.config"

[[ -d "$TREE/.git" ]] || { echo "GUARD-FAIL: kernel tree $TREE has no .git"; exit 1; }
[[ -f "$TREE/.config" ]] || { echo "GUARD-FAIL: no .config in kernel tree"; exit 1; }

DIRTY=$(git -C "$TREE" status --porcelain | wc -l)
if (( DIRTY > 0 )); then
  echo "GUARD-FAIL: kernel tree has $DIRTY uncommitted path(s):"
  git -C "$TREE" status --porcelain | head -20
  echo ""
  echo "COMMIT THEM FIRST. Uncommitted tree files are one cleanup away from being"
  echo "lost forever (see notes/cerro-linux-bringup.md 2026-10-31 显示栈丢失事故)."
  exit 1
fi

if [[ -f "$GOOD_CFG" ]]; then
  # Loss signature = symbol built-in in the good kernel that is ENTIRELY absent
  # from the current config (no =y, no =m, not even "# ... is not set"). That is
  # what happens when the source/Kconfig file is deleted: the symbol evaporates
  # at the next syncconfig. Mode changes (=y -> =m / not set) are visible choices
  # and pass with a warning.
  EVAPORATED=$(grep -oE '^CONFIG_[A-Za-z0-9_]+=y$' "$GOOD_CFG" | cut -d= -f1 | while read -r sym; do
    if ! grep -qE "^${sym}(=|\$)|^# ${sym} is not set" "$TREE/.config"; then
      echo "$sym=y"
    fi
  done || true)
  if [[ -n "$EVAPORATED" ]]; then
    echo "GUARD-FAIL: symbols built-in in the known-good kernel EVAPORATED from tree config"
    echo "(no trace at all => their source/Kconfig was deleted):"
    echo "$EVAPORATED"
    echo ""
    echo "This is exactly how the RM692H0 panel driver was lost on 2026-10-21."
    echo "Restore the source (or consciously update patches/kernel-config-good-*.config)."
    exit 1
  fi
  DOWNGRADED=$(grep -E '^CONFIG_.*=y$' "$GOOD_CFG" | while IFS='=' read -r sym _; do
    v=$(grep -E "^${sym}=" "$TREE/.config" | head -1 | cut -d= -f2)
    [[ "$v" == "m" ]] && echo "${sym}=y->m"
  done || true)
  if [[ -n "$DOWNGRADED" ]]; then
    echo "GUARD-WARN (non-fatal) built-in symbols now modules:"
    echo "$DOWNGRADED"
  fi
fi

echo "GUARD-PASS tree=$(git -C "$TREE" rev-parse --short HEAD) config=$(sha256sum "$TREE/.config" | cut -c1-12)"
