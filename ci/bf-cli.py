#!/usr/bin/env python3
"""ci/bf-cli.py <port> [command ...] [--file F] [--expect RE] [--wait S]
Runs Betaflight CLI commands over the flight controller's USB port and prints
the output. bl, dfu, save and exit restart it: nothing is read after them.
Needs pyserial."""
import argparse
import os
import re
import sys
import time

import serial

p = argparse.ArgumentParser()
p.add_argument('port')
p.add_argument('commands', nargs='*')
p.add_argument('--file', help='CLI lines to send first, e.g. a saved "diff all"')
p.add_argument('--expect', help='exit 1 unless the output matches this')
p.add_argument('--wait', type=float, default=0, help='seconds to wait for the port (after a restart)')
a = p.parse_args()

deadline = time.monotonic() + a.wait
while not os.path.exists(a.port) and time.monotonic() < deadline:
    time.sleep(0.25)
time.sleep(1 if a.wait else 0)  # let it finish starting
s = serial.Serial(a.port, 115200, timeout=0.2)
out = []


def until_prompt(limit=10.0):
    buf, end = b'', time.monotonic() + limit
    while time.monotonic() < end:
        chunk = s.read(4096)
        buf += chunk
        if not chunk and buf.endswith(b'\r\n# '):
            break
    text = buf.decode(errors='replace')
    print(text, end='', flush=True)
    out.append(text)


s.write(b'#\r\n')  # enter the CLI
until_prompt()
lines = open(a.file).read().splitlines() if a.file else []
for line in [x for x in lines if x.strip() and not x.startswith('#')] + a.commands:
    s.write(line.encode() + b'\r\n')
    if line.split()[0] in ('bl', 'dfu', 'save', 'exit'):
        time.sleep(0.5)
        break
    until_prompt()
print()
if a.expect and not re.search(a.expect, ''.join(out)):
    sys.exit(f'bf-cli: no "{a.expect}" in the output')
