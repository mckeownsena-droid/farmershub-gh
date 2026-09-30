#!/usr/bin/env bash
set -euo pipefail
apk="${1:?Pass the release APK path}"
: "${ANDROID_HOME:?Set ANDROID_HOME}"
adb="$ANDROID_HOME/platform-tools/adb"
serial="${ANDROID_SERIAL:-emulator-5554}"
package=com.mycompany.farmershubghmvp
out="${SMOKE_OUTPUT:-build/beta-smoke}"
mkdir -p "$out"
"$adb" -s "$serial" wait-for-device
for attempt in $(seq 1 120); do
  if [[ "$("$adb" -s "$serial" shell getprop sys.boot_completed | tr -d '\r')" == 1 ]]; then break; fi
  sleep 2
done
[[ "$("$adb" -s "$serial" shell getprop sys.boot_completed | tr -d '\r')" == 1 ]]
"$adb" -s "$serial" install -r "$apk"
"$adb" -s "$serial" logcat -c
"$adb" -s "$serial" shell am force-stop "$package"
"$adb" -s "$serial" shell am start -W -n "$package/$package.MainActivity" | tee "$out/launch.txt"
sleep 15
"$adb" -s "$serial" shell pidof "$package" | tee "$out/pid.txt"
"$adb" -s "$serial" logcat -d > "$out/logcat.txt"
if grep -En 'FATAL EXCEPTION|Unable to instantiate activity|ClassNotFoundException.*MainActivity|FarmersHub startup failed' "$out/logcat.txt"; then exit 1; fi
"$adb" -s "$serial" exec-out screencap -p > "$out/login.png"
"$adb" -s "$serial" shell am force-stop "$package"
"$adb" -s "$serial" shell am start -W -n "$package/$package.MainActivity" > "$out/relaunch.txt"
sleep 5
"$adb" -s "$serial" shell pidof "$package"
printf 'APK launch and relaunch passed. Inspect login.png before acceptance.\n'
