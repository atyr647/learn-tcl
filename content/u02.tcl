content::unit 2 "Values and variables" "Give names to things, reuse results, and learn how Tcl reads text." "#4C9AFF"

content::lesson 2.1 2 "Variables: naming things" "Store a value once, use it as often as you like." {
pages {
  {head "Boxes with names" body {
    p {A **variable** is a named box that holds a value. The command `set` puts a value into the box.}
    code {set name "Ada"
puts $name}
    out {Ada}
    p {`set name "Ada"` means: make a variable called `name` and put `Ada` in it. To **use** the contents, write a dollar sign before the name: `$name`.}
    tip {Read `$name` out loud as "the value of name".}
  }}
  {head "Changing and combining" body {
    p {A variable can change. Setting it again replaces the old value.}
    code {set score 10
puts $score
set score 15
puts $score}
    out {10
15}
    p {Inside double quotes Tcl swaps each `$name` for its value. This is called **variable substitution**.}
    code {set first "Grace"
set last "Hopper"
puts "$first $last"}
    out {Grace Hopper}
  }}
  {head "Naming rules" body {
    p {Names are **case sensitive**: `Name` and `name` are two different variables. Use letters, digits and underscores, and choose names that explain themselves - `total_price` beats `x`.}
    p {Using a variable that was never set is an error:}
    code {puts $missing}
    out {can't read "missing": no such variable}
    warn {If you see "no such variable", check the spelling and the capital letters.}
  }}
}
ex {
  {kind predict code {set a 3
puts $a} choices {3 a {$a} {set a 3}} ans 0 why {`$a` is replaced by the value stored in `a`, which is 3.}}
  {kind predict code {set x hello
set x world
puts $x} choices {world hello {hello world} x} ans 0 why {The second `set` replaces the first value, so the variable now holds `world`.}}
  {kind mc q {What does the `$` mean in front of a variable name?} choices {{"the value of" the variable} {"start a comment"} {"divide"} {"print this"}} ans 0 why {`$name` means "use the value stored in name".}}
  {kind predict code {set lang "Tcl"
puts "I love $lang"} choices {{I love Tcl} {I love $lang} {Tcl} {I love lang}} ans 0 why {Inside double quotes `$lang` is replaced by its value.}}
  {kind blank q {Print the contents of the variable city.} code {set city "Paris"
puts ___city} answers {$} extra {# & %} out {Paris} why {A dollar sign in front of the name fetches the value.}}
  {kind order q {Print hello world using a variable.} lines {{set who "world"} {puts "hello $who"}} out {hello world} why {A variable must be set before it is used, so `set` comes first.}}
  {kind type q {Which command gives a variable a value?} accept {set} why {`set name value` creates or changes a variable.}}
  {kind mc q {Are `Score` and `score` the same variable?} choices {{No - names are case sensitive} {Yes - capitals are ignored} {Only inside quotes} {Only on Android}} ans 0 why {Tcl is case sensitive everywhere, including variable names.}}
}
cards {
  {{How do you create a variable called age with the value 30?} {`set age 30`}}
  {{How do you read the value of a variable called age?} {Put a dollar sign in front: `$age`.}}
  {{Are Tcl variable names case sensitive?} {Yes. `Age` and `age` are different variables.}}
  {{What error do you get for a variable that was never set?} {`can't read "name": no such variable`}}
}
}

content::lesson 2.2 2 "Using a command's result" "Square brackets run a command and use what it returns." {
pages {
  {head "Square brackets" body {
    p {Many commands produce a **result**. Square brackets run a command and put its result into the line.}
    code {puts [string length "hello"]}
    out {5}
    p {Tcl runs the command in the brackets **first**. `[string length "hello"]` becomes `5`, and then the line is simply `puts 5`.}
    p {`string length` is one of many `string` commands. You will meet more soon.}
  }}
  {head "Keeping results" body {
    p {Combine brackets with `set` to keep a result in a variable.}
    code {set n [string length "Tcl rocks"]
puts "Length: $n"}
    out {Length: 9}
    code {set shout [string toupper "hey"]
puts $shout}
    out {HEY}
    p {Brackets can be nested. The innermost one runs first.}
    code {puts [string toupper [string range "hello" 0 1]]}
    out {HE}
    tip {Read nested brackets from the inside out. `string range "hello" 0 1` gives `he`, then `string toupper` turns it into `HE`.}
  }}
  {head "Brackets inside quotes" body {
    p {Square brackets also work inside double quotes, which is handy for building messages.}
    code {puts "Tcl has [string length Tcl] letters"}
    out {Tcl has 3 letters}
    p {Inside curly braces nothing is substituted, so `puts {[string length Tcl]}` would print the brackets as plain text.}
  }}
}
ex {
  {kind mc q {What do square brackets do in Tcl?} choices {{Run a command and use its result} {Make a list} {Start a comment} {Group words into one}} ans 0 why {`[command ...]` is replaced by the result of running the command.}}
  {kind predict code {puts [string length "banana"]} choices {6 banana 5 {string length banana}} ans 0 why {"banana" has 6 letters.}}
  {kind predict code {set w "tcl"
puts [string toupper $w]} choices {TCL tcl Tcl w} ans 0 why {`string toupper` returns the text in capitals.}}
  {kind predict code {puts "Ada has [string length Ada] letters"} choices {{Ada has 3 letters} {Ada has [string length Ada] letters} {Ada has Ada letters} {3 letters}} ans 0 why {Brackets are substituted inside double quotes too.}}
  {kind predict code {puts [string toupper [string index "hello" 0]]} choices {H h HELLO he} ans 0 why {`string index "hello" 0` is `h` (counting starts at 0), and `string toupper` makes it `H`.}}
  {kind blank q {Store the length of "Tcl" in n.} code {set n [___ length "Tcl"]
puts $n} answers {string} extra {str len count} out {3} why {`string length` returns how many characters a text has.}}
  {kind order q {Print: banana has 6 letters} lines {{set word "banana"} {set n [string length $word]} {puts "$word has $n letters"}} out {banana has 6 letters} why {Set the word, measure it, then print - each line uses what the previous one made.}}
  {kind mc q {In `puts [string length "hi"]`, which part runs first?} choices {{string length "hi"} {puts} {Both at once} {Neither}} ans 0 why {The bracketed command runs first; its result (2) becomes the argument for `puts`.}}
}
cards {
  {{What do [square brackets] do?} {They run the command inside and replace themselves with its result.}}
  {{What does `string length hello` return?} {5 - the number of characters.}}
  {{How do you keep a command's result in a variable?} {`set n [command ...]`}}
  {{In nested brackets, which command runs first?} {The innermost one.}}
}
}

content::lesson 2.3 2 "Quotes, braces and joining" "Everything is text - and the two ways to group it." {
pages {
  {head "Everything is a string" body {
    p {In Tcl every value is text. The number 5 is just the character `5` until you do arithmetic with it (next unit). There are no types to declare, and variables can hold anything.}
    code {set a 5
set b 7
puts "$a$b"}
    out {57}
    p {Writing two values side by side simply joins the text.}
  }}
  {head "Quotes versus braces" body {
    p {There are two ways to group words into one:}
    p {- `"..."` double quotes: `$variables` and `[commands]` are **replaced**
- `{...}` curly braces: everything is taken **literally**}
    code {set name "Ada"
puts "Hi $name"
puts {Hi $name}}
    out {Hi Ada
Hi $name}
    tip {Braces mean "leave this exactly as it is". You will see them everywhere - around the body of `if`, `proc` and loops - because those pieces of code should not run yet.}
  }}
  {head "Building text with append" body {
    p {`append` adds text to the end of a variable.}
    code {set s "Hello"
append s ", " "world"
puts $s}
    out {Hello, world}
    p {You do not write a `$` before the variable name in `append`: the command wants the *name*, not the value.}
  }}
}
ex {
  {kind predict code {set name "Ada"
puts "Hi $name"
puts {Hi $name}} choices {"Hi Ada\nHi $name" "Hi Ada\nHi Ada" "Hi $name\nHi $name" "Hi $name\nHi Ada"} ans 0 why {Double quotes substitute the variable; braces do not.}}
  {kind mc q {Which line prints the text $x exactly as written?} choices {{puts {$x}} {puts "$x"} {puts $x} {puts [$x]}} ans 0 why {Only braces stop substitution, so `{$x}` stays as the characters $x.}}
  {kind predict code {set a 5
set b 7
puts "$a$b"} choices {57 12 {5 7} {$a$b}} ans 0 why {Text is joined side by side - no arithmetic happens in quotes.}}
  {kind predict code {set s "Hello"
append s ", " "world"
puts $s} choices {{Hello, world} {Hello} {, world} {s}} ans 0 why {`append` adds each piece to the end of `s`.}}
  {kind blank q {Make the message use the value of x.} code {set x 42
puts ___Value: $x___} answers {{"} {"}} extra {{'} {(}} out {Value: 42} why {Double quotes allow `$x` to be replaced by 42.}}
  {kind order q {Build and print: Learning Tcl} lines {{set msg "Learning"} {append msg " Tcl"} {puts $msg}} out {Learning Tcl} why {Create the variable, extend it, then print it.}}
  {kind type q {Which command adds text to the end of a variable?} accept {append} why {`append name text`.}}
  {kind predict code {puts {2 + 3}} choices {{2 + 3} 5 {{2 + 3}} 23} ans 0 why {Braces keep the text exactly as written. Tcl does not do maths unless you ask with `expr`.}}
}
cards {
  {{What is the difference between "..." and {...}?} {Double quotes allow $variable and [command] substitution. Braces take everything literally.}}
  {{What type are values in Tcl?} {Everything is a string. Tcl reads a value as a number only when you do maths with it.}}
  {{How do you add text to the end of the variable s?} {`append s " more text"` (no dollar sign before s).}}
  {{What does `puts {Hi $name}` print?} {`Hi $name` - braces prevent substitution.}}
}
}
