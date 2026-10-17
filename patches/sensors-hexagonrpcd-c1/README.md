# sensors-hexagonrpcd-c1

## PASS (2026-10-17)
- `fastrpc.ko` → `/dev/fastrpc-adsp`
- `hexagonrpcd -s -R /usr/share/qcom/` (INIT_ATTACH_SNS)
- Android `persist` mounted at `/mnt/vendor/persist`
- HexagonFS registry synced (299 entries, includes `lanai_lsm6dso_0.*`)
- Units: `mnt-vendor-persist.mount`, `cerro-sensors-registry.service`, drop-ins under `hexagonrpcd.service.d/`

## FAIL / gap
- No IIO devices; auto-rotate not working
- `sensh` (QRTR/QMI SNS client) times out — SM8650 SEE talks FastRPC, not QRTR SNS
- Next: FastRPC/libssc (or future kernel SEE→IIO), not more registry packing

## DIR log line
`Tried to open .../registry/DIR for writing` is the DSP mkdir sentinel; stock Android registry also contains a `DIR` entry. Not a missing-file failure once registry is populated.
