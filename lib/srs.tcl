# srs.tcl - SM-2 style spaced-repetition scheduler.
# A card state is a dict: ease ivl reps lapses due seen
# Grades: 0 Again, 1 Hard, 2 Good, 3 Easy.   Intervals are whole days.
namespace eval srs {
    proc new {} {
        dict create ease 2.5 ivl 0 reps 0 lapses 0 due [util::today] seen 0
    }

    # Returns the updated card dict.
    proc grade {card g} {
        set today [util::today]
        set ease [dict get $card ease]
        set ivl  [dict get $card ivl]
        set reps [dict get $card reps]
        set lap  [dict get $card lapses]
        if {$g == 0} {
            incr lap
            set reps 0
            set ivl 0
            set ease [expr {max(1.3, $ease - 0.2)}]
            set due $today
        } else {
            if {$reps == 0} {
                set ivl [lindex {0 1 1 3} $g]
            } elseif {$reps == 1} {
                set ivl [lindex {0 2 3 5} $g]
            } else {
                switch $g {
                    1 { set n [expr {$ivl * 1.2}];            set ease [expr {max(1.3, $ease - 0.15)}] }
                    2 { set n [expr {$ivl * $ease}] }
                    3 { set n [expr {$ivl * $ease * 1.3}];    set ease [expr {$ease + 0.15}] }
                }
                set ivl [expr {max($ivl + 1, int(round($n)))}]
            }
            incr reps
            set due [expr {$today + $ivl}]
        }
        dict create ease $ease ivl $ivl reps $reps lapses $lap due $due seen 1
    }

    # Human label for the interval a grade would produce, e.g. "1d", "3w".
    proc preview {card g} {
        if {$g == 0} { return "<10m" }
        set n [dict get [grade $card $g] ivl]
        if {$n < 30}  { return ${n}d }
        if {$n < 365} { return [expr {int(round($n / 30.0))}]mo }
        return [format %.1fy [expr {$n / 365.0}]]
    }

    proc isMature {card} { expr {[dict get $card ivl] >= 21} }

    proc add {id} {
        if {![dict exists $::state cards $id]} {
            dict set ::state cards $id [new]
            return 1
        }
        return 0
    }
    proc isNew {card} { expr {![dict get $card seen]} }

    # Cards due today (reviews first, then up to the daily new-card allowance).
    proc dueList {{newLimit 12}} {
        set today [util::today]
        lassign [dict get $::state newToday] nd nc
        if {$nd != $today} { set nc 0 }
        set allow [expr {max(0, $newLimit - $nc)}]
        set rev {}; set fresh {}
        dict for {id c} [dict get $::state cards] {
            if {[dict get $c due] > $today} continue
            if {[isNew $c]} { lappend fresh $id } else { lappend rev $id }
        }
        set rev [lsort -command [list apply {{a b} {
            expr {[dict get $::state cards $a due] - [dict get $::state cards $b due]}
        }}] $rev]
        concat $rev [lrange [util::shuffle $fresh] 0 [expr {$allow - 1}]]
    }
    proc noteNewIntroduced {} {
        set today [util::today]
        lassign [dict get $::state newToday] nd nc
        if {$nd != $today} { set nc 0 }
        dict set ::state newToday [list $today [expr {$nc + 1}]]
    }
    proc counts {} {
        set today [util::today]
        set due 0; set new 0; set mature 0; set young 0; set total 0
        dict for {id c} [dict get $::state cards] {
            incr total
            if {[isNew $c]} { incr new; continue }
            if {[isMature $c]} { incr mature } else { incr young }
            if {[dict get $c due] <= $today} { incr due }
        }
        dict create total $total due $due new $new mature $mature young $young
    }
}
