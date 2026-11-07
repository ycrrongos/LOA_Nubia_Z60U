# Cerro 显示恢复战役（2026-11-07）

进度真相源：本文件。摘要同步根 `AGENTS.md`「当前战役」；细节/时间线仍写 `cerro-linux-bringup.md`。

## 真正正确的方向（硬规则，曾偷懒被骂）

**目标**：在**当前可维护内核树**里，把丢失的显示栈（RM692H0 面板 + DSI host 补丁等）**像最初那样一步一步摸回来并固化**，使以后 `make Image` / 方案 E 重链仍能亮屏。

| 是 | 不是 |
|----|------|
| rescue / 好内核 blob = **对照标本 + 回滚锚点** | 「rescue 已经亮了 → 显示战役收工」 |
| cam-c1（能起、丢屏）= 方案 E **可启动底**，往上叠最小面板差分 | 停在旧 blob、只靠 splice 过日子 |
| disp-r1b FAIL = 重建路上的**早挂证据**，拆变量继续摸 | 「旧的能亮就别折腾重建」 |
| 每刀：单变量 → 刷 boot → **USB 认出/连上** 就够判生死 | 每刀等到完整桌面 / 长 ACM 会话才敢往下 |

**禁止**把「锚点能亮」当成推进的替代品。锚点亮只证明硬件和旧二进制还行，**不证明树里的显示栈已恢复**。

## 一句话

cam-c1 起系统 PASS；rescue 回滚 PASS（且用户确认亮）。**战役未完成**：下一刀继续在方案 E 底上**最小差分并面板**，对照好内核 blob / 历史屏驱聊天，查清 disp-r1b 为何早挂。

## 锚点

| 锚点 | 状态 | 用途 |
|------|------|------|
| Aurora 完整槽 B + rescue `boot_b`（`a9430604…`） | **PASS** 亮屏（用户确认） | **回滚/对照**；ACM `user`/`user` |
| 好内核 blob `backups/kernel-good-20260817.bin`（`a6201111…`） | 考古标本 | 反汇编/对照命令表与补丁，不是日常刷入终点 |
| `linux-cam-c1`（`e7e79456…`） | **PASS 起系统**（丢屏） | 方案 E 底；下一刀差分起点 |
| `linux-cam-c10` | 历史能起（丢屏） | 备用底 |
| `linux-disp-r1b`（tree `ab9c02b61`） | **FAIL** 黑屏+无 USB | 整包并回面板后早挂；要拆，不是弃 |

## 已排除（勿空转）

- 只换 A/B、只怪 GPT、fastboot 写坏 boot、vbmeta 重开、拧验证值
- 「rescue 亮了所以别重建树」← **偷懒，禁止**

## 下一刀顺序（单变量）

1. ~~cam-c1 复测~~ PASS；~~rescue 回滚~~ PASS（亮）。
2. **现做**：以 cam-c1（或等价方案 E 底）为基，**最小一刀**并面板相关（先对照 blob/历史：panel  alone vs host DSC vs DT，选最小集合）；打包方案 E；只刷 `boot_b`。
3. **本刀观察（从简）**：刷完盯 USB——出现 `1d6b:0104`（能枚举/能连）= 没早死，可继续取证；一直无 gadget / 回 d00d / Dump = FAIL，回 rescue。
   - **不要**为中间刀等 SDDM/完整桌面；ACM getty 有更好、没有就 ICMP/串口噪声，够用再登。
4. 战役终判「显示栈恢复 PASS」才要：本树编出的镜像 + USB 活着 + **用户目视有图**（仅 fb0 ≠ PASS）。
5. 失败回滚：rescue `a9430604…`。

## 观察口诀（显示刀，从简）

| 现象 | 含义 |
|------|------|
| 刷后很快 `1d6b:0104` | 活着，可往下摸 |
| 无 USB / 回 `18d1:d00d` / `19d2:0112` | 早挂或拒载 → FAIL，回锚点 |
| rescue 亮屏 | 只说明锚点健康，**不是**本树显示 PASS |

## 打包

见 skill `cerro-boot-pack` 与 `AGENTS.md` §6.2。

## 聊天归档

- Cursor：`.cursor/restored-agent-transcripts/`（`55bc8cee` / `7f8c3d7b`）
- ZCode：`zcode-loa-session_9fd5e80c.md`
- Canvas：`cerro-display-roadmap`
