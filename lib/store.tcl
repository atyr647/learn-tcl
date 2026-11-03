# store.tcl - persistent learner state, kept as one Tcl dict in a file.
namespace eval store {
    variable path ""
    variable dir ""
    variable dirty 0

    proc defaults {} {
        dict create xp 0 streak 0 best 0 lastday 0 \
            daily {} lessons {} cards {} exstats {} newToday {0 0} \
            settings {theme dark goal 50 unlockAll 0 textScale 1.0} \
            playground "" version 1
    }

    # Pick the first writable directory from the candidates.
    proc chooseDir {} {
        set cands {}
        if {[info exists ::env(LEARNTCL_HOME)]} { lappend cands $::env(LEARNTCL_HOME) }
        if {[llength [info commands borg]]} {
            foreach what {files internal} {
                if {![catch {borg specialdir $what} d]} { lappend cands $d }
            }
        }
        if {[info exists ::env(HOME)]}   { lappend cands [file join $::env(HOME) .learn-tcl] }
        if {[info exists ::env(TMPDIR)]} { lappend cands [file join $::env(TMPDIR) learn-tcl] }
        lappend cands [file join [pwd] .learn-tcl] /tmp/learn-tcl
        foreach d $cands {
            if {![catch {file mkdir $d; set f [file join $d .w]; set h [open $f w]; close $h; file delete $f}]} {
                return [file normalize $d]
            }
        }
        return ""
    }

    proc init {{d ""}} {
        variable path
        variable dir
        variable state
        set dir [expr {$d ne "" ? $d : [chooseDir]}]
        set ::state [defaults]
        if {$dir eq ""} { return }
        catch {file mkdir $dir}
        set path [file join $dir state.tcl]
        if {[file exists $path]} {
            if {[catch {
                set f [open $path r]; set data [read $f]; close $f
                set loaded $data
                if {![string is list -strict $loaded] || [llength $loaded] % 2} { error "bad" }
                # merge so that new keys added in later versions get defaults
                dict for {k v} $loaded { dict set ::state $k $v }
            }]} {
                catch {file rename -force $path $path.bad}
                set ::state [defaults]
            }
        }
    }

    proc save {} {
        variable path
        if {$path eq ""} return
        catch {
            set tmp $path.tmp
            set f [open $tmp w]
            fconfigure $f -encoding utf-8
            puts -nonewline $f $::state
            close $f
            file rename -force $tmp $path
        }
    }

    proc setting {k {default ""}} {
        if {[dict exists $::state settings $k]} { return [dict get $::state settings $k] }
        return $default
    }
    proc setSetting {k v} { dict set ::state settings $k $v; save }

    proc reset {} {
        set ::state [defaults]
        save
    }

    # ---- derived facts -------------------------------------------------
    proc addXP {n} {
        set today [util::today]
        dict incr ::state xp $n
        set cur [expr {[dict exists $::state daily $today] ? [dict get $::state daily $today] : 0}]
        dict set ::state daily $today [expr {$cur + $n}]
        touchStreak
    }
    proc touchStreak {} {
        set today [util::today]
        set last [dict get $::state lastday]
        if {$last == $today} return
        if {$last == $today - 1} {
            dict incr ::state streak
        } else {
            dict set ::state streak 1
        }
        dict set ::state lastday $today
        if {[dict get $::state streak] > [dict get $::state best]} {
            dict set ::state best [dict get $::state streak]
        }
    }
    proc streak {} {
        set last [dict get $::state lastday]
        if {$last >= [util::today] - 1} { return [dict get $::state streak] }
        return 0
    }
    proc xpToday {} {
        set t [util::today]
        expr {[dict exists $::state daily $t] ? [dict get $::state daily $t] : 0}
    }
    proc level {} { expr {int(sqrt([dict get $::state xp] / 60.0)) + 1} }
    proc levelProgress {} {
        set L [level]
        set lo [expr {($L - 1) * ($L - 1) * 60}]
        set hi [expr {$L * $L * 60}]
        list [expr {[dict get $::state xp] - $lo}] [expr {$hi - $lo}]
    }
    proc levelTitle {} {
        set titles {Newcomer Apprentice Scripter Coder Hacker Artisan Engineer Wizard Sage Grandmaster}
        lindex $titles [expr {min([level] - 1, [llength $titles] - 1)}]
    }
    proc lessonDone {id} { dict exists $::state lessons $id }
    proc lessonStars {id} {
        if {[dict exists $::state lessons $id stars]} { return [dict get $::state lessons $id stars] }
        return 0
    }
    proc exStat {id} {
        if {[dict exists $::state exstats $id]} { return [dict get $::state exstats $id] }
        return {0 0}
    }
    proc recordEx {id ok} {
        lassign [exStat $id] r w
        if {$ok} { incr r } else { incr w }
        dict set ::state exstats $id [list $r $w]
    }
}
