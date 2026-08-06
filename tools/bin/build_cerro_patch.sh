#!/bin/bash
# Build 0001-arm64-dts-qcom-add-sm8650-nubia-cerro.patch from the
# project DTS. Produces a git-am-able patch that (1) adds the DTS under
# arch/arm64/boot/dts/qcom/ and (2) registers it in that Makefile.
set -e

LINUX_DIR=/mnt/data/LOA_Nubia_Z60U/linux
QPATH=arch/arm64/boot/dts/qcom
DTS=sm8650-nubia-cerro.dts
OUT="$LINUX_DIR/0001-arm64-dts-qcom-add-sm8650-nubia-cerro.patch"

cd "$LINUX_DIR"

NLINES=$(wc -l < "$DTS")

# --- commit header ---------------------------------------------------
cat > "$OUT" <<EOF
From 0000000000000000000000000000000000000000 Mon Sep 17 00:00:00 2001
From: Nubia Z60U port <root@localhost>
Date: Mon, 27 Jul 2026 00:00:00 +0000
Subject: [PATCH] arm64: dts: qcom: add SM8650 based Nubia Z60 Ultra (cerro)

Add an initial device tree for the Nubia Z60 Ultra (codename cerro,
model NX721J), built on the Snapdragon 8 Gen 3 (SM8650).

Enabled in this first submission: UART console, UFS storage, USB in
peripheral mode, the Visionox VTDR6130 DSI panel and the Goodix Berlin
GT9916 touchscreen on SPI4. Display and touch wiring matches the SM8650
QRD reference board. Remaining blocks (WiFi/BT, NFC, audio, haptics,
fingerprint, game shoulder keys) will be added in follow-up changes.

Signed-off-by: Nubia Z60U port <root@localhost>
---
 arch/arm64/boot/dts/qcom/Makefile             |   1 +
 .../boot/dts/qcom/sm8650-nubia-cerro.dts      | ${NLINES} +++
 2 files changed, $((NLINES + 1)) insertions(+)
 create mode 100644 arch/arm64/boot/dts/qcom/sm8650-nubia-cerro.dts

EOF

# --- Makefile hunk (real tabs preserved via printf) ------------------
{
  printf 'diff --git a/%s/Makefile b/%s/Makefile\n' "$QPATH" "$QPATH"
  printf 'index 0000000..0000000 100644\n'
  printf -- '--- a/%s/Makefile\n' "$QPATH"
  printf -- '+++ b/%s/Makefile\n' "$QPATH"
  printf '@@ -397,5 +397,6 @@\n'
  printf ' dtb-$(CONFIG_ARCH_QCOM)\t+= sm8650-hdk-rear-camera-card.dtb\n'
  printf ' dtb-$(CONFIG_ARCH_QCOM)\t+= sm8650-hdk.dtb\n'
  printf ' dtb-$(CONFIG_ARCH_QCOM)\t+= sm8650-mtp.dtb\n'
  printf '+dtb-$(CONFIG_ARCH_QCOM)\t+= sm8650-nubia-cerro.dtb\n'
  printf ' dtb-$(CONFIG_ARCH_QCOM)\t+= sm8650-qrd.dtb\n'
  printf ' dtb-$(CONFIG_ARCH_QCOM)\t+= sm8750-mtp.dtb\n'
} >> "$OUT"

# --- new-file hunk for the DTS ---------------------------------------
# git diff --no-index returns exit 1 when files differ; that's expected.
git diff --no-index /dev/null "$DTS" > .dts_diff.tmp 2>/dev/null || true
# Rewrite the bare filename to the in-tree path.
sed -e "s|b/$DTS|b/$QPATH/$DTS|g" \
    -e "s|a/$DTS|a/$QPATH/$DTS|g" \
    .dts_diff.tmp >> "$OUT"

rm -f .dts_diff.tmp
echo "WROTE $OUT"
wc -l "$OUT"
