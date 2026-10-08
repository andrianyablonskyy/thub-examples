#!/bin/sh
# ci/nucleo.sh <app.bin> — flash a Nucleo through its on-board ST-LINK, then
# wait for the self-test on its virtual COM port (/dev/thub/dut1-usb).
set -e
here=$(dirname "$0")
st-flash --reset write "$1" 0x08000000
python3 "$here/serial-expect.py" /dev/thub/dut1-usb 'self-test: PASSED' --timeout 30 --tag '[nucleo] '
