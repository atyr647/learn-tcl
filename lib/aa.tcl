# aa.tcl - anti-aliased graphics for Tk canvases.
#
# Tk canvas shapes are not anti-aliased, so rounded corners, circles and icons look
# jagged. Here every curved thing is rasterised once with signed-distance maths into
# a small RGBA PNG, loaded as a photo image and cached. Straight edges stay plain
# canvas rectangles, so a rounded panel of any size = 4 cached corners + 3 rects.
namespace eval aa {
    variable cache
    array set cache {}
}

proc aa::chunk {type data} {
    set body "$type$data"
    return [string cat [binary format I [string length $data]] $body [binary format I [zlib crc32 $body]]]
}
# rows: list of byte-strings (RGBA, w*4 bytes each)
proc aa::mkimg {w h rows} {
    set raw ""
    foreach r $rows { append raw \x00 $r }
    set png "\x89PNG\r\n\x1a\n"
    append png [chunk IHDR [binary format IIccccc $w $h 8 6 0 0 0]]
    append png [chunk IDAT [zlib compress $raw]]
    append png [chunk IEND ""]
    ::image create photo -data $png -format png
}
# 1-pixel soft edge: d is signed distance in pixels (negative = inside)
proc aa::cov {d} {
    set a [expr {0.5 - $d}]
    expr {$a <= 0 ? 0.0 : ($a >= 1 ? 1.0 : $a)}
}
proc aa::rgb {c} { scan $c "#%2x%2x%2x" r g b; list $r $g $b }

# ---- rounded corner pieces ---------------------------------------------------
proc aa::corner {color r which} {
    variable cache
    set key "c:$color:$r:$which"
    if {[info exists cache($key)]} { return $cache($key) }
    lassign [rgb $color] cr cg cb
    set cx [expr {$which in {tl bl} ? $r : 0}]
    set cy [expr {$which in {tl tr} ? $r : 0}]
    set rows {}
    for {set y 0} {$y < $r} {incr y} {
        set v {}
        for {set x 0} {$x < $r} {incr x} {
            set a [cov [expr {hypot($x + .5 - $cx, $y + .5 - $cy) - $r}]]
            lappend v $cr $cg $cb [expr {int($a * 255 + .5)}]
        }
        lappend rows [binary format c* $v]
    }
    set cache($key) [mkimg $r $r $rows]
}

# Filled rounded rectangle: 4 AA corners + 3 plain rectangles.
proc aa::fillRect {c x1 y1 x2 y2 r color tags} {
    set x1 [expr {int($x1)}]; set y1 [expr {int($y1)}]; set x2 [expr {int($x2)}]; set y2 [expr {int($y2)}]
    set w [expr {$x2 - $x1}]; set h [expr {$y2 - $y1}]
    if {$w < 1 || $h < 1} return
    set r [expr {int(min($r, $w / 2, $h / 2))}]
    if {$r < 2} {
        $c create rectangle $x1 $y1 $x2 $y2 -fill $color -outline "" -tags $tags
        return
    }
    $c create rectangle [expr {$x1 + $r}] $y1 [expr {$x2 - $r}] $y2 -fill $color -outline "" -tags $tags
    if {$h > 2 * $r} {
        $c create rectangle $x1 [expr {$y1 + $r}] [expr {$x1 + $r}] [expr {$y2 - $r}] -fill $color -outline "" -tags $tags
        $c create rectangle [expr {$x2 - $r}] [expr {$y1 + $r}] $x2 [expr {$y2 - $r}] -fill $color -outline "" -tags $tags
    }
    $c create image $x1 $y1 -anchor nw -image [corner $color $r tl] -tags $tags
    $c create image [expr {$x2 - $r}] $y1 -anchor nw -image [corner $color $r tr] -tags $tags
    $c create image $x1 [expr {$y2 - $r}] -anchor nw -image [corner $color $r bl] -tags $tags
    $c create image [expr {$x2 - $r}] [expr {$y2 - $r}] -anchor nw -image [corner $color $r br] -tags $tags
}

# Rounded rectangle with optional border band of thickness bw (inside the bounds).
proc aa::rrect {c x1 y1 x2 y2 r fill outline bw tags} {
    if {$outline ne "" && $bw > 0} {
        fillRect $c $x1 $y1 $x2 $y2 $r $outline $tags
        if {$fill ne ""} {
            fillRect $c [expr {$x1 + $bw}] [expr {$y1 + $bw}] [expr {$x2 - $bw}] [expr {$y2 - $bw}] [expr {max(0, $r - $bw)}] $fill $tags
        } else {
            return -code error "outlined shapes need a fill"
        }
    } elseif {$fill ne ""} {
        fillRect $c $x1 $y1 $x2 $y2 $r $fill $tags
    }
}

# ---- discs and progress rings ---------------------------------------------------
proc aa::disc {color d} {
    variable cache
    set key "d:$color:$d"
    if {[info exists cache($key)]} { return $cache($key) }
    lassign [rgb $color] cr cg cb
    set R [expr {$d / 2.0}]
    set rows {}
    for {set y 0} {$y < $d} {incr y} {
        set v {}
        for {set x 0} {$x < $d} {incr x} {
            set a [cov [expr {hypot($x + .5 - $R, $y + .5 - $R) - $R}]]
            lappend v $cr $cg $cb [expr {int($a * 255 + .5)}]
        }
        lappend rows [binary format c* $v]
    }
    set cache($key) [mkimg $d $d $rows]
}

# A ring of thickness t in a square of side d: track colour all the way round,
# plus an arc of `frac` (0..1) from 12 o'clock clockwise, with round ends.
proc aa::ring {d t frac color track} {
    variable cache
    set frac [expr {round($frac * 100) / 100.0}]
    set key "r:$d:$t:$frac:$color:$track"
    if {[info exists cache($key)]} { return $cache($key) }
    lassign [rgb $color] pr pg pb
    lassign [rgb $track] tr_ tg tb
    set R [expr {$d / 2.0 - $t / 2.0}]
    set mid [expr {$d / 2.0}]
    set two_pi 6.283185307
    set ex [expr {$mid + $R * sin($frac * $two_pi)}]
    set ey [expr {$mid - $R * cos($frac * $two_pi)}]
    set sx $mid; set sy [expr {$mid - $R}]
    set rows {}
    for {set y 0} {$y < $d} {incr y} {
        set v {}
        for {set x 0} {$x < $d} {incr x} {
            set px [expr {$x + .5}]; set py [expr {$y + .5}]
            set dx [expr {$px - $mid}]; set dy [expr {$py - $mid}]
            set dist [expr {hypot($dx, $dy)}]
            set ring [expr {abs($dist - $R) - $t / 2.0}]
            set at [cov $ring]
            set ap 0.0
            if {$frac > 0} {
                set ang [expr {atan2($dx, -$dy) / $two_pi}]
                if {$ang < 0} { set ang [expr {$ang + 1}] }
                set dp [expr {$ang <= $frac ? $ring : 1e9}]
                set d1 [expr {hypot($px - $sx, $py - $sy) - $t / 2.0}]
                set d2 [expr {hypot($px - $ex, $py - $ey) - $t / 2.0}]
                set ap [cov [expr {min($dp, $d1, $d2)}]]
            }
            # composite progress over track
            set a [expr {$ap + $at * (1 - $ap)}]
            if {$a <= 0} { lappend v 0 0 0 0; continue }
            set wr [expr {$ap / $a}]
            lappend v [expr {int($pr * $wr + $tr_ * (1 - $wr) + .5)}] [expr {int($pg * $wr + $tg * (1 - $wr) + .5)}] \
                [expr {int($pb * $wr + $tb * (1 - $wr) + .5)}] [expr {int($a * 255 + .5)}]
        }
        lappend rows [binary format c* $v]
    }
    set cache($key) [mkimg $d $d $rows]
}

# ---- icons: unions/differences of simple shapes on a 24x24 grid -----------------------
proc aa::dist {op px py} {
    lassign $op - kind a b c d e
    switch $kind {
        circle { return [expr {hypot($px - $a, $py - $b) - $c}] }
        ring   { return [expr {abs(hypot($px - $a, $py - $b) - $c) - $d / 2.0}] }
        line   {
            # capsule from (a,b) to (c,d) with half-width e
            set vx [expr {$c - $a}]; set vy [expr {$d - $b}]
            set l2 [expr {$vx * $vx + $vy * $vy}]
            set t [expr {$l2 == 0 ? 0.0 : (($px - $a) * $vx + ($py - $b) * $vy) / $l2}]
            set t [expr {max(0.0, min(1.0, $t))}]
            return [expr {hypot($px - $a - $t * $vx, $py - $b - $t * $vy) - $e}]
        }
        box {
            # rounded box: x y w h r
            set hw [expr {$c / 2.0}]; set hh [expr {$d / 2.0}]
            set qx [expr {abs($px - $a - $hw) - ($hw - $e)}]
            set qy [expr {abs($py - $b - $hh) - ($hh - $e)}]
            return [expr {hypot(max($qx, 0), max($qy, 0)) + min(max($qx, $qy), 0) - $e}]
        }
        poly {
            set pts [lrange $op 2 end]
            set n [expr {[llength $pts] / 2}]
            set best 1e9; set in 0
            set j [expr {$n - 1}]
            for {set i 0} {$i < $n} {incr i} {
                set ax [lindex $pts [expr {2 * $i}]]; set ay [lindex $pts [expr {2 * $i + 1}]]
                set bx [lindex $pts [expr {2 * $j}]]; set by [lindex $pts [expr {2 * $j + 1}]]
                set vx [expr {$bx - $ax}]; set vy [expr {$by - $ay}]
                set l2 [expr {$vx * $vx + $vy * $vy}]
                set t [expr {$l2 == 0 ? 0.0 : (($px - $ax) * $vx + ($py - $ay) * $vy) / $l2}]
                set t [expr {max(0.0, min(1.0, $t))}]
                set dd [expr {hypot($px - $ax - $t * $vx, $py - $ay - $t * $vy)}]
                if {$dd < $best} { set best $dd }
                if {($ay > $py) != ($by > $py) && $px < $ax + $vx * ($py - $ay) / $vy} { set in [expr {!$in}] }
                set j $i
            }
            return [expr {$in ? -$best : $best}]
        }
    }
    return 1e9
}

proc aa::spec {name} {
    switch $name {
        check  { return {{+ line 5.2 12.8 10 17.4 1.7} {+ line 10 17.4 19 7 1.7}} }
        cross  - close { return {{+ line 6 6 18 18 1.6} {+ line 18 6 6 18 1.6}} }
        back   { return {{+ line 14.5 5.5 8 12 1.6} {+ line 8 12 14.5 18.5 1.6}} }
        play   { return {{+ poly 8 5.2 19.2 12 8 18.8}} }
        plus   { return {{+ line 12 5 12 19 1.5} {+ line 5 12 19 12 1.5}} }
        star   {
            set pts {}
            for {set i 0} {$i < 10} {incr i} {
                set a [expr {-1.5707963 + $i * 0.6283185}]
                set r [expr {$i % 2 ? 4.9 : 10.8}]
                lappend pts [expr {12 + $r * cos($a)}] [expr {12.9 + $r * sin($a)}]
            }
            return [list [concat + poly $pts] [list + circle 12 12.9 2]]
        }
        flame  { return {{+ circle 12 15 6.6} {+ poly 12 1.8 18 11.6 6 11.6} {+ circle 12 8.2 0.1}
                         {- circle 12 16.6 3.2} {- poly 12 11 15 16.5 9 16.5}} }
        bolt   { return {{+ poly 13.6 2.5 5.5 13.2 11 13.2 9.8 21.5 18.5 10.2 12.8 10.2}} }
        lock   { return {{+ box 5 10.5 14 10.5 2.6} {+ ring 12 9.4 4.4 2.3} {- circle 12 15.2 1.5} {- line 12 15.4 12 17.4 .8}} }
        home   { return {{+ poly 12 3 21.5 11.6 18.6 11.6 18.6 20 5.4 20 5.4 11.6 2.5 11.6} {- box 10 14 4 6 .8}} }
        cards  { return {{+ box 8.2 3.2 12.6 12.4 2.6} {- box 9.6 4.6 9.8 9.6 1.4} {+ box 3.2 8.4 12.6 12.4 2.6}} }
        code   { return {{+ line 8.2 7 3.2 12 1.5} {+ line 3.2 12 8.2 17 1.5} {+ line 15.8 7 20.8 12 1.5} {+ line 20.8 12 15.8 17 1.5} {+ line 13.4 5.6 10.6 18.4 1.3}} }
        user   { return {{+ circle 12 8 4.2} {+ box 4.6 14.2 14.8 7 3.5}} }
        target { return {{+ ring 12 12 9 2} {+ ring 12 12 5 2} {+ circle 12 12 1.7}} }
        bulb   { return {{+ circle 12 10 6.4} {+ box 9 14 6 6 1.5}} }
        chevron { return {{+ line 9 6 15 12 1.6} {+ line 15 12 9 18 1.6}} }
        book   { return {{+ box 3.5 4 17 15.5 2.4} {- box 5.2 5.7 13.6 12.1 1.2} {+ line 12 5.5 12 17.8 .9}} }
        brain  { return {{+ circle 8.6 9.6 5} {+ circle 15.4 9.6 5} {+ box 7.5 11 9 7.5 3.2} {- line 12 6 12 17.4 .8}} }
    }
    return {{+ circle 12 12 6}}
}

proc aa::icon {name px color} {
    variable cache
    set key "i:$name:$px:$color"
    if {[info exists cache($key)]} { return $cache($key) }
    lassign [rgb $color] cr cg cb
    set ops [spec $name]
    set sc [expr {$px / 24.0}]
    set rows {}
    for {set y 0} {$y < $px} {incr y} {
        set v {}
        set gy [expr {($y + .5) / $sc}]
        for {set x 0} {$x < $px} {incr x} {
            set gx [expr {($x + .5) / $sc}]
            set d 1e9
            foreach op $ops { if {[lindex $op 0] eq "+"} { set o [dist $op $gx $gy]; if {$o < $d} { set d $o } } }
            foreach op $ops { if {[lindex $op 0] eq "-"} { set o [expr {-[dist $op $gx $gy]}]; if {$o > $d} { set d $o } } }
            lappend v $cr $cg $cb [expr {int([cov [expr {$d * $sc}]] * 255 + .5)}]
        }
        lappend rows [binary format c* $v]
    }
    set cache($key) [mkimg $px $px $rows]
}
