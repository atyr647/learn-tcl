content::unit 4 "Loops" "Make the computer repeat work - the heart of programming." "#4ADE80"

content::lesson 4.1 4 "while loops" "Repeat code for as long as a condition holds." {
pages {
  {head "Repeating things" body {
    p {A **loop** runs the same code again and again. `while` keeps going as long as its condition is true.}
    code {set i 1
while {$i <= 3} {
    puts "Round $i"
    incr i
}}
    out {Round 1
Round 2
Round 3}
    p {Tcl checks the condition. If it is true, it runs the body, then checks again. When it is false, the loop ends and the program carries on after it.}
  }}
  {head "Do not loop forever" body {
    p {Something inside the loop must eventually make the condition false. Here `incr` pulls the number down to zero. (`incr n -1` subtracts 1.)}
    code {set n 3
while {$n > 0} {
    puts $n
    incr n -1
}
puts "Liftoff!"}
    out {3
2
1
Liftoff!}
    warn {If nothing changes the variable in the condition, the loop never ends. In this app the Playground stops runaway code after a few seconds.}
  }}
  {head "Adding things up" body {
    p {A common pattern: keep a running **total** in a variable.}
    code {set total 0
set i 1
while {$i <= 5} {
    incr total $i
    incr i
}
puts $total}
    out {15}
    p {The total grows 0, 1, 3, 6, 10, 15 - the sum of the numbers 1 to 5.}
  }}
}
ex {
  {kind predict code {set i 1
while {$i <= 3} {
    puts $i
    incr i
}} choices {"1\n2\n3" "1\n2" "0\n1\n2" "3"} ans 0 why {The loop runs while `i` is 1, 2 and 3. When `i` becomes 4 the condition is false.}}
  {kind predict code {set n 10
while {$n > 4} {
    puts $n
    incr n -3
}} choices {"10\n7" "10\n7\n4" "10\n7\n4\n1" "7\n4"} ans 0 why {n goes 10, 7, 4. When n is 4 the test `4 > 4` is false, so 4 is never printed.}}
  {kind predict code {set t 0
set i 1
while {$i <= 4} {
    incr t $i
    incr i
}
puts $t} choices {10 4 24 6} ans 0 why {1 + 2 + 3 + 4 = 10.}}
  {kind mc q {Why does this loop never stop?} code {set i 1
while {$i < 5} {
    puts $i
}} choices {{Nothing changes i, so the condition stays true} {puts is not allowed in loops} {while needs a semicolon} {The number 5 is too small}} ans 0 why {`i` is always 1. Add `incr i` inside the body.}}
  {kind blank q {Make the loop print 0, 1, 2.} code {set i 0
while {$i < 3} {
    puts $i
    ___ i
}} answers {incr} extra {set expr puts} out {0
1
2} why {`incr i` adds 1 each time round.}}
  {kind order q {Print 0, 1, 2 with a loop.} lines {{set i 0} {while {$i < 3} {puts $i; incr i}}} out {0
1
2} why {Initialise the counter first, then loop.}}
  {kind type q {Which command adds 1 to a variable?} accept {incr} why {`incr name` - and `incr name 5` adds 5.}}
  {kind mc q {The condition is `$i < 5` and i starts at 0, increasing by 1. How many times does the body run?} choices {5 4 6 1} ans 0 why {i takes the values 0, 1, 2, 3 and 4 - five times.}}
}
cards {
  {{What does `while` do?} {It repeats its body for as long as the condition is true, checking before every round.}}
  {{How do you count down by 1?} {`incr n -1`}}
  {{What must happen inside a while loop?} {Something must change so the condition eventually becomes false - otherwise it loops forever.}}
  {{How do you keep a running total?} {Start with `set total 0` and then `incr total $value` inside the loop.}}
}
}

content::lesson 4.2 4 "for loops" "The tidy way to count." {
pages {
  {head "Count with for" body {
    p {A counting loop has three parts: where to start, when to stop, and how to step. `for` writes them all on one line.}
    code {for {set i 1} {$i <= 3} {incr i} {
    puts "Round $i"
}}
    out {Round 1
Round 2
Round 3}
    p {The four parts in braces are: **start**, **test**, **next**, **body**. The start runs once; then test, body, next repeat.}
  }}
  {head "Counting patterns" body {
    p {Change the start, test and step to count in other ways.}
    code {for {set i 10} {$i > 0} {incr i -3} {
    puts $i
}}
    out {10
7
4
1}
    code {for {set i 0} {$i <= 10} {incr i 5} {
    puts $i
}}
    out {0
5
10}
    tip {Use `for` when you know how many rounds you want, and `while` when you wait for something to happen.}
  }}
  {head "Loops inside loops" body {
    p {A loop can sit inside another loop. The inner loop runs completely for each round of the outer one.}
    code {for {set r 1} {$r <= 2} {incr r} {
    for {set c 1} {$c <= 3} {incr c} {
        puts "$r x $c = [expr {$r * $c}]"
    }
}}
    out {1 x 1 = 1
1 x 2 = 2
1 x 3 = 3
2 x 1 = 2
2 x 2 = 4
2 x 3 = 6}
  }}
}
ex {
  {kind predict code {for {set i 1} {$i <= 4} {incr i} {
    puts $i
}} choices {"1\n2\n3\n4" "1\n2\n3" "0\n1\n2\n3" "4"} ans 0 why {i starts at 1 and the loop runs while i is at most 4.}}
  {kind predict code {for {set i 0} {$i < 10} {incr i 4} {
    puts $i
}} choices {"0\n4\n8" "0\n4\n8\n12" "4\n8" "0\n10"} ans 0 why {0, 4, 8 - then 12 is not less than 10.}}
  {kind predict code {set s 0
for {set i 1} {$i <= 3} {incr i} {
    incr s [expr {$i * $i}]
}
puts $s} choices {14 6 9 3} ans 0 why {1 + 4 + 9 = 14, the sum of the squares of 1, 2 and 3.}}
  {kind predict code {for {set i 3} {$i > 0} {incr i -1} {
    puts -nonewline $i
}} choices {321 123 210 3} ans 0 why {Counting down 3, 2, 1, printed without line breaks.}}
  {kind mc q {In `for {set i 0} {$i < 5} {incr i} {...}`, which part runs only once?} choices {{set i 0} {$i < 5} {incr i} {The body}} ans 0 why {The start part runs once at the beginning. The test runs before each round, and the "next" part after each round.}}
  {kind blank q {Count from 1 to 3.} code {for {set i 1} {$i ___ 3} {incr i} {
    puts $i
}} answers {<=} extra {< > ==} out {1
2
3} why {`<=` includes 3 in the loop.}}
  {kind order q {Add up 1, 2 and 3 with a loop and print the total.} lines {{set sum 0} {for {set i 1} {$i <= 3} {incr i} {incr sum $i}} {puts $sum}} out {6} why {Start the total at 0, add inside the loop, and print only after the loop is finished.}}
  {kind type q {Which loop command is best for counting from a start to an end?} accept {for} why {`for` puts start, test and step on one line.}}
}
cards {
  {{What are the four parts of `for`?} {`for {start} {test} {next} {body}` - start runs once, then test, body, next repeat.}}
  {{How do you count from 10 down to 1?} {`for {set i 10} {$i >= 1} {incr i -1} {...}`}}
  {{When should you use `while` instead of `for`?} {When you do not know in advance how many rounds are needed - you wait for a condition.}}
  {{What happens with a loop inside a loop?} {The inner loop runs completely for every round of the outer loop.}}
}
}

content::lesson 4.3 4 "foreach, break and continue" "Do something for every item, and control the loop from inside." {
pages {
  {head "foreach" body {
    p {`foreach` runs its body once for **each item of a list**. A list is simply words separated by spaces.}
    code {foreach fruit {apple banana cherry} {
    puts "I like $fruit"
}}
    out {I like apple
I like banana
I like cherry}
    p {No counting needed. This is the loop you will use most often.}
  }}
  {head "Totals and pairs" body {
    p {Add up the items of a list:}
    code {set total 0
foreach n {4 8 15} {
    incr total $n
}
puts $total}
    out {27}
    p {Give `foreach` two variable names and it takes the items two at a time:}
    code {foreach {key val} {a 1 b 2} {
    puts "$key is $val"
}}
    out {a is 1
b is 2}
  }}
  {head "break and continue" body {
    p {Two commands steer a loop from the inside:}
    p {- `break` leaves the loop immediately
- `continue` skips the rest of this round and starts the next one}
    code {foreach n {3 8 5 12 7} {
    if {$n > 10} {break}
    puts $n
}}
    out {3
8
5}
    code {foreach n {1 2 3 4} {
    if {$n == 3} {continue}
    puts $n
}}
    out {1
2
4}
  }}
}
ex {
  {kind predict code {foreach c {x y z} {
    puts $c
}} choices {"x\ny\nz" "z\ny\nx" "xyz" "x y z"} ans 0 why {The body runs once per item, in order.}}
  {kind predict code {set t 0
foreach n {5 10 20} {incr t $n}
puts $t} choices {35 30 15 20} ans 0 why {5 + 10 + 20 = 35.}}
  {kind predict code {foreach {a b} {1 2 3 4} {
    puts [expr {$a + $b}]
}} choices {"3\n7" "10" "1\n2\n3\n4" "3\n4"} ans 0 why {Two items per round: (1, 2) then (3, 4). The sums are 3 and 7.}}
  {kind predict code {foreach n {3 8 5 12 7} {
    if {$n > 10} {break}
    puts $n
}} choices {"3\n8\n5" "3\n8\n5\n7" "12" "3\n8\n5\n12"} ans 0 why {`break` ends the loop when it reaches 12, so 7 is never visited.}}
  {kind predict code {foreach n {1 2 3 4} {
    if {$n == 3} {continue}
    puts $n
}} choices {"1\n2\n4" "1\n2" "3" "1\n2\n3\n4"} ans 0 why {`continue` skips printing when n is 3 but the loop carries on with 4.}}
  {kind mc q {What does `break` do?} choices {{Leaves the loop right away} {Skips to the next round} {Stops the whole program} {Pauses for a moment}} ans 0 why {`break` exits the innermost loop. `continue` skips to the next round.}}
  {kind blank q {Skip the number 2.} code {foreach n {1 2 3} {
    if {$n == 2} {___}
    puts $n
}} answers {continue} extra {break stop skip} out {1
3} why {`continue` jumps straight to the next item.}}
  {kind type q {Which command goes through every item of a list?} accept {foreach} why {`foreach`.}}
}
cards {
  {{What does `foreach` do?} {Runs the body once for each item of a list: `foreach item $list {...}`.}}
  {{What do `break` and `continue` do?} {`break` leaves the loop; `continue` skips to the next round.}}
  {{How can foreach take two items per round?} {Give it two variable names: `foreach {k v} $list {...}`.}}
  {{Which loop would you choose to process every item in a list?} {`foreach`.}}
}
}
