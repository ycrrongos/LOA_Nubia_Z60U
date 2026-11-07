---
name: cerro-bringup-gate
description: >-
  Cerro (Nubia Z60U / SM8650) Linux bring-up experiment gate. Use before any
  phone change touching cellular, IMS, IPA, modem, audio/UCM/PipeWire/AGM,
  display, power, or boot images — and whenever the user says 修/刷/继续/通话/数据.
  Enforces single-variable experiments, blast-radius checks, and regression
  lists so mid-loop context loss cannot justify thrashing coupled stacks.
---

# Cerro bring-up gate

This skill is the **method**. Hard USB/slot/Dialer rules stay in root `AGENTS.md`
and `.cursor/rules/cerro-agent.mdc`. Do not skip this skill because those files
were already injected at chat start — **long tool loops do not re-read them**.

Companions (also under `.agents/skills/`):

- `cerro-boot-pack` — dualboot packaging (splice vs 方案 E / ID audit limits)
- `systematic-debugging` — root-cause before more knobs
- `verification-before-completion` — no PASS without fresh evidence
- `linux-phone-porting` — evidence → research → one variable → flash-gate
  (linked from `~/.agents/skills/`; refresh from GitHub via FlClash when needed)

Use **this** skill for every Cerro live change. Prefer `linux-phone-porting`
research order when diagnosing a never-worked capability.

## Before the first mutating step

1. Read root `AGENTS.md`「当前战役」→ `notes/cerro-display-campaign.md` if display/boot.
2. Read `notes/cerro-open-work.md` — only the **current** open item.
3. Read `notes/cerro-active-experiment.md` — if empty/`idle`, fill it **before** editing.
4. Read `notes/cerro-linux-bringup.md` top「当前状态」+ the subsystem section you will touch.
5. State aloud (in the experiment card): **one variable**, **falsifier**, **blast radius**, **regression must-pass**.

## Single-variable rule (non-negotiable)

- One intent per session slice: e.g. 「只修 WWAN IPv4 配置」或「只改 UCM Earpiece」——**不可**同轮停 IMS + 重启 MM + 改 NM + 改音频。
- If a fix needs a second subsystem, **stop**, write the card, get explicit user OK or open a new chat titled with that variable.
- Three failed falsifiers → widen research (web/Linux first, then bringup notes, Android only as interface facts). Do not add more knobs.

## Blast radius map (minimum)

| You touch | Must not break (re-check before claiming PASS) |
|-----------|-----------------------------------------------|
| IMS / 81voltd / qcom-imsd / ims-iface | `qmapmux0.0` data: `curl -4 --interface qmapmux0.0` or `cerro-cell-connect` path |
| MM / NM gsm / qmapmux / IPA | voice registration path; ACM/USB; no `rmmod ipa` |
| UCM / callaudiod / voice-bridge / AGM | HiFi `paplay` after hangup; no MultiMedia1 off+suspend leftover |
| PipeWire / WirePlumber | default sink not Dummy; cold-boot order (no timer fake PASS) |
| boot.img / init / DTB | dual-slot flash; ACM marker; slot Successful; use `cerro-boot-pack` path |
| display / panel / DSI / DRM | rescue = rollback only (brightness ≠ campaign done); mid-knife OK if `1d6b:0104`; no same-knife mkbootimg+panel+DT; do not stop rebuild because anchor lights |

## Mid-loop anti-amnesia

Hooks inject reminders; you must still **re-open** `notes/cerro-active-experiment.md` after any compaction-sized digression or every ~10 tool calls that mutate the phone. If the card's variable no longer matches what you are doing, **stop and rewrite the card** — you have already drifted.

## Completion

- Update bringup with PASS/FAIL + evidence (commands/outputs), not vibes.
- Set experiment card status to `done`/`fail`/`aborted`.
- One commit per intent when user asks to commit.
- Dialer-only for call UX PASS (`AGENTS.md` §6.1).
