# screens.tcl - app shell and all top-level screens.
namespace eval app {
    variable view .v
    variable tab home
}

proc app::init {} {
    variable view
    store::init
    theme::apply [store::setting theme dark]
    . configure -bg $::T(bg)
    wm title . "Learn Tcl"
    frame $view -bg $::T(bg)
    place $view -relx .5 -y 0 -anchor n -relwidth 1 -relheight 1
    set ui::fscale [store::setting textScale 1.0]
    ui::fonts
    bind . <Configure> {if {"%W" eq "."} app::fit}
}

# Keep the app in a phone-width column, centred, on tablets / landscape / desktop.
proc app::fit {} {
    variable view
    set cw [expr {int(112 * $ui::U)}]
    if {[winfo width .] > $cw} {
        place configure $view -relwidth 0 -width $cw
    } else {
        place configure $view -relwidth 1 -width 0
    }
}

# Android back button / Escape.
proc app::back {} {
    variable tab
    if {[winfo exists .dlg]} { destroy .dlg; return }
    if {[winfo exists $::app::view.top.x]} {
        if {[winfo exists $::app::view.top.n]} { review::finish } else { run::quit }
        return
    }
    if {$tab ne "home"} { go home }
}

proc app::clear {} {
    variable view
    . configure -bg $::T(bg)
    $view configure -bg $::T(bg)
    foreach k [winfo children $view] { destroy $k }
    catch {destroy .toast}
    catch {destroy .dlg}
    catch {after cancel $::app::confettiJob}
}

proc app::go {where args} {
    variable tab
    switch $where {
        home     { set tab home;    screenHome }
        practice { set tab practice; screenPractice }
        play     { set tab play;    screenPlay }
        profile  { set tab profile; screenProfile }
    }
}

# Scrollable screen with a bottom tab bar. Returns the body frame.
proc app::tabScreen {active} {
    variable view
    clear
    frame $view.nav -bg $::T(surface)
    pack $view.nav -side bottom -fill x
    navbar $view.nav.c $active
    pack $view.nav.c -fill x
    set body [ui::scroll $view.s]
    pack $view.s -fill both -expand 1
    return $body
}
proc app::navbar {w active} {
    canvas $w -height [ui::px 15.5] -highlightthickness 0 -bd 0 -bg $::T(surface)
    bind $w <Configure> [list app::navDraw $w $active %w %h]
    bind $w <ButtonRelease-1> [list app::navTap $w %x]
}
proc app::navDraw {w active W H} {
    $w delete all
    $w create line 0 0 $W 0 -fill $::T(border) -width 1
    set tabs {home Learn home practice Practice cards play Playground code profile Profile user}
    set n 0
    foreach {id label ic} $tabs {
        set cx [expr {int(($n + .5) * $W / 4)}]
        set col [expr {$id eq $active ? $::T(primary) : $::T(muted)}]
        if {$id eq $active} {
            ui::rrect $w [expr {$cx - [ui::px 8]}] [expr {$H * .36 - [ui::px 4.2]}] [expr {$cx + [ui::px 8]}] [expr {$H * .36 + [ui::px 4.2]}] \
                [ui::px 4.2] -fill [ui::mix $::T(surface) $::T(primary) .24]
        }
        ui::icon $w $ic $cx [expr {$H * .36}] [ui::px 5.6] $col
        $w create text $cx [expr {$H * .75}] -text $label -font f.tab -fill $col
        incr n
    }
}
proc app::navTap {w x} {
    set i [expr {int($x * 4.0 / [winfo width $w])}]
    app::go [lindex {home practice play profile} $i]
}

proc app::pill {w icon text color} {
    set font f.smallb
    set tw [font measure $font $text]
    set H [ui::px 8.6]
    set W [expr {$tw + [ui::px 11.5]}]
    canvas $w -width $W -height $H -highlightthickness 0 -bd 0 -bg [[ui::par $w] cget -bg]
    ui::rrect $w 0 0 $W $H [expr {$H/2}] -fill $::T(surface) -outline $::T(border)
    ui::icon $w $icon [ui::px 4.6] [expr {$H/2}] [ui::px 4.4] $color
    $w create text [ui::px 7.8] [expr {$H/2}] -text $text -font $font -fill $::T(text) -anchor w
}

proc app::sectionTitle {parent text} {
    label $parent.[incr ::app::uid] -text $text -font f.h2 -fg $::T(text) -bg $::T(bg) -anchor w
    pack $parent.$::app::uid -fill x -padx [ui::px 4] -pady [list [ui::px 4] [ui::px 1.5]]
}
set app::uid 0
set app::confettiJob ""

# ============================================================== HOME
proc app::screenHome {} {
    set body [tabScreen home]
    set pad [ui::px 4]
    # header
    frame $body.hd -bg $::T(bg)
    pack $body.hd -fill x -padx $pad -pady [list [ui::px 4] [ui::px 2]]
    label $body.hd.t -text "Learn Tcl" -font f.title -fg $::T(text) -bg $::T(bg)
    pack $body.hd.t -side left
    pill $body.hd.xp bolt "[dict get $::state xp] XP" $::T(warn)
    pill $body.hd.st flame [store::streak] $::T(error)
    pack $body.hd.xp $body.hd.st -side right -padx [list [ui::px 1.5] 0]

    # daily goal + level
    set goal [store::setting goal 50]
    set today [store::xpToday]
    set f [ui::card $body.goal -fill $::T(surface) -line $::T(border)]
    pack $body.goal -fill x -padx $pad -pady [ui::px 1.5]
    set R [ui::px 22]
    canvas $f.ring -width $R -height $R -highlightthickness 0 -bg $::T(surface)
    set frac [expr {min(1.0, double($today) / $goal)}]
    set rc [expr {$frac >= 1 ? $::T(success) : $::T(primary)}]
    ui::ring $f.ring [expr {$R/2}] [expr {$R/2}] $R [ui::px 3] $frac $rc $::T(surface2)
    if {$frac >= 1} { ui::icon $f.ring check [expr {$R/2}] [expr {$R/2}] [ui::px 8] $::T(success) } else {
        $f.ring create text [expr {$R/2}] [expr {$R/2 - [ui::px 1.2]}] -text "$today" -font f.h1 -fill $::T(text)
        $f.ring create text [expr {$R/2}] [expr {$R/2 + [ui::px 3.6]}] -text "XP" -font f.smallb -fill $::T(muted)
    }
    pack $f.ring -side left
    frame $f.r -bg $::T(surface)
    pack $f.r -side left -fill x -expand 1 -padx [ui::px 3.5]
    label $f.r.a -text "Daily goal" -font f.bodyb -fg $::T(text) -bg $::T(surface) -anchor w
    label $f.r.b -text "$today of $goal XP today" -font f.small -fg $::T(muted) -bg $::T(surface) -anchor w
    lassign [store::levelProgress] lp lt
    label $f.r.c -text "Level [store::level]  -  [store::levelTitle]" -font f.smallb -fg $::T(primaryText) -bg $::T(surface) -anchor w
    ui::progress $f.r.p [expr {double($lp)/$lt}] -color $::T(primary) -track $::T(surface2)
    pack $f.r.a $f.r.b -fill x
    pack $f.r.c -fill x -pady [list [ui::px 1.6] [ui::px .8]]
    pack $f.r.p -fill x

    # next lesson hero
    set next [nextLesson]
    if {$next ne ""} {
        set l [content::get $next]
        set u [content::unitInfo [dict get $l unit]]
        set col [dict get $u color]
        set fill [ui::mix $::T(bg) $col .22]
        set f [ui::card $body.hero -fill $fill -line [ui::mix $::T(bg) $col .6] -pad [ui::px 4.4]]
        pack $body.hero -fill x -padx $pad -pady [ui::px 1.5]
        label $f.k -text "UP NEXT  -  LESSON $next" -font f.smallb -fg [ui::ink $col] -bg $fill -anchor w
        label $f.t -text [dict get $l title] -font f.h1 -fg $::T(text) -bg $fill -anchor w -justify left \
            -wraplength [expr {[winfo width .] - [ui::px 22]}]
        ui::rich $f.d [dict get $l blurb] -bg $fill -fg $::T(muted)
        pack $f.k $f.t -fill x
        pack $f.d -fill x -pady [list [ui::px 1] [ui::px 3]]
        ui::button $f.b "Start  ([content::minutes $next] min)" [list app::startLesson $next] -bg $fill -height [ui::px 12.5]
        pack $f.b -fill x
    } else {
        ui::rich $body.done "You have finished every lesson. Keep your skills sharp in Practice." -font f.bodyb
        pack $body.done -fill x -padx $pad -pady [ui::px 3]
    }

    # cards due
    set cnt [srs::counts]
    set due [llength [srs::dueList]]
    if {$due > 0} {
        set f [ui::card $body.due -fill $::T(surface) -line $::T(border) -pad [ui::px 3.4]]
        pack $body.due -fill x -padx $pad -pady [ui::px 1.5]
        frame $f.l -bg $::T(surface)
        pack $f.l -side left -fill x -expand 1
        label $f.l.a -text "$due cards ready to review" -font f.bodyb -fg $::T(text) -bg $::T(surface) -anchor w
        label $f.l.b -text "Spaced review keeps lessons in memory" -font f.small -fg $::T(muted) -bg $::T(surface) -anchor w
        pack $f.l.a $f.l.b -fill x
        ui::button $f.go "Review" {app::startReview} -style success -height [ui::px 10] -bg $::T(surface)
        $f.go configure -width [ui::px 31]
        pack $f.go -side right
    }

    # units
    foreach u $content::units {
        set n [dict get $u n]
        set ids [content::lessonsOf $n]
        if {![llength $ids]} continue
        set done 0
        foreach id $ids { if {[store::lessonDone $id]} { incr done } }
        set col [dict get $u color]
        set f [ui::card $body.u$n -fill [ui::mix $::T(bg) $col .2] -line [ui::mix $::T(bg) $col .55] -pad [ui::px 3.6]]
        pack $body.u$n -fill x -padx $pad -pady [list [ui::px 4.5] [ui::px 1]]
        set bg [ui::mix $::T(bg) $col .2]
        label $f.k -text "UNIT $n   -   $done / [llength $ids]" -font f.smallb -fg [ui::ink $col] -bg $bg -anchor w
        label $f.t -text [dict get $u title] -font f.h2 -fg $::T(text) -bg $bg -anchor w
        ui::rich $f.d [dict get $u blurb] -bg $bg -fg $::T(muted) -font f.small
        pack $f.k $f.t -fill x
        pack $f.d -fill x
        ui::button $f.t$n [expr {$done == [llength $ids] ? "Retake unit test" : "Unit test / test out"}] [list app::startUnitTest $n] \
            -style secondary -height [ui::px 9.5] -font f.smallb -bg $bg
        pack $f.t$n -fill x -pady [list [ui::px 2] 0]
        path $body.p$n $ids $col
        pack $body.p$n -fill x -padx $pad
    }
    frame $body.pad -bg $::T(bg) -height [ui::px 8]
    pack $body.pad
    ui::dragify $::app::view
}

proc app::isUnlocked {id} {
    if {[store::setting unlockAll 0]} { return 1 }
    set o [content::ids]
    set i [lsearch -exact $o $id]
    expr {$i <= 0 || [store::lessonDone [lindex $o [expr {$i - 1}]]]}
}
proc app::nextLesson {} {
    foreach id [content::ids] { if {![store::lessonDone $id]} { return $id } }
    return ""
}

# vertical lesson path for one unit
proc app::path {c ids color} {
    canvas $c -height [expr {[llength $ids] * [ui::px 22]}] -highlightthickness 0 -bd 0 -bg $::T(bg)
    bind $c <Configure> [list app::pathDraw $c [list $ids] $color %w]
}
proc app::pathDraw {c ids color W} {
    $c delete all
    set ids [lindex $ids 0]
    set cx [ui::px 9]
    set r [ui::px 6.4]
    set tx [expr {$cx + $r + [ui::px 4.5]}]
    set tw [expr {$W - $tx - [ui::px 3]}]
    set y [ui::px 1]
    set centers {}
    # pass 1: lay out text, remember node centres
    foreach id $ids {
        set l [content::get $id]
        set done [store::lessonDone $id]
        set open [isUnlocked $id]
        set tag lesson$id
        set fg [expr {$open ? $::T(text) : $::T(muted)}]
        set t1 [$c create text $tx $y -text "$id  [dict get $l title]" -font f.bodyb -fill $fg -anchor nw -width $tw -tags [list $tag txt$id]]
        set b1 [$c bbox $t1]
        set y2 [expr {[lindex $b1 3] + [ui::px .5]}]
        set t2 [$c create text $tx $y2 -text "[llength [dict get $l pages]] pages  -  [llength [dict get $l ex]] questions  -  ~[content::minutes $id] min" \
            -font f.small -fill $::T(muted) -anchor nw -tags [list $tag txt$id]]
        set bottom [lindex [$c bbox $t2] 3]
        if {$done} {
            set st [store::lessonStars $id]
            set sy [expr {$bottom + [ui::px 3]}]
            for {set s 0} {$s < 3} {incr s} {
                ui::icon $c star [expr {$tx + [ui::px 2.4] + $s * [ui::px 5.2]}] $sy [ui::px 4.6] \
                    [expr {$s < $st ? $::T(warn) : $::T(surface2)}] [list $tag txt$id]
            }
            set bottom [expr {$sy + [ui::px 2.4]}]
        }
        set th [expr {$bottom - $y}]
        set rowH [expr {max([ui::px 21], $th + [ui::px 6])}]
        set dy [expr {($rowH - $th) / 2}]
        $c move txt$id 0 $dy
        lappend centers [expr {$y + $rowH / 2}]
        set y [expr {$y + $rowH}]
    }
    $c configure -height [expr {$y + [ui::px 1]}]
    # pass 2: connector + nodes underneath/over the text
    set n [llength $ids]
    for {set i 0} {$i < $n - 1} {incr i} {
        $c create line $cx [lindex $centers $i] $cx [lindex $centers [expr {$i+1}]] -fill $::T(border) -width [ui::px 1.1]
    }
    set i 0
    foreach id $ids {
        set cy [lindex $centers $i]
        set tag lesson$id
        if {[store::lessonDone $id]} {
            ui::circle $c $cx $cy $r $color "" 0 $tag
            ui::icon $c check $cx $cy [ui::px 7] #ffffff $tag
        } elseif {[isUnlocked $id]} {
            ui::circle $c $cx $cy [expr {$r + [ui::px 1.4]}] [ui::mix $::T(bg) $color .28] "" 0 $tag
            ui::circle $c $cx $cy $r $::T(surface) $color [ui::px .8] $tag
            ui::icon $c play [expr {$cx+1}] $cy [ui::px 5] $color $tag
        } else {
            ui::circle $c $cx $cy $r $::T(surface2) $::T(border) [ui::px .5] $tag
            ui::icon $c lock $cx $cy [ui::px 5] $::T(muted) $tag
        }
        $c bind $tag <ButtonRelease-1> [list app::lessonTap $id]
        incr i
    }
}
proc app::lessonTap {id} {
    if {$::ui::drag(moved)} return
    if {![isUnlocked $id]} {
        ui::toast "Finish the lesson before it to unlock this one."
        return
    }
    startLesson $id
}

proc app::startLesson {id} {
    run::start steps [run::lessonSteps $id] mode lesson lesson $id onfinish app::lessonDone
}
proc app::lessonDone {sum} { result $sum }
proc app::startUnitTest {n} {
    set steps [run::unitSteps $n 10]
    if {![llength $steps]} return
    run::start steps $steps mode unittest unit $n onfinish app::lessonDone
}

# ============================================================== RESULT
proc app::result {sum} {
    variable view
    clear
    set mode [dict get $sum mode]
    set body [ui::scroll $view.s]
    frame $view.bot -bg $::T(bg)
    pack $view.bot -side bottom -fill x -padx [ui::px 4] -pady [ui::px 3]
    pack $view.s -fill both -expand 1
    set pad [ui::px 5]
    frame $body.in -bg $::T(bg)
    pack $body.in -fill x -padx $pad -pady [ui::px 8]
    set b $body.in
    canvas $b.st -height [ui::px 28] -highlightthickness 0 -bg $::T(bg)
    if {$mode eq "lesson"} {
        bind $b.st <Configure> [list app::drawStars $b.st [dict get $sum stars] %w %h]
        set head [expr {[dict get $sum first] ? "Lesson complete!" : "Lesson practised!"}]
    } else {
        bind $b.st <Configure> [list app::drawBadge $b.st %w %h]
        set head [expr {$mode eq "review" ? "Review complete!" : "Practice complete!"}]
        if {$mode eq "unittest"} { set head [expr {[dict get $sum passed] ? "Unit test passed!" : "Not quite yet"}] }
    }
    pack $b.st -fill x
    after 250 [list app::confetti $b.st]
    label $b.h -text $head -font f.title -fg $::T(text) -bg $::T(bg)
    pack $b.h -pady [list [ui::px 3] [ui::px 4]]
    # stat tiles
    frame $b.t -bg $::T(bg)
    pack $b.t -fill x -pady [ui::px 3]
    set tiles {}
    lappend tiles [list "XP" "+[dict get $sum xp]" $::T(warn)]
    if {[dict get $sum attempted] > 0} {
        lappend tiles [list "ACCURACY" "[expr {int(round([dict get $sum acc] * 100))}]%" $::T(success)]
    }
    set secs [dict get $sum seconds]
    lappend tiles [list "TIME" [format %d:%02d [expr {$secs/60}] [expr {$secs%60}]] $::T(info)]
    set i 0
    foreach t $tiles {
        lassign $t k v col
        set f [ui::card $b.t.c$i -fill $::T(surface) -line $col -pad [ui::px 2.4]]
        label $f.k -text $k -font f.smallb -fg [ui::ink $col] -bg $::T(surface)
        label $f.v -text $v -font f.h1 -fg $::T(text) -bg $::T(surface)
        pack $f.k $f.v
        pack $b.t.c$i -side left -expand 1 -fill x -padx [ui::px 1]
        incr i
    }
    if {$mode eq "unittest"} {
        if {[dict get $sum passed]} {
            ui::rich $b.n "You scored [expr {int(round([dict get $sum acc] * 100))}]%. Every lesson in this unit is now marked complete, and its flashcards are in your deck." -justify center -fg $::T(muted)
        } else {
            ui::rich $b.n "You scored [expr {int(round([dict get $sum acc] * 100))}]%. You need 80% to pass. Revisit the lessons in this unit and try again - the missed questions are now flashcards." -justify center -fg $::T(muted)
        }
        pack $b.n -fill x -pady [ui::px 3]
    }
    if {$mode eq "lesson"} {
        set nc [dict get $sum newCards]
        if {$nc > 0} {
            ui::rich $b.n "**$nc new flashcards** were added to your review deck. Reviewing them over the coming days is what moves this lesson into long-term memory." -justify center -fg $::T(muted)
            pack $b.n -fill x -pady [ui::px 3]
        }
        if {[dict get $sum missed] > 0} {
            ui::rich $b.m "Questions you missed became flashcards too, so they will come back at the right moment." -justify center -fg $::T(muted)
            pack $b.m -fill x -pady [ui::px 1]
        }
        set nxt [content::nextAfter [dict get $sum lesson]]
        if {$nxt ne ""} {
            ui::button $view.bot.n "Next lesson" [list app::startLesson $nxt] -height [ui::px 13]
            pack $view.bot.n -fill x -pady [list 0 [ui::px 2]]
        }
    }
    ui::button $view.bot.h "Back to home" {app::go home} -style [expr {$mode eq "lesson" && [content::nextAfter [dict get $sum lesson]] ne "" ? "secondary" : "primary"}] -height [ui::px 13]
    pack $view.bot.h -fill x
    ui::dragify $view
}
proc app::drawStars {c n W H} {
    $c delete all
    for {set i 0} {$i < 3} {incr i} {
        set cx [expr {$W/2 + ($i - 1) * [ui::px 19]}]
        set cy [expr {$H/2 + ($i == 1 ? 0 : [ui::px 3])}]
        set s [expr {$i == 1 ? [ui::px 19] : [ui::px 15]}]
        ui::icon $c star $cx $cy $s [expr {$i < $n ? $::T(warn) : $::T(surface2)}]
    }
}
proc app::drawBadge {c W H} {
    $c delete badge
    set r [expr {$H * .36}]
    ui::circle $c [expr {$W/2}] [expr {$H/2}] $r $::T(success) "" 0 badge
    ui::icon $c check [expr {$W/2}] [expr {$H/2}] [expr {$r*1.2}] #ffffff badge
}
# Confetti falls inside the header canvas only, so it never covers other widgets.
proc app::confetti {c} {
    if {![winfo exists $c]} return
    variable cfp
    array unset cfp
    set W [winfo width $c]; set H [winfo height $c]
    set cols [list $::T(primary) $::T(success) $::T(warn) $::T(error) $::T(info)]
    for {set i 0} {$i < 38} {incr i} {
        set x [expr {rand() * $W}]; set y [expr {-rand() * $H * .8}]
        set s [expr {[ui::px 1.0] + rand() * [ui::px 1.4]}]
        set id [$c create rectangle $x $y [expr {$x + $s * 1.6}] [expr {$y + $s}] \
            -fill [lindex $cols [expr {int(rand() * 5)}]] -outline "" -tags conf]
        set cfp($id) [list [expr {(rand() - .5) * 2.4}] [expr {1.6 + rand() * 2.6}]]
    }
    set ::app::confettiJob [after 16 [list app::confettiStep $c 0 $H]]
}
proc app::confettiStep {c n H} {
    variable cfp
    if {![winfo exists $c]} return
    if {$n > 80} { $c delete conf; return }
    foreach id [$c find withtag conf] {
        lassign $cfp($id) dx dy
        $c move $id $dx $dy
        if {[lindex [$c coords $id] 1] > $H} { $c delete $id }
    }
    set ::app::confettiJob [after 16 [list app::confettiStep $c [expr {$n+1}] $H]]
}

# ============================================================== PRACTICE
proc app::actionCard {w icon title desc cmd color enabled} {
    set fill $::T(surface)
    set f [ui::card $w -fill $fill -line $::T(border) -pad [ui::px 3.6]]
    canvas $f.i -width [ui::px 12] -height [ui::px 12] -highlightthickness 0 -bg $fill
    ui::rrect $f.i 0 0 [ui::px 12] [ui::px 12] [ui::px 4] -fill [ui::mix $fill $color [expr {$enabled ? .24 : .08}]]
    ui::icon $f.i $icon [ui::px 6] [ui::px 6] [ui::px 6.4] [expr {$enabled ? $color : $::T(muted)}]
    pack $f.i -side left
    frame $f.t -bg $fill
    pack $f.t -side left -fill x -expand 1 -padx [ui::px 3.2]
    label $f.t.a -text $title -font f.bodyb -fg [expr {$enabled ? $::T(text) : $::T(muted)}] -bg $fill -anchor w
    label $f.t.b -text $desc -font f.small -fg $::T(muted) -bg $fill -anchor w -justify left \
        -wraplength [expr {[winfo width .] - [ui::px 40]}]
    pack $f.t.a $f.t.b -fill x
    foreach x [list $w $f $f.i $f.t $f.t.a $f.t.b] {
        bind $x <ButtonRelease-1> [list app::actionTap $cmd $enabled]
    }
}
proc app::actionTap {cmd enabled} {
    if {$::ui::drag(moved)} return
    if {!$enabled} { ui::toast "Finish a lesson first to unlock this."; return }
    uplevel #0 $cmd
}

proc app::screenPractice {} {
    set body [tabScreen practice]
    set pad [ui::px 4]
    label $body.t -text "Practice" -font f.title -fg $::T(text) -bg $::T(bg) -anchor w
    pack $body.t -fill x -padx $pad -pady [list [ui::px 4] [ui::px 1]]
    ui::rich $body.s "Recalling something is the strongest way to learn it. Mix it up, and come back often." -fg $::T(muted) 
    pack $body.s -fill x -padx $pad -pady [list 0 [ui::px 3]]
    set cnt [srs::counts]
    set due [llength [srs::dueList]]
    set any [expr {[llength [run::pick 1]] > 0}]
    set dueText [expr {$due > 0 ? "$due ready now  -  [dict get $cnt mature] mastered  -  [dict get $cnt total] in deck" : "Nothing due right now.  [dict get $cnt total] cards in your deck"}]
    actionCard $body.a1 cards "Flashcards" $dueText app::startReview $::T(success) [expr {[dict get $cnt total] > 0}]
    pack $body.a1 -fill x -padx $pad -pady [ui::px 1.5]
    actionCard $body.a2 target "Daily practice" "10 mixed questions from everything you have learned. Weak spots show up more often." {app::startPractice 10 {mc predict type blank order}} $::T(primary) $any
    pack $body.a2 -fill x -padx $pad -pady [ui::px 1.5]
    actionCard $body.a3 bolt "Quick quiz" "5 fast multiple-choice questions, about two minutes." {app::startPractice 5 {mc predict}} $::T(warn) $any
    pack $body.a3 -fill x -padx $pad -pady [ui::px 1.5]
    # deck stats
    sectionTitle $body "Your memory deck"
    set f [ui::card $body.deck -fill $::T(surface) -line $::T(border)]
    pack $body.deck -fill x -padx $pad
    set total [expr {max(1, [dict get $cnt total])}]
    foreach {k label col} [list new "New" $::T(info) young "Learning" $::T(warn) mature "Mastered" $::T(success)] {
        frame $f.$k -bg $::T(surface)
        pack $f.$k -fill x -pady [ui::px .8]
        label $f.$k.l -text $label -font f.small -fg $::T(muted) -bg $::T(surface) -width 9 -anchor w
        label $f.$k.n -text [dict get $cnt $k] -font f.smallb -fg $::T(text) -bg $::T(surface) -width 4 -anchor e
        ui::progress $f.$k.p [expr {double([dict get $cnt $k])/$total}] -color $col -track $::T(surface2)
        pack $f.$k.l -side left
        pack $f.$k.n -side right
        pack $f.$k.p -side left -fill x -expand 1 -padx [ui::px 2]
    }
    sectionTitle $body "How this works"
    set f [ui::card $body.how -fill $::T(surface) -line $::T(border)]
    pack $body.how -fill x -padx $pad
    ui::rich $f.t "- **Spaced repetition**: a card you know comes back after 1, 3, then 7+ days. One you forget comes back sooner.\n- **Interleaving**: mixing topics feels harder but teaches you to tell similar commands apart.\n- **Rate honestly**: pick *Again* when you didn't know it. That is how the schedule learns you." -bg $::T(surface)
    pack $f.t -fill x
    frame $body.pad -bg $::T(bg) -height [ui::px 8]
    pack $body.pad
    ui::dragify $::app::view
}
proc app::startPractice {n kinds} {
    set steps [run::practiceSteps $n $kinds]
    if {![llength $steps]} { ui::toast "Finish a lesson first."; return }
    run::start steps $steps mode practice onfinish app::lessonDone
}

# ============================================================== FLASHCARD REVIEW
namespace eval review { variable S; array set S {} }
proc app::startReview {} {
    set q [srs::dueList]
    if {![llength $q]} { ui::toast "You're all caught up. Nothing is due."; return }
    review::start $q
}
proc review::start {q} {
    variable S
    array unset S
    set S(queue) $q
    set S(total) [llength $q]
    set S(done) 0
    set S(again) 0
    set S(start) [clock seconds]
    set S(reviewed) 0
    app::clear
    set v $::app::view
    frame $v.top -bg $::T(bg)
    pack $v.top -fill x -padx [ui::px 4] -pady [list [ui::px 3] [ui::px 1]]
    canvas $v.top.x -width [ui::px 9] -height [ui::px 9] -highlightthickness 0 -bg $::T(bg)
    ui::icon $v.top.x close [ui::px 4.5] [ui::px 4.5] [ui::px 6] $::T(muted)
    bind $v.top.x <ButtonRelease-1> {if {!$::ui::drag(moved)} {review::finish}}
    pack $v.top.x -side left
    ui::progress $v.top.p 0
    pack $v.top.p -side left -fill x -expand 1 -padx [ui::px 3]
    label $v.top.n -text "" -font f.smallb -fg $::T(muted) -bg $::T(bg) -width 5
    pack $v.top.n -side left
    frame $v.bot -bg $::T(bg)
    pack $v.bot -side bottom -fill x -padx [ui::px 4] -pady [ui::px 3]
    set S(bot) $v.bot
    set body [ui::scroll $v.s]
    pack $v.s -fill both -expand 1
    set S(body) $body
    set S(scroll) $v.s.c
    set S(top) $v.top
    show
}
proc review::show {} {
    variable S
    foreach k [winfo children $S(body)] { destroy $k }
    foreach k [winfo children $S(bot)] { destroy $k }
    ui::progress $S(top).p [expr {double($S(done)) / max(1, $S(total))}]
    $S(top).n configure -text "[llength $S(queue)] left"
    if {![llength $S(queue)]} { finish; return }
    set S(cid) [lindex $S(queue) 0]
    set S(card) [dict get $::state cards $S(cid)]
    set c [content::anyCard $S(cid)]
    set S(c) $c
    set b $S(body).in
    frame $b -bg $::T(bg)
    pack $b -fill x -padx [ui::px 4] -pady [ui::px 3]
    label $b.k -text [expr {[srs::isNew $S(card)] ? "NEW CARD" : "REVIEW"}] -font f.smallb \
        -fg [expr {[srs::isNew $S(card)] ? $::T(info) : $::T(muted)}] -bg $::T(bg) -anchor w
    pack $b.k -fill x -pady [list 0 [ui::px 1.5]]
    set f [ui::card $b.card -fill $::T(surface) -line $::T(border) -pad [ui::px 4.4]]
    pack $b.card -fill x
    ui::rich $f.q [dict get $c front] -bg $::T(surface) -font f.h2
    pack $f.q -fill x
    if {[dict get $c code] ne ""} {
        ui::code $f.code [dict get $c code] -outer $::T(surface)
        pack $f.code -fill x -pady [list [ui::px 2.5] 0]
    }
    label $b.hint -text "Try to recall the answer before you look." -font f.small -fg $::T(muted) -bg $::T(bg)
    pack $b.hint -pady [ui::px 3.5]
    set S(in) $b
    ui::button $S(bot).show "Show answer" review::reveal -height [ui::px 13.5]
    pack $S(bot).show -fill x
    ui::dragify $S(body)
}
proc review::reveal {} {
    variable S
    set b $S(in)
    destroy $b.hint
    set f [ui::card $b.ans -fill [ui::mix $::T(bg) $::T(success) .12] -line [ui::mix $::T(bg) $::T(success) .5] -pad [ui::px 4.4]]
    pack $b.ans -fill x -pady [ui::px 3]
    set fill [ui::mix $::T(bg) $::T(success) .12]
    ui::rich $f.a [dict get $S(c) back] -bg $fill
    pack $f.a -fill x
    foreach k [winfo children $S(bot)] { destroy $k }
    frame $S(bot).g -bg $::T(bg)
    pack $S(bot).g -fill x
    set i 0
    foreach {label style} {Again danger Hard secondary Good success Easy primary} {
        ui::button $S(bot).g.b$i "$label\n[srs::preview $S(card) $i]" [list review::grade $i] -style $style \
            -height [ui::px 15.5] -font f.smallb
        pack $S(bot).g.b$i -side left -expand 1 -fill x -padx [ui::px .8]
        incr i
    }
    ui::dragify $S(body)
    update idletasks
    ui::_scrollRegion $S(scroll)
    $S(scroll) yview moveto 1
}
proc review::grade {g} {
    variable S
    set cid $S(cid)
    if {[srs::isNew $S(card)]} { srs::noteNewIntroduced }
    dict set ::state cards $cid [srs::grade $S(card) $g]
    incr S(reviewed)
    set S(queue) [lrange $S(queue) 1 end]
    if {$g == 0} {
        incr S(again)
        set pos [expr {min(3, [llength $S(queue)])}]
        set S(queue) [linsert $S(queue) $pos $cid]
    } else {
        incr S(done)
    }
    store::save
    show
}
proc review::finish {} {
    variable S
    set n $S(reviewed)
    if {$n == 0} { app::go practice; return }
    set xp [expr {$n * 2}]
    store::addXP $xp
    store::save
    set acc [expr {double($n - $S(again)) / $n}]
    app::result [dict create mode review stars 0 acc $acc xp $xp bonus 0 first 0 newCards 0 \
        attempted $n correct [expr {$n - $S(again)}] missed 0 lesson "" seconds [expr {[clock seconds] - $S(start)}]]
}

# ============================================================== PLAYGROUND
proc app::screenPlay {} {
    set body [tabScreen play]
    set pad [ui::px 4]
    label $body.t -text "Playground" -font f.title -fg $::T(text) -bg $::T(bg) -anchor w
    pack $body.t -fill x -padx $pad -pady [list [ui::px 4] [ui::px 1]]
    ui::rich $body.s "A real Tcl interpreter. Experiment freely - nothing here can break anything." -fg $::T(muted)
    pack $body.s -fill x -padx $pad -pady [list 0 [ui::px 2.5]]
    set code [dict get $::state playground]
    if {$code eq ""} { set code "puts \"Hello, Tcl!\"\n" }
    ui::editor $body.ed $code -height 9
    pack $body.ed -fill x -padx $pad
    set ::app::pgText $body.ed.t
    ui::symbols $body.sym $body.ed.t
    pack $body.sym -fill x -padx $pad -pady [ui::px 1.8]
    frame $body.bt -bg $::T(bg)
    pack $body.bt -fill x -padx $pad -pady [ui::px 1]
    ui::button $body.bt.run "Run" app::playRun -height [ui::px 12]
    ui::button $body.bt.clr "Clear" app::playClear -style secondary -height [ui::px 12]
    pack $body.bt.run -side left -expand 1 -fill x -padx [list 0 [ui::px 1]]
    pack $body.bt.clr -side left -expand 1 -fill x -padx [list [ui::px 1] 0]
    frame $body.out -bg $::T(bg)
    pack $body.out -fill x -padx $pad -pady [ui::px 2]
    set ::app::pgOut $body.out
    label $body.ex -text "Try an example" -font f.h2 -fg $::T(text) -bg $::T(bg) -anchor w
    pack $body.ex -fill x -padx $pad -pady [list [ui::px 3] [ui::px 1]]
    ui::flow $body.fl
    pack $body.fl -fill x -padx $pad
    set ei 0
    foreach {name code} $app::examples {
        set c $body.fl.e[incr ei]
        ui::option $c $name [list app::playLoad $code] -fit 1 -font f.small -align center
        ui::flowAdd $body.fl $c
    }
    frame $body.pad -bg $::T(bg) -height [ui::px 10]
    pack $body.pad
    ui::dragify $::app::view
}
proc app::playRun {} {
    set code [$::app::pgText get 1.0 end-1c]
    dict set ::state playground $code
    store::save
    set r [sandbox::run $code]
    foreach k [winfo children $::app::pgOut] { destroy $k }
    ui::output $::app::pgOut.o [sandbox::display $r]
    pack $::app::pgOut.o -fill x
    ui::dragify $::app::pgOut
    if {[dict get $r ok]} { store::touchStreak }
}
proc app::playClear {} { $::app::pgText delete 1.0 end; focus $::app::pgText }
proc app::playLoad {code} { $::app::pgText delete 1.0 end; $::app::pgText insert 1.0 $code; ui::_editorColor $::app::pgText }
set app::examples [list \
    "Hello"   "puts \"Hello, Tcl!\"\n" \
    "Math"    "set r 6\nputs \"Area: \[expr {3.14159 * \$r ** 2}\]\"\n" \
    "Loop"    "for {set i 1} {\$i <= 5} {incr i} {\n    puts \"\$i squared is \[expr {\$i * \$i}\]\"\n}\n" \
    "Proc"    "proc greet {name} {\n    return \"Hello, \$name!\"\n}\nputs \[greet World\]\n" \
    "List"    "set fruits {pear apple fig}\nputs \[lsort \$fruits\]\nputs \[llength \$fruits\]\n" \
    "Dict"    "set d \[dict create a 1 b 2\]\ndict for {k v} \$d {puts \"\$k -> \$v\"}\n" \
    "Regex"   "regexp {(\\d+)-(\\d+)} \"call 555-1234\" all a b\nputs \"\$a / \$b\"\n" \
    "Lambda"  "set sq {x {expr {\$x * \$x}}}\nputs \[lmap n {1 2 3 4} {apply \$sq \$n}\]\n"]

# ============================================================== PROFILE
proc app::screenProfile {} {
    set body [tabScreen profile]
    set pad [ui::px 4]
    # identity
    frame $body.id -bg $::T(bg)
    pack $body.id -fill x -padx $pad -pady [list [ui::px 5] [ui::px 2]]
    set R [ui::px 22]
    canvas $body.id.a -width $R -height $R -highlightthickness 0 -bg $::T(bg)
    ui::circle $body.id.a [expr {$R/2}] [expr {$R/2}] [expr {$R/2 - 1}] $::T(primary)
    $body.id.a create text [expr {$R/2}] [expr {$R/2}] -text [store::level] -font f.num -fill $::T(onprimary)
    pack $body.id.a -side left
    frame $body.id.t -bg $::T(bg)
    pack $body.id.t -side left -padx [ui::px 4] -fill x -expand 1
    label $body.id.t.a -text [store::levelTitle] -font f.h1 -fg $::T(text) -bg $::T(bg) -anchor w
    lassign [store::levelProgress] lp lt
    label $body.id.t.b -text "Level [store::level]  -  $lp / $lt XP to next" -font f.small -fg $::T(muted) -bg $::T(bg) -anchor w
    ui::progress $body.id.t.p [expr {double($lp)/$lt}] -color $::T(primary)
    pack $body.id.t.a $body.id.t.b -fill x
    pack $body.id.t.p -fill x -pady [ui::px 1]

    # stats
    set cnt [srs::counts]
    set done 0
    foreach id [content::ids] { if {[store::lessonDone $id]} { incr done } }
    set r 0; set w 0
    dict for {k v} [dict get $::state exstats] { incr r [lindex $v 0]; incr w [lindex $v 1] }
    set acc [expr {$r + $w ? "[expr {int(100.0*$r/($r+$w))}]%" : "-"}]
    set tiles [list \
        "Day streak" [store::streak] flame $::T(error) \
        "Best streak" [dict get $::state best] flame $::T(warn) \
        "Lessons" "$done/[llength [content::ids]]" check $::T(success) \
        "Accuracy" $acc target $::T(info) \
        "Total XP" [dict get $::state xp] bolt $::T(warn) \
        "Mastered cards" [dict get $cnt mature] cards $::T(primary)]
    frame $body.g -bg $::T(bg)
    pack $body.g -fill x -padx $pad -pady [ui::px 2]
    set i 0
    foreach {label val ic col} $tiles {
        set cell $body.g.c$i
        set f [ui::card $cell -fill $::T(surface) -line $::T(border) -pad [ui::px 3]]
        frame $f.top -bg $::T(surface)
        pack $f.top -fill x
        canvas $f.top.i -width [ui::px 6] -height [ui::px 6] -highlightthickness 0 -bg $::T(surface)
        ui::icon $f.top.i $ic [ui::px 3] [ui::px 3] [ui::px 5] $col
        pack $f.top.i -side left
        label $f.top.l -text $label -font f.small -fg $::T(muted) -bg $::T(surface)
        pack $f.top.l -side left -padx [ui::px 1.5]
        label $f.v -text $val -font f.h1 -fg $::T(text) -bg $::T(surface) -anchor w
        pack $f.v -fill x
        grid $cell -row [expr {$i / 2}] -column [expr {$i % 2}] -sticky ew -padx [ui::px .8] -pady [ui::px .8]
        incr i
    }
    grid columnconfigure $body.g {0 1} -weight 1 -uniform c

    # last 7 days
    sectionTitle $body "Last 7 days"
    set f [ui::card $body.wk -fill $::T(surface) -line $::T(border)]
    pack $body.wk -fill x -padx $pad
    canvas $f.c -height [ui::px 34] -highlightthickness 0 -bg $::T(surface)
    pack $f.c -fill x
    bind $f.c <Configure> [list app::drawWeek $f.c %w %h]

    # settings
    sectionTitle $body "Settings"
    set f [ui::card $body.set -fill $::T(surface) -line $::T(border)]
    pack $body.set -fill x -padx $pad
    label $f.g -text "Daily goal (XP)" -font f.bodyb -fg $::T(text) -bg $::T(surface) -anchor w
    pack $f.g -fill x
    frame $f.gb -bg $::T(surface)
    pack $f.gb -fill x -pady [ui::px 1.5]
    set cur [store::setting goal 50]
    foreach g {20 50 100 150} {
        ui::option $f.gb.b$g $g [list app::setGoal $g] -font f.bodyb -align center -state [expr {$g == $cur ? "selected" : "normal"}] -bg $::T(surface)
        pack $f.gb.b$g -side left -expand 1 -fill x -padx [ui::px .6]
    }
    label $f.th -text "Appearance" -font f.bodyb -fg $::T(text) -bg $::T(surface) -anchor w
    pack $f.th -fill x -pady [list [ui::px 2] 0]
    frame $f.tb -bg $::T(surface)
    pack $f.tb -fill x -pady [ui::px 1.5]
    foreach t {dark light} {
        ui::option $f.tb.$t [string totitle $t] [list app::setTheme $t] -font f.bodyb -align center \
            -state [expr {$t eq $::T(name) ? "selected" : "normal"}] -bg $::T(surface)
        pack $f.tb.$t -side left -expand 1 -fill x -padx [ui::px .6]
    }
    label $f.ts -text "Text size" -font f.bodyb -fg $::T(text) -bg $::T(surface) -anchor w
    pack $f.ts -fill x -pady [list [ui::px 2] 0]
    frame $f.tsb -bg $::T(surface)
    pack $f.tsb -fill x -pady [ui::px 1.5]
    set cs [store::setting textScale 1.0]
    set k 0
    foreach {nm v} {A- 0.9 A 1.0 A+ 1.15 A++ 1.3} {
        ui::option $f.tsb.b[incr k] $nm [list app::setScale $v] -font f.bodyb -align center \
            -state [expr {$v == $cs ? "selected" : "normal"}] -bg $::T(surface)
        pack $f.tsb.b$k -side left -expand 1 -fill x -padx [ui::px .6]
    }
    label $f.ul -text "Lesson unlocking" -font f.bodyb -fg $::T(text) -bg $::T(surface) -anchor w
    pack $f.ul -fill x -pady [list [ui::px 2] 0]
    frame $f.ub -bg $::T(surface)
    pack $f.ub -fill x -pady [ui::px 1.5]
    set ua [store::setting unlockAll 0]
    ui::option $f.ub.a "In order" [list app::setUnlock 0] -font f.bodyb -align center -state [expr {$ua ? "normal" : "selected"}] -bg $::T(surface)
    ui::option $f.ub.b "All open" [list app::setUnlock 1] -font f.bodyb -align center -state [expr {$ua ? "selected" : "normal"}] -bg $::T(surface)
    pack $f.ub.a $f.ub.b -side left -expand 1 -fill x -padx [ui::px .6]
    ui::button $f.rs "Reset all progress" {ui::confirm "Reset everything?" "This erases your XP, streak, lesson progress and flashcards. It cannot be undone." "Erase it all" app::doReset} -style secondary -height [ui::px 11] -bg $::T(surface)
    pack $f.rs -fill x -pady [list [ui::px 3] 0]

    sectionTitle $body "About"
    ui::rich $body.ab "Learn Tcl is written entirely in Tcl/Tk. Every code example in the course is executed by an automated test, so what you learn is what really runs.\n\nStore: [expr {$store::path eq {} ? {not saved (read-only device?)} : $store::path}]" -fg $::T(muted) -font f.small
    pack $body.ab -fill x -padx $pad
    frame $body.pad -bg $::T(bg) -height [ui::px 10]
    pack $body.pad
    ui::dragify $::app::view
}
proc app::drawWeek {c W H} {
    $c delete all
    set today [util::today]
    set mx 20
    for {set i 6} {$i >= 0} {incr i -1} {
        set d [expr {$today - $i}]
        set v [expr {[dict exists $::state daily $d] ? [dict get $::state daily $d] : 0}]
        set mx [expr {max($mx, $v)}]
    }
    set colW [expr {$W / 7.0}]
    set base [expr {$H - [ui::px 7]}]
    for {set i 6; set k 0} {$i >= 0} {incr i -1; incr k} {
        set d [expr {$today - $i}]
        set v [expr {[dict exists $::state daily $d] ? [dict get $::state daily $d] : 0}]
        set cx [expr {$colW * ($k + .5)}]
        set bh [expr {$v > 0 ? max([ui::px 2], ($base - [ui::px 3]) * double($v) / $mx) : [ui::px 1]}]
        set bw [expr {$colW * .46}]
        set col [expr {$v >= [store::setting goal 50] ? $::T(success) : ($v > 0 ? $::T(primary) : $::T(surface2))}]
        ui::rrect $c [expr {$cx - $bw/2}] [expr {$base - $bh}] [expr {$cx + $bw/2}] $base [ui::px 1.2] -fill $col -outline ""
        $c create text $cx [expr {$H - [ui::px 3]}] -text [util::dayName $d] -font f.small -fill [expr {$i == 0 ? $::T(text) : $::T(muted)}]
    }
}
proc app::setScale {v} { store::setSetting textScale $v; set ui::fscale $v; ui::fonts; screenProfile }
proc app::setGoal {g} { store::setSetting goal $g; screenProfile }
proc app::setTheme {t} { store::setSetting theme $t; theme::apply $t; screenProfile }
proc app::setUnlock {v} { store::setSetting unlockAll $v; screenProfile }
proc app::doReset {} { store::reset; theme::apply dark; app::go home }
