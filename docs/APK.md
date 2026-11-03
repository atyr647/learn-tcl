# The Android APK

`dist/LearnTcl-arm64-debug.apk` is a self-contained app: AndroWish's Tcl/Tk 8.6 runtime
(SDL-based Tk for Android) with this course embedded, so nothing else needs installing.

* Package `tk.tcl.wish`, app name **Learn Tcl**, 64-bit ARM only (virtually all phones since ~2017).
* Android 4.0+ (minSdk 14); targets API 26.
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
