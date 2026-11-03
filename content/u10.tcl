content::unit 10 "Advanced Tcl" "How Tcl really works - and how to bend it to your will." "#FB7185"

content::lesson 10.1 10 "How Tcl reads code" "The few rules behind everything - and how to build and run code as data." {
pages {
  {head "One pass, left to right" body {
    p {You now know enough to see the whole picture. Tcl reads a command line like this:}
    p {- Split the line into **words**
- In each word, do the substitutions **once**: `$variable`, `[command]` and backslash sequences (not inside braces)
- Run the command with the resulting words}
    code {set a 5
set b {$a}
puts $b
puts "[set a 1] and $a"}
    out {$a
1 and 1}
    p {The text `$a` was **not** substituted a second time when it was printed. Substitution happens exactly once per word. This is why Tcl behaves so predictably.}
  }}
  {head "Running text as code" body {
    p {Because commands are just text, you can build a command in a variable and run it. `eval` runs text as a script; `subst` only performs the substitutions in some text without running a command.}
    code {set cmd {puts "hello from eval"}
eval $cmd
set template {Total: $x}
set x 5
puts [subst $template]}
    out {hello from eval
Total: 5}
    p {You can also **spread** a list as a command with `{*}`, which avoids many `eval` surprises:}
    code {set cmd {puts hi}
{*}$cmd}
    out {hi}
  }}
  {head "Build commands with list" body {
    p {When you assemble a command, use `list` so that every value stays **one word**, whatever characters it contains.}
    code {set name "Ada Lovelace"
set good [list puts "Hi $name"]
eval $good
set bad "puts Hi $name"
catch {eval $bad} err
puts $err}
    out {Hi Ada Lovelace
wrong # args: should be "puts ?-nonewline? ?channelId? string"}
    warn {Building a command by gluing strings makes the data run as code. This is the classic source of bugs - and security holes. `list` quotes each value correctly.}
  }}
}
ex {
  {kind predict code {set x 1
set y {$x}
puts $y} choices {{$x} 1 x {}} ans 0 why {Braces stopped substitution when `y` was set, and substitution does not happen again when it is printed.}}
  {kind predict code {set t {Value is $v}
set v 42
puts [subst $t]} choices {{Value is 42} {Value is $v} {Value is} {42}} ans 0 why {`subst` performs the `$` substitution on the text.}}
  {kind predict code {set c {puts hi}
eval $c} choices {hi {puts hi} {} c} ans 0 why {`eval` runs the text as a Tcl command.}}
  {kind predict code {set words {a b c}
puts [llength $words]
puts [llength [list $words]]} choices {"3\n1" "3\n3" "1\n1" "1\n3"} ans 0 why {`list $words` makes a one-item list whose single item is the whole three-word string.}}
  {kind predict code {set n 3
set cmd [list expr $n * 2]
puts [eval $cmd]} choices {6 {3 * 2} 32 n} ans 0 why {`list` assembled the command `expr 3 * 2`, and `eval` ran it.}}
  {kind mc q {How many times does Tcl substitute `$variable` inside one word?} choices {{Exactly once} {Until nothing is left} {Twice} {Never inside quotes}} ans 0 why {One substitution pass per word - the rule that makes Tcl predictable.}}
  {kind mc q {Why build commands with `list` rather than string concatenation?} choices {{`list` keeps each value as one word, however odd its characters} {`list` runs faster} {Concatenation is not allowed} {`list` adds comments}} ans 0 why {Values with spaces, quotes or brackets cannot change the shape of the command.}}
  {kind blank q {Turn the stored list into a command.} code {set cmd {puts ok}
___$cmd} answers {{{*}}} extra {{eval} {$} {@}} out {ok} why {`{*}$cmd` expands the list into separate words, which then form the command.}}
  {kind type q {Which command performs substitution on text without running it as a script?} accept {subst} why {`subst`.}}
}
cards {
  {{When does Tcl perform substitution?} {Once per word, left to right: `$var`, `[cmd]` and backslashes. Never inside braces.}}
  {{What does `eval` do?} {Runs text as a Tcl script.}}
  {{What does `subst` do?} {Performs variable, command and backslash substitution on text and returns the result.}}
  {{How should you build a command safely?} {With `list`, then run it with `{*}$cmd` or `eval $cmd`.}}
}
}

content::lesson 10.2 10 "upvar and uplevel" "Reach into the caller's world - the trick behind Tcl's control structures." {
pages {
  {head "upvar: link to the caller's variable" body {
    p {A proc normally cannot touch its caller's variables. `upvar` creates a local name that **points at** a variable in the caller. You pass the variable's **name**, just like `incr` and `append` expect.}
    code {proc incr2 {varName} {
    upvar 1 $varName v
    incr v 2
}
set n 10
incr2 n
puts $n}
    out {12}
    p {`upvar 1 $varName v` says: "`v` is another name for the variable called `$varName` one level up (in the caller)". Changing `v` changes the caller's `n`.}
  }}
  {head "Two variables at once" body {
    p {`upvar` can link several names in one go. A classic example is swapping two variables.}
    code {proc swap {a b} {
    upvar 1 $a x $b y
    set t $x
    set x $y
    set y $t
}
set p 1
set q 2
swap p q
puts "$p $q"}
    out {2 1}
    tip {`upvar #0 name local` links to a **global** variable, which is what `global` does.}
  }}
  {head "uplevel: run code in the caller" body {
    p {`uplevel` evaluates a script **in the caller's context**. Together with the fact that braces pass code around as ordinary text, this lets you invent your own control structures.}
    code {proc repeat {n body} {
    for {set i 0} {$i < $n} {incr i} {
        uplevel 1 $body
    }
}
repeat 3 {puts "hello"}}
    out {hello
hello
hello}
    code {proc unless {cond body} {
    uplevel 1 [list if "!($cond)" $body]
}
set n 5
unless {$n > 10} {puts "n is small"}}
    out {n is small}
    p {Neither `repeat` nor `unless` is built into Tcl - you just made them. This is why Tcl needs no special syntax for loops: they are ordinary commands.}
  }}
}
ex {
  {kind predict code {proc bump {name} {
    upvar 1 $name v
    incr v
}
set k 7
bump k
puts $k} choices {8 7 k 1} ans 0 why {`v` is linked to the caller's `k`, so `incr v` changes `k`.}}
  {kind predict code {proc swap {a b} {
    upvar 1 $a x $b y
    set t $x; set x $y; set y $t
}
set u first
set w second
swap u w
puts "$u $w"} choices {{second first} {first second} {u w} {w u}} ans 0 why {The values trade places.}}
  {kind predict code {proc twice {body} {
    uplevel 1 $body
    uplevel 1 $body
}
set c 0
twice {incr c 5}
puts $c} choices {10 5 0 c} ans 0 why {The body runs twice in the caller's scope, so `c` goes 5 then 10.}}
  {kind predict code {proc setit {} {
    uplevel 1 {set hidden 99}
}
setit
puts $hidden} choices {99 hidden {} 1} ans 0 why {`uplevel` ran `set hidden 99` in the caller, so the variable exists there.}}
  {kind mc q {What does `upvar 1 $name v` do?} choices {{Makes v another name for the caller's variable called $name} {Copies the value of name into v} {Creates a global} {Deletes the variable}} ans 0 why {It is a link, not a copy - changes to `v` change the original.}}
  {kind mc q {Why do you pass `n` rather than `$n` to a proc that uses upvar?} choices {{The proc needs the variable's name, not its value} {Dollar signs are slow} {It is required by upvar} {The name is shorter}} ans 0 why {With `$n` you would hand over the value, and there would be nothing to link to.}}
  {kind blank q {Run the body in the caller's scope.} code {proc do {body} {
    ___ 1 $body
}
do {puts "ran"}} answers {uplevel} extra {upvar eval global} out {ran} why {`uplevel` evaluates a script in the caller's context.}}
  {kind type q {Which command links a local name to a variable in the caller?} accept {upvar} why {`upvar`.}}
  {kind code prompt {Write a proc **dbl** that takes the NAME of a variable and doubles its value in the caller.} starter {proc dbl {name} {
    # use upvar
}} solution {proc dbl {name} {
    upvar 1 $name v
    set v [expr {$v * 2}]
}} tests {{set z 21; dbl z; set z} 42} why {Link with `upvar 1 $name v`, then set `v` to double its value.}}
}
cards {
  {{What does `upvar 1 name v` do?} {Makes `v` a local alias for the variable called `name` in the caller's scope.}}
  {{What does `uplevel 1 script` do?} {Runs the script in the caller's context.}}
  {{Why can you write your own control structures in Tcl?} {Braced code is just an argument; `uplevel` can run it in the caller, so commands like `repeat` behave like built-ins.}}
  {{How do you link to a global variable with upvar?} {`upvar #0 name local`}}
}
}

content::lesson 10.3 10 "Functions as data" "Lambdas, callbacks and looking at your own program." {
pages {
  {head "apply and anonymous functions" body {
    p {`apply` runs a **function value**: a list of parameters and a body (and optionally a namespace). It needs no name, so it is perfect for short throwaway functions.}
    code {puts [apply {{x} {expr {$x * 2}}} 21]
set sq {{n} {expr {$n * $n}}}
puts [apply $sq 7]
puts [lmap n {1 2 3} {apply $sq $n}]}
    out {42
49
1 4 9}
    p {Because the function is an ordinary value, you can store it in a variable, put it in a list, and pass it to a proc.}
  }}
  {head "Callbacks: command prefixes" body {
    p {A **command prefix** is a command with some leading arguments already filled in. A proc can take one and add the final argument(s) with `{*}`.}
    code {proc map {cmd list} {
    set r {}
    foreach x $list {lappend r [{*}$cmd $x]}
    return $r
}
puts [map {string toupper} {a b c}]
puts [map {apply {{n} {expr {$n * 3}}}} {1 2 3}]}
    out {A B C
3 6 9}
    p {This pattern is everywhere in Tcl: `after`, `trace`, `bind`, `fileevent`, `lsort -command`... all accept command prefixes.}
  }}
  {head "Looking at your own program" body {
    p {Tcl can inspect itself. `info` tells you about commands, variables and procs - and `rename` can change a command's name.}
    code {proc add {a b} {expr {$a + $b}}
puts [info args add]
puts [info body add]
puts [info exists nothing]
puts [llength [info procs add]]
rename add plus
puts [plus 1 2]}
    out {a b
expr {$a + $b}
0
1
3}
    tip {Because everything is a command, you can wrap or replace any command - even built-in ones - by renaming it and defining a new one in its place.}
  }}
}
ex {
  {kind predict code {puts [apply {{a b} {expr {$a + $b}}} 3 4]} choices {7 12 {3 4} a} ans 0 why {`apply` calls the function value with the arguments 3 and 4.}}
  {kind predict code {set f {{s} {string repeat $s 2}}
puts [apply $f ha]} choices {haha ha {ha ha} s} ans 0 why {The function repeats its argument twice.}}
  {kind predict code {proc each {cmd list} {foreach x $list {{*}$cmd $x}}
each puts {a b}} choices {"a\nb" "a b" "b\na" ""} ans 0 why {The prefix `puts` plus each item makes `puts a` and `puts b`.}}
  {kind predict code {proc greet {name} {return "hi $name"}
puts [info args greet]} choices {name greet hi {}} ans 0 why {`info args` lists the parameter names.}}
  {kind predict code {proc old {} {return 1}
rename old new
puts [new]} choices {1 old new {}} ans 0 why {`rename` changed the command's name but not what it does.}}
  {kind predict code {puts [lmap w {ab abc a} {string length $w}]} choices {{2 3 1} {1 2 3} {3 2 1} {ab abc a}} ans 0 why {Each word is replaced by its length.}}
  {kind mc q {What is a command prefix?} choices {{A command with some leading arguments, to which more are added later} {The first letter of a command} {A comment} {A namespace}} ans 0 why {`{string toupper}` is a prefix; calling `{*}$prefix hello` appends the final argument.}}
  {kind blank q {Call the function value with the argument 5.} code {set sq {{n} {expr {$n * $n}}}
puts [___ $sq 5]} answers {apply} extra {eval call proc} out {25} why {`apply funcValue arg ...`.}}
  {kind type q {Which command lists the parameter names of a proc?} accept {info args} why {`info args procName`.}}
  {kind code prompt {Write a proc **compose** taking two command prefixes f and g and a value x, returning f applied to the result of g applied to x. Example: `compose {string toupper} {string reverse} abc` gives `CBA`.} starter {proc compose {f g x} {
    return $x
}} solution {proc compose {f g x} {
    return [{*}$f [{*}$g $x]]
}} tests {{compose {string toupper} {string reverse} abc} CBA {compose {string length} {string trim} {  hi }} 2} why {Apply g first, then f to that result - each prefix gets its last argument via `{*}`.}}
}
cards {
  {{What does `apply` do?} {Calls a function value `{params body}` with arguments: `apply {{x} {expr {$x * 2}}} 21`.}}
  {{What is a command prefix?} {A command plus leading arguments, to which a caller appends more: `{*}$prefix $extra`.}}
  {{How do you get a proc's parameters or body?} {`info args name` and `info body name`.}}
  {{What does `rename old new` do?} {Gives a command a new name (and `rename old {}` deletes it).}}
}
}

content::lesson 10.4 10 "Namespaces and ensembles" "Organise large programs and build commands with subcommands." {
pages {
  {head "Namespaces" body {
    p {A **namespace** is a named container for commands and variables, preventing clashes in big programs. Refer to its contents with `name::item`.}
    code {namespace eval counter {
    variable n 0
    proc next {} {
        variable n
        return [incr n]
    }
}
puts [counter::next]
puts [counter::next]}
    out {1
2}
    p {`variable` declares a namespace variable, and inside a proc it links the name to the namespace's variable. The global namespace is written `::`.}
  }}
  {head "export and import" body {
    p {A namespace can `export` some commands, and others can `import` them to use the short name.}
    code {namespace eval util {
    namespace export double
    proc double {x} {expr {$x * 2}}
}
namespace import util::double
puts [double 4]
puts [util::double 5]}
    out {8
10}
    tip {Useful helpers: `namespace current` (where am I?), `namespace children`, `namespace which -command name`.}
  }}
  {head "Ensembles" body {
    p {Commands like `string` and `dict` have **subcommands**. `namespace ensemble create` lets you build the same thing: the exported procs of a namespace become its subcommands.}
    code {namespace eval stack {
    variable items {}
    proc push {x} {variable items; lappend items $x}
    proc pop {} {
        variable items
        set x [lindex $items end]
        set items [lrange $items 0 end-1]
        return $x
    }
    proc size {} {variable items; llength $items}
    namespace export push pop size
    namespace ensemble create
}
stack push 1
stack push 2
puts [stack pop]
puts [stack size]}
    out {2
1}
    p {This is how well-organised Tcl libraries look: `stack push`, `stack pop`, `stack size`. Later, TclOO will give you another way to bundle state and behaviour.}
  }}
}
ex {
  {kind predict code {namespace eval a {proc hi {} {return "from a"}}
puts [a::hi]} choices {{from a} hi a {}} ans 0 why {The proc lives in namespace `a` and is reached with `a::hi`.}}
  {kind predict code {namespace eval ctr {
    variable c 10
    proc up {} {variable c; incr c}
}
ctr::up
puts [ctr::up]} choices {12 11 10 1} ans 0 why {Each call adds one to the namespace variable: 11, then 12.}}
  {kind predict code {namespace eval m {
    namespace export sq
    proc sq {x} {expr {$x * $x}}
}
namespace import m::sq
puts [sq 6]} choices {36 12 6 {}} ans 0 why {After the import, `sq` can be used without the `m::` prefix.}}
  {kind predict code {namespace eval acc {
    variable list {}
    proc add {x} {variable list; lappend list $x}
    proc all {} {variable list; return $list}
    namespace export add all
    namespace ensemble create
}
acc add 1
acc add 2
puts [acc all]} choices {{1 2} {2 1} 1 {}} ans 0 why {`acc add` and `acc all` are subcommands created by the ensemble.}}
  {kind mc q {What does `namespace export` do?} choices {{Marks commands that others may import or that become ensemble subcommands} {Saves the namespace to disk} {Deletes the namespace} {Makes commands faster}} ans 0 why {Exported names can be imported elsewhere with `namespace import`.}}
  {kind mc q {Why use namespaces?} choices {{To avoid clashes between names in big programs} {To make code run in parallel} {Because procs need them} {To hide variables from the user}} ans 0 why {Each namespace has its own set of names.}}
  {kind blank q {Declare the namespace variable inside the proc.} code {namespace eval t {
    variable total 0
    proc add {n} {
        ___ total
        incr total $n
    }
}
t::add 5
puts [t::add 2]} answers {variable} extra {global set upvar} out {7} why {Inside a namespace proc, `variable name` links to the namespace variable.}}
  {kind type q {Which command creates a namespace (or runs code inside one)?} accept {namespace eval} why {`namespace eval name {...}`.}}
}
cards {
  {{How do you create a namespace and add a proc?} {`namespace eval name {proc p {} {...}}` - call it as `name::p`.}}
  {{What does `namespace ensemble create` do?} {Turns the namespace's exported commands into subcommands: `stack push 1`.}}
  {{How do you use a namespace variable in a proc?} {`variable name` inside the proc.}}
  {{How do you use the short name of a command from another namespace?} {`namespace import other::cmd` (the other namespace must export it).}}
}
}
