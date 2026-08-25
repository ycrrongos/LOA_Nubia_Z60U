# SM8650 Adreno a750 / gen70900 firmware (cerro)

Uncompressed copies for kernels with `CONFIG_FW_LOADER_COMPRESS` unset (`.zst` alone is useless).

| File | Install path | Notes |
|------|----------------|-------|
| `gen70900_zap.mbn` | `/lib/firmware/qcom/sm8650/gen70900_zap.mbn` | **Vendor** zap (MD5 `e20931c0738c0d031ae57c0c550d51ab`). linux-firmware generic zap fails SCM with `-EINVAL`. |
| `gmu_gen70900.bin` | `/lib/firmware/qcom/gmu_gen70900.bin` | GMU |
| `gen70900_sqe.fw` | `/lib/firmware/qcom/gen70900_sqe.fw` | SQE |
| `gen70900_aqe.fw` | `/lib/firmware/qcom/gen70900_aqe.fw` | AQE |

**Source (zap):** stock `vendor_a` → `/vendor/firmware/gen70900_zap.mbn`  
(from `notes/firmware-goodix/from-super/vendor_a.img`).

**Bring-up:**

- s5et: enabled `&gpu`/`&adreno_smmu` + linux-firmware zap → bind OK, **zap init -22**.
- s5eu: vendor zap in initramfs + rootfs stage → GMU/SQE load, Mesa `FD750`, KWin OpenGL compose PASS.

Also staged by `tools/cerro-init/init` (`staged Adreno gen70900 GPU firmware`).
