# UI smoke test. Run:  SHOTS=/some/dir xvfb-run -s "-screen 0 420x860x24" wish tests/ui_smoke.tcl [lessonIds...]
# Drives the real UI: plays through lessons by "tapping" through the widgets,
# solves every exercise type, and (optionally) writes screenshots.
set root [file dirname [file dirname [file normalize [info script]]]]
set ::env(LEARNTCL_NOSOUND) 1
set ::LEARNTCL_NO_MAIN 1
set tmp [file join /tmp learn-tcl-ui-[pid]]
file mkdir $tmp
set ::env(LEARNTCL_HOME) $tmp
source $root/main.tcl
set shots [expr {[info exists ::env(SHOTS)] ? $::env(SHOTS) : ""}]
if {$shots ne ""} { file mkdir $shots }
set fails 0
proc shot {name} {
    update idletasks; update
    if {$::shots ne ""} { catch {exec import -window root $::shots/$name.png} }
}
proc fail {msg} { puts "FAIL: $msg"; incr ::fails }
proc pump {} { update idletasks; update }

# ---- boot the app at phone size
wm geometry . 410x840+0+0
update
set ::ui::U [expr {[winfo width .] / 100.0}]
app::init
sandbox::init $store::dir
app::go home
pump
shot 01_home_empty

# ---- solve whatever exercise is on screen
proc solveCurrent {wrongFirst} {
    set e [dict get [lindex $run::S(steps) $run::S(idx)] e]
    set kind [dict get $e kind]
    switch $kind {
        mc - predict {
            set ans [dict get $e ans]
            if {$wrongFirst} { set ans [expr {([dict get $e ans] + 1) % [llength [dict get $e choices]]}] }
            ex::pick $ans
        }
        blank {
            set i 0
            foreach a [dict get $e answers] { ex::bankTap $i; incr i }
            if {$wrongFirst && [llength [dict get $e extra]] && [llength [dict get $e answers]]} {
                # swap: untap first slot and put a wrong chip
                ex::slotTap 0
                ex::bankTap [llength [dict get $e answers]]
            }
        }
        order {
            set n [llength [dict get $e lines]]
            set idx {}
            for {set i 0} {$i < $n} {incr i} { lappend idx $i }
            if {$wrongFirst && $n > 1} { set idx [list {*}[lrange $idx 1 end] 0] }
            foreach i $idx { ex::pick2 $i }
        }
        type {
            $ex::st(entry) delete 0 end
            $ex::st(entry) insert 0 [expr {$wrongFirst ? "zzz" : [lindex [dict get $e accept] 0]}]
            ex::typeChanged
        }
        code {
            $ex::st(text) delete 1.0 end
            $ex::st(text) insert 1.0 [expr {$wrongFirst ? "# nothing" : [dict get $e solution]}]
        }
    }
    return $kind
}

# ---- play a whole lesson through the UI
proc playLesson {id shotPrefix} {
    app::startLesson $id
    pump
    set seenKinds {}
    set guard 0
    set wrongDone 0
    while {$run::S(idx) < $run::S(n) && [incr guard] < 200} {
        set step [lindex $run::S(steps) $run::S(idx)]
        if {[dict get $step t] eq "page"} {
            if {$shotPrefix ne "" && $run::S(idx) == 0} { shot ${shotPrefix}_page }
            run::onCheckTap
            pump
            continue
        }
        set wrong [expr {!$wrongDone && !$run::S(idx) % 2 == 0 && 0}]
        # make the *first* exercise of each lesson wrong once to test the retry queue
        set first [expr {![dict get $step warm] && ![dict get $step retry] && !$wrongDone}]
        set kind [solveCurrent $first]
        if {$first} { set wrongDone 1 }
        pump
        if {$shotPrefix ne "" && [lsearch $seenKinds $kind] < 0} { shot ${shotPrefix}_${kind}_q }
        if {!$run::S(ready)} { fail "$id: exercise not ready after answering ($kind)"; run::setReady 1 }
        run::onCheckTap   ;# Check
        pump
        set bd $::ui::btn($run::S(btn))
        if {[dict get $bd text] ne "Continue" || [dict get $bd disabled]} { fail "$id: after Check the button should read Continue (got [dict get $bd text], disabled=[dict get $bd disabled])" }
        if {$shotPrefix ne "" && [lsearch $seenKinds $kind] < 0} { shot ${shotPrefix}_${kind}_fb }
        lappend seenKinds $kind
        run::onCheckTap   ;# Continue
        pump
    }
    if {$guard >= 200} { fail "$id: runaway" }
    return $seenKinds
}

set ids [expr {$argc ? $argv : [content::ids]}]
set k 0
foreach id $ids {
    set prefix [expr {$id in {1.1 5.1 7.3 10.2 11.7} ? "L$id" : ""}]
    if {[catch {set kinds [playLesson $id $prefix]} err opts]} {
        fail "$id: [dict get $opts -errorinfo]"
        break
    }
    if {![store::lessonDone $id]} { fail "$id: not marked complete" }
    if {$id eq [lindex $ids 0]} { shot 02_result }
    pump
    puts "lesson $id ok ([join $kinds ,])"
}

# ---- other screens
app::go home;     pump; shot 03_home
app::go practice; pump; shot 04_practice
app::go play;     pump
$::app::pgText delete 1.0 end
$::app::pgText insert 1.0 "set r 6\nputs \"Area: \[expr {3.14159 * \$r ** 2}\]\"\n"
app::playRun; pump; shot 05_play
app::go profile;  pump; shot 06_profile

# flashcard review
if {[llength [srs::dueList]] == 0} { fail "no cards due after lessons" } else {
    app::startReview; pump; shot 07_card_front
    review::reveal; pump; shot 08_card_back
    set guard 0
    while {$review::S(queue) ne "" && [incr guard] < 300} { review::grade 2; pump }
}
app::go practice; pump
app::startPractice 6 {mc predict type blank order}; pump
set guard 0
while {$run::S(idx) < $run::S(n) && [incr guard] < 100} {
    set st [lindex $run::S(steps) $run::S(idx)]
    solveCurrent 0; pump; run::onCheckTap; pump; run::onCheckTap; pump
}
shot 09_practice_done

# ---- regression: the 'stuck on Check' bug (order exercise, tapped through the screen overlay)
store::reset
app::go home; pump
app::startLesson 1.1; pump
proc tapAt {F x y} {
    event generate $F <ButtonPress-1> -x $x -y $y; update
    event generate $F <ButtonRelease-1> -x $x -y $y; update
    after 60 {set ::tw 1}; vwait ::tw; update
}
while {1} {
    set step [lindex $run::S(steps) $run::S(idx)]
    if {[dict get $step t] eq "ex" && [dict get [dict get $step e] kind] eq "order" && ![dict get $step warm]} break
    if {[dict get $step t] eq "page"} { run::onCheckTap; pump; continue }
    solveCurrent 0; pump; run::onCheckTap; pump; run::onCheckTap; pump
}
foreach want [lsearch -all -inline [dict get [dict get $step e] lines] *] {
    set target ""
    foreach h $flat::hot(.v.s) { lassign $h x1 y1 x2 y2 kind w a
        if {$kind eq "btn" && [string match *.bank.* $w] && [dict get $::ui::btn($w) text] eq $want} { set target $h; break } }
    if {$target eq ""} { fail "order line '$want' not tappable"; break }
    lassign $target x1 y1 x2 y2
    tapAt .v.s.flat [expr {($x1+$x2)/2}] [expr {($y1+$y2)/2}]
}
set b $run::S(btn)
tapAt $b 50 20
after 300 {set ::tw2 1}; vwait ::tw2; update
set bd $::ui::btn($b)
if {$run::S(phase) ne "checked" || [dict get $bd text] ne "Continue" || [dict get $bd disabled]} {
    fail "stuck-button regression: phase=$run::S(phase) button=[dict get $bd text] disabled=[dict get $bd disabled]"
}
puts "order exercise via touch overlay: Check -> Continue ok"

# ---- sound / haptics settings
app::go profile; pump
app::setSound 0; pump
if {[store::setting sound 1] != 0} { fail "sound setting not saved" }
app::setSound 1; app::setHaptics 0; app::setHaptics 1; pump
puts "sound settings ok"

# ---- unit test / test-out on a fresh profile
store::reset
app::go home; pump
app::startUnitTest 2; pump
set guard 0
while {$run::S(idx) < $run::S(n) && [incr guard] < 100} {
    solveCurrent 0; pump; run::onCheckTap; pump; run::onCheckTap; pump
}
foreach lid [content::lessonsOf 2] { if {![store::lessonDone $lid]} { fail "unit test pass did not complete $lid" } }
if {[store::lessonDone 3.1]} { fail "unit test leaked into unit 3" }
shot 12_unit_test_passed
# a failing unit test marks nothing
app::startUnitTest 3; pump
set guard 0
while {$run::S(idx) < $run::S(n) && [incr guard] < 100} {
    set step [lindex $run::S(steps) $run::S(idx)]
    if {[dict get $step retry]} { solveCurrent 0 } else { solveCurrent 1 }
    pump; run::onCheckTap; pump; run::onCheckTap; pump
}
if {[store::lessonDone 3.1]} { fail "failed unit test must not complete lessons" }
puts "unit test pass/fail flows ok"

# ---- back button
app::startLesson 1.1; pump
app::back; pump
if {![winfo exists .dlg]} { fail "back during a lesson should ask to leave" }
app::back; pump
if {[winfo exists .dlg]} { fail "second back should close the dialog" }
app::go profile; pump
app::back; pump
if {$app::tab ne "home"} { fail "back from a tab should go home" }

# ---- text size + wide (tablet/landscape) layout
foreach v {0.9 1.15 1.3 1.0} { app::setScale $v; pump }
app::go home; pump
wm geometry . 1000x600+0+0; update; pump
set cw [winfo width .v]
if {$cw > int(112 * $::ui::U) + 2} { fail "wide window not capped: $cw" }
shot 13_wide
wm geometry . 410x840+0+0; update; pump
puts "back button / text size / wide layout ok"

# light theme
app::setTheme light; pump; shot 10_profile_light
app::go home; pump; shot 11_home_light
app::setTheme dark

puts "\n[expr {$fails ? "$fails FAILED" : "UI SMOKE PASSED"}]"
file delete -force $tmp
exit [expr {$fails ? 1 : 0}]
