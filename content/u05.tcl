content::unit 5 "Procedures" "Create your own commands and organise programs into reusable pieces." "#FACC15"

content::lesson 5.1 5 "Your own commands" "Write code once, use it everywhere." {
pages {
  {head "proc" body {
    p {A **procedure** is a command that *you* create. `proc` defines it: first the name, then the parameter names in braces, then the body in braces.}
    code {proc greet {name} {
    puts "Hello, $name!"
}
greet "Ada"
greet "Linus"}
    out {Hello, Ada!
Hello, Linus!}
    p {Defining a proc does not run it. The body runs each time you call it, and `name` is filled in with whatever you pass.}
  }}
  {head "Giving back a result" body {
    p {`return` hands a value back to whoever called the procedure. Call the proc in square brackets to use the result.}
    code {proc double {x} {
    return [expr {$x * 2}]
}
puts [double 21]}
    out {42}
    tip {If a proc has no `return`, it gives back the result of its **last command**. So `proc double {x} {expr {$x * 2}}` works too.}
  }}
  {head "More than one parameter" body {
    p {List several parameter names. The caller must provide exactly that many values.}
    code {proc area {w h} {
    expr {$w * $h}
}
puts [area 3 4]}
    out {12}
    p {Call it with the wrong number of values and Tcl tells you the right shape:}
    code {area 3}
    out {wrong # args: should be "area w h"}
  }}
}
ex {
  {kind predict code {proc hello {} {
    puts "hi"
}
hello
hello} choices {"hi\nhi" hi "hello\nhello" nothing} ans 0 why {Calling the proc twice runs its body twice.}}
  {kind predict code {proc square {n} {
    return [expr {$n * $n}]
}
puts [square 7]} choices {49 14 7 n} ans 0 why {7 times 7 is 49.}}
  {kind predict code {proc add {a b} {expr {$a + $b}}
puts [add 2 3]} choices {5 23 {2 3} a} ans 0 why {The proc returns the result of its last command, `expr {$a + $b}`.}}
  {kind predict code {proc shout {s} {
    return [string toupper $s]
}
puts "[shout hey]!"} choices {HEY! hey! HEY {[shout hey]!}} ans 0 why {The call in brackets is replaced by its result, then `!` follows.}}
  {kind mc q {What does `return` do?} choices {{Hands a value back to the caller and ends the proc} {Prints a value} {Starts a loop} {Defines a variable}} ans 0 why {`return` gives a result back and leaves the procedure.}}
  {kind blank q {Define a proc that adds one to a number.} code {___ inc {n} {
    return [expr {$n + 1}]
}
puts [inc 9]} answers {proc} extra {def func set} out {10} why {`proc name {params} {body}` defines a procedure.}}
  {kind order q {Define a proc called twice and use it.} lines {{proc twice {x} {expr {$x * 2}}} {puts [twice 8]}} out {16} why {Define before you call - Tcl needs to know the command first.}}
  {kind type q {Which command defines a new procedure?} accept {proc} why {`proc`.}}
  {kind code prompt {Write a proc called **triple** that returns its argument times three.} starter {proc triple {n} {
    # your code here
}} solution {proc triple {n} {
    return [expr {$n * 3}]
}} tests {{triple 4} 12 {triple 0} 0 {triple -2} -6} why {The body must compute n * 3 and return it.}}
}
cards {
  {{How do you define a procedure?} {`proc name {param1 param2} {body}`}}
  {{What does a proc return if it has no `return`?} {The result of the last command in its body.}}
  {{How do you use a proc's result inside another command?} {Call it in square brackets: `puts [double 21]`.}}
  {{What error appears with the wrong number of arguments?} {`wrong # args: should be "name param1 param2"`}}
}
}

content::lesson 5.2 5 "Defaults and flexible arguments" "Optional parameters, any number of arguments and early exits." {
pages {
  {head "Default values" body {
    p {Give a parameter a **default** by writing the name and the default together in braces. Callers may then leave it out.}
    code {proc greet {{name "friend"}} {
    return "Hello, $name!"
}
puts [greet]
puts [greet "Ada"]}
    out {Hello, friend!
Hello, Ada!}
    p {Parameters with defaults must come **after** the required ones.}
  }}
  {head "Any number of arguments" body {
    p {If the last parameter is called `args`, it collects **all** the remaining values into a list.}
    code {proc sum {args} {
    set total 0
    foreach n $args {incr total $n}
    return $total
}
puts [sum 1 2 3 4]
puts [sum]}
    out {10
0}
    tip {`puts` itself, `expr max(...)` and `list` all work this way.}
  }}
  {head "Returning early" body {
    p {`return` leaves the procedure immediately, even from the middle of a loop or an `if`. This keeps code flat and readable.}
    code {proc sign {n} {
    if {$n < 0} {return "negative"}
    if {$n == 0} {return "zero"}
    return "positive"
}
puts [sign -5]
puts [sign 0]
puts [sign 12]}
    out {negative
zero
positive}
    p {To give back **two** values, return a list: `return [list $a $b]`.}
  }}
}
ex {
  {kind predict code {proc hi {{who "you"}} {return "hi $who"}
puts [hi]
puts [hi Ann]} choices {"hi you\nhi Ann" "hi\nhi Ann" "hi you\nhi you" "hi Ann\nhi Ann"} ans 0 why {Without an argument the default `you` is used.}}
  {kind predict code {proc count {args} {return [llength $args]}
puts [count a b c]} choices {3 1 a 0} ans 0 why {`args` collects every value into a list; `llength` counts its items.}}
  {kind predict code {proc max2 {a b} {
    if {$a > $b} {return $a}
    return $b
}
puts [max2 4 9]} choices {9 4 13 b} ans 0 why {4 > 9 is false, so execution continues to the final `return $b`.}}
  {kind predict code {proc f {n} {
    foreach x {1 2 3 4} {
        if {$x == $n} {return "found $x"}
    }
    return "none"
}
puts [f 3]
puts [f 9]} choices {"found 3\nnone" "found 3\nfound 9" "none\nnone" "3\n9"} ans 0 why {`return` exits the proc from inside the loop as soon as the item is found.}}
  {kind mc q {Where must parameters with defaults appear?} choices {{After the required parameters} {Before the required parameters} {Anywhere} {They cannot be used}} ans 0 why {Tcl fills parameters left to right; optional ones go last.}}
  {kind blank q {Collect any number of values.} code {proc total {___} {
    set t 0
    foreach n $args {incr t $n}
    return $t
}
puts [total 5 6]} answers {args} extra {list rest all} out {11} why {A final parameter named `args` gathers the remaining arguments into a list.}}
  {kind type q {What is the name of the special parameter that collects extra arguments?} accept {args} why {`args`.}}
  {kind code prompt {Write a proc **greet** with an optional name. `greet` returns `Hello, world!` and `greet Ada` returns `Hello, Ada!`.} starter {proc greet {} {
    return "Hello, world!"
}} solution {proc greet {{name world}} {
    return "Hello, $name!"
}} tests {{greet} {Hello, world!} {greet Ada} {Hello, Ada!}} why {Use `{name world}` to give the parameter a default value.}}
}
cards {
  {{How do you give a parameter a default value?} {Write it as a pair in braces: `proc greet {{name "friend"}} {...}`.}}
  {{What does the parameter `args` do?} {It collects all remaining arguments into a list, so a proc can take any number of values.}}
  {{How do you leave a proc early?} {Use `return` - it exits immediately, even inside a loop.}}
  {{How can a proc give back two values?} {Return a list: `return [list $a $b]`.}}
}
}

content::lesson 5.3 5 "Scope and recursion" "Which variables a proc can see - and procs that call themselves." {
pages {
  {head "Local variables" body {
    p {Variables created inside a proc are **local**: they exist only while the proc runs, and they cannot be seen outside. Likewise the proc cannot see your outside variables by default.}
    code {set x 10
proc f {} {
    set x 99
    return $x
}
puts [f]
puts $x}
    out {99
10}
    p {This is a feature: a proc cannot accidentally break variables elsewhere.}
  }}
  {head "global" body {
    p {Sometimes a proc really needs a variable from the outside. The `global` command links to it.}
    code {set count 0
proc bump {} {
    global count
    incr count
}
bump
bump
puts $count}
    out {2}
    tip {Prefer parameters and `return` to globals. They make procs easier to understand and test.}
  }}
  {head "Procs that call themselves" body {
    p {A **recursive** proc solves a problem by calling itself on a smaller one. It needs a **base case** that stops the chain.}
    code {proc fact {n} {
    if {$n <= 1} {return 1}
    return [expr {$n * [fact [expr {$n - 1}]]}]
}
puts [fact 5]}
    out {120}
    p {`fact 5` is 5 times `fact 4`, which is 4 times `fact 3`... down to `fact 1`, the base case.}
  }}
}
ex {
  {kind predict code {set x 1
proc f {} {
    set x 2
}
f
puts $x} choices {1 2 x {}} ans 0 why {The `x` inside `f` is a different, local variable.}}
  {kind predict code {set n 0
proc add {} {
    global n
    incr n 5
}
add
add
puts $n} choices {10 5 0 2} ans 0 why {`global n` makes the proc use the outside variable, so both calls change it.}}
  {kind predict code {proc fact {n} {
    if {$n <= 1} {return 1}
    return [expr {$n * [fact [expr {$n - 1}]]}]
}
puts [fact 4]} choices {24 10 16 4} ans 0 why {4 * 3 * 2 * 1 = 24.}}
  {kind predict code {proc sumto {n} {
    if {$n == 0} {return 0}
    return [expr {$n + [sumto [expr {$n - 1}]]}]
}
puts [sumto 4]} choices {10 4 24 0} ans 0 why {4 + 3 + 2 + 1 + 0 = 10.}}
  {kind mc q {What does a recursive procedure need to stop?} choices {{A base case that does not call itself} {A global variable} {A semicolon} {A loop}} ans 0 why {Without a base case, the proc would call itself forever.}}
  {kind blank q {Let the proc change the outside variable total.} code {set total 0
proc addten {} {
    ___ total
    incr total 10
}
addten
puts $total} answers {global} extra {local upvar set} out {10} why {`global` links the name inside the proc to the global variable.}}
  {kind type q {Which command lets a proc use a variable from outside it?} accept {global} why {`global name`. (`upvar` is the more general version - you will meet it later.)}}
  {kind code prompt {Write a recursive proc **power2** where `power2 n` returns 2 to the power n (assume n is 0 or more).} starter {proc power2 {n} {
    # base case: power2 0 is 1
}} solution {proc power2 {n} {
    if {$n == 0} {return 1}
    return [expr {2 * [power2 [expr {$n - 1}]]}]
}} tests {{power2 0} 1 {power2 1} 2 {power2 10} 1024} why {2 to the n is 2 times 2 to the n-1, and the base case is 1.}}
}
cards {
  {{Where are variables created inside a proc visible?} {Only inside that proc, while it runs (local scope).}}
  {{How does a proc use a variable from outside?} {`global name` inside the proc.}}
  {{What are the two parts of a recursive proc?} {A base case that returns directly, and a step that calls itself on a smaller problem.}}
  {{What does `fact 5` calculate?} {5 x 4 x 3 x 2 x 1 = 120 (the factorial).}}
}
}
