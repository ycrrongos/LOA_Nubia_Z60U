# Cerro active experiment card

## status

`aborted`（显示重建 cam-c7/c8 未点亮，已回滚 rescue 保用户可用；下一刀见 evidence_log）

## one_variable

（历史）显示栈重建：自建 panel 驱动 + dsi_host spp=2 + 好内核字节流复刻（cam-c8）。

## falsifier

cam-c7/c8 屏幕仍黑 = 命中（字节流一致仍不亮 → 差异在发送语义 / dsi_host 其余细节 / msm_drm_register bits）。

## blast_radius

boot_b（已回滚 rescue sha `a9430604…`）。相机 SoC 里程碑（media0+video17+unit 自动加载，cam-c1 血统）不受影响，待显示镜像就绪后合并回归。

## regression_must_pass

（rescue 回滚后）显示 fb0/用户可见、ACM/SSH、A 槽安卓不变。

## evidence_log

- 2026-10-31 下午全记录见 bringup「显示栈丢失事故」条。要点：丢失三件套确认（panel 驱动 / dsi_host spp=2 / 最终版 setup.c 含 msm_drm_register）；cam-c7 管线全起（fb0、DSI-1 connected enabled）但屏黑；cam-c8 好内核字节流（blob 0x18fe7f8..0x18feb78，339 写）逐字节复刻 + 120Hz preferred 仍黑。
- **下一刀（显示）**：a) 驱动加 DCS 回读探针（`0x0A` power_mode：0x9c=面板活着、0x00=毒化）区分「面板没收到/没听懂」vs「DSC 流不对」；b) 反汇编好内核 prepare 发送路径核对流的解释（分组/写类型）；c) `cerro: msm_drm_register` 语义挖掘。
- 2026-10-31 中午 A1 相机 SoC 里程碑 PASS（6dbb396）：camss+CCI enabled、unit 自动加载、media0+video17、回归绿；早期 udev autoload 竞态已用 unit 时序绕开（根因遗留）。
