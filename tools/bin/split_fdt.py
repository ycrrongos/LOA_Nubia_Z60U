#!/usr/bin/env python3
"""Split a concatenated FDT (device-tree) blob into individual .dtb files.

Scans for the FDT magic (0xd00dfeed), reads each blob's totalsize from its
header, and writes each blob out separately. Works on the `dtb` payload found
inside Android vendor_boot / boot images where several board DTBs are packed
back-to-back.
"""
import struct
import sys
import os

FDT_MAGIC = 0xd00dfeed


def split(path, outdir):
    with open(path, "rb") as f:
        data = f.read()
    os.makedirs(outdir, exist_ok=True)
    idx = 0
    off = 0
    n = len(data)
    while off + 8 <= n:
        magic, totalsize = struct.unpack_from(">II", data, off)
        if magic != FDT_MAGIC or totalsize < 40 or off + totalsize > n:
            # blobs may be packed back-to-back with no alignment; scan byte-wise
            off += 1
            continue
        blob = data[off:off + totalsize]
        out = os.path.join(outdir, f"{idx:02d}.dtb")
        with open(out, "wb") as w:
            w.write(blob)
        print(f"[{idx:02d}] off=0x{off:08x} size={totalsize} -> {out}")
        idx += 1
        off += totalsize
    if idx == 0:
        print("no FDT blobs found", file=sys.stderr)
        return 1
    print(f"total {idx} dtb(s)")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"usage: {sys.argv[0]} <concatenated.dtb> <outdir>", file=sys.stderr)
        sys.exit(2)
    sys.exit(split(sys.argv[1], sys.argv[2]))
