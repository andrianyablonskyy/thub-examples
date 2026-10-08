#!/bin/sh
# host/install-tools.sh — the flashing and test tools the examples in ci/ use,
# on an Ubuntu 26.04 Client host. Run it as the user the Client runs as.
set -e
sudo apt-get install -y stlink-tools avrdude dfu-util binutils python3-serial python3-pymavlink pipx
sudo install -m 0644 "$(dirname "$0")/45-stdfu.rules" /etc/udev/rules.d/45-stdfu.rules
sudo udevadm control --reload
sudo pipx install --global esptool  # esptool v5, on every user's PATH (the Client's too)
# J-Link (nRF52840 DK): SEGGER's J-Link Software .deb, then nrfutil from Nordic's
# site and: nrfutil install device
# Renode: Docker (the examples run antmicro/renode).
