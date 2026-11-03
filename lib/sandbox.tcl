# sandbox.tcl - run learner code in a throw-away child interpreter.
# * stdout/stderr output is captured (and capped)
# * runaway code is stopped after a time limit
# * exit / exec / socket / load are disabled
# * the working directory is a scratch folder that is emptied before each run
namespace eval sandbox {
    variable scratch ""
    variable timeLimit 3
    variable outLimit 20000

    proc init {dir} {
        variable scratch
        set scratch [file join $dir scratch]
        file mkdir $scratch
        cd $scratch
    }

    proc clean {} {
        variable scratch
        if {$scratch eq ""} return
        catch {
            # glob -types combines type AND hidden, so ask separately
            foreach f [concat [glob -nocomplain -directory $scratch -types {f d} *] \
                              [glob -nocomplain -directory $scratch -types {hidden} *]] {
                file delete -force $f
            }
        }
    }

    # run <code> ?<after-script>... via -then {script ...}?
    # Returns dict: ok (0/1) out result err thens (list of results of the -then scripts)
    proc run {code args} {
        variable timeLimit
        variable outLimit
        set thens {}
        foreach {k v} $args { if {$k eq "-then"} { set thens $v } }
        clean
        set i [interp create]
        $i eval {
            set ::__out ""
            rename puts ::__puts
            proc puts {args} {
                set nn 0
                if {[lindex $args 0] eq "-nonewline"} { set nn 1; set args [lrange $args 1 end] }
                if {[llength $args] == 1} { set ch stdout; set s [lindex $args 0] } elseif {[llength $args] == 2} {
                    lassign $args ch s
                } else { error "wrong # args: should be \"puts ?-nonewline? ?channelId? string\"" }
                if {$ch eq "stdout" || $ch eq "stderr"} {
                    if {[string length $::__out] < 40000} {
                        append ::__out $s [expr {$nn ? "" : "\n"}]
                    }
                    return
                }
                if {$nn} { ::__puts -nonewline $ch $s } else { ::__puts $ch $s }
            }
            rename gets ::__gets
            proc gets {ch args} {
                if {$ch eq "stdin"} {
                    if {[llength $args]} { upvar 1 [lindex $args 0] v; set v "" ; return -1 }
                    return ""
                }
                uplevel 1 [list ::__gets $ch {*}$args]
            }
            # sockets: loopback only (127.0.0.1 / localhost), so lessons can use
            # networking without ever reaching the outside world
            rename socket ::__socket
            proc socket {args} {
                if {"-server" in $args} {
                    set i [lsearch -exact $args -myaddr]
                    if {$i < 0 || [lindex $args [expr {$i + 1}]] ne "127.0.0.1"} {
                        error "in the sandbox a server must use -myaddr 127.0.0.1"
                    }
                } else {
                    set host [lindex $args end-1]
                    if {$host ni {127.0.0.1 localhost}} {
                        error "in the sandbox sockets may only connect to 127.0.0.1"
                    }
                }
                uplevel 1 [list ::__socket {*}$args]
            }
            foreach c {exit exec load} {
                proc $c args "error \"$c is turned off inside the sandbox\""
            }
        }
        interp limit $i time -seconds [expr {[clock seconds] + $timeLimit}]
        set ok 1; set err ""; set res ""; set tres {}
        if {[catch {$i eval $code} res opts]} {
            set ok 0
            set err $res
            set res ""
            if {[string match "*limit exceeded*" $err] || [string match "*time limit*" $err]} {
                set err "Stopped: your code ran for too long (is there an endless loop?)"
            }
        }
        if {$ok} {
            foreach s $thens {
                if {[catch {$i eval $s} r]} { lappend tres "ERROR: $r" } else { lappend tres $r }
            }
        }
        set out [$i eval {set ::__out}]
        catch {interp delete $i}
        if {[string length $out] > $outLimit} {
            set out "[string range $out 0 $outLimit]\n... (output cut)"
        }
        dict create ok $ok out $out result $res err $err thens $tres
    }

    # Text shown in the "output" panel of the playground.
    proc display {r} {
        set o [dict get $r out]
        if {![dict get $r ok]} {
            return "$o[expr {$o ne {} && ![string match *\n $o] ? "\n" : ""}]Error: [dict get $r err]"
        }
        set res [dict get $r result]
        if {$o eq "" && $res eq ""} { return "(no output)" }
        if {$res ne ""} { append o "[expr {$o ne {} && ![string match *\n $o] ? "\n" : ""}]=> $res" }
        return $o
    }
}
