content::unit 15 "Language deep-dives" "The corners of Tcl that complete your command of the language." "#60A5FA"

content::lesson 15.1 15 "Numbers in depth" "Integers of any size, floating-point surprises, rounding and operators as commands." {
pages {
  {head "Integers, bignums and floats" body {
    p {Tcl integers have **no fixed size**: they grow as needed, so you can compute with enormous numbers. Decimal numbers are 64-bit floating point, which cannot represent every fraction exactly - the same in every language.}
    code {puts [expr {2**100}]
puts [expr {0.1 + 0.2}]
puts [expr {7 == 7.0}]
puts [expr {1/3.0}]
puts [format %.3f [expr {1/3.0}]]}
    out {1267650600228229401496703205376
0.30000000000000004
1
0.3333333333333333
0.333}
    p {`0.1 + 0.2` is not exactly 0.3 because 0.1 has no exact binary form. Never compare floats with `==` for equality of calculations; compare the **difference** with a small tolerance, and use `format` for display.}
  }}
  {head "Division, remainder and rounding" body {
    p {Integer division **floors** (rounds toward minus infinity), and the remainder takes the sign of the divisor, so that `(a / b) * b + (a % b) == a` always holds. Conversion and rounding functions:}
    code {puts [expr {-7 / 2}]
puts [expr {-7 % 3}]
puts [expr {int(-3.9)}]
puts [expr {round(2.5)}]
puts [expr {round(-2.5)}]
puts [expr {floor(-1.5)}]
puts [expr {ceil(1.2)}]
puts [expr {isqrt(99)}]}
    out {-4
2
-3
3
-3
-2.0
2.0
9}
    p {`int()` truncates toward zero, `round()` rounds halves away from zero, `floor()` and `ceil()` return floats. `isqrt` is an exact integer square root.}
  }}
  {head "Maths functions and operators as commands" body {
    p {Every maths function is a command in `::tcl::mathfunc`, and every operator is a command in `::tcl::mathop`. That means operators work with `{*}` and `lmap`, and you can **define your own maths function**.}
    code {puts [::tcl::mathop::+ 1 2 3]
puts [::tcl::mathop::* {*}{2 3 4}]
puts [expr {max(1, 5.5, 3)}]
puts [expr {hypot(3, 4)}]
proc ::tcl::mathfunc::twice {x} {expr {$x * 2}}
puts [expr {twice(21)}]}
    out {6
24
5.5
5.0
42}
    tip {Prefix operators such as `::tcl::mathop::+` accept any number of arguments, so `+ {*}$list` adds up a whole list.}
  }}
}
ex {
  {kind predict code {puts [expr {2**10}]} choices {1024 20 100 2048} ans 0 why {`**` is exponentiation.}}
  {kind predict code {puts [expr {-7 / 2}]} choices {-4 -3 -3.5 3} ans 0 why {Integer division floors toward minus infinity.}}
  {kind predict code {puts [expr {-7 % 3}]} choices {2 -1 1 -2} ans 0 why {The remainder takes the sign of the divisor: -7 = -3 * 3 + 2.}}
  {kind predict code {puts [expr {int(-3.9)}]} choices {-3 -4 -3.0 3} ans 0 why {`int()` truncates toward zero.}}
  {kind predict code {puts [expr {round(2.5)}]} choices {3 2 2.5 3.0} ans 0 why {Halves round away from zero.}}
  {kind predict code {puts [expr {floor(-1.5)}]} choices {-2.0 -1.0 -2 -1} ans 0 why {`floor` returns a float, rounded toward minus infinity.}}
  {kind predict code {puts [expr {isqrt(99)}]} choices {9 10 9.9 99} ans 0 why {The integer part of the square root.}}
  {kind predict code {puts [::tcl::mathop::+ 1 2 3]} choices {6 {1 2 3} 123 +} ans 0 why {The `+` operator command adds all its arguments.}}
  {kind predict code {puts [expr {0.1 + 0.2 == 0.3}]} choices {0 1 true false} ans 0 why {Floating-point rounding makes the two sides differ slightly.}}
  {kind mc q {Why is `0.1 + 0.2` not exactly `0.3` in Tcl?} choices {{0.1 cannot be represented exactly in binary floating point} {Tcl has a bug} {`+` rounds up} {The numbers are strings}} ans 0 why {The same happens in every language that uses IEEE floating point.}}
  {kind mc q {How should you compare two computed floats?} choices {{Check that their difference is smaller than a small tolerance} {Always with ==} {Convert both to strings} {With eq}} ans 0 why {`expr {abs($a - $b) < 1e-9}`.}}
  {kind blank q {Add up all the numbers in a list with one operator command.} code {set nums {1 2 3 4}
puts [::tcl::mathop::+ ___$nums]} answers {{{*}}} extra {{...} {@} {&}} out {10} why {`{*}$nums` spreads the list as separate arguments.}}
  {kind code prompt {Write a proc **sumlist** that adds a list of numbers using `::tcl::mathop::+` and `{*}` (an empty list gives 0).} starter {proc sumlist {l} {
    return 0
}} solution {proc sumlist {l} {
    if {[llength $l] == 0} {return 0}
    return [::tcl::mathop::+ {*}$l]
}} tests {{sumlist {1 2 3}} 6 {sumlist {}} 0 {sumlist {2.5 2.5}} 5.0} why {`+` with no arguments returns 0 as well, but being explicit is clearer.}}
  {kind code prompt {Define a new maths function **cube** (use `::tcl::mathfunc::cube`) so that `expr {cube(3)}` is 27.} starter {# define it here
} solution {proc ::tcl::mathfunc::cube {x} {expr {$x * $x * $x}}} tests {{expr {cube(3)}} 27 {expr {cube(2) + 1}} 9} why {Procs in `::tcl::mathfunc` become functions inside `expr`.}}
  {kind code prompt {Write a proc **close** returning 1 when two numbers differ by less than 1e-9, else 0.} starter {proc close {a b} {
    return [expr {$a == $b}]
}} solution {proc close {a b} {
    return [expr {abs($a - $b) < 1e-9}]
}} tests {{close [expr {0.1 + 0.2}] 0.3} 1 {close 1 2} 0} why {Compare the difference, not the values.}}
}
cards {
  {{How big can a Tcl integer be?} {Arbitrarily big - integers grow as needed (`expr {2**100}` works).}}
  {{What does integer division do with negatives?} {It floors: `-7 / 2` is -4, and `-7 % 3` is 2.}}
  {{How do you compare floats?} {Check `abs($a - $b) < tolerance`, never `==`.}}
  {{Where do maths functions and operators live as commands?} {`::tcl::mathfunc::name` and `::tcl::mathop::op`; you can define your own functions there.}}
}
}

content::lesson 15.2 15 "The dict toolbox" "Everything dict can do - merge, replace, update, filter and more." {
pages {
  {head "Building and combining" body {
    p {Dictionaries are **values**, so every command that changes one either returns a new dict or updates a variable. `dict replace` and `dict merge` return new dicts; `dict append`, `dict lappend`, `dict incr`, `dict set` and `dict unset` update a variable.}
    code {puts [dict replace {a 1 b 2} b 9 c 3]
puts [dict merge {a 1 b 2} {b 20 c 3}]
puts [dict remove {a 1 b 2 c 3} a c]
set d {a 1}
dict append d a 5
puts $d
set e {}
dict lappend e k x y
puts $e}
    out {a 1 b 9 c 3
a 1 b 20 c 3
b 2
a 15
k {x y}}
    p {`merge` lets later dicts win. `append` concatenates **text** onto a value (1 and 5 become 15); `lappend` adds items to a **list** stored under the key.}
  }}
  {head "Selecting and transforming" body {
    p {Select keys by pattern, or filter by key, value or a script:}
    code {puts [dict keys {apple 1 avocado 2 banana 3} a*]
puts [dict filter {a 1 b 2 c 3} key {[ab]}]
puts [dict filter {a 1 b 2 c 3} value 2]
puts [dict get [dict create x {y {z 1}}] x y z]}
    out {apple avocado
a 1 b 2
b 2
1}
    p {Because values can be dicts, `dict get`, `dict set`, `dict exists` and `dict unset` all accept a **path** of keys. A path into a missing key raises an error from `get`, so test with `exists` first.}
  }}
  {head "update and with" body {
    p {`dict update d key var ... script` copies chosen keys into variables, runs the script, and writes the variables back (and deletes a key if you `unset` its variable). `dict with` does the same for **all** keys.}
    code {set d {a 1 b 2}
dict update d a v {set v 100}
puts $d
set rec {name Ada age 36}
dict with rec {incr age}
puts $rec}
    out {a 100 b 2
name Ada age 37}
    tip {A handy rule: use `dict get` to read, `dict set` to change one key, and `dict with`/`update` when you need several fields of a record at once.}
  }}
}
ex {
  {kind predict code {puts [dict merge {a 1 b 2} {b 5}]} choices {{a 1 b 5} {a 1 b 2} {b 5} {a 1 b 2 b 5}} ans 0 why {The later dict wins for duplicate keys.}}
  {kind predict code {puts [dict replace {a 1} a 2 b 3]} choices {{a 2 b 3} {a 1 b 3} {a 2} {a 1 a 2 b 3}} ans 0 why {`replace` overwrites and adds keys.}}
  {kind predict code {puts [dict remove {a 1 b 2 c 3} b]} choices {{a 1 c 3} {a 1 b 2} {b 2} {a c}} ans 0 why {`remove` drops the named keys.}}
  {kind predict code {set d {n 1}
dict append d n 0
puts $d} choices {{n 10} {n 1} {n 0} {n 1 0}} ans 0 why {`append` joins the text: "1" and "0" become "10".}}
  {kind predict code {set d {}
dict lappend d k 1
dict lappend d k 2
puts $d} choices {{k {1 2}} {k 12} {k 1 k 2} {{1 2}}} ans 0 why {`lappend` builds a list under the key.}}
  {kind predict code {puts [dict filter {a 1 b 2 c 3} value {[23]}]} choices {{b 2 c 3} {a 1} {b 2} {c 3}} ans 0 why {Values matching the pattern `[23]`.}}
  {kind predict code {set r {x 1 y 2}
dict with r {set x [expr {$x + $y}]}
puts $r} choices {{x 3 y 2} {x 1 y 2} {x 3} {x 2 y 2}} ans 0 why {`dict with` writes changed variables back into the dict.}}
  {kind predict code {puts [dict keys {apple 1 pear 2 plum 3} p*]} choices {{pear plum} {apple} {pear} {plum pear}} ans 0 why {The pattern `p*` selects the matching keys.}}
  {kind mc q {What is the difference between `dict append` and `dict lappend`?} choices {{`append` joins text onto a value; `lappend` adds an item to a list value} {They are the same} {`append` works on lists} {`lappend` only works on numbers}} ans 0 why {Choose by whether the stored value is text or a list.}}
  {kind mc q {What does `dict merge a b` do for keys present in both?} choices {{The value from b wins} {The value from a wins} {It raises an error} {Both are kept}} ans 0 why {Later dicts override earlier ones.}}
  {kind blank q {Update one key's variable inside a dict.} code {set d {n 5}
dict ___ d n v {incr v}
puts $d} answers {update} extra {with set get} out {n 6} why {`dict update d key var script`.}}
  {kind code prompt {Write a proc **mergeall** taking a list of dicts and returning them merged, later ones winning.} starter {proc mergeall {dicts} {
    return {}
}} solution {proc mergeall {dicts} {
    set r {}
    foreach d $dicts {set r [dict merge $r $d]}
    return $r
}} tests {{mergeall {{a 1} {b 2} {a 3}}} {a 3 b 2} {mergeall {}} {}} why {Fold the dicts together with `dict merge`.}}
  {kind code prompt {Write a proc **birthday** taking a person dict with an `age` key and returning the dict with age increased by one (use `dict incr`).} starter {proc birthday {p} {
    return $p
}} solution {proc birthday {p} {
    dict incr p age
    return $p
}} tests {{birthday {name Ada age 36}} {name Ada age 37}} why {`dict incr` changes the local copy of `p`; return it.}}
  {kind code prompt {Write a proc **getpath** that reads a nested dict value with a list of keys, returning a default when any key is missing: `getpath {a {b 1}} {a b} none` is 1.} starter {proc getpath {d keys default} {
    return $default
}} solution {proc getpath {d keys default} {
    if {[dict exists $d {*}$keys]} {return [dict get $d {*}$keys]}
    return $default
}} tests {{getpath {a {b 1}} {a b} none} 1 {getpath {a {b 1}} {a x} none} none} why {`dict exists` accepts a whole path; test before getting.}}
}
cards {
  {{Which dict commands return a new dict and which change a variable?} {`replace`, `merge`, `remove` return new dicts; `set`, `unset`, `incr`, `append`, `lappend`, `update`, `with` change a variable.}}
  {{When do you use `dict append` versus `dict lappend`?} {`append` joins text; `lappend` adds an item to a list stored under the key.}}
  {{What do `dict update` and `dict with` do?} {Make keys available as variables for a script and write changes back.}}
  {{How do you read a deep value safely?} {`if {[dict exists $d {*}$path]} {dict get $d {*}$path}`}}
}
}

content::lesson 15.3 15 "The twelve rules of Tcl" "The complete grammar of the language - short enough to memorise." {
pages {
  {head "How a script is read" body {
    p {Tcl's entire syntax is **twelve rules** (the "Dodekalogue"). Here they are in plain language, with the ones you will use most first:}
    p {- **Commands**: a script is commands separated by newlines or semicolons. A command is words separated by whitespace; the first word is the command name
- **Quotes** `"..."`: group words; substitutions still happen inside
- **Braces** `{...}`: group words **literally**; no substitutions, braces nest
- **Variable substitution** `$name`, `$name(index)` and `${any name}`
- **Command substitution** `[...]`: run the command and use its result
- **Backslash substitution**: `\n`, `\t`, `\\`, `\{`, and backslash-newline (a line continuation)
- **Comments**: `#` at the start of a command ignores the rest of the line
- **One pass**: each word is substituted exactly once, left to right}
    code {set a(x) 1
set v a(x)
puts [set $v]
set {my var} 5
puts ${my var}
set x 10
puts {$x [expr 1]}
puts "$x [expr {1 + 1}]"}
    out {1
5
$x [expr 1]
10 2}
    p {`${my var}` lets a variable name contain spaces. And `set $v` where `v` holds the text `a(x)` reads the array element - a first taste of **indirection**.}
  }}
  {head "Lists and quoting" body {
    p {The rules explain why `list` is special: it produces a string that, **when parsed by the rules**, gives back exactly the original items. Anything needing protection gets braces or backslashes.}
    code {puts [list a {b c} "d e" {} "f\{"]
puts [llength [list a {b c}]]
puts [llength "a {b c}"]
set x 10
set y {$x}
puts [subst $y]
puts [subst -nocommands {[expr 1] $x}]
puts [subst -novariables {[expr 1] $x}]}
    out {a {b c} {d e} {} f\{
2
2
10
[expr 1] 10
1 $x}
    p {The empty item became `{}`, the brace became `f\{`. `subst` applies rules 4-6 to a string on demand, and its flags switch parts off.}
  }}
  {head "Consequences" body {
    p {From the rules follow all the "gotchas" - and all the power:}
    p {- A `#` comment must start where a **command** could start (so use `;#` after a command)
- `if {$x > 1} {...}` works because braces keep the condition **unsubstituted** until `if` evaluates it
- A command receives words as **strings**; there are no hidden types
- Because code is just strings, `proc`, `if`, `foreach` and your own `repeat` are all ordinary commands taking braced bodies
- To evaluate twice you must ask for it (`eval`, `subst`, `uplevel`) - which is why Tcl is predictable}
    tip {When a line misbehaves, apply the rules by hand: split into words, perform the substitutions once, left to right, and look at the final words the command actually receives.}
  }}
}
ex {
  {kind predict code {set {a b} 7
puts ${a b}} choices {7 {a b} a {}} ans 0 why {`${...}` allows spaces in a variable name.}}
  {kind predict code {set x 5
puts {$x}
puts "$x"} choices {{$x
5} {5
5} {$x
$x} {5
$x}} ans 0 why {Braces suppress substitution; quotes allow it.}}
  {kind predict code {puts [llength {a {b c} d}]} choices {3 4 2 5} ans 0 why {Three items: `a`, `b c`, `d`.}}
  {kind predict code {puts [list a {} b]} choices {{a {} b} {a b} {a  b} {a "" b}} ans 0 why {An empty item must be shown as `{}` so it survives.}}
  {kind predict code {set x 3
set y {$x + 1}
puts [expr $y]} choices {4 {$x + 1} 3 {}} ans 0 why {`expr $y` substitutes y's value (`$x + 1`) as the expression, which then substitutes x again: a double substitution.}}
  {kind predict code {set a(i) hello
set n a(i)
puts [set $n]} choices {hello a(i) i n} ans 0 why {`set $n` with n = `a(i)` reads that array element.}}
  {kind predict code {puts [subst -nocommands {[expr 1] ok}]} choices {{[expr 1] ok} {1 ok} {ok} {[expr 1]}} ans 0 why {Command substitution is switched off.}}
  {kind mc q {Why does `if {$x > 1} {...}` use braces for the condition?} choices {{So the condition is substituted when `if` evaluates it, not earlier} {Braces are required by syntax} {To make it faster only} {Quotes cannot hold >}} ans 0 why {Braces delay substitution to the command that needs it.}}
  {kind mc q {What does "one pass" mean?} choices {{Each word is substituted exactly once, left to right} {Scripts run only once} {Only one command per line} {A variable can be set once}} ans 0 why {The single-pass rule makes Tcl predictable.}}
  {kind mc q {Where can a `#` comment start?} choices {{Where a command could start} {Anywhere on a line} {Only at column 1} {Only after a semicolon}} ans 0 why {That is why `puts hi # note` fails but `puts hi ;# note` works.}}
  {kind type q {Which command performs substitution on a string without running it as a command?} accept {subst} why {`subst`.}}
}
cards {
  {{What are the main substitutions in Tcl?} {`$var`, `[command]` and backslash sequences - done once per word, never inside braces.}}
  {{Why is `list` the right way to build a list or command?} {It quotes each item so that parsing the result gives back exactly the same items.}}
  {{What does `subst` do?} {Performs variable, command and backslash substitution on a string (with flags to disable parts).}}
  {{Where may a comment start?} {Only where a command may start; after a command use `;#`.}}
}
}

content::lesson 15.4 15 "Namespaces in depth" "Search paths, nested namespaces, ensembles with maps, and sharing variables." {
pages {
  {head "Names, paths and nesting" body {
    p {Namespaces nest (`::a::b::c`). A name starting with `::` is **absolute**; any other name is looked up from the current namespace and then the global one. `namespace path` adds extra namespaces to the **command search path**, so you can use their commands unqualified without importing.}
    code {namespace eval a {
    proc f {} {return a::f}
}
namespace eval b {
    namespace path ::a
    proc g {} {f}
}
puts [b::g]
namespace eval q {namespace eval inner {}}
puts [namespace children q]
puts [namespace parent ::q::inner]
puts [namespace eval q {namespace current}]
puts [namespace which -command puts]}
    out {a::f
::q::inner
::q
::q
::puts}
    p {`namespace which` finds where a name really lives. Procs in `b` call `f` because `::a` is on its path.}
  }}
  {head "Sharing variables" body {
    p {`namespace upvar ns var local ...` links local names to variables in another namespace - the namespace equivalent of `upvar`. Use it sparingly: better for namespaces to expose procs than variables.}
    code {namespace eval q {variable v 5}
namespace eval q2 {
    namespace upvar ::q v lv
    set lv 9
}
puts $::q::v}
    out {9}
    p {Setting `lv` in `q2` changed `v` in `q`. `namespace delete` removes a namespace and everything in it; `namespace exists` tests for one.}
  }}
  {head "Ensembles with maps" body {
    p {`namespace ensemble create` can **map** public subcommand names to internal commands, or **limit** which subcommands exist. Unknown subcommands produce a helpful error listing the valid ones.}
    code {namespace eval e {
    proc a {} {return A}
    proc b {} {return B}
    namespace export a b
    namespace ensemble create -map {first a second b}
}
puts [e first]
namespace eval e2 {
    proc alpha {} {return 1}
    proc beta {} {return 2}
    namespace export *
    namespace ensemble create -subcommands {alpha}
}
catch {e2 beta} m
puts $m}
    out {A
unknown or ambiguous subcommand "beta": must be alpha}
    tip {An ensemble is the idiomatic way to give a Tcl module an object-like interface (`stack push`, `dict get`) without OO machinery.}
  }}
}
ex {
  {kind predict code {namespace eval n {proc who {} {return n}}
namespace eval m {namespace path ::n; proc call {} {who}}
puts [m::call]} choices {n m {} who} ans 0 why {`::n` is on m's command path, so `who` resolves.}}
  {kind predict code {namespace eval x {namespace eval y {}}
puts [namespace children x]} choices {::x::y y x {}} ans 0 why {`namespace children` returns fully qualified names.}}
  {kind predict code {namespace eval ::p::q {}
puts [namespace parent ::p::q]} choices {::p p ::q {}} ans 0 why {The parent of `::p::q` is `::p`.}}
  {kind predict code {namespace eval s {variable total 0}
namespace eval t {namespace upvar ::s total tt; incr tt 5}
puts $::s::total} choices {5 0 tt {}} ans 0 why {`tt` is a link to `::s::total`.}}
  {kind predict code {namespace eval d {proc a {} {return 1}; namespace export a; namespace ensemble create -map {one a}}
puts [d one]} choices {1 a {} one} ans 0 why {The map sends the public name `one` to command `a`.}}
  {kind predict code {puts [namespace which -command string]} choices {::string string {} namespace} ans 0 why {Built-in commands live in the global namespace.}}
  {kind mc q {What does `namespace path ::a` do?} choices {{Adds ::a to the command search path of the current namespace} {Changes the current directory} {Imports every command from ::a} {Creates ::a}} ans 0 why {Unqualified commands are also looked up in the path namespaces.}}
  {kind mc q {What does a name starting with `::` mean?} choices {{It is absolute, resolved from the global namespace} {It is private} {It is a variable} {It is a comment}} ans 0 why {Without `::` the name is relative to the current namespace.}}
  {kind type q {Which command links local variable names to variables in another namespace?} accept {namespace upvar} why {`namespace upvar ::ns var local`.}}
  {kind code prompt {Create namespace **geom** with an ensemble providing subcommands **area** (width times height) and **perimeter**, so `geom area 3 4` is 12 and `geom perimeter 3 4` is 14.} starter {namespace eval geom {
}} solution {namespace eval geom {
    proc area {w h} {expr {$w * $h}}
    proc perimeter {w h} {expr {2 * ($w + $h)}}
    namespace export area perimeter
    namespace ensemble create
}} tests {{geom area 3 4} 12 {geom perimeter 3 4} 14} why {Exported procs become subcommands of the ensemble.}}
  {kind code prompt {Write a proc **nsdepth** returning how many `::` levels a namespace name has below the global one: `nsdepth ::a::b::c` is 3, `nsdepth ::` is 0. (Work on the text - the namespaces need not exist.)} starter {proc nsdepth {ns} {
    return 0
}} solution {proc nsdepth {ns} {
    set n 0
    foreach part [split $ns :] {
        if {$part ne ""} {incr n}
    }
    return $n
}} tests {{nsdepth ::a::b::c} 3 {nsdepth ::} 0 {nsdepth ::x} 1} why {Splitting on the colon leaves empty pieces between the `::` pairs; count only the real names.}}
}
cards {
  {{What does `namespace path` do?} {Adds namespaces to the command search path so their commands can be used unqualified.}}
  {{How do you share a variable across namespaces?} {`namespace upvar ::other var local` (or just qualify the name).}}
  {{How can an ensemble hide or rename subcommands?} {`namespace ensemble create -map {public internal}` or `-subcommands {list}`.}}
}
}

content::lesson 15.5 15 "Interpreters in depth" "Limits, hidden commands, aliases and bridging two interpreters." {
pages {
  {head "Limits and hidden commands" body {
    p {A child interpreter can be **limited** (commands, time, recursion depth) and have commands **hidden**: a hidden command is invisible to scripts in the child but the parent can still call it with `invokehidden`. This is how a safe interpreter keeps dangerous commands out of reach.}
    code {set i [interp create]
$i limit command -value 100
catch {$i eval {for {set k 0} {$k < 1000} {incr k} {}}} m
puts $m
set j [interp create]
$j hide puts
catch {$j eval {puts x}} m
puts $m
$j hide expr
puts [$j invokehidden expr 1+2]}
    out {command count limit exceeded
invalid command name "puts"
3}
    p {Limits turn "an endless loop" from a hang into an ordinary error you can catch.}
  }}
  {head "Aliases and sharing" body {
    p {An **alias** makes a command in the child that runs a command in the parent. Procs defined in a child run only in the child. `interp issafe` tells you whether an interpreter is safe.}
    code {set i [interp create]
$i eval {proc f {} {return in-child}}
puts [$i eval f]
interp alias $i hello {} string toupper
puts [$i eval {hello abc}]
puts [interp issafe [interp create -safe]]}
    out {in-child
ABC
1}
    p {Channels can be **shared** (`interp share`) or **transferred** (`interp transfer`) between interpreters; transferring moves ownership so only one interpreter can use the channel.}
  }}
  {head "A resource-limited evaluator" body {
    p {Combining safe interpreters, limits and aliases gives a miniature **sandbox** - exactly the technique this app uses to run your code in the Playground.}
    code {proc run {script} {
    set i [interp create -safe]
    $i limit command -value 5000
    set r [catch {$i eval $script} out]
    interp delete $i
    return [list $r $out]
}
puts [run {expr {6 * 7}}]
puts [run {while 1 {set x 1}}]}
    out {0 42
1 {command count limit exceeded}}
    tip {Always `interp delete` an interpreter when finished; it frees everything inside it.}
  }}
}
ex {
  {kind predict code {set i [interp create]
$i eval {set v 5}
puts [info exists v]} choices {0 1 5 {}} ans 0 why {The variable lives in the child only.}}
  {kind predict code {set i [interp create]
interp alias $i up {} string toupper
puts [$i eval {up hello}]} choices {HELLO hello up {}} ans 0 why {The alias runs `string toupper` in the parent.}}
  {kind predict code {puts [interp issafe [interp create]]} choices {0 1 safe {}} ans 0 why {A plain interpreter is not safe.}}
  {kind predict code {set i [interp create]
$i limit command -value 50
puts [catch {$i eval {while 1 {}}}]} choices {1 0 50 {}} ans 0 why {The command-count limit raises an error.}}
  {kind predict code {set i [interp create]
$i hide expr
puts [catch {$i eval {expr 1}}]} choices {1 0 expr {}} ans 0 why {Scripts in the child cannot see a hidden command.}}
  {kind mc q {What does `interp hide` do?} choices {{Makes a command invisible to the child, but callable by the parent with `invokehidden`} {Deletes the command forever} {Renames it} {Locks the interpreter}} ans 0 why {Hidden commands are how safe interpreters hold back dangerous features.}}
  {kind mc q {Why set a command limit on a sandboxed interpreter?} choices {{So endless loops become catchable errors} {To make code faster} {To save memory} {To block variables}} ans 0 why {A limit turns a hang into an error.}}
  {kind type q {Which command makes a command in a child run a command in its parent?} accept {interp alias} why {`interp alias child name {} parentCmd`.}}
  {kind code prompt {Write a proc **calc** that evaluates an expression in a fresh safe interpreter with a 1000-command limit, returning the result or the text **error** if anything goes wrong.} starter {proc calc {expr} {
    return error
}} solution {proc calc {expr} {
    set i [interp create -safe]
    $i limit command -value 1000
    if {[catch {$i eval [list expr $expr]} r]} {set r error}
    interp delete $i
    return $r
}} tests {{calc {6 * 7}} 42 {calc {1 +}} error} why {Run it isolated, catch problems, always delete the interpreter.}}
  {kind code prompt {Write a proc **sandboxed** that runs a script in a safe interpreter with an alias **emit** that appends its argument to a result list in the parent; return that list. Example: `sandboxed {emit a; emit b}` gives `a b`.} starter {proc sandboxed {script} {
    return {}
}} solution {proc sandboxed {script} {
    set ::emitted {}
    set i [interp create -safe]
    $i alias emit apply {{x} {lappend ::emitted $x}}
    $i eval $script
    interp delete $i
    return $::emitted
}} tests {{sandboxed {emit a; emit b}} {a b}} why {The alias is the controlled doorway from the child to the parent.}}
}
cards {
  {{What does `interp limit` give you?} {A cap on commands, time or recursion, so runaway code becomes a catchable error.}}
  {{What is a hidden command?} {A command removed from the child's view but still callable by the parent via `invokehidden`.}}
  {{What is the recipe for a sandbox?} {Safe interpreter + limits + a few aliases for the abilities you grant.}}
}
}

content::lesson 15.6 15 "Introspection, unknown and call stacks" "Asking Tcl about itself, and handling commands that do not exist." {
pages {
  {head "info: commands, procs and arguments" body {
    p {`info` reveals the running program. For procs: `info args`, `info body`, `info default proc arg var` (returns 1 and stores the default if there is one). For frames: `info level` is the current depth and `info level -1` the caller.}
    code {proc pf {a {b 2} args} {}
puts [info args pf]
puts [info default pf b v]
puts $v
proc lv {} {info level}
puts [lv]
proc outer {} {inner}
proc inner {} {info level -1}
puts [outer]
puts [info commands s*ing]}
    out {a b args
1
2
1
outer
string}
    p {`info commands pattern` lists commands matching a glob; `info procs`, `info vars`, `info exists` and `info script` complete the family.}
  }}
  {head "unknown: when a command is missing" body {
    p {Whenever Tcl meets a command it cannot find, it calls the command **`unknown`** with the words. You can replace it to implement auto-loading, abbreviations or forwarding. (Tcl's own `unknown` auto-loads libraries and lets you abbreviate commands interactively.)}
    code {rename unknown unknown_orig
proc unknown {args} {
    return "no such command: [lindex $args 0]"
}
puts [nosuchcmd 1 2]
rename unknown {}
rename unknown_orig unknown}
    out {no such command: nosuchcmd}
    warn {Always restore the original `unknown` (as above) or save it and call it for commands you do not handle, otherwise auto-loading of libraries stops working.}
  }}
  {head "Tracing commands" body {
    p {`trace add command name rename|delete handler` tells you when a command is renamed or deleted, and `trace add execution` tells you when it runs. `trace info` lists the traces on an object.}
    code {proc work {} {return done}
set log {}
trace add command work rename {apply {{old new op} {lappend ::log "$old->$new"}}}
rename work labour
puts $log
puts [labour]}
    out {::work->::labour
done}
    tip {Together with `uplevel`, `upvar` and `info frame` (a detailed record of each stack frame), introspection is how debuggers, profilers and test frameworks are built in Tcl itself.}
  }}
}
ex {
  {kind predict code {proc p {x y} {}
puts [info args p]} choices {{x y} p {} 2} ans 0 why {`info args` lists parameter names.}}
  {kind predict code {proc p {a {b 5}} {}
puts [info default p b dv]
puts $dv} choices {{1
5} {0
5} {5
5} {1
b}} ans 0 why {`info default` returns 1 when there is a default and stores it in the variable.}}
  {kind predict code {proc a {} {b}
proc b {} {info level -1}
puts [a]} choices {a b {} 0} ans 0 why {`info level -1` is the command that called us.}}
  {kind predict code {proc lv {} {info level}
proc wrap {} {lv}
puts "[lv] [wrap]"} choices {{1 2} {1 1} {2 2} {0 1}} ans 0 why {Called from the top level, `lv` is at level 1; through `wrap` it is at level 2.}}
  {kind predict code {rename unknown unknown_orig
proc unknown {args} {return "?[lindex $args 0]"}
set r [foo]
rename unknown {}
rename unknown_orig unknown
puts $r} choices {?foo foo {} unknown} ans 0 why {The custom `unknown` handled the missing command.}}
  {kind mc q {When does Tcl call `unknown`?} choices {{When a command name cannot be found} {When a variable is missing} {When a script ends} {When memory is low}} ans 0 why {It is the hook for auto-loading and custom dispatch.}}
  {kind mc q {Why restore the original `unknown` after replacing it?} choices {{Auto-loading of libraries depends on it} {Tcl will not run without it} {It speeds up programs} {It is only a convention for style}} ans 0 why {Package auto-loading goes through `unknown`.}}
  {kind type q {Which command returns the call-stack depth?} accept {info level} why {`info level`.}}
  {kind code prompt {Write a proc **callername** returning the name of the procedure that called it (use `info level`); called from the top level it returns **toplevel**.} starter {proc callername {} {
    return toplevel
}} solution {proc callername {} {
    if {[info level] < 2} {return toplevel}
    return [lindex [info level -1] 0]
}} tests {{callername} toplevel {proc w {} {callername}; w} w} why {`info level -1` is the caller's command line; its first word is the name.}}
  {kind code prompt {Write a proc **argcount** taking a proc name and returning how many parameters it declares (0 for none).} starter {proc argcount {name} {
    return 0
}} solution {proc argcount {name} {
    return [llength [info args $name]]
}} tests {{proc q {a b c} {}; argcount q} 3 {proc r {} {}; argcount r} 0} why {`info args` returns the list of parameter names.}}
}
cards {
  {{Which `info` commands describe a proc?} {`info args`, `info body`, `info default proc arg var`.}}
  {{What is `unknown`?} {The command Tcl calls when it cannot find a command - the hook for auto-loading and custom dispatch.}}
  {{How do you find your caller?} {`info level -1` gives the caller's command line.}}
  {{How do you notice a command being renamed or deleted?} {`trace add command name rename|delete handler`.}}
}
}

content::lesson 15.7 15 "Files, directories and the operating system" "Create, copy, move and find files - and talk to the program's environment." {
pages {
  {head "The file command family" body {
    p {`file` is a whole toolbox: `mkdir`, `copy`, `rename`, `delete`, `exists`, `isdirectory`, `size`, `normalize`, `split`, `join`, `tail`. `glob` finds files by pattern. Always build paths with `file join` so they work on every operating system.}
    code {puts [file normalize /tmp/../tmp/./x]
puts [file split /a/b/c.txt]
file mkdir d1/d2
puts [file isdirectory d1/d2]
set f [open d1/a.txt w]
puts $f hi
close $f
file copy d1/a.txt d1/b.txt
puts [lsort [glob -tails -directory d1 *.txt]]
file rename d1/b.txt d1/c.txt
puts [lsort [glob -tails -directory d1 *]]
puts [file size d1/a.txt]
file delete -force d1
puts [file exists d1]}
    out {/tmp/x
/ a b c.txt
1
a.txt b.txt
a.txt c.txt d2
3
0}
    p {`-tails` gives names without the directory; `-directory` is cleaner than gluing paths by hand; `-nocomplain` stops `glob` complaining when nothing matches.}
  }}
  {head "Arguments and environment" body {
    p {A script started from the command line sees its arguments in `argv` (a list) and `argc` (the count); `argv0` is the script name. `env` is an array of environment variables, and `exit` ends the program with a status code. Here we set `argv` ourselves to practise:}
    code {set ::argv {-v input.txt}
set ::argc 2
set opts {}
set files {}
foreach a $::argv {
    if {[string match -* $a]} {
        lappend opts $a
    } else {
        lappend files $a
    }
}
puts "options: $opts"
puts "files: $files"}
    out {options: -v
files: input.txt}
    p {Real programs parse arguments like this (or with Tcllib's `cmdline`). Use a **non-zero exit code** for failure: `exit 1`, so shell scripts and build tools can react.}
  }}
  {head "Running other programs" body {
    p {`exec` runs another program and returns its output; `open |command` connects to a running process through a channel. Errors are raised if the command writes to standard error or exits with a non-zero status.}
    show {puts [exec date +%Y]
set pipe [open "|sort" r+]
puts $pipe "pear\napple"
chan close $pipe write
puts [read $pipe]
close $pipe

if {[catch {exec ls /nonexistent} err]} {
    puts "failed: $err"
}}
    warn {Never build an `exec` command by pasting user input into a string. Pass arguments as separate words so the shell cannot reinterpret them, and validate them first. (This app's sandbox switches `exec` off entirely.)}
  }}
}
ex {
  {kind predict code {puts [file split /usr/local/bin]} choices {{/ usr local bin} {usr local bin} {/usr /local /bin} {/usr/local/bin}} ans 0 why {The root is its own element.}}
  {kind predict code {puts [file normalize /a/b/../c]} choices {/a/c /a/b/c /c /a} ans 0 why {`..` removes the previous component.}}
  {kind predict code {file mkdir t1/t2
puts [file isdirectory t1/t2]
file delete -force t1
puts [file exists t1]} choices {{1
0} {0
0} {1
1} {0
1}} ans 0 why {Created, tested, deleted, no longer exists.}}
  {kind predict code {set f [open "z.txt" w]; puts -nonewline $f hello; close $f
puts [file size z.txt]} choices {5 6 0 hello} ans 0 why {Five bytes with no newline.}}
  {kind predict code {foreach n {a.txt b.log c.txt} {close [open $n w]}
puts [lsort [glob -nocomplain *.txt]]} choices {{a.txt c.txt} {a.txt b.log c.txt} {b.log} {}} ans 0 why {The glob pattern selects names ending in .txt.}}
  {kind mc q {Why build paths with `file join` rather than string concatenation?} choices {{It uses the right separator on every operating system} {It is faster} {It checks that the file exists} {It is required by `open`}} ans 0 why {Windows uses backslashes, others slashes.}}
  {kind mc q {What does a non-zero exit status signal?} choices {{That the program failed, so scripts and tools can react} {That it ran twice} {That it printed output} {That it used memory}} ans 0 why {Convention: 0 means success.}}
  {kind type q {Which command returns a list of files matching a pattern?} accept {glob} why {`glob *.txt`.}}
  {kind code prompt {Write a proc **parseargs** that takes an argument list and returns a dict with keys **options** (arguments starting with `-`) and **files** (the rest).} starter {proc parseargs {args} {
    return {}
}} solution {proc parseargs {args} {
    set opts {}
    set files {}
    foreach a $args {
        if {[string match -* $a]} {lappend opts $a} else {lappend files $a}
    }
    return [dict create options $opts files $files]
}} tests {{parseargs -v a.txt -q b.txt} {options {-v -q} files {a.txt b.txt}} {parseargs} {options {} files {}}} why {Classify each argument by its first character.}}
  {kind code prompt {Write a proc **copyfile** that copies a file to a new name and returns the size of the copy.} starter {proc copyfile {from to} {
    return 0
}} solution {proc copyfile {from to} {
    file copy -force $from $to
    return [file size $to]
}} tests {{set f [open s.txt w]; puts -nonewline $f abcd; close $f; copyfile s.txt t.txt} 4} why {`file copy` then `file size`.}}
  {kind code prompt {Write a proc **extcount** that takes a list of file names and returns a dict counting how many files have each extension (without the dot).} starter {proc extcount {names} {
    return {}
}} solution {proc extcount {names} {
    set d {}
    foreach n $names {dict incr d [string range [file extension $n] 1 end]}
    return $d
}} tests {{extcount {a.txt b.txt c.log}} {txt 2 log 1}} why {`file extension` includes the dot, so drop it.}}
}
cards {
  {{Which `file` subcommands make, copy, move and remove things?} {`mkdir`, `copy`, `rename`, `delete` (use `-force` for non-empty directories).}}
  {{What are argv, argc and argv0?} {The script's argument list, its length, and the script name.}}
  {{How do you run another program?} {`exec cmd arg ...` or `open |cmd` for a pipe; pass arguments as separate words.}}
  {{Why use `glob -directory dir`?} {It is clearer and safer than concatenating a directory and a pattern.}}
}
}

content::lesson 15.8 15 "Unicode, encodings and translating your program" "Characters beyond ASCII, and message catalogs." {
pages {
  {head "Characters and code points" body {
    p {Tcl strings hold Unicode characters. `format %c n` makes the character with code number n, and `scan $ch %c` returns a character's code. `string length` counts characters, not bytes. Because source files here must stay plain ASCII, we make special characters from their code numbers.}
    code {set euro [format %c 8364]
puts [string length $euro]
puts [scan $euro %c]
set e [format %c 233]
puts [string length "caf$e"]
puts [string length [encoding convertto utf-8 "caf$e"]]
puts [regexp {^[[:alpha:]]+$} "caf$e"]}
    out {1
8364
4
5
1}
    p {The euro sign is one character (code 8364) though three bytes in UTF-8. Character classes such as `[[:alpha:]]` understand accented letters, and `string toupper`, `string tolower` and `string totitle` work on them too.}
  }}
  {head "Translating with msgcat" body {
    p {Software for several languages never hard-codes messages. **msgcat** keeps a catalog of translations per **locale**; `msgcat::mc key` returns the text for the current locale, falling back to the key itself when there is no translation.}
    code {package require msgcat
msgcat::mclocale en
msgcat::mcset en greeting Hello
msgcat::mcset fr greeting Bonjour
puts [msgcat::mc greeting]
msgcat::mclocale fr
puts [msgcat::mc greeting]
puts [msgcat::mc unknownkey]
msgcat::mcset en hi "Hi %s"
msgcat::mclocale en
puts [msgcat::mc hi Ann]}
    out {Hello
Bonjour
unknownkey
Hi Ann}
    p {Extra arguments are inserted with `format`-style placeholders, so word order can differ per language. Real projects store catalogs in `.msg` files and load them with `msgcat::mcload`.}
  }}
  {head "Pitfalls" body {
    p {- Do not assume one **byte** per character, or one **character** per screen position
- Sorting and case-folding are language-dependent; `lsort -dictionary` is not a full locale-aware sort
- Always set the encoding explicitly when reading and writing files and sockets (`-encoding utf-8`)
- Use `format` with positional arguments (`%1$s`) when a translated sentence reorders its parts
- Keep **user-visible text out of the logic**: pass it through `mc`}
    tip {Even if you never translate your program, routing messages through one place (`mc`) makes wording changes and later translation easy.}
  }}
}
ex {
  {kind predict code {puts [string length [format %c 8364]]} choices {1 3 2 4} ans 0 why {One character, whatever its UTF-8 size.}}
  {kind predict code {puts [scan A %c]} choices {65 A 97 1} ans 0 why {`%c` converts a character to its code.}}
  {kind predict code {puts [format %c 66]} choices {B 66 b {}} ans 0 why {`%c` converts a code to a character.}}
  {kind predict code {puts [string length [encoding convertto utf-8 [format %c 233]]]} choices {2 1 3 4} ans 0 why {An accented e takes two bytes in UTF-8.}}
  {kind predict code {package require msgcat
msgcat::mclocale en
msgcat::mcset en bye Goodbye
puts [msgcat::mc bye]} choices {Goodbye bye {} en} ans 0 why {The en catalog has an entry for `bye`.}}
  {kind predict code {package require msgcat
msgcat::mclocale en
puts [msgcat::mc nothere]} choices {nothere {} en error} ans 0 why {Missing keys fall back to the key text.}}
  {kind mc q {What is msgcat for?} choices {{Looking up translated messages by key for the current locale} {Concatenating strings} {Encoding files} {Sorting lists}} ans 0 why {It separates the words from the logic.}}
  {kind mc q {Why is it risky to assume one byte per character?} choices {{Non-ASCII characters take several bytes in UTF-8} {Bytes are slower} {Tcl forbids it} {Characters are bigger on phones}} ans 0 why {Use character commands for text and `encoding` for bytes.}}
  {kind type q {Which format specifier converts a number to the character with that code?} accept {%c} why {`format %c 65` gives A.}}
  {kind code prompt {Write a proc **codes** that returns the list of Unicode code numbers of the characters of a string: `codes ABC` is `65 66 67`.} starter {proc codes {s} {
    return {}
}} solution {proc codes {s} {
    set r {}
    foreach c [split $s ""] {lappend r [scan $c %c]}
    return $r
}} tests {{codes ABC} {65 66 67} {codes ""} {}} why {Split into characters, convert each with `scan %c`.}}
  {kind code prompt {Write a proc **shift** that moves each letter A-Z or a-z forward in the alphabet by n places (a Caesar cipher), leaving other characters alone: `shift abc 1` is `bcd`, `shift xyz 3` is `abc`.} starter {proc shift {s n} {
    return $s
}} solution {proc shift {s n} {
    set out ""
    foreach c [split $s ""] {
        set k [scan $c %c]
        if {$k >= 65 && $k <= 90} {
            append out [format %c [expr {65 + ($k - 65 + $n) % 26}]]
        } elseif {$k >= 97 && $k <= 122} {
            append out [format %c [expr {97 + ($k - 97 + $n) % 26}]]
        } else {
            append out $c
        }
    }
    return $out
}} tests {{shift abc 1} bcd {shift xyz 3} abc {shift "Hi!" 1} {Ij!}} why {Map to 0-25, add n modulo 26, map back; keep other characters.}}
}
cards {
  {{How do you convert between characters and code points?} {`format %c 65` gives A; `scan A %c` gives 65.}}
  {{What does msgcat do?} {Looks up translated messages by key for the current locale: `msgcat::mc key`.}}
  {{Why set encodings explicitly for files and sockets?} {Bytes and characters differ; defaults vary by platform.}}
}
}

content::lesson 15.9 15 "Writing safe and robust Tcl" "Injection, validation and defence in depth." {
pages {
  {head "Injection: when data becomes code" body {
    p {Because Tcl code is text, a program that builds code from outside data can be **tricked into running it**. The dangerous commands are `eval`, `expr` (unbraced), `subst`, `uplevel`, `exec`, `source`, and any `if`/`while` whose condition is a substituted string.}
    code {set input {[puts HACKED]}
puts [string is integer -strict $input]
catch {expr $input} r
puts "unbraced -> '$r'"
catch {expr {$input}} r2
puts "braced -> $r2"}
    out {0
HACKED
unbraced -> ''
braced -> [puts HACKED]}
    p {The unbraced `expr` executed the hidden command. The braced one treated the value as plain data. The cure is simple: **brace your expressions and conditions**, and build commands with `list`.}
  }}
  {head "Validate, then trust" body {
    p {Check external input against a **whitelist** of what is allowed before using it - never try to list everything that is forbidden. `string is`, anchored regular expressions and `in` do the job.}
    code {puts [string is integer -strict "12; exit"]
puts [regexp {^[a-z]{1,8}$} "valid"]
puts [regexp {^[a-z]{1,8}$} "no spaces"]
puts [expr {"png" in {png jpg gif}}]
puts [file normalize [file join /srv/data ../etc/passwd]]
puts [string match /srv/data/* [file normalize [file join /srv/data ../etc/passwd]]]}
    out {0
1
0
1
/srv/etc/passwd
0}
    p {The last lines show **path traversal**: the name `../etc/passwd` escapes the data folder. Normalise first, then check the result still starts inside the allowed directory.}
  }}
  {head "Defence in depth" body {
    p {Several layers, each cheap:}
    p {- Run untrusted code in a **safe interpreter** with a command limit and a time limit
- Give it only the abilities it needs, through **aliases**
- Use the **least privilege**: files opened read-only, directories restricted
- Handle errors without leaking internal details to users
- **Log** unexpected input; it is often the first sign of an attack
- Keep dependencies current and read what a package does before you trust it}
    tip {Security is a habit, not a feature. The two habits that prevent most Tcl vulnerabilities: braces around every expression, and `list` for every command you assemble.}
  }}
}
ex {
  {kind predict code {puts [string is integer -strict "12; exit"]} choices {0 1 12 {}} ans 0 why {The text contains characters other than digits.}}
  {kind predict code {puts [regexp {^[a-z]+$} "abc1"]} choices {0 1 abc {}} ans 0 why {The digit breaks the whitelist.}}
  {kind predict code {puts [file normalize [file join /app/data ../x]]} choices {/app/x /app/data/x /x /app} ans 0 why {`..` climbs out of `data`.}}
  {kind predict code {set v {[error boom]}
puts [catch {expr {$v}}]} choices {0 1 boom {}} ans 0 why {Braced: the value is data, so nothing runs and no error is raised.}}
  {kind mc q {What is the safest way to build a command from external values?} choices {{`list`, so each value stays one word} {String concatenation} {`format` with %s} {`subst`}} ans 0 why {`list` quotes values so they cannot change the command's shape.}}
  {kind mc q {Why prefer a whitelist to a blacklist?} choices {{You define exactly what is allowed instead of guessing every bad input} {Whitelists are shorter} {Blacklists are slower} {Tcl needs whitelists}} ans 0 why {Attackers are creative; allow only what you know is safe.}}
  {kind mc q {What is path traversal?} choices {{Using `..` in a name to escape the intended directory} {Walking a list} {Following a symbolic link} {Searching recursively}} ans 0 why {Normalise and check the prefix.}}
  {kind type q {Which two commands are most commonly misused to run attacker-supplied text? (name one)} accept {eval expr subst uplevel exec source} why {Any command that evaluates strings as code needs care.}}
  {kind code prompt {Write a proc **safename** returning 1 only if its argument is 1 to 12 characters of letters, digits and underscore, else 0.} starter {proc safename {s} {
    return 1
}} solution {proc safename {s} {
    return [regexp {^\w{1,12}$} $s]
}} tests {{safename user_1} 1 {safename "a b"} 0 {safename ""} 0 {safename abcdefghijklm} 0} why {An anchored whitelist pattern.}}
  {kind code prompt {Write a proc **insidedir** returning 1 if a path, after normalising, is inside the given directory, else 0. `insidedir /srv/data a/b.txt` is 1; `insidedir /srv/data ../x` is 0.} starter {proc insidedir {dir path} {
    return 1
}} solution {proc insidedir {dir path} {
    set full [file normalize [file join $dir $path]]
    set base [file normalize $dir]
    return [expr {[string first "$base/" $full] == 0}]
}} tests {{insidedir /srv/data a/b.txt} 1 {insidedir /srv/data ../x} 0} why {Normalise both, then check that the full path starts with the directory plus a slash.}}
}
cards {
  {{When does data become code in Tcl?} {When it reaches eval, unbraced expr/if/while conditions, subst, uplevel, exec or source.}}
  {{What are the two habits that prevent most injection bugs?} {Brace every expression, and build commands with `list`.}}
  {{How do you defend against path traversal?} {Normalise the path, then check it still lies inside the allowed directory.}}
  {{What is defence in depth?} {Layers: validation, safe interpreters with limits, least privilege, logging.}}
}
}

content::lesson 15.10 15 "Functional programming in Tcl" "Map, filter, reduce, composition and pipelines." {
pages {
  {head "Map, filter and reduce" body {
    p {Tcl has no special syntax for functional style, but `lmap`, `apply` and command prefixes give you all of it. **Map** transforms every item; **filter** keeps some; **reduce** (fold) combines all into one value.}
    code {proc map {f l} {lmap x $l {{*}$f $x}}
proc filter {f l} {lmap x $l {if {[{*}$f $x]} {set x} else continue}}
proc reduce {f init l} {
    set acc $init
    foreach x $l {set acc [{*}$f $acc $x]}
    return $acc
}
set sq {apply {{x} {expr {$x * $x}}}}
set even {apply {{x} {expr {$x % 2 == 0}}}}
set add {apply {{a b} {expr {$a + $b}}}}
puts [map $sq {1 2 3 4}]
puts [filter $even {1 2 3 4 5 6}]
puts [reduce $add 0 {1 2 3 4}]
puts [lmap x {1 2 3 4} {if {$x % 2} {expr {$x * 10}} else continue}]}
    out {1 4 9 16
2 4 6
10
10 30}
    p {The last line shows how `lmap` with `continue` is itself a map-and-filter in one step.}
  }}
  {head "Composition and partial application" body {
    p {**Composition** chains functions: `compose f g` applies g then f. **Partial application** fixes some arguments in advance. Both are just list-building, because a command prefix is a list.}
    code {proc compose {f g} {
    list apply [list x [format {%s [%s $x]} $f $g]]
}
set shout [compose {string toupper} {string reverse}]
puts [{*}$shout abc]
proc partial {cmd args} {list {*}$cmd {*}$args}
set add10 [partial {::tcl::mathop::+} 10]
puts [{*}$add10 5]}
    out {CBA
15}
    p {`compose` returns a lambda as a value. Because functions are values, you can store them in lists and dicts and pass them around freely.}
  }}
  {head "Pipelines and immutability" body {
    p {Code that returns **new values** instead of changing variables is easy to reason about and test. Chaining transformations reads like a recipe:}
    code {set words {the quick brown fox jumps over the lazy dog}
set result [lsort -unique [lmap w $words {
    if {[string length $w] > 3} {string toupper $w} else continue
}]]
puts $result}
    out {BROWN JUMPS LAZY OVER QUICK}
    tip {Tcl values are immutable under the hood (copy-on-write), which is why returning a modified copy is cheap. Prefer small pure procs that take values and return values; reserve mutation for where it clearly helps.}
  }}
}
ex {
  {kind predict code {puts [lmap x {1 2 3} {expr {$x + 1}}]} choices {{2 3 4} {1 2 3} {2 4 6} {3}} ans 0 why {`lmap` collects each result.}}
  {kind predict code {puts [lmap x {1 2 3 4} {if {$x > 2} {set x} else continue}]} choices {{3 4} {1 2} {1 2 3 4} {}} ans 0 why {`continue` drops items.}}
  {kind predict code {set add {apply {{a b} {expr {$a + $b}}}}
set acc 0
foreach x {1 2 3} {set acc [{*}$add $acc $x]}
puts $acc} choices {6 3 0 123} ans 0 why {A fold: 0+1+2+3.}}
  {kind predict code {set f [list string repeat ab]
puts [{*}$f 3]} choices {ababab {ab 3} 3 ab} ans 0 why {A command prefix plus the final argument.}}
  {kind predict code {proc compose {f g} {list apply [list x [format {%s [%s $x]} $f $g]]}
puts [{*}[compose {string length} {string trim}] "  hi  "]} choices {2 6 4 0} ans 0 why {Trim first, then take the length.}}
  {kind mc q {What is a **reduce** (fold)?} choices {{Combining all items of a list into one value, step by step} {Removing duplicates} {Sorting} {Splitting text}} ans 0 why {Sum, product, maximum and join are all folds.}}
  {kind mc q {Why are pure functions easy to test?} choices {{Same input always gives the same output, with no hidden state} {They run faster} {They need no arguments} {They cannot fail}} ans 0 why {No setup or cleanup is needed.}}
  {kind type q {Which command builds a new list by applying code to each item?} accept {lmap} why {`lmap`.}}
  {kind code prompt {Write a proc **count** taking a command prefix (a predicate) and a list, and returning how many items satisfy it.} starter {proc count {pred l} {
    return 0
}} solution {proc count {pred l} {
    set n 0
    foreach x $l {
        if {[{*}$pred $x]} {incr n}
    }
    return $n
}} tests {{count {apply {{x} {expr {$x > 2}}}} {1 2 3 4 5}} 3 {count {string is integer} {1 a 2 b}} 2} why {Call the predicate for each item.}}
  {kind code prompt {Write a proc **pipeline** taking a value and a list of command prefixes, applying each in turn (the result of one is the last argument of the next).} starter {proc pipeline {value fs} {
    return $value
}} solution {proc pipeline {value fs} {
    foreach f $fs {set value [{*}$f $value]}
    return $value
}} tests {{pipeline "  Hi " {{string trim} {string toupper} {string reverse}}} IH} why {Each step feeds the next.}}
  {kind code prompt {Write a proc **groupby** taking a command prefix and a list, returning a dict from each result of the prefix to the list of items producing it (items in original order).} starter {proc groupby {f l} {
    return {}
}} solution {proc groupby {f l} {
    set d {}
    foreach x $l {dict lappend d [{*}$f $x] $x}
    return $d
}} tests {{groupby {string length} {a bb c dd eee}} {1 {a c} 2 {bb dd} 3 eee}} why {`dict lappend` builds each group.}}
}
cards {
  {{What are map, filter and reduce?} {Transform each item, keep some items, combine all items into one value.}}
  {{How do you write a lambda in Tcl?} {`apply {{args} {body}}`, or store `{args} {body}` in a variable and `apply $f ...`.}}
  {{What is composition?} {Building a function that applies g then f; in Tcl just list building: `list apply [list x ...]`.}}
  {{Why prefer returning values over mutating?} {Pure code is easier to reason about, test and reuse; Tcl's copy-on-write keeps it cheap.}}
}
}

content::lesson 15.11 15 "Tk: text, lists, trees and images" "The widgets for editors, tables and pictures." {
pages {
  {head "The text widget" body {
    p {`text` is a full rich-text editor: positions are `line.char` (`1.0` is the start, `end` the end), and **tags** style ranges. It is what powers the code boxes in this very app.}
    show {text .t -width 50 -height 10 -wrap word
pack .t -fill both -expand 1
.t insert end "Hello, Tk!\nSecond line\n"
.t tag configure big -font {Helvetica 16 bold} -foreground blue
.t tag add big 1.0 1.5
puts [.t get 1.0 end]            ;# all text
puts [.t index end]              ;# 3.0
.t delete 1.0 1.5
.t search -nocase second 1.0     ;# position of a match
.t see end}
    p {`insert`, `delete`, `get`, `search`, `tag add/remove/configure/bind`, `mark set`, `edit undo` and embedded windows or images make the widget extremely versatile.}
  }}
  {head "Listbox, scrollbars and trees" body {
    p {`listbox` shows a scrolling list; `ttk::treeview` shows hierarchical or tabular data. Scrollbars connect to a widget by **two commands**: the widget calls the scrollbar's `set`, the scrollbar calls the widget's `yview`.}
    show {listbox .lb -yscrollcommand {.sb set} -height 6
scrollbar .sb -command {.lb yview}
pack .sb -side right -fill y
pack .lb -side left -fill both -expand 1
foreach item {red green blue} {.lb insert end $item}
bind .lb <<ListboxSelect>> {puts [.lb get [.lb curselection]]}

ttk::treeview .tv -columns {size} -show {tree headings}
.tv heading #0 -text Name
.tv heading size -text Size
set dir [.tv insert {} end -text docs]
.tv insert $dir end -text a.txt -values {12}}
    tip {The pairing `-yscrollcommand {.sb set}` plus `-command {.lb yview}` is the same pattern for every scrollable widget. This app uses its own touch-friendly version because phones have no scrollbars.}
  }}
  {head "Images and fonts" body {
    p {`image create photo` loads or builds bitmaps; widgets display them with `-image`. You can create pixels from data, scale with `copy -zoom`, and even generate PNG bytes yourself. `font create` defines named fonts that update everywhere when changed.}
    show {image create photo logo -file logo.png
label .l -image logo
pack .l

image create photo mini
mini copy logo -subsample 2     ;# half size
mini put #ff0000 -to 0 0 10 10  ;# a red square

font create title -family Helvetica -size 20 -weight bold
label .t -text "Hi" -font title
font configure title -size 28   ;# every user changes at once}
    p {This app draws its smooth icons by computing pixel coverage in Tcl, packing it into a PNG with `zlib compress` and `binary format`, and loading it with `image create photo -data`. You have now met every ingredient of that code.}
  }}
}
ex {
  {kind mc q {In a text widget, what does the index `1.0` mean?} choices {{Line 1, character 0: the very start} {Line 0, character 1} {The first word} {The whole text}} ans 0 why {Indices are `line.char`, with lines counted from 1 and characters from 0.}}
  {kind mc q {What do tags do in a text widget?} choices {{Style or attach behaviour to ranges of text} {Create new lines} {Save the file} {Resize the widget}} ans 0 why {`tag configure` and `tag bind` apply to ranges.}}
  {kind mc q {How are a listbox and a scrollbar connected?} choices {{Each calls the other: `-yscrollcommand {sb set}` and `-command {lb yview}`} {By packing them together} {They connect automatically} {Through a variable}} ans 0 why {Two commands, one in each direction.}}
  {kind mc q {Which widget shows hierarchical data with columns?} choices {ttk::treeview listbox label canvas} ans 0 why {The themed treeview.}}
  {kind mc q {What does `image create photo -data` accept?} choices {{Image data such as PNG bytes or base64} {Only a file name} {A canvas} {A widget path}} ans 0 why {This is how generated images are loaded from memory.}}
  {kind mc q {Why use named fonts (`font create`)?} choices {{Changing the font once updates every widget that uses it} {They are faster} {They support colours} {Widgets require them}} ans 0 why {Named fonts are shared objects.}}
  {kind type q {Which text-widget subcommand puts text into it?} accept {insert} why {`.t insert end "text"`.}}
  {kind type q {Which widget command creates a bitmap image object?} accept {image create photo image} why {`image create photo name`.}}
}
cards {
  {{How are text-widget positions written?} {`line.char`, e.g. `1.0` start, `end` the end, `2.5 + 3 chars` arithmetic.}}
  {{How do you connect a scrollbar?} {`-yscrollcommand {sb set}` on the widget and `-command {widget yview}` on the scrollbar.}}
  {{How do you display a picture?} {`image create photo name -file f.png`, then `label .l -image name`.}}
}
}

content::lesson 15.12 15 "Tk: a complete small application" "From window to working app, step by step." {
pages {
  {head "The plan" body {
    p {Let us assemble what you know into one application: a **notes app** with a list of notes on the left, an editor on the right, and buttons to add and delete. The design rules from the app-structure lesson apply: **data in a dict**, widgets as a view, one procedure to refresh the view.}
    show {package require Tk
set ::notes {}           ;# dict: id -> text
set ::next 1
set ::sel ""

proc addNote {} {
    dict set ::notes $::next "New note"
    incr ::next
    refresh
}
proc deleteNote {} {
    if {$::sel ne ""} {
        set ::notes [dict remove $::notes $::sel]
        set ::sel ""
        refresh
    }
}}
    p {The model is three variables and two procs; neither mentions a widget. That means they can be tested on their own.}
  }}
  {head "The view" body {
    p {The view is built once; `refresh` redraws it from the data. Selecting a note loads it into the editor; editing writes back.}
    show {ttk::frame .left
listbox .lb -exportselection 0
ttk::button .add -text Add -command addNote
ttk::button .del -text Delete -command deleteNote
pack .add .del -in .left -side top -fill x
pack .lb -in .left -fill both -expand 1

text .ed -width 40 -height 15
grid .left .ed -sticky nsew
grid columnconfigure . 1 -weight 1
grid rowconfigure . 0 -weight 1

proc refresh {} {
    .lb delete 0 end
    dict for {id text} $::notes {
        .lb insert end "$id: [string range $text 0 20]"
    }
}}
    p {`-exportselection 0` stops the listbox from fighting the text widget over the system selection. `grid` with weights makes the editor stretch.}
  }}
  {head "Events, saving and polish" body {
    p {Wire the widgets to the model with bindings, then persist the data (a dict is already a string, so saving is one `puts`):}
    show {bind .lb <<ListboxSelect>> {
    set i [.lb curselection]
    if {$i ne ""} {
        set ::sel [lindex [dict keys $::notes] $i]
        .ed delete 1.0 end
        .ed insert 1.0 [dict get $::notes $::sel]
    }
}
bind .ed <KeyRelease> {
    if {$::sel ne ""} {
        dict set ::notes $::sel [.ed get 1.0 {end - 1 char}]
        refresh
    }
}
proc save {} {
    set f [open notes.tcl w]
    puts $f [list set ::notes $::notes]
    close $f
}
wm protocol . WM_DELETE_WINDOW {save; exit}}
    p {Saving a dict as `set ::notes {...}` means loading is just `source notes.tcl`. From here you could add search, tags, a menu and keyboard shortcuts - each a small extension of the same structure.}
    tip {Notice what carried you here: dicts, procs, `foreach`, `list` quoting, files, bindings. Tk needed only a handful of new commands because the rest of the language is already the toolkit.}
  }}
}
ex {
  {kind mc q {In the notes app, where does the data live?} choices {{In a dict variable, separate from the widgets} {Inside the listbox} {In the text widget only} {In the window title}} ans 0 why {Model and view are separate.}}
  {kind mc q {What does the `refresh` proc do?} choices {{Redraws the list from the data} {Saves the file} {Deletes notes} {Resizes the window}} ans 0 why {One procedure turns data into widgets.}}
  {kind mc q {Why is saving the notes so easy?} choices {{A dict is a string, so `puts` can write it and `source` can load it} {Tk saves automatically} {The listbox stores it} {Files are not needed}} ans 0 why {Tcl values are strings.}}
  {kind mc q {What does `grid columnconfigure . 1 -weight 1` accomplish here?} choices {{The editor column stretches when the window grows} {It hides the list} {It sets the editor's width to 1} {It deletes column 1}} ans 0 why {Weights decide which columns take spare space.}}
  {kind mc q {Why bind `<<ListboxSelect>>` rather than `<Button-1>`?} choices {{It fires when the selection really changes, including from the keyboard} {It is faster} {Button-1 is not allowed} {It selects automatically}} ans 0 why {Virtual events describe meaning, not a particular input.}}
  {kind mc q {What does `wm protocol . WM_DELETE_WINDOW {save; exit}` do?} choices {{Saves before the window closes} {Prevents closing} {Hides the window} {Deletes the file}} ans 0 why {It intercepts the close button.}}
  {kind type q {Which Tk command arranges widgets in rows and columns?} accept {grid} why {`grid`.}}
  {kind type q {Which option stops a listbox exporting its selection to the system?} accept {-exportselection} why {`-exportselection 0`.}}
}
cards {
  {{What is the structure of a small Tk app?} {Data in plain variables or a dict, widgets as a view, a `refresh` proc, bindings that update the data and call refresh.}}
  {{How can you persist a dict simply?} {`puts $f [list set ::data $::data]`, and later `source` the file.}}
  {{Why use virtual events like <<ListboxSelect>>?} {They fire on the meaning (selection changed) however it happened.}}
}
}
