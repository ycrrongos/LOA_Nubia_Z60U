# Cerro active experiment card

## status
`in_progress` — 显示历史取证/源码恢复；下一步刷 disp-r1（仅 boot_b）。

## one_variable
恢复已知好显示栈：以旧 Cursor 最终记录与好内核为依据核对 panel/DSI host/显示 DT。

## falsifier
恢复代码与最终记录/好内核行为不符，或实机仍黑屏/帧完成超时，则不判完成。

## blast_radius
当前先改本机内核源码，保留现有 cam-c10 差异并提交。实机实验仅 Linux boot_b，保留 A 槽 Aurora 与 rescue 回滚锚点；不改 rootfs/音频/电源 UX。

## regression_must_pass
构建前 guard PASS + tree SHA；实机本枪标签、fb0/DSI、用户可见画面、触控、ACM/SSH、Wi-Fi、媒体声；稳定观察至少 2 分钟。黑屏即取证后回 rescue。

## evidence_log
- 2026-10-31：用户要求从旧 .cursor、Aurora Cerro 树及旧好内核恢复显示。已有 cam-c9 记录只证明管线注册，黑屏尚未解决。

- 构建 guard PASS，tree=52fa4bbc4；恢复 panel typed 包多重集与好内核一致。下一步上传 disp-r1，校验 boot_a 保持 b7dddcc1…，刷前/后读回 boot_b sha。
