content::unit 11 "Expert Tcl" "Coroutines, objects, traces, events, safe sandboxes, performance and Tk." "#FBBF24"

content::lesson 11.1 11 "Coroutines" "Procedures that can pause and resume - generators, two-way conversations and state." {
pages {
  {head "yield and coroutine" body {
    p {A **coroutine** is a procedure that can **pause** with `yield` and later **resume** exactly where it stopped, with all its local variables intact. `coroutine name command` creates one; afterwards calling `name` resumes it.}
    code {proc counter {} {
    yield
    set i 0
    while 1 {yield [incr i]}
}
coroutine next counter
puts [next]
puts [next]
puts [next]}
    out {1
2
3}
    p {The first `yield` is just a starting gate: `coroutine next counter` runs `counter` until it reaches it. After that, each call to `next` runs until the next `yield`, which hands a value back.}
  }}
  {head "Generators" body {
    p {A coroutine is a perfect **generator** - a source of values produced on demand, even an endless one. Here are the Fibonacci numbers:}
    code {proc fib {} {
    yield
    set a 0
    set b 1
    while 1 {
        yield $a
        lassign [list $b [expr {$a + $b}]] a b
    }
}
coroutine nextfib fib
set out {}
for {set i 0} {$i < 8} {incr i} {lappend out [nextfib]}
puts $out}
    out {0 1 1 2 3 5 8 13}
    tip {Without coroutines you would need to store the state in global variables and write the logic "inside out". The loop above reads like the maths.}
  }}
  {head "Two-way conversations" body {
    p {Values travel **both** ways. The argument you pass when resuming becomes the result of `yield` inside the coroutine.}
    code {proc acc {} {
    set total 0
    set v [yield]
    while 1 {
        incr total $v
        set v [yield $total]
    }
}
coroutine sum acc
puts [sum 5]
puts [sum 10]
puts [sum 100]}
    out {5
15
115}
    p {Each coroutine has its own private stack, so you can run many at once. `info coroutine` gives the name of the current one, and the Events and timers lesson shows a very powerful use of that.}
  }}
}
ex {
  {kind predict code {proc gen {} {
    yield
    yield a
    yield b
}
coroutine g gen
puts [g]
puts [g]} choices {"a\nb" "b\na" "a\na" "a"} ans 0 why {The first `g` resumes to the second `yield` (returning a), the next to the third (returning b).}}
  {kind predict code {proc evens {} {
    yield
    set n 0
    while 1 {yield $n; incr n 2}
}
coroutine e evens
e; e
puts [e]} choices {4 2 0 6} ans 0 why {Three calls give 0, 2, then 4 - and `puts` shows the third.}}
  {kind predict code {proc echo {} {
    set v [yield]
    while 1 {set v [yield "got $v"]}
}
coroutine ec echo
puts [ec ping]} choices {{got ping} ping {} ec} ans 0 why {The argument `ping` becomes the result of `yield`, and the coroutine hands back `got ping`.}}
  {kind mc q {What does `yield` do inside a coroutine?} choices {{Pauses it and hands a value back to the caller} {Ends the program} {Starts a new coroutine} {Prints a value}} ans 0 why {The coroutine's whole state is kept until it is resumed.}}
  {kind mc q {What is a good use of a coroutine?} choices {{A generator that produces values on demand} {Renaming files} {Comparing strings} {Printing tables}} ans 0 why {Generators and cooperative tasks are the classic uses.}}
  {kind blank q {Create a coroutine named tick from the proc ticker.} code {proc ticker {} {yield; yield 1; yield 2}
___ tick ticker
puts [tick]} answers {coroutine} extra {proc yield eval} out {1} why {`coroutine name command` starts it; it stops at the first `yield`.}}
  {kind type q {Which command pauses a coroutine and returns a value?} accept {yield} why {`yield`.}}
  {kind code prompt {Write a proc **squares** to be used as a coroutine: after `coroutine sq squares`, each call of `sq` returns the next square number 1, 4, 9, 16...} starter {proc squares {} {
    yield
    return
}} solution {proc squares {} {
    yield
    set n 1
    while 1 {
        yield [expr {$n * $n}]
        incr n
    }
}} tests {{coroutine sq squares; list [sq] [sq] [sq]} {1 4 9}} why {Yield once to start, then yield `n * n` forever, incrementing `n` between yields.}}
}
cards {
  {{What does `yield` do?} {Pauses a coroutine and returns a value to its caller; the coroutine resumes later where it stopped.}}
  {{How do you create and use a coroutine?} {`coroutine name command ...`, then call `name` to resume it.}}
  {{What is a generator?} {A coroutine that produces a sequence of values on demand, one per resume.}}
  {{How does data get into a coroutine?} {The argument you pass when resuming becomes the result of `yield`.}}
}
}

content::lesson 11.2 11 "Objects with TclOO" "Bundle data and behaviour into classes." {
pages {
  {head "Classes and objects" body {
    p {**TclOO** is Tcl's built-in object system. A **class** is a blueprint; an **object** is one thing built from it. `oo::class create` makes a class, `new` makes an object, and the object's name becomes a command.}
    code {oo::class create Counter {
    variable n
    constructor {} {set n 0}
    method incr {} {incr n}
    method value {} {return $n}
}
set c [Counter new]
$c incr
$c incr
puts [$c value]}
    out {2}
    p {`variable` lists the object's private data, `constructor` runs when the object is created, and each `method` is a command the object understands. Two objects have separate data.}
  }}
  {head "Inheritance" body {
    p {A class can build on another with `superclass`. It inherits everything and may **override** methods. Inside a method, `my` calls the object's own methods.}
    code {oo::class create Animal {
    variable name
    constructor {n} {set name $n}
    method speak {} {return "..."}
    method describe {} {return "$name says [my speak]"}
}
oo::class create Dog {
    superclass Animal
    method speak {} {return "Woof"}
}
puts [[Animal new Rex] describe]
puts [[Dog new Fido] describe]}
    out {Rex says ...
Fido says Woof}
    p {`describe` is written once in `Animal`, yet calls the right `speak` for each kind of animal. That is **polymorphism**.}
  }}
  {head "Extending with next" body {
    p {An overriding method can still use the original through `next`. Objects can be removed with `destroy`.}
    code {oo::class create Base {
    method hello {} {return "hello"}
}
oo::class create Loud {
    superclass Base
    method hello {} {return "[string toupper [next]]!"}
}
set o [Loud new]
puts [$o hello]
$o destroy
puts [llength [info commands $o]]}
    out {HELLO!
0}
    tip {TclOO also offers mixins, filters, class variables and introspection (`info object`). It stays small because it is built on the same idea as the rest of Tcl: everything is a command.}
  }}
}
ex {
  {kind predict code {oo::class create Box {
    variable v
    constructor {x} {set v $x}
    method get {} {return $v}
}
set b [Box new 42]
puts [$b get]} choices {42 v Box {}} ans 0 why {The constructor stored 42 in the object's variable `v`; `get` returns it.}}
  {kind predict code {oo::class create C {
    variable n
    constructor {} {set n 0}
    method up {} {incr n}
}
set a [C new]
set b [C new]
$a up
$a up
puts [$b up]} choices {1 3 2 0} ans 0 why {Each object has its own `n`, so `b` starts at 0 and `up` makes it 1.}}
  {kind predict code {oo::class create P {method who {} {return parent}}
oo::class create Q {superclass P}
puts [[Q new] who]} choices {parent Q P {}} ans 0 why {`Q` inherits `who` from `P`.}}
  {kind predict code {oo::class create P {method who {} {return p}}
oo::class create Q {
    superclass P
    method who {} {return "q+[next]"}
}
puts [[Q new] who]} choices {q+p p q q+q} ans 0 why {`next` calls the parent class's version of the method.}}
  {kind mc q {What is `my` for inside a method?} choices {{Calling the object's own methods} {Printing the object} {Making a copy} {Destroying the object}} ans 0 why {`my speak` calls the `speak` method of the current object (respecting overrides).}}
  {kind mc q {What is the difference between a class and an object?} choices {{A class is a blueprint; an object is one thing made from it} {They are the same} {An object is a blueprint} {A class has no methods}} ans 0 why {You create objects from a class with `new`.}}
  {kind blank q {Create an object of the class Dog.} code {oo::class create Dog {method speak {} {return Woof}}
set d [Dog ___]
puts [$d speak]} answers {new} extra {create make init} out {Woof} why {`ClassName new` creates an object.}}
  {kind type q {Which keyword names the parent class in a TclOO class definition?} accept {superclass} why {`superclass`.}}
}
cards {
  {{How do you create a class and an object?} {`oo::class create Name {...}` and then `set o [Name new]`.}}
  {{What are `constructor`, `method` and `variable` in a class?} {Code that runs on creation, a command the object understands, and the object's private data.}}
  {{How does inheritance work in TclOO?} {`superclass Parent` - the subclass inherits methods and can override them, calling the original with `next`.}}
  {{What does `my` do in a method?} {Calls another method of the same object.}}
}
}

content::lesson 11.3 11 "Traces and introspection" "Watch variables and commands, and ask Tcl about itself." {
pages {
  {head "Watching variables" body {
    p {A **trace** runs a command whenever something happens to a variable (it is read, written or removed). The handler is called with the variable name, array index and the operation.}
    code {proc watch {name1 name2 op} {
    upvar 1 $name1 v
    puts "x is now $v"
}
trace add variable x write watch
set x 1
set x 2}
    out {x is now 1
x is now 2}
    p {Traces are how a user interface can stay in sync with data: change the variable, and the display updates itself. (Tk's `-textvariable` options work this way.)}
  }}
  {head "Watching commands" body {
    p {`trace add execution` runs code when a command starts (`enter`) or finishes (`leave`), which makes debugging and logging simple.}
    code {proc work {} {return done}
proc note {cmd op} {puts "calling: $cmd"}
trace add execution work enter note
puts [work]}
    out {calling: work
done}
    p {You can also trace `rename` and `delete` of commands. `trace remove` switches a trace off, and `trace info` lists what is installed.}
  }}
  {head "Asking Tcl about itself" body {
    p {`info` can answer almost any question about the running program: which variables exist, which procs are defined, how deep the call stack is, what the current proc was called with.}
    code {proc f {a b} {
    set c 3
    return [lsort [info vars]]
}
puts [f 1 2]
proc who {} {info level 0}
puts [who]
proc caller {} {info level -1}
proc outer {} {caller}
puts [outer]
puts [lsort [info commands string]]}
    out {a b c
who
outer
string}
    tip {Together with `uplevel`, `upvar`, `rename` and `trace`, introspection is what lets Tcl programs build debuggers, testing frameworks and entire new languages.}
  }}
}
ex {
  {kind predict code {proc log {n1 n2 op} {puts "changed"}
trace add variable v write log
set v 1
set v 2} choices {"changed\nchanged" changed "" "changed\nchanged\nchanged"} ans 0 why {The trace fires on each write.}}
  {kind predict code {proc show {n1 n2 op} {puts $op}
trace add variable q read show
set q 5
set z $q} choices {read write "write\nread" ""} ans 0 why {Only reading `q` (the second line) triggers the read trace.}}
  {kind predict code {proc t {} {return ok}
proc note {c o} {puts "enter $o"}
trace add execution t enter note
t} choices {{enter enter} ok {enter t} {}} ans 0 why {The handler gets the command string and the operation name `enter`.}}
  {kind predict code {proc p {x y} {set z 1; return [lsort [info vars]]}
puts [p 1 2]} choices {{x y z} {x y} z {}} ans 0 why {`info vars` lists the proc's local variables, parameters included.}}
  {kind predict code {proc who {} {info level 0}
puts [who]} choices {who {} 0 level} ans 0 why {`info level 0` is the command that is currently running.}}
  {kind mc q {What is a trace for?} choices {{Running code automatically when a variable or command is used} {Drawing a line} {Sorting lists} {Reading files}} ans 0 why {Traces react to events on variables and commands.}}
  {kind blank q {React when the variable is written.} code {proc note {a b c} {puts "written"}
trace add variable w ___ note
set w 1} answers {write} extra {read unset change} out {written} why {The operations are `read`, `write` and `unset`.}}
  {kind type q {Which command tells you about the running program (its procs, variables, call stack)?} accept {info} why {`info`.}}
}
cards {
  {{How do you run code when a variable changes?} {`trace add variable name write handler`}}
  {{What arguments does a variable trace handler receive?} {The variable name, the array index (or empty), and the operation: read, write or unset.}}
  {{What does `trace add execution cmd enter handler` do?} {Calls the handler every time the command starts running.}}
  {{What does `info level 0` return?} {The command (with its arguments) currently being executed.}}
}
}

content::lesson 11.4 11 "Events and timers" "Programs that react: timers, waiting and non-blocking code." {
pages {
  {head "The event loop" body {
    p {Interactive programs do not run top to bottom and stop. They sit in an **event loop**, waiting for something to happen - a timer, a click, data arriving - and then run the matching code. Tk programs, like this app, live in this loop.}
    code {after 50 {set done yes}
vwait done
puts "timer fired"}
    out {timer fired}
    p {`after ms script` schedules a script to run later. `vwait variable` **waits inside the event loop** until the variable is set, so timers (and everything else) keep working meanwhile.}
  }}
  {head "Repeating and cancelling" body {
    p {A timer runs once. To repeat, let the script schedule itself again. `after cancel` removes a pending timer, and `after idle` runs code as soon as nothing else is waiting.}
    code {set n 0
proc tick {} {
    global n
    incr n
    puts "tick $n"
    if {$n < 3} {after 10 tick} else {set ::finished 1}
}
tick
vwait finished}
    out {tick 1
tick 2
tick 3}
    code {set id [after 1000 {puts "never printed"}]
after cancel $id
puts "cancelled"}
    out {cancelled}
  }}
  {head "Sequential code without blocking" body {
    p {Here is a beautiful expert pattern: combine **coroutines** with **timers**. The coroutine asks the event loop to wake it later, then yields. It reads like ordinary step-by-step code, yet nothing ever blocks.}
    code {proc delay {ms} {after $ms [list [info coroutine]]; yield}
proc job {} {
    puts "start"
    delay 20
    puts "after 20 ms"
    delay 20
    puts "finished"
    set ::done 1
}
coroutine j job
vwait done}
    out {start
after 20 ms
finished}
    tip {This is the idea behind "async/await" in other languages. In Tcl it takes six lines and no special syntax.}
  }}
}
ex {
  {kind predict code {after 10 {set go 1}
vwait go
puts [set go]} choices {1 go {} 10} ans 0 why {`vwait` returned when the timer set `go` to 1.}}
  {kind predict code {set id [after 100 {puts hidden}]
after cancel $id
puts shown} choices {shown hidden "hidden\nshown" ""} ans 0 why {The timer was cancelled, so only the last line prints.}}
  {kind predict code {set order {}
after 30 {lappend order slow; set ::d 1}
after 10 {lappend order fast}
vwait d
puts $order} choices {{fast slow} {slow fast} fast slow} ans 0 why {Timers fire by time, not by the order they were created.}}
  {kind mc q {What does `vwait var` do?} choices {{Waits, while processing events, until the variable is set} {Sleeps and blocks everything} {Creates a variable} {Prints a variable}} ans 0 why {Unlike a sleep, `vwait` lets timers and other events keep running.}}
  {kind mc q {How do you make a timer repeat?} choices {{The scheduled script schedules itself again} {Use `after forever`} {Use two `after` commands} {It repeats by default}} ans 0 why {Each run schedules the next one.}}
  {kind blank q {Run the script after 20 milliseconds.} code {___ 20 {set ok 1}
vwait ok
puts $ok} answers {after} extra {wait later sleep} out {1} why {`after ms script` schedules the script.}}
  {kind type q {Which command cancels a scheduled timer?} accept {after cancel} why {`after cancel $id`.}}
}
cards {
  {{What does `after 500 script` do?} {Schedules the script to run once, 500 ms later, from the event loop.}}
  {{What does `vwait var` do?} {Runs the event loop until the variable is written, then continues.}}
  {{How do you repeat something every so often?} {Make the script call `after ms script` again for itself.}}
  {{What is a good way to write non-blocking sequential code?} {A coroutine that does `after ms [list [info coroutine]]; yield` to sleep.}}
}
}

content::lesson 11.5 11 "Interpreters, safety and packages" "Isolated worlds, running untrusted code, and sharing libraries." {
pages {
  {head "Separate interpreters" body {
    p {An **interpreter** is an independent Tcl world with its own commands and variables. `interp create` makes another one inside your program, and `eval` runs code in it. Nothing leaks across unless you allow it.}
    code {set i [interp create]
$i eval {set secret 42}
puts [$i eval {expr {$secret + 1}}]
puts [info exists secret]
interp delete $i}
    out {43
0}
    p {This is how this app runs **your** code safely: each Playground run happens in a fresh interpreter, with time and output limits.}
  }}
  {head "Safe interpreters and aliases" body {
    p {`interp create -safe` makes a **safe** interpreter that has no access to files, processes or the network - suitable for untrusted code such as plugins or scripts from users.}
    code {set s [interp create -safe]
puts [catch {$s eval {open /etc/passwd}} msg]
puts $msg}
    out {1
invalid command name "open"}
    p {A safe interpreter can still be given **specific** abilities. An **alias** is a command inside it that runs a command in the parent - you decide exactly what is exposed.}
    code {$s alias hello apply {{} {return "from the host"}}
puts [$s eval hello]}
    out {from the host}
    tip {`interp limit` can also cap run time or the number of commands. That is exactly what stops an endless loop in the Playground.}
  }}
  {head "Packages and modules" body {
    p {Libraries are shared as **packages**. A package announces itself with `package provide` and is loaded with `package require`, which also returns the version.}
    code {package provide mathx 1.0
namespace eval mathx {
    proc square {x} {expr {$x * $x}}
}
puts [package require mathx]
puts [mathx::square 9]}
    out {1.0
81}
    p {Real packages live in files. A `pkgIndex.tcl` tells Tcl where a package is, and single-file **Tcl modules** (`name-1.0.tm`) are found through `tcl::tm::path`. `source file` runs another script, which is how you split a program into parts - this app does exactly that. The huge **Tcllib** collection provides JSON, CSV, HTTP, sets, matrices and much more.}
  }}
}
ex {
  {kind predict code {set i [interp create]
$i eval {set v 7}
puts [$i eval {incr v}]} choices {8 7 v {}} ans 0 why {The variable lives inside the other interpreter, where `incr` makes it 8.}}
  {kind predict code {set i [interp create]
$i eval {set only_there 1}
puts [info exists only_there]} choices {0 1 only_there {}} ans 0 why {Interpreters do not share variables.}}
  {kind predict code {set s [interp create -safe]
puts [catch {$s eval {exec ls}}]} choices {1 0 ls {}} ans 0 why {`exec` is not available in a safe interpreter, so evaluating it raises an error.}}
  {kind predict code {set i [interp create]
$i alias twice apply {{x} {expr {$x * 2}}}
puts [$i eval {twice 21}]} choices {42 21 twice {}} ans 0 why {The alias in the child calls the function in the parent.}}
  {kind predict code {package provide demo 2.5
puts [package require demo]} choices {2.5 demo 1 {}} ans 0 why {`package require` returns the version that is available.}}
  {kind mc q {Why run user code in a safe interpreter?} choices {{It cannot touch files, processes or the network unless you allow it} {It runs faster} {It uses less memory} {It has more commands}} ans 0 why {Safety by default - you add abilities one by one with aliases.}}
  {kind mc q {What does an alias in a safe interpreter do?} choices {{Gives the child a command that runs a specific command in the parent} {Renames a variable} {Makes the child unsafe} {Deletes the parent}} ans 0 why {Aliases are the controlled doorway between the two worlds.}}
  {kind type q {Which command creates a separate Tcl interpreter?} accept {interp create} why {`interp create`.}}
}
cards {
  {{What does `interp create` do?} {Makes an independent Tcl interpreter with its own commands and variables; `$i eval {...}` runs code in it.}}
  {{What is special about `interp create -safe`?} {The interpreter has no access to files, processes or the network - good for untrusted code.}}
  {{What is an interp alias for?} {To give a safe interpreter one specific, controlled ability by running a command in the parent.}}
  {{How do you declare and use a package?} {`package provide name version` in the library, `package require name` in the user.}}
}
}

content::lesson 11.6 11 "Performance and style" "Write Tcl that is correct, safe, quick and pleasant to read." {
pages {
  {head "Always brace your expressions" body {
    p {`expr` should nearly always get its expression in **braces**. Braced expressions are compiled once to fast bytecode, and they are **safe**. Without braces, Tcl substitutes first and then evaluates the result - so data can run as code.}
    code {set input {[puts HACKED]}
catch {expr $input} r
puts "unbraced -> '$r'"
catch {expr {$input}} r2
puts "braced -> $r2"}
    out {HACKED
unbraced -> ''
braced -> [puts HACKED]}
    warn {The unbraced form ran the command hidden inside the data. The same rule applies to `if`, `while` and `for` conditions: always use braces.}
  }}
  {head "Measure, then improve" body {
    p {Do not guess where time goes: **measure**. `time {script} count` runs a script `count` times and reports the average.}
    code {set t [time {
    set s 0
    for {set i 0} {$i < 1000} {incr i} {incr s $i}
} 50]
puts [string match "*microseconds per iteration" $t]}
    out {1}
    p {Typical wins, each worth knowing:}
    p {- Use `lappend` to grow a list, not `set l "$l $x"` (which copies the whole list each time)
- Use `append` to build long strings
- Use a **dict or array** for lookups instead of searching a list inside a loop
- Use `lsearch -sorted` on sorted data
- Do work **once**, outside the loop}
  }}
  {head "Habits of good Tcl" body {
    p {Fast code that nobody can read is a bad trade. These habits make Tcl clear:}
    p {- Brace everything that is code or an expression
- Keep procs short and give them one job
- Return values instead of using globals; pass **data**, not variable names, unless you mean to modify them
- Never build code by gluing strings - use `list` and `{*}`
- Handle errors where you can do something about them
- Write a few tests (Tcl ships with the `tcltest` package)}
    tip {You can now read the source of this very app: it is a few thousand lines of ordinary Tcl and Tk, built from exactly the ideas in this course.}
  }}
}
ex {
  {kind mc q {Why should you write `expr {$a + $b}` rather than `expr $a + $b`?} choices {{It is faster and prevents the values from being run as code} {It is required} {It rounds the answer} {It allows decimals}} ans 0 why {Braced expressions are bytecode-compiled and avoid double substitution.}}
  {kind mc q {Which is the better way to grow a list inside a loop?} choices {{lappend result $x} {set result "$result $x"} {set result [concat $result $x]} {They are equal}} ans 0 why {`lappend` appends in place; the others copy the whole list each time.}}
  {kind mc q {You search a long list inside a loop over thousands of items. What is a better approach?} choices {{Put the lookup data in a dict or array first} {Use a bigger list} {Use `eval`} {Sort after every search}} ans 0 why {A dict lookup is nearly instant, while a list search checks items one by one.}}
  {kind predict code {set input {[puts X]}
puts [expr {$input}]} choices {{[puts X]} X {} 0} ans 0 why {A braced expression treats the value as plain data and does not run the command inside.}}
  {kind mc q {What does `time {script} 100` report?} choices {{The average time of one run of the script} {The total time in minutes} {The time of day} {How many commands ran}} ans 0 why {It runs the script 100 times and gives microseconds per iteration.}}
  {kind mc q {How should you assemble a command from user-supplied parts?} choices {{With `list` and then run it with `{*}$cmd`} {By joining strings with spaces} {With `format`} {With `subst`}} ans 0 why {`list` keeps each part as exactly one word.}}
  {kind blank q {Add to the end of a string efficiently.} code {set s "ab"
___ s "cd"
puts $s} answers {append} extra {lappend set concat} out {abcd} why {`append` extends the variable in place.}}
  {kind type q {Which command measures how long a script takes?} accept {time} why {`time script count`.}}
}
cards {
  {{Why brace expressions: `expr {...}`?} {They compile to fast bytecode and are safe from double substitution (code injection).}}
  {{What is the efficient way to grow a list or a string?} {`lappend` for lists and `append` for strings.}}
  {{How do you measure performance?} {`time {script} count` gives microseconds per iteration.}}
  {{How do you avoid slow lookups in loops?} {Use a dict or array instead of searching a list.}}
}
}

content::lesson 11.7 11 "Tk: the other half of Tcl" "Build windows and apps - the toolkit this very app is made of." {
pages {
  {head "A window in four lines" body {
    p {**Tk** is Tcl's graphical toolkit. Every window, button and label is a **widget** with a **path name** that starts with a dot and nests by dots: `.` is the main window, `.frame.button` is a button inside a frame.}
    show {package require Tk
label .hello -text "Hello, Tk!"
button .quit -text "Quit" -command exit
pack .hello .quit -padx 20 -pady 10}
    p {- A widget command (`label`, `button`, `entry`, `canvas`, `text`, `frame`...) creates the widget
- Options start with a dash: `-text`, `-command`, `-width`, `-bg`
- A **geometry manager** (`pack`, `grid`, `place`) puts it on screen
- `-command` takes a command prefix - the same idea as before}
    tip {Tk code needs a screen, so these examples are not run in the Playground. Try them on a computer with `wish`, which comes with Tcl/Tk.}
  }}
  {head "Events and variables" body {
    p {`bind` attaches a script to an event such as a click, key press or mouse movement. `%x` and `%y` in the script become the event's coordinates. `-textvariable` links a widget to a variable, using a trace under the hood.}
    show {entry .name -textvariable who
label .greet -textvariable msg
bind .name <KeyRelease> {
    set msg "Hello, $who!"
}
pack .name .greet}
    show {canvas .c -width 200 -height 100
pack .c
proc dot {x y} {
    set x1 [expr {$x - 5}]
    set y1 [expr {$y - 5}]
    set x2 [expr {$x + 5}]
    set y2 [expr {$y + 5}]
    .c create oval $x1 $y1 $x2 $y2 -fill red
}
bind .c <Button-1> {dot %x %y}}
    p {The second half draws a red dot wherever you click on the canvas. The canvas is also what draws every rounded button, card and icon in this app - and `after` (from the events lesson) drives animations like the confetti.}
  }}
  {head "Where next?" body {
    p {You have gone from "what is a program?" to coroutines, objects, safe interpreters and Tk. Real mastery comes from building things. Some ideas, easiest first:}
    p {- A to-do list or notes app (files, lists, a Tk listbox)
- A flashcard or quiz program of your own
- A text-adventure or a Tk game (a canvas and `after`)
- A tiny web server using `socket` and `fileevent`
- A library in a namespace, packaged with `package provide`, with tests}
    p {Keep this app's habits: retrieve, don't re-read; practise little and often; build something every week. Read the reference at **tcl-lang.org** and the community wiki at **wiki.tcl-lang.org**, and read this app's own source - it is yours to change.}
    tip {You can finish by opening `lib/ui.tcl` and changing the colours in `lib/theme.tcl`. Changing a program you use every day is the fastest way to learn.}
  }}
}
ex {
  {kind mc q {What does the dot in a Tk path name like `.frame.button` mean?} choices {{It separates a widget from its parent: the button is inside the frame} {A decimal point} {A comment} {The end of the name}} ans 0 why {Path names mirror the widget hierarchy, starting at `.` the main window.}}
  {kind mc q {What does `pack` do?} choices {{Places a widget on screen (it is a geometry manager)} {Compresses files} {Creates a widget} {Packs a list}} ans 0 why {Widgets are created by their class command, then positioned by `pack`, `grid` or `place`.}}
  {kind mc q {What does this code do?} code {button .b -text "Go" -command {puts clicked}} choices {{Creates a button that runs `puts clicked` when pressed} {Prints clicked immediately} {Creates a label} {Removes the button}} ans 0 why {`-command` holds a script that runs when the button is pressed.}}
  {kind mc q {What is `bind` for?} choices {{Running a script when an event such as a click or key press happens} {Joining two strings} {Creating variables} {Declaring a namespace}} ans 0 why {`bind widget <Event> script`.}}
  {kind mc q {Which option keeps a label in sync with a variable?} choices {-textvariable -text -command -variable} ans 0 why {`-textvariable` watches the variable and redraws the label when it changes.}}
  {kind type q {Which widget command creates a drawing surface for shapes and lines?} accept {canvas} why {`canvas`.}}
  {kind type q {Complete the line that loads the graphical toolkit: `package require ...`} accept {Tk} why {`package require Tk`.}}
}
cards {
  {{What is a Tk widget path name?} {A dotted name like `.frame.button`; `.` is the main window and each dot nests a child inside its parent.}}
  {{What are `pack`, `grid` and `place`?} {Geometry managers: they put widgets on the screen.}}
  {{What does `bind .w <Button-1> script` do?} {Runs the script when the left mouse button is clicked on the widget.}}
  {{What does `-textvariable` do?} {Links a widget's text to a variable, so it updates automatically.}}
}
}
