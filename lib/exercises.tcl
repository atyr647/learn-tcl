# exercises.tcl - the six exercise types. Each is built into a body frame.
# Protocol with the runner:
#   ex::build body exdict   -> draws the question, calls run::setReady 0/1 as the learner interacts
#   ex::check               -> returns dict {ok 0/1 detail markdown}; also colours the UI
namespace eval ex {
    variable st
    array set st {}
    variable caption
    array set caption {
        mc "Choose the best answer"  predict "What does this code print?"
        blank "Fill in the blanks"   order "Put the lines in order"
        type "Type your answer"      code "Write the code"
    }
}

proc ex::build {body e} {
    variable st
    variable caption
    array unset st
    set st(e) $e
    set st(body) $body
    set kind [dict get $e kind]
    set st(kind) $kind
    label $body.cap -text [string toupper $caption($kind)] -font f.smallb -fg $::T(primaryText) -bg $::T(bg) -anchor w
    pack $body.cap -fill x -pady [list 0 [ui::px 1.5]]
    switch $kind {
        mc - predict { buildChoice $body $e }
        blank        { buildBlank $body $e }
        order        { buildOrder $body $e }
        type         { buildType $body $e }
        code         { buildCode $body $e }
    }
}

proc ex::check {} {
    variable st
    switch $st(kind) {
        mc - predict { return [checkChoice] }
        blank        { return [checkBlank] }
        order        { return [checkOrder] }
        type         { return [checkType] }
        code         { return [checkCode] }
    }
}

# ---- multiple choice & predict-the-output -----------------------------------------
proc ex::buildChoice {body e} {
    variable st
    set kind [dict get $e kind]
    if {$kind eq "predict"} {
        ui::rich $body.q "What will this program print?" -font f.bodyb
        pack $body.q -fill x -pady [list 0 [ui::px 2]]
        ui::code $body.code [dict get $e code]
        pack $body.code -fill x -pady [list 0 [ui::px 3]]
    } else {
        ui::rich $body.q [dict get $e q] -font f.bodyb
        pack $body.q -fill x -pady [list 0 [ui::px 2]]
        if {[dict exists $e code]} {
            ui::code $body.code [dict get $e code]
            pack $body.code -fill x -pady [list 0 [ui::px 3]]
        }
    }
    set ch [dict get $e choices]
    set idx {}
    for {set i 0} {$i < [llength $ch]} {incr i} { lappend idx $i }
    set st(sel) -1
    set st(opts) {}
    foreach i [util::shuffle $idx] {
        set w $body.o$i
        set font [expr {$kind eq "predict" || [dict exists $e mono] ? "f.mono" : "f.body"}]
        ui::option $w [lindex $ch $i] [list ex::pick $i] -font $font
        pack $w -fill x -pady [ui::px 1]
        lappend st(opts) $i $w
    }
    run::setReady 0
}
proc ex::pick {i} {
    variable st
    if {[info exists st(done)]} return
    foreach {k w} $st(opts) { ui::optSet $w [expr {$k == $i ? "selected" : "normal"}] }
    set st(sel) $i
    run::setReady 1
}
proc ex::checkChoice {} {
    variable st
    set ans [dict get $st(e) ans]
    set ok [expr {$st(sel) == $ans}]
    set st(done) 1
    foreach {k w} $st(opts) {
        if {$k == $ans} { ui::optSet $w correct } elseif {$k == $st(sel)} { ui::optSet $w wrong } else { ui::optSet $w disabled }
    }
    dict create ok $ok detail ""
}

# ---- fill in the blanks ---------------------------------------------------------------
proc ex::buildBlank {body e} {
    variable st
    ui::rich $body.q [expr {[dict exists $e q] ? [dict get $e q] : "Tap words to complete the program."}] -font f.bodyb
    pack $body.q -fill x -pady [list 0 [ui::px 2]]
    set st(parts) [split [string map [list ___ \x01] [dict get $e code]] \x01]
    set n [expr {[llength $st(parts)] - 1}]
    set bank [concat [dict get $e answers] [dict get $e extra]]
    set st(words) $bank
    set st(slot) [lrepeat $n -1]     ;# slot -> chip index, or -1
    set st(width) 4
    foreach w $bank { set st(width) [expr {max($st(width), [string length $w])}] }
    frame $body.cb -bg $::T(bg)
    pack $body.cb -fill x -pady [list 0 [ui::px 3]]
    set st(cb) $body.cb
    ui::flow $body.bank
    pack $body.bank -fill x
    set st(bankw) $body.bank
    set st(chips) {}
    set order {}
    for {set i 0} {$i < [llength $bank]} {incr i} { lappend order $i }
    foreach i [util::shuffle $order] {
        set c $body.bank.c$i
        ui::option $c [lindex $bank $i] [list ex::bankTap $i] -font f.mono -fit 1 -align center
        ui::flowAdd $body.bank $c
        lappend st(chips) $i $c
    }
    renderBlank
    run::setReady 0
}
proc ex::renderBlank {} {
    variable st
    foreach k [winfo children $st(cb)] { destroy $k }
    set text ""
    set marks {}
    set n [llength $st(slot)]
    for {set i 0} {$i < $n} {incr i} {
        append text [lindex $st(parts) $i]
        set ci [lindex $st(slot) $i]
        set word [expr {$ci < 0 ? [string repeat " " [expr {$st(width) + 1}]] : [lindex $st(words) $ci]}]
        if {$ci >= 0} { set word " $word " }
        lappend marks [string length $text] [string length $word] $ci $i
        append text $word
    }
    append text [lindex $st(parts) $n]
    ui::code $st(cb).c $text
    pack $st(cb).c -fill x
    set t $st(cb).c.f.b.t
    $t tag configure fill -background [ui::mix $::T(codebg) $::T(primary) .5] -foreground $::T(text)
    $t tag configure empty -background [ui::mix $::T(codebg) $::T(muted) .35] -foreground $::T(muted)
    foreach {start len ci i} $marks {
        set a "1.0 + $start chars"; set b "1.0 + [expr {$start + $len}] chars"
        foreach tg {cmd kw var str num punct cmt} { $t tag remove $tg $a $b }
        $t tag add [expr {$ci < 0 ? "empty" : "fill"}] $a $b
        if {$ci >= 0} {
            $t tag add slot$i $a $b
            $t tag bind slot$i <ButtonRelease-1> [list ex::slotTap $i]
        }
    }
    $t tag raise fill
    $t tag raise empty
    ui::dragify $st(cb)
    flat::dirtyOf $st(body)
}
proc ex::bankTap {ci} {
    variable st
    if {[info exists st(done)]} return
    set pos [lsearch -exact $st(slot) -1]
    if {$pos < 0} return
    lset st(slot) $pos $ci
    ui::optSet [dict get $st(chips) $ci] disabled
    place forget [dict get $st(chips) $ci]
    renderBlank
    run::setReady [expr {[lsearch -exact $st(slot) -1] < 0}]
}
proc ex::slotTap {i} {
    variable st
    if {[info exists st(done)] || $::ui::drag(moved)} return
    set ci [lindex $st(slot) $i]
    if {$ci < 0} return
    lset st(slot) $i -1
    set c [dict get $st(chips) $ci]
    ui::optSet $c normal
    ui::_flowLayout $st(bankw)
    renderBlank
    run::setReady 0
}
proc ex::checkBlank {} {
    variable st
    set e $st(e)
    set ans [dict get $e answers]
    set ok 1
    for {set i 0} {$i < [llength $ans]} {incr i} {
        if {[lindex $st(words) [lindex $st(slot) $i]] ne [lindex $ans $i]} { set ok 0 }
    }
    set st(done) 1
    set detail ""
    if {!$ok} { set detail "Correct program:" }
    dict create ok $ok detail $detail showcode [expr {$ok ? "" : [content::fill [dict get $e code] $ans]}] \
        showout [dict get $e out]
}

# ---- order the lines --------------------------------------------------------------------------
proc ex::buildOrder {body e} {
    variable st
    ui::rich $body.q [expr {[dict exists $e q] ? [dict get $e q] : "Tap the lines in the order they should run."}] -font f.bodyb
    pack $body.q -fill x -pady [list 0 [ui::px 2]]
    set st(lines) [dict get $e lines]
    set st(picked) {}
    label $body.al -text "YOUR PROGRAM" -font f.smallb -fg $::T(muted) -bg $::T(bg) -anchor w
    pack $body.al -fill x
    frame $body.ans -bg $::T(bg)
    pack $body.ans -fill x -pady [list [ui::px 1] [ui::px 3]]
    label $body.bl -text "LINES" -font f.smallb -fg $::T(muted) -bg $::T(bg) -anchor w
    pack $body.bl -fill x
    frame $body.bank -bg $::T(bg)
    pack $body.bank -fill x -pady [ui::px 1]
    set idx {}
    for {set i 0} {$i < [llength $st(lines)]} {incr i} { lappend idx $i }
    set st(shuf) [util::shuffle $idx]
    renderOrder
    run::setReady 0
}
proc ex::renderOrder {} {
    variable st
    set body $st(body)
    foreach k [winfo children $body.ans] { destroy $k }
    foreach k [winfo children $body.bank] { destroy $k }
    set n 0
    foreach i $st(picked) {
        ui::option $body.ans.r$n [lindex $st(lines) $i] [list ex::unpick $i] -font f.mono
        pack $body.ans.r$n -fill x -pady [ui::px .8]
        incr n
    }
    if {!$n} {
        canvas $body.ans.empty -height [ui::px 11] -highlightthickness 0 -bg $::T(bg)
        bind $body.ans.empty <Configure> {ex::_orderEmpty %W %w %h}
        pack $body.ans.empty -fill x
    }
    foreach i $st(shuf) {
        if {$i in $st(picked)} continue
        ui::option $body.bank.r$i [lindex $st(lines) $i] [list ex::pick2 $i] -font f.mono
        pack $body.bank.r$i -fill x -pady [ui::px .8]
    }
    # a frame that lost all its children keeps its old size - reset it
    if {[llength [winfo children $body.bank]] == 0} { $body.bank configure -width 1 -height 1 }
    ui::dragify $body
    flat::dirtyOf $body
}
proc ex::_orderEmpty {w W H} {
    $w delete all
    ui::rrect $w 2 2 [expr {$W-2}] [expr {$H-2}] [ui::px 3] -fill "" -outline $::T(border) -width 2 -dash {6 5}
    $w create text [expr {$W/2}] [expr {$H/2}] -text "Tap lines below" -fill $::T(muted) -font f.small
}
proc ex::pick2 {i} {
    variable st
    if {[info exists st(done)]} return
    lappend st(picked) $i
    renderOrder
    run::setReady [expr {[llength $st(picked)] == [llength $st(lines)]}]
}
proc ex::unpick {i} {
    variable st
    if {[info exists st(done)]} return
    set st(picked) [lsearch -all -inline -not -exact $st(picked) $i]
    renderOrder
    run::setReady 0
}
proc ex::checkOrder {} {
    variable st
    set st(done) 1
    set ok 1
    set n 0
    foreach i $st(picked) {
        set good [expr {$i == $n}]
        if {!$good} { set ok 0 }
        ui::optSet $st(body).ans.r$n [expr {$good ? "correct" : "wrong"}]
        incr n
    }
    set e $st(e)
    dict create ok $ok detail [expr {$ok ? "" : "Correct order:"}] \
        showcode [expr {$ok ? "" : [join $st(lines) \n]}] showout [dict get $e out]
}

# ---- typed answer -----------------------------------------------------------------------------------
proc ex::buildType {body e} {
    variable st
    ui::rich $body.q [dict get $e q] -font f.bodyb
    pack $body.q -fill x -pady [list 0 [ui::px 2]]
    if {[dict exists $e code]} {
        ui::code $body.code [dict get $e code]
        pack $body.code -fill x -pady [list 0 [ui::px 3]]
    }
    frame $body.eb -bg $::T(border)
    entry $body.eb.e -font f.mono -bg $::T(codebg) -fg $::T(text) -insertbackground $::T(primary) \
        -relief flat -bd 0 -highlightthickness 0 -insertwidth [ui::px .6] -justify left \
        -readonlybackground $::T(codebg) -disabledbackground $::T(codebg)
    pack $body.eb.e -fill x -padx 1 -pady 1 -ipady [ui::px 3]
    pack $body.eb -fill x -pady [ui::px 1]
    set st(entry) $body.eb.e
    bind $st(entry) <KeyRelease> {ex::typeChanged}
    bind $st(entry) <Return> {run::onCheckTap}
    bind $st(entry) <FocusIn> {catch {sdltk textinput 1}}
    if {[dict exists $e hint]} {
        ui::rich $body.h "Hint: [dict get $e hint]" -fg $::T(muted) -font f.small
        pack $body.h -fill x -pady [ui::px 2]
    }
    run::setReady 0
    focus $st(entry)
}
proc ex::typeChanged {} {
    variable st
    run::setReady [expr {[string trim [$st(entry) get]] ne ""}]
}
proc ex::checkType {} {
    variable st
    set given [util::norm [$st(entry) get]]
    set ok 0
    # forgiving: ignore case, a trailing semicolon and surrounding quotes/backticks
    set given [string trim [string trimright $given ";"] "`\"' "]
    foreach a [dict get $st(e) accept] {
        if {[string equal -nocase $given [string trim [util::norm $a] "`\"' "]]} { set ok 1 }
    }
    set st(done) 1
    $st(entry) configure -state readonly
    $st(entry) configure -fg [expr {$ok ? $::T(success) : $::T(error)}]
    dict create ok $ok detail [expr {$ok ? "" : "Answer: `[lindex [dict get $st(e) accept] 0]`"}]
}

# ---- write the code -----------------------------------------------------------------------------------
proc ex::buildCode {body e} {
    variable st
    ui::rich $body.q [dict get $e prompt] -font f.bodyb
    pack $body.q -fill x -pady [list 0 [ui::px 2]]
    ui::editor $body.ed [dict get $e starter] -height 7
    pack $body.ed -fill x
    set st(text) $body.ed.t
    ui::symbols $body.sym $st(text)
    pack $body.sym -fill x -pady [ui::px 2]
    ui::button $body.run "Run" ex::runCode -style secondary -height [ui::px 10.5]
    pack $body.run -fill x -pady [ui::px 1]
    frame $body.out -bg $::T(bg)
    pack $body.out -fill x -pady [ui::px 1]
    set st(outf) $body.out
    run::setReady 1
}
proc ex::runCode {} {
    variable st
    set r [sandbox::run [$st(text) get 1.0 end-1c]]
    foreach k [winfo children $st(outf)] { destroy $k }
    ui::output $st(outf).o [sandbox::display $r]
    pack $st(outf).o -fill x
    ui::dragify $st(outf)
}
proc ex::checkCode {} {
    variable st
    set e $st(e)
    set code [$st(text) get 1.0 end-1c]
    set tests [dict get $e tests]
    set thens {}
    foreach {s x} $tests { lappend thens $s }
    set r [sandbox::run $code -then $thens]
    set st(done) 1
    if {![dict get $r ok]} {
        return [dict create ok 0 detail "Your code stopped with an error:\n`[dict get $r err]`" showcode [dict get $e solution]]
    }
    set ok 1
    set detail ""
    set i 0
    foreach {s x} $tests {
        set got [lindex [dict get $r thens] $i]
        if {$got ne $x && $ok} {
            set ok 0
            set detail "I ran `$s` and expected `$x` but got `$got`."
        }
        incr i
    }
    if {!$ok} {
        dict create ok 0 detail "$detail\nOne possible solution:" showcode [dict get $e solution]
    } else {
        dict create ok 1 detail ""
    }
}
