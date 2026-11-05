content::unit 1 "First steps" "What a program is, and your very first Tcl commands." "#8B7CFF"

content::lesson 1.1 1 "Hello, Tcl" "What a program is, and how to make the computer say something." {
pages {
  {head "What is a program?" body {
    p {A **program** is a list of instructions for a computer, a bit like a recipe. The computer follows the steps one at a time, from top to bottom, and does exactly what you wrote - nothing more, nothing less.}
    p {**Tcl** (say "tickle", short for Tool Command Language) is a programming language created in 1988. It is easy to start with and surprisingly deep: it is used in testing tools, chip design, networking gear - and the screens and buttons of this very app are built with Tcl's toolkit, Tk.}
    tip {By the end of this course you will be able to read and write real Tcl programs. We start at the very beginning, so nothing is assumed.}
  }}
  {head "Your first command" body {
    p {Here is one line of Tcl. The command `puts` (say "put string") prints text on the screen.}
    code {puts "Hello, world!"}
    out {Hello, world!}
    p {The text is wrapped in double quotes so Tcl knows where it starts and ends. The quotes themselves are not printed.}
    tip {Open the **Playground** tab at any time and type this in yourself. Typing code - even code you have just seen - is how it sticks.}
  }}
  {head "More than one line" body {
    p {Tcl runs your lines **in order, top to bottom**.}
    code {puts "First"
puts "Second"
puts "Third"}
    out {First
Second
Third}
    p {Each line is a separate instruction. Change the order of the lines and you change the result.}
  }}
}
ex {
  {kind mc q {What is a program?} choices {{A list of instructions a computer follows} {A kind of computer screen} {A type of keyboard} {A game you download}} ans 0 why {A program is a list of instructions. The computer follows them one by one.}}
  {kind predict code {puts "Hi there"} choices {{Hi there} {"Hi there"} {puts Hi there} {Hi}} ans 0 why {`puts` prints the text. The quotes only mark where the text begins and ends, so they are not printed.}}
  {kind mc q {Which Tcl command prints text on the screen?} choices {puts print echo show} ans 0 why {In Tcl the command is `puts`, short for "put string".}}
  {kind predict code {puts "A"
puts "B"} choices {"A\nB" "B\nA" "AB" "A B"} ans 0 why {Lines run top to bottom, and each `puts` starts a new line of output, so you get A and then B on separate lines.}}
  {kind blank q {Complete the program so it prints Hello, Tcl!} code {___ "Hello, Tcl!"} answers {puts} extra {print echo say} out {Hello, Tcl!} why {`puts` is the command that prints text.}}
  {kind order q {Make the program print One, then Two, then Three.} lines {{puts "One"} {puts "Two"} {puts "Three"}} out {One
Two
Three} why {Tcl runs the lines from top to bottom, so the order of the lines is the order of the output.}}
  {kind type q {Type the command that prints text to the screen.} accept {puts} why {`puts` - "put string".}}
}
cards {
  {{What does `puts` do?} {It prints text on the screen and moves to a new line. The name means "put string".}}
  {{In what order does Tcl run the lines of a program?} {From top to bottom, one at a time.}}
  {{How do you print the words Hello there?} {`puts "Hello there"`}}
  {{What is a program?} {A list of instructions that a computer follows, one step at a time.}}
}
}

content::lesson 1.2 1 "Commands and words" "The one rule that all of Tcl is built on." {
pages {
  {head "A command is a row of words" body {
    p {Every Tcl instruction is called a **command**. A command is just a row of **words** with spaces between them.}
    p {The **first word** is the name of the command: it says what to do. Every word after it is an **argument**: extra information for the command.}
    code {puts "Hello"}
    p {That line has **two words**: `puts` (the command: "print this") and `"Hello"` (the argument: what to print).}
    p {Here is a line with **three words**. You will learn what `set` does in the next unit. For now, just count the words.}
    code {set name Tcl}
    p {The words are `set`, `name` and `Tcl`. The first word is always the command, and the spaces are what cut the line into words.}
    tip {To read any Tcl line: find the spaces, split it into words, and the first word is the command.}
  }}
  {head "Quotes keep words together" body {
    p {A message such as Hello, world! has a space in it. Spaces cut words apart, so Tcl needs help to know the message is **one** thing.}
    p {**Double quotes** are that help. Everything between the quotes counts as **one word**.}
    code {puts "Hello, world!"}
    out {Hello, world!}
    p {Count the words: `puts` and `"Hello, world!"`. That is two words, even though the message contains a space. The quote marks only tell Tcl where the word starts and ends, so they are not printed.}
    p {What if you forget the quotes? The space then cuts the message in two, so Tcl sees **three** words: `puts`, `Hello` and `world`. That is too many for `puts`, and it complains:}
    code {puts Hello world}
    out {can not find channel named "Hello"}
    p {Do not worry about the word "channel" yet. (`puts` can be told *where* to print, such as the screen or a file, and with two things after it, it reads the first as that place.) The lesson is simple: **if your text has a space, put it in quotes.**}
    tip {Error messages are your friend. They usually point straight at the problem, so read them slowly.}
  }}
  {head "Two commands on one line" body {
    p {Normally each command goes on its own line: the end of the line ends the command.}
    code {puts "A"
puts "B"}
    out {A
B}
    p {If you want two commands on **one** line, put a **semicolon** `;` between them. The semicolon means "this command is finished, a new one starts here".}
    code {puts "A"; puts "B"}
    out {A
B}
    p {Both versions do exactly the same thing: print A, then print B, each on its own line, in the order you wrote them. Most of the time one command per line is easier to read, so use `;` sparingly.}
  }}
}
ex {
  {kind mc q {In the line `puts "Hi"`, which word is the command?} choices {puts {"Hi"} {Hi} {The quote marks}} ans 0 why {The first word of a line is always the command name. Everything after it is an argument.}}
  {kind mc q {How many words are in the line `set name Tcl`?} choices {1 2 3 4} ans 2 why {Spaces cut the line into words: `set`, `name` and `Tcl`. That is three.}}
  {kind mc q {How many words are in the line `puts "Hello, world!"`?} choices {1 2 3 4} ans 1 why {Two: `puts`, and the quoted message. The quotes make the message ONE word, even though it contains a space.}}
  {kind mc q {What do double quotes do in Tcl?} choices {{Group several words into one word} {Make text appear in bold} {Start a comment} {Mark a number}} ans 0 why {Inside quotes, spaces no longer cut the text into words, so the whole message is a single word.}}
  {kind mc q {What happens when you run `puts Hello world` (no quotes)?} choices {{It prints Hello world} {It fails: Tcl sees too many words after puts} {It prints Hello only} {It prints nothing at all and succeeds}} ans 1 why {The space cuts the message into two words, which is one too many for `puts`. Fix it with quotes: `puts "Hello world"`.}}
  {kind blank q {Fill in the blanks so that Tcl sees the message as one word.} code {puts ___Good morning___} answers {{"} {"}} extra {{'} {(}} out {Good morning} why {Double quotes make `Good morning` a single word.}}
  {kind mc q {What does the semicolon do in `puts "A"; puts "B"`?} choices {{It ends the first command so a second one can start on the same line} {It joins the two messages into one} {It starts a comment} {It is printed on the screen}} ans 0 why {A semicolon says "this command is finished". The next command then starts straight after it.}}
  {kind predict code {puts "one"; puts "two"} choices {"one\ntwo" "two\none" "one two" onetwo} ans 0 why {Two commands, so two lines of output, running left to right: one, then two.}}
  {kind type q {Which character can separate two commands written on the same line?} accept {; semicolon} hint {It looks like a comma with a dot above it.} why {The semicolon: `puts "A"; puts "B"`.}}
}
cards {
  {{What is a Tcl command made of?} {Words separated by spaces. The first word is the command name; the rest are its arguments.}}
  {{What do double quotes do?} {They group several words into one word (one argument).}}
  {{How can two commands share one line?} {Separate them with a semicolon, for example `puts "A"; puts "B"`.}}
  {{Why does `puts Hello world` fail?} {The space cuts the message into two words, which is too many. Quote the text: `puts "Hello world"`.}}
}
}

content::lesson 1.3 1 "Comments and special characters" "Leave notes for humans, and print tabs, quotes and line breaks." {
pages {
  {head "Notes for humans" body {
    p {A line that begins with `#` is a **comment**. Tcl skips it completely. Comments explain *why* the code does something - they are notes to the next reader (often future you).}
    code {# Greet the user
puts "Hello!"}
    out {Hello!}
    p {To put a comment at the end of a line, you need a semicolon first:}
    code {puts "Hi" ;# this note is ignored}
    out {Hi}
    warn {Without the `;` the `#` would just be another argument to `puts`, because a comment may only start where a command could start.}
  }}
  {head "Special characters" body {
    p {Inside double quotes, a backslash starts an **escape sequence**:}
    p {- `\n` starts a new line
- `\t` inserts a tab
- `\"` prints a quote mark
- `\\` prints one backslash}
    code {puts "Line one\nLine two"}
    out {Line one
Line two}
    code {puts "She said \"hi\""}
    out {She said "hi"}
  }}
  {head "Staying on the same line" body {
    p {Normally `puts` adds a newline at the end. The `-nonewline` option turns that off, so the next output continues on the same line.}
    code {puts -nonewline "Loading"
puts "..."}
    out {Loading...}
    p {An option like `-nonewline` goes **before** the text, and starts with a dash. You will meet many commands with options.}
  }}
}
ex {
  {kind type q {Which character starts a comment?} accept {#} why {A `#` at the start of a command turns the rest of the line into a comment.}}
  {kind predict code {# puts "hidden"
puts "shown"} choices {shown hidden {hidden
shown} {nothing}} ans 0 why {The first line is a comment, so Tcl ignores it.}}
  {kind predict code {puts "One\nTwo"} choices {"One\nTwo" {One\nTwo} {One Two} OneTwo} ans 0 why {Inside double quotes `\n` becomes a line break, so the text is printed on two lines.}}
  {kind predict code {puts -nonewline "A"
puts "B"} choices {AB "A\nB" B A} ans 0 why {`-nonewline` stops `puts` from adding a line break, so B follows A directly.}}
  {kind mc q {What does `\t` put into text?} choices {{A tab} {A new line} {A quote mark} {The letter t}} ans 0 why {`\t` is a tab character; `\n` is a new line.}}
  {kind blank q {Complete the line so it prints a quote mark around hi.} code {puts "She said ___hi___"} answers {{\"} {\"}} extra {{"} {\n}} out {She said "hi"} why {A backslash before a quote mark prints it instead of ending the text.}}
  {kind order q {Print Hello, Tcl on a single line.} lines {{puts -nonewline "Hello, "} {puts "Tcl"}} out {Hello, Tcl} why {The first `puts` leaves the cursor on the same line, so the second one continues it.}}
}
cards {
  {{How do you write a comment in Tcl?} {Start a command with `#`. Tcl ignores the rest of that line.}}
  {{How do you add a comment after a command on the same line?} {Put a semicolon first: `puts "Hi" ;# note`.}}
  {{What do `\n`, `\t` and `\"` mean inside double quotes?} {New line, tab, and a literal quote mark.}}
  {{What does `puts -nonewline` do?} {It prints text without adding a line break at the end.}}
}
}
