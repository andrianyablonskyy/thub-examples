#!/bin/sh
# ci/power.sh on|off|reset [off-seconds] — switch this bench's socket or PDU outlet.
# BENCH_POWER (the Client's environment, or --env) names the device:
#   shelly:10.0.20.11   tasmota:10.0.20.12   ha:switch.bench1   apc:pdu1.lab:5
# Credentials, passed with --env: POWER_PASSWORD (Shelly, Tasmota), HA_URL + HA_TOKEN, PDU_COMMUNITY.
set -eu
: "${BENCH_POWER:?BENCH_POWER is not set for this Client (see README §8.8)}"
kind=${BENCH_POWER%%:*} target=${BENCH_POWER#*:}

switch() {   # $1: on | off
  case $kind in
    shelly)
      url="http://$target/rpc/Switch.Set?id=0&on=$([ "$1" = on ] && echo true || echo false)"
      if [ -n "${POWER_PASSWORD:-}" ]; then curl -fsS --digest -u "admin:$POWER_PASSWORD" "$url"; else curl -fsS "$url"; fi ;;
    tasmota)
      curl -fsS "http://$target/cm?user=admin&password=${POWER_PASSWORD:-}&cmnd=Power%20$1" ;;
    ha)
      curl -fsS -X POST -H "Authorization: Bearer $HA_TOKEN" -H 'Content-Type: application/json' \
        -d "{\"entity_id\":\"$target\"}" "$HA_URL/api/services/switch/turn_$1" ;;
    apc)
      snmpset -v1 -c "$PDU_COMMUNITY" "${target%:*}" "1.3.6.1.4.1.318.1.1.12.3.3.1.1.4.${target##*:}" \
        i "$([ "$1" = on ] && echo 1 || echo 2)" ;;
    *)
      echo "power.sh: unknown device kind '$kind' in BENCH_POWER" >&2; exit 2 ;;
  esac >/dev/null
  echo "power: $BENCH_POWER $1"
}

case ${1:-} in
  on|off) switch "$1" ;;
  reset)  switch off; sleep "${2:-1}"; switch on ;;
  *)      echo "usage: power.sh on|off|reset [off-seconds]" >&2; exit 2 ;;
esac
