# sfx.tcl - sound effects and haptics.
#
# Every sound is synthesised here from sine "bell" notes and cached as a small WAV
# file, so there are no audio assets to ship or license. Generation needs no Tk
# (it is unit-tested headlessly). Playback uses, in order:
#   * Snack (the sound package bundled with AndroWish, also used on desktops that
#     have it)
#   * an external player on desktop (paplay / aplay / afplay)
#   * on Android, `borg beep` for the big fanfares if Snack is unavailable
# Haptics use `borg vibrate`. Both can be switched off in Profile.
namespace eval sfx {
    variable rate 16000
    variable dir ""
    variable backend none
    variable snd
    array set snd {}
    variable last
    array set last {}
    variable player ""
    variable warmList {}
    variable ver v1

    # name -> list of {startSeconds frequency duration amplitude ?decay?}
    # (C5 523, E5 659, G5 784, C6 1047, E6 1319, G6 1568)
    variable defs
    array set defs {
        tap       {{0 1900 0.03 0.55 9}}
        flip      {{0 640 0.07 0.5 12}}
        good      {{0 784 0.14 0.34 9}}
        again     {{0 247 0.14 0.30 10}}
        correct   {{0 659 0.09 0.40 8} {0.08 880 0.22 0.42 7}}
        wrong     {{0 233 0.12 0.36 7} {0.1 175 0.26 0.36 6}}
        complete  {{0 523 0.16 0.38 6} {0.11 659 0.16 0.38 6} {0.22 784 0.16 0.38 6} {0.33 1047 0.45 0.42 5}}
        perfect   {{0 523 0.14 0.36 6} {0.10 659 0.14 0.36 6} {0.20 784 0.14 0.36 6} {0.30 1047 0.14 0.38 6} {0.40 1319 0.14 0.38 6} {0.50 1568 0.55 0.42 4.5}}
        goal      {{0 784 0.12 0.36 7} {0.1 1047 0.5 0.42 5}}
        levelup   {{0 523 0.1 0.34 7} {0.08 659 0.1 0.34 7} {0.16 784 0.1 0.34 7} {0.24 1047 0.1 0.34 7} {0.32 1319 0.5 0.4 5}}
        fail      {{0 330 0.18 0.34 6} {0.16 262 0.34 0.34 5}}
    }
}

# ---- synthesis -------------------------------------------------------------------
# Build one mono 16-bit sample list from note events.
proc sfx::synth {name} {
    variable defs
    variable rate
    set end 0.0
    foreach ev $defs($name) { set end [expr {max($end, [lindex $ev 0] + [lindex $ev 2])}] }
    set n [expr {int($end * $rate) + 1}]
    set buf [lrepeat $n 0.0]
    set twopi 6.283185307179586
    foreach ev $defs($name) {
        lassign $ev t0 freq dur amp decay
        set s0 [expr {int($t0 * $rate)}]
        set len [expr {int($dur * $rate)}]
        set w [expr {$twopi * $freq / $rate}]
        set att [expr {max(1, min(int(0.004 * $rate), $len / 4))}]
        set rel [expr {max(1, min(int(0.012 * $rate), $len / 3))}]
        for {set i 0} {$i < $len} {incr i} {
            set env [expr {exp(-$decay * $i / double($len))}]
            if {$i < $att} { set env [expr {$env * $i / double($att)}] }
            if {$len - $i < $rel} { set env [expr {$env * ($len - $i) / double($rel)}] }
            set v [expr {$amp * $env * (sin($w * $i) + 0.22 * sin(2.0 * $w * $i) + 0.08 * sin(3.0 * $w * $i))}]
            set j [expr {$s0 + $i}]
            if {$j < $n} { lset buf $j [expr {[lindex $buf $j] + $v}] }
        }
    }
    set out {}
    foreach v $buf {
        set x [expr {int($v * 32767)}]
        if {$x > 32767} { set x 32767 } elseif {$x < -32768} { set x -32768 }
        lappend out $x
    }
    return $out
}

proc sfx::wav {samples} {
    variable rate
    set data [binary format s* $samples]
    set n [string length $data]
    return [binary format {a4 i a4 a4 i s s i i s s a4 i} \
        RIFF [expr {36 + $n}] WAVE "fmt " 16 1 1 $rate [expr {$rate * 2}] 2 16 data $n]$data
}

proc sfx::file {name} {
    variable dir
    variable ver
    return [::file join $dir sfx-$ver-$name.wav]
}

# make (or reuse) the WAV file for an effect; returns its path or ""
proc sfx::ensure {name} {
    variable dir
    variable defs
    if {$dir eq "" || ![info exists defs($name)]} { return "" }
    set f [file $name]
    if {[::file exists $f] && [::file size $f] > 44} { return $f }
    if {[catch {
        ::file mkdir $dir
        set h [open $f.tmp wb]
        puts -nonewline $h [wav [synth $name]]
        close $h
        ::file rename -force $f.tmp $f
    }]} { return "" }
    return $f
}

# ---- setup and playback -----------------------------------------------------------------
proc sfx::init {d} {
    variable dir
    variable backend
    variable player
    variable warmList
    variable defs
    set dir [::file join $d sound]
    set backend none
    if {[info exists ::env(LEARNTCL_NOSOUND)]} { return }
    # Snack is the first choice
    if {![catch {package require snack}] && [llength [info commands snack::sound]]} {
        set backend snack
    } else {
        foreach p {paplay aplay afplay} {
            set e [auto_execok $p]
            if {$e ne ""} { set player $e; set backend external; break }
        }
        if {$backend eq "none" && [llength [info commands borg]]} { set backend borg }
    }
    set warmList [lsort [array names defs]]
}

# generate the remaining effects a little at a time so start-up is never blocked
proc sfx::warm {} {
    variable warmList
    variable backend
    if {$backend eq "none" || ![llength $warmList]} return
    set name [lindex $warmList 0]
    set warmList [lrange $warmList 1 end]
    ensure $name
    if {[llength $warmList]} { after 250 sfx::warm }
}

proc sfx::enabled {} {
    expr {[llength [info commands store::setting]] ? [store::setting sound 1] : 1}
}
proc sfx::hapticsOn {} {
    expr {[llength [info commands store::setting]] ? [store::setting haptics 1] : 1}
}

proc sfx::play {name} {
    variable backend
    variable last
    variable snd
    variable player
    haptic $name
    if {$backend eq "none" || ![enabled]} return
    # do not machine-gun the same sound
    set now [clock milliseconds]
    if {[info exists last($name)] && $now - $last($name) < 70} return
    set last($name) $now
    if {$backend eq "borg"} {
        if {$name in {complete perfect levelup goal}} { catch {borg beep} }
        return
    }
    set f [ensure $name]
    if {$f eq ""} return
    if {$backend eq "snack"} {
        if {![info exists snd($name)]} {
            if {[catch {
                set s [snack::sound ::sfx::s_$name]
                $s read $f
                set snd($name) $s
            }]} { set backend none; return }
        }
        catch {$snd($name) stop}
        catch {$snd($name) play -blocking 0}
    } elseif {$backend eq "external"} {
        catch {exec $player $f > /dev/null 2>@1 &}
    }
}

# short vibration pattern for important feedback (Android only)
proc sfx::haptic {name} {
    if {![llength [info commands borg]] || ![hapticsOn]} return
    switch $name {
        correct  { set ms 18 }
        good     { set ms 12 }
        wrong    { set ms 70 }
        fail     { set ms 70 }
        complete - perfect - levelup - goal { set ms 45 }
        default  { return }
    }
    catch {borg vibrate $ms}
}

proc sfx::describe {} {
    variable backend
    variable dir
    return "sound: $backend ([expr {[enabled] ? "on" : "off"}]), haptics [expr {[hapticsOn] ? "on" : "off"}], cache $dir"
}
