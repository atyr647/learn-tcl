#!/usr/bin/env bash
# Build the production Android app: Learn Tcl running on tcldroid (native Tcl/Tk 9 for Android).
#
#   TCLDROID_DIR=/path/to/tcldroid  LEARNTCL_KEYSTORE=/path/to/key  tools/tcldroid/build.sh
#
# Environment:
#   TCLDROID_DIR         checkout of github.com/atyr647/tcldroid          (required)
#   LEARNTCL_KEYSTORE    signing key (required; never commit it)
#   LEARNTCL_KEY_ALIAS   key alias in that file                            (default androiddebugkey)
#   TCLDROID_KS_PASS     keystore password (asked for if unset and a terminal is attached)
#   LEARNTCL_ABIS        ABIs to ship                                      (default arm64-v8a)
#   LEARNTCL_DEBUG=1     build a debuggable APK instead of a release APK
#   LEARNTCL_ID          application id                                    (default tk.tcl.wish)
#
# The application id and the signing key are what let this APK install OVER the old AndroWish-based
# Learn Tcl and keep the learner's progress (see docs/TCLDROID.md). Do not change either casually.
# versionCode is the build number (minutes since 2026-01-01), so every build is newer than the last
# and newer than the AndroWish builds (<= 441939).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)

: "${TCLDROID_DIR:?set TCLDROID_DIR to a tcldroid checkout}"
: "${LEARNTCL_KEYSTORE:?set LEARNTCL_KEYSTORE to the signing key file}"
[ -x "$TCLDROID_DIR/tools/pack-app.sh" ] || { echo "$TCLDROID_DIR is not a tcldroid checkout" >&2; exit 1; }
[ -f "$LEARNTCL_KEYSTORE" ] || { echo "keystore not found: $LEARNTCL_KEYSTORE" >&2; exit 1; }
alias=${LEARNTCL_KEY_ALIAS:-androiddebugkey}
id=${LEARNTCL_ID:-tk.tcl.wish}
abis=${LEARNTCL_ABIS:-arm64-v8a}
build=$(( ($(date -u +%s) - $(date -u -d 2026-01-01T00:00:00Z +%s)) / 60 ))
name=${LEARNTCL_VERSION_NAME:-1.1}.$build

# Stage only what the app needs (the repo also holds tests, docs and old APKs).
stage=$(mktemp -d "${TMPDIR:-/tmp}/learntcl-stage.XXXXXX")
trap 'rm -rf "$stage"' EXIT
cp -r "$repo/lib" "$repo/content" "$stage/"
{ echo "set ::LEARNTCL_BUILD $build"; cat "$repo/main.tcl"; } > "$stage/main.tcl"
cp "$repo/assets/icon/icon-foreground.png" "$stage/"

mode=--release
[ -z "${LEARNTCL_DEBUG:-}" ] || mode=
echo "Learn Tcl $name  (code $build, id $id, abis $abis, tcldroid $(git -C "$TCLDROID_DIR" rev-parse --short HEAD 2>/dev/null || echo '?'))"
"$TCLDROID_DIR/tools/pack-app.sh" "$stage" \
    --name "Learn Tcl" --id "$id" --version "$name" --code "$build" \
    --abis "$abis" --orientation auto --backup \
    --icon-bg '#6B58EC' --splash '#0B0F1A' \
    --keystore "$LEARNTCL_KEYSTORE" --key-alias "$alias" $mode

mkdir -p "$repo/dist"
out=$(ls -t "$TCLDROID_DIR"/out/*.apk | head -1)
cp "$out" "$repo/dist/LearnTcl.apk"
( cd "$repo/dist" && sha256sum LearnTcl.apk > LearnTcl.apk.sha256 )
echo "wrote dist/LearnTcl.apk"
