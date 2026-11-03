# store.tcl - persistent learner state, kept as one Tcl dict in a file.
namespace eval store {
    variable path ""
    variable dir ""
    variable dirty 0
    variable ver 0               ;# bumped on every save; lets screens know they are stale

    proc defaults {} {
        dict create xp 0 streak 0 best 0 lastday 0 \
            daily {} lessons {} cards {} exstats {} newToday {0 0} \
            settings {theme dark goal 50 unlockAll 0 textScale 1.0 sound 1 haptics 1} \
            playground "" version 1 schema 1
    }

    # The directories we would store progress in, best first. On Android HOME and
    # INTERNAL_STORAGE are the app's private internal files directory: it survives
    # app updates and restarts, and is included in Android's automatic backup.
    # The cache/temp directory is deliberately NOT used - the system may clear it.
    proc candidates {} {
        set c {}
        if {[info exists ::env(LEARNTCL_HOME)]} { lappend c $::env(LEARNTCL_HOME) }
        if {[info exists ::env(INTERNAL_STORAGE)]} { lappend c [file join $::env(INTERNAL_STORAGE) .learn-tcl] }
        if {[info exists ::env(HOME)]} { lappend c [file join $::env(HOME) .learn-tcl] }
        lappend c [file join [pwd] .learn-tcl]
        if {[info exists ::env(TMPDIR)]} { lappend c [file join $::env(TMPDIR) learn-tcl] }
        lappend c /tmp/learn-tcl
        return [lsearch -all -inline -not -exact $c ""]
    }

    proc writable {d} {
        expr {![catch {file mkdir $d; set f [file join $d .w]; set h [open $f w]; close $h; file delete $f}]}
    }

    # Pick the first writable directory from the candidates.
    proc chooseDir {} {
        foreach d [candidates] {
            if {[writable $d]} { return [file normalize $d] }
        }
        return ""
    }

    # If an earlier version kept progress somewhere else, bring it across.
    proc adopt {dir} {
        if {[file exists [file join $dir state.tcl]]} return
        foreach d [candidates] {
            set src [file join $d state.tcl]
            if {[file normalize $d] ne [file normalize $dir] && [file exists $src]} {
                catch {file copy -force $src [file join $dir state.tcl]}
                return
            }
        }
    }

    # Read and validate a state file; returns the dict or raises an error.
    proc readFile {f} {
        set h [open $f r]
        fconfigure $h -encoding utf-8
        set data [read $h]
        close $h
        if {![string is list -strict $data] || [llength $data] % 2 || [llength $data] == 0} { error "bad state file" }
        return $data
    }

    proc init {{d ""}} {
        variable path
        variable dir
        set dir [expr {$d ne "" ? $d : [chooseDir]}]
        set ::state [defaults]
        if {$dir eq ""} { return }
        catch {file mkdir $dir}
        set path [file join $dir state.tcl]
        if {$d eq ""} { adopt $dir }
        set loaded ""
        foreach f [list $path $path.bak] {
            if {![file exists $f]} continue
            if {![catch {readFile $f} data]} { set loaded $data; break }
            # keep the unreadable file for inspection rather than overwrite it
            catch {file copy -force $f $f.bad}
        }
        if {$loaded ne ""} {
            # merge so that keys added in later versions get their defaults
            dict for {k v} $loaded { dict set ::state $k $v }
            migrate
        }
    }

    # Upgrade older state layouts in place. Unknown keys are always preserved, so
    # installing an older version over a newer one never loses data.
    proc migrate {} {
        set v [dict get $::state schema]
        if {![string is integer -strict $v]} { set v 0 }
        # schema 0 -> 1: nothing to rewrite; just stamp the version
        if {$v < 1} { dict set ::state schema 1 }
    }

    proc save {} {
        variable path
        variable ver
        incr ver
        if {$path eq ""} return
        catch {
            set tmp $path.tmp
            set f [open $tmp w]
            fconfigure $f -encoding utf-8
            puts -nonewline $f $::state
            close $f
            # keep the previous good copy, then swap the new file in atomically
            if {[file exists $path]} { catch {file copy -force $path $path.bak} }
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
