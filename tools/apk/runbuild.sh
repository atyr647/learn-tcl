#!/bin/bash
# Reproducible build of the Learn Tcl APK (see docs/APK.md).
# The signing key MUST stay the same for every build, otherwise Android refuses to
# install a new APK over the old one (and the user would have to uninstall and lose
# their progress). The key is NOT in the repository (it is a secret): keep a private
# backup and place it at ~/.android/debug.keystore before building.
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 ANDROID_HOME=/home/user/aw/sdk ANDROID_NDK_HOME=/home/user/aw/sdk/android-ndk-r16b PATH=/usr/lib/jvm/java-8-openjdk-amd64/bin:$PATH
mkdir -p ~/.android
[ -f ~/.android/debug.keystore ] || { echo 'MISSING ~/.android/debug.keystore - a new key would break updates!'; exit 1; }
cd /home/user/aw/tree/x
# minutes since 2026-01-01: unique and increasing for every build
# use the build number stamped into the bundle so the in-app 'Build:' line equals versionCode
VCODE=$(grep -o 'LEARNTCL_BUILD [0-9]*' /home/user/learn-tcl/dist/learn-tcl.tcl | head -1 | awk '{print $2}')
[ -n "$VCODE" ] || VCODE=$(( ($(date +%s) - 1767225600) / 60 ))
for i in 1 2 3 4 5 6 7 8; do
  ./gradlew assembleDebug --no-daemon --max-workers=1 -Dorg.gradle.parallel=false -Pvcode=$VCODE > /home/user/aw/build.log 2>&1 && { echo BUILD_OK >> /home/user/aw/build.log; exit 0; }
  grep -q "429" /home/user/aw/build.log || break
  sleep 20
done
echo BUILD_FAILED >> /home/user/aw/build.log
