"""Emulator helper: text/label se button dhoondh ke tap karta hai.
Usage: python3 tool/ui.py tap "Weiter"
"""
import re, subprocess, sys, time


def adb(*args):
    return subprocess.run(["adb", "shell", *args], capture_output=True, text=True).stdout


def nodes():
    adb("uiautomator", "dump", "/sdcard/ui.xml")
    xml = adb("cat", "/sdcard/ui.xml")
    for m in re.finditer(r"<node [^>]*>", xml):
        n = m.group(0)
        text = (re.search(r' text="([^"]*)"', n) or [None, ""])[1]
        desc = (re.search(r'content-desc="([^"]*)"', n) or [None, ""])[1]
        b = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', n)
        if b:
            yield (text + " " + desc), tuple(int(x) for x in b.groups())


def tap(label):
    for _ in range(4):
        for txt, (x0, y0, x1, y1) in nodes():
            if label.lower() in txt.lower() and x1 > x0 and y1 > y0:
                x, y = (x0 + x1) // 2, (y0 + y1) // 2
                adb("input", "tap", str(x), str(y))
                print(f"tap '{label}' at {x},{y}")
                return True
        time.sleep(2)
    print(f"NOT FOUND: {label}")
    return False


if __name__ == "__main__":
    if sys.argv[1] == "tap":
        tap(sys.argv[2])
    elif sys.argv[1] == "dump":
        for txt, b in nodes():
            if txt.strip():
                print(b, txt.strip()[:80])
