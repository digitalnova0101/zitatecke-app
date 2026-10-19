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
adb shell pm grant de.zitatecke.app android.permission.POST_NOTIFICATIONS 2>/dev/null
adb shell monkey -p de.zitatecke.app -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 20
shot 00_welcome 1
$UI tap "Weiter"; sleep 2
$UI tap "Weiter"; sleep 2
$UI tap "Ja, gerne"; sleep 3
$UI tap "Allow" || $UI tap "Zulassen"; sleep 3
# Stadt setzen
$UI tap "Einstellungen"; sleep 2
$UI tap "Meine Stadt"; sleep 2
$UI tap "Hamburg"; sleep 5
$UI tap "Deutschland"; sleep 6
adb shell input keyevent KEYCODE_BACK; sleep 1
$UI tap "Start"; sleep 10
shot 01_home
$UI dump > /tmp/shots/home_nodes.txt
adb shell input swipe 950 1000 150 1000 300; shot 02_home_swipe
adb shell input swipe 950 1000 150 1000 300; shot 02b_home_swipe
adb shell input swipe 150 1000 950 1000 300; adb shell input swipe 150 1000 950 1000 300; sleep 1
adb shell input swipe 540 1900 540 700 700; shot 03_categories
$UI dump > /tmp/shots/cat_nodes.txt
$UI tap "Gute Nacht"; shot 04_category 4
adb shell input tap 280 900; shot 05_reels 4
adb shell input swipe 540 1700 540 500 300; shot 05b_reels 3
adb shell input keyevent KEYCODE_BACK; sleep 1
adb shell input keyevent KEYCODE_BACK; sleep 2
adb shell input swipe 540 700 540 2000 400; adb shell input swipe 540 700 540 2000 400; sleep 2
adb shell input tap 540 1000; sleep 3
$UI tap "Gestalten"; shot 06_gestalten_bild 3
$UI tap "Schrift"; sleep 2
$UI tap "Handschrift"; shot 07_schrift 3
$UI tap "Fertig"; shot 07b_detail 2
adb shell input keyevent KEYCODE_BACK; sleep 2
$UI tap "Einstellungen"; sleep 2
shot 08_settings 1
$UI tap "Dunkel"; sleep 3
$UI tap "Start"; shot 09_dark_home 6
adb shell input swipe 540 1900 540 700 700; shot 10_dark_categories 3
exit 0
