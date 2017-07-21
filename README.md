Message For You, Sir
====================

Bash scripting in my own particular...\[sigh\]...

Concorde: "Idiom, sir?"

Idiom!

Concorde is a small-ish library which distills some of the most useful
things I've done in bash.

Goals
=====

The big things which concorde attempts to address include:

-   encourage development of reusable scripts and libraries

-   encourage testable code

-   encourage use of functions

-   encourage use of local variables and reducing dependence on globals;
    generally reducing namespace clutter

-   make arrays and hashes (associative arrays) friendlier and more
    useful

-   make debugging easier with tracebacks

-   provide a reasonably programmable option parser

-   reduce the visual noise of excess punctuation wherever possible
    (quotes, braces, dollar-signs)

-   encourage an "OO-lite" method of marrying code to complex data
    structures in an approachable way

Most of these goals are intertwined, and many of the provided functions
rely on and build off of each other.

With this toolset, it is simple to create bash scripts which:

-   are more readable

-   can be developed in a test-driven manner

-   are able to receive and parse GNU-style options

-   automatically stop on unexpected errors and produce tracebacks to
    the malfunctioning lines of code

-   are easily refactorable into shared libraries of functions for your
    other scripts

Features
========

-   a GNU-style option parser

-   strict mode

-   ruby-style tracebacks

-   library packaging functions

-   utilitarian string and array manipulations

Prerequisites
=============

GNU readlink in your PATH, as `readlink`.

Installation
============

Clone this repo (or copy `lib/concorde.bash`) and make it avaiable in
your PATH. Then use `source concorde.bash` in your scripts.

Reserved Variables
==================

Concorde reserves the following global variables for its own use:

-   `CONCO_CALR` - the full path to the directory of the file which
    sourced concorde

-   `CONCO_ROOT` - the full path to the directory above
    `lib/concorde.bash`

-   `__` - double-underscore, used for returning strings from functions

-   `__conco` - a read-only marker to show that concorde has already
    been loaded

-   `__dependencies` - lists of dependencies for functions imported from
    other libraries

-   `__instanceh` - an internal hash for holding data structures

API
===

Internal-use functions, of which there are but a couple, start with an
underscore. The rest form the public API.

Names which appear to be a little esoteric were typically chosen that
way in order to avoid conflicts with similarly-named programs that you
might find on a system. For example, `wed` instead of the more standard
`join` for arrays.

Some functions incorporate data types in their names when they deal with
such types, such as:

-   `ary`: arrays
-   `str`: strings
-   `hsh`: hashes (associative arrays)

Functions which return string values (which are almost all of them) do
so in the global variable `__` (double-underscore). This is very
important to understand since it is used everywhere. Additionally, this
means that, like `$?`, you can't rely on its value remaining the same
after you call another function. Hence you need to save `__` off to
another variable if you intend to make more use of its value.

A reference is simply a string variable which happens to hold either the
name of another string variable or the name and index of an item in an
array or hash (e.g. `my_hash[key]`). Only references to the variable
`__instanceh` or the names of array or hash variables may be passed to
functions written in concorde's idiom. Other uses of references may
result in namespace clashes.

All parameters designated as "\_array" or "\_hash" in function
signatures described below actually require the literal representation
of the array or hash as a string, e.g. "(three item list)" or
"(\[key\]=value \[pairs\]="")", since bash can't pass actual arrays or
hashes. If you already have such a literal stored in a variable, the API
usually allows you to pass the un-expanded variable name (no dollar
sign) instead and the value will be automatically extrapolated.

The usual way to obtain such a literal from an active array or hash is
via `repr` (short for "representation", a la Python):

    repr my_array
    function_requiring_an_array_literal "$__"

Usually the above function would take the reference `__` as a valid
alternative for `$__`.

Option Parsing
--------------

-   **`parse_options`** *`definitions_array`* - creates a new instance
    of an options data structure

*Returns*: a reference to the option data structure

-   **`options_parse`** *`options_ref [options]`* - parses a list of
    options provided as-is from the command-line (i.e. "$@")

    Options definitions are in the form of an array literal, with each
    item containing a sub-array (literal) of four elements:

    -   *short option* (including hyphen) - may be ommitted (with '' in
        its place) if *long option* is defined

    -   *long option* (including double-hyphen) - may be ommitted (with
        '' in its place) if *short option* is defined

    -   *argument name* - if the option takes an argument, the name of
        the variable in which to store the value.

    -   if omitted with '' in its place, the option becomes a flag with
        the name `flag_[option]`, where \[option\] is the long name, if
        available, otherwise the short name. It receives either the
        value 1 if the flag is supplied, or does not exist if it wasn't

    -   *help string* - currently unused but can still be a useful
        reminder

    *definitions\_array* is usually supplied via `get_here_str`.
    Example:

        get_here_str <<'EOS'
          ( -o --option1            ''      'a flag'  )
          ( '' --option2 argument_name 'an argument'  )
        EOS

        options_new __


