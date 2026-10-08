#!/bin/sh
# ci/nrf52.sh <app.hex> — program an nRF52840 DK through its on-board J-Link
# (the one on this USB port), then reset it and wait for the self-test on VCOM.
set -e
here=$(dirname "$0")
port=/dev/thub/dut1-usb
sn=$(udevadm info --query=property --name="$port" | sed -n 's/^ID_SERIAL_SHORT=0*//p')
nrfutil device program --serial-number "$sn" --firmware "$1" --options chip_erase_mode=ERASE_ALL,reset=RESET_NONE
python3 "$here/serial-expect.py" "$port" 'self-test: PASSED' --timeout 30 --tag '[nrf52] ' &
sleep 1
nrfutil device reset --serial-number "$sn"
wait $!
