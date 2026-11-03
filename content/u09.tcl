content::unit 9 "Errors and files" "Handle problems gracefully and work with data on disk." "#22D3EE"

content::lesson 9.1 9 "When things go wrong" "Catch errors, raise your own, and clean up afterwards." {
pages {
  {head "Errors stop programs" body {
    p {When a command cannot do its job it raises an **error**. Unless something handles it, the program stops.}
    code {puts [expr {10 / 0}]}
    out {divide by zero}
    p {You can raise your own errors with `error`. This is how a proc says "I was given something I cannot work with".}
    code {proc setAge {n} {
    if {$n < 0} {error "age cannot be negative"}
    return $n
}
setAge -5}
    out {age cannot be negative}
  }}
  {head "catch" body {
    p {`catch {script} ?resultVar?` runs the script and **never** stops the program. It returns `0` when the script worked and `1` when it raised an error. The variable receives the result or the error message.}
    code {if {[catch {expr {10 / 0}} msg]} {
    puts "Oops: $msg"
}
puts [catch {set x 5} r]
puts $r}
    out {Oops: divide by zero
0
5}
  }}
  {head "try and finally" body {
    p {`try` is the tidy modern way. `on error` handles failures, and `finally` runs no matter what - ideal for cleanup like closing files.}
    code {try {
    expr {1 / 0}
} on error {msg} {
    puts "caught: $msg"
} finally {
    puts "done"
}}
    out {caught: divide by zero
done}
    p {You can also react only to a *specific* kind of error with `trap`:}
    code {try {
    expr {1 / 0}
} trap {ARITH DIVZERO} {} {
    puts "division by zero"
}}
    out {division by zero}
    tip {Errors have a machine-readable `-errorcode` list as well as the message. `trap` matches on that, so your handler does not depend on the exact wording.}
  }}
}
ex {
  {kind predict code {puts [catch {expr {4 / 2}} r]
puts $r} choices {"0\n2" "1\n2" "0\n4/2" "2\n0"} ans 0 why {The script worked, so `catch` returns 0 and the variable holds the result, 2.}}
  {kind predict code {puts [catch {error "boom"} m]
puts $m} choices {"1\nboom" "0\nboom" "1\nerror" "boom\n1"} ans 0 why {`error` raises an error, so `catch` returns 1 and `m` holds the message.}}
  {kind predict code {catch {expr {1 / 0}} m
puts $m} choices {{divide by zero} 0 1 {}} ans 0 why {The message of the error is stored in the variable.}}
  {kind predict code {try {
    puts "working"
} finally {
    puts "cleanup"
}} choices {"working\ncleanup" "cleanup\nworking" "working" "cleanup"} ans 0 why {`finally` runs after the body, whether or not an error happened.}}
  {kind predict code {try {
    error "bad"
} on error {m} {
    puts "handled $m"
}
puts "after"} choices {"handled bad\nafter" "after" "handled bad" "bad\nafter"} ans 0 why {The error is handled, so the program carries on.}}
  {kind mc q {What does `catch` return when the script succeeds?} choices {0 1 The result Nothing} ans 0 why {0 means success; 1 means an error was caught.}}
  {kind blank q {Raise an error with a message.} code {catch {___ "oops"} m
puts $m} answers {error} extra {throw fail raise} out {oops} why {`error message` raises an error.}}
  {kind type q {Which block of `try` always runs, whatever happens?} accept {finally} why {`finally`.}}
  {kind code prompt {Write a proc **safediv** that returns `a / b`, or the text `n/a` when the division fails (for example when b is 0).} starter {proc safediv {a b} {
    return [expr {$a / $b}]
}} solution {proc safediv {a b} {
    if {[catch {expr {$a / $b}} r]} {return n/a}
    return $r
}} tests {{safediv 10 2} 5 {safediv 1 0} n/a} why {Wrap the risky `expr` in `catch` and return `n/a` if it reports an error.}}
}
cards {
  {{How do you run code that might fail without stopping the program?} {`if {[catch {script} msg]} {...}` - catch returns 1 on error, and msg holds the message.}}
  {{How do you raise your own error?} {`error "message"`}}
  {{What does `finally` do in try?} {It always runs, error or not - used for cleanup.}}
  {{How do you handle one specific kind of error?} {`try {...} trap {ARITH DIVZERO} {} {...}` matches on the error code.}}
}
}

content::lesson 9.2 9 "Reading and writing files" "Make programs that remember things." {
pages {
  {head "Writing" body {
    p {To use a file you **open** it, get a **channel** (a handle), use it, then **close** it. The second argument says what you want to do: `r` read, `w` write (erases the file), `a` append.}
    code {set f [open "notes.txt" w]
puts $f "line one"
puts $f "line two"
close $f
puts [file exists "notes.txt"]}
    out {1}
    p {`puts` takes an optional channel before the text - the very first thing you learned about it! Without one it uses `stdout`, the screen.}
    tip {In this app, files created in lessons live in a private scratch folder that is wiped between runs, so you can experiment freely.}
  }}
  {head "Reading" body {
    p {`gets $f var` reads one line into a variable and returns its length (or -1 at the end of the file). `read $f` returns the whole file.}
    code {set f [open "notes.txt" w]
puts $f "alpha"
puts $f "beta"
close $f
set f [open "notes.txt" r]
while {[gets $f line] >= 0} {
    puts "got: $line"
}
close $f}
    out {got: alpha
got: beta}
    code {set f [open "notes.txt" r]
set text [read $f]
close $f
puts [llength [split [string trim $text] "\n"]]}
    out {2}
    warn {Always `close` what you `open`, even when something fails. Use `try ... finally { close $f }` to be certain.}
  }}
  {head "Names and paths" body {
    p {The `file` command works with names and the file system, without opening anything. `file join` builds a path correctly for any operating system.}
    code {puts [file join a b "c.txt"]
puts [file extension "report.pdf"]
puts [file tail /usr/lib/libx.so]
puts [file rootname "report.pdf"]
puts [file dirname /usr/lib/libx.so]}
    out {a/b/c.txt
.pdf
libx.so
report
/usr/lib}
    p {Also useful: `file exists`, `file size`, `file delete` and `glob *.txt` (list the files matching a pattern).}
  }}
}
ex {
  {kind predict code {puts [file extension "photo.jpg"]} choices {.jpg jpg photo {photo.}} ans 0 why {`file extension` includes the dot.}}
  {kind predict code {puts [file tail "/home/ann/notes.txt"]} choices {notes.txt /home/ann ann notes} ans 0 why {`file tail` is the last part of the path.}}
  {kind predict code {puts [file join usr local bin]} choices {usr/local/bin {usr local bin} /usr/local/bin usr:local:bin} ans 0 why {`file join` inserts the right separator.}}
  {kind predict code {set f [open "t.txt" w]
puts $f "hello"
close $f
set f [open "t.txt" r]
gets $f line
close $f
puts [string toupper $line]} choices {HELLO hello {} t.txt} ans 0 why {The line written to the file was read back and converted to capitals.}}
  {kind predict code {set f [open "c.txt" w]
puts $f a
puts $f b
puts $f c
close $f
set f [open "c.txt"]
set n 0
while {[gets $f line] >= 0} {incr n}
close $f
puts $n} choices {3 1 0 2} ans 0 why {Three lines were written, so the loop reads three.}}
  {kind mc q {What does opening a file with mode `w` do to an existing file?} choices {{Erases its contents first} {Adds to the end} {Only reads it} {Deletes the file}} ans 0 why {`w` truncates (empties) the file. Use `a` to append.}}
  {kind mc q {Which mode adds new lines to the end of an existing file?} choices {a w r x} ans 0 why {`a` is for append.}}
  {kind blank q {Close the file when done.} code {set f [open "x.txt" w]
puts $f hi
___ $f
puts [file size "x.txt"]} answers {close} extra {end stop done} out {3} why {`close` flushes the data to disk and releases the file. The file holds `hi` plus a newline: 3 bytes.}}
  {kind type q {Which command reads one line from a channel into a variable?} accept {gets} why {`gets $channel varName`.}}
  {kind code prompt {Write a proc **writelines** that takes a filename and a list, and writes each item on its own line to the file.} starter {proc writelines {name items} {
    # open, write each item, close
}} solution {proc writelines {name items} {
    set f [open $name w]
    foreach i $items {puts $f $i}
    close $f
}} tests {{writelines out.txt {a b c}; set f [open out.txt]; set t [read $f]; close $f; string length $t} 6} why {Open with `w`, `puts $f` for every item, then close.}}
}
cards {
  {{How do you write to a file?} {`set f [open name w]`, then `puts $f text`, then `close $f`.}}
  {{How do you read a file line by line?} {`while {[gets $f line] >= 0} {...}` - gets returns -1 at the end.}}
  {{What are the open modes r, w and a?} {Read, write (erases first), and append.}}
  {{What does `file join a b c.txt` give?} {`a/b/c.txt` - it builds a path with the correct separator.}}
}
}

content::lesson 9.3 9 "A small data pipeline" "Text in, tidy report out - and working with dates." {
pages {
  {head "From text to records" body {
    p {Real programs turn raw text into data. A typical recipe: **split** into lines, **split** each line into fields, **process**, then **format**.}
    code {set data "ann,31,paris
bob,25,rome
cy,40,oslo"
foreach line [split $data "\n"] {
    lassign [split $line ,] name age city
    puts "$name is $age and lives in $city"
}}
    out {ann is 31 and lives in paris
bob is 25 and lives in rome
cy is 40 and lives in oslo}
  }}
  {head "Summaries and reports" body {
    p {Collect the rows into a list, then sort, total and format them.}
    code {set rows {}
foreach line [split "ann,31
bob,25
cy,40" "\n"] {
    lappend rows [split $line ,]
}
set total 0
foreach r [lsort -integer -index 1 $rows] {
    lassign $r name age
    puts [format "%-5s %3d" $name $age]
    incr total $age
}
set avg [expr {double($total) / [llength $rows]}]
puts [format "average: %.1f" $avg]}
    out {bob    25
ann    31
cy     40
average: 32.0}
    tip {`double($total)` makes the division produce a decimal. Without it, 96 / 3 would be a whole-number division.}
  }}
  {head "Dates and times" body {
    p {`clock` handles time. `clock seconds` is the current moment as a count of seconds; `clock format` turns it into readable text; `clock scan` reads text into seconds; `clock add` does calendar arithmetic.}
    code {proc fmt {t} {
    clock format $t -format %Y-%m-%d -timezone :UTC
}
proc parse {s} {
    clock scan $s -format %Y-%m-%d -timezone :UTC
}
puts [fmt 86400]
set t [parse 2024-03-15]
puts [fmt [clock add $t 30 days]]
puts [expr {([parse 2024-03-20] - $t) / 86400}]}
    out {1970-01-02
2024-04-14
5}
    p {Format letters: `%Y` year, `%m` month, `%d` day, `%H:%M:%S` time, `%A` weekday name. Always think about time zones - `:UTC` keeps results the same everywhere.}
  }}
}
ex {
  {kind predict code {lassign [split "x,y,z" ,] a b c
puts $b} choices {y x z {x,y,z}} ans 0 why {`split` makes the list {x y z}; `lassign` puts the second item in `b`.}}
  {kind predict code {puts [llength [split "a b  c" " "]]} choices {4 3 2 5} ans 0 why {`split` keeps the empty item between the two spaces, giving a, b, an empty item, c.}}
  {kind predict code {set total 0
foreach line [split "3\n4\n5" "\n"] {incr total $line}
puts $total} choices {12 345 3 0} ans 0 why {Each line is a number; they sum to 12.}}
  {kind predict code {puts [format "%-4s|%3d" ab 7]} choices {{ab  |  7} {  ab|7  } {ab|7} {ab  |7  }} ans 0 why {Left-aligned text in 4 spaces, then a right-aligned number in 3.}}
  {kind predict code {puts [clock format 0 -format %Y -timezone :UTC]} choices {1970 1900 2000 0} ans 0 why {Second 0 of the clock is the start of 1970 (the "epoch").}}
  {kind predict code {set f %Y-%m-%d
set t [clock scan 2024-01-31 -format $f -timezone :UTC]
set n [clock add $t 1 day]
puts [clock format $n -format $f -timezone :UTC]} choices {2024-02-01 2024-01-32 2024-02-31 2024-01-30} ans 0 why {`clock add` understands calendars: the day after 31 January is 1 February.}}
  {kind mc q {Why write `double($total) / $n` for an average?} choices {{Whole-number division would drop the decimals} {double makes it faster} {It is required syntax} {It rounds the result}} ans 0 why {Making one number a decimal forces a decimal answer.}}
  {kind blank q {Cut the line into fields at the commas.} code {lassign [___ "ann,31" ,] name age
puts "$name/$age"} answers {split} extra {join lindex string} out {ann/31} why {`split text separator`.}}
  {kind code prompt {Write a proc **average** that takes a list of numbers and returns their average as a decimal, e.g. `average {2 4 9}` gives `5.0`.} starter {proc average {nums} {
    return 0
}} solution {proc average {nums} {
    set total 0
    foreach n $nums {incr total $n}
    return [expr {double($total) / [llength $nums]}]
}} tests {{average {2 4 9}} 5.0 {average {10}} 10.0} why {Sum the list, then divide using a decimal so the answer is not truncated.}}
}
cards {
  {{What is the usual text-processing recipe?} {Split into lines, split lines into fields, process, format the output.}}
  {{How do you split text into lines?} {`split $text "\n"`}}
  {{What do `clock format`, `clock scan` and `clock add` do?} {Format seconds as text, read text into seconds, and add calendar units like days.}}
  {{Why use `double($x)` in a division?} {To force a decimal result instead of a whole-number division.}}
}
}
