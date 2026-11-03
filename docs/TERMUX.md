# Running on Android with Termux (no AndroWish needed)

Termux gives you a Linux shell on Android, and its package repository ships **Tcl and Tk
8.6.14** for 64-bit ARM - the same version this app is tested against. Tk needs an X
display; the **Termux:X11** app provides one.

> **Status:** I verified that the packages exist in Termux's repository and that the app
> starts correctly in a full-screen X display on desktop. I have **not** run this on a phone.
> The commands below are from my knowledge of Termux; if one fails, the error message
> will say which package or app is missing.

## Steps

1. Install **Termux** and **Termux:X11** (the Android app). Get both from F-Droid or their
   GitHub releases - install both from the same source.
2. Open Termux and run:
   ```
   pkg install -y git
   git clone -b ccr-e0debf7c-0h74oo https://github.com/atyr647/learn-tcl
   bash learn-tcl/termux/setup.sh
   ```
3. Start it any time with `learn-tcl`. It starts the X server, opens the Termux:X11
   screen and runs the app full-screen.

Progress is saved in `~/.learn-tcl` inside Termux (on the device).

## Notes

* Touch in Termux:X11 behaves like a mouse/trackpad depending on its settings
  (Preferences -> Pointer). Choose *direct touch* so a tap presses what you tap.
* The on-screen keyboard is Android's: show it from Termux:X11's controls to type code.
* To run manually: `termux-x11 :0 &` then `DISPLAY=:0 wish ~/learn-tcl/learn-tcl.tcl`.
