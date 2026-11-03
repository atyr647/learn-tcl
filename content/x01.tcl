# Extra write-the-code exercises appended to existing lessons (ids continue each lesson's list).

# ---------------------------------------------------------------- unit 1
content::addEx 1.1 \
  {kind code prompt {Write a program that prints **Hello, Tcl!**} starter {# write your program here
} solution {puts "Hello, Tcl!"} out {Hello, Tcl!} why {One `puts` with the text in double quotes.}} \
  {kind code prompt {Print three lines: **Tcl**, then **is**, then **fun**.} starter {puts "Tcl"
} solution {puts "Tcl"
puts "is"
puts "fun"} out {Tcl
is
fun} why {One `puts` per line, in order.}}

content::addEx 1.2 \
  {kind code prompt {The line below fails. Fix it so it prints **Good morning, Tcl** (hint: quotes).} starter {puts Good morning, Tcl} solution {puts "Good morning, Tcl"} out {Good morning, Tcl} why {Without quotes `puts` receives three words. Quotes make them one argument.}}

content::addEx 1.3 \
  {kind code prompt {Print exactly: **She said "hi"** (the quote marks are part of the output).} starter {puts "She said hi"} solution {puts "She said \"hi\""} out {She said "hi"} why {A backslash before a quote mark prints it instead of ending the text.}} \
  {kind code prompt {Print **Loading...** on ONE line using two `puts` commands (use -nonewline).} starter {puts "Loading"
puts "..."} solution {puts -nonewline "Loading"
puts "..."} out {Loading...} why {`-nonewline` keeps the cursor on the same line.}}

# ---------------------------------------------------------------- unit 2
content::addEx 2.1 \
  {kind code prompt {Set a variable called **city** to **Paris**, then print it.} starter {# set city, then print it
} solution {set city Paris
puts $city} out {Paris} why {`set city Paris` stores the value; `$city` reads it.}} \
  {kind code prompt {Set **a** to 3 and **b** to 4, then print them as: **3 and 4**} starter {set a 3
set b 4} solution {set a 3
set b 4
puts "$a and $b"} out {3 and 4} why {Inside double quotes each variable is replaced by its value.}}

content::addEx 2.2 \
  {kind code prompt {Print how many letters are in the word **programming**.} starter {puts [string length programming]x} solution {puts [string length programming]} out {11} why {`string length` returns the number of characters.}} \
  {kind code prompt {Set **word** to **tcl** and print it in capitals.} starter {set word tcl
puts $word} solution {set word tcl
puts [string toupper $word]} out {TCL} why {Wrap the variable in `[string toupper ...]`.}}

content::addEx 2.3 \
  {kind code prompt {Use `append` to build **Hello, World** from the pieces and print it.} starter {set s Hello
puts $s} solution {set s Hello
append s ", World"
puts $s} out {Hello, World} why {`append s text` adds to the end of the variable.}}

# ---------------------------------------------------------------- unit 3
content::addEx 3.1 \
  {kind code prompt {Print the area of a circle with radius 2, using 3.14159 for pi (area = pi * r squared).} starter {set r 2
puts $r} solution {set r 2
puts [expr {3.14159 * $r ** 2}]} out {12.56636} why {`**` is "to the power of".}} \
  {kind code prompt {Write a proc **fahrenheit** that converts Celsius to Fahrenheit: F = C * 9 / 5 + 32. Use `9.0` so the maths is not whole-number.} starter {proc fahrenheit {c} {
    return $c
}} solution {proc fahrenheit {c} {
    return [expr {$c * 9.0 / 5 + 32}]
}} tests {{fahrenheit 100} 212.0 {fahrenheit 0} 32.0} why {Multiply, divide, then add - using a decimal 9.0 avoids dropping the remainder.}}

content::addEx 3.2 \
  {kind code prompt {Write a proc **grade** taking a score: return **A** for 90 or more, **B** for 80 or more, otherwise **C**.} starter {proc grade {score} {
    return C
}} solution {proc grade {score} {
    if {$score >= 90} {return A}
    if {$score >= 80} {return B}
    return C
}} tests {{grade 95} A {grade 85} B {grade 40} C} why {Test the highest threshold first.}}

content::addEx 3.3 \
  {kind code prompt {Write a proc **daytype** that returns **weekend** for Sat or Sun and **weekday** otherwise, using `switch`.} starter {proc daytype {d} {
    return weekday
}} solution {proc daytype {d} {
    switch $d {
        Sat - Sun {return weekend}
        default   {return weekday}
    }
}} tests {{daytype Sat} weekend {daytype Sun} weekend {daytype Mon} weekday} why {`Sat - Sun` shares one body between two patterns.}}

# ---------------------------------------------------------------- unit 4
content::addEx 4.1 \
  {kind code prompt {Use a **while** loop to print the numbers 1 to 5, one per line.} starter {set i 1} solution {set i 1
while {$i <= 5} {
    puts $i
    incr i
}} out {1
2
3
4
5} why {Print, then `incr i`, until the condition is false.}}

content::addEx 4.2 \
  {kind code prompt {Use a **for** loop to print the 3 times table from 3 x 1 = 3 up to 3 x 4 = 12.} starter {for {set i 1} {$i <= 4} {incr i} {
    puts $i
}} solution {for {set i 1} {$i <= 4} {incr i} {
    puts "3 x $i = [expr {3 * $i}]"
}} out {3 x 1 = 3
3 x 2 = 6
3 x 3 = 9
3 x 4 = 12} why {A command in brackets inside the quotes calculates each product.}}

content::addEx 4.3 \
  {kind code prompt {Write a proc **countbig** returning how many numbers in a list are greater than 10.} starter {proc countbig {nums} {
    return 0
}} solution {proc countbig {nums} {
    set n 0
    foreach x $nums {
        if {$x > 10} {incr n}
    }
    return $n
}} tests {{countbig {5 12 30 7 11}} 3 {countbig {}} 0} why {Keep a counter and increment it for each match.}} \
  {kind code prompt {Print the multiples of 3 from 1 to 12 using `foreach` and `continue` (3, 6, 9, 12 - one per line).} starter {foreach n {1 2 3 4 5 6 7 8 9 10 11 12} {
    puts $n
}} solution {foreach n {1 2 3 4 5 6 7 8 9 10 11 12} {
    if {$n % 3 != 0} {continue}
    puts $n
}} out {3
6
9
12} why {`continue` skips the numbers that are not multiples of 3.}}

# ---------------------------------------------------------------- unit 5
content::addEx 5.1 \
  {kind code prompt {Write a proc **maxof** that returns the larger of two numbers (do not use `max`).} starter {proc maxof {a b} {
    return $a
}} solution {proc maxof {a b} {
    if {$a > $b} {return $a}
    return $b
}} tests {{maxof 3 9} 9 {maxof 9 3} 9 {maxof 4 4} 4} why {Compare the two and return the larger.}}

content::addEx 5.2 \
  {kind code prompt {Write a proc **joinwords** that joins its arguments with a single space: `joinwords a b c` gives `a b c`. Any number of arguments (use `args`).} starter {proc joinwords {args} {
    return ""
}} solution {proc joinwords {args} {
    return [join $args " "]
}} tests {{joinwords a b c} {a b c} {joinwords x} x} why {`args` is a list, and `join` glues it back together.}}

content::addEx 5.3 \
  {kind code prompt {Write a recursive proc **fib** returning the nth Fibonacci number: fib 0 = 0, fib 1 = 1, fib n = fib(n-1) + fib(n-2).} starter {proc fib {n} {
    return 0
}} solution {proc fib {n} {
    if {$n < 2} {return $n}
    return [expr {[fib [expr {$n - 1}]] + [fib [expr {$n - 2}]]}]
}} tests {{fib 0} 0 {fib 1} 1 {fib 10} 55} why {Two base cases (0 and 1), then the sum of the two previous.}} \
  {kind code prompt {Write a proc **gcd** using recursion (Euclid): gcd a 0 is a, otherwise gcd b (a mod b).} starter {proc gcd {a b} {
    return 1
}} solution {proc gcd {a b} {
    if {$b == 0} {return $a}
    return [gcd $b [expr {$a % $b}]]
}} tests {{gcd 12 18} 6 {gcd 17 5} 1 {gcd 9 0} 9} why {Euclid's algorithm shrinks the problem each step.}}

# ---------------------------------------------------------------- unit 6
content::addEx 6.1 \
  {kind code prompt {Write a proc **lastitem** that returns the last item of a list.} starter {proc lastitem {l} {
    return [lindex $l 0]
}} solution {proc lastitem {l} {
    return [lindex $l end]
}} tests {{lastitem {a b c}} c {lastitem {x}} x} why {`end` means the last index.}} \
  {kind code prompt {Write a proc **middle** that returns the list without its first and last items.} starter {proc middle {l} {
    return $l
}} solution {proc middle {l} {
    return [lrange $l 1 end-1]
}} tests {{middle {1 2 3 4 5}} {2 3 4} {middle {a b}} {}} why {`end-1` is the second to last index.}}

content::addEx 6.2 \
  {kind code prompt {Write a proc **uniqsorted** that returns a list sorted alphabetically with duplicates removed.} starter {proc uniqsorted {l} {
    return $l
}} solution {proc uniqsorted {l} {
    return [lsort -unique $l]
}} tests {{uniqsorted {pear apple pear fig apple}} {apple fig pear}} why {`lsort -unique` sorts and drops duplicates in one go.}}

content::addEx 6.3 \
  {kind code prompt {Write a proc **zip** taking two lists of the same length and returning a list of pairs: `zip {a b} {1 2}` gives `{a 1} {b 2}`.} starter {proc zip {a b} {
    return {}
}} solution {proc zip {a b} {
    set r {}
    foreach x $a y $b {lappend r [list $x $y]}
    return $r
}} tests {{zip {a b c} {1 2 3}} {{a 1} {b 2} {c 3}}} why {`foreach` can walk two lists in step.}}

# ---------------------------------------------------------------- unit 7
content::addEx 7.1 \
  {kind code prompt {Write a proc **ispalin** returning 1 if a word reads the same backwards, else 0.} starter {proc ispalin {w} {
    return 0
}} solution {proc ispalin {w} {
    return [string equal $w [string reverse $w]]
}} tests {{ispalin level} 1 {ispalin tcl} 0} why {Compare the word with its reverse.}} \
  {kind code prompt {Write a proc **capitalize** that upper-cases the first letter and lower-cases the rest: `capitalize tCL` gives `Tcl`.} starter {proc capitalize {w} {
    return $w
}} solution {proc capitalize {w} {
    return [string totitle $w]
}} tests {{capitalize tCL} Tcl {capitalize ADA} Ada} why {`string totitle` does exactly this.}}

content::addEx 7.2 \
  {kind code prompt {Write a proc **zeropad** that formats a number as 5 digits with leading zeros: `zeropad 42` gives `00042`.} starter {proc zeropad {n} {
    return $n
}} solution {proc zeropad {n} {
    return [format %05d $n]
}} tests {{zeropad 42} 00042 {zeropad 7} 00007} why {`%05d` pads with zeros to width 5.}}

content::addEx 7.3 \
  {kind code prompt {Write a proc **numbers** returning the list of all whole numbers found in a text: `numbers {a1 b22 c333}` gives `1 22 333`.} starter {proc numbers {s} {
    return {}
}} solution {proc numbers {s} {
    return [regexp -all -inline {\d+} $s]
}} tests {{numbers {a1 b22 c333}} {1 22 333} {numbers none} {}} why {`-all -inline` returns every match as a list.}} \
  {kind code prompt {Write a proc **isdate** returning 1 if a string looks like YYYY-MM-DD (four digits, dash, two digits, dash, two digits), else 0.} starter {proc isdate {s} {
    return 0
}} solution {proc isdate {s} {
    return [regexp {^\d{4}-\d{2}-\d{2}$} $s]
}} tests {{isdate 2024-05-17} 1 {isdate 2024-5-17} 0 {isdate x2024-05-17} 0} why {Anchors `^`/`$` make the whole string match, and `\d{4}` means four digits.}}

# ---------------------------------------------------------------- unit 8
content::addEx 8.1 \
  {kind code prompt {Write a proc **invert** that swaps keys and values of a dict: `invert {a 1 b 2}` gives `1 a 2 b`.} starter {proc invert {d} {
    return $d
}} solution {proc invert {d} {
    set r {}
    dict for {k v} $d {dict set r $v $k}
    return $r
}} tests {{invert {a 1 b 2}} {1 a 2 b}} why {Loop with `dict for` and set each value as a key.}}

content::addEx 8.2 \
  {kind code prompt {Write a proc **total** that adds up the values of a dict of numbers.} starter {proc total {d} {
    return 0
}} solution {proc total {d} {
    set t 0
    dict for {k v} $d {incr t $v}
    return $t
}} tests {{total {a 3 b 4 c 5}} 12 {total {}} 0} why {Walk the values and keep a running sum.}}

content::addEx 8.3 \
  {kind code prompt {Write a proc **letters** that counts each letter of a word into a dict: `letters banana` gives `b 1 a 3 n 2`.} starter {proc letters {w} {
    return {}
}} solution {proc letters {w} {
    set d {}
    foreach c [split $w ""] {dict incr d $c}
    return $d
}} tests {{letters banana} {b 1 a 3 n 2}} why {`split $w ""` gives a list of characters; `dict incr` counts them.}}

# ---------------------------------------------------------------- unit 9
content::addEx 9.1 \
  {kind code prompt {Write a proc **toint** that returns the number if its argument is a whole number, or the text **invalid** if not - without crashing.} starter {proc toint {x} {
    return [expr {$x + 0}]
}} solution {proc toint {x} {
    if {[string is integer -strict $x]} {return $x}
    return invalid
}} tests {{toint 42} 42 {toint abc} invalid {toint {}} invalid} why {`string is integer -strict` checks safely before using the value.}} \
  {kind code prompt {Write a proc **mustpositive** that returns its argument, but raises the error **must be positive** when the number is 0 or less.} starter {proc mustpositive {n} {
    return $n
}} solution {proc mustpositive {n} {
    if {$n <= 0} {error "must be positive"}
    return $n
}} tests {{mustpositive 5} 5 {catch {mustpositive -1} m; set m} {must be positive}} why {`error "message"` raises the error that `catch` reports.}}

content::addEx 9.2 \
  {kind code prompt {Write a proc **linecount** that returns how many lines a file has.} starter {proc linecount {name} {
    return 0
}} solution {proc linecount {name} {
    set f [open $name r]
    set n 0
    while {[gets $f line] >= 0} {incr n}
    close $f
    return $n
}} tests {{set f [open t.txt w]; puts $f a; puts $f b; puts $f c; close $f; linecount t.txt} 3} why {Read with `gets` until it returns -1, counting.}}

content::addEx 9.3 \
  {kind code prompt {Write a proc **parserow** that turns `ann,31,paris` into a dict with keys name, age, city.} starter {proc parserow {line} {
    return {}
}} solution {proc parserow {line} {
    lassign [split $line ,] name age city
    return [dict create name $name age $age city $city]
}} tests {{parserow ann,31,paris} {name ann age 31 city paris}} why {Split on commas, unpack with `lassign`, build a dict.}}

# ---------------------------------------------------------------- unit 10
content::addEx 10.1 \
  {kind code prompt {Write a proc **callit** that runs a command given as its first argument with the remaining arguments, safely: `callit string toupper abc` gives `ABC`.} starter {proc callit {cmd args} {
    return {}
}} solution {proc callit {cmd args} {
    return [$cmd {*}$args]
}} tests {{callit string toupper abc} ABC {callit expr 2 + 3} 5} why {`{*}$args` spreads the arguments as separate words.}}

content::addEx 10.2 \
  {kind code prompt {Write a proc **appendto** taking a variable NAME and a value, adding the value to that list variable in the caller (use `upvar`).} starter {proc appendto {name val} {
}} solution {proc appendto {name val} {
    upvar 1 $name l
    lappend l $val
}} tests {{set x {}; appendto x a; appendto x b; set x} {a b}} why {`upvar 1 $name l` makes `l` the caller's variable.}}

content::addEx 10.3 \
  {kind code prompt {Write a proc **partial** taking a command prefix and some leading arguments and returning a new prefix with them added: `{*}[partial {string repeat} ab] 3` gives `ababab`.} starter {proc partial {cmd args} {
    return $cmd
}} solution {proc partial {cmd args} {
    return [list {*}$cmd {*}$args]
}} tests {{{*}[partial {string repeat} ab] 3} ababab} why {A command prefix is just a list, so extend it with `list {*}...`.}}

content::addEx 10.4 \
  {kind code prompt {Create a namespace **ticker** with a variable and a proc **next** that returns 1, 2, 3... on successive calls.} starter {namespace eval ticker {
}} solution {namespace eval ticker {
    variable n 0
    proc next {} {
        variable n
        return [incr n]
    }
}} tests {{ticker::next; ticker::next; ticker::next} 3} why {The namespace variable keeps its value between calls.}}

# ---------------------------------------------------------------- unit 11
content::addEx 11.1 \
  {kind code prompt {Write a proc **take** that calls a coroutine command n times and returns the list of results: `take gen 3`.} starter {proc take {gen n} {
    return {}
}} solution {proc take {gen n} {
    set r {}
    for {set i 0} {$i < $n} {incr i} {lappend r [$gen]}
    return $r
}} tests {{proc g {} {yield; set i 0; while 1 {yield [incr i]}}; coroutine cg g; take cg 4} {1 2 3 4}} why {Each call to the coroutine produces the next value.}}

content::addEx 11.2 \
  {kind code prompt {Write a TclOO class **Stack** with methods **push**, **pop** and **size**.} starter {oo::class create Stack {
}} solution {oo::class create Stack {
    variable items
    constructor {} {set items {}}
    method push {x} {lappend items $x}
    method pop {} {
        set x [lindex $items end]
        set items [lrange $items 0 end-1]
        return $x
    }
    method size {} {return [llength $items]}
}} tests {{set s [Stack new]; $s push a; $s push b; list [$s pop] [$s size]} {b 1}} why {The object's own variable keeps the list between method calls.}}

content::addEx 11.3 \
  {kind code prompt {Make every write to the variable **v** increase the global counter **writes**. Define a handler proc **bump** and attach it with a write trace.} starter {set ::writes 0
proc bump {args} {}
set v 0} solution {set ::writes 0
proc bump {args} {incr ::writes}
set v 0
trace add variable v write bump} tests {{set v 1; set v 2; set v 3; set ::writes} 3} why {A write trace runs the handler on every `set`.}}

content::addEx 11.4 \
  {kind code prompt {Write a proc **later** that waits 10 ms (without blocking events) and then returns the text **done**, using `after` and `vwait`.} starter {proc later {} {
    return {}
}} solution {proc later {} {
    after 10 {set ::fin done}
    vwait ::fin
    return $::fin
}} tests {{later} done} why {`after` schedules, `vwait` runs the event loop until the variable is set.}}

content::addEx 11.5 \
  {kind code prompt {Write a proc **evalsafe** that evaluates a Tcl script in a brand new SAFE interpreter and returns the result (then deletes the interpreter).} starter {proc evalsafe {script} {
    return {}
}} solution {proc evalsafe {script} {
    set i [interp create -safe]
    set r [$i eval $script]
    interp delete $i
    return $r
}} tests {{evalsafe {expr {6 * 7}}} 42 {evalsafe {set x 5; incr x}} 6} why {`interp create -safe` plus `eval` gives an isolated world.}}

content::addEx 11.6 \
  {kind code prompt {Write a proc **squares** that returns the list of squares 1..n efficiently, building the list with `lappend`.} starter {proc squares {n} {
    return {}
}} solution {proc squares {n} {
    set r {}
    for {set i 1} {$i <= $n} {incr i} {lappend r [expr {$i * $i}]}
    return $r
}} tests {{squares 5} {1 4 9 16 25} {squares 0} {}} why {`lappend` appends in place, so the loop stays fast even for large n.}}
