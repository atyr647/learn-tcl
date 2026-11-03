content::unit 3 "Numbers and decisions" "Do maths, compare things, and make your program choose." "#2DD4BF"

content::lesson 3.1 3 "Maths with expr" "Teach Tcl to calculate." {
pages {
  {head "expr does the maths" body {
    p {Tcl does not calculate unless you ask. The `expr` command evaluates a mathematical expression and returns the answer.}
    code {puts [expr {2 + 3}]}
    out {5}
    code {set price 4
set qty 3
puts [expr {$price * $qty}]}
    out {12}
    tip {Always put the expression in **curly braces**: `expr {2 + 3}`. It is safer and faster, and you will see why in the expert unit.}
  }}
  {head "The operators" body {
    p {- `+` `-` `*` add, subtract, multiply
- `/` divide
- `%` the remainder after dividing
- `**` to the power of
- `( )` to control the order}
    code {puts [expr {7 / 2}]
puts [expr {7 / 2.0}]
puts [expr {7 % 2}]
puts [expr {2 ** 10}]}
    out {3
3.5
1
1024}
    warn {When both numbers are whole, `/` throws the remainder away: `7 / 2` is `3`. Make one of them a decimal (`2.0`) to get `3.5`.}
  }}
  {head "Functions and incr" body {
    p {Inside `expr` you can call maths functions: `sqrt()`, `abs()`, `round()`, `max()`, `min()` and more.}
    code {puts [expr {sqrt(16)}]
puts [expr {round(3.6)}]
puts [expr {max(3, 9, 5)}]}
    out {4.0
4
9}
    p {Adding one to a variable is so common that it has its own command: `incr`.}
    code {set n 5
incr n
incr n 10
puts $n}
    out {16}
    p {`incr n` adds 1; `incr n 10` adds 10. Like `append`, it takes the variable's name without a dollar sign.}
  }}
}
ex {
  {kind predict code {puts [expr {10 % 3}]} choices {1 3 3.33 0} ans 0 why {10 divided by 3 is 3 remainder 1; `%` gives the remainder.}}
  {kind predict code {puts [expr {2 + 3 * 4}]} choices {14 20 24 9} ans 0 why {Multiplication comes before addition, like in school maths: 3 * 4 = 12, plus 2.}}
  {kind predict code {puts [expr {(2 + 3) * 4}]} choices {20 14 24 9} ans 0 why {Brackets are evaluated first.}}
  {kind predict code {puts [expr {9 / 2}]} choices {4 4.5 5 2} ans 0 why {Both numbers are whole, so the division is a whole-number division.}}
  {kind predict code {puts [expr {9 / 2.0}]} choices {4.5 4 5 9} ans 0 why {One decimal number is enough to get a decimal answer.}}
  {kind predict code {set n 7
incr n 3
puts $n} choices {10 8 73 n} ans 0 why {`incr n 3` adds 3 to n.}}
  {kind blank q {Multiply 4 by 5.} code {puts [___ {4 * 5}]} answers {expr} extra {calc math eval} out {20} why {`expr` evaluates the expression.}}
  {kind order q {Print the area of a 3 by 4 rectangle (12).} lines {{set w 3} {set h 4} {puts [expr {$w * $h}]}} out {12} why {Set both variables first, then calculate.}}
  {kind type q {What does `expr {17 % 5}` return?} accept {2} calc {expr {17 % 5}} res 1 why {17 = 3 * 5 + 2, so the remainder is 2.}}
}
cards {
  {{Which command does maths in Tcl?} {`expr`, as in `expr {2 + 3}`. Put the expression in braces.}}
  {{What does `expr {7 / 2}` return, and why?} {3. Both numbers are whole, so the remainder is dropped. Use 2.0 to get 3.5.}}
  {{What does `%` do?} {It gives the remainder of a division: `expr {10 % 3}` is 1.}}
  {{How do you add 1 to the variable n?} {`incr n` (and `incr n 5` adds 5).}}
}
}

content::lesson 3.2 3 "Making decisions: if" "Run code only when something is true." {
pages {
  {head "if" body {
    p {`if` runs some code **only when** a condition is true. The condition goes in curly braces, then the code to run goes in curly braces.}
    code {set age 20
if {$age >= 18} {
    puts "adult"
}}
    out {adult}
    p {Comparison operators: `==` equal, `!=` not equal, `<` less than, `>` greater than, `<=` and `>=`.}
    tip {Indent the code inside braces by four spaces. It does not matter to Tcl, but it makes your program readable.}
  }}
  {head "else and elseif" body {
    p {Add `else` for "otherwise", and `elseif` for further questions. Tcl checks from the top and stops at the first true one.}
    code {set temp 15
if {$temp > 25} {
    puts "hot"
} elseif {$temp > 10} {
    puts "mild"
} else {
    puts "cold"
}}
    out {mild}
    warn {`else` and `elseif` must start on the **same line** as the closing brace of the block before them. A new line would end the `if` command early.}
  }}
  {head "Combining conditions" body {
    p {- `&&` means **and**: both sides must be true
- `||` means **or**: at least one must be true
- `!` means **not**}
    code {set n 7
if {$n > 0 && $n < 10} {
    puts "single digit"
}}
    out {single digit}
    p {To compare **text**, use `eq` (equal) and `ne` (not equal). They always compare character by character.}
    code {set color "red"
if {$color eq "red" || $color eq "green"} {
    puts "warm or green"
}}
    out {warm or green}
  }}
}
ex {
  {kind predict code {set n 5
if {$n > 3} {
    puts "big"
} else {
    puts "small"
}} choices {big small {big
small} nothing} ans 0 why {5 is greater than 3, so the first block runs and the `else` is skipped.}}
  {kind predict code {set n 2
if {$n > 3} {
    puts "big"
} elseif {$n > 1} {
    puts "medium"
} else {
    puts "small"
}} choices {medium big small nothing} ans 0 why {2 is not greater than 3, but it is greater than 1, so `medium` is printed.}}
  {kind predict code {set a 4
if {$a > 0 && $a < 3} {
    puts "yes"
} else {
    puts "no"
}} choices {no yes {yes
no} nothing} ans 0 why {`&&` needs both sides true. 4 is greater than 0 but not less than 3.}}
  {kind predict code {set s "hi"
if {$s eq "hi"} {puts match}} choices {match hi nothing eq} ans 0 why {`eq` compares text. The two texts are identical.}}
  {kind mc q {What does `||` mean in a condition?} choices {{or - at least one side is true} {and - both sides are true} {not} {divide}} ans 0 why {`||` is "or"; `&&` is "and".}}
  {kind mc q {Why does this code fail?} code {set x 1
if {$x > 5} {
    puts "big"
}
else {
    puts "small"
}} choices {{`else` must be on the same line as the closing brace} {`>` is not allowed in an if} {`puts` needs two arguments} {Nothing - it works fine}} ans 0 why {The first line break ends the `if` command, so Tcl then tries to run `else` as a separate command. Keep `else` on the same line as the closing brace.}}
  {kind blank q {Complete the condition: print adult when age is at least 18.} code {set age 30
if {$age ___ 18} {
    puts "adult"
}} answers {>=} extra {<= == !=} out {adult} why {`>=` means greater than or equal to.}}
  {kind order q {Print big if the number is over 10.} lines {{set n 12} {if {$n > 10} {puts "big"}}} out {big} why {Set the variable first, then test it in the `if`.}}
  {kind type q {Which word do you use for "otherwise" in an if command?} accept {else} why {`else`.}}
}
cards {
  {{How does `if` look?} {`if {condition} { code }` - optionally with `elseif {condition} { code }` and `else { code }`.}}
  {{What do `&&`, `||` and `!` mean?} {And, or, not.}}
  {{How do you compare two pieces of text?} {Use `eq` (equal) and `ne` (not equal).}}
  {{Where must `else` be written?} {On the same line as the closing brace of the previous block.}}
}
}

content::lesson 3.3 3 "switch and truth values" "Choose between many options, and what Tcl counts as true." {
pages {
  {head "switch" body {
    p {When you compare one value against many possibilities, `switch` is tidier than a long chain of `elseif`.}
    code {set day "Sat"
switch $day {
    Sat - Sun { puts "weekend" }
    Fri       { puts "almost!" }
    default   { puts "weekday" }
}}
    out {weekend}
    p {Each pattern is followed by the code to run. A `-` instead of code means "use the same code as the next pattern". `default` matches anything not matched earlier.}
  }}
  {head "True and false" body {
    p {A condition can be anything that Tcl understands as a yes/no value. Comparisons return `1` (true) or `0` (false), and these words also work: `true` `false` `yes` `no` `on` `off`.}
    code {puts [expr {3 > 2}]
puts [expr {3 < 2}]
set done yes
if {$done} { puts "finished" }}
    out {1
0
finished}
    p {`!` flips a truth value.}
    code {set found 0
if {!$found} { puts "not found yet" }}
    out {not found yet}
  }}
  {head "Handy expression tricks" body {
    p {`expr` has a one-line choice, `condition ? a : b`:}
    code {set n -4
puts [expr {$n >= 0 ? "positive" : "negative"}]}
    out {negative}
    p {And `in` tests whether a value is in a list of choices:}
    code {set c "b"
puts [expr {$c in {a b c}}]}
    out {1}
    tip {`ni` is the opposite of `in` ("not in").}
  }}
}
ex {
  {kind predict code {set x "b"
switch $x {
    a { puts "first" }
    b { puts "second" }
    default { puts "other" }
}} choices {second first other {first
second}} ans 0 why {`b` matches the second pattern, so only that code runs.}}
  {kind predict code {set x "z"
switch $x {
    a { puts "first" }
    default { puts "other" }
}} choices {other first nothing z} ans 0 why {Nothing matches `z`, so the `default` branch runs.}}
  {kind predict code {puts [expr {5 == 5}]} choices {1 0 true 5} ans 0 why {A true comparison gives 1.}}
  {kind predict code {set ok no
if {$ok} {puts yes} else {puts no}} choices {no yes nothing ok} ans 0 why {Tcl treats `no` as false.}}
  {kind predict code {set n 8
puts [expr {$n % 2 == 0 ? "even" : "odd"}]} choices {even odd 0 8} ans 0 why {8 divided by 2 leaves remainder 0, so the condition is true and the first choice is used.}}
  {kind predict code {puts [expr {"x" in {a b c}}]} choices {0 1 x false} ans 0 why {`x` is not in the list, so the result is 0.}}
  {kind blank q {Fill in the keyword for "everything else".} code {set k "q"
switch $k {
    a { puts "A" }
    ___ { puts "something else" }
}} answers {default} extra {else other otherwise} out {something else} why {`default` is the catch-all branch of a switch.}}
  {kind mc q {Which of these is NOT understood as false by Tcl?} choices {yes 0 false off} ans 0 why {`yes` means true. `0`, `false` and `off` all mean false.}}
  {kind type q {What does `expr {4 > 9}` return?} accept {0} calc {expr {4 > 9}} res 1 why {Comparisons return 1 for true and 0 for false.}}
}
cards {
  {{What is `switch` for?} {Comparing one value against many patterns, with `default` as the catch-all.}}
  {{Which words does Tcl treat as true and false?} {true/yes/on/1 and false/no/off/0.}}
  {{How do you write a one-line choice inside expr?} {`condition ? valueIfTrue : valueIfFalse`}}
  {{What does `$x in {a b c}` test?} {Whether x is one of the listed items (1 if so, else 0). `ni` means not in.}}
}
}
