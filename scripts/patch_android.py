#!/usr/bin/env python3
"""Va thu muc android/ do `flutter create` sinh ra de dung duoc Vietmap Navigation SDK."""
import glob, os, re, sys

root = sys.argv[1] if len(sys.argv) > 1 else "."
android = os.path.join(root, "android")

# 1) AndroidManifest: quyen + service dan duong
mf = os.path.join(android, "app/src/main/AndroidManifest.xml")
s = open(mf, encoding="utf-8").read()
perms = """
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
"""
if "ACCESS_FINE_LOCATION" not in s:
    s = s.replace("<application", perms + "    <application", 1)
service = """
        <service
            android:name="vn.vietmap.services.android.navigation.v5.navigation.NavigationService"
            android:foregroundServiceType="location"
            android:exported="false" />
"""
if "NavigationService" not in s:
    s = s.replace("</application>", service + "    </application>", 1)
s = re.sub(r'android:label="[^"]*"', 'android:label="Nav App"', s, count=1)
open(mf, "w", encoding="utf-8").write(s)

# 2) minSdk 24
for f in glob.glob(os.path.join(android, "app/build.gradle*")):
    t = open(f, encoding="utf-8").read()
    t = t.replace("flutter.minSdkVersion", "24")
    t = re.sub(r"(minSdk(?:Version)?\s*=?\s*)\d+", r"\g<1>24", t)
    open(f, "w", encoding="utf-8").write(t)

# 3) jitpack repository
for f in glob.glob(os.path.join(android, "build.gradle*")):
    t = open(f, encoding="utf-8").read()
    if "jitpack.io" not in t:
        t += '\nallprojects {\n    repositories {\n        maven { url = uri("https://jitpack.io") }\n    }\n}\n'
        open(f, "w", encoding="utf-8").write(t)
print("android patched")
