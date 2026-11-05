# Learn Tcl — design plan

Goal: take a person who has **never programmed** to confident, idiomatic,
expert-level Tcl, using an app that is itself 100 % Tcl/Tk.

## 1. What the research says, and what the app does about it

| Principle (evidence) | In the app |
|---|---|
| **Retrieval practice / testing effect** — recalling beats re-reading (Roediger & Karpicke 2006) | Every lesson is ~40 % teaching, ~60 % questions. Nothing is "just read". |
| **Spaced repetition** — reviewing at expanding intervals gives durable memory (Ebbinghaus; Cepeda et al. 2006) | Flashcards use an SM-2 scheduler (Again / Hard / Good / Easy). Cards come from lessons *and* from questions you got wrong. |
| **Interleaving** — mixing topics improves discrimination and transfer (Rohrer & Taylor 2007) | Daily Practice mixes questions from every finished lesson; every lesson opens with a 2-question warm-up from older lessons. |
| **Desirable difficulty / generation effect** — effortful production beats recognition (Bjork) | Question types escalate: multiple choice → predict output → fill the blanks → order the lines → type the answer → write real code. |
| **Worked examples → fading** (Sweller; Kalyuga) — novices learn best from studying examples first | Pages show complete examples; later exercises remove more and more of the solution. |
| **Immediate, explanatory feedback** | After every answer you see *why*, not just right/wrong. |
| **Mastery learning + small steps** (Bloom) — manage cognitive load | Lessons are 5–8 minutes, one idea at a time, unlocked in order. |
| **Error-driven learning** — a wrong answer is re-asked in the same session | Missed questions re-queue at the end of the lesson and become flashcards. |
| **Motivation: goals, streaks, visible progress** (self-determination theory; Duolingo-style design) | Daily XP goal ring, streak, levels, stars per lesson. No punishment mechanics (no lost hearts). |
| **Learning by doing** | A Playground with a real Tcl interpreter (sandboxed, time-limited) and a symbol toolbar for phone typing. |

Recall *and* recognition are both covered on purpose: multiple choice builds
recognition and catches misconceptions cheaply; flashcards and typed answers
force true recall.

## 2. Curriculum (zero -> expert): 17 units, 78 lessons, 772 questions, 293 flashcards

| Unit | Lessons |
|---|---|
| 1 First steps | Hello, Tcl - Commands and words - Comments and special characters |
| 2 Values and variables | Variables - Using a command's result `[ ]` - Quotes, braces and joining |
| 3 Numbers and decisions | `expr` - `if` - `switch` and truth values |
| 4 Loops | `while` - `for` - `foreach`, `break`, `continue` |
| 5 Procedures | `proc` - defaults and `args` - scope and recursion |
| 6 Lists | list basics - searching/sorting/joining - `lmap`, `lassign`, `{*}` |
| 7 Strings and patterns | the `string` toolkit - `format`/`scan` - regular expressions |
| 8 Dictionaries and arrays | `dict` - nested data - arrays |
| 9 Errors and files | `catch`/`try` - reading and writing files - a data pipeline + `clock` |
| 10 Advanced Tcl | how Tcl reads code - `upvar`/`uplevel` - `apply` and introspection - namespaces and ensembles |
| 11 Expert Tcl | coroutines - TclOO - traces - events and timers - safe interpreters and packages - performance and style - Tk |
| 12 Data, channels and testing | bytes, encodings and binary data - channels, pipes and sockets - testing your code |
| 13 The advanced toolbox | regex in depth - text-processing toolbox - TclOO in depth - metaprogramming and DSLs - errors by design - Tcllib and the ecosystem - three Tk lessons (layout, events/canvas, structuring an app) |
| 15 Language deep-dives | numbers in depth - the dict toolbox - the twelve rules - namespaces in depth - interpreters in depth - introspection and `unknown` - files, directories and the OS - Unicode and msgcat - safe and robust Tcl - functional programming - Tk text/lists/images - a complete Tk app |
| 16 Algorithms and data structures | stacks, queues, sets - searching and sorting - recursion, memoisation, dynamic programming - trees and graphs |
| 17 Practice katas | warm-ups - strings and lists - data wrangling (30 small problems with tests) |
| 14 Read, debug and build | reading and debugging real code - capstone projects: to-do manager, word-frequency analyser, RPN calculator, config parser, TclOO bank, coroutine scheduler, state machine, tested string library |

Each lesson: ~3 short teaching pages (worked examples first), a 2-question
warm-up from older lessons, 8-14 questions that fade from recognition to
production (including write-the-code, find-the-bug and project-step exercises), and
3-4 flashcards. Each unit also has a 10-question unit test (80% to pass / test out).

## 3. App architecture

```
main.tcl            entry point & loader
lib/util.tcl        dates, shuffle, helpers
lib/theme.tcl       dark/light palettes
lib/store.tcl       persistent progress (a Tcl dict saved to disk)
lib/srs.tcl         SM-2 spaced-repetition scheduler
lib/sandbox.tcl     runs learner code safely (child interp, time/output limits)
lib/content.tcl     curriculum registry + validation
lib/ui.tcl          widget kit: rounded buttons/cards, rich text, syntax highlight, touch scrolling
lib/exercises.tcl   the six exercise types
lib/runner.tcl      lesson / practice session engine
lib/screens.tcl     Home, Practice, Playground, Profile, flashcard review
content/u*.tcl      the course itself (data, not code)
tests/              content verification + scheduler + UI smoke tests
tools/bundle.tcl    packs everything into one .tcl file for the phone
```

Design rules: touch-first (big targets, drag-to-scroll with inertia, no
hover), everything scales from screen width, no emoji or exotic glyphs (they
are not reliable in Tk fonts), icons drawn on canvases.

## 4. Quality gates

* `tests/run.tcl` executes **every** code example in the course in the real
  sandbox and checks the stated output, so the lessons cannot teach wrong Tcl.
* The scheduler and storage are unit-tested.
* `tests/ui_smoke.tcl` drives the real UI headlessly (taps every screen and
  every exercise type) and writes screenshots.

## 5. Running on Android

Tcl/Tk on Android is provided by **AndroWish** (androwish.org). See
`docs/ANDROID.md`. Build `tools/bundle.tcl` to get a single `learn-tcl.tcl`.
