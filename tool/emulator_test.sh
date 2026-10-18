#!/bin/bash
# Emulator mein APK install karke har screen ka screenshot + log save karta hai.
mkdir -p /tmp/emu
APK=build/app/outputs/flutter-apk/app-release.apk
UI="python3 tool/ui.py"
shot() { sleep "${2:-3}"; adb exec-out screencap -p > "/tmp/emu/$1.png"; echo "shot $1"; }

adb install -r "$APK" > /tmp/emu/install.txt 2>&1
adb logcat -c
adb shell monkey -p de.zitatecke.app -c android.intent.category.LAUNCHER 1 > /tmp/emu/launch.txt 2>&1
shot 01_welcome 20
$UI tap "Weiter";            shot 02_welcome2
$UI tap "Weiter";            shot 03_welcome3
$UI tap "Ja, gerne";         sleep 3
$UI tap "Allow" || $UI tap "Zulassen"
shot 04_home 4
$UI dump > /tmp/emu/home_nodes.txt
adb shell input swipe 500 1800 500 600 600; shot 05_home_scrolled
adb shell input swipe 500 600 500 1800 600; sleep 1
$UI tap "Spruch suchen";     sleep 2
adb shell input text "Geburtstag"; shot 06_search
adb shell input keyevent KEYCODE_BACK; sleep 1
adb shell input keyevent KEYCODE_BACK; sleep 2
$UI tap "Spruch des Tages" >/dev/null
adb shell input swipe 500 1500 500 1100 300; sleep 1
$UI tap "Kategorien" >/dev/null
adb shell input swipe 500 1800 500 700 600; sleep 2
$UI tap "Gute Nacht";        shot 07_category
adb shell input tap 540 460; shot 08_detail
adb shell input swipe 900 900 150 900 300; shot 09_detail_swiped
$UI tap "Per WhatsApp senden"; shot 10_share 5
adb shell input keyevent KEYCODE_BACK; sleep 2
# --- Wetter ---
adb shell input keyevent KEYCODE_BACK; sleep 1
adb shell input keyevent KEYCODE_BACK; sleep 2
adb shell input swipe 500 600 500 1900 300; sleep 1
adb shell input swipe 500 1700 500 900 500; sleep 2
$UI tap "Wetter-Sprüche";    shot 11_city
$UI tap "Hamburg";           sleep 4
$UI tap "Deutschland";       sleep 6
shot 12_home_weather
adb shell input swipe 500 1500 500 900 500; shot 13_weather_card
$UI dump > /tmp/emu/weather_nodes.txt
adb logcat -d > /tmp/emu/logcat_full.txt
grep -E " E flutter|FATAL|AndroidRuntime: |zitatecke" /tmp/emu/logcat_full.txt > /tmp/emu/logcat_app.txt || true
exit 0
