content::unit 12 "Data, channels and testing" "Bytes and encodings, pipes and sockets, and how to prove your code works." "#34D399"

content::lesson 12.1 12 "Bytes, encodings and binary data" "What is really inside a string or a file - and how to read and build binary formats." {
pages {
  {head "Characters are not bytes" body {
    p {A Tcl string is a sequence of **characters**. A file, a socket or a network packet is a sequence of **bytes**. An **encoding** is the rule that turns one into the other. The most common is **UTF-8**, where an ordinary letter is one byte but an accented letter takes two.}
    code {set s "caf[format %c 233]"
puts [string length $s]
puts [string bytelength $s]
puts [binary encode hex [encoding convertto utf-8 $s]]}
    out {4
5
636166c3a9}
    p {Four characters, five bytes: the accented e (character 233) became the two bytes `c3 a9`. `encoding convertto` turns text into bytes; `encoding convertfrom` turns bytes back into text.}
    code {set s "caf[format %c 233]"
set bytes [encoding convertto utf-8 $s]
puts [string length [encoding convertfrom utf-8 $bytes]]}
    out {4}
    tip {When reading or writing files and sockets, set the encoding explicitly with `chan configure $ch -encoding utf-8` (or `-translation binary` for raw bytes) rather than trusting the default.}
  }}
  {head "Building and reading binary data" body {
    p {`binary format` packs values into bytes and `binary scan` unpacks them. Each letter says what kind of value: `c` one byte, `s` and `S` 16-bit (little/big endian), `i` and `I` 32-bit, `w` and `W` 64-bit, `a` and `A` text, `H` hex.}
    code {puts [binary encode hex [binary format I 258]]
puts [binary encode hex [binary format s 258]]
binary scan "\x01\x02" cc a b
puts "$a $b"}
    out {00000102
0201
1 2}
    p {258 is `0x0102`. As big-endian 32-bit (`I`) the bytes read `00 00 01 02`; as little-endian 16-bit (`s`) they are `02 01`. Endianness is simply which byte comes first.}
    code {binary scan [binary format c -1] cu u
puts $u}
    out {255}
    p {Values are signed by default. Add a `u` after the letter (`cu`, `Iu`) to read them as unsigned.}
  }}
  {head "Hex, base64, checksums and bits" body {
    p {`binary encode` and `binary decode` convert between bytes and text forms such as hex and base64. `zlib crc32` computes a checksum. And Tcl's expression operators work on individual bits.}
    code {puts [binary encode base64 "Hello, Tcl!"]
puts [binary decode base64 SGVsbG8sIFRjbCE=]
puts [zlib crc32 "Hello, Tcl!"]
puts [format %08b 37]
puts [expr {12 & 10}]
puts [expr {12 | 3}]
puts [expr {5 << 2}]}
    out {SGVsbG8sIFRjbCE=
Hello, Tcl!
1247759882
00100101
8
15
20}
    p {- `&` AND, `|` OR, `^` XOR, `~` NOT
- `<<` and `>>` shift bits left and right
- `format %b`, `%o`, `%x` show a number in binary, octal or hex; `0xff`, `0b101`, `0o17` write them}
  }}
}
ex {
  {kind predict code {puts [string bytelength "abc"]} choices {3 4 6 abc} ans 0 why {Plain ASCII letters are one byte each in UTF-8.}}
  {kind predict code {puts [binary encode hex "abc"]} choices {616263 abc 636261 {61 62 63}} ans 0 why {`a`, `b`, `c` are bytes 0x61, 0x62, 0x63.}}
  {kind predict code {puts [format %x 255]} choices {ff 255 FF 0xff} ans 0 why {`%x` prints lower-case hexadecimal.}}
  {kind predict code {puts [expr {5 << 2}]} choices {20 10 7 52} ans 0 why {Shifting left by 2 multiplies by 4.}}
  {kind predict code {puts [expr {12 | 3}]} choices {15 9 36 7} ans 0 why {1100 OR 0011 = 1111 = 15.}}
  {kind predict code {puts [expr {12 & 10}]} choices {8 2 14 22} ans 0 why {1100 AND 1010 = 1000 = 8.}}
  {kind predict code {puts [format %08b 5]} choices {00000101 101 00000011 {5}} ans 0 why {`%08b` is binary, zero padded to 8 digits.}}
  {kind predict code {puts [string length [binary format I 1]]} choices {4 1 2 8} ans 0 why {`I` is a 32-bit integer: 4 bytes.}}
  {kind predict code {puts [binary encode base64 hello]} choices {aGVsbG8= hello 68656c6c6f aGVsbG8} ans 0 why {Base64 of "hello" - the `=` is padding.}}
  {kind mc q {Why is `string bytelength` larger than `string length` for "caf" plus an accented e?} choices {{UTF-8 stores the accented letter in two bytes} {Tcl adds a hidden byte at the end} {The two commands count different letters} {bytelength counts spaces}} ans 0 why {Characters and bytes are different things; UTF-8 uses 1 to 4 bytes per character.}}
  {kind blank q {Show the bytes of the text as hexadecimal.} code {puts [binary ___ hex "Hi"]} answers {encode} extra {decode format scan} out {4869} why {`binary encode hex` converts bytes to hex text.}}
  {kind type q {Which command packs numbers into binary bytes?} accept {binary format} why {`binary format`.}}
  {kind code prompt {Write a proc **tohex** that returns the hexadecimal form of a string's bytes: `tohex hi` gives `6869`.} starter {proc tohex {s} {
    return $s
}} solution {proc tohex {s} {
    return [binary encode hex $s]
}} tests {{tohex hi} 6869 {tohex A} 41} why {`binary encode hex` does it.}}
  {kind code prompt {Write a proc **bytelen** returning how many bytes a string takes in UTF-8.} starter {proc bytelen {s} {
    return [string length $s]
}} solution {proc bytelen {s} {
    return [string length [encoding convertto utf-8 $s]]
}} tests {{bytelen abc} 3 {bytelen "caf[format %c 233]"} 5} why {Convert to UTF-8 bytes first, then count them.}}
}
cards {
  {{What is the difference between a character and a byte?} {A string is characters; files and networks carry bytes. An encoding such as UTF-8 converts between them (one character may be several bytes).}}
  {{Which commands convert text to bytes and back?} {`encoding convertto utf-8 $text` and `encoding convertfrom utf-8 $bytes`.}}
  {{What do `binary format` and `binary scan` do?} {Pack values into bytes and unpack bytes into values, using type letters like c, s, I, a, H.}}
  {{Name the bit operators in expr.} {`&` and, `|` or, `^` xor, `~` not, `<<` shift left, `>>` shift right.}}
}
}

content::lesson 12.2 12 "Channels, pipes and sockets" "Configure channels, react to data with events, and talk over the network." {
pages {
  {head "Configuring a channel" body {
    p {Every open file, pipe or socket is a **channel**, and `chan configure` (also `fconfigure`) adjusts it. The important options: `-translation` (how line endings are handled), `-encoding`, `-buffering` (`full`, `line`, `none`) and `-blocking`.}
    code {set f [open "t.bin" wb]
puts -nonewline $f "a\r\nb"
close $f
set f [open "t.bin" rb]
puts [string length [read $f]]
close $f
set f [open "t.bin" r]
chan configure $f -translation auto
puts [string length [read $f]]
close $f}
    out {4
3}
    p {Opened in binary mode the file is read exactly: 4 bytes. With `-translation auto` the Windows line ending `\r\n` becomes a single newline, giving 3 characters.}
  }}
  {head "Pipes and the event loop" body {
    p {A **non-blocking** channel never makes your program wait. Instead you register a handler with `chan event ... readable` and the event loop calls it when data arrives. `chan pipe` makes a connected pair of channels, which is a handy way to practise.}
    code {lassign [chan pipe] r w
chan configure $r -blocking 0
chan event $r readable [list apply {{ch} {
    if {[gets $ch line] >= 0} {
        puts "got: $line"
    } elseif {[eof $ch]} {
        set ::done 1
    }
}} $r]
puts $w one
puts $w two
close $w
vwait ::done
close $r}
    out {got: one
got: two}
    p {This is the pattern behind every Tcl server, chat client and log watcher: **register, then let the event loop drive**. Nothing ever sits and waits.}
  }}
  {head "Sockets" body {
    p {`socket -server handler port` listens; `socket host port` connects. The handler runs for each new connection. Using port `0` lets the system choose a free port, and `chan configure $server -sockname` tells you which one. Here is a complete echo server and client talking over the loopback address inside one program:}
    code {proc accept {ch addr port} {
    chan configure $ch -buffering line
    chan event $ch readable [list echo $ch]
}
proc echo {ch} {
    if {[gets $ch line] < 0} {
        close $ch
    } else {
        puts $ch "echo: $line"
    }
}
set srv [socket -server accept -myaddr 127.0.0.1 0]
set port [lindex [chan configure $srv -sockname] 2]
set c [socket 127.0.0.1 $port]
chan configure $c -buffering line
chan event $c readable {set ::reply [gets $c]}
puts $c hello
vwait ::reply
puts $::reply
close $c
close $srv}
    out {echo: hello}
    warn {Reading from a socket with a plain blocking `gets` while your own server runs in the same program would deadlock - the server can only answer from the event loop. That is why the client uses `chan event` and `vwait`.}
    tip {On a phone, networking also needs Android's permission to use the network; this lesson only talks to the device itself (127.0.0.1).}
  }}
}
ex {
  {kind predict code {lassign [chan pipe] r w
puts $w hi
close $w
puts [read -nonewline $r]
close $r} choices {hi {hi
} {} r} ans 0 why {Whatever is written to one end of the pipe can be read from the other; `-nonewline` drops the final newline.}}
  {kind predict code {puts [lsort [chan names std*]]} choices {{stderr stdin stdout} {stdin stdout} {stdout} {stdin stdout stderr}} ans 0 why {Tcl always has the three standard channels; `lsort` puts them in order.}}
  {kind predict code {set f [open "x.txt" w]
chan configure $f -buffering none
puts [chan configure $f -buffering]
close $f} choices {none full line 0} ans 0 why {`chan configure $f -buffering` with no value reports the current setting.}}
  {kind mc q {What does `-translation binary` do?} choices {{No line-ending conversion and no encoding conversion - bytes pass through untouched} {Compresses the data} {Makes the channel read-only} {Turns on buffering}} ans 0 why {Use binary mode for images, archives and network protocols.}}
  {kind mc q {Why use `chan event ... readable` instead of a blocking `gets` in a server?} choices {{The program stays responsive and can serve many connections at once} {It is faster for single files} {Blocking reads are not allowed in Tcl} {It encrypts the connection}} ans 0 why {The event loop calls your handler only when data is ready.}}
  {kind mc q {What happens if you pass port 0 to `socket -server`?} choices {{The system picks a free port, which you can read with -sockname} {The server refuses to start} {It listens on every port} {It uses port 80}} ans 0 why {Port 0 means "any free port" - ideal for tests.}}
  {kind order q {Send a message through a pipe and read it back.} lines {{lassign [chan pipe] r w} {puts $w hello} {close $w} {puts [read -nonewline $r]}} out {hello} why {Create the pipe, write, close the writing end so the reader sees the end, then read.}}
  {kind blank q {Make the channel non-blocking.} code {lassign [chan pipe] r w
chan ___ $r -blocking 0
puts [chan configure $r -blocking]} answers {configure} extra {event pipe close} out {0} why {`chan configure channel -option value`.}}
  {kind type q {Which command lets you register a handler that runs when a channel has data?} accept {chan event fileevent} why {`chan event $ch readable script` (the older name is `fileevent`).}}
  {kind code prompt {Write a proc **readall** that returns the whole contents of a file.} starter {proc readall {name} {
    return {}
}} solution {proc readall {name} {
    set f [open $name r]
    set d [read $f]
    close $f
    return $d
}} tests {{set f [open r.txt w]; puts -nonewline $f "abc"; close $f; readall r.txt} abc} why {Open, `read`, close.}}
  {kind code prompt {Write a proc **roundtrip** that starts a loopback echo server, sends the given message through a socket and returns the reply: `roundtrip hi` gives `echo: hi`.} starter {proc roundtrip {msg} {
    return {}
}} solution {proc roundtrip {msg} {
    set srv [socket -server [list apply {{ch a p} {
        chan configure $ch -buffering line
        chan event $ch readable [list apply {{c} {
            if {[gets $c line] < 0} {close $c} else {puts $c "echo: $line"}
        }} $ch]
    }}] -myaddr 127.0.0.1 0]
    set port [lindex [chan configure $srv -sockname] 2]
    set c [socket 127.0.0.1 $port]
    chan configure $c -buffering line
    chan event $c readable [list apply {{ch} {set ::rt [gets $ch]}} $c]
    puts $c $msg
    vwait ::rt
    close $c
    close $srv
    return $::rt
}} tests {{roundtrip hi} {echo: hi}} why {Server handlers and the client's readable event both run from the event loop (`vwait`).}}
}
cards {
  {{What does `chan configure` set?} {Channel options such as -translation, -encoding, -buffering and -blocking.}}
  {{How do you avoid blocking on a channel?} {Make it non-blocking and register `chan event $ch readable handler`; the event loop calls the handler when data arrives.}}
  {{How do you create a TCP server and client?} {`socket -server handler port` and `socket host port`; port 0 picks a free port.}}
  {{What is a pipe from `chan pipe`?} {A connected pair of channels: data written to one end can be read from the other.}}
}
}

content::lesson 12.3 12 "Testing your code" "Prove it works, and keep proving it as the code changes." {
pages {
  {head "Why tests" body {
    p {Code that "seems to work" breaks the moment you change something else. A **test** is a small program that runs your code with known input and checks the result. Tests let you change code fearlessly: if they still pass, you did not break anything.}
    code {proc add {a b} {expr {$a + $b}}
proc assert {cond msg} {
    if {![uplevel 1 [list expr $cond]]} {
        error "FAILED: $msg"
    }
}
assert {[add 2 3] == 5} "add 2 3"
puts ok}
    out {ok}
    p {`assert` raises an error when its condition is false, so a failing test stops loudly. `uplevel 1` evaluates the condition in the caller, where `add` is visible.}
  }}
  {head "A mini test framework" body {
    p {A better harness runs every test, even after a failure, and prints a summary. It takes a name, a script and the expected result.}
    code {set ::passed 0
set ::failed 0
proc test {name script expected} {
    if {[catch {uplevel 1 $script} got]} {
        set got "ERROR: $got"
    }
    if {$got eq $expected} {
        incr ::passed
        puts "PASS $name"
    } else {
        incr ::failed
        puts "FAIL $name: got {$got}, expected {$expected}"
    }
}
proc double {x} {expr {$x * 2}}
test double-pos {double 3} 6
test double-neg {double -2} -4
test double-bad {catch {double x}} 1
test double-wrong {double 5} 11
puts "$::passed passed, $::failed failed"}
    out {PASS double-pos
PASS double-neg
PASS double-bad
FAIL double-wrong: got {10}, expected {11}
3 passed, 1 failed}
    p {Good tests cover the normal case, the edge cases (zero, empty, negative) and the error cases. Writing the test **first** and then the code to satisfy it is called test-driven development.}
  }}
  {head "tcltest - the standard framework" body {
    p {Tcl ships with a real framework called **tcltest**. The idea is identical, with more features: setup and cleanup code, conditions that skip tests, result matching modes, and a runner that finds all the `*.test` files in a directory.}
    show {package require tcltest
namespace import ::tcltest::*

test add-1.1 {add two numbers} -body {
    add 2 3
} -result 5

test add-1.2 {add rejects text} -body {
    add x 1
} -returnCodes error -match glob -result {*non-numeric*}

cleanupTests}
    p {Convention: put tests in a `tests/` folder in files named `something.test`, and run them all with `tcltest::runAllTests`. The output ends with a summary of totals, and the exit code tells a build system whether everything passed.}
    tip {This app tests itself in exactly this spirit: a script runs every lesson's code in the sandbox and checks the answer. Look at `tests/run.tcl` in the source.}
  }}
}
ex {
  {kind predict code {proc add {a b} {expr {$a + $b}}
proc check {name got want} {
    if {$got eq $want} {return "PASS $name"}
    return "FAIL $name"
}
puts [check sum [add 2 2] 4]} choices {{PASS sum} {FAIL sum} sum {PASS}} ans 0 why {2 + 2 is 4, so the check passes.}}
  {kind predict code {proc check {name got want} {
    if {$got eq $want} {return "PASS $name"}
    return "FAIL $name"
}
puts [check len [string length abc] 4]} choices {{FAIL len} {PASS len} len {4}} ans 0 why {The length is 3, not 4.}}
  {kind predict code {set n 0
foreach t {1 2 3} {
    if {[catch {expr {10 / ($t - 2)}}]} {incr n}
}
puts $n} choices {1 0 3 2} ans 0 why {Only the middle value (t = 2) divides by zero, so one test "errors".}}
  {kind mc q {What makes a good set of tests?} choices {{Normal cases, edge cases and error cases} {Only the cases that already work} {A single long test} {Tests that depend on each other's order}} ans 0 why {Edge and error cases are where bugs live.}}
  {kind mc q {What is test-driven development?} choices {{Writing the test first, then code to make it pass} {Testing only at the end of a project} {Letting users find the bugs} {Running tests only on release day}} ans 0 why {Red (failing test), green (passing code), then tidy up.}}
  {kind mc q {Why does the mini framework use `catch` around each test script?} choices {{So one crashing test does not stop the rest from running} {To make tests faster} {To hide failures} {Because catch is required by uplevel}} ans 0 why {A harness must survive the failures it is looking for.}}
  {kind blank q {Run the test script in the caller's scope.} code {proc runit {script} {
    return [___ 1 $script]
}
set v 7
puts [runit {expr {$v * 2}}]} answers {uplevel} extra {upvar eval apply} out {14} why {`uplevel 1` evaluates the script where the caller's variables live.}}
  {kind type q {What is the name of Tcl's standard test framework package?} accept {tcltest} why {`package require tcltest`.}}
  {kind code prompt {Write a proc **check** taking a name, the actual value and the expected value, returning `PASS name` or `FAIL name: got X, expected Y`.} starter {proc check {name got want} {
    return "PASS $name"
}} solution {proc check {name got want} {
    if {$got eq $want} {return "PASS $name"}
    return "FAIL $name: got $got, expected $want"
}} tests {{check a 4 4} {PASS a} {check b 3 4} {FAIL b: got 3, expected 4}} why {Compare, then build the matching message.}}
  {kind code prompt {Write a proc **runtests** taking a list of {name script expected} triples and returning how many FAILED. Evaluate each script with `uplevel #0` inside a `catch`.} starter {proc runtests {tests} {
    return 0
}} solution {proc runtests {tests} {
    set failed 0
    foreach t $tests {
        lassign $t name script expected
        if {[catch {uplevel #0 $script} got]} {set got "ERROR"}
        if {$got ne $expected} {incr failed}
    }
    return $failed
}} tests {{runtests {{a {expr {1+1}} 2} {b {expr {2*2}} 5} {c {error x} fine}}} 2} why {Count each mismatch, treating an error as a failure.}}
}
cards {
  {{What is an automated test?} {A small program that runs your code on known input and checks the result, so you can change code safely.}}
  {{Why should one failing test not stop the others?} {Wrap each in `catch` so the harness reports every failure in a single run.}}
  {{What should tests cover?} {Normal cases, edge cases (empty, zero, negative) and error cases.}}
  {{What is tcltest?} {Tcl's standard test framework: `test name desc -body {...} -result value`, run with `cleanupTests` or `runAllTests`.}}
}
}
