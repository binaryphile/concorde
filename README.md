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

-   write reusable bash libraries (naysaying curmudgeons be damned)

-   do [test-driven development] on bash code

-   work with hashes and arrays

-   write self-contained functions without reference to global variables

-   keep global variable and function namespaces as uncluttered as
    possible

-   reduce visual clutter from special characters

Prerequisites
=============

-   Bash 4.3 or 4.4 - verified with:

    -   4.3.11

    -   4.3.33

    -   4.4.12

-   GNU `readlink` in your PATH - for Mac users, `greadlink` is also
    acceptable

-   `sed` in your PATH

Reserved Variables
==================

Concorde reserves the following global variables for its own use:

-   `__` - double-underscore, used for returning strings from functions

-   `__features` - a hash for feature (i.e. library) meta-data

-   `__instances` - a hash for holding object-like data structures

-   `__macros` - a hash for holding safer versions of commonly-used
    commands

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

-   boolean flag options - e.g. `-f` or `--flag` - results in *true* or
    unset

-   named arguments (a.k.a. option arguments) - e.g. `-a <value>` or
    `--argument <value>` - result stored in variable named for option

-   multiple short flags condensed to a single dash - e.g. for `-a`,
    `-b` and `-c`: `-abc`

-   named argument allowed at the end of condensed options - e.g. for
    named argument `-d <value>`: `-abcd "d's value"`

-   long named arguments with or without equals sign - e.g.
    `--option <value>` or `--option=<value>`

-   automatic removal of options and values processed by the parser from
    the calling script's own positional arguments (`$1`, etc.), leaving
    just the actual positional arguments from the user

Variables which store boolean flags always hold *true* when the flag is
provided on the command-line.

`parse_options` notably **doesn't** provide:

-   the ability to specify a flag that sets a value of *false*

-   concatenation of an option argument to its short option - e.g.
    `-o<value>` is not allowed, a space is required as in:

        -o <value>

-   an automatic `--no-<flag>` form of long flag negation

-   automatic shortening of long option names to minimal unambiguous
    prefixes

-   built-in `--help` or `--version` implementations

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
before enabling it on legacy code.

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
    sourcing file, does not require file extension

Hash Operations
---------------

-   `grab` - create local variables from key/values in a hash

-   `local_hsh` - create a local hash from a hash literal or variable
    reference

-   `stuff` - add key/values to a hash using local variables

-   `update` - update a hash with the contents of another hash

-   `with` - extract all hash keys into local variables

Array Operations
----------------

-   `assign` - multiple assignment from array values to local variables

-   `get_here_ary` - get a (usually multiline) string from stdin and
    strip leading whitespace indentation, then assign each line to an
    element of an array

-   `local_ary` - create a local array from an array literal or variable
    reference

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

-   `sourced` - determine whether the current file is being sourced or
    not

Input/Output
------------

-   `die` - output message on stderr and exit

-   `log` - log output (currently just goes to stdout)

-   `put` - replacement for `echo` which uses printf, behaves like ruby
    `puts` - see [this explanation] for why you might want to use it

-   `puterr` - output message on stderr

-   `raise` - output message on stderr and return

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

A few points for understanding the template:

-   any `source` or `require` statements come right after the shebang
    line

-   the first part of the script only defines functions, up until
    `sourced && return`; this is so the test framework can test those
    functions

-   the second part tests whether the script is being run or is being
    sourced and does three things if it is being run:

    -   turn on strict mode

    -   define and parse options

    -   call the main function of the script with an options hash and
        the remaining positional arguments

-   `parse_options` places the options in a hash stored in `$__`, which
    is in turn fed to `script_main`

-   `parse_options` also removes from the script's positional arguments
    those options which it parses, so the "$@" in `script_main __ "$@"`
    only contains the remaining unparsed positional arguments

-   the first thing `script_main` does is use `grab` to create local
    variables of the keys "opt1" (a named argument) and "opt2\_flag" (a
    flag) from the hash passed in the first argument

-   "opt1" is a named argument holding a value from the user's
    invocation

-   "opt2\_flag" is a flag from the "opt2" definition, which
    automatically has "\_flag" appended to its name by `parse_options`

-   if "opt2\_flag" is *true*, then `(( opt2_flag ))` evaluates as true;
    this is the standard way to test a flag

-   `(( $# ))` is true so long as the number of positional arguments is
    greater than 0 - `shift` removes the first positional argument, so
    the loop will eventually end

Concorde's Internal Rules
=========================

These are the rules which concorde's functions follow. Although I try to
use the same rules for the rest of my bash coding, you are certainly not
required to follow them yourself, except insofar as to know how to
interact with concorde.

1.  **test**

    Write tests for bash functions. Employ [red-green-refactor]. Keep
    functions focused on a single task.

2.  **minimize [side-effects]**

    Side-effects are changes to variables outside of scope or other
    observable interactions with calling functions, other than returning
    a value.

    This means a lot of things, but for functions, it specifically means
    that they are self-contained to as great an extent as possible:

    -   all variables are declared local

    -   global variables are, for the most part, not employed or
        modified ("\_\_" being one notable exception)

    -   arguments should be values, not references (with some
        exceptions)

    -   where references are allowed, they are dereferenced and used as
        values

3.  **arrays and hashes are passed and returned as string
    representations**

    Bash is much better at working with strings as arguments than with
    other data structures. The rules explained so far mean that you
    really have to use strings for arrays and hashes, since you want to
    pass them rather than rely on globals, and they can only be passed
    as strings.

    While this sounds like extra work, it actually ends up being
    convenient when coupled with the other functions in concorde.  You
    don't often need to work with native hashes when you can extract
    keys directly into your namespace, and multiple assignment makes
    array items available as locals as well.  And the rest of concorde's
    functions expect arrays as strings in the first place, so once
    converted, the arrays rarely need to be converted back to native
    form.

    The format of the string representations is simply the text format
    used in array assignments, with parentheses on the outside and array
    items separated by spaces. Quotes are used to put spaces in values:

        "( zero \"item one\" 'item two' )"

    I call these array and hash literals, even though they are normally
    restricted to only assignment statements.

    In many places, this documentation refers to "passing an array" or a
    hash. This is simply shorthand for "passing an array literal".

    For hashes, the format always includes indices, which looks like:

        "( [zero]=0 [one]=1 [two]='et cetera' )"

    Hashes also have a succinct format which can be used instead.  It
    drops the parentheses and brackets:

        "zero=0 one=1 two='et cetera'"

    Notice that quotes are still needed around it as a whole, since it
    is a string.

4.  **arrays and hashes may be passed by variable name as well**

    Functions which expect an array or hash literal can use the
    functions `local_ary` or `local_hsh`, which create a local
    array/hash from the literal.

    Because array/hash literal strings are unambiguously distinct from
    variable names (which are restricted to single-word
    underscore/alphanumerics), those functions can tell the difference
    and will automatically dereference a variable name.

    The reason for this is that it results in fewer quotes and dollar
    signs, which makes things more readable.

5.  **return values, aside from return codes, are put in the global
    variable "\_\_" (double-underscore)**

    Rather than relying on [command substitution] to save returned
    strings in a variable, concorde prefers to store them in a global
    variable. This has a couple benefits:

    -   no subshell is required, improving performance

    -   unintentional output is rarely captured (a hazard with command
        substitution)

    -   intermediate values in a chain of string operations don't
        usually require a temporary or accumulator variable to be
        declared, since they are already stored in "\_\_"

    There are a couple downsides as well, however:

    -   "\_\_", much like "$?", can't be relied on to stay the same from
        function call to function call, so any value that needs to be
        saved must *immediately* be assigned - e.g. `myvalue=$**`

    -   therefore most assignments which were one line when using
        command substitution now require two lines, one for the call and
        one for the assignment

    -   functions following this rule can't be used in pipelines, since
        pipelines automatically run them in a subshell and the global
        context is thrown away when the function ends

    -   the code looks strange if you aren't used to the concept

6.  **functions use positional parameters for required arguments and a
    keyword hash for optional arguments**

    Optional arguments are ones that have defaults. An example:

          my_function () {
            local mandatory=$1; shift
            local optional="default value"
            $(grab optional from "$1")
            [...]
          }

          my_function "required string" optional="optional value"

  [StackOverflow]: https://stackoverflow.com/
  [Bash Hacker's Wiki]: http://wiki.bash-hackers.org/
  [GreyCat's Wiki]: http://mywiki.wooledge.org/
  [test-driven development]: https://www.agilealliance.org/glossary/tdd
  [enhanced getopt]: https://linux.die.net/man/1/getopt
  [Strict Mode]: http://redsymbol.net/articles/unofficial-bash-strict-mode/
  [here]: http://fvue.nl/wiki/Bash:_Error_handling
  [this explanation]: https://unix.stackexchange.com/questions/65803/why-is-printf-better-than-echo
  [tutorial]: share/doc/tutorial.md
  [red-green-refactor]: http://www.jamesshore.com/Blog/Red-Green-Refactor.html
  [side-effects]: https://en.wikipedia.org/wiki/Side_effect_%28computer_science%29
  [command substitution]: http://wiki.bash-hackers.org/syntax/expansion/cmdsubst
