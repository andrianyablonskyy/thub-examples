#!/bin/sh
# ci/ardupilot.sh <arducopter.apj> — flash ArduPilot over USB, then check over
# MAVLink that it starts with the expected version (AP_VERSION, default 4.6).
# FC_PORT: its USB port's /dev/serial/by-path name, first interface (MAVLink).
# Needs ArduPilot's Tools/scripts/uploader.py copied next to this script.
set -e
here=$(dirname "$0")
port=${FC_PORT:-'/dev/serial/by-path/*-usb-0:3.2.4:1.0'}
[ -f "$here/uploader.py" ] || { echo "ardupilot.sh: copy ArduPilot's Tools/scripts/uploader.py to $here/" >&2; exit 2; }
python3 "$here/uploader.py" --port "$port" "$1"
python3 "$here/mav-check.py" "$port" --version "${AP_VERSION:-4.6}" --timeout 60
