#!/usr/bin/env bash
set -euo pipefail

fail=0

check_cmd() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    printf 'OK   %-20s %s\n' "$name" "$(command -v "$name")"
  else
    printf 'MISS %-20s not found\n' "$name"
    fail=1
  fi
}

printf 'ARTEMIS Android environment check\n'
printf '%s\n' '-------------------------------'

if [[ -e /proc/version ]] && grep -qi microsoft /proc/version; then
  printf 'OK   %-20s WSL kernel detected\n' 'WSL2'
else
  printf 'WARN %-20s WSL kernel not detected\n' 'WSL2'
fi

if [[ -c /dev/kvm ]]; then
  printf 'OK   %-20s %s\n' '/dev/kvm' 'present'
else
  printf 'MISS %-20s not present\n' '/dev/kvm'
  fail=1
fi

if id -nG | tr ' ' '\n' | grep -qx kvm; then
  printf 'OK   %-20s current user is a member\n' 'kvm group'
else
  printf 'MISS %-20s current user is not a member\n' 'kvm group'
  fail=1
fi

check_cmd adb
check_cmd emulator
check_cmd avdmanager

if command -v emulator >/dev/null 2>&1; then
  printf '\nKVM acceleration:\n'
  if emulator -accel-check; then
    :
  else
    fail=1
  fi
fi

printf '\nConfigured AVDs:\n'
if command -v avdmanager >/dev/null 2>&1; then
  avdmanager list avd || fail=1
fi

printf '\nConnected devices:\n'
if command -v adb >/dev/null 2>&1; then
  adb devices || fail=1
fi

if (( fail )); then
  printf '\nEnvironment check: FAILED\n'
  exit 1
fi

printf '\nEnvironment check: PASSED\n'
