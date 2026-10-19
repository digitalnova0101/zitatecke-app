#!/bin/bash
# Play Store screenshots: app chala ke har screen ka PNG /tmp/shots mein.
mkdir -p /tmp/shots
UI="python3 tool/ui.py"
shot() { sleep "${2:-3}"; adb exec-out screencap -p > "/tmp/shots/$1.png"; echo "shot $1"; }
adb shell settings put global hide_error_dialogs 1
sleep 40
adb shell am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS >/dev/null 2>&1
# Saaf status bar (12:00, full battery, no notifications)
adb shell settings put global sysui_demo_allowed 1
adb shell am broadcast -a com.android.systemui.demo -e command enter
adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0900
adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false
adb shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4
adb shell am broadcast -a com.android.systemui.demo -e command network -e mobile show -e datatype none -e level 4
adb shell am broadcast -a com.android.systemui.demo -e command notifications -e visible false
adb install -r app.apk > /tmp/shots/install.txt 2>&1
adb logcat -c
adb shell pm grant de.zitatecke.app android.permission.POST_NOTIFICATIONS 2>/dev/null
adb shell monkey -p de.zitatecke.app -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 20
shot 00_welcome 1
focus() { echo "[$1] $(adb shell dumpsys window | grep -m1 mCurrentFocus)" | tee -a /tmp/shots/focus.txt; }
$UI tap "Weiter"; shot dbg_a 2; focus a
$UI tap "Weiter"; shot dbg_b 2; focus b
$UI dump > /tmp/shots/onb_nodes.txt
$UI tap "Ja, gerne"; shot dbg_c 3; focus c
$UI tap "Allow" || $UI tap "Zulassen"; shot dbg_d 3; focus d
front() { adb shell dumpsys window | grep -m1 mCurrentFocus | grep -q zitatecke || { adb shell monkey -p de.zitatecke.app -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 6; }; }
sleep 8
shot 01_home 2
adb shell input swipe 950 1000 150 1000 300; shot 02_home_swipe 3
adb shell input swipe 150 1000 950 1000 300; sleep 2
adb shell input swipe 540 1900 540 900 800; shot 03_categories 3
$UI dump > /tmp/shots/cat_nodes.txt
$UI tap "Gute Nacht"; shot 04_category 4
adb shell input tap 280 900; shot 05_reels 4
adb shell input keyevent KEYCODE_BACK; sleep 2
adb shell input keyevent KEYCODE_BACK; sleep 2
front
adb shell input swipe 540 900 540 2000 400; sleep 1; adb shell input swipe 540 900 540 2000 400; sleep 2
adb shell input tap 540 1000; sleep 4
$UI dump > /tmp/shots/detail_nodes.txt
shot 06_detail 1
$UI tap "Gestalten"; shot 07_gestalten_bild 3
$UI tap "Schrift"; sleep 2
$UI tap "Handschrift"; shot 08_schrift 3
adb shell input keyevent KEYCODE_BACK; sleep 2
front
$UI tap "Einstellungen"; shot 09_settings 3
$UI tap "Dunkel"; sleep 4
$UI tap "Start"; shot 10_dark_home 6
adb shell input swipe 540 1900 540 900 800; shot 11_dark_categories 3
timeout 60 adb logcat -d > /tmp/shots/logcat.txt
grep -E " E flutter|FATAL|AndroidRuntime|zitatecke" /tmp/shots/logcat.txt > /tmp/shots/logcat_app.txt || true
exit 0
