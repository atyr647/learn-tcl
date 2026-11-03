content::unit 16 "Algorithms and data structures" "The classic building blocks, implemented in idiomatic Tcl." "#14B8A6"

content::lesson 16.1 16 "Stacks, queues and sets" "Three fundamental structures built from lists and dicts." {
pages {
  {head "Stacks and queues" body {
    p {A **stack** is last-in, first-out: push and pop at the end of a list. A **queue** is first-in, first-out: add at the end, remove from the front. In Tcl both are just lists, and `lappend`, `lindex` and `lrange` are fast.}
    code {set stack {}
lappend stack a
lappend stack b
lappend stack c
puts [lindex $stack end]
set stack [lrange $stack 0 end-1]
puts $stack
set q {}
lappend q x y z
set front [lindex $q 0]
set q [lrange $q 1 end]
puts "$front $q"}
    out {c
a b
x y z}
    p {Popping the top of the stack gave `c`, leaving `a b`. Taking the front of the queue gave `x`, leaving `y z`. Stacks power undo, parsing and recursion; queues power scheduling and breadth-first search.}
  }}
  {head "Sets with dicts" body {
    p {A **set** holds distinct items with fast membership tests. A dict whose values do not matter is a perfect set: keys are unique and `dict exists` is quick.}
    code {proc toset {l} {
    set s {}
    foreach x $l {dict set s $x 1}
    return $s
}
proc inter {a b} {
    set r {}
    dict for {k v} $a {
        if {[dict exists $b $k]} {lappend r $k}
    }
    return $r
}
proc union {a b} {dict keys [dict merge $a $b]}
set a [toset {1 2 3 4}]
set b [toset {3 4 5}]
puts [inter $a $b]
puts [union $a $b]
puts [dict exists $a 2]}
    out {3 4
1 2 3 4 5
1}
    p {For tiny lists, `lsearch` or the `in` operator is fine. For large collections searched repeatedly, convert to a dict once: each test is then constant time instead of scanning.}
  }}
  {head "Sorted insertion and how fast is it?" body {
    p {`lsearch -bisect` does a **binary search** on a sorted list and returns the position of the last item that is not greater than the value. That makes it easy to keep a list sorted as you insert, which is a simple priority queue.}
    code {set pq {}
foreach x {5 1 4 2 3} {
    set i [expr {[lsearch -bisect -integer $pq $x] + 1}]
    set pq [linsert $pq $i $x]
}
puts $pq}
    out {1 2 3 4 5}
    p {Computer scientists describe cost with **Big-O**: appending to a list or reading by index is O(1); `lsearch` on an unsorted list is O(n) (grows with the length); a dict lookup is about O(1); a binary search is O(log n).}
    tip {Choose the structure by the operation you do most: lookups by key want a dict, ordered traversal wants a sorted list, "latest first" wants a stack, "oldest first" wants a queue.}
  }}
}
ex {
  {kind predict code {set s {}
lappend s 1 2 3
set s [lrange $s 0 end-1]
puts $s} choices {{1 2} {2 3} {1 2 3} {3}} ans 0 why {Popping the last item.}}
  {kind predict code {set q {a b c}
set q [lrange $q 1 end]
puts $q} choices {{b c} {a b} {c} {a c}} ans 0 why {Removing the front item.}}
  {kind predict code {set s {}
foreach x {a b a c b} {dict set s $x 1}
puts [dict size $s]} choices {3 5 2 1} ans 0 why {A dict keeps each key once.}}
  {kind predict code {set pq {}
foreach x {3 1 2} {
    set i [expr {[lsearch -bisect -integer $pq $x] + 1}]
    set pq [linsert $pq $i $x]
}
puts $pq} choices {{1 2 3} {3 1 2} {3 2 1} {1 3 2}} ans 0 why {Each value is inserted in sorted position.}}
  {kind predict code {puts [lsearch -bisect -integer {1 3 5 7} 4]} choices {1 2 0 -1} ans 0 why {The last item not greater than 4 is 3, at index 1.}}
  {kind mc q {Which structure undoes the most recent action first?} choices {stack queue set dict} ans 0 why {Last in, first out.}}
  {kind mc q {Why convert a big list to a dict before many membership tests?} choices {{A dict lookup does not scan the whole collection} {Dicts are smaller} {Lists cannot be searched} {It sorts the data}} ans 0 why {O(1) versus O(n) per test.}}
  {kind mc q {What is the cost of `lsearch` on an unsorted list of n items?} choices {{O(n)} {O(1)} {O(log n)} {O(n squared)}} ans 0 why {It may have to look at every item.}}
  {kind code prompt {Write a proc **balanced** returning 1 if the brackets `( ) [ ] { }` in a string are properly nested and closed, else 0 (use a stack). Other characters are ignored.} starter {proc balanced {s} {
    return 1
}} solution {proc balanced {s} {
    set pairs {) ( ] [ \} \{}
    set stack {}
    foreach c [split $s ""] {
        if {$c in {( [ \{}} {
            lappend stack $c
        } elseif {[dict exists $pairs $c]} {
            if {[llength $stack] == 0 || [lindex $stack end] ne [dict get $pairs $c]} {return 0}
            set stack [lrange $stack 0 end-1]
        }
    }
    return [expr {[llength $stack] == 0}]
}} tests {{balanced {(a[b]{c})}} 1 {balanced {(]}} 0 {balanced {((}} 0 {balanced {}} 1} why {Push openers; each closer must match the top of the stack.}}
  {kind code prompt {Write a proc **uniq** that removes duplicates from a list but keeps the **first-seen order** (use a dict as a set).} starter {proc uniq {l} {
    return $l
}} solution {proc uniq {l} {
    set seen {}
    set r {}
    foreach x $l {
        if {![dict exists $seen $x]} {
            dict set seen $x 1
            lappend r $x
        }
    }
    return $r
}} tests {{uniq {b a b c a}} {b a c} {uniq {}} {}} why {`lsort -unique` would reorder; the set keeps order while testing membership fast.}}
  {kind code prompt {Write a proc **intersect** returning the items common to two lists, in the order of the first, without duplicates.} starter {proc intersect {a b} {
    return {}
}} solution {proc intersect {a b} {
    set inb {}
    foreach x $b {dict set inb $x 1}
    set seen {}
    set r {}
    foreach x $a {
        if {[dict exists $inb $x] && ![dict exists $seen $x]} {
            dict set seen $x 1
            lappend r $x
        }
    }
    return $r
}} tests {{intersect {a b c b} {b c d}} {b c} {intersect {x} {y}} {}} why {Put one list into a set for fast lookup, then scan the other.}}
  {kind code prompt {Write a proc **rotate** that moves the first item of a list to the end, n times: `rotate {a b c d} 1` is `b c d a`.} starter {proc rotate {l n} {
    return $l
}} solution {proc rotate {l n} {
    set len [llength $l]
    if {$len == 0} {return $l}
    set n [expr {$n % $len}]
    return [concat [lrange $l $n end] [lrange $l 0 [expr {$n - 1}]]]
}} tests {{rotate {a b c d} 1} {b c d a} {rotate {a b c d} 5} {b c d a} {rotate {} 3} {}} why {Split at position n and swap the two halves; use modulo for large n.}}
}
cards {
  {{What are a stack and a queue?} {Stack: last in, first out (push/pop at the end). Queue: first in, first out (add at the end, remove from the front).}}
  {{How do you make a set in Tcl?} {A dict with keys as members: `dict set s $x 1`; test with `dict exists`.}}
  {{What does `lsearch -bisect` do?} {Binary search in a sorted list: the index of the last item not greater than the value.}}
  {{What does O(n) mean?} {The cost grows in proportion to the number of items.}}
}
}

content::lesson 16.2 16 "Searching and sorting" "Binary search and the classic sorting algorithms." {
pages {
  {head "Binary search" body {
    p {A **linear search** checks every item. If the list is **sorted** you can do far better: look at the middle; if the target is smaller, search the left half; otherwise the right half. Each step halves the problem, so a million items need only about 20 steps.}
    code {proc binsearch {l target} {
    set lo 0
    set hi [expr {[llength $l] - 1}]
    while {$lo <= $hi} {
        set mid [expr {($lo + $hi) / 2}]
        set v [lindex $l $mid]
        if {$v == $target} {
            return $mid
        } elseif {$v < $target} {
            set lo [expr {$mid + 1}]
        } else {
            set hi [expr {$mid - 1}]
        }
    }
    return -1
}
puts [binsearch {1 3 5 7 9 11} 7]
puts [binsearch {1 3 5 7 9 11} 4]}
    out {3
-1}
    p {The interval `lo .. hi` always contains the target if it is present. When it becomes empty, the target is not there.}
  }}
  {head "Simple sorts" body {
    p {**Insertion sort** builds a sorted prefix by sliding each new item into place. It is simple and fast for short or nearly-sorted lists, but O(n squared) in general. (You will almost never write your own - `lsort` is fast and stable - but implementing sorts teaches how algorithms work.)}
    code {proc insertion {l} {
    set r {}
    foreach x $l {
        set i [llength $r]
        while {$i > 0 && [lindex $r [expr {$i - 1}]] > $x} {incr i -1}
        set r [linsert $r $i $x]
    }
    return $r
}
puts [insertion {5 2 9 1 5 6}]}
    out {1 2 5 5 6 9}
    p {Each item is inserted at the position where everything before it is not larger.}
  }}
  {head "Divide and conquer" body {
    p {**Merge sort** splits the list in half, sorts each half recursively, then merges the two sorted halves. It is O(n log n). **Quicksort** picks a pivot and partitions the rest into smaller and larger parts.}
    code {proc mergesort {l} {
    if {[llength $l] <= 1} {return $l}
    set mid [expr {[llength $l] / 2}]
    set a [mergesort [lrange $l 0 [expr {$mid - 1}]]]
    set b [mergesort [lrange $l $mid end]]
    set r {}
    while {[llength $a] && [llength $b]} {
        if {[lindex $a 0] <= [lindex $b 0]} {
            lappend r [lindex $a 0]; set a [lrange $a 1 end]
        } else {
            lappend r [lindex $b 0]; set b [lrange $b 1 end]
        }
    }
    return [concat $r $a $b]
}
proc quicksort {l} {
    if {[llength $l] <= 1} {return $l}
    set p [lindex $l 0]
    set rest [lrange $l 1 end]
    set small [lmap x $rest {if {$x < $p} {set x} else continue}]
    set big [lmap x $rest {if {$x >= $p} {set x} else continue}]
    return [concat [quicksort $small] $p [quicksort $big]]
}
puts [mergesort {5 2 9 1 5 6}]
puts [quicksort {5 2 9 1 5 6}]}
    out {1 2 5 5 6 9
1 2 5 5 6 9}
    tip {Both rely on recursion with a base case (a list of 0 or 1 items is already sorted) and on combining smaller solutions. That pattern solves a huge range of problems.}
  }}
}
ex {
  {kind predict code {proc bs {l t} {
    set lo 0; set hi [expr {[llength $l] - 1}]
    while {$lo <= $hi} {
        set m [expr {($lo + $hi) / 2}]
        set v [lindex $l $m]
        if {$v == $t} {return $m} elseif {$v < $t} {set lo [expr {$m + 1}]} else {set hi [expr {$m - 1}]}
    }
    return -1
}
puts [bs {2 4 6 8} 8]} choices {3 2 1 -1} ans 0 why {8 is at index 3.}}
  {kind predict code {proc ins {l} {
    set r {}
    foreach x $l {
        set i [llength $r]
        while {$i > 0 && [lindex $r [expr {$i - 1}]] > $x} {incr i -1}
        set r [linsert $r $i $x]
    }
    return $r
}
puts [ins {3 1 2}]} choices {{1 2 3} {3 2 1} {3 1 2} {1 3 2}} ans 0 why {Sorted ascending.}}
  {kind predict code {puts [lsort -integer {10 9 100 1}]} choices {{1 9 10 100} {1 10 100 9} {100 10 9 1} {9 10 100 1}} ans 0 why {The built-in sort already does this, fast.}}
  {kind mc q {Why does binary search need a sorted list?} choices {{Each comparison discards half the remaining items only if order is known} {It is faster on unsorted lists} {It sorts the list first} {Sorting is optional}} ans 0 why {Order lets us rule out a whole half.}}
  {kind mc q {What is the typical cost of merge sort?} choices {{O(n log n)} {O(n)} {O(n squared)} {O(1)}} ans 0 why {log n levels of splitting, n work per level.}}
  {kind mc q {What is the base case of recursive sorting?} choices {{A list with 0 or 1 items is already sorted} {A list of 100 items} {The largest item} {The first item}} ans 0 why {Without a base case recursion never stops.}}
  {kind code prompt {Write a proc **binsearch** returning the index of a target in a sorted list, or -1.} starter {proc binsearch {l target} {
    return -1
}} solution {proc binsearch {l target} {
    set lo 0
    set hi [expr {[llength $l] - 1}]
    while {$lo <= $hi} {
        set mid [expr {($lo + $hi) / 2}]
        set v [lindex $l $mid]
        if {$v == $target} {return $mid}
        if {$v < $target} {set lo [expr {$mid + 1}]} else {set hi [expr {$mid - 1}]}
    }
    return -1
}} tests {{binsearch {1 3 5 7 9} 9} 4 {binsearch {1 3 5 7 9} 1} 0 {binsearch {1 3 5} 4} -1 {binsearch {} 1} -1} why {Halve the interval each time.}}
  {kind code prompt {Write a proc **bubblesort** returning the list sorted ascending using repeated swaps of neighbours that are out of order.} starter {proc bubblesort {l} {
    return $l
}} solution {proc bubblesort {l} {
    set n [llength $l]
    for {set i 0} {$i < $n} {incr i} {
        for {set j 0} {$j < $n - $i - 1} {incr j} {
            set a [lindex $l $j]
            set b [lindex $l [expr {$j + 1}]]
            if {$a > $b} {
                lset l $j $b
                lset l [expr {$j + 1}] $a
            }
        }
    }
    return $l
}} tests {{bubblesort {5 2 9 1}} {1 2 5 9} {bubblesort {}} {} {bubblesort {1}} 1} why {After each pass the largest remaining item has "bubbled" to its place.}}
  {kind code prompt {Write a recursive proc **quicksort** returning the list sorted ascending (first item as the pivot).} starter {proc quicksort {l} {
    return $l
}} solution {proc quicksort {l} {
    if {[llength $l] <= 1} {return $l}
    set p [lindex $l 0]
    set rest [lrange $l 1 end]
    set small [lmap x $rest {if {$x < $p} {set x} else continue}]
    set big [lmap x $rest {if {$x >= $p} {set x} else continue}]
    return [concat [quicksort $small] $p [quicksort $big]]
}} tests {{quicksort {3 1 4 1 5 9 2 6}} {1 1 2 3 4 5 6 9} {quicksort {}} {}} why {Partition around the pivot, recurse on each side, join.}}
  {kind code prompt {Write a proc **mergelists** that merges two already-sorted lists into one sorted list.} starter {proc mergelists {a b} {
    return {}
}} solution {proc mergelists {a b} {
    set r {}
    while {[llength $a] && [llength $b]} {
        if {[lindex $a 0] <= [lindex $b 0]} {
            lappend r [lindex $a 0]
            set a [lrange $a 1 end]
        } else {
            lappend r [lindex $b 0]
            set b [lrange $b 1 end]
        }
    }
    return [concat $r $a $b]
}} tests {{mergelists {1 4 9} {2 3 10}} {1 2 3 4 9 10} {mergelists {} {5}} 5} why {Repeatedly take the smaller front item.}}
}
cards {
  {{How does binary search work?} {On a sorted list, compare with the middle and discard the half that cannot contain the target; repeat. O(log n).}}
  {{How does merge sort work?} {Split in half, sort each half recursively, merge the sorted halves. O(n log n).}}
  {{Should you write your own sort in practice?} {No - `lsort` is fast, stable and flexible; implementing sorts is for understanding.}}
}
}

content::lesson 16.3 16 "Recursion, memoisation and dynamic programming" "Solve big problems by solving smaller ones - once." {
pages {
  {head "Recursion patterns" body {
    p {Recursion shines when a problem contains smaller copies of itself: **permutations** (fix one item, permute the rest), the **Towers of Hanoi** (move n-1 discs out of the way, move the biggest, move n-1 back), **tree walking**.}
    code {proc perms {l} {
    if {[llength $l] <= 1} {return [list $l]}
    set r {}
    for {set i 0} {$i < [llength $l]} {incr i} {
        set x [lindex $l $i]
        set rest [lreplace $l $i $i]
        foreach p [perms $rest] {lappend r [linsert $p 0 $x]}
    }
    return $r
}
puts [perms {a b c}]
proc hanoi {n} {
    if {$n == 0} {return 0}
    return [expr {2 * [hanoi [expr {$n - 1}]] + 1}]
}
puts [hanoi 5]}
    out {{a b c} {a c b} {b a c} {b c a} {c a b} {c b a}
31}
    p {Hanoi needs 2^n - 1 moves: 31 for five discs.}
  }}
  {head "Memoisation" body {
    p {Plain recursive Fibonacci recomputes the same values exponentially many times. **Memoisation** caches each result the first time. In Tcl a dict (or array) is the cache.}
    code {set memo {0 0 1 1}
proc fib {n} {
    global memo
    if {[dict exists $memo $n]} {return [dict get $memo $n]}
    set v [expr {[fib [expr {$n - 1}]] + [fib [expr {$n - 2}]]}]
    dict set memo $n $v
    return $v
}
puts [fib 10]
puts [fib 90]}
    out {55
2880067194370816120}
    p {Without the cache `fib 90` would take longer than the age of the universe; with it, it is instant. Each value is computed exactly once.}
  }}
  {head "Dynamic programming" body {
    p {**Dynamic programming** builds the answer from the bottom up, filling a table of sub-answers. Example: the fewest coins that make an amount. `best(a)` is 1 plus the smaller of `best(a - coin)` over the coins.}
    code {proc mincoins {coins amount} {
    set best [dict create 0 0]
    for {set a 1} {$a <= $amount} {incr a} {
        set b 1000000
        foreach c $coins {
            if {$c <= $a && [dict exists $best [expr {$a - $c}]]} {
                set t [expr {[dict get $best [expr {$a - $c}]] + 1}]
                if {$t < $b} {set b $t}
            }
        }
        if {$b < 1000000} {dict set best $a $b}
    }
    if {[dict exists $best $amount]} {return [dict get $best $amount]}
    return -1
}
puts [mincoins {1 5 10 25} 63]
puts [mincoins {5 10} 3]}
    out {6
-1}
    tip {The recipe: define the sub-problem, write the relation between a problem and its smaller ones, decide the order to fill the table, and store results so nothing is computed twice.}
  }}
}
ex {
  {kind predict code {proc hanoi {n} {
    if {$n == 0} {return 0}
    return [expr {2 * [hanoi [expr {$n - 1}]] + 1}]
}
puts [hanoi 3]} choices {7 8 6 3} ans 0 why {2^3 - 1 = 7 moves.}}
  {kind predict code {set memo {0 0 1 1}
proc fib {n} {
    global memo
    if {[dict exists $memo $n]} {return [dict get $memo $n]}
    set v [expr {[fib [expr {$n - 1}]] + [fib [expr {$n - 2}]]}]
    dict set memo $n $v
    return $v
}
puts [fib 12]} choices {144 89 233 55} ans 0 why {The 12th Fibonacci number.}}
  {kind predict code {proc perms {l} {
    if {[llength $l] <= 1} {return [list $l]}
    set r {}
    for {set i 0} {$i < [llength $l]} {incr i} {
        set x [lindex $l $i]
        foreach p [perms [lreplace $l $i $i]] {lappend r [linsert $p 0 $x]}
    }
    return $r
}
puts [llength [perms {1 2 3 4}]]} choices {24 12 16 4} ans 0 why {4! = 24 permutations.}}
  {kind mc q {What does memoisation do?} choices {{Caches results so each sub-problem is computed once} {Sorts the data} {Makes recursion iterative} {Frees memory}} ans 0 why {Trading memory for time.}}
  {kind mc q {Why is plain recursive Fibonacci slow?} choices {{It recomputes the same sub-problems exponentially many times} {Recursion is always slow} {Tcl has no stack} {It uses floats}} ans 0 why {fib(n) calls fib(n-1) and fib(n-2), which overlap heavily.}}
  {kind mc q {What is dynamic programming?} choices {{Building answers bottom-up from a table of smaller sub-answers} {Changing code while it runs} {A kind of loop} {Dynamic typing}} ans 0 why {Store sub-answers so nothing is recomputed.}}
  {kind code prompt {Write a recursive proc **power** with `power base exp` for whole exponents using repeated squaring: if exp is even, power(base, exp/2) squared; if odd, base times power(base, exp-1).} starter {proc power {b e} {
    return 1
}} solution {proc power {b e} {
    if {$e == 0} {return 1}
    if {$e % 2 == 0} {
        set h [power $b [expr {$e / 2}]]
        return [expr {$h * $h}]
    }
    return [expr {$b * [power $b [expr {$e - 1}]]}]
}} tests {{power 2 10} 1024 {power 3 0} 1 {power 5 3} 125} why {Squaring halves the exponent each step: O(log n) multiplications.}}
  {kind code prompt {Write a proc **fibmemo** using a dict named `memo` kept in the proc's own namespace-free way: pass the memo as a variable name (upvar). `fibmemo n memoVar` returns the nth Fibonacci number and fills the dict.} starter {proc fibmemo {n memoVar} {
    return 0
}} solution {proc fibmemo {n memoVar} {
    upvar 1 $memoVar memo
    if {$n < 2} {return $n}
    if {[dict exists $memo $n]} {return [dict get $memo $n]}
    set v [expr {[fibmemo [expr {$n - 1}] memo] + [fibmemo [expr {$n - 2}] memo]}]
    dict set memo $n $v
    return $v
}} tests {{set m {}; fibmemo 30 m} 832040 {set m {}; fibmemo 50 m} 12586269025} why {The memo dict is shared by name, so every recursive call reuses it.}}
  {kind code prompt {Write a proc **subsets** returning all subsets of a list (as a list of lists), including the empty set; order: for `{a b}` give `{} a b {a b}`.} starter {proc subsets {l} {
    return {}
}} solution {proc subsets {l} {
    set r [list {}]
    foreach x $l {
        foreach s $r {lappend new [concat $s $x]}
        foreach s $new {lappend r $s}
        unset new
    }
    return $r
}} tests {{subsets {a b}} {{} a b {a b}} {subsets {}} {{}} {llength [subsets {1 2 3 4}]} 16} why {Each new item doubles the collection: keep the old subsets and add copies containing the item.}}
  {kind code prompt {Write a proc **mincoins** (dynamic programming) returning the fewest coins from a list that make an amount, or -1 if impossible.} starter {proc mincoins {coins amount} {
    return -1
}} solution {proc mincoins {coins amount} {
    set best [dict create 0 0]
    for {set a 1} {$a <= $amount} {incr a} {
        set b 1000000
        foreach c $coins {
            if {$c <= $a && [dict exists $best [expr {$a - $c}]]} {
                set t [expr {[dict get $best [expr {$a - $c}]] + 1}]
                if {$t < $b} {set b $t}
            }
        }
        if {$b < 1000000} {dict set best $a $b}
    }
    if {[dict exists $best $amount]} {return [dict get $best $amount]}
    return -1
}} tests {{mincoins {1 5 10 25} 63} 6 {mincoins {5 10} 3} -1 {mincoins {2} 0} 0} why {Fill the table from small amounts upward.}}
}
cards {
  {{What is memoisation?} {Caching a function's results (e.g. in a dict) so each sub-problem is computed only once.}}
  {{What is the Towers of Hanoi move count?} {2^n - 1 for n discs.}}
  {{What are the steps of dynamic programming?} {Define the sub-problem, write the recurrence, fill a table in a sensible order, read off the answer.}}
}
}

content::lesson 16.4 16 "Trees and graphs" "Nested data, walks, and finding paths." {
pages {
  {head "Trees" body {
    p {A **tree** is a value with child trees. In Tcl a natural representation is a list: `{value child child ...}` where each child is itself such a list. Recursion follows the structure exactly.}
    code {set tree {1 {2 {4} {5}} {3 {6}}}
proc sum {t} {
    set total [lindex $t 0]
    foreach child [lrange $t 1 end] {incr total [sum $child]}
    return $total
}
proc depth {t} {
    set d 0
    foreach child [lrange $t 1 end] {
        set cd [depth $child]
        if {$cd > $d} {set d $cd}
    }
    return [expr {$d + 1}]
}
puts [sum $tree]
puts [depth $tree]}
    out {21
3}
    p {1 + 2 + 3 + 4 + 5 + 6 = 21; the longest path from the root has 3 levels.}
  }}
  {head "Graphs" body {
    p {A **graph** is nodes joined by edges. An **adjacency dict** maps each node to its neighbours. Walking a graph needs a record of visited nodes so cycles do not trap you.}
    code {set g {a {b c} b {d} c {d} d {}}
proc dfs {g node} {
    set seen {}
    set stack [list $node]
    while {[llength $stack]} {
        set n [lindex $stack end]
        set stack [lrange $stack 0 end-1]
        if {$n in $seen} continue
        lappend seen $n
        foreach m [lreverse [dict get $g $n]] {lappend stack $m}
    }
    return $seen
}
puts [dfs $g a]}
    out {a b d c}
    p {**Depth-first search** follows one branch to the end before backing up; it uses a **stack**.}
  }}
  {head "Shortest paths" body {
    p {**Breadth-first search** explores in rings around the start, using a **queue**; the first time it reaches a node is along a shortest path (counting edges).}
    code {set g {a {b c} b {d} c {d} d {e} e {}}
proc shortest {g from to} {
    set queue [list [list $from]]
    set seen [list $from]
    while {[llength $queue]} {
        set path [lindex $queue 0]
        set queue [lrange $queue 1 end]
        set n [lindex $path end]
        if {$n eq $to} {return $path}
        foreach m [dict get $g $n] {
            if {$m ni $seen} {
                lappend seen $m
                lappend queue [concat $path $m]
            }
        }
    }
    return {}
}
puts [shortest $g a e]
puts [shortest $g e a]}
    out {a b d e}
    tip {Route planning, dependency resolution, web crawling, social networks - all are graph problems. Learn BFS and DFS well and many hard-looking tasks become routine.}
  }}
}
ex {
  {kind predict code {set tree {5 {3} {2 {1}}}
proc sum {t} {
    set s [lindex $t 0]
    foreach c [lrange $t 1 end] {incr s [sum $c]}
    return $s
}
puts [sum $tree]} choices {11 10 8 5} ans 0 why {5 + 3 + 2 + 1.}}
  {kind predict code {set g {a {b} b {c} c {}}
set seen {}
set n a
while {1} {
    lappend seen $n
    set next [dict get $g $n]
    if {$next eq ""} break
    set n [lindex $next 0]
}
puts $seen} choices {{a b c} {c b a} {a c} {a}} ans 0 why {Following the only edge each time.}}
  {kind mc q {Which data structure does depth-first search use?} choices {stack queue set heap} ans 0 why {A stack (or recursion) takes the most recent branch first.}}
  {kind mc q {Which does breadth-first search use?} choices {queue stack tree dict} ans 0 why {A queue explores in rings around the start.}}
  {kind mc q {Why keep a visited set when walking a graph?} choices {{Cycles would otherwise make the walk loop forever} {To sort the nodes} {To save memory} {Dicts require it}} ans 0 why {Seeing a node twice means a cycle.}}
  {kind code prompt {Write a proc **treesize** counting the nodes of a tree in the `{value child...}` representation.} starter {proc treesize {t} {
    return 0
}} solution {proc treesize {t} {
    set n 1
    foreach c [lrange $t 1 end] {incr n [treesize $c]}
    return $n
}} tests {{treesize {1 {2 {4} {5}} {3 {6}}}} 6 {treesize {x}} 1} why {One for this node plus the sizes of the children.}}
  {kind code prompt {Write a proc **leaves** returning the values of the leaf nodes (nodes with no children), left to right.} starter {proc leaves {t} {
    return {}
}} solution {proc leaves {t} {
    set kids [lrange $t 1 end]
    if {[llength $kids] == 0} {return [list [lindex $t 0]]}
    set r {}
    foreach c $kids {lappend r {*}[leaves $c]}
    return $r
}} tests {{leaves {1 {2 {4} {5}} {3 {6}}}} {4 5 6} {leaves {x}} x} why {A node with no children is a leaf; otherwise collect from each child.}}
  {kind code prompt {Write a proc **reachable** taking an adjacency dict and a start node, returning the sorted list of all nodes reachable from it (including itself).} starter {proc reachable {g start} {
    return {}
}} solution {proc reachable {g start} {
    set seen {}
    set todo [list $start]
    while {[llength $todo]} {
        set n [lindex $todo 0]
        set todo [lrange $todo 1 end]
        if {$n in $seen} continue
        lappend seen $n
        if {[dict exists $g $n]} {
            foreach m [dict get $g $n] {lappend todo $m}
        }
    }
    return [lsort $seen]
}} tests {{reachable {a {b c} b {d} c {} d {} e {a}} a} {a b c d} {reachable {a {b} b {a}} a} {a b}} why {Walk with a visited list so cycles terminate.}}
  {kind code prompt {Write a proc **hasPath** returning 1 if there is a path from one node to another in an adjacency dict, else 0.} starter {proc hasPath {g from to} {
    return 0
}} solution {proc hasPath {g from to} {
    set seen {}
    set todo [list $from]
    while {[llength $todo]} {
        set n [lindex $todo 0]
        set todo [lrange $todo 1 end]
        if {$n eq $to} {return 1}
        if {$n in $seen} continue
        lappend seen $n
        if {[dict exists $g $n]} {lappend todo {*}[dict get $g $n]}
    }
    return 0
}} tests {{hasPath {a {b} b {c} c {}} a c} 1 {hasPath {a {b} b {c} c {}} c a} 0 {hasPath {a {a}} a a} 1} why {Search until the target is found or nothing is left to visit.}}
}
cards {
  {{How can you represent a tree in Tcl?} {A nested list: `{value child child ...}`; recursion follows the structure.}}
  {{How do DFS and BFS differ?} {DFS uses a stack and goes deep first; BFS uses a queue and finds shortest paths by edge count.}}
  {{Why track visited nodes?} {To avoid looping forever in graphs with cycles.}}
}
}
