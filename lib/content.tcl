# content.tcl - registry for the curriculum (which lives in content/*.tcl).
#
# content::unit   N TITLE BLURB COLOR
# content::lesson ID UNIT TITLE BLURB SPEC
#   SPEC is a dict with keys:
#     pages  - list of {head TEXT body {type content type content ...}}
#              types: p (paragraph, **bold** and `code` allowed), code, out,
#                     tip, warn, h
#     ex     - list of exercise dicts (kind mc|predict|blank|order|type|code)
#     cards  - list of {front back ?code-on-front?}
namespace eval content {
    variable units {}
    variable order {}
    variable L
    array set L {}

    proc unit {n title blurb color} {
        variable units
        lappend units [dict create n $n title $title blurb $blurb color $color]
    }

    proc lesson {id unitN title blurb spec} {
        variable L
        variable order
        set exs {}
        set k 0
        foreach e [dict get $spec ex] {
            incr k
            dict set e id $id.e$k
            lappend exs $e
        }
        set cards {}
        set k 0
        foreach c [dict get $spec cards] {
            incr k
            lappend cards [dict create id $id.c$k front [lindex $c 0] back [lindex $c 1] \
                code [expr {[llength $c] > 2 ? [lindex $c 2] : ""}]]
        }
        set L($id) [dict create id $id unit $unitN title $title blurb $blurb \
            pages [dict get $spec pages] ex $exs cards $cards]
        lappend order $id
    }

    # Append exercises to an already-registered lesson (progress ids stay stable).
    proc addEx {id args} {
        variable L
        set l $L($id)
        set exs [dict get $l ex]
        set k [llength $exs]
        foreach e $args {
            incr k
            dict set e id $id.e$k
            lappend exs $e
        }
        dict set l ex $exs
        set L($id) $l
    }

    proc ids {} { variable order; return $order }
    proc get {id} { variable L; return $L($id) }
    proc unitInfo {n} {
        variable units
        foreach u $units { if {[dict get $u n] == $n} { return $u } }
    }
    proc lessonsOf {n} {
        variable L
        set r {}
        foreach id [ids] { if {[dict get $L($id) unit] == $n} { lappend r $id } }
        return $r
    }
    proc nextAfter {id} {
        set o [ids]
        set i [lsearch -exact $o $id]
        lindex $o [expr {$i + 1}]
    }
    proc minutes {id} {
        set l [get $id]
        expr {max(3, int(([llength [dict get $l pages]] * 45 + [llength [dict get $l ex]] * 25) / 60.0 + 0.5))}
    }
    proc allEx {} {
        set r {}
        foreach id [ids] { foreach e [dict get [get $id] ex] { lappend r $e } }
        return $r
    }
    # exercise by id
    proc exById {eid} {
        set lid [join [lrange [split $eid .] 0 end-1] .]
        foreach e [dict get [get $lid] ex] { if {[dict get $e id] eq $eid} { return $e } }
        error "no such exercise $eid"
    }
    proc cardById {cid} {
        set lid [join [lrange [split $cid .] 0 end-1] .]
        foreach c [dict get [get $lid] cards] { if {[dict get $c id] eq $cid} { return $c } }
        error "no such card $cid"
    }

    # Text shown for the "answer" of an exercise (used for flashcards from misses).
    proc answerText {e} {
        switch [dict get $e kind] {
            mc - predict { return [lindex [dict get $e choices] [dict get $e ans]] }
            type         { return [lindex [dict get $e accept] 0] }
            default      { return "" }
        }
    }

    # ---- verification --------------------------------------------------
    proc fill {code answers} {
        set parts [split [string map [list ___ \x01] $code] \x01]
        set out [lindex $parts 0]
        set i 0
        foreach a $answers {
            append out $a [lindex $parts [incr i]]
        }
        return $out
    }

    proc trimOut {s} { string trimright $s "\n" }
    # NB: not an expr ternary - expr would turn the string 007 into the number 7.
    proc got {e r} {
        if {[dict exists $e res]} { return [dict get $r result] }
        return [trimOut [dict get $r out]]
    }

    proc check {} {
        variable L
        set problems {}
        set seen {}
        foreach id [ids] {
            set l $L($id)
            if {[llength [dict get $l pages]] < 1} { lappend problems "$id: no pages" }
            if {[llength [dict get $l ex]] < 4}    { lappend problems "$id: fewer than 4 exercises" }
            if {[llength [dict get $l cards]] < 2} { lappend problems "$id: fewer than 2 cards" }
            foreach p [dict get $l pages] {
                if {![dict exists $p head] || ![dict exists $p body]} { lappend problems "$id: bad page" ; continue }
                foreach pp [checkPage $id $p] { lappend problems $pp }
                foreach {t c} [dict get $p body] {
                    if {$t ni {p code show out tip warn h}} { lappend problems "$id: bad block type $t" }
                }
            }
            foreach e [dict get $l ex] {
                set eid [dict get $e id]
                if {[catch {checkEx $e} msg]} { lappend problems "$eid: $msg" }
            }
        }
        return $problems
    }

    # Run every `code` block on a page (cumulatively, so procs defined earlier
    # are available) and compare with the `out` block that follows it.
    proc checkPage {id p} {
        set probs {}
        set prefix ""
        set blocks [dict get $p body]
        set n [expr {[llength $blocks] / 2}]
        for {set i 0} {$i < $n} {incr i} {
            set t [lindex $blocks [expr {2 * $i}]]
            set c [lindex $blocks [expr {2 * $i + 1}]]
            if {$t ne "code"} continue
            set exp ""; set hasOut 0
            if {$i + 1 < $n && [lindex $blocks [expr {2 * ($i + 1)}]] eq "out"} {
                set hasOut 1
                set exp [lindex $blocks [expr {2 * ($i + 1) + 1}]]
            }
            set r [sandbox::run "$prefix\nset ::__out {}\n$c"]
            set got [trimOut [dict get $r out]]
            set head [string range [string map [list \n { }] $c] 0 40]
            if {$hasOut} {
                if {[dict get $r ok]} {
                    if {$got ne [trimOut $exp]} { lappend probs "$id page '[dict get $p head]': `$head` printed {$got} but page says {[trimOut $exp]}" }
                    append prefix $c "\n"
                } else {
                    if {[dict get $r err] ne [trimOut $exp]} { lappend probs "$id page '[dict get $p head]': `$head` failed with {[dict get $r err]} but page says {[trimOut $exp]}" }
                }
            } else {
                if {![dict get $r ok]} { lappend probs "$id page '[dict get $p head]': `$head` errored: [dict get $r err]" } else { append prefix $c "\n" }
            }
        }
        return $probs
    }

    proc checkEx {e} {
        set kind [dict get $e kind]
        switch $kind {
            mc {
                set ch [dict get $e choices]
                if {[llength $ch] < 2 || [llength $ch] > 5} { error "choice count" }
                if {[llength [lsort -unique $ch]] != [llength $ch]} { error "duplicate choices" }
                set a [dict get $e ans]
                if {![string is integer -strict $a] || $a < 0 || $a >= [llength $ch]} { error "bad ans" }
                dict get $e q; dict get $e why
            }
            predict {
                set ch [dict get $e choices]
                if {[llength [lsort -unique $ch]] != [llength $ch]} { error "duplicate choices" }
                set a [dict get $e ans]
                if {$a < 0 || $a >= [llength $ch]} { error "bad ans" }
                set r [sandbox::run [dict get $e code]]
                if {![dict get $r ok]} { error "code failed: [dict get $r err]" }
                set got [got $e $r]
                if {$got ne [lindex $ch $a]} { error "code gives {$got} but answer is {[lindex $ch $a]}" }
                dict get $e why
            }
            blank {
                set code [dict get $e code]
                set ans [dict get $e answers]
                set n [expr {[llength [split [string map [list ___ \x01] $code] \x01]] - 1}]
                if {$n != [llength $ans]} { error "$n blanks but [llength $ans] answers" }
                set r [sandbox::run [fill $code $ans]]
                if {![dict get $r ok]} { error "filled code failed: [dict get $r err]" }
                set got [got $e $r]
                if {$got ne [dict get $e out]} { error "filled code gives {$got}, expected {[dict get $e out]}" }
                dict get $e why
            }
            order {
                set lines [dict get $e lines]
                set r [sandbox::run [join $lines \n]]
                if {![dict get $r ok]} { error "ordered code failed: [dict get $r err]" }
                set got [got $e $r]
                if {$got ne [dict get $e out]} { error "ordered code gives {$got}, expected {[dict get $e out]}" }
                if {[llength [lsort -unique $lines]] != [llength $lines]} { error "duplicate lines (ambiguous)" }
                dict get $e why
            }
            type {
                if {[llength [dict get $e accept]] < 1} { error "no accepted answers" }
                if {[dict exists $e calc]} {
                    set r [sandbox::run [dict get $e calc]]
                    if {![dict get $r ok]} { error "calc failed" }
                    set got [got $e $r]
                    if {$got ni [dict get $e accept]} { error "calc gives {$got} not in accept" }
                }
                dict get $e q; dict get $e why
            }
            code {
                set tests [expr {[dict exists $e tests] ? [dict get $e tests] : {}}]
                set wantOut [dict exists $e out]
                if {[llength $tests] == 0 && !$wantOut} { error "code exercise needs tests or out" }
                set thens {}
                foreach {script exp} $tests { lappend thens $script }
                set r [sandbox::run [dict get $e solution] -then $thens]
                if {![dict get $r ok]} { error "solution errors: [dict get $r err]" }
                set i 0
                foreach {script exp} $tests {
                    set got [lindex [dict get $r thens] $i]
                    if {$got ne $exp} { error "solution fails test {$script}: got {$got} want {$exp}" }
                    incr i
                }
                if {$wantOut && [trimOut [dict get $r out]] ne [dict get $e out]} {
                    error "solution prints {[trimOut [dict get $r out]]} want {[dict get $e out]}"
                }
                # the starter must NOT already pass
                set r2 [sandbox::run [dict get $e starter] -then $thens]
                if {[dict get $r2 ok]} {
                    set allpass 1; set i 0
                    foreach {script exp} $tests {
                        if {[lindex [dict get $r2 thens] $i] ne $exp} { set allpass 0 }
                        incr i
                    }
                    if {$wantOut && [trimOut [dict get $r2 out]] ne [dict get $e out]} { set allpass 0 }
                    if {$allpass} { error "starter already passes" }
                }
                dict get $e prompt; dict get $e why
            }
            default { error "unknown kind $kind" }
        }
    }
}

namespace eval content {
    # Flashcard made from a missed exercise: card id "x.<exercise id>".
    proc cardFromEx {e} {
        set kind [dict get $e kind]
        switch $kind {
            mc {
                set front [dict get $e q]
                set code [expr {[dict exists $e code] ? [dict get $e code] : ""}]
            }
            predict {
                set front "What does this print?"
                set code [dict get $e code]
            }
            type {
                set front [dict get $e q]
                set code [expr {[dict exists $e code] ? [dict get $e code] : ""}]
            }
            default { return "" }
        }
        set back "**[answerText $e]**\n[dict get $e why]"
        dict create id x.[dict get $e id] front $front back $back code $code
    }
    proc anyCard {cid} {
        if {[string match x.* $cid]} {
            return [cardFromEx [exById [string range $cid 2 end]]]
        }
        cardById $cid
    }
}
