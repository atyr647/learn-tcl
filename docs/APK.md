# The Android APK

> **Retired.** The production app is now the tcldroid build, see [TCLDROID.md](TCLDROID.md). This page documents the old AndroWish-based APK for reference.

The retired AndroWish build (removed from `dist/`; see git history) was a self-contained app: AndroWish's Tcl/Tk 8.6 runtime
(SDL-based Tk for Android) with this course embedded, so nothing else needs installing.

* Package `tk.tcl.wish`, app name **Learn Tcl**, 64-bit ARM only (virtually all phones since ~2017).
* Android 4.0+ (minSdk 14); targets API 30.
* Signed with the standard Android *debug* key, so it installs by sideloading but is not a
  Play Store release. (Package name is AndroWish's, so it replaces an installed AndroWish.)
* SHA-256 is in `dist/LearnTcl-arm64-debug.apk.sha256`.

## Install

Copy the APK to the phone, open it, and allow "install unknown apps" for your file
manager/browser when asked. Or with a computer: `adb install -r LearnTcl-arm64-debug.apk`.

## How it was built (reproducible)

Source: the AndroWish tree (https://fossil.etoyoc.com/fossil/androwish, trunk). Toolchain:
JDK 8, Android SDK platform 26 + build-tools 28.0.3, NDK r16b, Gradle 4.10.2 (wrapper).
Changes made to the stock tree:

1. `assets/learn-tcl.tcl` = `dist/learn-tcl.tcl` (the one-file bundle).
2. `src/tk/tcl/wish/AndroWishLauncher.java`: when launched with no file, run
   `/assets/learn-tcl.tcl` instead of opening the AndroWish console
   (patched file: `tools/apk/AndroWishLauncher.java.patched`).
3. `res/values/strings.xml`: `app_name` = Learn Tcl.
4. `jni/Application64.mk`: `APP_ABI := arm64-v8a` (faster build, smaller APK).
5. `build.gradle`: `jcenter()` -> `mavenCentral()` (jcenter is retired).
6. `ANDROID_HOME`, `ANDROID_NDK_HOME` set; `./gradlew assembleDebug --max-workers=1`.

## Honest status

Built and structurally verified (signature valid, native libraries and the embedded script
present, launcher activity and label correct). **It has not been run on a device or
emulator** - none was available. First-launch problems, if any, are most likely in how
the embedded `/assets/` script path is handled; please report what you see.

## Progress, updates and signing (important)

* **Where progress is stored:** the app's private internal storage, `files/.learn-tcl/state.tcl`
  (AndroWish sets `HOME` to it). It is written after every answer, atomically (temp file
  then rename), with the previous good copy kept as `state.tcl.bak`. If the main file is
  ever unreadable the backup is used and the bad file is kept as `state.tcl.bad`.
* **Restarts and updates keep it.** Internal storage survives app restarts and in-place
  updates. It is removed only by **uninstalling** the app or **clearing its data**. The
  manifest also has `allowBackup="true"`, so Android's automatic backup can restore it
  after a reinstall or on a new phone.
* **Updates must be signed with the same key.** Android refuses to install over an
  existing app signed with a different key, and the only way round that is to uninstall
  (which erases progress). Every build has so far been signed with the same key; the
  SHA-256 of its certificate is
  `24:43:09:3A:CC:1B:45:08:F1:7E:15:5D:E0:E6:14:FC:D6:B6:2F:ED:2F:63:9D:B8:83:9E:39:E2:FA:C4:AA:45`
  (check any APK with `apksigner verify --print-certs`).
  **The key file is deliberately NOT in this repository** - anyone holding it could sign
  a fake update that phones would accept. Keep a private backup (`learntcl-debug.keystore`,
  password `android`, alias `androiddebugkey`) and put it at `~/.android/debug.keystore`
  before building; `tools/apk/runbuild.sh` uses it from there. If the key is ever lost,
  the next build gets a new identity and cannot update the installed app.
* **Version code increases on every build** (minutes since 2026-01-01), so each new APK
  is a valid update. Check with `aapt dump badging`.
* Future versions keep unknown fields in the save file, so installing an older build
  over a newer one never loses data either.
* This is a debug-style key meant for personal sideloading. For the Play Store you would
  create a proper, secret release key and use Play App Signing.
