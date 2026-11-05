# Running Learn Tcl on Android

> **Retired.** The production app is now the tcldroid build, see [TCLDROID.md](TCLDROID.md). This page documents running Learn Tcl under AndroWish, for reference.

Android does not run Tcl/Tk by itself. **AndroWish** is a port of Tcl/Tk (with a
touch-capable Tk) to Android, and this app is a plain Tcl/Tk program, so AndroWish
is the way to run it with no changes.

> **Honest status.** The app has been developed and tested on desktop Tcl/Tk 8.6
> (including a phone-sized window, all 38 lessons driven through the real UI, and
> screenshots). It was **not** run on a physical Android device while it was being
> built, because that was not possible in the build environment. It only uses
> standard Tcl/Tk 8.6 features and is written defensively for AndroWish
> (pixel-based fonts scaled from the screen width, drag-to-scroll instead of a mouse
> wheel, no emoji, safe fallbacks for storage and the keyboard), but if something
> looks off on your phone, that is the place to look - please report it.

## Steps

1. **Install AndroWish** on your phone. Get it from the project's site,
   <https://www.androwish.org>, and follow the install instructions there (it is
   distributed as an APK, so Android may ask you to allow installing from that source).
2. **Get the app file onto the phone.** The easiest way is the single file
   `dist/learn-tcl.tcl` from this repository (open the repository on GitHub in your
   phone's browser, open the file, and download it). Or copy it over USB / cloud
   storage into, for example, your *Downloads* folder.
3. **Open it with AndroWish.** From your file manager, open `learn-tcl.tcl` with
   AndroWish. If your file manager does not offer that, start AndroWish and run, in
   its console:

   ```
   source /sdcard/Download/learn-tcl.tcl
   ```

   (adjust the path to wherever you put the file).

Progress is stored in a private folder chosen at startup (it tries AndroWish's app
files directory first, then `$HOME`, then a temporary folder). The Profile screen
shows the exact path, and says so if saving is not possible.

## Performance note

Smooth icons and corners are drawn in pure Tcl the first time they are needed, then
cached. On a desktop the first screen builds in about 0.4 s and later ones in about 0.2 s;
a phone will be slower (expect a noticeable first-launch pause). Please report timings.

## Tips and known unknowns

* The app asks AndroWish to show the on-screen keyboard when you tap a text field. If
  your AndroWish version does not do that automatically, tap the field again or open
  the keyboard from Android's own controls.
* Typing code on a phone is slow, so exercises lean on tapping: multiple choice,
  tap-to-fill blanks and tap-to-order lines. Typed exercises are short, and the
  Playground has a symbol keypad for `{ } [ ] $ "` and friends.
* The window fills the screen and scales from the shorter screen side, so it works in
  portrait; landscape works but is best on a tablet.
* Building a standalone, installable APK of this app (so you do not need AndroWish
  separately) is possible with AndroWish's own build system, but that needs the
  Android SDK/NDK and was out of scope here. The bundle script (`tools/bundle.tcl`)
  produces the single script file such a build would embed.

## Troubleshooting

| Symptom | Try |
|---|---|
| Nothing happens when opening the file | Use the console and `source` the file; any error message tells you what is missing |
| Text is too small or too big | Fonts are sized from the screen width; if your device reports an unusual size, tell me the screen size and AndroWish version |
| Progress is not saved | Open Profile -> About to see the save location; AndroWish needs a writable private folder |
| A tap scrolls instead of pressing | Taps that move more than a few millimetres count as scrolling, by design |
