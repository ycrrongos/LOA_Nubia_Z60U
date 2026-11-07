# Cerro active experiment card

## status

`idle` — 方向已纠正。下一刀待开：**cam-c1 底最小并面板**（重建树，不是收工）

## one_variable

（待开）在方案 E / cam-c1 底上只并入**最小一块**面板相关差分（具体子集开刀前写死：panel alone / host DSC / DT 三选一优先最小），出新 boot，只刷 `boot_b`。

## falsifier

刷后无 `1d6b:0104`（或回 d00d/Dump）→ 该差分导致早挂；回 rescue，缩小差分。

## blast_radius

仅 `boot_b` + 内核树已提交的那一刀源码；失败回 rescue `a9430604…`。

## regression_must_pass

- [ ] 刷后 USB `1d6b:0104`（能认出/连上即够；不要求桌面）
- [ ] 失败回 rescue

## evidence_log

- 2026-11-07 cam-c1 PASS；rescue 回刷 PASS；用户确认 rescue **亮屏**。
- 2026-11-07 用户纠正：亮锚点≠收工；要继续一步步摸树内屏驱；中间刀别等完整系统。已写入 AGENTS + campaign。
