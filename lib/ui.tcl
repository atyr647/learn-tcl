# ui.tcl - a small touch-first widget kit built on plain Tk canvases.
namespace eval ui {
    variable fscale 1.0
    variable U 4.0               ;# 1% of screen width in pixels; everything scales from it
    variable drag
    array set drag {moved 0 canvas "" y 0 vel 0 down 0 sy 0}
    variable scrollers
    array set scrollers {}
    variable btn
    array set btn {}
    variable flowKids
    array set flowKids {}
}

proc ui::px {k} { expr {int(round($ui::U * $k))} }

# Parent window path computed from the name (the widget may not exist yet).
proc ui::par {w} { string range $w 0 [expr {[string last . $w] - 1}] }

# ---- colours -----------------------------------------------------------
proc ui::rgb {c} {
    scan $c "#%2x%2x%2x" r g b
    list $r $g $b
}
proc ui::mix {c1 c2 t} {
    lassign [rgb $c1] r1 g1 b1
    lassign [rgb $c2] r2 g2 b2
    format "#%02x%02x%02x" [expr {int($r1 + ($r2 - $r1) * $t)}] \
        [expr {int($g1 + ($g2 - $g1) * $t)}] [expr {int($b1 + ($b2 - $b1) * $t)}]
}
proc ui::shade {c f} { mix $c #000000 $f }
# A bright accent colour made readable as small text on the current theme.
proc ui::ink {c} { expr {$::T(name) eq "light" ? [mix $c #000000 .55] : $c} }

# ---- fonts -------------------------------------------------------------
proc ui::fonts {} {
    variable U
    variable fscale
    set have [font families]
    set sans [dict get [font actual TkDefaultFont] -family]
    foreach c {"Inter" "SF Pro Text" "Segoe UI" "Roboto" "Noto Sans" "Cantarell" "Helvetica Neue"} { if {$c in $have} { set sans $c; break } }
    set mono [dict get [font actual TkFixedFont] -family]
    foreach c {"JetBrains Mono" "Cascadia Mono" "SF Mono" "Menlo" "Roboto Mono" "DejaVu Sans Mono"} { if {$c in $have} { set mono $c; break } }
    foreach {n sz wt fam} {
        title 7.4 bold sans   h1 5.8 bold sans   h2 4.7 bold sans
        body 4.2 normal sans  bodyb 4.2 bold sans small 3.4 normal sans
        smallb 3.4 bold sans  btn 4.3 bold sans  mono 3.35 normal mono
        monob 3.5 bold mono   monosm 2.9 normal mono num 9 bold sans
        tab 2.9 bold sans  bodyi 4.2 normal sans
    } {
        catch {font delete f.$n}
        font create f.$n -family [set $fam] -size -[expr {max(9, int(round($U * $sz * $fscale)))}] -weight $wt -slant [expr {$n eq "bodyi" ? "italic" : "roman"}]
    }
}

# ---- drawing helpers ---------------------------------------------------
proc ui::rrect {c x1 y1 x2 y2 r args} {
    set o [dict merge [dict create -fill "" -outline "" -width 0 -tags "" -dash ""] $args]
    if {[dict get $o -dash] ne ""} {
        # dashed outlines are only used for placeholders; plain polygon is fine there
        set pts [list [expr {$x1+$r}] $y1 [expr {$x2-$r}] $y1 $x2 $y1 $x2 [expr {$y1+$r}] $x2 [expr {$y2-$r}] \
            $x2 $y2 [expr {$x2-$r}] $y2 [expr {$x1+$r}] $y2 $x1 $y2 $x1 [expr {$y2-$r}] $x1 [expr {$y1+$r}] $x1 $y1]
        return [$c create polygon $pts -smooth 1 -fill [dict get $o -fill] -outline [dict get $o -outline] \
            -width [dict get $o -width] -dash [dict get $o -dash] -tags [dict get $o -tags]]
    }
    set line [dict get $o -outline]
    set bw [expr {$line ne "" ? max(1, int([dict get $o -width])) : 0}]
    aa::rrect $c $x1 $y1 $x2 $y2 $r [dict get $o -fill] $line $bw [dict get $o -tags]
}

# Anti-aliased icon image centred at cx,cy. s = size in pixels.
proc ui::icon {c name cx cy s color {tag ""}} {
    set px [expr {max(8, int(round($s)))}]
    $c create image [expr {int($cx)}] [expr {int($cy)}] -image [aa::icon $name $px $color] -tags $tag
}

# Anti-aliased filled circle (optionally with an outline band of width bw).
proc ui::circle {c cx cy r fill {outline ""} {bw 0} {tag ""}} {
    if {$outline ne "" && $bw > 0} {
        $c create image [expr {int($cx)}] [expr {int($cy)}] -image [aa::disc $outline [expr {int(2 * $r)}]] -tags $tag
        set r [expr {$r - $bw}]
    }
    if {$fill ne ""} {
        $c create image [expr {int($cx)}] [expr {int($cy)}] -image [aa::disc $fill [expr {max(2, int(2 * $r))}]] -tags $tag
    }
}

# Anti-aliased progress ring image centred at cx,cy.
proc ui::ring {c cx cy d t frac color track {tag ""}} {
    $c create image [expr {int($cx)}] [expr {int($cy)}] -image [aa::ring [expr {int($d)}] [expr {int($t)}] $frac $color $track] -tags $tag
}

# ---- buttons -------------------------------------------------------------
# styles: primary secondary success danger ghost
proc ui::btnColors {style disabled} {
    if {$disabled} { return [list $::T(surface2) [ui::shade $::T(surface2) .15] $::T(muted)] }
    switch $style {
        primary   { list $::T(primary) [ui::shade $::T(primary) .3] $::T(onprimary) }
        success   { list $::T(success) [ui::shade $::T(success) .3] #06241a }
        danger    { list $::T(error)   [ui::shade $::T(error) .3]   #ffffff }
        ghost     { list "" "" $::T(primary) }
        default   { list $::T(surface2) $::T(border) $::T(text) }
    }
}

proc ui::button {w text cmd args} {
    variable btn
    set o [dict create -style primary -height [px 13] -font f.btn -bg ""]
    set o [dict merge $o $args]
    set bg [dict get $o -bg]
    if {$bg eq ""} { set bg [[ui::par $w] cget -bg] }
    canvas $w -height [dict get $o -height] -width 10 -highlightthickness 0 -bd 0 -bg $bg -takefocus 0
    set btn($w) [dict create text $text cmd $cmd style [dict get $o -style] font [dict get $o -font] \
        disabled 0 pressed 0 bgc $bg]
    bind $w <Configure> [list ui::_btnDraw $w]
    bind $w <ButtonPress-1> [list ui::_btnPress $w 1]
    bind $w <ButtonRelease-1> [list ui::_btnRelease $w %x %y]
    bind $w <Destroy> [list unset -nocomplain ::ui::btn($w)]
    return $w
}
proc ui::btnSet {w args} {
    variable btn
    if {![info exists btn($w)]} return
    foreach {k v} $args {
        dict set btn($w) [string range $k 1 end] $v
    }
    _btnDraw $w
}
proc ui::_btnPress {w v} {
    variable btn
    if {![info exists btn($w)]} return
    set ::ui::drag(moved) 0
    if {[dict get $btn($w) disabled]} return
    dict set btn($w) pressed $v
    _btnDraw $w
}
proc ui::_btnRelease {w x y} {
    variable btn
    variable drag
    if {![info exists btn($w)]} return
    set was [dict get $btn($w) pressed]
    dict set btn($w) pressed 0
    _btnDraw $w
    if {!$was || [dict get $btn($w) disabled] || $drag(moved)} return
    if {$x < 0 || $y < 0 || $x > [winfo width $w] || $y > [winfo height $w]} return
    set cmd [dict get $btn($w) cmd]
    after idle [list uplevel #0 $cmd]
}
proc ui::_btnDraw {w} {
    variable btn
    if {![winfo exists $w] || ![info exists btn($w)]} return
    set d $btn($w)
    set W [winfo width $w]; set H [winfo height $w]
    if {$W < 8} return
    $w delete all
    $w configure -bg [dict get $d bgc]
    lassign [btnColors [dict get $d style] [dict get $d disabled]] face edge fg
    set depth [expr {$face eq "" ? 0 : max(3, [px 0.9])}]
    set off [expr {[dict get $d pressed] ? $depth : 0}]
    set r [expr {int($H * .3)}]
    if {$face ne ""} {
        if {$depth > $off} { rrect $w 0 $depth $W $H $r -fill $edge -outline "" }
        rrect $w 0 $off $W [expr {$H - $depth + $off}] $r -fill $face -outline ""
    }
    $w create text [expr {$W / 2}] [expr {($H - $depth) / 2 + $off}] -text [dict get $d text] \
        -fill $fg -font [dict get $d font] -width [expr {$W - 6}] -justify center
}

# A selectable option row / chip. States: normal selected correct wrong disabled
proc ui::option {w text cmd args} {
    variable btn
    set o [dict create -font f.body -fit 0 -state normal -align left -bg "" -pad [px 3.6]]
    set o [dict merge $o $args]
    set bg [dict get $o -bg]
    if {$bg eq ""} { set bg [[ui::par $w] cget -bg] }
    set font [dict get $o -font]
    if {[dict get $o -fit]} {
        set tw [font measure $font $text]
        canvas $w -height [expr {[font metrics $font -linespace] + [px 5.2]}] \
            -width [expr {$tw + 2 * [dict get $o -pad] + 4}]
    } else {
        canvas $w -height [px 14] -width 10
    }
    $w configure -highlightthickness 0 -bd 0 -bg $bg -takefocus 0
    set btn($w) [dict create text $text cmd $cmd font $font fit [dict get $o -fit] state [dict get $o -state] \
        align [dict get $o -align] bgc $bg pad [dict get $o -pad] pressed 0 disabled 0 style option]
    bind $w <Configure> [list ui::_optDraw $w]
    bind $w <ButtonPress-1> [list ui::_optPress $w]
    bind $w <ButtonRelease-1> [list ui::_optRelease $w %x %y]
    bind $w <Destroy> [list unset -nocomplain ::ui::btn($w)]
    return $w
}
proc ui::optSet {w state} {
    variable btn
    if {![info exists btn($w)]} return
    dict set btn($w) state $state
    _optDraw $w
}
proc ui::_optPress {w} {
    variable btn
    set ::ui::drag(moved) 0
    if {![info exists btn($w)]} return
    if {[dict get $btn($w) state] in {disabled correct wrong}} return
    dict set btn($w) pressed 1
    _optDraw $w
}
proc ui::_optRelease {w x y} {
    variable btn
    variable drag
    if {![info exists btn($w)]} return
    set was [dict get $btn($w) pressed]
    dict set btn($w) pressed 0
    _optDraw $w
    if {!$was || $drag(moved)} return
    if {$x < 0 || $y < 0 || $x > [winfo width $w] || $y > [winfo height $w]} return
    after idle [list uplevel #0 [dict get $btn($w) cmd]]
}
proc ui::_optDraw {w} {
    variable btn
    if {![winfo exists $w] || ![info exists btn($w)]} return
    set d $btn($w)
    set W [winfo width $w]; set H [winfo height $w]
    if {$W < 8} return
    $w delete all
    set st [dict get $d state]
    switch $st {
        selected { set fill [mix $::T(surface) $::T(primary) .16]; set line $::T(primary); set fg $::T(text) }
        correct  { set fill [mix $::T(surface) $::T(success) .2];  set line $::T(success); set fg $::T(text) }
        wrong    { set fill [mix $::T(surface) $::T(error) .2];    set line $::T(error);   set fg $::T(text) }
        disabled { set fill $::T(surface); set line $::T(border); set fg $::T(muted) }
        default  { set fill $::T(surface); set line $::T(border); set fg $::T(text) }
    }
    if {[dict get $d pressed]} { set fill [mix $fill $::T(primary) .12] }
    set pad [dict get $d pad]
    set font [dict get $d font]
    set anchor [expr {[dict get $d align] eq "center" ? "center" : "w"}]
    set tx [expr {$anchor eq "center" ? $W / 2 : $pad + 2}]
    set tid [$w create text $tx 0 -text [dict get $d text] -font $font -fill $fg -anchor $anchor \
        -width [expr {$W - 2 * $pad - 4}] -justify left]
    set bb [$w bbox $tid]
    set th [expr {[lindex $bb 3] - [lindex $bb 1]}]
    if {![dict get $d fit]} {
        set need [expr {max([px 14], $th + 2 * [px 3.4])}]
        if {abs($need - $H) > 1} { $w configure -height $need; set H $need }
    }
    $w delete $tid
    set r [expr {min(int($H * .3), [px 3.5])}]
    set lw [expr {max(2, [px 0.55])}]
    rrect $w 0 0 $W $H $r -fill $fill -outline $line -width $lw
    $w create text $tx [expr {$H / 2}] -text [dict get $d text] -font $font -fill $fg -anchor $anchor \
        -width [expr {$W - 2 * $pad - 4}] -justify left
}

# ---- cards -------------------------------------------------------------
# Returns the inner frame; pack the *outer* name returned by "ui::cardOuter".
proc ui::card {w args} {
    set o [dict create -fill $::T(surface) -line "" -pad [px 3.6] -r [px 3.8] -bg ""]
    set o [dict merge $o $args]
    set bg [dict get $o -bg]
    if {$bg eq ""} { set bg [[ui::par $w] cget -bg] }
    canvas $w -highlightthickness 0 -bd 0 -bg $bg -width 10 -height [expr {2 * [dict get $o -pad] + 6}]
    frame $w.f -bg [dict get $o -fill]
    $w create window [dict get $o -pad] [dict get $o -pad] -window $w.f -anchor nw -tags win
    set st [list $o]
    bind $w <Configure> [list ui::_cardLayout $w $o %w]
    bind $w.f <Configure> [list ui::_cardInner $w $o %h]
    return $w.f
}
proc ui::_cardLayout {w o W} {
    if {![winfo exists $w]} return
    set pad [dict get $o -pad]
    $w itemconfigure win -width [expr {$W - 2 * $pad}]
    _cardPaint $w $o
}
proc ui::_cardInner {w o h} {
    if {![winfo exists $w]} return
    set pad [dict get $o -pad]
    set want [expr {$h + 2 * $pad}]
    if {[$w cget -height] != $want} { $w configure -height $want }
    _cardPaint $w $o
}
proc ui::_cardPaint {w o} {
    set W [winfo width $w]; set H [winfo height $w]
    if {$W < 8} return
    $w delete bg
    set line [dict get $o -line]
    rrect $w 0 0 $W $H [dict get $o -r] \
        -fill [dict get $o -fill] -outline $line -width [expr {$line eq "" ? 0 : [px .35]}] -tags bg
    $w lower bg
}

# ---- text --------------------------------------------------------------
proc ui::_inline {s} {
    set out {}; set buf ""; set bold 0; set code 0; set ital 0
    set n [string length $s]
    for {set i 0} {$i < $n} {incr i} {
        set ch [string index $s $i]
        set nx [string index $s [expr {$i+1}]]
        set pv [string index $s [expr {$i-1}]]
        if {$ch eq "`"} {
            if {$buf ne ""} { lappend out $buf [_tags $bold $code $ital]; set buf "" }
            set code [expr {!$code}]; continue
        }
        if {!$code && $ch eq "*" && $nx eq "*"} {
            if {$buf ne ""} { lappend out $buf [_tags $bold $code $ital]; set buf "" }
            set bold [expr {!$bold}]; incr i; continue
        }
        if {!$code && $ch eq "*" && (($ital && $pv ne " " && $pv ne "") || (!$ital && $nx ne " " && $nx ne ""))} {
            if {$buf ne ""} { lappend out $buf [_tags $bold $code $ital]; set buf "" }
            set ital [expr {!$ital}]; continue
        }
        append buf $ch
    }
    if {$buf ne ""} { lappend out $buf [_tags $bold $code $ital] }
    return $out
}
proc ui::_tags {bold code {ital 0}} {
    set t {}
    if {$bold} { lappend t bold }
    if {$code} { lappend t ic }
    if {$ital} { lappend t ital }
    return $t
}

proc ui::_noInteract {t} { bindtags $t [list $t . all] }

proc ui::_fitText {f t} {
    if {![winfo exists $t]} return
    set px [$t count -update -ypixels 1.0 end]
    # a trailing newline never exists in our content; add a hair for descenders
    set want [expr {$px + 2}]
    if {[$f cget -height] != $want} { $f configure -height $want }
}

# Rich paragraph: **bold**, `code`, and lines beginning "- " as bullets.
proc ui::rich {w text args} {
    set o [dict create -bg $::T(bg) -fg $::T(text) -font f.body -mono f.mono -pad 0 -justify left]
    set o [dict merge $o $args]
    set bg [dict get $o -bg]
    frame $w -bg $bg -height 20
    pack propagate $w 0
    set t $w.t
    text $t -wrap word -bd 0 -highlightthickness 0 -bg $bg -fg [dict get $o -fg] \
        -font [dict get $o -font] -cursor arrow -padx 0 -pady 0 -spacing1 0 -spacing2 [px .8] \
        -spacing3 [px 1.2] -height 1 -takefocus 0 -insertwidth 0 -state normal
    pack $t -fill both -expand 1
    set f [dict get $o -font]
    $t tag configure bold -font f.bodyb
    $t tag configure ic -font [dict get $o -mono] -foreground $::T(c_var) -background [mix $bg $::T(primary) .13]
    $t tag configure ital -font f.bodyi
    $t tag configure center -justify center
    set lines [split $text \n]
    set n 0
    foreach ln $lines {
        if {$n} { $t insert end "\n" }
        incr n
        if {[string match "- *" $ln]} {
            $t insert end "  \u2022  " {} 
            set ln [string range $ln 2 end]
            $t tag configure hang -lmargin1 0 -lmargin2 [expr {[font measure $f "  \u2022  "]}]
            set base hang
        } else { set base {} }
        foreach {seg tags} [_inline $ln] {
            $t insert end $seg [concat $base $tags]
        }
        if {$base ne ""} { $t tag add hang "end-1c linestart" "end-1c" }
    }
    if {[dict get $o -justify] eq "center"} { $t tag add center 1.0 end }
    $t configure -state disabled
    _noInteract $t
    bind $t <Configure> [list ui::_fitText $w $t]
    return $w
}

# ---- syntax highlighting --------------------------------------------------
variable ui::keywords {
    if else elseif while for foreach proc return set expr switch break continue
    catch try finally error namespace variable global upvar uplevel apply lambda
    coroutine yield class method constructor destructor oo::class oo::object
    lmap dict array string list incr append puts
}
proc ui::highlight {t} {
    variable keywords
    foreach tg {cmd kw var str num cmt punct out} {
        $t tag configure $tg -foreground $::T(c_$tg)
    }
    $t tag configure cmt -font [$t cget -font]
    set txt [$t get 1.0 end-1c]
    set ln 0
    foreach line [split $txt \n] {
        incr ln
        # command word at the start of a line (or after [ or ;)
        set pos 0
        while {[regexp -indices -start $pos {(?:^\s*|\[|;\s*)([A-Za-z_:][\w:]*)} $line all grp]} {
            lassign $grp a b
            set word [string range $line $a $b]
            $t tag add [expr {$word in $keywords ? "kw" : "cmd"}] $ln.$a $ln.[expr {$b+1}]
            set pos [expr {$b + 1}]
        }
        set pos 0
        while {[regexp -indices -start $pos {\$\{[^\}]*\}|\$[\w:]+(\([^)]*\))?} $line m]} {
            lassign $m a b
            $t tag add var $ln.$a $ln.[expr {$b+1}]
            set pos [expr {$b + 1}]
        }
        set pos 0
        while {[regexp -indices -start $pos {\m\d+(\.\d+)?\M} $line m]} {
            lassign $m a b
            $t tag add num $ln.$a $ln.[expr {$b+1}]
            set pos [expr {$b + 1}]
        }
        set pos 0
        while {[regexp -indices -start $pos {[\[\]\{\};]} $line m]} {
            lassign $m a b
            $t tag add punct $ln.$a $ln.[expr {$b+1}]
            set pos [expr {$b + 1}]
        }
        set pos 0
        while {[regexp -indices -start $pos {"([^"\\]|\\.)*"} $line m]} {
            lassign $m a b
            $t tag add str $ln.$a $ln.[expr {$b+1}]
            set pos [expr {$b + 1}]
        }
        if {[regexp -indices {^\s*#.*|;\s*#.*} $line m]} {
            lassign $m a b
            set a [expr {[string first # $line $a]}]
            $t tag add cmt $ln.$a $ln.end
        }
    }
    $t tag raise var str
    $t tag raise cmt
}

# A read-only syntax-highlighted code block.
proc ui::code {w code args} {
    set o [dict create -bg $::T(codebg) -title "" -font f.mono -outer $::T(bg)]
    set o [dict merge $o $args]
    set outer [dict get $o -outer]
    set inner [card $w -fill [dict get $o -bg] -pad [px 3] -r [px 3] -bg $outer]
    if {[dict get $o -title] ne ""} {
        label $inner.t -text [dict get $o -title] -font f.smallb -fg $::T(muted) -bg [dict get $o -bg] -anchor w
        pack $inner.t -fill x -pady [list 0 [px 1]]
    }
    set code [string trim $code "\n"]
    set f $inner.b
    frame $f -bg [dict get $o -bg] -height 20
    pack propagate $f 0
    text $f.t -wrap word -bd 0 -highlightthickness 0 -bg [dict get $o -bg] -fg $::T(text) \
        -font [dict get $o -font] -cursor arrow -padx 0 -pady 0 -spacing1 0 -spacing2 [px .4] -spacing3 [px .4] \
        -height 1 -takefocus 0 -insertwidth 0
    pack $f.t -fill both -expand 1
    pack $f -fill x
    $f.t insert end $code
    highlight $f.t
    $f.t configure -state disabled
    _noInteract $f.t
    bind $f.t <Configure> [list ui::_fitText $f $f.t]
    return $w
}

# Program output block.
proc ui::output {w text args} {
    set o [dict create -outer $::T(bg)]
    set o [dict merge $o $args]
    set bg [mix $::T(codebg) $::T(info) .08]
    set inner [card $w -fill $bg -pad [px 3] -r [px 3] -bg [dict get $o -outer]]
    label $inner.t -text "OUTPUT" -font f.smallb -fg $::T(c_out) -bg $bg -anchor w
    pack $inner.t -fill x -pady [list 0 [px 1]]
    set f $inner.b
    frame $f -bg $bg -height 20
    pack propagate $f 0
    text $f.t -wrap word -bd 0 -highlightthickness 0 -bg $bg -fg $::T(text) -font f.mono \
        -cursor arrow -padx 0 -pady 0 -spacing2 [px .4] -height 1 -takefocus 0 -insertwidth 0
    pack $f.t -fill both -expand 1
    pack $f -fill x
    $f.t insert end [string trimright $text "\n"]
    $f.t configure -state disabled
    _noInteract $f.t
    bind $f.t <Configure> [list ui::_fitText $f $f.t]
    return $w
}

# ---- scrolling by dragging (no wheel on a phone) -------------------------
proc ui::scroll {w} {
    variable scrollers
    frame $w -bg $::T(bg)
    canvas $w.c -bg $::T(bg) -highlightthickness 0 -bd 0 -yscrollincrement 1
    pack $w.c -fill both -expand 1
    frame $w.c.f -bg $::T(bg)
    $w.c create window 0 0 -window $w.c.f -anchor nw -tags win
    bind $w.c.f <Configure> [list ui::_scrollRegion $w.c]
    bind $w.c <Configure> [list ui::_scrollWidth $w.c %w]
    set scrollers($w.c) 1
    bind $w.c <Destroy> [list unset -nocomplain ::ui::scrollers($w.c)]
    # mouse wheel for desktop testing
    bind $w.c <MouseWheel> [list $w.c yview scroll [expr {-1}] units]
    bind $w.c <Button-4> [list $w.c yview scroll -60 units]
    bind $w.c <Button-5> [list $w.c yview scroll 60 units]
    return $w.c.f
}
proc ui::_scrollWidth {c W} {
    $c itemconfigure win -width $W
    _scrollRegion $c
}
proc ui::_scrollRegion {c} {
    if {![winfo exists $c]} return
    set h [winfo reqheight $c.f]
    set ch [winfo height $c]
    $c configure -scrollregion [list 0 0 1 [expr {max($h, $ch)}]]
    if {$h <= $ch} { $c yview moveto 0 }
}
proc ui::scrollTo {c frac} {
    update idletasks
    _scrollRegion $c
    $c yview moveto $frac
}
proc ui::dragify {w} {
    if {![winfo exists $w]} return
    if {"Drag" ni [bindtags $w]} { bindtags $w [concat [bindtags $w] Drag] }
    foreach k [winfo children $w] { dragify $k }
}
proc ui::_findScroller {w} {
    variable scrollers
    while {$w ne "" && $w ne "."} {
        foreach k [winfo children $w] { if {[info exists scrollers($k)]} { return $k } }
        set w [ui::par $w]
    }
    return ""
}
proc ui::_dragStart {W X Y {isDrag 0}} {
    variable drag
    set drag(moved) $isDrag
    set drag(down) 1
    set drag(y) $Y
    set drag(sy) $Y
    set drag(vel) 0
    set drag(acc) 0
    set drag(t) [clock milliseconds]
    set drag(canvas) [_findScroller $W]
    if {[info exists drag(anim)]} { after cancel $drag(anim); unset drag(anim) }
}
# Motion events are coalesced: we only remember how far the finger moved and
# apply it once per idle cycle, so a slow renderer never builds a backlog.
proc ui::_dragMove {X Y} {
    variable drag
    if {!$drag(down) || $drag(canvas) eq "" || ![winfo exists $drag(canvas)]} return
    if {abs($Y - $drag(sy)) > [px 2.5]} { set drag(moved) 1 }
    if {!$drag(moved)} return
    set now [clock milliseconds]
    set dy [expr {$Y - $drag(y)}]
    set dt [expr {max(1, $now - $drag(t))}]
    set drag(y) $Y
    set drag(t) $now
    set drag(vel) [expr {$drag(vel) * .6 + ($dy / double($dt)) * .4}]   ;# px per ms
    set drag(acc) [expr {$drag(acc) + $dy}]
    if {![info exists drag(job)]} { set drag(job) [after idle ui::_dragApply] }
}
proc ui::_dragApply {} {
    variable drag
    unset -nocomplain drag(job)
    if {$drag(canvas) eq "" || ![winfo exists $drag(canvas)]} return
    set d $drag(acc)
    set drag(acc) 0
    if {$d != 0} { $drag(canvas) yview scroll [expr {-$d}] units }
}
proc ui::_dragEnd {} {
    variable drag
    set drag(down) 0
    if {[info exists drag(job)]} { after cancel $drag(job); unset drag(job); _dragApply }
    if {$drag(moved) && abs($drag(vel)) > 0.15 && $drag(canvas) ne ""} {
        set drag(t) [clock milliseconds]
        set drag(anim) [after 30 ui::_inertia]
    }
}
# time-based so it feels the same whatever the frame rate
proc ui::_inertia {} {
    variable drag
    unset -nocomplain drag(anim)
    if {$drag(down) || $drag(canvas) eq "" || ![winfo exists $drag(canvas)]} return
    set now [clock milliseconds]
    set dt [expr {min(100, $now - $drag(t))}]
    set drag(t) $now
    set drag(vel) [expr {$drag(vel) * pow(0.994, $dt)}]
    if {abs($drag(vel)) < 0.03} return
    $drag(canvas) yview scroll [expr {int(round(-$drag(vel) * $dt))}] units
    set drag(anim) [after 30 ui::_inertia]
}
bind Drag <ButtonPress-1>   {ui::_dragStart %W %X %Y}
bind Drag <B1-Motion>       {ui::_dragMove %X %Y}
bind Drag <ButtonRelease-1> {ui::_dragEnd}
# AndroWish/SDL turns a touch-drag into a MIDDLE-button drag
bind Drag <ButtonPress-2>   {ui::_dragStart %W %X %Y 1}
bind Drag <B2-Motion>       {ui::_dragMove %X %Y}
bind Drag <ButtonRelease-2> {ui::_dragEnd}

# ---- flow layout for chips ----------------------------------------------
proc ui::flow {w} {
    variable flowKids
    frame $w -bg [[ui::par $w] cget -bg] -height 10
    set flowKids($w) {}
    bind $w <Configure> [list ui::_flowLayout $w]
    return $w
}
proc ui::flowAdd {w kid} {
    variable flowKids
    lappend flowKids($w) $kid
    _flowLayout $w
}
proc ui::flowClear {w} {
    variable flowKids
    foreach k $flowKids($w) { destroy $k }
    set flowKids($w) {}
    $w configure -height 4
}
proc ui::_flowLayout {w} {
    variable flowKids
    if {![winfo exists $w] || ![info exists flowKids($w)]} return
    set W [winfo width $w]
    if {$W < 20} return
    set gap [px 2]
    set x 0; set y 0; set rowH 0
    foreach k $flowKids($w) {
        if {![winfo exists $k]} continue
        set kw [$k cget -width]; set kh [$k cget -height]
        if {$x > 0 && $x + $kw > $W} { set x 0; incr y [expr {$rowH + $gap}]; set rowH 0 }
        place $k -x $x -y $y
        incr x [expr {$kw + $gap}]
        set rowH [expr {max($rowH, $kh)}]
    }
    set want [expr {$y + $rowH + 2}]
    if {[$w cget -height] != $want} { $w configure -height $want }
}

# ---- progress bar -----------------------------------------------------------
proc ui::progress {w frac args} {
    set o [dict create -color $::T(success) -height [px 3.2] -track $::T(surface2)]
    set o [dict merge $o $args]
    if {![winfo exists $w]} {
        canvas $w -height [dict get $o -height] -highlightthickness 0 -bd 0 -bg [[ui::par $w] cget -bg]
        bind $w <Configure> [list ui::_progDraw $w]
    }
    set ::ui::prog($w) [list $frac $o]
    _progDraw $w
    return $w
}
proc ui::_progDraw {w} {
    if {![winfo exists $w] || ![info exists ::ui::prog($w)]} return
    lassign $::ui::prog($w) frac o
    set W [winfo width $w]; set H [winfo height $w]
    if {$W < 8} return
    $w delete all
    set r [expr {$H / 2}]
    rrect $w 0 0 $W $H $r -fill [dict get $o -track] -outline ""
    set fw [expr {int($W * max(0, min(1, $frac)))}]
    if {$fw > $H} {
        rrect $w 0 0 $fw $H $r -fill [dict get $o -color] -outline ""
        $w create line [expr {$r}] [expr {$H*.28}] [expr {max($r+1,$fw-$r)}] [expr {$H*.28}] \
            -fill [mix [dict get $o -color] #ffffff .35] -width [expr {max(1,$H/5)}] -capstyle round
    } elseif {$fw > 3} {
        rrect $w 0 0 $H $H $r -fill [dict get $o -color] -outline ""
    }
}

# ---- toast / confirm ----------------------------------------------------------
proc ui::toast {msg} {
    catch {destroy .toast}
    set f [frame .toast -bg $::T(text)]
    label $f.l -text $msg -font f.small -bg $::T(text) -fg $::T(bg) -padx [px 4] -pady [px 2.4] -wraplength [expr {[winfo width .] - [px 20]}]
    pack $f.l
    place $f -relx .5 -rely .86 -anchor center
    after 2000 [list catch [list destroy $f]]
}

proc ui::confirm {title msg yesText cmd} {
    catch {destroy .dlg}
    frame .dlg -bg [mix $::T(bg) #000000 .55]
    place .dlg -x 0 -y 0 -relwidth 1 -relheight 1
    bind .dlg <ButtonPress-1> {}
    set c [card .dlg.c -fill $::T(surface) -line $::T(border)]
    place .dlg.c -relx .5 -rely .5 -anchor center -relwidth .86
    label $c.t -text $title -font f.h2 -bg $::T(surface) -fg $::T(text) -anchor w
    pack $c.t -fill x
    rich $c.m $msg -bg $::T(surface)
    pack $c.m -fill x -pady [px 2.5]
    frame $c.b -bg $::T(surface)
    pack $c.b -fill x
    button $c.b.y $yesText [list ui::_confirmGo $cmd] -style danger -height [px 11]
    button $c.b.n "Cancel" {destroy .dlg} -style secondary -height [px 11]
    pack $c.b.y -fill x -pady [list 0 [px 2]]
    pack $c.b.n -fill x
    raise .dlg
}
proc ui::_confirmGo {cmd} { destroy .dlg; uplevel #0 $cmd }

# ---- symbol keypad for typing code on a phone -------------------------------------
proc ui::symbols {w target} {
    frame $w -bg $::T(bg)
    set syms {\{ \} [ ] $ \" ( ) ; # \\ = + - * / < > ! & | : Tab}
    set per 9
    set i 0
    foreach s $syms {
        if {$i % $per == 0} {
            set row $w.r[expr {$i / $per}]
            frame $row -bg $::T(bg)
            pack $row -fill x -pady [px .6]
        }
        set show [expr {$s eq "Tab" ? "tab" : $s}]
        set ins  [expr {$s eq "Tab" ? "    " : $s}]
        set b $row.b$i
        canvas $b -height [px 9.5] -width 10 -highlightthickness 0 -bd 0 -bg $::T(bg)
        set ::ui::symCmd($b) [list $target $ins $show]
        bind $b <Configure> [list ui::_symDraw $b]
        bind $b <ButtonPress-1> [list ui::_symPress $b 1]
        bind $b <ButtonRelease-1> [list ui::_symRelease $b]
        pack $b -side left -expand 1 -fill x -padx [px .4]
        incr i
    }
    return $w
}
proc ui::_symDraw {b} {
    if {![winfo exists $b]} return
    lassign $::ui::symCmd($b) tgt ins show
    set W [winfo width $b]; set H [winfo height $b]
    $b delete all
    set fill [expr {[info exists ::ui::symDown($b)] ? [mix $::T(surface2) $::T(primary) .3] : $::T(surface2)}]
    rrect $b 0 0 $W $H [px 1.6] -fill $fill -outline ""
    $b create text [expr {$W/2}] [expr {$H/2}] -text $show -font f.monob -fill $::T(text)
}
proc ui::_symPress {b v} { set ::ui::symDown($b) 1; set ::ui::drag(moved) 0; _symDraw $b }
proc ui::_symRelease {b} {
    unset -nocomplain ::ui::symDown($b)
    _symDraw $b
    lassign $::ui::symCmd($b) tgt ins show
    if {[winfo exists $tgt]} { $tgt insert insert $ins; _editorColor $tgt; focus $tgt }
}

# a styled editable code box
proc ui::editor {w text args} {
    set o [dict create -height 8]
    set o [dict merge $o $args]
    frame $w -bg $::T(border)
    text $w.t -wrap none -bd 0 -highlightthickness 0 -bg $::T(codebg) -fg $::T(text) -font f.mono \
        -insertbackground $::T(primary) -insertwidth [px .6] -padx [px 2.5] -pady [px 2.5] \
        -height [dict get $o -height] -undo 1 -selectbackground [mix $::T(codebg) $::T(primary) .45] \
        -spacing1 [px .3] -spacing3 [px .3] -wrap char
    pack $w.t -fill both -expand 1 -padx 1 -pady 1
    $w.t insert 1.0 $text
    bind $w.t <KeyRelease> [list ui::_editorColor $w.t]
    bind $w.t <FocusIn> {catch {sdltk screenkeyboard 1}}
    _editorColor $w.t
    return $w
}
proc ui::_editorColor {t} {
    foreach tg {cmd kw var str num cmt punct} { $t tag remove $tg 1.0 end }
    set sel [$t cget -font]
    set keep [$t get 1.0 end-1c]
    highlight $t
}
