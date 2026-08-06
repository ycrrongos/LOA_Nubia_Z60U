# Cerro (Nubia Z60 Ultra) 主线 Linux 启动日志与经验教训

> **强制约定（给后续 Agent / 自己）**  
> 1. 每次踩坑、探针结论、错误刷机路径，**必须立刻追加到本文**。  
> 2. 遇到黑屏 / fastboot / memorydump / 编译失败时，**先读本文再改代码**。  
> 3. 进 9008/fastboot 后先观察 USB ID，再下结论、再刷机。  
> 相关硬件事实见 `notes/cerro-hardware.md`；EDL 工具见 `tools/edl-tools/README.md`。

最后更新：2026-08-06

---

## 1. USB / 模式速查

| `lsusb` ID | 含义 | 能否刷机 |
|------------|------|----------|
| `05c6:9008` | Qualcomm EDL | ✅ `flash-boot-any.sh` / edl |
| `18d1:d00d` | fastboot | ✅ fastboot flash boot |
| `19d2:0112` | **ZTE MemoryDump**（内核硬崩 / SError 等） | ❌ 不能当 9008；需强制关机后音量±进 EDL |
| 无设备 + 黑屏 | 可能卡在内核早期（无 USB gadget） | 等/强制进 9008 |

进 9008：长按电源 20–30s 关机 → **音量+和音量−同时按住**插 USB → 确认 `05c6:9008`。

---

## 2. 已确认可用的启动链

| 项 | 结论 |
|----|------|
| Bootloader | 解锁 ABL；可用 fastboot 或 9008 |
| boot 格式 | **header v2** + 非空 `--dtb`（`dtb-id.dtb` 带 msm-id）。v4 易掉 fastboot；空 DTB 被 mkbootimg 拒绝 |
| DTB 来源 | ABL 从 **vendor_boot** 取 DT；主线应用 **Image 内置** `sm8650-nubia-cerro.dtb.o`（`prefer_builtin_dtb`），header 里仍放带 id 的 stub DTB |
| vendor_boot | 保持 **原厂**；擦除 **dtbo** |
| UART earlycon | `earlycon=qcom_geni,0x0089c000`（主机侧常无串口，靠 PSCI 探针观察） |
| 刷机脚本 | `tools/edl-tools/flash-boot-any.sh`（优先 fastboot，否则 9008） |
| 产物 | `build/boot_repack/boot-v2-builtin-dtb.img` |

表现：解锁警告 → **立刻黑屏** = ABL 已交权（无显示时不会出 Nubia logo）。

---

## 3. 探针约定（`cerro_stage_probe`）

定义在 `arch/arm64/kernel/setup.c`，`mmu.c` 的 `paging_init` 也会调用。

| Stage | 位置 | 含义 |
|------:|------|------|
| 0 | FDT scan 后、apply 前 | |
| 1 | apply 内存后 | |
| 2 | `arm64_memblock_init` 后 | |
| 30 | `paging_init` 入口、`map_mem` 前 | |
| 31 | `map_mem` 后 | |
| 32 | `create_idmap` 后 | |
| 3 | `paging_init` 整段结束后 | |
| 4–6 | unflatten / bootmem / setup_arch 末 | |

延迟固定约 **3 秒**。`CERRO_PROBE_SIGNAL=1`（脚本默认）：再 `panic` → **晚出现的 sticky fastboot = PASS**。  
`SIGNAL=0` 时仍为 PSCI 复位（约 3s 循环重启 = PASS）。  
观察口诀：**晚 fastboot=探针到了；早 fastboot=map 内 panic；一直黑=挂死；MemoryDump=`19d2:0112` 硬崩**。

---

## 4. 探针结果时间线（重要）

基线路径（当前较稳）：

- 内置 cerro DTB
- **仅** `early_init_dt_add_memory_arch(0xa0000000, 0x260000000)`（12GB − 2.5GB 洞）
- **不做** BL FDT harvest / 不批量 `memblock_reserve` BL reserved
- DTS：`hwfence` 改到 **`0xd4e23000`**，删除错误 **`rmtfs`**（对齐原厂 / Ayaneo）

| 实验 | 结果 | 结论 |
|------|------|------|
| stage 0/1（FDT+fallback） | ~2–3s 重启 | 内置 DTB + fallback 内存可用 |
| stage 2（memblock_init 后） | ~3–4s 重启 | `arm64_memblock_init` OK |
| 批量 apply BL reserved-memory | 黑屏 / dump；去掉后 stage2 才恢复 | **禁止**在 memblock 前 bulk-reserve 全部 BL carveout |
| 1GB 内存上限 + ensure kernel | 直接 fastboot | 限内存方式不对，易早期 panic；勿随意 cap |
| stage 30 且 `paging_init` 立即 return | ~3s 重启 | 进入 `paging_init`、从 mmu 调探针 OK |
| stage 31 完整 `map_mem`（含 DRAM bank 循环） | **fastboot** | panic 在 `map_mem` |
| stage 31，`map_mem` **只映射内核**、跳过 `for_each_mem_range` | **`19d2:0112` MemoryDump** | 连内核线性别名 `__map_memblock(kernel_*)` 也会硬崩 |
| 同上，但改用 `PAGE_KERNEL`（无 `pgprot_tagged`） | 黑屏一会 → **MemoryDump** | **不是 MTE tagged 单独导致** |
| stage31，`map_mem` 跳过 `__map_memblock` 但仍跑 `force_pte`/`can_set_direct_map`/`bbml2` | **fastboot** | prologue 就会 panic |
| stage31，`map_mem` **开头直接 return**（无任何逻辑） | **自动重启** | 进入/离开空 `map_mem` OK |
| stage31，只调用 `force_pte_mapping()` 后 return | **自动重启** | `force_pte` / `bbml2` MIDR 检查 OK |
| stage31，只调用 `can_set_direct_map()` 后 return | **自动重启**（用户） | `can_set_direct_map` OK；此前“完整赋值→fastboot”更像未真正 reboot 进新镜像的误判 |
| stage31 + `__map_memblock(kernel)` PAGE_KERNEL、无 DRAM bank（step2） | **MemoryDump** | 崩在建内核线性别名 |
| stage31 + **只 map 1 页** + 强制 PTE（step23） | **MemoryDump** | 与块映射/大小无关；`__map_memblock`/页表/`__phys_to_virt` 即崩 |
| 同上（VA52 配置）用户再确认 | **`19d2:0112` MemoryDump** | 确认非误判 |
| **VA48/PA48** + step23（1 页 map） | 刷入后先短暂无 USB，再 **`19d2:0112` MemoryDump** | **VA52/LPA2 不是唯一原因**；`__map_memblock` 在 VA48 仍硬崩 |
| **VA48** + 空 `map_mem`（step0） | 长时间无 USB → **fastboot** | **VA48 本身过不了 stage31**（预期应 ~3s 探针重启）；勿再在 VA48 上 bisect map |
| **VA52** + 空 `map_mem`（step0） | **自动重启**（用户确认） | 基线恢复；继续 dig `__map_memblock` / memstart |
| **VA52** + step24（map `0xa0000000` 1 页） | **MemoryDump** | **不是**「内核 PA < PHYS_OFFSET」单独导致；任意 `__map_memblock`/建页表即硬崩 |
| **VA52** + step25（`early_pgtable_alloc`） | **fastboot** | 多半 `memblock` 分配失败触发 `panic()`；先确认 bank 内能否 alloc |
| **VA52** + step251（bank 内 alloc，失败挂死） | 长时间无 USB → 后变 **fastboot** | 倾向 **alloc 失败**（挂死后看门狗/ABL）；memblock 在 `0xa0000000+` 无可用页 |
| **VA52** + step252（`memblock_add` 后再 alloc） | **自动重启**（用户） | **根因之一：memblock 在 map_mem 前无可用页**；re-add 后 alloc OK |
| **VA52** + step253（re-add + map `0xa0000000` 1 页） | **MemoryDump** | alloc 够了仍崩；疑 **`memstart_addr` 未随 re-add 更新** → `__phys_to_virt` 错 |
| **VA52** + step254（re-add + 修 memstart + map 1 页） | **fastboot** | 非 Dump；修 memstart 改变了崩法（更像 panic）。下一步只写 memstart 不 map |
| **VA52** + step255（re-add + memstart，不 map） | **自动重启**（用户） | 写 memstart 安全；**崩在往 swapper 安装线性映射** |
| **VA52** + step26（临时 pgd map 1 页） | **MemoryDump** | 不碰 swapper 也崩；疑 **tmp pgd 未清零** 或 fixmap/建表路径本身 |
| **VA52** + step261（tmp pgd memset 后再 map） | **MemoryDump** | 不是未清零；**`early_create_pgd_mapping`/fixmap 建表** 即硬崩 |
| **VA52** + step262（alloc + `init_clear_pgtable` 新页） | **MemoryDump**（用户/自检） | 写**新分配页**崩；当时尚无 2720 对照 |
| **VA52** + step263（fixmap @ `0xa0100000` + `init_clear_pgtable`，**无** TLB flush） | **直接 fastboot**（用户 U727） | 当时无 flush；已被 **2723/2724** 纠正 |
| **VA52** + step264（fixmap @ `0xa0100000` 只装/卸，不写） | **自动重启**（用户两确：误记撤销后再确） | **装低端 PA 的 fixmap PTE OK** |
| **VA52** + step266（fixmap `clear_page` 内核 scratch，无 flush） | **fastboot**（自检） | 无 flush 的 DC ZVA 路径失败 |
| **VA52** + step267（fixmap `memset` 内核 scratch，无 flush） | **fastboot**（用户 U750） | 无 flush 的 memset 也失败 |
| **VA52** + step268（fixmap **读** scratch + `flush_tlb_kernel_range`） | **PASS**（用户 U867「自动重启」；TSV） | 首刷用户曾说「直接 fb」(U764)，**以复测自动重启为准**（当时尚不会分早晚 fb） |
| **VA52** + step269（fixmap 写 1 字节 scratch + flush） | **PASS**（USB 先静默再晚 fb；TSV） | 写**内核镜像内**页 OK |
| **VA52** + step270（fixmap `memset` 整页 scratch + flush） | **硬 PASS**（晚 sticky fb @83.3s，PASS_MIN=28，含解锁全等待，无人跳过） | 整页写内核内页 OK |
| **VA52** + step271（`init_clear_pgtable` @ scratch） | **硬 PASS**（晚 sticky fb @83.3s，同上） | DC ZVA 清内核内页 OK |
| **VA52** + step272（alloc + `init_clear_pgtable`） | **假 PASS → Dump** | quiet 误判；最终 Dump（用户 U897）；见 §5.7 |
| **VA52** + step2720（只 `early_pgtable_alloc`） | **PASS**（晚 fb；用户亦述可循环重启；重跑 TSV） | memblock **能**分到页 |
| **VA52** + step2721（alloc + fixmap 装/卸，不写） | **PASS**（晚 fb，重跑 TSV） | 新页 PA **可**装进 fixmap |
| **VA52** + step2722（alloc + fixmap `memset` 新页 + flush） | **Dump** @~34s（TSV extend） | top-down 新页写零 Dump |
| **VA52** + step2723（`0xa0100000` + flush + 写 1 字节） | **PASS**（晚 sticky @51.6s，SKIP_UNLOCK） | **低端固定 PA 可写**；263 缺的是 flush |
| **VA52** + step2724（`0xa0100000` + flush + memset） | **PASS**（晚 sticky @29.3s） | 低端整页写 OK |
| **VA52** + step2725（`early_pgtable_alloc` + flush + 写 1 字节） | **Dump**（旧 top-down）→ **PASS**（限低 +256MiB 后 @58.9s） | 限制区间后可写 |
| **VA52** + step2726（bank 低 256MiB 内 alloc + flush + memset） | **PASS**（晚 sticky @45.8s） | **低端 alloc 可写**；与旧 2725 对照锁定 top-down/过高 PA |
| **VA52** + step273（`__map_memblock` 1 页 @ `0xa0000000`，低端 pt alloc） | **PASS**（晚 sticky @41.0s） | **线性映射 1 页 OK** |
| **VA52** + step274（`__map_memblock` 内核 1 页，低端 pt alloc） | **PASS**（晚 sticky @33.0s） | **映射内核 PA 1 页 OK** |
| **VA52** + step2（映射内核 text+data 两段，跳过 DRAM） | **PASS**（晚 sticky @68.1s，SKIP_UNLOCK） | **内核两段线性映射 OK** |

**证据等级（防再带偏进度）：**

| 等级 | 含义 | 本表适用 |
|------|------|----------|
| **硬** | sticky fastboot 早晚判定 / Dump；`SKIP_UNLOCK` 时不算解锁等待 | 含 **2723–2726、273、274、2** |
| **弱** | 仅 quiet / PASS_MIN 过短 | （旧 quiet；已作废） |
| **已撤销** | 曾记 PASS 后被 Dump/用户纠正/计时作废 | 272 quiet；264 误确认；+2GiB 的 2725 hang |

**当前卡点（2026-08-06 20:10）：**  
1. **已过**：低端写/alloc、`__map_memblock` 1 页（273/274）、**step2 内核两段**。前提：`early_pgtable_alloc` **限在 bank 低 256MiB**。  
2. **下一步**：step **3**（`for_each_mem_range`）；**先把 fallback/SAFE_MAP 缩到已验证的 256MiB**，再全量 map，避免假上沿。  
3. +2GiB 上限曾 hang；正式靠 ABL FDT harvest，不要死守 `0x260000000`。

观察自动规则（`cerro-map-bisect.sh`，**靠 sticky fastboot 时机**）：  
- **很快** sticky `fastboot`（&lt; `PASS_MIN`）→ **early_fastboot**（几乎无循环 / 像一开就进 fb）  
- 先长时间 USB 静默（多轮自动重启），**很晚**才 sticky fastboot 且不再开机 → **PASS**（用户观察：循环几次后 ABL 放弃）  
- Dump → dump  
- 一直静默无 sticky fb → **hang**（默认不再 quiet 当 PASS）  
- **每轮必须计入解锁警告等待**；无人值守**勿按电源跳过**，否则 `PASS_MIN` 会偏短、误判  

时间模型：  
- **你跳过解锁**（`SKIP_UNLOCK=1`）：**不算**解锁等待；`PASS_MIN ≈ 2×(开机+探针3s)`；**只看 sticky fastboot 早晚**。  
- 无人跳过：`UNLOCK_WAIT`（默认8s）计入 CYCLE。  
- 久等仍无 sticky fb → hang（加长 EXTEND，默认至少 ~70s）。

---

## 5. 问题 → 处理（速查）

### 5.1 主线 DTB `memory` 大小为 0 / 多容量 SKU

- **现象**：换内置 DTB 后无可用 RAM；硬编码 size 只对某一容量正确。  
- **处理（临时）**：固定 bank `0xa0000000 + 0x260000000`（12GB 假设）。  
- **处理（正式）**：从 ABL 传入的 FDT harvest `/memory`（及必要 reserved），**一份镜像适配 12G/16G/24G**；不要为每个容量单独出 kernel。  
- **坑**：错误/不完整的 BL harvest 曾搞挂 `memblock_init`；先过 `map_mem` 再重新打开 harvest。

### 5.2 reserved-memory / hwfence 地址不一致

- **现象**：paging 阶段 dump 或挂死。  
- **事实**：原厂 hwfence = `0xd4e23000`；QRD/主线默认 `0xe6440000`（错）。  
- **处理**：在 `sm8650-nubia-cerro.dts` 里 `/delete-node/ &hwfence_shbuf` + 重声明正确地址；参考 `sm8650-ayaneo-pocket-s2.dts`。  
- **坑**：把 BL 全部 reserved bulk `memblock_reserve` 会挂在 `arm64_memblock_init`——改 DTS，不要在 setup.c 里扫荡式 reserve。

### 5.3 显示不是第一块石头

禁用显示节点后仍早期挂死 → 优先内存/页表，不是 panel。

### 5.4 刷机与构建

- 编译失败仍去刷 → 会刷到**旧** Image；先看 `BUILD:0` 和 `strings Image | grep cerro`。  
- `systemctl is-active` 返回 `inactive` 不是空字符串（旧监控脚本坑）。  
- setup.c 里勿留中文垃圾字符（曾弄挂编译）。

### 5.5 MemoryDump vs fastboot

- Dump = 更“硬”的异常（常见于错误物理映射 / 踩固件）。  
- fastboot = ABL 认为启动失败或 panic 被接住。  
- 二者都**不能**用 dump 口当 EDL 刷。

### 5.6 他机参考

- Ayaneo Pocket S2：自定义 EFI ABL 较多；但 **hwfence@d4e23000**、删 rmtfs 可直接抄到 cerro DTS。  
- 消费级 SM8650 手机主线 + 原厂 ABL 仍然少见，预期早期痛苦在 ABL/DT/内存交接。

### 5.7 quiet 自动 PASS 会误判（272 教训）

- step272 曾两次 `quiet_auto_psci_*` → TSV 记 **pass**，随后出现 **MemoryDump**。  
- 原因：PSCI 循环前/崩前 USB 长时间静默，与真 PASS 外观相同。  
- 规则：  
  1. quiet PASS 后 **加长观察**（脚本 extend）；若出现 Dump → 记 `dump` 并撤销 pass。  
  2. 优先采信 **晚出现的 sticky fastboot**（探针重启后再进 fb）。  
  3. 用户目视「~3s 循环重启」仍是最硬证据。  
- **权威结果以 TSV 最后一条有效结论为准**（例如 272 最终是 dump，不是前面的 pass）。

### 5.8 刷回 Android / AOSP 测试

- 备份：`tools/edl-tools/pmos-flash/backup-20260806-020517/`  
- 恢复分区：`boot_{a,b}`、`vendor_boot_{a,b}`、`dtbo_{a,b}`、`vbmeta_{a,b}`、`vbmeta_system_{a,b}`  
- 2026-08-06 18:29 已从 9008 整链刷回；随后可刷 AOSP。继续 cerro 时再刷 `boot-v2-builtin-dtb.img`。

---

## 6. 关键文件

| 路径 | 用途 |
|------|------|
| `build/linux/arch/arm64/kernel/setup.c` | builtin DTB、fallback 内存、阶段探针 |
| `build/linux/arch/arm64/mm/mmu.c` | `paging_init` / `map_mem` 探针与临时跳过 DRAM 循环 |
| `build/linux/arch/arm64/boot/dts/qcom/sm8650-nubia-cerro.dts` | 板级 DTS（hwfence 等） |
| `build/linux/arch/arm64/kernel/sm8650-nubia-cerro.dtb` | 链进 Image 的 blob（改 DTS 后需重编 DTB 并 `cp` 再编 Image） |
| `tools/edl-tools/flash-boot-any.sh` | 双路径刷 boot |
| `build/boot_repack/boot-v2-builtin-dtb.img` | 当前刷入镜像 |

改 DTB 后务必：

```bash
make ARCH=arm64 LLVM=1 qcom/sm8650-nubia-cerro.dtb
cp -f arch/arm64/boot/dts/qcom/sm8650-nubia-cerro.dtb arch/arm64/kernel/
rm -f arch/arm64/kernel/sm8650-nubia-cerro.dtb.o
make ARCH=arm64 LLVM=1 -j$(nproc) Image
```

---

## 7. 下一步候选（未验证；SKIP_UNLOCK=1 时只看 sticky fb 早晚）

1. ~~**step 2**~~：**PASS**（映内核两段）。  
2. **step 3**：完整 `for_each_mem_range`（fallback/SAFE_MAP 先缩到 **256MiB** 再测）。  
3. 正式方案：ABL FDT harvest `/memory`；`early_pgtable_alloc` 保留低端限制或改 bottom-up。

---

## 8. 变更记录（短）

| 日期 | 记事 |
|------|------|
| 2026-08-06 | 建立本文；整理 probe 时间线；记录「kernel-only map_mem → MemoryDump `19d2:0112`」 |
| 2026-08-06 | hwfence→`d4e23000`；禁止 BL reserved bulk apply；基线 fallback 内存 + stage2 恢复 |
| 2026-08-06 | step23（1 页 `__map_memblock`）仍 MemoryDump；改 VA48/PA48，镜像已编好待 9008 |
| 2026-08-06 | VA48+step23 刷入后仍 MemoryDump；改 step0 空 map_mem 做 VA48 对照 |
| 2026-08-06 | VA48+step0 → fastboot（非 ~3s 重启）；放弃 VA48，回 VA52+step0 基线 |
| 2026-08-06 | VA52+step0 用户确认自动重启；试 step24（map `0xa0000000` 1 页测 memstart） |
| 2026-08-06 | step24 亦 MemoryDump；改 step25 只 early_pgtable_alloc |
| 2026-08-06 | step25 → fastboot；改 step251（bank 内 alloc，失败挂死/成功重启） |
| 2026-08-06 | step252 re-add+alloc → 自动重启；试 step253 re-add+map 1 页 |
| 2026-08-06 | step253 → MemoryDump；改 step254（再修 memstart_addr 后 map） |
| 2026-08-06 | step254 → fastboot；改 step255（只 re-add+memstart，不 map） |
| 2026-08-06 | step255 → 自动重启；setup.c 在 memblock_init 后 re-add；试 step26 临时 pgd |
| 2026-08-06 | step26 → MemoryDump；改 step261（tmp pgd memset 后再 map） |
| 2026-08-06 | step262 → MemoryDump；改 step263（fixmap 清 bank 低地址 0xa0100000） |
| 2026-08-06 | step263 → 直接 fastboot；改 step264（只 set/clear fixmap，不写页） |
| 2026-08-06 | step264 → 自动重启；试 step266（fixmap clear 内核内 scratch） |
| 2026-08-06 | step266 → fastboot；改 step267（fixmap memset 替代 clear_page）；待确认 |
| 2026-08-06 | step267 → fastboot；改 step268（fixmap 只读 + TLB flush，不改 memblock） |
| 2026-08-06 | 探针改 `CERRO_PROBE_SIGNAL=1`（panic→fastboot=PASS）；加 `tools/cerro-map-bisect.sh` 自动摸内存 |
| 2026-08-06 | panic→fastboot 在本机不可靠，改回 PSCI；quiet 用答案文件确认 |
| 2026-08-06 | 对照 UotanToolboxNT 重写 USB 检测：`tools/lib/cerro-usb-detect.sh`（fastboot CLI + lsusb + 去抖） |
| 2026-08-06 | 0/264/268/269 全 PASS；观察改为自动区分「早 fb=失败 / 久静默后晚 fb=PASS」 |
| 2026-08-06 | 270/271 **quiet** 记过；272 假 PASS 后 Dump → 拆 2720/2721/2722 |
| 2026-08-06 | **2720/2721 硬 PASS；2722 Dump**（alloc+memset 新页） |
| 2026-08-06 | 9008 整链刷回 `backup-20260806-020517`；Dump **未**用 9008 拉 ramdump |
| 2026-08-06 | 补 §4；随后按聊天记录**勘误**：270/271 降为弱 PASS；263 明确无 flush；修正 §7 勿重复裸测 263 |
| 2026-08-06 | 证据等级表写入 §4；frontier 禁止只靠 quiet |
| 2026-08-06 | 按用户：多轮自动重启后 sticky fb=PASS；计时含解锁等待；跳过解锁的复测作废 |
| 2026-08-06 | **270/271 硬 PASS**（晚 sticky @~83s，PASS_MIN=28，CYCLE=14） |
| 2026-08-06 | 用户之后会跳过解锁：`SKIP_UNLOCK=1`（不算解锁等待；只看 fb 早晚） |
| 2026-08-06 | **2723/2724 PASS；2725 Dump；2726 PASS** → 卡点=top-down alloc PA 过高/假 DRAM |
| 2026-08-06 | early_pgtable_alloc 限低 2GiB 后 **2725 黑屏 hang**（top-down 仍贴区间上沿）；改回 +256MiB |
| 2026-08-06 | **2725/273/274 全 PASS**（+256MiB pt alloc）；下一步 step2→3 扩 map |
| 2026-08-06 | **step2 PASS**（晚 sticky @68.1s）；准备缩 fallback→step3；首推 GitHub（FlClash） |

---

## 9. 自动二分脚本（path A）

```bash
# 默认队列：0(基线) 264(只装fixmap) 268(读) 269(写)
/mnt/data/LOA_Nubia_Z60U/tools/cerro-map-bisect.sh

# 只跑某几档
/mnt/data/LOA_Nubia_Z60U/tools/cerro-map-bisect.sh 268 269

# 干跑（只改 STEP 宏，不编译不刷）
/mnt/data/LOA_Nubia_Z60U/tools/cerro-map-bisect.sh --dry-run --step 268
```

| USB 结果 | 脚本判定 |
|----------|----------|
| 离开刷机后静默 **≥ PASS_MIN**（默认约 2×(解锁8s+开机3s+探针3s)≈28s）再 sticky `18d1:d00d` | **PASS**（多轮 PSCI 后 ABL 放弃进 fb） |
| **很快** sticky fastboot（&lt; PASS_MIN） | **early_fastboot** |
| `19d2:0112` | **dump** |
| 观察+extend 内一直无 sticky fb | **hang**（默认；勿当 PASS） |

**注意：** 解锁警告全时长要算进每轮；**不要**按电源跳过。可用 `UNLOCK_WAIT_S` / `MIN_PASS_CYCLES` 覆盖。

日志：`notes/bisect-logs/map-bisect.tsv` 与带时间戳的 `.log`。  
刷机仍走 `flash-boot-any.sh`（fastboot 优先，否则 9008）；**不换 ABL/XBL**。

## 9.1 USB 检测（对齐 UotanToolboxNT）

- 库: `tools/lib/cerro-usb-detect.sh`
- Fastboot: 以 `fastboot devices` 为准（非仅 lsusb 18d1:d00d）
- EDL: lsusb `:9008`
- Dump: `19d2:0112`（cerro 特有）
- 去抖: 连续 2 次相同读数才认定
