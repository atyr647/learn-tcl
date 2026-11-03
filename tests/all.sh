#!/usr/bin/env bash
# Runs every automated check. Needs: tclsh, wish, xvfb-run (for the UI tests).
set -e
cd "$(dirname "$0")/.."
echo "### content + scheduler + storage (headless)"
tclsh tests/run.tcl | tail -8
echo "### UI smoke test: plays every lesson through the real widgets"
xvfb-run -a -s "-screen 0 420x860x24" wish tests/ui_smoke.tcl | tail -3
echo "### single-file bundle"
tclsh tools/bundle.tcl /tmp/learn-tcl-bundle/learn-tcl.tcl
( mkdir -p /tmp/learn-tcl-empty && cd /tmp/learn-tcl-empty && \
  xvfb-run -a -s "-screen 0 420x860x24" wish "$OLDPWD/tests/bundle_test.tcl" /tmp/learn-tcl-bundle/learn-tcl.tcl )
