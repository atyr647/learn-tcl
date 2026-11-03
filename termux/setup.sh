#!/data/data/com.termux/files/usr/bin/bash
# Installs and launches Learn Tcl inside Termux (Android) using Termux:X11.
# Prerequisite: the "Termux:X11" Android app is installed (from its GitHub releases
# or F-Droid), alongside Termux.  Then, in Termux:
#     pkg install -y curl && curl -fsSL <raw-url-of-this-file> | bash
# or, from a checkout of the repo:   bash termux/setup.sh
set -e
pkg update -y
pkg install -y tcl tk x11-repo
pkg install -y termux-x11-nightly xorg-xrandr fontconfig-utils
APPDIR="$HOME/learn-tcl"
mkdir -p "$APPDIR"
if [ -f "$(dirname "$0")/../dist/learn-tcl.tcl" ]; then
    cp "$(dirname "$0")/../dist/learn-tcl.tcl" "$APPDIR/learn-tcl.tcl"
else
    curl -fsSL "https://raw.githubusercontent.com/atyr647/learn-tcl/ccr-e0debf7c-0h74oo/dist/learn-tcl.tcl" -o "$APPDIR/learn-tcl.tcl"
fi
cat > "$PREFIX/bin/learn-tcl" <<'LAUNCH'
#!/data/data/com.termux/files/usr/bin/bash
# start the X server if it is not running, then the app
if ! pgrep -f "termux-x11 :0" >/dev/null; then
    termux-x11 :0 >/dev/null 2>&1 &
    sleep 3
fi
export DISPLAY=:0
export LEARNTCL_HOME="$HOME/.learn-tcl"
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true
exec wish "$HOME/learn-tcl/learn-tcl.tcl"
LAUNCH
chmod +x "$PREFIX/bin/learn-tcl"
echo
echo "Done. Start the app any time with:   learn-tcl"
