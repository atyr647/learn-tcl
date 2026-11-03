# util.tcl - small helpers shared by everything (no Tk needed)
namespace eval util {
    variable todayOverride ""

    # Whole-day number of the *local* calendar date (days since 1970-01-01).
    proc today {} {
        variable todayOverride
        if {$todayOverride ne ""} { return $todayOverride }
        set d [clock format [clock seconds] -format %Y-%m-%d]
        expr {[clock scan $d -format %Y-%m-%d -timezone :UTC] / 86400}
    }
    proc dayName {n} { clock format [expr {$n * 86400}] -format %a -timezone :UTC }
    proc dayDate {n} { clock format [expr {$n * 86400}] -format %Y-%m-%d -timezone :UTC }

    proc shuffle {list} {
        set n [llength $list]
        for {set i [expr {$n - 1}]} {$i > 0} {incr i -1} {
            set j [expr {int(rand() * ($i + 1))}]
            set t [lindex $list $i]
            lset list $i [lindex $list $j]
            lset list $j $t
        }
        return $list
    }
    proc clamp {x lo hi} { expr {$x < $lo ? $lo : ($x > $hi ? $hi : $x)} }

    # Collapse runs of whitespace, trim. Used when comparing typed answers.
    proc norm {s} { regsub -all {\s+} [string trim $s] " " }

    proc plural {n word {many ""}} {
        if {$many eq ""} { set many ${word}s }
        expr {$n == 1 ? "$n $word" : "$n $many"}
    }
}
