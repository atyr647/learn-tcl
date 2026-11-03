# Checks that the single-file bundle really is self-contained.
#   tclsh tools/bundle.tcl /tmp/b/learn-tcl.tcl
#   mkdir /tmp/empty && cd /tmp/empty && xvfb-run wish /path/tests/bundle_test.tcl /tmp/b/learn-tcl.tcl
set ::LEARNTCL_NO_MAIN 1
set ::env(LEARNTCL_HOME) /tmp/learn-tcl-bundle-test
source [lindex $argv 0]
if {[llength [content::ids]] < 30} { puts "FAIL: content missing"; exit 1 }
boot::main
update
if {![winfo exists .v.s_home]} { puts "FAIL: home screen not built"; exit 1 }
puts "BUNDLE OK: [llength [content::ids]] lessons, no source files needed"
exit 0
