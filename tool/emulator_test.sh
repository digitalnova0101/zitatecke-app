#!/bin/bash
# Emulator mein APK install karke chalata hai, screenshot + log save karta hai.
mkdir -p /tmp/emu
APK=build/app/outputs/flutter-apk/app-release.apk
adb install -r "$APK" > /tmp/emu/install.txt 2>&1
adb logcat -c
adb shell monkey -p de.zitatecke.app -c android.intent.category.LAUNCHER 1 > /tmp/emu/launch.txt 2>&1
sleep 25
adb exec-out screencap -p > /tmp/emu/screen_start.png
# Notification permission popup ho to Allow
adb shell input keyevent KEYCODE_BACK || true
sleep 5
adb exec-out screencap -p > /tmp/emu/screen_after.png
adb logcat -d > /tmp/emu/logcat_full.txt
grep -E "flutter|AndroidRuntime|FATAL|Exception|zitatecke" /tmp/emu/logcat_full.txt > /tmp/emu/logcat_app.txt || true
exit 0
