#!/bin/bash
# pmbootstrap 完整构建脚本
set -e
cd /mnt/data/LOA_Nubia_Z60U
LOG=build/pmb_full_build.log
: > "$LOG"

log() {
    echo "=== $(date '+%H:%M:%S') === $*" | tee -a "$LOG"
}

PMB="python3 pmbootstrap/repo/pmbootstrap.py -c pmbootstrap/pmbootstrap_v3.cfg"

log "开始 pmbootstrap 完整构建"

# Step 1: checksum
log "Step 1: 生成内核 checksum (下载 ~140MB 内核 tarball)..."
$PMB checksum linux-nubia-cerro 2>&1 | tee -a "$LOG"
log "checksum 完成, exit=$?"

# 显示生成的 sha512sums
log "生成的 APKBUILD sha512sums:"
grep -A5 "^sha512sums=" pmbootstrap/pmaports/device/testing/linux-nubia-cerro/APKBUILD 2>&1 | tee -a "$LOG"

# Step 2: build linux
log "Step 2: 构建内核包 (交叉编译,预计 30-60 分钟)..."
$PMB build linux-nubia-cerro 2>&1 | tee -a "$LOG"
log "内核构建完成, exit=$?"

# Step 3: build device
log "Step 3: 构建设备包..."
$PMB build device-nubia-cerro 2>&1 | tee -a "$LOG"
log "设备包构建完成, exit=$?"

# Step 4: install
log "Step 4: 生成最终镜像..."
$PMB install 2>&1 | tee -a "$LOG"
log "install 完成, exit=$?"

# 显示产物
log "=== 构建产物 ==="
find pmbootstrap/work/chroot_rootfs_nubia-cerro/ -name "*.img" -o -name "boot.img" 2>/dev/null | tee -a "$LOG"
ls -lh pmbootstrap/work/chroot_rootfs_nubia-cerro/ 2>&1 | tee -a "$LOG"

log "=== 全部完成 ==="
