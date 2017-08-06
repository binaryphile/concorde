Message For You, Sir [![Build Status](https://travis-ci.org/binaryphile/concorde.svg?branch=master)](https://travis-ci.org/binaryphile/concorde)
====================

Bash scripting in my own particular...\[sigh\]...

Concorde: "Idiom, sir?"

Idiom!

Concorde is a distillation of techniques I've picked up from
[StackOverflow] and the [Bash Hacker's Wiki], and to a lesser extent
[GreyCat's Wiki], as well as my own personal stylings with bash.

Goals
=====

Make it easy to:

-   get started writing a script with the familiar command-line
    interface

-   write reusable bash libraries

-   do [test-driven development] on bash code

-   work with hashes and arrays

-   write self-contained functions without reference to global variables

-   keep global variable and function namespaces as uncluttered as
    possible

Prerequisites
=============

-   Bash 4.3 or 4.4

-   GNU readlink in your PATH as `readlink`

-   `sed` in your PATH

Installation
============

Clone this repo or copy `lib/concorde.bash`. Make the location of
`concorde.bash` (e.g. `~/concorde/lib`) available in your PATH. Then use
`source concorde.bash` in your scripts.

Features
========

Option Parser
-------------

A basic parser, aimed at the features of [enhanced getopt].

Features:

-   single-dash short options - e.g. `-o`

-   double-dash long options - e.g. `--option`

-   boolean flag options - e.g. `-f` or `--flag` - *true* or unset

-   named arguments (a.k.a. option arguments) - e.g. `-a <value>` or
    `--argument <value>` - stored in named variable

-   multiple short flags condensed to a single dash - e.g. for `-a`,
    `-b` and `-c`: `-abc`

-   named argument allowed at the end of condensed options - e.g. for
    named argument `-d <value>`: `-abcd "d's value"`

-   long named arguments with or without equals sign - e.g.
    `--option <value>` or `--option=<value>`

-   automatic removal of options and values processed by the parser from
    the calling script's own positional arguments (`$1`, etc.)

Variables which store boolean flags always hold *true* when the flag is
provided on the command-line.

`parse_options` notably **doesn't** provide:

-   the ability to specify a flag that sets a value of *false*

-   concatenation of an option argument to its short option - e.g.
    `-o<value>` is not allowed, a space is required as in `-o <value>`

-   an automatic `--no-<flag>` form of long flag negation

-   automatic shortening of long option names to minimal unambiguous
    prefixes

[Strict Mode] With Tracebacks
-----------------------------

-   stops on most errors

-   can be turned on and off

-   issues ruby-style tracebacks of the call stack, including file and
    line numbers, as well as the offending line of code such as:

        Traceback:  my_intentionally_erroring_function "$my_argument"
          bin/myscript:193:in erroring_function_caller
          bin/myscript:1:in main

Strict mode does require more careful coding style to avoid
unintentional errors, so it is suggested that you have practice with it
before enabling it on existing code.

I will add some recommended coding hygeine when working with strict
mode, but until I do, you can learn more [here] and at [Aaron Maxwell's
page][Strict Mode].

Ruby-style "Features" a.k.a. Libraries
--------------------------------------

Libraries are written so that they are not unintentionally loaded more
than once, even if sourced multiple times. Concorde also allows the file
extension (e.g. `.sh`) for library files to be left off with its
`require*` functions.

-   `bring` - python-style import of only specified functions from a
    library to keep function namespace uncluttered

-   `feature` - protect a library file from being loaded multiple times
    and register its metadata

-   `load` - source a filename even if it has been loaded already -
    searches PATH but not current directory

-   `require` - like `source` but only searches PATH, not current
    directory, and does not require file extension

-   `require_relative` - source a file relative to the location of the
    sourcing file and does not require file extension

Hash Operations
---------------

-   `grab` - create local variables from key/values in a hash

-   `merge` - update a hash with the contents of another hash

-   `stuff` - add key/values to a hash using local variables

-   `with` - extract all hash keys into local variables

Array Operations
----------------

-   `assign` - multiple assignment from array values to local variables

-   `get_here_ary` - get a (usually multiline) string from stdin and
    strip leading whitespace indentation, then assign each line to an
    element of an array

-   `wed` - join array elements into a string with the specified
    delimiter

String Operations
-----------------

-   `get_here_str` - get a string from stdin (usually a heredoc) and
    strip leading whitespace indentation

-   `get_str` - get a string from stdin (usually a heredoc)

-   `part` - split a string into an array with the specified delimiter

-   `repr` - return string literal representation of hash or array

Contextual Operations
---------------------

-   `in_scope` - determine whether the named variable is local or not

-   `instantiate` - evaluate a string containing unevaluated variable
    references in order to interpolate them

-   `is_set` - determine whether the named variable is set or not

-   `local_ary` - create a local array from an array literal or variable
    reference

-   `local_hsh` - create a local hash from a hash literal or variable
    reference

-   `sourced` - determine whether the current file is being sourced or
    not

Input/Output
------------

-   `die` - exit with a message

-   `log` - log output (currently just goes to stdout)

-   `put` - replacement for `echo` which uses printf, behaves like ruby
    `puts` - see [this explanation] for why you might want to use it

-   `puterr` - output message on stderr

Reserved Variables
==================

Concorde reserves the following global variables for its own use:

-   `__` - double-underscore, used for returning strings from functions

-   `__feature_hsh` - a hash for feature (i.e. library) meta-data

-   `__instance_hsh` - a hash for holding object-like data structures

Sample Script Template
======================

See the [tutorial] for a walkthrough on the thought process behind this
example:

``` bash
#!/usr/bin/env bash

source concorde.bash

get_here_str <<'EOS'
  Detailed usage message goes here
EOS
printf -v usage '\n%s\n' "$__"

script_main () {
  $(grab '( opt1 opt2_flag )' from "$1"); shift

  do_something_with_option "$opt1"

  (( opt2_flag )) && do_something_with_flag

  # consume positional arguments
  while (( $# )); do
    do_something_with_args
    shift
  done
}

other_functions () {
  ...
}

sourced && return   # stop here if testing with shpec
strict_mode on      # stop on errors and issue traceback

# option fields:
#
# short     long      var name                 help
# -----   ------      --------   ------------------
get_here_ary <<'EOS'
  (  -o   --opt1      opt1       "a named argument" )
  (  ''   --opt2      ''         "a long flag"      )
EOS

$(parse_options __ "$@") || die "$usage" 0
script_main     __ "$@"
```

  [StackOverflow]: https://stackoverflow.com/
  [Bash Hacker's Wiki]: http://wiki.bash-hackers.org/
  [GreyCat's Wiki]: http://mywiki.wooledge.org/
  [test-driven development]: https://www.agilealliance.org/glossary/tdd
  [enhanced getopt]: https://linux.die.net/man/1/getopt
  [Strict Mode]: http://redsymbol.net/articles/unofficial-bash-strict-mode/
  [here]: http://fvue.nl/wiki/Bash:_Error_handling
  [this explanation]: https://unix.stackexchange.com/questions/65803/why-is-printf-better-than-echo
  [tutorial]: TUTORIAL.md
