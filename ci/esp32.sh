#!/bin/sh
# ci/esp32.sh <merged.bin> — flash an ESP32 over its USB-UART, then restart it
# and wait for the self-test on the same port.
set -e
here=$(dirname "$0")
port=/dev/thub/dut1-usb
esptool --chip esp32 --port "$port" --baud 460800 --after no-reset write-flash 0x0 "$1"
python3 "$here/serial-expect.py" "$port" 'self-test: PASSED' --reset rts --timeout 30 --tag '[esp32] '
