# The production Android app (tcldroid)

Learn Tcl ships as a native Android app built on **tcldroid** (github.com/atyr647/tcldroid): real
Tcl/Tk 9.0 running through a native Android backend (no SDL, no emulation layer). The earlier
AndroWish-based build is retired; see "Going back" below.

| | |
|---|---|
| File | `dist/LearnTcl.apk` (+ `.sha256`) |
| Name / id | **Learn Tcl** / `tk.tcl.wish` |
| ABIs | arm64-v8a |
| Versioning | `versionCode` = build number (minutes since 2026-01-01), `versionName` = `1.1.<build>`; shown under Profile > About |
| Icon | adaptive icon: white `[ ]` brackets (Tcl's command substitution) around a mint terminal prompt on the brand purple `#6B58EC`; launch screen is the app's dark background `#0B0F1A` |
| Sources | `assets/icon/` (made by `tools/make-icon.py`) |

## Updating over the old app keeps your progress

The id (`tk.tcl.wish`) and the signing key are the same as the AndroWish build, and the build number is
higher, so Android installs this APK **over** the old one. Progress lives in the app's private files
directory (`files/.learn-tcl`), which both runtimes use, so streak, XP, lessons and flashcards carry
over. Do not change the id or the key lightly: either change makes Android treat it as a different app
and the old progress is not reachable.

The key is **not** in this repository (and must never be committed). Keep a backup of it; losing it
means no future update can install over an existing copy.

## Building

Needs a tcldroid checkout (built and tested here at commit `29d241c`, version 0.9.4), plus `cmake`,
`ninja`, a JDK and network access for the first build (tcldroid fetches its own Android NDK and SDK
pieces and builds Tcl and Tk from source).

```
TCLDROID_DIR=~/tcldroid \
LEARNTCL_KEYSTORE=~/keys/learn-tcl.keystore \
TCLDROID_KS_PASS=... \
tools/tcldroid/build.sh
```

`LEARNTCL_KEY_ALIAS` (default `androiddebugkey`), `LEARNTCL_ABIS` and `LEARNTCL_DEBUG=1` (debuggable
build) are optional. The script stages only `main.tcl`, `lib/`, `content/` and the icon (not the tests,
docs or old APKs), stamps the build number, and calls tcldroid's `tools/pack-app.sh`.

## How the app adapts to tcldroid

* `main.tcl` detects tcldroid (`::tkdroid::vibrate`) next to AndroWish and the desktop.
* Sound: the generated WAV effects are played through `::tkdroid::sound`; haptics use `::tkdroid::vibrate`.
* Back: `WM_DELETE_WINDOW` steps back inside the app and exits only from Home.
* Progress and the image cache are flushed on `<<AndroidSaveState>>` (app going to the background).
* All variable references to other namespaces are absolute (`$::store::dir`), which is required by
  Tcl 9 and also works on 8.6.

## Testing

```
tests/all.sh                                              # Tcl/Tk 8.6 (default)
TCLSH=.../tclsh9.0 WISH=.../wish9.0 tests/all.sh          # Tcl/Tk 9.0, what the app runs on Android
```

Both pass: 770 exercises executed in the sandbox, every lesson played through the real widgets, and the
single-file bundle. These are desktop tests; they cannot cover tcldroid's Android drawing, touch,
keyboard or sound, which are verified by using the app on a phone.

## Going back (rollback)

The AndroWish build recipe is kept in `tools/apk/` and `docs/APK.md` for reference. An AndroWish APK with
a lower `versionCode` will not install over this one; uninstall first (which deletes progress) or rebuild
it with a higher code.
