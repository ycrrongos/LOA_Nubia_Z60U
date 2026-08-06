# pmbootstrap 完整构建指南

> **主线开机/踩坑日志（必读）**：[`notes/cerro-linux-bringup.md`](notes/cerro-linux-bringup.md)  
> 改启动链、遇黑屏/fastboot/MemoryDump 前先查该文件，并在结束后把结论写回去。

## 当前状态
- ✅ work 目录已初始化 (version 8)
- ✅ 配置文件就绪 (`pmbootstrap_v3.cfg`)
- ✅ 内核补丁和 APKBUILD 就绪
- ⚠️ checksum 步骤卡住(正在排查)

## 问题诊断
pmbootstrap checksum 在创建 chroot 时卡在安装 gcc 包,可能原因:
1. 网络慢,下载大文件超时
2. apk.static 进程异常
3. FIFO 管道阻塞

## 解决方案

### 方案 1: 清理并重新运行(推荐)

```bash
cd /mnt/data/LOA_Nubia_Z60U

# 1. 停止所有 pmbootstrap 进程
pkill -9 -f pmbootstrap
sudo pkill -9 apk.static

# 2. 清理 work 目录
rm -rf pmbootstrap/work

# 3. 重新初始化 work 目录
python3 << "PYEOF"
import sys
sys.path.insert(0, "pmbootstrap/repo")
from pathlib import Path
import pmb.config

work = Path("pmbootstrap/work")
work.mkdir(mode=0o700, parents=True, exist_ok=True)
work_version_file = work / "version"
work_version_file.write_text(f"{pmb.config.work_version}\n")
work.joinpath("cache_git").mkdir(mode=0o700, parents=True, exist_ok=True)
print(f"Work directory initialized at: {work}")
PYEOF

# 4. 运行 checksum (使用 --details-to-stdout 看详细输出)
python3 pmbootstrap/repo/pmbootstrap.py \
  --details-to-stdout \
  -c pmbootstrap/pmbootstrap_v3.cfg \
  checksum linux-nubia-cerro

# 5. 如果成功,继续构建
python3 pmbootstrap/repo/pmbootstrap.py \
  -c pmbootstrap/pmbootstrap_v3.cfg \
  build linux-nubia-cerro

python3 pmbootstrap/repo/pmbootstrap.py \
  -c pmbootstrap/pmbootstrap_v3.cfg \
  build device-nubia-cerro

python3 pmbootstrap/repo/pmbootstrap.py \
  -c pmbootstrap/pmbootstrap_v3.cfg \
  install
```

### 方案 2: 跳过 checksum,手动填写 SHA512

如果 checksum 一直失败,可以手动下载内核源码并计算 SHA512:

```bash
cd /mnt/data/LOA_Nubia_Z60U

# 1. 下载内核源码
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.12.22.tar.xz \
  -O build/linux-6.12.22.tar.xz

# 2. 计算 SHA512
sha512sum build/linux-6.12.22.tar.xz

# 3. 编辑 APKBUILD,填入正确的 sha512sums
# 编辑 pmbootstrap/pmaports/device/testing/linux-nubia-cerro/APKBUILD
# 将 placeholder 替换为实际的 SHA512

# 4. 直接开始构建
python3 pmbootstrap/repo/pmbootstrap.py \
  -c pmbootstrap/pmbootstrap_v3.cfg \
  build linux-nubia-cerro
```

### 方案 3: 使用预编译内核(最快)

如果交叉编译太慢,可以考虑:
1. 在其他机器上编译好内核
2. 将生成的 .apk 包复制到 `pmbootstrap/work/packages/edge/aarch64/`
3. 直接运行 `pmbootstrap install`

## 预期时间
- checksum: 10-30 分钟(下载 ~140MB 内核源码)
- build linux-nubia-cerro: 30-60 分钟(交叉编译内核)
- build device-nubia-cerro: 5-10 分钟
- install: 5-10 分钟(生成镜像)

总计: **50-110 分钟**(取决于网络和 CPU 性能)

## 监控进度

在新终端窗口中运行:
```bash
# 查看日志
tail -f /mnt/data/LOA_Nubia_Z60U/build/pmb_checksum_detailed.log

# 查看进程
watch -n 5 'ps aux | grep -E "(pmbootstrap|apk)" | grep -v grep'

# 查看缓存大小变化
watch -n 10 'du -sh /mnt/data/LOA_Nubia_Z60U/pmbootstrap/work/cache_apk_x86_64/'
```

## 常见问题

### Q: apk.static 卡住怎么办?
A: 杀掉进程,清理 work/tmp,重新运行:
```bash
sudo pkill -9 apk.static
rm -rf pmbootstrap/work/tmp/*
```

### Q: 网络太慢怎么办?
A: 更换 Alpine 镜像源,编辑 `pmbootstrap_v3.cfg`:
```ini
[mirrors]
alpine = http://mirrors.tuna.tsinghua.edu.cn/alpine/
```

### Q: 磁盘空间不足?
A: 清理旧文件:
```bash
rm -rf pmbootstrap/work/cache_apk_*
rm -rf pmbootstrap/work/chroot_*
```

## 最终产物
成功后会在以下位置生成:
- boot.img: `pmbootstrap/work/chroot_rootfs_nubia-cerro/boot/boot.img`
- rootfs: `pmbootstrap/work/chroot_rootfs_nubia-cerro/rootfs.img`
