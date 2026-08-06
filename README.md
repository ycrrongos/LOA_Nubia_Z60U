# LOA_Nubia_Z60U

Nubia Z60 Ultra (cerro / NX721J / SM8650) mainline Linux bring-up notes, tools, and WIP patches.

- Docs: `notes/cerro-linux-bringup.md`
- Bisect log: `notes/bisect-logs/map-bisect.tsv`
- Flash / USB automation: `tools/`
- Kernel WIP snapshots (full tree not in git): `patches/*.cerro-wip`

Path A: stock ABL + custom `boot.img` (header v2 + builtin DTB). Full kernel tree lives locally under `build/linux/` (gitignored).
