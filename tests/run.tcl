# Headless tests: no Tk needed.   tclsh tests/run.tcl
set root [file dirname [file dirname [file normalize [info script]]]]
foreach f {util theme store srs sandbox content} { source -encoding utf-8 $root/lib/$f.tcl }
set tmp [file join [expr {[info exists ::env(TMPDIR)] ? $::env(TMPDIR) : "/tmp"}] learn-tcl-test-[pid]]
file mkdir $tmp
sandbox::init $tmp
set fails 0
proc check {name cond} {
    if {[uplevel 1 [list expr $cond]]} { puts "  ok    $name" } else { puts "  FAIL  $name"; incr ::fails }
}

puts "== scheduler"
set util::todayOverride 1000
set c [srs::new]
check "new card due today" {[dict get $c due] == 1000}
set c1 [srs::grade $c 2]
check "good #1 -> 1 day" {[dict get $c1 ivl] == 1 && [dict get $c1 due] == 1001}
set util::todayOverride 1001
set c2 [srs::grade $c1 2]
check "good #2 -> 3 days" {[dict get $c2 ivl] == 3}
set util::todayOverride 1004
set c3 [srs::grade $c2 2]
check "good #3 grows by ease (>=7)" {[dict get $c3 ivl] >= 7}
set c4 [srs::grade $c3 0]
check "again resets + lapse" {[dict get $c4 ivl] == 0 && [dict get $c4 lapses] == 1 && [dict get $c4 reps] == 0}
check "ease floor 1.3" {[dict get [srs::grade [dict replace $c4 ease 1.3] 0] ease] >= 1.3}
check "easy > good" {[dict get [srs::grade $c3 3] ivl] > [dict get [srs::grade $c3 2] ivl]}
check "hard < good" {[dict get [srs::grade $c3 1] ivl] < [dict get [srs::grade $c3 2] ivl]}
check "preview labels" {[srs::preview $c 0] eq "<10m" && [srs::preview $c 2] eq "1d"}

puts "== store"
store::init $tmp/data
check "defaults" {[dict get $::state xp] == 0}
set util::todayOverride 2000
store::addXP 30
check "xp + streak 1" {[dict get $::state xp] == 30 && [store::streak] == 1}
set util::todayOverride 2001
store::addXP 10
check "streak 2" {[store::streak] == 2}
set util::todayOverride 2004
check "streak lapses" {[store::streak] == 0}
store::addXP 5
check "streak restarts" {[dict get $::state streak] == 1 && [dict get $::state best] == 2}
srs::add testcard
store::save
set saved $::state
store::init $tmp/data
check "round trip" {$::state eq $saved}
set f [open $tmp/data/state.tcl w]; puts $f "{{{ broken"; close $f
store::init $tmp/data
check "corrupt file tolerated" {[dict get $::state xp] == 0}
check "level math" {[store::level] == 1}

puts "== course content"
foreach f [lsort [glob -directory $root/content u*.tcl]] { source -encoding utf-8 $f }
set probs [content::check]
foreach p $probs { puts "  FAIL  $p"; incr fails }
set nl [llength [content::ids]]
set ne [llength [content::allEx]]
set nc 0; foreach id [content::ids] { incr nc [llength [dict get [content::get $id] cards]] }
puts "  lessons: $nl   exercises: $ne   flashcards: $nc   problems: [llength $probs]"
check "units all have lessons" {[expr {[llength [lsearch -all -not -exact [lmap u $content::units {llength [content::lessonsOf [dict get $u n]]}] 0]] == [llength $content::units]}]}
# exercise ids unique, card ids unique
set seen {}
foreach id [content::ids] {
    foreach e [dict get [content::get $id] ex] { dict set seen [dict get $e id] 1 }
}
check "exercise ids unique" {[dict size $seen] == $ne}
# every card/ex front is non-empty
set bad 0
foreach id [content::ids] { foreach c [dict get [content::get $id] cards] { if {[string trim [dict get $c front]] eq "" || [string trim [dict get $c back]] eq ""} { incr bad } } }
check "no empty flashcards" {$bad == 0}

file delete -force $tmp
puts "\n[expr {$fails ? "$fails FAILED" : "ALL PASSED"}]"
exit [expr {$fails ? 1 : 0}]
