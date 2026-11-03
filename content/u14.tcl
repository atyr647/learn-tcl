content::unit 14 "Read, debug and build" "Read other people's code, hunt bugs, and finish eight real projects." "#EC4899"

content::lesson 14.1 14 "Reading and debugging real code" "The most underrated skill: understanding a program you did not write." {
pages {
  {head "How to read a program" body {
    p {Experts spend more time **reading** code than writing it. A reliable method:}
    p {- Find the **data**: what shapes flow through the program (lists? dicts of dicts?)
- Find the **entry point**: the lines that run when the program starts
- Read each proc by its **name, parameters and return value** first, body second
- **Trace** a tiny input by hand, writing down the variables as they change}
    code {proc parse {text} {
    set rows {}
    foreach line [split [string trim $text] "\n"] {
        lassign [split $line ,] name dept pay
        lappend rows [dict create name $name dept $dept pay $pay]
    }
    return $rows
}
proc totals {rows} {
    set t {}
    foreach r $rows {
        dict incr t [dict get $r dept] [dict get $r pay]
    }
    return $t
}
set data "ann,ops,30
bob,dev,50
cy,ops,20"
dict for {d n} [totals [parse $data]] {
    puts "$d: $n"
}}
    out {ops: 50
dev: 50}
    p {Data first: `parse` turns CSV text into a list of dicts; `totals` folds those into one dict of department to pay. The entry point is the last block. Tracing: ann adds 30 to ops, bob adds 50 to dev, cy adds 20 to ops, giving ops 50 and dev 50.}
  }}
  {head "Recursion and tables of behaviour" body {
    p {Two shapes you will meet constantly. **Recursive** code handles nested data by calling itself on the parts:}
    code {proc flatten {l} {
    set r {}
    foreach x $l {
        if {[llength $x] > 1} {
            lappend r {*}[flatten $x]
        } else {
            lappend r $x
        }
    }
    return $r
}
puts [flatten {1 {2 3} {4 {5 6}}}]}
    out {1 2 3 4 5 6}
    p {And **dispatch tables** replace long chains of `if` with a dict from name to behaviour:}
    code {set ops [dict create \
    add {{a b} {expr {$a + $b}}} \
    mul {{a b} {expr {$a * $b}}} \
    neg {{a} {expr {-$a}}}]
proc calc {op args} {
    global ops
    if {![dict exists $ops $op]} {error "unknown op $op"}
    apply [dict get $ops $op] {*}$args
}
puts [calc add 2 3]
puts [calc neg 5]
puts [catch {calc pow 2 3} m]
puts $m}
    out {5
-5
1
unknown op pow}
  }}
  {head "Debugging" body {
    p {Most bugs fall into a few families. Learn to recognise them:}
    p {- **Off-by-one**: `<` where you meant `<=`, or indexes starting at 0
- **Whole-number division**: `expr {7 / 2}` is 3
- **Scope**: a proc cannot see a global variable unless you say `global`
- **Quoting**: braces versus quotes, and a missing `$`
- **Mutation**: forgetting that `lappend`/`set` change the variable but `lsort` returns a new list}
    p {Debug scientifically: reproduce the bug with the **smallest** input, print the intermediate values with `puts`, form a guess, test the guess, repeat. Do not change code at random.}
    tip {`puts stderr "x=$x"` is a perfectly good debugger. `info body`, `info args` and `trace add execution` are better ones. And `catch` plus `puts $::errorInfo` shows the whole call stack of an error.}
  }}
}
ex {
  {kind predict code {proc flatten {l} {
    set r {}
    foreach x $l {
        if {[llength $x] > 1} {lappend r {*}[flatten $x]} else {lappend r $x}
    }
    return $r
}
puts [llength [flatten {a {b c} {d {e f g}}}]]} choices {7 5 3 4} ans 0 why {Seven leaves: a b c d e f g.}}
  {kind predict code {set ops [dict create sq {{x} {expr {$x * $x}}} inc {{x} {expr {$x + 1}}}]
puts [apply [dict get $ops sq] [apply [dict get $ops inc] 4]]} choices {25 17 20 5} ans 0 why {inc 4 = 5, then sq 5 = 25.}}
  {kind predict code {proc totals {rows} {
    set t {}
    foreach r $rows {dict incr t [lindex $r 0] [lindex $r 1]}
    return $t
}
puts [totals {{a 1} {b 2} {a 3}}]} choices {{a 4 b 2} {a 1 b 2 a 3} {a 3 b 2} {4 2}} ans 0 why {Amounts for the same key are added.}}
  {kind mc q {You find `for {set i 0} {$i <= [llength $l]} {incr i}` while reading a program. What is the likely bug?} choices {{Off-by-one: it runs once too many (indexes go 0 to llength-1)} {It runs too few times} {It never runs} {There is no bug}} ans 0 why {A list with n items has indexes 0 .. n-1.}}
  {kind mc q {A proc reads a variable `count` that is set at the top of the script, but fails with "no such variable". Why?} choices {{Procs have their own scope; it needs `global count`} {Variables cannot be read in procs} {count is a reserved word} {The script must be saved first}} ans 0 why {Without `global` (or `::count`) the proc looks in its own local scope.}}
  {kind mc q {What is the best first step when you find a bug?} choices {{Reproduce it with the smallest possible input} {Rewrite the whole function} {Add random changes until it works} {Ignore it}} ans 0 why {A small reproduction makes the cause visible.}}
  {kind code prompt {**Fix the bug.** `average` should return a decimal result, but whole-number division throws away the fraction.} starter {proc average {l} {
    set t 0
    foreach x $l {incr t $x}
    return [expr {$t / [llength $l]}]
}} solution {proc average {l} {
    set t 0
    foreach x $l {incr t $x}
    return [expr {double($t) / [llength $l]}]
}} tests {{average {1 2}} 1.5 {average {4}} 4.0} why {Making one operand a double forces decimal division.}}
  {kind code prompt {**Fix the bug.** `range 3` should return `1 2 3`, but it stops one short.} starter {proc range {n} {
    set r {}
    for {set i 1} {$i < $n} {incr i} {lappend r $i}
    return $r
}} solution {proc range {n} {
    set r {}
    for {set i 1} {$i <= $n} {incr i} {lappend r $i}
    return $r
}} tests {{range 3} {1 2 3} {range 1} 1 {range 0} {}} why {The test must be `<=` so n itself is included.}}
  {kind code prompt {**Fix the bug.** `hit` should increase the global `count`, but it fails because of scope.} starter {proc hit {} {
    incr count
}} solution {proc hit {} {
    global count
    incr count
}} tests {{set count 0; hit; hit; set count} 2} why {`global count` links the name to the global variable.}}
  {kind code prompt {**Fix the bug.** `sorted` should return the list in order, but the result is thrown away.} starter {proc sorted {l} {
    lsort $l
    return $l
}} solution {proc sorted {l} {
    return [lsort $l]
}} tests {{sorted {c a b}} {a b c}} why {`lsort` returns a new list; it does not change the original.}}
  {kind code prompt {Write a proc **depth** returning how deeply a list is nested. A single word has depth 0; a list is 1 plus the depth of its deepest item. So `depth x` is 0, `depth {a b}` is 1 and `depth {a {b {c d}}}` is 3.} starter {proc depth {x} {
    return 0
}} solution {proc depth {x} {
    if {[llength $x] <= 1 && [lindex $x 0] eq $x} {return 0}
    set d 0
    foreach i $x {
        set di [depth $i]
        if {$di > $d} {set d $di}
    }
    return [expr {$d + 1}]
}} tests {{depth x} 0 {depth {a b}} 1 {depth {a {b {c d}}}} 3} why {Recurse into each item, keep the deepest, add one.}}
}
cards {
  {{What is a reliable method for reading unfamiliar code?} {Find the data shapes, find the entry point, read each proc's name/parameters/return first, then trace a tiny input by hand.}}
  {{Name common bug families.} {Off-by-one, whole-number division, missing `global` (scope), quoting mistakes, and forgetting `lsort`/`string` return new values.}}
  {{What is a dispatch table?} {A dict from a name to behaviour (a lambda), replacing a long if/elseif chain: `apply [dict get $ops $name] {*}$args`.}}
  {{How should you debug?} {Reproduce with the smallest input, print intermediate values, guess, test the guess, repeat - never change code at random.}}
}
}

content::lesson 14.2 14 "Project 1: a to-do manager" "Lists, dicts, namespaces and procs working together." {
pages {
  {head "The brief" body {
    p {Build a small **to-do manager** as a namespace called `todo`. It must:}
    p {- `todo::reset` empties the list
- `todo::add title` adds an item and returns its id (1, 2, 3, ...)
- `todo::complete id` marks an item done, or raises the error `no such item` for an unknown id
- `todo::pending` returns the titles of the items not yet done, in id order
- `todo::report` returns a text listing, one line per item, like `[x] 1 milk` (done) or `[ ] 2 eggs`}
    p {Work in small steps: each exercise below adds one feature, and you can always run it in the **Playground** first.}
  }}
  {head "Design" body {
    p {Store the items in a **dict keyed by id**, each value a dict with `title` and `done`. A separate counter gives the next id. A namespace keeps all of it private:}
    code {namespace eval todo {
    variable items {}
    variable next 1
    proc reset {} {
        variable items
        variable next
        set items {}
        set next 1
    }
}
puts [dict size $todo::items]}
    out {0}
    p {Each public proc starts with `variable items next` to reach the namespace's data. Because the dict is keyed by id, finding or updating an item is a single `dict` call.}
  }}
  {head "Tips" body {
    p {- Create the next id with `incr next` and use the value **before** incrementing
- `dict set items $id [dict create title $title done 0]` stores a record
- For `report`, `dict for` walks the items in insertion order, which is id order here
- Use `error "no such item"` and test it with `catch`}
    tip {Think about the unhappy paths early: unknown ids, empty lists, and titles containing spaces. Tests for those catch the most bugs.}
  }}
}
ex {
  {kind code prompt {**Step 1.** Create the namespace `todo` with `reset` and `add`. `add title` stores the item and returns its id.} starter {namespace eval todo {
    variable items {}
    variable next 1
}} solution {namespace eval todo {
    variable items {}
    variable next 1
    proc reset {} {
        variable items
        variable next
        set items {}
        set next 1
    }
    proc add {title} {
        variable items
        variable next
        set id $next
        incr next
        dict set items $id [dict create title $title done 0]
        return $id
    }
}} tests {{todo::reset; todo::add milk; todo::add eggs} 2 {todo::reset; todo::add milk} 1} why {Read `next` for the id, increment it, and store a record under that id.}}
  {kind code prompt {**Step 2.** Add `complete id`. It sets `done` to 1, and raises `no such item` if the id does not exist. (Your namespace from step 1 is included.)} starter {namespace eval todo {
    variable items {}
    variable next 1
    proc reset {} {variable items; variable next; set items {}; set next 1}
    proc add {title} {
        variable items; variable next
        set id $next; incr next
        dict set items $id [dict create title $title done 0]
        return $id
    }
}} solution {namespace eval todo {
    variable items {}
    variable next 1
    proc reset {} {variable items; variable next; set items {}; set next 1}
    proc add {title} {
        variable items; variable next
        set id $next; incr next
        dict set items $id [dict create title $title done 0]
        return $id
    }
    proc complete {id} {
        variable items
        if {![dict exists $items $id]} {error "no such item"}
        dict set items $id done 1
    }
}} tests {{todo::reset; set a [todo::add x]; todo::complete $a; dict get $todo::items $a done} 1 {todo::reset; catch {todo::complete 9} m; set m} {no such item}} why {Check with `dict exists` first.}}
  {kind code prompt {**Step 3.** Add `pending`, returning the titles of items that are not done, in id order.} starter {namespace eval todo {
    variable items {}
    variable next 1
    proc reset {} {variable items; variable next; set items {}; set next 1}
    proc add {title} {
        variable items; variable next
        set id $next; incr next
        dict set items $id [dict create title $title done 0]
        return $id
    }
    proc complete {id} {
        variable items
        if {![dict exists $items $id]} {error "no such item"}
        dict set items $id done 1
    }
}} solution {namespace eval todo {
    variable items {}
    variable next 1
    proc reset {} {variable items; variable next; set items {}; set next 1}
    proc add {title} {
        variable items; variable next
        set id $next; incr next
        dict set items $id [dict create title $title done 0]
        return $id
    }
    proc complete {id} {
        variable items
        if {![dict exists $items $id]} {error "no such item"}
        dict set items $id done 1
    }
    proc pending {} {
        variable items
        set r {}
        dict for {id rec} $items {
            if {![dict get $rec done]} {lappend r [dict get $rec title]}
        }
        return $r
    }
}} tests {{todo::reset; todo::add milk; set b [todo::add eggs]; todo::add bread; todo::complete $b; todo::pending} {milk bread}} why {Walk the records and collect titles whose `done` is 0.}}
  {kind code prompt {**Step 4.** Add `report`: one line per item, `[x] 1 milk` for done and `[ ] 2 eggs` for pending, joined with newlines.} starter {namespace eval todo {
    variable items {}
    variable next 1
    proc reset {} {variable items; variable next; set items {}; set next 1}
    proc add {title} {
        variable items; variable next
        set id $next; incr next
        dict set items $id [dict create title $title done 0]
        return $id
    }
    proc complete {id} {
        variable items
        if {![dict exists $items $id]} {error "no such item"}
        dict set items $id done 1
    }
}} solution {namespace eval todo {
    variable items {}
    variable next 1
    proc reset {} {variable items; variable next; set items {}; set next 1}
    proc add {title} {
        variable items; variable next
        set id $next; incr next
        dict set items $id [dict create title $title done 0]
        return $id
    }
    proc complete {id} {
        variable items
        if {![dict exists $items $id]} {error "no such item"}
        dict set items $id done 1
    }
    proc report {} {
        variable items
        set lines {}
        dict for {id rec} $items {
            set mark [expr {[dict get $rec done] ? "x" : " "}]
            lappend lines "\[$mark\] $id [dict get $rec title]"
        }
        return [join $lines "\n"]
    }
}} tests {{todo::reset; todo::add milk; set b [todo::add eggs]; todo::complete $b; todo::report} {[ ] 1 milk
[x] 2 eggs}} why {Build each line with a conditional mark, then `join` the lines with newlines.}}
  {kind code prompt {**Step 5 - final.** Put it all together in one namespace: reset, add, complete, pending and report, with a **count** proc returning how many items are not done.} starter {namespace eval todo {
}} solution {namespace eval todo {
    variable items {}
    variable next 1
    proc reset {} {variable items; variable next; set items {}; set next 1}
    proc add {title} {
        variable items; variable next
        set id $next; incr next
        dict set items $id [dict create title $title done 0]
        return $id
    }
    proc complete {id} {
        variable items
        if {![dict exists $items $id]} {error "no such item"}
        dict set items $id done 1
    }
    proc pending {} {
        variable items
        set r {}
        dict for {id rec} $items {
            if {![dict get $rec done]} {lappend r [dict get $rec title]}
        }
        return $r
    }
    proc report {} {
        variable items
        set lines {}
        dict for {id rec} $items {
            set mark [expr {[dict get $rec done] ? "x" : " "}]
            lappend lines "\[$mark\] $id [dict get $rec title]"
        }
        return [join $lines "\n"]
    }
    proc count {} {return [llength [pending]]}
}} tests {{todo::reset; todo::add a; todo::add b; todo::add c; todo::complete 2; todo::count} 2 {todo::reset; todo::count} 0 {todo::reset; todo::add "buy milk"; todo::pending} {{buy milk}}} why {`count` reuses `pending` - small procs that build on each other.}}
  {kind mc q {Why store items in a dict keyed by id rather than a list of titles?} choices {{Looking up or updating one item is a single dict call, and ids stay stable if items are removed} {Dicts are always faster} {Lists cannot hold text} {It uses less memory}} ans 0 why {Stable ids and direct lookup are the point.}}
  {kind predict code {namespace eval t {variable n 1; proc next {} {variable n; set id $n; incr n; return $id}}
puts "[t::next][t::next][t::next]"} choices {123 111 321 333} ans 0 why {Read the value, then increment - so ids go 1, 2, 3.}}
}
cards {
  {{How do you give items stable ids?} {Keep a `next` counter in the namespace; use its value as the id, then `incr` it.}}
  {{How do you raise a clear error for an unknown id?} {`if {![dict exists $items $id]} {error "no such item"}`}}
  {{Why use a namespace for a module?} {It keeps the data and procs together and private, avoiding clashes with other code.}}
}
}

content::lesson 14.3 14 "Project 2: a word-frequency analyser" "Text processing with regular expressions, dicts and sorting." {
pages {
  {head "The brief" body {
    p {Write the core of a **text analyser**. Given any text it should:}
    p {- `tokenize text` split it into lower-case words (letters and apostrophes only; punctuation and numbers are dropped)
- `count words` return a dict of how often each word appears
- `top counts n` the n most frequent words, most frequent first (ties keep first-seen order)
- `drop counts stopwords` remove common words such as `the` and `a`}
  }}
  {head "Design" body {
    p {The pipeline is four small pure functions, each easy to test on its own: **text -> words -> counts -> ranking**. A `regexp -all -inline` does the tokenising in one line:}
    code {puts [regexp -all -inline {[a-z']+} [string tolower "It's a dog-eat-dog world, 2 times!"]]}
    out {it's a dog eat dog world times}
    p {Note how the hyphen, comma, digit and exclamation mark all act as separators.}
  }}
  {head "Tips" body {
    p {- Always lower-case **before** matching, so `[a-z']` is enough
- `dict incr counts $w` counts without any `if`
- `lsort -stride 2 -index 1 -integer -decreasing` ranks a flat dict, keeping ties in first-seen order because `lsort` is stable
- To drop stop words use `dict remove` or skip them in a `foreach`}
    tip {Small, pure functions (input in, result out, no globals) are the easiest code to test and reuse. The whole analyser needs no global state at all.}
  }}
}
ex {
  {kind code prompt {**Step 1.** Write `tokenize`.} starter {proc tokenize {text} {
    return {}
}} solution {proc tokenize {text} {
    return [regexp -all -inline {[a-z']+} [string tolower $text]]
}} tests {{tokenize "It's a dog-eat-dog world, 2 times!"} {it's a dog eat dog world times} {tokenize "123 !!"} {}} why {Lower-case, then collect runs of letters and apostrophes.}}
  {kind code prompt {**Step 2.** Write `count`, returning a dict of word counts from a list of words.} starter {proc count {words} {
    return {}
}} solution {proc count {words} {
    set d {}
    foreach w $words {dict incr d $w}
    return $d
}} tests {{count {a b a c a b}} {a 3 b 2 c 1} {count {}} {}} why {`dict incr` creates missing keys at zero.}}
  {kind code prompt {**Step 3.** Write `top counts n`, returning the n most frequent words, highest first.} starter {proc top {counts n} {
    return {}
}} solution {proc top {counts n} {
    set r {}
    foreach {w c} [lsort -stride 2 -index 1 -integer -decreasing $counts] {lappend r $w}
    return [lrange $r 0 [expr {$n - 1}]]
}} tests {{top {a 3 b 5 c 4 d 1} 2} {b c} {top {x 1 y 1 z 1} 2} {x y}} why {Stable sorting keeps ties in their original order.}}
  {kind code prompt {**Step 4.** Write `drop counts stopwords`, returning the dict without any word in the stopword list.} starter {proc drop {counts stop} {
    return $counts
}} solution {proc drop {counts stop} {
    set r {}
    dict for {w c} $counts {
        if {$w ni $stop} {dict set r $w $c}
    }
    return $r
}} tests {{drop {the 5 cat 2 a 3 dog 1} {the a}} {cat 2 dog 1}} why {The `ni` operator tests "not in" a list.}}
  {kind code prompt {**Step 5 - final.** Write `analyse text n stopwords`, returning the n most frequent non-stop words of the text, using all four steps.} starter {proc analyse {text n stop} {
    return {}
}} solution {proc analyse {text n stop} {
    set counts {}
    foreach w [regexp -all -inline {[a-z']+} [string tolower $text]] {
        if {$w in $stop} continue
        dict incr counts $w
    }
    set r {}
    foreach {w c} [lsort -stride 2 -index 1 -integer -decreasing $counts] {lappend r $w}
    return [lrange $r 0 [expr {$n - 1}]]
}} tests {{analyse "The cat and the hat and the bat. The cat sat." 2 {the and}} {cat hat} {analyse "" 3 {}} {}} why {Chain the pipeline: tokenise, filter, count, rank, take n.}}
  {kind predict code {puts [regexp -all -inline {[a-z']+} "don't stop-believin'"]} choices {{don't stop believin'} {don't stop-believin'} {dont stop believin} {don't}} ans 0 why {Apostrophes are kept; the hyphen separates words.}}
  {kind mc q {Why lower-case the text before tokenising?} choices {{So "The" and "the" count as the same word} {Regular expressions require it} {It makes the program faster} {Tcl cannot match capitals}} ans 0 why {Normalising input is the first step of most text pipelines.}}
}
cards {
  {{How do you split text into words with a regex?} {`regexp -all -inline {[a-z']+} [string tolower $text]`}}
  {{How do you rank a flat dict by value?} {`lsort -stride 2 -index 1 -integer -decreasing $dict` (stable, so ties keep order).}}
  {{What makes a function easy to test?} {Pure: input in, result out, no hidden global state.}}
}
}

content::lesson 14.4 14 "Project 3: an RPN calculator" "A stack machine with careful error handling." {
pages {
  {head "The brief" body {
    p {**Reverse Polish Notation** writes the operator after its numbers: `3 4 +` means 3 plus 4, and `3 4 + 2 *` means (3 + 4) times 2. It needs no brackets and is trivially evaluated with a **stack**: numbers are pushed; an operator pops two, computes, and pushes the result.}
    p {Write `rpn expression` supporting `+ - * /`, with these rules:}
    p {- the result is the single value left on the stack
- an operator without two numbers raises `stack underflow`
- an unknown word raises `bad token: X`
- leftovers (more than one value at the end) raise `too many values`}
  }}
  {head "Design" body {
    p {Keep the stack as a list and use `lindex ... end` and `lrange` to pop. A small loop over the tokens does everything:}
    code {set stack {}
foreach tok {3 4 +} {
    if {[string is double -strict $tok]} {
        lappend stack $tok
    } else {
        set b [lindex $stack end]
        set a [lindex $stack end-1]
        set stack [lrange $stack 0 end-2]
        lappend stack [expr "$a $tok $b"]
    }
}
puts $stack}
    out {7}
    p {The operand order matters for `-` and `/`: the **second-from-top** is the left operand.}
  }}
  {head "Tips" body {
    p {- Check the stack size **before** popping, so underflow is a clean error rather than an `expr` crash
- Build the expression with `expr {$a + $b}`-style code, or use `switch` on the operator for safety
- `/` should produce a decimal when needed; use `double($a) / $b`
- Raise errors with `error "..."` and test them with `catch`}
    warn {`expr "$a $tok $b"` would evaluate whatever the token says if it were not validated. Always check the token against the allowed operators first - never pass user input straight to `expr`.}
  }}
}
ex {
  {kind code prompt {**Step 1.** Write `rpn` for numbers and `+` only.} starter {proc rpn {text} {
    return 0
}} solution {proc rpn {text} {
    set stack {}
    foreach tok $text {
        if {$tok eq "+"} {
            set b [lindex $stack end]
            set a [lindex $stack end-1]
            set stack [lrange $stack 0 end-2]
            lappend stack [expr {$a + $b}]
        } else {
            lappend stack $tok
        }
    }
    return [lindex $stack end]
}} tests {{rpn "3 4 +"} 7 {rpn "1 2 + 3 +"} 6} why {Push numbers; on `+` pop two and push the sum.}}
  {kind code prompt {**Step 2.** Support `+ - * /` using a `switch` on the operator. Division should give a decimal: `rpn "7 2 /"` is 3.5.} starter {proc rpn {text} {
    return 0
}} solution {proc rpn {text} {
    set stack {}
    foreach tok $text {
        switch -- $tok {
            + - - - * - / {
                set b [lindex $stack end]
                set a [lindex $stack end-1]
                set stack [lrange $stack 0 end-2]
                switch -- $tok {
                    +  {set r [expr {$a + $b}]}
                    -  {set r [expr {$a - $b}]}
                    *  {set r [expr {$a * $b}]}
                    /  {set r [expr {double($a) / $b}]}
                }
                lappend stack $r
            }
            default {lappend stack $tok}
        }
    }
    return [lindex $stack end]
}} tests {{rpn "3 4 + 2 *"} 14 {rpn "10 4 -"} 6 {rpn "7 2 /"} 3.5} why {Operand order: the second-from-top is the left operand.}}
  {kind code prompt {**Step 3.** Add errors: `stack underflow` when an operator lacks two values, and `bad token: X` for anything that is neither a number nor an operator.} starter {proc rpn {text} {
    return 0
}} solution {proc rpn {text} {
    set stack {}
    foreach tok $text {
        if {[string is double -strict $tok]} {
            lappend stack $tok
        } elseif {$tok in {+ - * /}} {
            if {[llength $stack] < 2} {error "stack underflow"}
            set b [lindex $stack end]
            set a [lindex $stack end-1]
            set stack [lrange $stack 0 end-2]
            switch -- $tok {
                +  {set r [expr {$a + $b}]}
                -  {set r [expr {$a - $b}]}
                *  {set r [expr {$a * $b}]}
                /  {set r [expr {double($a) / $b}]}
            }
            lappend stack $r
        } else {
            error "bad token: $tok"
        }
    }
    return [lindex $stack end]
}} tests {{rpn "3 4 +"} 7 {catch {rpn "3 +"} m; set m} {stack underflow} {catch {rpn "3 x"} m; set m} {bad token: x}} why {Validate before popping, and reject unknown words.}}
  {kind code prompt {**Step 4 - final.** Add the `too many values` error when more than one value is left, and an empty expression should raise `empty expression`.} starter {proc rpn {text} {
    return 0
}} solution {proc rpn {text} {
    if {[llength $text] == 0} {error "empty expression"}
    set stack {}
    foreach tok $text {
        if {[string is double -strict $tok]} {
            lappend stack $tok
        } elseif {$tok in {+ - * /}} {
            if {[llength $stack] < 2} {error "stack underflow"}
            set b [lindex $stack end]
            set a [lindex $stack end-1]
            set stack [lrange $stack 0 end-2]
            switch -- $tok {
                +  {set r [expr {$a + $b}]}
                -  {set r [expr {$a - $b}]}
                *  {set r [expr {$a * $b}]}
                /  {set r [expr {double($a) / $b}]}
            }
            lappend stack $r
        } else {
            error "bad token: $tok"
        }
    }
    if {[llength $stack] != 1} {error "too many values"}
    return [lindex $stack 0]
}} tests {{rpn "5 1 2 + 4 * + 3 -"} 14 {catch {rpn "1 2"} m; set m} {too many values} {catch {rpn ""} m; set m} {empty expression}} why {A valid expression leaves exactly one value.}}
  {kind predict code {set stack {1 2 3}
set b [lindex $stack end]
set a [lindex $stack end-1]
set stack [lrange $stack 0 end-2]
puts "$a $b $stack"} choices {{2 3 1} {1 2 3} {3 2 1} {2 3 {}}} ans 0 why {Pop two from the end; one item (1) remains.}}
  {kind mc q {Why validate each token before using `expr`?} choices {{Passing unchecked input to `expr` could run unintended code} {expr is slow} {Tokens must be numbers} {It is required by switch}} ans 0 why {Never evaluate input you have not checked.}}
  {kind mc q {For `10 4 -`, which value is the left operand?} choices {{10 (the second-from-top)} {4} {Either} {Neither}} ans 0 why {Operators take the older value first, so 10 - 4.}}
}
cards {
  {{How does RPN evaluation work?} {Push numbers on a stack; an operator pops two values, computes, and pushes the result.}}
  {{Why check the stack size before popping?} {To raise a clean `stack underflow` error instead of a confusing crash.}}
  {{Why never pass raw input to expr?} {It evaluates whatever it is given, so unvalidated input can run unintended code.}}
}
}

content::lesson 14.5 14 "Project 4: a config-file parser" "Parsing a real file format, with line-numbered errors." {
pages {
  {head "The brief" body {
    p {Parse an **INI-style** configuration into a nested dict:}
    code {set text {# demo config
[server]
host = example.com
port = 8080

[log]
level = debug}
foreach line [split $text "\n"] {
    puts "<$line>"
}}
    out {<# demo config>
<[server]>
<host = example.com>
<port = 8080>
<>
<[log]>
<level = debug>}
    p {Write `parseini text` returning a dict of sections, each a dict of keys, e.g. `server {host example.com port 8080} log {level debug}`. Comment lines (starting with `#`) and blank lines are ignored. Keys before any section go in a section named `global`. A bad line raises `line N: bad syntax`, where N counts from 1.}
  }}
  {head "Design" body {
    p {Walk the lines with a counter. For each line, **trim**, then decide: blank or comment (skip), `[name]` (new section), `key = value` (store), or anything else (error). Regular expressions classify lines neatly:}
    code {foreach line {{[server]} {host = a b} {# note} {oops}} {
    if {[regexp {^\[(\w+)\]$} $line -> sec]} {
        puts "section $sec"
    } elseif {[regexp {^(\w+)\s*=\s*(.*)$} $line -> k v]} {
        puts "pair $k = $v"
    } else {
        puts "other: $line"
    }
}}
    out {section server
pair host = a b
other: # note
other: oops}
    p {`->` is a conventional name for "the whole match, which I do not need".}
  }}
  {head "Tips" body {
    p {- Keep the current section in a variable; `dict set result $section $key $value` creates nested dicts automatically
- Do the comment/blank test **first**
- `string trim` the value so stray spaces vanish
- Count lines with `incr n` in the loop so errors can say which line}
    tip {A hand-written parser is often shorter and clearer than a heavy tool for small formats. For big ones, use a real parsing package - but you will understand it better having done this.}
  }}
}
ex {
  {kind code prompt {**Step 1.** Write `parseini` for sections and `key = value` lines (no comments or errors yet).} starter {proc parseini {text} {
    return {}
}} solution {proc parseini {text} {
    set result {}
    set sec global
    foreach line [split $text "\n"] {
        set line [string trim $line]
        if {$line eq ""} continue
        if {[regexp {^\[(\w+)\]$} $line -> s]} {
            set sec $s
        } elseif {[regexp {^(\w+)\s*=\s*(.*)$} $line -> k v]} {
            dict set result $sec $k $v
        }
    }
    return $result
}} tests {{parseini "\[a\]\nx = 1\ny = 2\n\[b\]\nz = 3"} {a {x 1 y 2} b {z 3}}} why {Track the current section; `dict set` builds the nested structure.}}
  {kind code prompt {**Step 2.** Ignore blank lines and `#` comments, and put keys that appear before any section into `global`.} starter {proc parseini {text} {
    return {}
}} solution {proc parseini {text} {
    set result {}
    set sec global
    foreach line [split $text "\n"] {
        set line [string trim $line]
        if {$line eq "" || [string index $line 0] eq "#"} continue
        if {[regexp {^\[(\w+)\]$} $line -> s]} {
            set sec $s
        } elseif {[regexp {^(\w+)\s*=\s*(.*)$} $line -> k v]} {
            dict set result $sec $k [string trim $v]
        }
    }
    return $result
}} tests {{parseini "# top\nname = demo\n\n\[s\]\n# note\nk = v"} {global {name demo} s {k v}}} why {Skip comments and blanks first; `global` is just the starting section name.}}
  {kind code prompt {**Step 3.** Raise `line N: bad syntax` for any line that is none of the accepted forms (N counts from 1, including blank and comment lines).} starter {proc parseini {text} {
    return {}
}} solution {proc parseini {text} {
    set result {}
    set sec global
    set n 0
    foreach line [split $text "\n"] {
        incr n
        set line [string trim $line]
        if {$line eq "" || [string index $line 0] eq "#"} continue
        if {[regexp {^\[(\w+)\]$} $line -> s]} {
            set sec $s
        } elseif {[regexp {^(\w+)\s*=\s*(.*)$} $line -> k v]} {
            dict set result $sec $k [string trim $v]
        } else {
            error "line $n: bad syntax"
        }
    }
    return $result
}} tests {{parseini "a = 1\n\[s\]\nb = 2"} {global {a 1} s {b 2}} {catch {parseini "a = 1\n\n???"} m; set m} {line 3: bad syntax}} why {Keep a line counter and fall through to an error.}}
  {kind code prompt {**Step 4.** Write `cfgget cfg section key default` returning the value, or the default when the section or key is missing.} starter {proc cfgget {cfg section key default} {
    return $default
}} solution {proc cfgget {cfg section key default} {
    if {[dict exists $cfg $section $key]} {
        return [dict get $cfg $section $key]
    }
    return $default
}} tests {{cfgget {s {k v}} s k none} v {cfgget {s {k v}} s x none} none {cfgget {} q k 7} 7} why {`dict exists` accepts a whole path of keys.}}
  {kind code prompt {**Step 5 - final.** Write `validate cfg required` where `required` is a list of `section.key` names; return the list of those that are missing (empty list if all present).} starter {proc validate {cfg required} {
    return {}
}} solution {proc validate {cfg required} {
    set missing {}
    foreach item $required {
        lassign [split $item .] sec key
        if {![dict exists $cfg $sec $key]} {lappend missing $item}
    }
    return $missing
}} tests {{validate {server {host a port 1} log {level x}} {server.host log.level log.file db.url}} {log.file db.url} {validate {a {b 1}} {a.b}} {}} why {Split each name into section and key, and test with `dict exists`.}}
  {kind predict code {regexp {^(\w+)\s*=\s*(.*)$} "port  =  8080 " -> k v
puts "<$k> <[string trim $v]>"} choices {{<port> <8080>} {<port > <8080>} {<port> <8080 >} {<> <>}} ans 0 why {`\s*` absorbs the spaces; the value is trimmed.}}
  {kind mc q {Why report the line number in the error message?} choices {{The user can find and fix the exact problem} {Line numbers are required by `error`} {It makes parsing faster} {It hides the cause}} ans 0 why {Good errors say where, not just what.}}
}
cards {
  {{How do you classify lines in a simple parser?} {Skip blanks/comments, then try regular expressions for each accepted form, and raise an error for anything else.}}
  {{How does `dict set d a b c` behave?} {It creates the nested dicts as needed: d becomes `a {b c}`.}}
  {{Why give a parse error a line number?} {So the user can locate the problem immediately.}}
}
}

content::lesson 14.6 14 "Project 5: a bank with TclOO" "Classes, inheritance, error handling and consistency." {
pages {
  {head "The brief" body {
    p {Model a tiny **bank** with TclOO:}
    p {- `Account`: constructor takes an opening balance; `deposit n`, `withdraw n` (raises `insufficient funds`), `balance`
- `Savings` inherits from `Account` and adds `addinterest rate`, which deposits balance times rate
- `Bank` holds accounts by name: `open name balance`, `get name`, and `transfer from to amount`}
    p {The important rule: a **transfer must be all-or-nothing**. If the withdrawal fails, nothing must change.}
  }}
  {head "Design" body {
    p {Each class owns its data with `variable`. `Savings` uses `superclass Account` and calls inherited methods through `my`. The bank stores objects in a dict by name:}
    code {oo::class create Account {
    variable bal
    constructor {start} {set bal $start}
    method deposit {n} {incr bal $n}
    method balance {} {return $bal}
}
oo::class create Savings {
    superclass Account
    method addinterest {rate} {
        my deposit [expr {int([my balance] * $rate)}]
    }
}
set s [Savings new 1000]
$s addinterest 0.05
puts [$s balance]}
    out {1050}
    p {`Savings` got `deposit` and `balance` for free and added only what is new.}
  }}
  {head "Tips" body {
    p {- Check funds **before** changing anything; an error raised first leaves the object untouched
- In `transfer`, withdraw first (it may fail), then deposit
- A missing account should raise `no such account`
- Test the failure paths: they are where money bugs hide}
    tip {All-or-nothing operations are called **atomic**. Ordering your steps so the risky one comes first, as here, is the simplest way to get atomicity without any special machinery.}
  }}
}
ex {
  {kind code prompt {**Step 1.** Write the `Account` class.} starter {oo::class create Account {
}} solution {oo::class create Account {
    variable bal
    constructor {start} {set bal $start}
    method deposit {n} {incr bal $n}
    method withdraw {n} {
        if {$n > $bal} {error "insufficient funds"}
        incr bal -$n
    }
    method balance {} {return $bal}
}} tests {{set a [Account new 100]; $a deposit 20; $a withdraw 50; $a balance} 70 {set a [Account new 10]; catch {$a withdraw 11} m; list $m [$a balance]} {{insufficient funds} 10}} why {Validate before changing the balance.}}
  {kind code prompt {**Step 2.** Add `Savings`, inheriting from `Account` (the class is included below), with `addinterest rate`.} starter {oo::class create Account {
    variable bal
    constructor {start} {set bal $start}
    method deposit {n} {incr bal $n}
    method withdraw {n} {
        if {$n > $bal} {error "insufficient funds"}
        incr bal -$n
    }
    method balance {} {return $bal}
}} solution {oo::class create Account {
    variable bal
    constructor {start} {set bal $start}
    method deposit {n} {incr bal $n}
    method withdraw {n} {
        if {$n > $bal} {error "insufficient funds"}
        incr bal -$n
    }
    method balance {} {return $bal}
}
oo::class create Savings {
    superclass Account
    method addinterest {rate} {
        my deposit [expr {int([my balance] * $rate)}]
    }
}} tests {{set s [Savings new 1000]; $s addinterest 0.05; $s balance} 1050 {set s [Savings new 100]; $s withdraw 30; $s balance} 70} why {Inherited methods are available through `my`.}}
  {kind code prompt {**Step 3.** Write `Bank` with `open name balance` (creates an Account), `get name` (raises `no such account` if missing) and `total` (the sum of all balances). The Account class is included.} starter {oo::class create Account {
    variable bal
    constructor {start} {set bal $start}
    method deposit {n} {incr bal $n}
    method withdraw {n} {
        if {$n > $bal} {error "insufficient funds"}
        incr bal -$n
    }
    method balance {} {return $bal}
}} solution {oo::class create Account {
    variable bal
    constructor {start} {set bal $start}
    method deposit {n} {incr bal $n}
    method withdraw {n} {
        if {$n > $bal} {error "insufficient funds"}
        incr bal -$n
    }
    method balance {} {return $bal}
}
oo::class create Bank {
    variable accts
    constructor {} {set accts {}}
    method open {name bal} {dict set accts $name [Account new $bal]}
    method get {name} {
        if {![dict exists $accts $name]} {error "no such account"}
        return [dict get $accts $name]
    }
    method total {} {
        set t 0
        dict for {n a} $accts {incr t [$a balance]}
        return $t
    }
}} tests {{set b [Bank new]; $b open ann 100; $b open bob 50; $b total} 150 {set b [Bank new]; catch {$b get zed} m; set m} {no such account}} why {A dict of name to object; `total` asks each object for its balance.}}
  {kind code prompt {**Step 4 - final.** Add `transfer from to amount` to `Bank`. It must be all-or-nothing: if the withdrawal fails (or an account is missing), nothing changes anywhere. (Account and the rest of Bank are included.)} starter {oo::class create Account {
    variable bal
    constructor {start} {set bal $start}
    method deposit {n} {incr bal $n}
    method withdraw {n} {
        if {$n > $bal} {error "insufficient funds"}
        incr bal -$n
    }
    method balance {} {return $bal}
}
oo::class create Bank {
    variable accts
    constructor {} {set accts {}}
    method open {name bal} {dict set accts $name [Account new $bal]}
    method get {name} {
        if {![dict exists $accts $name]} {error "no such account"}
        return [dict get $accts $name]
    }
}} solution {oo::class create Account {
    variable bal
    constructor {start} {set bal $start}
    method deposit {n} {incr bal $n}
    method withdraw {n} {
        if {$n > $bal} {error "insufficient funds"}
        incr bal -$n
    }
    method balance {} {return $bal}
}
oo::class create Bank {
    variable accts
    constructor {} {set accts {}}
    method open {name bal} {dict set accts $name [Account new $bal]}
    method get {name} {
        if {![dict exists $accts $name]} {error "no such account"}
        return [dict get $accts $name]
    }
    method transfer {from to amount} {
        set a [my get $from]
        set b [my get $to]
        $a withdraw $amount
        $b deposit $amount
    }
}} tests {{set b [Bank new]; $b open a 100; $b open c 5; $b transfer a c 40; list [[$b get a] balance] [[$b get c] balance]} {60 45} {set b [Bank new]; $b open a 10; $b open c 5; catch {$b transfer a c 99}; list [[$b get a] balance] [[$b get c] balance]} {10 5} {set b [Bank new]; $b open a 10; catch {$b transfer a nobody 1} m; list $m [[$b get a] balance]} {{no such account} 10}} why {Look up both accounts and withdraw first - the step that can fail - before depositing.}}
  {kind predict code {oo::class create A {
    variable n
    constructor {} {set n 0}
    method up {} {incr n}
}
oo::class create B {superclass A}
set b [B new]
$b up
puts [$b up]} choices {2 1 0 {}} ans 0 why {B inherits the constructor and `up`; two calls give 2.}}
  {kind mc q {Why should `transfer` withdraw before it deposits?} choices {{The withdrawal can fail; failing first leaves everything unchanged} {Deposits are slower} {Withdrawals are logged} {Order never matters}} ans 0 why {Put the step that can fail first, so there is nothing to undo.}}
  {kind mc q {What does `superclass Account` give the `Savings` class?} choices {{All of Account's methods, plus its constructor} {Only the variables} {A copy of one object} {Nothing until instantiated}} ans 0 why {Inheritance reuses behaviour.}}
}
cards {
  {{How do you make a multi-step operation all-or-nothing?} {Do the step that can fail first; check preconditions before changing state.}}
  {{How does a TclOO subclass reuse behaviour?} {`superclass Parent`; call inherited methods with `my method` (or `next`).}}
  {{Why test failure paths in particular?} {That is where state-corruption bugs hide: money moved without the other half.}}
}
}

content::lesson 14.7 14 "Project 6: a cooperative scheduler" "Coroutines as lightweight tasks, scheduled round-robin." {
pages {
  {head "The brief" body {
    p {Write a tiny **cooperative multitasking** scheduler. Each **task** is a coroutine that does a little work, then `yield`s to let others run. The scheduler runs the tasks in turn, round-robin, until all have finished, and returns a **log** of what each did.}
    p {- `spawn name body` registers a task. Inside the body, `log text` records a line and `yield` hands control back
- `runall` runs the tasks round-robin and returns the combined log, in the order things happened}
  }}
  {head "Design" body {
    p {A coroutine is a proc that can pause. Run in a loop, three such tasks interleave perfectly with no threads and no locks:}
    code {proc worker {name n} {
    yield
    for {set i 1} {$i <= $n} {incr i} {
        yield "$name$i"
    }
    return done
}
coroutine A worker A 2
coroutine B worker B 3
set out {}
foreach c {A B A B A B B} {
    lappend out [$c]
}
puts $out}
    out {A1 B1 A2 B2 done B3 done}
    p {Each call resumes the task until its next `yield`; when the body ends the final value is returned and the coroutine disappears.}
  }}
  {head "Tips" body {
    p {- Keep a list of live task names; each pass, resume each one and remove those that finished
- Detect a finished coroutine with `info commands $name`: it is empty once the coroutine ends
- Append what a task yields to the log, but ignore the final `done`
- Deterministic order makes cooperative code easy to test - there is no timing involved}
    tip {This model - many logical tasks, one thread, explicit switch points - is the idea behind async/await in other languages, and behind most Tcl network servers.}
  }}
}
ex {
  {kind code prompt {**Step 1.** Write `ticker name n` as a coroutine body: it yields once to start, then yields `name1 name2 ... namen`, then returns `done`.} starter {proc ticker {name n} {
    return done
}} solution {proc ticker {name n} {
    yield
    for {set i 1} {$i <= $n} {incr i} {
        yield "$name$i"
    }
    return done
}} tests {{coroutine T1 ticker X 2; list [T1] [T1] [T1]} {X1 X2 done}} why {The first `yield` is the starting gate; the rest hand back values.}}
  {kind code prompt {**Step 2.** Write `runtask name` that resumes the coroutine `name` once and returns its value, or the empty string if it has already finished.} starter {proc runtask {name} {
    return {}
}} solution {proc runtask {name} {
    if {[info commands $name] eq ""} {return ""}
    return [$name]
}} tests {{proc t {} {yield; yield a; return z}; coroutine Q t; list [runtask Q] [runtask Q] [runtask Q]} {a z {}}} why {A finished coroutine no longer exists as a command.}}
  {kind code prompt {**Step 3.** Write `roundrobin names` that resumes each named coroutine in turn, again and again, collecting every yielded value (not the final return) until all tasks are finished. Return the list of collected values.} starter {proc roundrobin {names} {
    return {}
}} solution {proc roundrobin {names} {
    set log {}
    set live $names
    while {[llength $live]} {
        set next {}
        foreach n $live {
            set v [$n]
            if {[info commands $n] ne ""} {
                lappend log $v
                lappend next $n
            }
        }
        set live $next
    }
    return $log
}} tests {{proc w {name n} {yield; for {set i 1} {$i <= $n} {incr i} {yield $name$i}; return done}; coroutine A w A 2; coroutine B w B 3; roundrobin {A B}} {A1 B1 A2 B2 B3}} why {After each resume, a coroutine that still exists yielded a value; one that has gone had just returned.}}
  {kind code prompt {**Step 4 - final.** Write `schedule tasks` where `tasks` is a dict of task name to a list of items. Each task, when run, produces its items one per turn. Use coroutines and round-robin scheduling, and return the combined log as `name:item` entries.} starter {proc schedule {tasks} {
    return {}
}} solution {proc schedule {tasks} {
    set names {}
    dict for {name items} $tasks {
        proc ::body_$name {name items} {
            yield
            foreach i $items {yield "$name:$i"}
            return done
        }
        coroutine ::co_$name ::body_$name $name $items
        lappend names ::co_$name
    }
    set log {}
    set live $names
    while {[llength $live]} {
        set next {}
        foreach n $live {
            set v [$n]
            if {[info commands $n] ne ""} {
                lappend log $v
                lappend next $n
            }
        }
        set live $next
    }
    return $log
}} tests {{schedule {a {1 2} b {x y z}}} {a:1 b:x a:2 b:y b:z} {schedule {}} {}} why {Create one coroutine per task, then drive them all round-robin.}}
  {kind predict code {proc g {} {yield; yield 1; yield 2; return 3}
coroutine c g
puts "[c] [c] [c]"} choices {{1 2 3} {2 3 {}} {1 2 {}} {3}} ans 0 why {The first call returns the first yielded value 1, then 2, then the final return 3.}}
  {kind predict code {proc g {} {yield; return x}
coroutine c g
c
puts [llength [info commands c]]} choices {0 1 2 c} ans 0 why {After the body returns, the coroutine command is deleted.}}
  {kind mc q {What does "cooperative" multitasking mean?} choices {{Tasks switch only where they choose to yield} {The system interrupts tasks at random} {Tasks run on separate CPUs} {Tasks cannot share data}} ans 0 why {Switch points are explicit, which makes behaviour deterministic.}}
}
cards {
  {{How does a coroutine-based scheduler work?} {Keep a list of live tasks; resume each in turn; drop those that have finished.}}
  {{How do you know a coroutine has finished?} {Its command disappears: `info commands $name` is empty.}}
  {{Why is cooperative scheduling easy to test?} {The switch points are explicit, so the order of events is deterministic.}}
}
}

content::lesson 14.8 14 "Project 7: a state machine" "Model behaviour as states and transitions - and make illegal moves impossible." {
pages {
  {head "The brief" body {
    p {Many programs are really **state machines**: a door is open, closed or locked; an order is placed, paid, shipped. The rules are a table: *in this state, this event moves to that state.* Write a generic machine plus a vending-machine example.}
    p {- `machine::new transitions initial` returns a machine (a dict)
- `machine::fire m event` returns the machine moved to its new state, or raises `illegal: EVENT in STATE`
- `machine::state m` returns the current state}
  }}
  {head "Design" body {
    p {The whole behaviour is **data**: a dict mapping state to a dict of event to next state. The code is just a lookup.}
    code {set door {
    closed {open opened lock locked}
    opened {close closed}
    locked {unlock closed}
}
set s closed
foreach ev {open close lock unlock} {
    set s [dict get $door $s $ev]
    puts "$ev -> $s"
}}
    out {open -> opened
close -> closed
lock -> locked
unlock -> closed}
    p {Adding a state or rule means editing the table, not the code. And impossible moves, like unlocking an open door, simply are not in the table.}
  }}
  {head "Tips" body {
    p {- `dict exists $table $state $event` tells you whether a move is legal
- Represent the machine as a dict with `table` and `state` so it can be passed around as a plain value
- Return a **new** dict from `fire` (functional style) so earlier states are never lost
- List all legal events for a state with `dict keys [dict get $table $state]`}
    tip {Drawing the states and arrows on paper first is the best design step. The code is then almost a transcription of the picture.}
  }}
}
ex {
  {kind code prompt {**Step 1.** Create the namespace `machine` with `new transitions initial` returning a dict with keys `table` and `state`, and `state m` returning the current state.} starter {namespace eval machine {
}} solution {namespace eval machine {
    proc new {table initial} {
        return [dict create table $table state $initial]
    }
    proc state {m} {
        return [dict get $m state]
    }
}} tests {{machine::state [machine::new {a {go b}} a]} a} why {A machine is just a dict holding its rules and its state.}}
  {kind code prompt {**Step 2.** Add `fire m event`, returning the machine in its new state, or raising `illegal: EVENT in STATE`.} starter {namespace eval machine {
    proc new {table initial} {return [dict create table $table state $initial]}
    proc state {m} {return [dict get $m state]}
}} solution {namespace eval machine {
    proc new {table initial} {return [dict create table $table state $initial]}
    proc state {m} {return [dict get $m state]}
    proc fire {m event} {
        set s [dict get $m state]
        if {![dict exists $m table $s $event]} {
            error "illegal: $event in $s"
        }
        dict set m state [dict get $m table $s $event]
        return $m
    }
}} tests {{set m [machine::new {a {go b} b {back a}} a]; machine::state [machine::fire $m go]} b {set m [machine::new {a {go b}} a]; catch {machine::fire $m nope} e; set e} {illegal: nope in a}} why {A legal move exists in the table; anything else is an error.}}
  {kind code prompt {**Step 3.** Add `events m`, returning the sorted list of legal events in the current state, and `run m eventlist` which fires each event in turn and returns the final state.} starter {namespace eval machine {
    proc new {table initial} {return [dict create table $table state $initial]}
    proc state {m} {return [dict get $m state]}
    proc fire {m event} {
        set s [dict get $m state]
        if {![dict exists $m table $s $event]} {error "illegal: $event in $s"}
        dict set m state [dict get $m table $s $event]
        return $m
    }
}} solution {namespace eval machine {
    proc new {table initial} {return [dict create table $table state $initial]}
    proc state {m} {return [dict get $m state]}
    proc fire {m event} {
        set s [dict get $m state]
        if {![dict exists $m table $s $event]} {error "illegal: $event in $s"}
        dict set m state [dict get $m table $s $event]
        return $m
    }
    proc events {m} {
        return [lsort [dict keys [dict get $m table [dict get $m state]]]]
    }
    proc run {m evs} {
        foreach e $evs {set m [fire $m $e]}
        return [state $m]
    }
}} tests {{set d {closed {open opened lock locked} opened {close closed} locked {unlock closed}}; machine::events [machine::new $d closed]} {lock open} {set d {closed {open opened lock locked} opened {close closed} locked {unlock closed}}; machine::run [machine::new $d closed] {open close lock unlock}} closed} why {`dict keys` of the current state's row lists the legal events.}}
  {kind code prompt {**Step 4 - final.** Use your machine to model a vending machine with states `idle`, `paid`, `dispensing` and events `coin` (idle to paid), `select` (paid to dispensing), `done` (dispensing to idle), `refund` (paid to idle). Write `vend events` that runs the given events from `idle` and returns the final state, raising the machine's error for an illegal move. (A complete `machine` namespace is included.)} starter {namespace eval machine {
    proc new {table initial} {return [dict create table $table state $initial]}
    proc state {m} {return [dict get $m state]}
    proc fire {m event} {
        set s [dict get $m state]
        if {![dict exists $m table $s $event]} {error "illegal: $event in $s"}
        dict set m state [dict get $m table $s $event]
        return $m
    }
}
proc vend {events} {
    return idle
}} solution {namespace eval machine {
    proc new {table initial} {return [dict create table $table state $initial]}
    proc state {m} {return [dict get $m state]}
    proc fire {m event} {
        set s [dict get $m state]
        if {![dict exists $m table $s $event]} {error "illegal: $event in $s"}
        dict set m state [dict get $m table $s $event]
        return $m
    }
}
proc vend {events} {
    set table {
        idle {coin paid}
        paid {select dispensing refund idle}
        dispensing {done idle}
    }
    set m [machine::new $table idle]
    foreach e $events {set m [machine::fire $m $e]}
    return [machine::state $m]
}} tests {{vend {coin select done}} idle {vend {coin refund}} idle {vend {coin}} paid {catch {vend {select}} e; set e} {illegal: select in idle}} why {The vending rules are just a table handed to the generic machine.}}
  {kind predict code {set t {a {x b} b {y a}}
set s a
foreach e {x y x} {set s [dict get $t $s $e]}
puts $s} choices {b a {} x} ans 0 why {a -x-> b -y-> a -x-> b.}}
  {kind mc q {Why store the transition rules as data rather than as `if` statements?} choices {{Changing behaviour means editing a table, and illegal moves are simply absent} {Tables run faster} {if statements are not allowed} {Dicts cannot be empty}} ans 0 why {Data-driven design is easier to read, test and extend.}}
  {kind mc q {Why does `fire` return a new machine instead of changing one in place?} choices {{Earlier states are never lost, so it is easy to test and undo} {It uses less memory} {Tcl forbids in-place changes} {It is required by dict}} ans 0 why {Values that are not modified cannot surprise you.}}
}
cards {
  {{What is a state machine?} {A set of states with rules: in this state, this event moves to that state.}}
  {{How do you represent transitions in Tcl?} {A dict of state to a dict of event to next state; lookup with `dict get $table $state $event`.}}
  {{How do you detect an illegal event?} {`dict exists $table $state $event` is false.}}
}
}

content::lesson 14.9 14 "Capstone: your own tested library" "Write a utility library with a test suite - the way professionals ship code." {
pages {
  {head "The brief" body {
    p {For your capstone, write a small **string utility library** as a namespace `strutil`, together with a **test runner** that proves it works. This is the professional pattern: a library plus tests that run in one command and report pass or fail.}
    p {Functions to write:}
    p {- `pad text width ?char?` pad on the right to the given width
- `center text width` centre text in a field (extra space goes to the right)
- `truncate text max` shorten with `...` when longer than max (result never longer than max)
- `wrap text width` break text into lines of at most `width` characters at spaces
- `title text` capitalise each word}
  }}
  {head "Design" body {
    p {Write each function as a **pure** proc (text in, text out). Then a `selftest` proc runs a table of cases and returns the number of failures. The runner is the same idea as in the testing lesson:}
    code {namespace eval strutil {
    proc pad {text width {char " "}} {
        set n [expr {$width - [string length $text]}]
        if {$n <= 0} {return $text}
        return $text[string repeat $char $n]
    }
}
puts "<[strutil::pad ab 5]>"
puts "<[strutil::pad ab 5 .]>"}
    out {<ab   >
<ab...>}
    p {Edge cases deserve their own tests: width smaller than the text, empty strings, and exact fits.}
  }}
  {head "Tips" body {
    p {- Write the tests **first** for each function, watch them fail, then write the code
- `string repeat`, `string range`, `string totitle` and `split`/`join` do most of the work
- For `wrap`, add words to the current line while it fits, else start a new line
- A test table is data: `{name script expected}` triples are easy to extend}
    tip {When all your tests pass, change one function and run them again. That feeling of safety is why professionals write tests.}
  }}
}
ex {
  {kind code prompt {**Step 1.** Write `strutil::pad text width ?char?`.} starter {namespace eval strutil {
}} solution {namespace eval strutil {
    proc pad {text width {char " "}} {
        set n [expr {$width - [string length $text]}]
        if {$n <= 0} {return $text}
        return $text[string repeat $char $n]
    }
}} tests {{strutil::pad ab 5} {ab   } {strutil::pad ab 5 .} ab... {strutil::pad abcdef 3} abcdef {strutil::pad "" 2 -} --} why {Compute the shortfall; add that many characters if positive.}}
  {kind code prompt {**Step 2.** Add `strutil::center text width` (extra space goes to the right) and `strutil::truncate text max` (results longer than max are cut to `max` characters ending in `...`).} starter {namespace eval strutil {
    proc pad {text width {char " "}} {
        set n [expr {$width - [string length $text]}]
        if {$n <= 0} {return $text}
        return $text[string repeat $char $n]
    }
}} solution {namespace eval strutil {
    proc pad {text width {char " "}} {
        set n [expr {$width - [string length $text]}]
        if {$n <= 0} {return $text}
        return $text[string repeat $char $n]
    }
    proc center {text width} {
        set n [expr {$width - [string length $text]}]
        if {$n <= 0} {return $text}
        set left [expr {$n / 2}]
        return [string repeat " " $left]$text[string repeat " " [expr {$n - $left}]]
    }
    proc truncate {text max} {
        if {[string length $text] <= $max} {return $text}
        return [string range $text 0 [expr {$max - 4}]]...
    }
}} tests {{strutil::center ab 6} {  ab  } {strutil::center abc 6} { abc  } {strutil::truncate hello 10} hello {strutil::truncate "hello world" 8} {hello...}} why {Half the padding goes left, the rest right. Truncation reserves 3 characters for the dots.}}
  {kind code prompt {**Step 3.** Add `strutil::title text` (capitalise each space-separated word, lower-casing the rest) and `strutil::wrap text width` returning a list of lines, each at most `width` characters, breaking at spaces (a word longer than the width gets its own line).} starter {namespace eval strutil {
}} solution {namespace eval strutil {
    proc title {text} {
        set out {}
        foreach w [split $text " "] {lappend out [string totitle $w]}
        return [join $out " "]
    }
    proc wrap {text width} {
        set lines {}
        set cur ""
        foreach w [split $text " "] {
            if {$w eq ""} continue
            if {$cur eq ""} {
                set cur $w
            } elseif {[string length $cur] + 1 + [string length $w] <= $width} {
                append cur " " $w
            } else {
                lappend lines $cur
                set cur $w
            }
        }
        if {$cur ne ""} {lappend lines $cur}
        return $lines
    }
}} tests {{strutil::title "hELLO wORLD"} {Hello World} {strutil::wrap "the quick brown fox jumps" 10} {{the quick} {brown fox} jumps} {strutil::wrap "supercalifragilistic is long" 8} {supercalifragilistic {is long}}} why {Greedy line filling: add the word if it fits, otherwise start a new line.}}
  {kind code prompt {**Step 4 - final.** Write the test runner `strutil::selftest`: it runs at least these cases against your functions and returns the number of **failures** (0 when everything passes): `pad ab 4` gives `ab  `; `truncate "hello world" 8` gives `hello...`; `title "a b"` gives `A B`. (Include working implementations of those three functions.)} starter {namespace eval strutil {
    proc selftest {} {
        return 99
    }
}} solution {namespace eval strutil {
    proc pad {text width {char " "}} {
        set n [expr {$width - [string length $text]}]
        if {$n <= 0} {return $text}
        return $text[string repeat $char $n]
    }
    proc truncate {text max} {
        if {[string length $text] <= $max} {return $text}
        return [string range $text 0 [expr {$max - 4}]]...
    }
    proc title {text} {
        set out {}
        foreach w [split $text " "] {lappend out [string totitle $w]}
        return [join $out " "]
    }
    proc selftest {} {
        set cases {
            {{pad ab 4} {ab  }}
            {{truncate "hello world" 8} {hello...}}
            {{title "a b"} {A B}}
        }
        set failed 0
        foreach c $cases {
            lassign $c script want
            if {[catch {namespace eval ::strutil $script} got] || $got ne $want} {incr failed}
        }
        return $failed
    }
}} tests {{strutil::selftest} 0 {strutil::pad ab 4} {ab  } {strutil::title "x y"} {X Y}} why {The runner is a table of cases evaluated inside the namespace, counting mismatches.}}
  {kind predict code {namespace eval s {proc pad {t w} {return $t[string repeat . [expr {$w - [string length $t]}]]}}
puts [s::pad ab 4]} choices {ab.. ab.... ..ab ab} ans 0 why {Two characters short, so two dots are appended.}}
  {kind mc q {Why write the test for a function before the function itself?} choices {{It defines exactly what "correct" means, and proves the test can fail} {It is required by namespaces} {Tests run faster first} {It is shorter}} ans 0 why {A test that has never failed has not been shown to detect anything.}}
  {kind mc q {What should a good test suite include for `pad`?} choices {{Normal use, width smaller than the text, exact fit and the empty string} {Only one normal example} {Only error cases} {Only long strings}} ans 0 why {Edges are where bugs live.}}
}
cards {
  {{What is the professional pattern for a library?} {A namespace of pure functions plus a test suite that runs in one command and reports pass/fail.}}
  {{Which edge cases should you always test?} {Empty input, exact fit, too short or too long, and invalid input.}}
  {{Why write tests first?} {It defines "correct" up front and shows the test can detect failure.}}
}
}
