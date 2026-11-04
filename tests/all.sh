#!/usr/bin/env bash
# Runs every automated check. Needs: tclsh, wish, xvfb-run (for the UI tests).
# Use another Tcl/Tk (e.g. 9.0) with:  TCLSH=/path/tclsh9.0 WISH=/path/wish9.0 tests/all.sh
set -e
cd "$(dirname "$0")/.."
TCLSH=${TCLSH:-tclsh}
WISH=${WISH:-wish}
echo "### content + scheduler + storage (headless)"
$TCLSH tests/run.tcl | tail -8
echo "### UI smoke test: plays every lesson through the real widgets"
xvfb-run -a -s "-screen 0 1100x900x24" $WISH tests/ui_smoke.tcl | tail -3
echo "### single-file bundle"
$TCLSH tools/bundle.tcl /tmp/learn-tcl-bundle/learn-tcl.tcl
( mkdir -p /tmp/learn-tcl-empty && cd /tmp/learn-tcl-empty && \
  xvfb-run -a -s "-screen 0 1100x900x24" $WISH "$OLDPWD/tests/bundle_test.tcl" /tmp/learn-tcl-bundle/learn-tcl.tcl )
