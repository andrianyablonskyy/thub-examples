#!/bin/sh
# ci/renode.sh <app.elf> — run the Robot tests in tests/renode/ on Renode, in
# Docker. JUnit results go to results/, which the Client sums up (§8.1).
set -e
tests=$(cd "$(dirname "$0")/../tests/renode" && pwd)
fw=$(cd "$(dirname "$1")" && pwd)
mkdir -p results
docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp \
  -v "$PWD:/work" -v "$tests:/tests:ro" -v "$fw:/fw:ro" -w /work \
  antmicro/renode:1.16.1 sh -c '
    renode-test --variable "ELF:/fw/$1" -r results /tests/*.robot; rc=$?
    python3 -m robot.rebot --xunit results/junit.xml --output NONE --log NONE --report NONE results/robot_output.xml
    exit $rc' renode "$(basename "$1")"
