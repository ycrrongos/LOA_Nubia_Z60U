# Cerro 主屏：BF068 / Raydium RM692H0

## 实机确认（AOSP）

- 分辨率 **1116×2480**（非 VTDR6130 的 1080×2400）
- 模式 **CMD + DSC**（`dsi_cmd_mode` + `compression-mode = "dsc"`）
- overlay：`panel = <&dsi_bf068_rm692h0_6p8_plus_dsc_cmd>`

## DSC（60/120Hz 相同）

- slice_height=20, slice_width=558, slice_per_pkt=2
- bpc=10, bpp=10, block_prediction_enable

## 电源

见 `zte-lcd-supply-cerro.dtsi`：除 L11B/L12B/L13B 外还有 GPIO 控的
`display_panel_vddio` / `display_panel_vddd`。

## 主线工作

- **硬依赖**：MSM DSI 必须支持 `slice_per_pkt=2`（`MIPI_DSI_MODE_DSC_ALL_SLICES_IN_PKT`）；仅 `slice_count=2` 不够。
- 驱动：`panel-raydium-rm692h0.c`；DTS：`raydium,rm692h0`。
- **默认 120Hz preferred（s5ew）**：DRM 三档 **60 / 90 / 120**（KDE 显示设置可选）。
  - 60：vendor timing@0（HFP/HBP 248/336，`BD=00`）+ timing-switch@0。
  - 120：vendor timing@1（HFP/HBP 26/76，`BD=05` + black-line）+ timing-switch@1。
  - 90：**无原厂 timing**；中插 porch（137/206）+ **`BD=0x02`（cerro 猜测）**，switch 体用 @1。
- 运行时：`msm_dsi_host_get_display_mode` → panel `prepare`/`enable` 里发 BD + timing-switch。

1. 新建 `panel-raydium-rm692h0.c`（或 zte-bf068），把 vendor `on-command` 译成
   `mipi_dsi_dcs_write_seq` / multi helpers；默认 **无 VIDEO**。
2. `dsi->dsc` 填上表参数；`prepare_prev_first = true`。
3. DTS：`compatible` + 1116×2480 mode + of_graph；确认 GPIO 供电。
4. 勿再把 `visionox,vtdr6130` 当主屏。

Vendor 原文已拷到本目录。

## s5an (2026-08-12)
- 根因嫌疑：on-cmd 误用 `mipi_dsi_generic_write`（MIPI generic DT），vendor 为 DCS `0x15/0x39`。
- 修复：全量改 `mipi_dsi_dcs_write_seq_multi`；加 supply post-on delay；读 display ID。


## s5ar (2026-08-12)
- 最小 on（跳过 FE）→ **power_mode=0x9c / id=d28000**。完整 FE on-cmd 会毒化面板回到 0x00。

## s5au (2026-08-12)
- FE bisect 前 20 条：after-on=0x00 id=000000 enable=0x00
- 对照：s5ar 最小 on → 0x9c / id=d28000
