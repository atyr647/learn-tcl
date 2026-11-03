# flat.tcl - "freeze" a laid-out widget screen into ONE canvas of plain items.
#
# On Android (AndroWish/SDL Tk) moving a window makes the toolkit recompute and
# repaint every nested child window, so scrolling a screen made of 100+ widgets is
# very slow. Instead we build the screen with ordinary widgets (they stay alive,
# hidden underneath), copy what they draw into a single canvas, and scroll that:
# a canvas only redraws its items, with no windows to move.
#
# Taps are forwarded to the original widgets' handlers. After the page changes,
# call flat::dirty and the snapshot is rebuilt.
namespace eval flat {
    variable hot        ;# per scroll container: list of {x1 y1 x2 y2 kind a b}
    array set hot {}
    variable job
    array set job {}
    variable enabled 1
}

proc flat::supported {w} {
    foreach k [winfo children $w] {
        switch [winfo class $k] {
            Frame - Label - Canvas { }
            Text { if {[$k cget -state] ne "disabled"} { return 0 } }
            default { return 0 }
        }
        if {![supported $k]} { return 0 }
    }
    return 1
}

# sc = the ui::scroll container (frame holding canvas .c with inner frame .c.f)
proc flat::freeze {sc} {
    variable hot
    variable enabled
    if {!$enabled || ![winfo exists $sc.c.f]} { return 0 }
    update idletasks
    set root $sc.c.f
    if {![supported $root]} { return 0 }
    set F $sc.flat
    destroy $F
    canvas $F -bg [$sc.c cget -bg] -highlightthickness 0 -bd 0 -yscrollincrement 1
    set hot($sc) {}
    set ox [winfo rootx $root]; set oy [winfo rooty $root]
    set ::flat::bgdef [$sc.c cget -bg]
    walk $sc $F $root $ox $oy
    set h [winfo reqheight $root]
    set vh [winfo height $sc.c]
    $F configure -scrollregion [list 0 0 1 [expr {max($h, $vh)}]]
    place $F -in $sc.c -x 0 -y 0 -relwidth 1 -relheight 1
    raise $F
    set ui::scrollers($F) 1
    bindtags $F [list $F Drag . all]
    bind $F <ButtonRelease-1> [list flat::tap $sc $F %x %y]
    bind $F <MouseWheel> [list $F yview scroll -60 units]
    bind $F <Button-4> [list $F yview scroll -60 units]
    bind $F <Button-5> [list $F yview scroll 60 units]
    # keep the page at the top the first time
    $F yview moveto 0
    return 1
}

proc flat::walk {sc F w ox oy} {
    variable hot
    set x [expr {[winfo rootx $w] - $ox}]
    set y [expr {[winfo rooty $w] - $oy}]
    set W [winfo width $w]; set H [winfo height $w]
    set cls [winfo class $w]
    # background of this widget
    if {$cls ne "Canvas" || 1} {
        set bg [expr {[catch {$w cget -background} b] ? "" : $b}]
        if {$bg ne "" && [string tolower $bg] ne [string tolower $::flat::bgdef]} {
            $F create rectangle $x $y [expr {$x + $W}] [expr {$y + $H}] -fill $bg -outline ""
        }
    }
    switch $cls {
        Label  { label $F $w $x $y $W $H }
        Canvas { copyCanvas $F $w $x $y }
        Text   { copyText $sc $F $w $x $y }
    }
    # interactivity
    if {[info exists ::ui::btn($w)]} {
        lappend hot($sc) [list $x $y [expr {$x + $W}] [expr {$y + $H}] btn $w ""]
    } else {
        set script [bind $w <ButtonRelease-1>]
        if {$script ne "" && $cls ne "Text"} {
            lappend hot($sc) [list $x $y [expr {$x + $W}] [expr {$y + $H}] script $w $script]
        }
    }
    foreach k [winfo children $w] {
        if {[winfo ismapped $k] || [winfo manager $k] ne ""} { walk $sc $F $k $ox $oy }
    }
}

proc flat::label {F w x y W H} {
    set text [$w cget -text]
    if {$text eq ""} return
    set anchor [$w cget -anchor]
    set wl [$w cget -wraplength]
    set px [$w cget -padx]
    set ax $x; set an nw
    switch -glob -- $anchor {
        center { set ax [expr {$x + $W / 2.0}]; set ay [expr {$y + $H / 2.0}]; set an center }
        w      { set ax [expr {$x + $px}];      set ay [expr {$y + $H / 2.0}]; set an w }
        e      { set ax [expr {$x + $W - $px}]; set ay [expr {$y + $H / 2.0}]; set an e }
        default { set ax [expr {$x + $px}]; set ay [expr {$y + $H / 2.0}]; set an w }
    }
    set opts [list -text $text -font [$w cget -font] -fill [$w cget -foreground] -anchor $an -justify [$w cget -justify]]
    if {$wl > 0} { lappend opts -width $wl }
    $F create text $ax $ay {*}$opts
}

proc flat::copyCanvas {F c x y} {
    set bg [$c cget -background]
    foreach id [$c find all] {
        set type [$c type $id]
        if {$type eq "window"} continue
        set opts {}
        foreach o [$c itemconfigure $id] {
            lassign $o name - - dflt cur
            if {$cur ne $dflt && $name ne "-tags"} { lappend opts $name $cur }
        }
        set new [$F create $type {*}[$c coords $id] {*}$opts]
        $F move $new $x $y
        # item bindings (e.g. lesson nodes)
        foreach tag [$c gettags $id] {
            if {$tag eq "current"} continue
            set s [$c bind $tag <ButtonRelease-1>]
            if {$s ne ""} {
                $F addtag $tag withtag $new
                $F bind $tag <ButtonRelease-1> $s
            }
        }
    }
}

proc flat::copyText {sc F t x y} {
    variable hot
    set wfont [$t cget -font]
    set wfg [$t cget -foreground]
    set wbg [$t cget -background]
    set run ""; set runStyle {}; set rx 0; set ry 0; set rxe 0; set rh 0
    set flush {
        if {$run ne ""} {
            lassign $runStyle f fg bgc
            if {$bgc ne "" && $bgc ne $wbg} {
                $F create rectangle [expr {$x + $rx}] [expr {$y + $ry}] [expr {$x + $rxe}] [expr {$y + $ry + $rh}] -fill $bgc -outline ""
            }
            $F create text [expr {$x + $rx}] [expr {$y + $ry}] -text $run -anchor nw -font $f -fill $fg
        }
        set run ""
    }
    foreach {key val idx} [$t dump -text 1.0 end] {
        if {$key ne "text"} continue
        set tags [$t tag names $idx]
        set f $wfont; set fg $wfg; set bgc ""
        foreach tg $tags {
            set v [$t tag cget $tg -font];       if {$v ne ""} { set f $v }
            set v [$t tag cget $tg -foreground]; if {$v ne ""} { set fg $v }
            set v [$t tag cget $tg -background]; if {$v ne ""} { set bgc $v }
        }
        set style [list $f $fg $bgc]
        set n [string length $val]
        for {set i 0} {$i < $n} {incr i} {
            set ch [string index $val $i]
            if {$ch eq "\n"} { eval $flush; continue }
            set bb [$t bbox "$idx + $i chars"]
            if {$bb eq ""} { continue }
            lassign $bb bx by bw bh
            if {$run ne "" && ($style ne $runStyle || abs($by - $ry) > 2 || $bx < $rx)} { eval $flush }
            if {$run eq ""} { set rx $bx; set ry $by; set rh $bh; set runStyle $style }
            append run $ch
            set rxe [expr {$bx + $bw}]
        }
        eval $flush
    }
    # tappable tag ranges (e.g. filled blanks)
    foreach tg [$t tag names] {
        set sc_ [$t tag bind $tg <ButtonRelease-1>]
        if {$sc_ eq ""} continue
        foreach {a b} [$t tag ranges $tg] {
            set b1 [$t bbox $a]
            set b2 [$t bbox "$b - 1 chars"]
            if {$b1 eq "" || $b2 eq ""} continue
            lappend hot($sc) [list [expr {$x + [lindex $b1 0]}] [expr {$y + [lindex $b1 1]}] \
                [expr {$x + [lindex $b2 0] + [lindex $b2 2]}] [expr {$y + [lindex $b1 1] + [lindex $b1 3]}] script $t $sc_]
        }
    }
}

# ---- taps -------------------------------------------------------------------------
proc flat::tap {sc F wx wy} {
    variable hot
    if {$::ui::drag(moved)} return
    set x [$F canvasx $wx]; set y [$F canvasy $wy]
    foreach h [lreverse $hot($sc)] {
        lassign $h x1 y1 x2 y2 kind w arg
        if {$x < $x1 || $x > $x2 || $y < $y1 || $y > $y2} continue
        if {![winfo exists $w]} continue
        switch $kind {
            btn {
                set d $::ui::btn($w)
                if {[dict get $d style] eq "option"} {
                    if {[dict get $d state] in {disabled correct wrong}} return
                } elseif {[dict get $d disabled]} { return }
                after idle [list uplevel #0 [dict get $d cmd]]
                return
            }
            script {
                after idle [list uplevel #0 [string map [list %W $w %x [expr {int($x - $x1)}] %y [expr {int($y - $y1)}]] $arg]]
                return
            }
        }
    }
}

# ---- keeping the snapshot current ----------------------------------------------------------
proc flat::dirty {sc} {
    variable job
    if {[info exists job($sc)] || ![winfo exists $sc.flat]} return
    set job($sc) [after idle [list flat::refresh $sc]]
}
proc flat::refresh {sc} {
    variable job
    unset -nocomplain job($sc)
    if {![winfo exists $sc.flat]} return
    set top [$sc.flat canvasy 0]
    freeze $sc
    if {[winfo exists $sc.flat]} { $sc.flat yview scroll [expr {int($top)}] units }
}

# Mark the scroll container that owns widget w as needing a new snapshot.
proc flat::dirtyOf {w} {
    set p $w
    while {$p ne "." && $p ne ""} {
        if {[winfo exists $p.c.f] && [winfo exists $p.flat]} { dirty $p; return }
        set p [winfo parent $p]
    }
}
