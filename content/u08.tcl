content::unit 8 "Dictionaries and arrays" "Look things up by name: Tcl's key-value data structures." "#C084FC"

content::lesson 8.1 8 "Dictionaries" "Store values under names, like a tiny database." {
pages {
  {head "Keys and values" body {
    p {A **dictionary** (dict) stores **values** under **keys**. Instead of "item number 3" you ask for "the value named age".}
    code {set person [dict create name Ada age 36]
puts [dict get $person name]
dict set person city London
puts [dict size $person]
puts [dict exists $person age]}
    out {Ada
3
1}
    p {- `dict get $d key` reads a value
- `dict set d key value` changes or adds (note: variable **name**, no `$`)
- `dict exists $d key` tests for a key
- `dict size $d` counts the entries}
  }}
  {head "Going through a dict" body {
    p {`dict for` visits every key and value, in the order they were added.}
    code {dict for {k v} {a 1 b 2 c 3} {
    puts "$k -> $v"
}}
    out {a -> 1
b -> 2
c -> 3}
    code {set d {x 10 y 20}
puts [dict keys $d]
puts [dict values $d]}
    out {x y
10 20}
  }}
  {head "Counting with dicts" body {
    p {`dict incr` adds to a number stored under a key, and creates it at zero if it is missing. That makes counting things easy:}
    code {set counts {}
foreach w {a b a c a b} {
    dict incr counts $w
}
puts $counts}
    out {a 3 b 2 c 1}
    p {Other useful commands: `dict unset d key` removes a key, `dict merge $a $b` combines two dicts, and `dict lappend d key item` adds to a list stored under a key.}
    tip {A dict is just a list with an even number of items, key then value. That is why you can print one with `puts`.}
  }}
}
ex {
  {kind predict code {set d [dict create a 1 b 2]
puts [dict get $d b]} choices {2 1 b a} ans 0 why {The value stored under key `b` is 2.}}
  {kind predict code {set d {}
dict set d x 5
dict set d y 6
puts [dict size $d]} choices {2 0 5 1} ans 0 why {Two keys were added.}}
  {kind predict code {set d {k 1}
puts [dict exists $d z]} choices {0 1 k {}} ans 0 why {There is no key `z`.}}
  {kind predict code {set c {}
foreach x {p q p} {dict incr c $x}
puts [dict get $c p]} choices {2 1 3 p} ans 0 why {`p` was counted twice.}}
  {kind predict code {set d {a 1 b 2}
dict set d a 9
puts $d} choices {{a 9 b 2} {a 1 b 2} {a 9} {a 1 b 9}} ans 0 why {`dict set` replaces the value of an existing key.}}
  {kind predict code {puts [dict keys {one 1 two 2}]} choices {{one two} {1 2} {one 1} {two one}} ans 0 why {`dict keys` lists the keys.}}
  {kind blank q {Read the value stored under the key colour.} code {set car {colour red wheels 4}
puts [___ get $car colour]} answers {dict} extra {list array string} out {red} why {`dict get dictionary key`.}}
  {kind mc q {Why is `dict set` written without a dollar sign?} choices {{It needs the variable's name, because it changes the variable} {It is a mistake} {Dollar signs are not allowed in dicts} {Only in Tcl 9}} ans 0 why {Like `append`, `lappend` and `incr`, `dict set` modifies a variable so it needs the name.}}
  {kind type q {Which command visits every key and value in a dict?} accept {dict for} why {`dict for {k v} $d {...}`.}}
  {kind code prompt {Write a proc **tally** that takes a list of words and returns a dict of how many times each appears.} starter {proc tally {words} {
    set counts {}
    return $counts
}} solution {proc tally {words} {
    set counts {}
    foreach w $words {dict incr counts $w}
    return $counts
}} tests {{tally {a b a}} {a 2 b 1} {tally {}} {}} why {`dict incr` creates the key at zero if needed, so each word is simply incremented.}}
}
cards {
  {{What is a dict?} {A collection of values stored under keys: `dict create name Ada age 36`.}}
  {{How do you read, add and test keys?} {`dict get $d k`, `dict set d k v`, `dict exists $d k`.}}
  {{How do you loop over a dict?} {`dict for {k v} $d {...}`}}
  {{What does `dict incr counts $word` do?} {Adds 1 to the count stored under that key, starting from 0 if it does not exist.}}
}
}

content::lesson 8.2 8 "Nested data and transformations" "Dicts inside dicts, and ways to reshape them." {
pages {
  {head "Dicts inside dicts" body {
    p {A value can be another dict. Give `dict set` and `dict get` a **path** of keys to reach inside.}
    code {set db {}
dict set db ada age 36
dict set db ada lang Tcl
dict set db bob age 25
puts [dict get $db ada lang]
puts [dict keys $db]
puts $db}
    out {Tcl
ada bob
ada {age 36 lang Tcl} bob {age 25}}
    p {This is how Tcl programs hold records: a dict of users, each user a dict of fields.}
  }}
  {head "map, filter and with" body {
    p {`dict map` builds a new dict by running code on each value. `dict filter` keeps entries that pass a test.}
    code {set stock {apple 3 pear 0 fig 7}
puts [dict map {k v} $stock {expr {$v * 10}}]
puts [dict filter $stock script {k v} {expr {$v > 0}}]}
    out {apple 30 pear 0 fig 70
apple 3 fig 7}
    p {`dict with` temporarily turns every key into a variable, which is handy for working with a record:}
    code {set user {name Ada age 36}
dict with user {
    puts "$name is $age"
    incr age
}
puts $user}
    out {Ada is 36
name Ada age 37}
  }}
  {head "Sorted output" body {
    p {A dict remembers the order keys were added. To print it in alphabetical order, sort the keys first.}
    code {set d {pear 2 apple 5 fig 1}
foreach k [lsort [dict keys $d]] {
    puts "$k=[dict get $d $k]"
}}
    out {apple=5
fig=1
pear=2}
    tip {Work out how your data is shaped first - "a list of records" or "a dict of records" - and the code usually falls into place.}
  }}
}
ex {
  {kind predict code {set db {}
dict set db ann age 31
puts [dict get $db ann age]} choices {31 ann age {age 31}} ans 0 why {A key path reaches inside the nested dict.}}
  {kind predict code {set d {a 1 b 2}
puts [dict map {k v} $d {expr {$v + 100}}]} choices {{a 101 b 102} {101 102} {a 1 b 2} {a 100 b 100}} ans 0 why {`dict map` keeps the keys and replaces each value with the result.}}
  {kind predict code {puts [dict filter {a 1 b 5 c 9} script {k v} {expr {$v > 3}}]} choices {{b 5 c 9} {a 1} {a 1 b 5} {c 9}} ans 0 why {Only entries whose value is greater than 3 survive.}}
  {kind predict code {set p {x 3 y 4}
dict with p {
    puts [expr {$x * $y}]
}} choices {12 7 {3 4} y} ans 0 why {`dict with` makes `x` and `y` into variables inside the body.}}
  {kind predict code {set d {b 2 a 1}
foreach k [lsort [dict keys $d]] {puts $k}} choices {"a\nb" "b\na" "1\n2" "ab"} ans 0 why {Sorted keys give a, then b.}}
  {kind mc q {How would you store several users, each with a name and an age?} choices {{A dict whose values are dicts} {One long string} {Several unrelated variables} {A single number}} ans 0 why {Nested dicts - the key is the user and the value is the record - model this naturally.}}
  {kind blank q {Keep only the entries whose value is above zero.} code {puts [dict ___ {a 0 b 2} script {k v} {expr {$v > 0}}]} answers {filter} extra {map with get} out {b 2} why {`dict filter` returns the entries that pass the test.}}
  {kind type q {Which command turns the keys of a dict into variables inside a body?} accept {dict with} why {`dict with`.}}
  {kind code prompt {Write a proc **oldest** that takes a dict mapping names to ages and returns the name with the highest age.} starter {proc oldest {people} {
    return
}} solution {proc oldest {people} {
    set best ""
    set max -1
    dict for {name age} $people {
        if {$age > $max} {set max $age; set best $name}
    }
    return $best
}} tests {{oldest {ann 31 bob 25 cy 40}} cy {oldest {z 1}} z} why {Remember the highest age so far and the name that goes with it.}}
}
cards {
  {{How do you set and read a value in a nested dict?} {`dict set d outer inner value` and `dict get $d outer inner`.}}
  {{What do `dict map` and `dict filter` do?} {`map` transforms each value into a new dict; `filter` keeps entries that pass a test.}}
  {{What does `dict with` do?} {Makes each key of a dict a variable inside its body, and writes changes back.}}
  {{How do you print a dict sorted by key?} {`foreach k [lsort [dict keys $d]] {...}`}}
}
}

content::lesson 8.3 8 "Arrays" "Tcl's other lookup table - and how to choose." {
pages {
  {head "Variables with slots" body {
    p {An **array** is a variable with many named slots. Write the key in round brackets after the name.}
    code {set price(apple) 3
set price(pear) 5
puts $price(apple)
puts [array size price]
puts [array exists price]
puts [info exists price(fig)]}
    out {3
2
1
0}
    p {An array is **not** a single value: you cannot write `puts $price`. It is a collection of variables sharing a name.}
  }}
  {head "Working with arrays" body {
    p {`array names` lists the keys (in no guaranteed order, so sort them), `array get` converts to a list of key/value pairs, `array set` fills from such a list, and `unset` removes an element.}
    code {array set stock {apple 3 pear 5 fig 1}
foreach k [lsort [array names stock]] {
    puts "$k: $stock($k)"
}
unset stock(pear)
puts [lsort [array names stock]]}
    out {apple: 3
fig: 1
pear: 5
apple fig}
  }}
  {head "Array or dict?" body {
    p {Both map keys to values. Which should you use?}
    p {- A **dict** is a *value*: you can pass it to a proc, return it, nest it, store it in a list and compare it. **Use dicts by default.**
- An **array** is a *variable*: great for a big table that many parts of a program update in place, but it cannot be passed around by value or nested.}
    tip {Older Tcl code uses arrays a lot, so you will meet them often. Reading them is a must; writing new code with dicts is usually nicer.}
  }}
}
ex {
  {kind predict code {set a(x) 10
puts $a(x)} choices {10 x a {a(x)}} ans 0 why {`$a(x)` reads the slot named x.}}
  {kind predict code {set a(p) 1
set a(q) 2
puts [array size a]} choices {2 1 0 3} ans 0 why {The array has two elements.}}
  {kind predict code {array set m {k 5}
puts $m(k)} choices {5 k m {}} ans 0 why {`array set` created the slot `k` with value 5.}}
  {kind predict code {set s(a) 1
puts [info exists s(b)]} choices {0 1 b a} ans 0 why {There is no slot `b`.}}
  {kind predict code {array set d {b 2 a 1 c 3}
puts [lsort [array names d]]} choices {{a b c} {b a c} {1 2 3} {c b a}} ans 0 why {`array names` returns the keys; `lsort` puts them in order.}}
  {kind mc q {Which is true about dicts compared with arrays?} choices {{A dict is a value that can be passed, returned and nested} {Arrays can be returned from procs} {Dicts cannot hold other dicts} {They are the same thing}} ans 0 why {A dict is an ordinary value, so you can use it anywhere a value is allowed.}}
  {kind blank q {Remove the element named b.} code {array set t {a 1 b 2}
___ t(b)
puts [array names t]} answers {unset} extra {delete remove clear} out {a} why {`unset` deletes a variable or an array element.}}
  {kind type q {Which command lists the keys of an array?} accept {array names} why {`array names arrayName`.}}
  {kind code prompt {Write a proc **sumvalues** that takes an array NAME and returns the total of its values. (Hint: use `upvar 1 $name arr` to reach the caller's array.)} starter {proc sumvalues {name} {
    upvar 1 $name arr
    return 0
}} solution {proc sumvalues {name} {
    upvar 1 $name arr
    set t 0
    foreach k [array names arr] {incr t $arr($k)}
    return $t
}} tests {{array set z {a 1 b 2 c 4}; sumvalues z} 7} why {`upvar 1 $name arr` links `arr` to the caller's array; then loop over `array names`.}}
}
cards {
  {{How do you write an array element?} {`set price(apple) 3` and read it with `$price(apple)`.}}
  {{How do you list an array's keys?} {`array names price` - sort them for a stable order.}}
  {{Dict or array - which by default?} {A dict: it is a normal value you can pass, return and nest.}}
  {{How do you delete an array element?} {`unset price(apple)`}}
}
}
