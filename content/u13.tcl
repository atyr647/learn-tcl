content::unit 13 "The advanced toolbox" "The techniques that separate a competent Tcl programmer from an expert one." "#F59E0B"

content::lesson 13.1 13 "Regular expressions in depth" "Greedy versus lazy, lookahead, boundaries, flags and powerful substitutions." {
pages {
  {head "Greedy and lazy matching" body {
    p {By default `+` and `*` are **greedy**: they match as much as they can. Add `?` after them to make them **lazy** (match as little as possible). The difference matters whenever the same character can appear several times.}
    code {puts [regexp -inline {<(.+)>} "<a><b>"]
puts [regexp -inline {<(.+?)>} "<a><b>"]}
    out {<a><b> a><b
<a> a}
    p {The greedy pattern grabbed everything up to the **last** `>`; the lazy one stopped at the **first**. `regexp -inline` returns the whole match followed by each capture.}
  }}
  {head "Boundaries, lookahead and flags" body {
    p {- `\y` matches a word boundary, so `\yTcl\y` finds the word Tcl but not TclTk
- `(?=...)` **lookahead**: matches only if followed by the text, without consuming it
- `(?i)` at the start makes the pattern case-insensitive
- `\1` refers back to what the first group matched
- `-indices` returns positions instead of text}
    code {puts [regexp -all -inline {\yTcl\y} "Tcl TclTk Tcl"]
puts [regexp -all -inline {\d(?=px)} "1px 2em 3px"]
puts [regexp {(?i)hello} HELLO]
regexp {(\w)\1} hello m c
puts "$m $c"
regexp -indices {b+} "aabbbcc" idx
puts $idx}
    out {Tcl Tcl
1 3
1
ll l
2 4}
    p {`(\w)\1` finds a doubled letter: in "hello" it is `ll`.}
  }}
  {head "Powerful substitutions" body {
    p {In a `regsub` replacement, `\1`, `\2` are the groups and `&` is the whole match. `regexp -line` makes `^` and `$` match at every line.}
    code {puts [regsub -all {(\w+)@(\w+)\.com} "ann@site.com bob@web.com" {\2: \1}]
puts [regsub -all {\d+} "a1b22" {<&>}]
puts [regexp -all -line -inline {^\w+} "one two
three four"]}
    out {site: ann web: bob
a<1>b<22>
one three}
    tip {A long regular expression is hard to read. Tcl lets you build one from parts with `format` or `set`, and comment each piece - or switch to `string` commands when they are clear enough.}
  }}
}
ex {
  {kind predict code {puts [regexp -inline {<(.+?)>} "<x><y>"]} choices {{<x> x} {<x><y> x><y} {x} {<y> y}} ans 0 why {The lazy `+?` stops at the first closing bracket.}}
  {kind predict code {puts [regexp -inline {<(.+)>} "<x><y>"]} choices {{<x><y> x><y} {<x> x} {x><y} {<y> y}} ans 0 why {Greedy matching runs on to the last `>`.}}
  {kind predict code {puts [regexp -all -inline {\d(?=px)} "5px 6em 7px"]} choices {{5 7} {5px 7px} {6} {5 6 7}} ans 0 why {Lookahead matches the digit only when `px` follows.}}
  {kind predict code {puts [regexp {(?i)tcl} "I love TCL"]} choices {1 0 TCL tcl} ans 0 why {`(?i)` ignores case.}}
  {kind predict code {regexp {(\w)\1} "committee" m
puts $m} choices {mm tt ee co} ans 0 why {The first doubled letter in "committee" is `mm`.}}
  {kind predict code {puts [regsub -all {\d+} "a1b22" {<&>}]} choices {a<1>b<22> a<&>b<&> <a1b22> a1b22} ans 0 why {`&` stands for the whole match.}}
  {kind predict code {puts [regsub {(\w+) (\w+)} "hello world" {\2-\1}]} choices {world-hello hello-world {\2-\1} world} ans 0 why {`\1` and `\2` are the two captured words, swapped.}}
  {kind predict code {regexp -indices {b+} "aabbbcc" idx
puts $idx} choices {{2 4} {2 5} {3 5} {bbb}} ans 0 why {-indices gives the start and end positions (counting from 0, end inclusive).}}
  {kind mc q {What does adding `?` after `+` do, as in `.+?`} choices {{Makes it lazy: match as little as possible} {Makes it optional} {Makes it greedy} {Makes it case-insensitive}} ans 0 why {Quantifier plus `?` means non-greedy.}}
  {kind blank q {Match the word Tcl only as a whole word.} code {puts [regexp {___Tcl___} "I use Tcl daily"]} answers {{\y} {\y}} extra {{\d} {^}} out {1} why {`\y` is the word boundary.}}
  {kind type q {Which regexp flag returns positions instead of text?} accept {-indices} why {`regexp -indices`.}}
  {kind code prompt {Write a proc **emails** returning every email address (simple form: word characters, @, word characters, dot, letters) found in a text.} starter {proc emails {text} {
    return {}
}} solution {proc emails {text} {
    return [regexp -all -inline {\w+@\w+\.[a-z]+} $text]
}} tests {{emails "write to ann@site.com or bob@web.org now"} {ann@site.com bob@web.org} {emails nothing} {}} why {`-all -inline` returns each whole match.}}
  {kind code prompt {Write a proc **squeeze** replacing every run of whitespace in a string with a single space.} starter {proc squeeze {s} {
    return $s
}} solution {proc squeeze {s} {
    return [regsub -all {\s+} $s " "]
}} tests {{squeeze "a   b    c"} {a b c}} why {`\s+` matches one or more whitespace characters.}}
}
cards {
  {{What is the difference between `.+` and `.+?`} {`.+` is greedy (as much as possible); `.+?` is lazy (as little as possible).}}
  {{What do `\y`, `(?=x)` and `(?i)` mean?} {Word boundary, lookahead (followed by x), and case-insensitive matching.}}
  {{What do `\1` and `&` mean in regsub?} {`\1` is the first captured group and `&` is the whole match.}}
  {{What does `regexp -all -inline` return?} {A list of every match (and its captured groups).}}
}
}

content::lesson 13.2 13 "A text-processing toolbox" "Sort, search, transform and report - the everyday work of a Tcl scripter." {
pages {
  {head "Sorting with intent" body {
    p {`lsort` has options for every need: `-dictionary` (numbers inside words compare naturally), `-index` (sort rows by a column), `-decreasing`, `-real`, `-unique`, and `-command` for a comparison you define yourself.}
    code {puts [lsort -dictionary {a10 a9 a2}]
puts [lsort -command {apply {{a b} {
    expr {[string length $a] - [string length $b]}
}}} {ccc a bb}]
puts [lsort -index 1 -integer {{x 30} {y 4} {z 100}}]}
    out {a2 a9 a10
a bb ccc
{y 4} {x 30} {z 100}}
    p {A comparison command returns negative, zero or positive, like `strcmp` in C.}
  }}
  {head "Searching lists" body {
    p {`lsearch` can match by pattern (`-glob`, the default), by regular expression (`-regexp`), exactly (`-exact`), by column (`-index`), and can return **all** matches or the **items** instead of positions (`-all`, `-inline`).}
    code {puts [lsearch -all -inline -regexp {a1 b22 c3 d44} {\d\d}]
puts [lsearch -index 0 {{a 1} {b 2} {c 3}} b]
puts [lsearch -all {red green red blue} red]
puts [lsearch -inline -glob {apple banana cherry} b*]}
    out {b22 d44
1
0 2
banana}
  }}
  {head "From raw text to a report" body {
    p {A classic Tcl program reads text, tallies it in a dict and prints a sorted report. Here `lsort -stride 2` treats the flat dict as pairs, so we can sort by count.}
    code {set text "the cat and the hat and the bat"
set counts {}
foreach w [split $text] {dict incr counts $w}
foreach {w n} [lsort -stride 2 -index 1 -integer -decreasing $counts] {
    puts [format "%-4s %d" $w $n]
}}
    out {the  3
and  2
cat  1
hat  1
bat  1}
    p {`lsort` is **stable**: items with equal counts keep their original order (cat, hat, bat).}
    tip {Reach for `split`, `foreach`, `dict incr`, `lsort` and `format`. With these five you can answer most "count, group and report" questions in a few lines.}
  }}
}
ex {
  {kind predict code {puts [lsort -dictionary {x10 x9 x1}]} choices {{x1 x9 x10} {x1 x10 x9} {x10 x9 x1} {x9 x10 x1}} ans 0 why {Dictionary sorting compares the embedded numbers as numbers.}}
  {kind predict code {puts [lsort {x10 x9 x1}]} choices {{x1 x10 x9} {x1 x9 x10} {x9 x10 x1} {x10 x9 x1}} ans 0 why {Plain sorting compares character by character: "x10" comes before "x9".}}
  {kind predict code {puts [lsearch -all -inline -regexp {a1 bb cc2 d} {\d}]} choices {{a1 cc2} {1 2} {a1 bb} {0 2}} ans 0 why {Items containing a digit, returned as items.}}
  {kind predict code {puts [lsearch -index 0 {{a 1} {b 2}} b]} choices {1 0 2 b} ans 0 why {The row whose first column is `b` is at position 1.}}
  {kind predict code {puts [lsearch -all {x y x z x} x]} choices {{0 2 4} {x x x} 0 3} ans 0 why {-all returns every matching position.}}
  {kind predict code {puts [lsort -index 1 -integer {{a 9} {b 10} {c 2}}]} choices {{{c 2} {a 9} {b 10}} {{a 9} {b 10} {c 2}} {{b 10} {a 9} {c 2}} {{c 2} {b 10} {a 9}}} ans 0 why {Sorted by the second column as numbers: 2, 9, 10.}}
  {kind predict code {puts [lsort -command {apply {{a b} {expr {$b - $a}}}} {1 3 2}]} choices {{3 2 1} {1 2 3} {2 3 1} {1 3 2}} ans 0 why {Reversing the subtraction reverses the order.}}
  {kind mc q {What does `lsort -stride 2 -index 1` let you do?} choices {{Sort a flat key/value list by its values} {Sort every second letter} {Skip two items} {Sort in groups of two alphabetically}} ans 0 why {-stride treats the list as groups of 2 items; -index picks which item in each group to compare.}}
  {kind mc q {What does it mean that `lsort` is stable?} choices {{Equal items keep their original order} {It never fails} {It only sorts numbers} {It sorts in place}} ans 0 why {Stability matters when you sort by one column after another.}}
  {kind blank q {Return the matching items, not their positions.} code {puts [lsearch -all ___ -glob {apple avocado pear} a*]} answers {-inline} extra {-index -exact -sorted} out {apple avocado} why {`-inline` returns the items themselves.}}
  {kind code prompt {Write a proc **topn** that takes a dict of word counts and a number n, and returns the n words with the highest counts, highest first.} starter {proc topn {counts n} {
    return {}
}} solution {proc topn {counts n} {
    set r {}
    foreach {w c} [lsort -stride 2 -index 1 -integer -decreasing $counts] {lappend r $w}
    return [lrange $r 0 [expr {$n - 1}]]
}} tests {{topn {a 1 b 5 c 3 d 4} 2} {b d} {topn {x 2} 3} x} why {Sort the pairs by count, collect the words, take the first n.}}
  {kind code prompt {Write a proc **wordfreq** that takes some text and returns a dict of lower-cased word counts (split on spaces).} starter {proc wordfreq {text} {
    return {}
}} solution {proc wordfreq {text} {
    set d {}
    foreach w [split [string tolower $text]] {dict incr d $w}
    return $d
}} tests {{wordfreq "The cat the hat"} {the 2 cat 1 hat 1}} why {Lower-case first so "The" and "the" count together.}}
}
cards {
  {{Which lsort options sort rows by a column and sort naturally?} {`-index n` for a column, `-dictionary` for natural number-aware sorting.}}
  {{Which lsearch options give all matches, the items themselves and regex matching?} {`-all`, `-inline` and `-regexp`.}}
  {{How do you sort a flat dict by its values?} {`lsort -stride 2 -index 1 -integer $dict`}}
  {{What is the classic count-and-report recipe?} {`split` the text, `dict incr` a counter per word, `lsort` the pairs, `format` the output.}}
}
}

content::lesson 13.3 13 "TclOO in depth" "Mixins, lifecycles, introspection and customising single objects." {
pages {
  {head "Mixins" body {
    p {Inheritance says "a Dog **is an** Animal". A **mixin** adds a ready-made bundle of behaviour from outside the family tree, wrapped **around** the class's own methods. A mixin method can call `next` to reach the original.}
    code {oo::class create Loud {
    method speak {} {return [string toupper [next]]}
}
oo::class create Animal {
    method speak {} {return quiet}
}
oo::class create Dog {
    superclass Animal
    method speak {} {return woof}
}
oo::define Dog mixin Loud
puts [[Dog new] speak]}
    out {WOOF}
    p {The call goes to `Loud` first; `next` continues to Dog's own `speak`, and Loud shouts the result.}
  }}
  {head "Lifecycle and introspection" body {
    p {A `constructor` runs when an object is made and a `destructor` when it is destroyed. TclOO can also describe itself with `info object` and `info class`.}
    code {oo::class create Counter {
    variable id
    constructor {} {
        global total
        incr total
        set id $total
    }
    method id {} {return $id}
    destructor {
        global total
        incr total -1
    }
}
set total 0
set a [Counter new]
set b [Counter new]
puts "$total [$b id]"
$a destroy
puts $total
puts [info object class $b]
puts [lsort [info class methods Counter]]}
    out {2 2
1
::Counter
id}
  }}
  {head "Customising one object" body {
    p {Methods can be added to a **single** object (`oo::objdefine`), and a class is itself an object, so you can give it methods too - for example a factory.}
    code {oo::class create Config {
    variable data
    constructor {} {set data {}}
    method set {k v} {dict set data $k $v}
    method get {k} {dict get $data $k}
}
oo::objdefine Config method defaults {} {
    set c [my new]
    $c set color blue
    return $c
}
set c [Config defaults]
puts [$c get color]
set o [Config new]
oo::objdefine $o method hello {} {return "only I can say hi"}
puts [$o hello]}
    out {blue
only I can say hi}
    tip {Inside TclOO code, `my` calls a method of the current object (or class, in a class-level method). Keep objects small: one job each, with the data private and the behaviour in methods.}
  }}
}
ex {
  {kind predict code {oo::class create A {method who {} {return a}}
oo::class create B {superclass A}
puts [[B new] who]} choices {a B {} who} ans 0 why {B inherits `who` from A.}}
  {kind predict code {oo::class create M {method t {} {return "<[next]>"}}
oo::class create C {method t {} {return core}}
oo::define C mixin M
puts [[C new] t]} choices {<core> core <> M} ans 0 why {The mixin's method runs first and wraps the original through `next`.}}
  {kind predict code {oo::class create D {destructor {puts bye}}
set d [D new]
$d destroy
puts after} choices {{bye
after} after {after
bye} bye} ans 0 why {The destructor runs during `destroy`, before the next line.}}
  {kind predict code {oo::class create K {method m {} {}}
puts [info object class [K new]]} choices {::K K object {}} ans 0 why {`info object class` reports the object's class (fully qualified).}}
  {kind predict code {oo::class create P {
    variable v
    constructor {x} {set v $x}
    method get {} {return $v}
}
set a [P new 1]
set b [P new 2]
puts "[$a get][$b get]"} choices {12 11 22 21} ans 0 why {Each object has its own copy of `v`.}}
  {kind predict code {oo::class create Q {method m {} {return class}}
set o [Q new]
oo::objdefine $o method m {} {return object}
puts [$o m]} choices {object class {} m} ans 0 why {An object-specific method overrides the class's method for that one object.}}
  {kind mc q {What is a mixin for?} choices {{Adding reusable behaviour to a class without inheritance} {Hiding a class's variables} {Deleting methods} {Making a class faster}} ans 0 why {Mixins wrap a class's methods with extra behaviour, and are reusable across unrelated classes.}}
  {kind mc q {What does `oo::objdefine $obj method ...` do?} choices {{Adds a method to that single object only} {Adds a method to every object} {Deletes the object} {Renames the class}} ans 0 why {It customises one object without changing its class.}}
  {kind blank q {Run code when an object is removed.} code {oo::class create Tmp {
    ___ {puts gone}
}
[Tmp new] destroy} answers {destructor} extra {constructor finalize exit} out {gone} why {`destructor` is the cleanup counterpart of `constructor`.}}
  {kind type q {Which command lists information about an object, such as its class?} accept {info object} why {`info object class $obj`.}}
  {kind code prompt {Write a TclOO class **Account** with a constructor taking an opening balance, and methods **deposit n**, **withdraw n** (raise the error **insufficient funds** if it would go below zero) and **balance**.} starter {oo::class create Account {
}} solution {oo::class create Account {
    variable bal
    constructor {start} {set bal $start}
    method deposit {n} {incr bal $n}
    method withdraw {n} {
        if {$n > $bal} {error "insufficient funds"}
        incr bal -$n
    }
    method balance {} {return $bal}
}} tests {{set a [Account new 100]; $a deposit 50; $a withdraw 30; $a balance} 120 {set a [Account new 10]; catch {$a withdraw 20} m; set m} {insufficient funds}} why {Keep the balance in the object's own variable; check before withdrawing.}}
}
cards {
  {{What is a mixin?} {A class whose methods are layered around another class's methods (via `oo::define Class mixin Mix`), reachable with `next`.}}
  {{Which methods run when an object is created and destroyed?} {`constructor` and `destructor`.}}
  {{How do you add a method to one object only?} {`oo::objdefine $obj method name args body`.}}
  {{Which commands introspect objects and classes?} {`info object class $obj`, `info class methods Class`, `info class instances Class`.}}
}
}

content::lesson 13.4 13 "Metaprogramming and mini-languages" "Programs that write programs, and languages built inside Tcl." {
pages {
  {head "Code that writes code" body {
    p {Because a proc body is just a string, a loop can **create procs**. Use `list` to build the body so every value is quoted correctly.}
    code {foreach {name op} {add + sub - mul *} {
    proc $name {a b} [list expr "\$a $op \$b"]
}
puts [add 6 3]
puts [sub 6 3]
puts [mul 6 3]
puts [info body add]}
    out {9
3
18
expr {$a + $b}}
    p {Three procs from one loop, and `info body` proves each has its own body. This is how big Tcl libraries generate repetitive code instead of copy-pasting it.}
  }}
  {head "A mini-language in a safe interpreter" body {
    p {Tcl is ideal for writing small **domain-specific languages**: configuration files, build scripts, test descriptions. Give a **safe interpreter** just the commands of your language, and the user's file can say what it wants but cannot do harm.}
    code {set cfg {}
set i [interp create -safe]
$i alias option apply {{k v} {dict set ::cfg $k $v}}
$i eval {
    option name demo
    option port 8080
}
puts $cfg
interp delete $i}
    out {name demo port 8080}
    p {The "file" is ordinary Tcl, but the only command it has is `option`. Tcl's own syntax gives your language variables, loops and conditions for free.}
  }}
  {head "Wrapping and aliasing commands" body {
    p {Commands can be renamed, so you can **wrap** one - adding logging, timing or checks - without touching its callers. `interp alias` creates a new name for a command, optionally with arguments filled in.}
    code {proc add {a b} {expr {$a + $b}}
rename add add_orig
proc add {a b} {
    puts "add called with $a $b"
    add_orig $a $b
}
puts [add 2 3]
interp alias {} double {} apply {{x} {expr {$x * 2}}}
puts [double 21]}
    out {add called with 2 3
5
42}
    warn {Metaprogramming is powerful and easy to overdo. Prefer plain procs and data until duplication or a genuine language need appears, and always build code with `list`, never with string pasting.}
  }}
}
ex {
  {kind predict code {foreach {n v} {a 1 b 2} {
    proc $n {} [list return $v]
}
puts "[a][b]"} choices {12 ab {a b} 21} ans 0 why {The loop created two procs returning 1 and 2.}}
  {kind predict code {proc greet {} {return hi}
rename greet hello
puts [hello]} choices {hi greet {} hello} ans 0 why {`rename` changes the name, not the behaviour.}}
  {kind predict code {proc f {} {return 1}
rename f f_old
proc f {} {return [expr {[f_old] + 1}]}
puts [f]} choices {2 1 0 3} ans 0 why {The new `f` calls the old one and adds one.}}
  {kind predict code {interp alias {} triple {} apply {{x} {expr {$x * 3}}}
puts [triple 5]} choices {15 5 8 triple} ans 0 why {The alias runs the lambda with the argument.}}
  {kind predict code {set cfg {}
set i [interp create -safe]
$i alias set_opt apply {{k v} {dict set ::cfg $k $v}}
$i eval {set_opt a 1; set_opt b 2}
puts [dict size $cfg]} choices {2 1 0 {a b}} ans 0 why {Two options were recorded in the parent's `cfg`.}}
  {kind predict code {proc mk {n} {return [list expr "\$x * $n"]}
puts [mk 4]} choices {{expr {$x * 4}} {expr $x * 4} {$x * 4} 4} ans 0 why {`list` brace-quotes the multi-word argument, giving a correctly formed command.}}
  {kind mc q {Why run a user's configuration "file" in a safe interpreter with a few aliases?} choices {{It can use Tcl syntax but only the commands you allow} {It runs faster} {It cannot contain comments} {Safe interpreters are required for files}} ans 0 why {You get a flexible language with a tiny, safe vocabulary.}}
  {kind mc q {What is the safest way to build a proc body from variables?} choices {{With `list`, so values are quoted correctly} {By gluing strings with dots} {With `format` only} {With `eval`}} ans 0 why {`list` prevents values from changing the structure of the code.}}
  {kind blank q {Give the command a second name that fills in an argument.} code {interp ___ {} twice {} expr 2 *
puts [twice 21]} answers {alias} extra {rename proc link} out {42} why {`interp alias {} newname {} command args...`.}}
  {kind type q {Which command changes the name of an existing command?} accept {rename} why {`rename old new`.}}
  {kind code prompt {Write a proc **defconst** taking a name and a value that creates a proc with that name returning the value: after `defconst pi 3.14`, `pi` returns 3.14.} starter {proc defconst {name value} {
}} solution {proc defconst {name value} {
    proc $name {} [list return $value]
}} tests {{defconst pi 3.14; pi} 3.14 {defconst two {a b}; llength [two]} 2} why {`list return $value` builds a correctly quoted body.}}
  {kind code prompt {Write a proc **counted** that wraps an existing proc named by its argument so that calls are counted in the global variable **calls**.} starter {proc counted {name} {
}} solution {proc counted {name} {
    rename $name ${name}_orig
    proc $name args [format {incr ::calls; %s_orig {*}$args} $name]
}} tests {{set ::calls 0; proc sq {x} {expr {$x*$x}}; counted sq; sq 2; sq 3; list [sq 4] $::calls} {16 3}} why {Rename the original, then define a proc with the old name that counts and forwards its arguments.}}
}
cards {
  {{How can a loop create procs?} {`proc $name args [list ...body...]` inside the loop, using `list` to quote the body safely.}}
  {{Why are safe interpreters good for mini-languages?} {They expose only the commands you alias, so user files cannot do harm.}}
  {{How do you wrap a command?} {`rename cmd cmd_orig`, then define a new `cmd` that does extra work and calls `cmd_orig`.}}
  {{What does `interp alias {} new {} cmd args` do?} {Creates `new` as a name for `cmd` with the leading arguments pre-filled.}}
}
}

content::lesson 13.5 13 "Errors by design" "Error codes, throw and trap, rethrowing and tail calls." {
pages {
  {head "Error codes and options" body {
    p {An error is more than a message. It carries an **error code** - a list you can match on - and an **options dictionary**. `return -code error -errorcode {...} message` raises a well-formed one, and `catch` can capture the options.}
    code {proc div {a b} {
    if {$b == 0} {
        return -code error -errorcode {MATH DIVZERO} "cannot divide $a by zero"
    }
    expr {$a / $b}
}
catch {div 1 0} msg opts
puts $msg
puts [dict get $opts -errorcode]}
    out {cannot divide 1 by zero
MATH DIVZERO}
    p {Callers can react to the **code** rather than parsing the wording of the message, which may change.}
  }}
  {head "throw and trap" body {
    p {`throw` is the short way to raise an error with a code. `try ... trap {code}` handles only errors whose code **starts with** the pattern; others pass through.}
    code {proc parse {s} {
    if {![string is integer -strict $s]} {
        throw {PARSE NOTINT} "not an integer: $s"
    }
    return $s
}
foreach v {5 x} {
    try {
        puts "ok [parse $v]"
    } trap {PARSE NOTINT} {msg} {
        puts "caught: $msg"
    }
}}
    out {ok 5
caught: not an integer: x}
    p {A hierarchy of codes - `MYAPP`, `MYAPP IO`, `MYAPP IO TIMEOUT` - lets one handler catch a whole family or a single specific error.}
  }}
  {head "Rethrowing and tail calls" body {
    p {To log an error and let it continue upward, `return -options $opts $msg` re-raises it unchanged. And `tailcall` replaces the current call instead of stacking a new one, so deep tail recursion uses constant stack.}
    code {proc risky {} {error "boom"}
proc wrapper {} {
    try {
        risky
    } on error {msg opts} {
        puts "logging: $msg"
        return -options $opts $msg
    }
}
catch {wrapper} m
puts "outer got: $m"}
    out {logging: boom
outer got: boom}
    code {proc fact {n {acc 1}} {
    if {$n <= 1} {return $acc}
    tailcall fact [expr {$n - 1}] [expr {$acc * $n}]
}
puts [fact 20]
puts [string length [fact 1000]]}
    out {2432902008176640000
2568}
  }}
}
ex {
  {kind predict code {catch {error "bad" "" {APP BAD}} msg opts
puts [dict get $opts -errorcode]} choices {{APP BAD} bad {} BAD} ans 0 why {The third argument of `error` is the error code.}}
  {kind predict code {try {
    throw {X Y} "oops"
} trap {X} {m} {
    puts "trapped $m"
}} choices {{trapped oops} oops {} X} ans 0 why {`trap {X}` matches any code starting with X.}}
  {kind predict code {try {
    throw {A B} "oops"
} trap {C} {m} {
    puts "never"
} on error {m} {
    puts "other: $m"
}} choices {{other: oops} never oops {} } ans 0 why {The code does not start with C, so the generic `on error` clause handles it.}}
  {kind predict code {proc f {} {return -code error -errorcode {E1 E2} "msg"}
catch {f} m o
puts [lindex [dict get $o -errorcode] 1]} choices {E2 E1 msg {E1 E2}} ans 0 why {The error code is the list `E1 E2`; its second item is E2.}}
  {kind predict code {proc loop {n acc} {
    if {$n == 0} {return $acc}
    tailcall loop [expr {$n - 1}] [expr {$acc + $n}]
}
puts [loop 100 0]} choices {5050 100 0 4950} ans 0 why {1 + 2 + ... + 100 = 5050, with constant stack depth.}}
  {kind predict code {proc w {} {
    try {error "inner"} finally {puts cleanup}
}
catch {w} m
puts $m} choices {{cleanup
inner} {inner
cleanup} inner cleanup} ans 0 why {`finally` runs first, then the error carries on to `catch`.}}
  {kind mc q {Why match on an error **code** rather than the message text?} choices {{Messages change and are meant for humans; codes are stable} {Codes are shorter} {Messages cannot be read} {Codes are faster to print}} ans 0 why {A code is a contract between the code that raises and the code that handles.}}
  {kind mc q {What does `tailcall` give you?} choices {{A call that replaces the current one, so recursion does not grow the stack} {A call that runs later} {A call that ignores errors} {A faster `expr`}} ans 0 why {Proper tail calls make loops-by-recursion safe.}}
  {kind blank q {Raise an error with a code in one command.} code {catch {___ {APP FAIL} "failed"} m o
puts [dict get $o -errorcode]} answers {throw} extra {error return raise} out {APP FAIL} why {`throw code message`.}}
  {kind type q {Which try clause matches a specific error code?} accept {trap} why {`trap {code} {var} {...}`.}}
  {kind code prompt {Write a proc **safeparse** that returns the integer, or raises an error with code `{PARSE NOTINT}` and message `not an integer: X` (where X is the input).} starter {proc safeparse {s} {
    return $s
}} solution {proc safeparse {s} {
    if {![string is integer -strict $s]} {
        throw {PARSE NOTINT} "not an integer: $s"
    }
    return $s
}} tests {{safeparse 12} 12 {catch {safeparse abc} m o; list $m [dict get $o -errorcode]} {{not an integer: abc} {PARSE NOTINT}}} why {`throw` raises an error with both a code and a message.}}
  {kind code prompt {Write a proc **sumto** using `tailcall` so `sumto 100000 0` does not overflow the stack: sumto n acc adds n down to 1 into acc.} starter {proc sumto {n acc} {
    return $acc
}} solution {proc sumto {n acc} {
    if {$n == 0} {return $acc}
    tailcall sumto [expr {$n - 1}] [expr {$acc + $n}]
}} tests {{sumto 100000 0} 5000050000} why {The tail call reuses the stack frame, so 100000 steps are fine.}}
}
cards {
  {{What does an error carry besides its message?} {An error code (a list to match on) and an options dictionary (`-errorcode`, `-errorinfo`, `-code`...).}}
  {{How do you raise and handle a coded error?} {`throw {APP KIND} "message"` and `try {...} trap {APP KIND} {msg} {...}`.}}
  {{How do you re-raise an error after logging it?} {`return -options $opts $msg` inside `on error {msg opts}`.}}
  {{What is `tailcall` for?} {It replaces the current call, so recursive loops use constant stack.}}
}
}

content::lesson 13.6 13 "Tcllib and the Tcl ecosystem" "Standing on the shoulders of a large library." {
pages {
  {head "Packages and versions" body {
    p {Tcl's package system lets one program use thousands of libraries. `package require name ?version?` loads one, and Tcl can compare version numbers for you.}
    code {puts [package vcompare 8.6.10 8.6.9]
puts [package vsatisfies 8.6.10 8.6]
puts [package vsatisfies 8.5 8.6-]
package require Tcl 8.6-
puts "ok"}
    out {1
1
0
ok}
    p {`vcompare` returns -1, 0 or 1. `vsatisfies 8.6.10 8.6` asks "is 8.6.10 acceptable where 8.6 is required?" and `8.6-` means "8.6 or newer".}
  }}
  {head "A tour of Tcllib" body {
    p {**Tcllib** is the big standard library of pure-Tcl packages. A few you will use again and again:}
    p {- `json` and `json::write` - read and write JSON
- `csv` - parse and produce CSV files
- `struct::list`, `struct::set`, `struct::matrix`, `struct::tree` - data structures
- `cmdline` - parse command-line options
- `textutil` - wrap, indent and trim text
- `md5`, `sha256`, `base64` - hashing and encoding
- `logger` - levelled logging
- `uri`, `html` - web helpers}
    show {package require json
set data [json::json2dict {{"name": "Ada", "langs": ["Tcl", "C"]}}]
puts [dict get $data name]
puts [lindex [dict get $data langs] 0]

package require csv
puts [csv::split {a,"b,c",d}]}
    p {These examples use packages that live outside the core, so they are shown but not run in this app's sandbox. On a normal install, `tclsh` finds them in the Tcl library directories listed in `auto_path`.}
  }}
  {head "The wider world" body {
    p {Beyond Tcllib:}
    p {- **Tk** - the GUI toolkit (the next three lessons)
- **Thread** - real threads with message passing
- **sqlite3** - an embedded SQL database, with a Tcl interface built in to many distributions
- **http** and **tls** - web clients and secure sockets
- **tdom** - fast XML and HTML handling
- **Expect** - automating interactive programs
- **TclOO frameworks** and **tcltest** for structure and testing}
    p {For packaging, a **starkit** or **tclkit** bundles a script and a Tcl runtime into one file, and `package ifneeded` / `tcl::tm` modules (`name-1.0.tm`) let you ship your own libraries. The community lives at **tcl-lang.org** and the wiki at **wiki.tcl-lang.org** - searching the wiki before writing something is a Tcl habit worth keeping.}
    tip {Before writing a utility yourself, check Tcllib. Before using a package, read its tests - they show exactly how it is meant to be used.}
  }}
}
ex {
  {kind predict code {puts [package vcompare 8.5 8.6]} choices {-1 1 0 8.5} ans 0 why {8.5 is older than 8.6.}}
  {kind predict code {puts [package vsatisfies 8.6.14 8.6]} choices {1 0 8.6.14 {}} ans 0 why {Any 8.6.x satisfies a requirement of 8.6.}}
  {kind predict code {puts [package vsatisfies 9.0 8.6]} choices {0 1 9.0 -1} ans 0 why {A requirement of `8.6` means major version 8; 9.0 does not satisfy it.}}
  {kind mc q {What is Tcllib?} choices {{A large library of pure-Tcl packages} {Tcl's compiler} {A text editor} {A Tcl command} } ans 0 why {Tcllib collects JSON, CSV, data structures, hashing, logging and much more.}}
  {kind mc q {Which command loads a package?} choices {{package require} {source package} {load name} {import name}} ans 0 why {`package require name ?version?`.}}
  {kind mc q {What is a starkit/tclkit used for?} choices {{Bundling a script and a Tcl runtime into a single file} {Sorting lists} {Testing code} {Compiling Tcl to machine code}} ans 0 why {It makes a program easy to ship as one executable.}}
  {kind mc q {Which package gives you real operating-system threads?} choices {Thread tcltest http json} ans 0 why {The `Thread` package.}}
  {kind mc q {Why read a package's tests?} choices {{They show exactly how it is meant to be used} {They are required by `package require`} {They run faster than the package} {They contain the license}} ans 0 why {Tests are executable documentation.}}
  {kind type q {Which variable lists the directories Tcl searches for packages?} accept {auto_path} why {`auto_path`.}}
  {kind type q {Which package would you use to read JSON? (give the package name)} accept {json} why {`package require json` from Tcllib.}}
}
cards {
  {{What does `package require name 8.6` do?} {Loads the package, demanding a version that satisfies 8.6; errors if none is found.}}
  {{What is Tcllib?} {The standard library of pure-Tcl packages: json, csv, struct, cmdline, textutil, md5, logger, uri...}}
  {{Where does Tcl look for packages?} {In the directories listed in `auto_path` (and `tcl::tm::path` for .tm modules).}}
  {{What is a starkit?} {A single-file bundle of a script plus a Tcl runtime, for easy distribution.}}
}
}

content::lesson 13.7 13 "Tk in depth: layout and widgets" "Lay out a real window: grid, pack, themed widgets and resizing." {
pages {
  {head "grid: rows and columns" body {
    p {For forms and anything table-like, `grid` places widgets in rows and columns. `-sticky` says which edges a widget clings to, and `columnconfigure` / `rowconfigure` with `-weight` say which columns and rows stretch when the window is resized.}
    show {package require Tk
ttk::label .l1 -text "Name:"
ttk::entry .e1 -textvariable name
ttk::label .l2 -text "Email:"
ttk::entry .e2 -textvariable email
ttk::button .ok -text "Save" -command save

grid .l1 .e1 -sticky ew -padx 4 -pady 2
grid .l2 .e2 -sticky ew -padx 4 -pady 2
grid .ok -columnspan 2 -pady 6

grid columnconfigure . 1 -weight 1}
    p {Reading it: two rows of label + entry, a button spanning both columns, and column 1 (the entries) stretches. `-sticky ew` makes the entries fill their cell east-to-west.}
    tip {Never mix `pack` and `grid` in the **same parent**. Use one geometry manager per container, and nest frames to combine them.}
  }}
  {head "pack, place and frames" body {
    p {`pack` stacks widgets along a side: good for toolbars and simple layouts. `place` positions by exact coordinates or fractions (`-relx .5`): good for overlays. Frames group widgets so each group can use its own manager.}
    show {frame .tools
button .tools.a -text "A"
button .tools.b -text "B"
pack .tools.a .tools.b -side left -padx 2
pack .tools -side top -fill x

text .t -width 40 -height 10
pack .t -side top -fill both -expand 1

label .status -text "Ready" -anchor w
pack .status -side bottom -fill x}
    p {`-fill both -expand 1` is the pair you will use most: stretch in both directions and claim any spare space.}
  }}
  {head "Themed ttk widgets" body {
    p {`ttk::` widgets (button, entry, label, notebook, treeview, progressbar, combobox...) draw themselves natively and can be restyled with `ttk::style`. They keep their state in **state flags**, not options.}
    show {ttk::notebook .nb
.nb add [ttk::frame .nb.home] -text "Home"
.nb add [ttk::frame .nb.prefs] -text "Prefs"
pack .nb -fill both -expand 1

ttk::button .nb.home.go -text "Go"
.nb.home.go state disabled
puts [.nb.home.go instate disabled]   ;# 1

ttk::style configure TButton -padding 8
ttk::progressbar .p -mode determinate -value 40}
    p {A widget's path name encodes its parent: `.nb.home.go` is `go` inside `home` inside `nb`. Learn the layout of a window by reading its path names.}
  }}
}
ex {
  {kind mc q {Which option makes a gridded widget stretch to fill its cell horizontally?} choices {{-sticky ew} {-expand 1} {-fill x} {-weight 1}} ans 0 why {`-sticky` belongs to `grid`; `-fill`/`-expand` belong to `pack`.}}
  {kind mc q {What does `grid columnconfigure . 1 -weight 1` do?} choices {{Lets column 1 take extra space when the window grows} {Makes column 1 invisible} {Sets column 1's width to 1} {Deletes column 1}} ans 0 why {Weights decide which rows/columns stretch.}}
  {kind mc q {Why not use `pack` and `grid` together in one parent?} choices {{They fight over layout and can freeze the program} {It is slower} {They use different fonts} {It is a syntax error}} ans 0 why {Use one manager per container and nest frames.}}
  {kind mc q {What does `pack .t -fill both -expand 1` do?} choices {{Stretches the widget in both directions and gives it spare space} {Packs it twice} {Hides it} {Aligns it left}} ans 0 why {The classic resizing recipe.}}
  {kind mc q {In the path name `.nb.home.go`, what is `go`?} choices {{A widget inside the widget `.nb.home`} {The main window} {A command option} {A variable}} ans 0 why {Each dot nests a child inside its parent.}}
  {kind mc q {Which geometry manager positions by coordinates or fractions of the parent?} choices {place grid pack wm} ans 0 why {`place -relx .5 -rely .5` centres a widget.}}
  {kind type q {Which command makes a themed (native-looking) button?} accept {ttk::button} why {`ttk::button`.}}
  {kind type q {What option on `grid` says which edges a widget clings to?} accept {-sticky sticky} why {`-sticky nsew`.}}
}
cards {
  {{When do you use grid, pack and place?} {grid for rows/columns, pack for simple stacks and toolbars, place for exact or fractional positioning.}}
  {{What does `-sticky ew` do?} {Makes a widget in a grid cell stretch east to west (fill the cell's width).}}
  {{What does `pack -fill both -expand 1` mean?} {Fill the available space in both directions and take spare room when the window grows.}}
  {{What are ttk widgets?} {Themed widgets (`ttk::button`, `ttk::entry`, `ttk::notebook`...) that draw natively and are styled with `ttk::style`.}}
}
}

content::lesson 13.8 13 "Tk in depth: events and the canvas" "Bindings, the canvas, and animating with after." {
pages {
  {head "bind and event details" body {
    p {`bind widget <Sequence> script` runs a script on an event. Inside the script, `%`-codes are replaced with details: `%x %y` the position, `%W` the widget, `%K` the key, `%b` the mouse button. **Virtual events** like `<<Copy>>` give meaning-based names, and you can create your own and send them with `event generate`.}
    show {bind .c <Button-1> {puts "clicked at %x,%y in %W"}
bind . <Key-Escape> {exit}
bind .e <Return> {submit}

event add <<Save>> <Control-s>
bind . <<Save>> {save}
event generate . <<Save>>}
    p {Mouse events: `<Button-1>`, `<B1-Motion>`, `<ButtonRelease-1>`, `<Double-Button-1>`, `<Enter>`, `<Leave>`. Keyboard: `<KeyPress-a>`, `<Control-s>`, `<Return>`. Widget events: `<Configure>` (resized), `<FocusIn>`, `<Destroy>`.}
    tip {This app uses `<Configure>` everywhere: a canvas redraws itself when its size changes. Responding to size changes is how Tk layouts stay flexible.}
  }}
  {head "The canvas" body {
    p {A **canvas** draws shapes that stay alive as objects: rectangles, ovals, lines, polygons, text, images and even other widgets. Each item has an id and can carry **tags** so you can move, recolour or delete groups at once.}
    show {canvas .c -width 300 -height 200 -bg white
pack .c
set r [.c create rectangle 20 20 120 80 -fill skyblue -tags box]
.c create oval 150 40 250 140 -fill gold -tags {ball shape}
.c create text 150 170 -text "Hello" -font {Helvetica 16}

.c move box 10 0            ;# move everything tagged "box"
.c itemconfigure shape -fill orange
.c bind ball <Button-1> {puts "ball!"}
puts [.c bbox ball]         ;# bounding box
.c delete box}
    p {Item **bindings** are the canvas superpower: `.c bind ball <Button-1> ...` makes just that shape clickable.}
  }}
  {head "Animation with after" body {
    p {Animation is just `after` rescheduling itself, moving things a little each time. Never loop with `sleep`; that freezes the interface because the event loop cannot run.}
    show {proc step {} {
    .c move ball 3 0
    lassign [.c coords ball] x1 y1 x2 y2
    if {$x2 < 300} {
        after 16 step       ;# about 60 frames per second
    }
}
step}
    p {Each call moves the ball and, if it is still on screen, schedules the next frame 16 ms later. In between, Tk handles clicks, resizes and redraws. This is the same technique behind this app's confetti and drag-scrolling inertia.}
  }}
}
ex {
  {kind mc q {What does `%x` mean inside a bind script?} choices {{The x coordinate of the event} {The widget name} {The key pressed} {The time}} ans 0 why {`%x %y` are coordinates; `%W` is the widget; `%K` the key.}}
  {kind mc q {What is a virtual event such as `<<Save>>` for?} choices {{Giving an action a meaningful name that can be bound to several keys} {Creating a fake mouse} {Slowing events down} {Logging errors}} ans 0 why {`event add <<Save>> <Control-s>` maps keys to a named action.}}
  {kind mc q {Why animate with `after` rather than a loop with a delay?} choices {{The event loop keeps running, so the interface stays responsive} {`after` is more accurate} {Loops are not allowed in Tk} {It uses less memory}} ans 0 why {A blocking delay freezes everything.}}
  {kind mc q {What is a canvas tag for?} choices {{Grouping items so they can be moved, changed or bound together} {Giving the canvas a title} {Setting the canvas size} {Saving the canvas}} ans 0 why {`.c move tagname dx dy` acts on every item with that tag.}}
  {kind mc q {Which event fires when a widget changes size?} choices {<Configure> <Resize> <Size> <Change>} ans 0 why {`<Configure>`.}}
  {kind mc q {How do you make just one canvas shape clickable?} choices {{.c bind tagOrId <Button-1> script} {bind .c <Button-1> script only} {.c click tagOrId} {Create a button on top of it}} ans 0 why {Canvas item bindings attach to the item or tag.}}
  {kind type q {Which command sends a virtual event programmatically?} accept {event generate} why {`event generate . <<Save>>`.}}
  {kind type q {Which canvas subcommand moves items by an offset?} accept {move} why {`.c move tag dx dy`.}}
}
cards {
  {{What are %x, %y, %W and %K in a bind script?} {Event details: the x and y position, the widget path and the key pressed.}}
  {{How do canvas tags help?} {They let you move, configure, bind or delete a group of items at once.}}
  {{How do you animate in Tk?} {A proc that moves things a little and reschedules itself with `after 16 proc`, keeping the event loop free.}}
  {{What is `event generate` used for?} {Sending a (virtual) event to a widget from code, e.g. `event generate . <<Save>>`.}}
}
}

content::lesson 13.9 13 "Tk in depth: building and structuring an app" "Patterns for real programs - illustrated by the source of this very app." {
pages {
  {head "Keep state separate from widgets" body {
    p {A maintainable GUI keeps its **data** in plain Tcl structures (a dict, a namespace, an object) and treats widgets as a view of that data. Link them with `-textvariable`, variable **traces**, or by rebuilding the view when the data changes.}
    show {namespace eval model {
    variable items {}
    proc add {x} {variable items; lappend items $x; notify}
    proc notify {} {event generate . <<ModelChanged>>}
}
bind . <<ModelChanged>> {refreshList}

proc refreshList {} {
    .lb delete 0 end
    foreach i $model::items {.lb insert end $i}
}}
    p {The model knows nothing about widgets; it just announces a change. The view listens and redraws. You can test the model with no window at all.}
  }}
  {head "How this app is built" body {
    p {Learn Tcl is about 3,500 lines of Tcl and Tk, organised exactly like that:}
    p {- `lib/store.tcl` and `lib/srs.tcl` - state and scheduling, no widgets (unit-tested headlessly)
- `lib/content.tcl` and `content/*.tcl` - the course as **data**
- `lib/sandbox.tcl` - a child interpreter with limits, as you learned in the safe-interpreter lesson
- `lib/ui.tcl`, `lib/aa.tcl`, `lib/flat.tcl` - the drawing toolkit: canvas widgets, anti-aliased images, a "freeze to one canvas" trick for fast scrolling
- `lib/exercises.tcl`, `lib/runner.tcl`, `lib/screens.tcl` - the screens, built from the toolkit
- `tests/` - content verification, the scheduler, and a UI test that taps through every lesson}
    p {Notice the habits from this course: namespaces per module, dicts for records, `after` for animation, `uplevel`/`upvar` where needed, `try`/`catch` around risky steps, and tests for everything that can be tested.}
  }}
  {head "Dialogs, menus and shipping" body {
    p {Standard dialogs save you work: `tk_messageBox`, `tk_getOpenFile`, `tk_getSaveFile`, `tk_chooseColor`. Menus come from the `menu` widget. Window behaviour comes from `wm` (title, size, close handler).}
    show {proc quit {} {
    if {[tk_messageBox -type yesno -message "Quit?"] eq "yes"} exit
}
wm protocol . WM_DELETE_WINDOW quit
wm title . "My App"

menu .m
. configure -menu .m
menu .m.file -tearoff 0
.m add cascade -label File -menu .m.file
.m.file add command -label "Open..." -command {set f [tk_getOpenFile]}
.m.file add command -label Quit -command quit}
    p {To ship: a starkit/tclkit wraps your script and runtime in one file; or, as this project does, you can embed the script in a runtime for a platform such as Android. Either way, your Tcl source is the app.}
    tip {You have now seen every layer: language, data, files, networking, objects, events, testing and GUI. The best next step is a project of your own - the capstone projects in the next unit are good practice.}
  }}
}
ex {
  {kind mc q {Why keep program data separate from widgets?} choices {{The data can be tested without a window and the view can change freely} {Widgets cannot hold data} {It makes the program shorter} {Tk requires it}} ans 0 why {Separation of model and view is the foundation of maintainable GUIs.}}
  {kind mc q {Which of these links a widget directly to a variable?} choices {-textvariable -command -text -variable-name} ans 0 why {`-textvariable` keeps a label or entry in sync with a variable.}}
  {kind mc q {What does `wm protocol . WM_DELETE_WINDOW quit` do?} choices {{Runs your `quit` proc when the user closes the window} {Deletes the window} {Hides the window} {Prevents closing forever}} ans 0 why {It intercepts the close button so you can confirm or save first.}}
  {kind mc q {Which command shows a standard "open file" dialog?} choices {tk_getOpenFile open_file tk_open file_dialog} ans 0 why {`tk_getOpenFile`.}}
  {kind mc q {In this app, which files can be unit-tested without any display?} choices {{store, srs, sandbox and content} {ui and flat} {screens and runner} {None of them}} ans 0 why {They contain no widgets, which is exactly why they are separate.}}
  {kind mc q {Why does this app build the course as data in `content/*.tcl`?} choices {{So lessons can be verified by running them, and edited without touching the UI code} {Because Tk cannot display text} {To make the program bigger} {Because data files are faster}} ans 0 why {Data-driven design lets a test run every example.}}
  {kind type q {Which command controls window properties such as title and size?} accept {wm} why {`wm title . "Name"`, `wm geometry . 400x300`.}}
  {kind type q {Which widget command creates a menu?} accept {menu} why {`menu .m`.}}
}
cards {
  {{What is the model/view idea for GUIs?} {Keep data in plain Tcl structures and treat widgets as a view that redraws when the data changes.}}
  {{Name Tk's standard dialogs.} {`tk_messageBox`, `tk_getOpenFile`, `tk_getSaveFile`, `tk_chooseColor`.}}
  {{What does `wm protocol . WM_DELETE_WINDOW cmd` do?} {Calls `cmd` when the user closes the window, so you can confirm or save.}}
  {{Why separate lib files for state, UI and tests?} {Non-UI code can be tested headlessly and reused; the UI stays thin.}}
}
}
