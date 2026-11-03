# UI smoke test. Run:  SHOTS=/some/dir xvfb-run -s "-screen 0 420x860x24" wish tests/ui_smoke.tcl [lessonIds...]
# Drives the real UI: plays through lessons by "tapping" through the widgets,
# solves every exercise type, and (optionally) writes screenshots.
set root [file dirname [file dirname [file normalize [info script]]]]
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

# light theme
app::setTheme light; pump; shot 10_profile_light
app::go home; pump; shot 11_home_light
app::setTheme dark

puts "\n[expr {$fails ? "$fails FAILED" : "UI SMOKE PASSED"}]"
file delete -force $tmp
exit [expr {$fails ? 1 : 0}]
