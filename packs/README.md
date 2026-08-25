# packs/

| 目录 | 说明 |
|------|------|
| `clo-agent-kit/` | CLO / 类原生 Agent 工具包**源码**（脚本、文档、舵机夹 STL、AVB-off vbmeta） |

**Git 不含**：`clo-agent-kit-*.zip`、`edl/`、`nubia_sm8650_eng/` firehose（体积/授权原因）。克隆后：

```bash
cd packs/clo-agent-kit/tools/edl-tools
./install-udev.sh          # 一次
./setup-edl-venv.sh        # 自动 git clone bkerler/edl + venv
# 将 prog_ufs_firehose_sm8650_v1_ddr.elf 放入 nubia_sm8650_eng/（见 AGENT-HANDOFF.md）
source ./edl-env.sh
```

本地打 zip：`cd packs && zip -r clo-agent-kit-$(date +%Y%m%d).zip clo-agent-kit`（会包含本机已有的 edl/firehose）。
