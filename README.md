Message For You, Sir [![Build Status](https://travis-ci.org/binaryphile/concorde.svg?branch=master)](https://travis-ci.org/binaryphile/concorde)
====================

Bash scripting in my own particular...\[sigh\]...

Concorde: "Idiom, sir?"

Idiom!

Concorde is a distillation of some useful things I've done in bash.
It synthesizes a lot of techniques I've picked up from StackOverflow and
other sites, so it may look a bit unfamiliar to most.  It's heavily
idiomatic of my own personal style, so apologies in advance.

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

-   boolean flag options - e.g. `-f` or `--flag` - true or unset

-   named arguments (a.k.a. option arguments) - e.g. `-a <value>` or
    `--argument <value>` - stored in named variable

-   multiple short flags condensed to a single dash - e.g. for `-a`,
    `-b` and `-c`: `-abc`

-   named argument allowed at the end of condensed options - e.g. for
    named argument `-d <value>`: `-abcd "d's value"`

-   long named arguments with or without equals sign - e.g. `--option
    <value>` or `--option=<value>`

-   automatic removal of options and values processed by the parser from
    the calling script's own positional arguments (`$1`, etc.)

It notably doesn't provide:

-   concatenation of an option argument to its short option - e.g.
    `-o<value>` is not allowed, a space is required as in `-o <value>`

-   the automatic `--no-<flag>` form of flag negation

-   the automatic shortening of long option names to minimally
    unambiguous prefixes

Variables which store boolean flags always hold true when the flag is
provided on the command-line.

[Strict Mode] With Tracebacks
-----------------------------

-   stops on most errors

-   can be turned on and off

-   issues ruby-style tracebacks of the call stack, including file and
    line numbers, as well as echoing the offending line of code

Strict mode does require more careful coding style to avoid
unintentional errors, so it is suggested that you have practice with it
before enabling it on existing code.

Ruby-style "Features" a.k.a. Libraries
--------------------------------------

Libraries are written so that they are not unintentionally loaded more
than once, even if sourced multiple times.  Concorde also allows the
extension for library files to be left off with its `require*`
functions.

-   `bring` - python-style import of only specified functions from a
    library

-   `feature` - protect a library file from being loaded multiple times

-   `load` - source a filename even if it has been loaded already -
    searches PATH but not current directory

-   `require` - like `source` but only searches PATH, not current
    directory

-   `require_relative` - source a file relative to the location of the
    sourcing file

Hash Operations
---------------

-   `grab` - create local variables from key/values in a hash

-   `merge` - update a hash with the contents of another hash

-   `stuff` - add key/values to hash from local variables

-   `with` - extract all hash keys into local variables

Array Operations
----------------

-   `assign` - multiple assignment from array values to local variables

-   `get_here_ary` - get a string from stdin and strip leading
    whitespace indentation, then assign lines to elements of an array

-   `instantiate` - evaluate a string to interpolate variable references

-   `wed` - join array elements into a string with the specified
    delimiter

String Operations
-----------------

-   `get_here_str` - get a string from stdin and strip leading
    whitespace indentation

-   `get_str` - get a string from stdin

-   `part` - split a string into an array with the specified delimiter

-   `repr` - return string literal representation of hash or array

Contextual Operations
---------------------

-   `die` - exit with a message

-   `in_scope` - determine whether the named variable is local or not

-   `is_set` - determine whether the named variable is set or not

-   `local_ary` - create a local array from an array literal or variable
    reference

-   `local_hsh` - create a local hash from an hash literal or variable
    reference

-   `sourced` - determine whether the current file is being sourced or
    not

Input/Output
------------

-   `log` - log some output

-   `put` - replacement for `echo` which uses printf

-   `puterr` - output message on stderr

Reserved Variables
==================

Concorde reserves the following global variables for its own use:

-   `__` - double-underscore, used for returning strings from functions

-   `__feature_hsh` - a hash for feature (i.e. library) meta-data

-   `__instance_hsh` - a hash for holding object-like data structures

Tutorial
========

See the [tutorial] file for details.

  [strict mode]: http://redsymbol.net/articles/unofficial-bash-strict-mode/
  [enhanced getopt]: https://linux.die.net/man/1/getopt
  [test-driven]: https://www.agilealliance.org/glossary/tdd
  [command substitution]: http://wiki.bash-hackers.org/syntax/expansion/cmdsubst
  [here document]: http://wiki.bash-hackers.org/syntax/redirection#here_documents
  [tutorial]: TUTORIAL.md
