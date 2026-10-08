#!/bin/sh
# ci/test.sh — what a job's script gets: its id, parameters, --env values,
# downloads and --meta; flashes the board and runs the tests (README §8.1).
set -eu
echo "Job $THUB_JOB_ID on $(hostname), suite ${JOB_SUITE}"

# optional parameters with defaults
TARGET="${TARGET:-staging}"
BRANCH="${BRANCH:-main}"          # from --env BRANCH=…

# every downloaded file
printf '%s\n' "$THUB_DOWNLOADS" | while read -r f; do echo "downloaded: $f"; done

# HW: flash through the first ST-Link, talk to the second UART
st-flash --reset write "$THUB_DOWNLOAD_1" 0x08000000
python3 -m pytest tests/ --uart "/dev/thub/dut2-uart" --junitxml=results/junit.xml

# CI metadata passed with --meta ciJobId=… / --meta sha=…
echo "CI run ${THUB_META_CI_JOB_ID:-local}, sha ${THUB_META_SHA:-unknown}"
