#!/bin/sh
# ci/flash-all.sh <image> [boards] — flash every board on this Client at once,
# each through its own ST-Link (/dev/thub/dut<N>-stlink, found by serial),
# then print each one's output tagged [flash dut<N>]. Exits 2 if any failed.
image=$1 boards=${2:-5}
[ -f "$image" ] || { echo "flash-all: no image $image" >&2; exit 2; }
n=1
while [ "$n" -le "$boards" ]; do
  (
    serial=$(udevadm info --query=property --name="/dev/thub/dut$n-stlink" 2>/dev/null | sed -n 's/^ID_SERIAL_SHORT=//p')
    if [ -z "$serial" ]; then
      echo "no ST-Link at /dev/thub/dut$n-stlink" > "flash-$n.log"; echo 1 > "flash-$n.rc"; exit
    fi
    st-flash --serial "$serial" --reset write "$image" 0x08000000 > "flash-$n.log" 2>&1
    echo $? > "flash-$n.rc"
  ) &
  n=$((n + 1))
done
wait
failed=0
n=1
while [ "$n" -le "$boards" ]; do
  sed "s/^/[flash dut$n] /" "flash-$n.log"
  if [ "$(cat "flash-$n.rc")" != 0 ]; then
    echo "[flash dut$n] FAILED"; failed=1
  fi
  n=$((n + 1))
done
[ "$failed" -eq 0 ] || exit 2
