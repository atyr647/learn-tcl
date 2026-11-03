# Headless tests: no Tk needed.   tclsh tests/run.tcl
set root [file dirname [file dirname [file normalize [info script]]]]
foreach f {util theme store srs sandbox content sfx} { source -encoding utf-8 $root/lib/$f.tcl }
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

puts "== persistence (restart / update / crash safety)"
set pd $tmp/persist
file delete -force $pd
store::init $pd
store::addXP 120
dict set ::state lessons 1.1 [dict create stars 3 day 5]
store::save
store::addXP 30
store::save
check "two saves leave a backup of the previous one" {[file exists $pd/state.tcl.bak]}
# simulate an app restart
store::init $pd
check "progress survives a restart" {[dict get $::state xp] == 150 && [dict exists $::state lessons 1.1]}
# simulate a crash that left a half-written temp file
set h [open $pd/state.tcl.tmp w]; puts -nonewline $h "{{{ half writ"; close $h
store::init $pd
check "a stray half-written temp file is ignored" {[dict get $::state xp] == 150}
# simulate corruption of the main file
set h [open $pd/state.tcl w]; puts -nonewline $h "garbage {{"; close $h
store::init $pd
check "corrupt main file recovers from the backup" {[dict get $::state xp] >= 120 && [dict exists $::state lessons 1.1]}
check "the unreadable file is kept as .bad, not erased" {[file exists $pd/state.tcl.bad]}
# an update that adds new keys / an older file without them
set h [open $pd/state.tcl w]; puts -nonewline $h [list xp 77 settings {theme light goal 100} lessons {2.1 {stars 2 day 1}}]; close $h
file delete -force $pd/state.tcl.bak
store::init $pd
check "older file gets new default keys (schema, cards...)" {[dict get $::state schema] == 1 && [dict exists $::state cards] && [dict get $::state xp] == 77}
check "settings added in newer versions fall back to defaults" {[store::setting sound 1] == 1 && [store::setting theme x] eq "light"}
# a NEWER version's file opened by an older one must not lose unknown data
set h [open $pd/state.tcl w]; puts -nonewline $h [list xp 5 futureFeature {a 1 b 2} schema 9]; close $h
store::init $pd
store::addXP 1
store::save
store::init $pd
check "unknown (future) keys are preserved across save/load" {[dict get $::state futureFeature] eq "a 1 b 2"}
# directory choice: private internal storage first, temp last
set old [array get ::env]
set ::env(INTERNAL_STORAGE) $tmp/internal
set ::env(HOME) $tmp/home
set ::env(TMPDIR) $tmp/cache
unset -nocomplain ::env(LEARNTCL_HOME)
set cands [store::candidates]
check "Android internal storage is the first choice" {[lindex $cands 0] eq "$tmp/internal/.learn-tcl"}
check "the cache/temp dir is only a last resort" {[lsearch $cands "$tmp/cache/learn-tcl"] > [lsearch $cands "$tmp/home/.learn-tcl"]}
check "chosen dir is writable and not the cache" {[string match "$tmp/internal*" [store::chooseDir]]}
# migration: progress kept in an older location is adopted
file delete -force $tmp/internal $tmp/home
file mkdir $tmp/home/.learn-tcl
set h [open $tmp/home/.learn-tcl/state.tcl w]; puts -nonewline $h [list xp 999]; close $h
set ::env(INTERNAL_STORAGE) $tmp/internal2
store::init
check "progress from an older location is adopted" {[dict get $::state xp] == 999}
array unset ::env
array set ::env $old
store::init $tmp/data

puts "== sound effects"
set ::env(LEARNTCL_NOSOUND) 1
sfx::init $tmp/sfxtest
check "sound off in headless test mode" {$sfx::backend eq "none"}
foreach n [lsort [array names sfx::defs]] {
    set f [sfx::ensure $n]
    set h [open $f rb]; set d [read $h]; close $h
    binary scan $d a4ia4a4issiissa4i riff len wave fmt sz fmtc ch rate brate align bits dat dlen
    binary scan [string range $d 44 end] s* pcm
    set peak 0; foreach v $pcm { if {abs($v) > $peak} { set peak [expr {abs($v)}] } }
    set dur [expr {[llength $pcm] / double($rate)}]
    check "$n: valid mono 16-bit WAV ($riff/$wave, ${rate}Hz)" {$riff eq "RIFF" && $wave eq "WAVE" && $ch == 1 && $bits == 16 && $rate == 16000 && $dlen == 2 * [llength $pcm]}
    check "$n: duration sane ([format %.2f $dur]s)" {$dur > 0.015 && $dur < 1.3}
    check "$n: loudness sane ([expr {100 * $peak / 32767}]%, no clipping)" {$peak > 3000 && $peak < 22000}
    check "$n: silent at both ends (no click)" {abs([lindex $pcm 0]) < 50 && abs([lindex $pcm end]) < 50}
}
# the external-player path really runs a player on the cached file
set sfx::backend external
set sfx::player /bin/true
check "play via external backend works" {![catch {sfx::play correct}]}
check "unknown effect is ignored" {![catch {sfx::play nosuchsound}]}
set sfx::backend none

puts "== source hygiene"
set nonascii {}
foreach f [concat [glob -directory $root/lib *.tcl] [glob -directory $root/content *.tcl] $root/main.tcl] {
    set h [open $f rb]; set d [read $h]; close $h
    if {[regexp {[\x80-\xff]} $d]} { lappend nonascii [file tail $f] }
}
check "all source files are pure ASCII ($nonascii)" {[llength $nonascii] == 0}

puts "== accessibility: WCAG contrast"
proc lum {c} { scan $c "#%2x%2x%2x" r g b; set s 0
    foreach v [list $r $g $b] w {.2126 .7152 .0722} { set x [expr {$v/255.0}]; set x [expr {$x<=0.03928 ? $x/12.92 : pow(($x+0.055)/1.055,2.4)}]; set s [expr {$s+$w*$x}] }
    return $s }
proc ratio {a b} { set la [lum $a]; set lb [lum $b]; expr {(max($la,$lb)+.05)/(min($la,$lb)+.05)} }
foreach th {dark light} {
    theme::apply $th
    foreach {fg bgk min} {text bg 7 text surface 7 muted bg 4.5 muted surface 4.5 primaryText bg 4.5 primaryText surface 4.5
        success surface 4.5 error surface 4.5 warn surface 4.5 info surface 4.5 onprimary primary 4.5
        c_cmd codebg 4.5 c_kw codebg 4.5 c_var codebg 4.5 c_str codebg 4.5 c_num codebg 4.5 c_cmt codebg 4.5 c_out codebg 4.5 primary bg 3} {
        check "$th: $fg on $bgk >= $min" {[ratio $::T($fg) $::T($bgk)] >= $min}
    }
}
theme::apply dark

puts "== course content"
foreach f [concat [lsort [glob -directory $root/content u*.tcl]] [lsort [glob -nocomplain -directory $root/content x*.tcl]]] { source -encoding utf-8 $f }
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
