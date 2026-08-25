# Cerro AW882xx / AW88261 firmware

Source: AOSP `vendor/firmware` on onlyaosp_cerro (also `vendor/nubia/cerro/proprietary`).

| File | Use |
|------|-----|
| `aw882xx_acf.bin` | Awinic ACF profile blob (embeds `aw88261` / `A1901`). Mainline: `firmware-name = "aw882xx_acf.bin"`. |
| `aw_cali.bin` | Factory cali (20B). Vendor path also under persist `smartpa_cali_data/`. |

Chip: I²C `0x34`/`0x35`, chipid `0x2113` = mainline `SND_SOC_AW88261`.
