#!/usr/bin/env wish
# Learn Tcl - a spaced-repetition course in Tcl, written in Tcl/Tk.
# Run with:  wish main.tcl        (desktop)   or open in AndroWish (Android)
package require Tk

set ::app_lib {util theme store srs sandbox content aa ui exercises runner screens}
set ::app_content {u01 u02 u03 u04 u05 u06 u07 u08 u09 u10 u11}

namespace eval boot {
    variable root [file dirname [file normalize [info script]]]
    # Load a source file, from the embedded bundle if there is one.
    proc load {rel} {
        variable root
        if {[info exists ::EMBED($rel)]} {
            uplevel #0 $::EMBED($rel)
        } else {
            uplevel #0 [list source -encoding utf-8 [file join $root $rel]]
        }
    }
}

foreach f $::app_lib     { boot::load lib/$f.tcl }
foreach f $::app_content { boot::load content/$f.tcl }

proc boot::main {} {
    set android [llength [info commands borg]]
    if {$android} {
        catch {wm attributes . -fullscreen 1}
        update
        set W [expr {min([winfo screenwidth .], [winfo screenheight .])}]
    } elseif {[info exists ::env(TERMUX_VERSION)] || [info exists ::env(LEARNTCL_FULLSCREEN)]} {
        # Termux + an X server app (Termux:X11): fill the whole display
        set sw [winfo screenwidth .]; set sh [winfo screenheight .]
        wm geometry . ${sw}x${sh}+0+0
        update
        set W [expr {min($sw, $sh)}]
    } else {
        set W 410
        wm geometry . ${W}x840
        wm minsize . 300 500
        update
        set W [winfo width .]
    }
    set ::ui::U [expr {$W / 100.0}]
    app::init
    sandbox::init [expr {$store::dir ne "" ? $store::dir : [pwd]}]
    app::go home
    foreach k {<Escape> <Cancel> <XF86Back> <Key-Escape>} { catch {bind . $k app::back} }
    app::fit
}
if {![info exists ::LEARNTCL_NO_MAIN]} { boot::main }
