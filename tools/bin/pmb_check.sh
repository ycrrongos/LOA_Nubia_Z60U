#!/bin/bash
set -e
cd /mnt/data/LOA_Nubia_Z60U
LOG=build/pmb_run.log
: > "$LOG"
echo "=== pmaports.cfg ===" >> "$LOG"
cat pmbootstrap/pmaports/pmaports.cfg >> "$LOG" 2>&1 || echo "(no pmaports.cfg)" >> "$LOG"
echo "=== pmbootstrap config ===" >> "$LOG"
python3 pmbootstrap/repo/pmbootstrap.py -c pmbootstrap/pmbootstrap_v3.cfg config >> "$LOG" 2>&1 || echo "config exit=$?" >> "$LOG"
echo "=== DONE ===" >> "$LOG"
