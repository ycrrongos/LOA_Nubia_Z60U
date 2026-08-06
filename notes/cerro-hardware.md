# Nubia Z60 Ultra (cerro / NX721J) — 下游硬件配置清单

> 来源:对本机 EDL 全量备份 `backups/device-dump-20260717-222750/by-name/` 中
> `vendor_boot_a.img`(基础 SoC DTB ×7)与 `dtbo_a.img`(DT overlay ×4)反编译得到。
> cerro 专属配置全部集中在 **dtbo overlay #1**(`downstream-dt/dts/dtbo_1.dts`)。
> 反编译产物见 `downstream-dt/dts/`。

## SoC / 平台

| 项 | 值 |
|----|----|
| SoC | Qualcomm Snapdragon 8 Gen 3 = **SM8650**,代号 pineapple/lanai |
| 主线内核 | 已支持(v6.6 引入,v6.8+ 较完整) |
| 架构 | aarch64 |
| 存储 | UFS(sector size 4096) |
| boot.img | header v4,GKI 内核 ~34MB(gzip),ramdisk 在 init_boot/vendor_boot |
| vendor cmdline | `ignore_loglevel sysctl.kernel.firmware_config.force_sysfs_fallback=1 bootconfig` |

## 显示(重点利好)

- 面板:**Visionox VTDR6130**(FHD+ AMOLED,支持 120Hz/144Hz qsync);另有 Raydium `bf068_rm692h0` 6.8" 备选节点。
- **主线已有驱动 `panel-visionox-vtdr6130`**(drivers/gpu/drm/panel/),这是最大利好 —— 显示可直接复用。
- 电源轨映射(PM8550B,"B" 后缀):
  - `vdd`  = **L11B**(panel VDD)
  - `vddio`= **L12B**(panel VDDIO,同时给触摸 iovdd)
  - `vci`  = **L13B**(panel VCI)
- 显示控制器:`mdss_mdp@ae00000`、`dsi_ctrl0@ae94000`、`dsi_ctrl1@ae96000`、`dp_display@ae154000`、`sde_rscc@af20000`(标准 sm8650 地址)。

## 触摸屏

| 项 | 值 |
|----|----|
| 芯片 | **Goodix GT9916S**(Berlin 家族),`compatible = "goodix,gt9916S"` |
| 总线 | **SPI**(固件 `goodix_firmware_spi.bin`) |
| 主线驱动 | `goodix-berlin-core` + `goodix-berlin-spi` ✅ |
| reset-gpio | TLMM **161** (0xa1) |
| irq-gpio | TLMM **162** (0xa2),flags 0x2008(下降沿) |
| 电源 | avdd = **L14B**,iovdd = **L12B** |
| 分辨率标定 | panel-max-x=1080 (0x438), panel-max-y=2400 (0x960) |
| 次触摸(brl-d) | `goodix-berlin-d@0`(9916r,可能是副屏/背屏),vdd=L12B |

## 无线 / 连接

| 功能 | 器件 | 主线方向 |
|------|------|---------|
| WiFi/BT | `qcom,cnss-kiwi@b0000000`(WCN kiwi = WCN6855/7850 家族) | ath11k/ath12k + bluetooth |
| NFC | `st21nfc@08`(ST,I²C) + `st54spi@0`(ST 安全元件,SPI) | 社区 st-nfc 驱动 |
| GPS | 走 modem/qcom pd | 未验证 |

## 传感器 / 输入 / 其它

- 指纹:`goodix,fingerprint`(屏下,SPI),pwr-gpio = TLMM **93** (0x5d)。**主线无驱动**,需用户态方案。
- 马达:`haptic_hv@5A`(I²C 0x5A,awinic haptic 系列)。
- ToF:`tof@29`(激光对焦)。
- 霍尔:`hall_sensor`。
- **游戏肩键**:`gpio_keys_nubia`(`game_sw_on` / `game_sw_off`)—— Z60U 特色的实体肩键滑块。
- USB:`usb-role-switch`(Type-C 角色切换);`nubia,usb_switch_dp`(DP alt-mode 切换)。

## PMIC 推断

SM8650 标准配套:pmk8550 / pm8550 / **pm8550b**(L11B/L12B/L13B/L14B 来自此)/ pm8550ve / pm8550vs / pmr735d。
主线 dts 引用方式:`&pm8550b_l11` 等(具体电压约束以主线 `pm8550.dtsi` 为准)。

## 移植可行性速评

| 子系统 | 主线现状 | cerro 难度 |
|--------|---------|-----------|
| CPU/UFS/USB/串口 | Works | 低 |
| 显示(VTDR6130) | 驱动已在主线 | **低**(最大惊喜) |
| GPU(Adreno 750 / freedreno) | Works | 低 |
| 触摸(goodix-berlin SPI) | 驱动在主线 | 低-中(需正确 SPI+电源+GPIO) |
| WiFi/BT(kiwi) | ath1xk | 中(需固件+节点) |
| 音频 | Works(参考机) | 中 |
| Modem 蜂窝 | Works(参考机) | 中-高(rmtfs/固件) |
| 指纹/相机 | 无/弱 | 高(基本放弃) |
