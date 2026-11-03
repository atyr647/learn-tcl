content::unit 17 "Practice katas" "Small problems, big skill: solve them from a blank editor." "#A3E635"

content::lesson 17.1 17 "Katas: warm-ups" "Quick problems to build fluency." {
pages {
  {head "How to practise katas" body {
    p {A **kata** is a small problem you solve repeatedly to build skill, the way a musician plays scales. The routine that works:}
    p {- **Read** the spec twice and restate it in your own words
- Work out the answer **by hand** for a tiny example
- Write the simplest code that passes; then check **edge cases** (empty, one item, negative, huge)
- Only then tidy it. Later, solve it again a different way (loop versus recursion, list versus dict)}
    code {proc fizz {n} {
    set r {}
    for {set i 1} {$i <= $n} {incr i} {
        if {$i % 15 == 0} {
            lappend r FizzBuzz
        } elseif {$i % 3 == 0} {
            lappend r Fizz
        } elseif {$i % 5 == 0} {
            lappend r Buzz
        } else {
            lappend r $i
        }
    }
    return $r
}
puts [fizz 15]}
    out {1 2 Fizz 4 Buzz Fizz 7 8 Fizz Buzz 11 Fizz 13 14 FizzBuzz}
    tip {Test the most specific case first (15 before 3 and 5). Order of conditions is the classic source of bugs in this problem.}
  }}
}
ex {
  {kind code prompt {**fizzbuzz n**: return the list 1..n where multiples of 3 are `Fizz`, of 5 are `Buzz`, of both `FizzBuzz`.} starter {proc fizzbuzz {n} {
    return {}
}} solution {proc fizzbuzz {n} {
    set r {}
    for {set i 1} {$i <= $n} {incr i} {
        if {$i % 15 == 0} {lappend r FizzBuzz} elseif {$i % 3 == 0} {lappend r Fizz} elseif {$i % 5 == 0} {lappend r Buzz} else {lappend r $i}
    }
    return $r
}} tests {{fizzbuzz 5} {1 2 Fizz 4 Buzz} {fizzbuzz 0} {}} why {Check the combined case first.}}
  {kind code prompt {**isprime n**: return 1 if n is prime, else 0 (n below 2 is not prime).} starter {proc isprime {n} {
    return 0
}} solution {proc isprime {n} {
    if {$n < 2} {return 0}
    for {set i 2} {$i * $i <= $n} {incr i} {
        if {$n % $i == 0} {return 0}
    }
    return 1
}} tests {{isprime 2} 1 {isprime 17} 1 {isprime 18} 0 {isprime 1} 0 {isprime 97} 1} why {Only test divisors up to the square root.}}
  {kind code prompt {**factorial n** for n 0 or more (use big integers: `factorial 20` is 2432902008176640000).} starter {proc factorial {n} {
    return 1
}} solution {proc factorial {n} {
    set r 1
    for {set i 2} {$i <= $n} {incr i} {set r [expr {$r * $i}]}
    return $r
}} tests {{factorial 0} 1 {factorial 5} 120 {factorial 20} 2432902008176640000} why {Multiply 1 * 2 * ... * n.}}
  {kind code prompt {**reversewords s**: reverse the order of the words in a sentence: `reversewords "one two three"` is `three two one`.} starter {proc reversewords {s} {
    return $s
}} solution {proc reversewords {s} {
    return [join [lreverse [split $s " "]] " "]
}} tests {{reversewords "one two three"} {three two one} {reversewords hi} hi} why {Split, `lreverse`, join.}}
  {kind code prompt {**countvowels s**: count the vowels a e i o u (any case) in a string.} starter {proc countvowels {s} {
    return 0
}} solution {proc countvowels {s} {
    return [llength [regexp -all -inline -nocase {[aeiou]} $s]]
}} tests {{countvowels Hello} 2 {countvowels "RHYTHM"} 0 {countvowels AEIOU} 5} why {Collect every vowel match and count them.}}
  {kind code prompt {**digitsum n**: the sum of the digits of a whole number: `digitsum 1234` is 10.} starter {proc digitsum {n} {
    return 0
}} solution {proc digitsum {n} {
    set s 0
    foreach d [split $n ""] {incr s $d}
    return $s
}} tests {{digitsum 1234} 10 {digitsum 0} 0 {digitsum 999} 27} why {Split the number into characters and add them.}}
  {kind code prompt {**collatz n**: the number of steps for n to reach 1, where even n becomes n/2 and odd n becomes 3n+1: `collatz 6` is 8.} starter {proc collatz {n} {
    return 0
}} solution {proc collatz {n} {
    set steps 0
    while {$n != 1} {
        if {$n % 2 == 0} {set n [expr {$n / 2}]} else {set n [expr {3 * $n + 1}]}
        incr steps
    }
    return $steps
}} tests {{collatz 1} 0 {collatz 6} 8 {collatz 27} 111} why {Loop until 1, counting steps.}}
  {kind code prompt {**isleap year**: 1 if a year is a leap year (divisible by 4, except centuries unless divisible by 400), else 0.} starter {proc isleap {y} {
    return 0
}} solution {proc isleap {y} {
    return [expr {($y % 4 == 0 && $y % 100 != 0) || $y % 400 == 0}]
}} tests {{isleap 2024} 1 {isleap 1900} 0 {isleap 2000} 1 {isleap 2023} 0} why {The rule has two exceptions; encode them exactly.}}
  {kind code prompt {**sumsquares n**: the sum of the squares 1 + 4 + 9 + ... up to n squared.} starter {proc sumsquares {n} {
    return 0
}} solution {proc sumsquares {n} {
    set s 0
    for {set i 1} {$i <= $n} {incr i} {incr s [expr {$i * $i}]}
    return $s
}} tests {{sumsquares 3} 14 {sumsquares 0} 0 {sumsquares 10} 385} why {Accumulate in a loop (or use the formula n(n+1)(2n+1)/6).}}
}
cards {
  {{What is a kata?} {A small problem you solve repeatedly to build fluency, like practising scales.}}
  {{What is a good kata routine?} {Restate the spec, work a tiny example by hand, write the simplest passing code, check edge cases, then tidy and re-solve differently.}}
  {{What is the usual bug in FizzBuzz?} {Testing 3 and 5 before 15, so FizzBuzz is never produced.}}
}
}

content::lesson 17.2 17 "Katas: strings and lists" "Transformations you will meet constantly." {
pages {
  {head "Think in pipelines" body {
    p {Most string and list problems are a **pipeline**: break the input into pieces (`split`, `regexp -all -inline`), transform each piece (`lmap`, `string map`), then combine (`join`, `concat`, `dict`). Sketch the pipeline before writing code.}
    code {proc anagrams {words} {
    set groups {}
    foreach w $words {
        set key [join [lsort [split $w ""]] ""]
        dict lappend groups $key $w
    }
    return [dict values $groups]
}
puts [anagrams {listen silent enlist google gogole cat act}]}
    out {{listen silent enlist} {google gogole} {cat act}}
    p {The trick: two words are anagrams exactly when their sorted letters match, so the sorted letters make a perfect dictionary key.}
  }}
}
ex {
  {kind code prompt {**anagrams words**: group words that are anagrams of each other, returning a list of groups in first-seen order.} starter {proc anagrams {words} {
    return {}
}} solution {proc anagrams {words} {
    set groups {}
    foreach w $words {
        set key [join [lsort [split $w ""]] ""]
        dict lappend groups $key $w
    }
    return [dict values $groups]
}} tests {{anagrams {listen silent enlist cat act dog}} {{listen silent enlist} {cat act} dog}} why {Use the sorted letters as a dict key.}}
  {kind code prompt {**roman n**: convert a whole number 1-3999 to a Roman numeral: `roman 1994` is `MCMXCIV`.} starter {proc roman {n} {
    return $n
}} solution {proc roman {n} {
    set r ""
    foreach {v s} {1000 M 900 CM 500 D 400 CD 100 C 90 XC 50 L 40 XL 10 X 9 IX 5 V 4 IV 1 I} {
        while {$n >= $v} {
            append r $s
            incr n -$v
        }
    }
    return $r
}} tests {{roman 4} IV {roman 9} IX {roman 58} LVIII {roman 1994} MCMXCIV} why {Greedy: subtract the largest value that fits, including the subtractive pairs.}}
  {kind code prompt {**fromroman s**: convert a Roman numeral to a number: `fromroman MCMXCIV` is 1994.} starter {proc fromroman {s} {
    return 0
}} solution {proc fromroman {s} {
    set v {I 1 V 5 X 10 L 50 C 100 D 500 M 1000}
    set total 0
    set chars [split $s ""]
    for {set i 0} {$i < [llength $chars]} {incr i} {
        set cur [dict get $v [lindex $chars $i]]
        set next 0
        if {$i + 1 < [llength $chars]} {set next [dict get $v [lindex $chars [expr {$i + 1}]]]}
        if {$cur < $next} {incr total -$cur} else {incr total $cur}
    }
    return $total
}} tests {{fromroman IV} 4 {fromroman LVIII} 58 {fromroman MCMXCIV} 1994} why {A smaller numeral before a larger one is subtracted.}}
  {kind code prompt {**rle s**: run-length encode a string: `rle aaabccdd` is `a3b1c2d2`.} starter {proc rle {s} {
    return $s
}} solution {proc rle {s} {
    set out ""
    set prev ""
    set n 0
    foreach c [split $s ""] {
        if {$c eq $prev} {
            incr n
        } else {
            if {$prev ne ""} {append out $prev $n}
            set prev $c
            set n 1
        }
    }
    if {$prev ne ""} {append out $prev $n}
    return $out
}} tests {{rle aaabccdd} a3b1c2d2 {rle ""} {} {rle z} z1} why {Count consecutive repeats; flush the last run at the end.}}
  {kind code prompt {**unrle s**: decode run-length text (single-digit counts): `unrle a3b1` is `aaab`.} starter {proc unrle {s} {
    return $s
}} solution {proc unrle {s} {
    set out ""
    foreach {all c n} [regexp -all -inline {(.)(\d)} $s] {
        append out [string repeat $c $n]
    }
    return $out
}} tests {{unrle a3b1} aaab {unrle ""} {} {unrle x2y3} xxyyy} why {Capture each letter-and-count pair and repeat the letter.}}
  {kind code prompt {**chunk list n**: split a list into sublists of at most n items: `chunk {1 2 3 4 5} 2` is `{1 2} {3 4} 5`.} starter {proc chunk {l n} {
    return $l
}} solution {proc chunk {l n} {
    set r {}
    for {set i 0} {$i < [llength $l]} {incr i $n} {
        lappend r [lrange $l $i [expr {$i + $n - 1}]]
    }
    return $r
}} tests {{chunk {1 2 3 4 5} 2} {{1 2} {3 4} 5} {chunk {} 3} {}} why {Step through the list n at a time with `lrange`.}}
  {kind code prompt {**transpose m**: transpose a matrix given as a list of equal-length rows: `transpose {{1 2 3} {4 5 6}}` is `{1 4} {2 5} {3 6}`.} starter {proc transpose {m} {
    return $m
}} solution {proc transpose {m} {
    set r {}
    set cols [llength [lindex $m 0]]
    for {set c 0} {$c < $cols} {incr c} {
        set row {}
        foreach line $m {lappend row [lindex $line $c]}
        lappend r $row
    }
    return $r
}} tests {{transpose {{1 2 3} {4 5 6}}} {{1 4} {2 5} {3 6}} {transpose {{1}}} 1} why {Collect column c from every row.}}
  {kind code prompt {**ispangram s**: 1 if a sentence uses every letter a-z at least once (any case), else 0.} starter {proc ispangram {s} {
    return 0
}} solution {proc ispangram {s} {
    set seen {}
    foreach c [split [string tolower $s] ""] {
        if {[string is alpha $c]} {dict set seen $c 1}
    }
    return [expr {[dict size $seen] == 26}]
}} tests {{ispangram "The quick brown fox jumps over the lazy dog"} 1 {ispangram "Hello world"} 0} why {Count the distinct letters.}}
  {kind code prompt {**longestword s**: return the longest word in a sentence (the first one if tied).} starter {proc longestword {s} {
    return {}
}} solution {proc longestword {s} {
    set best ""
    foreach w [split $s " "] {
        if {[string length $w] > [string length $best]} {set best $w}
    }
    return $best
}} tests {{longestword "a quick brownish fox"} brownish {longestword "ab cd"} ab {longestword ""} {}} why {Keep the best so far; replace it only when strictly longer.}}
}
cards {
  {{How do you detect anagrams?} {Sort the letters of each word; equal sorted strings mean anagrams - use that as a dict key.}}
  {{What is greedy conversion?} {Repeatedly take the largest value that fits (Roman numerals, coin change with canonical coins).}}
  {{How do you write a string/list kata?} {Sketch a pipeline: split into pieces, transform each, combine.}}
}
}

content::lesson 17.3 17 "Katas: data wrangling" "Realistic tasks: grouping, joining, parsing and dates." {
pages {
  {head "Everyday data tasks" body {
    p {Real programs mostly **reshape data**: group records, join two sources on a key, parse a slightly awkward format, compute dates. These katas practise exactly that. The tool kit: `dict` (grouping and lookup), `lmap`/`foreach` (reshaping), `regexp` (parsing), `clock` (dates).}
    code {set people {{name ann dept ops} {name bob dept dev} {name cy dept ops}}
set by {}
foreach p $people {dict lappend by [dict get $p dept] [dict get $p name]}
puts $by}
    out {ops {ann cy} dev bob}
    p {Grouping is `dict lappend` keyed by the field you group on. Joining is the same idea in reverse: put one side in a dict, then look each row of the other side up in it.}
  }}
}
ex {
  {kind code prompt {**groupby field records**: records are dicts. Return a dict mapping each value of `field` to the list of records having it (in order).} starter {proc groupby {field records} {
    return {}
}} solution {proc groupby {field records} {
    set d {}
    foreach r $records {dict lappend d [dict get $r $field] $r}
    return $d
}} tests {{groupby k {{k a v 1} {k b v 2} {k a v 3}}} {a {{k a v 1} {k a v 3}} b {{k b v 2}}}} why {`dict lappend` builds each group.}}
  {kind code prompt {**join left right key**: both lists of dicts; return a list of merged dicts for every pair with equal `key` values (inner join), left order.} starter {proc join_on {left right key} {
    return {}
}} solution {proc join_on {left right key} {
    set idx {}
    foreach r $right {dict lappend idx [dict get $r $key] $r}
    set out {}
    foreach l $left {
        set k [dict get $l $key]
        if {[dict exists $idx $k]} {
            foreach r [dict get $idx $k] {lappend out [dict merge $l $r]}
        }
    }
    return $out
}} tests {{join_on {{id 1 a x} {id 2 a y}} {{id 2 b p} {id 3 b q}} id} {{id 2 a y b p}}} why {Index one side by the key, then look up each row of the other.}}
  {kind code prompt {**csvsplit line**: split a CSV line into fields, honouring double-quoted fields that contain commas: `csvsplit {a,"b,c",d}` is `a b,c d`.} starter {proc csvsplit {line} {
    return [split $line ,]
}} solution {proc csvsplit {line} {
    set fields {}
    set cur ""
    set inq 0
    foreach c [split $line ""] {
        if {$c eq "\""} {
            set inq [expr {!$inq}]
        } elseif {$c eq "," && !$inq} {
            lappend fields $cur
            set cur ""
        } else {
            append cur $c
        }
    }
    lappend fields $cur
    return $fields
}} tests {{csvsplit {a,"b,c",d}} {a b,c d} {csvsplit x} x {csvsplit {,}} {{} {}}} why {Track whether we are inside quotes; only commas outside quotes separate fields.}}
  {kind code prompt {**matmul a b**: multiply two matrices (lists of rows): `matmul {{1 2} {3 4}} {{5 6} {7 8}}` is `{19 22} {43 50}`.} starter {proc matmul {a b} {
    return {}
}} solution {proc matmul {a b} {
    set r {}
    set cols [llength [lindex $b 0]]
    foreach row $a {
        set out {}
        for {set c 0} {$c < $cols} {incr c} {
            set s 0
            set k 0
            foreach x $row {
                incr s [expr {$x * [lindex $b $k $c]}]
                incr k
            }
            lappend out $s
        }
        lappend r $out
    }
    return $r
}} tests {{matmul {{1 2} {3 4}} {{5 6} {7 8}}} {{19 22} {43 50}}} why {Each result cell is the dot product of a row of a with a column of b.}}
  {kind code prompt {**tobinary n**: convert a non-negative whole number to a binary string without using `format %b`: `tobinary 10` is `1010`, `tobinary 0` is `0`.} starter {proc tobinary {n} {
    return $n
}} solution {proc tobinary {n} {
    if {$n == 0} {return 0}
    set s ""
    while {$n > 0} {
        set s [expr {$n % 2}]$s
        set n [expr {$n / 2}]
    }
    return $s
}} tests {{tobinary 10} 1010 {tobinary 0} 0 {tobinary 255} 11111111} why {Repeatedly divide by two, prepending each remainder.}}
  {kind code prompt {**compound principal rate years**: the amount after compounding annually, formatted to 2 decimals: `compound 1000 0.05 2` is `1102.50`.} starter {proc compound {p r y} {
    return $p
}} solution {proc compound {p r y} {
    return [format %.2f [expr {$p * (1 + $r) ** $y}]]
}} tests {{compound 1000 0.05 2} 1102.50 {compound 100 0 5} 100.00} why {Multiply by (1 + rate) once per year; format at the end.}}
  {kind code prompt {**daysbetween a b**: whole days between two dates given as YYYY-MM-DD (use `clock scan` with `-timezone :UTC`).} starter {proc daysbetween {a b} {
    return 0
}} solution {proc daysbetween {a b} {
    set ta [clock scan $a -format %Y-%m-%d -timezone :UTC]
    set tb [clock scan $b -format %Y-%m-%d -timezone :UTC]
    return [expr {($tb - $ta) / 86400}]
}} tests {{daysbetween 2024-01-01 2024-03-01} 60 {daysbetween 2024-05-10 2024-05-10} 0} why {Convert both to seconds and divide the difference by a day.}}
  {kind code prompt {**wordwrapcount text width**: how many lines a text needs when greedily wrapped at the given width (words are never split).} starter {proc wordwrapcount {text width} {
    return 0
}} solution {proc wordwrapcount {text width} {
    set lines 0
    set cur ""
    foreach w [split $text " "] {
        if {$w eq ""} continue
        if {$cur eq ""} {
            set cur $w
            set lines 1
        } elseif {[string length $cur] + 1 + [string length $w] <= $width} {
            append cur " " $w
        } else {
            incr lines
            set cur $w
        }
    }
    return $lines
}} tests {{wordwrapcount "the quick brown fox" 10} 2 {wordwrapcount "" 10} 0 {wordwrapcount "aaaa bbbb" 4} 2} why {Fill each line greedily; start a new one when the next word does not fit.}}
  {kind code prompt {**histogram counts**: given a dict of label to count, return a list of lines like `ann ###` (one `#` per count), sorted by label.} starter {proc histogram {counts} {
    return {}
}} solution {proc histogram {counts} {
    set r {}
    foreach k [lsort [dict keys $counts]] {
        lappend r "$k [string repeat # [dict get $counts $k]]"
    }
    return $r
}} tests {{histogram {bob 2 ann 3}} {{ann ###} {bob ##}}} why {`string repeat` draws each bar.}}
}
cards {
  {{How do you group records by a field?} {`dict lappend groups [dict get $rec $field] $rec` for each record.}}
  {{How do you join two lists of records on a key?} {Index one list in a dict by key, then look up each row of the other and `dict merge`.}}
  {{How do you handle quoted CSV fields?} {Scan characters with an in-quotes flag; only commas outside quotes separate fields.}}
}
}
