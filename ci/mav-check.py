#!/usr/bin/env python3
"""ci/mav-check.py <port-glob> [--version V] [--timeout S]
Waits for the flight controller's MAVLink heartbeat on that USB port, prints
its firmware version and status messages, and fails unless the version starts
with V. Needs pymavlink."""
import argparse
import glob
import sys
import time

from pymavlink import mavutil

p = argparse.ArgumentParser()
p.add_argument('port')
p.add_argument('--version', default='')
p.add_argument('--timeout', type=float, default=60)
a = p.parse_args()

end = time.monotonic() + a.timeout
while not glob.glob(a.port) and time.monotonic() < end:
    time.sleep(0.5)  # it's restarting after the upload
if not glob.glob(a.port):
    sys.exit(f'mav-check: no {a.port}')
m = mavutil.mavlink_connection(glob.glob(a.port)[0], baud=115200)
if not m.wait_heartbeat(timeout=max(1, end - time.monotonic())):
    sys.exit('mav-check: no heartbeat')
print(f'heartbeat from system {m.target_system}', flush=True)
m.mav.command_long_send(m.target_system, m.target_component, mavutil.mavlink.MAV_CMD_REQUEST_MESSAGE, 0,
                        mavutil.mavlink.MAVLINK_MSG_ID_AUTOPILOT_VERSION, 0, 0, 0, 0, 0, 0)
version = None
while version is None and time.monotonic() < end:
    msg = m.recv_match(type=['AUTOPILOT_VERSION', 'STATUSTEXT'], blocking=True, timeout=1)
    if msg is None:
        continue
    if msg.get_type() == 'STATUSTEXT':
        print('status:', msg.text, flush=True)
    else:
        v = msg.flight_sw_version
        version = f'{v >> 24 & 255}.{v >> 16 & 255}.{v >> 8 & 255}'
        print('firmware:', version, flush=True)
if version is None:
    sys.exit('mav-check: no AUTOPILOT_VERSION')
if not version.startswith(a.version):
    sys.exit(f'mav-check: firmware {version}, expected {a.version}')
