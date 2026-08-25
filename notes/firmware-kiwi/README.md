# Cerro WiFi/BT firmware (from AOSP live)

Pulled/listed 2026-08-15 on **onlyaosp_cerro-userdebug** while RF works (`wlan0` scan OK, BT ON).

## Chip

| Item | Value |
|------|--------|
| Platform node | `qcom,cnss-kiwi@b0000000` |
| PCI | **`17cb:1107`** (driver `cnss_pci` / `qca_cld3_kiwi_v2`) |
| BT DT | `soc:bt_kiwi` compatible **`qcom,kiwi`** (driver `bt_power`) |
| BT UART | `898000.qcom,qup_uart` (= uart14) |
| Prop | `persist.vendor.qcom.bluetooth.soc=hamilton` |
| Modem | `4080000.remoteproc-mss` **running**; `vendor.peripheral.modem.state=ONLINE` |

## Firmware paths (vendor)

- WLAN CNSS: `/vendor/firmware_mnt/image/kiwi/`  
  - `amss.bin` / `amss20.bin`, `bdwlan.elf` (+ many `bdwlan.e*`), `regdb.bin`, `phy_ucode20.elf`, …
- CLD ini/mac: `/vendor/firmware/wlan/qca_cld/kiwi_v2/`
- BT: `/vendor/bt_firmware` ← partition `bluetooth_a` (vfat)
- Modem: `/vendor/firmware_mnt/image/modem.b*` (+ mba)

See `listing-from-aosp.txt`, `bt-listing-from-aosp.txt`.

## Mainline note

QRD-style `wcn7850-pmu` + PCIe0 + `qcom,wcn7850-bt` on uart14 **matches GPIOs/PCI ID**. PCIe EP up since s5eo-era RF work.

### WiFi (ath12k) — PASS 2026-08-16

- Modules (kernel `7.2.0-rc5-dirty`): **`ath12k` + `ath12k_wifi7`** (PCI IDs are in wifi7), deps `cfg80211`/`mac80211`/`qmi_helpers`/`libarc4` (mhi builtin).  
- Prefer **linux-firmware** `amss.bin`/`m3.bin` under `/lib/firmware/ath12k/WCN7850/hw2.0/`.  
- Cerro OTP board_id=255 + PCI subsystem `17cb:1107` needs a custom `board-2.bin` entry — packaged in `ath12k-WCN7850-hw2.0/`.  
- Vendor `amss.bin` + reload can hang; do not prefer it over upstream for bring-up.  
- Auto-load: `cerro-wifi.service` on rootfs; init plants on next s5es+ image.
