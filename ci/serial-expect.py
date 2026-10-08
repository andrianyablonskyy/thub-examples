#!/usr/bin/env python3
"""ci/serial-expect.py <port> <pattern> [--baud N] [--timeout S] [--fail RE] [--reset dtr|rts] [--tag T]
Prints what the board sends; exits 0 once a line matches <pattern>,
1 if one matches --fail, 2 on timeout. Needs pyserial."""
import argparse
import re
import sys
import time

import serial

p = argparse.ArgumentParser()
p.add_argument('port')
p.add_argument('pattern')
p.add_argument('--baud', type=int, default=115200)
p.add_argument('--timeout', type=float, default=30)
p.add_argument('--fail', default=r'FAIL|panic|Guru Meditation|HardFault')
p.add_argument('--reset', choices=['dtr', 'rts'])
p.add_argument('--tag', default='')
a = p.parse_args()

s = serial.Serial()
s.port, s.baudrate, s.timeout = a.port, a.baud, 0.5
s.dtr = s.rts = False  # opening the port mustn't hold the board in reset
s.open()
if a.reset:  # a pulse: Arduino resets on DTR, ESP32 on RTS (EN)
    setattr(s, a.reset, True)
    time.sleep(0.1)
    setattr(s, a.reset, False)
deadline, buf = time.monotonic() + a.timeout, b''
while time.monotonic() < deadline:
    buf += s.read(256)
    *lines, buf = buf.split(b'\n')
    for raw in lines:
        line = raw.decode(errors='replace').rstrip('\r')
        print(a.tag + line, flush=True)
        if re.search(a.pattern, line):
            sys.exit(0)
        if re.search(a.fail, line):
            sys.exit(1)
print(f'{a.tag}serial-expect: no "{a.pattern}" within {a.timeout:g} s', file=sys.stderr)
sys.exit(2)
