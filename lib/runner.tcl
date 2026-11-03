# runner.tcl - the lesson / practice session engine.
namespace eval run {
    variable S
    array set S {}
    variable praise {"Correct!" "Nice one!" "Exactly!" "Well done!" "That's it!" "Spot on!"}
    variable oops {"Not quite" "Close, but no" "Almost" "Let's look again"}
}

# opts: -title T -steps LIST -lesson ID -mode lesson|practice -onfinish SCRIPT
proc run::start {args} {
    variable S
    array unset S
    array set S [list title "" steps {} lesson "" mode practice onfinish {} idx 0 \
        unit 0 firstOK 0 attempted 0 xp 0 ready 0 phase answering warmOK 0 warmN 0 missed {} bar ""]
    array set S $args
    set S(n) [llength $S(steps)]
    set S(startTime) [clock seconds]
    buildChrome
    showStep
}

proc run::buildChrome {} {
    variable S
    app::clear
    set v $::app::view
    frame $v.top -bg $::T(bg)
    pack $v.top -fill x -padx [ui::px 4] -pady [list [ui::px 3] [ui::px 1]]
    canvas $v.top.x -width [ui::px 9] -height [ui::px 9] -highlightthickness 0 -bg $::T(bg)
    ui::icon $v.top.x close [ui::px 4.5] [ui::px 4.5] [ui::px 6] $::T(muted)
    bind $v.top.x <ButtonRelease-1> {if {!$::ui::drag(moved)} run::quit}
    pack $v.top.x -side left
    ui::progress $v.top.p 0
    pack $v.top.p -side left -fill x -expand 1 -padx [ui::px 3]
    set S(bar) $v.top.p
    frame $v.bot -bg $::T(bg)
    pack $v.bot -side bottom -fill x -padx [ui::px 4] -pady [ui::px 3]
    ui::button $v.bot.b "Continue" run::onCheckTap -height [ui::px 13.5]
    pack $v.bot.b -fill x
    set S(btn) $v.bot.b
    set body [ui::scroll $v.s]
    pack $v.s -fill both -expand 1
    set S(scroll) $v.s.c
    set S(body) $body
}

proc run::quit {} {
    ui::confirm "Leave this session?" "Your progress in this session will be lost." "Leave" {app::go home}
}

proc run::setReady {r} {
    variable S
    if {$S(phase) ne "answering"} return
    set S(ready) $r
    ui::btnSet $S(btn) -disabled [expr {!$r}] -text "Check"
}

proc run::clearBody {} {
    variable S
    foreach k [winfo children $S(body)] { destroy $k }
    $S(scroll) yview moveto 0
}

proc run::showStep {} {
    variable S
    clearBody
    set body $S(body)
    ui::progress $S(bar) [expr {double($S(idx)) / max(1, $S(n))}]
    if {$S(idx) >= $S(n)} { finish; return }
    set step [lindex $S(steps) $S(idx)]
    set pad [ui::px 4]
    frame $body.in -bg $::T(bg)
    pack $body.in -fill x -padx $pad -pady [list [ui::px 3] [ui::px 8]]
    set b $body.in
    if {[dict get $step t] eq "page"} {
        set S(phase) page
        showPage $b $step
        set last [expr {$S(idx) + 1 >= $S(n) || [dict get [lindex $S(steps) [expr {$S(idx)+1}]] t] eq "ex"}]
        ui::btnSet $S(btn) -disabled 0 -text [expr {$last ? "Start practice" : "Continue"}] -style primary
    } else {
        set S(phase) answering
        set S(ready) 0
        set e [dict get $step e]
        if {[dict get $step warm]} {
            label $b.warm -text "WARM-UP  -  from an earlier lesson" -font f.smallb -fg $::T(warn) -bg $::T(bg) -anchor w
            pack $b.warm -fill x -pady [list 0 [ui::px 1]]
        } elseif {[dict get $step retry]} {
            label $b.warm -text "TRY AGAIN" -font f.smallb -fg $::T(warn) -bg $::T(bg) -anchor w
            pack $b.warm -fill x -pady [list 0 [ui::px 1]]
        }
        ex::build $b $e
        # exercises may already be "ready" (e.g. write-code); honour that
        ui::btnSet $S(btn) -disabled [expr {!$S(ready)}] -text "Check" -style primary
    }
    ui::dragify $S(body)
    update idletasks
    ui::_scrollRegion $S(scroll)
    flat::freeze [winfo parent $S(scroll)]
}

proc run::showPage {b step} {
    variable S
    set lesson [expr {$S(lesson) ne "" ? "Lesson $S(lesson)" : ""}]
    label $b.k -text [string toupper $lesson] -font f.smallb -fg $::T(muted) -bg $::T(bg) -anchor w
    label $b.h -text [dict get $step head] -font f.h1 -fg $::T(text) -bg $::T(bg) -anchor w -justify left \
        -wraplength [expr {[winfo width .] - 2 * [ui::px 4]}]
    pack $b.k -fill x
    pack $b.h -fill x -pady [list [ui::px .5] [ui::px 2.5]]
    set n 0
    foreach {type content} [dict get $step body] {
        incr n
        set w $b.b$n
        switch $type {
            p    { ui::rich $w $content }
            h    { label $w -text $content -font f.h2 -fg $::T(text) -bg $::T(bg) -anchor w }
            code - show { ui::code $w $content }
            out  { ui::output $w $content }
            tip  { callout $w TIP $content $::T(info) }
            warn { callout $w "WATCH OUT" $content $::T(warn) }
        }
        pack $w -fill x -pady [list 0 [ui::px 2.6]]
    }
}

proc run::callout {w title text color} {
    set fill [ui::mix $::T(bg) $color .13]
    set in [ui::card $w -fill $fill -line [ui::mix $::T(bg) $color .5] -pad [ui::px 3.2] -r [ui::px 3]]
    label $in.t -text $title -font f.smallb -fg $color -bg $fill -anchor w
    pack $in.t -fill x
    ui::rich $in.r $text -bg $fill
    pack $in.r -fill x -pady [list [ui::px .8] 0]
}

# ---- the Check / Continue button ---------------------------------------------------------------
# Make the bottom button match the session state, whatever happened before.
proc run::syncButton {} {
    variable S
    if {![info exists S(btn)] || ![winfo exists $S(btn)] || ![info exists S(phase)]} return
    switch $S(phase) {
        page     { ui::btnSet $S(btn) -disabled 0 -style primary }
        answering { ui::btnSet $S(btn) -disabled [expr {!$S(ready)}] -text "Check" -style primary }
        checked  { ui::btnSet $S(btn) -disabled 0 -text "Continue" -style [expr {[info exists S(lastOK)] && $S(lastOK) ? "success" : "danger"}] }
    }
}

proc run::onCheckTap {} {
    variable S
    switch $S(phase) {
        page      { incr S(idx); showStep }
        answering { if {$S(ready)} { doCheck } }
        checked   { incr S(idx); showStep }
    }
}

proc run::doCheck {} {
    variable S
    variable praise
    variable oops
    set step [lindex $S(steps) $S(idx)]
    set e [dict get $step e]
    set warm [dict get $step warm]
    set retry [dict get $step retry]
    set res [ex::check]
    set ok [dict get $res ok]
    set S(phase) checked
    set S(lastOK) $ok
    sfx::play [expr {$ok ? "correct" : "wrong"}]
    set eid [dict get $e id]
    # --- scoring
    set gain 0
    if {$ok} {
        if {$warm} { set gain 5; incr S(warmOK) } elseif {$retry} { set gain 4 } else { set gain 10; incr S(firstOK) }
    }
    if {!$warm && !$retry} { incr S(attempted) }
    if {$warm} { incr S(warmN) }
    incr S(xp) $gain
    store::recordEx $eid $ok
    if {!$ok} {
        lappend S(missed) $eid
        set cc [content::cardFromEx $e]
        if {$cc ne ""} {
            set cid [dict get $cc id]
            if {[srs::add $cid]} {}
            # a miss makes the card due again right away
            dict set ::state cards $cid due [util::today]
        }
        if {!$warm && !$retry} {
            lappend S(steps) [dict create t ex e $e warm 0 retry 1]
            incr S(n)
        }
    }
    # --- feedback card
    set color [expr {$ok ? $::T(success) : $::T(error)}]
    set fill [ui::mix $::T(bg) $color .14]
    set b $S(body).in
    set f [ui::card $b.fb -fill $fill -line [ui::mix $::T(bg) $color .55] -pad [ui::px 3.4] -r [ui::px 3.4]]
    pack $b.fb -fill x -pady [list [ui::px 3.5] [ui::px 2]]
    frame $f.h -bg $fill
    pack $f.h -fill x
    canvas $f.h.i -width [ui::px 7.5] -height [ui::px 7.5] -highlightthickness 0 -bg $fill
    ui::icon $f.h.i [expr {$ok ? "check" : "cross"}] [ui::px 3.75] [ui::px 3.75] [ui::px 6] $color
    pack $f.h.i -side left
    set title [expr {$ok ? [lindex $praise [expr {int(rand()*[llength $praise])}]] : [lindex $oops [expr {int(rand()*[llength $oops])}]]}]
    label $f.h.t -text $title -font f.h2 -fg $color -bg $fill
    pack $f.h.t -side left -padx [ui::px 1.5]
    if {$gain > 0} {
        label $f.h.x -text "+$gain XP" -font f.smallb -fg $color -bg $fill
        pack $f.h.x -side right
    }
    set n 0
    if {[dict exists $res detail] && [dict get $res detail] ne ""} {
        ui::rich $f.d [dict get $res detail] -bg $fill
        pack $f.d -fill x -pady [list [ui::px 1.5] 0]
    }
    if {[dict exists $res showcode] && [dict get $res showcode] ne ""} {
        ui::code $f.c [dict get $res showcode] -outer $fill
        pack $f.c -fill x -pady [list [ui::px 1.5] 0]
    }
    if {[dict exists $res showout] && [dict get $res showout] ne "" && [dict exists $res showcode] && [dict get $res showcode] ne ""} {
        ui::output $f.o [dict get $res showout] -outer $fill
        pack $f.o -fill x -pady [list [ui::px 1.5] 0]
    }
    if {[dict exists $e why]} {
        ui::rich $f.w [dict get $e why] -bg $fill
        pack $f.w -fill x -pady [list [ui::px 1.5] 0]
    }
    ui::btnSet $S(btn) -disabled 0 -text "Continue" -style [expr {$ok ? "success" : "danger"}]
    ui::dragify $S(body)
    update idletasks
    ui::_scrollRegion $S(scroll)
    $S(scroll) yview moveto 1
    set sc [winfo parent $S(scroll)]
    if {[winfo exists $sc.flat]} { flat::refresh $sc; catch {$sc.flat yview moveto 1} }
    if {$S(mode) eq "lesson" || $S(mode) eq "practice"} { store::save }
    syncButton
    after 150 run::syncButton
}

# ---- finishing ----------------------------------------------------------------------------------------
proc run::finish {} {
    variable S
    set n $S(attempted)
    set acc [expr {$n > 0 ? double($S(firstOK)) / $n : 1.0}]
    set stars [expr {$acc >= 0.9 ? 3 : ($acc >= 0.7 ? 2 : 1)}]
    set bonus 0
    set newCards 0
    set first 0
    if {$S(mode) eq "lesson"} {
        set id $S(lesson)
        set first [expr {![store::lessonDone $id]}]
        set bonus [expr {$first ? 20 : 8}]
        set prev [store::lessonStars $id]
        dict set ::state lessons $id [dict create stars [expr {max($prev, $stars)}] day [util::today]]
        foreach c [dict get [content::get $id] cards] {
            if {[srs::add [dict get $c id]]} { incr newCards }
        }
    }
    set passed 0
    if {$S(mode) eq "unittest"} {
        set passed [expr {$n >= 4 && $acc >= 0.8}]
        if {$passed} {
            set bonus 30
            foreach lid [content::lessonsOf $S(unit)] {
                if {![store::lessonDone $lid]} {
                    dict set ::state lessons $lid [dict create stars 2 day [util::today]]
                }
                foreach c [dict get [content::get $lid] cards] { srs::add [dict get $c id] }
            }
        }
    }
    set total [expr {$S(xp) + $bonus}]
    set lvl0 [store::level]
    set goal [store::setting goal 50]
    set goalDone0 [expr {[store::xpToday] >= $goal}]
    if {$total > 0} { store::addXP $total } else { store::touchStreak }
    # celebration sounds
    switch $S(mode) {
        lesson   { sfx::play [expr {$stars == 3 ? "perfect" : "complete"}] }
        unittest { sfx::play [expr {$passed ? ($acc >= 1.0 ? "perfect" : "complete") : "fail"}] }
        default  { sfx::play [expr {$acc >= 0.7 ? "complete" : "good"}] }
    }
    set later 750
    if {[store::level] > $lvl0} { after $later [list sfx::play levelup]; incr later 900 }
    if {!$goalDone0 && [store::xpToday] >= $goal} { after $later [list sfx::play goal] }
    store::save
    set summary [dict create mode $S(mode) stars $stars acc $acc xp $total bonus $bonus first $first \
        newCards $newCards passed $passed attempted $n correct $S(firstOK) missed [llength $S(missed)] \
        lesson $S(lesson) seconds [expr {[clock seconds] - $S(startTime)}]]
    if {$S(onfinish) ne ""} { uplevel #0 [list {*}$S(onfinish) $summary] }
}

# ---- building step lists -------------------------------------------------------------------------------------
proc run::lessonSteps {id} {
    set l [content::get $id]
    set steps {}
    foreach p [dict get $l pages] { lappend steps [dict create t page head [dict get $p head] body [dict get $p body]] }
    # warm-up: 2 questions from earlier finished lessons (spaced + interleaved)
    foreach e [pick 2 -before $id -kinds {mc predict type}] {
        lappend steps [dict create t ex e $e warm 1 retry 0]
    }
    set ex [dict get $l ex]
    foreach e $ex { lappend steps [dict create t ex e $e warm 0 retry 0] }
    return $steps
}

# Pick n exercises from finished lessons, favouring ones answered wrongly.
proc run::pick {n args} {
    set before ""; set kinds {mc predict type blank order}; set only {}
    foreach {k v} $args {
        switch $k { -before {set before $v} -kinds {set kinds $v} -only {set only $v} }
    }
    set pool {}
    foreach id [content::ids] {
        if {$id eq $before} break
        if {![store::lessonDone $id]} continue
        foreach e [dict get [content::get $id] ex] {
            if {[dict get $e kind] ni $kinds} continue
            lassign [store::exStat [dict get $e id]] r w
            lappend pool [list $e [expr {(1.0 + 2.5 * $w) / (1.0 + 0.5 * $r)}]]
        }
    }
    set out {}
    for {set i 0} {$i < $n && [llength $pool]} {incr i} {
        set tot 0.0
        foreach p $pool { set tot [expr {$tot + [lindex $p 1]}] }
        set r [expr {rand() * $tot}]
        set acc 0.0; set pickIdx 0; set j 0
        foreach p $pool {
            set acc [expr {$acc + [lindex $p 1]}]
            if {$acc >= $r} { set pickIdx $j; break }
            incr j
        }
        lappend out [lindex $pool $pickIdx 0]
        set pool [lreplace $pool $pickIdx $pickIdx]
    }
    return $out
}

# A unit test: n questions drawn from every lesson in the unit.
proc run::unitSteps {unit n} {
    set pool {}
    foreach lid [content::lessonsOf $unit] {
        foreach e [dict get [content::get $lid] ex] {
            if {[dict get $e kind] in {mc predict type blank order}} { lappend pool $e }
        }
    }
    set steps {}
    foreach e [lrange [util::shuffle $pool] 0 [expr {$n - 1}]] {
        lappend steps [dict create t ex e $e warm 0 retry 0]
    }
    return $steps
}

proc run::practiceSteps {n kinds} {
    set steps {}
    foreach e [pick $n -kinds $kinds] { lappend steps [dict create t ex e $e warm 0 retry 0] }
    return $steps
}
