#!/bin/sh
# ci/run.sh — cold-boot the board, flash and test it, then always power it off.
set -u
cd "$(dirname "$0")/.."
test_pid=
off() { ci/power.sh off || echo "power: could not switch $BENCH_POWER off" >&2; }
trap '[ -n "$test_pid" ] && kill "$test_pid" 2>/dev/null; off; exit 143' TERM INT

ci/power.sh reset 2 || exit 2
sleep 3
st-flash --reset write "$THUB_DOWNLOAD_1" 0x08000000 || { off; exit 2; }
./ci/test.sh "$@" & test_pid=$!
wait "$test_pid"; rc=$?
off
exit "$rc"
