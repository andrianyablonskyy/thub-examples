#!/bin/sh
# ci/betaflight.sh <betaflight.hex> [settings.txt] — flash Betaflight over USB
# (DFU), restore the bench's settings, and check the flight controller answers.
# settings.txt: the bench's "diff all" from the CLI (default: ci/bench1-diff.txt).
# FC_PORT, FC_USB: its serial port and its USB port as dfu-util names it.
set -e
here=$(dirname "$0")
fc=${FC_PORT:-/dev/thub/dut1-usb}
usb=${FC_USB:-1-3.2.4}  # <bus>-<devpath>
settings=${2:-$here/bench1-diff.txt}
[ -f "$settings" ] || { echo "betaflight.sh: no $settings — save \"diff all\" from the CLI there" >&2; exit 2; }
objcopy -I ihex -O binary "$1" fw.bin
python3 "$here/bf-cli.py" "$fc" bl  # restart into DFU: the serial port goes away
for i in $(seq 40); do dfu-util -l 2>/dev/null | grep -q "path=\"$usb\"" && break; sleep 0.25; done
dfu-util -p "$usb" -a 0 -s 0x08000000:leave -D fw.bin
python3 "$here/bf-cli.py" "$fc" --wait 15 --file "$settings" save
python3 "$here/bf-cli.py" "$fc" --wait 15 version status --expect 'Betaflight'
