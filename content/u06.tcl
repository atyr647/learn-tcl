content::unit 6 "Lists" "Tcl's workhorse data structure: ordered collections of things." "#FB923C"

content::lesson 6.1 6 "Lists: ordered collections" "Create lists, read items, grow and change them." {
pages {
  {head "A list of things" body {
    p {A **list** is an ordered collection of items. In Tcl a simple list is just words separated by spaces. Counting starts at **0**, and `end` means the last item.}
    code {set colors {red green blue}
puts [llength $colors]
puts [lindex $colors 0]
puts [lindex $colors end]}
    out {3
red
blue}
    p {- `llength` counts the items
- `lindex list n` fetches item number n}
    tip {Starting at 0 feels odd at first. Think of the index as "how many items to skip".}
  }}
  {head "Growing and changing" body {
    p {`lappend` adds items to the end of a list variable (no `$` - it takes the name). `lrange` takes a slice, and `lset` replaces one item.}
    code {set l {}
lappend l apple
lappend l pear fig
puts $l
puts [lrange $l 1 end]
lset l 0 kiwi
puts $l}
    out {apple pear fig
pear fig
kiwi pear fig}
    p {`{}` is the empty list. `linsert` and `lreplace` insert and replace in the middle.}
  }}
  {head "Building lists with list" body {
    p {To build a list from separate values, use `list`. It looks after the quoting for you, even for items that contain spaces.}
    code {set items [list "red apple" banana]
puts [llength $items]
puts [lindex $items 0]}
    out {2
red apple}
    warn {`{red apple banana}` is a list of **three** items. Use `list "red apple" banana` when an item contains a space.}
  }}
}
ex {
  {kind predict code {set l {a b c d}
puts [lindex $l 1]} choices {b a c d} ans 0 why {Index 0 is `a`, so index 1 is `b`.}}
  {kind predict code {puts [lindex {x y z} end]} choices {z x y end} ans 0 why {`end` means the last item.}}
  {kind predict code {puts [llength {one two three four}]} choices {4 3 5 1} ans 0 why {There are four items.}}
  {kind predict code {set n {}
lappend n 5
lappend n 6 7
puts $n} choices {{5 6 7} {5} {{5 6 7}} {7 6 5}} ans 0 why {`lappend` adds items to the end; the list becomes 5 6 7.}}
  {kind predict code {puts [lrange {a b c d e} 1 3]} choices {{b c d} {a b c} {b c d e} {c d}} ans 0 why {`lrange l 1 3` gives items 1 to 3 inclusive.}}
  {kind predict code {set l {1 2 3}
lset l 1 99
puts $l} choices {{1 99 3} {99 2 3} {1 2 99} {1 2 3 99}} ans 0 why {`lset` replaces item number 1 (the second one).}}
  {kind predict code {puts [llength [list "red apple" banana]]} choices {2 3 1 4} ans 0 why {`list` keeps "red apple" together as one item.}}
  {kind blank q {Get the third item.} code {puts [___ {a b c d} 2]} answers {lindex} extra {lrange llength lappend} out {c} why {`lindex list n` returns item n, counting from 0.}}
  {kind type q {Which command adds an item to the end of a list variable?} accept {lappend} why {`lappend name item`.}}
  {kind code prompt {Write a proc **second** that returns the second item of a list.} starter {proc second {l} {
    return
}} solution {proc second {l} {
    return [lindex $l 1]
}} tests {{second {a b c}} b {second {10 20}} 20} why {The second item has index 1.}}
}
cards {
  {{How do you get the number of items in a list?} {`llength $list`}}
  {{How do you read item number 2 (counting from 0)?} {`lindex $list 2` - and `lindex $list end` for the last one.}}
  {{How do you add an item to the end of a list variable?} {`lappend name item` (no dollar sign before the name).}}
  {{Why use `list` to build a list?} {It quotes items correctly, so values with spaces stay as one item.}}
}
}

content::lesson 6.2 6 "Searching, sorting and joining" "Find things, put them in order, and convert between lists and text." {
pages {
  {head "Finding items" body {
    p {`lsearch` returns the index of the first matching item, or `-1` if there is none. `lsearch -all` returns every matching index. And `in` is a quick yes/no test.}
    code {set l {apple pear fig pear}
puts [lsearch $l fig]
puts [lsearch $l kiwi]
puts [lsearch -all $l pear]
puts [expr {"fig" in $l}]}
    out {2
-1
1 3
1}
    p {By default `lsearch` uses **glob** patterns: `lsearch $l p*` finds the first item starting with p. Add `-exact` to match literally.}
  }}
  {head "Sorting" body {
    p {`lsort` returns a sorted copy. By default it sorts alphabetically, so numbers need `-integer` (or `-real`).}
    code {puts [lsort {pear apple fig}]
puts [lsort -integer {10 9 100 1}]
puts [lsort -integer -decreasing {10 9 100 1}]}
    out {apple fig pear
1 9 10 100
100 10 9 1}
    warn {Without `-integer`, the numbers are sorted as text: `1 10 100 9`.}
    p {`lreverse` flips a list. `lsort -unique` also removes duplicates.}
  }}
  {head "Lists and text" body {
    p {`split` cuts text into a list at a separator; `join` glues a list back into text.}
    code {set parts [split "2024-05-17" -]
puts [lindex $parts 1]
puts [join {a b c} " + "]
puts [llength [split "a,b,,c" ,]]}
    out {05
a + b + c
4}
    p {Notice the empty item between the two commas - `split` keeps it. `concat` joins lists into one longer list.}
  }}
}
ex {
  {kind predict code {puts [lsearch {a b c} c]} choices {2 3 c 1} ans 0 why {`c` is at index 2.}}
  {kind predict code {puts [lsearch {a b c} z]} choices {-1 0 {} z} ans 0 why {No match gives -1.}}
  {kind predict code {puts [lsort {pear apple fig}]} choices {{apple fig pear} {pear fig apple} {fig apple pear} {apple pear fig}} ans 0 why {Alphabetical order.}}
  {kind predict code {puts [lsort {10 9 100 1}]} choices {{1 10 100 9} {1 9 10 100} {100 10 9 1} {9 10 100 1}} ans 0 why {Without `-integer` the items are compared as text, character by character.}}
  {kind predict code {puts [lsort -integer -decreasing {5 50 7}]} choices {{50 7 5} {5 7 50} {7 5 50} {50 5 7}} ans 0 why {Largest first.}}
  {kind predict code {puts [join {x y z} -]} choices {x-y-z {x - y - z} xyz {x y z}} ans 0 why {`join` places the separator between items.}}
  {kind predict code {puts [lindex [split "a:b:c" :] 2]} choices {c b a {a:b:c}} ans 0 why {`split` gives {a b c}; index 2 is `c`.}}
  {kind predict code {puts [lreverse {1 2 3}]} choices {{3 2 1} {1 2 3} {2 1 3} {3 1 2}} ans 0 why {`lreverse` flips the order.}}
  {kind blank q {Sort the numbers from smallest to largest.} code {puts [lsort ___ {30 4 200}]} answers {-integer} extra {-text -decreasing -unique} out {4 30 200} why {`-integer` compares the items as numbers.}}
  {kind type q {What does lsearch return when nothing matches?} accept {-1} why {-1.}}
  {kind code prompt {Write a proc **csvsum** that takes comma-separated numbers like `3,4,5` and returns their sum.} starter {proc csvsum {text} {
    set total 0
    return $total
}} solution {proc csvsum {text} {
    set total 0
    foreach n [split $text ,] {incr total $n}
    return $total
}} tests {{csvsum 3,4,5} 12 {csvsum 10} 10} why {`split` turns the text into a list, `foreach` adds up the items.}}
}
cards {
  {{What does `lsearch $l x` return?} {The index of the first item matching x, or -1 if there is none.}}
  {{How do you sort numbers properly?} {`lsort -integer $list` (or `-real`). Plain `lsort` sorts as text, so 10 comes before 9.}}
  {{What do `split` and `join` do?} {`split text sep` makes a list from text; `join list sep` makes text from a list.}}
  {{How do you test membership in a list?} {`expr {$x in $list}` returns 1 or 0.}}
}
}

content::lesson 6.3 6 "More list power" "Transform lists, unpack them, nest them and spread them out." {
pages {
  {head "lmap - transform a list" body {
    p {`lmap` is like `foreach`, but it **collects** the results into a new list.}
    code {puts [lmap n {1 2 3 4} {expr {$n * 10}}]}
    out {10 20 30 40}
    p {Use `continue` to filter: items for which the body continues are left out.}
    code {puts [lmap n {1 2 3 4 5 6} {
    if {$n % 2} continue
    set n
}]}
    out {2 4 6}
    p {Here odd numbers are skipped, and `set n` as the last command produces each kept value.}
  }}
  {head "Unpacking and nesting" body {
    p {`lassign` splits a list into separate variables. A list can also contain lists, which is how tables are stored.}
    code {lassign {Ada 36} name age
puts "$name is $age"
set table {{Ann 31} {Bob 25} {Cy 40}}
puts [lindex $table 1 0]
puts [lsort -integer -index 1 $table]}
    out {Ada is 36
Bob
{Bob 25} {Ann 31} {Cy 40}}
    p {`lindex $table 1 0` means "item 1, then item 0 of that". `lsort -index 1` sorts the rows by their second column.}
  }}
  {head "Spreading with {*}" body {
    p {Put `{*}` in front of a list to spread its items out as separate arguments.}
    code {set nums {3 9 5}
puts [tcl::mathfunc::max {*}$nums]
set more {7 8}
lappend nums {*}$more
puts $nums}
    out {9
3 9 5 7 8}
    p {Maths functions such as `max` are really commands in the `tcl::mathfunc` namespace, which is why they can be called directly like this.}
    tip {Without the expansion, `lappend nums $more` would add one item that is itself a list.}
  }}
}
ex {
  {kind predict code {puts [lmap x {1 2 3} {expr {$x * $x}}]} choices {{1 4 9} {1 2 3} {2 4 6} {3 6 9}} ans 0 why {`lmap` collects the result of each round into a new list.}}
  {kind predict code {lassign {red green} a b
puts $b} choices {green red {red green} {}} ans 0 why {`lassign` puts the first item in `a` and the second in `b`.}}
  {kind predict code {set t {{a 1} {b 2}}
puts [lindex $t 1 0]} choices {b a 2 1} ans 0 why {Row 1 is `b 2`, and its item 0 is `b`.}}
  {kind predict code {puts [lmap w {apple fig kiwi} {string length $w}]} choices {{5 3 4} {3 5 4} {5 4 3} {apple fig kiwi}} ans 0 why {Each word is replaced by its length.}}
  {kind predict code {set l {1 2}
lappend l {*}{3 4}
puts [llength $l]} choices {4 3 2 5} ans 0 why {`{*}` spreads 3 and 4 as separate items, so the list has four items.}}
  {kind predict code {puts [lsort -integer -index 1 {{a 9} {b 2} {c 5}}]} choices {{{b 2} {c 5} {a 9}} {{a 9} {b 2} {c 5}} {{c 5} {b 2} {a 9}} {{b 2} {a 9} {c 5}}} ans 0 why {The rows are ordered by their second column: 2, 5, 9.}}
  {kind mc q {What is the difference between `foreach` and `lmap`?} choices {{`lmap` collects the results into a new list} {`foreach` is faster} {`lmap` only works on numbers} {There is none}} ans 0 why {`foreach` just runs code; `lmap` returns a list of the results.}}
  {kind blank q {Spread the list as separate arguments.} code {set n {4 8 6}
puts [tcl::mathfunc::max ___$n]} answers {{{*}}} extra {{...} {@} {&}} out {8} why {`{*}$n` expands the list into separate words.}}
  {kind code prompt {Write a proc **evens** that returns only the even numbers of a list, using lmap.} starter {proc evens {l} {
    return $l
}} solution {proc evens {l} {
    return [lmap n $l {if {$n % 2} continue; set n}]
}} tests {{evens {1 2 3 4 5 6}} {2 4 6} {evens {7 9}} {}} why {`continue` skips odd numbers, and `set n` gives the value to keep.}}
}
cards {
  {{What does `lmap` do?} {Like foreach, but collects each round's result into a new list.}}
  {{What does `lassign {a b} x y` do?} {Puts a in x and b in y.}}
  {{What does `{*}$list` do?} {Spreads the items of the list as separate arguments.}}
  {{How do you read row 1, column 0 of a nested list?} {`lindex $table 1 0`}}
}
}
