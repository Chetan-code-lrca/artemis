#!/usr/bin/env bash
set -euo pipefail

AVD_NAME="${ARTEMIS_AVD_NAME:-Pixel_8_API_34}"

if ! command -v emulator >/dev/null 2>&1; then
  echo "emulator was not found in PATH. Check ANDROID_HOME/ANDROID_SDK_ROOT and PATH."
  exit 1
fi

if ! command -v adb >/dev/null 2>&1; then
  echo "adb was not found in PATH. Install Android Platform-Tools or add it to PATH."
  exit 1
fi

echo "Starting Android AVD: ${AVD_NAME}"
emulator -avd "${AVD_NAME}" "$@"
