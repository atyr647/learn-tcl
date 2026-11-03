content::unit 7 "Strings and patterns" "Slice, search, format and transform text - Tcl's home turf." "#F472B6"

content::lesson 7.1 7 "The string toolkit" "A family of commands for looking at and changing text." {
pages {
  {head "Looking inside text" body {
    p {All text tools live under one command, `string`, followed by what to do. Positions start at 0 and `end` means the last character.}
    code {set s "Hello, Tcl"
puts [string length $s]
puts [string index $s 0]
puts [string range $s 7 end]
puts [string first "," $s]}
    out {10
H
Tcl
5}
    p {`string first` returns where a piece of text first occurs (or -1); `string last` finds the final one.}
  }}
  {head "Changing text" body {
    p {These return a **new** string - the original is untouched.}
    code {puts [string toupper "tcl"]
puts [string trim "   hi   "]
puts [string repeat "ab" 3]
puts [string reverse "stressed"]
puts [string map {cat dog} "the cat sat"]}
    out {TCL
hi
ababab
desserts
the dog sat}
    p {`string map` replaces several things at once: give it a list of `old new old new ...` pairs.}
  }}
  {head "Comparing and testing" body {
    p {`string equal` compares text, `string match` matches a **glob** pattern (`*` any characters, `?` one character), and `string is` checks what kind of thing a value is.}
    code {puts [string equal abc abc]
puts [string match "h*o" hello]
puts [string is integer -strict 42]
puts [string is integer -strict 4x2]}
    out {1
1
1
0}
    tip {`string is` also knows `double`, `alpha`, `alnum`, `space`, `upper`, `lower` and more. Always add `-strict` so an empty string is not counted as valid.}
  }}
}
ex {
  {kind predict code {puts [string length "Tcl is fun"]} choices {10 8 9 3} ans 0 why {Count the characters including both spaces: T-c-l, space, i-s, space, f-u-n = 10.}}
  {kind predict code {puts [string range "abcdef" 1 3]} choices {bcd abc bcde cde} ans 0 why {Positions 1 to 3 inclusive.}}
  {kind predict code {puts [string index "hello" end]} choices {o h l e} ans 0 why {`end` is the last position.}}
  {kind predict code {puts [string first "l" "hello"]} choices {2 3 1 -1} ans 0 why {The first `l` is at position 2.}}
  {kind predict code {puts [string map {a 1 b 2} "abcab"]} choices {12c12 abcab 12cab 1b2} ans 0 why {Every `a` becomes 1 and every `b` becomes 2.}}
  {kind predict code {puts [string trim "  x  "]} choices {x {  x} {x  } {  x  }} ans 0 why {`trim` removes whitespace from both ends.}}
  {kind predict code {puts [string match "*.txt" "notes.txt"]} choices {1 0 notes .txt} ans 0 why {`*` matches any characters, so the name ends in .txt.}}
  {kind predict code {puts [string is integer -strict "12a"]} choices {0 1 12 a} ans 0 why {"12a" contains a letter, so it is not an integer.}}
  {kind blank q {Make it all capital letters.} code {puts [string ___ "quiet"]} answers {toupper} extra {tolower totitle trim} out {QUIET} why {`string toupper` returns an uppercase copy.}}
  {kind type q {Which `string` subcommand gives the number of characters?} accept {length} why {`string length`.}}
  {kind code prompt {Write a proc **initial** that returns the first letter of a word in capitals, e.g. `initial tcl` gives `T`.} starter {proc initial {w} {
    return $w
}} solution {proc initial {w} {
    return [string toupper [string index $w 0]]
}} tests {{initial tcl} T {initial ada} A} why {Take character 0 with `string index`, then pass it to `string toupper`.}}
}
cards {
  {{How do you get part of a string?} {`string range $s first last` (positions start at 0; `end` is the last).}}
  {{What does `string map {a 1 b 2} $s` do?} {Replaces every a with 1 and every b with 2.}}
  {{How do you test if text matches a pattern like *.txt?} {`string match "*.txt" $name`}}
  {{How do you check whether text is a number?} {`string is integer -strict $x` (or `double`).}}
}
}

content::lesson 7.2 7 "format and scan" "Build neat text from values, and pull values out of text." {
pages {
  {head "format fills a template" body {
    p {`format` takes a template with **placeholders** and fills them in. `%s` is text, `%d` a whole number, `%f` a decimal number.}
    code {puts [format "%s is %d years old" Ada 36]
puts [format "%.2f" 3.14159]
puts [format "%05d" 42]
puts [format "%x" 255]}
    out {Ada is 36 years old
3.14
00042
ff}
    p {`%.2f` means two digits after the point; `%05d` pads with zeros to width 5; `%x` shows hexadecimal.}
  }}
  {head "Widths and alignment" body {
    p {A number before the letter sets a minimum width. A minus sign aligns left. This lets you print tidy tables.}
    code {foreach {name price} {apple 1.5 melon 12.25} {
    puts [format "%-8s %6.2f" $name $price]
}}
    out {apple      1.50
melon     12.25}
    p {To print a literal percent sign write `%%`.}
    tip {Use `format` whenever you want control of the layout: money with two decimals, aligned columns, zero-padded numbers.}
  }}
  {head "scan - the reverse" body {
    p {`scan` reads values out of text following a template. It returns how many values it found.}
    code {scan "age: 36" "age: %d" age
puts $age
scan "#ff8000" "#%2x%2x%2x" r g b
puts "$r $g $b"}
    out {36
255 128 0}
    p {Great for taking apart fixed-format text such as dates, colours or log lines. For flexible patterns, regular expressions (next lesson) are more powerful.}
  }}
}
ex {
  {kind predict code {puts [format "%d items" 3]} choices {{3 items} {%d items} {3} {items 3}} ans 0 why {`%d` is replaced by 3.}}
  {kind predict code {puts [format "%.1f" 2.75]} choices {2.8 2.7 2.75 3} ans 0 why {One decimal place; 2.75 rounds to 2.8.}}
  {kind predict code {puts [format "%03d" 7]} choices {007 7 070 {  7}} ans 0 why {Zero padded to width 3.}}
  {kind predict code {puts [format "%5s|" ab]} choices {{   ab|} {ab   |} {ab|} {5ab|}} ans 0 why {Width 5, right-aligned by default.}}
  {kind predict code {puts [format "%-5s|" ab]} choices {{ab   |} {   ab|} {ab|} {-5ab|}} ans 0 why {The minus flag left-aligns.}}
  {kind predict code {puts [format "%s has %d%%" Ann 90]} choices {{Ann has 90%} {Ann has 90} {Ann has 90%%} {Ann has %}} ans 0 why {`%%` prints one percent sign.}}
  {kind predict code {scan "7 apples" "%d %s" n w
puts "$w:$n"} choices {apples:7 7:apples {7 apples} n:w} ans 0 why {`scan` stored 7 in n and apples in w.}}
  {kind blank q {Print the value with exactly two decimals.} code {puts [format "___" 2.5]} answers {%.2f} extra {%d %s %2f} out {2.50} why {`%.2f` shows two decimal places.}}
  {kind type q {Which placeholder inserts a whole number in format?} accept {%d} why {`%d`.}}
  {kind code prompt {Write a proc **money** that formats a number with two decimals and a dollar sign: `money 5` gives `$5.00`.} starter {proc money {x} {
    return $x
}} solution {proc money {x} {
    return [format {$%.2f} $x]
}} tests {{money 5} {$5.00} {money 3.456} {$3.46}} why {Use braces so the dollar sign stays literal: `format {$%.2f} $x`.}}
}
cards {
  {{What do %s, %d and %f mean in format?} {Text, whole number, decimal number.}}
  {{How do you show two decimals?} {`format "%.2f" $x`}}
  {{What does the minus in `%-8s` do?} {Left-aligns the text in a field 8 characters wide.}}
  {{What does `scan` do?} {Reads values out of text following a template, like `scan "age: 36" "age: %d" age`.}}
}
}

content::lesson 7.3 7 "Regular expressions" "A tiny language for describing patterns in text." {
pages {
  {head "Describing patterns" body {
    p {A **regular expression** (regex) describes a pattern of text. `regexp pattern string` returns 1 if the pattern is found, 0 otherwise.}
    p {- `.` any one character
- `\d` a digit, `\w` a letter/digit/underscore, `\s` a space
- `+` one or more, `*` zero or more, `?` optional
- `^` start of text, `$` end of text
- `[abc]` one of these characters, `a|b` a or b}
    code {puts [regexp {\d+} "room 42"]
puts [regexp {^\d+$} "42a"]
puts [regexp {colou?r} "my color"]}
    out {1
0
1}
    tip {Write patterns in **curly braces**, so Tcl leaves the backslashes alone for the regex engine.}
  }}
  {head "Capturing parts" body {
    p {Round brackets **capture** the part they match. After the string, list variables to receive the whole match followed by each capture.}
    code {regexp {(\d+)-(\d+)} "call 555-1234" all area num
puts "$all / $area / $num"}
    out {555-1234 / 555 / 1234}
    p {With `-all -inline` you get every match as a list:}
    code {puts [regexp -all -inline {\d+} "a1 b22 c333"]}
    out {1 22 333}
  }}
  {head "Replacing text" body {
    p {`regsub` replaces matches. Use `-all` to replace every match instead of only the first. In the replacement, `\1`, `\2` ... refer to the captures.}
    code {puts [regsub -all {\s+} "a   b    c" " "]
puts [regsub {(\w+) (\w+)} "hello world" {\2 \1}]}
    out {a b c
world hello}
    p {Add `-nocase` to ignore capital letters. Regular expressions take time to learn, but one line can replace pages of code.}
  }}
}
ex {
  {kind predict code {puts [regexp {\d} "abc"]} choices {0 1 abc {}} ans 0 why {There is no digit in "abc".}}
  {kind predict code {puts [regexp {^a.*z$} "abcxyz"]} choices {1 0 abcxyz a} ans 0 why {Starts with a, ends with z, anything in between.}}
  {kind predict code {regexp {(\w+)@(\w+)} "mail ann@site now" all user host
puts "$user at $host"} choices {{ann at site} {ann@site at now} {mail at ann} {all at user}} ans 0 why {The two captures are the word before and after the @.}}
  {kind predict code {puts [regexp -all -inline {[aeiou]} "banana"]} choices {{a a a} {b n n} {a n a} {banana}} ans 0 why {Every vowel match is collected into a list.}}
  {kind predict code {puts [regsub -all {a} "banana" "o"]} choices {bonono banana bonana ooooo} ans 0 why {Every `a` is replaced.}}
  {kind predict code {puts [regsub {\d+} "order 66 and 77" "N"]} choices {{order N and 77} {order N and N} {order 66 and 77} {N}} ans 0 why {Without `-all` only the first match is replaced.}}
  {kind mc q {Why write regex patterns in curly braces?} choices {{So Tcl does not process the backslashes first} {It makes them run faster} {Because regexp requires it} {To make them case-insensitive}} ans 0 why {Braces pass the pattern to the regex engine untouched.}}
  {kind blank q {Match one or more digits.} code {puts [regexp {___} "id 123"]} answers {\d+} extra {\w* \s+ .} out {1} why {`\d` is a digit and `+` means one or more.}}
  {kind type q {Which command replaces text that matches a pattern?} accept {regsub} why {`regsub`.}}
  {kind code prompt {Write a proc **digits** that returns only the digits found in a string, joined together: `digits a1b22c3` gives `1223`.} starter {proc digits {s} {
    return $s
}} solution {proc digits {s} {
    return [regsub -all {\D} $s ""]
}} tests {{digits a1b22c3} 1223 {digits none} {}} why {`\D` means "not a digit", so removing every `\D` leaves only digits.}}
}
cards {
  {{What do \d, \w, \s mean in a regex?} {A digit, a word character (letter, digit, underscore), and a whitespace character.}}
  {{How do you capture parts of a match?} {Use round brackets and variable names: `regexp {(\d+)-(\d+)} $s all a b`.}}
  {{How do you replace every match?} {`regsub -all pattern string replacement`}}
  {{Why put regex patterns in braces?} {So Tcl does not interpret the backslashes before the regex engine sees them.}}
}
}
