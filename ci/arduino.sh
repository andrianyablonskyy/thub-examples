#!/bin/sh
# ci/arduino.sh <sketch.hex> — flash an Arduino Uno through its bootloader, then
# restart it and wait for the self-test on the same port (the sketch's Serial).
set -e
here=$(dirname "$0")
port=/dev/thub/dut1-usb
avrdude -p atmega328p -c arduino -P "$port" -b 115200 -D -U "flash:w:$1:i"
python3 "$here/serial-expect.py" "$port" 'self-test: PASSED' --baud 9600 --reset dtr --timeout 20 --tag '[uno] '
