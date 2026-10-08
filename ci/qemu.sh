#!/bin/sh
# ci/qemu.sh <tests.elf> — run a semihosting test image on QEMU's Arm MPS2-AN385
# (Cortex-M3). Its exit code is the verdict; killed after 120 s.
timeout 120 qemu-system-arm -M mps2-an385 -cpu cortex-m3 -nographic \
  -semihosting-config enable=on,target=native -kernel "$1" </dev/null
